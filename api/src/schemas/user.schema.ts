import { z } from 'zod';

export const updateProfileSchema = z.object({
  name: z.string().min(1).optional(),
  nickname: z.string().optional(),
  avatarUrl: z.string().optional(),
});
