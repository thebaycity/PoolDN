-- Migration: users/roles architecture
-- Drops all old tables and recreates with new schema

DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS matches;
DROP TABLE IF EXISTS team_invitations;
DROP TABLE IF EXISTS team_participations;
DROP TABLE IF EXISTS team_members;
DROP TABLE IF EXISTS competitions;
DROP TABLE IF EXISTS teams;
DROP TABLE IF EXISTS organizers;
DROP TABLE IF EXISTS players;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS cities;
DROP TABLE IF EXISTS countries;

CREATE TABLE countries (
    code TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE cities (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    country_code TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE users (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'player',
    name TEXT,
    nickname TEXT,
    avatar_url TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE organizers (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    organization_name TEXT,
    phone TEXT,
    city TEXT,
    country TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE teams (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    captain_id TEXT NOT NULL,
    city TEXT,
    country TEXT,
    home_venue TEXT,
    logo_url TEXT,
    members TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE team_members (
    id TEXT PRIMARY KEY,
    competition_id TEXT NOT NULL,
    team_id TEXT NOT NULL,
    team_name TEXT NOT NULL,
    status TEXT NOT NULL,
    roster TEXT,
    home_venue TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE competitions (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    organizer_id TEXT NOT NULL,
    description TEXT,
    game_type TEXT,
    format TEXT NOT NULL,
    tournament_type TEXT NOT NULL,
    start_date TEXT,
    prize REAL,
    city TEXT,
    country TEXT,
    status TEXT NOT NULL,
    team_size_min INTEGER NOT NULL,
    team_size_max INTEGER NOT NULL,
    game_structure TEXT,
    schedule_config TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE team_invitations (
    id TEXT PRIMARY KEY,
    team_id TEXT NOT NULL,
    team_name TEXT NOT NULL,
    invited_user_id TEXT,
    invited_email TEXT,
    invited_by_user_id TEXT NOT NULL,
    status TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE matches (
    id TEXT PRIMARY KEY,
    competition_id TEXT NOT NULL,
    round INTEGER NOT NULL,
    matchday INTEGER NOT NULL,
    home_team_id TEXT NOT NULL,
    away_team_id TEXT NOT NULL,
    home_team_name TEXT NOT NULL,
    away_team_name TEXT NOT NULL,
    scheduled_date TEXT,
    venue TEXT,
    status TEXT NOT NULL,
    home_score INTEGER NOT NULL,
    away_score INTEGER NOT NULL,
    games TEXT,
    submitted_by TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE notifications (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    read INTEGER NOT NULL,
    reference_id TEXT,
    reference_type TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

-- Indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_organizers_user_id ON organizers(user_id);
CREATE INDEX idx_teams_captain_id ON teams(captain_id);
CREATE INDEX idx_team_members_competition_id ON team_members(competition_id);
CREATE INDEX idx_team_members_team_id ON team_members(team_id);
CREATE INDEX idx_team_members_comp_status ON team_members(competition_id, status);
CREATE INDEX idx_competitions_organizer_id ON competitions(organizer_id);
CREATE INDEX idx_competitions_status ON competitions(status);
CREATE INDEX idx_team_invitations_team_id ON team_invitations(team_id);
CREATE INDEX idx_team_invitations_invited_user_id ON team_invitations(invited_user_id);
CREATE INDEX idx_matches_competition_id ON matches(competition_id);
CREATE INDEX idx_matches_status ON matches(status);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_user_read ON notifications(user_id, read);
CREATE INDEX idx_cities_country_code ON cities(country_code);
