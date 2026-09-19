# Autonomous Business Creation Loop — Architecture & Implementation Report

**Status:** APPROVED IN PRINCIPLE 2026-09-19 (§19). Schema apply to the brain awaits an explicit yes.
**Date:** 2026-09-19
**Branch:** `claude/autonomous-business-creation-ah7dfm`
**Author:** Claude Code (orchestrator), for Dustan Durrett

Every statement below is tagged the way the factory itself will tag research:
**FACT** (observed in this environment), **INFERENCE** (reasoned from facts),
**ESTIMATE** (a number with a range), **ASSUMPTION** (needs your confirmation),
**UNVERIFIED** (could not check from here).

Update 2026-09-19: the Slice 1 schema migration (`factory/supabase/migrations/0001_factory_schema.sql`) and its gate tests (`factory/sim/lifecycle_test.sql`, 12 checks) exist in the repo and pass on a local Postgres 16. Nothing has been applied to the brain, no money spent.

---

## 1. Current environment

| Item | Finding | Tag |
|---|---|---|
| Repo | `dustandurrettclaude-coder/mindsovermatters-co` — two commits, a `README.md` and a `CNAME` (`mindsovermatters.co`). No code, no CI, no `.github/`, no PR template. | FACT |
| Purpose of repo | The Minds Over Matters landing page, published by GitHub Pages under the custom domain. | FACT (README) + INFERENCE (Pages is enabled; the CNAME file is the Pages convention, Pages settings not visible from here) |
| Runtime | Linux container. Node 22.22, Bun 1.3.11, Python 3.11, `psql` 16 client, Docker 29, `jq`, `curl`. **No** Supabase CLI, **no** Deno. | FACT |
| Machine | 4 vCPU, 15 GB RAM, ~30 GB free disk. Ephemeral; anything not pushed is lost. | FACT |
| Secrets in env | `GH_TOKEN`/`GITHUB_TOKEN`, AWS keys, a Google Cloud auth token, `ANTHROPIC_BASE_URL`. **No `ANTHROPIC_API_KEY`**, no OpenAI/Gemini/other-vendor keys, no Supabase service key, no Stripe/Gumroad/HubSpot keys. | FACT |
| Network | Outbound HTTPS via an agent proxy. WebSearch and WebFetch tools available. | FACT |
| Existing brain | Supabase project `ompxlqmszgutlldtivph` (Postgres 17, `ACTIVE_HEALTHY`), ~60 tables in `public`, including `sessions`, `spinoffs`, `pending_confirmations` (385 rows), `policies` (60), `model_routing`, `mcp_routing`, `delegations`, `deploy_memory`, `sales` (Gumroad Ping webhook), `marketing_products`, `marketing_targets`, `brand_identities`, `x_queue`, `brain_edges`, `dream_proposals`. | FACT |
| Other Supabase projects | `mom-buyer-test` (INACTIVE), `pearls-library` (ACTIVE). | FACT |
| Existing businesses | Minds Over Matters (10 Gumroad products, organic X + Pinterest, sales captured to `public.sales`); CSSI cost-seg sales role (Formspree landing page, n8n → HubSpot weekly lead gen). | FACT (your preferences) + FACT (`sales` table comment) |
| Brain has prior art on this project? | No. Searched `spinoffs` and `deploy_memory` for "business factory / autonomous business / business creation": zero relevant rows. | FACT |

**Implication (INFERENCE):** the factory is a greenfield system, but it should *not* be a greenfield **platform**. You already own a Postgres brain with lifecycle, approval, memory and routing tables, a scheduled-session mechanism, a static-site host, and a webhook path for sales. The cheapest reliable architecture reuses those.

---

## 2. Available tools

Observed in this session. "Enabled" means usable from a Claude Code session right now.

