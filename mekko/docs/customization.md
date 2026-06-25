# Customization

*What* and *why* to change in the Twenty **source** for the Mekko CRM use case.
For *how to run / iterate / hot-reload* see **[`local-dev.md`](local-dev.md)**; for the
Docker/production side see [`deployment.md`](deployment.md); for data-only changes via the API
see [`data-setup.md`](data-setup.md).

> Branded as **Mekko CRM**. Customization was proven end-to-end on 2026-06-25:
> the sign-in heading was changed to "Welcome to Mekko CRM" and verified live via Playwright.

## First, pick the right route

Twenty has four customization surfaces. **Prefer the highest one in this table that can do
the job** — the lower you go, the more upstream-upgrade pain you take on. Forking the source
is the *last* resort, not the default.

| Route | Upgrade-safe? | Can add | Use when | Where |
|-------|---------------|---------|----------|-------|
| **1. Data setup (metadata API)** | ✅ | fields, objects, options, views | pure data-model changes | `.tools/twenty-setup` (see [`data-setup.md`](data-setup.md)) |
| **2. Build a Twenty App (SDK)** ⭐ | ✅ app stays separate, Twenty stays vanilla | objects, fields, **front components**, **page layouts/record pages**, nav & command-menu items, **logic functions** (serverless), workflows, roles, AI agents | most custom UI + logic + data | a separate app project (SDK basics below; the **product** built this way = the channel plugins, see [`channel-apps.md`](channel-apps.md)) |
| **3. Alongside service** | ✅ | its own UI / heavy compute / 3rd-party integrations (LinkedIn) | features that aren't *inside* Twenty | the separate SaaS (system of action) |
| **4. Fork the source** | ❌ permanent merge tax | literally anything | only changes to Twenty's **own built-in screens / core behavior** an App can't reach | edit `packages/`, rebuild — rest of this doc |

