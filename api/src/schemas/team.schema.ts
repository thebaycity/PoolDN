import { z } from 'zod';

export const createTeamSchema = z.object({
  name: z.string().min(1),
  city: z.string().optional(),
  homeVenue: z.string().optional(),
});

export const updateTeamSchema = z.object({
  name: z.string().min(1).optional(),
  city: z.string().optional(),
  homeVenue: z.string().optional(),
  logoUrl: z.string().optional(),
});

export const invitePlayerSchema = z.object({
  email: z.string().email(),
});