| Tool / connector | State | Use in the factory | Tag |
|---|---|---|---|
| Supabase MCP | connected, enabled | System of record: schema, migrations, SQL, edge functions, logs, advisors | FACT |
| GitHub MCP | enabled | Code, PRs, landing-page deploys via Pages | FACT |
| Claude Code Remote | enabled | **`create_trigger` (Routines)**: cron-scheduled Claude sessions. This is the factory's scheduler for scout / maintenance runs. Also `send_later`, child sessions, PR watching. | FACT |
| WebSearch / WebFetch | enabled | Primary research engine (company sites, pricing pages, reviews, ad libraries, directories) | FACT |
| Ahrefs | connected, enabled | SEO visibility, keyword demand, backlinks, traffic estimates for competitor sites (USD cents) | FACT |
| Supermetrics | connected, enabled | Ad/analytics performance pulls (Google Ads, GA, Pinterest, YouTube etc.) for MEASURE stage | FACT |
| Gmail | connected, enabled | Drafts only for outreach experiments; sending stays a human step per `mcp_routing` | FACT |
| Google Drive | connected, enabled | Document archive / backup target | FACT |
| Microsoft 365 | connected, enabled | Available; no planned role | FACT |
| Composio | connected, enabled | Fallback integrations (GitHub, Gmail, Calendar per your notes) | FACT |
| Lusha | connected, enabled, **paid credits** | B2B contact enrichment for outbound validation. Ask-before-use. | FACT |
| n8n | connected at org level, **failed to connect this session (404)** | Fulfillment / integration automation lane (already runs CSSI lead gen → HubSpot) | FACT (connection failure is a session issue, not a missing capability) |
| Zapier, Vibe Prospecting, Google Calendar | connected, not enabled in chat | Toggle on per-chat when needed | FACT |
| HubSpot, Airtable, Bright Data, Close, Cloudflare, Notion, similarweb, Slack, Mailchimp, Klaviyo, Descript | installed, not connected / needs reconnect | Not available. HubSpot is notable: your CSSI lead gen writes to it via n8n, but the MCP is not connected. | FACT |
| Artifacts (private pages with optional `db` capability) | enabled | Candidate dashboard surface. Your Rule 6 applies to live artifacts touched via the remote bridge. | FACT |
| Chrome extension / computer use | not in this environment | Anything requiring a logged-in browser (Gumroad, Pinterest, X posting) remains a Cowork/desktop task | FACT |
| Payments (Stripe etc.) | none connected | Gumroad already handles checkout for MOM; new businesses would need Gumroad, Stripe Payment Links, or Lemon Squeezy | FACT + INFERENCE |

---

## 3. Available AI models

| Model | Available how | Role | Tag |
|---|---|---|---|
| Claude Fable 5.1 | This session (orchestrator) | Synthesis, strategy, final review, architecture. Never delegated. | FACT |
| Claude Opus | Subagent | Reasoning, verification-factcheck, code-implementation, devil's advocate | FACT (`public.model_routing`) |
| Claude Sonnet | Subagent | Multi-source research, mechanical verification, list enrichment, first drafts | FACT (`public.model_routing`) |
| Claude Haiku | Subagent | Classification, extraction, formatting, search-locate | FACT (`public.model_routing`) |
| Any Claude model **from code** (edge function, cron job, n8n) | **Not currently possible** — no `ANTHROPIC_API_KEY` in this environment, and the brain holds no key I could find | Needed for Phase-2 automated classification/alerts outside a live session | FACT + INFERENCE |
| GPT / Gemini / others | No API keys anywhere in the environment. `model_routing` records image generation as a manual handoff to you (ChatGPT free / Gemini image). | "Other AI as consultant" is possible only via manual copy-paste or a future key. | FACT |

**Recommendation (numbered for your reply):**

1. **Treat "multiple AI models" as multiple Claude *tiers* plus adversarial *roles*, not multiple vendors.** The prompt's collaboration roles (Research, Strategy, Marketing, Sales, Technical, Financial, Devil's Advocate, Optimization) map onto subagents with distinct role prompts and the routing table's tier per task. Disagreement-resolution works the same whether the "other AI" is a different vendor or a different Claude instance with an adversarial mandate. Yes = proceed this way. (Recommended.)
2. **Add a second vendor only when it earns its place.** If you later want a true second opinion, the cheapest path is one API key and one `factory.ai_calls` provider column. No architecture changes. Defer.
3. **An Anthropic API key is required for any unattended automation** (alerts, classification in cron, n8n LLM nodes). Without it, every AI step runs inside a scheduled Claude Code session (Routine), which is fine for the MVP and Phase 2. Decision deferred to Phase 3.

---

## 4. Recommended architecture

**Principle:** one database, one scheduler, one code repo, no new platforms.

```
                 ┌─────────────────────────────────────────────────┐
                 │  Claude Code sessions (orchestrator, Fable 5.1)  │
  Routines ─────►│  scout │ research │ evaluate │ build │ maintain │◄──── you (approvals)
  (cron)         │  role subagents: opus / sonnet / haiku           │
                 └───────┬───────────────────────────┬─────────────┘
                         │ SQL (migrations, reads,   │ git
                         │ writes, RLS)              │
                 ┌───────▼───────────┐       ┌───────▼───────────────────┐
                 │ Supabase brain     │       │ this repo                  │
                 │ schema `factory`   │       │  factory/ (CLI, prompts,   │
                 │ + existing public  │       │  agents, migrations, docs) │
                 │ (pending_confirm.. │       │  sites/<biz>/ (Pages)      │
                 │  sales, sessions)  │       └───────┬───────────────────┘
                 └───┬───────────┬────┘               │ GitHub Pages
                     │ webhooks  │ pg_cron / edge fn  ▼
      Gumroad Ping ──┘           │            landing pages / waitlists
      Formspree ─────────────────┘            (Formspree → email → brain)
                     ▲
      n8n / Zapier ──┘  (fulfillment + integration lane, Phase 3)
```

