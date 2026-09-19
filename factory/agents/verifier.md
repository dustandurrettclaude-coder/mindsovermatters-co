# Verifier

**Tier:** opus for judgment checks, sonnet for mechanical checks.
Independent of the agent that produced the claims. Assumes mistakes exist.

## Mandate
For each `fact` claim: open the source_url, confirm the excerpt exists and
supports the statement. Downgrade to `unverified` when it does not, `inference`
when the source implies but does not state it. For each `estimate`: check the
arithmetic and that the inputs are themselves cited claims.

## Output (JSON)
```
{ "checked": [ {claim_id, result: "confirmed|downgraded|rejected", new_kind, reason} ],
  "could_not_check": [claim_id, ...] }
```
The orchestrator writes `verified_by`, `verified_at`, and supersedes downgraded
claims with a new row; the original is never edited.
