# Seed Data Reference

Run: `curl -X POST http://localhost:8787/seed`

All accounts use password: **`password123`**

---

## Accounts

| Email | Name | Role | Captain of | Also on |
|-------|------|------|------------|---------|
| toan@thebay.city | Toan Nguyen | **organizer** | Bay City Breakers | - |
| sarah@thebay.city | Sarah Chen | **organizer** | Midland Sharks | - |
| mike@thebay.city | Mike Johnson | player | - | Bay City Breakers |
| jake@thebay.city | Jake Miller | player | Bay City Legends | - |
| lisa@thebay.city | Lisa Park | player | Saginaw Stars | - |
| chris@thebay.city | Chris Brown | player | - | Bay City Legends |
| emma@thebay.city | Emma Wilson | player | - | Midland Sharks |
| david@thebay.city | David Lee | player | - | Saginaw Stars |

---

## Teams

| Team | Captain | Member | Home Venue | City |
|------|---------|--------|------------|------|
| Bay City Breakers | Toan Nguyen | Mike Johnson | Elbow Room | Bay City |
| Midland Sharks | Sarah Chen | Emma Wilson | Shark's Pool Hall | Midland |
| Saginaw Stars | Lisa Park | David Lee | Star Lanes | Saginaw |
| Bay City Legends | Jake Miller | Chris Brown | Legends Bar | Bay City |

---

## Competitions

### 1. Spring League 2026 — `active`
- **Organizer**: Toan Nguyen
- **Game**: 8-ball, round robin, team venues, Wednesdays
- **Teams**: All 4 accepted
- **Matches**: 6 total (4-team round robin)
  - Round 1: Breakers 3-1 Legends (completed), Sharks 2-2 Stars (completed)
  - Round 2: Breakers 4-0 Sharks (completed), Legends 1-3 Stars (completed)
  - Round 3: Breakers vs Stars — **pending_review** (Toan submitted 3-1, Lisa hasn't confirmed)
  - Round 3: Sharks vs Legends — **pending_review / disputed** (Sarah submitted 2-1, Jake submitted 1-2)

### 2. Summer 8-Ball Classic 2026 — `upcoming`
- **Organizer**: Sarah Chen
- **Game**: 8-ball, round robin, central venue (Bay City Recreation Center), Thursdays
- **Teams**:
  - Midland Sharks — accepted
  - Saginaw Stars — **invited** (Lisa has competition_invitation notification)
  - Bay City Breakers — **pending** application

### 3. Winter League 2025 — `completed`
- **Organizer**: Toan Nguyen
- **Game**: 9-ball, round robin, team venues, Tuesdays
- **Teams**: Breakers, Sharks, Stars (3-team round robin)
- **Results**: Breakers 2-1 Sharks, Stars 1-2 Breakers, Sharks 2-1 Stars

---

## Team Invitation

- Sarah Chen invited **Toan** to join Midland Sharks (pending)

---

## Notifications

### Toan (toan@thebay.city)
| Type | Title | Read | Notes |
|------|-------|------|-------|
| competition_update | Competition Started | yes | Spring League active |
| match_result | Match Result | yes | Breakers 3-1 Legends |
| match_scheduled | Upcoming Match | no | Breakers vs Stars Apr 15 |
| team_invitation | Team Invitation | no | Sarah invited to Sharks |
| application_accepted | Application Accepted | no | Breakers into Spring League |
| competition_update | New Competition | no | Summer Classic announced |
| score_submitted | Score Submitted | no | Breakers vs Stars 3-1 (metadata) |
| score_disputed | Score Disputed | no | Sharks vs Legends conflicting scores (metadata) |

### Lisa (lisa@thebay.city)
| Type | Title | Read | Notes |
|------|-------|------|-------|
| competition_invitation | Competition Invitation | no | Stars invited to Summer Classic (metadata: teamId, teamName, competitionName) |
| score_submitted | Score Submitted | no | Toan submitted Breakers vs Stars 3-1, needs Lisa to confirm (metadata) |

### Jake (jake@thebay.city)
| Type | Title | Read | Notes |
|------|-------|------|-------|
| match_result | Match Result | no | Legends lost to Breakers 1-3 |

### Sarah (sarah@thebay.city)
| Type | Title | Read | Notes |
|------|-------|------|-------|
| match_result | Match Result | no | Sharks drew Stars 2-2 |
| competition_update | New Application | no | Breakers applied to Summer Classic |

---

## Testing Scenarios

**Login as Toan** — sees organizer view of Spring League, pending_review matches, score_submitted + score_disputed notifications, team invitation from Sarah

**Login as Lisa** — sees captain view with competition invitation for Stars to Summer Classic, score_submitted notification prompting confirmation

**Login as Sarah** — sees organizer view of Summer Classic with segmented tabs (Accepted/Invited/Pending), Breakers application to accept/reject

**Login as Jake** — sees player view, match result notification
