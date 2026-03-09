import { eq, desc, sql } from 'drizzle-orm';
import { nanoid } from 'nanoid';
import { Services } from '../utils/helpers';
import { competitions, teams, matches, notifications, users } from '../db/schema';
import { AppError } from '../utils/errors';
import type { MatchSubmission, GameResult } from '../models';

function parseSubmission(raw: string | null | undefined): MatchSubmission | null {
  if (!raw) return null;
  try { return JSON.parse(raw); } catch { return null; }
}

export async function getCompetitionMatches(
  services: Services,
  competitionId: string,
  limit = 30,
  offset = 0
) {
  const { db } = services;
  const data = await db.select().from(matches)
    .where(eq(matches.competitionId, competitionId))
    .orderBy(desc(matches.scheduledDate), desc(matches.round))
    .limit(limit)
    .offset(offset)
    .all();
  const totalResult = await db.select({ value: sql<number>`count(*)` })
    .from(matches)
    .where(eq(matches.competitionId, competitionId))
    .get();
  const total = totalResult?.value ?? 0;
  return { data, total, hasMore: offset + limit < total };
}

export async function getMatch(services: Services, id: string) {
  const { db } = services;
  const match = await db.select().from(matches).where(eq(matches.id, id)).get();
  if (!match) throw AppError.notFound('Match not found');
  return match;
}

export async function submitResult(
  services: Services,
  matchId: string,
  userId: string,
  data: { homeScore: number; awayScore: number; games?: GameResult[] }
) {
  const { db } = services;
  const match = await db.select().from(matches).where(eq(matches.id, matchId)).get();
  if (!match) throw AppError.notFound('Match not found');

  if (match.status === 'completed') {
    throw AppError.badRequest('Match result already confirmed');
  }

  const comp = await db.select().from(competitions).where(eq(competitions.id, match.competitionId)).get();
  const homeTeam = await db.select().from(teams).where(eq(teams.id, match.homeTeamId)).get();
  const awayTeam = await db.select().from(teams).where(eq(teams.id, match.awayTeamId)).get();

  const isOrganizer = comp?.organizerId === userId;
  const isHomeCaptain = homeTeam?.captainId === userId;
  const isAwayCaptain = awayTeam?.captainId === userId;

  if (!isOrganizer && !isHomeCaptain && !isAwayCaptain) {
    throw AppError.forbidden('Only team captains or competition organizer can submit results');
  }

  const user = await db.select().from(users).where(eq(users.id, userId)).get();
  const submitterName = user?.name ?? user?.nickname ?? 'Unknown';
  const now = Date.now();

  // Organizer submits → set scores directly, complete immediately
  if (isOrganizer) {
    const updated = await db.update(matches)
      .set({
        homeScore: data.homeScore,
        awayScore: data.awayScore,
        games: data.games,
        status: 'completed',
        confirmedBy: userId,
        submittedBy: userId,
        updatedAt: now,
      })
      .where(eq(matches.id, matchId))
      .returning().get();

    // Notify both captains
    const metadata = JSON.stringify({
      matchId, homeTeamName: match.homeTeamName, awayTeamName: match.awayTeamName,
      homeScore: data.homeScore, awayScore: data.awayScore,
    });
    const captainIds = [homeTeam?.captainId, awayTeam?.captainId].filter(Boolean) as string[];
    for (const captainId of captainIds) {
      await db.insert(notifications).values({
        id: nanoid(), userId: captainId, type: 'score_confirmed',
        title: 'Score Confirmed',
        message: `${match.homeTeamName} ${data.homeScore}–${data.awayScore} ${match.awayTeamName} has been confirmed`,
        read: false, referenceId: matchId, referenceType: 'match', metadata, createdAt: now, updatedAt: now,
      });
    }

    return updated;
  }

  // Captain submits
  const submission: MatchSubmission = {
    homeScore: data.homeScore,
    awayScore: data.awayScore,
    games: data.games,
    submittedBy: userId,
    submittedAt: now,
  };

  const isHome = isHomeCaptain;
  const otherSubmission = parseSubmission(isHome ? match.awaySubmission : match.homeSubmission);
  const otherCaptainId = isHome ? awayTeam?.captainId : homeTeam?.captainId;

  const updateData: Record<string, any> = {
    [isHome ? 'homeSubmission' : 'awaySubmission']: JSON.stringify(submission),
    updatedAt: now,
  };

  if (otherSubmission) {
    // Other side already submitted — check if scores match
    if (otherSubmission.homeScore === data.homeScore && otherSubmission.awayScore === data.awayScore) {
      // Scores agree → auto-complete
      updateData.homeScore = data.homeScore;
      updateData.awayScore = data.awayScore;
      updateData.games = data.games ?? otherSubmission.games;
      updateData.status = 'completed';
      updateData.submittedBy = userId;

      const updated = await db.update(matches).set(updateData).where(eq(matches.id, matchId)).returning().get();

      // Notify both captains: score_confirmed
      const metadata = JSON.stringify({
        matchId, homeTeamName: match.homeTeamName, awayTeamName: match.awayTeamName,
        homeScore: data.homeScore, awayScore: data.awayScore,
      });
      const captainIds = [homeTeam?.captainId, awayTeam?.captainId].filter(Boolean) as string[];
      for (const captainId of captainIds) {
        await db.insert(notifications).values({
          id: nanoid(), userId: captainId, type: 'score_confirmed',
          title: 'Score Confirmed',
          message: `${match.homeTeamName} ${data.homeScore}–${data.awayScore} ${match.awayTeamName} has been confirmed`,
          read: false, referenceId: matchId, referenceType: 'match', metadata, createdAt: now, updatedAt: now,
        });
      }

      return updated;
    } else {
      // Scores disagree → disputed
      updateData.status = 'pending_review';

      const updated = await db.update(matches).set(updateData).where(eq(matches.id, matchId)).returning().get();

      // Notify organizer: score_disputed
      if (comp) {
        const homeSub = isHome ? submission : otherSubmission;
        const awaySub = isHome ? otherSubmission : submission;
        const metadata = JSON.stringify({
          matchId, homeTeamName: match.homeTeamName, awayTeamName: match.awayTeamName,
          homeSubmission: { homeScore: homeSub.homeScore, awayScore: homeSub.awayScore },
          awaySubmission: { homeScore: awaySub.homeScore, awayScore: awaySub.awayScore },
        });
        await db.insert(notifications).values({
          id: nanoid(), userId: comp.organizerId, type: 'score_disputed',
          title: 'Score Disputed',
          message: `${match.homeTeamName} vs ${match.awayTeamName}: captains submitted different scores`,
          read: false, referenceId: matchId, referenceType: 'match', metadata, createdAt: now, updatedAt: now,
        });
      }

      return updated;
    }
  } else {
    // No other submission yet → pending_review, notify other captain + organizer
    updateData.status = 'pending_review';

    const updated = await db.update(matches).set(updateData).where(eq(matches.id, matchId)).returning().get();

    const metadata = JSON.stringify({
      matchId, homeTeamName: match.homeTeamName, awayTeamName: match.awayTeamName,
      homeScore: data.homeScore, awayScore: data.awayScore, submitterName,
    });

    // Notify other captain
    if (otherCaptainId) {
      await db.insert(notifications).values({
        id: nanoid(), userId: otherCaptainId, type: 'score_submitted',
        title: 'Score Submitted',
        message: `${submitterName} submitted ${match.homeTeamName} ${data.homeScore}–${data.awayScore} ${match.awayTeamName}`,
        read: false, referenceId: matchId, referenceType: 'match', metadata, createdAt: now, updatedAt: now,
      });
    }

    // Notify organizer
    if (comp) {
      await db.insert(notifications).values({
        id: nanoid(), userId: comp.organizerId, type: 'score_submitted',
        title: 'Score Submitted',
        message: `${submitterName} submitted ${match.homeTeamName} ${data.homeScore}–${data.awayScore} ${match.awayTeamName}`,
        read: false, referenceId: matchId, referenceType: 'match', metadata, createdAt: now, updatedAt: now,
      });
    }

    return updated;
  }
}

