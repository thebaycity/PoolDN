#!/bin/bash
# Seed all countries and cities into the local D1 database
# Usage: cd api && ./seed-locations.sh

set -e

echo "Seeding countries and cities..."
npx wrangler d1 execute DB --local --file=seed-locations.sql
echo "Done! Seeded all countries and Vietnamese cities."
