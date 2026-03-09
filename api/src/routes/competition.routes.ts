import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { Env } from '../env';
import { createCompetitionSchema, updateCompetitionSchema } from '../schemas';
import { createServices } from '../utils/helpers';
import { authMiddleware } from '../middleware/auth';
import { requireRole } from '../middleware/role';
import * as competitionService from '../services/competition.service';
import * as schedulingService from '../services/scheduling.service';

const competitions = new Hono<Env>();

competitions.use('*', authMiddleware);

competitions.post('/', requireRole('organizer', 'admin'), zValidator('json', createCompetitionSchema), async (c) => {
  const data = c.req.valid('json');
  const services = createServices(c);
  const comp = await competitionService.createCompetition(services, c.get('userId'), data);
  return c.json(comp, 201);
});

competitions.get('/', async (c) => {
  const services = createServices(c);
  const limit = Math.min(parseInt(c.req.query('limit') ?? '20'), 100);
  const offset = parseInt(c.req.query('offset') ?? '0');
  const comps = await competitionService.listCompetitions(services, limit, offset);
  return c.json(comps);
});

competitions.get('/:id', async (c) => {
  const services = createServices(c);
  const comp = await competitionService.getCompetition(services, c.req.param('id'));
  return c.json(comp);
});

competitions.put('/:id', zValidator('json', updateCompetitionSchema), async (c) => {
  const data = c.req.valid('json');
  const services = createServices(c);
  const comp = await competitionService.updateCompetition(services, c.req.param('id'), c.get('userId'), data);
  return c.json(comp);
});

competitions.post('/:id/publish', async (c) => {
  const services = createServices(c);
  const comp = await competitionService.publishCompetition(services, c.req.param('id'), c.get('userId'));
  return c.json(comp);
});

competitions.post('/:id/close-applications', async (c) => {
  const services = createServices(c);
  const comp = await competitionService.closeApplications(services, c.req.param('id'), c.get('userId'));
  return c.json(comp);
});

competitions.post('/:id/complete', async (c) => {
  const services = createServices(c);
  const comp = await competitionService.completeCompetition(services, c.req.param('id'), c.get('userId'));
  return c.json(comp);
});

competitions.post('/:id/generate-matches', async (c) => {
  const services = createServices(c);
  const matches = await schedulingService.generateMatches(services, c.req.param('id'), c.get('userId'));
  return c.json(matches, 201);
});

export default competitions;
