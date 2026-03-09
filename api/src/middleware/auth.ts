import { createMiddleware } from 'hono/factory';
import { Env } from '../env';
import { verifyJwt } from '../utils/jwt';
import { AppError } from '../utils/errors';

export const authMiddleware = createMiddleware<Env>(async (c, next) => {
  const header = c.req.header('Authorization');
  if (!header?.startsWith('Bearer ')) {
    throw AppError.unauthorized('Missing or invalid Authorization header');
  }

  const token = header.slice(7);
  const userId = await verifyJwt(token, c.env.JWT_SECRET);
  if (!userId) {
    throw AppError.unauthorized('Invalid or expired token');
  }

  c.set('userId', userId);
  await next();
});
