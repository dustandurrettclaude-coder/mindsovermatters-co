# Native Android MOM app — inspection findings and phased plan

Status: **PROPOSAL, awaiting Dustan's approval. Nothing below has been built. No schema, grant, or
desktop-dashboard change has been made.**
Brain goal: `2026-09-27-android-mom-app` (deploy_memory id 756, domain infra, status queued, gate = plan approval).
Written 2026-09-27 by session 20260927-161451 (Claude Code, cloud). Every fact marked *measured* was read from
the live brain, the dashboard source files, or this container during the session; anything marked *assumed* or
*unverified* is labelled as such.

---

## 0. The ask, restated in one paragraph

Put MOM on Dustan's Android phone as an installed app (APK first, store-ready later) that talks to the **same
Supabase brain** the desktop dashboard uses, looks and behaves like the desktop dashboard (same brand, colours,
sections, terminology, controls), rearranged for a phone. Key loop: phone **Pick up** → Supabase updates →
prompt on the clipboard → Claude works → Supabase updates → phone reflects it. Build the personal version first,
but leave the door open for Meeting of the Minds (community, Jobs, Marketplace, Discovery, Profile, MOM Verified)
and a commercial multi-customer edition: no personal identity, personal Supabase ids, local paths, or privileged
keys compiled into the app; private data and deliberately shared data kept strictly apart. **Private by default.
Shared by choice.**

---

## 1. What exists today (inspection results)

### 1.1 The desktop dashboard is a single-file Cowork artifact, not a web app

| Fact | Measured value |
|---|---|
| Location (live) | `<PC>/Claude/Artifacts/brain-dashboard/index.html` (path scrubbed; this repo is public) (Cowork artifact; `system_cache.dashboard_last_publish`) |
| Sources on disk / Drive | `1 BRAIN/Specs & Setup/2026-09-21-dashboard-v3-redesign/dashboard-v3-phase3/index.html` (v3.3, sha256 `ed7f1c22…`, 174,342 B, 2,238 lines) and `…/dashboard-v3.4-goal-tabs/index.html` (v3.4 staged, Drive copy sha256 `177a0c55…`, 197,735 B, 2,547 lines; a revision newer than its PATCH-NOTES, which describe `580d477b…`) |
| Framework | None. Vanilla HTML + CSS + one inline `<script>` (~131 K chars of JS). No bundler, no npm, no build step, no external JS. The only external asset is one Google Fonts stylesheet requesting three families (Bricolage Grotesque for display, IBM Plex Sans for body, IBM Plex Mono; the `--mono` token itself falls back to the system monospace stack) — the app must bundle those font files so the look survives offline. |
| Persistence in the page | None on purpose (manifest item [13]: no localStorage). All preferences live in `public.system_cache` key `dashboard_prefs` (v, layout, theme, accent, density, tabs, hidden, labels, home, whidden, title, domOrder, domLabels). |
| Backend access | `window.cowork.callMcpTool('mcp__…__execute_sql', {project_id, query})` — raw SQL text sent to the Supabase MCP `execute_sql` tool, which runs as DB role **`postgres`** (`rolbypassrls = true`, measured 2026-09-17 and noted in the file). The page holds **no** anon, publishable, or service-role key. |
| Parser | `parse()` strips the MCP `<untrusted-data-…>` wrapper and `JSON.parse`s the array ([11]); `sql()` surfaces the real Postgres error; `wfail()` toasts every rejected write ([24]); a `-- cb:<nonce>` comment defeats the bridge's query cache ([20]). |
| Read surface | 11 tables: system_cache (8 queries), deploy_memory (7), dream_proposals (3), domains (2), system_flags, spinoffs, skill_catalog (the Skills tab reads only the catalog, never skill_registry), quick_actions, pending_confirmations, loops, brain_edges. |
| Write surface | 15 statements: 4 INSERTs (deploy_memory ×3 — add goal, quick capture, and an `audit` row written after every status or domain change; system_cache prefs upsert) and 11 UPDATEs (deploy_memory status + domain, spinoffs status, loops is_active ×7, system_flags system_paused). Goal rows are stamped `agent='dashboard'`. Every armed write is one confirm-click (`arm()`); deletes are soft (`status='deleted'`, [17]). |
| Chat hand-off | `sendToChat(text)` → `window.cowork.sendPrompt(text)` (opens a Cowork chat with the prompt) → fallback `copyText` (clipboard) → fallback copy modal. **Pick up writes nothing to the DB** ([19], [22]); the "picked" state is in-memory only. |
| Desktop-only bridge calls | `window.cowork.runScheduledTask(ref)` for quick actions of kind=task ([8]); `window.cowork.sendPrompt`. |

