# Channel plugins — product architecture

How we build installable channel integrations (LinkedIn, Telegram, WhatsApp, …) for Twenty
and ship them per client. This is the product, not internal tooling.

## The model in one line

Each channel is a **self-contained Twenty App ("plugin")** that defines the *structure + UI*
in a client's Twenty; a **dedicated external automation system (per client, per channel)** with
an **AI agent** does the real platform work and reads/writes Twenty through a defined contract.

Twenty = **system of record** (structure, database, UI). Automation systems = **system of
action**. (Generalizes the split already in our notes to all channels and to a per-client
productized model.)

## Decisions locked

| Decision | Choice |
|----------|--------|
| Plugin role | **Structure + UI + database** only — never the automation runtime |
| Automation | **External, dedicated per client, per channel** (LinkedIn-C1, Telegram-C1, … each its own system) |
| Writers | An **AI agent** (in each automation system) **or a real person**, shaped by the plugin's schema |
| Client hosting | **Separate Twenty instance per client** |
| Channels | **Independent per channel** (no shared installed "core" app) |
| Data flow | **Two-way** — automation writes in; human actions in Twenty signal automation back out |
| Write path | **API-first** — use Twenty's GraphQL/REST where it works; add a plugin-defined route only when the plugin needs something the API can't express |

## Architecture (per client C, per channel X)

```
                    ┌──────────────────────────────────────────┐
   external         │  Client C's Twenty instance               │
   platform X  ◄──► │  ┌────────────────────────────────────┐  │
 (LinkedIn/Tg/Wa)   │  │  Plugin X (installed)              │  │
        ▲           │  │  • objects/fields  (the contract)  │  │
        │           │  │  • inbox/timeline UI               │  │
        │           │  │  • per-install vars: endpoint+secret│  │
        │           │  │  • DATABASE_EVENT → http-request ──┼──┼──┐ outbound signal
        │           │  └────────────────────────────────────┘  │  │ (human approves/sends)
        │           └──────────────▲───────────────────────────┘  │
        │   act              inbound│ write (standard API, per-C    │
        │  (send msg)               │ key, into plugin's objects)   │
        │           ┌───────────────┴───────────────────────────┐  │
        └───────────┤  Automation system X for client C         │◄─┘
                    │  (dedicated)  • platform runtime/session   │
                    │               • AI agent (writes records)  │
                    │               • webhook receiver (outbound)│
                    └────────────────────────────────────────────┘
```

### Two directions, both on native primitives
- **Inbound (automation → Twenty):** AI agent writes records (conversations, messages,
  contacts, activities) via Twenty's **GraphQL/REST API** using client C's API key, into the
  objects Plugin X defines. *Use idempotency keys / unique external-id fields so agent retries
  don't double-write.*
- **Outbound (Twenty → automation):** a human action in Twenty (approve a draft, mark "send",
  change status) fires a **`DATABASE_EVENT` trigger** → a workflow **`http-request` action**
  POSTs to client C's automation endpoint (signed with the per-install secret). The automation
  system then acts on the platform.

## Anatomy of a channel plugin

| Piece | Twenty app entity | Role |
|-------|-------------------|------|
| Data model (the contract) | `object` ×N + fields on Person/Company | what the agent writes; what the UI shows |
| Inbox / timeline | `frontComponent` + `pageLayout` + `navigationMenuItem` + `commandMenuItem` | presentation |
| Outbound signal | workflow: `DATABASE_EVENT` trigger → `http-request` action | tell automation to act |
| Per-install wiring | `application-registration-variable` / `application-variable` | this client's automation URL + secret + creds |
| Platform creds (if any) | `connectionProvider` | per-client auth where the plugin holds it |
| Access | `role` | who can use the channel |

The plugin's **schema is the integration contract.** Publish a `@mekko/<channel>-contract`
package (types generated from the plugin) that the automation system depends on, so writer and
schema stay in lockstep and version together.

## Reuse strategy (independent plugins, shared at build time)

No shared *installed* core (channels are independent). Share **source**:
- **`@mekko/channel-kit`** — base objects, inbox UI components, inbound-write helpers, the
  outbound-signal pattern, per-install-variable conventions. Compiled *into* each plugin, so
  installs stay self-contained.
- **`@mekko/automation-kit`** (or a template repo) — common base for each per-client automation
  system: typed Twenty client, outbound-webhook receiver, AI-agent harness, idempotency.
- **`create-mekko-channel`** — scaffolder (wraps `create-twenty-app` + our conventions).
- Repo: a `mekko-apps/` workspace (one package per channel + the two kits), separate from the
  Twenty fork.

## Per-client provisioning (the real operational cost)

Per client **per channel** multiplies systems — provisioning must be automated. Onboarding
client C with channels [X, Y]:
1. Provision C's Twenty instance.
2. `app:install` plugins X, Y into C's Twenty.
3. Stand up automation systems X-C and Y-C (from `automation-kit`).
4. Set per-install variables: C's Twenty API key, automation endpoints, signing secrets,
   platform credentials.
5. Verify the round-trip both directions before handing over.

Treat this as infra-as-code / a provisioning CLI from day one — manual setup won't scale to
N clients × M channels.

## Build order

- **Phase 0 — Unblock deploy. ✅ DONE (proven 2026-06-25).** App deploy works end-to-end on
  native Windows after a 2-point `twenty-sdk` path-normalization patch (upload + manifest). Make
  it durable with `patch-package` in the app repo. Details in [`customization.md`](customization.md).
- **Phase 1 — Reference vertical slice: Telegram, one client (us), full two-way loop.**
  Plugin (objects + inbox + outbound signal) + dedicated Telegram automation (AI agent writes
  in; receives outbound signal and sends). Easiest channel — proves the whole pattern.
- **Phase 2 — Extract `channel-kit`, `automation-kit`, `create-mekko-channel`** from Phase 1.
- **Phase 3 — WhatsApp (Cloud API).** Second API channel; validates the kit + contract generalize.
- **Phase 4 — LinkedIn.** Same plugin pattern; the hard part is the dedicated automation
  (browser/session, **ToS / ban risk — a business decision**), isolated per client.
- **Phase 5 — Provisioning automation.** Get client × channel onboarding close to one command.

## Risks / things to verify

1. **Logic-function / `http-request` outbound** to arbitrary automation URLs — confirm egress is
   allowed and secrets can be injected from per-install variables.
2. **Inbound idempotency** — unique external-id fields + upserts so agent retries don't duplicate.
3. **Auth both ways** — Twenty→automation (signed webhook secret per install); automation→Twenty
   (per-client scoped API key).
4. **Private-registry install per self-hosted instance** — verify publish→install across instances.
