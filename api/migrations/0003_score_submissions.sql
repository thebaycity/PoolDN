ALTER TABLE matches ADD COLUMN home_submission TEXT;
ALTER TABLE matches ADD COLUMN away_submission TEXT;
ALTER TABLE matches ADD COLUMN confirmed_by TEXT;
ALTER TABLE notifications ADD COLUMN metadata TEXT;
