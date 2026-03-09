import { createMiddleware } from 'hono/factory';
import { eq } from 'drizzle-orm';
import { Env } from '../env';
import { users } from '../db/schema';
import { getDb } from '../db';
import { AppError } from '../utils/errors';

export function requireRole(...roles: string[]) {
  return createMiddleware<Env>(async (c, next) => {
    const userId = c.get('userId');
    const db = getDb(c.env.DB);
    const user = await db.select().from(users).where(eq(users.id, userId)).get();
    if (!user) {
      throw AppError.unauthorized('User not found');
    }

    // Admin and super_admin always pass
    if (user.role === 'admin' || user.role === 'super_admin') {
      await next();
      return;
    }

    if (!roles.includes(user.role)) {
      throw AppError.forbidden('Insufficient permissions');
    }

    await next();
  });
}
