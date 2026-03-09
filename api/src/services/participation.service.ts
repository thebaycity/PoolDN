import { eq, and, sql } from 'drizzle-orm';
import { nanoid } from 'nanoid';
import { Services } from '../utils/helpers';
import { competitions, teams, teamMembers, notifications } from '../db/schema';
import { AppError } from '../utils/errors';

export async function applyToCompetition(
  services: Services,
  competitionId: string,
  teamId: string,
  userId: string
) {
  const { db } = services;
  const comp = await db.select().from(competitions).where(eq(competitions.id, competitionId)).get();
  if (!comp) throw AppError.notFound('Competition not found');
  if (comp.status !== 'upcoming') throw AppError.badRequest('Competition is not accepting applications');

  const team = await db.select().from(teams).where(eq(teams.id, teamId)).get();
  if (!team) throw AppError.notFound('Team not found');
  if (team.captainId !== userId) throw AppError.forbidden('Only team captain can apply');

  if (team.members.length < comp.teamSizeMin) {
    throw AppError.badRequest(`Team must have at least ${comp.teamSizeMin} members`);
  }
  if (team.members.length > comp.teamSizeMax) {
    throw AppError.badRequest(`Team must have at most ${comp.teamSizeMax} members`);
  }

  const existing = await db.select().from(teamMembers)
    .where(and(eq(teamMembers.competitionId, competitionId), eq(teamMembers.teamId, teamId)))
    .all();
  if (existing.length > 0) {
    throw AppError.conflict('Team has already applied');
  }

  const now = Date.now();
  return db.insert(teamMembers).values({
    id: nanoid(),
    competitionId,
    teamId,
    teamName: team.name,
    status: 'pending',
    homeVenue: team.homeVenue,
    roster: team.members.map(m => ({
      playerId: m.playerId,
      name: m.playerId, // Will be resolved at display time
    })),
    createdAt: now,
    updatedAt: now,
  }).returning().get();
}

export async function handleApplication(
  services: Services,
  competitionId: string,
  teamId: string,
  userId: string,
  action: 'accept' | 'reject'
) {
  const { db } = services;
  const comp = await db.select().from(competitions).where(eq(competitions.id, competitionId)).get();
  if (!comp) throw AppError.notFound('Competition not found');
  if (comp.organizerId !== userId) throw AppError.forbidden();

  const apps = await db.select().from(teamMembers)
    .where(and(eq(teamMembers.competitionId, competitionId), eq(teamMembers.teamId, teamId)))
    .all();
  if (apps.length === 0) throw AppError.notFound('Application not found');

  const app = apps[0];
  if (app.status !== 'pending') throw AppError.badRequest('Application already handled');

  const newStatus = action === 'accept' ? 'accepted' : 'rejected';
  const updated = await db.update(teamMembers)
    .set({ status: newStatus, updatedAt: Date.now() })
    .where(eq(teamMembers.id, app.id))
    .returning().get();

  // Notify team captain
  const team = await db.select().from(teams).where(eq(teams.id, teamId)).get();
  if (team) {
    const now = Date.now();
    await db.insert(notifications).values({
      id: nanoid(),
      userId: team.captainId,
      type: action === 'accept' ? 'application_accepted' : 'application_rejected',
      title: action === 'accept' ? 'Application Accepted' : 'Application Rejected',
      message: `Your application for ${team.name} to ${comp.name} has been ${action}ed`,
      read: false,
      referenceId: competitionId,
      referenceType: 'competition',
      createdAt: now,
      updatedAt: now,
    });
  }

  return updated;
}

export async function getCompetitionParticipations(
  services: Services,
  competitionId: string,
  limit = 20,
  offset = 0
) {
  const { db } = services;
  const data = await db.select().from(teamMembers)
    .where(eq(teamMembers.competitionId, competitionId))
    .limit(limit)
    .offset(offset)
    .all();
  const totalResult = await db.select({ value: sql<number>`count(*)` })
    .from(teamMembers)
    .where(eq(teamMembers.competitionId, competitionId))
    .get();
  const total = totalResult?.value ?? 0;
  return { data, total, hasMore: offset + limit < total };
}

