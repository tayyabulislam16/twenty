# Twenty-Linkedin (private — do not publish)

This is the **LinkedIn channel plugin** for Twenty CRM — a `twenty-sdk` app, one branch
(`Twenty-Linkedin`) of the private `tayyabulislam16/twenty` repo. **Private project**; do not
publish source, links, or credentials externally.

**Architecture lives in the private base repo** (`mekkoMarketing`, branch `mekko-main`):
`mekko/docs/channel-apps.md` (product architecture), `mekko/docs/customization.md` (App SDK +
the Windows path patch). Local path: `d:\work\mekkoMarketing\mekko\docs\`. Read those before
making structural decisions. The key decisions, in brief:

- **This plugin = structure + UI + database only.** It never runs the automation.
- A **dedicated external LinkedIn automation system (per client)** with an **AI agent**
  reads/writes this app's objects via Twenty's API (API-first; per-client API key).
- **Two-way:** the agent/person writes records *in*; human actions in Twenty (approve / send /
  status) fire a `DATABASE_EVENT` → `http-request` workflow that signals the automation *out*.
- Shared code (`@mekko/channel-kit`, `@mekko/<channel>-contract`) ships as **private npm
  packages**, compiled into the app — not copied between repos.
- **Deploy is patched for Windows** via Yarn native patch (`.yarn/patches/`); auth is **API-key**,
  not OAuth, against the base stack on `http://localhost:3900`.

## Base documentation

- Getting started:
  - https://docs.twenty.com/developers/extend/apps/getting-started/quick-start.md
  - https://docs.twenty.com/developers/extend/apps/getting-started/concepts.md
  - https://docs.twenty.com/developers/extend/apps/getting-started/project-structure.md
  - https://docs.twenty.com/developers/extend/apps/getting-started/local-server.md
  - https://docs.twenty.com/developers/extend/apps/getting-started/scaffolding.md
  - https://docs.twenty.com/developers/extend/apps/getting-started/troubleshooting.md
- Config:
  - https://docs.twenty.com/developers/extend/apps/config/overview.md
  - https://docs.twenty.com/developers/extend/apps/config/application.md
  - https://docs.twenty.com/developers/extend/apps/config/roles.md
  - https://docs.twenty.com/developers/extend/apps/config/install-hooks.md
  - https://docs.twenty.com/developers/extend/apps/config/public-assets.md
- Data:
  - https://docs.twenty.com/developers/extend/apps/data/overview.md
  - https://docs.twenty.com/developers/extend/apps/data/objects.md
  - https://docs.twenty.com/developers/extend/apps/data/extending-objects.md
  - https://docs.twenty.com/developers/extend/apps/data/relations.md
- Logic:
  - https://docs.twenty.com/developers/extend/apps/logic/overview.md
  - https://docs.twenty.com/developers/extend/apps/logic/logic-functions.md
  - https://docs.twenty.com/developers/extend/apps/logic/skills-and-agents.md
  - https://docs.twenty.com/developers/extend/apps/logic/connections.md
- Layout:
  - https://docs.twenty.com/developers/extend/apps/layout/overview.md
  - https://docs.twenty.com/developers/extend/apps/layout/views.md
  - https://docs.twenty.com/developers/extend/apps/layout/navigation-menu-items.md
  - https://docs.twenty.com/developers/extend/apps/layout/page-layouts.md
  - https://docs.twenty.com/developers/extend/apps/layout/front-components.md
  - https://docs.twenty.com/developers/extend/apps/layout/command-menu-items.md
- Operations:
  - https://docs.twenty.com/developers/extend/apps/operations/overview.md
  - https://docs.twenty.com/developers/extend/apps/operations/cli.md
  - https://docs.twenty.com/developers/extend/apps/operations/testing.md
  - https://docs.twenty.com/developers/extend/apps/operations/publishing.md
- Rich app example: https://github.com/twentyhq/twenty/tree/main/packages/twenty-apps/examples/postcard

## UUID requirement

- All generated UUIDs must be valid UUID v4.

## Common Pitfalls

- Creating an object without an index view associated. Unless this is a technical object, user will need to visualize it.
- Creating a view without a navigationMenuItem associated. This will make the view available on the left sidebar.
- Creating a front-end component that has a scroll instead of being responsive to its fixed widget height and width, unless it is specifically meant to be used in a canvas tab.

## Best practice

It's highly recommended to create new app entities using `yarn twenty dev:add`. These are the options:

| Entity type          | Command                                  | Generated file                        |
| -------------------- | ---------------------------------------- | ------------------------------------- |
| Object               | `yarn twenty dev:add object`             | `src/objects/<name>.ts`               |
| Field                | `yarn twenty dev:add field`              | `src/fields/<name>.ts`                |
| Logic function       | `yarn twenty dev:add logicFunction`      | `src/logic-functions/<name>.ts`       |
| Front component      | `yarn twenty dev:add frontComponent`     | `src/front-components/<name>.tsx`     |
| Role                 | `yarn twenty dev:add role`               | `src/roles/<name>.ts`                 |
| Skill                | `yarn twenty dev:add skill`              | `src/skills/<name>.ts`                |
| Agent                | `yarn twenty dev:add agent`              | `src/agents/<name>.ts`                |
| View                 | `yarn twenty dev:add view`               | `src/views/<name>.ts`                 |
| Navigation menu item | `yarn twenty dev:add navigationMenuItem` | `src/navigation-menu-items/<name>.ts` |
| Page layout          | `yarn twenty dev:add pageLayout`         | `src/page-layouts/<name>.ts`          |

This helps automatically generate required IDs etc.