export async function confirmResult(
  services: Services,
  matchId: string,
  userId: string,
  data: { homeScore: number; awayScore: number; games?: GameResult[] }
) {
  const { db } = services;
  const match = await db.select().from(matches).where(eq(matches.id, matchId)).get();
  if (!match) throw AppError.notFound('Match not found');

  const comp = await db.select().from(competitions).where(eq(competitions.id, match.competitionId)).get();
  if (!comp || comp.organizerId !== userId) {
    throw AppError.forbidden('Only the competition organizer can confirm results');
  }

  if (match.status === 'completed') {
    throw AppError.badRequest('Match is already completed');
  }

  const now = Date.now();
  const updated = await db.update(matches)
    .set({
      homeScore: data.homeScore,
      awayScore: data.awayScore,
      games: data.games,
      status: 'completed',
      confirmedBy: userId,
      updatedAt: now,
    })
    .where(eq(matches.id, matchId))
    .returning().get();

  // Notify both captains
  const homeTeam = await db.select().from(teams).where(eq(teams.id, match.homeTeamId)).get();
  const awayTeam = await db.select().from(teams).where(eq(teams.id, match.awayTeamId)).get();
  const metadata = JSON.stringify({
    matchId, homeTeamName: match.homeTeamName, awayTeamName: match.awayTeamName,
    homeScore: data.homeScore, awayScore: data.awayScore,
  });
  const captainIds = [homeTeam?.captainId, awayTeam?.captainId].filter(Boolean) as string[];
  for (const captainId of captainIds) {
    await db.insert(notifications).values({
      id: nanoid(), userId: captainId, type: 'score_confirmed',
      title: 'Score Confirmed',
      message: `${match.homeTeamName} ${data.homeScore}–${data.awayScore} ${match.awayTeamName} has been confirmed by the organizer`,
      read: false, referenceId: matchId, referenceType: 'match', metadata, createdAt: now, updatedAt: now,
    });
  }

  return updated;
}
