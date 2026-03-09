import { z } from 'zod';

export const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  name: z.string().min(1),
  nickname: z.string().optional(),
  role: z.enum(['player', 'organizer']).default('player'),
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});
