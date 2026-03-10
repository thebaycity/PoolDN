import { eq, and } from 'drizzle-orm';
import { Services } from '../utils/helpers';
import { teamMembers, matches } from '../db/schema';
import { StandingEntry } from '../types';

export async function getStandings(services: Services, competitionId: string): Promise<StandingEntry[]> {
  const { db } = services;
  const participations = await db.select().from(teamMembers)
    .where(and(eq(teamMembers.competitionId, competitionId), eq(teamMembers.status, 'accepted')))
    .all();
  const allMatches = await db.select().from(matches)
    .where(eq(matches.competitionId, competitionId))
    .all();
  const completedMatches = allMatches.filter(m => m.status === 'completed');

  const standingsMap = new Map<string, StandingEntry>();

  for (const p of participations) {
    standingsMap.set(p.teamId, {
      teamId: p.teamId,
      teamName: p.teamName,
      played: 0,
      won: 0,
      drawn: 0,
      lost: 0,
      gamesWon: 0,
      gamesLost: 0,
      points: 0,
      form: [],
    });
  }

  for (const match of completedMatches) {
    const home = standingsMap.get(match.homeTeamId);
    const away = standingsMap.get(match.awayTeamId);

    if (home) {
      home.played++;
      home.gamesWon += match.homeScore;
      home.gamesLost += match.awayScore;
      if (match.homeScore > match.awayScore) {
        home.won++;
        home.points += 3;
      } else if (match.homeScore === match.awayScore) {
        home.drawn++;
        home.points += 1;
      } else {
        home.lost++;
      }
    }

    if (away) {
      away.played++;
      away.gamesWon += match.awayScore;
      away.gamesLost += match.homeScore;
      if (match.awayScore > match.homeScore) {
        away.won++;
        away.points += 3;
      } else if (match.homeScore === match.awayScore) {
        away.drawn++;
        away.points += 1;
      } else {
        away.lost++;
      }
    }
  }

  // Compute form guide (last 5 results) for each team
  const sortedCompleted = [...completedMatches].sort((a, b) => b.updatedAt - a.updatedAt);
  for (const [teamId, entry] of standingsMap) {
    const teamMatches = sortedCompleted.filter(m => m.homeTeamId === teamId || m.awayTeamId === teamId);
    entry.form = teamMatches.slice(0, 5).map(m => {
      const isHome = m.homeTeamId === teamId;
      const teamScore = isHome ? m.homeScore : m.awayScore;
      const opponentScore = isHome ? m.awayScore : m.homeScore;
      if (teamScore > opponentScore) return 'W' as const;
      if (teamScore < opponentScore) return 'L' as const;
      return 'D' as const;
    });
  }

  return Array.from(standingsMap.values()).sort((a, b) => {
    if (b.points !== a.points) return b.points - a.points;
    const aDiff = a.gamesWon - a.gamesLost;
    const bDiff = b.gamesWon - b.gamesLost;
    if (bDiff !== aDiff) return bDiff - aDiff;
    return b.gamesWon - a.gamesWon;
  });
}