export async function getAcceptedTeams(services: Services, competitionId: string) {
  const { db } = services;
  return db.select().from(teamMembers)
    .where(and(eq(teamMembers.competitionId, competitionId), eq(teamMembers.status, 'accepted')))
    .all();
}

export async function respondToCompetitionInvite(
  services: Services,
  competitionId: string,
  teamId: string,
  userId: string,
  accept: boolean
) {
  const { db } = services;
  const team = await db.select().from(teams).where(eq(teams.id, teamId)).get();
  if (!team) throw AppError.notFound('Team not found');
  if (team.captainId !== userId) throw AppError.forbidden('Only team captain can respond');

  const apps = await db.select().from(teamMembers)
    .where(and(eq(teamMembers.competitionId, competitionId), eq(teamMembers.teamId, teamId)))
    .all();
  if (apps.length === 0) throw AppError.notFound('Invitation not found');

  const app = apps[0];
  if (app.status !== 'invited') throw AppError.badRequest('No pending invitation');

  const newStatus = accept ? 'accepted' : 'declined';
  const updated = await db.update(teamMembers)
    .set({ status: newStatus, updatedAt: Date.now() })
    .where(eq(teamMembers.id, app.id))
    .returning().get();

  // Notify organizer
  const comp = await db.select().from(competitions).where(eq(competitions.id, competitionId)).get();
  if (comp) {
    const now = Date.now();
    await db.insert(notifications).values({
      id: nanoid(),
      userId: comp.organizerId,
      type: accept ? 'invitation_accepted' : 'invitation_declined',
      title: accept ? 'Invitation Accepted' : 'Invitation Declined',
      message: `${team.name} has ${accept ? 'accepted' : 'declined'} the invitation to ${comp.name}`,
      read: false,
      referenceId: competitionId,
      referenceType: 'competition',
      createdAt: now,
      updatedAt: now,
    });
  }

  return updated;
}

export async function getTeamCompetitionInvitations(services: Services, userId: string) {
  const { db } = services;
  // Get all teams where user is captain
  const userTeams = await db.select().from(teams).where(eq(teams.captainId, userId)).all();
  if (userTeams.length === 0) return [];

  const invitations = [];
  for (const team of userTeams) {
    const teamInvites = await db.select().from(teamMembers)
      .where(and(eq(teamMembers.teamId, team.id), eq(teamMembers.status, 'invited')))
      .all();
    for (const invite of teamInvites) {
      const comp = await db.select().from(competitions).where(eq(competitions.id, invite.competitionId)).get();
      invitations.push({ ...invite, competitionName: comp?.name ?? 'Unknown' });
    }
  }

  return invitations;
}

export async function withdrawInvitation(
  services: Services,
  competitionId: string,
  teamId: string,
  userId: string
) {
  const { db } = services;
  const comp = await db.select().from(competitions).where(eq(competitions.id, competitionId)).get();
  if (!comp) throw AppError.notFound('Competition not found');
  if (comp.organizerId !== userId) throw AppError.forbidden('Only competition organizer can withdraw invitations');

  const apps = await db.select().from(teamMembers)
    .where(and(eq(teamMembers.competitionId, competitionId), eq(teamMembers.teamId, teamId)))
    .all();
  if (apps.length === 0) throw AppError.notFound('Invitation not found');

  const app = apps[0];
  if (app.status !== 'invited') throw AppError.badRequest('Team is not in invited status');

  await db.delete(teamMembers).where(eq(teamMembers.id, app.id));

  // Notify team captain
  const team = await db.select().from(teams).where(eq(teams.id, teamId)).get();
  if (team) {
    const now = Date.now();
    await db.insert(notifications).values({
      id: nanoid(),
      userId: team.captainId,
      type: 'invitation_withdrawn',
      title: 'Invitation Withdrawn',
      message: `The invitation for ${team.name} to ${comp.name} has been withdrawn`,
      read: false,
      referenceId: competitionId,
      referenceType: 'competition',
      createdAt: now,
      updatedAt: now,
    });
  }
}

