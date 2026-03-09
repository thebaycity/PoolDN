import { z } from 'zod';
import { baseEntitySchema } from './base';

export const teamPlayerSchema = z.object({
  playerId: z.string(),
  role: z.enum(['captain', 'player']),
  joinedAt: z.string(),
});

export type TeamPlayer = z.infer<typeof teamPlayerSchema>;

export const teamSchema = baseEntitySchema.extend({
  name: z.string(),
  captainId: z.string(),
  city: z.string().optional(),
  homeVenue: z.string().optional(),
  logoUrl: z.string().optional(),
  members: z.array(teamPlayerSchema),
});

export type Team = z.infer<typeof teamSchema>;
