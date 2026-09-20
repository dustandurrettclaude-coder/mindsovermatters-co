-- Lifecycle + gate tests for the factory schema. Run against a throwaway DB with the migration applied.
-- Each block prints PASS/FAIL. Expected: all PASS.
\set ON_ERROR_STOP off
\pset format unaligned
\pset tuples_only on

-- setup
insert into factory.opportunities (id, name, category, lane, stage)
values ('00000000-0000-0000-0000-000000000001','Sim: cost-seg pre-check calculator','info_product','cost_seg_cre','approved_for_validation');
insert into factory.businesses (id, opportunity_id, name, lane, first_dollar_deadline)
values ('00000000-0000-0000-0000-00000000000a','00000000-0000-0000-0000-000000000001','Sim biz','cost_seg_cre', current_date + 30);

-- T1: a fact without a source is rejected
do $$ begin
  insert into factory.claims (opportunity_id, topic, statement, kind) values ('00000000-0000-0000-0000-000000000001','offer','they charge $99','fact');
  raise notice 'T1 FAIL: fact without source accepted';
exception when check_violation then raise notice 'T1 PASS: fact without source rejected'; end $$;

-- T2: direct state update is rejected
do $$ begin
  update factory.businesses set state='building' where id='00000000-0000-0000-0000-00000000000a';
  raise notice 'T2 FAIL: direct state update accepted';
exception when others then raise notice 'T2 PASS: % ', sqlerrm; end $$;

-- T3: validating -> building without paying demand is rejected (Gate 2)
do $$ begin
  perform factory.transition('00000000-0000-0000-0000-00000000000a','building','test');
  raise notice 'T3 FAIL: Gate 2 bypassed';
exception when others then raise notice 'T3 PASS: %', sqlerrm; end $$;

-- T4: experiment with budget but no approving decision is rejected (spend gate)
do $$ begin
  insert into factory.experiments (business_id, hypothesis, type, kill_criteria, success_criteria, budget_cents)
  values ('00000000-0000-0000-0000-00000000000a','people pay $49','presale','0 sales in 14d','3 sales',2000);
  raise notice 'T4 FAIL: unapproved spend accepted';
exception when check_violation then raise notice 'T4 PASS: unapproved spend rejected'; end $$;

-- T5: approved presale experiment, closed with paying demand + lesson, then Gate 2 passes with a decided decision
insert into factory.decisions (id, business_id, kind, what_happened, why_it_matters, already_done, options, recommended_option, decision_required, status, decided_option, decided_by, decided_at)
values ('00000000-0000-0000-0000-0000000000d1','00000000-0000-0000-0000-00000000000a','approve_spend','presale test','tests paying demand','drafted page','["approve $20","decline"]','approve $20','approve?','decided','approve $20','dustan',now());
insert into factory.lessons (id, business_id, lesson) values ('00000000-0000-0000-0000-0000000000e1','00000000-0000-0000-0000-00000000000a','3 pre-sales at $49 from 40 outreach drafts');
insert into factory.experiments (id, business_id, hypothesis, type, kill_criteria, success_criteria, counts_as_paying_demand, budget_cents, approval_decision_id, status, result, lesson_id)
values ('00000000-0000-0000-0000-0000000000f1','00000000-0000-0000-0000-00000000000a','people pay $49','presale','0 sales in 14d','3 sales',true,2000,'00000000-0000-0000-0000-0000000000d1','closed','3 sales, $147','00000000-0000-0000-0000-0000000000e1');
-- closing an experiment without a lesson is rejected
do $$ begin
  insert into factory.experiments (business_id, hypothesis, type, kill_criteria, success_criteria, status, result)
  values ('00000000-0000-0000-0000-00000000000a','x','demo','k','s','closed','meh');
  raise notice 'T5a FAIL: closed without lesson accepted';
exception when check_violation then raise notice 'T5a PASS: closed experiment requires lesson'; end $$;
-- Gate 2 still needs the approve_build decision
do $$ begin
  perform factory.transition('00000000-0000-0000-0000-00000000000a','building','test');
  raise notice 'T5b FAIL: build without decision accepted';
exception when others then raise notice 'T5b PASS: %', sqlerrm; end $$;
insert into factory.decisions (id, business_id, kind, what_happened, why_it_matters, already_done, options, recommended_option, decision_required, status, decided_option, decided_by, decided_at)
values ('00000000-0000-0000-0000-0000000000d2','00000000-0000-0000-0000-00000000000a','approve_build','3 presales','paying demand shown','closed experiment','["build MVP","kill"]','build MVP','build?','decided','build MVP','dustan',now());
select case when (factory.transition('00000000-0000-0000-0000-00000000000a','building','test','gate 2 passed','00000000-0000-0000-0000-0000000000d2')).to_state='building'
  then 'T5c PASS: building via decided approve_build' else 'T5c FAIL' end;

-- T6: illegal edge rejected
do $$ begin
  perform factory.transition('00000000-0000-0000-0000-00000000000a','maintaining','test');
  raise notice 'T6 FAIL: building->maintaining accepted';
exception when others then raise notice 'T6 PASS: %', sqlerrm; end $$;

-- T7: dead requires a failure report
do $$ begin
  perform factory.transition('00000000-0000-0000-0000-00000000000a','dead','test');
  raise notice 'T7 FAIL: dead without failure report accepted';
exception when others then raise notice 'T7 PASS: %', sqlerrm; end $$;

-- T8: spend over budget rejected; kill cap opens a decision
do $$ begin
  update factory.experiments set spent_cents=2500 where id='00000000-0000-0000-0000-0000000000f1';
  raise notice 'T8a FAIL: overspend accepted';
exception when others then raise notice 'T8a PASS: %', sqlerrm; end $$;
update factory.experiments set human_minutes=301 where id='00000000-0000-0000-0000-0000000000f1';
select case when exists (select 1 from factory.decisions where kind='kill_cap_exceeded' and business_id='00000000-0000-0000-0000-00000000000a')
  then 'T8b PASS: kill cap opened a decision' else 'T8b FAIL' end;

-- T9: transitions + events logged
select 'T9 transitions=' || count(*) from factory.state_transitions where business_id='00000000-0000-0000-0000-00000000000a';
select 'T9 events=' || count(*) from factory.events where business_id='00000000-0000-0000-0000-00000000000a';
select 'views ok: ' || (select count(*) from factory.portfolio) || ' portfolio rows, ' || (select count(*) from factory.open_decisions) || ' open decisions, profit/hr=' || coalesce((select profit_per_human_hour_usd::text from factory.factory_metrics),'null');
