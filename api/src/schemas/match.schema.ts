import { z } from 'zod';
import { gameResultSchema } from '../models/match';

export const submitResultSchema = z.object({
  homeScore: z.number().min(0),
  awayScore: z.number().min(0),
  games: z.array(gameResultSchema).optional(),
});

export const confirmResultSchema = z.object({
  homeScore: z.number().min(0),
  awayScore: z.number().min(0),
  games: z.array(gameResultSchema).optional(),
});
