# Independent verification: dashboard v3.3 (A) vs v3.4 (B)

A = <scratch>/dash/index-v3.3-live.html
B = <scratch>/dash/index-v3.4-staged.html

Method: read-only. All commands run against the files as they exist on disk; no edits made.

---

## D1 — file stats

Command:
```
sha256sum "$A" "$B"
wc -l -c "$A" "$B"
```
Output:
```
ed7f1c22f8aaebdfe8127a32bf0d5526cc67d0ee580fbe5b5fc141947b3559da  .../index-v3.3-live.html
177a0c5544214b7bc011c830d35dc8fc2d8727b4a4eba831fcd9c5d7731b0e5f  .../index-v3.4-staged.html
  2238 174342 .../index-v3.3-live.html
  2547 197735 .../index-v3.4-staged.html
```
- A sha256 starts `ed7f1c22` — matches.
- A size 174,342 bytes — matches.
- B size 197,735 bytes — matches.
- B lines (wc -l) 2,547 — matches.
- B sha256 starts `177a0c55` — matches.

**Verdict: CONFIRMED** — every sub-value matches exactly.

---

## D2 — external resources

Commands:
```
grep -n 'href=' "$B" | grep -i 'http'
grep -n 'src=' "$B" | grep -i 'http'
grep -n '<script' "$B"
grep -n '<link' "$B"
grep -n 'https\?://' "$B"   # whole-file sweep, not just src=/href=
```
Output:
```
320:<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700&family=IBM+Plex+Sans:wght@400;500;600&family=IBM+Plex+Mono:wght@400;500;600&display=swap">
(src= with http: no output)
1:<!DOCTYPE html><script type="application/json" id="cowork-artifact-meta">
681:<script>
(only one <link>, same as above)
(whole-file https?:// sweep: only line 320, the same one link)
```
- Exactly one `<link rel="stylesheet">`, exactly one external resource, confirmed by a whole-file `http(s)://` sweep (only hit in the entire 2,547-line file).
- No `<script src=...>` — the only two `<script>` tags are the inline JSON-meta block (line 1) and the inline app script (line 681); neither has a `src` attribute.
- No other http(s) URL anywhere in the file.

However, the Google Fonts URL requests **three** font families, not two: `Bricolage+Grotesque`, `IBM+Plex+Sans`, **and `IBM+Plex+Mono`**. The claim states it requests only "Bricolage Grotesque and IBM Plex Sans," omitting IBM Plex Mono.

**Verdict: REFUTED** (partial) — "exactly one external resource / no script src / no other http(s) URL" is true, but the claim's description of the fonts requested is incomplete: the link also loads **IBM Plex Mono**, unmentioned in the claim.

---

## D3 — backend call path / no embedded credentials

Commands and output:
```
grep -n 'callMcpTool' "$B"
  732:function q(s){ return window.cowork.callMcpTool(TOOL,{project_id:P,query:s}); }
  1896:// service_role key at all — every read goes through window.cowork.callMcpTool

grep -n "function q(" "$B"
  732:function q(s){ return window.cowork.callMcpTool(TOOL,{project_id:P,query:s}); }

grep -n "const P" "$B"  (via literal match)
  682:const P='<brain-project-ref>', TOOL='mcp__<mcp-tool-id>__execute_sql';

grep -ni "service_role" "$B"
  1896:// service_role key at all — every read goes through window.cowork.callMcpTool
  1900:// that is the reason to cite. (It also happens to be a member of service_role
  1902:// service_role_only policy too - but do not lean on that.) That is why the

grep -ni "sb_publishable" "$B"   -> no output
grep -n "eyJ" "$B"               -> no output
```
Inspected lines 1885-1905 directly: the `service_role` mentions are all inside a `//`-commented block (an explanatory note about DB role privileges), not used as an object key or a credential value anywhere in executable code. Confirmed only one definition each of `P` and `TOOL` (line 682), and only one executable call site for `callMcpTool` (line 732, inside `q(s)`); the other `callMcpTool` hit (1896) is inside a comment.

**Verdict: CONFIRMED** — call path, constants, and absence of service_role-as-key / sb_publishable / eyJ all verified exactly as claimed.

---

## D4 — SQL verb line counts