**Components and the "does this materially improve the factory?" answer:**

| Component | Choice | Why this and not something else |
|---|---|---|
| System of record | New Postgres schema **`factory`** in the existing brain project | Zero new infra; RLS and backups already exist; a separate schema keeps 15+ new tables from colliding with 60 brain tables and keeps `brain-backup` behaviour unchanged. |
| Code | `factory/` directory in this repo, **TypeScript on Bun** (Bun runs TS without a build step, Bun is present, Node 22 is the fallback) | One language for CLI, edge functions (Deno-compatible TS) and any dashboard. Python is available but adds a second toolchain for no gain. |
| Orchestration | Claude Code sessions, kicked by **Routines** (`create_trigger`) for scheduled work, and by you for gated work | Already exists, survives container loss, and every run is a session row in the brain. No queue, no worker fleet. |
| Agents | Markdown role specs in `factory/agents/*.md` + versioned prompts in `factory/prompts/` | Version-controlled prompts; the orchestrator spawns them with the routing table's model. |
| Scheduled data jobs | `pg_cron` inside Supabase for metric rollups/alerts; Edge Functions for webhooks | Free with the project; no server to run. |
| Landing pages | Static HTML under `sites/<business>/` served by GitHub Pages on the existing domain, or a per-business subdomain via CNAME later | Pages already hosts mindsovermatters.co; deploy = git push. |
| Lead capture | Formspree → email → Gmail MCP parse → `factory.leads` (same pattern you use for CSSI) | Proven in your setup; upgrade to an Edge Function webhook when volume justifies. |
| Payments | Gumroad first (already wired to `public.sales`), Stripe Payment Links when a business needs subscriptions | Reuse the working webhook before adding a processor. |
| Dashboard | Phase 1: SQL views + `factory status` CLI text. Phase 2: a **private Artifact** page reading the views. | Ship data first, pixels later. Rule 6 noted: the dashboard artifact is created and republished only from a file you drop, never mutated blindly. |
| Fulfillment automation | n8n (existing) → Zapier fallback | Only after a business has real customers. |
| Logging | `factory.events` (append-only) + `factory.ai_calls` (cost ledger) | Every state change and every model call is a row. |

---

## 5. Database schema (proposed, schema `factory`)

Types are Postgres. Every table has `id uuid pk default gen_random_uuid()`, `created_at`, `updated_at`. All rows reference `business_id` or `opportunity_id` where they apply.

