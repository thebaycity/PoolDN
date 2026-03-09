import { z } from 'zod';
import { baseEntitySchema } from './base';

export const invitationStatus = z.enum(['pending', 'accepted', 'rejected']);
export type InvitationStatus = z.infer<typeof invitationStatus>;

export const teamInvitationSchema = baseEntitySchema.extend({
  teamId: z.string(),
  teamName: z.string(),
  invitedPlayerId: z.string().optional(),
  invitedEmail: z.string().email().optional(),
  invitedByPlayerId: z.string(),
  status: invitationStatus.default('pending'),
});

export type TeamInvitation = z.infer<typeof teamInvitationSchema>;
