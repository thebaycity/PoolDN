import { Hono } from 'hono';
import { Env } from '../env';
import { createServices } from '../utils/helpers';
import { authMiddleware } from '../middleware/auth';
import * as notificationService from '../services/notification.service';

const notifications = new Hono<Env>();

notifications.use('*', authMiddleware);

notifications.get('/', async (c) => {
  const services = createServices(c);
  const limit = Math.min(parseInt(c.req.query('limit') ?? '20'), 100);
  const offset = parseInt(c.req.query('offset') ?? '0');
  const results = await notificationService.getPlayerNotifications(services, c.get('userId'), limit, offset);
  return c.json(results);
});

notifications.put('/:id/read', async (c) => {
  const services = createServices(c);
  const notification = await notificationService.markNotificationRead(
    services,
    c.req.param('id'),
    c.get('userId')
  );
  return c.json(notification);
});

export default notifications;
