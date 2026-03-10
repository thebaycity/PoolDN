import { eq, and, desc, sql, inArray, like, or } from 'drizzle-orm';
import { nanoid } from 'nanoid';
import { Services } from '../utils/helpers';
import { users, teams, teamInvitations, notifications } from '../db/schema';
import { AppError } from '../utils/errors';

async function enrichMembers(db: any, members: { playerId: string; role: string; joinedAt: string }[]) {
  if (members.length === 0) return [];
  const playerIds = members.map(m => m.playerId);
  const userRows = await db.select({
    id: users.id, name: users.name, nickname: users.nickname, avatarUrl: users.avatarUrl
  }).from(users).where(inArray(users.id, playerIds)).all();
  const userMap = new Map(userRows.map((u: any) => [u.id, u] as [string, any]));
  return members.map(m => {
    const user = userMap.get(m.playerId) as { name: string | null; nickname: string | null; avatarUrl: string | null } | undefined;
    return { ...m, name: user?.name ?? 'Unknown', nickname: user?.nickname ?? null, avatarUrl: user?.avatarUrl ?? null };
  });
}

export async function createTeam(
  services: Services,
  captainId: string,
  data: { name: string; city?: string; homeVenue?: string }
) {
  const { db } = services;
  const now = Date.now();
  return db.insert(teams).values({
    id: nanoid(),
    name: data.name,
    captainId,
    city: data.city,
    homeVenue: data.homeVenue,
    members: [{ playerId: captainId, role: 'captain', joinedAt: new Date().toISOString() }],
    createdAt: now,
    updatedAt: now,
  }).returning().get();
}

export async function getTeam(services: Services, id: string) {
  const { db } = services;
  const team = await db.select().from(teams).where(eq(teams.id, id)).get();
  if (!team) throw AppError.notFound('Team not found');
  const members = await enrichMembers(db, team.members);
  return { ...team, members };
}

export async function listTeams(services: Services, limit = 20, offset = 0) {
  const { db } = services;
  const data = await db.select().from(teams)
    .orderBy(desc(teams.createdAt))
    .limit(limit)
    .offset(offset)
    .all();
  const totalResult = await db.select({ value: sql<number>`count(*)` }).from(teams).get();
  const total = totalResult?.value ?? 0;
  return { data, total, hasMore: offset + limit < total };
}

export async function searchTeams(
  services: Services,
  query: string,
  city?: string,
  limit = 30
) {
  const { db } = services;
  const q = `%${query.trim()}%`;
  let allTeams = await db.select().from(teams)
    .where(or(like(teams.name, q), like(teams.city, q)))
    .orderBy(desc(teams.createdAt))
    .limit(limit)
    .all();

  if (city) {
    const cityLower = city.toLowerCase();
    allTeams = allTeams.filter(t => t.city?.toLowerCase().includes(cityLower));
  }

  return allTeams;
}

export async function updateTeam(
  services: Services,
  teamId: string,
  userId: string,
  data: { name?: string; city?: string; homeVenue?: string; logoUrl?: string }
) {
  const { db } = services;
  const team = await db.select().from(teams).where(eq(teams.id, teamId)).get();
  if (!team) throw AppError.notFound('Team not found');
  if (team.captainId !== userId) throw AppError.forbidden('Only captain can update team');

  return db.update(teams)
    .set({ ...data, updatedAt: Date.now() })
    .where(eq(teams.id, teamId))
    .returning().get();
}

export async function deleteTeam(
  services: Services,
  teamId: string,
  userId: string
) {
  const { db } = services;
  const team = await db.select().from(teams).where(eq(teams.id, teamId)).get();
  if (!team) throw AppError.notFound('Team not found');
  if (team.captainId !== userId) throw AppError.forbidden('Only captain can delete team');

  await db.delete(teamInvitations).where(eq(teamInvitations.teamId, teamId));
  await db.delete(teams).where(eq(teams.id, teamId));
  return { success: true };
}

