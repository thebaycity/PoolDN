import { ErrorHandler } from 'hono';
import { AppError } from '../utils/errors';
import { ZodError } from 'zod';
import { Env } from '../env';

export const errorHandler: ErrorHandler<Env> = (err, c) => {
  if (err instanceof AppError) {
    return c.json({ error: err.message }, err.statusCode as any);
  }

  if (err instanceof ZodError) {
    return c.json(
      { error: 'Validation error', details: err.errors },
      400
    );
  }

  console.error('Unhandled error:', err);
  return c.json({ error: 'Internal server error' }, 500);
};
