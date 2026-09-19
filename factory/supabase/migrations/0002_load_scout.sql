-- 0002_load_scout.sql
-- Server-side loader: turns a Scout JSON payload (factory/agents/scout.md schema) into
-- factory.opportunities + factory.claims rows. Enforces fact→source_url (downgrades to
-- unverified otherwise), maps text confidence to numbers, truncates long text.
-- Returns one row per opportunity inserted.

create or replace function factory.load_scout(
  p_payload jsonb,
  p_lane factory.lane,
  p_session_id text,
  p_agent text default 'scout',
  p_model text default 'sonnet'
) returns table (opportunity_id uuid, name text, claims int, facts int, downgraded int)
language plpgsql as $$
declare
  o jsonb; c jsonb;
  oid uuid; cat factory.opportunity_category; kind factory.claim_kind; topic text;
  conf numeric; conf_txt text; src text;
  n_claims int; n_facts int; n_down int;
  extra text; summary text;
begin
  for o in select * from jsonb_array_elements(coalesce(p_payload->'opportunities','[]'::jsonb)) loop
    oid := gen_random_uuid();
    begin
      cat := (o->>'category')::factory.opportunity_category;
    exception when others then cat := 'info_product'; end;

    extra := concat_ws(E'\n',
      case when o->>'owned_channel' is not null then 'OWNED CHANNEL: ' || (o->>'owned_channel') end,
      case when o->>'fulfillment' is not null then 'FULFILLMENT: ' || (o->>'fulfillment') end,
      case when o->>'first_dollar_path' is not null then 'FIRST DOLLAR PATH: ' || (o->>'first_dollar_path') end,
      case when jsonb_typeof(o->'why_it_might_fail') = 'array'
           then 'WHY IT MIGHT FAIL: ' || (select string_agg(x, ' | ') from jsonb_array_elements_text(o->'why_it_might_fail') x) end);
    summary := left(coalesce(o->>'summary','') || case when extra <> '' then E'\n\n' || extra else '' end, 4000);

    insert into factory.opportunities (id, name, category, lane, summary, source_urls, stage, graveyard_checked_at, p_first_100_inputs, scouted_by_session)
    values (oid, left(o->>'name', 200), cat, p_lane, summary,
            coalesce((select array_agg(left(x,500)) from jsonb_array_elements_text(coalesce(o->'source_urls','[]'::jsonb)) x), '{}'),
            'scouted', now(),
            jsonb_build_object(
              'price_point_usd', o->'price_point_usd',
              'owned_channel', o->'owned_channel',
              'fulfillment', o->'fulfillment',
              'first_dollar_path', o->'first_dollar_path',
              'graveyard_matches', coalesce(o->'graveyard_matches','[]'::jsonb),
              'scout_disagreements', coalesce(p_payload->'disagreements','[]'::jsonb),
              'not_public', coalesce(p_payload->'not_public','[]'::jsonb)),
            p_session_id);

    n_claims := 0; n_facts := 0; n_down := 0;
    for c in select * from jsonb_array_elements(coalesce(o->'claims','[]'::jsonb)) loop
      begin kind := (c->>'kind')::factory.claim_kind; exception when others then kind := 'unverified'; end;
      topic := lower(coalesce(c->>'topic',''));
      topic := case topic
        when 'pricing' then 'economics' when 'pricing_and_demand' then 'economics' when 'economics' then 'economics'
        when 'demand' then 'customer' when 'audience' then 'customer' when 'market_context' then 'customer'
        when 'market' then 'customer' when 'channel' then 'acquisition' when 'marketing' then 'acquisition'
        when 'delivery' then 'fulfillment' when 'competitor' then 'competition' when 'risk' then 'other'
        else topic end;
      if topic is null or topic not in ('customer','offer','acquisition','sales','fulfillment','economics','history','competition','differentiation','legal','other') then topic := 'other'; end if;
      src := nullif(c->>'source_url','');
      if kind = 'fact' and src is null then kind := 'unverified'; n_down := n_down + 1; end if;
      conf_txt := c->>'confidence';
      conf := case lower(coalesce(conf_txt,''))
                when 'high' then 0.85 when 'medium' then 0.6 when 'med' then 0.6 when 'low' then 0.35
                else null end;
      if conf is null and conf_txt ~ '^[0-9.]+$' then conf := least(1, greatest(0, conf_txt::numeric)); end if;
      insert into factory.claims (opportunity_id, topic, statement, kind, source_url, source_excerpt, confidence, agent, model, session_id)
      values (oid, topic, left(coalesce(c->>'statement',''),400), kind, left(src,500), left(c->>'source_excerpt',400), conf, p_agent, p_model, p_session_id);
      n_claims := n_claims + 1;
      if kind = 'fact' then n_facts := n_facts + 1; end if;
    end loop;

    insert into factory.events (opportunity_id, actor, event_type, payload)
    values (oid, p_agent, 'scouted', jsonb_build_object('lane', p_lane, 'session', p_session_id, 'claims', n_claims, 'facts', n_facts, 'downgraded', n_down));

    opportunity_id := oid; name := left(o->>'name',200); claims := n_claims; facts := n_facts; downgraded := n_down;
    return next;
  end loop;
end $$;
comment on function factory.load_scout is 'Loads a Scout JSON payload into opportunities + claims. A fact without source_url is stored as unverified.';
