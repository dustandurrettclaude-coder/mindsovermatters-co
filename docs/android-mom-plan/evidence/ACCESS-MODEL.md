# Minds Over Matters — Database Access Model (as provisioned by brain-setup)

Source files (line numbers below refer to these, by filename):
- `SKILL.md` — `/tmp/claude-0/-home-user-mindsovermatters-co/5d11479c-c65e-5dec-a00b-17eb9b1a8f35/scratchpad/brain-setup/brain-setup/SKILL.md` (3434 lines)
- `verify-license.cjs` — `/tmp/claude-0/-home-user-mindsovermatters-co/5d11479c-c65e-5dec-a00b-17eb9b1a8f35/scratchpad/brain-setup/brain-setup/verify-license.cjs` (131 lines)

`dashboard-template.html` itself is **not** among the files I was given, and is not present in the skill folder — `SKILL.md:3395` says it "sits at the top of the unzipped Minds Over Matters download... NOT inside the installed skill." Everything below about what the dashboard does is drawn from `SKILL.md`'s own commentary about that file, not from reading its code.

Two counts in the task brief do not match the file and are corrected below with evidence: **20** real `CREATE POLICY` statements exist, not 24 (§3), and a two-digit number of real `GRANT`/`REVOKE` statements exists (19, listed in full), not 72 (§4).

---

## 1. TENANCY MODEL

**Each buyer provisions and owns a separate Supabase project; there is no shared multi-tenant backend in this file.** Phase 1a (`SKILL.md:48-71`) has each buyer bring or create *their own* free Supabase account and project ("You need a free account", `:46`); Phase 1c extracts that buyer's own `PROJECT_URL` / `PROJECT_ID` / `ANON_KEY` (`:91-104`); Phase 5 states "The Supabase project ID must be included — all skills use it as the single source of truth for which database to connect to" (`:3430`), and the About-Me template stores it as "single source of truth for goals, sessions, loops" (`:3322`). Nothing in the file describes one Supabase project serving more than one buyer.

**"DEDICATED projects only" (`SKILL.md:2817`) is a narrower flag, not the buyer-tenancy question.** It refers to a *second* question asked back in Phase 1a, after the buyer already has their own project:

> `:65` `AskUserQuestion: "Will this Supabase project be used ONLY for Minds Over Matters?"`
> `:71` `Record the answer as DEDICATED (yes / no / not sure). Only **yes** unlocks step 1e...`

I.e. it asks whether *that one buyer's own project* is used exclusively for this product or is shared with other apps the same buyer separately runs in it. Section 1e's heading (`:2817`) restricts the optional RLS-auto-enable event trigger to DEDICATED=yes projects because that trigger changes *every future table Postgres sees in `public`* — "by any skill, and by any other app" (`:2819`) — which would overreach into a shared project. It has nothing to do with isolating one buyer from another.

**Supabase Auth (`auth.users`, `auth.uid()`) is not used anywhere.** A search of the whole file for `auth.users`, `auth.uid`, and "Supabase Auth" returns zero hits. All 20 `CREATE POLICY` statements target `TO anon` or `TO service_role` only — never `TO authenticated`, and never reference an auth schema. The file says this is deliberate and not-yet-done, not accidental:

> `:1674-1676` "`authenticated` and PUBLIC hold nothing on any of the eighteen -- the dashboard always runs as anon; if you add Supabase sign-in, mirror these anon grants to authenticated and widen each policy to `TO anon, authenticated`."

So as shipped, every row any policy exposes is exposed to *anyone holding the one static anon key*, with no per-user identity layer at all.

**How `dashboard-template.html` reaches the database**, per the requested line ranges:

- **`:1556-1558`** (header comment for the whole RLS/policy block): "WHAT THE BOARD ACTUALLY NEEDS, measured from dashboard-template.html rather than from prose: reads inside `Promise.all` WITHOUT a `.catch()` are HARD-fail — the whole board renders nothing and shows 'Brain unreachable'. Reads WITH `.catch(()=>[])` fail SOFT..." → the dashboard's reads are described as JavaScript `Promise.all(...)` calls made from the page itself.

- **`:1757-1759`**: "the writes are dashboard-template.html's `setGoal`, `activateLoop` / `setLoop`, `setSpin`, and `confirmDone`, and the capture POST in `capture()` (cited by function: line numbers move). The v4.0 dashboard has NO function that writes `system_flags`; that grant below is reserved for a later version." → writes are an HTTP POST (`capture()`) for inserts and (per `:1746-1749`) PATCH-style updates for everything else.

