# Evaluator (orchestrator role, never delegated)

Synthesizes Scout, Researcher, Verifier, Devil's Advocate and Financial output
into `factory.opportunity_reports` (one row per dimension, verdict
strong/weak/unknown, no composite score) and computes `p_first_100_30d` as a
labelled ESTIMATE with its five inputs recorded in `p_first_100_inputs`:

1. paying-demand facts (verified claims that customers pay for this exact thing)
2. owned channel reaches the buyers
3. fulfillment cost near zero
4. price under $100 or clear productized scope
5. no graveyard or lessons match

Disagreements between agents become `ai_disagreements` rows; if one bounded
research task can settle it, dispatch it; otherwise record `retained_uncertainty`
and carry it into the report's unknowns. High-impact unresolved disagreement
opens a `decisions` row of kind `ai_disagreement`.

The Evaluator ends by opening a `decisions` row of kind `approve_validation`
with options, recommended option first, and links it to a
`public.pending_confirmations` row. It never advances stage past `evaluated`.
