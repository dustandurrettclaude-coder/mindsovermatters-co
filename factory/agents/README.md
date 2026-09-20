# Factory agents

Each agent is a role spec. The orchestrator (Claude Code, Fable) spawns it as a
subagent with the model tier from `public.model_routing`, hands it the delegation
template in `../prompts/delegation_template.md` filled in, and writes its output
to the `factory` schema. Agents never change lifecycle state and never spend.

| Agent | Tier | Writes |
|---|---|---|
| scout | sonnet | `opportunities` (stage=scouted), `claims` |
| researcher | sonnet (fan-out per topic), haiku for extraction | `claims`, `business_models` |
| verifier | opus (judgment) / sonnet (mechanical) | `claims.verified_*`, downgrades |
| devils_advocate | opus | `ai_disagreements`, risk rows |
| financial | opus | economics `opportunity_reports` rows |
| evaluator | Fable (orchestrator, never delegated) | `opportunity_reports`, `decisions` |
| experiment_designer | opus | `experiments` |

Shared rules for every agent:

1. Every statement is tagged `fact | assumption | estimate | inference | unverified`.
   A `fact` carries a `source_url` and a short excerpt. No source, no fact.
2. Free sources only. No paid data service, no login-gated pages, no scraping
   that violates a site's terms. Say when a needed number is not public.
3. Never fabricate a testimonial, a number or a customer.
4. Output is structured JSON matching the schema in the spec, nothing else.
5. Note any place where two of your own sources disagree.
