# PROCGEN PORTAL PAIR TELEPORT

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-09
- Created: 2026-05-09
- Last updated: 2026-05-09

## Task

Make the procgen portal ring prop pair with a second portal and teleport the operator between the two portal locations.

## Outcome

Runtime procgen guarantees a paired `portal_ring_01` endpoint set on the active tactical map and wires each portal with a deterministic cooldown-gated teleport trigger.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/props/PROCEDURAL_PROP_VARIANT_SYSTEM.md`
- Active runtime/docs files: `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/content/props/ruins/scripts/ProceduralProp.gd`, `custodian/content/props/ruins/scripts/PropScatterer.gd`, `custodian/content/props/ruins/data/prop_definitions/portal_ring_01.tres`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change:
  - `custodian/game/world/procgen/proc_gen_tilemap.gd`
  - `custodian/game/world/procgen/portal_teleporter.gd`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
  - `custodian/docs/ai_context/task_packets/README.md`
  - this packet
- Files or folders expected to be read but not changed:
  - `custodian/content/props/ruins/scripts/ProceduralProp.gd`
  - `custodian/content/props/ruins/scripts/PropScatterer.gd`
  - `custodian/content/props/ruins/data/ruin_prop_spawn_set.tres`
- Out-of-scope areas:
  - cross-planet travel
  - loading a second tactical map
  - portal animation/VFX/audio

## Constraints

- Determinism concerns: portal placement and teleport cooldown must use deterministic map seed/tile data and physics-frame cooldowns, not wall-clock time.
- Simulation/UI boundary concerns: teleport behavior lives in world/runtime scripts, not HUD.
- Asset requirements: use existing `portal_ring_01` prop art.
- Compatibility or migration concerns: existing decorative prop scatter should continue to work.
- Clarifying questions or assumptions: v1 links portals inside the active tactical map. Different-biome/different-planet travel is deferred until world streaming/contract handoff exists.

## Implementation Plan

1. Add a reusable `PortalTeleporter` component.
2. Extend procgen ruin prop placement to guarantee exactly enough portal endpoints for a pair when possible.
3. Link portal components after placement and apply safe arrival offsets.
4. Update active context docs and validate.

## Acceptance

- Runtime behavior: entering one portal teleports the operator to its paired portal.
- Runtime behavior: cooldown prevents immediate bounce-back.
- Runtime behavior: portal pair placement is deterministic from generated map data.
- Documentation: current state and file index describe the new portal system.
- Path/reference validation: new script path is indexed.
- Automated/headless validation: Godot script check or headless boot.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Not for this v1 runtime slice; a future cross-planet portal design needs a dedicated design doc.

## Completion Notes

- Implemented: added `PortalTeleporter` trigger component, recorded prop source tiles in `PropScatterer`, and extended `ProcGenTilemap` to guarantee and link two deterministic `portal_ring_01` endpoints when portal pairing is enabled.
- Validated: `godot --headless --check-only --script res://game/world/procgen/portal_teleporter.gd`; `godot --headless --check-only --script res://game/world/procgen/proc_gen_tilemap.gd`; `godot --headless --check-only --script res://content/props/ruins/scripts/PropScatterer.gd`; game scene boot reached normal system initialization without script/resource errors before manual stop because the `--scene` process did not exit.
- Deferred: cross-biome and cross-planet portal destinations remain future work and need a world/contract handoff design.

## Next Steps

- Next action: in-editor playtest portal trigger size, arrival offset, and visual affordance.
- Best starting files: `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/game/world/procgen/portal_teleporter.gd`
- Required context: ruin prop scatterer, portal prop definition, operator scene path.
- Validation to run: `cd custodian && godot`, then enter each portal and confirm paired teleport without bounce-back.
- Blockers or open questions: cross-biome/planet target rules are not designed yet.
