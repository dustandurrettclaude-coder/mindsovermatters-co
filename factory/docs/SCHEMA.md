# factory schema — reference

Applied to the brain project `ompxlqmszgutlldtivph` on 2026-09-19 as migration
`factory_schema_0001`. Source: `factory/supabase/migrations/0001_factory_schema.sql`.

## Tables (18)

| Table | Purpose |
|---|---|
| opportunities | discovered business/model; `stage`; `lane`; `p_first_100_30d` ESTIMATE + inputs |
| claims | evidence ledger; `kind` fact/assumption/estimate/inference/unverified; fact needs `source_url` |
| business_models | reverse-engineered model blocks (jsonb, each citing claim ids) |
| opportunity_reports | one row per evaluation dimension; verdict strong/weak/unknown; no score |
| businesses | approved business or shared asset; `state`; autonomy level; spend limit (default 0) |
| state_transitions | immutable lifecycle log, written only by `transition()` |
| decisions | human gates and escalations (six required fields); links `pending_confirmations` |
| experiments | validation/marketing tests; spend needs a decision; closing needs a lesson |
| metrics | time series per business/experiment |
| campaigns | channel tests |
| leads | sales loop |
| ai_calls | model cost ledger |
| ai_disagreements | recorded agent conflicts and their resolution |
| lessons | institutional memory |
| failure_reports | graveyard record (one per business) |
| sops | repeatable processes and their automation status |
| automations | what runs unattended, where, and how reliably |
| events | append-only audit |

## Views (4)
`graveyard`, `portfolio`, `open_decisions`, `factory_metrics` (headline: `profit_per_human_hour_usd`).

## Functions and guards
- `factory.transition(business_id, to_state, actor, reason, decision_id)` is the only writer of
  `businesses.state`. Enforces allowed edges, Gate 2 (a closed experiment with
  `counts_as_paying_demand`), a decided `approve_build` decision, and a failure report before `dead`.
- `guard_state` trigger rejects direct state updates.
- `guard_spend` trigger rejects spend over the approved budget and opens a `kill_cap_exceeded`
  decision past $50 or 5 human hours.

## Access
RLS enabled on every table; no anon or authenticated grants; `service_role` only.

## Tests
`factory/sim/lifecycle_test.sql` (12 checks) against a local Postgres 16; all pass.
