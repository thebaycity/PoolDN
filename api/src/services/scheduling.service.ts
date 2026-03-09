import { eq, and } from 'drizzle-orm';
import { nanoid } from 'nanoid';
import { Services } from '../utils/helpers';
import { competitions, teamMembers, matches } from '../db/schema';
import { AppError } from '../utils/errors';
import type { ScheduleConfig } from '../models/competition';

interface MatchFixture {
  round: number;
  homeTeamId: string;
  awayTeamId: string;
  homeTeamName: string;
  awayTeamName: string;
}

/**
 * Berger algorithm for round-robin scheduling.
 * With N teams (pad to even with a BYE), fix team 0, rotate others.
 */
function bergerRoundRobin(teams: { id: string; name: string; homeVenue?: string | null }[]): MatchFixture[] {
  const n = teams.length;
  const usesBye = n % 2 !== 0;
  const participants = [...teams];

  if (usesBye) {
    participants.push({ id: 'BYE', name: 'BYE' });
  }

  const count = participants.length;
  const rounds = count - 1;
  const half = count / 2;
  const fixtures: MatchFixture[] = [];

  // Create indices array (fix index 0, rotate the rest)
  const indices = participants.map((_, i) => i);

  for (let round = 0; round < rounds; round++) {
    for (let i = 0; i < half; i++) {
      const homeIdx = indices[i];
      const awayIdx = indices[count - 1 - i];
      const home = participants[homeIdx];
      const away = participants[awayIdx];

      if (home.id === 'BYE' || away.id === 'BYE') continue;

      // Handle venue conflicts: if both teams share same home venue,
      // alternate who plays at home based on round
      let finalHome = home;
      let finalAway = away;
      if (home.homeVenue && away.homeVenue && home.homeVenue === away.homeVenue && round % 2 === 1) {
        finalHome = away;
        finalAway = home;
      }

      fixtures.push({
        round: round + 1,
        homeTeamId: finalHome.id,
        awayTeamId: finalAway.id,
        homeTeamName: finalHome.name,
        awayTeamName: finalAway.name,
      });
    }

    // Rotate: fix index 0, shift the rest
    const last = indices.pop()!;
    indices.splice(1, 0, last);
  }

  return fixtures;
}

interface ScheduledMatch extends MatchFixture {
  matchday: number;
  scheduledDate?: string;
  venue?: string;
}

function assignDates(
  fixtures: MatchFixture[],
  config: ScheduleConfig,
  startDate: string | undefined | null
): ScheduledMatch[] {
  const start = startDate ? new Date(startDate) : new Date();
  const result: ScheduledMatch[] = [];

  if (config.schedulingType === 'weekly_rounds' && config.weekdays?.length) {
    const weekdays = config.weekdays.sort();
    let currentDate = new Date(start);
    let matchday = 1;
    const roundMap = new Map<number, number>();

    for (const fixture of fixtures) {
      if (!roundMap.has(fixture.round)) {
        // Find next matching weekday
        while (!weekdays.includes(currentDate.getDay())) {
          currentDate.setDate(currentDate.getDate() + 1);
        }
        roundMap.set(fixture.round, matchday);
        matchday++;
      }

      result.push({
        ...fixture,
        matchday: roundMap.get(fixture.round)!,
        scheduledDate: currentDate.toISOString().split('T')[0],
        venue: config.venueType === 'central' ? config.centralVenue : undefined,
      });

      // If this is the last fixture for the round, advance to next weekday
      const remainingInRound = fixtures.filter(f => f.round === fixture.round);
      const currentInRound = result.filter(r => r.round === fixture.round);
      if (currentInRound.length === remainingInRound.length) {
        currentDate.setDate(currentDate.getDate() + 1);
      }
    }
  } else if (config.schedulingType === 'fixed_matchdays' && config.fixedDates?.length) {
    const dates = config.fixedDates.sort();
    let dateIndex = 0;
    let matchday = 1;
    const roundMap = new Map<number, number>();

    for (const fixture of fixtures) {
      if (!roundMap.has(fixture.round)) {
        roundMap.set(fixture.round, matchday);
        matchday++;
        if (dateIndex < dates.length - 1) dateIndex++;
      }

      result.push({
        ...fixture,
        matchday: roundMap.get(fixture.round)!,
        scheduledDate: dates[Math.min(dateIndex, dates.length - 1)],
        venue: config.venueType === 'central' ? config.centralVenue : undefined,
      });
    }
  } else {
    // Default: one matchday per round, weekly
    let matchday = 1;
    let currentDate = new Date(start);

    const rounds = [...new Set(fixtures.map(f => f.round))];
    for (const round of rounds) {
      const roundFixtures = fixtures.filter(f => f.round === round);
      for (const fixture of roundFixtures) {
        result.push({
          ...fixture,
          matchday,
          scheduledDate: currentDate.toISOString().split('T')[0],
          venue: config.venueType === 'central' ? config.centralVenue : undefined,
        });
      }
      matchday++;
      currentDate.setDate(currentDate.getDate() + 7);
    }
  }

  return result;
}