export async function invitePlayerByEmail(
  services: Services,
  teamId: string,
  captainId: string,
  email: string
) {
  const { db } = services;
  const team = await db.select().from(teams).where(eq(teams.id, teamId)).get();
  if (!team) throw AppError.notFound('Team not found');
  if (team.captainId !== captainId) throw AppError.forbidden('Only captain can invite players');

  const matchedUsers = await db.select().from(users).where(eq(users.email, email)).all();
  const user = matchedUsers.length > 0 ? matchedUsers[0] : null;

  if (user) {
    if (team.members.some(m => m.playerId === user.id)) {
      throw AppError.conflict('Player is already a team member');
    }

    const existing = await db.select().from(teamInvitations)
      .where(and(
        eq(teamInvitations.teamId, teamId),
        eq(teamInvitations.invitedUserId, user.id),
        eq(teamInvitations.status, 'pending')
      )).all();
    if (existing.length > 0) {
      throw AppError.conflict('Invitation already pending');
    }

    const now = Date.now();
    const invitation = await db.insert(teamInvitations).values({
      id: nanoid(),
      teamId,
      teamName: team.name,
      invitedUserId: user.id,
      invitedEmail: email,
      invitedByUserId: captainId,
      status: 'pending',
      createdAt: now,
      updatedAt: now,
    }).returning().get();

    await db.insert(notifications).values({
      id: nanoid(),
      userId: user.id,
      type: 'team_invitation',
      title: 'Team Invitation',
      message: `You have been invited to join ${team.name}`,
      read: false,
      referenceId: invitation.id,
      referenceType: 'team_invitation',
      createdAt: now,
      updatedAt: now,
    });

    return invitation;
  }

  // Player not registered yet — create deferred invitation
  const existing = await db.select().from(teamInvitations)
    .where(and(
      eq(teamInvitations.teamId, teamId),
      eq(teamInvitations.invitedEmail, email),
      eq(teamInvitations.status, 'pending')
    )).all();
  if (existing.length > 0) {
    throw AppError.conflict('Invitation already pending for this email');
  }

  const now = Date.now();
  return db.insert(teamInvitations).values({
    id: nanoid(),
    teamId,
    teamName: team.name,
    invitedEmail: email,
    invitedByUserId: captainId,
    status: 'pending',
    createdAt: now,
    updatedAt: now,
  }).returning().get();
}

export async function respondToInvitation(
  services: Services,
  invitationId: string,
  userId: string,
  accept: boolean
) {
  const { db } = services;
  const invitation = await db.select().from(teamInvitations).where(eq(teamInvitations.id, invitationId)).get();
  if (!invitation) throw AppError.notFound('Invitation not found');
  if (invitation.invitedUserId !== userId) throw AppError.forbidden();
  if (invitation.status !== 'pending') throw AppError.badRequest('Invitation already responded to');

  const newStatus = accept ? 'accepted' : 'rejected';
  await db.update(teamInvitations)
    .set({ status: newStatus, updatedAt: Date.now() })
    .where(eq(teamInvitations.id, invitationId));

  if (accept) {
    const team = await db.select().from(teams).where(eq(teams.id, invitation.teamId)).get();
    if (team) {
      const updatedMembers = [...team.members, {
        playerId: userId,
        role: 'player' as const,
        joinedAt: new Date().toISOString(),
      }];
      await db.update(teams)
        .set({ members: updatedMembers, updatedAt: Date.now() })
        .where(eq(teams.id, invitation.teamId));
    }
  }

  return { ...invitation, status: newStatus };
}

export async function getPlayerInvitations(services: Services, userId: string) {
  const { db } = services;
  return db.select().from(teamInvitations).where(eq(teamInvitations.invitedUserId, userId)).all();
}

export async function getTeamInvitations(services: Services, teamId: string, userId: string) {
  const { db } = services;
  const team = await db.select().from(teams).where(eq(teams.id, teamId)).get();
  if (!team) throw AppError.notFound('Team not found');
  if (team.captainId !== userId) throw AppError.forbidden('Only captain can view invitations');
  return db.select().from(teamInvitations)
    .where(eq(teamInvitations.teamId, teamId))
    .orderBy(desc(teamInvitations.createdAt))
    .all();
}