The v3 shell (goal `2026-09-22-brain-dashboard-v3`, done 2026-09-26): one `TABS_DEF` registry — **Home** (pinned
first, badge = pending confirmations), **Goals**, **Saved for Later**, **Parked**, **Loops**, **Skills**,
**Dreams** — in three rail groups **Work / Later / System**; side-rail or top-tabs layout; light / dark /
follow-system; four accents (the default "aubergine" set, plus harbor, ember, moss); comfortable / compact
density; Customize drawer; Ctrl+K Jump palette; keyboard shortcuts; seven Home widgets (`top-per-domain`,
`needs-click`, `dream`, `inbox`, `ready`, `health`, `quick`); Goals domain chips (MOM pinned first, then every
active `public.domains` row, dormant domains on an "on deck" shelf; v3.4 makes chips movable and renamable).

Design tokens in the shipped file (light): ground `#F6F3F9`, panel `#FFFFFF`, ink `#1E1530`, muted `#6F6784`,
line `#E4DEEC`, accent `#6366f1` on deep `#2C1A47`, good `#2E7D4F`, warn `#A8720F`, bad `#B3372B`, info
`#2F5FA8`, plus their soft variants, spacing/density tokens and the three font stacks; a full dark override; one phone breakpoint at `max-width:640px` that only collapses the rail to icons.
(The full token, font, terminology and function inventory is in §1.5 / Appendix A.)

**Open fact (D1 below):** v3.4's PATCH-NOTES (written 2026-09-26) record that the live artifact file hashed to
the **v2.9 body** (64,457 B, sha `7615dda6…`) at 2026-09-26 05:56Z, with only its meta-description line taken
from v3.3, "why not known". Whether Dustan has since dropped v3.3/v3.4 back onto the live file cannot be
observed from here. The plan treats **v3.4 staged** as the design reference; if the intent is v2.9, say so.

### 1.2 The buyer edition already has the shape a phone needs