export async function generateMatches(
  services: Services,
  competitionId: string,
  userId: string
) {
  const { db } = services;
  const comp = await db.select().from(competitions).where(eq(competitions.id, competitionId)).get();
  if (!comp) throw AppError.notFound('Competition not found');
  if (comp.organizerId !== userId) throw AppError.forbidden();
  if (comp.status !== 'active') throw AppError.badRequest('Competition must be active to generate matches');

  // Check no matches exist yet
  const existingMatches = await db.select().from(matches)
    .where(eq(matches.competitionId, competitionId)).all();
  if (existingMatches.length > 0) {
    throw AppError.conflict('Matches already generated for this competition');
  }

  const accepted = await db.select().from(teamMembers)
    .where(and(eq(teamMembers.competitionId, competitionId), eq(teamMembers.status, 'accepted')))
    .all();
  if (accepted.length < 2) {
    throw AppError.badRequest('Need at least 2 accepted teams to generate matches');
  }

  const teamList = accepted.map(p => ({
    id: p.teamId,
    name: p.teamName,
    homeVenue: p.homeVenue,
  }));

  let fixtures = bergerRoundRobin(teamList);

  // If gamesPerOpponent === 2, mirror all fixtures (home/away swap)
  const scheduleConfig = comp.scheduleConfig as ScheduleConfig | null;
  const gamesPerOpponent = scheduleConfig?.gamesPerOpponent ?? 1;
  if (gamesPerOpponent === 2) {
    const mirrored = fixtures.map(f => ({
      round: f.round + fixtures.length,
      homeTeamId: f.awayTeamId,
      awayTeamId: f.homeTeamId,
      homeTeamName: f.awayTeamName,
      awayTeamName: f.homeTeamName,
    }));
    fixtures = [...fixtures, ...mirrored];
  }

  const config: ScheduleConfig = scheduleConfig ?? {
    venueType: 'central',
    gamesPerOpponent: 1,
    schedulingType: 'weekly_rounds',
  };

  const scheduled = assignDates(fixtures, config, comp.startDate);

  const createdMatches = [];
  for (const s of scheduled) {
    const now = Date.now();
    const match = await db.insert(matches).values({
      id: nanoid(),
      competitionId,
      round: s.round,
      matchday: s.matchday,
      homeTeamId: s.homeTeamId,
      awayTeamId: s.awayTeamId,
      homeTeamName: s.homeTeamName,
      awayTeamName: s.awayTeamName,
      scheduledDate: s.scheduledDate,
      venue: s.venue,
      status: 'scheduled',
      homeScore: 0,
      awayScore: 0,
      createdAt: now,
      updatedAt: now,
    }).returning().get();
    createdMatches.push(match);
  }

  return createdMatches;
}
