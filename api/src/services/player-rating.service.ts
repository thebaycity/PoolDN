import { eq, and } from 'drizzle-orm';
import { Services } from '../utils/helpers';
import { competitions, teamMembers, matches } from '../db/schema';
import { AppError } from '../utils/errors';

export interface PlayerRatingEntry {
  playerId: string;
  playerName: string;
  teamId: string;
  teamName: string;
  gamesPlayed: number;
  singlesWon: number;
  singlesLost: number;
  doublesWon: number;
  doublesLost: number;
  pointsEarned: number;
  pointsAvailable: number;
  rating: number;
}

export async function getPlayerRatings(
  services: Services,
  competitionId: string
): Promise<PlayerRatingEntry[]> {
  const { db } = services;

  const comp = await db.select().from(competitions)
    .where(eq(competitions.id, competitionId)).get();
  if (!comp) throw AppError.notFound('Competition not found');

  const gameStructure = comp.gameStructure ?? [];
  // Build map: order → definition (game items only)
  const structureMap = new Map(
    gameStructure.filter(g => g.type === 'game').map(g => [g.order, g])
  );

  const participations = await db.select().from(teamMembers)
    .where(and(eq(teamMembers.competitionId, competitionId), eq(teamMembers.status, 'accepted')))
    .all();
  const teamMap = new Map(participations.map(p => [p.teamId, p.teamName]));

  const allMatches = await db.select().from(matches)
    .where(eq(matches.competitionId, competitionId))
    .all();
  const completedMatches = allMatches.filter(m => m.status === 'completed' && m.games?.length);

  const playerStats = new Map<string, {
    playerName: string;
    teamId: string;
    teamName: string;
    gamesPlayed: number;
    singlesWon: number;
    singlesLost: number;
    doublesWon: number;
    doublesLost: number;
    pointsEarned: number;
    pointsAvailable: number;
  }>();

  function ensurePlayer(playerId: string, playerName: string, teamId: string) {
    if (!playerStats.has(playerId)) {
      playerStats.set(playerId, {
        playerName,
        teamId,
        teamName: teamMap.get(teamId) ?? teamId,
        gamesPlayed: 0,
        singlesWon: 0,
        singlesLost: 0,
        doublesWon: 0,
        doublesLost: 0,
        pointsEarned: 0,
        pointsAvailable: 0,
      });
    }
  }

  function creditPlayer(playerId: string, isDoubles: boolean, won: boolean) {
    const stats = playerStats.get(playerId);
    if (!stats) return;
    const pointValue = isDoubles ? 2 : 3;
    stats.gamesPlayed++;
    stats.pointsAvailable += pointValue;
    if (won) {
      stats.pointsEarned += pointValue;
      if (isDoubles) stats.doublesWon++;
      else stats.singlesWon++;
    } else {
      if (isDoubles) stats.doublesLost++;
      else stats.singlesLost++;
    }
  }

  for (const match of completedMatches) {
    if (!match.games) continue;
    for (const game of match.games) {
      const def = structureMap.get(game.gameOrder);
      const isDoubles = def
        ? def.label.toLowerCase().includes('doubles')
        : false;

      const homeWon = game.homeScore > game.awayScore;

      // Process home player(s)
      if (game.homePlayerId) {
        const homeIds = game.homePlayerId.split(' & ');
        const homeNames = (game.homePlayerName ?? '').split(' & ');
        for (let i = 0; i < homeIds.length; i++) {
          const pid = homeIds[i].trim();
          if (!pid) continue;
          ensurePlayer(pid, homeNames[i]?.trim() ?? pid, match.homeTeamId);
          creditPlayer(pid, isDoubles, homeWon);
        }
      }

      // Process away player(s)
      if (game.awayPlayerId) {
        const awayIds = game.awayPlayerId.split(' & ');
        const awayNames = (game.awayPlayerName ?? '').split(' & ');
        for (let i = 0; i < awayIds.length; i++) {
          const pid = awayIds[i].trim();
          if (!pid) continue;
          ensurePlayer(pid, awayNames[i]?.trim() ?? pid, match.awayTeamId);
          creditPlayer(pid, isDoubles, !homeWon);
        }
      }
    }
  }

  const entries: PlayerRatingEntry[] = Array.from(playerStats.entries()).map(([playerId, s]) => ({
    playerId,
    playerName: s.playerName,
    teamId: s.teamId,
    teamName: s.teamName,
    gamesPlayed: s.gamesPlayed,
    singlesWon: s.singlesWon,
    singlesLost: s.singlesLost,
    doublesWon: s.doublesWon,
    doublesLost: s.doublesLost,
    pointsEarned: s.pointsEarned,
    pointsAvailable: s.pointsAvailable,
    rating: s.pointsAvailable > 0
      ? Math.round((s.pointsEarned / s.pointsAvailable) * 1000) / 10
      : 0,
  }));

  // Sort by rating desc, then pointsAvailable desc as tiebreak
  entries.sort((a, b) => {
    if (b.rating !== a.rating) return b.rating - a.rating;
    return b.pointsAvailable - a.pointsAvailable;
  });

  return entries;
}
