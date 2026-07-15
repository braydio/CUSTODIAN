# Procedural Prop Variant System

Status: in progress
Last updated: 2026-07-15

## Goal

Provide a Godot-native visual variant system for pixel-art ruin props without AI generation or runtime image synthesis.

The system composes variants from:

- one authored base sprite
- optional authored overlay sprites
- optional authored rubble sprites
- conservative shader palette shifts
- deterministic seeded placement
- optional stable collision scene authored separately from visuals
- optional authored collision footprint fields for simple blocker shapes
- optional player-relative depth sorting for tall props that should tuck behind the operator when the player is in front of them

## Runtime Files

- `custodian/content/props/ruins/scenes/ProceduralProp.tscn`
- `custodian/content/props/ruins/scripts/ProceduralProp.gd`
- `custodian/content/props/ruins/scripts/PropDefinition.gd`
- `custodian/content/props/ruins/scripts/PropVariantLayer.gd`
- `custodian/content/props/ruins/scripts/PropVariantGenerator.gd`
- `custodian/content/props/ruins/scripts/WeightedPropEntry.gd`
- `custodian/content/props/ruins/scripts/PropSpawnSet.gd`
- `custodian/content/props/ruins/scripts/PropScatterer.gd`
- `custodian/content/props/ruins/shaders/prop_palette_variation.gdshader`
- `custodian/content/props/ruins/README.md`

## Behavior

`ProceduralProp` is a visual `Node2D` assembly scene. It uses a `PropDefinition` resource plus `variant_seed` to regenerate the same variant at the same seed. `VariantIntensity` exposes four visual states:

- `ORIGINAL`: base sprite only
- `SUBTLE`: small tone shifts and light detail
- `DRAMATIC`: stronger tone shifts and more overlays/rubble
- `RETURNED`: near-original palette with a few residual details

Collision is never generated from visual output. `PropDefinition.collision_scene` supplies an authored stable footprint when needed. For simple props, `PropDefinition` can also describe a lightweight rectangle/capsule-style blocker footprint directly so the runtime does not need a bespoke scene for every prop.

The `ProceduralProp` root is the floor/contact anchor. Its centered base sprite is placed at `-anchor_offset`, while `collision_shape_offset` is the collision center in that same root-local coordinate space. Bottom-anchored floor prop collision should normally end near local `y=0`; intentional below-anchor collision must opt into `collision_allows_below_anchor`. Runtime alignment reports expose visual and collision rectangles in root-local/global space, and procgen can force per-instance collision overlays without mutating shared definitions.

Tall props that should visually pass behind the player can opt into player-relative depth sorting. The runtime keeps that behavior local to the prop layer so it does not require a global scene-wide Y-sort rewrite.

Portal props can also opt into a 2.5D stair/platform impostor: the definition can provide a trigger offset, a passable center lane, side blockers, and a fake-elevation ramp so the prop feels like the player is walking up onto a raised portal mouth without requiring true 3D stairs. The portal runtime may mirror that approach for a north-side entry as well so the same prop can read as walkable from both sides without introducing full 3D geometry. For the current portal-ring frame, the visual FX center and the platform horizon are intentionally separate: the FX remains centered on its animation frame, while occlusion is tuned to the source-image y=60 platform horizon so the operator remains in front until their visual feet cross that line. Portal definitions can also hide their static base texture when a runtime `PortalStateSprite` owns idle, activation, and arrival visuals; overlays, rubble, collision, and deterministic variant data remain owned by the procedural prop.

For portal-ring props, prefer a dedicated authored collision scene when the side blockers need exact placement; keep the ramp math and top-only trigger in the teleporter runtime, not in the prop collision body.

## Procgen Placement Slice

`ProcGenTilemap` can now place decorative ruin prop variants after floor/wall generation captures the stable generated cell state. Placement uses a `PropSpawnSet` resource with weighted entries, spacing checks, player/compound clearance, wall clearance, and deterministic seeds derived from tile cells.

The current slice keeps visual variation presentation-only while registering authored physical footprints:

- props spawn under `NavigationRegion2D/PropLayer`
- spawned `ProceduralProp` instances use `collision_scene = null` unless a definition explicitly provides one
- definitions can also opt into simple authored collision footprints for runtime collision without a dedicated collision scene
- definitions can opt into player-relative depth sorting for tall blockers and portal props
- portal definitions can opt into a raised platform impostor with ramp-side blockers, fake elevation, top-only teleport gating, single-state-sprite animation, and platform-horizon depth sorting
- floor/wall TileMaps remain base structural walkability authority, while collision-bearing ruin props register physical tiles in the runtime prop-blocker overlay: inline blockers use their generated global collision rectangle, and multi-shape collision scenes preserve each authored shape so passable gaps are not filled by a union AABB
- runtime blocker footprints participate in local escape validation and navigation rebuilds; a footprint that still crosses a protected route/spawn/structure/story/combat clear zone after placement has its collision disabled and unregistered while its visual may remain
- dedicated portal side blockers are exempt from that generic clearance cleanup because the portal connector intentionally terminates inside their authored approach footprint; their center lane remains the walkable authority
- placement avoids the player spawn, compound buildings, and near-wall cells

Collision alignment anomalies and protected-clear-zone footprint overlaps log loudly and mirror structured events, counters, gauges, and warnings into `DevObservatory`. Observatory data is diagnostic only and never decides placement, collision, navigation, or remediation.

The initial spawn set lives at `custodian/content/props/ruins/data/ruin_prop_spawn_set.tres`.

## Asset Rules

Source sheets should be sliced into transparent prop PNGs under `custodian/content/props/ruins/extracted/`. Overlay and rubble sprites should live under `custodian/content/props/ruins/overlays/`.

If extracted sprites were cropped without padding, add transparent padding before authoring definitions. The recommended default is 16 px on every side:

```bash
mkdir -p padded
magick mogrify -path padded -background none -gravity center -extent "%[fx:w+32]x%[fx:h+32]" *.png
```

For ImageMagick builds that reject the expression form, this equivalent command can be used:

```bash
mkdir -p padded
magick mogrify -path padded -background none -bordercolor none -border 16x16 *.png
```

Use bottom-center `anchor_offset` conventions for floor props after padding.

## Pixel-Art Constraints

- Use nearest-neighbor filtering.
- Do not use arbitrary runtime rotation.
- Do not use non-integer runtime scaling.
- Do not derive gameplay collision from decorative overlays or rubble.
- Keep hue shifts conservative; most visual difference should come from authored overlays and rubble recombination.
