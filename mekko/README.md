# Mekko — project workflow

**Read this before the root `CLAUDE.md`.** The root `CLAUDE.md` and `.cursor/rules/`
are inherited verbatim from upstream Twenty and describe *contributing to the Twenty
CRM open-source project*. That is **not** what this repo is for.

## What this repo actually is

A self-hosted **fork/deployment of Twenty CRM**, run as a personal CRM for
**LinkedIn relationship tracking + job-hunt management**, branded as **Mekko CRM**.

The real work here is three things:

1. **Deployment** — running Twenty from local source via Docker (`mekko-twenty` image).
2. **Data setup** — seeding people / companies / opportunities through the API.
3. **Customization** — editing the Twenty source (fields, objects, UI) for our use case.
   *(Being planned separately — see `docs/customization.md`.)*

We are **building and customizing the app**, not shipping changes back upstream. Ignore
upstream-contribution guidance (changelog process, CLA, PR conventions to twentyhq)
unless explicitly asked.

## The two layers, kept separate

| Layer | Lives in | Touch it? |
|-------|----------|-----------|
| Upstream Twenty source | `packages/`, root `CLAUDE.md`, `.cursor/rules/`, `twenty-claude-skills/` | Only when customizing the app — never for "tidying" |
| **Our deployment + workflow** | `mekko/`, `twenty/`, `.tools/twenty-setup/`, `.claude/skills/` | Freely |

## Docs

- [`docs/deployment.md`](docs/deployment.md) — Docker stack, building the `mekko-twenty` image, env, backups.
- [`docs/data-setup.md`](docs/data-setup.md) — the `.tools/twenty-setup/` API toolkit (key extraction, metadata, seeding).
- [`docs/customization.md`](docs/customization.md) — editing Twenty source: frontend hot-reload dev (`dev-frontend.ps1`, Vite on :3001), Windows build gotchas, deploy + verify loop.

## Conventions for Claude

- The upstream dev commands in root `CLAUDE.md` (`yarn start`, `npx nx ...`) apply **only**
  when we are customizing the Twenty source — not for running our deployment.
- To run the deployed app, use Docker from `twenty/` (see `docs/deployment.md`), not `yarn start`.
- The read-only Postgres MCP server (`.mcp.json`) is the way to inspect live CRM data.
- Treat `twenty/.env`, `twenty/backups/`, and `.tools/twenty-setup/api-key.txt` as secrets —
  never paste their contents into commits, PRs, or external services.
