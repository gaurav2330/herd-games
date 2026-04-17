# Herd 🎮

A private multiplayer party games web app for friend groups. Play games together, track scores, and settle who's actually the best.

## What is Herd?

Herd is a game night platform built for small friend groups. Create a squad, spin up a room, and play together — all in one place. No downloads, no subscriptions, just games.

V1 ships with **Skribbl** — a drawing and guessing game. More games coming.

---

## Features

- **Squads** — Create a persistent friend group. Your squad, your history.
- **Rooms** — Spin up a game room, share the code, everyone joins.
- **Skribbl** — Live drawing canvas, real-time guessing, round timers.
- **Leaderboard** — Scores tracked across every session. Bragging rights included.
- **Persistent identity** — Log in, see your stats, know who owes who a rematch.

---

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Rails 8 |
| Language | Ruby 3.3.7 |
| WebSockets | Action Cable + Solid Cable |
| Frontend | Hotwire + Stimulus + Vanilla JS |
| Background Jobs | Solid Queue |
| Cache | Solid Cache |
| Auth | Rails 8 built-in auth generator |
| Database | PostgreSQL |
| Deployment | Kamal on Hetzner VPS |
| CI/CD | GitHub Actions |

---

## Data Models

```
User
Squad
SquadMembership
Game
Room
RoomMembership
Round
Turn
Score (polymorphic — belongs to Turn or Round)
```

---

## Getting Started

### Prerequisites
- Ruby 3.3.7
- PostgreSQL
- Rails 8

### Setup

```bash
# clone the repo
git clone https://github.com/yourusername/herd.git
cd herd

# install dependencies
bundle install

# setup database
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed

# start the server
bin/rails server
```

Open `localhost:3000` and you're good to go.

---

## Game: Skribbl

- One player draws, others guess
- 3 words to choose from, 10 seconds to pick
- 80 seconds per turn, 8 rounds per game
- Points for guessing fast, points for others guessing your drawing
- Scores tracked per turn and per round

---

## Roadmap

### V1 (current)
- [x] Auth
- [x] Squads
- [ ] Rooms
- [ ] Skribbl game
- [ ] Leaderboard

### V2
- [ ] Trivia game
- [ ] Word games
- [ ] Cross-room leaderboard
- [ ] Per-user stats and profiles

---

## Contributing

This is a personal side project. PRs welcome from friends.

---

## License

MIT