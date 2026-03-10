import { Context } from 'hono';
import { getDb, Database } from '../db';
import { Env } from '../env';

export interface Services {
  db: Database;
}

export function createServices(c: Context<Env>): Services {
  return {
    db: getDb(c.env.DB),
  };
}
