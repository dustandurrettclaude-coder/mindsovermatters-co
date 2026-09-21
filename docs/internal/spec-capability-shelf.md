# Spec: Capability Shelf + Uniform Agent Envelope

**Version:** 0.1 (draft, unrefined)
**Date:** 2026-09-21
**Status:** planning artifact. No implementation. Nothing in here has been executed.
**Not for publication** — this repo publishes to mindsovermatters.co.

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

This is the whole design. Everything below follows from it.

## 2. Architecture

### 2.1 Two tiers

**Tier R — Resident core.** Installed as real skills, always in context. Target ≤ 12.
Candidate set (the session loop plus anything that must fire without being asked):

```
session-init · close · wrap · deploy · recall · spinoff · reconcile
model-router · skill-packager · btw · confirm-recommendations · dispatch
```

**Tier S — Shelved procedures.** Not installed as skills. Body stored in Supabase,
discovered through `skill_catalog`, fetched and executed on demand by `dispatch`.

### 2.2 The honest trade

Claude Code / Cowork decides what is resident; a skill that is installed is in context.
So Tier S is only real if those skills are **actually uninstalled** and their bodies live
in the database.

**The cost of that:** a shelved procedure loses the harness's automatic trigger matching.
`dispatch` must do that matching instead, against `skill_catalog.triggers`. If `dispatch`
misses, the capability silently does not fire.

This is a genuine regression risk, not a free win. It is the reason for shadow mode in
Phase 2 (§6) — the router's matching must be proven against real sessions before anything
is uninstalled. If shadow mode shows poor match rates, **this spec should be abandoned**,
not forced.

### 2.3 Schema changes (all additive)

`skill_catalog` — two new columns, no existing column touched, dashboard unaffected:

```sql
alter table public.skill_catalog
  add column tier text default 'R' check (tier in ('R','S')),
  add column body_ref text;          -- null for Tier R; storage key for Tier S
```

New table for shelved bodies:

```sql
create table public.procedures (
  name          text primary key references public.skill_catalog(name),
  version       text not null,
  body          text not null,       -- the SKILL.md content
  output_schema jsonb,               -- mirrors skill_registry.output_schema
  depends_on    text[],
  updated_at    timestamptz default now()
);
```

`skill_registry` stays the source of truth for versioning and install state. No column is
dropped anywhere in this spec.

## 3. Uniform agent envelope

"Run many agents the same way" = one input contract and one output contract for every
spawn, whether it came from `/deploy`, `dispatch`, or a direct Agent call.

### 3.1 Input

```jsonc
{
  "task_type":     "multi-source-research",   // keys into public.model_routing
  "tier":          2,                          // effort tier, sets budget (§3.3)
  "objective":     "one sentence, the deliverable",
  "inputs":        { },                        // facts handed down, never reasoning
  "procedure_ref": "cssi-lead-gen",            // optional; dispatch fetches procedures.body
  "memory_packet": [ ],                        // pre-assembled rows (§4.1) — agent cannot query
  "output_schema": { },                        // from skill_registry.output_schema
  "write_scope":   "none",                     // default none (§4.2)
  "budget_tokens": 150000
}
```

`task_type` → `model_routing` supplies `model` and `agent_type`. That table already exists
and already carries the routing decision; the envelope just makes consulting it mandatory
rather than optional.

### 3.2 Output

```jsonc
{
  "status": "complete | partial | blocked",
  "result": { },                    // must validate against the input output_schema
  "claims": [
    { "claim": "...", "evidence": "file:line | table.column | url", 
      "verdict": "supported | unsupported | not_found" }
  ],
  "memory_writes": [ ],             // PROPOSED rows — the agent does not write them
  "cost": { "tokens": 0, "tool_uses": 0, "duration_ms": 0 },
  "unknowns": [ ]                   // what it could not resolve, stated not smoothed over
}
```

Two rules make this worth having:

- **`claims` replaces prose verdicts.** Any `unsupported` blocks acceptance. This is the
  direct fix for the failure mode that produced Perplexity's attribution lawsuits: their
  citations prove a source was in context, not that the sentence follows from it.
- **`unknowns` is mandatory and may not be empty-by-default.** An agent that reports no
  unknowns on a research task is reporting a bug.

### 3.3 Effort tiers

| Tier | Budget | Shape | Agent type |
|---|---|---|---|
| 0 | 0 spawns | answer from context | — |
| 1 | ≤ 40k | locate / confirm one fact | Explore, haiku |
| 2 | ≤ 150k | multi-source research | general-purpose, sonnet |
| 3 | current `/deploy` | 4+ independent workstreams | per `model_routing` |
| 4 | tier 3 + synthesis pass | irreversible or high-stakes | opus chair |

