import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { Env } from '../env';
import { updateProfileSchema } from '../schemas';
import { createServices } from '../utils/helpers';
import { authMiddleware } from '../middleware/auth';
import * as userService from '../services/user.service';

const userRoutes = new Hono<Env>();

userRoutes.use('*', authMiddleware);

userRoutes.get('/search', async (c) => {
  const q = c.req.query('q') ?? '';
  const role = c.req.query('role');
  const limit = Math.min(Number(c.req.query('limit') ?? '30'), 100);
  // require at least 1 char OR a role filter for browse mode
  if (q.trim().length === 0 && !role) return c.json([]);
  const services = createServices(c);
  const results = await userService.searchUsers(services, q, limit, c.get('userId'), role);
  return c.json(results);
});

userRoutes.get('/:id', async (c) => {
  const services = createServices(c);
  const user = await userService.getUser(services, c.req.param('id'));
  return c.json(user);
});

userRoutes.put('/:id', zValidator('json', updateProfileSchema), async (c) => {
  const id = c.req.param('id');
  const userId = c.get('userId');
  if (id !== userId) {
    return c.json({ error: 'Cannot update other users' }, 403);
  }
  const data = c.req.valid('json');
  const services = createServices(c);
  const user = await userService.updateUser(services, userId, data);
  return c.json(user);
});

userRoutes.get('/:id/teams', async (c) => {
  const services = createServices(c);
  const teams = await userService.getUserTeams(services, c.req.param('id'));
  return c.json(teams);
});

userRoutes.get('/:id/stats', async (c) => {
  const services = createServices(c);
  const id = c.req.param('id');
  const [stats, gameStats] = await Promise.all([
    userService.getUserStats(services, id),
    userService.getUserGameStats(services, id),
  ]);
  return c.json({ ...stats, ...gameStats });
});

userRoutes.post('/:id/avatar', async (c) => {
  const id = c.req.param('id');
  const userId = c.get('userId');
  if (id !== userId) {
    return c.json({ error: 'Cannot update other users' }, 403);
  }

  const body = await c.req.parseBody();
  const file = body['avatar'];
  if (!file || !(file instanceof File)) {
    return c.json({ error: 'No avatar file provided' }, 400);
  }

  const allowedTypes = ['image/jpeg', 'image/png'];
  if (!allowedTypes.includes(file.type)) {
    return c.json({ error: 'Only JPEG and PNG files are allowed' }, 400);
  }

  const maxSize = 5 * 1024 * 1024; // 5MB
  if (file.size > maxSize) {
    return c.json({ error: 'File size must be under 5MB' }, 400);
  }

  const key = `avatars/${userId}.jpg`;
  const arrayBuffer = await file.arrayBuffer();
  await c.env.BUCKET.put(key, arrayBuffer, {
    httpMetadata: { contentType: file.type },
  });

  const avatarUrl = `/assets/${key}`;
  const services = createServices(c);
  const user = await userService.updateUser(services, userId, { avatarUrl });
  return c.json(user);
});

export default userRoutes;
