#!/usr/bin/env bash
set -euo pipefail

# Seed script for PoolDN local R2 bucket
# Usage: cd api && ./seed.sh

BUCKET="pooldn"
NOW=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

echo "==> Hashing passwords..."
# Hash password "password123" using PBKDF2 via Node (matches our Web Crypto implementation)
PASS_HASH=$(node -e "
const crypto = require('crypto');
const password = 'password123';
const salt = crypto.randomBytes(16);
crypto.pbkdf2(password, salt, 100000, 32, 'sha256', (err, key) => {
  const saltHex = salt.toString('hex');
  const hashHex = key.toString('hex');
  process.stdout.write(saltHex + ':' + hashHex);
});
")

echo "==> Password hash generated"

# --- Player IDs ---
P1="player-001"
P2="player-002"
P3="player-003"
P4="player-004"
P5="player-005"
P6="player-006"

# --- Team IDs ---
T1="team-001"
T2="team-002"
T3="team-003"
T4="team-004"

# --- Competition ID ---
C1="comp-001"

# --- Helper: put JSON object into local R2 ---
put_object() {
  local key="$1"
  local json="$2"
  echo "$json" | npx wrangler r2 object put "${BUCKET}/${key}" --pipe --local --content-type application/json
}

echo ""
echo "=== Seeding Players ==="

put_object "players/${P1}.json" '{
  "id": "'$P1'",
  "email": "alice@thebay.city",
  "passwordHash": "'$PASS_HASH'",
  "name": "Alice Johnson",
  "nickname": "AceAlice",
  "phone": "+1-555-0101",
  "city": "Dallas",
  "createdAt": "'$NOW'",
  "updatedAt": "'$NOW'"
}'

put_object "players/${P2}.json" '{
  "id": "'$P2'",
  "email": "bob@thebay.city",
  "passwordHash": "'$PASS_HASH'",
  "name": "Bob Smith",
  "nickname": "BobTheBreaker",
  "city": "Houston",
  "createdAt": "'$NOW'",
  "updatedAt": "'$NOW'"
}'

put_object "players/${P3}.json" '{
  "id": "'$P3'",
  "email": "carol@thebay.city",
  "passwordHash": "'$PASS_HASH'",
  "name": "Carol Williams",
  "nickname": "CueCarol",
  "city": "Dallas",
  "createdAt": "'$NOW'",
  "updatedAt": "'$NOW'"
}'

put_object "players/${P4}.json" '{
  "id": "'$P4'",
  "email": "dave@thebay.city",
  "passwordHash": "'$PASS_HASH'",
  "name": "Dave Brown",
  "nickname": "DaveyB",
  "city": "Austin",
  "createdAt": "'$NOW'",
  "updatedAt": "'$NOW'"
}'

put_object "players/${P5}.json" '{
  "id": "'$P5'",
  "email": "eve@thebay.city",
  "passwordHash": "'$PASS_HASH'",
  "name": "Eve Davis",
  "city": "Houston",
  "createdAt": "'$NOW'",
  "updatedAt": "'$NOW'"
}'

put_object "players/${P6}.json" '{
  "id": "'$P6'",
  "email": "frank@thebay.city",
  "passwordHash": "'$PASS_HASH'",
  "name": "Frank Miller",
  "city": "Austin",
  "createdAt": "'$NOW'",
  "updatedAt": "'$NOW'"
}'

# Players index
put_object "players/_index.json" '{
  "entries": {
    "'$P1'": { "id": "'$P1'", "email": "alice@thebay.city", "name": "Alice Johnson", "city": "Dallas" },
    "'$P2'": { "id": "'$P2'", "email": "bob@thebay.city", "name": "Bob Smith", "city": "Houston" },
    "'$P3'": { "id": "'$P3'", "email": "carol@thebay.city", "name": "Carol Williams", "city": "Dallas" },
    "'$P4'": { "id": "'$P4'", "email": "dave@thebay.city", "name": "Dave Brown", "city": "Austin" },
    "'$P5'": { "id": "'$P5'", "email": "eve@thebay.city", "name": "Eve Davis", "city": "Houston" },
    "'$P6'": { "id": "'$P6'", "email": "frank@thebay.city", "name": "Frank Miller", "city": "Austin" }
  }
}'

