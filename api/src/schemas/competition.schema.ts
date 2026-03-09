import { z } from 'zod';
import { gameDefinitionSchema, scheduleConfigSchema } from '../models/competition';

export const createCompetitionSchema = z.object({
  name: z.string().min(1),
  description: z.string().optional(),
  gameType: z.string().optional(),
  startDate: z.string().optional(),
  prize: z.number().optional(),
  city: z.string().optional(),
  country: z.string().optional(),
});

export const updateCompetitionSchema = z.object({
  name: z.string().min(1).optional(),
  description: z.string().optional(),
  gameType: z.string().optional(),
  startDate: z.string().optional(),
  prize: z.number().optional(),
  city: z.string().optional(),
  country: z.string().optional(),
  teamSizeMin: z.number().min(1).optional(),
  teamSizeMax: z.number().min(1).optional(),
  gameStructure: z.array(gameDefinitionSchema).optional(),
  scheduleConfig: scheduleConfigSchema.optional(),
});

export const applicationActionSchema = z.object({
  action: z.enum(['accept', 'reject']),
});