The sign-in heading was a route-4 change (it edits Twenty's built-in auth screen). That's the
*narrow* case forking is for. New features — custom objects with their own pages, dashboards,
automation — should be **route 2 (an App)**, which leaves the source untouched and upgrades cleanly.

## Route 2 — Build a Twenty App (the preferred route)

> This section covers the App SDK **basics + what we verified on our setup**. For the **product
> architecture** built on this route — per-channel plugins, the AI-agent automation systems, and
> per-client provisioning — see **[`channel-apps.md`](channel-apps.md)**. Keep product-specific
> app guidance there, not here, so the two don't drift.

Twenty ships an official **Applications** framework. An app is a **separate TypeScript project**
(not a fork) that declares entities and is synced/deployed into the workspace; it can be
versioned, upgraded, and even published to a marketplace.

Toolchain (all in this repo): `create-twenty-app` (scaffold) · `twenty-sdk` (CLI+SDK, replaces
the deprecated `twenty-cli`) · `twenty-client-sdk` (typed API client) · server `application`
core-module (install/manifest/upgrade/marketplace). Docs: `docs.twenty.com/developers/extend/apps`.

```bash
# Scaffold (point it at OUR self-hosted instance on :3900, not the default :2020)
npx create-twenty-app@latest my-app --url http://localhost:3900 --authentication-method apiKey
cd my-app
yarn twenty remote:add        # authenticate against the running stack (one-time, interactive)
yarn twenty dev               # live dev: edit entities, auto-generates the typed client
yarn twenty dev add           # scaffold an entity (object / field / front-component / logic-function / page-layout / view / workflow ...)
yarn twenty app deploy        # deploy the app into the workspace
```

An app can contribute: **objects, fields, views, front components, page layouts / record pages /
tabs, navigation & command-menu items, logic functions (serverless), workflows, roles, AI
agents, skills, connection providers**.

### Spike results — verified 2026-06-25 against our self-hosted `:3900`

A throwaway app (`create-twenty-app`) was scaffolded, built, and synced against the live
instance. Findings:

- ✅ **Framework is real and capable.** A fresh app ships `src/front-components/main-page.tsx`
  — a genuine React component (hooks, JSX, events) importing Twenty's design system
  (`twenty-sdk/ui`: `Avatar`, `Icon*`) — plus a page-layout and a nav-menu-item. **Custom UI
  without forking is a first-class, out-of-the-box capability.**
- ✅ **`dev:add` entity types:** `object, field, logicFunction, frontComponent, role, skill,
  agent, connectionProvider, view, viewField, navigationMenuItem, pageLayout, pageLayoutTab,
  commandMenuItem`.
- ✅ **Self-hosted auth works** via `remote:add --url http://localhost:3900 --api-key <key>`
  (reuses `.tools/twenty-setup/api-key.txt`). The existing key authenticates `valid`.
- ✅ **Build + register succeed** against our instance (`dev:build`, `dev --once`).
- ✅ **Windows path bug — RESOLVED (was the blocker).** Full deploy now works on native
  Windows: `dev --once` synced an app end-to-end (`✓ Synced (4 files)`, 6 metadata entities
  created — role, frontComponent, pageLayout, pageLayoutTab, pageLayoutWidget,
  navigationMenuItem). The bug was **two** path-normalization leaks in `twenty-sdk`, both fixed
  by converting `\` → `/`:
  1. **Upload** — `src/cli/utilities/api/file-api.ts` sends `filePath: builtHandlerPath`
     (backslashed). Error: *"filePath contains unsafe characters or path traversal."*
  2. **Manifest** — the manifest builder sets `sourceComponentPath`/`builtComponentPath` (front
     components) and `sourceHandlerPath`/`builtHandlerPath` (logic functions) from backslashed
     relative paths. Error: *"Built component path is invalid"* (`METADATA_VALIDATION_FAILED`).
  **Durable fix:** apply both normalizations and capture them with **`patch-package`** in the
  app project (re-applies on every `yarn install`), and/or upstream the one-liner to twentyhq.
  WSL2 also avoids it (POSIX paths) but isn't required now that the 2-point patch is proven.

**Gotchas:**
- OAuth auth fails (`Server does not expose a CLI client ID`) on our instance — **use `--api-key`**, not OAuth.
- `create-twenty-app`'s own `yarn install` fails because it runs `corepack enable` (needs admin).
  Workaround: skip it, then install manually with `corepack-bin` on PATH (see [`local-dev.md`](local-dev.md)).
- `app:install` requires the app to be **registered/synced first** (`dev --once` or `app:publish --private`), not a standalone step.

**Verdict:** route 2 works end-to-end on our self-hosted Windows setup once the 2-point
path patch is applied. It is the right primary surface for custom UI + logic + data. Make the
patch durable via `patch-package` in the real app repo before building plugins.

---

## Route 4 — Fork the source (last resort)

Everything below is for the narrow case where an App can't reach what you need (changing
Twenty's own built-in screens or core behavior). Keep these edits few, isolated, and logged.

## The customization loop

1. **Edit** the source under `packages/` (`twenty-front` for UI/copy, `twenty-server` for
   backend/logic).
2. **Iterate** — for frontend changes use the hot-reload dev server (`:3901`); see
   [`local-dev.md`](local-dev.md). Backend changes need an image rebuild.
3. **Deploy** — rebuild and recreate the app containers (serves on `:3900`):
   ```powershell
   cd twenty; docker compose up -d --build server worker
   ```
4. **Verify** what's actually rendered (see below), then **commit + push** (see Versioning).

## Verify the change — don't trust grep alone

The same UI string often appears in multiple branches/components. Confirm what is **actually
rendered**, not the first code match — load the page (Playwright or a browser) and assert the
text. See the Playwright tip in [`local-dev.md`](local-dev.md#verifying-a-running-change-playwright).

- Example gotcha: the active sign-in page is **`SignInUp.tsx` (V1)**, not `SignInUpV2.tsx`.
  Its heading came from the `` t`Welcome, ${workspaceName}.` `` branch (workspace name =
  "Mekko Digital"), **not** the `isGlobalScope` branch grep finds first.

## Migrations (backend/schema source changes)

If a change edits server entity files (new columns/objects in source rather than via the
API), Twenty generates a migration — see root `CLAUDE.md` (`database:migrate:generate`). The
first boot of the rebuilt image runs pending migrations automatically against the
`twenty_db-data` volume. **Back up the DB first** (see [`deployment.md`](deployment.md)) before
any schema change.

## Versioning

Our source history is the fork `github.com/tayyabulislam16/twenty`, on branch **`mekko-main`**
(not `main`). Commit and push customizations there:

```powershell
git add -A; git commit -m "..."; git push origin main:mekko-main
```

## Ideas backlog

_(add candidate customizations here as they come up)_

- [done] Brand sign-in heading → "Welcome to Mekko CRM".
