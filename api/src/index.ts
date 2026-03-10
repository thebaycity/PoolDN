import { Hono } from 'hono';
import { Env } from './env';
import { corsMiddleware } from './middleware/cors';
import { errorHandler } from './middleware/error-handler';
import { mountRoutes } from './routes';

const app = new Hono<Env>();

app.use('*', corsMiddleware);
app.onError(errorHandler);

app.get('/', (c) => c.json({ name: 'PoolDN API', version: '1.0.0' }));

app.get('/assets/*', async (c) => {
  const key = c.req.path.replace('/assets/', '');
  const object = await c.env.BUCKET.get(key);
  if (!object) return c.notFound();
  const headers = new Headers();
  object.writeHttpMetadata(headers);
  headers.set('Cache-Control', 'public, max-age=86400');
  return new Response(object.body, { headers });
});

mountRoutes(app);

export default app;
