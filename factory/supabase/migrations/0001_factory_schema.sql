-- 0001_factory_schema.sql
-- Autonomous Business Creation Loop: schema `factory` in the brain project (ompxlqmszgutlldtivph).
-- Design: factory/docs/ARCHITECTURE_REPORT.md §5, §7, §9, §19.
-- Apply with the Supabase MCP `apply_migration` (no Supabase CLI in the build environment).
-- Idempotent where Postgres allows; safe to re-run.

create schema if not exists factory;

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
do $$ begin
  create type factory.claim_kind as enum ('fact','assumption','estimate','inference','unverified');
exception when duplicate_object then null; end $$;

do $$ begin
  create type factory.opportunity_category as enum (
    'local_service','b2b_service','saas','ai_service','productized','agency','leadgen',
    'recurring','niche_software','marketplace','info_product','ops_automatable','asset');
exception when duplicate_object then null; end $$;

do $$ begin
  create type factory.lane as enum ('cost_seg_cre','respiratory_therapy','mom_digital','other');
exception when duplicate_object then null; end $$;

do $$ begin
  create type factory.opportunity_stage as enum (
    'scouted','researched','evaluated','approved_for_validation','rejected');
exception when duplicate_object then null; end $$;

do $$ begin
  create type factory.business_state as enum (
    'validating','killed','building','launched','optimizing','profitable',
    'automating','maintaining','escalated','paused','dead');
exception when duplicate_object then null; end $$;

do $$ begin
  create type factory.business_kind as enum ('business','asset');
exception when duplicate_object then null; end $$;

do $$ begin
  create type factory.experiment_type as enum (
    'landing_page','waitlist','cold_outreach','paid_ad','presale','demo','concierge',
    'pilot','loi','paid_trial','other');
exception when duplicate_object then null; end $$;

do $$ begin
  create type factory.experiment_status as enum ('planned','approved','running','closed','killed');
exception when duplicate_object then null; end $$;

do $$ begin
  create type factory.decision_kind as enum (
    'approve_validation','approve_build','approve_spend','pricing_change','legal',
    'refund_threshold','security','strategic','ai_disagreement','autonomy_promotion',
    'kill_cap_exceeded','other');
exception when duplicate_object then null; end $$;

do $$ begin
  create type factory.decision_status as enum ('open','decided','expired');
exception when duplicate_object then null; end $$;

do $$ begin
  create type factory.lead_stage as enum (
    'lead','qualified','responded','booked','sold','onboarded','lost');
exception when duplicate_object then null; end $$;

do $$ begin
  create type factory.automation_status as enum (
    'manual','ai_assisted','delegated','automated','eliminated');
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------------------
-- Shared trigger: updated_at
-- ---------------------------------------------------------------------------
create or replace function factory.set_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

