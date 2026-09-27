# VERIFY-backend: independent verification evidence

Date: 2026-09-27. Supabase project: <brain-project-ref>.
Method: SELECT-only SQL via Supabase MCP execute_sql (session role `postgres`: rolsuper=false, rolbypassrls=true),
plus Supabase MCP list_edge_functions and get_publishable_keys, plus Bash in this container.
Nothing was written to the database. No project files were modified. API key values are deliberately not reproduced.

## Verdicts

| Claim | Verdict |
|---|---|
| C1 RLS on every public table | CONFIRMED |
| C2 17 policies, 4 anon, 0 authenticated | CONFIRMED |
| C3 auth.users empty | CONFIRMED |
| C4 anon/authenticated grants on deploy_memory | CONFIRMED |
| C5 deploy_memory id=756 | CONFIRMED |
| C6 pending_confirmations id=436 | CONFIRMED |
| C7 current_session_id + open session | CONFIRMED |
| C8 pg_cron, pg_net, single keepalive function | CONFIRMED |
| C9 legacy anon + publishable key, both enabled | CONFIRMED |
| C10 network 403s and 200s | CONFIRMED, with a caveat: repo1.maven.org sometimes returns 429 |
| C11 java 21 / gradle / node 22 / no Android SDK | CONFIRMED |

---

## C1: RLS enabled on every relkind='r' table in public (CONFIRMED)

Query:
    SELECT count(*) AS total_r, count(*) FILTER (WHERE c.relrowsecurity) AS rls_on,
           count(*) FILTER (WHERE NOT c.relrowsecurity) AS rls_off, current_user AS cu
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind = 'r';
Result: total_r=57, rls_on=57, rls_off=0, cu=postgres

Listing query (relkind IN ('r','p')): 57 rows, all relkind 'r', all relrowsecurity=true
(relforcerowsecurity=false on all). There are no partitioned ('p') tables.
Tables: active_sessions, android_news_stories, brain_edges, brain_meta, brand_identities, budget_cc_spending,
budget_config, budget_cssi, budget_digital, budget_electric, budget_expenses, budget_finance_imports,
budget_fixed_costs_state, budget_heloc, budget_import_chats, budget_income, budget_months, budget_propane,
budget_propane_log, budget_receipts, budget_rentals, budget_school, campaign_sends, command_queue,
creator_contacts, cssi_campaigns, delegations, deploy_memory, domains, dream_proposals, email_campaign_log,
loops, marketing_products, marketing_targets, mcp_routing, model_routing, pending_confirmations,
pipeline_runs, policies, policy_proposals, quick_actions, referral_contacts, run_plans, sales, scripts,
seen_properties, sessions, skill_catalog, skill_registry, spinoffs, stock_performance, stock_signals,
stock_trades, system_cache, system_flags, system_locks, x_queue.

## C2: pg_policies in public (CONFIRMED)

Query:
    SELECT count(*) AS n_policies,
           count(*) FILTER (WHERE 'anon' = ANY(roles)) AS n_anon,
           count(*) FILTER (WHERE 'authenticated' = ANY(roles)) AS n_authenticated,
           count(*) FILTER (WHERE 'public' = ANY(roles)) AS n_public_role
    FROM pg_policies WHERE schemaname = 'public';
Result: n_policies=17, n_anon=4, n_authenticated=0, n_public_role=0

Query:
    SELECT tablename, policyname, cmd, roles::text, permissive, qual, with_check
    FROM pg_policies WHERE schemaname = 'public' ORDER BY tablename, policyname;
The 4 anon policies (all PERMISSIVE, roles exactly {anon}):
- deploy_memory | anon_capture_queued | INSERT | qual NULL |
  with_check ((key = 'goal_meta'::text) AND (status = 'queued-unreviewed'::text) AND (agent = 'desktop'::text))
- deploy_memory | anon_read_goal_meta | SELECT | qual (key = 'goal_meta'::text) | with_check NULL
- domains       | anon_read_domains   | SELECT | qual true | with_check NULL
- system_flags  | anon_read_flags     | SELECT | qual true | with_check NULL
The other 13 rows are all named service_role_only: cmd ALL, roles {service_role}, qual true, with_check true.
They sit on brain_edges, deploy_memory, dream_proposals, loops, mcp_routing, scripts, sessions,
skill_registry, spinoffs, stock_performance, stock_signals, stock_trades and system_cache.
No policy names `authenticated`. No policy uses role PUBLIC, so no policy reaches anon indirectly.
Context (not part of the claim): policies exist on only 15 distinct tables. The other 42 RLS-enabled
tables have no policy, so anon and authenticated see no rows in them.

## C3: auth.users has 0 rows (CONFIRMED)

Query: SELECT count(*) AS auth_users_rows FROM auth.users;   -> 0
Cross-check that RLS is not hiding rows: auth.users has relrowsecurity=true and 0 policies, but the
querying role postgres has rolbypassrls=true. pg_stat_all_tables for auth.users shows n_live_tup=0,
n_tup_ins=0 and n_tup_del=0 (reltuples=-1). The statistics agree with the count.

## C4: grants on public.deploy_memory (CONFIRMED)

Query:
    SELECT grantee, grantor, privilege_type, is_grantable FROM information_schema.role_table_grants
    WHERE table_schema = 'public' AND table_name = 'deploy_memory' AND grantee IN ('anon','authenticated')
    ORDER BY grantee, privilege_type;
