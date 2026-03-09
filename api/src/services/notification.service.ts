import { eq, desc, sql, and } from 'drizzle-orm';
import { Services } from '../utils/helpers';
import { notifications } from '../db/schema';
import { AppError } from '../utils/errors';

export async function getPlayerNotifications(services: Services, userId: string, limit = 20, offset = 0) {
  const { db } = services;
  const data = await db.select().from(notifications)
    .where(eq(notifications.userId, userId))
    .orderBy(desc(notifications.createdAt))
    .limit(limit)
    .offset(offset)
    .all();
  const totalResult = await db.select({ value: sql<number>`count(*)` })
    .from(notifications)
    .where(eq(notifications.userId, userId))
    .get();
  const total = totalResult?.value ?? 0;
  return { data, total, hasMore: offset + limit < total };
}

export async function markNotificationRead(services: Services, notificationId: string, userId: string) {
  const { db } = services;
  const notification = await db.select().from(notifications).where(eq(notifications.id, notificationId)).get();
  if (!notification) throw AppError.notFound('Notification not found');
  if (notification.userId !== userId) throw AppError.forbidden();

  return db.update(notifications)
    .set({ read: true, updatedAt: Date.now() })
    .where(eq(notifications.id, notificationId))
    .returning().get();
}
