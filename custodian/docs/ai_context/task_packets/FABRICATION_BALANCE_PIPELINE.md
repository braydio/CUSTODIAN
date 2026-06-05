# Fabrication Balance Pipeline

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-06-05
- Created: 2026-06-05
- Last updated: 2026-06-05

## Task

Add a repeatable programmatic pipeline that simulates 30-minute fabrication/resource runs across drop-rate profiles and player build priorities, reports unaffordable/over-dominant/thematically-wrong recipes or drops, and writes JSON-only balance proposals.

## Outcome

The repo has a deterministic CLI that reads current fabrication recipes and resource definitions, uses an explicit scenario file, writes a Markdown report, and writes separate proposal JSON without mutating runtime balance data.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/resource_fabrication/RESOURCE_FABRICATION_SYSTEM.md`, `design/02_features/enemy_objective/GRUNT_LOOT_TABLE.md`
- Active runtime/docs files: `custodian/content/fabrication/fab_recipes.json`, `custodian/content/resources/resource_defs.json`, `custodian/autoload/fab_pipeline.gd`, `custodian/autoload/resource_ledger.gd`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change: `custodian/tools/balance/`, `custodian/content/balance/scenarios/`, `reports/fabrication_balance/`, this packet, active AI context indexes.
- Files or folders expected to be read but not changed: live fabrication recipes, resource definitions, enemy loot docs/runtime scene.
- Out-of-scope areas: automatic runtime recipe/drop-table edits, Godot gameplay behavior changes, new dependencies, production art.

## Constraints

- Determinism concerns: use seeded Python RNG and stable scenario inputs; no wall-clock or unordered simulation choices.
- Simulation/UI boundary concerns: this is an offline balance/report tool only and must not become gameplay authority.
- Asset requirements: none.
- Compatibility or migration concerns: keep output proposal-only so existing runtime JSON remains unchanged until reviewed.
- Clarifying questions or assumptions: the first 30-minute model approximates encounters/resource-node inflows rather than booting a full Godot run.

## Implementation Plan

1. Add a default scenario JSON covering build priorities, drop-rate profiles, resource nodes, grunt salvage, and sabotage-story loot.
2. Add a Python CLI that simulates the scenario against live recipes/resources and writes a report plus JSON proposals.
3. Update AI context indexes to make the pipeline discoverable.
4. Run Python syntax validation and a sample 30-minute report generation.

## Acceptance

- Runtime behavior: no live gameplay behavior changes.
- Documentation: task packet plus context/index references describe the pipeline and output contract.
- Path/reference validation: scenario, script, report, and proposal paths exist.
- Manual validation: inspect the generated report for recipe affordability, build/drop matrix, bottlenecks, and lore-drop review.
- Automated/headless validation: run `python -m py_compile custodian/tools/balance/fabrication_balance_pipeline.py` and a sample pipeline invocation.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes, workflow/tooling surface changed.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No unless broader guardrails change.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes, add tool and scenario/report references.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No runtime behavior/design authority changed; the scenario is tool input.

## Completion Notes

- Implemented: Added `custodian/tools/balance/fabrication_balance_pipeline.py`, the default explicit scenario at `custodian/content/balance/scenarios/default_fabrication_run.json`, and generated report/proposal outputs under `reports/fabrication_balance/`.
- Validated: `python -m py_compile custodian/tools/balance/fabrication_balance_pipeline.py`; `python custodian/tools/balance/fabrication_balance_pipeline.py --seeds 25` produced 225 deterministic sample runs with zero lore rule violations.
- Deferred: full Godot run simulation and automatic proposal application are intentionally deferred.

## Next Steps

- Next action: Review `reports/fabrication_balance/proposed_changes.json` before applying any balance edits.
- Best starting files: `custodian/tools/balance/fabrication_balance_pipeline.py`, `custodian/content/balance/scenarios/default_fabrication_run.json`
- Required context: live recipes in `custodian/content/fabrication/fab_recipes.json` and resource definitions in `custodian/content/resources/resource_defs.json`
- Validation to run: `python -m py_compile custodian/tools/balance/fabrication_balance_pipeline.py`; `python custodian/tools/balance/fabrication_balance_pipeline.py --seeds 100`
- Blockers or open questions: none for the first repeatable pipeline.
