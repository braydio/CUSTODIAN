# Gothic Compound Perimeter And Readability Pass

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-19
- Created: 2026-05-19
- Last updated: 2026-05-19

## Task

Make the generated gothic compound read more clearly as a fortified gothic-industrial compound without redesigning the generator or increasing asset density.

## Outcome

- Primary perimeter reads as wall/post/gatehouse rather than sandbag boundary.
- South gate is visually explicit and passable.
- Command keep has a clean front plaza.
- Interior floor and decals are calmer.
- Grates are placed around utility/power areas rather than as generic courtyard noise.
- Exterior scatter is clustered around causes instead of evenly sprinkled.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/features/implementation/GOTHIC_COMPOUND_PROCGEN.md`
- Active runtime/docs files: `custodian/game/world/procgen/gothic_compound/`, `custodian/game/world/gothic_compound/gothic_compound_map.gd`
- Historical reference only: previous gothic connected-map packet

## Work Surface

- Files or folders expected to change:
  - `custodian/game/world/procgen/gothic_compound/`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
  - `design/features/implementation/GOTHIC_COMPOUND_PROCGEN.md`
- Files or folders expected to be read but not changed:
  - `custodian/content/procgen/special_rooms/gothic_compound/`
- Out-of-scope areas:
  - replacing the Sprite2D adapter with TileMapLayer integration
  - adding new production art
  - changing combat encounters or save/load

## Constraints

- Determinism concerns: placement must stay seed-derived and repeatable.
- Simulation/UI boundary concerns: this is world layout only.
- Asset requirements: use existing sliced gothic compound PNGs.
- Compatibility or migration concerns: preserve current connected-map travel behavior.
- Clarifying questions or assumptions: no new art; use existing wall/corner/pillar/gate/lamp/ruin assets as available.

## Implementation Plan

1. Add zone metadata for keep plaza and utility/decal anchors.
2. Tighten perimeter/gate placement with posts, corner bastion accents, and secondary sandbag placement only.
3. Replace random interior grates with zone-specific utility decals and replace exterior scatter with deterministic clusters.

## Acceptance

- Runtime behavior:
  - Required path from map edge to gate to keep remains walkable.
  - Perimeter validator still passes.
  - Gate lane remains unblocked.
- Documentation:
  - Current state and file index mention the readability pass if runtime behavior changed.
- Path/reference validation:
  - New or changed paths resolve.
- Manual validation:
  - Next screenshot should read as a fortified gothic compound with clearer hierarchy.
- Automated/headless validation:
  - Godot check-only for changed gothic scripts and full headless project load.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes.

## Completion Notes

- Implemented: Added wall/post/gatehouse perimeter grammar, corner bastion posts, explicit gate pillars/lamps, keep-plaza exclusion, zone-specific grates/decals, and clustered exterior scatter while preserving required path validation.
- Validated: Godot check-only passed for the gothic generator, asset definitions, validator, and connected map scripts; full `godot --headless --path custodian --quit` loaded successfully with only the existing exit leak/resource warnings.
- Deferred: Exact visual footprint tuning still needs screenshot/live-play review; main tactical-map TileMapLayer integration remains separate.

## Next Steps

- Next action: live-review the next screenshot and tune exact footprints/asset choices if needed.
- Best starting files: `custodian/game/world/procgen/gothic_compound/gothic_compound_generator.gd`
- Required context: current screenshot notes and `GOTHIC_COMPOUND_PROCGEN.md`
- Validation to run: Godot check-only for gothic procgen scripts and full headless project load.
- Blockers or open questions: none.
