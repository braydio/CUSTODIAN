
# CUSTODIAN ISOMETRIC 2.5D PRESENTATION CONTRACT

**Status:** active design authority
**Decision date:** 2026-10-04
**Reviewed main:** `09ebb90e78e4568f81f4a7fc270da0a3d158d445`
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac60342-02a4-83e9-b402-577faeed63ff

## Decision

CUSTODIAN will realize its existing **2.5D fixed-isometric doctrine on top of the current 2D simulation/runtime**, rather than pursue a full gameplay conversion to 3D.

```text
authoritative simulation: 2D XY
movement/collision/navigation: 2D
combat geometry: 2D
camera: Camera2D
presentation: may express height, volume, depth and occlusion
```

A 360-degree gameplay camera is not required. This program does not migrate normal gameplay to Camera3D, CharacterBody3D, NavigationRegion3D, 3D collision or mesh-authored runtime worlds.

Existing isolated 3D UI/vista technology may remain isolated. It is not a gameplay migration precedent.

## Why this is viable now

The repository already contains pieces of the intended language:

- `custodian/game/world/procgen/gothic_compound/gothic_compound_sprite_context.gd` uses base-rooted dynamic depth sorting.
- `custodian/game/world/common/roof_occluder_2d.gd` fades foreground/roof presentation for Operator readability.
- `custodian/game/actors/effects/blob_shadow.gd` grounds actors with contact shadows.
- `dev_lop_skeleton` proves a 2D AnimatedSprite2D actor can read volumetrically with 16 directional views.
- `SunderedKeepApproach` already separates underlay, playable, roof-occlusion and foreground presentation bands.

The missing work is convergence and a production-quality vertical slice, not a replacement simulation dimension.

## 1. Ground XY is authoritative

Gameplay position is always the 2D ground-contact point:

```text
simulation_position = Vector2(x, y)
```

Presentation height must not change that point.

Preferred structure:

```text
GroundRoot (authoritative world XY / sort point)
├── ContactShadow
└── VisualRoot (presentation-only elevation offset)
    └── Sprite / animation
```

For visual elevation:

```text
GroundRoot.position = simulation_position
VisualRoot.position.y = authored_visual_y - visual_elevation_px
```

Collision, navigation, targeting, save state and deterministic gameplay remain on the ground root.

## 2. Visual elevation

`visual_elevation_px` is presentation-only.

Valid uses include raised machinery, upper decks, bridges, gantries, tall props, stairs/ramp visual rise, hovering presentation and VFX.

It may affect sprite offset, shadow separation and presentation ordering. It must not silently become free-Z locomotion.

## 3. Sorting uses the base/ground anchor

Anything intended to sort against actors needs a stable ground/base anchor.

Use Godot `y_sort_enabled` when it cleanly solves the case. Reuse the Gothic Compound base-root/sort-line pattern where explicit front/behind control is required.

Do not sort by the elevated child texture origin. Do not create a second global depth manager if ground-root Y sorting is sufficient.

## 4. Semantic presentation bands

The relative order is:

```text
UNDERLAY / FAR DEPTH
VISTA / BACKDROP
SURFACE
GROUND / ACTORS
STRUCTURES
ROOF OCCLUSION
OVERHEAD / FOREGROUND
SCREEN UI
```

Current production precedents already cluster around:

```text
underlay       -300
vista          -200
playable          0
structure       ~40
roof occlusion  ~90
foreground     ~100
```

These are reference defaults, not a command to mass-rewrite existing scene z-values.

## 5. Occlusion

`RoofOccluder2D` remains the default simple fade authority.

Foreground/roof art may overlap the Operator to sell height, but must fade/cut away when it harms tactical readability. Fading presentation must never alter collision or navigation.

## 6. Shadows and grounding

Actors remain visibly attached to the gameplay ground point.

`blob_shadow.gd` is the actor contact-shadow precedent. Static architecture may use baked/dedicated contact shadows.

A shadow stays at ground contact. Visual elevation may separate the rendered body from its shadow without moving authoritative XY.

## 7. Directional actor tiers

Directional sprites are a first-class 2.5D tool.

- **8 directions:** normal target for hand-authored gameplay actors.
- **16 directions:** preferred where rendered/source coverage makes it economical, especially vehicles, large/high-value enemies and pre-rendered actors.
- **4 directions / omni:** acceptable for low-value or presentation-insensitive objects.

Do not force the Operator to 16 directions merely because the Lords skeleton has that coverage.

The Lords skeleton is the proof that 16-direction 2D rendering can carry convincing volume.

## 8. Stairs, ramps and multiple floors

The game does not gain unrestricted free Z.

Stairs/ramps may communicate visual rise while gameplay uses authored 2D traversal semantics.

Where separate floors are required, retain the existing authored-room model: separate 2D spaces linked explicitly, not continuous 3D navigation.

## 9. Camera

Production camera authority remains `Camera2D` with the existing follow, lookahead, zoom, combat framing and bounds behavior.

No orbit controls, free pitch/yaw or 360-degree rotation are required by this direction.

## 10. Asset production

Shipping/runtime targets remain 2D Asset Pipeline V2 assets.

3D tools may later be used **offline** to author fixed-view sprites, directional renders, masks or reference, but this program does not require a runtime mesh/GLB schema or MeshInstance3D gameplay objects.

Do not build that asset-authoring workflow until the playable 2.5D vertical slice proves which outputs are actually useful.

## 11. Explicit non-migration

The realized 2.5D program must not convert or duplicate:

- Operator/enemy movement;
- collision/navigation;
- combat hitboxes/hurtboxes;
- projectiles;
- procgen semantic grid;
- authored-level XY;
- save positions;
- Camera2D;
- campaign/world-transition state.

No Node3D/Vector3/Camera3D/CharacterBody3D/CollisionShape3D/NavigationRegion3D/MeshInstance3D is required by the active program.

## Success criterion

A normal gameplay scene should convincingly show volumetric actors, vertical architectural mass, natural front/behind relationships, readable roof/foreground fading, contact grounding and raised visual elements **while the gameplay simulation remains ordinary deterministic 2D**.
