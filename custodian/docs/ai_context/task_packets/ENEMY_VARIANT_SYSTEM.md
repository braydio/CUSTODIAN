# ENEMY VARIANT SYSTEM TASK PACKET

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-06
- Created: 2026-05-06 05:08 EDT
- Last updated: 2026-05-06 05:08 EDT

## Task

Implement the first Godot runtime slice of `design/ENEMY_VARIANT_SYSTEM.md` for the enemy spritesheets currently present in the project, with wolf variants generated through a deterministic profile factory and applied to spawned enemies.

## Outcome

Wolf enemy variants are generated as data-only `EnemyVariantProfile` resources from seed, biome, threat level, and context; spawned enemies can consume those profiles for stats, tint, scale, collision, behavior ids, and wolf sprite animations.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/ENEMY_VARIANT_SYSTEM.md`
- Active runtime/docs files: `custodian/game/actors/enemies/enemy.gd`, `custodian/game/systems/core/systems/enemy_factory.gd`, `custodian/game/systems/core/systems/wave_manager.gd`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change: `custodian/game/enemies/procgen/`, `custodian/game/actors/enemies/enemy.gd`, `custodian/game/systems/core/systems/enemy_factory.gd`, `custodian/game/systems/core/systems/wave_manager.gd`, AI context docs
- Files or folders expected to be read but not changed: `custodian/content/sprites/enemies/wolf/`, `custodian/scenes/game.tscn`
- Out-of-scope areas: full beast-pack alpha extraction, Aseprite rebake tools, bespoke wolf combat AI scene rewrite

## Constraints

- Determinism concerns: variant generation must use stable seed streams and avoid global RNG where variant results matter.
- Simulation/UI boundary concerns: factory generates data only; enemy actor applies data at spawn time.
- Asset requirements: use the wolf PNG sheets already available under `res://content/sprites/enemies/wolf/`.
- Compatibility or migration concerns: keep existing drone/generic enemy scenes working and keep legacy `drone`, `fast`, and `heavy` type ids valid.
- Clarifying questions or assumptions: wolf sheets have no JSON beside them, so the first runtime library slices each sheet by square frame height.

## Implementation Plan

1. Add profile, factory, animation library, and palette shader resources under `game/enemies/procgen/`.
2. Extend the existing `Enemy` actor with `apply_variant(profile)` and wolf animation playback support.
3. Route `EnemyFactory` and `WaveManager` so compositions may include `"wolf"` and spawned enemies receive deterministic profiles.
4. Update AI context docs and validate with Godot headless.

## Acceptance

- Runtime behavior: wave spawning can instantiate a wolf variant and still supports existing enemy type ids.
- Documentation: current state and file index mention the implemented variant slice.
- Path/reference validation: new `res://` paths load in Godot.
- Manual validation: not required for this headless pass.
- Automated/headless validation: `cd custodian && godot --headless --quit`.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No, implementation follows the active spec.

## Completion Notes

- Implemented: Added wolf profile resource, deterministic variant factory, wolf animation library, palette shader, `Enemy.apply_variant(profile)`, deterministic `"wolf"` composition support, and wave-spawn profile application.
- Validated: `cd custodian && godot --headless --quit`.
- Deferred: Beast-pack alpha extraction, Aseprite JSON rebaking/normalization, overlays, dedicated wolf scene tree, precise attack windows, and visual QA lab.

## Next Steps

- Next action: playtest assault waves and tune wolf composition weight, sprite scale, attack range, and collision radius.
- Best starting files: `custodian/game/systems/core/systems/enemy_factory.gd`, `custodian/game/systems/core/systems/wave_manager.gd`, `custodian/game/actors/enemies/enemy.gd`
- Required context: `design/ENEMY_VARIANT_SYSTEM.md`
- Validation to run: `cd custodian && godot --headless --quit`
- Blockers or open questions: none for the first wolf runtime slice.
