import { Hono } from 'hono';
import { eq, and } from 'drizzle-orm';
import { Env } from '../env';
import { createServices } from '../utils/helpers';
import { teamInvitations } from '../db/schema';
import { authMiddleware } from '../middleware/auth';
import * as teamService from '../services/team.service';

const invitations = new Hono<Env>();

invitations.use('*', authMiddleware);

invitations.get('/pending', async (c) => {
  const { db } = createServices(c);
  const pending = await db.select().from(teamInvitations)
    .where(and(
      eq(teamInvitations.invitedUserId, c.get('userId')),
      eq(teamInvitations.status, 'pending')
    ))
    .all();
  return c.json(pending);
});

invitations.post('/:id/respond', async (c) => {
  const { accept } = await c.req.json<{ accept: boolean }>();
  const services = createServices(c);
  const invitation = await teamService.respondToInvitation(
    services,
    c.req.param('id'),
    c.get('userId'),
    accept
  );
  return c.json(invitation);
});

export default invitations;