The Minds Over Matters product ships `dashboard-template.html` plus the `brain-setup` provisioner skill
(read from the shipped `brain-setup.skill`, 274 KB; independent extraction in Appendix B). *Measured:* each
buyer provisions **their own Supabase project** (single tenant; "DEDICATED projects only" in step 1e is about
whether that one project is shared with the buyer's other apps, not about buyer-to-buyer isolation); the buyer
dashboard **embeds the publishable key in the static HTML** and reads/writes the project's REST API from the
browser (`Promise.all` reads, a `capture()` POST, PATCH-style status updates); **Supabase Auth is not used** (zero
`auth.users` / `auth.uid()` references; all 20 policies name `anon` or `service_role`); anon holds SELECT on nine
tables, INSERT on six `deploy_memory` columns and column-level UPDATE on six tables — **15 column grants in all,
no DELETE anywhere** — and nothing on the other nine core tables; `done_when` / `done_when_kind` are unreachable
*by privilege*, proven on `mom-buyer-test` 2026-09-24. Licensing is an offline Ed25519-signed key checked by
`verify-license.cjs` (no device binding) and stored in `system_cache`. This matters because the phone cannot
use the Cowork bridge: the buyer edition proves the same board can be driven through the REST API with a public
key and a tight server-side ceiling — the phone adds a signed-in identity on top of that pattern.

### 1.3 The live brain today (security posture, measured 2026-09-27)

| Item | Measured |
|---|---|
| Project | `<brain-project-ref>` (ref scrubbed; this repo is public), us-east-1, Postgres 17.6, ACTIVE_HEALTHY. Free tier: two active projects max (`pearls-library` active, `mom-buyer-test` paused). |
| RLS | Enabled on every public table. |
| Policies | 17 total. Role **anon**: `deploy_memory` SELECT where key='goal_meta'; `deploy_memory` INSERT only (key='goal_meta', status='queued-unreviewed', agent='desktop'); `domains` SELECT; `system_flags` SELECT. Everything else is `service_role_only` or has **no policy at all** (= denied). Role **authenticated: zero policies anywhere.** |
| Grants | anon and authenticated still hold the Supabase default table-level SELECT/INSERT/UPDATE/DELETE on every public table (TRUNCATE was revoked 2026-09-17); RLS is what actually blocks them. |
| Supabase Auth | `auth.users` = 0 rows. Never used. |
| Keys | A legacy anon JWT and a modern `sb_publishable_…` key both exist and are enabled (values deliberately not written here). |
| Extensions / functions | pg_cron, pg_net (in public — advisor WARN); one Edge Function `keepalive`; six `factory.*` functions with mutable search_path (WARN). |
| Advisors | 60 tables "RLS enabled, no policy" (INFO — correct for a postgres-only brain). |

Consequence: **with the keys that exist, a phone can today read goal_meta and domains and quick-capture a goal,
and nothing else.** It cannot read pending confirmations, spinoffs, loops, prefs, skills, dreams, or health, and
it cannot change a status. A mobile access layer must be added on the server before any app can work.

### 1.4 This build environment

*Measured:* Java 21, Gradle 8.14.3, Node 22 present; **no Android SDK**, and the egress policy returns 403 for
`dl.google.com` (SDK downloads) and for `*.supabase.co` (PostgREST). Maven Central, Google Maven, npm and GitHub
are reachable. So: APKs are built by **GitHub Actions** (Ubuntu runners ship the Android SDK), not in this
container; the database is reached from here only through the Supabase MCP connector; the app's REST path is
tested on the phone and in CI, not here.

### 1.5 What can be reused, what cannot (summary; Appendix A has the per-function list)

| Layer of the desktop file | Reusable on the phone? | How |
|---|---|---|
| Database + its semantics (tables, statuses, badges' `row_number` formula, soft delete, one-writer rule, prefs row) | **Yes, 100 %** | Same project, same rows. The phone is one more client of the same truth. |
| Terminology, tab registry `TABS_DEF`, widget registry, domain-chip rules, status colours, pick-up prompt templates | **Yes, verbatim** | Lifted into a small shared module (`mom-core`). |
| CSS tokens (light/dark/accents/density) and card/stripe/pill conventions | **Yes** | Same stylesheet, plus a phone layer (bottom nav, single column, larger tap targets). |
| Render functions (`card`, `render*`, `homeWidget`, `spinoffCard`, `loopCard`, Skills views, Dreams panes) | **Mostly** | They build HTML from the already-loaded arrays; they need no bridge. Inline `onclick` strings and globals make them copy-then-adapt today, shareable after a light refactor (Phase 3). |
| Data layer (`q`, `sql`, `parse`, cache-bust) | **No** | Cowork-bridge specific. Replaced by a `DataSource` adapter over supabase-js (auth session + RPC/policies). |
| `sendToChat` (Cowork `sendPrompt`), `runScheduledTask` | **No** | Replaced by clipboard + an "Open Claude" intent; task-kind quick actions stay desktop-only (shown disabled with a note). |
| Pointer-drag reordering, Ctrl+K palette, Alt+arrows, 1–9 keys | **Partly** | Drag becomes up/down buttons in Customize; palette becomes a search field; keys dropped. |

---

## 2. Proposed architecture

### 2.1 Shape

```
Android APK "Minds Over Matters" (applicationId co.mindsovermatters.mom)
└── Capacitor shell (Android WebView, native plugins) — no server, assets ship inside the APK
    ├── www/                     the MOM web core (forked from dashboard v3.4, no bundler)
    │   ├── core/                tokens.css · tabs.js (TABS_DEF, widgets, terminology) · prompts.js (pick-up text)
    │   ├── ui/                  render functions (cards, boards, widgets, Skills, Dreams) + phone layout layer
    │   ├── data/                DataSource interface
    │   │   ├── supabase.js      supabase-js: Auth session + RPC + RLS-scoped selects     ← mobile
    │   │   └── cowork.js        (parity adapter around the existing sql()/parse(); future desktop use)
    │   └── modules/             feature registry: my-mom (built) · meeting-of-the-minds · jobs · marketplace ·
    │                            discovery · profile · verified  (stubs behind flags; NOT built now)
    ├── native/                  Capacitor plugins: Clipboard, App/Browser (open claude.ai/new?q=…),
    │                            SecureStorage (auth session), Preferences (device-only conveniences)
    └── config/                  runtime config, never code: { brain:{url, publishableKey}, community:null }
                                 injected at build from CI secrets for the personal APK; entered on a
                                 "Connect your brain" screen for anyone else (Phase 3)

Supabase brain project (per user; Dustan's today)      Supabase community project (future, shared)
├── existing tables, unchanged                          ├── auth.uid()-scoped RLS on every table
├── + "MOM Brain API v1": RLS policies for role         ├── posts, jobs, products, profiles, projects …
│     authenticated + a small set of RPC functions      └── receives ONLY what the user explicitly publishes
└── Supabase Auth: exactly one user (Dustan), signups off
```

Why a WebView shell and not a native rewrite: the entire desktop UI is HTML/CSS/JS with no framework, so the
only path that satisfies "same visual language, same controls" *and* "not two independent implementations" is to
run that code on the phone. Capacitor packages web assets inside the APK (no hosting), gives native clipboard /
intents / secure storage through plugins, and is a standard, Play-Store-accepted way to ship. A Kotlin/Compose
rewrite would duplicate ~130 K chars of logic and drift immediately. (Flutter / React Native have the same
duplication problem.) The cost is WebView performance and feel, which is acceptable for a card-and-list board.

### 2.2 The server-side contract: "MOM Brain API v1" (proposed, not applied)

The phone never runs as `postgres` and never carries a service-role key. It signs in with Supabase Auth and
acts as role `authenticated`, which today has no rights at all. Proposed additions, shipped as ONE reviewed SQL
migration file (`sql/0001_mom_brain_api.sql`), applied by Claude Code through the Supabase connector only after
approval (one-writer rule), and later packaged into `brain-setup` so buyer brains get the identical API:

1. **Read policies for `authenticated`** on exactly the 11 tables the dashboard reads: deploy_memory, domains,
   spinoffs, loops, pending_confirmations, system_cache (keys `brain_meta`, `dashboard_prefs`, `dream_*`),
   system_flags, skill_catalog, quick_actions, dream_proposals (aggregates + inbox rows, per the Dreams-tab
   rules), brain_edges (counts). Single-user project, so the policy is "signed in", not `owner_id`.
2. **Write RPCs** (SECURITY DEFINER, EXECUTE granted to `authenticated` only, revoked from public/anon), one per
   desktop write, same guards as the buyer ceiling: `mom_capture(text, domain)`, `mom_set_goal_status(goal_id,
   status)` (done/parked/active/deleted only), `mom_move_goal(goal_id, domain)`, `mom_set_spinoff_status`,
   `mom_set_loop_active`, `mom_set_paused(bool)`, `mom_save_prefs(jsonb)`. All stamp `agent='mobile'`, write the
   same `audit` row the desktop writes after a status or domain change, and none can touch
   `done_when`/`done_when_kind`/`value` free-form (manifest [12] and buyer ruling A1 carried over).
3. **Pick-up RPCs** — the one new behaviour the phone adds: `mom_pick_up(kind, id)` sets `lease_owner =
   'mobile:<user>'` and `lease_expires_at = now() + 2h` on the goal / spinoff (both tables already carry lease
   columns; reconcile already honours leases), returns the pick-up prompt text built server-side from the same
   template as the desktop; `mom_release(kind, id)` clears it. The desktop keeps writing nothing on Pick up
   (unchanged); the phone's lease is what makes "Supabase updates" true and lets the desktop show "picked up on
   phone" whenever it chooses to read the lease columns.
4. `mom_api_version()` → `'1.0'` so a client can refuse to run against a brain that lacks the API.
5. No new tables. No change to existing policies, grants, triggers, or the anon ceiling.

Alternative considered (D4): direct table writes through wide `authenticated` UPDATE policies. Rejected because
every write would then need column-level guards re-proven on each table, exactly the hole the buyer edition
spent v3.9.2 closing; RPCs keep the writable surface to seven named operations.

### 2.3 Authentication and isolation

- **Personal build:** Supabase Auth email + password (magic links would need SMTP; passwords need nothing),
  one user, **sign-ups disabled** in the project's Auth settings, session held in Android secure storage and
  refreshed by supabase-js. The publishable key is public by design; the account is the secret.
- **Commercial build (later):** unchanged code — each customer signs in to *their own* brain project (the
  product's existing single-tenant model), so isolation between customers is by project, not by row. A shared
  multi-tenant brain is explicitly *not* proposed; if it is ever wanted, the API in 2.2 is where `owner_id`
  checks would go.
- **Community (later):** a separate Supabase project with `auth.uid()` RLS; the app holds a second client for
  it; nothing crosses from the brain client except a deliberate `publish` action that copies one chosen item.
  The two clients live in separate module folders with an import rule enforced by a lint check.

### 2.4 The pick-up loop on the phone

1. Find the card (Home widgets, Goals board, Saved for Later, Loops) — same names, same badges.
2. Tap **💬 Pick up** → `mom_pick_up` (lease) → prompt text returned → written to the clipboard (Capacitor
   Clipboard) → toast "Prompt copied — paste into Claude".
3. **Open Claude** button: fires `https://claude.ai/new?q=<prompt>` (*measured:* the web app prefills the
   prompt from `q`; *unverified:* whether the Claude Android app claims that link — if it does not, the link
   opens Claude in the browser, and the clipboard path still works. Verified on the device in Phase 1).
4. Claude works; brain rows change (next_action, status, memos).
5. Phone refreshes on foreground / pull-to-refresh (Phase 1) and by Supabase Realtime on `deploy_memory`
   (Phase 2), showing the new state and clearing the lease when the goal moves.

### 2.5 Phone layout (same MOM, rearranged)

- Header: brain glyph + title (from prefs), quick capture collapses into a "+" sheet.
- Bottom navigation = the **Work** group (Home, Goals) plus **More**, which opens the Later / System tabs
  (Saved for Later, Parked, Loops, Skills, Dreams) in the same order and with the same badges as the rail.
- Goals domain chips scroll horizontally; MOM stays pinned first; boards are single column; drill-in opens
  as a full-height sheet; every confirm stays the desktop's two-tap `arm()` pattern.
- Home widgets stack single column in the saved order; Customize drawer keeps hide/show/reorder with buttons.
- Theme, accent, density come from the same `dashboard_prefs` row, so the phone inherits Dustan's look.

### 2.6 Distribution path

- Phase 1–2: GitHub Actions builds a **signed release APK** on every tag; Dustan downloads and sideloads
  ("install unknown apps"). Signing keystore is created by Dustan once and stored only as CI secrets.
- Later: the same Gradle project produces an AAB for Play internal testing → production. Kept true from day one:
  reverse-domain applicationId, `versionCode` discipline, current target SDK, no cleartext traffic, no secrets
  in assets, third-party licences listed. (A Play developer account costs money — never bought without asking.)

---

## 3. Guard-rails honoured (the "don't paint us into a corner" list)

| Requirement | How the plan meets it |
|---|---|
| No hard-coded personal identity | Auth session decides who; no user id, email, or name in code. |
| No personal Supabase ids in logic | Project URL and publishable key are runtime config (CI secret for the personal build; a Connect screen later). The desktop file's `P='<brain-project-ref>'` constant is *not* copied. |
| No privileged credentials in the APK | Only the publishable key (public by design) plus the user's own session. Service-role never leaves the server; verified per build by a shell scan of the APK contents. |
| No local paths | None needed on a phone; the Cowork-era constants (`C:/Users/…`, MCP tool id) are dropped with the bridge. |
| User config separated from code | `config/` + secure storage + the prefs row; nothing user-specific under `www/`. |
| Different users, only their own MOM | Per-project isolation now; `authenticated`-only API; no cross-project client. |
| Private vs shared | Two clients, two projects, one explicit publish action, an import lint rule. |
| Modular for Jobs/Marketplace/Community/Discovery/licensing | A module registry with flag-gated stubs; the brain API is versioned. |
| Store distribution possible later | Capacitor/Gradle project from day one; APK today, AAB later. |
| Desktop dashboard untouched | The desktop file is forked, not edited; the migration adds objects only. |
| Supabase stays the source of truth | The phone caches nothing authoritative; every write is an RPC on the brain. |

---

## 4. Phases and done_when

Evidence kinds follow the brain's convention: **sql** (a query Claude runs), **shell** (a command), **manual**
(Dustan observes). Each phase ends with a fresh verifier subagent that did not do the work.

### Phase 0 — Foundations (after approval; ~2 sessions)
- New repo `mom-app` (D2) with the Capacitor project, `www/` seeded from dashboard v3.4, CI workflow building a
  debug APK, secret-scan job.
- `sql/0001_mom_brain_api.sql` written, adversarially reviewed by a fresh verifier, then applied to the brain
  through the Supabase connector.
- Dustan: create his Auth user (Supabase dashboard → Authentication → Users → Add user), disable sign-ups,
  add the CI secrets (URL, publishable key). Each is a `pending_confirmations` row.
- **done_when:** sql — `select mom_api_version()` = '1.0' AND `select count(*) from pg_policies where policyname
  like 'mom_mobile_%'` ≥ 12 AND `select count(*) from auth.users` = 1; shell — CI produces `app-debug.apk`;
  manual — Dustan signs in on the debug APK and Home loads his real brain.

### Phase 1 — Personal MOM v1 (the MVP; ~3–4 sessions)
- Every tab reads live: Home (7 widgets, same numbers as `/close`), Goals (rollup, domain chips, boards,
  drill-in, on-deck shelf), Saved for Later, Parked, Loops, Skills (Buckets + Pipelines), Dreams (read-only
  panes; review buttons copy the same `dream review` line).
- Writes: quick capture, done / park / unpark / activate / soft-delete, move domain, spinoff status, loop
  toggles, pause, prefs; all via RPC, all two-tap confirmed, all failures toasted.
- Pick up: lease + clipboard + Open Claude; picked state shown from the lease, not memory.
- Theme / accent / density from prefs; phone layout per §2.5; signed release APK sideloaded.
- **done_when:** sql — `select count(*) from public.deploy_memory where lease_owner like 'mobile:%'` ≥ 1 and a
  goal_meta row with `agent='mobile'` exists; manual — the full loop (§2.4) observed once end-to-end by Dustan;
  verifier — parity table over manifest items [1]–[42], each marked ported / desktop-only / deferred, zero
  "unknown".

### Phase 2 — Live data and polish (~2 sessions)
- Realtime subscription on `deploy_memory` / `spinoffs` (or foreground polling if Realtime is declined),
  pull-to-refresh, offline read cache (non-authoritative), Jump palette as search, Customize drawer, app icon
  and splash in brand colours, crash-free error screens, versioning.
- **done_when:** manual — a change made by Claude on the desktop appears on the phone within 10 s without a
  manual refresh; shell — `unzip -l app-release.apk` + `strings` scan finds no `service_role`, no JWT with
  role service_role, no personal email or path; verifier — round clean.

### Phase 3 — Convergence and commercial readiness (~2–3 sessions)
- Extract `mom-core` (tokens, registries, prompts, render functions) so the desktop can adopt it when Dustan
  next changes the desktop (his drop, never through the bridge).
- "Connect your brain" first-run screen (URL + publishable key + sign-in, optional QR from the desktop), the
  migration packaged for `brain-setup`, module registry with Meeting of the Minds stubs behind flags, Play
  internal-testing track prepared (no purchase without asking).
- **done_when:** manual + shell — the same APK connects to `mom-buyer-test` (restored, provisioned with the
  packaged migration) with a config-only change (`git diff` of the build shows no code change); verifier — the
  boundary lint (no import from `modules/community` into `modules/my-mom` or vice-versa) passes in CI.

### Not in this plan (deliberately)
Meeting of the Minds features, Jobs, Marketplace, Discovery, Profile/Reputation, MOM Verified, licensing UI,
push notifications, iOS. Each gets its own goal when its turn comes; the module registry and the second
client slot are the only things built for them now.

---

## 5. Decisions for Dustan (answer by number; "yes" = do it as recommended)

1. **Reference design = v3.4 staged file** (recommended). Alternative: whatever is live (possibly the v2.9 body).
2. **New private repo `mom-app`** for the app (recommended). Alternative: a folder inside `mindsovermatters-co`
   (the landing-page repo with the CNAME) — workable but mixes a Pages site with an Android project.
3. **Capacitor WebView shell reusing the dashboard code** (recommended). Alternative: native Kotlin rewrite.
4. **MOM Brain API v1 = `authenticated` read policies + seven write RPCs + pick-up lease RPCs** (recommended).
   Alternative: wide table policies and direct PostgREST writes.
5. **Supabase Auth email + password, one user, sign-ups disabled** (recommended). Alternative: magic link (needs
   SMTP, pending elsewhere) or keep no auth (rejected: the publishable key alone would expose the brain).
6. **Pick up on the phone writes a lease** (`lease_owner`, `lease_expires_at`) (recommended). Alternative: no
   write, desktop parity only (then "Supabase updates" in the loop is false).
7. **GitHub Actions builds the signed APK; sideload first, Play later** (recommended).
8. **Phase 1 refresh = foreground + pull-to-refresh; Realtime in Phase 2** (recommended). Alternative: Realtime
   from day one.
9. **Fork the desktop file now, converge into `mom-core` in Phase 3** (recommended). Alternative: refactor the
   desktop first (touches the live dashboard before the phone exists).
10. **Open Claude = clipboard always + `https://claude.ai/new?q=` intent** (recommended); verified on the device
    in Phase 1.

If you say yes to 1–10, the next action is Phase 0 in a fresh chat with this document as the kickoff.

---

## 6. Risks and unknowns, stated plainly

- **Live file state** (D1). The last recorded observation says v2.9 body; this plan assumes v3.4.
- **Claude Android app and `?q=` links**: unverified; clipboard is the guaranteed path.
- **Realtime on the free tier** and the project's 7-day pause rule: the brain project is used daily and has a
  keepalive function, so low risk; `mom-buyer-test` must be restored for the Phase 3 test (two active projects
  max, `pearls-library` is the other).
- **WebView drag/gesture code**: the desktop's pointer-drag reorder is replaced by buttons; the v3.4 patch
  notes already record pointer-capture edge cases.
- **Guarded probes**: the Dreams tab probes its tables with `to_regclass()` before querying (a missing table once
  took the whole board down for weeks, [29]); the phone keeps the same guard so a brain without Dream Mode still
  renders every other tab.
- **One-writer rule**: the phone is a second concurrent writer, like the desktop already is (memo 311 records
  the dashboard writing mid-session). RPCs stamp `agent='mobile'` so `/close` and `reconcile` can see them.
- **Estimates** are session counts, not hours; they assume the API lands without a second migration round.

---

## Appendix A — Dashboard inventory (per-function reuse list)

*(filled from the independent inventory pass; see `INVENTORY.md` in the PR when attached)*

## Appendix B — Buyer-edition access model (brain-setup)

Extracted by an independent pass over the shipped `brain-setup/SKILL.md` (every claim cited by line in
`evidence/ACCESS-MODEL.md`). Corrections to the brief that commissioned it: 20 real `CREATE POLICY` statements
(not 24) and 19 executable `GRANT`/`REVOKE` statements (not 72); the larger numbers were grep hits on prose.

**Tables provisioned (20):** 18 unconditional — sessions, deploy_memory, system_cache, spinoffs, loops,
skill_registry, domains, active_sessions, run_plans, pending_confirmations, policies, scripts, model_routing,
system_locks, policy_proposals, system_flags, skill_catalog, brain_meta — plus brain_edges and dream_proposals
when Dream Mode is switched on; `spinoffs_numbered` is a security-invoker view (the `row_number()` badge).

**The anon ceiling (what the buyer dashboard may do with the publishable key):**

| Table | anon may read | anon may write (column-level) |
|---|---|---|
| deploy_memory | yes | INSERT goal_id, agent, key, status, domain, value; UPDATE status |
| loops | yes | UPDATE status, is_active |
| spinoffs | yes | UPDATE status |
| skill_registry | yes | UPDATE install_confirmed, installed_at |
| pending_confirmations | yes | UPDATE status, confirmed_at |
| system_flags | yes | UPDATE value (row-scoped to `system_paused`) |
| domains, system_cache (5 keys), skill_catalog | yes | nothing |
| sessions, active_sessions, run_plans, policies, scripts, model_routing, brain_meta, system_locks, policy_proposals, brain_edges, dream_proposals | no | nothing |

No DELETE, TRUNCATE, TRIGGER or REFERENCES for anon anywhere. `done_when`, `done_when_kind`, `run_done_when`,
`run_done_when_kind` are outside every grant because the shipped reality-check executes them as SQL or shell.
Sequences are revoked from anon; trigger and lane functions are revoked from PUBLIC/anon/authenticated.

**Identity:** none. Eleven of the sixteen anon policies are bare `USING (true)`; the key is static in the HTML;
there is no per-user or per-device scoping. That is exactly the gap the phone plan closes with Supabase Auth and
`authenticated`-only access (§2.2–2.3), and it is why the personal build must never fall back to "anon + wide
policies".

**Contrast with Dustan's live brain (§1.3):** his brain has only the four anon policies (goal_meta read,
capture insert, domains, system_flags); the buyer ceiling above is *wider* than his own anon surface. The MOM
Brain API proposed here is designed so the same migration can be packaged into `brain-setup` later, giving
buyer brains and Dustan's brain one identical, versioned contract for any client.

**Seen along the way (not this plan's scope):** the verifier notes that `verify-license.cjs` carries a header
saying it is staged for v4.1 and must not enter the sealed v4.0 bundle, while the paired `SKILL.md` presents the
same check as a live v4.0 Step 0 — worth a look by whoever owns the product cut.