Commands:
```
grep -nic "insert into public\." "$B"   -> 4
grep -nic "update public\." "$B"        -> 11
grep -nic "delete from public\." "$B"   -> 0
```
Line numbers for insert: 966, 1811, 1819, 1823.
Line numbers for update: 1475, 1536, 1540, 1548, 1549, 1552, 1560, 1626, 1805, 1806, 1884.

**Verdict: CONFIRMED** — counts are exactly 4 / 11 / 0.

---

## D5 — deploy_memory inserts stamp agent 'dashboard', one is audit(), none is 'desktop'

Command:
```
grep -ni "insert into public\.deploy_memory" "$B"
```
Output (3 lines, all with columns `(goal_id,agent,key,value,status,domain) values ('<id>','dashboard','<key>',...)`):
```
1811: ... values ('${lit(id)}','dashboard','goal_meta', ...)
1819: ... values ('${lit(id)}','dashboard','goal_meta', ...)
1823: async function audit(id,act){ ... values ('${lit(id)}','dashboard','audit', ...) ...}
```
All three literal `insert into public.deploy_memory` statements place the literal string `'dashboard'` in the 2nd value position, aligned with the `agent` column. Line 1823 is inside `function audit(id,act)` and writes `key` = `'audit'`.

```
grep -n "'desktop'" "$B"      -> no output
grep -nic "desktop" "$B"      -> 0
```
`desktop` does not occur anywhere in the file (0 matches, case-insensitive, whole file).

**Verdict: CONFIRMED.**

---

## D6 — localStorage/sessionStorage only in comments

Command:
```
grep -n "localStorage" "$B"
grep -n "sessionStorage" "$B"
```
Output — localStorage (5 hits): lines 35, 111, 222, 683, 1661. sessionStorage: 0 hits.

Checked each localStorage line's context:
- Lines 35, 111, 222 fall inside the file's single HTML header comment, which runs from `<!--` at line 14 to `-->` at line 314 (verified with `grep -n "<!--\|-->" "$B"` → only those two markers in the first 320 lines).
- Line 683: `// [13] In-memory tab state — NO localStorage (not supported in Claude artifacts)` — a `//` line comment immediately after the `<script>` tag (line 681) and the `const P=...,TOOL=...;` line (line 682).
- Line 1661: `let SK_VIEW = 'buckets';   // in-memory only — no localStorage anywhere in this dashboard [13]` — the word appears only after `//`; the executable statement itself (`let SK_VIEW='buckets';`) does not reference localStorage.

**Verdict: CONFIRMED** — every occurrence of "localStorage" is inside a comment; "sessionStorage" does not occur at all (vacuously satisfies the claim).

---

## D7 — sendToChat fallback order; Pick-up functions never write to DB

Command:
```
grep -n "function sendToChat" "$B"   -> 1855
sed -n '1855,1883p' "$B"
```
Body of `sendToChat` (lines 1855-1860):
```js
async function sendToChat(text){
  if(window.cowork && typeof window.cowork.sendPrompt==='function'){ try{ window.cowork.sendPrompt(text); ...; return; }catch(e){} }
  if(typeof sendPrompt==='function'){ try{ sendPrompt(text); ...; return; }catch(e){} }
  if(await copyText(text)){ ...; return; }
  showCopyModal(text);
}
```
Order confirmed: `window.cowork.sendPrompt` → global `sendPrompt` → `copyText(text)` → `showCopyModal(text)`.

`togglePickup` (1862-1868), `pickUp` (1870-1873), `pickUpSpin` (1875-1877), `pickUpLoop` (1879-1882) — read in full; each is defined exactly once in the file (verified via `grep -n "function <name>("`). None contains `sql(` or `q(`; they only call `.find()` on in-memory arrays (`GOALS`, `SPINOFFS`, `LOOPS`) and `sendToChat(...)`.

**Verdict: CONFIRMED.**

---

## D8 — TABS_DEF

Command:
```
grep -n "TABS_DEF" "$B"   -> definition at 863
sed -n '863,872p' "$B"
```
```js
const TABS_DEF = [
  { k:'home',   l:'Home',            g:'Work',   pin:true, ... },
  { k:'goals',  l:'Goals',           g:'Work'   },
  { k:'saved',  l:'Saved for Later', g:'Later',  ... },
  { k:'parked', l:'Parked',          g:'Later',  ... },
  { k:'loops',  l:'Loops',           g:'System', ... },
  { k:'skills', l:'Skills',          g:'System' },
  { k:'dreams', l:'Dreams',          g:'System' }
];
```
7 entries, keys/order/labels/groups all match the claim exactly. Only the `home` entry carries `pin:true`; no other entry has a `pin` property at all.

