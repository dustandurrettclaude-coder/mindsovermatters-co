# Minds Over Matters: long-term business model and ecosystem evaluation

Date: 2026-09-27. Evaluation only. Nothing in the live system, the brain, or the product bundle was changed.

Scope: the proposal to grow Minds Over Matters (MOM) from a personal AI workspace into a network ("Meeting of the Minds") with discovery, lineage, verification, jobs, and a marketplace, plus a native app. Judged against what is actually built and decided as of today.

How to read this: Part 1 is the verdict. Part 2 is the verified inventory of what exists (with sources). Part 3 maps the proposal onto it. Part 4 answers your 25 questions. Part 5 is the staged roadmap. Part 6 is KEEP / CHANGE / DEFER / DROP / QUESTIONS. Part 7 is the evidence appendix. Every list is numbered so you can reference items.

---

## Part 1: Verdict in one page

1. **The private product is the business. The network is a possible second act, not a co-launch.** Nothing has sold yet (the Gumroad `sales` webhook table has 0 rows; the only MOM listing is "not currently for sale"; the site is a noindex "coming soon" page). The network thesis cannot be tested on zero retained users, and building any of it now would delay the only test that matters: do strangers install, come back, and pay.

2. **What is genuinely differentiated is narrower than the proposal, and stronger.** Persistent memory, dashboards, skill libraries, communities, and gig marketplaces all exist elsewhere, most of them free. What does not exist elsewhere, verified in this pass: (1) completion that must be proven by a check the AI runs (`done_when`); (2) functional verification of shared AI workflows (every "verified" badge found in today's skill and MCP registries means identity/ownership only); (3) attribution that survives remixes (registries visibly lose it). Those three, applied to a shared library, are the defensible core of "Meeting of the Minds." The "personal AI OS" framing is not differentiated and is being commoditized by Anthropic and OpenAI (Claude memory free since March 2026, the in-app skills directory, OpenAI's Plugins carrying Skills; appendix 7.2).

3. **The single largest architectural discontinuity is "no code runs."** MOM today is ~30,000 lines of prose plus SQL, zero servers, zero inference cost, and the customer's own Supabase. Every network feature (accounts, search index, payments, moderation, verification queue) is code and servers you operate. That flips the operating model from "sell files" to "run a service." It is doable, but it must be a deliberate decision, not a drift.

4. **The pricing proposal conflicts with a decision you already made on 2026-09-23 ("no longer buy once own forever"; $79/yr with a soft gate at day 366).** The clean resolution is to make the renewal *be* the membership: year one $79 includes updates and founding network access; renewal buys updates plus network; stop paying and you keep what you installed. One SKU, no lock-in, and it funds maintenance. Do not reintroduce a one-time SKU.

5. **Jobs and a paid marketplace should not be built for at least two stages.** Two-sided liquidity, chargeback fraud (friendly fraud is up to 80% of digital-goods chargebacks), 1099 and VAT obligations, and malicious-skill supply-chain attacks (one security firm found 341 malicious skills on a single AI skill hub in early 2026, and a separate audit of nearly 4,000 skills found 76 carrying malicious payloads) are real costs with no demand side yet. The one version worth running early is bounties where you are the only buyer ("MOM builds MOM"), paid manually, delivered by pull request through the gate you already designed.

6. **The native app should be a Progressive Web App first.** The dashboard is a claude.ai artifact that depends on the artifact runtime; it cannot be "wrapped." A standalone PWA on mindsovermatters.co with Supabase Auth and Row Level Security reuses the HTML, installs on Android and desktop today, becomes a Play Store listing through a Trusted Web Activity for a one-time $25, and hands prompts to Claude through the Android share sheet or the Claude Code deep link. That respects Anthropic's consumer terms (human presses send) and needs no API key.

7. **Shortest realistic path to "people actually want it":** ship v4.1 through the seven gates already on the board → run the shipped bundle yourself for 30 days on a clean brain → 5 to 10 validation users → 25 paying customers with measured activation → only then seed the network from the ~50 of your own items that stand alone on someone else's install, using GitHub as the lineage engine. Roughly two to three quarters at your current pace, with explicit kill criteria at each gate.

---

## Part 2: What exists today (verified 2026-09-27)

Sources: the live brain (read-only SQL, re-checked by an independent verifier at the end of the session; counts move because the brain is in daily use), your published decision artifacts (2026-08-27 to 2026-09-26), the `mom-build` repository, the Gumroad listing, and mindsovermatters.co.

### 2.1 The product

1. **Name and pitch (decided 2026-09-24):** "The AI Life Dashboard for Claude" as the name line; "the memory system for Claude" as the one-sentence description. The 2026-08-28 assessment already recommended dropping "memory" from the pitch because memory shipped free in Claude in March and August; the differentiator named there is "work that cannot be marked done without proof."
2. **What ships:** markdown skills (the product cut is 12 core skills; your workshop is 86 registered skills, of which the registry marks 45 `ship`, 22 `vendor`, 19 `generalize`), a SQL provisioner for the buyer's own Supabase project (14 tables in the product), a dashboard, a Handbook and Setup Guide, a claims ledger, an acceptance gate script (9 checks), and hostile verification by two external models before release (policy #66).
3. **Licensing (spec final 2026-09-24, goal `2026-09-23-mom-365-licensing`, active):** $79 per year, single user, signed keys verified offline, key check at install time only, soft gate at day 366 (updates and reinstalls stop; the installed product keeps working), every revocation gated on your confirm, Termux/Node server deferred. Policy #73 requires sweeping the shipped bundle for the old model's guarantees before any pricing change.
4. **Commercial state:** `public.sales` (Gumroad Ping webhook) has 0 rows. The Gumroad listing `/l/minds-over-matters` shows $79 and "This product is not currently for sale." mindsovermatters.co is a placeholder ("We're updating this page") with `robots: noindex`, linking to Gumroad. The storefront index itself could not be read from this container (CAPTCHA), so the other Gumroad products were not verified here.
5. **Open MOM-product goals on the board:** v4.0 parity release (active), 365 licensing (active), citable site with `llms.txt` (active, shell-checked `done_when`), post-launch marketing "validate with 5–10 users" (queued), and `2026-09-24-mom-community` (queued): founding-member framing in the listing, buyer email capture, all 10 validation users invited as founding members; gated on ruling 27 (a real second person installs clean) with the note "do not open a space early, an empty room reads as a dead product," budgeted at about 20 minutes a day.
6. **Seven gates before v4.1 ships (2026-09-24):** brother's timed clean install; unpublish the old one-time listing; set Gumroad to $79/yr auto-renew with one live checkout; upload v4.1 with the annual description; deploy `site/` with `llms.txt`; submit sitemaps; back up the signing key. No outside person has installed MOM yet.

### 2.2 The brain (your own usage)

| Table | Rows | Notes |
|---|---|---|
| sessions | 211 | first 2026-07-05; 81 in the last 30 days; 174 wrap-complete |
| deploy_memory (board + memos) | 589 | 77 rows carry a `done_when`; statuses: 211 done, 104 active, 85 permanent, 55 open |
| spinoffs | 192 | 118 done, 13 merged |
| pending_confirmations | 418 | 340 done, 29 pending |
| policies | 69 live | 15 verification, 9 infra; 37 written in the last 30 days |
| skill_registry | 86 | 45 install-confirmed |
| delegations (measured subagent spawns) | 74 | since 2026-09-15 |
| brain_edges / dream_proposals | 829 / 49 | derived graph; 43 proposals accepted |
| sales | 0 | Gumroad webhook |
| skill_catalog | 83 | per-skill triggers, summary, bucket, ELI10 text (single-user) |
| marketing_products | 2 | |

