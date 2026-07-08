# Material Intelligence System

Status: candidate
Category: world
Priority: P0
Maturity: system
Cost: high
Owner: Brayden
Last reviewed: 2026-07-08

## One-line pitch

A unified material-tag system where every surface, prop, projectile impact, footstep, decal, particle, and destruction reaction derives from the material being touched.

## Problem it solves

CUSTODIAN risks becoming expensive to polish if every sound, spark, dust puff, footstep, bullet hit, blood smear, scrape, and destruction effect has to be wired manually. A material intelligence system makes polish scalable: one material tag can drive audio, visual effects, combat feedback, traversal readability, stealth/noise behavior, and future destruction rules.

## Why it fits CUSTODIAN

CUSTODIAN is built around ruined infrastructure, dead machines, wet stone, ash, brass, glass, bone, ocean, signal machinery, temporal artifacts, and decayed industrial spaces. These materials should not be cosmetic. They should feel physically different.

The Operator walking over wet stone should sound different from walking over dry ash. Bullets hitting brass machinery should spark differently from bullets hitting bone, cloth, resin, glass, or corroded steel. The player should learn the world through material response.

## Player-facing effect

The player feels the world respond consistently.

Examples:

- Boots on wet stone produce heavier, slicker footstep sounds.
- Bullets hitting rusted steel produce sparks and a metallic ring.
- Shots into ash-covered floors produce dust clouds instead of sparks.
- Hitting memory glass creates high, brittle chimes and refracted particles.
- Heavy enemies walking on metal catwalks announce themselves through distant clanging.
- Resin growth muffles footsteps and catches light differently.
- Bone fields crackle under pressure and produce pale debris.
- Temporal material gives strange delayed impact sounds.

## Systems touched

- Footstep audio
- Projectile impact effects
- Melee hit reactions
- Decals
- Particle effects
- Tilemap metadata
- Prop metadata
- Enemy footsteps
- Destruction
- AI hearing/noise propagation
- Developer Observatory
- Procedural generation
- Biome design
- Performance budgeting

## Dependencies

Minimal version requires only a lookup table and material IDs on tiles/props.

Full version benefits from:

- Tile metadata conventions
- Projectile hit reporting
- Footstep event emission
- Particle/FX registry
- Audio event registry
- Developer Observatory logging
- Optional Sector Heatmap integration for noise

## Risks

The biggest risk is overbuilding the system before the game has enough real surfaces to justify it. Another risk is inconsistent tagging: if some tiles use `stone_wet` and others use `wet_stone`, effects will fragment.

The system also needs graceful fallbacks. Every unknown material should degrade to a safe default rather than breaking combat or FX.

## Material taxonomy

Start with a small canonical list.

Core physical materials:

- `stone_dry`
- `stone_wet`
- `metal_rusted`
- `metal_clean`
- `metal_hollow`
- `wood_rotted`
- `glass`
- `memory_glass`
- `ash`
- `soil`
- `mud`
- `bone`
- `cloth`
- `resin`
- `flesh`
- `water_shallow`
- `void_temporal`

Optional later tags:

- `brass`
- `obsidian`
- `ceramic`
- `cable_bundle`
- `machine_core`
- `coral_mechanical`
- `salt_crust`
- `blood_wet`
- `blood_dry`
- `lattice_field`

## Minimal version

Create a `MaterialRegistry` that maps material IDs to bundled response data.

Each material should define:

- Footstep sound group
- Projectile impact sound group
- Melee impact sound group
- Impact particle scene
- Decal type
- Noise multiplier
- Ricochet chance
- Dust/spark amount
- Optional color hint for debug overlays

Example behavior:

- Player footstep asks current tile for material.
- Player emits `footstep(material_id, position)`.
- MaterialRegistry picks the correct sound and particle response.
- Projectile collision asks impacted tile/body for material.
- MaterialRegistry spawns appropriate impact FX.

## Full version

The full version becomes a world-physics vocabulary.

Advanced features:

- Material layering: `wet + stone`, `ash + metal`, `blood + tile`.
- Temporary material overrides: fire, water, blood, oil, temporal residue.
- AI hearing uses material noise multipliers.
- Enemy weight modifies material response.
- Heavy enemies deform weak surfaces.
- Material-specific destruction produces salvage.
- Repair tools interact differently with materials.
- Developer Observatory can display material IDs under cursor.
- Procedural generation uses material transitions to make biomes coherent.

## Data shape

A Godot Resource works well long-term.

Suggested file:

`custodian/resources/materials/material_response.gd`

Fields:

- `material_id: StringName`
- `display_name: String`
- `footstep_audio_group: StringName`
- `projectile_impact_audio_group: StringName`
- `melee_impact_audio_group: StringName`
- `impact_fx_scene: PackedScene`
- `decal_id: StringName`
- `noise_multiplier: float`
- `ricochet_chance: float`
- `dust_amount: float`
- `spark_amount: float`
- `debug_color: Color`

## First useful implementation target

Do not try to wire everything.

Start with:

1. Player footsteps.
2. Bullet impacts.
3. Debug material readout.
4. Five materials only:
   - `stone_dry`
   - `stone_wet`
   - `metal_rusted`
   - `ash`
   - `memory_glass`

## Acceptance criteria

- Player footsteps change based on tile material.
- Projectile impact sound/particle changes based on material.
- Unknown materials safely use default response.
- Developer Observatory can show material at player position or mouse position.
- Material IDs are documented in one canonical list.

## Graduation criteria

Graduate when at least three gameplay surfaces exist and combat/footstep feedback needs shared material logic.

## Related cards

- Developer Observatory
- Sound Propagation
- Sector Heatmap
- Procedural Ruin Generator
- Performance Budget Manager
- Encounter Language

## Notes / references

This should become one of the main “polish multipliers” in CUSTODIAN. It is not just juice. It is how the game teaches the player what the world is made of.