Result: 8 rows, all grantor=postgres and is_grantable=NO.
  anon:          DELETE, INSERT, SELECT, UPDATE
  authenticated: DELETE, INSERT, SELECT, UPDATE
  Neither role has a TRUNCATE row.
Cross-check: relacl = {postgres=arwdDxtm/postgres,anon=arwdm/postgres,authenticated=arwdm/postgres,service_role=arwdDxtm/postgres}.
anon and authenticated have no 'D' (TRUNCATE). has_table_privilege(role,'public.deploy_memory',priv) returns
SELECT/INSERT/UPDATE/DELETE = true and TRUNCATE = false for both roles. The extra 'm' is the PG17 MAINTAIN
privilege, which information_schema does not list.

## C5: deploy_memory id=756 (CONFIRMED)

Query:
    SELECT id, goal_id, key, status, domain, done_when_kind, created_session_id, value->>'pr' AS pr
    FROM public.deploy_memory WHERE id = 756;
Result: 756 | 2026-09-27-android-mom-app | goal_meta | queued | infra | manual | 20260927-161451 |
        https://github.com/dustandurrettclaude-coder/mindsovermatters-co/pull/4
Exact-equality check: count(*) with id=756 and all 7 field equalities (including value->>'pr') = 1.
Rows with id=756 = 1.

## C6: pending_confirmations id=436 (CONFIRMED)

Query: SELECT id, status, action_type, ref, created_session_id FROM public.pending_confirmations WHERE id = 436;
Result: 436 | pending | decision | android-mom-app-plan | 20260927-161451
Exact-equality check: count = 1. Rows with id=436 = 1.

## C7: current_session_id and open session (CONFIRMED)

Query: SELECT key, COALESCE(value->>'value', value#>>'{}') FROM public.system_cache WHERE key = 'current_session_id';
Result: 1 row, '20260927-161451'. The value column is jsonb, stored as a JSON string. Exact-equality count = 1.
Query: SELECT session_id, closed_at, (closed_at IS NULL) FROM public.sessions WHERE session_id = '20260927-161451';
Result: 1 row, closed_at = NULL (closed_at IS NULL = true).

## C8: extensions and edge functions (CONFIRMED)

Query:
    SELECT e.extname, e.extversion, n.nspname FROM pg_extension e
    JOIN pg_namespace n ON n.oid = e.extnamespace WHERE e.extname IN ('pg_cron','pg_net');
Result: pg_cron 1.6.4 (schema pg_catalog); pg_net 0.20.3 (schema public)
list_edge_functions: exactly 1 function (slug 'keepalive', name 'keepalive', status ACTIVE, version 1, verify_jwt true).

## C9: publishable keys (CONFIRMED)

get_publishable_keys returned 2 keys. Their values are deliberately not reproduced here.
- name 'anon',    type 'legacy' (legacy anon JWT key), disabled=false
- name 'default', type 'publishable',                  disabled=false

## C10: network from this container (CONFIRMED, with a caveat)

curl 8.5.0. Blocked URLs, using the claim's exact command:
    curl -sS -o /dev/null -w '%{http_code} %{errormsg}' --max-time 20 <url>
- https://dl.google.com/android/repository/repository2-1.xml
    stderr: curl: (56) CONNECT tunnel failed, response 403
    stdout: 000 CONNECT tunnel failed, response 403        exit 56
- https://<brain-project-ref>.supabase.co/rest/v1/
    stderr: curl: (56) CONNECT tunnel failed, response 403
    stdout: 000 CONNECT tunnel failed, response 403        exit 56
HEAD requests (curl -sS -I). The final code comes from -w '%{http_code}' or the last ^HTTP/ status line,
not from the proxy's "200 Connection Established":
- https://registry.npmjs.org/@capacitor/core  -> 200 on 5/5 attempts (HTTP/2 200). http_connect=000, so this
  host goes direct and does not use the proxy (it is on the no-proxy list).
- https://maven.google.com/web/index.html     -> 200 on 5/5 attempts (proxy CONNECT 200, then HTTP/2 200)
- https://repo1.maven.org/maven2/             -> 200 on 5/8 attempts and HTTP/2 429 on 3/8.
  In order: 200, 429, 429, 200, 200, 200, 200, 429. The proxy CONNECT always returned 200. The 429 responses
  carry "server: cloudflare", so they are upstream rate limiting, not a proxy block.
Caveat: every outcome the claim describes was reproduced, but Maven Central does not reliably return 200.
A Gradle build that pulls from it may hit intermittent 429s and may need retries or a cache.

## C11: toolchain in this container (CONFIRMED)

- java -version  -> openjdk version "21.0.10" 2026-01-20 (Ubuntu build 21.0.10+7), /usr/lib/jvm/java-21-openjdk-amd64. Exit 0.
- gradle         -> on PATH at /opt/gradle/bin/gradle (exists, -rwxr-xr-x). gradle --version reports Gradle 8.14.3,
                    Launcher JVM 21.0.10. Exit 0.
- node --version -> v22.22.2 (/opt/node22/bin/node)
- sdkmanager     -> `command -v sdkmanager` prints nothing and exits 1; `type -a sdkmanager` says not found
- ANDROID_HOME and ANDROID_SDK_ROOT are both unset. No environment variable name contains "android".
  A login shell (bash -lc) gives the same result.
- Extra context: find / -xdev finds no file named sdkmanager*. None of /opt/android-sdk, /usr/lib/android-sdk,
  /root/Android/Sdk, /usr/local/android-sdk or /opt/android exists. No profile file mentions ANDROID.
  The container has no Android SDK at all; this is not just a missing variable.
