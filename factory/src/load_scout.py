#!/usr/bin/env python3
"""Turn a Scout JSON file (factory/agents/scout.md schema) into SQL that inserts
factory.opportunities + factory.claims rows. Prints the SQL; the orchestrator runs
it against the brain. Enforces: fact needs source_url; text fields truncated.

usage: load_scout.py <scout.json> <lane> <session_id>
"""
import json, sys, uuid

ALLOWED_KINDS = {"fact","assumption","estimate","inference","unverified"}
ALLOWED_TOPICS = {"customer","offer","acquisition","sales","fulfillment","economics",
                  "history","competition","differentiation","legal","other"}
ALLOWED_CATS = {"local_service","b2b_service","saas","ai_service","productized","agency","leadgen",
                "recurring","niche_software","marketplace","info_product","ops_automatable","asset"}

def q(s, n=None):
    if s is None: return "null"
    s = str(s)
    if n: s = s[:n]
    return "'" + s.replace("'", "''") + "'"

def arr(xs):
    return "array[" + ",".join(q(x, 500) for x in xs) + "]::text[]" if xs else "'{}'::text[]"

def main(path, lane, session_id):
    data = json.load(open(path))
    out = ["begin;"]
    stats = {"opps":0, "claims":0, "downgraded":0}
    for o in data["opportunities"]:
        oid = str(uuid.uuid4())
        cat = o.get("category","other")
        if cat not in ALLOWED_CATS: cat = "info_product"
        summary = o.get("summary","")
        extra = []
        for k in ("owned_channel","fulfillment","first_dollar_path"):
            if o.get(k): extra.append(f"{k.replace('_',' ').upper()}: {o[k]}")
        if o.get("why_it_might_fail"): extra.append("WHY IT MIGHT FAIL: " + " | ".join(o["why_it_might_fail"]))
        full_summary = summary + ("\n\n" + "\n".join(extra) if extra else "")
        inputs = json.dumps({
            "price_point_usd": o.get("price_point_usd"),
            "owned_channel": o.get("owned_channel"),
            "fulfillment": o.get("fulfillment"),
            "first_dollar_path": o.get("first_dollar_path"),
            "graveyard_matches": o.get("graveyard_matches", []),
            "scout_disagreements": data.get("disagreements", []),
            "not_public": data.get("not_public", []),
        })
        out.append(
          f"insert into factory.opportunities (id,name,category,lane,summary,source_urls,stage,graveyard_checked_at,p_first_100_inputs,scouted_by_session) values "
          f"({q(oid)},{q(o['name'],200)},{q(cat)}::factory.opportunity_category,{q(lane)}::factory.lane,{q(full_summary,4000)},{arr(o.get('source_urls',[]))},'scouted',now(),{q(inputs)}::jsonb,{q(session_id)});")
        stats["opps"] += 1
        for c in o.get("claims", []):
            kind = c.get("kind","unverified")
            if kind not in ALLOWED_KINDS: kind = "unverified"
            topic = c.get("topic","other")
            if topic not in ALLOWED_TOPICS: topic = "other"
            src = c.get("source_url") or None
            if kind == "fact" and not src:
                kind = "unverified"; stats["downgraded"] += 1
            conf = c.get("confidence")
            if isinstance(conf, str):
                conf = {"high":0.85,"medium":0.6,"med":0.6,"low":0.35}.get(conf.strip().lower())
                if conf is None:
                    try: conf = float(c.get("confidence"))
                    except (TypeError, ValueError): conf = None
            conf_sql = "null" if conf is None else str(max(0,min(1,float(conf))))
            out.append(
              f"insert into factory.claims (opportunity_id,topic,statement,kind,source_url,source_excerpt,confidence,agent,model,session_id) values "
              f"({q(oid)},{q(topic)},{q(c.get('statement',''),400)},{q(kind)}::factory.claim_kind,{q(src,500)},{q(c.get('source_excerpt'),400)},{conf_sql},'scout','sonnet',{q(session_id)});")
            stats["claims"] += 1
    out.append(f"insert into factory.events (actor,event_type,payload) values ('scout','scout_run',{q(json.dumps({'lane':lane,'session':session_id,**stats}))}::jsonb);")
    out.append("commit;")
    sys.stderr.write(json.dumps(stats)+"\n")
    print("\n".join(out))

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
