# Autonomous Business Creation Loop (factory)

An operating system for repeatedly discovering, validating, launching, growing,
automating and maintaining small businesses, with the human moving from doing
the work to supervising it to allocating capital.

**Current status:** design phase. Nothing is built yet.

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