export async function removeTeam(
  services: Services,
  competitionId: string,
  teamId: string,
  userId: string
) {
  const { db } = services;
  const comp = await db.select().from(competitions).where(eq(competitions.id, competitionId)).get();
  if (!comp) throw AppError.notFound('Competition not found');
  if (comp.organizerId !== userId) throw AppError.forbidden('Only competition organizer can remove teams');
  if (comp.status === 'completed') throw AppError.badRequest('Cannot remove teams from a completed competition');

  const apps = await db.select().from(teamMembers)
    .where(and(eq(teamMembers.competitionId, competitionId), eq(teamMembers.teamId, teamId)))
    .all();
  if (apps.length === 0) throw AppError.notFound('Team not found in competition');

  const app = apps[0];
  if (app.status !== 'accepted') throw AppError.badRequest('Team is not in accepted status');

  if (comp.status === 'upcoming') {
    // No matches yet — hard delete
    await db.delete(teamMembers).where(eq(teamMembers.id, app.id));
  } else {
    // Active — soft delete to preserve match history
    await db.update(teamMembers)
      .set({ status: 'removed', updatedAt: Date.now() })
      .where(eq(teamMembers.id, app.id));
  }

  // Notify team captain
  const team = await db.select().from(teams).where(eq(teams.id, teamId)).get();
  if (team) {
    const now = Date.now();
    await db.insert(notifications).values({
      id: nanoid(),
      userId: team.captainId,
      type: 'team_removed',
      title: 'Team Removed',
      message: `${team.name} has been removed from ${comp.name}`,
      read: false,
      referenceId: competitionId,
      referenceType: 'competition',
      createdAt: now,
      updatedAt: now,
    });
  }
}

export async function inviteTeamToCompetition(
  services: Services,
  competitionId: string,
  teamId: string,
  organizerUserId: string
) {
  const { db } = services;
  const comp = await db.select().from(competitions).where(eq(competitions.id, competitionId)).get();
  if (!comp) throw AppError.notFound('Competition not found');
  if (comp.organizerId !== organizerUserId) throw AppError.forbidden('Only competition organizer can invite teams');
  if (comp.status !== 'upcoming') throw AppError.badRequest('Competition is not accepting teams');

  const team = await db.select().from(teams).where(eq(teams.id, teamId)).get();
  if (!team) throw AppError.notFound('Team not found');

  const existing = await db.select().from(teamMembers)
    .where(and(eq(teamMembers.competitionId, competitionId), eq(teamMembers.teamId, teamId)))
    .all();
  if (existing.length > 0) {
    throw AppError.conflict('Team is already in this competition');
  }

  const now = Date.now();
  const participation = await db.insert(teamMembers).values({
    id: nanoid(),
    competitionId,
    teamId,
    teamName: team.name,
    status: 'invited',
    homeVenue: team.homeVenue,
    roster: team.members.map(m => ({
      playerId: m.playerId,
      name: m.playerId,
    })),
    createdAt: now,
    updatedAt: now,
  }).returning().get();

  // Notify team captain
  await db.insert(notifications).values({
    id: nanoid(),
    userId: team.captainId,
    type: 'competition_invitation',
    title: 'Competition Invitation',
    message: `Your team ${team.name} has been invited to ${comp.name}`,
    read: false,
    referenceId: competitionId,
    referenceType: 'competition',
    metadata: JSON.stringify({ teamId, teamName: team.name, competitionName: comp.name }),
    createdAt: now,
    updatedAt: now,
  });

  return participation;
}
