# Brain Dashboard v3.4 (staged): technical inventory for an Android port

**Source:** `scratchpad/dash/index-v3.4-staged.html`. It has 2,547 lines and is 197,735 bytes. The file was only read; nothing in it was changed.
**Method:** I read the file end to end. Every statement below cites line numbers in that file (`Lnnn`).
**Measured** marks the claims I checked by loading the unmodified file in headless Chromium 141 through Playwright, using:
- mobile emulation at 390×844 CSS px, DPR 3, touch enabled;
- a stubbed `window.cowork` that returned synthetic rows wrapped in the untrusted-data envelope.

The Google Fonts CSS did not load in that harness (`ERR_CERT_AUTHORITY_INVALID` from the sandbox proxy), so every measured width uses system fallback fonts. The harness lives in `scratchpad/inv-harness/` and is not part of the dashboard. Real devices, real data and real fonts will differ somewhat.

The older sibling `index-v3.3-live.html` was used for one comparison only: the set of `sql(` lines in v3.3 is identical to v3.4, which confirms v3.4's claim of "no new query, no new write" (L222).

---

## 0. Corrections to the brief: what the file actually contains

| Assumption (from the brief, or from the file's own docs) | What the code actually does |
|---|---|
| Quick capture INSERT uses `agent='desktop'` | It uses **`agent='dashboard'`** (L1819). Add goal (L1811) and the audit row (L1823) do the same. The string `desktop` appears **nowhere** in the file. |
| Goal edits use `jsonb_set` | **No executed `jsonb_set`.** The only occurrence is manifest comment [12] at L34. The page changes goals through column UPDATEs of `status` (L1805) and `domain` (L1806), plus a whole-`value` upsert in Add goal (L1811). |
| Skills reads `skills_registry` | It reads **`public.skill_catalog`** (L782). `skills_registry` appears only in comments (L69, L307, L309, L774). `skill_registry` (sic) appears once, inside a prompt string (L1472). |
| There are DELETE statements | **Zero `DELETE`.** Every "Delete" is a soft delete that sets `status='deleted'` (L1560, L1626, L1645→L1805). |
| localStorage / sessionStorage | **Only mentioned in comments** (L35, L111, L222, L683, L1661). No storage API, IndexedDB or cookie is ever executed. |
| Dreams has Accept/Keep/Defer buttons | That is stale text in the artifact meta description (L5). The code renders a single "Review this one" button per proposal that copies a line (L2014-L2021, manifest [41]). |
| "Reassign domain" is a working one-confirm write (manifest [6], L27) | **Measured broken.** `arm()` sets `textContent='confirm?'` on the `<select>` (L1800), which deletes all of its `<option>`s. The second change can therefore never happen. No SQL fires, and the select stays empty until the next re-render. See §4 W9. |
| Health row gets loops and merge-pending counts from brain_meta (manifest [15], L37) | The code takes only `last_write` and `failed_writes` from brain_meta (L821-L822). The loop and merge-pending counts are computed from the rows already loaded (L820, L825-L826). |
| Every write is behind the two-click confirm | **Quick capture has no confirm.** It writes on a single Enter or "Queue" click (L624, L626, L1814-L1822). `savePrefs` also writes without a confirm. The one exception there is "Reset tabs". |
| Pick up writes to the DB | **No DB write** (comment L1854). **Measured:** 0 SQL statements on either click. |
| Quick actions are "prompt-only" (artifact meta L5, ruling B-R4) | That holds only on **Home** (L2269-L2272) and in the **Jump palette** (L2466-L2467). The ⚡ buttons on **Goals domain boards** still call `window.cowork.runScheduledTask` for `kind='task'` (L1451 → L1835). |

---

## 1. FRAMEWORK & BUILD

**File anatomy**

| Lines | Content | Bytes |
|---|---|---|
| 1-13 | `<!DOCTYPE html>` followed by `<script type="application/json" id="cowork-artifact-meta">`. This block is not executed. It holds `name` "Brain Dashboard" (L3), `schemaVersion` 1, a long `description` (L5), `mcpTools: ["mcp__<mcp-tool-id>-…__execute_sql"]` (L7) and `mcpServerNames: ["Supabase"]` (L10). | 2,208 |
| 14-314 | An HTML comment containing the feature manifest [1]-[42] and the changelog. It is never rendered. | 29,925 |
| 315-320 | `<html><head>`: charset, `<meta name="viewport" content="width=device-width,initial-scale=1">` (L318), `<title>Minds Over Matters</title>` (L319), and the Google Fonts `<link>` (L320). | — |
| 321-618 | A single `<style>` block. | 26,438 |
| 619-680 | The static body shell: header, health strip, rail, tabs, domain nav, main, footer, toast, copy modal, hidden copy textarea, Customize drawer, More menu, Jump palette. | 4,878 |
| 681-2545 | A single classic inline `<script>`. It is not a module, and every function is global. | **133,899** (L682-L2544) |

- **Languages:** HTML, CSS and vanilla JavaScript. There is no framework and no TypeScript.
  - CSS uses custom properties, flex, grid, `:not()`, `display:contents` (L428) and `@media (prefers-color-scheme)`.
  - JS syntax that needs a modern Chromium: optional chaining `?.` (L734), nullish `??` (L1830), regex lookbehind `(?<!…)` (L1052), `\u{…}` code-point escapes (14 lines), async/await (21 `async` lines), spread, `Set`/`Map`, `Array.from`, `CSS.escape` (guarded, L2496), and `matchMedia(...).addEventListener('change')` (L988).
- **External resources:** exactly one. There is **no `<script src>`** anywhere. The one `<link>` is at L320:
  `https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700&family=IBM+Plex+Sans:wght@400;500;600&family=IBM+Plex+Mono:wght@400;500;600&display=swap`
  Drag-reorder is hand-written; the comment "pointer drag-reorder (no library)" is at L1301.
- **Build step:** none. The file is a self-contained single HTML page. Inline handlers depend on every function being global: the source contains 45 `onclick=`, 2 `onchange=`, 1 `oninput=` and 1 `onkeydown=`. The comments mention tests and files that live outside this file:
  - a `tests/` harness that extracts the block between `/* v3.4-goal-tabs:begin */` and `/* v3.4-goal-tabs:end */` (L1036-L1142) and runs it in node (L1037);
  - `tests/real_input_cdp.mjs` (L1175);
  - a "pglast test" (L218);
  - `MANIFEST.txt` (L243).
- **localStorage / sessionStorage:** only mentioned in comments (L35, L111, L222, L683, L1661), all of them saying *"NO localStorage"*. Nothing is executed; there is also no IndexedDB and no `document.cookie`.
  - All runtime state is held in in-memory globals: L684-L689 (`DOMAINS, GOALS, ACTIONS, SKILLS, PAUSED, TAB, MEMOS, ORPHANS, MAIN_TAB, LOOPS, SPINOFFS, BRAIN_META, CURRENT_SESSION, PICKED`), `SK_VIEW` (L1661), `DREAM` (L1909), `HOME` (L2225), `PAL_SEL` (L2444), `PREFS/PREFS_RAW/PREFS_LIVE` (L896-L898) and `_domClick` (L1199).
  - Persistent UI preferences go to the database row `public.system_cache` with key `dashboard_prefs` (§4 W1).
- **Inline JS size:** 133,899 bytes. CSS is 26,438 bytes. The comment header is 29,925 bytes, about 15% of the file.
- **Boot sequence** (`boot()` L2516-L2543, called at L2544):
  1. `applyAttrs()`.
  2. `await loadPrefs()`.
  3. `applyAttrs()` again, then `renderNav()`.
  4. Wire the drawer option buttons.
  5. Set up 4 `makeSortable` lists.
  6. Wire the palette and the global `keydown` handler.
  7. `loadAll()`.

  The boot tab is `'home'` (L687), so the first render also runs `loadHome()` (L2392). **Measured:** 13 queries at boot, made up of prefs, 9 queries in parallel, `system_flags`, the Home probe and the pending list. A 14th runs when `dream_proposals` exists.

---

## 2. DATA ACCESS LAYER

**Constants (L682).** The artifact meta declares the same tool (L7) and the server name `"Supabase"` (L10).
```js
const P='<brain-project-ref>', TOOL='mcp__<mcp-tool-id>__execute_sql';
```
**Transport, parser and error wrapper (L732-L748)**
```js
function q(s){ return window.cowork.callMcpTool(TOOL,{project_id:P,query:s}); }
function parse(r){
  let t = r.structuredContent?.result || (()=>{ try{return JSON.parse(r.content[0].text).result;}catch(e){return r.content[0].text;} })();
  const m = t.match(/<untrusted-data-[^>]*>\s*([\[{][\s\S]*?)\s*<\/untrusted-data-/); // [11]
  return JSON.parse(m ? m[1] : t);
}
// [24] Surface the REAL Postgres error text. The old version threw a bare
// 'query failed', which told us nothing when a CHECK constraint rejected a write.
async function sql(s){
  const r = await q(s);
  if(r.isError){
    let msg='query failed';
    try{ if(r.content && r.content[0] && r.content[0].text) msg = String(r.content[0].text); }catch(e){}
    throw new Error(msg.replace(/\s+/g,' ').slice(0,300));
  }
  return parse(r);
}
```
**Quoting, toast and write-failure hook (L755-L762)**
```js
function lit(s){ return (s==null?'':String(s)).replace(/'/g,"''"); }
function toast(m,bad){ const t=document.getElementById('toast'); t.textContent=m; t.classList.toggle('bad',!!bad); t.style.opacity=1; setTimeout(()=>t.style.opacity=0, bad?6000:2400); }
// [24] Any rejected write lands here instead of vanishing as an unobserved promise.
function wfail(e){
  const m = (e && e.message) ? e.message : String(e);
  toast('⚠ write REJECTED by the database — nothing was saved. ' + m, true);
  try{ console.error('[dashboard write failed]', e); }catch(_){}
}
```

**Bridge API used (`window.cowork.*`)**

| Call | Where | Purpose |
|---|---|---|
| `window.cowork.callMcpTool(TOOL, {project_id:P, query:s})` | L732 (`q()`) | **Every** read and write. |
| `window.cowork.sendPrompt(text)` | L1856 (`sendToChat`) | Chat hand-off. Falls back to a bare global `sendPrompt(text)` (L1857), then to the clipboard. |
| `window.cowork.runScheduledTask(a.ref)` | L1835 (`runQA`) | Runs task-kind quick actions from Goals domain boards only. |

A comment at L1895-L1902 says the page holds no Supabase anon or service key, and that reads run as DB role `postgres`. That is the file's own claim; this inventory did not verify it.

**How SQL is built.** SQL is built by string concatenation. Values are escaped only by `lit()`, which doubles single quotes. There is no parameter binding. Three places interpolate values without `lit()`:
- `setStatus` interpolates `status='${st}'` raw (L1805). Its callers pass constants.
- `togglePause` interpolates a JS boolean (L1884).
- `card()` puts the raw `goal_id` inside inline `onclick` JS strings (L1638-L1652). This is not SQL, but see §12.

**Result parsing (the untrusted-data wrapper).** `parse()` works in two steps:
1. It takes the payload from `r.structuredContent?.result`. Failing that, it uses `JSON.parse(r.content[0].text).result`. Failing that, it uses the raw `r.content[0].text`.
2. It looks for the first payload that starts with `[` or `{` inside `<untrusted-data-…> … </untrusted-data-`, using a lazy match (manifest [11], L33). If there is no wrapper, it JSON-parses the whole text.

Because the match is lazy, a stored string containing `</untrusted-data-` would cut the payload short. `domLabelClean()` therefore rewrites that sequence with a non-breaking hyphen (L1053), and `domKeyOk()` rejects keys that contain it (L1070). Some values can arrive either as a JSON object or as a string:
- `brain_meta` (L805) and `dashboard_prefs` (L931) are handled inline;
- dream receipts go through `jparse()` (L1913-L1917);
- `current_session_id` may be a scalar or `{value}` (L808).

**Cache-bust discipline**
- Each load prepends a nonce comment, `const cb='-- cb:'+Date.now()+'\n';`. This happens in `loadAll` (L769; all 10 reads, L771-L809), `loadPrefs` (L930), `loadDreams` (L1924) and `loadHome` (L2233). The file's stated reason is that "reads are cached by query text" (L768, manifest [20] L44-L45).
- **`drill()` (L1829) and all writes are sent without the nonce.**
- After every **data** write, the handler calls `loadAll()`: L1542, L1555, L1562, L1628, L1805, L1806, L1812, L1820. `loadAll` also re-runs `loadHome(true)` when Home has loaded (L812).
- `togglePause` does not reload; it only calls `renderChrome()` (L1884). `savePrefs` does not reload either.
- **No in-page control re-runs `loadAll()`.** The error text tells the user to "Hit Reload (top of panel)" (L814), which is a host control, not part of this file.

**Isolation.** `loadAll` runs a single `Promise.all` of 9 queries (L770-L801) and then `system_flags` (L809). If any one of them fails, the whole load fails. The Dreams and Home extras are deliberately kept out of it (L1925-L1928, L2215-L2218) and guarded with `to_regclass` probes.

**How errors surface**

| Path | Behaviour | Lines |
|---|---|---|
| `sql()` | Throws `Error` holding the first 300 characters of `r.content[0].text` (whitespace collapsed) when `r.isError`. A rejected `callMcpTool` promise or a `JSON.parse` failure propagates unchanged. | L742-L746 |
| `loadAll` | `#main` is replaced with *"Brain unreachable — {msg}. Hit Reload (top of panel)."* The header, health strip and nav keep their previous render. | L814 |
| `loadPrefs` | Toast: *"dashboard_prefs unreachable — using defaults; customization will not persist this session"*. Sets `PREFS_LIVE=false`, which turns `savePrefs` into a no-op. | L933-L937, L963 |
| armed writes | `arm()` runs `Promise.resolve(fn()).catch(wfail)` → red toast *"⚠ write REJECTED by the database — nothing was saved. {msg}"* for 6 s. | L1797, L760, L756 |
| `capture()` | Its own `try/catch` → `wfail`. | L1818-L1821 |
| `savePrefs` | `.catch(wfail)`. | L966 |
| `audit()` | **Errors are swallowed silently** (`catch(e){}`). | L1823 |
| `drill()` | Red error text inside the drill box. | L1831 |
| `runQA` (task) | Toast *"task launch failed"*. | L1835 |
| Dreams | Whole-load error: *"Dreams unreachable — {msg}. Retry"*. Per-query errors render inline. | L2205; L1947, L1953, L1958 |
| Home | Whole-load error: *"Home extras unreachable — {msg} Retry"*. Per-query errors render inline. | L2396; L2253, L2258 |
| Toast timing | 2.4 s normally, 6 s when marked bad. | L756 |

---

## 3. READ QUERIES

The page has **19 SELECT call sites** and no other reads. The SQL below is the exact text sent. **Measured:** it was captured from the bridge stub with the `-- cb:<ms>` nonce removed, and `<…>` marks a value the page interpolates. None of these queries has a `LIMIT` unless one is shown.

### 3a. Every query

**`loadAll()`.** R1-R9 run in one `Promise.all` (L770-L801). R10 runs after it. All ten carry the nonce.

- **R1 (L771) domains.** Fills `DOMAINS`.
  ```sql
  select domain,label,sort from public.domains where active order by sort;
  ```
- **R2 (L772) goals.** Fills `GOALS`.
  ```sql
  select goal_id,domain,status,value->>'title' as title,value->>'next_action' as next_action,coalesce(value->>'priority','2') as priority,value->>'project' as project,to_char(updated_at,'Mon DD') as upd,updated_at from public.deploy_memory where key='goal_meta' and status is distinct from 'deleted' order by updated_at desc;
  ```
- **R3 (L773) quick actions.** Fills `ACTIONS`.
  ```sql
  select id,domain,label,kind,ref,prompt from public.quick_actions where active order by id;
  ```
- **R4 (L782) skills.** Fills `SKILLS`. The table is `skill_catalog`, not `skills_registry`.
  ```sql
  select name,triggers,summary,domains,works_with,bucket,eli10,runs_within from public.skill_catalog order by name;
  ```
- **R5 (L785) loops.** Fills `LOOPS`. It excludes `deleted` and `retired` rows and has `limit 50`. R8 (`limit 300`) and R15 (`limit 100`) are the only other queries with a limit.
  ```sql
  select loop_id,title,version,is_active,skill_list,created_session_id,status,scope,loop_kind,done_when,updated_at from public.loops where status is distinct from 'deleted' and status is distinct from 'retired' order by updated_at desc limit 50;
  ```
- **R6 (L790-L793) spinoffs ("Saved for Later").** Fills `SPINOFFS`. The `#N` badge comes from the database as `row_number()` over the **filtered** set, ordered by `created_at, spinoff_id`. The file says this is the same formula `/close` uses (L786-L789).
  ```sql
  select spinoff_id,title,prompt,status,skills,spawned_session_id,merge_pending_since,created_at,updated_at,row_number() over (order by created_at, spinoff_id) as n from public.spinoffs where status in ('draft','ready','active','merge_pending','parked') order by created_at, spinoff_id;
  ```
- **R7 (L794) health keys.** Fills `BRAIN_META` and `CURRENT_SESSION`.
  ```sql
  select key,value from public.system_cache where key in ('brain_meta','current_session_id');
  ```
- **R8 (L797) context memos.** Fills `MEMOS`. The JS source has `\\_`; the SQL that is sent has `\_`.
  ```sql
  select m.id,m.goal_id,m.key,m.domain,m.status,m.created_session_id,to_char(m.updated_at,'Mon DD') as upd,m.updated_at,coalesce(m.value->>'title',m.key) as title,exists(select 1 from public.deploy_memory g where g.goal_id=m.goal_id and g.key='goal_meta') as parented from public.deploy_memory m where (m.key='context' or m.key like 'context\_%') and m.status is distinct from 'deleted' order by m.updated_at desc limit 300;
  ```
- **R9 (L800) unparented rows.** Fills `ORPHANS`.
  ```sql
  select count(*)::int as n from public.deploy_memory m where m.key<>'goal_meta' and m.key<>'scout_flag' and m.key<>'context' and m.key not like 'context\_%' and m.goal_id<>'system' and not exists (select 1 from public.deploy_memory g where g.goal_id=m.goal_id and g.key='goal_meta');
  ```
- **R10 (L809) flags.** Runs after the `Promise.all`. `PAUSED` is the value of flag `'system_paused'` (L810).
  ```sql
  select flag,value from public.system_flags;
  ```

**Preferences.**

- **R11 (L930) `loadPrefs()`.** Nonce yes.
  ```sql
  select value from public.system_cache where key='dashboard_prefs';
  ```

**Drill-in.**

- **R12 (L1829) `drill(id)`.** Runs each time a goal's drill box is opened (clicking the goal title). There is **no nonce** on this query. It renders one line per row: `[w<wave>·<key>·<status>] <JSON, first 300 chars>` (L1830).
  ```sql
  select wave,key,value,status from public.deploy_memory where goal_id='<goal_id>' and key in ('task','summary') order by wave,id;
  ```

**Dreams.** These are lazy: they run on the first visit to the Dreams tab, on "↻ Refresh dreams" or on "Retry" (L2203-L2208). Each is isolated in its own `try` block.

- **R13 (L1929-L1935) probe.** Always runs.
  ```sql
  select to_regclass('public.dream_proposals')::text as t_props, to_regclass('public.brain_edges')::text as t_edges, (select value from public.system_cache where key='dream_readiness') as readiness, (select value from public.system_cache where key='dream_last_run') as last_run, (select value from public.system_cache where key='dream_runs') as runs, (select value from public.system_cache where key='dashboard_last_publish') as publish;
  ```
- **R14 (L1945-L1946) counts.** Only when `t_props` is set.
  ```sql
  select op, coalesce(verdict,'unreviewed') as verdict, count(*)::int as n from public.dream_proposals group by 1,2 order by 1,2;
  ```
- **R15 (L1949-L1952) unreviewed rows.** Only when `t_props` is set. Limit 100.
  ```sql
  select proposal_id,lane,op,ref_table,ref_id,base_sha256,created_by,to_char(created_at,'Mon DD HH24:MI') as created,proposal from public.dream_proposals where verdict is null order by created_at desc limit 100;
  ```
- **R16 (L1956) edge count.** Only when `t_edges` is set.
  ```sql
  select count(*)::int as n from public.brain_edges;
  ```

**Home extras.** These are lazy: they run on the first Home render, which happens at boot. They also re-run after every `loadAll` once Home has loaded (L812), or on "Retry".

- **R17 (L2234-L2238) probe.** Always runs.
  ```sql
  select to_regclass('public.pending_confirmations')::text as t_pend, to_regclass('public.dream_proposals')::text as t_props, (select value from public.system_cache where key='dream_readiness') as readiness, (select value from public.system_cache where key='dream_last_run') as last_run;
  ```
- **R18 (L2248-L2252) pending list.** Only when `t_pend` is set. The file describes this as "the /close formula, verbatim" (L2244-L2246). There is no limit; Home shows the first 6.
  ```sql
  select n, id, action_type, ref, label, created_session_id, created from (select row_number() over (order by created_at, id) as n, id, action_type, ref, label, created_session_id, to_char(created_at,'Mon DD') as created from public.pending_confirmations where status='pending') t order by n;
  ```
- **R19 (L2256) unreviewed count.** Only when `t_props` is set.
  ```sql
  select count(*)::int as n from public.dream_proposals where verdict is null;
  ```

**When the queries run**
- **Boot:** R11, then R1-R9 in parallel, then R10. Because Home is the boot tab, R17, R18 and (when the table exists) R19 follow. **Measured:** 13 queries, or 14 when `dream_proposals` exists.
- **After any data write:** R1-R10 again, plus R17-R19 if Home has loaded.
- **Drill-in:** R12 each time a drill box is opened. Nothing is cached client-side.
- **Dreams tab:** R13-R16.

### 3b. Which tab or widget uses which query

| Consumer | Queries | Client-side logic (lines) |
|---|---|---|
| Home › Needs your click | R17 → R18 | Count. First 6 rows show `#n`, label and date. There are separate states for loading, error, missing table and query error (L2299-L2314). |
| Home › Top item per domain | R1, R2 | `goalDoms()` order. For each domain, the top **active**, else **blocked**, goal by priority then `updated_at` desc; a queued count; a stale flag at ≥14 days (L2315-L2327). |
| Home › Inbox | R2 (+R1 labels) | `status` starting with `queued`, sorted by priority then `updated_at` desc. First 5 (L2328-L2337). |
| Home › Ready to claim | R6 | `status='ready'` (first 5, `#n`) plus a count of drafts (L2338-L2348). |
| Home › Brain health | R7, R5, R6, R8, R9, R4 | Tiles for `failed_writes` (brain_meta), unparented (R9), loops, saved open, merge-pending, memos and skills counts, plus `last_write` and the session (L2349-L2359). |
| Home › Quick actions | R3 | `kind==='prompt'` only (L2360-L2368). |
| Home › Dream readiness | R17 (+R19) | `score`/`threshold`, `ran_at`, `ok`, unreviewed count (L2369-L2385). |
| Goals › MOM rollup | R1, R2 | Same maths as Top item per domain. Rows follow the saved `domOrder` (L1432-L1444). |
| Goals › domain board | R2, R3, R8 | Goals filtered by `domain===TAB`. Sections: Inbox (`queued*`), Active, Blocked, Done (collapsed). ⚡ quick actions where `a.domain===TAB \|\| a.domain==='all'` (L1446). A Context memos section for the domain (L1415-L1420). |
| Goals › drill-in | R12 | L1824-L1832 |
| Goals › chips | R1, R2 | A domain is "on deck" (dormant) when it has no goal whose status is `active`, `blocked` or `queued*` (L1144). `business` is excluded (L1145). |
| Saved for Later | R6 | Merge Pending / Ready to Claim / Active / Draft. Parked is only counted (L1566-L1583). Merge rows escalate at ≥7 days (L1603). |
| Parked | R2, R5, R6 | Goals `parked`, loops `paused`, spinoffs `parked` (L1586-L1595). |
| Loops | R5 | Lanes: Unproven (`candidate`, `draft`, plus any unknown or NULL status, L1505), Verified, Active, a paused note, and Retired. **The Retired section is unreachable** because R5 excludes retired rows. |
| Skills | R4 | Buckets view and Pipelines graph, both built from `runs_within` (L1656-L1789). |
| Dreams | R13-R16 | Four panes: Readiness, Inbox, Diff, Graph (L2072-L2210). |
| Health strip | R7 + counts from R5, R6, R8, R9 | L818-L832 |
| Footer | R2 (queued count, L1279), R10 (pause label, L1281) | |
| `dashboard_prefs` | R11 | `mergePrefs` (L900-L927). |

**`system_cache` keys read:** `dashboard_prefs` (R11), `brain_meta` and `current_session_id` (R7), `dream_readiness` and `dream_last_run` (R13, R17), `dream_runs` and `dashboard_last_publish` (R13).

**Fields used from JSON values**
- **brain_meta:** only `last_write` and `failed_writes` (L821-L822, L2350-L2351).
- **dream_readiness:** `score`, `threshold`, `components`, `since`, `computed_at` (L2084-L2106, L2374-L2376).
- **dream_last_run:** `ran_at`, `ok`, `error`, `edges_added`, `flags`, `trigger` (L1969-L1984, L2189-L2195).
- **dream_runs:** an array whose `edges_added` values are summed (L2182).
- **dashboard_last_publish:** printed as raw JSON (L2197).
- **proposal:** `before`, `after`, `why`, `dependencies` (L2157-L2171).

**Columns fetched but never used.** A mobile client could drop these:
- R4: `domains`.
- R5: `is_active`, `loop_kind`. The lane label comes from `done_when` (L1521).
- R6: `spawned_session_id`, `updated_at`.
- R8: `id`, and `updated_at` except as the sort key.
- R18: `id`, `action_type`, `ref`, `created_session_id`.

**Goal status handling (client side)**
- The "queued" family is anything where `status.startsWith('queued')` (L1436, L1447, L2329). `queued-unreviewed` gets a "NEEDS REVIEW" tag (L1636).
- **A goal whose status is not `queued*`, `active`, `blocked`, `done` or `parked` is loaded but appears in no section.** It is still reachable by title from the Jump palette. The file's own cleanup prompt names an `open` status (L1493).

---

## 4. WRITE STATEMENTS

### Exact count

**13 distinct write-statement templates at 14 call sites.** The call sites are L966, L1536, L1540, L1548, L1549, L1552, L1560, L1626, L1805, L1806, L1811, L1819, L1823 and L1884. **L1536 and L1548 are byte-identical**, which is why 14 sites give 13 templates.

- **Tables written (5):** `system_cache`, `loops`, `spinoffs`, `deploy_memory`, `system_flags`.
- **DELETE:** 0. **`jsonb_set`:** 0. **DDL:** 0.
- **One more side effect, not SQL:** `window.cowork.runScheduledTask(ref)` (L1835).
- The set of `sql(` lines is identical to v3.3's.

### Confirm mechanism: `arm(el, fn)` (L1794-L1803)
```js
function arm(el,fn){
  if(el.dataset.armed){
    el.dataset.armed=''; el.classList.remove('confirm');
    try{ Promise.resolve(fn()).catch(wfail); }catch(e){ wfail(e); }
  } else {
    el.dataset.armed='1'; el.classList.add('confirm');
    const old=el.textContent; el.textContent='confirm?';
    setTimeout(()=>{ if(el.dataset.armed){el.dataset.armed='';el.classList.remove('confirm');el.textContent=old;} },3500);
  }
}
```
- **First click:** stores the button text, replaces it with **`confirm?`**, adds the red `.confirm` class (L467) and sets `data-armed='1'`. It disarms automatically after **3,500 ms**.
- **Second click within that window:** runs `fn`. A rejected promise goes to `wfail`, which shows a red toast.
- **Measured:** the first click on a goal's "🅿 Park" sent no SQL and relabelled it `confirm?`; the second click sent W8 followed by W12.
- **Side effect:** the label swap goes through `textContent`. On the `<select>` used for "move…" this **removes every `<option>`** (see W9).
- `arm()` is called on 12 source lines: L1161, L1461, L1528, L1529, L1530, L1612, L1614, L1615, L1616, L1651 (one line that renders every status button on a goal card), L1652 and L1884.

### W1: preferences upsert (`savePrefs`, L940-L968; SQL at L966)
```sql
insert into public.system_cache (key,value) values ('dashboard_prefs','<lit(JSON.stringify(PREFS_RAW))>'::jsonb) on conflict (key) do update set value=excluded.value, updated_at=now();
```
- **Written value:** every known key taken from `PREFS`, laid over the row as it was loaded, so keys a newer build owns are carried over unchanged (L941-L958). The known keys are `v, layout, theme, accent, density, tabs, hidden, labels, title, home, whidden, domOrder, domLabels` (L959-L962).
  - `tabs` is always re-pinned so `home` comes first.
  - `hidden` never contains `home`.
- **Measured default payload:** `{"v":1,"layout":"rail","theme":"light","accent":"aubergine","density":"comfortable","tabs":["home","goals","saved","parked","loops","skills","dreams"],"hidden":[],"labels":{},"title":"","home":["needs-click","top-per-domain","inbox","ready","health","quick","dream"],"whidden":[],"domOrder":[],"domLabels":{}}`
- **When it runs:** the write is debounced by 600 ms (L964-L967). It is **skipped entirely when `PREFS_LIVE` is false** (L963). There is no `arm()` except on Reset tabs.
- **What triggers it (all UI customization):**
  - theme button (L985);
  - the drawer's Layout, Theme, Accent and Density buttons (L2521-L2524);
  - the title field (L668 → L989);
  - dragging tabs in the top strip or the rail (L2525-L2526 → `applyTabOrder` L2286);
  - dragging the drawer's tab list (L2527), its ↑/↓ buttons (L1387 → `moveTab` L1361) and Hide/Show (L1388-L1393);
  - renaming a tab (L1341-L1360) and Alt+←/→ (L2505);
  - dragging widgets on Home (L2433) or in the drawer (L2528), their ↑/↓ buttons (L2273) and ×/Hide/Show (L2279);
  - the domain chips: drag (L1189 → L1213), Alt+←/→ (L1182 → L1214) and rename (L1222-L1247);
  - Reset tabs, which is armed (L1161 → L1269).

### W2-W6: loops (all fired from loop cards and all armed)

The statements:

| # | Line(s) | Statement |
|---|---|---|
| W2 | L1536, L1548 | `UPDATE public.loops SET is_active=false, status='paused' WHERE scope='<scope>' AND is_active=true AND loop_id!='<loop_id>';` |
| W3 | L1540 | `UPDATE public.loops SET is_active=true, status='active', version=version+1, version_history=version_history\|\|'<snap>'::jsonb WHERE loop_id='<loop_id>';` where `snap` = JSON `{version, skill_list, scope, status, updated_at}` of the row in memory (L1539) |
| W4 | L1549 | `UPDATE public.loops SET is_active=true, status='active' WHERE loop_id='<loop_id>';` |
| W5 | L1552 | `UPDATE public.loops SET is_active=false, status='paused' WHERE loop_id='<loop_id>';` |
| W6 | L1560 | `UPDATE public.loops SET is_active=false, status='deleted' WHERE loop_id='<loop_id>';` |

The UI actions that fire them:

| Button | Shown on | Runs | Toast |
|---|---|---|---|
| **"✅ Verify & Promote"** (L1528) | `candidate` and `draft` loops only | `verifyPromote` (L1535-L1543): W2, then W3 | "✅ Loop promoted to active". If the row is missing from memory: "Loop not found — reload". |
| **"▶ Resume"** (L1529) | paused loops, which appear on the Parked tab | `toggleLoop` (L1545-L1556): W2, then W4 | "Loop resumed" |
| **"🅿 Park"** (L1529) | any loop that is not paused | `toggleLoop`: W5 | "Loop parked" |
| **"🗑 Delete"** (L1530) | any loop | `delLoop` (L1559-L1563): W6 | "Loop deleted (recoverable in DB)" |

### W7: saved-for-later status (`setSpin`, L1625-L1629; SQL at L1626)
```sql
UPDATE public.spinoffs SET status='<st>' WHERE spinoff_id='<spinoff_id>';
```
`st` is one of `ready`, `parked` or `deleted`. Every button is on the spinoff card and every one is armed:
- **"▶ Make ready"**: draft → `ready` (L1612).
- **"▶ Unpark"**: parked → `ready` (L1614).
- **"🅿 Park"**: → `parked` (L1615).
- **"🗑 Delete"**: → `deleted` (L1616).

Toasts: "Saved item → <st>" or "Saved item deleted (recoverable in DB)".

### W8: goal status (`setStatus`, L1805)
```sql
update public.deploy_memory set status='<st>' where key='goal_meta' and goal_id='<goal_id>';
```
`st` is one of `active`, `parked`, `done` or `deleted`, and it is **not escaped by `lit()`**. W12 follows, with action `status→<st>`. Toasts: "<goal_id> → <st>" or "<goal_id> deleted (recoverable in DB)". The buttons on each goal card depend on its status (L1637-L1645), and all are armed (L1651):

| Card status | Buttons (status written) |
|---|---|
| `queued`, `queued-unreviewed` | ▶ Activate (`active`), 🅿 Park (`parked`) |
| `active` | ✔ Done (`done`), 🅿 Park |
| `blocked` | ▶ Unblock (`active`), ✔ Done, 🅿 Park |
| `parked`, and **any status not listed here** (L1635) | ▶ Unpark (`active`), ✔ Done |
| `done` | ▶ Reopen (`active`) |
| every card | 🗑 Delete (`deleted`) |

### W9: goal domain (`setDomain`, L1806)
```sql
update public.deploy_memory set domain='<slug>' where goal_id='<goal_id>';
```
- W12 follows, with action `domain→<slug>`. Toast: "moved to <slug>".
- **This statement has no `key` filter**, so it re-domains **every** `deploy_memory` row that shares the `goal_id`: goal_meta, task, summary, audit, memos.
- **UI:** the "move…" `<select>` on every goal card: `onchange="if(this.value)arm(this,()=>setDomain('<id>',this.value))"` (L1652). Its options are every active domain except the goal's own; **`business` is not excluded here** (L1646).
- **Measured: this cannot complete.** After the first change, `arm()` had set `textContent` on the select, so the select held **0 options**, `value=''` and the text node "confirm?". No SQL was sent. After 3.5 s the text was restored as a text node, still with 0 options. The select only recovers on the next re-render.

### W10: add goal (`addGoal`, L1807-L1813; SQL at L1811)
```sql
insert into public.deploy_memory (goal_id,agent,key,value,status,domain) values ('<YYYY-MM-DD>-<slug>','dashboard','goal_meta','{"title":"<t>","project":"<TAB>","next_action":"<n or define next action>","priority":"<1|2|3>"}'::jsonb,'active','<TAB>') on conflict (goal_id) where key='goal_meta' do update set value=excluded.value;
```
- **UI:** the "Add goal" form at the bottom of each domain board (L1457-L1461). It has inputs with placeholders `title` and `next action`, a P1/P2/P3 select defaulting to P2, and a button **"Add to <slug>"** that is armed.
- **Empty title:** toast "title required" (L1809).
- **Success:** W12 with "added via dashboard", then toast "added".
- **`goal_id`:** `new Date().toISOString().slice(0,10)` gives the **UTC** date. Then comes `-` and the title lowercased, with each run of non-alphanumerics turned into `-`, cut to 30 characters, and any trailing `-` removed (L1810).
- **Conflict:** if the id already exists, the upsert **replaces the whole `value`** of that goal_meta row. Its status is not changed.

### W11: quick capture (`capture`, L1814-L1822; SQL at L1819)
```sql
insert into public.deploy_memory (goal_id,agent,key,value,status,domain) values ('<YYYY-MM-DD>-<slug>','dashboard','goal_meta','{"title":"<t>","project":"<dom>","next_action":"queued via MOM dashboard — awaiting drain","priority":"2"}'::jsonb,'queued','<dom>') on conflict (goal_id) where key='goal_meta' do nothing;
```
- **Columns written:** `goal_id, agent='dashboard', key='goal_meta', value{title, project, next_action, priority:'2'}, status='queued', domain`.
- **No `arm()`.** It fires on Enter in `#capText` (L624) or on the **"Queue"** button (L626).
- **Domain:** the header select `#capDom`, which lists active domains except `business` in `sort` order; the first is the default (L1278).
- **After the write:** toast "queued to <slug>" and the text box is cleared.
- **Same-day duplicate title:** `do nothing` drops it silently, but the toast still appears.
- No audit row is written.
- The `goal_id` rule is the same as W10 (L1817).
- **Measured example:** `...values ('2026-09-27-call-o-brien-about-test','dashboard','goal_meta','{"title":"Call O''Brien about test","project":"health",...}'::jsonb,'queued','health') ...`

### W12: audit row (`audit`, L1823)
```sql
insert into public.deploy_memory (goal_id,agent,key,value,status,domain) values ('<goal_id>','dashboard','audit','{"action":"<act>","at":"<ISO time>"}'::jsonb,'done',(select domain from public.deploy_memory where key='goal_meta' and goal_id='<goal_id>'));
```
It is called after W8, W9 and W10. **Its errors are swallowed.**

### W13: automation pause (`togglePause`, L1884)
```sql
update public.system_flags set value=<true|false>, updated_at=now() where flag='system_paused';
```
- **UI:** the footer button **"⏸ Pause automation"** or **"▶ Resume automation"** (L642, L1281). It is armed.
- **Toast:** "automation PAUSED" or "automation resumed".
- **Ordering:** `PAUSED` is flipped in memory **before** the write. If the write is rejected, the red toast shows but the flag stays flipped until the next `loadAll`.

### Not SQL: running a scheduled task (`runQA`, L1833-L1837)
- **Task actions:** `kind==='task' && ref` calls `await window.cowork.runScheduledTask(a.ref)`. Toasts: "running: <label>" or "task launch failed".
- **Other actions:** everything else copies `a.prompt` through `copyText`, showing "prompt copied" or falling back to the copy modal.
- **UI:** the **"⚡ <label>"** buttons on each Goals domain board (L1451).
- **Measured:** `runQA` on a task action called `runScheduledTask('lead-scan')` and sent no SQL.

---

## 5. NAVIGATION MODEL

### `TABS_DEF` registry (L863-L873)

Internal keys never change. What the user types is only a display label, stored in `prefs.labels`.

| key | label | group | flags | count badge (shown only when > 0, L1004) |
|---|---|---|---|---|
| `home` | Home | Work | `pin:true`, `cls:'warn'` | `HOME.pending.length`, i.e. pending confirmations (only after Home has loaded) |
| `goals` | Goals | Work | — | — |
| `saved` | Saved for Later | Later | `cls:'amber'` | spinoffs with status `merge_pending` or `draft` |
| `parked` | Parked | Later | `cls:'gray'` | parked goals + paused loops + parked spinoffs |
| `loops` | Loops | System | `cls:'warn'` | loops with status `draft` or `candidate` |
| `skills` | Skills | System | — | — |
| `dreams` | Dreams | System | — | — |

- **Measured** rail text with the synthetic data: `WORK · Home 2 · Goals · LATER · Saved for Later 2 · Parked 3 · SYSTEM · Loops 1 · Skills · Dreams`.
- **Dispatch:** `render()` (L1422-L1462) maps each key to its renderer: `home`→`renderHome`, `loops`→`renderLoops`, `saved`→`renderSpinoffs`, `parked`→`renderParked`, `skills`→`renderSkillsTab`, `dreams`→`renderDreams`. Anything else renders Goals, meaning the domain chips plus either the MOM rollup or a domain board.
- `setMainTab(k)` (L1022-L1028) sets `MAIN_TAB`, closes the More menu, re-renders the nav and shows `nav#domtabs` only on `goals`.
- **Icons:** each tab has an inline SVG in `TAB_ICON` (L852-L860).

### Rail vs top tabs

The layout is set by the `data-layout` attribute on `<html>` (L976). `renderNav()` always builds **both** layouts from one list, `visTabs()` (L1006-L1021), and CSS shows only one of them (L391-L392).

- **`rail`** (the default, `PREFS_DEFAULTS.layout='rail'` at L892): `nav.rail#rail` is 176 px wide, with a mono uppercase heading for each group, Work, Later and System (L390, L393, L408-L411, L1010-L1012).
  - At **≤640 px** it narrows to 52 px and shows icons only. Labels, group headings and count badges are hidden (L412-L417).
- **`tabs`:** a horizontal strip `.tabs#tabs` with `overflow-x:auto` (L394). **Measured:** at 390 px the strip content is 758 px wide, so it has to scroll.

### Home is pinned first
- `pinFirst()` (L889) is applied on load (L911), on save (L960), after a strip or rail drag (L2288) and after a drawer drag (L2527).
- `moveTab` refuses to move it and toasts **"Home stays pinned first"** (L1364).
- Home cannot be hidden: it is filtered out of `hidden` (L913, L960), and the drawer offers no move or Hide button for a pinned tab (L1381).
- It **can** be renamed (L1380).

### Hidden and renamed tabs
- **Hide:** the drawer's Hide/Show toggles `prefs.hidden` (L1388-L1393). If the open tab gets hidden, the first visible tab opens instead (L1391).
- **Reaching hidden tabs:** a **"More (N)"** button appears only when N > 0 (L1008). It sits at the end of the strip (`margin-left:auto`) or the bottom of the rail and opens `#moreMenu` (L1286-L1297), an absolutely positioned list of hidden tabs. The menu closes on any `pointerdown` outside it (L1299) or on navigation (L1024).
- The Jump palette also lists hidden tabs, tagged "hidden tab" (L2452).
- **Rename triggers:** double-click (L1018), F2 (L1019) or the drawer's **"Rename"** button (L1380, L1386). This opens `renameTab` (L1341-L1360), an inline input:
  - capped at **24 code points** (`TAB_LABEL_MAX` L1043, via `capBox` L1204 and `domLabelClean` L1350);
  - Enter or blur saves; Escape cancels;
  - an empty name or the default name clears the override.
- **Rename toasts:** 'Renamed to "<v>" (key stays <key>)' or "Name reset".
- **Showing the original name:** tooltip `(originally "…")` (L1001-L1002); in the drawer, `was <orig>` (L1379).

### Goals-section domain chips (v3.4, `renderGoalsChips` L1143-L1197)

**Chip strip contents, in order (L1157-L1162):**
1. **Pinned overview chip.**
   - Its key is `'__all__'` (`DOM_ALL_KEY`, L1040). Clicking it sets `TAB='mom'` (L1169).
   - Its default label is **"MOM"** (L1041), shown with the `BRAIN_ICON` SVG (L1153). When selected it uses the accent fill (L422).
   - It sits outside the sortable spans, so it cannot be dragged. It can be renamed.
2. **Active domain chips** in `span.dsort#domSortA`. A domain is active when it has at least one goal whose status is `active`, `blocked` or `queued*` (L1144).
3. **"+ tab"** (`.dtool`, dashed border; L1160).
   - A click replaces it with an input whose placeholder is *"new tab name, Enter copies"*.
   - Enter **copies** `add a Goals tab "<name>" to public.domains` through `dreamCopy` (L1251-L1267).
   - Blur or Escape copies nothing. **It never writes.**
4. **"Reset tabs"**, shown only once `domOrder` or `domLabels` is non-empty (L1155, L1161).
   - It is armed, and clears those two keys only (L1269-L1273).
   - Toast: "Goals tabs reset to the default order and names".
5. **The on-deck shelf** `.shelf`, with a label **"on deck"** and the chips `span.dsort#domSortD` (L1162): dormant domains, dimmed to opacity .5 (L424).

**Order**
- Slugs saved in `prefs.domOrder` come first. Any active domain missing from it follows in `public.domains.sort` order (`orderDomains` L1101-L1112).
- **Drag** reorders within each group (L1189 → `dropDoms` L1213 → `domSubsetOrder` L1121). Toast: "Goals tab order saved".
- **Alt+←/→** on a focused chip moves it within its group (L1182-L1186 → `moveDom` L1214 → `domMove` L1128). The key event is `stopPropagation`'d so the global handler does not also move the top tab.
- Trying to move a chip in front of MOM toasts **"<MOM label> stays pinned first"**.
- Slugs that are no longer active are kept on write (L1137-L1141).

**Rename**
- Triggered **only by double-click or F2** (L1171-L1181). There is no button for it.
- Capped at 40 code points (L1042). Stored in `prefs.domLabels[slug]`, with `'__all__'` as the key for the pinned chip.
- Toasts: 'Renamed to "<v>" (lookups still use <slug | the overview>)' or 'Name reset to "<default>"'.
- A double-click renames the chip that the **first** click hit (`_domClick`, within 1,000 ms; L1165-L1178, L1195).

**Display names vs raw slugs**
- `domLabel(slug)` (L1200) supplies the name wherever a domain is shown: chips, rollup, Home top-per-domain and inbox, capture and move-to options, and the Jump palette.
- These places show the **raw slug** instead: the "Add to <slug>" button (L1461), the toasts "moved to <slug>" and "queued to <slug>" (L1806, L1820), and the goal card meta line, which shows `project` (L1650).
- The Pick-up prompt uses the canonical `public.domains.label` on purpose (L1872).
- **`business`** is excluded from the chips (L1145), `goalDoms()` (L1201) and the capture select (L1278). It is **not** excluded from the card move-to select (L1646).

### Jump palette (markup L673-L679; CSS L606-L616; logic L2444-L2488)
- **Open:** the header **"Jump"** button, which shows a "Ctrl K" hint (L628, L2530), or **Ctrl/Cmd+K**, which toggles it (L2502).
- **Close:** Escape (L2538), a click on the backdrop (L2540), or running an item.
- **Items** (`palItems` L2445-L2469) are filtered by substring on the label **or** the kind text, and **capped at 9** (L2468):
  1. every tab, in `prefs.tabs` order, tagged `tab` or `hidden tab`, plus `· was <orig>` when renamed;
  2. every chip domain, shown as `<label> goals` and tagged `domain`; running it calls `homeGoDom(slug)`;
  3. every loaded goal by title, tagged `goal · <domain label>`, which opens that domain's board;
  4. `Customize dashboard` and `Toggle dark theme`, both tagged `action`;
  5. every `kind='prompt'` quick action, tagged `quick action`, which runs `qaCopy`. The palette never calls `runScheduledTask`.
- **Picking:** ArrowUp/ArrowDown then Enter (L2533-L2537), or a click (L2484-L2487).

### Keyboard shortcuts

| Key | Where | Effect | Lines |
|---|---|---|---|
| Ctrl/Cmd + K | anywhere | Toggle the Jump palette | L2502 |
| ↑ / ↓ / Enter / Esc | palette input | Select, run, close | L2533-L2539 |
| Alt + ← / → | not in an input | Move the focused `.tab`, or the active tab, one slot through `moveTab` | L2505-L2508, L2491-L2499 |
| Alt + ← / → | focused domain chip | Move the chip within its group | L1182-L1186 |
| 1-9 | not in input, select or textarea; no modifiers | Open the Nth **visible** tab ("1" is always Home) | L2509-L2512 |
| F2 | focused top tab or domain chip | Rename in place | L1019, L1181 |
| Enter / Esc | rename box, "+ tab" box | Save or copy / cancel | L1242, L1265, L1357 |
| Enter | quick-capture box | `capture()`, which writes W11 | L624 |

There is **no Escape handling** for the Customize drawer, the copy modal or the More menu.

### Customize drawer (markup L659-L670; `renderDrawer` L1373-L1412)

- **Open:** the header **"Customize"** button (L630) or the palette action.
- **Close:** × (L661) or a click on the backdrop (L660).
- **Contents:**
  1. **"Tabs — drag to reorder, Hide to tuck away".** One row per tab with a ⋮ handle (📌 when pinned), the icon, the name, and the buttons Rename / ↑ / ↓ / Hide|Show. Pinned tabs get Rename only.
  2. **"Home widgets — drag to reorder, Hide to tuck away".** The same row layout without Rename.
  3. **Layout:** Side rail / Top tabs.
  4. **Theme:** White / Dark / Follow system.
  5. **Accent:** **Purple** (key `aubergine`) / Harbor / Ember / Moss.
  6. **Density:** Comfortable / Compact.
  7. **Dashboard title:** `maxlength="40"`. The value is cut with `.slice(0,40)` in UTF-16 units, unlike the code-point caps used elsewhere (L923, L989).
  8. The fine print (L669).
- **Behaviour:** every change calls `savePrefs()` (W1).

---

## 6. HOME WIDGETS

- **Registry:** `HOME_DEF` (L877-L885). Keys are fixed; the labels are for display only.
- **Stored state:** order in `prefs.home`, hidden widgets in `prefs.whidden`. The default order is the registry order.
- **Load behaviour:** Home is the boot tab (L687). Its extra reads (R17-R19) are lazy and isolated (L2228-L2265). Every other widget renders from data `loadAll()` has already fetched.

| # | key | Card title | Shows | Data source | Interactions |
|---|---|---|---|---|---|
| 1 | `needs-click` | Needs your click | A big count of pending confirmations. Up to **6** rows, each with a `#n` badge, the label (ellipsized, full text in a tooltip), the created date (`Mon DD`) and a **"tick"** button. After 6 rows: "… N more — the full numbered list prints at /close." | R18 via R17. Row numbers come from the database (`row_number() over (order by created_at, id)`). | "tick" **copies** `tick <n>` through `dreamCopy`, with no DB write (L2309). The count also drives the Home tab badge (L866). |
| 2 | `top-per-domain` (`wide:true`, full grid row) | Top item per domain | One row per chip domain, in the saved order: bold domain label, priority pill and title of the top active (else blocked) goal, `📥N` queued count, and `⚠ Nd` when stale (≥14 days) | R1 + R2 | A row click calls `homeGoDom(slug)`, which opens that domain board (L2323). |
| 3 | `inbox` | Inbox | A big count of queued goals. Up to **5** rows with priority pill, title and domain label. After 5: "… N more in Goals."; when empty, "inbox zero". | R2 | A row click opens that goal's domain board. |
| 4 | `ready` | Ready to claim | A big count of `ready` spinoffs; "· N draft(s) await promotion". Up to **5** rows with `#n` and title. | R6 | A row click opens the Saved for Later tab (L2343). |
| 5 | `health` | Brain health | Seven tiles: failed writes, unparented, loops, saved open, merge-pending, memos, skills. Failed writes, unparented and merge-pending turn red when > 0. Below: "last write <date> · session <id>". | R7 (`brain_meta.failed_writes`, `last_write`; `current_session_id`), R9, plus lengths of R5, R6, R8 and R4 | None |
| 6 | `quick` | Quick actions | One "⚡ <label>" button for each `kind='prompt'` quick action. Fine print: "Prompt-only (ruling B-R4) … N task-type action(s) stay on the Goals tab." | R3 | `qaCopy(id)` copies the prompt, falling back to the copy modal. It **never** runs a task (L2269-L2272). |
| 7 | `dream` | Dream readiness | Score /100, a meter with a threshold line (the receipt's `threshold`, else the page default **60**, L1908), the last-run time, `ok=false` when the run failed, and the unreviewed count. Aggregates only (ruling B-R6). | R17 (`dream_readiness`, `dream_last_run`) + R19 | An **"Open Dreams"** button opens the Dreams tab. |

**Card chrome and layout (L2294-L2402)**
- **Card header:** a **⋮** drag handle, the uppercase mono title, and **×** to hide.
- **Grid:** `.wgrid` is `repeat(auto-fit,minmax(270px,1fr))` (L555).
- **Hidden widgets:** listed under the grid as "Hidden: [buttons]" to bring them back.
- **Footnote:** *"Drag a card by its ⋮ handle to rearrange; × hides it. Order and visibility save to the same dashboard_prefs row."*
- **Dragging:** only from the handle (`makeWidgetSortable` L2407-L2436). Toast: "Home layout saved".
- **When the Home reads fail:** a red banner "Home extras unreachable — <msg> Retry" (L2396).
- **Writes:** Home writes to the database only through W1 (layout preferences).

---

## 7. PICK-UP / CHAT HANDOFF FLOW

**Pick up writes nothing to the database.** The comment at L1854 says so ("Non-destructive (no DB write)"). **Measured:**
- first click: 0 SQL statements and exactly 1 `sendPrompt` call;
- second click: 0 SQL statements and no new prompt; it only clears the green state.

Pick up is **not** behind `arm()`.

**Buttons.** **"💬 Pick up"** appears on goal cards (L1651), loop cards (L1527) and saved-for-later cards (L1611). Home rows do not have it.

**`PICKED` state** (L689) is an in-memory `Set` of keys `goal:<id>`, `spin:<id>` and `loop:<id>`.
- Each card checks it on every render, so the green `.picked` style (L466) survives re-renders and reloads of the data.
- It is lost on a page reload and is never persisted.

**Toggle, three prompt templates and the dispatcher, verbatim (L1855-L1883)**
```js
async function sendToChat(text){
  if(window.cowork && typeof window.cowork.sendPrompt==='function'){ try{ window.cowork.sendPrompt(text); toast('\u{1F4AC} Opening chat…'); return; }catch(e){} }
  if(typeof sendPrompt==='function'){ try{ sendPrompt(text); toast('\u{1F4AC} Opening chat…'); return; }catch(e){} }
  if(await copyText(text)){ toast('\u{1F4CB} Prompt copied — paste into a new chat'); return; }
  showCopyModal(text);
}
// [22] Pick-up toggle
function togglePickup(el, kind, id){
  const key = kind+':'+id;
  if(PICKED.has(key)){ PICKED.delete(key); el.classList.remove('picked'); return; }
  PICKED.add(key); el.classList.add('picked');
  if(kind==='goal') pickUp(id);
  else if(kind==='spin') pickUpSpin(id);
  else if(kind==='loop') pickUpLoop(id);
}
function pickUp(id){
  const g=GOALS.find(x=>x.goal_id===id); if(!g) return;
  const dom=(DOMAINS.find(d=>d.domain===g.domain)||{}).label||g.domain;
  sendToChat("Resume this brain task and pull its full context first — query public.deploy_memory for goal_id='"+id+"' (goal_meta, task, and summary rows) to load prior work, then continue from the current next action with me.\nTask: \""+(g.title||'')+"\" ["+id+"] · Domain: "+dom+" · Current next action: "+(g.next_action||'none set')+".");
}
function pickUpSpin(id){
  const s=SPINOFFS.find(x=>x.spinoff_id===id); if(!s) return;
  sendToChat("Resume this saved-for-later item and pull its context first — read public.spinoffs where spinoff_id='"+id+"' for the full prompt, status, and skills, then continue it with me.\nSaved item #"+(s.n||'?')+": \""+(s.title||'')+"\" ["+id+"] · Status: "+(s.status||'')+"\nDeferred prompt: "+(s.prompt||'none recorded'));
}
function pickUpLoop(id){
  const l=LOOPS.find(x=>x.loop_id===id); if(!l) return;
  const sk=Array.isArray(l.skill_list)?l.skill_list.join(', '):(l.skill_list||'none recorded');
  sendToChat("Start a session from this saved loop — read public.loops where loop_id='"+id+"' for its full skill_list and scope, then walk me through running it.\nLoop: \""+(l.title||'')+"\" ["+id+"] · Scope: "+(l.scope||'')+"\nSkill sequence: "+sk);
}
```
**The goal prompt as the user receives it.** `dom` is `public.domains.label` or the slug, **never** the user's `domLabels` rename (L1872).
```
Resume this brain task and pull its full context first — query public.deploy_memory for goal_id='<goal_id>' (goal_meta, task, and summary rows) to load prior work, then continue from the current next action with me.
Task: "<title>" [<goal_id>] · Domain: <domain label> · Current next action: <next_action | none set>.
```
**The saved-for-later prompt:**
```
Resume this saved-for-later item and pull its context first — read public.spinoffs where spinoff_id='<spinoff_id>' for the full prompt, status, and skills, then continue it with me.
Saved item #<n | ?>: "<title>" [<spinoff_id>] · Status: <status>
Deferred prompt: <prompt | none recorded>
```
**The loop prompt:**
```
Start a session from this saved loop — read public.loops where loop_id='<loop_id>' for its full skill_list and scope, then walk me through running it.
Loop: "<title>" [<loop_id>] · Scope: <scope>
Skill sequence: <skill_list joined ", " | none recorded>
```

**How `sendToChat(text)` delivers a prompt** (L1855-L1860), trying each step in order:
1. `window.cowork.sendPrompt(text)`, called synchronously. On success the toast is "💬 Opening chat…".
2. If that is unavailable or throws, a bare global `sendPrompt(text)`, with the same toast.
3. `await copyText(text)`. On success the toast is "📋 Prompt copied — paste into a new chat".
4. `showCopyModal(text)`.

When `sendPrompt` succeeds, nothing is copied to the clipboard.

**Clipboard helpers, verbatim (L1839-L1853)**
```js
async function copyText(text){
  try{ await navigator.clipboard.writeText(text); return true; }catch(e){}
  try{
    const ta=document.createElement('textarea');
    ta.value=text; ta.style.position='fixed'; ta.style.top='0'; ta.style.left='0'; ta.style.opacity='0';
    document.body.appendChild(ta); ta.focus(); ta.select();
    const ok=document.execCommand('copy'); document.body.removeChild(ta);
    return !!ok;
  }catch(e){ return false; }
}
function showCopyModal(text){
  document.getElementById('copyModalText').value=text;
  document.getElementById('copyModal').style.display='flex';
  const ta=document.getElementById('copyModalText'); ta.focus(); ta.select();
}
```
The copy modal markup is at L647-L654:
- heading **"Copy this prompt, then paste it into a new chat"**;
- a read-only monospace textarea;
- **"Select & copy"**, which runs `select()` + `document.execCommand('copy')` and toasts "copied";
- **"Close"**.

**Other chat hand-offs**
- **"Evaluate & clean up"** buttons also go through `sendToChat`:
  - Goals domain board (L1450) → `cleanupGoalsPrompt(TAB)` (L1490-L1500);
  - Loops (L1502) → `reconcileLoopsPrompt()` (L1467-L1478);
  - Saved for Later (L1568) → `cleanupSavedPrompt()` (L1479-L1489).

  The full text is in Appendix A. It embeds the project id and `memory.md`.
- **Copy-only lines** use `dreamCopy(btn, text)` (L1992-L2008), **not** `sendToChat`. It works like this:
  1. It puts the text in the hidden **read-only** textarea `#dreamCopySrc` (L657) and runs `document.execCommand('copy')` **synchronously first**.
  2. If that fails, it falls back to `navigator.clipboard.writeText`.
  3. The button relabels to **"Copied ✓"** or **"Copy FAILED"** for 2.8 s.
  4. Toast: `copied → paste into Claude Code:  <text>`.
  5. On failure it opens the copy modal.

  The copied lines are:
  - `dream review <uuid>` (L2018);
  - `dream show <uuid>` (L2019, only for a proposal with no before/after);
  - `dream review` (L2025, L2147);
  - `tick <n>` (L2309, Home);
  - `add a Goals tab "<name>" to public.domains` (L1263).

  An id must pass `isUuid()` before it is placed in an `onclick` string (L2015).
- **Quick-action prompts:** `runQA` (the prompt branch, L1836) and `qaCopy` (L2271) use `copyText`, then fall back to `showCopyModal`. They do **not** use `sendToChat`.

---

## 8. VISUAL LANGUAGE

**Where the theme lives.** Theme, accent, density and layout are all attributes on `<html>`: `data-theme`, `data-accent`, `data-density` and `data-layout`. `applyAttrs()` sets them (L973-L982).
- `theme='system'` **removes** `data-theme`, so the OS preference applies through `@media (prefers-color-scheme:dark)`.
- The defaults (L892) are `layout:'rail'`, `theme:'light'`, `accent:'aubergine'` and `density:'comfortable'`.

### Tokens, verbatim (L330-L370)
```css
  :root{
    color-scheme:light;
    --ground:#F6F3F9; --panel:#FFFFFF; --panel-2:#FAF8FC; --ink:#1E1530; --muted:#6F6784;
    --line:#E4DEEC; --line-2:#EFEBF4;
    --acc:#6366f1; --acc-ink:#FFFFFF; --acc-soft:#E8E9FD; --deep:#2C1A47; --deep-ink:#F4EEF7;
    --good:#2E7D4F; --good-s:#E3F2E9; --warn:#A8720F; --warn-s:#FBF0D6; --bad:#B3372B; --bad-s:#FAE3DF;
    --info:#2F5FA8; --info-s:#E4ECF9;
    --pad:14px; --card-pad:9px 11px; --fs:14px;
    --mono:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;
    --sans:"IBM Plex Sans",-apple-system,'Segoe UI',sans-serif;
    --disp:"Bricolage Grotesque","IBM Plex Sans",-apple-system,'Segoe UI',sans-serif;
  }
  :root[data-density="compact"]{ --pad:9px; --card-pad:6px 9px; --fs:12.5px; }
  :root[data-accent="harbor"]{--acc:#1F6F8B;--acc-soft:#E0EFF4;--deep:#12333F;--deep-ink:#EAF3F6}
  :root[data-accent="ember"]{--acc:#B9541C;--acc-soft:#F9E6DC;--deep:#3A1F12;--deep-ink:#F7EDE6}
  :root[data-accent="moss"]{--acc:#3E7A3A;--acc-soft:#E4F0E2;--deep:#1E3A1C;--deep-ink:#EAF3E9}
  /* dark — twice on purpose: once for system-dark with no explicit choice, once for the explicit pick */
  @media (prefers-color-scheme:dark){
    :root:not([data-theme="light"]){
      color-scheme:dark;
      --ground:#140F1E; --panel:#1E1730; --panel-2:#241C39; --ink:#F1ECF7; --muted:#A99DBD;
      --line:#352A4C; --line-2:#2B2240;
      --acc:#818CF8; --acc-ink:#141433; --acc-soft:#26264A; --deep:#F1ECF7; --deep-ink:#1E1730;
      --good:#7CCB9C; --good-s:#1B3527; --warn:#E0B75A; --warn-s:#3A2F14; --bad:#F0918A; --bad-s:#3F1D1B;
      --info:#8DB0F0; --info-s:#1C2A46;
    }
    :root:not([data-theme="light"])[data-accent="harbor"]{--acc:#5FB3D0;--acc-soft:#16303A}
    :root:not([data-theme="light"])[data-accent="ember"]{--acc:#F0915F;--acc-soft:#3B2216}
    :root:not([data-theme="light"])[data-accent="moss"]{--acc:#8BCB85;--acc-soft:#1F3A1E}
  }
  :root[data-theme="dark"]{
    color-scheme:dark;
    --ground:#140F1E; --panel:#1E1730; --panel-2:#241C39; --ink:#F1ECF7; --muted:#A99DBD;
    --line:#352A4C; --line-2:#2B2240;
    --acc:#818CF8; --acc-ink:#141433; --acc-soft:#26264A; --deep:#F1ECF7; --deep-ink:#1E1730;
    --good:#7CCB9C; --good-s:#1B3527; --warn:#E0B75A; --warn-s:#3A2F14; --bad:#F0918A; --bad-s:#3F1D1B;
    --info:#8DB0F0; --info-s:#1C2A46;
  }
  :root[data-theme="dark"][data-accent="harbor"]{--acc:#5FB3D0;--acc-soft:#16303A}
  :root[data-theme="dark"][data-accent="ember"]{--acc:#F0915F;--acc-soft:#3B2216}
  :root[data-theme="dark"][data-accent="moss"]{--acc:#8BCB85;--acc-soft:#1F3A1E}
```

**How the tokens combine**
- **Light defaults** (L330-L341) apply to the `aubergine` accent. No rule targets `aubergine` directly, and the drawer labels it **"Purple"** (L666).
- **Dark** is defined twice with identical values. One copy covers the OS preference when no theme is chosen (L347-L359); the other covers an explicit dark choice (L360-L367).
- **In dark mode the accent overrides change only `--acc` and `--acc-soft`.** `--deep`, `--deep-ink` and `--acc-ink` keep the dark base values `#F1ECF7`, `#1E1730` and `#141433`.

### The four accent palettes

| `data-accent` | Drawer label | light `--acc` | `--acc-soft` | `--deep` | `--deep-ink` | dark `--acc` | dark `--acc-soft` |
|---|---|---|---|---|---|---|---|
| `aubergine` (default) | Purple | `#6366f1` | `#E8E9FD` | `#2C1A47` | `#F4EEF7` | `#818CF8` | `#26264A` |
| `harbor` | Harbor | `#1F6F8B` | `#E0EFF4` | `#12333F` | `#EAF3F6` | `#5FB3D0` | `#16303A` |
| `ember` | Ember | `#B9541C` | `#F9E6DC` | `#3A1F12` | `#F7EDE6` | `#F0915F` | `#3B2216` |
| `moss` | Moss | `#3E7A3A` | `#E4F0E2` | `#1E3A1C` | `#EAF3E9` | `#8BCB85` | `#1F3A1E` |

`--acc-ink` is `#FFFFFF` in light mode and `#141433` in dark mode, for every accent.

### Density
- **`comfortable`** (default): `--pad:14px; --card-pad:9px 11px; --fs:14px`.
- **`compact`** (L342): `--pad:9px; --card-pad:6px 9px; --fs:12.5px`.
- Nothing else in the stylesheet changes with density.

### Fonts
- **Google Fonts is loaded** from an external stylesheet (L320):
  - Bricolage Grotesque, weights 500 and 700, optical size 12..96;
  - IBM Plex Sans, weights 400, 500 and 600;
  - IBM Plex Mono, weights 400, 500 and 600.
- **Font stacks:**
  - `--sans: "IBM Plex Sans",-apple-system,'Segoe UI',sans-serif` sets the body text (L373).
  - `--disp: "Bricolage Grotesque",…` is used only for the header `h1` (L375) and the drawer `h3` (L583).
  - `--mono: ui-monospace,SFMono-Regular,Menlo,Consolas,monospace` is a **system mono stack**. It covers the rail group headings, tab badges, widget titles, drawer `h4`, the palette hint, the copy textarea and the diff and table cells.
- **IBM Plex Mono is downloaded but never referenced** in the stylesheet.
- **Offline behaviour:** `-apple-system` and `Segoe UI` do not exist on Android, so the text would fall back to the generic `sans-serif`.

### Header brand mark
- **Header `h1`:** the 🧠 emoji `&#129504;` followed by the title (L622). `applyAttrs` re-sets it as `'&#129504; '+esc(dashTitle())` (L981).
  - `TITLE_DEFAULT='Minds Over Matters'` (L845). `prefs.title` overrides it and also sets `document.title` (L979).
- **`BRAIN_ICON`** (L849) is an inline stroke SVG. It is used **only** on the pinned MOM domain chip (L1153), styled `.brain-ic` at 13×13 (L435).
- **Other icons:**
  - `TAB_ICON` SVGs (L852-L860), 24-unit viewBox, `stroke=currentColor`, width 2;
  - `SUN_SVG` and `MOON_SVG` (L850-L851) on the theme button, labelled " Dark" in light mode and " Light" in dark mode (L978);
  - inline SVGs on Jump and Customize (L628, L630);
  - emoji inside many labels: 💬 ⚡ 🅿 🗑 ✔ ▶ 📥 ⚠ 📝 🗒 🌱 🔁 🧠 🔍 📋.

### Border radii
| Radius | Where it is used |
|---|---|
| `8px` (21 rules) | Buttons, inputs, cards, rollup rows, drawer rows, buckets, the toast |
| `6px` (10 rules) | Diff blocks, rename inputs, the priority pill `.pri`, meter bars |
| `10px` (5 rules) | `main` panel (L436), `.pill` (L505), the copy-modal box (L517), Home widget cards `.w` (L556), the More menu (L602) |
| `999px` (3 rules) | Tab count badge (L400), domain chips (L420), the "+ tab" input (L434) |
| `14px` | Palette box (L610) |
| `9px` | `RUNS`/`STEP` badges (L491, L493) |
| `7px` | `#N` badge (L459), More-menu items (L603) |
| `5px` | Keyboard hint (L607) |
| `8px 8px 0 0` | Top tab (L395) |

### Cards and stripes
- **Base `.card`** (L439): a 1 px `--line` border, 8 px radius, `--card-pad` padding, a 6 px bottom margin and a `--panel` background.
- **Status is shown as a 3 px left stripe:**

  | Class | Stripe colour | Also |
  |---|---|---|
  | `queued` | `--warn` | |
  | `active` | `--good` | |
  | `blocked` | `--bad` | |
  | `parked`, `done` | `--muted` | opacity .85 |
  | `draft` | `--warn` | |
  | `merge` | `--bad` | `--bad-s` fill |
  | `lready` (ready spinoff) | `--info` | |
  | `skl` (skill) | `--muted` | |
  | `dcard` (dream) | `--acc` | |

  These are defined at L440-L447 and L538.
- **Section headings:** `h2` is 12 px, uppercase, `letter-spacing .05em`, in `--acc`. `h2.inbox` switches to `--warn` (L437-L438).
- **Action row** `.acts` (L464-L465): 11.5 px buttons. A picked button turns solid `--good` (L466). An armed button turns solid `--bad` (L467).

### Status colours

| Token pair | Used for |
|---|---|
| `--warn` / `--warn-s` | pills `draft`, `candidate`; `tagO` (NEEDS REVIEW); count badges `warn`/`amber` |
| `--info` / `--info-s` | pills `verified`, `ready`; `P2`; the health strip; `.runs` |
| `--good` / `--good-s` | pill `active`; `STEP`; "success" buttons; `.callers` |
| `--bad` / `--bad-s` | pill `merge`; `P1`; `tagB` (BLOCKED, ≥7-day merge escalation); danger buttons; stale warnings |
| `--line-2` / `--muted` | pills `paused`, `retired`, `parked`; `P3`; the lane pill (Recipe/Cadence uses `pill-parked`) |

The pill rules are at L505-L515 and the priority rules at L457.

`--deep` / `--deep-ink` fill the `#N` badge (L459), the selected domain chip (L421), the selected Skills view and drawer option (L487, L599) and the toast (L503).

**Colours hard-coded outside the tokens. These do not follow the theme:**
- `#dc2626` for the health-strip warnings (L829, L830).
- `#16a34a` for "✓ No failed writes" (L830).
- `#94a3b8` for the session label (L831) and the memo meta line (L1418).
- `#ddd` for the Add goal input borders (L1458, L1459).
- `#999` for the pipeline depth text (L1750).
- `rgba` backdrops and shadows at L516, L517, L580, L602, L608 and L610.

**Dead CSS:**
- `.tagP` (L463) is defined but never used.
- `.tl-txt` is used in JS (L978) but has no rule.

### Fixed overlays

| Element | Position | z-index | Size |
|---|---|---|---|
| `.toast` | `fixed`, bottom 16 / right 16 | 10000 | `max-width:min(520px,80vw)` (L503) |
| `#copyModal` | `fixed`, inset 0 | 9999 | box `min(560px,92vw)` (L516-L517) |
| `.drawer` | `fixed`, inset 0 | 9998 | pane `min(360px,100%)` (L580-L582) |
| `.pal` | `fixed`, inset 0, top padding 12vh | **60** | box `min(520px,92vw)` (L608-L610) |
| `.moremenu` | `absolute` | 9999 | — (L602) |

### The single `@media (max-width:640px)` block, verbatim (L412-L417)
```css
  @media (max-width:640px){
    :root[data-layout="rail"] .rail { width:52px; padding:10px 6px; }
    :root[data-layout="rail"] .rail .tab span.t, :root[data-layout="rail"] .rail .rgrp, :root[data-layout="rail"] .rail .tab .ct { display:none; }
    :root[data-layout="rail"] .rail .tab { justify-content:center; padding:9px 0; }
    :root[data-layout="rail"] .rail .more { font-size:10px; padding:3px 4px; }
  }
```
It changes **only the rail layout**: 52 px wide, icons only, with labels, group headings and count badges hidden.

No media query targets any of these: the header, the quick-capture row, the health strip, the top-tab strip, the chips, the cards, the Home grid, the drawer, the palette or the Dreams tables. They adapt only through `flex-wrap` (L374, L386, L419, L464, L474), `auto-fit` grids (L555, L571), `min()` widths (L503, L517, L582, L610) and `overflow-x:auto` (L394). The only other media query is the colour-scheme one at L347.

### Phone fit at 390 px (**Measured**; synthetic data, fallback fonts)

**Vertical chrome**
- The header wraps into **3 rows, 124 px** tall: title / capture row / Jump · Dark · Customize.
- The health strip wraps into about 4 rows, **127 px**.
- `main` therefore starts at **y = 261**, 31% of an 844 px screen, before any content.

**Rail layout (the default)**
- The 52 px icon rail leaves **280 px** of content width. The Home grid becomes 1 column of 280 px, fitting its 270 px minimum with **10 px** to spare.
- Tab labels and count badges are hidden.
- Measured target sizes: rail tab **39×32**, domain chip **73×24**, card action button **75×22**, "move…" select **156×30** (CSS px).

**Top-tab layout:** 332 px of content width. The tab strip is **758 px** wide and scrolls horizontally.

**What does not fit at 390 px**
1. **Quick-capture row** (`#capture`, L376: `display:flex`, no wrap, `min-width:260px`).
   - The input never shrank below about **198-206 px** (flex `min-width:auto`).
   - `#capDom` is as wide as its **longest domain label**. That can be a user rename of up to 40 code points (L1278 uses `domLabel`).
   - Short labels (Health/CSSI/Infra/Money): input 206 + select 80 + Queue 60 = 358 px. **Fits.**
   - A 21-character label ("CSSI Cost Segregation"): the select grows to 172 px, **the Queue button ends at 458 px, and the page scrolls horizontally by 68 px**. That happens on every tab, because the header is always visible.
   - At **360 px** the page overflows by 6 px even with the short labels.
2. **Top-tab strip.** It needs horizontal scrolling, but each `.tab` has `touch-action:none` (L395), so on a touchscreen a swipe that starts on a tab cannot pan the strip (see §12).
3. **Home grid at 360 px in rail layout.** The content box is 250 px but each column's minimum is 270 px, so the grid overflows its box by 20 px.
4. **Fixed minimum widths to review:**
   - `#capture` `min-width:260px` (L376);
   - the Add goal inputs `min-width:160px` / `200px` (L1458-L1459; they wrap, which is acceptable);
   - rollup domain label `min-width:100px` (L470);
   - Home domain label `min-width:92px` (L2323);
   - `.moremenu` `min-width:160px` (L602);
   - rail 176 px above 640 px wide (L390);
   - drawer pane 360 px, which leaves only a 30 px strip of backdrop to tap-close at 390 (L582).
5. **Text that relies on hover.** Ellipsized widget rows (`.wl`, L567) and ellipsized drawer names (`.tl .t`, L590) reveal the full text only through a `title` tooltip. Several hover styles have no touch equivalent.

---

## 9. TERMINOLOGY (user-facing strings, verbatim)

In this section `<n>`, `<N>` and `<…>` stand for values the page interpolates.

### App and header
- **Tab title:** "Minds Over Matters" (L319, L845). **Header:** "🧠 Minds Over Matters" (L622). **Artifact name:** "Brain Dashboard" (L3).
- **Quick-capture placeholder:** "Quick capture — what's on your mind?" (L624). **Button:** "Queue" (L626).
- **"Jump" button:** keyboard hint "Ctrl K"; tooltip "Jump — search tabs, domains, goals, actions (Ctrl+K)" (L628).
- **Theme button:** "Dark" in light mode, "Light" in dark mode (L978); tooltip "Switch between white and dark background" (L629).
- **"Customize"** (L630).

### Health strip (L824-L831)
- "🔁 Loops: **N**"
- "🌱 Saved for Later: **N** open · **N** merge-pending"
- "📝 Last write: <date>"
- "🗒 Memos: **N**"
- "⚠ N unparented row(s) — a /deploy wave skipped its goal_meta upsert"
- "⚠ N failed write(s)" or "✓ No failed writes"
- "Session: <id>"
- Before the data loads: "Loading brain stats…" (L632).

### Footer
- "loaded <local time>" (L813)
- "<n> queued" (L1279)
- "⏸ Pause automation" or "▶ Resume automation" (L1281)

### Tabs, groups and the More menu
- **Tabs:** Home · Goals · Saved for Later · Parked · Loops · Skills · Dreams
- **Groups:** Work · Later · System
- **Overflow:** "More (N)"; when nothing is hidden, "nothing hidden"
- **Tooltip suffixes:** " — pinned first; double-click or F2 to rename", " — drag to move, double-click or F2 to rename", ' (originally "<name>")'

### Home (L878-L884, L2294-L2400)

**Widget titles:** Needs your click · Top item per domain · Inbox · Ready to claim · Brain health · Quick actions · Dream readiness

**Needs your click**
- "pending confirmations — #N is DB-assigned (row_number over created_at, id), the same number /close prints"
- Row button: "tick"
- More rows: "… N more — the full numbered list prints at /close."
- Empty: "nothing waiting on you"
- Loading: "reading the tracker…"

**Inbox**
- "queued goals waiting for triage"
- More rows: "… N more in Goals."
- Empty: "inbox zero"

**Ready to claim**
- "saved-for-later items you can pick up now · N draft(s) await promotion"
- More rows: "… N more on Saved for Later."
- Empty: "nothing claimable right now"

**Brain health tiles:** failed writes · unparented · loops · saved open · merge-pending · memos · skills. Below them: "last write <d> · session <id>".

**Quick actions**
- "Prompt-only (ruling B-R4): every button copies a ready prompt — nothing runs from Home."
- Empty: "no prompt-type quick actions defined"

**Dream readiness**
- "threshold <t> (page default) · last run <ts> · <n> unreviewed"
- "Aggregates only (ruling B-R6) — proposal contents render on the Dreams tab, never here."
- Button: "Open Dreams"

**Home page-level**
- Footnote: "Drag a card by its ⋮ handle to rearrange; × hides it. Order and visibility save to the same dashboard_prefs row."
- "Hidden: …"
- "every widget is hidden — bring them back below or in Customize."
- Error: "Home extras unreachable — <msg> Retry"

### Goals

**Chips**
- "MOM" (the pinned chip, with the brain icon)
- "+ tab", then "new tab name, Enter copies"
- "Reset tabs" (tooltip: "Back to the default order and names (click twice to confirm)")
- "on deck"

**Rollup (the MOM chip)**
- Heading: "Executive view — top item per life category"
- Row: "<domain> <P#> <title> — <next action (140 chars)>" plus "📥<n>" and "⚠ <n>d idle"
- Empty row: "nothing active" / "no goals yet"

**Domain board**
- "Evaluate & clean up": "Opens a chat that checks every goal in this area and asks before parking, closing or dropping anything."
- Quick actions: "⚡ <label>"
- Sections: "📥 Inbox (N)", "Active (N)", "Blocked (N)", "Done (N)" (collapsed), "🗒 Context memos (N)"
- Memo rows: suffix " · standalone" / " · permanent"
- Empty section: "nothing active"
- "Add goal" form: placeholders "title" / "next action"; priority options P1/P2/P3; button "Add to <slug>"

**Goal card**
- Priority pill: "P1" / "P2" / "P3" (default P2)
- Tags: "BLOCKED", "NEEDS REVIEW"
- Meta line: "<project> · <goal_id> · <Mon DD>"
- Buttons: "💬 Pick up", "▶ Activate", "🅿 Park", "✔ Done", "▶ Unblock", "▶ Unpark", "▶ Reopen", "🗑 Delete", and the select "move…" with options "→ <domain>"
- Drill-in: "loading…", "no task rows yet", rows "[w<wave>·<key>·<status>] <json>"

### Saved for Later (L1566-L1619)
- "Evaluate & clean up": "Opens a chat that checks every saved item and asks before closing or dropping anything."
- Note: "#N badges are assigned by the database (row_number() OVER (ORDER BY created_at, spinoff_id)) — the same numbering the Pending confirmations tracker and the numbered /close list use."
- **Sections:**
  - "⚠ Merge Pending (N)"
  - "Ready to Claim (N)"
  - "Active (N)"
  - "📋 Draft — captured at close, not claimable yet (N)", with the note "/open-spin only claims **ready** rows, so these stay invisible until promoted."
- Parked note: "N parked — see the Parked tab."
- **Card**
  - Badge "#<n>" (tooltip: "DB-assigned badge — matches the Pending confirmations tracker")
  - Raw status pill (e.g. `merge_pending`)
  - "⚠ <n>d" when merge-pending for 7 days or more
  - Meta: "Skills: … · created YYYY-MM-DD · pending since YYYY-MM-DD"
  - Buttons: "💬 Pick up", "▶ Make ready", "▶ Unpark", "🅿 Park", "🗑 Delete"
- Empty tab: "Nothing saved for later — all clear."

### Parked (L1586-L1595)
- Sections: "Parked goals (N)", "Paused loops (N)", "Parked saved-for-later (N)"
- Empty: "Nothing parked — all clear."

### Loops (L1501-L1533)
- "Evaluate & clean up": "Opens a chat that lists recipes and cadences, checks each one, and asks before retiring anything. Retired loops are hidden here."
- Empty: "No loops yet — run /loop-scout to mine a repeatable workflow."
- **Sections:**
  - "📝 Unproven — awaiting review (N)"
  - "Verified (N)"
  - "Active (N)"
  - "N paused — see the Parked tab."
  - "Retired (N)"
- **Card**
  - Status pill: raw status text
  - Lane pill: "Recipe" / "Cadence"
  - "Skills: …" (or "none recorded"), "Done when: …"
  - Meta: "<scope> v<version> · <id8>… · session: <id>"
  - Buttons: "💬 Pick up", "✅ Verify & Promote", "🅿 Park" / "▶ Resume", "🗑 Delete"

### Skills (L1656-L1789)
- View toggle: "Buckets" | "Pipelines"
- Search placeholder: "Search skills, triggers, descriptions…"
- Badges: "RUNS <n>", "STEP"
- Card lines: "runs:" / "runs inside:" / "triggers: … · works with: …"
- **Pipelines**
  - Header: "<n> skill(s) deep"
  - Node notes: "(no catalog row)", "(loops back — not expanded)", "(shown above in this pipeline)"
  - "Standalone — runs nothing, run by nothing" with "These fire on their own and do not appear inside another skill's procedure."
- Empty: "no pipeline matches", "no match"
- Extra group: "Uncategorized"
- Bucket keys, labels and blurbs, verbatim:
```js
const BUCKET_ORDER = ['session','brain','orchestration','planning','execution','style','documents',
                      'skillforge','audit','maintenance','release','cssi','marketing','onboarding','retired'];
const BUCKET_LABEL = {
  session:'Session Lifecycle', brain:'Goals & Memory', orchestration:'Orchestration & Scheduling',
  planning:'Planning & Second Opinion', execution:'Execution & Web', style:'Reply Style & Delivery',
  documents:'Documents & Assets', skillforge:'Skill Forge', audit:'Audit & Review',
  maintenance:'Backup & Recovery', release:'Product Release', cssi:'CSSI Pipeline',
  marketing:'MOM Marketing', onboarding:'Getting Started', retired:'Retired / Not Installed'
};
// One-line orientation per bucket, rendered under the group header in Buckets view when the
// group is open. 15 buckets only help if you can tell at a glance which one you want.
const BUCKET_BLURB = {
  session:'Opening, saving and closing a work session.',
  brain:'The goal board, workflow memory and deferred work.',
  orchestration:'Splitting work across agents and running things on a timer.',
  planning:'Scoping a task before building, and sanity-checking it after.',
  execution:'Doing the thing — browser, web, email, manual-step tracking.',
  style:'How Claude talks back and hands you the result.',
  documents:'Producing files and visual assets.',
  skillforge:'Building, packaging and cataloguing the skills themselves.',
  audit:'Checking the system against reality and scoring what it finds.',
  maintenance:'Backups, cleanup and unbreaking things.',
  release:'Cutting and shipping a product version.',
  cssi:'The cost-seg sales pipeline, lead to sent email.',
  marketing:'Minds Over Matters promotion and posting.',
  onboarding:'First-run setup.',
  retired:'Catalog rows kept for history — not currently installed.'
};
```

### Dreams (L2072-L2210)
- Intro: "Nightly Lane M receipts and its proposal inbox. Every pane is a query; no button on this tab writes to the brain — the Review buttons copy a line for Claude Code, which evaluates and brings back a recommendation for you to rule on."
- Button: "↻ Refresh dreams"
- **Panes:**
  - "Readiness"
  - "Inbox — <n> unreviewed" (or "count unavailable")
  - "Diff — <n> unreviewed" (or "the newest 100")
  - "Graph"
- **Buttons**
  - "🧠 Review this one (Claude evaluates)"
  - "🔍 Show this diff in chat"
  - "🧠 Review the whole inbox (<n>) — Claude evaluates, you rule"
  - "🧠 Review the whole inbox in chat"
- Health lines: "✓ last run <h>h ago, ok=true" or "⚠ <reason>"
- Loading and errors: "Reading the dream receipts…", "Dreams unreachable — <msg>. Retry"

### Customize drawer (L660-L669)
- Title: "Customize"
- Sections:
  - "Tabs — drag to reorder, Hide to tuck away"
  - "Home widgets — drag to reorder, Hide to tuck away"
  - "Layout": Side rail / Top tabs
  - "Theme": White / Dark / Follow system
  - "Accent": Purple / Harbor / Ember / Moss
  - "Density": Comfortable / Compact
  - "Dashboard title"
- Row buttons: "Rename", "↑", "↓", "Hide" / "Show"
- Renamed rows: "was <orig>"

### Jump palette (L676, L2452-L2483)
- Placeholder: "Jump to a tab, domain, goal, or action…"
- Item kinds: "tab", "hidden tab", "domain", "goal · <domain>", "action", "quick action"
- Fixed actions: "Customize dashboard", "Toggle dark theme"
- Domain items: "<label> goals"
- Empty: "no matches"

### Copy, confirm and receipts
- Armed button label: "confirm?"
- Copy receipts: "Copied ✓" / "Copy FAILED"
- Copy modal: "Copy this prompt, then paste it into a new chat", with buttons "Select & copy" and "Close"
- Show more toggle: "Show more" / "Show less"

### Toasts (complete list)

**Writes and data**

| Line | Toast |
|---|---|
| L760 | "⚠ write REJECTED by the database — nothing was saved. <pg error>" |
| L936 | "dashboard_prefs unreachable — using defaults; customization will not persist this session" |
| L1538 | "Loop not found — reload" |
| L1541 | "✅ Loop promoted to active" |
| L1550 / L1553 / L1561 | "Loop resumed" / "Loop parked" / "Loop deleted (recoverable in DB)" |
| L1627 | "Saved item → <st>" / "Saved item deleted (recoverable in DB)" |
| L1805 | "<goal_id> → <st>" / "<goal_id> deleted (recoverable in DB)" |
| L1806 | "moved to <slug>" |
| L1809 / L1812 | "title required" / "added" |
| L1820 | "queued to <slug>" |
| L1835 | "running: <label>" / "task launch failed" |
| L1884 | "automation PAUSED" / "automation resumed" |

**Copy and chat hand-off**

| Line | Toast |
|---|---|
| L1836, L2271 | "prompt copied" |
| L651 | "copied" |
| L1856-L1857 | "💬 Opening chat…" |
| L1858 | "📋 Prompt copied — paste into a new chat" |
| L2002, L2005 | "copied → paste into Claude Code:  <text>" (two spaces) |

**Customization**

| Line | Toast |
|---|---|
| L986 | "Dark background" / "White background" |
| L1213 | "Goals tab order saved" |
| L1215, L1217 | "MOM stays pinned first" (uses the chip's current name) |
| L1238 | 'Renamed to "<v>" (lookups still use <slug\|the overview>)' / 'Name reset to "<default>"' |
| L1262 | "Type a name for the new tab first; nothing was copied" |
| L1272 | "Goals tabs reset to the default order and names" |
| L1353 | 'Renamed to "<v>" (key stays <key>)' / "Name reset" |
| L1364, L2290 | "Home stays pinned first" |
| L2290 | "Tab order saved" |
| L2433 | "Home layout saved" |

### Status vocabulary the code knows
- **Goals:** `queued`, `queued-unreviewed`, `active`, `blocked`, `parked`, `done`, `deleted` (excluded from loads).
- **Loops:** `candidate`, `draft`, `verified`, `active`, `paused`, `retired`, `deleted`. The last two are excluded from loads.
- **Spinoffs:** `draft`, `ready`, `active`, `merge_pending`, `parked`, `deleted`.
- **pending_confirmations:** `pending`.
- **dream_proposals.verdict:** `null`, displayed as "unreviewed".

---

## 10. HARD-CODED PERSONAL / ENVIRONMENT VALUES

Legend: **exec** means the value is used by running code or appears in a rendered or sent string; **comment** means it appears only in comments.

**Values that would have to become configuration for another user**

| Value | Where | Kind |
|---|---|---|
| Supabase project id `<brain-project-ref>` | L682 (`const P`, sent with **every** query); also inside the three cleanup prompts L1469, L1481, L1492 | exec |
| MCP tool id `mcp__<mcp-tool-id>__execute_sql` | L682 (`const TOOL`); artifact meta L7; server name `"Supabase"` L10 | exec / meta |
| Product name "Minds Over Matters" | `<title>` L319, `h1` L622, `TITLE_DEFAULT` L845 (can be overridden by `prefs.title`) | exec |
| "Brain Dashboard" and the long description | artifact meta L3, L5 | meta |
| Font CDN URL | L320 | exec |
| Domain slug **`business`**, hidden as a catch-all | L1145, L1201, L1278 (but **not** L1646) | exec |
| Overview sentinel **`TAB='mom'`** | L684, L1149, L1169, L1432. If `public.domains` ever holds `domain='mom'`, its chip would set `TAB='mom'` and show the rollup instead of its board, and both chips would appear selected (L1151). | exec |
| Pinned-chip prefs key `'__all__'` and default label **"MOM"** | L1040-L1041 | exec |
| `quick_actions.domain='all'`, meaning the action appears on every board | L1446 | exec |
| `goal_id 'system'` excluded from the orphan count | L800 | exec |
| `agent='dashboard'` | L1811, L1819, L1823 | exec |
| Default next actions: 'define next action', 'queued via MOM dashboard — awaiting drain' | L1811, L1819 | exec |
| Flag `system_paused` | L810, L1884 | exec |
| Skill taxonomy: 15 buckets with labels and blurbs, including the personal business buckets `cssi` ("CSSI Pipeline", "The cost-seg sales pipeline, lead to sent email.") and `marketing` ("MOM Marketing", "Minds Over Matters promotion and posting.") | L698-L725 | exec |
| Cleanup-prompt assumptions: `memory.md` sections 'Kept active on purpose' and 'Parked - not for a reaper pass'; "INSTALLED skills folder on disk"; `brain_meta.cache_bust`; the "One writer chat rule" | L1467-L1500 | exec (prompt text) |
| Governance and process words shown to the user: "ruling B-R4", "ruling B-R6", "Lane M", "Lane S", "Phase 1/2", "spec §6", "Neo4j … graph_last_sync", "/close", "/open-spin", "/loop-scout", "/deploy", "Claude Code" | L2366, L2383, L2077, L2096, L2099-L2104, L2196, L2207, L1503, L1580, L829, L2306, L2002 | exec (UI text) |
| Host-UI reference "Hit Reload (top of panel)" | L814 | exec |

**Schema assumptions the code makes**

| Value | Where | Kind |
|---|---|---|
| `deploy_memory` key conventions: `goal_meta`, `task`, `summary`, `audit`, `context`, `context_%`, `scout_flag` | L772, L797, L800, L1823, L1829 | exec |
| `system_cache` keys: `dashboard_prefs`, `brain_meta`, `current_session_id`, `dream_readiness`, `dream_last_run`, `dream_runs`, `dashboard_last_publish` | §3 | exec |
| Tables read or written: `domains`, `deploy_memory`, `quick_actions`, `skill_catalog`, `loops`, `spinoffs`, `system_cache`, `system_flags`, `pending_confirmations`, `dream_proposals`, `brain_edges` (all in `public`) | §3, §4 | exec |

**Tuning numbers**

| Setting | Value | Where |
|---|---|---|
| Goal staleness | 14 days | L1438, L2321 |
| Merge-pending escalation | 7 days | L1603 |
| Dream-run staleness | 48 h | L1983 |
| Dream threshold default | 60 | L1908 |
| Row limits: loops / memos / proposals | 50 / 300 / 100 | L785, L797, L1952 |
| Home row caps | 6 / 5 / 5 | L2307, L2332, L2343 |
| Palette results | 9 | L2468 |
| `arm()` window | 3,500 ms | L1801 |
| Prefs save debounce | 600 ms | L967 |
| Text clamp | 180 characters | L753 |
| Rollup next-action cut | 140 characters | L1439 |
| Name caps: top tab / chip / title | 24 / 40 / 40 | L1042-L1043, L923 |

**Locale and time behaviour**
- `goal_id` date prefix uses UTC (`toISOString`, L1810, L1817).
- Displayed dates and times use the device locale (`toLocaleTimeString` / `toLocaleDateString`, L813, L821, L2351).
- The server formats dates as `Mon DD` (`to_char`, L772, L797, L2251).

**Personal values that are *not* in running code**

| Value | Where | Kind |
|---|---|---|
| Personal name "Dustan" | **Comments only**: L160, L161, L167, L173, L174, L230, L451, L784, L1465, L1892, L2011. It never appears in rendered text or in prompts. | comment |
| Emails | None anywhere | — |
| Session ids | None hard-coded; the current one is read from `system_cache.current_session_id` (L806-L808) | — |
| File paths | `1 BRAIN/Specs & Setup/…` (L16, L78, L168), `Executive Function/docs/corp_skill_manifest.json` (L73), `tests/real_input_cdp.mjs` (L1175), `MANIFEST.txt` (L243), `dashboard-template.html` (L234) | comment |

---

## 11. REUSE ASSESSMENT

**A. Pure functions: no DOM, no I/O. They can be shared unchanged, for example as a JS module in a WebView build or as a reference for a Kotlin port.**
- **The v3.4 goal-tab block** (L1036-L1142), which the file itself says is extracted and tested in node (L1037):
  - constants `DOM_ALL_KEY`, `DOM_ALL_DEFAULT`, `DOM_LABEL_MAX`, `TAB_LABEL_MAX`;
  - `domLabelClean`, `capCodePoints`, `domKeyOk`, `domOrderClean`, `domLabelsClean`, `domDefaultLabel`, `domLabelOf`, `orderDomains`, `goalChips`, `domSubsetOrder`, `domMove`, `domOrderWithStale`.
- **Other pure helpers:**
  - `pinFirst` (L889), `lit` (L755), `daysAgo` (L764, uses `Date.now()`), `byStatus` (L1632), `skMatch` (L1677), `skSubtreeNames` (L1730), `jparse` (L1913), `isUuid` (L2009);
  - `parse` (L733), which is pure given the bridge's result shape.
- **Prompt builders** (pure strings): `reconcileLoopsPrompt` (L1467), `cleanupSavedPrompt` (L1479), `cleanupGoalsPrompt` (L1490). They embed the project id and `memory.md`.
- **Static data:** `BUCKET_ORDER` / `BUCKET_LABEL` / `BUCKET_BLURB` (L698-L725), `HOME_DEF` (L877), `PREFS_DEFAULTS` (L892), `TABS_DEF` (L863; its `ct` closures read globals), `DREAM_THRESHOLD_DEFAULT` (L1908), and the SVG icons (L849-L860).
- **Pure except that they read globals** (easy to parameterize):
  - `mergePrefs` (L900-L927, writes `PREFS` and `PREFS_RAW`) and the merge half of `savePrefs` (L945-L962);
  - `skGraph` (L1664, reads `SKILLS`) and `dreamHealth` (L1969, reads `DREAM.lastRun`);
  - the three Pick-up prompt strings (L1873, L1877, L1882);
  - the rollup maths, which is **duplicated** in `render` (L1433-L1441) and in Home top-per-domain (L2316-L2325).

**B. Functions that return HTML strings.** They need `document` only for `esc()`. They can be reused unchanged inside a WebView but not by a native UI. Their output contains inline `onclick="…"` strings that call global functions.
- `esc`, `attrEsc`, `clampy`, `clTog`, `pri`, `tabBtn`;
- `card`, `loopCard`, `spinoffCard`, `memosBlock`, `skillRow`, `renderBucketsView`, `skTreeNode`, `renderPipelinesView`;
- `dreamLineDiff`, `dreamJsonDiff`, `dreamReadinessPane`, `dreamInboxPane`, `dreamDiffPane`, `dreamGraphPane`, `dreamVerdictBtns`, `dreamReviewAllBtn`;
- `homeWidget`.

**C. Coupled to the Cowork bridge (`window.cowork`).** A phone build must replace these.
- **`callMcpTool`:** `q` (L732), and therefore `sql` (L740) and every loader and writer:
  - loaders: `loadAll` (L766), `loadPrefs` (L928), `savePrefs` (L940/L966), `drill` (L1824), `loadDreams` (L1919), `loadHome` (L2228);
  - writers: `setStatus` (L1805), `setDomain` (L1806), `addGoal` (L1807), `capture` (L1814), `audit` (L1823), `verifyPromote` (L1535), `toggleLoop` (L1545), `delLoop` (L1559), `setSpin` (L1625), `togglePause` (L1884).
- **`sendPrompt`:** `sendToChat` (L1855).
- **`runScheduledTask`:** `runQA` (L1833).
- **Chat and hand-off assumptions:** every prompt tells a *chat* to query Supabase, so a phone build needs an equivalent destination for these prompts.

**D. Stateful UI glue.** It works as-is in a WebView and would be rewritten natively.
- Renderers: `render`, `renderHome`, `renderLoops`, `renderSpinoffs`, `renderParked`, `renderSkillsTab`, `renderDreams`, `renderNav`, `renderGoalsChips`, `renderChrome`, `renderHealthRow`, `renderDrawer`.
- Theme and navigation: `applyAttrs`, `toggleTheme`, `setMainTab`, `setDom`, `homeGoDom`.
- Confirm, feedback and copy: `arm`, `toast`, `wfail`, `copyText`, `showCopyModal`, `dreamCopy`, `togglePickup`.
- Menus and panels: `openMore`/`closeMore`, `drawerOpen`/`drawerClose`, `palOpen`/`palClose`/`renderPal`/`palItems`.

**E. Desktop-only: keyboard, precise pointer drag, double-click and hover**
- **Keyboard:** `onKey` (L2501), `moveFocusedTab` (L2491), the palette's key handling (L2533-L2539), and the F2 and double-click handlers (L1018-L1019, L1171-L1181, L1195).
- **Rename entry points:** `renameTab` (L1341) and `renameDom` (L1222) are reached through double-click or F2. The only other way in is the drawer's "Rename" button, and it exists **only for top tabs**. Domain chips have no non-keyboard rename.
- **Chip reordering:** only by drag or Alt+←/→. There are no arrow buttons for chips, unlike the drawer lists.
- **Pointer drag:** `makeSortable` (L1304) and `makeWidgetSortable` (L2407). They use Pointer Events, so touch is technically possible, but see §12.
- **Desktop-only hint:** `.jkbd` "Ctrl K" (L628).

---

## 12. RISKS for a WebView port

Each risk below gives the risk itself, the evidence in the file, and what a port has to do about it.

### Interaction

**1. Pointer drag starts instantly and blocks scrolling.**
- **Evidence:**
  - `makeSortable` (L1304-L1338) starts a drag on **any** `pointerdown` on a `.tab`, `.dchip` or `.tl` row. There is no long-press and no movement threshold.
  - It calls `setPointerCapture` (L1310), reorders live with `elementFromPoint` (L1314) and swallows the next click for 250 ms (L1328, L1014, L1166).
  - `touch-action:none` is set on `.tab` (L395), `nav .dchip` (L429), `.wh .h` (L561) and `.tl` (L587).
- **What this means:** by CSS semantics, a touch that *starts* on one of those elements is never handed to the browser for panning. This was not tested with a real touch device.
  - The overflowing top-tab strip (758 px of tabs in 390) cannot be swiped where the tabs are, and the strip is almost entirely tabs.
  - In the drawer (`overflow:auto` pane), vertical scrolling that starts on a row is blocked.
  - Vertical page scroll that starts on a Goals chip is blocked.
  - Home cards drag from the ⋮ handle only (L2412), so Home scrolls normally.
- **Port:** add a long-press activation or a drag threshold, remove `touch-action:none` from scroll containers' children, and keep the handle-only pattern.

**2. Several features are keyboard-only.**
- **Evidence:** `onKey` (L2501-L2513) handles Ctrl/Cmd+K, Alt+←/→ and 1-9. F2 renames (L1019, L1181). Alt+←/→ on a chip moves it (L1182-L1186).
- **Port:** the Jump palette also has a button (L628). Top-tab rename and move, and widget move, have drawer buttons (L1380-L1384, L1405-L1407). **Chip rename and chip move have no non-keyboard path other than double-click and drag.** Add buttons, or a long-press menu, for chips.

**3. Rename relies on double-click.**
- **Evidence:** double-click is the main rename gesture (L1018, L1171). The chip click handler ignores `e.detail>1` (L1167, L1192), and double-click targeting uses a 1 s `_domClick` window (L1176).
- **Port:** whether Android WebView delivers a double-tap as `dblclick` / `detail` was not tested. Do not rely on double-tap.

**4. There are no native dialogs, but `arm()` is fragile.**
- **Evidence:** `prompt()`, `confirm()` and `alert()` occur **0 times**. Confirmation is done in-page by `arm()` (L1794-L1803), which swaps `textContent`.
- **Measured:** this empties the "move…" `<select>` (L1652), so reassigning a domain is unreachable.
- **Port:** use a confirm pattern that does not overwrite element content, such as a snackbar with Undo, or a dialog.

**5. Clipboard.**
- **Evidence:**
  - `copyText` (L1839-L1848) tries `navigator.clipboard.writeText` first. That needs a secure context and whatever permissions the host grants.
  - It then falls back to `execCommand('copy')` on a fixed, opacity-0 textarea that it `focus()`es and that is **not read-only** (L1842-L1844).
  - `dreamCopy` (L1992-L2008) uses `execCommand` first, on the read-only `#dreamCopySrc` (L657), and falls back to the clipboard API.
  - The modal's "Select & copy" also uses `execCommand` (L651).
  - Every path ends in the manual-copy modal when both methods fail (L1859, L2006-L2007, L1836).
- **Port:** `execCommand('copy')` is deprecated. Focusing an editable field on a touch device may raise the soft keyboard; this was not tested. Prefer a native clipboard bridge.

### Host bridge

**6. `window.cowork.runScheduledTask`.**
- **Evidence:** called only in `runQA` (L1835), from the ⚡ buttons on Goals domain boards for `kind='task'` actions (L1451). Home and the palette never call it (L2270, L2466).
- **Port:** the phone host must provide it, hide task actions, or route them some other way.

**7. `callMcpTool` and `sendPrompt` are the only data and hand-off paths.**
- **Evidence:** all data flows through `callMcpTool` (L732). Chat hand-off uses `sendPrompt` (L1856). `sql()` / `parse()` expect `isError`, `content[0].text` and `structuredContent.result` (L733-L746). The artifact meta declares the tool (L6-L11).
- **Port:** this is the core job. There is no key and no other network path in the page (comment L1895).

### Layout

**8. Fixed overlays and the soft keyboard.**
- **Evidence:** the toast, copy modal, drawer and palette are `position:fixed` (L503, L516, L580, L608), and so is `copyText`'s temporary textarea (L1843). The palette focuses its input on open (L2474), as do the rename inputs (L1229, L1346) and "+ tab" (L1255). The More menu is positioned from `getBoundingClientRect` + `scrollY`, clamped to `innerWidth-180` (L1293-L1296).
- **Port:** test with the soft keyboard open. The palette's z-index (60) sits below the other overlays (L608).

**9. Widths and touch targets.**
- **Measured:**
  - The quick-capture row overflows the page: 68 px at 390 with a 21-character domain label, and 6 px at 360 even with short labels.
  - The Home grid minimum (`minmax(270px,1fr)`, L555) overflows at 360 in rail layout.
  - The top-tab strip needs horizontal scrolling.
  - Header plus health strip use **261 px** of vertical space.
  - Touch targets are 22-32 px tall.
  - Mobile Chromium widened the layout viewport to 458 px once content overflowed (`innerWidth` 458 vs 390).
- **Port:** give the capture row `flex-wrap` and `min-width:0`, collapse the health strip, use 48 dp targets, and provide a bottom nav in place of the 52 px rail.

**10. Information hidden behind hover.**
- **Evidence:** full text behind ellipses is only in `title` tooltips (L2308, L2333, L2345, L590), as are renamed originals (L1002, L1152) and control explanations (L1160, L1161). There are also `:hover` styles (L397, L570, L563).
- **Port:** show this content on tap instead.

### Data flow

**11. No refresh control.**
- **Evidence:** `loadAll` runs only at boot and after writes. The error text points to a host "Reload" (L814).
- **Measured:** 13-14 queries at boot, and about 10-13 after every write.
- **Port:** add pull-to-refresh. Consider batching queries or narrowing the reload after a write.

**12. Content Security Policy.**
- **Evidence:** the page has one inline `<script>` (L681), and the source contains 45 `onclick=`, 2 `onchange=`, 1 `oninput=` and 1 `onkeydown=`.
- **Port:** this is incompatible with any CSP that forbids inline script or handlers.

**13. Handler strings are built from data.**
- **Evidence:**
  - Goal ids go **raw** into `onclick` JS (L1638-L1652, L1648, L1651).
  - Loop and spinoff ids go through `lit()` (L1527-L1530, L1611-L1616), which is SQL escaping, not JS escaping.
  - Slugs go raw into `setDom('…')` (L1440) and `homeGoDom('…')` (L2323, L2332).
  - Only Dreams checks ids with `isUuid()` (L2015).
- **Port:** a quote in an id or slug would break the handler. The page's own ids are `[a-z0-9-]` (L1810), but rows from other writers are not constrained. Use `addEventListener` with data attributes.

### Platform

**14. External fonts.**
- **Evidence:** Google Fonts is loaded (L320); Plex Mono is loaded but unused.
- **Port:** offline, text falls back to the generic `sans-serif`. Bundle the fonts.

**15. System theme.**
- **Evidence:** `theme='system'` follows `prefers-color-scheme` (L972, L988). The page declares `color-scheme` (L331, L349, L361).
- **Port:** the WebView host decides what `prefers-color-scheme` reports. Verify it.

**16. Viewport and zoom.**
- **Evidence:** `width=device-width,initial-scale=1` (L318), with no zoom limits.
- **Port:** once a row overflows, the page zooms out or pans.

**17. Emoji glyphs.**
- **Evidence:** status and action buttons use emoji prefixes such as 🅿 (U+1F17F), 🗑, ▶, ✔ and ⚡.
- **Port:** the glyphs depend on the device's emoji font.

### SQL quirks

These matter if the port reuses the SQL.

**18. Quirks in the write paths.**
- **Evidence:**
  - `togglePause` flips its state before the write (L1884).
  - `audit()` swallows errors (L1823).
  - Capture toasts success even when `ON CONFLICT DO NOTHING` drops the row (L1819-L1820).
  - `setDomain` has no `key` filter (L1806).
  - `setStatus`'s status value is not escaped (L1805).
  - `drill()` has no cache-bust nonce (L1829).
- **Port:** fix these in any shared data layer.

---

## Appendix A: the three "Evaluate & clean up" prompts, verbatim (L1467-L1500)

They are sent through `sendToChat`, the same way as Pick up. They write nothing themselves.
```js
function reconcileLoopsPrompt(){
  return [
    "Reconcile my loops (public.loops, Supabase project <brain-project-ref>). Evaluate first, read-only; write only what I confirm.",
    "1. List every loop where status is distinct from 'deleted', in two groups: DETERMINATE (loop_kind='determinate', recipes) and INDETERMINATE (loop_kind='indeterminate', cadences). Include the retired ones in a short line per group, since the dashboard hides them.",
    "2. For each loop that is NOT retired, show: last_run_at, created_at, number of run-instances ever (deploy_memory rows where value->>'parent_loop_id' = loop_id::text) and how many are live (status in active, queued, blocked), whether run_done_when is set, and its skill_list.",
    "3. Check each skill_list name against the INSTALLED skills folder on disk (not skill_registry, which is frozen) and name any skill that is not installed.",
    "4. Run the self-satisfying template finder: run_done_when like '%now() - interval%' and run_done_when not like '%created_at%'.",
    "5. Verdict per loop, in plain English with the reason: KEEP, FIX (say what), or RETIRE. A loop never run in 30 days with no live turn, or one naming skills I no longer have, is a retire candidate. Never retire a loop that has a live run-instance.",
    "6. Ask me with buttons, recommended option first. Retire = UPDATE public.loops SET is_active=false, status='retired', updated_at=now() ... RETURNING, plus a dated note in evidence. Never delete a row.",
    "One writer chat rule: if another open chat is the brain writer, report only and write nothing."
  ].join("\n");
}
function cleanupSavedPrompt(){
  return [
    "Evaluate and clean up my saved-for-later items (public.spinoffs, Supabase project <brain-project-ref>). Evaluate first, read-only; write only what I confirm.",
    "1. Read the distinct status values in public.spinoffs first, so you use this table's own vocabulary. List every open item (not done, not deleted) grouped by status, oldest first, with its domain, age in days and its done_when.",
    "2. For each: run its done_when check if it has a sql or shell one (already done = close candidate); look for a goal or another saved item that already covers the same work (duplicate = merge or drop candidate); check whether the files or skills it names still exist.",
    "3. Read memory.md's 'Kept active on purpose' and 'Parked' lines first and never propose those.",
    "4. Verdict per item, in plain English with the reason: KEEP, PROMOTE (draft to ready), MERGE INTO (name it), CLOSE AS DONE (evidence-proven only), or DROP AS UNNECESSARY.",
    "5. Ask me with buttons, recommended option first. Apply with a status UPDATE ... RETURNING only. Never delete a row, and never close an item whose check is manual without asking me.",
    "One writer chat rule: if another open chat is the brain writer, report only and write nothing."
  ].join("\n");
}
function cleanupGoalsPrompt(dom){
  return [
    "Evaluate and clean up the goals in my '"+dom+"' area (public.deploy_memory where key='goal_meta' and domain='"+dom+"', Supabase project <brain-project-ref>). Evaluate first, read-only; write only what I confirm.",
    "1. List every goal with status in (open, active, queued, blocked, parked), excluding loop run-instances with the NULL-safe form coalesce(value->>'loop_instance','') <> 'true'. Show title, status, next_action, days since updated_at, and whether the done_when COLUMN is set and its kind.",
    "2. For each: evaluate a sql or shell done_when (proven done = close candidate); flag a goal with no done_when as 'still a thought'; flag duplicates and goals whose next_action points at files, skills or products that no longer exist; count the context_ memos and saved items that hang off it before proposing anything.",
    "3. Read memory.md's 'Kept active on purpose' and 'Parked - not for a reaper pass' lines first and never propose those.",
    "4. Verdict per goal, in plain English with the reason: KEEP, NEEDS A DONE_WHEN (propose one), PARK, CLOSE AS DONE (evidence-proven only), or DROP AS UNNECESSARY.",
    "5. Ask me with buttons, recommended option first. Apply with a status UPDATE ... RETURNING only. Never delete a row, never auto-close a manual check, and bump brain_meta.cache_bust after any close.",
    "One writer chat rule: if another open chat is the brain writer, report only and write nothing."
  ].join("\n");
}
```

## Appendix B: measurement harness (outside the dashboard)

The harness is in `scratchpad/inv-harness/`. It is throwaway and **did not modify the source file**.

| File | What it does |
|---|---|
| `stub.js` | A fake `window.cowork` (`callMcpTool`, `sendPrompt`, `runScheduledTask`). It returns synthetic rows inside the `<untrusted-data-…>` envelope and records every SQL string it receives. |
| `measure.js` | Measures overflow per tab in both layouts at 390×844, and takes the screenshots `shot-*.png`. |
| `capture-probe.js` | Measures the quick-capture row widths with short and long domain labels. |
| `grid360.js` | Measures the Home grid and page overflow at 360 and 390 px. |
| `chrome-probe.js` | Measures the heights of the header and health strip, and the sizes of touch targets. |
| `behavior-probe.js` | Checks `arm()` on the select, Pick up, capture, the two-click Park, `runQA` and the prefs write. |
| `sql-capture.js` / `sql-capture.json` | Captures the exact text of every read and write. |

**Caveats:**
- The browser was Chromium 141 headless, run through Playwright.
- The Google Fonts request failed in the sandbox, so every width uses fallback fonts.
- All data was synthetic.
