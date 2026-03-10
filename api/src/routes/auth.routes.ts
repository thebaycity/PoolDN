import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { Env } from '../env';
import { registerSchema, loginSchema, changePasswordSchema } from '../schemas';
import { createServices } from '../utils/helpers';
import * as authService from '../services/auth.service';
import { authMiddleware } from '../middleware/auth';

const auth = new Hono<Env>();

auth.post('/register', zValidator('json', registerSchema), async (c) => {
  const data = c.req.valid('json');
  const services = createServices(c);
  const result = await authService.register(services, c.env.JWT_SECRET, data);
  return c.json(result, 201);
});

auth.post('/login', zValidator('json', loginSchema), async (c) => {
  const data = c.req.valid('json');
  const services = createServices(c);
  const result = await authService.login(services, c.env.JWT_SECRET, data);
  return c.json(result);
});

auth.get('/me', authMiddleware, async (c) => {
  const services = createServices(c);
  const user = await authService.getMe(services, c.get('userId'));
  return c.json(user);
});

auth.post('/change-password', authMiddleware, zValidator('json', changePasswordSchema), async (c) => {
  const data = c.req.valid('json');
  const services = createServices(c);
  const result = await authService.changePassword(services, c.get('userId'), data);
  return c.json(result);
});

export default auth;