- **`:2065-2068`** (verification-probe comment, READS section): "What dashboard-template.html reads. `deploy_memory` and `domains` are its HARD-fail reads (the whole board shows 'Brain unreachable'); the rest fail SOFT (an empty tab, which a user reads as lost data). An absent relation is not a broken read..." — restates the same Promise.all/catch behavior as something the probe actually exercises.

- **`:2105-2106`** (verification-probe comment, WRITES section): "Exactly what dashboard-template.html sends, column for column. The capture POST carries `agent:'desktop'` — the INSERT policy's WITH CHECK requires it." — confirms the capture insert is a literal POST body containing `agent:'desktop'`.

- **Phase 3, `:3390-3403`**: the dashboard is a static HTML file the buyer opens locally. Step 2 (`:3396-3398`) substitutes exactly two placeholders — `{{SUPABASE_URL}}` → `PROJECT_URL`, `{{SUPABASE_ANON_KEY}}` → the *publishable* anon key — directly into that file. The key is called "fine to embed in this dashboard file" but explicitly "not read-only" (`:3398`), and the buyer is told to "Keep the dashboard file on your own machine — do not host it at a public URL" (`:3398`).

**None of the terms "PostgREST", "supabase-js", "createClient", "MCP bridge", "fetch(", or "rest/v1" appear anywhere in `SKILL.md`** (all zero hits by direct search). So the file never names the transport library or protocol. What it does establish: the anon key is embedded straight into the static HTML (not proxied through Claude), and the dashboard's reads/writes are browser-side `Promise.all` GETs, a `capture()` POST, and PATCH-style updates, gated only by RLS + the grants in §3/§4 below — consistent with a direct client-side call to Supabase's REST endpoint using the anon key, but I cannot confirm "PostgREST" or "supabase-js" specifically because the file never says so.

**The "connector" is a completely separate, more privileged path, used by Claude — not the dashboard.** `SKILL.md:75` defines it: "A **connector** (also called MCP) is how Claude talks directly to your Supabase database — instead of you copy-pasting things back and forth, Claude reads and writes it for you." It is invoked via tool calls (`execute_sql`, `get_project_url`, `get_publishable_keys`, `list_projects`, `:81-104`) and runs as "the connector's privileged role, which neither the REVOKE nor RLS restricts" (`:1824`). Tables the anon key can never reach (`system_locks`, `policy_proposals`) are explicitly reached only this way: "Claude reaches them through the connector" (`:1625-1626`).

---

## 2. TABLES PROVISIONED

