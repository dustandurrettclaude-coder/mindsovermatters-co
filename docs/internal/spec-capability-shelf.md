# Spec: Capability Shelf + Uniform Agent Envelope

**Version:** 0.3 (refined against the live brain-graph-dream spec)
**Date:** 2026-09-21
**Status:** planning artifact. No implementation. Nothing in here has been executed.
**Not for publication** — this repo publishes to mindsovermatters.co.

**Changes from v0.2:** §9 rewritten against the actual text of
`1 BRAIN/Specs & Setup/2026-09-15-brain-graph-dream/plan.md` (v0.6), read 2026-09-21,
replacing the generic "Agent OS" guess. Four consequences folded back into the spec body:
the proposal channel is now `dream_proposals` rather than an invented one (§3.2, §4.2);
`delegations` records failures and cancellations, not just returns (§3.4); `procedures`
inherits the service_role-only RLS rule and the counts-only dashboard read (§2.3, §5); DDL
sequences explicitly behind Phase 1 (§6). Policy 60 remains unresolved.

---

## 0. Problem

Three problems, one root cause.

1. **Everything is resident.** All installed skills sit in context every session, each
   pattern-matching every sentence. Adding capability makes existing capability harder to
   trigger. This does not scale past a few dozen; there are 86 registered.
2. **Agents are ad hoc.** 61 spawns averaging 167k tokens with no shared input contract, no
   shared output contract, and verdicts returned as prose.
3. **State drifts.** `install_confirmed` is wrong on 20 of 41 rows. Tracking state costs
   more than the state is worth once it is large enough to drift.

Root cause: capability is held in *residence* rather than behind *retrieval*.

## 1. Core insight — the shelf already exists

`public.skill_catalog` holds **84 rows** with exactly the columns a retrieval index needs:

```
name, triggers, summary, domains, works_with, bucket, eli10, runs_within, updated_at
```

It is currently a read model for the Skills-tab dashboard, maintained automatically by
`skill-packager`. It does not need to be built. It needs to be **promoted from a display
table to the routing index**, with the dashboard continuing to read it unchanged.

## 2. Architecture

### 2.1 Two tiers

**Tier R — Resident core.** Installed as real skills, always in context. Target ≤ 12.

```
session-init · close · wrap · deploy · recall · spinoff · reconcile
model-router · skill-packager · btw · confirm-recommendations · shelf
```

**Tier S — Shelved procedures.** Not installed as skills. Body stored in Supabase,
discovered through `skill_catalog`, fetched and executed on demand by `shelf`.

> **v0.2 fix — name collision.** v0.1 called the router `dispatch`. `dispatch` v2.2.1
> already exists in `skill_registry` with 4 recorded uses. Two capabilities answering one
> name is a trigger collision and a hard block under the Skill Impact Audit. The router is
> now **`shelf`**, which collides with nothing in the 86-row registry.

### 2.2 The honest trade

Claude Code / Cowork decides what is resident; an installed skill is in context. So Tier S
is only real if those skills are **actually uninstalled** and their bodies live in the
database.

**The cost:** a shelved procedure loses the harness's automatic trigger matching. `shelf`
must do that matching against `skill_catalog.triggers`. If `shelf` misses, the capability
silently does not fire.

This is a genuine regression risk, not a free win. Phase 2 (§6) proves the match rate
before anything is uninstalled. If shadow mode shows poor accuracy, **this spec should be
abandoned**, not forced.

### 2.3 Schema changes (all additive)

```sql
alter table public.skill_catalog
  add column tier text default 'R' check (tier in ('R','S')),
  add column body_ref text;          -- null for Tier R; storage key for Tier S

create table public.procedures (
  name          text primary key references public.skill_catalog(name),
  version       text not null,
  body          text not null,       -- the SKILL.md content
  output_schema jsonb,
  depends_on    text[],
  updated_at    timestamptz default now()
);
```

```sql
alter table public.procedures enable row level security;
create policy service_role_only on public.procedures
  for all to service_role using (true) with check (true);
```

