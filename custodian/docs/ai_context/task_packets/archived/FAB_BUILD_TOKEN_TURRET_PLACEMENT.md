# FAB BUILD TOKEN TURRET PLACEMENT

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-09
- Created: 2026-05-09
- Last updated: 2026-05-09

## Task

Connect completed fabrication build tokens to the existing turret placement path.

## Outcome

Completed `turret_basic` build tokens should allow placing a basic/gunner turret through the existing `TurretPlacement` placement mode without requiring legacy material cost.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/features/implementation/FAB_PIPELINE_SYSTEM.md`
- Active runtime/docs files: `custodian/game/systems/core/systems/turret_placement.gd`, `custodian/autoload/build_inventory.gd`
- Historical reference only: `design/04_research/resource_fabrication/*`, `python-sim/`

## Work Surface

- Files or folders expected to change: `custodian/game/systems/core/systems/turret_placement.gd`, docs/context
- Files or folders expected to be read but not changed: fabrication autoloads and recipe JSON
- Out-of-scope areas: barricade placement, full buildable registry, production placement UI

## Constraints

- Determinism concerns: Token consumption must be explicit and refunded if placement cannot instantiate.
- Simulation/UI boundary concerns: `BuildInventory` owns token counts; `TurretPlacement` only checks/consumes tokens.
- Asset requirements: None.
- Compatibility or migration concerns: Preserve legacy material placement fallback.
- Clarifying questions or assumptions: Map `turret_basic` to the existing `gunner` turret for V1.

## Implementation Plan

1. Add a build-token map to `TurretPlacement`.
2. Allow entering placement mode when a matching token exists.
3. Consume the token on successful placement and refund it if instantiation fails.
4. Validate script/project load and update docs.

## Acceptance

- Runtime behavior: `turret_basic` token permits `gunner` placement without materials.
- Documentation: Context notes token-to-turret placement path.
- Path/reference validation: No new runtime paths.
- Manual validation: Headless project load.
- Automated/headless validation: `godot --headless --check-only --script res://game/systems/core/systems/turret_placement.gd`.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Update implementation note.

## Completion Notes

- Implemented: Added `TURRET_BUILD_TOKENS` mapping in `TurretPlacement`, allowed `turret_basic` tokens to unlock `gunner` placement mode, consumed tokens on placement, and refunded token consumption if turret scene instantiation fails.
- Validated: `godot --headless --check-only --script res://game/systems/core/systems/turret_placement.gd`; `godot --headless --quit`.
- Deferred: `barricade_light`, `reinforced_panel`, and `sensor_pylon_basic` placement; full buildable registry.

## Next Steps

- Next action: Add broader buildable placement or terminal/fabricator UI.
- Best starting files: `custodian/game/systems/core/systems/turret_placement.gd`
- Required context: Existing turret placement material path and `BuildInventory` autoload.
- Validation to run: Script check and project headless load.
- Blockers or open questions: None.