**Verdict: CONFIRMED.**

---

## D9 — :root tokens, accent overrides, media-query counts

Command:
```
grep -n ":root" "$B"
sed -n '330,345p' "$B"
grep -n "data-accent" "$B"
grep -n "aubergine" "$B"
grep -n "@media" "$B"
```
`:root{ ... }` (lines 330-341) contains, verbatim:
```
color-scheme:light;
--ground:#F6F3F9; --panel:#FFFFFF; --panel-2:#FAF8FC; --ink:#1E1530; --muted:#6F6784;
--line:#E4DEEC; --line-2:#EFEBF4;
--acc:#6366f1; --acc-ink:#FFFFFF; --acc-soft:#E8E9FD; --deep:#2C1A47; --deep-ink:#F4EEF7;
--good:#2E7D4F; --good-s:#E3F2E9; --warn:#A8720F; --warn-s:#FBF0D6; --bad:#B3372B; --bad-s:#FAE3DF;
--info:#2F5FA8; --info-s:#E4ECF9;
--pad:14px; --card-pad:9px 11px; --fs:14px;
--mono:...; --sans:...; --disp:...;
```
The 11 tokens the claim names (`--ground`, `--panel`, `--ink`, `--muted`, `--line`, `--acc`, `--deep`, `--good`, `--warn`, `--bad`, `--info`) do all carry exactly the hex values claimed. **But** `:root` is not limited to those 11 — it also defines `--panel-2`, `--line-2`, `--acc-ink`, `--acc-soft`, `--deep-ink`, `--good-s`, `--warn-s`, `--bad-s`, `--info-s` (9 more color-family tokens) plus `--pad`, `--card-pad`, `--fs`, `--mono`, `--sans`, `--disp` (6 non-color tokens) and `color-scheme:light`. So "the light tokens are **exactly**" the 11 listed is false as an exhaustive statement; it is true only as "these 11 named tokens have these values."

Accent overrides: `grep -n "data-accent"` returns 9 lines, all `harbor`/`ember`/`moss` (light default block 343-345, `prefers-color-scheme:dark` block 356-358, explicit `data-theme="dark"` block 368-370). No `[data-accent="aubergine"]` rule anywhere. `aubergine` itself appears only as a JS/UI string (comment at 103, button `data-v` at 666, `PREFS_DEFAULTS.accent` default at 892, and the allow-list at 905) — never as a CSS attribute selector. So aubergine does fall through to the `:root` default (`--acc:#6366f1`, matching the claim).

Media queries: exactly one `@media (prefers-color-scheme:dark)` (line 347) and exactly one `@media (max-width:640px)` (line 412); no other `@media` block exists in the file.

**Verdict: REFUTED** (partial) — the accent-override and media-query counts are exactly as claimed (CONFIRMED), and each of the 11 named tokens does carry the exact value claimed, but the assertion that these are *exactly* ("only") the light tokens in `:root` is false: `:root` defines at least 15 additional custom properties not mentioned (`--panel-2`, `--line-2`, `--acc-ink`, `--acc-soft`, `--deep-ink`, `--good-s`, `--warn-s`, `--bad-s`, `--info-s`, `--pad`, `--card-pad`, `--fs`, `--mono`, `--sans`, `--disp`).

---

## D10 — runScheduledTask call site; table set; skills_registry-only-in-comments

Commands:
```
grep -n "runScheduledTask" "$B"
grep -noiE "from[[:space:]]+public\.[a-z_]+" "$B" | sed -E 's/^[0-9]+://' | tr 'A-Z' 'a-z' | sort | uniq -c
grep -ni "public\.skill_registry\b" "$B"     -> no output (0 matches, anywhere, any case)
grep -n "public\.skills_registry" "$B"
```
`runScheduledTask` hits: lines 29, 137, 149 (all inside the header HTML comment, 14-314), 1835 (executable: `if(a.kind==='task'&&a.ref){ try{ await window.cowork.runScheduledTask(a.ref); ... } }` inside `function runQA(id)`), 2268 and 2463 (both `//` comments). Exactly one executed call site (1835), gated on `kind==='task'`. **Confirmed.**

