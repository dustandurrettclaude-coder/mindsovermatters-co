# Autonomous Business Creation Loop (factory)

An operating system for repeatedly discovering, validating, launching, growing,
automating and maintaining small businesses, with the human moving from doing
the work to supervising it to allocating capital.

**Current status:** Slice 1 in progress. The `factory` schema migration and its gate tests exist and pass locally; not yet applied to the brain.

Run the tests locally (needs a Postgres 16+ server and roles anon/authenticated/service_role):

```
psql -d factorytest -v ON_ERROR_STOP=1 -f factory/supabase/migrations/0001_factory_schema.sql
psql -d factorytest -f factory/sim/lifecycle_test.sql | grep -E 'PASS|FAIL'
```

- `docs/ARCHITECTURE_REPORT.md` — the Architecture & Implementation Report
  (environment audit, recommended architecture, schema, agents, lifecycle,
  costs, risks, open questions, first implementation). Awaiting approval.

Planned layout once approved:

```
factory/
  README.md
  docs/            architecture, setup, environment, schema, agents, SOPs, changelog
  supabase/
    migrations/    SQL migrations for the `factory` schema (brain project)
  src/             Bun/TypeScript CLI, lifecycle state machine, claims ledger
  agents/          markdown role specs (scout, researcher, verifier, ...)
  prompts/         version-controlled prompts
  sim/             simulated businesses and failure-condition tests
sites/<business>/  static landing pages served by GitHub Pages
```
