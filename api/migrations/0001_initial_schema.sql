-- Players
CREATE TABLE players (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  name TEXT NOT NULL,
  nickname TEXT,
  phone TEXT,
  city TEXT,
  avatar_url TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE INDEX idx_players_email ON players(email);
CREATE INDEX idx_players_city ON players(city);

-- Teams
CREATE TABLE teams (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  captain_id TEXT NOT NULL,
  city TEXT,
  home_venue TEXT,
  logo_url TEXT,
  members TEXT NOT NULL DEFAULT '[]',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE INDEX idx_teams_captain_id ON teams(captain_id);
CREATE INDEX idx_teams_city ON teams(city);

-- Competitions
CREATE TABLE competitions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  organizer_id TEXT NOT NULL,
  game_type TEXT,
  format TEXT NOT NULL DEFAULT 'teams',
  tournament_type TEXT NOT NULL DEFAULT 'round_robin',
  start_date TEXT,
  prize REAL,
  status TEXT NOT NULL DEFAULT 'draft',
  team_size_min INTEGER NOT NULL DEFAULT 2,
  team_size_max INTEGER NOT NULL DEFAULT 5,
  game_structure TEXT,
  schedule_config TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE INDEX idx_competitions_organizer_id ON competitions(organizer_id);
CREATE INDEX idx_competitions_status ON competitions(status);

-- Team Participations
CREATE TABLE team_participations (
  id TEXT PRIMARY KEY,
  competition_id TEXT NOT NULL,
  team_id TEXT NOT NULL,
  team_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  roster TEXT,
  home_venue TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE INDEX idx_team_participations_competition_id ON team_participations(competition_id);
CREATE INDEX idx_team_participations_team_id ON team_participations(team_id);
CREATE INDEX idx_team_participations_status ON team_participations(status);

-- Team Invitations
CREATE TABLE team_invitations (
  id TEXT PRIMARY KEY,
  team_id TEXT NOT NULL,
  team_name TEXT NOT NULL,
  invited_player_id TEXT,
  invited_email TEXT,
  invited_by_player_id TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE INDEX idx_team_invitations_team_id ON team_invitations(team_id);
CREATE INDEX idx_team_invitations_invited_player_id ON team_invitations(invited_player_id);
CREATE INDEX idx_team_invitations_invited_email ON team_invitations(invited_email);
CREATE INDEX idx_team_invitations_status ON team_invitations(status);

-- Matches
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
  status TEXT NOT NULL DEFAULT 'scheduled',
  home_score INTEGER NOT NULL DEFAULT 0,
  away_score INTEGER NOT NULL DEFAULT 0,
  games TEXT,
  submitted_by TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE INDEX idx_matches_competition_id ON matches(competition_id);
CREATE INDEX idx_matches_home_team_id ON matches(home_team_id);
CREATE INDEX idx_matches_away_team_id ON matches(away_team_id);
CREATE INDEX idx_matches_status ON matches(status);
CREATE INDEX idx_matches_round ON matches(round);

-- Notifications
CREATE TABLE notifications (
  id TEXT PRIMARY KEY,
  player_id TEXT NOT NULL,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  read INTEGER NOT NULL DEFAULT 0,
  reference_id TEXT,
  reference_type TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE INDEX idx_notifications_player_id ON notifications(player_id);
CREATE INDEX idx_notifications_read ON notifications(read);
