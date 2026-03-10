import { Hono } from 'hono';
import { Env } from '../env';
import { createServices } from '../utils/helpers';
import { authMiddleware } from '../middleware/auth';
import * as standingsService from '../services/standings.service';
import * as playerRatingService from '../services/player-rating.service';

const standings = new Hono<Env>();

standings.get('/competitions/:competitionId/standings', authMiddleware, async (c) => {
  const services = createServices(c);
  const results = await standingsService.getStandings(services, c.req.param('competitionId'));
  return c.json(results);
});

standings.get('/competitions/:competitionId/player-ratings', authMiddleware, async (c) => {
  const services = createServices(c);
  const ratings = await playerRatingService.getPlayerRatings(services, c.req.param('competitionId'));
  return c.json(ratings);
});

export default standings;