20 `CREATE TABLE IF NOT EXISTS` statements total. 18 are unconditional (Phase 1d's main SQL block); 2 (`brain_edges`, `dream_proposals`) exist only if the buyer opts into the optional Dream Mode block, Step 1f (`SKILL.md:2916`, off by default: "Offer it; do not switch it on by default", `:2920`). The file itself repeatedly refers to the unconditional 18 as "the eighteen tables" (e.g. `:1678`, `:1938`, `:2014`, `:2039`, `:2505`, `:2693`, `:2777`, `:2791`) and sums the base install as "eighteen tables, one view, six functions, seven triggers" (`:2039-2040`).

| # | Table | Line | Purpose (one line) |
|---|---|---|---|
| 1 | `sessions` | 423 | One row per Claude session (start/close time, skills used, projects, scope, wrap/force-closed flags). |
| 2 | `deploy_memory` | 437 | The goal/task inbox — the "capture box"; keyed rows (`goal_meta`, etc.) with status, domain, and the `done_when`/`done_when_kind` evidence-check + multi-user lease columns. |
| 3 | `system_cache` | 472 | Small key→JSONB cache (session id, health/aggregate keys, the stored `license_key`, Dream Mode status). |
| 4 | `spinoffs` | 479 | "Saved for later" / spun-off items; 8-state status lifecycle plus the same `done_when`/lease columns as `deploy_memory`. |
| 5 | `loops` | 501 | Saved workflows — "determinate" recipes vs "indeterminate" cadences — with `is_active`/`status`, `done_when`/`done_when_kind`, and a copy for the next minted run (`run_done_when`/`run_done_when_kind`). |
| 6 | `skill_registry` | 646 | Tracks which skills are installed/confirmed and their `installed_version`. |
| 7 | `domains` | 656 | Small public lookup for the dashboard's tab/category list (label, sort order, active flag). |
| 8 | `active_sessions` | 664 | Which domains/task/locks a given session currently holds. |
| 9 | `run_plans` | 673 | Grouped task plans (label, `tasks` JSONB, status). |
| 10 | `pending_confirmations` | 683 | Actions awaiting the user's yes/no (e.g. skill installs); `confirmed_by` is "evidence trail for multi-user closure" (comment at 693). |
| 11 | `policies` | 699 | Operational "always/never" safety-rule text; seeded with starter rows, zero rows is a valid state (comment at 697-698). |
| 12 | `scripts` | 710 | Stored script content with version/`previous_content`. |
| 13 | `model_routing` | 719 | Maps `task_type` → model/`agent_type`/`tier`, plus running token averages. |
| 14 | `system_locks` | 762 | Single-writer lock row (`lock_name`/`holder`/`taken_at`) used by `claim_system_lane`/`release_system_lane`. |
| 15 | `policy_proposals` | 771 | Lessons-learned's proposed rules awaiting promotion into `policies`; comment at 770: "No anon privilege at all." |
| 16 | `system_flags` | 787 | One reserved `system_paused` flag; comment at 784: "NOTHING in v4.0 reads it." |
| 17 | `skill_catalog` | 797 | Plain-English descriptions of shipped skills, for the dashboard's Skills tab; read-only to anon. |
| 18 | `brain_meta` | 1106 | Singleton row (`id=1`): `loops_count`, `spinoffs_count`, `last_write`, `failed_writes`, `cache_bust`. |
| 19 | `brain_edges` | 2962 | *(optional, Dream Mode)* Relationship graph between rows (`spawned`/`cites`/`supersedes`/etc.). |
| 20 | `dream_proposals` | 2986 | *(optional, Dream Mode)* Proposed cleanups (`promote`/`update`/`delete`/`resolve`/`edge`/`feature`) awaiting human accept/reject; comment at 2984: "NEVER give the anon key a policy on this table." |

A 21st relation, `public.spinoffs_numbered`, is a **view** (`CREATE OR REPLACE VIEW ... WITH (security_invoker = true)`, `:966`/`:993`), not a table — a `row_number()` badge over `spinoffs`, filtered to `status IN ('draft','ready','active','merge_pending','parked')`. It is conditionally `GRANT SELECT`-ed to anon (§4) and is not part of the "20 tables" count.

---

## 3. RLS POLICIES

**20 real `CREATE POLICY` statements exist, not 24.** A plain `grep -n "CREATE POLICY"` returns 24 hits, but 4 of them (`:417`, `:825`, `:1540`, `:1553`) are prose/comment sentences and one `RAISE EXCEPTION` message string that merely *mention* the phrase "CREATE POLICY" while explaining the design — they create nothing. The 20 below (`grep -n "^CREATE POLICY"`, confirmed against a matching count of 20 `DROP POLICY IF EXISTS` lines immediately preceding each) are the actual statements.

| # | Line(s) | Policy | Table | Role | Command | USING / WITH CHECK |
|---|---|---|---|---|---|---|
| 1 | 1567-1568 | `anon_read_goal_meta` | deploy_memory | anon | SELECT | `USING (key = 'goal_meta')` |
| 2 | 1570-1571 | `anon_capture_queued` | deploy_memory | anon | INSERT | `WITH CHECK (key = 'goal_meta' AND status = 'queued-unreviewed' AND agent = 'desktop')` |
| 3 | 1573-1574 | `anon_update_goal_meta` | deploy_memory | anon | UPDATE | `USING (key = 'goal_meta') WITH CHECK (key = 'goal_meta')` |
| 4 | 1578-1579 | `anon_read_domains` | domains | anon | SELECT | `USING (true)` |
| 5 | 1588-1589 | `anon_read_health_keys` | system_cache | anon | SELECT | `USING (key IN ('brain_meta','current_session_id','schema_features','dream_readiness','dream_last_run'))` |
| 6 | 1594 | `anon_read_loops` | loops | anon | SELECT | `USING (true)` |
| 7 | 1596 | `anon_update_loops` | loops | anon | UPDATE | `USING (true) WITH CHECK (true)` |
| 8 | 1599 | `anon_read_spinoffs` | spinoffs | anon | SELECT | `USING (true)` |
| 9 | 1601 | `anon_update_spinoffs` | spinoffs | anon | UPDATE | `USING (true) WITH CHECK (true)` |
| 10 | 1604 | `anon_read_skill_registry` | skill_registry | anon | SELECT | `USING (true)` |
| 11 | 1606 | `anon_update_skill_registry` | skill_registry | anon | UPDATE | `USING (true) WITH CHECK (true)` |
| 12 | 1609 | `anon_read_pending` | pending_confirmations | anon | SELECT | `USING (true)` |
| 13 | 1611 | `anon_update_pending` | pending_confirmations | anon | UPDATE | `USING (true) WITH CHECK (true)` |
| 14 | 1616 | `anon_read_flags` | system_flags | anon | SELECT | `USING (true)` |
| 15 | 1618-1619 | `anon_update_pause_flag` | system_flags | anon | UPDATE | `USING (flag = 'system_paused') WITH CHECK (flag = 'system_paused')` |
| 16 | 1623 | `anon_read_skill_catalog` | skill_catalog | anon | SELECT | `USING (true)` |
| 17 | 1628 | `service_role_only` | system_locks | service_role | ALL | `USING (true) WITH CHECK (true)` |
| 18 | 1630 | `service_role_only` | policy_proposals | service_role | ALL | `USING (true) WITH CHECK (true)` |
| 19 | 3027 | `service_role_only` | brain_edges | service_role | ALL | `USING (true) WITH CHECK (true)` |
| 20 | 3029 | `service_role_only` | dream_proposals | service_role | ALL | `USING (true) WITH CHECK (true)` |

Notes straight from the file:
- 11 of the 16 anon policies (#4,6,7,8,9,10,11,12,13,14,16) are bare `USING (true)` — every row, no per-row scoping at all beyond the column ceiling (§4). Only 5 (#1,2,3,5,15) scope by a specific key/status/flag value.
- **9 tables get no anon policy at all**: `:1819` — "The nine tables with NO anon policy above are intentional: the dashboard never touches sessions, active_sessions, run_plans, policies, scripts, model_routing, brain_meta, system_locks or policy_proposals." RLS is still enabled on them (§4), so with zero policies they deny-all to every non-owner role.
- The four `service_role_only` policies are, by the file's own description, not functional access control so much as "house style (service_role bypasses RLS anyway)" (`:1626`) — service_role bypasses RLS regardless of any policy.
- Order is load-bearing: `:1547` "⚠ ORDER IS LOAD-BEARING — EVERY POLICY IS CREATED BEFORE ANY TABLE IS ENABLED," and `:1553` "CREATE POLICY has no IF NOT EXISTS, so each is DROP-then-CREATE."

---

## 4. GRANTS

**19 real, executable `GRANT`/`REVOKE` statements exist, not 72.** `grep -n "GRANT \|REVOKE "` returns 81 lines, but the large majority are comments explaining the design or string literals inside `RAISE EXCEPTION`/`WARNING`/`NOTICE` messages (e.g. `:352-372`, `:417`, `:1794`, `:1808-1811`, `:1857-1931`, `:2011-2019`) that describe a GRANT/REVOKE in prose without executing one. I could not find anything resembling 72 real statements anywhere in the file. The real ones:

| Line(s) | Statement (summarized) |
|---|---|
| 1379-1382 | `REVOKE ALL ON FUNCTION` `claim_system_lane`, `release_system_lane`, `brain_touch_updated_at`, `trigger_spinoff_merge_pending`, `spinoffs_stamp_merge_pending`, `deploy_memory_domain_guard` `FROM PUBLIC, anon, authenticated` |
| 1383-1384 | `GRANT EXECUTE ON FUNCTION claim_system_lane, release_system_lane TO service_role` (the other 4 functions get no EXECUTE grant to anyone — comment at 1377-1378: a trigger function fires without one) |
| 1736-1741 | `REVOKE ALL ON` (all 18 core tables) `FROM anon, authenticated, PUBLIC` |
| 1742-1744 | `GRANT SELECT ON` (9 tables: deploy_memory, domains, system_cache, loops, spinoffs, skill_registry, pending_confirmations, system_flags, skill_catalog) `TO anon` |
| 1748 | `GRANT INSERT (goal_id, agent, key, status, domain, value) ON deploy_memory TO anon` |
| 1749 | `GRANT UPDATE (status) ON deploy_memory TO anon` |
| 1762 | `GRANT UPDATE (status, is_active) ON loops TO anon` |
| 1763 | `GRANT UPDATE (status) ON spinoffs TO anon` |
| 1764 | `GRANT UPDATE (install_confirmed, installed_at) ON skill_registry TO anon` |
| 1765 | `GRANT UPDATE (status, confirmed_at) ON pending_confirmations TO anon` |
| 1767 | `GRANT UPDATE (value) ON system_flags TO anon` |
| 1799 | (inside a `DO` block, dynamic) `EXECUTE format('REVOKE ALL ON SEQUENCE %s FROM anon, authenticated, PUBLIC', s)` looped over the 4 sequences owned by `deploy_memory.id`, `pending_confirmations.id`, `policies.id`, `policy_proposals.id` (`:1780-1784`) |
| 1865 | `REVOKE ALL ON spinoffs_numbered FROM anon, authenticated, PUBLIC` (inside a conditional `DO` block) |
| 1003 / 1923 | `GRANT SELECT ON spinoffs_numbered TO anon` — written twice, once per code branch (pre-PG15 fallback vs. PG15+ hardened path); only one branch executes per install |
| 2878 | `REVOKE ALL ON FUNCTION mom_rls_auto_enable() FROM PUBLIC, anon, authenticated` (optional Step 1e) |
| 3023 | `REVOKE ALL ON brain_edges, dream_proposals FROM anon, authenticated, PUBLIC` (optional Dream Mode) |
| 3282 | `REVOKE ALL ON FUNCTION dream_m(text), dream_readiness() FROM PUBLIC, anon, authenticated` (Dream Mode) |
| 3283 | `GRANT EXECUTE ON FUNCTION dream_m(text), dream_readiness() TO service_role` (Dream Mode) |

### The column ceiling (anon: table-level vs. column-level)

The file's own summary (`:1662-1673`): after section 1b, anon holds exactly —
- **SELECT** on the 9 tables the board reads;
- **INSERT** on `deploy_memory` only, on 6 named columns;
- **UPDATE**, column-level, on the 6 tables the board PATCHes;
- **nothing** on the other 9 of the 18 core tables (sessions, active_sessions, run_plans, policies, scripts, model_routing, brain_meta, system_locks, policy_proposals) — and nothing at all on the 2 Dream Mode tables (`:2928`: "The anon key reaches NONE of it: no grant, no policy, RLS on.").

Split precisely, of the 18 core tables:
- **3 read-only, table-level SELECT, no write grant at all**: `domains`, `system_cache` (rows scoped by policy to 5 keys, not by column), `skill_catalog`.
- **6 read + column-level write ("the column ceiling")**: `deploy_memory`, `loops`, `spinoffs`, `skill_registry`, `pending_confirmations`, `system_flags`.
- **9 zero-privilege**: sessions, active_sessions, run_plans, policies, scripts, model_routing, brain_meta, system_locks, policy_proposals.
- **No DELETE, TRUNCATE, TRIGGER, or REFERENCES for anon anywhere** (`:1714`: "No DELETE, TRUNCATE, TRIGGER or REFERENCES for anon anywhere, and no write at all outside the six tables named.").

### Exact anon-writable surface (the "fifteen column grants")

`:2336-2338` states the file's own count: "This edition grants fifteen column-level privileges, on six tables." Enumerated at `:2365-2376` (`expected_col`) and matching the GRANT lines above:

| Table | Verb | Columns anon may write | Count |
|---|---|---|---|
| `deploy_memory` | INSERT | `goal_id, agent, key, status, domain, value` | 6 |
| `deploy_memory` | UPDATE | `status` | 1 |
| `loops` | UPDATE | `status, is_active` | 2 |
| `spinoffs` | UPDATE | `status` | 1 |
| `skill_registry` | UPDATE | `install_confirmed, installed_at` | 2 |
| `pending_confirmations` | UPDATE | `status, confirmed_at` | 2 |
| `system_flags` | UPDATE | `value` (row-scoped by policy #15 to `flag='system_paused'`) | 1 |

Total = 15, matching the file's own count exactly.

**Explicitly and by design NOT anon-writable** (named at `:1700-1704` and reasserted in the `column_ceiling_open` check at `:2777`): `deploy_memory.done_when`, `deploy_memory.done_when_kind`, `spinoffs.done_when`, `spinoffs.done_when_kind`, `loops.done_when`, `loops.done_when_kind`, `loops.run_done_when`, `loops.run_done_when_kind` — "unreachable to anon BY PRIVILEGE, not merely by policy" (`:1702`), because reality-check later *executes* those columns as SQL or a shell command (§7).

---

## 5. WRITES THE BUYER DASHBOARD MAKES

The provisioner's own citation, verbatim (`:1750-1759`):

> "Each list below is exactly the body the dashboard PATCHes to that table -- nothing was guessed; the writes are dashboard-template.html's **setGoal**, **activateLoop / setLoop**, **setSpin**, and **confirmDone**, and the capture POST in **capture()** (cited by function: line numbers move). The v4.0 dashboard has NO function that writes `system_flags`; that grant below is reserved for a later version."

What's independently confirmed elsewhere in the file:
- **`capture()`** → the capture POST → `INSERT (goal_id, agent, key, status, domain, value) ON deploy_memory` (`:1745-1748`); the INSERT policy's `WITH CHECK` requires `key='goal_meta' AND status='queued-unreviewed' AND agent='desktop'` (`:1570-1571`), and the verification probe literally sends `agent:'desktop'` in that INSERT (`:2138-2139`, `:2105-2106`).
- The only other PATCH on `deploy_memory` is `UPDATE (status)` — `:1746-1747`: "UPDATE is status alone, which is the only column the board PATCHes there."
- Beyond that, the file names the five functions as a group and then lists four more table-level column grants (`loops`, `spinoffs`, `skill_registry`, `pending_confirmations`) — it does **not** give an explicit one-to-one mapping of which named function writes which table. By naming (not asserted by the file, offered here only as the most literal reading): `setGoal` ↔ `deploy_memory` status; `activateLoop`/`setLoop` ↔ `loops` (`status, is_active`); `setSpin` ↔ `spinoffs` (`status`); `confirmDone` ↔ `pending_confirmations` (`status, confirmed_at`).
- **Gap in the file, stated as a fact, not an inference**: `skill_registry`'s grant — `UPDATE (install_confirmed, installed_at)` (`:1764`) — has **no named function anywhere in this passage**; none of `setGoal`/`activateLoop`/`setLoop`/`setSpin`/`confirmDone` obviously corresponds to it, and the text does not say what dashboard code performs it.
- **`system_flags`'s grant has no writing function at all yet**, per the file's own words (`:1758-1759` above) — the grant exists ("reserved") ahead of any dashboard feature that uses it.

The verification probe (`:2113-2178`) independently exercises the same six write bodies as literal SQL run under `SET LOCAL ROLE anon`, confirming column-for-column: the capture INSERT (`:2138-2139`), `deploy_memory` status UPDATE (`:2142`), `loops` status/`is_active` UPDATE (`:2145`), `spinoffs` status UPDATE (`:2148`), `pending_confirmations` status/`confirmed_at` UPDATE (`:2151`), `skill_registry` `install_confirmed`/`installed_at` UPDATE (`:2154`), and the reserved `system_flags` value UPDATE (`:2157`).

---

## 6. LICENSE

**Step 0 (`SKILL.md:21-42`)** — runs before Phase 1, "needs no internet" (`:23`):
- Key format: `MOM365-…-…`, "emailed to you within one business day of purchase" (`:25`).
- Run via `node verify-license.cjs YOUR-KEY-HERE` (`:29`); "Nothing is sent anywhere — the check is fully offline against a public key baked into the file" (`:32`).
- Exit-code branching (`:34-38`): **0 VALID** → continue; **1 INVALID** → stop, re-paste or contact the seller; **2 EXPIRED** → soft gate: "Setup, re-installs and updates stop here — but **everything you already installed keeps working**" (`:37`), renew on Gumroad; **3 BUILD ERROR** → "the download is faulty (no key was embedded). Not your fault" (`:38`).
- "This check runs only at setup, re-install, and update time — never while you work." (`:40`).
- **Where the key is stored — table 1d-LICENSE (`:2805-2814`)**: after Phase 1d has created `system_cache`, the *entire verified key string* (not just a pass/fail flag) is written with one upsert:
  ```sql
  INSERT INTO public.system_cache (key, value, updated_at)
  VALUES ('license_key', to_jsonb('MOM365-…-…'::text), now())
  ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = now();
  ```
  A re-install/update reads it back with `SELECT value #>> '{}' FROM public.system_cache WHERE key='license_key'` and re-runs Step 0 against that instead of re-prompting (`:2815`). Note: the anon key **cannot** read this row back — `system_cache`'s only anon SELECT policy is scoped to 5 named keys (`:1588-1589`) and `license_key` is not one of them; only the connector/SQL-Editor path (`:2815`) can retrieve it.

**Not tied to a machine.** `verify-license.cjs:10` states the check is "no network call, no activation server, no device count," and `SKILL.md:35` confirms: "the same key re-verifies anywhere, any number of times, on any machine."

**Tied to a person only nominally, and not checked as such.** `verify-license.cjs:104-109` requires the signed payload to contain `email_hash` matching `^[0-9a-f]{64}$` (a SHA-256-shaped hex string) alongside `sku`, `issued`, `term_days`, `seq` — but the script **never asks the person running it for an email address and never compares the hash to anything**; it only checks the field is present and well-formed. As far as this file is concerned, `email_hash` is inert data baked into the key at issuance (presumably by the seller's backend, which is not among the files given to me), not something verify-license.cjs itself enforces.

**Cryptographic mechanism** (`verify-license.cjs`): the key's 2nd and 3rd dash-separated segments are base32-decoded (`:29-50`, using a canonical-form decoder that rejects non-canonical padding — the comment at `:44-46` notes this closes an alias-spelling bypass a "verifier finding" caught) into a JSON payload and an Ed25519 signature, verified with `crypto.verify(null, payloadBuf, publicKey, sigBuf)` (`:94`) against an embedded SPKI public key (`:27`). Expiry is `issued + term_days` in UTC calendar days (`:111-126`).

**A discrepancy the two files themselves expose, worth flagging directly**: `verify-license.cjs:4-6` opens with "MOM365 license verify step — **STAGED FOR v4.1 ONLY**... **NEVER add this to the sealed v4.0 bundle** (Minds Over Matters/_bundle-source-v4.0/) — see VERIFY-STEP-EDIT.md." But `SKILL.md` is itself full of `(v4.0)` version tags throughout (e.g. `:391`, `:439`, `:448`, `:520`, `:573`, `:590`, `:723`, `:1205`), and its Step 0 (`:21-23`) presents this exact license check as live, mandatory, first-run behavior — "Minds Over Matters is a 365-day license. Before setup runs, verify the key..." with no version gate at all. None of the terms in the .cjs header ("v4.1", "sealed", "_bundle-source", "VERIFY-STEP-EDIT", "SPEC-mom-365-licensing") appear anywhere in `SKILL.md`. So, read literally, the companion file's own comment says it should not yet be shipping next to a v4.0 `SKILL.md` that already treats it as required — but that is exactly the pairing found on disk in this skill folder.

---

## 7. SECURITY NOTES THE PROVISIONER ITSELF STATES

**Why `done_when` (and its siblings) is not anon-writable** (`:1637-1656`): reality-check later *executes* `done_when` — "as SQL when its kind is 'sql', as a shell command in your connected folder when it is 'shell'" — and does so from `/end-session --full` "without asking first, on goals and spinoffs alike" (`:1641-1643`). Therefore "a write to any of those columns is a write of code a later session of yours would run, and the column ceiling makes every one of them unreachable to the publishable key" (`:1644-1645`). The same applies to `loops.run_done_when`/`run_done_when_kind`, because they are "copied into a minted run-instance's `done_when`... executed text one hop removed" (`:520-522`). The protection is stated as two-part and interdependent: "this privilege ceiling, and reality-check's provenance rule (never auto-execute the `done_when` of a row whose `agent` is 'desktop')... The provenance rule holds only because the ceiling keeps anon from rewriting `agent`" (`:1646-1649`).

**The ceiling's one named blind spot** (`:1719-1727`): "a column privilege is checked against the columns a statement NAMES, not against what a BEFORE trigger then writes" — so a future trigger could write `done_when` from a column anon *can* write, bypassing the ceiling entirely. The file asserts its own 7 shipped triggers don't do this and that adding one "needs table ownership — not the anon key" (`:1725`), and the verification probe "names every non-internal trigger... and FAILS on any it does not expect" (`:1726-1727`).

**`rls_auto_enable`** (Step 1e, `:2817-2905`): an optional event trigger `mom_ensure_rls` fires on `ddl_command_end` for `CREATE TABLE`/`CREATE TABLE AS`/`SELECT INTO` in schema `public` (`:2864-2866`) and runs `ALTER TABLE IF EXISTS <new table> ENABLE ROW LEVEL SECURITY` (`:2869`) on every table created afterward, "by any skill, and by any other app" (`:2819`). It requires DEDICATED=yes *and* its own separate explicit yes (`:2821-2826`); "No answer, a dismissed question, 'not sure' or anything other than Yes = do NOT install" (`:2828`). Even when installed it is partial: "its default grants still stand, so TRUNCATE stays open on it until revoked" (`:2793`).

**`service_role` never appears in the dashboard** — not asserted as one sentence anywhere, but consistent throughout: Phase 3's only two substituted placeholders are `{{SUPABASE_URL}}` and `{{SUPABASE_ANON_KEY}}` (`:3396-3398`); every `service_role` reference in the file (`:1377-1384`, `:1626-1630`, `:3023-3029`, `:3282-3283`) is scoped to internal trigger-support functions or to `service_role_only` policies on tables the anon key cannot reach at all (`system_locks`, `policy_proposals`, `brain_edges`, `dream_proposals`), reached instead "through the connector" (`:1625-1626`, `:1824`) — Claude's privileged MCP path, never the dashboard's.

**The accepted residual trade, named explicitly, twice**: "Within those columns the key still writes what it likes -- it can park a goal, deactivate a workflow, flip the reserved `system_paused` flag..., or tick a pending row it did not complete. That is a data-integrity trade and it is unavoidable while the board writes at all" (`:1652-1655`, restated in near-identical words at `:1711-1713` and again at Phase 3 `:3398`).

**A concretely named historical vulnerability in an earlier build of this same product** (`:1539-1545`): "Before the 2026-09-03 build the script created 14 tables with zero ENABLE ROW LEVEL SECURITY, zero CREATE POLICY and zero REVOKE, while the Supabase default grants hand anon SELECT/INSERT/UPDATE/DELETE/TRUNCATE/TRIGGER/REFERENCES on every one of them... `TRUNCATE` as anon SUCCEEDED at the SQL level on all fourteen tables (measured by execution)."

**Explicit imperative on the Dream Mode proposals table** (`:2984`): "NEVER give the anon key a policy on this table: RLS restricts rows, not columns, and a proposal can quote memo text."

**The PREFLIGHT bystander/ownership guard** (`:113-421`) exists specifically so this script's own REVOKE/ENABLE-RLS/GRANT machinery can never be turned into an attack on a table it doesn't own: it refuses outright, before any CREATE, on any name collision it doesn't recognize as its own (`:128-136`), rather than silently adopting and re-securing a stranger's table.

---

## 8. WHAT A MOBILE CLIENT WOULD NEED THAT THIS MODEL LACKS

Stated as facts about the current grants/policies (§3-§4), not as recommendations:

1. **No per-user identity in the schema.** Zero use of `auth.uid()`/`auth.users` anywhere; 11 of the 16 anon policies are bare `USING (true)` and the other 5 scope by a fixed key/status/flag value, never by "who is asking" (§3). Fact: every holder of the one shared anon key sees and can update the identical set of rows — there is no per-family-member or per-device row separation inside one buyer's project, only the one-project-per-buyer boundary from §1.
2. **The credential is a static, embedded key, not a session token.** `:97` and `:3398` both describe the anon key as meant to be embedded in a client-side file, with the only stated mitigation being "don't host it publicly" — not encryption, rotation, or expiry. Fact: a mobile app built the same way inherits one non-revocable-per-install credential; the schema gives it no mechanism to scope or expire access per device.
3. **9 of the 18 core tables are completely unreachable to anon** — no SELECT, no write at all: `sessions`, `active_sessions`, `run_plans`, `policies`, `scripts`, `model_routing`, `brain_meta`, `system_locks`, `policy_proposals` (`:1736-1744`, `:1819`, `:2778`). Fact: a mobile client cannot show session history, run plans, live policies, model-routing config, or brain_meta counters using the anon key; that data exists only behind the privileged connector Claude itself uses (`:1824`).
4. **Correcting a premise worth flagging**: `pending_confirmations`, `spinoffs`, `loops`, and `system_cache` are *not* in that unreachable set — anon already holds SELECT on all four today (`pending_confirmations`: `:1609`; `spinoffs`: `:1599`; `loops`: `:1594`; `system_cache`: `:1588`, scoped to 5 keys). Fact: a mobile client using the same anon key could already read these exactly as the desktop dashboard does. The real gaps on these four are (a) the column ceiling on writes — `loops`/`spinoffs`/`pending_confirmations` may only UPDATE the specific columns in §4's table, never `done_when`/`done_when_kind`/`run_done_when`/`run_done_when_kind` (`:1637-1656`) — and (b) `system_cache` has no anon write grant or policy at all, so it is read-only to anon everywhere, including for a mobile client.
5. **No INSERT capability anywhere except `deploy_memory`'s 6 named columns** (`:1748`). Fact: a mobile client cannot create a new loop, spinoff, pending_confirmation, or domain row via the anon key — Phase 2's domain-seeding and Phase 4's goal-seeding are both done explicitly "via the connector" (`:3373`, `:3422`), never via the anon key, because no INSERT grant exists on those tables for anon.
6. **No DELETE/TRUNCATE for anon anywhere** (`:1714`). The existing UX is soft-delete only — `UPDATE ... SET status='deleted'` (`:642-643`: "The dashboard still never runs a hard DELETE (delete = soft, status='deleted', recoverable)"). Fact: a mobile client has no hard-delete path through the anon key and must follow the same soft-delete convention.
7. **The license key and brain metadata are not anon-readable.** `system_cache`'s anon SELECT policy names 5 specific keys (`:1588-1589`) and `license_key` is not among them; `brain_meta` and `sessions`/`active_sessions` have no anon privilege at all (§3/§4). Fact: a mobile client cannot read back license status or brain_meta counters via the anon key; the provisioner's own re-install flow reads `license_key` back only through the connector/SQL Editor (`:2815`).
8. **No Supabase-Auth session concept exists to extend.** Since `authenticated` currently holds nothing and no policy references it (`:1674-1676`), "add per-user login" is not a small config change on top of this schema — every one of the 16 anon policies and every column-level grant in §4 would need to be duplicated/widened by hand for `authenticated`, exactly as the file itself describes as a not-yet-done future step (`:1674-1676`).