Budgets are seeded from the 61 existing `delegations` rows (observed mean 167,309 tokens,
832s) and corrected as `model_routing.avg_tokens` / `avg_tokens_n` accumulate. Three rows
carry measurements today; the envelope makes every spawn contribute one.

### 3.4 Recording

Every spawn writes exactly one `public.delegations` row on return — which is that table's
stated purpose already. The envelope makes it automatic rather than remembered.

## 4. Memory contract

### 4.1 Read — packets, not access

Agents do not query the brain. The parent assembles a **memory packet** and passes it in
`memory_packet`. Rationale: 61 spawns × free query access is how an approval loop happens,
and an agent that queries freely cannot be given a token budget that holds.

Packet assembly, scoped by `domain`:

```sql
-- open goals + recent memos for the domain, capped
select key, value, status, done_when, done_when_kind
from public.deploy_memory
where domain = $1 and status in ('open','in_progress')
order by updated_at desc limit 12;
```

### 4.2 Write — propose, never apply

`write_scope` defaults to `none`. Agents return `memory_writes` as **proposals**; the main
thread applies them.

This is not a new principle — it is the rule already written on
`public.dream_proposals`: *the dream proposes, Claude disposes; no lane changes a status,
merges a row, or deletes anything.* The envelope extends that existing rule from Dream Mode
to all agents.

`brain_edges` stays derived and rebuildable by `public.dream_m()`. No agent writes edges.

### 4.3 What memory gains

Today `sessions.skills_used` records that a skill ran. With the envelope, `delegations`
records what each agent was *given*, what it *returned*, what it *cost*, and what it could
not resolve. That is the first time the brain would hold enough to answer "was that spawn
worth it" — which is the question the 525:7 ratio exists to raise.

## 5. Dashboard contract

**Non-negotiable: the Skills tab keeps working throughout.** `skill_catalog` is read by the
dashboard and written by `skill-packager`; this spec adds columns and changes neither
behaviour.

What the dashboard gains, for free, once the columns exist:

1. **Resident vs shelved** — `tier`, so the resident core's size is visible. If Tier R
   creeps past 12, that is the drift signal.
2. **Cost per capability** — join `delegations` → `model_routing.task_type` → catalog
   `name`. Answers "what does this skill cost me when it runs."
3. **Last actually used** — from `sessions.skills_used`, surfacing the 21 never-used
   without anyone running an audit.

`skill-packager` gains one responsibility: set `tier` and, for Tier S, write
`procedures.body` alongside the existing catalog upsert.

## 6. Migration — phased, reversible, non-destructive

No phase deletes anything. Each phase is independently abandonable.

- **Phase 0 — Truth.** Correct `install_confirmed` on the 20 proven-used rows. Resolve the
  5 version-drift rows (install the update or retire the spec). Nothing else proceeds on a
  registry known to be wrong. *No new capability.*
- **Phase 1 — Columns.** Add `tier`, `body_ref`, create `procedures`. Classify all 84
  catalog rows R or S on paper. **No behaviour change.**
- **Phase 2 — Shadow.** `dispatch` matches every user turn against `skill_catalog.triggers`
  and logs what it *would* have routed, next to what actually fired. Changes nothing.
  **Gate: if match accuracy is poor over ~20 sessions, stop here and abandon §2.**
- **Phase 3 — First shelf.** Uninstall only the 21 never-used skills and serve them from
  `procedures`. Lowest possible risk: nothing that has ever fired is touched.
- **Phase 4 — Envelope.** `/deploy` and `dispatch` emit the §3 input contract and validate
  the §3 output contract. `claims` enforcement on.
- **Phase 5 — Widen.** Shelve further Tier S candidates only if Phase 3 held.

## 7. Decisions needed before Phase 1

1. Is the Tier R list in §2.1 right, or does something else have to always be resident?
2. `procedures.body` in Postgres, or files in the repo with the row holding a path?
   (Postgres = one source of truth; files = diffable in git.)
3. Should `claims` enforcement be hard-block or warn-only at first?
4. Is a poor Phase 2 match rate an abandon, or a signal to rewrite `triggers` and retry?

## 8. What this spec does not do

- It does not make the system smaller. It makes less of it resident at once. Capability
  count is unchanged; 86 skills remain 86 things.
- It does not reduce coupling between the core-loop skills. Tier R still interlocks.
- It does not address the 525:7 maintenance ratio. It makes that ratio *measurable* per
  spawn, which is a precondition for addressing it, not a fix.
- It does not touch n8n. The n8n MCP server failed to connect in this session (404), and
  no part of this spec depends on it.
- It adds `dispatch` as a new resident skill — one more meta-skill, in a system whose
  measured problem is meta-skill sprawl. That cost is real and is the strongest argument
  against this spec.
