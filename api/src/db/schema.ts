import {sqliteTable, text, integer, real} from 'drizzle-orm/sqlite-core';
import type {TeamPlayer} from '../models';
import type {GameDefinition, ScheduleConfig} from '../models';
import type {RosterPlayer} from '../models';
import type {GameResult} from '../models';

export const countries = sqliteTable('countries', {
    code: text('code').primaryKey(),
    name: text('name').notNull(),
    createdAt: integer('created_at').notNull(),
    updatedAt: integer('updated_at').notNull(),
});

export const cities = sqliteTable('cities', {
    id: text('id').primaryKey(),
    name: text('name').notNull(),
    countryCode: text('country_code').notNull(),
    createdAt: integer('created_at').notNull(),
    updatedAt: integer('updated_at').notNull(),
});

export const users = sqliteTable('users', {
    id: text('id').primaryKey(),
    email: text('email').notNull().unique(),
    passwordHash: text('password_hash').notNull(),
    role: text('role').notNull().default('player'), // player | organizer | admin | super_admin
    name: text('name'),
    nickname: text('nickname'),
    avatarUrl: text('avatar_url'),
    createdAt: integer('created_at').notNull(),
    updatedAt: integer('updated_at').notNull(),
});

export const organizers = sqliteTable('organizers', {
    id: text('id').primaryKey(),
    userId: text('user_id').notNull(),
    organizationName: text('organization_name'),
    phone: text('phone'),
    city: text('city'),
    country: text('country'),
    createdAt: integer('created_at').notNull(),
    updatedAt: integer('updated_at').notNull(),
});


export const teams = sqliteTable('teams', {
    id: text('id').primaryKey(),
    name: text('name').notNull(),
    captainId: text('captain_id').notNull(),
    city: text('city'),
    country: text('country'),
    homeVenue: text('home_venue'),
    logoUrl: text('logo_url'),
    members: text('members', {mode: 'json'}).$type<TeamPlayer[]>().notNull(),
    createdAt: integer('created_at').notNull(),
    updatedAt: integer('updated_at').notNull(),
});


export const teamMembers = sqliteTable('team_members', {
    id: text('id').primaryKey(),
    competitionId: text('competition_id').notNull(),
    teamId: text('team_id').notNull(),
    teamName: text('team_name').notNull(),
    status: text('status').notNull(),
    roster: text('roster', {mode: 'json'}).$type<RosterPlayer[]>(),
    homeVenue: text('home_venue'),
    createdAt: integer('created_at').notNull(),
    updatedAt: integer('updated_at').notNull(),
});

export const competitions = sqliteTable('competitions', {
    id: text('id').primaryKey(),
    name: text('name').notNull(),
    organizerId: text('organizer_id').notNull(),
    description: text('description'),
    gameType: text('game_type'),
    format: text('format').notNull(),
    tournamentType: text('tournament_type').notNull(),
    startDate: text('start_date'),
    prize: real('prize'),
    city: text('city'),
    country: text('country'),
    status: text('status').notNull(),
    teamSizeMin: integer('team_size_min').notNull(),
    teamSizeMax: integer('team_size_max').notNull(),
    gameStructure: text('game_structure', {mode: 'json'}).$type<GameDefinition[]>(),
    scheduleConfig: text('schedule_config', {mode: 'json'}).$type<ScheduleConfig>(),
    createdAt: integer('created_at').notNull(),
    updatedAt: integer('updated_at').notNull(),
});


export const teamInvitations = sqliteTable('team_invitations', {
    id: text('id').primaryKey(),
    teamId: text('team_id').notNull(),
    teamName: text('team_name').notNull(),
    invitedUserId: text('invited_user_id'),
    invitedEmail: text('invited_email'),
    invitedByUserId: text('invited_by_user_id').notNull(),
    status: text('status').notNull(),
    createdAt: integer('created_at').notNull(),
    updatedAt: integer('updated_at').notNull(),
});

export const matches = sqliteTable('matches', {
    id: text('id').primaryKey(),
    competitionId: text('competition_id').notNull(),
    round: integer('round').notNull(),
    matchday: integer('matchday').notNull(),
    homeTeamId: text('home_team_id').notNull(),
    awayTeamId: text('away_team_id').notNull(),
    homeTeamName: text('home_team_name').notNull(),
    awayTeamName: text('away_team_name').notNull(),
    scheduledDate: text('scheduled_date'),
    venue: text('venue'),
    status: text('status').notNull(),
    homeScore: integer('home_score').notNull(),
    awayScore: integer('away_score').notNull(),
    games: text('games', {mode: 'json'}).$type<GameResult[]>(),
    homeSubmission: text('home_submission'),
    awaySubmission: text('away_submission'),
    confirmedBy: text('confirmed_by'),
    submittedBy: text('submitted_by'),
    createdAt: integer('created_at').notNull(),
    updatedAt: integer('updated_at').notNull(),
});

export const notifications = sqliteTable('notifications', {
    id: text('id').primaryKey(),
    userId: text('user_id').notNull(),
    type: text('type').notNull(),
    title: text('title').notNull(),
    message: text('message').notNull(),
    read: integer('read', {mode: 'boolean'}).notNull(),
    referenceId: text('reference_id'),
    referenceType: text('reference_type'),
    metadata: text('metadata'),
    createdAt: integer('created_at').notNull(),
    updatedAt: integer('updated_at').notNull(),
});
