# PROCGEN PORTAL SAFE PLACEMENT

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-09
- Created: 2026-05-09
- Last updated: 2026-05-09

## Task

Make procgen portal-ring placement safer so paired teleporters do not spawn embedded in or visually overlapping wall clusters.

## Outcome

Portal-ring endpoints should be selected from portal-specific safe floor tiles, existing unsafe scattered portal props should be discarded and replaced, and guaranteed portal endpoints should avoid prop jitter that can push the large ring into walls.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/procgen/INDOOR_OUTDOOR_PROCGEN_REGIONS.md`
- Active runtime/docs files: `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change: `custodian/game/world/procgen/proc_gen_tilemap.gd`, active AI context docs, this packet
- Files or folders expected to be read but not changed: `custodian/AGENTS.md`, procgen docs/context indexes
- Out-of-scope areas: Portal FX playback, prop art, biome-to-planet portal routing

## Constraints

- Determinism concerns: Placement must remain tile/seed deterministic.
- Simulation/UI boundary concerns: This is procgen placement only; teleport trigger logic remains in `portal_teleporter.gd`.
- Asset requirements: None.
- Compatibility or migration concerns: Existing `portal_ring_01` prop definition remains the endpoint asset.
- Clarifying questions or assumptions: Use a stricter clear floor footprint and wall clearance for portals than normal decorative props.

## Implementation Plan

1. Add portal-specific footprint and wall-clearance exports to `ProcGenTilemap`.
2. Filter and snap existing scattered portal props before pairing; discard unsafe portal props.
3. Restrict guaranteed endpoint selection to safe portal tiles and spawn them centered without jitter.
4. Validate scripts and update docs/context.

## Acceptance

- Runtime behavior: Paired portal endpoints are only accepted on clear floor footprints with no nearby wall cells.
- Documentation: Current state and file ownership mention portal-safe placement.
- Path/reference validation: Changed file paths remain indexed.
- Manual validation: Not run unless a full Godot scene boot is available.
- Automated/headless validation: Run Godot script checks for procgen and portal teleporter scripts.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No separate design doc change required for this small runtime safety refinement.

## Completion Notes

- Implemented: Added portal-specific floor-footprint and wall-clearance exports, rejected unsafe scattered portal props, constrained guaranteed portal tile selection to safe candidates, and centered portal props without ruin-prop jitter.
- Validated: `godot --headless --check-only --script res://game/world/procgen/proc_gen_tilemap.gd`; `godot --headless --check-only --script res://game/world/procgen/portal_teleporter.gd`.
- Deferred: Full scene boot/playtest to visually confirm portal spacing in generated maps.

## Next Steps

- Next action: Playtest a generated map and verify portal rings do not overlap wall art or block player arrival.
- Best starting files: `custodian/game/world/procgen/proc_gen_tilemap.gd`
- Required context: Existing paired portal endpoint wiring and ruin prop scatterer source-tile metadata.
- Validation to run: `godot --headless --check-only --script res://game/world/procgen/proc_gen_tilemap.gd`
- Blockers or open questions: None.