| Table | Purpose | Key columns |
|---|---|---|
| `opportunities` | One row per discovered business/model | `name`, `category` (enum: local_service, b2b_service, saas, ai_service, productized, agency, leadgen, recurring, niche_software, marketplace, info_product, ops_automatable), `source_urls text[]`, `stage` (scouted → researched → evaluated → approved_for_validation / rejected), `graveyard_match_ids uuid[]` (mandatory check before insert) |
| `claims` | **The evidence ledger.** Every factual statement any agent produces | `opportunity_id`, `topic` (customer/offer/acquisition/sales/fulfillment/economics/history), `statement`, `kind` enum(**fact, assumption, estimate, inference, unverified**), `source_url`, `source_excerpt`, `confidence numeric`, `agent`, `model`, `verified_by`, `verified_at` |
| `business_models` | Reverse-engineered model per opportunity | jsonb blocks: `customer`, `offer`, `acquisition`, `sales`, `fulfillment`, `economics` (each value carries claim ids), `evolution` (original offer/pricing/niche → later), `smallest_viable_version` |
| `opportunity_reports` | Standardized Opportunity Report | one text/score-free row per evaluation dimension: `dimension` (demand, pain, roi, competition, differentiation, acquisition, recurring, margin, automation, complexity, startup_cost, speed, scalability, exit_value), `evidence_claim_ids`, `risks`, `unknowns`, `required_experiments`, `failure_conditions`, `success_conditions`, `verdict` (strong/weak/unknown). No composite score column by design. |
| `businesses` | A business the human approved to validate or run | `opportunity_id`, `name`, `state` (see §7), `autonomy_level int 0-5`, `mode` (build/maintain), `spend_limit_cents` (default **0**), `owner_hours_week numeric` |
| `state_transitions` | Immutable lifecycle log | `business_id`, `from_state`, `to_state`, `actor` (agent/human), `decision_id`, `reason` |
| `experiments` | Validation + marketing experiments | `business_id`, `hypothesis`, `assumption_claim_id`, `type` (landing_page, waitlist, cold_outreach, paid_ad, presale, demo, concierge, pilot, loi, paid_trial), `kill_criteria`, `success_criteria`, `budget_cents`, `spent_cents`, `status`, `result`, `lesson_id` (**required on close**) |
| `metrics` | Time series, one row per metric per period | `business_id`, `experiment_id`, `metric` (impressions, leads, qualified_leads, responses, appointments, sales, revenue_cents, cac_cents, conversion_rate, objections, refunds, retention, mrr_cents, churn, ai_cost_cents, human_minutes ...), `period_start`, `period_end`, `value`, `source` (manual/webhook/supermetrics/ahrefs/gumroad) |
| `campaigns` | Marketing channel tests | `business_id`, `channel`, `audience`, `offer`, `creative_ref`, `landing_url`, `spend_cents`, `status` (test/scale/killed) |
| `leads` | Sales loop | `business_id`, `source`, `stage` (lead→qualified→responded→booked→sold→onboarded / lost), `lost_reason`, `objections text[]`, `followups int`, `closed_at` |
| `decisions` | **Human escalation & approval gates** | `business_id`, `kind` (approve_validation, approve_build, approve_spend, pricing_change, legal, refund_threshold, security, strategic, ai_disagreement, other), `what_happened`, `why_it_matters`, `already_done`, `evidence_claim_ids`, `options jsonb`, `recommended_option`, `decision_required`, `status` (open/decided/expired), `decided_option`, `decided_at`, `pending_confirmation_id` → `public.pending_confirmations.id` |
| `ai_calls` | Cost ledger | `session_id`, `business_id`, `agent`, `model`, `task_type`, `input_tokens`, `output_tokens`, `cost_cents`, `outcome` |
| `ai_disagreements` | Recorded when two agents conflict | `topic`, `positions jsonb` (agent, claim ids), `resolution` (research_resolved / retained_uncertainty / human), `resolving_claim_ids` |
| `lessons` | Institutional memory | `business_id`, `experiment_id`, `lesson`, `category`, `applies_to` (scout/research/offer/acquisition/sales/fulfillment/automation), `evidence_claim_ids` |
| `failure_reports` | Business graveyard | `business_id`, `original_hypothesis`, `niche`, `offer`, `acquisition_method`, `experiments_summary`, `money_spent_cents`, `customers`, `revenue_cents`, `failure_point`, `shutdown_reason`, `lessons ids[]`; view `graveyard` = businesses in state `dead` joined here |
| `sops` | Repeatable processes | `business_id`, `process`, `trigger`, `steps jsonb` (TRIGGER→ACTION→DECISION→ACTION→RESULT), `automation_status` (manual/ai_assisted/delegated/automated/eliminated), `owner` |
| `automations` | What runs unattended | `business_id`, `sop_id`, `platform` (pg_cron/edge_fn/n8n/zapier/routine), `ref`, `last_run_at`, `last_status`, `failure_count` |
| `events` | Append-only audit | `business_id`, `actor`, `event_type`, `payload jsonb` |
| `factory_metrics` (view) | The factory's own KPIs (§27 of the brief) | speed (discovery→validation, validation→first customer, first customer→profit), cost per stage, human hours, escalations, portfolio counts, **profit per human hour** |

**Reuse, not duplication:** approvals surface through the existing `public.pending_confirmations` (your Rule 8), sales continue landing in `public.sales`, and each factory run is a `public.sessions` row. `factory.decisions` holds the structured payload the brief requires; the pending-confirmation row is the tick surface.

**RLS:** service role only for writes; a read-only role for the dashboard views. No anon policies on any factory table (same lesson as `dream_proposals`).

---

## 6. Agent architecture

Each agent is a markdown spec (`factory/agents/<name>.md`) with: role, allowed tools, model tier (from `public.model_routing`), input contract, output contract (structured JSON that maps to `claims` / report rows), and hard limits. Every delegated task carries the brief's protocol: CONTEXT, OBJECTIVE, CONSTRAINTS, OUTPUT, EVIDENCE, RETURN FORMAT.

