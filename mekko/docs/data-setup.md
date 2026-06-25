# Data setup

Toolkit lives in [`.tools/twenty-setup/`](../../.tools/twenty-setup/) — Node scripts that
drive Twenty's API to create custom schema and seed records. No UI clicking required after
the first sign-in.

## Prerequisites

- The deployment is running at `http://localhost:3000` (see [deployment.md](deployment.md)).
- `cd .tools/twenty-setup && npm install` (only dependency is Playwright, used by the key extractor).

## 1. Get an API key — `get-api-key.js`

```bash
cd .tools/twenty-setup
npm run get-key       # node get-api-key.js
```

Opens a Chromium window with a persistent profile (`.userdata/`). Sign in via the
"Welcome, Mekko Digital" email screen if prompted; the script creates an API key and
writes it to **`api-key.txt`**. Every other script reads that file.

> `api-key.txt`, `.userdata/`, and the `debug-*.png` screenshots are local secrets/artifacts — never commit or share them.

## 2. Create custom schema — `setup.js`

```bash
node setup.js
```

Talks to the **`/metadata`** GraphQL endpoint (Bearer `api-key.txt`) to create/extend
objects and fields — e.g. LinkedIn-activity and job-opportunity fields on the built-in
Person and Company objects, select options with colors, etc. This is schema/metadata
mutation, the same channel documented in the `twenty_api_setup` memory.

Object IDs (`PERSON_ID`, `COMPANY_ID`) are currently hardcoded near the top of the script;
if you reset the workspace they change — re-fetch via the `listObjects()` query in the file.

## 3. Seed records — `seed.js`

```bash
node seed.js
```

Talks to the **`/graphql`** (data) endpoint to insert sample records: target companies
(Stripe, Vercel, Linear, Notion, Figma, …), people, LinkedIn activities, and job
opportunities. Edit the `COMPANIES_SEED` / people arrays in the file to change what gets created.

## Endpoints cheat-sheet

| Purpose | Endpoint | Used by |
|---------|----------|---------|
| Schema / metadata mutations | `http://localhost:3000/metadata` | `setup.js` |
| Record CRUD (data) | `http://localhost:3000/graphql` | `seed.js` |
| Auth | `Authorization: Bearer <api-key.txt>` | all |

The `*-verify.json`, `*-fields.json`, `enums.json`, `inputs.json` files are captured
query results kept for reference when constructing mutations.

## Inspecting results

After seeding, verify with the read-only Postgres MCP server (preferred over re-querying
GraphQL) or the `inspect.sql` snippet in the toolkit.
