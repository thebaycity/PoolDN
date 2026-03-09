import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { Env } from '../env';
import { createTeamSchema, updateTeamSchema, invitePlayerSchema } from '../schemas';
import { createServices } from '../utils/helpers';
import { authMiddleware } from '../middleware/auth';
import * as teamService from '../services/team.service';

const teams = new Hono<Env>();

teams.use('*', authMiddleware);

teams.post('/', zValidator('json', createTeamSchema), async (c) => {
  const data = c.req.valid('json');
  const services = createServices(c);
  const team = await teamService.createTeam(services, c.get('userId'), data);
  return c.json(team, 201);
});

teams.get('/', async (c) => {
  const services = createServices(c);
  const limit = Math.min(parseInt(c.req.query('limit') ?? '20'), 100);
  const offset = parseInt(c.req.query('offset') ?? '0');
  const allTeams = await teamService.listTeams(services, limit, offset);
  return c.json(allTeams);
});

teams.get('/search', async (c) => {
  const q = c.req.query('q') ?? '';
  if (q.trim().length < 2) return c.json([]);
  const city = c.req.query('city');
  const limit = Math.min(Number(c.req.query('limit') ?? '30'), 100);
  const services = createServices(c);
  const results = await teamService.searchTeams(services, q, city, limit);
  return c.json(results);
});

teams.get('/:id', async (c) => {
  const services = createServices(c);
  const team = await teamService.getTeam(services, c.req.param('id'));
  return c.json(team);
});

teams.put('/:id', zValidator('json', updateTeamSchema), async (c) => {
  const data = c.req.valid('json');
  const services = createServices(c);
  const team = await teamService.updateTeam(services, c.req.param('id'), c.get('userId'), data);
  return c.json(team);
});

teams.post('/:id/invite', zValidator('json', invitePlayerSchema), async (c) => {
  const { email } = c.req.valid('json');
  const services = createServices(c);
  const invitation = await teamService.invitePlayerByEmail(services, c.req.param('id'), c.get('userId'), email);
  return c.json(invitation, 201);
});

export default teams;