| Agent | Tier | Reads | Writes | Notes |
|---|---|---|---|---|
| **Scout** | sonnet | WebSearch, Ahrefs, graveyard view, `lessons` | `opportunities` (stage=scouted), `claims` | Must query graveyard + open opportunities before proposing. Never scores. |
| **Researcher** | sonnet (fan-out per topic), haiku for extraction | WebSearch/WebFetch, Ahrefs, Supermetrics where relevant | `claims` (every statement tagged), `business_models` | Parallel by topic (customer / offer / acquisition / sales / fulfillment / economics / evolution). |
| **Verifier** | opus (judgment) / sonnet (mechanical) | `claims` | `claims.verified_*`, downgrades kind (fact → unverified) | Independent of the Researcher, per your standing verification rule. |
| **Devil's Advocate** | opus | `business_models`, `claims`, `opportunity_reports` | `ai_disagreements`, additional risk rows | Mandate: disprove. Its objections must cite claim ids or name the missing evidence. |
| **Financial** | opus | economics claims | `opportunity_reports` rows for margin/roi/startup_cost, projected P&L (all ESTIMATE) | Stress-tests price, CAC, LTV, break-even, cash. |
| **Evaluator** | Fable (orchestrator) | everything above | `opportunity_reports`, `decisions` (kind=approve_validation) | Synthesizes; never declares a winner by score. |
| **Experiment Designer** | opus | approved opportunity, assumptions | `experiments` (with kill/success criteria) | "Cheapest experiment that tests the most important assumption." |
| **Marketing** | sonnet | offer, audience | copy drafts to `campaigns` and `sites/<biz>/` | Draft-first: copy is reviewed in chat before publish (your draft-first rule). |
| **Sales** | sonnet | `leads`, lost reasons | follow-up drafts (Gmail drafts), `lessons` | Never sends. |
| **Builder** | opus | approved MVP scope | code in `sites/`, `factory/`; SOP rows | Standard code-implementation lane. |
| **Optimizer** | opus | `metrics`, `campaigns`, `experiments` | proposed experiments; bottleneck diagnosis | Implements §12 constraint logic (leads low → acquisition, etc.). |
| **Maintainer** | sonnet, scheduled Routine | metrics, automations, uptime | `events`, `decisions` when thresholds breach | Emits the "operating normally / decision required" digest. |

**Disagreement protocol (encoded, not ad hoc):** when Devil's Advocate or Financial contradicts Researcher/Evaluator, the orchestrator writes an `ai_disagreements` row, lists the claim ids each side used, dispatches one bounded research task if it can resolve it, and otherwise records `retained_uncertainty` and carries it into the Opportunity Report's unknowns. High-impact unresolved disagreement → `decisions` row (kind=ai_disagreement).

