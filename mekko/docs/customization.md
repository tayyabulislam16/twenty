# Customization

*What* and *why* to change in the Twenty **source** for the Mekko CRM use case.
For *how to run / iterate / hot-reload* see **[`local-dev.md`](local-dev.md)**; for the
Docker/production side see [`deployment.md`](deployment.md); for data-only changes via the API
see [`data-setup.md`](data-setup.md).

> Branded as **Mekko CRM**. Customization was proven end-to-end on 2026-06-25:
> the sign-in heading was changed to "Welcome to Mekko CRM" and verified live via Playwright.

## First, pick the right route

| If you can achieve it by… | Do it as… | Where |
|---------------------------|-----------|-------|
| Adding fields / objects / options through the metadata API | **Data setup** — no source edit | `.tools/twenty-setup` (see [`data-setup.md`](data-setup.md)) |
| Changing UI, copy, business logic, or built-in behavior | **Source customization** — edit `packages/`, rebuild | this doc |

Prefer the API route when it's enough — it survives upstream upgrades far more cleanly
than a source fork.

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
