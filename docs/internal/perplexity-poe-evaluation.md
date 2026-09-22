# Perplexity + Poe vs. the current assistant stack

**Date:** 2026-09-21
**Status:** internal evaluation — NOT for publication. This repo publishes to
mindsovermatters.co via GitHub Pages; merging this file to `main` makes it public.

---

## 0. What was measured

The comparison baseline is not an impression — it is the Supabase brain
(project `ompxlqmszgutlldtivph`), read 2026-09-21, covering 2026-07-05 → 09-20
(~11 weeks, 175 sessions).

| Metric | Value |
|---|---|
| Sessions | 175 (174 closed, 160 wrap_complete) |
| Memos (`deploy_memory`) | 542 |
| Skills registered | 86 |
| Skills install-confirmed | 45 (**41 built and never installed**) |
| Live policies | 61 |
| Spinoffs | 189 (112 done, 36 deleted, 23 declined, 11 merged, **7 ready**) |
| Pending confirmations | 402 (327 done, 32 superseded, **30 open**, 13 declined) |
| Subagent spawns (`delegations`) | 61 — avg **167,309 tokens**, avg **832s**, 58/61 verdict used |
| Brain edges | 733 (session→skill 532, memo→goal 167, spinoff→goal 32, goal→loop 2) |
| Loops | **0 rows** (`loops` v2.2.1 and `loop-scout` v2.1.1 both installed) |
| `model_routing` rows | 16 task types — 9 are retired n8n lanes; only 3 carry measured token averages |

**Skill invocation mix** (`sessions.skills_used`, 532 recorded uses):

- meta/system: **525 uses**, 50 distinct skills
- business/revenue (`cssi-*`, `market-run`, `social-batch`, `xpost`, `product-*`, `mom-*`): **7 uses**, 5 skills

Top skills: close 86 · deploy 54 · session-init 47 · skill-packager 40 · wrap 32 ·
recall 31 · brain-changelog 23 · reconcile 22 · spinoff 21 · cp 19 · mark-done 18 ·
model-router 17.

> **Caveat, stated plainly:** `skills_used` only records skill-mediated work. CSSI and
> Gumroad work done by hand is invisible to this column. The 525:7 ratio measures how the
> *skill system* is spent, not how Dustan's total hours are spent. It is still the single
> most important number in this document.

**Version drift between registered and installed:** `recall` 1.12.4 / 1.5 ·
`mark-done` 1.14.2 / 1.10 · `brain-changelog` 1.11 / 1.4 · `install-verify` 1.1 / 1.0 ·
`token-footprint-audit` 1.1 / 1.0. Roughly 30 more installed skills report
`installed_version = 'unversioned'`, i.e. drift that cannot be measured at all.

---

## 1. Perplexity — what it actually is

**Retrieval.** Own crawler (PerplexityBot) building an independent index, supplemented by
the Bing index for freshness. Retrieval is a hybrid funnel: lexical (BM25-style) and
embedding scorers run in parallel over the candidate pool, get fused, then a cross-encoder
reranker re-scores the survivors. They train their own embedding models (`pplx-embed-v1`,
`pplx-embed-context-v1`) explicitly to maximize recall at large retrieval depth — the
first-stage retriever gates everything downstream.

**Depth ladder.** The product is stratified by effort, and the user picks the tier:

1. Search — one-shot RAG answer
2. Pro Search — 2–4 sub-searches from a decomposed query
3. Deep Research — iterative agent loop, ~2–4 min, reads full documents, replans
4. Labs — ~10 min, adds code execution, charts, asset generation
5. Computer — goal-directed, plans steps, **picks a different model per step**, ships files

**Model Council** (Feb 2026, folded into Computer July 2026): one query fans out to 2–8
models in parallel, then a separate *chair* model synthesizes, explicitly surfacing where
the models agreed and disagreed.

**Cost dial.** `search_context_size` = low/medium/high is a single exposed parameter
trading money for grounding depth. On the API, a per-request search fee (~$5–14 per 1,000
requests) dominates token cost on short queries.

**Memory.** Spaces/Projects = uploaded files + per-space custom instructions + live
connectors (Gmail, Drive, Notion, Slack, SharePoint, Salesforce…). Background Assistants
run scheduled/triggered async work.

**Distribution.** Pages turns a thread or Deep Research run into a formatted public
document readable without an account — research output becomes indexed content.

**The failure to learn from.** Perplexity's citations guarantee that a source *was in the
prompt*, not that the sentence is *entailed by* it. That gap is the direct root of
hallucinated-attribution suits from NYT (Dec 2025), News Corp, Britannica, Merriam-Webster,
Reddit and others, plus forensic findings of 48% paraphrase of a paywalled Forbes article.
Presence-based grounding is not verification.

---

## 2. Poe — what it actually is

**Aggregator + metered currency.** 200+ models behind one subscription, billed in compute
points that vary from ~10 pts for a light text model to 2,200+ for frontier models. Points
do not roll over. The free tier was cut ~90% around March 2026.

