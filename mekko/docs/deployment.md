# Deployment

We run Twenty from **our local source**, not the published `twentycrm/twenty:latest` image.

## How it's wired

Everything lives in [`twenty/`](../../twenty/):

- `docker-compose.yml` — the standard Twenty stack (server, worker, db/Postgres, redis), copied from `packages/twenty-docker`.
- `docker-compose.override.yml` — **ours**. Auto-loaded by `docker compose` when run from `twenty/`. It overrides the `server` and `worker` services to build the **`mekko-twenty:latest`** image from local source:
  - build context: repo root (`..`)
  - dockerfile: `packages/twenty-docker/twenty/Dockerfile`, target `twenty`
- `docker-compose.override.yml` also pins the host port: `ports: !override ["3900:3000"]`, so the app is exposed on **3900**, not the common 3000. This URL is fixed — see [`local-dev.md`](local-dev.md). Don't change it.
- `.env` — secrets and config (`SERVER_URL=http://localhost:3900`, local file storage, encryption key, PG password). **Secret — do not commit contents.**
- `backups/` — database backups. Treat as precious.

Because the override builds from `packages/`, **any change you make to the Twenty source
is picked up on the next image rebuild** — that's the loop for customization.

## Commands

Always run from the `twenty/` directory so the override is applied automatically.

```bash
cd twenty

# Build the mekko-twenty image from local source + start the stack
docker compose up -d --build

# Start without rebuilding (use the existing image)
docker compose up -d

# After editing Twenty source: rebuild and recreate just the app containers
docker compose up -d --build server worker

# Tail logs
docker compose logs -f server

# Stop the stack (keeps data volumes)
docker compose down

# DANGER: 'docker compose down -v' deletes Postgres/Redis volumes — back up first.

# Status
docker compose ps
```

App is served at **http://localhost:3900** (fixed — see [`local-dev.md`](local-dev.md); do not change). Sign-in heading is branded "Welcome to Mekko CRM".

## Notes

- First boot runs DB migrations automatically inside the server container.
- `docker-fix-install.ps1` (repo root) is a Windows helper to reinstall Docker Desktop if the daemon is broken — not part of normal operation.
- Back up before destructive ops: dump the `db` service or copy `backups/` before `down -v` or a DB reset.

## When this is NOT the right tool

If the task is editing **frontend** source in a tight loop, use the Vite hot-reload dev server
instead of rebuilding the image each time — see [`local-dev.md`](local-dev.md). Use Docker for
running the actual deployment and for backend changes.