`from public.<table>` case-insensitive sweep, deduped:
```
   8 from public.system_cache
   7 from public.deploy_memory
   3 from public.dream_proposals
   2 from public.domains
   1 from public.system_flags
   1 from public.spinoffs
   1 from public.skills_registry   <- line 69 only, inside the header HTML comment (14-314)
   1 from public.skill_catalog
   1 from public.quick_actions
   1 from public.pending_confirmations
   1 from public.loops
   1 from public.brain_edges
```
So the **real** table set actually queried in executable code (excluding the one comment hit) is 11 tables: `system_cache, deploy_memory, dream_proposals, domains, system_flags, spinoffs, skill_catalog, quick_actions, pending_confirmations, loops, brain_edges`.

The claim's list names **12** tables and includes `skill_registry` (singular "skill", no final "s"). A direct case-insensitive search for `public.skill_registry` (that exact singular spelling) returns **zero** matches anywhere in the file, in code or comments — it does not exist under that name at all. (Only `skill_catalog`, already separately listed, and the comment-only `skills_registry`, plural, exist.) So the claimed set is wrong: it has a 12th, nonexistent member.

The plural `skills_registry` does occur 3 times total in the file (lines 69, 309, 774) and all 3 are inside comments (69 and 309 inside the header `<!-- -->` block; 774 inside a `//` line comment in `loadAll()`) — this specific sub-claim is true.

**Verdict: REFUTED** — the `runScheduledTask` single-call-site claim and the "skills_registry occurs only in comments" claim are both true, but the stated 12-table set is wrong: the actual set read via `from public.<table>` has 11 members, and does not include `skill_registry` (that string does not appear anywhere in the file); the claim appears to have invented that 12th entry.

---

## D11 — savePrefs()

Command:
```
grep -n "function savePrefs" "$B"   -> 940
sed -n '940,967p' "$B"
```
Relevant lines:
```js
Object.assign(PREFS_RAW, { v:PREFS.v, layout:PREFS.layout, theme:PREFS.theme, accent:PREFS.accent,
    density:PREFS.density, tabs:pinFirst(outTabs), hidden:outHidden.filter(k=>k!=='home'), labels:outLabels, title:PREFS.title,
    home:outHome, whidden:outWh,
    domOrder:domOrderClean(PREFS.domOrder), domLabels:domLabelsClean(PREFS.domLabels) });
...
sql("insert into public.system_cache (key,value) values ('dashboard_prefs','"+lit(JSON.stringify(PREFS_RAW))+"'::jsonb) on conflict (key) do update set value=excluded.value, updated_at=now();").catch(wfail);
```
`PREFS_RAW` (the object serialized and written) is explicitly assigned `domOrder` and `domLabels` keys immediately before the write. The write is `insert into public.system_cache ... on conflict (key) do update ...` targeting key `'dashboard_prefs'`.

**Verdict: CONFIRMED.**

---

## D12 — inline `<script>` parses with `node --check`

Commands:
```
grep -n "<script" "$B"     -> 1:<script type="application/json" ...>   681:<script>
grep -n "</script>" "$B"   -> 13:</script>   2545:</script>
sed -n '682,2544p' "$B" > /tmp/.../scratchpad/extracted-script.js
node --check /tmp/.../scratchpad/extracted-script.js ; echo $?
node --version
```
Output:
```
PARSE_OK
v22.22.2
```
The only two `<script>` elements in the file are: (1) line 1, `type="application/json"` (excluded by the claim's selection rule), and (2) line 681, no `type` attribute (the one to extract — also the "last" such element since it's the only qualifying one). Its content (lines 682-2544, 1863 lines) was extracted verbatim into `extracted-script.js` and `node --check` exited 0 with no syntax errors.

**Verdict: CONFIRMED.**

---

# Summary table

| Claim | Verdict |
|---|---|
| D1 | CONFIRMED |
| D2 | REFUTED (partial — fonts list omits IBM Plex Mono; everything else true) |
| D3 | CONFIRMED |
| D4 | CONFIRMED |
| D5 | CONFIRMED |
| D6 | CONFIRMED |
| D7 | CONFIRMED |
| D8 | CONFIRMED |
| D9 | REFUTED (partial — token values correct but list not exhaustive; accent/media parts true) |
| D10 | REFUTED (table set wrong — phantom `skill_registry`; call-site and comment-only parts true) |
| D11 | CONFIRMED |
| D12 | CONFIRMED |
