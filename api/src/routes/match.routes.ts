import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { Env } from '../env';
import { submitResultSchema, confirmResultSchema } from '../schemas';
import { createServices } from '../utils/helpers';
import { authMiddleware } from '../middleware/auth';
import * as matchService from '../services/match.service';

const matches = new Hono<Env>();

matches.use('*', authMiddleware);

// Get matches for a competition
matches.get('/competitions/:competitionId/matches', async (c) => {
  const services = createServices(c);
  const limit = Math.min(Number(c.req.query('limit') ?? '30'), 100);
  const offset = Number(c.req.query('offset') ?? '0');
  const results = await matchService.getCompetitionMatches(
    services,
    c.req.param('competitionId'),
    limit,
    offset
  );
  return c.json(results);
});

// Get single match
matches.get('/:id', async (c) => {
  const services = createServices(c);
  const match = await matchService.getMatch(services, c.req.param('id'));
  return c.json(match);
});

// Submit result
matches.post('/:id/result', zValidator('json', submitResultSchema), async (c) => {
  const data = c.req.valid('json');
  const services = createServices(c);
  const match = await matchService.submitResult(services, c.req.param('id'), c.get('userId'), data);
  return c.json(match);
});

// Confirm result (organizer only)
matches.post('/:id/confirm', zValidator('json', confirmResultSchema), async (c) => {
  const data = c.req.valid('json');
  const services = createServices(c);
  const match = await matchService.confirmResult(services, c.req.param('id'), c.get('userId'), data);
  return c.json(match);
});

export default matches;
