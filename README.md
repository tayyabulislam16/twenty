# Twenty-Linkedin

The installable **LinkedIn channel plugin** for Twenty CRM — a [`twenty-sdk`](https://www.npmjs.com/package/twenty-sdk)
application. It installs into a client's Twenty instance and provides the LinkedIn
**structure + UI + database**: objects/fields, the inbox/timeline UI, and the outbound
signal that tells the LinkedIn automation system to act.

## Where it fits

This app is one channel in a per-channel plugin model (siblings: Twenty-Telegram,
Twenty-WhatsApp). The architecture and decisions live in the base repo
(`mekkoMarketing` → `mekko/docs/channel-apps.md`). In short:

- **This plugin = structure + UI + DB only.** It never runs the automation.
- **A dedicated external LinkedIn automation system (per client)** with an **AI agent**
  reads/writes this app's objects through Twenty's API.
- **Two-way:** the agent writes records *in*; human actions in Twenty (approve / send /
  status change) fire a `DATABASE_EVENT` → `http-request` workflow that signals the
  automation system *out*.

The base Twenty fork + deployment stays a separate repo; only app code lives here.

## Develop

Requires the Twenty backend running (base repo's Docker stack on **http://localhost:3900**).

```bash
yarn install                 # applies the Windows path patch automatically (see below)
yarn twenty remote:status    # should show :3900, api-key (valid)
yarn twenty dev              # live dev: edit src/**, syncs to the workspace
yarn twenty dev:add          # scaffold an entity (object | field | frontComponent | logicFunction | view | workflow | ...)
yarn twenty dev --once       # one-shot build + sync (CI / scripts)
```

On Windows, prepend the corepack bin to PATH first:
`$env:Path = "C:\Users\tayyab\corepack-bin;$env:Path"`.

## Windows path patch (important)

`twenty-sdk@2.16.0` sends **Windows backslash paths** to the server in two places — the
file upload and the manifest's built component/handler paths — and the server rejects
them (`filePath contains unsafe characters` / `Built component path is invalid`). Deploy
is impossible on native Windows without a fix.

This repo carries a durable fix via **Yarn's native patch** (`yarn patch`), wired through
`package.json` → `resolutions` and stored under
[`.yarn/patches/`](.yarn/patches). It normalizes `\` → `/` at all five sites and
**re-applies automatically on every `yarn install`** — no manual steps.

If the SDK version bumps, the patch may need regenerating, or upstream the one-liner to
twentyhq/twenty so it can be dropped.

## Auth

Use **API-key** auth, not OAuth (this self-hosted instance doesn't expose the CLI OAuth
client id). Configure with `yarn twenty remote:add --url http://localhost:3900 --api-key <key>`.
