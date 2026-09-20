# Delegation template (every subagent brief uses exactly these six fields)

CONTEXT
  What is being built and where this task sits in the loop
  (DISCOVER → RESEARCH → REVERSE ENGINEER → EVALUATE → VALIDATE → ...).

OBJECTIVE
  The specific question to answer. Never "what do you think?".

CONSTRAINTS
  What must not be changed or done: free sources only, no login-gated pages,
  no fabrication, tag every statement, lanes in scope, kill cap, Rule 2.

OUTPUT
  The exact artifact: JSON matching the agent spec's schema.

EVIDENCE
  Sources and data the agent should use, in priority order, plus what already
  exists in `factory.claims` so it is not re-researched.

RETURN FORMAT
  JSON only. Fields: `claims[]` (statement, kind, topic, source_url,
  source_excerpt, confidence), plus the agent-specific block.
  End with `disagreements[]` where sources conflicted and `not_public[]`
  for numbers that could not be found.
