import { Hono } from 'hono';
import { Env } from '../env';
import auth from './auth.routes';
import userRoutes from './user.routes';
import teams from './team.routes';
import competitions from './competition.routes';
import participations from './participation.routes';
import matches from './match.routes';
import standings from './standings.routes';
import notifications from './notification.routes';
import invitations from './invitation.routes';
import { cityRoutes, countryRoutes } from './city.routes';
import seed from './seed';

export function mountRoutes(app: Hono<Env>) {
  app.route('/api', seed);
  app.route('/api/auth', auth);
  app.route('/api/users', userRoutes);
  app.route('/api/teams', teams);
  app.route('/api/competitions', competitions);
  app.route('/api', participations);
  app.route('/api/matches', matches);
  app.route('/api', standings);
  app.route('/api/notifications', notifications);
  app.route('/api/team-invitations', invitations);
  app.route('/api/cities', cityRoutes);
  app.route('/api/countries', countryRoutes);
}
