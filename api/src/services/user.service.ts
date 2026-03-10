import { eq, like, or, desc } from 'drizzle-orm';
import { Services } from '../utils/helpers';
import { users, teams, matches, competitions, teamMembers } from '../db/schema';
import { AppError } from '../utils/errors';

export async function getUser(services: Services, id: string) {
  const { db } = services;
  const user = await db.select().from(users).where(eq(users.id, id)).get();
  if (!user) throw AppError.notFound('User not found');
  const { passwordHash, ...profile } = user;
  return profile;
}

export async function searchUsers(
  services: Services,
  query: string,
  limit = 30,
  excludeUserId?: string,
  role?: string
) {
  const { db } = services;
  const trimmed = query.trim();

  let rows: any[];
  if (trimmed.length === 0) {
    // Browse mode — return all players (newest first)
    rows = await db
      .select()
      .from(users)
      .orderBy(desc(users.createdAt))
      .limit(limit)
      .all();
  } else {
    const q = `%${trimmed}%`;
    rows = await db
      .select()
      .from(users)
      .where(or(like(users.name, q), like(users.nickname, q), like(users.email, q)))
      .limit(limit)
      .all();
  }

  return rows
    .filter(u => u.id !== excludeUserId)
    .filter(u => !role || u.role === role)
    .map(({ passwordHash, ...profile }) => profile);
}

export async function updateUser(
  services: Services,
  userId: string,
  data: { name?: string; nickname?: string; avatarUrl?: string }
) {
  const { db } = services;
  const user = await db.select().from(users).where(eq(users.id, userId)).get();
  if (!user) throw AppError.notFound('User not found');

  const updated = await db.update(users)
    .set({ ...data, updatedAt: Date.now() })
    .where(eq(users.id, userId))
    .returning().get();
  const { passwordHash, ...profile } = updated;
  return profile;
}

export async function getUserTeams(services: Services, userId: string) {
  const { db } = services;
  const allTeams = await db.select().from(teams).all();
  return allTeams.filter(t => t.members.some(m => m.playerId === userId));
}

export async function getUserStats(services: Services, userId: string) {
  const userTeams = await getUserTeams(services, userId);
  const teamIds = userTeams.map(t => t.id);

  const { db } = services;
  const allMatches = await db.select().from(matches).all();
  const userMatches = allMatches.filter(
    m => m.status === 'completed' && (teamIds.includes(m.homeTeamId) || teamIds.includes(m.awayTeamId))
  );

  let wins = 0;
  let losses = 0;
  let draws = 0;

  for (const match of userMatches) {
    const isHome = teamIds.includes(match.homeTeamId);
    if (match.homeScore > match.awayScore) {
      isHome ? wins++ : losses++;
    } else if (match.homeScore < match.awayScore) {
      isHome ? losses++ : wins++;
    } else {
      draws++;
    }
  }

  return {
    totalMatches: userMatches.length,
    wins,
    losses,
    draws,
    teamsCount: userTeams.length,
  };
}

export async function getUserGameStats(services: Services, userId: string) {
  const { db } = services;

  // Find all competitions this user participates in
  const allParticipations = await db.select().from(teamMembers).all();
  const userParticipations = allParticipations.filter(
    p => p.status === 'accepted' && p.roster?.some(r => r.playerId === userId)
  );
  if (userParticipations.length === 0) {
    return { gamesPlayed: 0, singlesWon: 0, singlesLost: 0, doublesWon: 0, doublesLost: 0, pointsEarned: 0, pointsAvailable: 0, rating: 0 };
  }

  const competitionIds = [...new Set(userParticipations.map(p => p.competitionId))];

  let totalGamesPlayed = 0;
  let totalSinglesWon = 0;
  let totalSinglesLost = 0;
  let totalDoublesWon = 0;
  let totalDoublesLost = 0;
  let totalPointsEarned = 0;
  let totalPointsAvailable = 0;

  for (const compId of competitionIds) {
    const comp = await db.select().from(competitions).where(eq(competitions.id, compId)).get();
    if (!comp) continue;

    const gameStructure = comp.gameStructure ?? [];
    const structureMap = new Map(
      gameStructure.filter(g => g.type === 'game').map(g => [g.order, g])
    );

    const compMatches = await db.select().from(matches).where(eq(matches.competitionId, compId)).all();
    const completedMatches = compMatches.filter(m => m.status === 'completed' && m.games?.length);

    for (const match of completedMatches) {
      if (!match.games) continue;
      for (const game of match.games) {
        // Check if this user is involved in this game
        const homeIds = (game.homePlayerId ?? '').split(' & ').map(s => s.trim()).filter(Boolean);
        const awayIds = (game.awayPlayerId ?? '').split(' & ').map(s => s.trim()).filter(Boolean);
        const isHome = homeIds.includes(userId);
        const isAway = awayIds.includes(userId);
        if (!isHome && !isAway) continue;

        const def = structureMap.get(game.gameOrder);
        const isDoubles = def ? def.label.toLowerCase().includes('doubles') : false;
        const pointValue = isDoubles ? 2 : 3;
        const homeWon = game.homeScore > game.awayScore;
        const won = isHome ? homeWon : !homeWon;

        totalGamesPlayed++;
        totalPointsAvailable += pointValue;
        if (won) {
          totalPointsEarned += pointValue;
          if (isDoubles) totalDoublesWon++;
          else totalSinglesWon++;
        } else {
          if (isDoubles) totalDoublesLost++;
          else totalSinglesLost++;
        }
      }
    }
  }

  return {
    gamesPlayed: totalGamesPlayed,
    singlesWon: totalSinglesWon,
    singlesLost: totalSinglesLost,
    doublesWon: totalDoublesWon,
    doublesLost: totalDoublesLost,
    pointsEarned: totalPointsEarned,
    pointsAvailable: totalPointsAvailable,
    rating: totalPointsAvailable > 0
      ? Math.round((totalPointsEarned / totalPointsAvailable) * 1000) / 10
      : 0,
  };
}
