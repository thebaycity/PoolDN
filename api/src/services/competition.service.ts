import { eq, and, desc, sql } from 'drizzle-orm';
import { nanoid } from 'nanoid';
import { Services } from '../utils/helpers';
import { competitions, teamMembers } from '../db/schema';
import { AppError } from '../utils/errors';

type CompetitionStatus = 'draft' | 'upcoming' | 'active' | 'completed';

export async function createCompetition(
  services: Services,
  organizerId: string,
  data: { name: string; description?: string; gameType?: string; startDate?: string; prize?: number; city?: string; country?: string }
) {
  const { db } = services;
  const now = Date.now();
  return db.insert(competitions).values({
    id: nanoid(),
    name: data.name,
    organizerId,
    description: data.description,
    gameType: data.gameType,
    format: 'teams',
    tournamentType: 'round_robin',
    startDate: data.startDate,
    prize: data.prize,
    city: data.city,
    country: data.country,
    status: 'draft',
    teamSizeMin: 2,
    teamSizeMax: 5,
    createdAt: now,
    updatedAt: now,
  }).returning().get();
}

export async function getCompetition(services: Services, id: string) {
  const { db } = services;
  const comp = await db.select().from(competitions).where(eq(competitions.id, id)).get();
  if (!comp) throw AppError.notFound('Competition not found');
  return comp;
}

export async function listCompetitions(services: Services, limit = 20, offset = 0) {
  const { db } = services;
  const data = await db.select().from(competitions)
    .orderBy(desc(competitions.createdAt))
    .limit(limit)
    .offset(offset)
    .all();
  const totalResult = await db.select({ value: sql<number>`count(*)` }).from(competitions).get();
  const total = totalResult?.value ?? 0;
  return { data, total, hasMore: offset + limit < total };
}

export async function updateCompetition(
  services: Services,
  id: string,
  userId: string,
  data: Record<string, unknown>
) {
  const { db } = services;
  const comp = await db.select().from(competitions).where(eq(competitions.id, id)).get();
  if (!comp) throw AppError.notFound('Competition not found');
  if (comp.organizerId !== userId) throw AppError.forbidden('Only organizer can update');
  if (comp.status === 'active' || comp.status === 'completed') {
    throw AppError.badRequest('Cannot edit an active or completed competition');
  }

  // Strip protected fields
  const { id: _, createdAt, updatedAt, organizerId, status, ...updateFields } = data as any;

  // For upcoming, only allow safe edits (no team size changes once teams applied)
  let safeFields: Record<string, unknown>;
  if (comp.status === 'upcoming') {
    const { teamSizeMin, teamSizeMax, tournamentType, format, ...upcomingAllowed } = updateFields;
    safeFields = upcomingAllowed;
  } else {
    safeFields = updateFields;
  }

  return db.update(competitions)
    .set({ ...safeFields, updatedAt: Date.now() })
    .where(eq(competitions.id, id))
    .returning().get();
}

function validateTransition(current: CompetitionStatus, target: CompetitionStatus) {
  const transitions: Record<CompetitionStatus, CompetitionStatus[]> = {
    draft: ['upcoming'],
    upcoming: ['active'],
    active: ['completed'],
    completed: [],
  };
  if (!transitions[current].includes(target)) {
    throw AppError.badRequest(`Cannot transition from ${current} to ${target}`);
  }
}

export async function publishCompetition(services: Services, id: string, userId: string) {
  const { db } = services;
  const comp = await db.select().from(competitions).where(eq(competitions.id, id)).get();
  if (!comp) throw AppError.notFound('Competition not found');
  if (comp.organizerId !== userId) throw AppError.forbidden();

  validateTransition(comp.status as CompetitionStatus, 'upcoming');
  return db.update(competitions)
    .set({ status: 'upcoming', updatedAt: Date.now() })
    .where(eq(competitions.id, id))
    .returning().get();
}

export async function closeApplications(services: Services, id: string, userId: string) {
  const { db } = services;
  const comp = await db.select().from(competitions).where(eq(competitions.id, id)).get();
  if (!comp) throw AppError.notFound('Competition not found');
  if (comp.organizerId !== userId) throw AppError.forbidden();

  validateTransition(comp.status as CompetitionStatus, 'active');

  // Reject all pending applications
  const pendingApps = await db.select().from(teamMembers)
    .where(and(eq(teamMembers.competitionId, id), eq(teamMembers.status, 'pending')))
    .all();
  for (const app of pendingApps) {
    await db.update(teamMembers)
      .set({ status: 'rejected', updatedAt: Date.now() })
      .where(eq(teamMembers.id, app.id));
  }

  return db.update(competitions)
    .set({ status: 'active', updatedAt: Date.now() })
    .where(eq(competitions.id, id))
    .returning().get();
}

export async function completeCompetition(services: Services, id: string, userId: string) {
  const { db } = services;
  const comp = await db.select().from(competitions).where(eq(competitions.id, id)).get();
  if (!comp) throw AppError.notFound('Competition not found');
  if (comp.organizerId !== userId) throw AppError.forbidden();

  validateTransition(comp.status as CompetitionStatus, 'completed');
  return db.update(competitions)
    .set({ status: 'completed', updatedAt: Date.now() })
    .where(eq(competitions.id, id))
    .returning().get();
}
