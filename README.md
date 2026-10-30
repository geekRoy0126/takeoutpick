# TakeoutPick

Decide what takeout to order in seconds, by true total cost (deals, fees, tip, tax), health level and variety.
Course Project 2 (CS6983 AI Coding, Fall 2026): Diner, Partner and Admin roles, real-time Group Pick rooms and a public REST API.

- Product requirements: [docs/PRD.md](docs/PRD.md) · UI spec: [docs/ui-spec.md](docs/ui-spec.md)
- Rules for AI agents and humans: [AGENTS.md](AGENTS.md)

## Local setup

```bash
npm install                      # also generates the Prisma client
cp .env.example .env             # then set JWT_SECRET
docker compose up -d db          # local Postgres 16
npm run db:migrate               # create tables
npm run dev                      # http://localhost:3000
```

## Tests

| Command | What |
| --- | --- |
| `npm test` | Unit tests (Vitest + Testing Library) |
| `npm run test:int` | Integration tests against the local database |
| `npm run test:e2e` | Playwright, desktop + mobile (`npx playwright install` once) |
| `npm run test:coverage` | Unit coverage; `src/lib/domain` must stay at 80% or above |

Full README, diagrams and deployment guide: issue #14.