**Two bot classes — the important idea.**
- **Prompt bots** (no-code): base model + system prompt + optional knowledge base (files
  up to 5GB / 30M chars, RAG-retrieved, optional inline citation toggle) + greeting.
- **Server bots** (code): a `PoeBot` subclass implementing the Poe Protocol via
  `fastapi-poe`, hosted anywhere reachable (Modal recommended), registered by URL + access
  key. Poe calls the endpoint per message.

**Programmatic orchestration.** A server bot may invoke up to **10 calls to other bots per
user message** through the Bot Query API, with dependencies declared in its settings
endpoint — and those dependency calls cost the calling creator nothing.

**Canvas apps.** Full interactive web apps hosted on Poe that call any model on the
platform, generated through the App Creator bot: chat pane drives generation, Canvas pane
live-renders the app.

**Developer surface.** OpenAI-compatible `/v1/chat/completions` and `/v1/responses`, plus an
Anthropic-compatible endpoint. Swap base URL + key and existing OpenAI tooling works.

**Weaknesses.** Point pricing is unpredictable and expires unused; proxy latency is worse
than hitting models natively; thousands of community bots with wildly uneven quality that
discovery doesn't sort; knowledge bases and bot configs don't export.

---

## 3. Where the current stack already wins

State this before the criticism, because it's true and it's the reason not to rebuild.

1. **Durable structured state.** Perplexity Spaces are files + instructions. Poe knowledge
   bases are an RAG blob. Neither has goals, spinoffs, policies, evidence-checked
   completion (`done_when` / `done_when_kind`), or a derived graph (733 edges). The brain
   is a genuinely more advanced memory architecture than either platform ships.
2. **A governance layer.** 61 live policies and a proposal queue. Neither competitor has
   any notion of a rule the assistant must obey across sessions.
3. **Write access to the real world.** Gmail, Drive, GitHub, Supabase, the filesystem, git.
   Perplexity's connectors mostly read (Gmail/GCal write being the exception); Poe has no
   equivalent at all.
4. **Self-modification.** `skill-packager` → `skill_registry` → install is a loop that
   writes new capability. Neither platform's users can change the platform.

---

## 4. Where they beat it — and what to steal

### 4.1 One gear vs. five (Perplexity's depth ladder) — biggest win

`/deploy` is the only escalation available, and it costs **167k tokens and ~14 minutes per
subagent**. There is no cheap gear, so every non-trivial question pays the heavy price or
gets answered inline with no verification at all.

**Steal:** a declared effort ladder with hard token budgets, defaulting to the cheapest
tier that could work, escalating only on failure.

| Tier | Budget | Shape |
|---|---|---|
| 0 inline | 0 spawns | answer from context |
| 1 scout | ≤40k, 1 Explore/haiku agent | locate/confirm one fact |
| 2 research | ≤150k, 1–3 sonnet agents | multi-source research |
| 3 deploy | current `/deploy` | 4+ independent workstreams |
| 4 council | tier 3 + chair | irreversible or high-stakes decisions |

The `delegations` table already has 61 rows of real measurements to calibrate these
budgets against. Only 3 of 16 `model_routing` rows currently carry `avg_tokens`.

### 4.2 Model Council → a decision council

Verification today is sequential and single-voiced: one verifier returns a verdict
(58/61 used). Perplexity's council runs N models in parallel and a chair reports
**agreement and disagreement** rather than a verdict.

Honest limitation: subagents are all Claude, so a "council" is one provider wearing three
hats — correlated errors stay correlated. The genuine cross-provider version needs Poe's
OpenAI-compatible endpoint (or OpenRouter) as a gateway. That's a real experiment, not a
guaranteed win, and it costs money per call.

Cheap version worth doing regardless: for spec approvals and policy proposals, spawn 3
agents with *deliberately different framings* (proponent / skeptic / cost-auditor) and have
the main thread report the disagreement rather than a merged verdict.

### 4.3 Entailment, not presence (the Perplexity lawsuit lesson, inverted)

Rule 7 already says verify, don't guess, and "verify the claim, not the file." The gap is
enforcement: verifier agents return **prose**, which is exactly the presence-based
grounding that put Perplexity in court.

**Steal:** give every verifier a structured output schema — one row per claim
`{claim, evidence_locator, verdict: supported|unsupported|not_found}` — and treat any
`unsupported` as a hard block. `skill_registry.output_schema` (jsonb) already exists and is
the right home.

### 4.4 Prompt bots vs. server bots (Poe's cleanest idea)

86 skills are all markdown prompts. But `cssi-lead-gen` scraping county ArcGIS,
`cssi-easy-win-phones`, and `brain-backup` are **deterministic programs** being re-derived
by an LLM on every run — expensive, slow, and non-reproducible.

**Steal the split:**
- *prompt-skills* — judgment, voice, drafting. Stay markdown.
- *runner-skills* — deterministic. Become code with a fixed entrypoint (Supabase edge
  function or n8n), invoked by a thin skill. Versioned, testable, cheap.