echo ""
echo "=== Seeding Teams ==="

put_object "teams/${T1}.json" '{
  "id": "'$T1'",
  "name": "Dallas Sharks",
  "captainId": "'$P1'",
  "city": "Dallas",
  "homeVenue": "Rack City Billiards",
  "members": [
    { "playerId": "'$P1'", "role": "captain", "joinedAt": "'$NOW'" },
    { "playerId": "'$P3'", "role": "player", "joinedAt": "'$NOW'" }
  ],
  "createdAt": "'$NOW'",
  "updatedAt": "'$NOW'"
}'

put_object "teams/${T2}.json" '{
  "id": "'$T2'",
  "name": "Houston Hustlers",
  "captainId": "'$P2'",
  "city": "Houston",
  "homeVenue": "Corner Pocket Lounge",
  "members": [
    { "playerId": "'$P2'", "role": "captain", "joinedAt": "'$NOW'" },
    { "playerId": "'$P5'", "role": "player", "joinedAt": "'$NOW'" }
  ],
  "createdAt": "'$NOW'",
  "updatedAt": "'$NOW'"
}'

put_object "teams/${T3}.json" '{
  "id": "'$T3'",
  "name": "Austin Aces",
  "captainId": "'$P4'",
  "city": "Austin",
  "homeVenue": "Slick Willie Pool Hall",
  "members": [
    { "playerId": "'$P4'", "role": "captain", "joinedAt": "'$NOW'" },
    { "playerId": "'$P6'", "role": "player", "joinedAt": "'$NOW'" }
  ],
  "createdAt": "'$NOW'",
  "updatedAt": "'$NOW'"
}'

put_object "teams/${T4}.json" '{
  "id": "'$T4'",
  "name": "Dallas Coyotes",
  "captainId": "'$P3'",
  "city": "Dallas",
  "homeVenue": "Rack City Billiards",
  "members": [
    { "playerId": "'$P3'", "role": "captain", "joinedAt": "'$NOW'" }
  ],
  "createdAt": "'$NOW'",
  "updatedAt": "'$NOW'"
}'

# Teams index
put_object "teams/_index.json" '{
  "entries": {
    "'$T1'": { "id": "'$T1'", "name": "Dallas Sharks", "captainId": "'$P1'", "city": "Dallas" },
    "'$T2'": { "id": "'$T2'", "name": "Houston Hustlers", "captainId": "'$P2'", "city": "Houston" },
    "'$T3'": { "id": "'$T3'", "name": "Austin Aces", "captainId": "'$P4'", "city": "Austin" },
    "'$T4'": { "id": "'$T4'", "name": "Dallas Coyotes", "captainId": "'$P3'", "city": "Dallas" }
  }
}'

echo ""
echo "=== Seeding Competition ==="

put_object "competitions/${C1}.json" '{
  "id": "'$C1'",
  "name": "Texas 8-Ball Spring League 2026",
  "organizerId": "'$P1'",
  "gameType": "8-Ball",
  "format": "teams",
  "tournamentType": "round_robin",
  "startDate": "2026-04-01",
  "prize": 5000,
  "status": "upcoming",
  "teamSizeMin": 2,
  "teamSizeMax": 5,
  "gameStructure": [
    { "order": 1, "label": "Game 1", "type": "game" },
    { "order": 2, "label": "Game 2", "type": "game" },
    { "order": 3, "label": "Break", "type": "break" },
    { "order": 4, "label": "Game 3", "type": "game" },
    { "order": 5, "label": "Game 4", "type": "game" },
    { "order": 6, "label": "Game 5 (Decider)", "type": "game" }
  ],
  "scheduleConfig": {
    "venueType": "team_venues",
    "gamesPerOpponent": 2,
    "schedulingType": "weekly_rounds",
    "weekdays": [1, 4]
  },
  "createdAt": "'$NOW'",
  "updatedAt": "'$NOW'"
}'

