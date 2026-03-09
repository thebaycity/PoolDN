import { z } from 'zod';
import { baseEntitySchema } from './base';

export const matchStatus = z.enum(['scheduled', 'in_progress', 'pending_review', 'completed']);
export type MatchStatus = z.infer<typeof matchStatus>;

export interface MatchSubmission {
  homeScore: number;
  awayScore: number;
  games?: GameResult[];
  submittedBy: string;
  submittedAt: number;
}

export const gameResultSchema = z.object({
  gameOrder: z.number(),
  homePlayerName: z.string().optional(),
  awayPlayerName: z.string().optional(),
  homeScore: z.number().default(0),
  awayScore: z.number().default(0),
});

export type GameResult = z.infer<typeof gameResultSchema>;

export const matchSchema = baseEntitySchema.extend({
  competitionId: z.string(),
  round: z.number(),
  matchday: z.number(),
  homeTeamId: z.string(),
  awayTeamId: z.string(),
  homeTeamName: z.string(),
  awayTeamName: z.string(),
  scheduledDate: z.string().optional(),
  venue: z.string().optional(),
  status: matchStatus.default('scheduled'),
  homeScore: z.number().default(0),
  awayScore: z.number().default(0),
  games: z.array(gameResultSchema).optional(),
  homeSubmission: z.any().optional(),
  awaySubmission: z.any().optional(),
  confirmedBy: z.string().optional(),
  submittedBy: z.string().optional(),
});

export type Match = z.infer<typeof matchSchema>;
