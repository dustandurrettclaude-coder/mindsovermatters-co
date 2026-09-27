# KJ "AI Second Brain 2.0" vs Minds Over Matters — architecture review

**Date:** 2026-09-27 · **Scope:** assessment only; no MOM code, schema or skill was changed · **Requested by:** Dustan (review note of 2026-09-27)

The question asked: has KJ discovered anything that would materially improve MOM? Not whether MOM can reproduce his features.

---

## 0. Verdict in one screen

KJ found nothing that requires re-architecting MOM. He found **one thing MOM is genuinely missing** (real-world outcomes never re-enter memory), **one thing MOM designed but does not ship** (the product never reads back the memory it writes at chat start), and **one thing where his product is simply ahead** (time to first value). Everything else on the list already exists in MOM or would make MOM worse.

| # | Recommendation from the note | Verdict | One-line reason |
|---|---|---|---|
| 1 | Simplify the mental model | **IMPROVE** | The architecture is explainable in three sentences. The buyer surfaces expose ~40 concepts, 45 skills, four aliases and three different step counts instead. |
| 2 | Global → Area → Project → Task → Session inheritance | **DON'T COPY the hierarchy; IMPROVE retrieval** | MOM is a flat `domain → goal` brain on purpose and sells it that way. The real gap: the product never loads the `context_*` rows it writes, and the personal handoff is one global slot. |
| 3 | Real-world result → feedback → memory | **ADD (small)** | `deploy_memory.outcome` exists, is documented as "what happened after the memo was acted on", and is NULL on 588 of 588 rows. No writer, no reader. |
| 4 | Strong provenance | **ALREADY EXISTS** (+ three dead fields to fix; model ledger is FUTURE) | Session, writer role, timestamps, supersession, approval trail and a proposal/verdict chain all exist. Model identity and "re-confirmed" do not, on memory rows. |
| 5 | Onboarding | **IMPROVE — top priority** | 14 buyer steps, three accounts, a license key emailed "within one business day", ~154 KB of SQL, ~20 clicks before any value. The first outside buyer got stuck at message one. |
| — | "Sophistication underneath, not in front" | **IMPROVE** (folds into 1 and 5) | The skills are written for Claude; the buyer documents inherit that voice. |

The three actions worth doing now are §6 items 1–3. Item 1 is the launch.

---

## 1. What this review examined, and what it could not

Examined, as-built (not plans):

1. **The live personal brain**, Supabase project `ompxlqmszgutlldtivph`: 60 public tables plus the `factory` schema; columns, column comments, triggers, check constraints, cron jobs; 69 live policies read in full; row counts and value distributions. Snapshot 2026-09-27, Appendix B.
2. **The 37 installed personal skills** synced to this machine (close 182 KB, reconcile 85 KB, session-init, wrap, spinoff, reflect, loops, loop-scout, insights, deploy, model-router, skill-scout, skill-packager, interview, spec-refine, backup, brain-backup), read in full by a reader agent with line citations.
3. **The shipped product**: the "Minds Over Matters v4.1" kit zip on Drive (cut 2b; 136 members: 45 skills, START-HERE, README, Handbook, Setup Guide, PATCH-NOTES, six workspace templates, dashboard template), extracted and read by a second reader agent, with brain-setup's SQL parsed for its table definitions.
4. **The `mom-build` repository** (G0 skeleton: a README quoting the multi-model spec v0.4 §10.10–10.14, CODEOWNERS, two rulesets, setup and negative-test docs).
5. **Personal workspace and specs on Drive**: CLAUDE.md, about-me.md, memory.md, rules.md, lessons.md, the multi-model-brain plan.md (v0.3 copy), brain-graph-dream v0.6, the positioning draft, the 2026-09-18 competitor comparison and borrow list.

Not examined:

- **KJ's own materials.** Assessed only from the note's description of his stack and layers.
- **mindsovermatters.co and the Gumroad listing**: blocked by this container's network policy. The Handbook, README and positioning draft stand in for the public pitch.
- **plan.md v0.4 §10.10–10.14**: the Drive copy is v0.3 and has no §10. The mom-build README quotes v0.4 verbatim, and those quotes are used.
- **Chat transcripts**: how often a session actually opens with a domain slug cannot be measured from the database. A proxy is used in §3.2.

