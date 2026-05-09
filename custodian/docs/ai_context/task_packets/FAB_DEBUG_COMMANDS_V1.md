# FAB DEBUG COMMANDS V1

## Packet Status

- Status: in_progress
- Owner: agent
- Agent/session: Codex 2026-05-09
- Created: 2026-05-09
- Last updated: 2026-05-09

## Task

Expose the new fabrication runtime spine through DevConsole commands so the resource/fabrication loop can be tested without direct autoload calls.

## Outcome

DevConsole should support inspecting recipes/status, granting starter resources, and starting recipes through `FabPipeline`.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/features/implementation/FAB_PIPELINE_SYSTEM.md`
- Active runtime/docs files: `custodian/game/ui/hud/ui.gd`, `custodian/autoload/resource_ledger.gd`, `custodian/autoload/fab_pipeline.gd`, `custodian/autoload/build_inventory.gd`
- Historical reference only: `design/04_research/resource_fabrication/*`, `python-sim/`

## Work Surface

- Files or folders expected to change: `custodian/game/ui/hud/ui.gd`, active AI context docs
- Files or folders expected to be read but not changed: fabrication autoloads
- Out-of-scope areas: full terminal page UI, placement mode, save/load

## Constraints

- Determinism concerns: Debug grants are explicit test helpers only.
- Simulation/UI boundary concerns: DevConsole calls into runtime autoload APIs; it does not own fabrication state.
- Asset requirements: None.
- Compatibility or migration concerns: Existing DevConsole commands must remain unchanged.
- Clarifying questions or assumptions: DevConsole is the fastest usable surface before dedicated terminal/fabricator UI.

## Implementation Plan

1. Register fab debug commands in the existing HUD DevConsole setup.
2. Add command handlers for status, recipes, starter grants, and recipe starts.
3. Validate `ui.gd` and project load.

## Acceptance

- Runtime behavior: `fab_grant` adds starter resources, `fab_start barricade_light` starts a job when affordable, and `fab_status` reports resources/jobs/tokens.
- Documentation: Active context and this packet mention the debug command surface.
- Path/reference validation: No new paths required.
- Manual validation: Headless project load.
- Automated/headless validation: `godot --headless --check-only --script res://game/ui/hud/ui.gd`.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Update implementation next-step note.

## Completion Notes

- Implemented:
- Validated:
- Deferred:

## Next Steps

- Next action: Add DevConsole command handlers.
- Best starting files: `custodian/game/ui/hud/ui.gd`
- Required context: Existing DevConsole command registration in the HUD.
- Validation to run: `godot --headless --check-only --script res://game/ui/hud/ui.gd`; `godot --headless --quit`
- Blockers or open questions: None.
