import { z } from 'zod';
import { baseEntitySchema } from './base';

export const participationStatus = z.enum(['pending', 'accepted', 'rejected', 'invited', 'declined', 'removed']);
export type ParticipationStatus = z.infer<typeof participationStatus>;

export const rosterPlayerSchema = z.object({
  playerId: z.string(),
  name: z.string(),
});

export type RosterPlayer = z.infer<typeof rosterPlayerSchema>;

export const teamMemberSchema = baseEntitySchema.extend({
  competitionId: z.string(),
  teamId: z.string(),
  teamName: z.string(),
  status: participationStatus.default('pending'),
  roster: z.array(rosterPlayerSchema).optional(),
  homeVenue: z.string().optional(),
});

export type TeamMember = z.infer<typeof teamMemberSchema>;
