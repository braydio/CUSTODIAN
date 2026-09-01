#!/usr/bin/env python3
import json, sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/"custodian/tools/operator"))
from animation_preview import validate_plan

plan=json.loads((ROOT/"design/02_features/animation/OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json").read_text())
catalog=json.loads((ROOT/"custodian/content/data/operator/generated/operator_animation_catalog.generated.json").read_text())
rows=validate_plan(plan,catalog)
assert rows and [x["rank"] for x in rows]==sorted(x["rank"] for x in rows)
assert len({x["rank"] for x in rows})==len(rows)==len({x["id"] for x in rows})
assert all(0<=x["coverage"]<=x["coverage_total"] for x in rows)
assert rows[0]["id"]=="melee_1h_walk" and rows[0]["state"]=="active"
print("operator_animation_plan_smoke ok")