# Competitions index
put_object "competitions/_index.json" '{
  "entries": {
    "'$C1'": { "id": "'$C1'", "name": "Texas 8-Ball Spring League 2026", "organizerId": "'$P1'", "status": "upcoming" }
  }
}'

echo ""
echo "=== Seeding Team Participations (Applications) ==="

TP1="tp-001"
TP2="tp-002"
TP3="tp-003"

put_object "team-participations/${TP1}.json" '{
  "id": "'$TP1'",
  "competitionId": "'$C1'",
  "teamId": "'$T1'",
  "teamName": "Dallas Sharks",
  "status": "accepted",
  "homeVenue": "Rack City Billiards",
  "roster": [
    { "playerId": "'$P1'", "name": "Alice Johnson" },
    { "playerId": "'$P3'", "name": "Carol Williams" }
  ],
  "createdAt": "'$NOW'",
  "updatedAt": "'$NOW'"
}'

put_object "team-participations/${TP2}.json" '{
  "id": "'$TP2'",
  "competitionId": "'$C1'",
  "teamId": "'$T2'",
  "teamName": "Houston Hustlers",
  "status": "accepted",
  "homeVenue": "Corner Pocket Lounge",
  "roster": [
    { "playerId": "'$P2'", "name": "Bob Smith" },
    { "playerId": "'$P5'", "name": "Eve Davis" }
  ],
  "createdAt": "'$NOW'",
  "updatedAt": "'$NOW'"
}'

put_object "team-participations/${TP3}.json" '{
  "id": "'$TP3'",
  "competitionId": "'$C1'",
  "teamId": "'$T3'",
  "teamName": "Austin Aces",
  "status": "pending",
  "homeVenue": "Slick Willie Pool Hall",
  "roster": [
    { "playerId": "'$P4'", "name": "Dave Brown" },
    { "playerId": "'$P6'", "name": "Frank Miller" }
  ],
  "createdAt": "'$NOW'",
  "updatedAt": "'$NOW'"
}'

# Team participations index
put_object "team-participations/_index.json" '{
  "entries": {
    "'$TP1'": { "id": "'$TP1'", "competitionId": "'$C1'", "teamId": "'$T1'", "status": "accepted" },
    "'$TP2'": { "id": "'$TP2'", "competitionId": "'$C1'", "teamId": "'$T2'", "status": "accepted" },
    "'$TP3'": { "id": "'$TP3'", "competitionId": "'$C1'", "teamId": "'$T3'", "status": "pending" }
  }
}'

echo ""
echo "=== Seeding Notifications ==="

N1="notif-001"

put_object "notifications/${N1}.json" '{
  "id": "'$N1'",
  "playerId": "'$P2'",
  "type": "application_accepted",
  "title": "Application Accepted",
  "message": "Houston Hustlers has been accepted into Texas 8-Ball Spring League 2026!",
  "read": false,
  "referenceId": "'$C1'",
  "referenceType": "competition",
  "createdAt": "'$NOW'",
  "updatedAt": "'$NOW'"
}'

put_object "notifications/_index.json" '{
  "entries": {
    "'$N1'": { "id": "'$N1'", "playerId": "'$P2'", "read": false }
  }
}'

# Empty indexes for collections with no seed data
put_object "team-invitations/_index.json" '{ "entries": {} }'
put_object "matches/_index.json" '{ "entries": {} }'

echo ""
echo "=== Seed complete! ==="
echo ""
echo "Test accounts (all use password: password123):"
echo "  alice@thebay.city  - Organizer, Captain of Dallas Sharks"
echo "  bob@thebay.city    - Captain of Houston Hustlers"
echo "  carol@thebay.city  - Player on Dallas Sharks, Captain of Dallas Coyotes"
echo "  dave@thebay.city   - Captain of Austin Aces"
echo "  eve@thebay.city    - Player on Houston Hustlers"
echo "  frank@thebay.city  - Player on Austin Aces"
echo ""
echo "Competition: Texas 8-Ball Spring League 2026 (status: upcoming)"
echo "  - Dallas Sharks: accepted"
echo "  - Houston Hustlers: accepted"
echo "  - Austin Aces: pending"
echo ""
echo "Next steps: accept Austin Aces, close applications, generate matches"