-- ---------------------------------------------------------------------------
-- Opportunities and evidence
-- ---------------------------------------------------------------------------
create table if not exists factory.opportunities (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category factory.opportunity_category not null,
  lane factory.lane not null default 'other',
  summary text,
  source_urls text[] not null default '{}',
  stage factory.opportunity_stage not null default 'scouted',
  graveyard_match_ids uuid[] not null default '{}',
  graveyard_checked_at timestamptz,
  p_first_100_30d numeric(4,3) check (p_first_100_30d between 0 and 1),
  p_first_100_inputs jsonb,
  scouted_by_session text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table factory.opportunities is 'One row per discovered business/model. stage moves scouted→researched→evaluated→approved_for_validation|rejected. p_first_100_30d is an ESTIMATE (§19.8) used to order, never to decide alone.';
comment on column factory.opportunities.lane is 'Unfair-advantage lane (§19.1). other requires a decision row before Gate 1.';

create table if not exists factory.claims (
  id uuid primary key default gen_random_uuid(),
  opportunity_id uuid references factory.opportunities(id) on delete cascade,
  business_id uuid,
  topic text not null check (topic in ('customer','offer','acquisition','sales','fulfillment','economics','history','competition','differentiation','legal','other')),
  statement text not null,
  kind factory.claim_kind not null,
  source_url text,
  source_excerpt text,
  confidence numeric(4,3) check (confidence is null or confidence between 0 and 1),
  agent text,
  model text,
  session_id text,
  verified_by text,
  verified_at timestamptz,
  superseded_by uuid references factory.claims(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint fact_requires_source check (kind <> 'fact' or (source_url is not null and length(source_url) > 0))
);
comment on table factory.claims is 'Evidence ledger. Every statement an agent produces, tagged fact/assumption/estimate/inference/unverified. A fact without a source_url is rejected by constraint.';
create index if not exists claims_opportunity_idx on factory.claims(opportunity_id);
create index if not exists claims_business_idx on factory.claims(business_id);
create index if not exists claims_kind_idx on factory.claims(kind);

create table if not exists factory.business_models (
  id uuid primary key default gen_random_uuid(),
  opportunity_id uuid not null references factory.opportunities(id) on delete cascade,
  customer jsonb not null default '{}',
  offer jsonb not null default '{}',
  acquisition jsonb not null default '{}',
  sales jsonb not null default '{}',
  fulfillment jsonb not null default '{}',
  economics jsonb not null default '{}',
  evolution jsonb not null default '{}',
  smallest_viable_version text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table factory.business_models is 'Reverse-engineered model. Each jsonb block carries claim ids for every value.';

create table if not exists factory.opportunity_reports (
  id uuid primary key default gen_random_uuid(),
  opportunity_id uuid not null references factory.opportunities(id) on delete cascade,
  dimension text not null check (dimension in (
    'demand','pain','roi','competition','differentiation','acquisition','recurring','margin',
    'automation','complexity','startup_cost','speed','scalability','exit_value','owner_time')),
  verdict text not null check (verdict in ('strong','weak','unknown')),
  evidence_claim_ids uuid[] not null default '{}',
  risks text[] not null default '{}',
  unknowns text[] not null default '{}',
  assumptions text[] not null default '{}',
  required_experiments text[] not null default '{}',
  failure_conditions text[] not null default '{}',
  success_conditions text[] not null default '{}',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (opportunity_id, dimension)
);
comment on table factory.opportunity_reports is 'One row per evaluation dimension. No composite score column by design.';

-- ---------------------------------------------------------------------------
-- Businesses and lifecycle
-- ---------------------------------------------------------------------------
create table if not exists factory.businesses (
  id uuid primary key default gen_random_uuid(),
  opportunity_id uuid references factory.opportunities(id),
  name text not null,
  kind factory.business_kind not null default 'business',
  lane factory.lane not null default 'other',
  state factory.business_state not null default 'validating',
  autonomy_level int not null default 0 check (autonomy_level between 0 and 5),
  mode text not null default 'build' check (mode in ('build','maintain')),
  spend_limit_cents int not null default 0 check (spend_limit_cents >= 0),
  spent_cents int not null default 0 check (spent_cents >= 0),
  human_hours_cap numeric(6,2) not null default 5,
  human_hours_spent numeric(8,2) not null default 0,
  first_dollar_deadline date,
  first_dollar_at timestamptz,
  owner_hours_week numeric(6,2),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table factory.businesses is 'A business (or shared distribution asset, kind=asset) the human approved. spend_limit_cents defaults to 0 (Rule 2). first_dollar_deadline = Gate 1 date + 30 days (§19.2).';

alter table factory.claims
  drop constraint if exists claims_business_fk,
  add constraint claims_business_fk foreign key (business_id) references factory.businesses(id) on delete set null;

create table if not exists factory.state_transitions (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references factory.businesses(id) on delete cascade,
  from_state factory.business_state,
  to_state factory.business_state not null,
  actor text not null,
  decision_id uuid,
  reason text,
  created_at timestamptz not null default now()
);
comment on table factory.state_transitions is 'Immutable lifecycle log. Written only by factory.transition().';

-- ---------------------------------------------------------------------------
-- Decisions (human gates and escalations)
-- ---------------------------------------------------------------------------
create table if not exists factory.decisions (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references factory.businesses(id) on delete cascade,
  opportunity_id uuid references factory.opportunities(id) on delete cascade,
  kind factory.decision_kind not null,
  what_happened text not null,
  why_it_matters text not null,
  already_done text not null,
  evidence_claim_ids uuid[] not null default '{}',
  options jsonb not null,
  recommended_option text not null,
  decision_required text not null,
  status factory.decision_status not null default 'open',
  decided_option text,
  decided_by text,
  decided_at timestamptz,
  pending_confirmation_id bigint,
  expires_at timestamptz not null default now() + interval '14 days',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint options_is_array check (jsonb_typeof(options) = 'array'),
  constraint decided_has_option check (status <> 'decided' or decided_option is not null)
);
comment on table factory.decisions is 'Every human gate/escalation with the six required fields. pending_confirmation_id links the public.pending_confirmations tick surface (Rule 8).';
create index if not exists decisions_open_idx on factory.decisions(status) where status = 'open';

alter table factory.state_transitions
  drop constraint if exists state_transitions_decision_fk,
  add constraint state_transitions_decision_fk foreign key (decision_id) references factory.decisions(id);

-- ---------------------------------------------------------------------------
-- Experiments, metrics, campaigns, leads
-- ---------------------------------------------------------------------------
create table if not exists factory.lessons (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references factory.businesses(id) on delete set null,
  experiment_id uuid,
  lesson text not null,
  category text,
  applies_to text[] not null default '{}',
  evidence_claim_ids uuid[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table factory.lessons is 'Institutional memory. Every closed experiment must reference one.';

create table if not exists factory.experiments (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references factory.businesses(id) on delete cascade,
  hypothesis text not null,
  assumption_claim_id uuid references factory.claims(id),
  type factory.experiment_type not null,
  kill_criteria text not null,
  success_criteria text not null,
  counts_as_paying_demand boolean not null default false,
  budget_cents int not null default 0 check (budget_cents >= 0),
  spent_cents int not null default 0 check (spent_cents >= 0),
  human_minutes int not null default 0,
  approval_decision_id uuid references factory.decisions(id),
  status factory.experiment_status not null default 'planned',
  result text,
  lesson_id uuid references factory.lessons(id),
  started_at timestamptz,
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint spend_needs_approval check (budget_cents = 0 or approval_decision_id is not null),
  constraint closed_needs_lesson check (status not in ('closed','killed') or lesson_id is not null)
);
comment on table factory.experiments is 'Validation and marketing experiments. counts_as_paying_demand marks presale/pilot/paid_trial/loi evidence for Gate 2. Any budget requires an approving decision; closing requires a lesson.';

alter table factory.lessons
  drop constraint if exists lessons_experiment_fk,
  add constraint lessons_experiment_fk foreign key (experiment_id) references factory.experiments(id) on delete set null;

create table if not exists factory.metrics (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references factory.businesses(id) on delete cascade,
  experiment_id uuid references factory.experiments(id) on delete cascade,
  metric text not null,
  period_start date not null,
  period_end date not null,
  value numeric not null,
  source text not null default 'manual',
  created_at timestamptz not null default now(),
  check (period_end >= period_start)
);
create index if not exists metrics_business_metric_idx on factory.metrics(business_id, metric, period_start);

create table if not exists factory.campaigns (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references factory.businesses(id) on delete cascade,
  channel text not null,
  audience text,
  offer text,
  creative_ref text,
  landing_url text,
  spend_cents int not null default 0,
  status text not null default 'test' check (status in ('test','scale','killed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists factory.leads (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references factory.businesses(id) on delete cascade,
  source text,
  contact jsonb not null default '{}',
  stage factory.lead_stage not null default 'lead',
  lost_reason text,
  objections text[] not null default '{}',
  followups int not null default 0,
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- AI cost + disagreement ledgers
-- ---------------------------------------------------------------------------
create table if not exists factory.ai_calls (
  id uuid primary key default gen_random_uuid(),
  session_id text,
  business_id uuid references factory.businesses(id) on delete set null,
  opportunity_id uuid references factory.opportunities(id) on delete set null,
  agent text not null,
  model text not null,
  provider text not null default 'anthropic',
  task_type text,
  input_tokens int,
  output_tokens int,
  cost_cents numeric(10,4),
  outcome text,
  created_at timestamptz not null default now()
);
create index if not exists ai_calls_business_idx on factory.ai_calls(business_id);

create table if not exists factory.ai_disagreements (
  id uuid primary key default gen_random_uuid(),
  opportunity_id uuid references factory.opportunities(id) on delete cascade,
  business_id uuid references factory.businesses(id) on delete cascade,
  topic text not null,
  positions jsonb not null,
  resolution text check (resolution in ('research_resolved','retained_uncertainty','human')),
  resolving_claim_ids uuid[] not null default '{}',
  decision_id uuid references factory.decisions(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Graveyard, SOPs, automations, events
-- ---------------------------------------------------------------------------
create table if not exists factory.failure_reports (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null unique references factory.businesses(id) on delete cascade,
  original_hypothesis text not null,
  niche text,
  offer text,
  acquisition_method text,
  experiments_summary text,
  money_spent_cents int not null default 0,
  customers int not null default 0,
  revenue_cents int not null default 0,
  failure_point text not null,
  shutdown_reason text not null,
  lesson_ids uuid[] not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists factory.sops (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references factory.businesses(id) on delete cascade,
  process text not null,
  trigger_text text,
  steps jsonb not null default '[]',
  automation_status factory.automation_status not null default 'manual',
  owner text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists factory.automations (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references factory.businesses(id) on delete cascade,
  sop_id uuid references factory.sops(id) on delete set null,
  platform text not null check (platform in ('pg_cron','edge_fn','n8n','zapier','routine','other')),
  ref text,
  last_run_at timestamptz,
  last_status text,
  failure_count int not null default 0,
  clean_runs int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists factory.events (
  id bigint generated always as identity primary key,
  business_id uuid,
  opportunity_id uuid,
  actor text not null,
  event_type text not null,
  payload jsonb not null default '{}',
  created_at timestamptz not null default now()
);
create index if not exists events_business_idx on factory.events(business_id, created_at desc);

-- ---------------------------------------------------------------------------
-- updated_at triggers
-- ---------------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['opportunities','claims','business_models','opportunity_reports','businesses',
    'decisions','lessons','experiments','campaigns','leads','ai_disagreements','sops','automations']
  loop
    execute format('drop trigger if exists set_updated_at on factory.%I', t);
    execute format('create trigger set_updated_at before update on factory.%I for each row execute function factory.set_updated_at()', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- Lifecycle: the only way to change business state
-- ---------------------------------------------------------------------------
create or replace function factory.transition(
  p_business_id uuid,
  p_to factory.business_state,
  p_actor text,
  p_reason text default null,
  p_decision_id uuid default null
) returns factory.state_transitions
language plpgsql as $$
declare
  b factory.businesses%rowtype;
  d factory.decisions%rowtype;
  allowed boolean := false;
  needs_kind factory.decision_kind := null;
  paying_demand boolean;
  tr factory.state_transitions%rowtype;
begin
  perform set_config('factory.in_transition', 'on', true);
  select * into b from factory.businesses where id = p_business_id for update;
  if not found then raise exception 'business % not found', p_business_id; end if;

  -- allowed edges (§7)
  allowed := case
    when p_to = 'dead' then true
    when b.state = 'validating'  and p_to in ('killed','building') then true
    when b.state = 'building'    and p_to in ('launched','paused','killed') then true
    when b.state = 'launched'    and p_to in ('optimizing','paused','killed') then true
    when b.state = 'optimizing'  and p_to in ('profitable','paused','killed') then true
    when b.state = 'profitable'  and p_to in ('automating','optimizing','paused') then true
    when b.state = 'automating'  and p_to in ('maintaining','optimizing','paused') then true
    when b.state = 'maintaining' and p_to in ('escalated','optimizing','paused') then true
    when b.state = 'escalated'   and p_to in ('maintaining','optimizing','paused','killed') then true
    when b.state = 'paused'      and p_to in ('validating','building','launched','optimizing','maintaining','killed') then true
    else false end;
  if not allowed then
    raise exception 'transition % -> % not allowed', b.state, p_to;
  end if;

  -- gated edges
  if b.state = 'validating' and p_to = 'building' then
    needs_kind := 'approve_build';
    select exists (
      select 1 from factory.experiments e
      where e.business_id = b.id and e.counts_as_paying_demand and e.status = 'closed'
        and e.result is not null
    ) into paying_demand;
    if not paying_demand then
      raise exception 'Gate 2: no closed experiment with paying-demand evidence for business %', b.id;
    end if;
  end if;

  if needs_kind is not null then
    if p_decision_id is null then
      raise exception 'transition % -> % requires a decided decision of kind %', b.state, p_to, needs_kind;
    end if;
    select * into d from factory.decisions where id = p_decision_id;
    if not found or d.business_id <> b.id or d.kind <> needs_kind or d.status <> 'decided' then
      raise exception 'decision % does not authorise % -> %', p_decision_id, b.state, p_to;
    end if;
  end if;

  if p_to in ('dead') and not exists (select 1 from factory.failure_reports f where f.business_id = b.id) then
    raise exception 'state dead requires a failure_reports row for business %', b.id;
  end if;

  update factory.businesses set state = p_to where id = b.id;
  insert into factory.state_transitions (business_id, from_state, to_state, actor, decision_id, reason)
  values (b.id, b.state, p_to, p_actor, p_decision_id, p_reason) returning * into tr;
  insert into factory.events (business_id, actor, event_type, payload)
  values (b.id, p_actor, 'state_transition', jsonb_build_object('from', b.state, 'to', p_to, 'decision_id', p_decision_id));
  perform set_config('factory.in_transition', 'off', true);
  return tr;
end $$;
comment on function factory.transition is 'Sole writer of businesses.state. Enforces allowed edges, Gate 2 paying-demand evidence, decision authorisation, and failure report before dead.';

-- Direct state updates outside transition() are rejected.
create or replace function factory.guard_state_update() returns trigger
language plpgsql as $$
begin
  if new.state is distinct from old.state
     and coalesce(current_setting('factory.in_transition', true), '') <> 'on' then
    -- transition() sets the GUC before updating
    raise exception 'businesses.state may only change via factory.transition()';
  end if;
  return new;
end $$;

drop trigger if exists guard_state on factory.businesses;
create trigger guard_state before update of state on factory.businesses
  for each row execute function factory.guard_state_update();

-- Spend and kill-cap guards (§19.5, §19.7, Rule 2)
create or replace function factory.guard_spend() returns trigger
language plpgsql as $$
declare b factory.businesses%rowtype;
begin
  select * into b from factory.businesses where id = new.business_id;
  if new.spent_cents > coalesce(new.budget_cents, 0) then
    raise exception 'experiment % spent (%) exceeds its approved budget (%)', new.id, new.spent_cents, new.budget_cents;
  end if;
  if new.spent_cents > 5000 or new.human_minutes > 300 then
    insert into factory.decisions (business_id, kind, what_happened, why_it_matters, already_done, options, recommended_option, decision_required)
    values (new.business_id, 'kill_cap_exceeded',
      format('experiment %s reached spent=%s cents, human_minutes=%s', new.id, new.spent_cents, new.human_minutes),
      'Kill cap is $50 / 5 human hours per validation (§19.5).',
      'Experiment left running; no further spend recorded.',
      '["kill experiment","extend cap once","convert to paid experiment with new budget"]',
      'kill experiment', 'Choose one option');
  end if;
  return new;
end $$;
drop trigger if exists guard_spend on factory.experiments;
create trigger guard_spend before insert or update of spent_cents, human_minutes on factory.experiments
  for each row execute function factory.guard_spend();

-- ---------------------------------------------------------------------------
-- Views
-- ---------------------------------------------------------------------------
create or replace view factory.graveyard as
  select b.name, b.lane, o.category, f.*
  from factory.businesses b
  join factory.failure_reports f on f.business_id = b.id
  left join factory.opportunities o on o.id = b.opportunity_id
  where b.state in ('dead','killed');

create or replace view factory.portfolio as
  select state, kind, lane, count(*) as n,
         sum(spent_cents) as spent_cents,
         sum(human_hours_spent) as human_hours
  from factory.businesses group by 1,2,3;

create or replace view factory.open_decisions as
  select d.*, b.name as business_name, o.name as opportunity_name
  from factory.decisions d
  left join factory.businesses b on b.id = d.business_id
  left join factory.opportunities o on o.id = d.opportunity_id
  where d.status = 'open' order by d.created_at;

create or replace view factory.factory_metrics as
  select
    (select count(*) from factory.opportunities) as opportunities_scouted,
    (select count(*) from factory.opportunities where stage in ('evaluated','approved_for_validation','rejected')) as opportunities_evaluated,
    (select count(*) from factory.businesses where kind='business') as businesses_total,
    (select count(*) from factory.businesses where state in ('profitable','automating','maintaining')) as businesses_profitable,
    (select count(*) from factory.businesses where state in ('killed','dead')) as businesses_graveyard,
    (select count(*) from factory.experiments where status in ('closed','killed')) as experiments_completed,
    (select count(*) from factory.lessons) as lessons_retained,
    (select coalesce(sum(value),0) from factory.metrics where metric='revenue_cents') as revenue_cents,
    (select coalesce(sum(cost_cents),0) from factory.ai_calls) as ai_cost_cents,
    (select coalesce(sum(human_hours_spent),0) from factory.businesses) as human_hours,
    case when (select coalesce(sum(human_hours_spent),0) from factory.businesses) > 0
      then ((select coalesce(sum(value),0) from factory.metrics where metric='profit_cents') / 100.0)
           / (select sum(human_hours_spent) from factory.businesses)
      else null end as profit_per_human_hour_usd;

-- ---------------------------------------------------------------------------
-- RLS: service role writes; factory_reader reads views only. No anon policies.
-- ---------------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['opportunities','claims','business_models','opportunity_reports','businesses',
    'state_transitions','decisions','lessons','experiments','metrics','campaigns','leads','ai_calls',
    'ai_disagreements','failure_reports','sops','automations','events']
  loop
    execute format('alter table factory.%I enable row level security', t);
  end loop;
end $$;

revoke all on schema factory from anon, authenticated;
grant usage on schema factory to service_role;
grant all on all tables in schema factory to service_role;
grant execute on all functions in schema factory to service_role;