**Cost discipline:** the orchestrator checks `claims` before dispatching research (retrieval before generation), batches per-topic research in one fan-out, uses haiku for extraction/classification, and writes an `ai_calls` row per spawn (the brain's `delegations` table already does this for subagent spawns; `ai_calls` adds business attribution).

---

## 7. Business lifecycle

State machine on `businesses.state`. Transitions are the only way to change state, each writes `state_transitions`, and gated transitions require a decided `decisions` row.

```
opportunity: scouted → researched → evaluated ──► rejected
                                        │
                                   [GATE 1: human approves validation + budget]
                                        ▼
business:   validating ──► killed (→ failure_report + lessons)
                │
           [thresholds met: paying-demand signal, not interest]
           [GATE 2: human approves MVP build]
                ▼
            building → launched → optimizing ──► paused / killed
                                       │
                              [profitable N consecutive periods]
                                       ▼
                                  profitable → automating → maintaining
                                                                 │
                                          [any breach the Maintainer can't fix]
                                                                 ▼
                                                     escalated (→ human decision)
                                                     
any state ──► dead  (requires failure_report; graveyard view)
```

Gates:

1. **Gate 1 — validate:** requires an Opportunity Report with no dimension `unknown` that the report lists as critical, a graveyard check, and a spend limit you set (default $0).
2. **Gate 2 — build:** requires experiment results showing **paying demand** (pre-sale, paid trial, LOI, or pilot revenue), not clicks or waitlist sign-ups alone. Thresholds are per-business and stored on the experiment, not hardcoded.
3. **Spend gate:** any `spent_cents` that would exceed `spend_limit_cents` blocks and opens a decision. This is your Rule 2 made structural.
4. **Autonomy promotion gate:** `autonomy_level` only increments via a human decision, and only after `automations` show N clean runs (proposal: 30 days, zero failures).

---

## 8. Automation architecture

| Job | Mechanism | Cadence | Phase |
|---|---|---|---|
| Scout run | Routine → Claude Code session | weekly | 2 |
| Metric ingestion (Gumroad) | existing Ping webhook → `public.sales` → view into `factory.metrics` | real time | 1 |
| Metric ingestion (ads/analytics/SEO) | Supermetrics + Ahrefs pulled inside a Routine session | weekly | 2 |
| Lead ingestion | Formspree → email → parse in session (v1), Edge Function webhook (v2) | daily / real time | 2 |
| Rollups + threshold checks | `pg_cron` SQL | daily | 2 |
| Maintainer digest | Routine → session reads rollups, writes `events`/`decisions`, emails digest via Gmail draft or a Push notification | daily / weekly | 3 |
| Fulfillment workflows | n8n (Zapier fallback) with SOP ids as the contract | per business | 3 |
| Self-improvement review | Routine, monthly, answers the ten §25 questions from `ai_calls`, `lessons`, `experiments` | monthly | 3 |

No workers to host, no queue to babysit. If a job needs an LLM outside a session (e.g. classify inbound leads at 3 a.m.), that is the trigger for the API-key decision in §3.

---

## 9. Human approval system

- **Surface:** `public.pending_confirmations` row (existing, your Rule 8) linked from `factory.decisions`. The chat prints the row the same turn it is created. A decision is ticked only on observable evidence (your reply, a PR review, a DB update you made), never on my say-so.
- **Payload:** every decision row carries all six required fields: what happened, why it matters, what the system already did, evidence (claim ids), options with a recommended option first, and the exact decision required. The CLI (`factory decide <id> <option>`) records it and unblocks the transition.
- **Never auto-act on:** spend above limit, legal, unusual complaints, refund threshold breach, security, major pricing, contracts, strategic direction, AI uncertainty, high-impact disagreement, anything that could materially damage the business. These are `decisions.kind` values, so the gate is data, not prose.
- **Expiry:** an open decision older than 14 days is re-surfaced, never silently dropped.

---

## 10. AI collaboration strategy

1. Orchestrator (this) synthesizes; subagents produce evidence. No subagent changes state.
2. Routing per `public.model_routing`; new task types get a routing row after first use ("learn once, route forever", already your policy).
3. Each delegated brief uses the six-field protocol. Outputs are JSON that maps onto `claims` and report tables, so nothing lives only in a transcript.
4. Independent verification by a fresh subagent on every multi-step deliverable (your standing rule).
5. Cheap-first: retrieval from `claims` → haiku → sonnet → opus → Fable. Every spawn logged to `ai_calls` with business attribution.
6. Second vendor deferred (§3 item 2).

---

## 11. Security considerations

- Secrets never enter the repo; the container has none for Supabase, so runtime code will read them from Supabase Edge Function secrets or from a local `.env` you hold. Documented in `ENVIRONMENT.md`, values never committed.
- `factory` schema: RLS on, service-role writes, a `factory_reader` role for views. No anon policies.
- The repo is public-facing via Pages. Business data stays in the DB; Pages only hosts landing pages. No dashboard on the public domain.
- Untrusted inputs: scraped pages, form submissions, inbound email, review text. Stored as data, never executed as instructions; the Researcher prompt states this explicitly.
- Legal/platform boundaries (§21 of the brief) are encoded as a Scout/Researcher checklist and a `claims.source_url` requirement: no source, no fact. No scraping behind logins, no copied branding, no fabricated testimonials or numbers. Your Rule 3 covers all outbound copy.
- Spend: structural $0 default; no card, no payment API, no ad account credentials in the system. A paid experiment is a human action with a decision row.
- Chrome-profile routing is out of scope for this environment (no browser); any Cowork step that publishes will follow `Chrome Profile Registry.md`.

---

## 12. Estimated operating costs

All **ESTIMATE**. I could not read your Supabase or n8n plan tiers from here (UNVERIFIED).

| Line | Phase 1–2 | Phase 3+ | Notes |
|---|---|---|---|
| Supabase | $0 incremental | $0–25/mo | Same project; schema adds a few MB. Pro tier only if `pg_cron`/edge function limits bite. |
| GitHub Pages | $0 | $0 | |
| Claude usage (sessions + subagents) | Whatever your plan already covers | + API key spend if unattended jobs are added: $10–60/mo per active business at haiku/sonnet rates | Measured per business via `ai_calls`; tokens per research run estimated 300k–900k across fan-out. Measured spawn averages in `public.model_routing`: opus code-implementation ~254k, sonnet mechanical verification ~123k, opus fact-check verification ~118k; multi-source research has no measured average yet. |
| Domains | $0 (existing domain) | $10–15/yr per new business domain | |
| Payments | Gumroad fee on sales only | Stripe 2.9% + 30¢ if adopted | |
| Validation experiments | $0 (organic; drafts, Pages, Formspree free tier) | Human-approved per experiment | No paid social per your policy; paid search only by decision. |
| Lusha / Supermetrics / Ahrefs | already subscribed | same | Lusha credits are paid per use: gated. |
| n8n | already subscribed (tier unverified) | same | |

Factory overhead at MVP: **≈ $0/month incremental** beyond Claude usage you already pay for.

---

## 13. MVP scope (Build Phase 3 of the brief)

Deliver, in this repo under `factory/`:

1. `supabase/migrations/0001_factory_schema.sql` — schema in §5 with enums, RLS, views (`graveyard`, `factory_metrics`, `portfolio`).
2. `src/cli.ts` (Bun) — `factory status | scout | research <id> | evaluate <id> | approve <decision> <option> | transition <biz> <state> | experiment new/close | metric add | lesson add | graveyard search <terms>`.
3. `src/lifecycle.ts` — the state machine with gate enforcement and `state_transitions` writes.
4. `src/claims.ts` — evidence ledger helpers; refuses a `fact` without `source_url`.
5. `agents/*.md` and `prompts/*.md` — Scout, Researcher, Verifier, Devil's Advocate, Financial, Evaluator, Experiment Designer specs with the six-field delegation template.
6. `src/ai_calls.ts` — cost ledger writer used by every spawn.
7. Docs: `README.md`, `ARCHITECTURE.md` (this file, promoted), `SETUP.md`, `ENVIRONMENT.md`, `SCHEMA.md`, `AGENTS.md`, `SOPS.md`, `CHANGELOG.md`.
8. Tests (Phase 4): a `sim/` folder with three simulated businesses driven through scouted → maintaining, plus failure tests: AI disagreement, corrupt claim data, API failure (mocked WebFetch), unauthorized transition (skip a gate), spend over limit.

Out of MVP: marketing automation, dashboard page, n8n workflows, scheduled Routines, any real outreach.

---

## 14. Phase 2 scope

1. Validation engine: landing-page generator into `sites/<biz>/`, Formspree waitlist/lead capture, outreach drafts to Gmail (no sending), pre-sale via Gumroad, experiment tracking with kill/success criteria.
2. Marketing experiment DB and the RESEARCH→CREATE→TEST→MEASURE→KILL→IMPROVE→SCALE loop for organic channels (X, Pinterest, SEO via Ahrefs).
3. Sales loop tables live; lost-reason analysis feeding `lessons`.
4. Metric ingestion from Gumroad, Supermetrics, Ahrefs.
5. Weekly Scout Routine.
6. Private dashboard artifact (portfolio, financial, pipeline, experiments, autonomy, alerts) reading `factory` views.
7. Calibration run: put **Minds Over Matters (existing, live, with real `public.sales` data)** through the loop as business #0 so the metrics, bottleneck logic and dashboard are tested on real numbers before any new business is launched.

---

## 15. Phase 3 scope

1. Maintenance mode: Maintainer Routine, threshold alerts, digest messages, automated corrective experiments within limits.
2. Autonomy levels 0–5 with earned promotion and demonstrated-reliability counters.
3. Fulfillment automation: SOP → n8n/Zapier workflows, `automations` monitoring.
4. Portfolio engine: parallel businesses, factory KPIs (`profit per human hour` as headline).
5. Self-improvement Routine (monthly §25 review) and token-cost optimization from `ai_calls`.
6. Unattended LLM jobs if and when an API key is approved.

---

## 16. Risks

1. **Zero-spend validation ceiling.** With no ad spend and organic-only channels, some categories (local services, paid-acquisition SaaS) cannot be validated quickly. Mitigation: Scout filters for organic/outbound-reachable niches; paid tests become explicit decisions.
2. **Research hallucination.** Mitigated structurally: no `fact` without a URL, independent Verifier, Devil's Advocate, and the ledger keeps `unverified` visible in every report.
3. **Copycat bias.** "Proven demand" can degrade into cloning. The `smallest_viable_version` + differentiation dimension + legal checklist are required, not optional, before Gate 1.
4. **Human bottleneck.** You are one person with a day job; every gate waits on you. Mitigation: decisions are batched into digests, and the factory never blocks on anything not on the gate list.
5. **Brain sprawl.** 60 tables already. Separate schema, migrations in git, and no new tables without a migration file.
6. **Tooling gaps in this environment.** No Supabase CLI (migrations applied via MCP `apply_migration` instead), n8n MCP failed to connect this session, no browser. All workable; noted so nothing is over-promised.
7. **Unattended AI needs a key.** Phase 3's maintenance digests are session-bound until then.
8. **Token cost creep.** Every spawn is logged; the monthly review has a hard question about it. `model_routing` already shows opus implementation runs at ~254k tokens each.
9. **Repo mismatch.** The factory lives in the landing-page repo because that is the designated branch. Works, but a dedicated repo is cleaner long-term (open question 1).

---

## 17. Open questions

Yes/no format; my recommendation first, yes = do it.

1. **Keep the factory in this repo under `factory/` (recommended: yes for MVP, move to its own repo before Phase 2).** No = create a new repo now.
2. **Use a new `factory` schema in the existing brain project (recommended: yes).** No = new Supabase project, separate from the brain.
3. **Bun + TypeScript for all factory code (recommended: yes).** No = Python.
4. **Multi-model = Claude tiers + adversarial roles, second vendor deferred (recommended: yes).** No = provision another vendor key now.
5. **Default `spend_limit_cents = 0`, every dollar a decision row (recommended: yes).**
6. **Business #0 = Minds Over Matters, run through the loop as a calibration on real data before scouting anything new (recommended: yes).**
7. **Approvals surface through `public.pending_confirmations` linked to `factory.decisions` (recommended: yes).** No = factory-only table.
8. **Provide an Anthropic API key for unattended jobs in Phase 3 (recommended: defer; decide when the first unattended job is specified).**
9. **First scout categories, if you want to constrain them:** my suggestion given your assets is productized/AI services and information products with organic acquisition; local services are last. Yes = accept, or name categories.

---

## 18. Recommended first implementation

**Slice 1 (one session):** items 1, 3, 4, 6 and the docs skeleton from §13: the `factory` schema migration applied to the brain via `apply_migration`, the lifecycle state machine with gate enforcement, the claims ledger, the `ai_calls` writer, `factory status`, and one simulated opportunity walked from `scouted` to `approved_for_validation` with a real `decisions` row surfaced as a pending confirmation. Verified by an independent subagent before commit.

**Slice 2:** agent specs + prompts, `factory scout` and `factory research` running real WebSearch fan-outs writing tagged claims, Verifier and Devil's Advocate passes.

**Slice 3:** Phase 4 simulation tests (three fake businesses, the five failure conditions), then the Phase 2 calibration on Minds Over Matters.

Nothing in Slice 1 spends money, sends anything, or touches existing brain tables except inserting one `pending_confirmations` row for Gate 1 of the simulated business.

---

*Approval needed on §17 before any of §18 is built. Reply with numbers (e.g. "1 yes, 2 yes, 6 no").*

---

## 19. Decisions recorded 2026-09-19 (Dustan: "do all recommended")

Approved design constraints, now binding on Slice 1 and later:

1. **Scout lanes are constrained to unfair-advantage territory:** (a) cost-seg / commercial real estate owners and their advisors, (b) respiratory therapy, (c) the Minds Over Matters digital-product audience. Other categories require an explicit decision row.
2. **Gate 2 requires first-dollar evidence:** a pre-sale, paid pilot or paid trial. Waitlists and clicks never satisfy it. Any business not able to take money within 30 days of Gate 1 is killed automatically at day 30 with a failure report.
3. **Preferred models: near-zero fulfillment cost** — digital products, templates, calculators, niche guides, fixed-scope productized micro-services. Many small bets over one large one.
4. **Shared distribution assets are portfolio infrastructure:** email list, Pinterest, X, directory sites get their own `businesses` rows (state `maintaining`, kind `asset`) and metrics; every new business launches into them.
5. **Kill cap:** a validation may not exceed $50 or 5 human hours; exceeding either opens a decision row. Headline factory KPI stays profit per human hour.
6. **Devil's Advocate mandate** includes an explicit attack on owner-time feasibility ("will Dustan actually have time for the manual steps this needs?").
7. **Validation budget: $100/month standing cap** across all businesses. Every experiment with spend is still pre-approved by decision row, every dollar logged in `experiments.spent_cents`, and the system never holds a card or payment credential (Rule 2). The cap only removes the per-dollar decision below it after the experiment itself is approved.
8. **Ranking dimension added:** `P(first $100 within 30 days)` as a labelled ESTIMATE on every Opportunity Report, with its five inputs shown (paying-demand facts, owned channel, fulfillment cost, price under $100, no graveyard/lessons match). Used to order the list, never to decide alone.
9. **Connectors (free only, Dustan 2026-09-19: "I'm not paying for services"):** Parallel Search (free, no auth) and Firecrawl (free tier, 1,000 credits/month, connected 2026-09-19); HubSpot (existing account); check n8n; toggle Vibe Prospecting and Zapier on per chat. **Similarweb dropped**: its MCP requires a paid Business/Enterprise/API plan and meters every call in paid credits. Ahrefs (already subscribed) covers competitor traffic. Semrush, Apollo, Cloudflare, Notion not added. G2 deferred with the SaaS lane. Rule for the factory: no connector, API or data service that costs money is proposed without saying so in the same line. Connectors are connected once at org level and enabled per chat; `public.mcp_routing` gets a `factory-research` row once they are observed connected.
10. **§17 open questions:** recommended answers taken as approved (1 yes for MVP, 2 yes, 3 yes, 4 yes, 5 yes, 6 yes, 7 yes, 8 defer, 9 superseded by item 1 above). Pending-confirmation row 404 stays open until Dustan confirms this reading.

*Slice 1 (§18) proceeds on these. The `factory` schema migration lives at `factory/supabase/migrations/0001_factory_schema.sql` and is applied to the brain only on an explicit yes.*

