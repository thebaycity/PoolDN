import { z } from 'zod';
import { baseEntitySchema } from './base';

export const competitionStatus = z.enum([
  'draft',
  'upcoming',
  'active',
  'completed',
]);
export type CompetitionStatus = z.infer<typeof competitionStatus>;

export const gameDefinitionSchema = z.object({
  order: z.number(),
  label: z.string(),
  type: z.enum(['game', 'break']),
});

export type GameDefinition = z.infer<typeof gameDefinitionSchema>;

export const scheduleConfigSchema = z.object({
  venueType: z.enum(['central', 'team_venues']),
  centralVenue: z.string().optional(),
  gamesPerOpponent: z.number().min(1).max(2).default(1),
  schedulingType: z.enum(['weekly_rounds', 'fixed_matchdays']),
  weekdays: z.array(z.number().min(0).max(6)).optional(),
  fixedDates: z.array(z.string()).optional(),
});

export type ScheduleConfig = z.infer<typeof scheduleConfigSchema>;

export const competitionSchema = baseEntitySchema.extend({
  name: z.string(),
  organizerId: z.string(),
  gameType: z.string().optional(),
  format: z.enum(['teams']).default('teams'),
  tournamentType: z.enum(['round_robin']).default('round_robin'),
  startDate: z.string().optional(),
  prize: z.number().optional(),
  status: competitionStatus.default('draft'),
  teamSizeMin: z.number().min(1).default(2),
  teamSizeMax: z.number().min(1).default(5),
  gameStructure: z.array(gameDefinitionSchema).optional(),
  scheduleConfig: scheduleConfigSchema.optional(),
});

export type Competition = z.infer<typeof competitionSchema>;
