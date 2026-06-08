## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-06-07
- Created: 2026-06-07
- Last updated: 2026-06-07

## Task

Non-destructively re-author the existing Sundered Keep V1 front-gate slice into the
cheat-sheet route hierarchy and fortress floorplan.

## Outcome

The active large front-gate JSON is generated deterministically from the preserved
V1 layout, retains progression/interaction/cutaway metadata, and explicitly
describes the causeway, lower lanes, Return Mooring, Gatehouse Core, courtyard,
west service yard, east rampart, and Great Hall exterior/interior spaces.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/world_expansion/THE_SUNDERED_KEEP_LEVEL_SET.md`
- Active runtime/docs files: `custodian/game/world/sundered_keep/`, `custodian/content/levels/sundered_keep/`, `custodian/docs/ai_context/`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change: Sundered Keep large layout JSON/generator/smoke, active design and AI context docs, required asset trackers
- Files or folders expected to be read but not changed: Sundered Keep runtime map/loader and existing asset catalogs
- Out-of-scope areas: true same-coordinate stacked traversal, production art replacement, multi-floor keep expansion

## Constraints

- Determinism concerns: generated operations and metadata must be stable across reruns
- Simulation/UI boundary concerns: layout metadata remains authored data; runtime interaction authority stays in `sundered_keep_map.gd`
- Asset requirements: reuse registered assets and explicit existing `PLACEHOLDER_*` readability art
- Compatibility or migration concerns: preserve the current V1 JSON before migration and retain all gameplay-critical top-level keys
- Clarifying questions or assumptions: the textual cheat-sheet requirements are sufficient; no separate image attachment is available in this session

## Implementation Plan

1. Preserve the current V1 JSON and establish a deterministic generator baseline.
2. Generate named zones, route/elevation metadata, visible blocker coverage, and readable fortress geometry without dropping current gameplay metadata.
3. Expand smoke coverage, update active docs/asset tracking, and validate deterministic output plus Godot runtime behavior.

## Acceptance

- Runtime behavior: existing gate/key/mooring/siege/Great Hall behavior remains functional
- Documentation: active design/current-state/file-index/asset tracking describe the relayout and V1 limitation
- Path/reference validation: preservation copy and generator are indexed and referenced paths exist
- Manual validation: deferred to in-editor visual review
- Automated/headless validation: generator determinism and Sundered Keep large-layout smoke pass

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes
- Does `custodian/AGENTS.md` need an update? No
- Do any design docs need an update? Yes

## Completion Notes

- Implemented: preservation copy, deterministic relayout generator, named zones/routes, expanded elevation/transitions, blocker visual coverage, placeholder sidecars/manifest/runtime registration, smoke assertions, and active docs
- Validated: generator Python compile, JSON parsing, identical hashes across consecutive generator runs, zero unresolved generated asset IDs, 21/21 blocker visual coverage, and relayout-specific large-layout smoke assertions through route/cutaway/elevation checks
- Deferred: in-editor visual polish and production replacement art; the full large-layout smoke currently stops on the concurrently modified Great Hall marine dash asset readiness assertion after all relayout-specific checks pass

## Next Steps

- Next action: visually review the generated slice in-editor and replace registered placeholder readability art as production assets arrive
- Best starting files: `custodian/tools/levels/generate_sundered_keep_front_gate_layout.py`, `custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.json`
- Required context: preserved V1 JSON and current large-layout smoke
- Validation to run: rerun the Godot large-layout smoke after the concurrent Great Hall marine dash asset work is restored/finished
- Blockers or open questions: full smoke completion is blocked by unrelated current Great Hall marine dash body readiness