---

## 2. MOM as it runs today, on one page

Two implementations exist, and they differ.

**Personal brain (Dustan's).** Supabase is the source of truth. A Markdown "md tier" is a cache with hard caps: CLAUDE.md ≤150 lines, about-me.md ≤60, memory.md ≤40 ("a decisions cache, not a log"), lessons.md under an 8,000-token ceiling. Memory is `deploy_memory`: 75 goals (`key='goal_meta'`), 344 `context_*` memos, 50 tasks. Around it: 192 spinoffs, 417 pending confirmations (28 open), 69 live policies (Claude proposes, Dustan promotes; 81 proposals so far), 829 derived graph edges, 49 Dream proposals (a nightly cron proposes retiring memos unused for 60 days; Claude applies only after Dustan rules; 43 accepted, 6 rejected). One partition: `domain`, six active values (cssi, rt, realestate, digital, infra, mom-product), enforced by a trigger that rejects any other value.

**A session, personally.** session-init mints an id (up to seven brain calls), reads memory.md, and pulls at most 5 open goals and 5 memo titles (cut at 90 characters) for the one domain the chat opened with. Work happens. close (20 numbered steps FULL, 17 of them LITE) writes eight tables, merges memory.md, routes lessons through wrap to one of four homes (a skill's Gotchas, lessons.md, a to-do row, a policy proposal), runs reconcile (auto-closes only rows whose `sql` or `shell` check passes; `manual` rows surface for a human), and emits a ≤150-word kickoff into one global handoff slot. Day to day that is about four user actions: `/close` plus a mode, `tick n`, paste the kickoff into the next chat, answer a picker.

**Shipped product (v4.1).** The same idea on an older schema: 18 tables plus two optional Dream tables; `deploy_memory` without `source_type`, `confirmations`, `last_used_at` or `outcome`. 45 skills (18 core, 27 extras). Claude-only. Positioning draft (2026-09-18): "a one-time purchase that installs 43 Claude skills and turns a free database you create and own into Claude's working memory and its operations desk". Handbook one-liner: "Your goals, workflows, and memory live in a database you own. Any Claude that can reach it — on any surface — can be briefed on your world at the start of a session." Pricing per the 365-day licensing goal: $79/yr.

**Multi-model.** A process today (each product cut goes through hostile ChatGPT audits; policy #72 names ChatGPT and a token-lean second lane, and memo 754 records that Kimi lane as dead), a plan tomorrow (mom-build: "Codex builds, Claude Code audits, Dustan merges"; "AI can propose, review and repair; AI never authorizes an irreversible action"), and explicitly out of the v4.x product (§10.14: "the public word is planned"). "Meeting of the Minds" in the product is an offline update-pack reviewer that "never installs", not a council of models.

---

## 3. The five recommendations against the implementation

### 3.1 Simplify the mental model — IMPROVE

**KJ:** two layers, one sentence each: a strategy brain and per-project execution "soldiers".

**MOM today:**

- The architecture already has a three-sentence story, and the Handbook nearly says it (quoted in §2).
- What the buyer actually meets, per the product reader's count: about 40 concepts (15 setup, 25 runtime); 14 skills named in the setup documents, 22 in the Learning Guide, 45 in the catalogue; legacy aliases (`cp → checkpoint`, `brain → goal-board`, `close → end-session`, `start → session-menu`); and a generated About-Me that names menu tabs ("Recall / Workflows / Saved for Later / Brain / Dispatch / Fresh start") that session-menu's own buttons ("Goal board", "Task inbox") do not use.
- Three different step counts for one setup: 14 (START-HERE, the HTML guide, MOM-BUYER-SETUP), 7 (README "QUICK START"), 6 (Handbook "Six steps, run once"; Setup Guide PDF "your license key, then six steps").
- Root cause: the skills are written for Claude (close carries 256 version tags and 78 dates in 182 KB) and the buyer documents inherit that register. The T16 kit declutter already in the backlog (cuts a–m, memo 754) removes files. It does not yet remove words.

**Gap:** presentation, not architecture. Nothing in the backend needs to change for this.

**Action:** one model, three sentences, on every buyer surface, in this order. **Brain**: what Claude remembers about you, in a database you own. **Board**: what you are working toward; nothing is marked done until a check proves it. **Session**: open with a briefing, work, seal it at the end. Everything else is "advanced" and stays out of sight until day two. One step count. No aliases in buyer documents.

### 3.2 Hierarchical context inheritance — DON'T COPY the hierarchy; IMPROVE retrieval

**KJ:** isolated project folders, a top brain that sees across them, each level inheriting only what it needs.

**MOM today:**

- The partition is one level deep by design: `domain` (trigger-enforced vocabulary) → `goal_id` → memos, spinoffs, tasks → sessions. "project" is free text inside the goal JSON (workflow-saver: "This field is DIRTY free-text"). `sessions.scope` is free text and reads `general` on 121 of 210 sessions. No per-project CLAUDE.md, memory.md or now.md exists in the 37 personal skills or the 45 product skills.
- Flatness is a selling point, not an accident. Handbook: "every domain sits on one board, not walled off project by project the way Claude's own memory is." Gumroad description draft: "One brain across every project and domain — Claude scopes its own memory per project; this doesn't."
- KJ's two arguments for hierarchy, token efficiency and isolation, are already handled another way: retrieval is bounded (5 goals + 5 memos, titles cut at 90 characters), the md tier has hard line caps, and skill changelogs were moved out of skill bodies so session-init "stops loading ~23 KB of its own history on every invocation". A vault loads whole files; MOM loads titles and lets Claude ask.

**Where KJ's point lands, twice:**

1. **Product: the memory that is written is never read.** The product's session-bootstrap is "Silent — no menu, no goal load" and reads memory.md once. recall loads `goal_meta` rows, active loops, spinoff and skill counts, the open handoff and one checkpoint snapshot. It never loads the `context_*` rows that checkpoint and end-session write. checkpoint's own text claims otherwise: "Retrieval: domain-scoped /recall surfaces context rows for that tab." The personal brain fixed exactly this on 2026-09-11 (session-init v3.1, the two-lane "C4 retrieval"); the product did not inherit it.
2. **Personal: the handoff is one global slot.** `system_cache.handoff_latest` holds one kickoff (≤150 words, at most 5 items) for every project. A second project's close must "merge or replace" the first's, and the one-deep history is written but "nothing READS it". Two kickoffs pasted into two chats on 2026-09-26 produced the one-writer breaches on record (memos 751 and 755; policy proposal #80). `active_sessions.domains` is `{}` on every row, so the per-domain claim mechanism that would arbitrate this has never been used.

**Proxy for whether domain retrieval fires at all:** `last_used_at` is stamped only when the retrieval returns rows. It is set on 60 rows across 5 distinct days (2026-09-18, 23, 24, 25, 26) since the trigger exemption landed on 2026-09-17, against 57 sessions opened since 2026-09-11. Most chats appear to open without a resolvable domain slug and get "retrieval: SKIPPED — no active domain slug resolved at init". Measure this from receipts before prioritising any retrieval work; if most inits skip, no hierarchy would help either.

**Action:** port the two-lane retrieval into the product's session-bootstrap and recall (the SQL exists and is proven); make the handoff one row per goal, keyed by `goal_id`, with the kickoff naming the goal; correct checkpoint's claim. Do not build a five-level hierarchy, per-project brains or per-project CLAUDE.md files.

### 3.3 The complete work/learning loop with real-world results — ADD (small)

**KJ:** INPUT → THINK → BUILD → OUTPUT → REAL-WORLD RESULT → FEEDBACK → MEMORY.

**MOM today has every arrow except one:**

- INPUT / THINK: interview ("What does success look like? What's the real outcome?"); spec-refine ends with a "Built vs. quoted" check.
- BUILD: deploy upserts the goal row and working rows; `delegations` logs each subagent spawn with `verdict_used`.
- OUTPUT / DONE: `done_when` with kind `sql | shell | manual`. reconcile auto-closes only on "A truthy SINGLE value → DONE (auto)" or a shell run whose last line is "DONE-WHEN-RESULT: SATISFIED". Every documented example checks that an artifact exists: a count of 48 files, a grep, a version string. Today 541 of 588 memory rows and 93 of 192 spinoffs are `manual`, outside auto-close.
- FEEDBACK: wrap scans the chat for "Mistakes … Workarounds … Surprises … Friction" and routes each lesson to one home. insights reads session hygiene and goal throughput; revenue appears only as a ranking hint ("money domains … outrank infra/meta"). Dream proposes retiring memos unused for 60 days. All of it is feedback about **process**.
- REAL-WORLD RESULT: designed, never wired. `deploy_memory.outcome`, column comment "What happened after the memo was acted on (free text, NULL until known)", is NULL on 588 of 588 rows; close says "Leave `outcome` NULL: a later session sets it on evidence", and no skill sets it. `public.sales` (Gumroad Ping webhook; `offer_code=PIN5` marks Pinterest attribution) holds 0 rows and nothing reads it into a goal. `loops.evidence` holds topic recurrence. Dream's inputs are internal brain state only.
- The right shape already exists in the same database: the `factory` schema (2026-09-19) has `experiments` (hypothesis, kill_criteria, success_criteria, result, lesson_id), `metrics`, `lessons` ("Every closed experiment must reference one"), `failure_reports` and `graveyard` (revenue_cents, customers, failure_point), and `decisions` linked to `pending_confirmations`. It is a separate product with 4 experiments and 0 metrics, not connected to goals.

**Gap:** genuine, and cheap to close. This is the one thing KJ's loop names that MOM lacks.

**Action (minimum):** (1) at goal close, one question, "what happened in the world?", written to `outcome` with a kind in the value JSON (`revenue | response | metric | none-yet`); (2) one Dream lane-M clause: propose an outcome check-in for goals done ≥30 days with `outcome` NULL, the same way it proposes stale-memo retirement; (3) when sales exist, map `public.sales` rows onto the mom-product goal's outcome. insights then gets a fifth bucket, "what worked", for free. Reuse the factory vocabulary; do not build a second experiments schema.

### 3.4 Strong provenance — ALREADY EXISTS (core); IMPROVE three fields; FUTURE for the model ledger

**KJ:** one rule separating AI-generated text from his own writing.

**MOM today, per memory row (`deploy_memory`):** `agent` (the writer's role: orchestrator, close, brain, dashboard, claude-code, driver…), `created_session_id` (set on 512 of 588), `source_type` (comment: "Who wrote the row: legacy | session-close | deploy | reconcile | manual. Writers stamp it; nothing rewrites history."), `confirmations` ("Times a later session confirmed the row still true. Default 1 = written once, never re-confirmed."), `last_used_at`, two `updated_at` triggers, `status='superseded'` plus `value.superseded_by`, `version_anchor`, lease fields.

**Around it:** `policies.updated_by` (48 of 69 name Dustan); `policy_proposals.proposed_by` with a `proposed → approved → live` status that only Dustan advances (wrap "only ever writes `proposed`"); `pending_confirmations.confirmed_by`; `dream_proposals` with `created_by`, `reviewed_by_session`, `verdict`, `review_note`, `executed_by_session`, `execution_evidence` and a mandatory `base_sha256` for file targets, the strongest chain in the system; `brain_edges.created_by` and `evidence`; `delegations.model`. Governance already codifies KJ's rule and goes further: policy #24 (dated records are append-only), #36 (no provenance claim before the artifact exists), #40 and #51 (a relayed figure is a claim; never attribute what you cannot quote), #57 (raw output of disagreeing checks goes into a memo), #64 (a justifying figure is re-run by an independent agent first). The `factory.claims` table (377 rows) is a complete provenance ledger: kind `fact | assumption | estimate | inference | unverified`, `source_url` required for a fact, `agent`, `model`, `session_id`, `verified_by`, `verified_at`, `superseded_by`.

**What is dead or loose:**

1. `confirmations` = 1 on 588 of 588 rows. Nothing increments it, so "still true?" is unknowable.
2. `source_type` = `legacy` on 565 of 588; only `session-close` (17) and `deploy` (6) have been written since the column landed on 2026-09-16.
3. Model identity is recorded nowhere on memory rows (only `delegations.model` and `factory.claims.model`). In the product, `agent` is NULL on end-session and checkpoint rows and is used for exactly one decision (rows from the dashboard capture box are never auto-checked).
4. `confirmed_by` is free text with 99 distinct values (`dustan`, `artifact`, `claude-observed`, session ids, whole sentences). Not queryable.
5. Policy #12 ("created_session_id must be stamped structurally … a BEFORE INSERT trigger") is not implemented. The table's five triggers are the domain guard, two `updated_at` touches, `on_goal_done` and `protect_deleted_goal_meta`. 76 rows are NULL.
6. The product schema predates all of `source_type`, `confirmations`, `last_used_at` and `outcome`.

**Verdict:** ALREADY EXISTS for who, when, which session, verified, modified, and approved at the proposal level. **IMPROVE:** put surface and model into `agent` (`claude-code/opus`, `cowork/sonnet`, `dustan`, `chatgpt-paste`); increment `confirmations` when retrieval re-loads a row or reconcile re-verifies it; constrain `confirmed_by` to a small vocabulary; add the policy #12 trigger; ship the four columns in the next product cut. **FUTURE:** the per-model results ledger is already specified (plan v0.3: `ai_results` with `source`, `model_id`, `packet_hash`, Claude's `verdict`; v0.4 §10.9: "provider, model, model_version, tokens, estimated_cost, timestamps, status") and gated out of v4.x by §10.14. When it comes, reuse the `factory.claims` shape rather than a third design.

### 3.5 Onboarding — IMPROVE, top priority

**KJ:** download → open → run setup → answer questions → AI builds your brain → start working.

**MOM as shipped (START-HERE "STEP SCRIPT", 14 steps):**

- Buyer-side: install the Desktop app and sign in ("the website chat on its own cannot install it"); extract the kit ("not Downloads"); two settings toggles plus two typed lines of Instructions; make an empty MOM folder and connect it (Path A); add the plugin marketplace and install Core (18 skills), or upload 18 skills one at a time where there is no Plugins menu; create a Supabase account, a project and a database password, copy the Project ID; add a custom connector with a pasted URL and authorize it ("On the Free plan this is your one custom connector"); answer the 9-question About-Me interview and paste the block; wait for the license key ("emailed to you within one business day of purchase … setup pauses here until the key arrives"); possibly install Node.js so `verify-license.cjs` can run; answer three yes/no setup questions; paste the About-Me into Settings; open a new chat for onboarding-interview (8 questions) and head-check. The reader's count: about 20 buyer actions, about 15 interview answers, three accounts. Path B (Free plan, no folder access) adds about 13 drag/attach/save actions.
- Claude-side: a 1,912-line, roughly 154 KB SQL provisioning script sent in one call, plus roughly 53 KB of verification SQL. brain-setup's SKILL.md alone is about 69k tokens by the kit's own bytes ÷ 4 rule.
- Value gate: "/recall throws SQL errors without the tables it creates." Nothing works before step 10, and step 10 waits on an email.
- What happened: "A real first-time buyer uploaded the kit to a plain chat, had no Desktop app, and Claude asked 'what would you like to do'" (PATCH-NOTES). README: "a guided first run built after a real first-time buyer got stuck at the first message." The round-2 audit file: "no Cowork tab, a Setup Guide that assumed Windows, and a Claude that wanted to review the zip before starting." Hostile ChatGPT rounds on cuts 1o, 1u, 1y and 2a each returned NOT CLEARED; the cut-2b round returned nine findings (R2B-01..09).
- No setup-time estimate exists in any buyer document. Support: "There is no human support for this product."

**Structural friction that stays:** the Supabase account (it *is* the "database you own" promise) and some form of license check. Everything else is removable:

1. **The one-business-day key.** Deliver the key at purchase (Gumroad license keys, or an instant email), or let the first run proceed on a grace key and verify on the next run. This one change removes the only hard stop in the flow.
2. **One step count.** Six buyer-visible steps (app, kit folder, skills, Supabase, connector, key), everything else done by Claude, and the 7- and 14-step variants retired.
3. **Path B is where the buyer stalled.** Either make the Free-plan path the tested primary path or state "Pro plan required" on the listing. Then run a fresh Mac Free-plan install with a stopwatch before cut 2c ships and print the minutes in the Handbook.
4. **Interview once.** The About-Me interview (9 questions) and onboarding-interview (8) overlap; one interview run by Claude should feed both.

---

## 4. Do not copy, with the reasons from the data

1. **Obsidian or Markdown as the source of truth.** The brain holds 588 memos, 192 spinoffs, 417 confirmations, 69 policies, 829 edges, two cron jobs and five triggers that enforce vocabulary and lifecycle. None of that is governable in a vault. MOM already has the Markdown tier where it helps: memory.md as a cache, lessons.md, backups, and (in the Dream spec) a hash-stamped `brain_files` mirror.
2. **Per-project CLAUDE.md or isolated project folders.** They fragment the one-writer session model and contradict the product's own positioning.
3. **A "general and soldiers" split.** MOM's equivalent is domain-scoped retrieval plus per-goal kickoffs; the fix is §3.2, not a new layer.
4. **Claude-only as a virtue.** The personal system is Claude-only in its skills today and the product is Claude-only by design; the multi-model lane is a plan. Do not market multi-model until §10.14 lifts, and do not design it out.

---

## 5. Found along the way (not on KJ's list)

1. **Skill text drifts from the live database in its own favour.** session-init says "every rows-path init prints 'last_used_at SKIPPED — updated_at triggers not exempt'". The trigger was exempted on 2026-09-17 and 60 rows now carry stamps.
2. **Two dead columns:** `outcome` (588 NULL) and `confirmations` (588 × 1).
3. **Policy #12's session-stamp trigger is unimplemented**; 76 memory rows have no session.
4. **The personal handoff is one global slot**, and `active_sessions.domains` is always empty.
5. **Product recall does not load `context_*` rows**; checkpoint claims it does.
6. **Buyer documents disagree on the step count (14 / 7 / 6)**, and the generated About-Me names menu tabs that do not exist.
7. **32 of 210 sessions (15%) ended by force-close**, 11 closed without wrap, and `sessions.env` is NULL on 204 of 210, so surface (Cowork vs Claude Code) is unknown for nearly every session.
8. **plan.md on Drive is v0.3**; mom-build's README quotes v0.4 §10.10–10.14. The newer spec is not mirrored to Drive.
9. **This category was already studied**: the 2026-09-18 comparison ranked "Second Brain Starter Kit – Obsidian + Claude Code" the closest paid analogue. KJ's system is a second look at the same category, and the borrow list from that study still applies.

---

## 6. Recommended actions, ranked (answer yes/no by number; "yes" = do it)

1. **Onboarding:** key at purchase or a grace key; one six-step buyer path; the Free-plan path tested on a fresh Mac with a stopwatch; one interview. **Recommended: yes.** Cost: documents, Gumroad settings, one brain-setup step edit. Value: the launch.
2. **Product retrieval:** port session-init 4b's two-lane query into session-bootstrap and recall; correct checkpoint's claim. **Recommended: yes.** Cost: one SQL statement moved, two skill edits.
3. **Outcome capture:** write `outcome` at goal close; Dream proposes an outcome check-in at 30 days; map sales when they exist. **Recommended: yes.** Cost: one close sub-step, one `dream_m` clause.
4. **Provenance hygiene:** `agent` = surface/model; `confirmations` incremented on re-load or re-verify; a `confirmed_by` vocabulary; the policy #12 trigger; the four columns in the next product cut. **Recommended: yes, bundled into the next migration**, not its own project.
5. **Three-sentence model on every buyer surface**, buyer vocabulary ≤10 concepts on day one, aliases removed. **Recommended: yes, inside the T16 declutter.**
6. **Per-goal handoff rows**, personal lane only. **Recommended: yes, after 1–3.** A personal-productivity fix, not a launch item.
7. **Hierarchy, per-project brains, Markdown-as-truth, Obsidian.** **Recommended: no.**
8. **Multi-model provenance ledger.** **Recommended: later**, when §10.14 lifts, reusing the `factory.claims` shape.

---

## 7. Verification

Independent verifiers (agents that did not do the reading) were given the claims in this document, told to assume mistakes exist, and asked to report only. Results are recorded here.

_Pending at the time of writing; see the section update in the same commit series._

---

## Appendix A — evidence index

| Claim | Source | How checked |
|---|---|---|
| `outcome` NULL on 588/588; `confirmations` = 1 on 588/588 | `public.deploy_memory` | `GROUP BY` counts, 2026-09-27 |
| Column comments for `outcome`, `source_type`, `confirmations`, `last_used_at` | `pg_attribute` + `col_description` | read 2026-09-27 |
| `source_type`: legacy 565, session-close 17, deploy 6 | `public.deploy_memory` | `GROUP BY source_type, agent` |
| `created_session_id` NULL on 76/588 | `public.deploy_memory` | count |
| `done_when_kind`: manual 541 / sql 22 / shell 17 / NULL 8 (memory); manual 93 / shell 76 / sql 23 (spinoffs) | both tables | counts |
| Domains: 7 rows, 6 active; trigger `deploy_memory_domain_guard` | `public.domains`, `pg_trigger`, `pg_get_functiondef` | read |
| Triggers on `deploy_memory` (five; no session stamp) | `pg_trigger` | listed |
| `last_used_at` set on 60 rows over 5 days | `public.deploy_memory` | count, distinct dates |
| `sessions`: 210; scope `general` 121; force_closed 32; closed unwrapped 11; env NULL 204; projects set 107 | `public.sessions` | counts |
| `active_sessions.domains` = `{}` on all 3 rows | `public.active_sessions` | read |
| Policies 69 live; proposals 81 (14 proposed); `updated_by` distribution | `public.policies`, `public.policy_proposals` | read in full |
| Dream: 49 proposals, 43 accepted / 6 rejected, all lane M op delete; cron `dream-m` 03:20 daily; `reap-abandoned-sessions` hourly | `public.dream_proposals`, `cron.job` | read |
| `brain_edges` 829: ran_skill 594, cites 200, spawned 35, goal→loop 2; 7 allowed rels | table + check constraint | counts |
| `public.sales` 0 rows; table comment names the Gumroad Ping webhook and `offer_code=PIN5` | `public.sales` | count, comment |
| `factory` schema: 22 tables; claims 377, experiments 4, metrics 0, lessons 10 | `pg_stat_user_tables`, `information_schema.columns`, table comments | read |
| close 182,187 B; FULL 20 steps / LITE 17; writes 8 tables; C4 retrieval 5+5; handoff one global slot ≤150 words; outcome "Leave NULL" | `close/SKILL.md`, `session-init/SKILL.md` (synced skills on disk) | reader agent, line citations |
| Product: 14 steps; ~20 buyer actions; 3 accounts; key "within one business day"; ~154 KB SQL; recall loads no `context_*` rows; checkpoint claims it does; 18 + 2 tables; step counts 14/7/6; ~40 concepts | v4.1 kit zip on Drive (cut 2b), extracted | reader agent, quotes |
| First-buyer stall quotes | PATCH-NOTES.txt, README.txt, ROUND2-ALL-IN-ONE.md | quotes |
| Multi-model plan quotes; §10.14 "planned" | `mom-build/README.md` | read in full |
| plan.md on Drive is v0.3; Dream v0.6 internal-only; Gumroad/Handbook flatness quotes; competitor study of 2026-09-18 | Drive files (ids in the reader's report) | reader agent |
| Hostile audits R2B-01..09; Kimi lane dead; T16 declutter | `deploy_memory` memos 726 and 754 | read |

## Appendix B — numbers snapshot (2026-09-27, project `ompxlqmszgutlldtivph`)

| Table | Rows | Notes |
|---|---|---|
| deploy_memory | 588 | goals 75 (`goal_meta`), memos 344 (`context_*`), tasks 50, scout flags 29; status: done 211, active 104, permanent 85, open 55, superseded 49, context 46, pending 19 |
| sessions | 210 | first 2026-07-05; 57 since 2026-09-11 |
| spinoffs | 192 | done 118, deleted 36, declined 23, merged 13, ready 2 |
| pending_confirmations | 417 | 28 pending; skill_install 176, todo 154, manual_step 45 |
| policies / policy_proposals | 69 / 81 | 14 proposals open |
| loops | 17 | 2 active |
| brain_edges / dream_proposals | 829 / 49 | derived nightly |
| delegations | 74 | opus 52, sonnet 19, haiku 3 |
| domains | 7 | 6 active |
| skill_registry | 86 | `product_fit` ship / vendor |
| sales | 0 | webhook wired, pre-launch |
| factory.* | 22 tables | claims 377, opportunities 42, experiments 4, metrics 0 |

Goals open by domain: infra 3, cssi 5, digital 2, rt 2, mom-product 5. Memos by domain: infra 234, mom-product 65, digital 31, cssi 5, rt 1.
