import { z } from 'zod';
import { baseEntitySchema } from './base';

export const organizerSchema = baseEntitySchema.extend({
  userId: z.string(),
  organizationName: z.string().nullable(),
  phone: z.string().nullable(),
  city: z.string().nullable(),
  country: z.string().nullable(),
});

export type Organizer = z.infer<typeof organizerSchema>;
