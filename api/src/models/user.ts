import { z } from 'zod';
import { baseEntitySchema } from './base';

export const userRole = z.enum(['player', 'organizer', 'admin', 'super_admin']);
export type UserRole = z.infer<typeof userRole>;

export const userSchema = baseEntitySchema.extend({
  email: z.string().email(),
  passwordHash: z.string(),
  role: userRole.default('player'),
  name: z.string().nullable(),
  nickname: z.string().nullable(),
  avatarUrl: z.string().nullable(),
});

export type User = z.infer<typeof userSchema>;
