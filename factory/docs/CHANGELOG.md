# Changelog

## 2026-09-19
- Architecture & Implementation Report (§1–18) and approved decisions (§19).
- Migration `0001_factory_schema` written, tested locally (12 gate checks), independently
  verified, and applied to the brain project.
- Agent role specs: scout, researcher, verifier, devils_advocate, financial, evaluator,
  experiment_designer; delegation template.
- First scout run across the three lanes (results recorded in `factory.opportunities`).
- Connector decisions: Firecrawl connected (free tier); Similarweb dropped (paid).
- Scout run 1 re-ranked after owner-reported channel sizes (MOM buyers 0, X 0, RT 0; referral_contacts 212). Lesson filed.
- Decision A approved: research CRE offering-memorandum template, CRE deal-analyzer template, TMC exam study guide.
- Migration `0003_load_research` (Researcher JSON → claims + business_models, stage → researched) applied to the brain.
- Research, verification, Devil's Advocate and Financial passes on the three approved opportunities; Opportunity Reports (45 rows); Gate 1 decisions opened (rows 413–415); 2027 RT Examination pivot opportunity created; 4 lessons filed. Run artifacts in `factory/runs/2026-09-19/`.
- Scout run 2 (visible-sales-count rule, no-audience rule): 22 opportunities, 8 with sales-count comps; 2027 RT Examination pivot researched (blueprint published; first movers exist). Etsy sales figures re-labelled shop-level; lessons on evidence and shop clustering filed. Sequencing decision opened (row 419).
