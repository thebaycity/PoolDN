import { Hono } from 'hono';
import { nanoid } from 'nanoid';
import { Env } from '../env';
import { getDb } from '../db';
import {
  users, organizers, teams, competitions, teamMembers,
  teamInvitations, matches, notifications, countries, cities,
} from '../db/schema';
import { hashPassword } from '../utils/password';

const seed = new Hono<Env>();

seed.post('/seed', async (c) => {
  const db = getDb(c.env.DB);

  // Clear all tables
  await db.delete(notifications);
  await db.delete(matches);
  await db.delete(teamInvitations);
  await db.delete(teamMembers);
  await db.delete(competitions);
  await db.delete(teams);
  await db.delete(organizers);
  await db.delete(users);
  await db.delete(cities);
  await db.delete(countries);

  const now = Date.now();
  const passwordHash = await hashPassword('password123');

  // =====================
  // USERS (8 players)
  // =====================
  const userData = [
    { name: 'Toan Nguyen', email: 'toan@thebay.city', nickname: 'ToanN', role: 'organizer' },
    { name: 'Mike Johnson', email: 'mike@thebay.city', nickname: 'MikeJ', role: 'player' },
    { name: 'Sarah Chen', email: 'sarah@thebay.city', nickname: 'SarahC', role: 'organizer' },
    { name: 'Jake Miller', email: 'jake@thebay.city', nickname: 'JakeM', role: 'player' },
    { name: 'Lisa Park', email: 'lisa@thebay.city', nickname: 'LisaP', role: 'player' },
    { name: 'Chris Brown', email: 'chris@thebay.city', nickname: 'ChrisB', role: 'player' },
    { name: 'Emma Wilson', email: 'emma@thebay.city', nickname: 'EmmaW', role: 'player' },
    { name: 'David Lee', email: 'david@thebay.city', nickname: 'DavidL', role: 'player' },
  ];

  const createdUsers: { id: string; name: string | null; email: string }[] = [];
  for (const u of userData) {
    const user = await db.insert(users).values({
      id: nanoid(),
      email: u.email,
      passwordHash,
      role: u.role,
      name: u.name,
      nickname: u.nickname,
      createdAt: now,
      updatedAt: now,
    }).returning().get();
    createdUsers.push(user);
  }

  const [toan, mike, sarah, jake, lisa, chris, emma, david] = createdUsers;
  const nameOf = (u: typeof toan) => u.name!;

  // =====================
  // ORGANIZERS
  // =====================
  await db.insert(organizers).values({
    id: nanoid(), userId: toan.id, createdAt: now, updatedAt: now,
  });
  await db.insert(organizers).values({
    id: nanoid(), userId: sarah.id, createdAt: now, updatedAt: now,
  });

  // =====================
  // TEAMS (4 teams, 2 members each)
  // =====================
  const teamDefs = [
    { name: 'Bay City Breakers', captain: toan, member: mike, venue: 'Elbow Room', city: 'Bay City' },
    { name: 'Midland Sharks', captain: sarah, member: emma, venue: "Shark's Pool Hall", city: 'Midland' },
    { name: 'Saginaw Stars', captain: lisa, member: david, venue: 'Star Lanes', city: 'Saginaw' },
    { name: 'Bay City Legends', captain: jake, member: chris, venue: 'Legends Bar', city: 'Bay City' },
  ];

  const createdTeams = [];
  for (const t of teamDefs) {
    const team = await db.insert(teams).values({
      id: nanoid(),
      name: t.name,
      captainId: t.captain.id,
      city: t.city,
      homeVenue: t.venue,
      members: [
        { playerId: t.captain.id, role: 'captain', joinedAt: new Date(now).toISOString() },
        { playerId: t.member.id, role: 'player', joinedAt: new Date(now).toISOString() },
      ],
      createdAt: now,
      updatedAt: now,
    }).returning().get();
    createdTeams.push(team);
  }

  const [breakers, sharks, stars, legends] = createdTeams;

  // Helper: build roster with real names
  function roster(team: typeof breakers) {
    return team.members.map((m: { playerId: string }) => ({
      playerId: m.playerId,
      name: createdUsers.find(u => u.id === m.playerId)?.name ?? m.playerId,
    }));
  }

  // =====================
  // COMPETITION 1: ACTIVE — Spring League 2026
  //   4 teams, 6 round-robin matches: 4 completed (with game-level data), 1 pending_review, 1 scheduled
  // =====================
  const comp = await db.insert(competitions).values({
    id: nanoid(),
    name: 'Spring League 2026',
    organizerId: toan.id,
    description: 'The premier 8-ball league in the Great Lakes Bay Region. Teams compete weekly in a round-robin format.',
    gameType: '8-ball',
    format: 'teams',
    tournamentType: 'round_robin',
    startDate: '2026-04-01',
    city: 'Bay City',
    country: 'US',
    status: 'active',
    teamSizeMin: 2,
    teamSizeMax: 5,
    gameStructure: [
      { order: 1, label: 'Singles 1', type: 'game' },
      { order: 2, label: 'Singles 2', type: 'game' },
      { order: 3, label: 'Break', type: 'break' },
      { order: 4, label: 'Doubles', type: 'game' },
      { order: 5, label: 'Singles 3', type: 'game' },
    ],
    scheduleConfig: {
      venueType: 'team_venues',
      gamesPerOpponent: 1,
      schedulingType: 'weekly_rounds',
      weekdays: [3],
    },
    createdAt: now,
    updatedAt: now,
  }).returning().get();

  // =====================
  // COMPETITION 2: UPCOMING — Summer 8-Ball Classic 2026
  //   Has: 1 pending app (Breakers), 1 invited (Stars), 1 accepted (Sharks)
  // =====================
  const comp2 = await db.insert(competitions).values({
    id: nanoid(),
    name: 'Summer 8-Ball Classic 2026',
    organizerId: sarah.id,
    description: 'Summer tournament at the Bay City Recreation Center. Central venue format.',
    gameType: '8-ball',
    format: 'teams',
    tournamentType: 'round_robin',
    startDate: '2026-07-01',
    city: 'Bay City',
    country: 'US',
    status: 'upcoming',
    teamSizeMin: 2,
    teamSizeMax: 4,
    gameStructure: [
      { order: 1, label: 'Singles 1', type: 'game' },
      { order: 2, label: 'Singles 2', type: 'game' },
      { order: 3, label: 'Doubles', type: 'game' },
    ],
    scheduleConfig: {
      venueType: 'central',
      centralVenue: 'Bay City Recreation Center',
      gamesPerOpponent: 1,
      schedulingType: 'weekly_rounds',
      weekdays: [4],
    },
    createdAt: now,
    updatedAt: now,
  }).returning().get();

  // =====================
  // COMPETITION 3: COMPLETED — Winter League 2025
  //   3 teams, 3 round-robin matches, all completed with full game data + player IDs
  // =====================
  const comp3 = await db.insert(competitions).values({
    id: nanoid(),
    name: 'Winter League 2025',
    organizerId: toan.id,
    gameType: '9-ball',
    format: 'teams',
    tournamentType: 'round_robin',
    startDate: '2025-11-01',
    status: 'completed',
    teamSizeMin: 2,
    teamSizeMax: 5,
    gameStructure: [
      { order: 1, label: 'Singles 1', type: 'game' },
      { order: 2, label: 'Singles 2', type: 'game' },
      { order: 3, label: 'Doubles', type: 'game' },
    ],
    scheduleConfig: {
      venueType: 'team_venues',
      gamesPerOpponent: 1,
      schedulingType: 'weekly_rounds',
      weekdays: [2],
    },
    createdAt: now,
    updatedAt: now,
  }).returning().get();

  // =====================
  // COMPETITION 4: DRAFT — Fall 9-Ball Championship 2026
  // =====================
  const comp4 = await db.insert(competitions).values({
    id: nanoid(),
    name: 'Fall 9-Ball Championship 2026',
    organizerId: toan.id,
    description: 'A competitive 9-ball championship for the fall season.',
    gameType: '9-ball',
    format: 'teams',
    tournamentType: 'round_robin',
    startDate: '2026-10-01',
    city: 'Bay City',
    country: 'US',
    status: 'draft',
    teamSizeMin: 2,
    teamSizeMax: 4,
    gameStructure: [
      { order: 1, label: 'Singles 1', type: 'game' },
      { order: 2, label: 'Singles 2', type: 'game' },
      { order: 3, label: 'Doubles', type: 'game' },
    ],
    scheduleConfig: {
      venueType: 'team_venues',
      gamesPerOpponent: 1,
      schedulingType: 'weekly_rounds',
      weekdays: [4],
    },
    createdAt: now,
    updatedAt: now,
  }).returning().get();

  // =====================
  // PARTICIPATIONS — Spring League (active, all 4 accepted)
  // =====================
  const springParticipations = [];
  for (const team of [breakers, sharks, stars, legends]) {
    const p = await db.insert(teamMembers).values({
      id: nanoid(),
      competitionId: comp.id,
      teamId: team.id,
      teamName: team.name,
      status: 'accepted',
      homeVenue: team.homeVenue,
      roster: roster(team),
      createdAt: now,
      updatedAt: now,
    }).returning().get();
    springParticipations.push(p);
  }

  // =====================
  // PARTICIPATIONS — Winter League (completed, 3 teams)
  // =====================
  for (const team of [breakers, sharks, stars]) {
    await db.insert(teamMembers).values({
      id: nanoid(),
      competitionId: comp3.id,
      teamId: team.id,
      teamName: team.name,
      status: 'accepted',
      homeVenue: team.homeVenue,
      roster: roster(team),
      createdAt: now,
      updatedAt: now,
    });
  }

  // =====================
  // PARTICIPATIONS — Summer Classic (upcoming: pending, invited, accepted)
  // =====================
  await db.insert(teamMembers).values({
    id: nanoid(),
    competitionId: comp2.id,
    teamId: breakers.id,
    teamName: breakers.name,
    status: 'pending',
    homeVenue: breakers.homeVenue,
    roster: roster(breakers),
    createdAt: now,
    updatedAt: now,
  });
  await db.insert(teamMembers).values({
    id: nanoid(),
    competitionId: comp2.id,
    teamId: stars.id,
    teamName: stars.name,
    status: 'invited',
    homeVenue: stars.homeVenue,
    roster: roster(stars),
    createdAt: now,
    updatedAt: now,
  });
  await db.insert(teamMembers).values({
    id: nanoid(),
    competitionId: comp2.id,
    teamId: sharks.id,
    teamName: sharks.name,
    status: 'accepted',
    homeVenue: sharks.homeVenue,
    roster: roster(sharks),
    createdAt: now,
    updatedAt: now,
  });

  // =====================
  // MATCHES — Winter League (completed, 3 matches, full game + player IDs)
  // =====================
  const winterMatchDefs = [
    {
      round: 1, matchday: 1, home: breakers, away: sharks, date: '2025-11-04',
      status: 'completed' as const, hs: 2, as: 1,
      games: [
        { gameOrder: 1, homePlayerName: nameOf(toan), awayPlayerName: nameOf(sarah), homePlayerId: toan.id, awayPlayerId: sarah.id, homeScore: 1, awayScore: 0 },
        { gameOrder: 2, homePlayerName: nameOf(mike), awayPlayerName: nameOf(emma), homePlayerId: mike.id, awayPlayerId: emma.id, homeScore: 0, awayScore: 1 },
        { gameOrder: 3, homePlayerName: `${nameOf(toan)} & ${nameOf(mike)}`, awayPlayerName: `${nameOf(sarah)} & ${nameOf(emma)}`, homePlayerId: `${toan.id} & ${mike.id}`, awayPlayerId: `${sarah.id} & ${emma.id}`, homeScore: 1, awayScore: 0 },
      ],
    },
    {
      round: 2, matchday: 2, home: stars, away: breakers, date: '2025-11-11',
      status: 'completed' as const, hs: 1, as: 2,
      games: [
        { gameOrder: 1, homePlayerName: nameOf(lisa), awayPlayerName: nameOf(toan), homePlayerId: lisa.id, awayPlayerId: toan.id, homeScore: 0, awayScore: 1 },
        { gameOrder: 2, homePlayerName: nameOf(david), awayPlayerName: nameOf(mike), homePlayerId: david.id, awayPlayerId: mike.id, homeScore: 1, awayScore: 0 },
        { gameOrder: 3, homePlayerName: `${nameOf(lisa)} & ${nameOf(david)}`, awayPlayerName: `${nameOf(toan)} & ${nameOf(mike)}`, homePlayerId: `${lisa.id} & ${david.id}`, awayPlayerId: `${toan.id} & ${mike.id}`, homeScore: 0, awayScore: 1 },
      ],
    },
    {
      round: 3, matchday: 3, home: sharks, away: stars, date: '2025-11-18',
      status: 'completed' as const, hs: 2, as: 1,
      games: [
        { gameOrder: 1, homePlayerName: nameOf(sarah), awayPlayerName: nameOf(lisa), homePlayerId: sarah.id, awayPlayerId: lisa.id, homeScore: 1, awayScore: 0 },
        { gameOrder: 2, homePlayerName: nameOf(emma), awayPlayerName: nameOf(david), homePlayerId: emma.id, awayPlayerId: david.id, homeScore: 0, awayScore: 1 },
        { gameOrder: 3, homePlayerName: `${nameOf(sarah)} & ${nameOf(emma)}`, awayPlayerName: `${nameOf(lisa)} & ${nameOf(david)}`, homePlayerId: `${sarah.id} & ${emma.id}`, awayPlayerId: `${lisa.id} & ${david.id}`, homeScore: 1, awayScore: 0 },
      ],
    },
  ];

  for (const m of winterMatchDefs) {
    await db.insert(matches).values({
      id: nanoid(),
      competitionId: comp3.id,
      round: m.round,
      matchday: m.matchday,
      homeTeamId: m.home.id,
      awayTeamId: m.away.id,
      homeTeamName: m.home.name,
      awayTeamName: m.away.name,
      scheduledDate: m.date,
      venue: m.home.homeVenue,
      status: m.status,
      homeScore: m.hs,
      awayScore: m.as,
      games: m.games,
      submittedBy: toan.id,
      createdAt: now,
      updatedAt: now,
    });
  }

  // =====================
  // MATCHES — Spring League (4 completed, 1 pending_review, 1 scheduled)
  //   Game structure: Singles1(o1), Singles2(o2), Break(o3), Doubles(o4), Singles3(o5)
  // =====================
  const springMatchDefs = [
    // R1: Breakers 3-1 Legends (completed)
    {
      round: 1, matchday: 1, home: breakers, away: legends, date: '2026-04-01',
      status: 'completed' as const, hs: 3, as: 1,
      games: [
        { gameOrder: 1, homePlayerName: nameOf(toan), awayPlayerName: nameOf(jake), homePlayerId: toan.id, awayPlayerId: jake.id, homeScore: 1, awayScore: 0 },
        { gameOrder: 2, homePlayerName: nameOf(mike), awayPlayerName: nameOf(chris), homePlayerId: mike.id, awayPlayerId: chris.id, homeScore: 1, awayScore: 0 },
        { gameOrder: 4, homePlayerName: `${nameOf(toan)} & ${nameOf(mike)}`, awayPlayerName: `${nameOf(jake)} & ${nameOf(chris)}`, homePlayerId: `${toan.id} & ${mike.id}`, awayPlayerId: `${jake.id} & ${chris.id}`, homeScore: 0, awayScore: 1 },
        { gameOrder: 5, homePlayerName: nameOf(toan), awayPlayerName: nameOf(chris), homePlayerId: toan.id, awayPlayerId: chris.id, homeScore: 1, awayScore: 0 },
      ],
    },
    // R1: Sharks 2-2 Stars (completed, draw)
    {
      round: 1, matchday: 1, home: sharks, away: stars, date: '2026-04-01',
      status: 'completed' as const, hs: 2, as: 2,
      games: [
        { gameOrder: 1, homePlayerName: nameOf(sarah), awayPlayerName: nameOf(lisa), homePlayerId: sarah.id, awayPlayerId: lisa.id, homeScore: 1, awayScore: 0 },
        { gameOrder: 2, homePlayerName: nameOf(emma), awayPlayerName: nameOf(david), homePlayerId: emma.id, awayPlayerId: david.id, homeScore: 0, awayScore: 1 },
        { gameOrder: 4, homePlayerName: `${nameOf(sarah)} & ${nameOf(emma)}`, awayPlayerName: `${nameOf(lisa)} & ${nameOf(david)}`, homePlayerId: `${sarah.id} & ${emma.id}`, awayPlayerId: `${lisa.id} & ${david.id}`, homeScore: 1, awayScore: 0 },
        { gameOrder: 5, homePlayerName: nameOf(sarah), awayPlayerName: nameOf(david), homePlayerId: sarah.id, awayPlayerId: david.id, homeScore: 0, awayScore: 1 },
      ],
    },
    // R2: Breakers 4-0 Sharks (completed, dominant)
    {
      round: 2, matchday: 2, home: breakers, away: sharks, date: '2026-04-08',
      status: 'completed' as const, hs: 4, as: 0,
      games: [
        { gameOrder: 1, homePlayerName: nameOf(toan), awayPlayerName: nameOf(sarah), homePlayerId: toan.id, awayPlayerId: sarah.id, homeScore: 1, awayScore: 0 },
        { gameOrder: 2, homePlayerName: nameOf(mike), awayPlayerName: nameOf(emma), homePlayerId: mike.id, awayPlayerId: emma.id, homeScore: 1, awayScore: 0 },
        { gameOrder: 4, homePlayerName: `${nameOf(toan)} & ${nameOf(mike)}`, awayPlayerName: `${nameOf(sarah)} & ${nameOf(emma)}`, homePlayerId: `${toan.id} & ${mike.id}`, awayPlayerId: `${sarah.id} & ${emma.id}`, homeScore: 1, awayScore: 0 },
        { gameOrder: 5, homePlayerName: nameOf(toan), awayPlayerName: nameOf(emma), homePlayerId: toan.id, awayPlayerId: emma.id, homeScore: 1, awayScore: 0 },
      ],
    },
    // R2: Legends 1-3 Stars (completed)
    {
      round: 2, matchday: 2, home: legends, away: stars, date: '2026-04-08',
      status: 'completed' as const, hs: 1, as: 3,
      games: [
        { gameOrder: 1, homePlayerName: nameOf(jake), awayPlayerName: nameOf(lisa), homePlayerId: jake.id, awayPlayerId: lisa.id, homeScore: 0, awayScore: 1 },
        { gameOrder: 2, homePlayerName: nameOf(chris), awayPlayerName: nameOf(david), homePlayerId: chris.id, awayPlayerId: david.id, homeScore: 1, awayScore: 0 },
        { gameOrder: 4, homePlayerName: `${nameOf(jake)} & ${nameOf(chris)}`, awayPlayerName: `${nameOf(lisa)} & ${nameOf(david)}`, homePlayerId: `${jake.id} & ${chris.id}`, awayPlayerId: `${lisa.id} & ${david.id}`, homeScore: 0, awayScore: 1 },
        { gameOrder: 5, homePlayerName: nameOf(jake), awayPlayerName: nameOf(david), homePlayerId: jake.id, awayPlayerId: david.id, homeScore: 0, awayScore: 1 },
      ],
    },
    // R3: Breakers vs Stars — pending_review (Toan submitted, Lisa hasn't confirmed)
    {
      round: 3, matchday: 3, home: breakers, away: stars, date: '2026-04-15',
      status: 'pending_review' as const, hs: 3, as: 1,
      homeSubmission: JSON.stringify({
        homeScore: 3, awayScore: 1,
        games: [
          { gameOrder: 1, homePlayerName: nameOf(toan), awayPlayerName: nameOf(lisa), homePlayerId: toan.id, awayPlayerId: lisa.id, homeScore: 1, awayScore: 0 },
          { gameOrder: 2, homePlayerName: nameOf(mike), awayPlayerName: nameOf(david), homePlayerId: mike.id, awayPlayerId: david.id, homeScore: 1, awayScore: 0 },
          { gameOrder: 4, homePlayerName: `${nameOf(toan)} & ${nameOf(mike)}`, awayPlayerName: `${nameOf(lisa)} & ${nameOf(david)}`, homePlayerId: `${toan.id} & ${mike.id}`, awayPlayerId: `${lisa.id} & ${david.id}`, homeScore: 0, awayScore: 1 },
          { gameOrder: 5, homePlayerName: nameOf(toan), awayPlayerName: nameOf(david), homePlayerId: toan.id, awayPlayerId: david.id, homeScore: 1, awayScore: 0 },
        ],
        submittedBy: toan.id, submittedAt: now,
      }),
    },
    // R3: Sharks vs Legends — pending_review (disputed scores)
    {
      round: 3, matchday: 3, home: sharks, away: legends, date: '2026-04-15',
      status: 'pending_review' as const, hs: 0, as: 0,
      homeSubmission: JSON.stringify({
        homeScore: 2, awayScore: 1,
        submittedBy: sarah.id, submittedAt: now,
      }),
      awaySubmission: JSON.stringify({
        homeScore: 1, awayScore: 2,
        submittedBy: jake.id, submittedAt: now,
      }),
    },
  ];

  const createdSpringMatches = [];
  for (const m of springMatchDefs) {
    const match = await db.insert(matches).values({
      id: nanoid(),
      competitionId: comp.id,
      round: m.round,
      matchday: m.matchday,
      homeTeamId: m.home.id,
      awayTeamId: m.away.id,
      homeTeamName: m.home.name,
      awayTeamName: m.away.name,
      scheduledDate: m.date,
      venue: m.home.homeVenue,
      status: m.status,
      homeScore: m.hs,
      awayScore: m.as,
      games: 'games' in m ? (m as any).games : undefined,
      homeSubmission: 'homeSubmission' in m ? (m as any).homeSubmission : undefined,
      awaySubmission: 'awaySubmission' in m ? (m as any).awaySubmission : undefined,
      submittedBy: m.status === 'completed' ? toan.id : undefined,
      createdAt: now,
      updatedAt: now,
    }).returning().get();
    createdSpringMatches.push(match);
  }

  // =====================
  // TEAM INVITATIONS (player-to-team)
  // =====================
  await db.insert(teamInvitations).values({
    id: nanoid(),
    teamId: sharks.id,
    teamName: sharks.name,
    invitedUserId: toan.id,
    invitedEmail: toan.email,
    invitedByUserId: sarah.id,
    status: 'pending',
    createdAt: now,
    updatedAt: now,
  });

  // =====================
  // NOTIFICATIONS — cover all types for testing
  // =====================
  const notificationDefs = [
    // --- Toan (organizer + player) ---
    {
      userId: toan.id, type: 'competition_update',
      title: 'Competition Started',
      message: 'Spring League 2026 is now active!',
      read: true, referenceId: comp.id, referenceType: 'competition',
    },
    {
      userId: toan.id, type: 'match_result',
      title: 'Match Result',
      message: 'Bay City Breakers defeated Bay City Legends 3-1',
      read: true, referenceId: createdSpringMatches[0].id, referenceType: 'match',
    },
    {
      userId: toan.id, type: 'match_scheduled',
      title: 'Upcoming Match',
      message: 'Bay City Breakers vs Saginaw Stars on Apr 15, 2026',
      read: false, referenceId: createdSpringMatches[4].id, referenceType: 'match',
    },
    {
      userId: toan.id, type: 'team_invitation',
      title: 'Team Invitation',
      message: 'Sarah Chen invited you to join Midland Sharks',
      read: false, referenceId: sharks.id, referenceType: 'team',
    },
    {
      userId: toan.id, type: 'application_accepted',
      title: 'Application Accepted',
      message: 'Bay City Breakers has been accepted into Spring League 2026',
      read: false, referenceId: comp.id, referenceType: 'competition',
    },
    {
      userId: toan.id, type: 'competition_update',
      title: 'New Competition',
      message: 'Summer 8-Ball Classic 2026 is now accepting teams!',
      read: false, referenceId: comp2.id, referenceType: 'competition',
    },
    // Score submitted notification for organizer Toan (Breakers vs Stars)
    {
      userId: toan.id, type: 'score_submitted',
      title: 'Score Submitted',
      message: 'Score submitted for Bay City Breakers vs Saginaw Stars (3-1)',
      read: false, referenceId: createdSpringMatches[4].id, referenceType: 'match',
      metadata: JSON.stringify({
        matchId: createdSpringMatches[4].id,
        homeTeamName: 'Bay City Breakers', awayTeamName: 'Saginaw Stars',
        homeScore: 3, awayScore: 1, submitterName: nameOf(toan),
      }),
    },
    // Score disputed notification for organizer Toan (Sharks vs Legends)
    {
      userId: toan.id, type: 'score_disputed',
      title: 'Score Disputed',
      message: 'Midland Sharks vs Bay City Legends has conflicting score submissions. Please review.',
      read: false, referenceId: createdSpringMatches[5].id, referenceType: 'match',
      metadata: JSON.stringify({
        matchId: createdSpringMatches[5].id,
        homeTeamName: 'Midland Sharks', awayTeamName: 'Bay City Legends',
        homeSubmission: { homeScore: 2, awayScore: 1 },
        awaySubmission: { homeScore: 1, awayScore: 2 },
      }),
    },
    // --- Lisa (Stars captain) ---
    {
      userId: lisa.id, type: 'competition_invitation',
      title: 'Competition Invitation',
      message: 'Saginaw Stars has been invited to Summer 8-Ball Classic 2026',
      read: false, referenceId: comp2.id, referenceType: 'competition',
      metadata: JSON.stringify({
        teamId: stars.id, teamName: 'Saginaw Stars',
        competitionName: 'Summer 8-Ball Classic 2026',
      }),
    },
    // Score submitted for Lisa to confirm (Breakers vs Stars)
    {
      userId: lisa.id, type: 'score_submitted',
      title: 'Score Submitted',
      message: `${nameOf(toan)} submitted the score for Bay City Breakers vs Saginaw Stars (3-1). Please review and confirm.`,
      read: false, referenceId: createdSpringMatches[4].id, referenceType: 'match',
      metadata: JSON.stringify({
        matchId: createdSpringMatches[4].id,
        homeTeamName: 'Bay City Breakers', awayTeamName: 'Saginaw Stars',
        homeScore: 3, awayScore: 1, submitterName: nameOf(toan),
      }),
    },
    // --- Jake (Legends captain) ---
    {
      userId: jake.id, type: 'match_result',
      title: 'Match Result',
      message: 'Bay City Legends lost to Bay City Breakers 1-3',
      read: false, referenceId: createdSpringMatches[0].id, referenceType: 'match',
    },
    // --- Sarah (Sharks captain + organizer) ---
    {
      userId: sarah.id, type: 'match_result',
      title: 'Match Result',
      message: 'Midland Sharks drew with Saginaw Stars 2-2',
      read: false, referenceId: createdSpringMatches[1].id, referenceType: 'match',
    },
    {
      userId: sarah.id, type: 'competition_update',
      title: 'New Application',
      message: 'Bay City Breakers has applied to Summer 8-Ball Classic 2026',
      read: false, referenceId: comp2.id, referenceType: 'competition',
    },
  ];

  for (const n of notificationDefs) {
    await db.insert(notifications).values({
      id: nanoid(),
      ...n,
      actioned: false,
      createdAt: now - Math.floor(Math.random() * 86400000 * 7), // spread over last 7 days
      updatedAt: now,
    });
  }

  // =====================
  // COUNTRIES & CITIES
  // =====================
  await db.insert(countries).values({ code: 'VN', name: 'Vietnam', createdAt: now, updatedAt: now });
  await db.insert(countries).values({ code: 'US', name: 'United States', createdAt: now, updatedAt: now });

  const vnCities = [
    'Hanoi', 'Ho Chi Minh City', 'Da Nang', 'Hai Phong', 'Can Tho',
    'Nha Trang', 'Hue', 'Vung Tau', 'Quy Nhon', 'Da Lat',
    'Bien Hoa', 'Buon Ma Thuot', 'Thai Nguyen', 'Nam Dinh', 'Vinh',
    'Ha Long', 'Thanh Hoa', 'Rach Gia', 'Long Xuyen', 'Phan Thiet',
  ];
  for (const city of vnCities) {
    await db.insert(cities).values({
      id: nanoid(), name: city, countryCode: 'VN', createdAt: now, updatedAt: now,
    });
  }

  const usCities = ['Bay City', 'Midland', 'Saginaw', 'Detroit', 'Grand Rapids'];
  for (const city of usCities) {
    await db.insert(cities).values({
      id: nanoid(), name: city, countryCode: 'US', createdAt: now, updatedAt: now,
    });
  }

  return c.json({
    message: 'Database seeded successfully',
    users: createdUsers.length,
    teams: createdTeams.length,
    competitions: 4,
    springMatches: createdSpringMatches.length,
    winterMatches: winterMatchDefs.length,
    notifications: notificationDefs.length,
    countries: 2,
    cities: vnCities.length + usCities.length,
  });
});

export default seed;
