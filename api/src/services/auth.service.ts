import { eq, and } from 'drizzle-orm';
import { nanoid } from 'nanoid';
import { Services } from '../utils/helpers';
import { users, organizers, teamInvitations, notifications } from '../db/schema';
import { hashPassword, verifyPassword } from '../utils/password';
import { signJwt } from '../utils/jwt';
import { AppError } from '../utils/errors';

export async function register(
  services: Services,
  jwtSecret: string,
  data: { email: string; password: string; name: string; nickname?: string; role?: string }
) {
  const { db } = services;
  const existing = await db.select().from(users).where(eq(users.email, data.email)).all();
  if (existing.length > 0) {
    throw AppError.conflict('Email already registered');
  }

  const passwordHash = await hashPassword(data.password);
  const now = Date.now();
  const role = data.role ?? 'player';
  const user = await db.insert(users).values({
    id: nanoid(),
    email: data.email,
    passwordHash,
    role,
    name: data.name,
    nickname: data.nickname,
    createdAt: now,
    updatedAt: now,
  }).returning().get();

  // If organizer, also insert into organizers table
  if (role === 'organizer') {
    await db.insert(organizers).values({
      id: nanoid(),
      userId: user.id,
      createdAt: now,
      updatedAt: now,
    });
  }

  // Link any pending invitations sent to this email
  const pendingInvitations = await db.select().from(teamInvitations)
    .where(and(eq(teamInvitations.invitedEmail, data.email), eq(teamInvitations.status, 'pending')))
    .all();
  for (const invitation of pendingInvitations) {
    await db.update(teamInvitations)
      .set({ invitedUserId: user.id, updatedAt: Date.now() })
      .where(eq(teamInvitations.id, invitation.id));

    await db.insert(notifications).values({
      id: nanoid(),
      userId: user.id,
      type: 'team_invitation',
      title: 'Team Invitation',
      message: `You have been invited to join ${invitation.teamName}`,
      read: false,
      referenceId: invitation.id,
      referenceType: 'team_invitation',
      createdAt: Date.now(),
      updatedAt: Date.now(),
    });
  }

  const token = await signJwt(user.id, jwtSecret);
  return {
    token,
    user: { id: user.id, email: user.email, name: user.name, nickname: user.nickname, role: user.role },
  };
}

export async function login(
  services: Services,
  jwtSecret: string,
  data: { email: string; password: string }
) {
  const { db } = services;
  const results = await db.select().from(users).where(eq(users.email, data.email)).all();
  if (results.length === 0) {
    throw AppError.unauthorized('Invalid email or password');
  }

  const user = results[0];
  const valid = await verifyPassword(data.password, user.passwordHash);
  if (!valid) {
    throw AppError.unauthorized('Invalid email or password');
  }

  const token = await signJwt(user.id, jwtSecret);
  return {
    token,
    user: { id: user.id, email: user.email, name: user.name, nickname: user.nickname, role: user.role },
  };
}

export async function getMe(services: Services, userId: string) {
  const { db } = services;
  const user = await db.select().from(users).where(eq(users.id, userId)).get();
  if (!user) throw AppError.notFound('User not found');
  const { passwordHash, ...profile } = user;
  return profile;
}

export async function changePassword(
  services: Services,
  userId: string,
  data: { currentPassword: string; newPassword: string }
) {
  const { db } = services;
  const user = await db.select().from(users).where(eq(users.id, userId)).get();
  if (!user) throw AppError.notFound('User not found');

  const valid = await verifyPassword(data.currentPassword, user.passwordHash);
  if (!valid) throw AppError.unauthorized('Current password is incorrect');

  const newHash = await hashPassword(data.newPassword);
  await db.update(users)
    .set({ passwordHash: newHash, updatedAt: Date.now() })
    .where(eq(users.id, userId));

  return { message: 'Password updated successfully' };
}