Weekly sessions over the last 13 weeks ranged from 0 to 36 (one August week had none). Top skills by session use: close (101), session-init (59), deploy (54), skill-packager (41), wrap (39), recall (31), reconcile (25). The domains table lists business, cssi, digital, infra, mom-product, realestate, rt. You are, in other words, a heavy daily user of a system that has never been used by anyone else.

### 2.3 Architecture facts that matter for the proposal

1. **Runtime:** Claude desktop/Cowork, Claude Code, and the Chrome extension, all on your consumer Claude plan. MOM runs *inside* Anthropic's apps as instructions. No MOM code executes anywhere.
2. **Record:** one Supabase project per person (RLS on; policy #38 "RLS and least privilege before the first row"). No `user_id` or tenant column anywhere, by design: one brain, one person, one project. Supabase free tier allows two active projects; the brain and Pearls Library fill both, `mom-buyer-test` is paused.
3. **Dashboard:** claude.ai artifacts ("Brain Dashboard v3", "Brain dashboard — council, lanes and dreams", plus decision pages) built on the artifact runtime (`window.claude`, the `db` capability, connector grants). Your own rule 6 records that republishing through the remote bridge can strip the connector grant and take artifacts offline. Of the two dashboard artifacts inspected this session, "Brain Dashboard v3" is a design prototype (vanilla JS, browser storage only, no Supabase calls; its own prose says the personal build reads through the MCP bridge as role postgres while the buyer template reads through the publishable key under a column-grant ceiling), and the council/lanes/dreams page is a static design mockup with no data layer at all. That buyer-template design (publishable key plus RLS) is the same data layer a standalone app needs, which, in my judgment, makes the app path shorter than it looks (the data-access design exists; only the runtime changes); the personal MCP-bridge path is the one that cannot leave claude.ai. One recorded hazard (Decision Board, 2026-09-16): v3.9.1 had a hole where a public dashboard key could let someone rewrite a goal's `done_when` text, which the reconcile skill then executes; v3.9.2 fixed it. That is exactly the class of risk a shared library of executable checks must be designed against.
4. **Verification culture already built:** blind multi-model review ("a second model's review is independent only if it never sees Claude's findings first"; "two models agreeing is not evidence"), the acceptance gate, the claims ledger, `install-verify`, `mom-gate` planned in `mom-build`.
5. **Lineage primitives already present:** `version_anchor` on goals and spinoffs, `version_history` on loops, `superseded_by` on graph edges, `base_sha256` on dream proposals, `skill_registry.version` and `last_verified_against`. The brain already thinks in versions and supersession, for your own objects only.
6. **The multi-model build lane (`mom-build`, G0 committed 2026-09-25):** Codex builds, Claude audits, you merge; rulesets on `main`, CODEOWNERS on governance paths, gitleaks, blind reviews, the invariant "AI can propose, review and repair; AI never authorizes an irreversible action." Spec §10.14 (2026-09-26) keeps all of this, and Dream Mode, OUT of the MOM product. It is, however, an exact template for community contributions: a spec, a gated pull request, an independent audit, a human merge.
7. **Cost of the lifecycle:** close is 342 lines and 13 steps with six database round trips and about five subagent calls (2026-08-28 assessment). Of 17 loop definitions, 4 are active and 13 retired. This is the retention risk for anyone who is not you.
8. **Other ventures competing for your time:** Pearls Library (active, separate Supabase project and repo, "2–3 hrs/day" pace note), Executive Function (a second skill-bundle product, parked until MOM launches), CSSI day job and its eight skills, respiratory therapy content, and the D.A.W.N. channel (parked).

### 2.4 Decisions already on record that bear on this proposal

1. **"Install Twelve, Shelve Sixty-Two" (2026-08-28):** the workbench audit that picked the 12 core skills (close, deploy, recall, session-init, mark-done, wrap, reconcile, spinoff, model-router, brain, dispatch, synapse), retired the document-format skills and the memory-import skills, and measured the per-message skill overhead at about 12,900 tokens, with a target near 2,260. Explicitly workbench, not product.
2. **"The Workbench in Plain English" and "Workbench Overhaul Queue" (2026-08-28 to 2026-09-02):** memory.md and lessons.md had grown to about 21,500 and 22,800 tokens and were never trimmed; 15 cadence definitions, 2 ever ran; close's fast mode becomes the default; six proven defects in close fixed in v4.8; CLAUDE.md at 10,768 tokens to be cut under 4,000. The lesson for a network: every shared item is prose that must be kept true by someone.
3. **"Decision Board" (2026-09-16):** hold v3.9.1 and ship v3.9.2 because of the dashboard-key hole; soften four unverified homepage claims ("Save hours every week", "Kill switch included", "Everything lives in files you own", the 15-vs-20-minute setup claim); Dream Mode v0.6 adopted with safer defaults (no permanent deletes, no server reaching the laptop, no dashboard buttons writing to the database); a second product, Executive Function (EF), sold in bundles; a Mem0 experiment deferred; lock the `command_queue` table and anonymous `exec_sql`.
4. **"Five Decisions" (2026-09-23):** cap subagent fan-out at 5 by default (one run hit 34 and burned two-thirds of a week's tokens); Quick close as the default (Full costs about 3x); Etsy confirmed as a channel with six product files prepared.
5. **"Dream Mode Phase 2" (2026-09-26):** a nightly SQL-only maintenance pass with memory decay and co-retrieval links, zero API spend; Neo4j and a Gemini digest deferred pending a keys-and-spend ruling. Kept out of the product by §10.14.
6. **"Five-Row Board Triage" (2026-09-25):** EF parked until MOM launches; 42 skills installed against a 35-to-37 ceiling; a ship-gate script now scrubs internal vocabulary and checks version labels on every cut; "v3.9.x never sold."
7. **"Free Tier Card" (2026-09-18):** not a pricing tier. It is a routing card that sends lookups, deep research, long documents, and drafts to free tools (Perplexity, Gemini Deep Research, NotebookLM, Le Chat, Copilot) to save measured Claude tokens (deep research about 129,000 tokens per run), with a "stays with Claude" list (code, verification, decisions, brain writes, deliverables). The only free on-ramp decided for MOM is the public GitHub repo: README plus the Apache-2.0 skill-creator (2026-09-24, decision 3a).
8. **"The No-Access Wedge" (2026-08-27):** unrelated to MOM (a consulting-services evaluation), but its own conclusion is worth remembering: a ten-lens panel ranked "software-first" worst for year one and recommended services before software. You have already, once, judged that selling software first is the hard road.
9. **"Pearls Library Phase 2" (2026-09-26):** a separate product with its own project and repo; Phase 1 live, single-user, invites blocked on custom SMTP; its Integrity Engine needs the app's first Anthropic API key. It competes with MOM for the same hours.


---

## Part 3: The proposal mapped onto what exists

### 3.1 Already exists (do not rebuild)

1. Persistent personal brain with goals, tasks, notes, lessons, workflows, AI instructions, skills, history: the product itself (deploy_memory, sessions, spinoffs, policies, loops, skill_registry, pending_confirmations).
2. "Every MOM evolves differently": your own brain proves it (seven domains, 86 skills, 69 policies), and the registry's `ship / vendor / generalize` split is the mechanism that separates the generic core from a person's specialization.
3. Evidence-gated completion (`done_when` + reconcile): the one mechanism with no free equivalent, and the natural definition of "MOM Verified."
4. Verification pipeline: acceptance gate, claims ledger, blind hostile review, install-verify.
5. Versioning primitives: anchors, histories, supersession, hashes.
6. A community plan: goal `2026-09-24-mom-community`, queued and gated, with the right instinct about empty rooms.
7. A contribution governance model: the `mom-build` lane (roles, rulesets, audit-before-merge).
8. Outcome-first marketing plan: citation-authority loop, creator outreach loop, Product Hunt one shot, marketing stop rule (90 days, 4 hours a week, review at week 8).

### 3.2 Genuinely additive

1. A shared registry of skills/workflows/templates with provenance, forks, and attribution across people (nothing exists across people; `skill_catalog` has 83 rows but describes one person's skills).
2. Functional verification of *other people's* items on a clean install ("MOM Verified" as a mark, not a badge of identity).
3. Discovery from inside the user's Claude across the private brain, the shared library, and the web (a `/find` skill; nothing exists).
4. "Improvement available for something you use" notifications (needs registry + opt-in telemetry).
5. Bounties/jobs with sealed selection before work.
6. Earning playbooks written as `done_when` for services ("what the customer buys, what finished looks like, what the human verifies"). This is your method applied to freelancing and is on-brand.
7. An installable app that is not tied to claude.ai's artifact runtime.

### 3.3 Conflicts with the current architecture

1. **Single tenant vs shared layer.** Every skill assumes one connector, one project, one person. The network needs a second, shared store (the commons) that the private brain never writes to unless a publish action is recorded. Keep the private brain exactly as is; add a commons with its own API. Do not merge them.
2. **"No code runs" vs a service.** The proposal needs: an index, auth for members, contribution intake and scanning, a verification queue, notifications, and (later) payments. Each is code you host. Your licensing spec explicitly deferred even a small Node server. Decide on purpose.
3. **Pricing.** One-time $79–99 plus $10/mo membership vs the decided $79/yr with a soft gate. See Part 4, question 22.
4. **Dashboard as artifact vs app.** The artifact's data layer (`window.claude` db/connector) does not exist outside claude.ai. The app is a rewrite of the data layer (supabase-js + Auth + RLS), not a repackaging.
5. **Terms of service.** Nothing MOM-hosted may call Claude with a user's Pro/Max session. Since April 2026 Anthropic actively enforces that consumer OAuth credentials power only Claude.ai and Claude Code. Your copy/paste handoff is compliant precisely because a human presses send; the "later automation" line in the proposal must mean BYO API key or nothing.
6. **Lifecycle weight.** A 13-step close is tolerable for its author; a network of people who churn out of the private product is a ghost town.
7. **Supabase free-tier pausing.** A free project pauses after 7 days without database activity. A casual buyer's brain going dark looks like a broken product. No network feature fixes that; it is an onboarding and hosting problem for the private product.

### 3.4 What evolving toward the vision requires, in order

1. Separate MOM Core from your workshop (in progress: the 12-skill cut, `product_fit` tags, v4.x).
2. One stranger installs unaided; then 10; then 25 pay. Measured, not assumed.
3. Dashboard leaves claude.ai: a PWA with Supabase Auth reading the user's own project. Later a Play Store listing via Trusted Web Activity.
4. A commons object model (manifest with id, kind, author, license, version, parent, origin, changelog, acceptance test, provenance URL) stored in a public git registry, indexed in a MOM-owned Supabase project exposed read-only to a `/find` skill.
5. Contributions as pull requests through `mom-gate` plus a security scan (prompt injection, exfiltration patterns) and a named human clean-install run for "MOM Verified."
6. Money only through merchant-of-record links (Gumroad, Lemon Squeezy) owned by creators, and manual bounty payouts, until GMV justifies rails.

---

## Part 4: Your 25 questions

**1. Differentiated vs available elsewhere.**
Not differentiated: cross-session memory (Claude and ChatGPT ship it free; claude-mem ~94k GitHub stars, Mem0 ~66k, per your 2026-09-18 scorecard), dashboards (Notion), skill directories (Anthropic's in-app directory; third-party indexes list ~7,000 to ~24,000 Claude skills), template libraries (n8n ~12,500 workflows, Zapier's template gallery), prompt markets (PromptBase 330,000+ prompts), paid communities (Skool, Whop, Circle), gig markets (Upwork, Fiverr, Contra). Differentiated: (1) `done_when` completion proven by a check; (2) functional verification of shared AI workflows (MCP Registry, Smithery, Glama, Docker Verified Publisher all verify identity or namespace, not behavior); (3) attribution preserved through remixes (a documented dispute in a popular Claude templates repo shows curators re-publishing without original credit; over 60% of Hugging Face models carry no documented parentage); (4) selection before work plus vetted supply in jobs (no GitHub-native bounty tool implements it; Algora and Boss.dev pay whichever pull request merges first); (5) a user-owned Postgres record that works across Claude desktop, Claude Code, and Chrome. Anthropic's own roadmap moved fast this year: memory free for every claude.ai user since March 2026, Cowork included in Pro since January 2026 and merged into the main chat interface from September 2026, Windows support since April. Each of those was once part of MOM's pitch and became a free platform feature within months, and native memory in every assistant (ChatGPT free since June 2025, Gemini personal context, Microsoft 365 Copilot memory GA January 2026) is vendor-locked with no cross-tool export, which is the one gap the owned-Postgres record fills. The independent "personal AI" field is crowded and mostly open source (OpenClaw 250,000+ GitHub stars in about a month on a bring-your-own-key model; mem0 65,000+ stars and $24M raised; AnythingLLM ~62,700; Khoj ~35,000, with its paid cloud sunset in April 2026; Letta ~24,700; Zep ~27,000), all of it memory-and-agent plumbing, none of it proof-of-done. The cautionary tale for vendor-hosted personal memory is Rewind/Limitless: acquired by Meta and shut down on 2025-12-19. That is the strongest argument for your "your own database" stance, and it is a marketing line, not just an architecture choice.

**2. Strongest value proposition.**
For the private product: "Work you do with AI is recorded, proven done, and carried forward, in a record you own." For the network: "Find a workflow that someone proved on a clean install, with the chain of who built and improved it, from inside your own AI." The second is unproven and depends on the first retaining users. Sell the first.

**3. Who realistically buys the first version.**
Not "everyone whose MOM will be different." The prerequisite stack is a paid Claude plan (Pro at $20 a month at least, which since 2026 includes Claude Code and Cowork on Windows and macOS), a Supabase account, and the patience to run a provisioner. Your scorecard's target is "someone who uses Claude a lot and is not a developer," and your own scorecard rates today's setup 4/10. So, in my judgment, the first 25 buyers will be semi-technical Claude power users who already run multi-session projects, most likely solo operators running a business or side business through Claude, which is your own profile (sales rep, agent, digital products). Musicians, filmmakers, and hobbyists are stage-7 audiences, not stage-3 buyers. Reachable channels are organic: r/ClaudeAI, X, Show HN, Product Hunt, Claude-focused YouTubers (your creator-outreach loop).

**4. Smallest product to sell before the network.**
Exactly the v4.1 you have gated: 12 core skills, provisioner, dashboard, Handbook, $79 year one. An even smaller wedge exists if v4.1 stalls: the evidence gate alone (goal board with `done_when`, reconcile, close) as a "Proof Board for Claude" at $29 to $49, with the public GitHub repo (README plus the Apache-2.0 skill-creator, decided 2026-09-24) as the free on-ramp. Do not add a single network-shaped feature before 25 paid installs.

**5. What creates the strongest network effects.**
Ranked: (1) the verified library (more contributors, more useful items, more users: a classic indirect effect; Notion's template ecosystem is the model, with one creator clearing $2.1M in two years on two templates); (2) lineage (value compounds with forks; each improvement makes the original more valuable); (3) a data effect nobody has: which items get installed and pass their acceptance check on real installs; (4) reputation from verified contributions and completed bounties (switching cost); (5) jobs (weakest: local, two-sided, needs liquidity); (6) discussions (a commodity).

**6. What fails from cold start.**
Jobs (zero posters with money, zero vetted doers), a paid marketplace (no buyers; Whop's median product earns $72 a month), reputation (no history), AI discovery over an empty index (the user asks, gets nothing, concludes the network is dead; your own community goal says this about empty rooms), lineage (needs two versions of anything), MOM Verified (needs verifiers other than you).

**7. How to seed before there are many users.**
(1) Your own registry: the 45 `ship` and 19 `generalize` skills, the 69 policies, and the four active loops are about 135 candidate items; curate them to the ~50 that make sense on someone else's install and publish those with provenance. (2) Import with provenance from outside: Anthropic's Apache-2.0 skills repo, n8n templates, adapted into MOM form; that is the "outside discovery → adaptation → contribution" loop, run by you first. (3) "MOM builds MOM" bounties with you as the only buyer. (4) The 10 validation users as founding members with one concrete ask each: fork one item, improve it, submit it. (5) Your own cross-domain stories (a CSSI lead-gen workflow adapted to real estate, a Gumroad listing kit adapted to Etsy) as the first "started in one industry, moved to another" evidence. (6) A weekly "show your board" thread. All within the 20-minutes-a-day budget the board already set.

**8. Does Jobs strengthen or distract initially?**
Distracts. Reasons, all verified: two-sided liquidity does not exist; gig platforms see fake-delivery claims and multi-accounting fraud (Incognia's 2025 gig-fraud report), and digital goods carry friendly-fraud chargebacks; paying members makes you a filer of 1099-K (via Stripe Connect) or 1099-NEC (direct payouts) and, for EU buyers, liable for VAT from the first sale unless a merchant of record sits in between; disputes need a policy and a person. One more caution on the mechanism itself: the only peer-reviewed comparison found (71,437 open-bid against 7,499 sealed-bid auctions on an online labor market) shows sealed bidding draws more bids (18.4% more) while open bidding produced higher selection and completion odds, and nothing in it shows sealed bids protect suppliers from underbidding; what practitioners actually use against the race to the bottom is vetted supply and price floors. Keep "poster selects before work" and the minimum bid; do not over-engineer sealed bids. The exception that helps: bounties where you are the sole poster, fixed price, sealed claim, delivery by pull request through `mom-gate`, paid manually. That tests post → select → work → submit → verify → pay with none of the infrastructure. Open jobs to members only when at least five of them ask to post and manual GMV has passed about $2,000.

**9. Does Marketplace strengthen the model?**
As a free registry with attribution and verification, yes, strongly: it is the substance of the network. As a paid marketplace with MOM as the seller, not yet: MOM revenue at this scale is membership, not a take rate on tiny GMV, and being the seller pulls in marketplace-facilitator sales tax, VAT OSS, and refunds. Let creators sell paid items through their own Gumroad or Lemon Squeezy links (both are merchant of record: 10%+$0.50 and 5%+$0.50 respectively), MOM lists and verifies, takes 0% initially. Revisit a fee when at least 20 paid items have sold.

**10. Is AI-first discovery a meaningful differentiator?**
Meaningful UX, not a moat. Semantic search over a catalog is table stakes; Claude already has an in-app directory and web search. What differentiates is what is indexed (structured, tested, attributed items with acceptance checks) and where discovery runs (inside the user's own Claude, against a small read-only index, so no MOM-hosted inference and no API cost). Build a `/find` skill early because it is cheap; do not market it as the product.

**11. Lineage and versioning: early, later, or never?**
Design now, implement minimally now, build the graph UI later. The minimal implementation is git: a public registry repository where each item is a folder with a manifest (id, kind, author, license, version, parent, origin, changelog, acceptance test, provenance URL); forks are branches and pull requests; attribution is the manifest chain plus commit history; "newer is not automatically better" falls out because versions are siblings with a verified flag. You already use anchors, histories, supersession, and hashes internally. Do not build a custom lineage engine.

**12. Free vs paid community resources.**
Default free under CC BY 4.0 for prose items and Apache-2.0 for code-like items (compatible with Anthropic's skills repo, and attribution is a license term, which matters because purely AI-generated content is largely not copyrightable under the Copyright Office's January 2025 report, so attribution must rest on license and community norm, not copyright). Paid items: creator sets the price and sells through their own merchant of record; MOM never holds funds. Verification is open to free and paid alike. Discovery never ranks paid above free; sort by verified status, fit, and freshness.

**13. What makes skilled users contribute.**
Honest answer: below a few hundred members, only two incentives reliably work: money (bounties) and being seen by a founder who responds within a day. Beyond that: attribution that survives remixes, a verified-contributor mark tied to real installs (not likes), discoverability to people with jobs, early access, and revenue share on paid items. Reputation systems do not motivate until there is an audience to have a reputation with.

**14. Proper attribution when others build on work.**
Manifest chain (origin id, parent id, contributors list, what changed) carried by every fork; the gate rejects a submission that strips provenance; display "based on X by Y, improved by Z (changed: …)"; license requires attribution; git history is the audit trail. Contributors grant the commons a non-exclusive license at submission (a lightweight contributor agreement, the Atlassian/VS Code marketplace pattern).

**15. Trust, fraud, payment, tax, moderation, IP, privacy, security problems to solve eventually.**
(1) IP: pure AI output is largely uncopyrightable; attribution rests on license terms and takedown; derivatives need the parent's notice. (2) Payments and tax: merchant of record (Gumroad, Lemon Squeezy) removes sales tax and VAT burdens; Stripe alone leaves you liable; holding buyer funds yourself is treated as money transmission, so any rail must be Stripe Connect or a merchant of record; federal 1099-K threshold is back to $20,000 and 200 transactions (2025 legislation) but Maryland, Massachusetts, Vermont, and Virginia use $600; EU VAT via non-union OSS applies from the first consumer sale; Stripe Connect makes the platform the 1099-K filer. (3) Fraud: friendly fraud up to 80% of digital-goods chargebacks; multi-accounting and fake deliverables on gig platforms. (4) Security: malicious shared skills are a live threat. In January–February 2026 Koi Security found 341 malicious skills on OpenClaw's ClawHub; Snyk's audit of 3,984 skills found a 36.8% flaw rate and 76 active malicious payloads; the first malicious MCP server (September 2025) silently copied users' email and may have been downloaded by about 1,500 organizations. "No code runs" is not protection here; a prose skill can instruct the model to exfiltrate. Every contribution needs an automated scan for injection and exfiltration patterns plus human review, and MOM Verified must include a security pass. (5) Privacy: hosting other people's data brings GDPR from the first EU user (no small-business exemption), a data-processing agreement chain (Supabase provides theirs), export and deletion within statutory windows, and the dominant Supabase breach pattern is missing RLS (a 2025 CVE found hundreds of publicly readable endpoints). BYO Supabase keeps MOM out of the data path entirely; a hosted tier puts you in it. (6) Terms: state plainly whether MOM is a facilitator or a party; register a DMCA agent ($6); adopt arbitration and venue clauses before any dispute; Section 230 shelter is narrowing for platforms' "own conduct." (7) Moderation: automated pre-publish scan, a human review queue that always includes new contributors, reviews gated to verified installs.

**16. What should absolutely NOT be built yet.**
(1) Jobs infrastructure: bids, escrow, disputes. (2) Any payment rail where MOM holds funds. (3) A hosted multi-tenant brain. (4) App Store or Play Store apps before a PWA exists. (5) A reputation engine. (6) A lineage graph UI. (7) Community projects with revenue sharing. (8) A verifier program at scale. (9) Community-run development of MOM (beyond your own bounties). (10) A MOM-hosted AI discovery service. (11) Automated job execution. (12) A social feed.

**17. What to design for now even if not built.**
(1) Stable ids and manifests for every shareable object (skill, loop, policy, workflow, template) with origin, parent, author, license, version, acceptance test, provenance. (2) A publish boundary: nothing leaves a private brain without an explicit publish action recorded as a row with a hash of what left. (3) A `user_id`-ready convention in schemas and skills even under BYO, so a hosted tier is additive. (4) Export and delete paths as a product promise. (5) Opt-in telemetry rows (install, acceptance-check pass) that feed verification and "improvement available." (6) The `/find` query contract (kind, domain, verified, free/paid, fit). (7) Namespaces (author/item, like the MCP registry's reverse-DNS). (8) The contribution gate as a reusable tool (`mom-gate` plus a security scan). (9) Renewal wording that makes membership the renewal. (10) Agent Skills standard compliance for the skill format, so items can run in other runtimes.

**18. How the native app fits the commercial strategy.**
The app is the front door and the phone companion, not the paid product. The AI keeps running in the user's Claude. Path: (1) PWA at mindsovermatters.co/app, reusing the dashboard HTML with supabase-js, Supabase Auth, and RLS against the user's own project; installable on Android, Windows, macOS today (iOS installs manually via Share → Add to Home Screen, with push limits). (2) Play Store listing via PWABuilder/Trusted Web Activity ($25 one-time). (3) Capacitor only if native clipboard or share plugins become necessary. Handoff to Claude: the Claude app in Android's share sheet (works for every Claude user), the mobile deep links `claude://code/new?q=…` and `https://claude.ai/code/new?q=…` that prefill without sending (Claude Code users; the desktop scheme is `claude-cli://open`), and the iOS "Ask Claude" intent via Shortcuts. Commercially the app drives activation (see the board on your phone), retention (tick confirmations, pick up parked work), and later the network UI. Your "personal Android version first, multi-user-capable architecture" instinct is right if "architecture" means Auth plus RLS from day one. The shipped buyer dashboard is already specified to read through the publishable key under a column-grant ceiling (RLS), so the app's data layer is a port of that design, not new design; only the personal build's MCP-bridge path is stuck inside claude.ai. Claude Pro is $20 a month ($17 annual) and includes Claude Code and Cowork, so the app's prerequisite is Pro, not Max.

**19. What makes MOM difficult to copy.**
Not the files: prose and SQL are trivially copyable and your spec already caps piracy defense at one afternoon. Hard to copy: (1) a verified library with real install and pass data; (2) the attribution graph and contribution history; (3) a public standard for verification (blind multi-model hostile review, clean-install acceptance) that others cite; (4) the brand of "proof, not claims" backed by your own track record as the case study; (5) a community of specialists who found each other here.

**20. Defensibility if models keep improving.**
Better models make MOM cheaper and more reliable to run; MOM is a complement to the model, not a substitute. The real threat is platform absorption: Claude memory and Projects, Anthropic's in-app skills directory, OpenAI retiring the GPT Store (creation frozen October 26, 2026; retirement December 11, 2026) in favor of Plugins that carry Skills. Defensible layers: (1) the user-owned record in plain Postgres that no vendor wants to make portable; (2) the Agent Skills open standard (published 2025-12-18; secondary coverage counts about 32 supporting tools by March 2026, including Codex CLI, Gemini CLI, and Copilot) means MOM skills can run on other runtimes, so "your record and your proof, whatever model you use" can be literally true if you test it; (3) the evidence gate, a discipline models do not impose on themselves; (4) the network's data. Position accordingly and test at least one skill on a second runtime before making the claim.

**21. Could the network become more valuable than the software?**
Yes, plausibly, on the pattern of GitHub over git and npm over Node: the software becomes the on-ramp and the durable asset is the verified, attributed library plus the mark "MOM Verified." That is also the argument for eventually making the core free or open source and charging for membership, verification, and hosting. But only in that order: a network built on a product people churn from is an empty room. Software retention first.

**22. Pricing and business model to test first.**
Keep the decided $79 year-one price; do not churn that decision again (policy #73 makes each change a re-cut). Fold the proposal's $10/mo membership into the day-366 renewal instead of creating a second SKU: year one $79 includes updates and founding network access; renewal is updates plus network at a lower price (test $49/yr, or $5/mo); stop paying and you keep what you installed, which is already what the soft gate does. This matches "no artificial lock-in," funds maintenance (a prose product breaks with every Claude release, so updates are the real product), and mirrors licenses people already accept (Sublime: perpetual with three years of updates; JetBrains: perpetual fallback). Marketplace fee: 0% until 20 paid items have sold; merchant of record handles tax. Decide the renewal price at month 6 with real renewal-intent data from the founding cohort, not now. Alternatives evaluated and not recommended: pure $79/yr flat (simplest, but year-two value is invisible without the network), $10/mo everything (SaaS framing needs hosted value you do not have), one-time plus separate membership (two SKUs, reopens the ledger sweep).

**23. Evidence needed from early users before investing heavily in the network.**
(1) At least 10 outside installs completed unaided in under 45 minutes, timed. (2) At least half of buyers with 8 or more sessions in their first 30 days and at least one goal closed by evidence. (3) At least 25 paid; refunds at or below 10%. (4) At least 3 users who built their own skill, and (5) at least 3 who asked, unprompted, to share it or to see others'. (6) Support under 2 hours a week per 25 users. (7) At least one unsolicited outcome story. If (4) and (5) do not happen on their own, the network thesis is wrong for this audience regardless of how good the plan is.

**24. Major reasons this could fail.**
(1) Platform absorption of memory, boards, and skill directories. (2) The onboarding stack (paid Claude plan, Supabase account, connector, provisioner) kills activation. (3) Founder bandwidth: CSSI, Pearls Library, respiratory content, and MOM plus a network is three jobs. (4) Prose-defect arithmetic: 30,000 lines that must all be true, with support per user scaling with it. (5) No ICP: if "everyone's MOM is different" is also the marketing message, there is no specific person to market to (judgment, and a common failure pattern). (6) Marketplace legal and fraud overhead before revenue. (7) Skills break with Claude releases (already happened: the Cowork artifact tooling a skill relied on is gone). (8) "Make money with AI" adjacency attracts scam-adjacent reputation (FTC actions in 2025–2026 against AI passive-income schemes; widespread refund complaints in AI side-hustle communities). (9) Lifecycle weight drives churn. (10) Free Supabase projects pause after 7 idle days and the product looks broken. (11) An empty network launched early reads as a dead product.

**25. Changes that substantially improve the odds.**
(1) Narrow the first ICP to solo operators who run their business through Claude, your mirror image, and market with your own outcomes. (2) Lead with proof-of-done and the owned record, not "personal AI OS" (the brain already dropped "memory"). (3) Build the PWA before any community. (4) Make the network a GitHub-backed registry plus Discussions before any platform (Skool is $99/mo, Circle $89/mo; GitHub is free and *is* the lineage engine). (5) Run MOM-builds-MOM bounties as the only jobs for a year. (6) Define MOM Verified as "passed the gate and a clean install by a named person," which no registry offers. (7) Make skills Agent-Skills-standard and test one on a second runtime. (8) Instrument activation and retention from day one. (9) Keep the founder-time caps and kill criteria the board already uses. (10) Solve the free-tier pause (a keep-alive, or Pro guidance in the Handbook). (11) Decide deliberately, later, whether the core goes open source to widen the funnel.

---

## Part 5: Staged roadmap

Each stage lists: objective, build, do not build, hypothesis, success criteria, cost and complexity, major risks, go/no-go.

### Stage 1: Finish now (v4.1 through its seven gates)

1. **Objective:** a sellable, verified core on a live listing and a live site.
2. **Build:** nothing new. Close the seven gates on the board (brother's timed install; unpublish the old one-time listing; annual listing with one live checkout; upload v4.1; deploy `site/` with `llms.txt`; sitemaps; key backup) and hostile round 2. Write the renewal sentence so that it can later mean "updates plus network" without contradicting the ledger.
3. **Do not build:** app, community space, registry, jobs, marketplace, multi-user anything.
4. **Hypothesis:** a stranger can install the shipped bundle unaided.
5. **Success:** brother's install completes in 45 minutes or less with no help on the first three steps; round 2 returns no re-cut; listing live; `llms.txt` returns 200.
6. **Cost:** days of your time; $0.
7. **Risks:** round 2 forces cut 1c; a pricing sentence triggers policy #73; time drawn to Pearls Library.
8. **Go/no-go:** all seven gates ticked and the install measured → Stage 2. Install fails → fix setup before anything else; do not proceed on the strength of your own use.

### Stage 2: Prove it with yourself (on the shipped bundle, not the workshop)

1. **Objective:** show that MOM Core alone, not your 86-skill workshop, sustains daily work; and build the phone view you want for yourself.
2. **Build:** (1) run the shipped v4.1 bundle on a clean brain (`mom-buyer-test`, woken) as your daily driver for 30 days, workshop skills off; (2) PWA v0: dashboard HTML moved to mindsovermatters.co/app with supabase-js, Supabase Auth (magic link), RLS policies by `auth.uid()`, installable on Android; (3) handoff: Android share sheet to Claude and the Claude Code deep link.
3. **Do not build:** multi-user features, the commons, store listings, native code.
4. **Hypothesis:** the core is sufficient (you do not reach for workshop skills more than twice a week) and a phone view gets used daily.
5. **Success:** 20 or more sessions in 30 days on the shipped bundle; 3 or fewer defects found; PWA opened 5 or more times a week; zero connector-grant incidents because the app no longer depends on the artifact runtime.
6. **Cost:** two to four weeks part-time; Supabase stays free if Pearls is paused or a second free project is available.
7. **Risks:** discovering the core is too thin (which means the product is the workshop and the cut was wrong; better to learn now); auth or RLS mistakes (policy #38); scope creep into features.
8. **Go/no-go:** defects ≤ 3 and no workshop dependence → Stage 3. Otherwise re-cut the core.

### Stage 3: First outside users (5 to 10, already the queued goal)

1. **Objective:** learn install friction and whether strangers come back.
2. **Build:** onboarding fixes only; a private founding channel that costs nothing (GitHub Discussions in a private repo, or a small Discord); opt-in usage pings (weekly self-report is acceptable).
3. **Do not build:** public community, registry, marketplace, jobs.
4. **Hypothesis:** strangers install unaided and return without you nudging them.
5. **Success:** 5 or more complete installs; median install ≤ 45 minutes; 3 or more active at day 30 (8 or more sessions); 1 or more builds a skill; support ≤ 2 hours a week.
6. **Cost:** 20 minutes a day for four to six weeks.
7. **Risks:** silent churn; each Claude release breaking a skill; you fixing everyone's setup by hand.
8. **Go/no-go:** 3 of 10 retained at day 30 → Stage 4. Fewer → fix the product, not the plan.

### Stage 4: First revenue

1. **Objective:** strangers pay $79 for proof-of-done and an owned record.
2. **Build:** nothing new in product. Marketing per the existing plan: X, r/ClaudeAI, Show HN, Product Hunt one shot after video 1, creator outreach loop, and outcome content from you and the validation users.
3. **Do not build:** network features beyond the founding channel.
4. **Hypothesis:** the pitch converts organically at the decided price.
5. **Success:** within 90 days, 25 paid; activation ≥ 40% (install plus first session recorded); refunds ≤ 10%; support ≤ 2 hours a week; at least one unsolicited outcome story.
6. **Cost:** 4 hours a week (the standing stop rule); $0 to $100 in tools.
7. **Risks:** sales without activation; a platform feature launch; price objections; the marketing budget of time crowding out fixes.
8. **Go/no-go:** ≥ 25 paid and ≥ 40% activation → Stage 5. Sales but activation below 40% → fix onboarding first. Fewer than 10 sales → revisit ICP and pitch; do not build the network.

### Stage 5: Seed Meeting of the Minds

1. **Objective:** a living, verified, attributed library that paying users pull from and push to.
2. **Build:** (1) public GitHub registry repo, one folder per item with a manifest (id, kind, author, license, version, parent, origin, changelog, acceptance test, provenance); (2) contributions as pull requests through `mom-gate` plus an automated injection/exfiltration scan; (3) "MOM Verified" = gate pass plus a clean-install run by a named verifier, recorded; (4) a MOM-owned Supabase index (read-only anon, RLS, optional pgvector) and a `/find` skill that queries it from inside the user's Claude; (5) GitHub Discussions for talk; (6) membership = the renewal (updates plus registry plus discussions); (7) seed the ~50 curated items from your `ship` and `generalize` skills, policies, and loops (about 135 candidates), plus imports with provenance.
3. **Do not build:** jobs, payments, reputation engine, lineage UI, hosted brains, notifications beyond a changelog.
4. **Hypothesis:** paying users contribute and reuse without being paid to.
5. **Success:** within 90 days, 10 or more external pull requests merged; 5 or more forks or improvements of someone else's item; 30% or more of members use `/find` monthly; 3 or more MOM Verified items not authored by you; zero security incidents from listed items.
6. **Cost:** 20 minutes a day plus verifier time; infrastructure $0 to $25 a month.
7. **Risks:** empty-room effect; a malicious contribution; you as the sole verifier; drift back to building features instead of reviewing contributions.
8. **Go/no-go:** at least 3 of the 5 success metrics met, including the 10 merged external pull requests → Stage 6. Otherwise keep the registry as a free asset and stop here; that is a fine outcome.

### Stage 6: Jobs and marketplace experiments (no infrastructure)

1. **Objective:** money moves between members without MOM being a party.
2. **Build:** (1) MOM-builds-MOM bounties: you post a spec with `done_when`, fixed price, sealed claims, one selected claimer, delivery by pull request through the gate, manual payout; (2) paid registry items sold through creators' own merchant-of-record links, MOM at 0%; (3) a "help wanted" board in Discussions with MOM taking no part in payment.
3. **Do not build:** escrow, Stripe Connect, disputes, reputation math, a jobs app.
4. **Hypothesis:** sealed selection before work produces good deliverables at fair prices, and members will hire each other.
5. **Success:** 10 or more bounties completed by 3 or more distinct people; 5 or more paid items sold by creators other than you; 1 or more member-to-member paid job reported; zero disputes you had to adjudicate.
6. **Cost:** a bounty budget you set ($1,000 to $2,000 over six months is a reasonable test) plus a 1099-NEC for any payee you pay $2,000 or more in 2026 (the threshold was raised from $600 by the 2025 legislation).
7. **Risks:** contribution quality; tax forms; a contributor disputing attribution or payment; scam-adjacent perception if "earn with AI" becomes the headline.
8. **Go/no-go:** ≥ $2,000 manual GMV and ≥ 5 members asking for a real jobs flow → design Stage 7 jobs with rails. Otherwise keep bounties only.

### Stage 7: Network expansion (only if 5 and 6 pass)

1. **Objective:** network revenue (membership plus fees) that pays for itself and could exceed license revenue.
2. **Build:** hosted brain option for non-technical users (Supabase Pro, multi-tenant RLS, DPA, GDPR posture); Play Store listing via Trusted Web Activity and the iOS shortcut; a real marketplace on existing rails (Whop, or Stripe Connect with the platform filing 1099-K); reputation computed from verified installs and completed jobs; lineage graph UI; community projects with revenue splits agreed before work; a paid verifier program; "improvement available" notifications from telemetry; community-built MOM features as the standard process.
3. **Do not build:** anything without a measured cost table (your §10.10.13 rule) and a named owner.
4. **Hypothesis:** the network, not the license, is what people renew for.
5. **Success:** renewal ≥ 60%; 500 or more members; 100 or more verified items; GMV covering infrastructure and verifier costs; membership revenue ≥ license revenue within 12 months of this stage.
6. **Cost:** real money and probably a second person; legal review of terms, DPA, and marketplace status.
7. **Risks:** everything in question 15; founder burnout; platform terms changes.
8. **Go/no-go:** go on hosting and hiring only if membership renewal is 60% or more and membership revenue has matched or exceeded license revenue for two consecutive quarters; otherwise hold the network at Stage 5–6 scale, which is a viable end state. This is also the point to decide on incorporation and whether the core goes open source.

---

## Part 6: Buckets

### KEEP (strongest parts of the idea)

1. Private by default, shared by choice, with the brain in the user's own database.
2. Specialization without silos as the community thesis; cross-domain pattern transfer as the marketing story.
3. MOM Verified defined as functional verification on a clean install (the gap every registry has today).
4. Idea lineage with attribution that survives forks (implemented on git).
5. Manual copy/paste handoff to Claude: it is the compliant design, not a compromise.
6. No lock-in: what you installed keeps working when you stop paying.
7. Outcome-based marketing, with your own record as the first case.
8. "MOM builds MOM" through gated pull requests.
9. Selection before work, with a minimum bid and vetted bidders, in any jobs flow.
10. Earning playbooks written as `done_when` for services.
11. "Making money is one branch," not the product: it keeps MOM out of the scam-adjacent "make money with AI" category (question 24, item 8) while bounties still supply real demand.

### CHANGE (good ideas needing modification)

1. Pricing: one-time plus membership → year-one license with membership as the renewal, one SKU.
2. Native Android app → PWA with Auth and RLS first; Trusted Web Activity for the store; Capacitor only if needed.
3. AI-first discovery → a `/find` skill over a small read-only index inside the user's Claude; no MOM-hosted inference.
4. Marketplace → free registry first; paid items through creators' own merchant-of-record links; MOM at 0% until 20 paid items sell.
5. Jobs → bounties with you as the only poster for a year.
6. Positioning → "the record and the proof," not "personal AI OS" or "memory."
7. Lineage engine → git plus manifests.
8. Reputation → counts of verified contributions and completed bounties, displayed not scored, until there is an audience.
9. Community platform → GitHub Discussions or a free Discord until 100 members; not Skool or Circle.
10. "As many MOMs as users" → one ICP for the first 100 buyers.
11. Membership value → updates plus registry plus discussions, explicitly listed, because year-two value must be visible.
12. Sealed bids → keep the minimum/maximum range and poster selection, add vetting; drop sealed-bid mechanics as a claimed differentiator (the evidence does not support them).

### DEFER (valuable but premature)

1. Hosted multi-tenant MOM.
2. App Store and Play Store apps (after the PWA proves daily use).
3. Paid marketplace with MOM as seller or fee-taker.
4. Jobs marketplace with escrow and disputes.
5. Reputation engine.
6. Lineage graph UI.
7. Community projects with revenue sharing.
8. Paid verifier program.
9. "Improvement available" notifications.
10. Discovery over outside sources (Claude already searches the web; provenance capture is the part to design).
11. Open-sourcing the core (a stage-7 decision).

### DROP (complexity or risk outweighs value, at least as described)

1. A MOM-run AI discovery service with its own inference and billing.
2. Automated job execution using the user's Claude session (terms violation since April 2026; also removes the control you said you want).
3. MOM as a party to transactions or holder of funds (holding funds is treated as money transmission; Bountysource went bankrupt in 2023 with at least $21,702 of developers' bounties still in its escrow).
4. Uploads of "free resources" without scanning and review (the 2026 skill-hub compromises are the precedent).
5. A social feed or general discussion product as a core feature.
6. The Termux/Node licensing server (already deferred; keep it dropped).
7. Multi-seat licensing now (already decided single-user).

### QUESTIONS FOR DUSTAN (decisions that need your judgment)

1. Is MOM the primary venture for the next two quarters, or one of three alongside Pearls Library and CSSI? The roadmap assumes 10 or more hours a week; the brain shows Pearls at 2–3 hours a day.
2. Renewal as membership: do you approve folding the $10/mo idea into the day-366 renewal (one SKU)? And which renewal price do we test first: $49/yr (recommended in question 22), $5/mo, or the $79/yr flat that the 365 spec recommended and question 22 argues against?
3. Data custody as a principle: will MOM ever host users' brains (hosted tier: easy onboarding, but DPA, GDPR, breach liability), or is "we never hold your data" a brand rule? This decides Stage 7's shape and how the PWA authenticates.
4. Open core: are you willing, later, to make the 12-skill core free or open source and charge for membership, verification, and hosting? Yes widens the funnel; no keeps the purchase signal clean. Not needed now, but it changes how you write the license.
5. Beachhead ICP: confirm or override the recommendation in question 3 (solo business operators who run their operations in Claude, your mirror) versus Claude power users in general.
6. Bounty budget: what cash will you put into MOM-builds-MOM in the first six months ($500, $1,000, $2,000)?
7. The "make money with AI" branch: keep it as an explicit community lane (with FTC and scam-adjacency risk to your brand), or position around "proof of work" and let earning be an outcome people report?
8. Publish the verification standard: will you make the acceptance gate and blind hostile-review protocol public? It becomes the moat and the mark, and it also becomes copyable.
9. Runtime claim: "built on Claude" only, or test skills on a second Agent-Skills runtime (Codex CLI, Gemini CLI) so "your record, whatever model" is true?
10. Governance reuse: the multi-model build lane and Dream Mode are kept out of the product (§10.14). Is the build lane the template for community contributions, or does it stay a private tool?
11. Name collision: "MOM" for both the product and the network is deliberate, but the queued community goal and the Gumroad listing already call the buyer group "founding members." Confirm the network name before any public copy.

---

## Part 7: Evidence appendix

### 7.1 Facts taken from your own system (verified this session)

1. Brain row counts and dates: read-only SQL on the brain project, 2026-09-27 (Part 2.2 table).
2. Product, pricing, gates, decisions: artifacts "MOM Launch Decisions" (2026-09-24), "MOM 365 Decisions" (2026-09-23/24), "MOM Competitor Scorecard" (2026-09-18), "The Workshop and the Storefront" (2026-08-28).
3. Build-lane governance and scope rule §10.14: `mom-build` README, `setup/G0-steps.md`, rulesets (commit e628fe5, 2026-09-25).
4. Listing state: mindsovermatters.gumroad.com/l/minds-over-matters ("not currently for sale", $79); mindsovermatters.co ("coming soon", noindex).
5. Skill usage, product_fit split, loops, domains, policies #3, #38, #56, #69, #73, #79: read-only SQL, 2026-09-27.

### 7.2 External facts (verified by research agents on 2026-09-27; access date same unless noted)

1. Anthropic consumer terms bar automated access to Claude.ai/Pro/Max except via API key; the terms language was clarified on 2026-02-20 and enforcement that Pro/Max OAuth credentials power only Claude.ai and Claude Code began 2026-04-04 (anthropic.com/legal/consumer-terms; The Register 2026-02-20; VentureBeat, April 2026).
2. Claude Code mobile deep links `claude://code/new?q=` and `https://claude.ai/code/new?q=` prefill without sending, and desktop uses `claude-cli://open`; the Claude Android app appears in the system share sheet; iOS exposes an "Ask Claude" intent (code.claude.com/docs/en/deep-links; support.claude.com articles 14898120, 14729294, 11869629, 10263469).
3. PWA install criteria and iOS limits (web.dev, MDN, Apple/community docs); Trusted Web Activity via PWABuilder; Google Play developer fee $25 one-time (blog.pwabuilder.com; developer.android.com).
4. Supabase: free tier 2 active projects, pause after 7 idle days, Pro $25/month per org; RLS `auth.uid()` pattern; Supabase MCP `apply_migration` lets Claude apply migrations to a connected project (supabase.com/pricing; supabase.com/docs, some via cached excerpts because supabase.com blocked direct fetch from this container).
5. Claude API list prices for an optional BYO-key mode: Sonnet 5 $2/$10, Opus 5 $5/$25, Haiku 4.5 $1/$5, Fable 5.1 $10/$50 per million tokens in/out (claude-api skill rate card, corroborated 2026-09-27).
6. Anthropic skills repo (Apache-2.0), in-app skills directory; third-party indexes (~7,200 and ~23,600 skills); no Anthropic paid-skills market; Agent Skills open standard published 2025-12-18; the "32 tools by March 2026" count comes from secondary coverage, not an Anthropic figure (github.com/anthropics/skills; support.claude.com article 14328846; VentureBeat; SiliconANGLE).
7. OpenAI: GPT Store revenue share largely never paid; Custom GPTs retire (creation freeze 2026-10-26, retirement 2026-12-11) in favor of Plugins carrying Skills; Apps SDK launched October 2025 (help.openai.com articles 20001519 and 8798878).
8. n8n ~12,500 community workflows, no per-template payout; Zapier template gallery with no verified count and no creator payment; PromptBase 330,000+ prompts, 20% fee; Whop 2.7%+$0.30 with the 30% marketplace commission removed in 2025; Gumroad 10%+$0.50 merchant of record since January 2025; Lemon Squeezy 5%+$0.50 merchant of record; Etsy $0.20 listing + 6.5% + processing.
9. Registries verify identity, not behavior: MCP Registry (reverse-DNS namespace ownership, ~9,652 servers, May 2026), Smithery "author verified" = GitHub ownership, Glama trust ladder, Docker Verified Publisher = identity review; npm provenance attestations exist but adoption is ~12.6%; Hugging Face `base_model` lineage is self-reported and over 60% of models have none.
10. Attribution loss precedent: github.com/davila7/claude-code-templates/issues/121.
11. Community platforms: Skool $9/mo (10% fee) or $99/mo; Circle $89/mo (2%); Discord server subscriptions 90/10; Patreon 10% for new creators; Mighty Networks from $79/mo; Substack 10%; GitHub Sponsors 0% personal, Discussions free. Only Whop and Skool's classifieds offer member-to-member paid transactions.
12. Benchmarks (aggregator-sourced, directional): paid community churn about 5.8% monthly, highest in the $10–25 band; freemium conversion about 3.7%; Whop median product revenue $72/month vs $2,984 average.
13. One-time plus optional subscription precedents: Obsidian (free, Sync $4/mo, Publish $8/mo), Sublime ($99 perpetual with 3 years of updates), JetBrains perpetual fallback after 12 months, Setapp one-time path added March 2026.
14. AI side-hustle communities: large free Skool funnels (280k+ and ~85k members) into $59/mo to $5,000+ upsells; FTC actions in 2025–2026 against AI passive-income schemes; widespread refund complaints.
15. Outcome marketing precedents: Skool Games leaderboards; Thomas Frank's Notion templates (about $1.0M in 2022 by his own report, $2.1M over two years; Notion marketplace 30,000+ templates and 2,000+ creators per Notion's own page); Gumroad and Whop creator-stat content.
16. Legal: US Copyright Office Part 2 report (2025-01-29) on AI-generated works; CC BY 4.0 and marketplace CLAs; CPRA and state thresholds; GDPR has no small-business exemption; Supabase DPA; CVE-2025-48757 (303 publicly readable endpoints from missing RLS); marketplace-facilitator laws vary for digital goods; federal 1099-K threshold restored to $20,000/200 transactions (2025 legislation) with MD/MA/VT/VA at $600; EU non-union OSS with no threshold; Stripe Connect 1099-K filing; DMCA agent $6; Section 230 narrowing in 2026 rulings; California SB 940 on venue.
17. Competitors and platform: Claude memory free for all users since March 2026; Projects on Pro and above; Cowork on Pro since 2026-01-16, Windows GA 2026-04-09, merging into the main chat UI from 2026-09-16; Pro $20/mo ($17 annual), Max $100–$200/mo, Claude Code on all paid tiers, no standalone mobile Claude Code app; ChatGPT memory free since June 2025; Gemini personal context; Microsoft 365 Copilot memory GA January 2026; OpenClaw 250,000+ stars in about a month (renamed 2026-01-30, 250,829 stars by 2026-03-03); mem0 65,000+ stars and $24M raised; AnythingLLM ~62,700; Khoj ~35,000 (cloud sunset 2026-04-15); Letta ~24,700; Zep ~27,000; Rewind/Limitless acquired by Meta, service shut down 2025-12-19; lifetime-deal AI tools trend toward one-time shell plus recurring credits ("models ship weekly").
18. Fraud and security: friendly fraud up to 80% of digital-goods chargebacks (industry statistic, Justt); gig-platform fake-delivery and multi-accounting fraud (Incognia 2025 report; no chargeback ratio is given there); malicious `postmark-mcp` (September 2025, downloaded by up to ~1,500 organizations per reporting); "ClawHavoc" (Koi Security, January–February 2026, 341 malicious ClawHub skills); Snyk "ToxicSkills" audit (3,984 skills, 36.8% flaw rate, 76 malicious).
19. Gig fees and mechanics: Upwork 0–15% (most about 10%) plus paid Connects, escrowed milestones, mediation then arbitration; Fiverr 20% seller plus 5.5% buyer fee, 14-day clearance; Contra 0% for freelancers (client Pro $12–29/mo), 120-hour dispute window; Braintrust 15% client markup; Mercor about 30% placement (support.upwork.com; help.fiverr.com; contra.com/pricing).
20. Bounty platforms: Replit Bounties transitioned to Contra in July 2025; Algora active (maintainer picks the merged pull request, paid via Stripe Connect); Bountysource defunct (parent bankruptcy November 2023, at least $21,702 of developers' bounties unpaid from escrow); Polar's issue funding in maintenance mode; Boss.dev small. None implements sealed bidding; all pay on merge.
21. Bidding evidence: Hong, Wang and Pavlou, *Information Systems Research* (2016), 71,437 open vs 7,499 sealed auctions: sealed bidding drew at least 18.4% more bids while open bidding gave higher selection and completion odds (the exact odds figures sit behind the paywall and were not independently re-read); no peer-reviewed study found that sealed bids protect suppliers from underbidding. Upwork's floors are $3/hour and $5 fixed; practitioners' lever is vetted, invite-only supply (Toptal admits about 3%).
22. Rails and reporting: Stripe Connect Express/Custom $2 per active account per month plus 0.25% + $0.25 per payout and $2.99 per 1099 e-filed; holding buyer funds yourself is treated as money transmission; 1099-K $20,000 and 200 transactions (IRS FAQ under the 2025 act); 1099-NEC threshold $2,000 for payments made in 2026; Stripe's hosted onboarding absorbs KYC (stripe.com/connect/pricing; irs.gov; taxbandits.com).

### 7.3 What could not be verified from this container

1. The full Gumroad storefront (CAPTCHA); only the MOM product page was read.
2. Direct fetch of supabase.com and v2.tauri.app pages (proxy); those facts rest on cached excerpts and secondary sources.
3. The contents of the product bundle itself (it lives in Claudes Place on OneDrive, not in git); counts come from the brain and your decision artifacts.
