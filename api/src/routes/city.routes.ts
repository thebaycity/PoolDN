import { Hono } from 'hono';
import { Env } from '../env';
import { getDb } from '../db';
import * as cityService from '../services/city.service';

const cityRoutes = new Hono<Env>();

// GET /api/cities?country=VN&q=hanoi  (country defaults to VN)
cityRoutes.get('/', async (c) => {
  const db = getDb(c.env.DB);
  const country = c.req.query('country');
  const q = c.req.query('q');
  const results = await cityService.searchCities(db, country, q);
  return c.json(results);
});

const countryRoutes = new Hono<Env>();

countryRoutes.get('/', async (c) => {
  const db = getDb(c.env.DB);
  const results = await cityService.listCountries(db);
  return c.json(results);
});

export { cityRoutes, countryRoutes };
