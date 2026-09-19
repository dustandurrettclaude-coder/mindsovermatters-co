-- 0003_load_research.sql
-- Loader for Researcher JSON (factory/agents/researcher.md): claims + business_models row,
-- then stage -> researched. Same fact/source and topic-alias rules as load_scout.

create or replace function factory.load_research(
  p_payload jsonb,
  p_session_id text,
  p_agent text default 'researcher',
  p_model text default 'sonnet'
) returns table (opportunity_id uuid, claims int, facts int, downgraded int, model_id uuid)
language plpgsql as $$
declare
  oid uuid; c jsonb; kind factory.claim_kind; topic text; src text; conf numeric; conf_txt text;
  n_claims int := 0; n_facts int := 0; n_down int := 0; mid uuid; b jsonb;
begin
  oid := (p_payload->>'opportunity_id')::uuid;
  if not exists (select 1 from factory.opportunities where id = oid) then
    raise exception 'opportunity % not found', oid;
  end if;

  for c in select * from jsonb_array_elements(coalesce(p_payload->'claims','[]'::jsonb)) loop
    begin kind := (c->>'kind')::factory.claim_kind; exception when others then kind := 'unverified'; end;
    topic := lower(coalesce(c->>'topic',''));
    topic := case topic
      when 'pricing' then 'economics' when 'pricing_and_demand' then 'economics'
      when 'demand' then 'customer' when 'audience' then 'customer' when 'market_context' then 'customer'
      when 'market' then 'customer' when 'channel' then 'acquisition' when 'marketing' then 'acquisition'
      when 'delivery' then 'fulfillment' when 'competitor' then 'competition' when 'risk' then 'other'
      else topic end;
    if topic not in ('customer','offer','acquisition','sales','fulfillment','economics','history','competition','differentiation','legal','other') then topic := 'other'; end if;
    src := nullif(c->>'source_url','');
    if kind = 'fact' and src is null then kind := 'unverified'; n_down := n_down + 1; end if;
    conf_txt := c->>'confidence';
    conf := case lower(coalesce(conf_txt,'')) when 'high' then 0.85 when 'medium' then 0.6 when 'med' then 0.6 when 'low' then 0.35 else null end;
    if conf is null and conf_txt ~ '^[0-9.]+$' then conf := least(1, greatest(0, conf_txt::numeric)); end if;
    insert into factory.claims (opportunity_id, topic, statement, kind, source_url, source_excerpt, confidence, agent, model, session_id)
    values (oid, topic, left(coalesce(c->>'statement',''),400), kind, left(src,500), left(c->>'source_excerpt',400), conf, p_agent, p_model, p_session_id);
    n_claims := n_claims + 1; if kind = 'fact' then n_facts := n_facts + 1; end if;
  end loop;

  b := coalesce(p_payload->'blocks','{}'::jsonb);
  insert into factory.business_models (opportunity_id, customer, offer, acquisition, sales, fulfillment, economics, evolution, smallest_viable_version)
  values (oid, coalesce(b->'customer','{}'), coalesce(b->'offer','{}'), coalesce(b->'acquisition','{}'), coalesce(b->'sales','{}'),
          coalesce(b->'fulfillment','{}'), coalesce(b->'economics','{}'),
          coalesce(b->'history','{}') || jsonb_build_object('disagreements', coalesce(p_payload->'disagreements','[]'::jsonb), 'not_public', coalesce(p_payload->'not_public','[]'::jsonb)),
          left(p_payload->>'smallest_viable_version', 2000))
  returning id into mid;

  update factory.opportunities set stage = 'researched' where id = oid and stage = 'scouted';
  insert into factory.events (opportunity_id, actor, event_type, payload)
  values (oid, p_agent, 'researched', jsonb_build_object('session', p_session_id, 'claims', n_claims, 'facts', n_facts, 'downgraded', n_down, 'business_model_id', mid));

  opportunity_id := oid; claims := n_claims; facts := n_facts; downgraded := n_down; model_id := mid;
  return next;
end $$;
comment on function factory.load_research is 'Loads a Researcher JSON payload: claims + business_models row; advances stage scouted→researched.';
