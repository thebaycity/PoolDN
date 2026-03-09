import { z } from 'zod';
import { baseEntitySchema } from './base';

export const notificationType = z.enum([
  'team_invitation',
  'application_accepted',
  'application_rejected',
  'match_scheduled',
  'match_result',
  'competition_update',
  'competition_invitation',
  'invitation_accepted',
  'invitation_declined',
  'score_submitted',
  'score_disputed',
  'score_confirmed',
  'invitation_withdrawn',
  'team_removed',
]);
export type NotificationType = z.infer<typeof notificationType>;

export const notificationSchema = baseEntitySchema.extend({
  playerId: z.string(),
  type: notificationType,
  title: z.string(),
  message: z.string(),
  read: z.boolean().default(false),
  referenceId: z.string().optional(),
  referenceType: z.string().optional(),
  metadata: z.string().optional(),
});

export type Notification = z.infer<typeof notificationSchema>;
