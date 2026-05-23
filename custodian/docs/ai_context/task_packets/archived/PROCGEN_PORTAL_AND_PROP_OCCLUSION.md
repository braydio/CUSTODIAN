# PROCGEN PORTAL AND PROP OCCLUSION

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-10
- Created: 2026-05-10
- Last updated: 2026-05-10

## Task

Harden portal-ring procgen placement against nearby wall collision and add lightweight ruin-prop collision and player-relative occlusion hooks so tall props can sit behind the operator when appropriate.

## Outcome

Portal endpoints should nudge to a nearby safe tile if a local collision probe or wall clearance check fails, and authored ruin props should support simple runtime collision footprints plus explicit occlusion bounds so tall props can sort behind or in front of the player based on their actual visual span without requiring a bespoke collision scene for every prop.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/procgen/DESTRUCTIBLE_PROCGEN_WALLS.md`, `design/02_features/props/PROCEDURAL_PROP_VARIANT_SYSTEM.md`
- Active runtime/docs files: `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/content/props/ruins/scripts/PropDefinition.gd`, `custodian/content/props/ruins/scripts/ProceduralProp.gd`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`
- Historical reference only: older static ruin-prop behavior

## Work Surface

- Files or folders expected to change: `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/content/props/ruins/scripts/PropDefinition.gd`, `custodian/content/props/ruins/scripts/ProceduralProp.gd`, selected ruin prop definition resources, active AI context docs
- Files or folders expected to be read but not changed: terminal/UI code, unrelated gameplay systems, asset pipeline code
- Out-of-scope areas: new prop art, save/load, global scene-wide Y-sort refactor

## Constraints

- Determinism concerns: portal relocation must remain seed and tile deterministic.
- Simulation/UI boundary concerns: this is a runtime world-prop and procgen change, not a HUD change.
- Asset requirements: reuse existing ruin-prop art; collision and occlusion should be authored in data/code first.
- Compatibility or migration concerns: existing prop definitions should continue to load if they do not opt into the new fields.
- Clarifying questions or assumptions: use a small local search radius and a half-tile collision probe for portal safety; only tall props opt into depth sorting.

## Implementation Plan

1. Add a deterministic local portal-tile relocation helper that probes for nearby collision and wall clearance.
2. Extend ruin prop definitions with simple collision footprint fields and player-relative depth-sort toggles.
3. Wire procgen to update ruin prop draw order against the player and update selected prop definitions.
4. Update active docs and validate the changed scripts in headless Godot.

## Acceptance

- Runtime behavior: portal endpoints avoid nearby wall collision and relocate to a safe neighboring tile when needed.
- Runtime behavior: tall ruin props can sit behind the player visually and can expose simple blocker collision without a bespoke scene.
- Documentation: current state, file index, and prop-system design note describe the new hooks.
- Path/reference validation: all changed files remain indexed and loadable.
- Automated/headless validation: run Godot script checks for the procgen and prop runtime scripts.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes
- Does `custodian/AGENTS.md` need an update? No
- Do any design docs need an update? Yes

## Completion Notes

- Implemented: portal endpoint relocation helper, collision-probe-based portal safety, inline collision footprint support, explicit occlusion bounds, player-relative ruin-prop depth sorting, portal ring platform-style collision/occlusion tuning, and initial prop-definition updates.
- Validated: `godot --headless --path /home/linux/Projects/CUSTODIAN/custodian --check-only --script res://game/world/procgen/proc_gen_tilemap.gd`; `godot --headless --path /home/linux/Projects/CUSTODIAN/custodian --check-only --script res://content/props/ruins/scripts/ProceduralProp.gd`; `godot --headless --path /home/linux/Projects/CUSTODIAN/custodian --check-only --script res://content/props/ruins/scripts/PropDefinition.gd`
- Deferred: no full scene boot or in-world playtest yet

## Next Steps

- Next action: patch the procgen portal placement and prop runtime scripts.
- Best starting files: `custodian/game/world/procgen/proc_gen_tilemap.gd`
- Required context: existing portal-ring teleport wiring and the ruin prop variant system.
- Validation to run: Godot headless script checks for the procgen and prop scripts.
- Blockers or open questions: none
