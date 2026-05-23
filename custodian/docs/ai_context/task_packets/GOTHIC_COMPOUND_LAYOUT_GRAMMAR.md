# Gothic Compound Layout Grammar

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-19
- Created: 2026-05-19
- Last updated: 2026-05-19

## Task

Refactor the gothic compound generator so the connected-map compound uses asset metadata, top-left sprite anchoring, quieter terrain/decal rules, zone-aware placement, stronger perimeter validation, and placement flags/errors.

## Outcome

The generated gothic compound should read as a fortified yard with a clear perimeter, south gate, approach road, internal path, focal command keep, reachable terminal, lower decal density, and more reliable collision/occupancy for large assets.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/features/implementation/GOTHIC_COMPOUND_PROCGEN.md`
- Active runtime/docs files: `custodian/game/world/procgen/gothic_compound/*`, `custodian/game/world/gothic_compound/gothic_compound_map.gd`, `custodian/docs/ai_context/CURRENT_STATE.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change: gothic compound procgen scripts, active design doc, AI context docs, this packet.
- Files or folders expected to be read but not changed: gothic compound sliced PNG assets and classification notes.
- Out-of-scope areas: new production art, main procgen room graph, contract generation semantics.

## Constraints

- Determinism concerns: keep generation seeded from the existing gothic compound seed and avoid non-deterministic layout choices.
- Simulation/UI boundary concerns: this is world layout/rendering/collision generation, not combat or terminal behavior.
- Asset requirements: use existing sliced assets under `res://content/procgen/special_rooms/gothic_compound/`.
- Compatibility or migration concerns: preserve existing context method names as wrappers while adding metadata-aware placement.
- Clarifying questions or assumptions: treat asset footprints as approximate grid metadata derived from current PNG sizes and screenshot feedback; leave final per-asset tuning for visual review.

## Implementation Plan

1. Add a `gothic_compound_asset_defs.gd` metadata registry.
2. Patch `GothicCompoundSpriteContext` to support metadata-aware top-left placement and collision.
3. Update result/config/validator with flags, placement errors, zones, lower decal chance, and perimeter validation.
4. Refactor generator placement to use zones, calmer macro terrain patches, quota decals, chunked long roads, and secondary sandbag cover.
5. Update docs and run Godot validation.

## Acceptance

- Runtime behavior: gothic compound generation still returns an accepted result and produces a reachable gate/keep/terminal path.
- Documentation: design doc and AI context mention metadata/zoning validator hardening.
- Path/reference validation: new asset defs use `res://content/procgen/special_rooms/gothic_compound/`.
- Manual validation: screenshot/playtest remains recommended for final footprint tuning.
- Automated/headless validation: run Godot script checks for changed modules and project boot.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes, for the new asset defs file.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes, `design/features/implementation/GOTHIC_COMPOUND_PROCGEN.md`.

## Completion Notes

- Implemented: added metadata asset definitions, top-left sprite anchoring, footprint-aware collision/occupancy, zone records, calmer macro terrain patches, chunked east-west road placement, quota/focal decals, secondary gate defenses, placement flags/errors, and perimeter topology validation.
- Validated: Godot script checks passed for `gothic_compound_asset_defs.gd`, `gothic_compound_sprite_context.gd`, `gothic_compound_generator.gd`, and `gothic_compound_validator.gd`; full `godot --headless --path custodian --quit` booted without gothic blueprint failure.
- Deferred: exact per-asset footprint tuning should continue from fresh screenshots/playtest because current footprints are grid approximations from PNG dimensions.

## Next Steps

- Next action: review a fresh gothic compound screenshot and tune individual asset footprints/zone offsets if visual overlap remains.
- Best starting files: `custodian/game/world/procgen/gothic_compound/`
- Required context: current screenshot diagnosis and sliced asset dimensions.
- Validation to run: optional visual playtest/screenshot pass.
- Blockers or open questions: none.
