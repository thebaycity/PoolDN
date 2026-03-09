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

  // --- Users ---
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

  const createdUsers = [];
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

  // --- Organizers (Toan + Sarah) ---
  await db.insert(organizers).values({
    id: nanoid(),
    userId: toan.id,
    createdAt: now,
    updatedAt: now,
  });
  await db.insert(organizers).values({
    id: nanoid(),
    userId: sarah.id,
    createdAt: now,
    updatedAt: now,
  });

  // --- Teams ---
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

  // Build user ID → name map for roster names
  const userNameMap = new Map(createdUsers.map(u => [u.id, u.name]));

  // --- Competition 1: Active (Spring League 2026) ---
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

  // --- Competition 2: Upcoming (Summer 8-Ball Classic 2026) ---
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

  // --- Competition 3: Completed (Winter League 2025) ---
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

  // --- Competition 4: Draft (Fall 9-Ball Championship 2026) ---
  const comp4 = await db.insert(competitions).values({
    id: nanoid(),
    name: 'Fall 9-Ball Championship 2026',
    organizerId: toan.id,
    description: 'A competitive 9-ball championship for the fall season. Teams battle it out in a round-robin format.',
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

  // --- TeamMembers (Spring League) ---
  const allTeams = [breakers, sharks, stars, legends];
  const createdParticipations = [];
  for (const team of allTeams) {
    const p = await db.insert(teamMembers).values({
      id: nanoid(),
      competitionId: comp.id,
      teamId: team.id,
      teamName: team.name,
      status: 'accepted',
      homeVenue: team.homeVenue,
      roster: team.members.map(m => ({ playerId: m.playerId, name: userNameMap.get(m.playerId) ?? m.playerId })),
      createdAt: now,
      updatedAt: now,
    }).returning().get();
    createdParticipations.push(p);
  }

  // --- TeamMembers (Winter League - completed) ---
  const winterTeams = [breakers, sharks, stars];
  for (const team of winterTeams) {
    await db.insert(teamMembers).values({
      id: nanoid(),
      competitionId: comp3.id,
      teamId: team.id,
      teamName: team.name,
      status: 'accepted',
      homeVenue: team.homeVenue,
      roster: team.members.map(m => ({ playerId: m.playerId, name: userNameMap.get(m.playerId) ?? m.playerId })),
      createdAt: now,
      updatedAt: now,
    });
  }

  // --- TeamMembers (Summer Classic - upcoming: pending app + invite) ---
  await db.insert(teamMembers).values({
    id: nanoid(),
    competitionId: comp2.id,
    teamId: breakers.id,
    teamName: breakers.name,
    status: 'pending',
    homeVenue: breakers.homeVenue,
    roster: breakers.members.map(m => ({ playerId: m.playerId, name: m.playerId })),
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
    roster: stars.members.map(m => ({ playerId: m.playerId, name: m.playerId })),
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
    roster: sharks.members.map(m => ({ playerId: m.playerId, name: m.playerId })),
    createdAt: now,
    updatedAt: now,
  });

  // --- Matches (Winter League: 3-team round-robin, all completed) ---
  const winterMatchDefs = [
    {
      round: 1, matchday: 1, home: breakers, away: sharks, date: '2025-11-04',
      status: 'completed', hs: 2, as: 1,
      games: [
        { gameOrder: 1, homePlayerName: 'Toan Nguyen', awayPlayerName: 'Sarah Chen', homeScore: 1, awayScore: 0 },
        { gameOrder: 2, homePlayerName: 'Mike Johnson', awayPlayerName: 'Emma Wilson', homeScore: 0, awayScore: 1 },
        { gameOrder: 3, homePlayerName: 'Toan Nguyen & Mike Johnson', awayPlayerName: 'Sarah Chen & Emma Wilson', homeScore: 1, awayScore: 0 },
      ],
    },
    {
      round: 2, matchday: 2, home: stars, away: breakers, date: '2025-11-11',
      status: 'completed', hs: 1, as: 2,
      games: [
        { gameOrder: 1, homePlayerName: 'Lisa Park', awayPlayerName: 'Toan Nguyen', homeScore: 0, awayScore: 1 },
        { gameOrder: 2, homePlayerName: 'David Lee', awayPlayerName: 'Mike Johnson', homeScore: 1, awayScore: 0 },
        { gameOrder: 3, homePlayerName: 'Lisa Park & David Lee', awayPlayerName: 'Toan Nguyen & Mike Johnson', homeScore: 0, awayScore: 1 },
      ],
    },
    {
      round: 3, matchday: 3, home: sharks, away: stars, date: '2025-11-18',
      status: 'completed', hs: 2, as: 1,
      games: [
        { gameOrder: 1, homePlayerName: 'Sarah Chen', awayPlayerName: 'Lisa Park', homeScore: 1, awayScore: 0 },
        { gameOrder: 2, homePlayerName: 'Emma Wilson', awayPlayerName: 'David Lee', homeScore: 0, awayScore: 1 },
        { gameOrder: 3, homePlayerName: 'Sarah Chen & Emma Wilson', awayPlayerName: 'Lisa Park & David Lee', homeScore: 1, awayScore: 0 },
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

  // --- Matches (Spring League: 6 round-robin, 4 completed with games, 2 scheduled) ---
  const matchDefs = [
    {
      round: 1, matchday: 1, home: breakers, away: legends, date: '2026-04-01',
      status: 'completed', hs: 3, as: 1,
      games: [
        { gameOrder: 1, homePlayerName: 'Toan Nguyen', awayPlayerName: 'Jake Miller', homeScore: 1, awayScore: 0 },
        { gameOrder: 2, homePlayerName: 'Mike Johnson', awayPlayerName: 'Chris Brown', homeScore: 1, awayScore: 0 },
        { gameOrder: 4, homePlayerName: 'Toan Nguyen & Mike Johnson', awayPlayerName: 'Jake Miller & Chris Brown', homeScore: 0, awayScore: 1 },
        { gameOrder: 5, homePlayerName: 'Toan Nguyen', awayPlayerName: 'Chris Brown', homeScore: 1, awayScore: 0 },
      ],
    },
    {
      round: 1, matchday: 1, home: sharks, away: stars, date: '2026-04-01',
      status: 'completed', hs: 2, as: 2,
      games: [
        { gameOrder: 1, homePlayerName: 'Sarah Chen', awayPlayerName: 'Lisa Park', homeScore: 1, awayScore: 0 },
        { gameOrder: 2, homePlayerName: 'Emma Wilson', awayPlayerName: 'David Lee', homeScore: 0, awayScore: 1 },
        { gameOrder: 4, homePlayerName: 'Sarah Chen & Emma Wilson', awayPlayerName: 'Lisa Park & David Lee', homeScore: 1, awayScore: 0 },
        { gameOrder: 5, homePlayerName: 'Sarah Chen', awayPlayerName: 'David Lee', homeScore: 0, awayScore: 1 },
      ],
    },
    {
      round: 2, matchday: 2, home: breakers, away: sharks, date: '2026-04-08',
      status: 'completed', hs: 4, as: 0,
      games: [
        { gameOrder: 1, homePlayerName: 'Toan Nguyen', awayPlayerName: 'Sarah Chen', homeScore: 1, awayScore: 0 },
        { gameOrder: 2, homePlayerName: 'Mike Johnson', awayPlayerName: 'Emma Wilson', homeScore: 1, awayScore: 0 },
        { gameOrder: 4, homePlayerName: 'Toan Nguyen & Mike Johnson', awayPlayerName: 'Sarah Chen & Emma Wilson', homeScore: 1, awayScore: 0 },
        { gameOrder: 5, homePlayerName: 'Toan Nguyen', awayPlayerName: 'Emma Wilson', homeScore: 1, awayScore: 0 },
      ],
    },
    {
      round: 2, matchday: 2, home: legends, away: stars, date: '2026-04-08',
      status: 'completed', hs: 1, as: 3,
      games: [
        { gameOrder: 1, homePlayerName: 'Jake Miller', awayPlayerName: 'Lisa Park', homeScore: 0, awayScore: 1 },
        { gameOrder: 2, homePlayerName: 'Chris Brown', awayPlayerName: 'David Lee', homeScore: 1, awayScore: 0 },
        { gameOrder: 4, homePlayerName: 'Jake Miller & Chris Brown', awayPlayerName: 'Lisa Park & David Lee', homeScore: 0, awayScore: 1 },
        { gameOrder: 5, homePlayerName: 'Jake Miller', awayPlayerName: 'David Lee', homeScore: 0, awayScore: 1 },
      ],
    },
    // Round 3: Breakers vs Stars — pending_review (Toan submitted, Lisa hasn't yet)
    {
      round: 3, matchday: 3, home: breakers, away: stars, date: '2026-04-15',
      status: 'pending_review', hs: 3, as: 1,
      homeSubmission: JSON.stringify({
        homeScore: 3, awayScore: 1,
        submittedBy: toan.id, submittedAt: now,
      }),
      awaySubmission: undefined,
    },
    // Round 3: Sharks vs Legends — pending_review (disputed: both submitted different scores)
    {
      round: 3, matchday: 3, home: sharks, away: legends, date: '2026-04-15',
      status: 'pending_review', hs: 0, as: 0,
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

  const createdMatches = [];
  for (const m of matchDefs) {
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
      games: 'games' in m ? m.games : undefined,
      homeSubmission: 'homeSubmission' in m ? m.homeSubmission : undefined,
      awaySubmission: 'awaySubmission' in m ? m.awaySubmission : undefined,
      submittedBy: m.status === 'completed' ? toan.id : undefined,
      createdAt: now,
      updatedAt: now,
    }).returning().get();
    createdMatches.push(match);
  }

  // --- Pending team invitation for Toan (from Midland Sharks) ---
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

  // --- Notifications (all types for Toan) ---
  const notificationDefs = [
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
      read: true, referenceId: createdMatches[0].id, referenceType: 'match',
    },
    {
      userId: toan.id, type: 'match_scheduled',
      title: 'Upcoming Match',
      message: 'Bay City Breakers vs Saginaw Stars on Apr 15, 2026',
      read: false, referenceId: createdMatches[4].id, referenceType: 'match',
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
    // Competition invitation for Lisa (Stars captain) with metadata
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
    // Notifications for other players
    {
      userId: jake.id, type: 'match_result',
      title: 'Match Result',
      message: 'Bay City Legends lost to Bay City Breakers 1-3',
      read: false, referenceId: createdMatches[0].id, referenceType: 'match',
    },
    {
      userId: sarah.id, type: 'match_result',
      title: 'Match Result',
      message: 'Midland Sharks drew with Saginaw Stars 2-2',
      read: false, referenceId: createdMatches[1].id, referenceType: 'match',
    },
    // Sarah gets notification about Breakers pending application
    {
      userId: sarah.id, type: 'competition_update',
      title: 'New Application',
      message: 'Bay City Breakers has applied to Summer 8-Ball Classic 2026',
      read: false, referenceId: comp2.id, referenceType: 'competition',
    },
    // Score submitted: Lisa needs to confirm (Toan submitted Breakers vs Stars)
    {
      userId: lisa.id, type: 'score_submitted',
      title: 'Score Submitted',
      message: 'Toan Nguyen submitted the score for Bay City Breakers vs Saginaw Stars (3-1). Please review and confirm.',
      read: false, referenceId: createdMatches[4].id, referenceType: 'match',
      metadata: JSON.stringify({
        matchId: createdMatches[4].id,
        homeTeamName: 'Bay City Breakers', awayTeamName: 'Saginaw Stars',
        homeScore: 3, awayScore: 1, submitterName: 'Toan Nguyen',
      }),
    },
    // Score submitted: organizer (Toan) gets notified about Breakers vs Stars submission
    {
      userId: toan.id, type: 'score_submitted',
      title: 'Score Submitted',
      message: 'Score submitted for Bay City Breakers vs Saginaw Stars (3-1)',
      read: false, referenceId: createdMatches[4].id, referenceType: 'match',
      metadata: JSON.stringify({
        matchId: createdMatches[4].id,
        homeTeamName: 'Bay City Breakers', awayTeamName: 'Saginaw Stars',
        homeScore: 3, awayScore: 1, submitterName: 'Toan Nguyen',
      }),
    },
    // Score disputed: organizer (Toan) must resolve Sharks vs Legends
    {
      userId: toan.id, type: 'score_disputed',
      title: 'Score Disputed',
      message: 'Midland Sharks vs Bay City Legends has conflicting score submissions. Please review.',
      read: false, referenceId: createdMatches[5].id, referenceType: 'match',
      metadata: JSON.stringify({
        matchId: createdMatches[5].id,
        homeTeamName: 'Midland Sharks', awayTeamName: 'Bay City Legends',
        homeSubmission: { homeScore: 2, awayScore: 1 },
        awaySubmission: { homeScore: 1, awayScore: 2 },
      }),
    },
  ];

  for (const n of notificationDefs) {
    await db.insert(notifications).values({
      id: nanoid(),
      ...n,
      createdAt: now,
      updatedAt: now,
    });
  }

  // --- Countries & Cities ---
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
    teamMembers: createdParticipations.length + 3 + 3,
    matches: winterMatchDefs.length + matchDefs.length,
    notifications: notificationDefs.length,
    countries: 2,
    cities: vnCities.length + usCities.length,
  });
});

export default seed;
