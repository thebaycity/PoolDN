import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { Env } from '../env';
import { applicationActionSchema } from '../schemas';
import { createServices } from '../utils/helpers';
import { authMiddleware } from '../middleware/auth';
import { requireRole } from '../middleware/role';
import * as participationService from '../services/participation.service';

const participations = new Hono<Env>();

participations.use('*', authMiddleware);

// Apply to competition
participations.post(
  '/competitions/:competitionId/apply',
  zValidator('json', z.object({ teamId: z.string() })),
  async (c) => {
    const { teamId } = c.req.valid('json');
    const services = createServices(c);
    const app = await participationService.applyToCompetition(
      services,
      c.req.param('competitionId'),
      teamId,
      c.get('userId')
    );
    return c.json(app, 201);
  }
);

// Handle application (accept/reject)
participations.put(
  '/competitions/:competitionId/applications/:teamId',
  zValidator('json', applicationActionSchema),
  async (c) => {
    const { action } = c.req.valid('json');
    const services = createServices(c);
    const app = await participationService.handleApplication(
      services,
      c.req.param('competitionId'),
      c.req.param('teamId'),
      c.get('userId'),
      action
    );
    return c.json(app);
  }
);

// Invite team to competition (organizer only)
participations.post(
  '/competitions/:competitionId/invite',
  requireRole('organizer', 'admin'),
  zValidator('json', z.object({ teamId: z.string() })),
  async (c) => {
    const { teamId } = c.req.valid('json');
    const services = createServices(c);
    const result = await participationService.inviteTeamToCompetition(
      services,
      c.req.param('competitionId'),
      teamId,
      c.get('userId')
    );
    return c.json(result, 201);
  }
);

// Respond to competition invitation (team captain)
participations.post(
  '/competitions/:competitionId/invitations/:teamId/respond',
  zValidator('json', z.object({ accept: z.boolean() })),
  async (c) => {
    const { accept } = c.req.valid('json');
    const services = createServices(c);
    const result = await participationService.respondToCompetitionInvite(
      services,
      c.req.param('competitionId'),
      c.req.param('teamId'),
      c.get('userId'),
      accept
    );
    return c.json(result);
  }
);

// Withdraw invitation (organizer only)
participations.delete(
  '/competitions/:competitionId/invitations/:teamId',
  requireRole('organizer', 'admin'),
  async (c) => {
    const services = createServices(c);
    await participationService.withdrawInvitation(
      services,
      c.req.param('competitionId'),
      c.req.param('teamId'),
      c.get('userId')
    );
    return c.json({ message: 'Invitation withdrawn' });
  }
);

// Remove team from competition (organizer only)
participations.delete(
  '/competitions/:competitionId/teams/:teamId',
  requireRole('organizer', 'admin'),
  async (c) => {
    const services = createServices(c);
    await participationService.removeTeam(
      services,
      c.req.param('competitionId'),
      c.req.param('teamId'),
      c.get('userId')
    );
    return c.json({ message: 'Team removed' });
  }
);

// Get competition invitations for current user's teams
participations.get('/competition-invitations', async (c) => {
  const services = createServices(c);
  const invitations = await participationService.getTeamCompetitionInvitations(services, c.get('userId'));
  return c.json(invitations);
});

// List participations for a competition
participations.get('/competitions/:competitionId/participations', async (c) => {
  const services = createServices(c);
  const limit = Math.min(Number(c.req.query('limit') ?? '20'), 100);
  const offset = Number(c.req.query('offset') ?? '0');
  const apps = await participationService.getCompetitionParticipations(
    services,
    c.req.param('competitionId'),
    limit,
    offset
  );
  return c.json(apps);
});

export default participations;
