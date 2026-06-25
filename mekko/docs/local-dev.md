# Local dev & running the app

How to run Mekko CRM locally and iterate on the frontend with hot reload. For the
Docker/production side see [`deployment.md`](deployment.md); for *what* to change in the
source see [`customization.md`](customization.md).

## Fixed ports — DO NOT CHANGE

We deliberately avoid the common `3000`/`3001` (other projects squat on them). Our ports
are **fixed** so that multiple agents/sessions all hit the **same** running server:

| Port | What | URL |
|------|------|-----|
| **3900** | Backend (Docker server — the deployed app) | http://localhost:3900 |
| **3901** | Frontend dev server (Vite, hot reload) | http://localhost:3901 |

> **Rule for agents:** treat `http://localhost:3900` as the canonical app URL. **Do not
> change it**, and do not start the app on a different port — another agent may already be
> working against `:3900`. If a port is genuinely occupied, increment (3902, 3903 …) **and
> update the config consistently** (below), but prefer leaving it fixed.

These ports are wired in three places (keep them in sync if you ever must change them):

- `twenty/.env` → `SERVER_URL=http://localhost:3900`
- `twenty/docker-compose.override.yml` → `ports: !override ["3900:3000"]` (replaces the base
  `3000:3000` so 3000 is never exposed)
- `packages/twenty-front/.env` → `REACT_APP_SERVER_BASE_URL=http://localhost:3900`
- `dev-frontend.ps1` → `vite --port 3901 --strictPort`

## Two ways to run — use the right one

| Mode | URL | Use for | Hot reload? |
|------|-----|---------|-------------|
| **Production image** | http://localhost:3900 | What we deploy; **backend** changes | ❌ rebuild the image |
| **Dev server (Vite)** | http://localhost:3901 | Iterating on **frontend** source | ✅ ~1s, no rebuild |

The dev server only does fast **frontend** iteration; it still uses the **real backend in
Docker** on `:3900`, so the backend must be up first.

## Run it

```powershell
# 1. Backend (once per session) — serves the app on http://localhost:3900
cd twenty; docker compose up -d

# 2. Frontend hot-reload dev server — http://localhost:3901
.\dev-frontend.ps1

# 3. Edit packages/twenty-front/src/** -> browser updates in ~1s, no rebuild
```

To **deploy** a change (frontend or backend), rebuild the image — see
[`deployment.md`](deployment.md): `cd twenty; docker compose up -d --build server worker`.

### Hot reload is frontend-only
Backend changes (`packages/twenty-server`, etc.) are **not** picked up by Vite — they need an
image rebuild. No server watch-mode is wired up yet.

## Why the dev server needs our env injection

`packages/twenty-front/src/config/index.ts` resolves the backend URL as
`window._env_?.REACT_APP_SERVER_BASE_URL || getDefaultUrl()`, and `getDefaultUrl()`
**hardcodes `localhost:3000` in dev**. In production the Docker entrypoint fills
`window._env_`; in a plain Vite dev server nothing does, so without help the frontend would
look for the backend on `:3000` (wrong — ours is `:3900`) and show *"Unable to Reach Back-end."*

Fix (already in place): a **dev-only** Vite plugin `mekko-dev-env-inject` in
`packages/twenty-front/vite.config.ts` (`apply: 'serve'`) injects `window._env_` from
`packages/twenty-front/.env`. So **`.env` is authoritative in dev**; the production build is
untouched (`apply: 'serve'`). Don't remove the plugin or the `.env`.

## Windows environment (this repo is developed on Windows native)

Twenty's tooling assumes Linux/macOS — the setup below is the working Windows config. Don't
"fix" it back to upstream defaults.

- **Yarn 4 / nx** via corepack in a **user-writable** dir: `C:\Users\tayyab\corepack-bin`
  (added to PATH by `dev-frontend.ps1`). `corepack enable` (global) and `npm config set …`
  need admin and were **avoided** — don't run them.
- **First-time setup** (already done; only if `node_modules` is missing):
  ```powershell
  corepack enable --install-directory C:\Users\tayyab\corepack-bin
  $env:Path = "C:\Users\tayyab\corepack-bin;$env:Path"
  yarn install            # ~10 min, large
  ```
- **Unix-only build scripts break on cmd.** Single-quoted globs like `rimraf 'dist/**/*.d.ts'`
  pass the quotes literally on Windows → *"Illegal characters in path."* We patched
  `packages/twenty-sdk/project.json` to `rimraf --glob dist/…`. Apply the same fix if you hit
  it elsewhere.
- **`.d.ts` declaration steps may still error** (e.g. implicit-`any` in upstream). **Harmless
  for running** — Vite emits the runtime JS before that step. Dev server and Docker image both
  work without it.
- **`npx vite` vs `nx start twenty-front`.** `nx start` builds all dependent workspace packages
  first; one broken `.d.ts` step makes nx abort the whole chain, so `dev-frontend.ps1` runs
  `npx vite` directly. The catch: Vite must still **resolve** workspace packages, so their
  `dist/` must exist. If Vite reports a package "could not be resolved" (e.g.
  `twenty-front-component-renderer`), build it once then restart the dev server:
  ```powershell
  npx nx build twenty-front-component-renderer    # also builds twenty-sdk
  ```

## Verifying a running change (Playwright)

Don't trust grep — confirm what is **actually rendered**. A throwaway Playwright script that
navigates to the URL (`:3900` for prod, `:3901` for dev) and asserts the expected text is the
fastest reliable check. Example gotcha: the active sign-in page is `SignInUp.tsx` (V1), and its
heading comes from the `` t`Welcome, ${workspaceName}.` `` branch — **not** the `isGlobalScope`
branch grep finds first.
