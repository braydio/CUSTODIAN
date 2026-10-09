#!/usr/bin/env python3
import json, sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/"custodian/tools/operator"))
from animation_preview import validate_plan

plan=json.loads((ROOT/"design/02_features/animation/OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json").read_text())
catalog=json.loads((ROOT/"custodian/content/data/operator/generated/operator_animation_catalog.generated.json").read_text())
rows=validate_plan(plan,catalog)
assert rows and len({x["id"] for x in rows})==len(rows)
assert len({(x["art_generation"],x["rank"]) for x in rows})==len(rows)
assert all(0<=x["coverage"]<=x["coverage_total"] for x in rows)
targets=[x for x in rows if x["art_generation"]=="operator_2_5d_128"]
legacy=[x for x in rows if x["art_generation"]=="legacy_96"]
assert len(targets)==69 and len(legacy)==18
assert targets[0]["id"]=="operator_2_5d_unarmed_posture_idle_relaxed_01"
assert targets[0]["migration_verdict"]=="canonical_2_5d"
assert targets[0]["coverage"]==8 and targets[0]["coverage_total"]==8
assert sum(row["coverage_total"]-row["coverage"] for row in targets)==544
assert next(x for x in legacy if x["id"]=="melee_1h_walk")["state"]=="active"
assert all(x["group"]!="action" for x in rows)
legacy_item=next(x for x in legacy if x["id"]=="melee_1h_walk")
v1_fields=("id","rank","priority","profile","group","action","directions","required_layers","state","reason")
v1_payload={"schema":"custodian.operator_animation_implementation_plan.v1",
            "items":[{key:legacy_item[key] for key in v1_fields}]}
v1_rows=validate_plan(v1_payload,catalog)
assert len(v1_rows)==1 and v1_rows[0]["art_generation"]=="legacy_96"
assert v1_rows[0]["rank"]==legacy_item["rank"] and v1_rows[0]["state"]=="active"
print("operator_animation_plan_smoke ok")
