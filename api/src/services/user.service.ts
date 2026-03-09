import { eq } from 'drizzle-orm';
import { Services } from '../utils/helpers';
import { users, teams, matches } from '../db/schema';
import { AppError } from '../utils/errors';

export async function getUser(services: Services, id: string) {
  const { db } = services;
  const user = await db.select().from(users).where(eq(users.id, id)).get();
  if (!user) throw AppError.notFound('User not found');
  const { passwordHash, ...profile } = user;
  return profile;
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