This also attacks the install problem. Poe deploys a server bot by pointing at a URL; the
current stack deploys by packaging a `.skill` file Dustan must install by hand — which is
precisely why **41 of 86 skills were built and never installed**, and why `recall` runs
seven minor versions behind its registered spec.

### 4.5 Declared dependencies with a hard call budget

`skill_registry.depends_on` exists as a column but nothing enforces it at runtime, and there
is no cap on fan-out. Poe caps bot-to-bot calls at 10 per user message.

**Steal:** a per-session spawn budget enforced by `/deploy`, plus a `depends_on` cycle check
at package time (the Skill Impact Audit already calls circular dependency a hard block —
this makes it mechanical instead of a judgment call).

### 4.6 Usage transparency (Poe's points + leaderboard)

Poe's points system is widely disliked *and* it makes cost visceral before you spend.
`delegations` holds tokens and duration per spawn, but nothing surfaces "this session cost
X" at close.

**Steal:** a cost line in `/close` — spawns, tokens, wall-clock, and cost-per-shipped-item.
That one number is what makes the 525:7 ratio impossible to ignore next time.

### 4.7 Pages → publish the research (the business-side steal)

542 memos sit in a database nobody but Claude reads. Perplexity turns a research thread into
a public, indexed page, and that's a distribution flywheel — the research *is* the content.

Given the stated marketing priority (Etsy → Pinterest → content site → paid ads) and a
landing-page repo that already publishes to mindsovermatters.co, the mechanism is
half-built. Research already being done for free becomes the content site.

### 4.8 Background Assistants vs. an empty `loops` table

`loops` v2.2.1 and `loop-scout` v2.1.1 are both installed. `loops` has **0 rows**, and
`goal→loop` edges number 2. Recurrence detection was built; nothing recurs. Perplexity's
Background Assistants are the working counterpart — scheduled agents that fire without
anyone watching.

`wake-timer-scheduler` exists and the Routines/cron surface is available. The gap is that
nothing has been registered, not that the machinery is missing.

---

## 5. The finding underneath all of it

Perplexity and Poe both spend essentially all their engineering on the loop that produces
user-visible output. Their meta-layer is invisible because it is subordinate to the product.

The current stack has inverted that: **525 of 532 recorded skill invocations maintain the
system; 7 do revenue work.** The brain is genuinely more sophisticated than anything either
platform offers — and it is mostly employed keeping itself tidy. 41 skills built and never
installed, 189 spinoffs of which 59 were deleted or declined, 402 pending confirmations, and
zero loops are all the same symptom.

The most valuable thing to adopt from either company is not a feature. It's the constraint
that **infrastructure earns its keep only through shipped output** — which in this case
means a cost-per-shipped-item number on every session close, and a moratorium on new
meta-skills until the 41 uninstalled ones are either installed or deleted.

---

## 6. Ranked recommendations

1. **Effort ladder with token budgets** (§4.1), calibrated from the 61 `delegations` rows —
   biggest cost win, lowest risk.
2. **Session cost line in `/close`** (§4.6) — makes everything else measurable; ~1 hour of work.
3. **Structured verifier schema, entailment not presence** (§4.3) — directly hardens rule 7.
4. **Registry reconciliation**: install, update or delete the 41 uninstalled skills and fix
   the ~30 `unversioned` rows (§4.4). No new skills until this is clean.
5. **Split prompt-skills from runner-skills** (§4.4); move `cssi-lead-gen` and
   `cssi-easy-win-phones` to deterministic runners first.
6. **Publish research as content** (§4.7) — the only recommendation here that touches revenue.
7. **Register two real loops** (§4.8) — weekly lead-gen and weekly referral outreach — so the
   loop machinery stops being theoretical.
8. **Decision council for high-stakes calls** (§4.2). Framing-diverse Claude agents now;
   cross-provider via Poe's OpenAI-compatible endpoint is an experiment, not a promise.

## 7. Explicitly do not copy

- Presence-based citation grounding (§1) — the mechanism behind Perplexity's litigation.
- Non-rolling metered credits (§2) — Poe's most-criticized design.
- Unsorted capability sprawl (§2) — thousands of bots with no quality gate is the same
  failure mode as 86 skills with 41 uninstalled.

---

## 8. Research provenance and confidence

Both platform briefs were produced by delegated research agents on 2026-09-21 against live
web sources. Two confidence caveats they reported, preserved rather than smoothed over:

- **Perplexity retrieval internals** (funnel stage order, the ~100ms budget) came from
  search-result snippets, not full-text reads — the two most detailed sources were blocked
  by the sandbox egress proxy. Treat as secondhand.
- **Poe creator docs**: `creator.poe.com` and the Poe blog were similarly blocked; findings
  rely on WebSearch snippets plus the GitHub-mirrored `poe-platform/documentation`, which
  may lag the live docs.

Baseline numbers in §0 are first-party SQL reads and carry no such caveat.
