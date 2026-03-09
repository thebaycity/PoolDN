import { Hono } from 'hono';
import { Env } from '../env';
import { createServices } from '../utils/helpers';
import { authMiddleware } from '../middleware/auth';
import * as standingsService from '../services/standings.service';

const standings = new Hono<Env>();

standings.get('/competitions/:competitionId/standings', authMiddleware, async (c) => {
  const services = createServices(c);
  const results = await standingsService.getStandings(services, c.req.param('competitionId'));
  return c.json(results);
});

export default standings;
