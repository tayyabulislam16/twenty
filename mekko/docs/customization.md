# Customization

How to change the Twenty **source** (UI, logic, fields, objects) for the Mekko CRM
use case, run it with fast feedback, and deploy it. For the Docker/production side
see [`deployment.md`](deployment.md); for data-only changes via the API see
[`data-setup.md`](data-setup.md).

> Branded as **Mekko CRM**. Customization was proven end-to-end on 2026-06-25:
> the sign-in heading was changed to "Welcome to Mekko CRM" and verified live via Playwright.

## First, pick the right route

| If you can achieve it by… | Do it as… | Where |
|---------------------------|-----------|-------|
| Adding fields / objects / options through the metadata API | **Data setup** — no source edit | `.tools/twenty-setup` (see `data-setup.md`) |
| Changing UI, copy, business logic, or built-in behavior | **Source customization** — edit `packages/`, rebuild | this doc |

Prefer the API route when it's enough — it survives upstream upgrades far more cleanly
than a source fork.

## Two ways to run the app — use the right one for the task

| Mode | URL | Use for | Hot reload? |
|------|-----|---------|-------------|
| **Dev server (Vite)** | http://localhost:3001 | Iterating on **frontend** source (`packages/twenty-front`) | ✅ ~1s, no rebuild |
| **Production image** | http://localhost:3000 | What we actually deploy; **backend** changes | ❌ rebuild the image |

The dev server is *only* for fast frontend iteration. It still talks to the **real
backend running in Docker** on `:3000` (configured in `packages/twenty-front/.env` →
`REACT_APP_SERVER_BASE_URL=http://localhost:3000`), so the backend stack must be up.

## Frontend hot-reload dev workflow

```powershell
# 1. Backend must be running (once per session)
cd twenty; docker compose up -d

# 2. From the repo root, start the hot-reload frontend
.\dev-frontend.ps1            # Vite on http://localhost:3001

# 3. Edit any file under packages/twenty-front/src/** -> browser updates in ~1s
```

`dev-frontend.ps1` just prepends the Yarn install dir to PATH and runs `npx vite`
directly (deliberately bypassing `nx start`, see gotchas). When done iterating, **deploy**
the change by rebuilding the image — see [`deployment.md`](deployment.md):

```powershell
cd twenty; docker compose up -d --build server worker
```

### Hot reload is frontend-only
Changes to `packages/twenty-server` (or any backend package) are **not** picked up by the
Vite dev server — they require an image rebuild. There is no server watch-mode wired up yet.

## Windows environment (important — this repo is developed on Windows native)

Twenty's tooling assumes Linux/macOS. The setup below is the working Windows config; don't
"fix" it back to the upstream defaults.

- **Yarn 4 / nx** are installed via corepack to a **user-writable** dir:
  `C:\Users\tayyab\corepack-bin` (added to PATH by `dev-frontend.ps1`).
  `corepack enable` (global) and `npm config set ...` need admin and were **avoided** —
  don't run them.
- **First-time dev setup** (already done; only if `node_modules` is missing):
  ```powershell
  corepack enable --install-directory C:\Users\tayyab\corepack-bin
  $env:Path = "C:\Users\tayyab\corepack-bin;$env:Path"
  yarn install            # ~10 min, large
  ```
- **Unix-only build scripts break on cmd.** Several `package`/`project.json` scripts use
  single-quoted globs (e.g. `rimraf 'dist/**/*.d.ts'`). On Windows the quotes are passed
  literally → *"Illegal characters in path."* We patched `packages/twenty-sdk/project.json`
  to `rimraf --glob dist/...` (no quotes). If you hit the same error elsewhere, apply the
  same fix.
- **`.d.ts` declaration steps may still error** (e.g. implicit-`any` in upstream source).
  This is **harmless for running the app** — the runtime JS is already emitted by Vite
  before the declaration step. The dev server and the Docker image both work without it.
- **`npx vite` vs `nx start twenty-front`.** `nx start` first builds all dependent workspace
  packages; one broken `.d.ts` step makes nx abort the whole chain. Running `npx vite`
  directly skips that. The catch: Vite must still **resolve** workspace packages, so their
  `dist/` must exist. If Vite reports a package "could not be resolved" (e.g.
  `twenty-front-component-renderer`), build it once:
  ```powershell
  npx nx build twenty-front-component-renderer    # also builds twenty-sdk
  ```
  then restart the dev server.

## Verify the change — don't trust grep alone

The same UI string often appears in multiple branches/components. Confirm what is **actually
rendered**, not the first code match:

- The active sign-in page is **`SignInUp.tsx` (V1)**, not `SignInUpV2.tsx`. Its heading came
  from the `` t`Welcome, ${workspaceName}.` `` branch (workspace name = "Mekko Digital"),
  **not** the `isGlobalScope` branch that grep finds first.
- Verify by loading the page (Playwright or a browser) and asserting the rendered text.
  A throwaway Playwright script that navigates to the URL and checks for the expected
  string is the fastest reliable check.

## Migrations (backend/schema source changes)

If a change edits server entity files (new columns/objects in source rather than via the
API), Twenty generates a migration — see root `CLAUDE.md`
(`database:migrate:generate`). The first boot of the rebuilt image runs pending migrations
automatically against the `twenty_db-data` volume. **Back up the DB first** (see
`deployment.md`) before any schema change.

## Versioning

Our source history is the fork `github.com/tayyabulislam16/twenty`, on branch **`mekko-main`**
(not `main`). Commit and push customizations there:

```powershell
git add -A; git commit -m "..."; git push origin main:mekko-main
```

## Ideas backlog

_(add candidate customizations here as they come up)_

- [done] Brand sign-in heading → "Welcome to Mekko CRM".