> **v0.3 fix — RLS.** v0.2 omitted this. `procedures.body` holds full skill text, the same
> secrecy class as `dream_proposals.proposal`, which the live spec protects absolutely:
> *never a row policy on dream_proposals — RLS restricts rows, not columns or aggregates,
> so any such policy hands anon the full jsonb of every row it matches.* `procedures` gets
> the same treatment: service_role only, and any dashboard read goes through a SECURITY
> DEFINER view returning counts, never bodies.

`skill_registry` stays the source of truth for versioning and install state. No column is
dropped anywhere in this spec.

## 3. Uniform agent envelope

One input contract and one output contract for every spawn, whether it came from
`/deploy`, `shelf`, or a direct Agent call.

### 3.1 Input

```jsonc
{
  "task_type":     "multi-source-research",   // keys into public.model_routing
  "tier":          2,                          // effort tier, sets budget (§3.3)
  "objective":     "one sentence, the deliverable",
  "inputs":        { },                        // facts handed down, never reasoning
  "procedure_ref": "cssi-lead-gen",            // optional; shelf fetches procedures.body
  "memory_packet": [ ],                        // pre-assembled (§4.1) — agent cannot query
  "output_schema": { },                        // from skill_registry.output_schema
  "grants":        [ ],                        // capability list (§4.2), default empty
  "budget_tokens": 150000,
  "cancel_token":  "uuid"                      // §3.5
}
```

`task_type` → `model_routing` supplies `model` and `agent_type`. That table already exists
and already carries the routing decision; the envelope makes consulting it mandatory
rather than optional.

### 3.2 Output

```jsonc
{
  "status": "complete | partial | blocked | cancelled",
  "result": { },                    // must validate against the input output_schema
  "claims": [
    { "claim": "...", "evidence": "file:line | table.column | url",
      "verdict": "supported | unsupported | not_found" }
  ],
  "proposals": [ ],                 // public.dream_proposals rows (§4.2) — agent never applies
  "cost": { "tokens": 0, "tool_uses": 0, "duration_ms": 0 },
  "unknowns": [ ]
}
```

- **`claims` replaces prose verdicts.** Any `unsupported` blocks acceptance. This is the
  direct fix for the failure mode behind Perplexity's attribution lawsuits: their citations
  prove a source was in context, not that the sentence follows from it.
- **`unknowns` is mandatory.** An agent reporting no unknowns on a research task is
  reporting a bug.

### 3.3 Effort tiers

| Tier | Budget | Shape | Agent type |
|---|---|---|---|
| 0 | 0 spawns | answer from context | — |
| 1 | ≤ 40k | locate / confirm one fact | Explore, haiku |
| 2 | ≤ 150k | multi-source research | general-purpose, sonnet |
| 3 | current `/deploy` | 4+ independent workstreams | per `model_routing` |
| 4 | tier 3 + synthesis pass | irreversible or high-stakes | opus chair |

Budgets seed from the 61 existing `delegations` rows (observed mean 167,309 tokens, 832s)
and self-correct as `model_routing.avg_tokens` / `avg_tokens_n` accumulate. Three rows
carry measurements today; the envelope makes every spawn contribute one.

### 3.4 Recording — two writes, both mandatory

1. **`public.delegations`** — one row per spawn, written on **return, failure, or
   cancellation alike**. Modelled on Lane M, which catches its own exception and still
   writes both receipts: a run that produced nothing must still be countable, or the cost
   record silently under-reports exactly the spawns worth studying.
2. **`public.sessions.skills_used`** — `shelf` appends the procedure name on every shelved
   invocation.

> **v0.2 fix — broken consequence chain.** v0.1 omitted (2). `skill-scout` mines
> `skills_used` and needs ≥2 distinct sessions to suggest anything; `loop-scout` mines the
> same column. Without this append, shelving a capability makes it invisible to both
> scouts. Nothing errors — the scouts just quietly report less forever. Any implementation
> that drops this requirement silently degrades the system's ability to improve itself.

### 3.5 Cancellation

Every spawn carries a `cancel_token`. The parent may revoke it; the agent must exit at its
next tool boundary and return `status: "cancelled"` with partial `result` and accumulated
`cost`.

