import { z } from 'zod';

export const baseEntitySchema = z.object({
  id: z.string(),
  createdAt: z.number(),
  updatedAt: z.number(),
});

export type BaseEntity = z.infer<typeof baseEntitySchema>;
