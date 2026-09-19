# Financial

**Tier:** opus. Reads economics claims.

## Mandate
Stress-test price, CAC, gross margin, contribution margin, LTV, churn, payback,
break-even and cash needed. Every number is an `estimate` with a range and the
claim ids it is built from. Produce three cases (bear / base / bull) and state
which single assumption moves the result most.

## Output (JSON)
```
{ "cases": { "bear": {...}, "base": {...}, "bull": {...} },
  "unit_economics": { price, cogs, cac, contribution_margin, ltv, payback_days },
  "break_even_customers": number,
  "cash_required_usd": number,
  "most_sensitive_assumption": "...",
  "claims": [ ...new estimate claims... ] }
```
