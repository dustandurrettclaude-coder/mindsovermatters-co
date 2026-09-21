# Spec: Capability Shelf + Uniform Agent Envelope

**Version:** 0.2 (refined)
**Date:** 2026-09-21
**Status:** planning artifact. No implementation. Nothing in here has been executed.
**Not for publication** — this repo publishes to mindsovermatters.co.

**Changes from v0.1:** renamed the router (name collision with the existing `dispatch`
skill); added the `skills_used` recording requirement that was a silent-failure chain;
replaced the duplicate memory query with a call into `session-init`'s existing retrieval;
added tier authority for `reconcile`; resolved the `dream_m()` node-kind question; added a
cancellation contract; added a session-level budget ceiling; added §9, the Agent OS
mapping. Policy 60 remains unresolved and is flagged as a decision, not silently patched.

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
  "memory_writes": [ ],             // PROPOSED rows — the agent does not write them
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

1. **`public.delegations`** — one row per spawn on return. Already that table's purpose.
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

### 4.2 Write — propose, never apply

`grants` defaults to empty. Agents return `memory_writes` as **proposals**; the main thread
applies them.

> **v0.2 fix — permissions.** v0.1 had `write_scope: "none"`, a binary. That is not a
> permission model. `grants` is an explicit capability list (e.g.
> `["read:deploy_memory:cssi", "propose:spinoffs"]`). Empty by default; a grant is named or
> it does not exist.

This is not a new principle — it is the rule already written on `public.dream_proposals`:
*the dream proposes, Claude disposes; no lane changes a status, merges a row, or deletes
anything.* The envelope extends that existing rule to all agents.

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

## 9. Fit with the Agent OS idea

> **ASSUMPTION, FLAGGED.** "Agent OS" appears nowhere in the brain — no match across 542
> memos, 189 spinoffs, 61 policies, or 23 dream proposals. This section is written against
> the generic reading: *a persistent operating layer that runs agents as managed processes
> with scheduling, permissions, shared memory, and a package/capability system.* If your
> idea differs, this section is the part to correct first.

### 9.1 The mapping is unusually clean

| OS concept | This spec |
|---|---|
| Process | an agent spawn |
| Process control block | the §3.1 envelope |
| Syscall boundary | §4.1/§4.2 — agents request, the parent acts |
| Scheduler / priority | `model_routing` + §3.3 tiers |
| Memory protection | memory packets; no direct brain access |
| Capabilities | §4.2 `grants` |
| Filesystem | `skill_catalog` (index) + `procedures` (bodies) |
| Loader / exec | `shelf` |
| Package manager | `skill-packager` |
| init / shutdown | `session-init` / `close` |
| Audit log | `delegations` |
| Advisory locks | `active_sessions` (60-min TTL) — already built |
| Signals / kill | §3.5 cancellation |

The envelope is a process model. That is why it fits: an OS is mostly a uniform contract
for running untrusted things with bounded resources, which is precisely §3.

### 9.2 Three gaps this spec does not close

1. **No IPC.** Agents cannot talk to each other; they return to the parent and nothing else.
   For fan-out work that is fine, but an OS without IPC forces every exchange through the
   parent's context — the exact bottleneck the shelf is meant to relieve. **Poe already
   solved this**: a server bot may call up to 10 other bots per message, with dependencies
   declared up front. That cap is the design — bounded, declared, non-recursive. Your
   `skill_registry.depends_on` column already exists and is unenforced; it is the natural
   place for declared dependencies.
2. **No preemption or quotas across concurrent sessions.** `active_sessions` gives advisory
   locking, but two sessions can each open a full token ceiling. A real OS arbitrates.
3. **No scheduler for unattended work.** `wake-timer-scheduler` and Routines exist;
   `loops` has 0 rows. Perplexity's Background Assistants are the working counterpart. The
   machinery is present and unused — an OS with a cron that nothing is registered in.

### 9.3 Verdict

This spec is a **kernel, not an OS**: process model, memory protection, capabilities,
audit, loader. Gaps 1–3 are the difference, and each is additive — none requires
re-opening §2 or §3.

**Sequencing that follows:** the shelf is the filesystem, and a filesystem comes before
IPC and before a scheduler. If the Agent OS idea is real, this spec is a reasonable first
layer rather than a detour — *provided* the Phase 2 gate passes. If shelving proves
unreliable there, the OS framing does not rescue it; it just inherits the same broken
routing at a larger scale.