> **v0.2 addition.** Prompted by a real incident in this session: a verifier agent had to
> be killed at the harness level because it was generating repeated approval prompts. The
> harness kill worked, but the envelope had no notion of cancellation, so no partial result
> and no cost were recovered. An agent model without cancellation is incomplete.

### 3.6 Session budget ceiling

Per-spawn budgets do not bound a session. `shelf` and `/deploy` share a session-level token
ceiling; when remaining budget cannot cover the requested tier, the spawn is refused and
the caller is told, rather than silently downgraded.

## 4. Memory contract

### 4.1 Read — packets, not access

Agents do not query the brain. The parent assembles a **memory packet**.

> **v0.2 fix — redundancy.** v0.1 specified a new domain-scoped query. `session-init`
> already performs the C4 retrieval (board-open goals and memos for the session's domain).
> The packet is that existing retrieval's output, passed down. No second query path is
> introduced; two paths would drift.

Rationale for packets over access: 61 spawns × free query access is how an approval loop
happens, and an agent that queries freely cannot be held to a token budget.

### 4.2 Write — propose into the channel that already exists

`grants` defaults to empty. Agents never apply a change.

> **v0.3 fix — do not invent a second proposal channel.** v0.2 returned `memory_writes[]`,
> a new shape. `public.dream_proposals` already exists, is already wired to the dashboard's
> Diff pane, and already carries the review lifecycle (`verdict`, `reviewed_by_session`,
> `executed_at`, `execution_evidence`, plus the `dream_exec_needs_accept` constraint that
> makes executing an unaccepted proposal impossible). Agents write **that** row shape:
>
> ```
> lane · op (promote|update|delete|resolve|edge|feature) · ref_table · ref_id
> base_sha256 (file targets only) · proposal {before, after, why, dependencies[]}
> created_by
> ```
>
> A second channel would mean a second review surface, a second diff renderer, and a second
> place for a verdict to be lost.

> **v0.3 fix — permissions.** v0.1 had `write_scope: "none"`, a binary. `grants` is an
> explicit capability list (e.g. `["read:deploy_memory:cssi", "propose:spinoffs"]`). Empty
> by default; a grant is named or it does not exist.

Rationale for packets over query access (§4.1): 61 spawns × free query access is how an
approval loop happens, and an agent that queries freely cannot be held to a token budget.

This is the house principle, quoted from the spec's §0: **THE DREAM PROPOSES, CLAUDE
DISPOSES** — no background pass changes a goal status, merges a row, or deletes anything.
The envelope extends it from the two lanes to every model-backed agent.

`brain_edges` stays derived and rebuildable by `public.dream_m()`. No agent writes edges.

### 4.3 Tier authority for `reconcile`

> **v0.2 fix.** `reconcile` checks `version_anchor` drift against `skill_registry`. Rule:
> **`skill_registry` remains authoritative for both tiers.** `procedures.version` must
> equal `skill_registry.version` for the same name; a mismatch is a reconcile finding, not
> a second source of truth. Tier S changes where the *body* lives, never where *version
> truth* lives.

### 4.4 `dream_m()` and the new table

> **v0.2 fix.** Documented node kinds are goal, spinoff, memo, session, skill, policy,
> loop, feature. **`procedures` rows are not nodes.** A procedure is the body of a skill
> that already has a `skill` node; adding a second node for the same capability would
> double-count every `session→skill` edge (currently 532 of 733). `dream_m()` needs no
> change.

## 5. Dashboard contract

**Non-negotiable: the Skills tab keeps working throughout.** `skill_catalog` is read by the
dashboard and written by `skill-packager`; this spec adds columns and changes neither.

Gains, once the columns exist:

1. **Resident vs shelved** — `tier`. If Tier R creeps past 12, that is the drift signal.
2. **Cost per capability** — join `delegations` → `model_routing.task_type` → catalog name.
3. **Last actually used** — from `skills_used`, surfacing the 21 never-used without an audit.

**Two house rules this inherits.** (1) *Buttons never write* — every dashboard control
copies a one-line instruction for Claude Code to run; no pane added here gets a write path.
(2) The dashboard is delivered **as a file to drop over the source**, never through
`update_artifact` on the bridge.

`skill-packager` gains one responsibility: set `tier` and, for Tier S, write
`procedures.body` alongside the existing catalog upsert.

> **MUST VERIFY before Phase 1.** How `skill-packager` writes `skill_catalog` is unknown
> without reading its SKILL.md, which the Skill Impact Audit says not to do. Two failure
> modes: an upsert leaves new skills at `tier='R'` forever and the shelf never grows; a
> full-row replace wipes `tier` on every repackage. This is an open question, not an
> assumption.

## 6. Migration — phased, reversible, non-destructive

No phase deletes anything. Each phase is independently abandonable.

- **Phase 0 — Truth.** Correct `install_confirmed` on the 20 proven-used rows. Resolve the
  5 version-drift rows. *No new capability.*
  **Blocked on:** the system-updating workflow currently running. It is the most likely
  other writer to `skill_registry`. Re-read the registry after it completes; its output may
  change or fix some of these findings.
- **Phase 1 — Columns.** Add `tier`, `body_ref`, create `procedures`. Classify all 84
  catalog rows on paper. **No behaviour change.**
  **DDL ordering is not negotiable.** Ruling P2 fixes the order: verified backup first,
  then the already-planned DDL. brain-graph-dream Phase 1 has two `done_when` legs still
  false. Its own sequencing note records that writing a clause before its table exists
  raises 42P01 rather than returning false — the failure mode is real and already cost
  them a round. This spec's DDL queues **after** Phase 1 closes, never beside it.
- **Phase 2 — Shadow.** `shelf` matches every user turn against `skill_catalog.triggers`
  and logs what it *would* route beside what actually fired. Changes nothing.
  **Gate: poor match accuracy over ~20 sessions ⇒ stop and abandon §2.**
- **Phase 3 — First shelf.** Uninstall only the 21 never-used skills. Nothing that has ever
  fired is touched.
- **Phase 4 — Envelope.** `/deploy` and `shelf` emit §3.1 and validate §3.2. `claims`
  enforcement on.
- **Phase 5 — Widen.** Only if Phase 3 held.

## 7. Decisions needed

1. **Policy 60 vs Tier S — unresolved, and only you can resolve it.** Policy 60 says a
   skill draft is not delivered until its Cowork install prompt exists, and
   `skill-packager` files an install checkbox row for every packaged skill. A shelved
   procedure **has no install step**. Either policy 60 gains an explicit Tier S exemption,
   or Tier S violates a live policy. This spec does not patch around it.
2. Is the Tier R list in §2.1 right?
3. `procedures.body` in Postgres, or files in git with the row holding a path?
4. `claims` enforcement hard-block or warn-only at first?
5. Poor Phase 2 match rate — abandon, or rewrite `triggers` and retry once?

## 8. What this spec does not do

- It does not make the system smaller. It makes less of it resident. 86 capabilities remain
  86 things.
- It does not reduce coupling among the Tier R core.
- It does not fix the 525:7 maintenance ratio. It makes it *measurable per spawn*, which is
  a precondition, not a fix.
- It does not touch n8n (MCP server failed to connect this session, 404). Nothing here
  depends on it.
- It adds `shelf` as a new resident skill — one more meta-skill in a system whose measured
  problem is meta-skill sprawl. That cost is real and is the strongest argument against
  this spec.

---

## 9. Fit with brain-graph-dream (the real spec)

> **v0.3.** v0.2 guessed at "Agent OS". The actual system is
> `1 BRAIN/Specs & Setup/2026-09-15-brain-graph-dream/plan.md` **v0.6**, read in full on
> 2026-09-21, whose parent is **multi-model-brain v0.3**
> (`1 BRAIN/Specs & Setup/2026-09-11-multi-model-brain/`, which holds the paste lane,
> `ai_results` and the Studio tab). Phase 1 is live. This section is now an assessment, not
> an analogy.

### 9.1 What is already built

**Dream Mode** is the user-facing name for the whole loop: *Lane M notices, Lane S
proposes, Dustan rules in the Dreams tab, Claude Code applies the ruling in a session.*

- **Lane M** (Phase 1, live): pg_cron `dream-m` at `20 3 * * *`, pure SQL
  (`public.dream_m(trigger)`), deliberately off the hour-15 slot that
  `reap-abandoned-sessions` occupies. Derives edges, flags exact duplicates and 60-day
  stale `context_%` memos as proposals. Writes **only** `brain_edges`, `dream_proposals`,
  `system_cache`.
- **Lane S** (Phase 2): pg_cron Sunday `45 3 * * 0` → pg_net → Edge Function `dream-s` →
  **Gemini**. Reads Lane M's flags plus a 2-hop Neo4j neighbourhood; writes proposals only.
- **Dreams tab**: Readiness, Inbox, Diff, Graph. Buttons never write — they copy
  `dream verdict <proposal_id> accepted|rejected|deferred`.
- Six curation ops: promote, update, delete, resolve, edge, feature. `delete` means
  `status='superseded'` or a file into `DELETE/` with a MANIFEST row — **never a hard
  delete, by any lane or by Claude.**

### 9.2 Four things this spec must change to fit — all folded into v0.3 above

1. **Lane M is not an agent under the envelope.** It is a scheduled SQL function with no
   parent session and no model. §3 governs **model-backed spawns only**. Without that line,
   the two specs contradict each other on who may write `dream_proposals` directly.
2. **`dream_proposals` is the proposal channel.** Folded into §3.2 and §4.2.
3. **`procedures` inherits service_role-only RLS and a counts-only dashboard read.** Folded
   into §2.3 and §5.
4. **Receipts on failure, not just return.** Folded into §3.4.

### 9.3 What their design does better than v0.2 — adopt it

**The readiness gate beats per-spawn budgets.** Lane S *exits with a receipt and no model
call* unless `dream_readiness.score` ≥ threshold, or the run was started by hand — so a
quiet week costs zero Gemini tokens. My §3.3 caps what a run may spend; their gate decides
whether the run happens at all. That is the stronger control, and §3.6's session ceiling
should gain the same shape: a spawn with nothing to work on should be refused, not
budgeted.

Their honesty discipline is also worth copying verbatim: the readiness weights and the
threshold of 60 are labelled **"unmeasured guesses"** in the spec itself, stored in the
receipt so they can be tuned, and scheduled for calibration after 14 nightly readings. My
§3.3 tier budgets are exactly the same kind of guess and should carry the same label.

### 9.4 Where this leaves the Perplexity and Poe comparison

Two of the earlier recommendations are weaker than I presented them:

- **"Model Council needs a cross-provider gateway like Poe."** Lane S already crosses
  providers — pg_cron → pg_net → Edge Function → Gemini, with keys in Supabase Vault. The
  pattern exists and is specified; a council would extend it, not introduce it.
- **"The empty `loops` table is a failure signal."** Already ruled on:
  *KEEP loops, loop-scout, skill-scout, reflect, insights — non-use is not evidence of
  failure.* Withdrawn.

One comparison survives intact, and it is the one this spec rests on: capability held in
**residence** does not scale, and `skill_catalog`'s 84 rows are already the index that
would let it be held behind **retrieval** instead.

### 9.5 Verdict

The capability shelf is **compatible but subordinate**. It shares the proposal channel, the
propose-never-apply principle, the no-hard-delete rule, the buttons-never-write rule and
the RLS posture. It introduces no competing surface.

It is also **not next**. `SPEC-consistent-system-plan-2026-09-06.md` already contains
"SHELF 7 deliberately-invoked skills → 35 installed" — a shelving decision reached at the
house bar of /spec-refine v2.3, three rounds, zero must-fix. This spec has had one
refinement pass, by its own author, and has not met that bar. Ruling D2 set the precedent
directly: *Dream Phase 2 now = NO, revisit after Phase 1 runs two weeks.* Phase 1 still has
two `done_when` legs open.

**Therefore: reconcile §2 against the consistent-system shelving decision first, take this
through /spec-refine to zero must-fix second, and land nothing until Phase 1's composed
boolean returns true.**
