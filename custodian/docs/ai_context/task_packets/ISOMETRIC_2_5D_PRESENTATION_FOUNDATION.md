
# ISOMETRIC 2.5D PRESENTATION FOUNDATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `isometric-2-5d-presentation-foundation`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `kenney-isometric-blockout-playtest`
- Locks: `world-presentation, presentation-experiments`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime`
- Paired review workstream: `review-isometric-2-5d-presentation-foundation`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `09ebb90e78e4568f81f4a7fc270da0a3d158d445`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Coordination chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7
- Supplemental summary backlink: Every durable implementation/closeout summary for this packet must also include `Coordination chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7` exactly.
- Goal: Make CUSTODIAN's 2.5D doctrine an explicit reusable 2D runtime presentation contract by separating ground XY from visual elevation and converging existing depth-sort, roof-occlusion and contact-shadow precedents without creating a 3D gameplay path.
- Completion boundary: Add one small reusable isometric presentation profile/anchor, one focused fixture proving ground-position invariance and base-root sorting, document reuse of `RoofOccluder2D` and actor shadows, and leave production movement/collision/navigation/camera unchanged.
- Current measured state: Gothic Compound already base-roots dynamic occluders; Sundered Keep already has underlay/playable/roof/foreground bands; `RoofOccluder2D` already fades roofs; actors already have `blob_shadow.gd`. The missing piece is a reusable semantic contract, not a new renderer.
- Evidence: `design/01_systems/ISOMETRIC_2_5D_PRESENTATION_CONTRACT.md`; Gothic Compound sprite context; `roof_occluder_2d.gd`; `blob_shadow.gd`; Sundered Keep approach.
- Task-specific authority: `ISOMETRIC_2_5D_PRESENTATION_CONTRACT.md`. Existing physics/navigation/camera authorities stay authoritative.
- Work surface: new helpers under `custodian/game/world/presentation/isometric_2_5d/` plus one focused fixture/smoke and manifest/docs updates.
- Change: implement reusable ground-root + presentation elevation + semantic band data; prove Y-sort/base-anchor behavior; reuse existing occlusion/shadow authorities.
- Preserve: gameplay XY, collision, navigation, Operator/enemy movement, procgen semantics, authored coordinates, save state, Camera2D, existing roof fade and actor shadow behavior.
- Non-goals: no production-scene retrofit; no new art; no asset ingest; no Operator/enemy conversion; no Node3D/Vector3/Camera3D/CharacterBody3D/MeshInstance3D; no 360 camera; no free-Z locomotion.
- Acceptance: changing visual elevation moves only the visual child; ground/world position and collision stay unchanged; depth bands are deterministic; sorting uses ground/base anchors; `RoofOccluder2D` remains the fade authority; no duplicate shadow system; focused smoke passes; production boot unchanged.
- Validation: run the new focused smoke and `git diff --check`. Run broader validation only if focused evidence or repository policy requires it.
- Task overrides: `none`
- Deferred: playable integration is `isometric-2-5d-forum-vertical-slice`.

## Identity

```text
workstream: isometric-2-5d-presentation-foundation
branch: agent/isometric-2-5d-presentation-foundation
closing summary: ISOMETRIC_2_5D_PRESENTATION_FOUNDATION_CLAUDE_SUMMARY.md
```

## Preferred exact files

| Action | Path |
| --- | --- |
| create | `custodian/game/world/presentation/isometric_2_5d/isometric_presentation_profile.gd` |
| create | `custodian/game/world/presentation/isometric_2_5d/isometric_visual_anchor_2d.gd` |
| create | `custodian/game/world/presentation/isometric_2_5d/README.md` |
| create | `custodian/tools/validation/fixtures/isometric_2_5d_presentation_foundation.tscn` |
| create | `custodian/tools/validation/isometric_2_5d_presentation_foundation_smoke.gd` |
| modify | `custodian/tools/validation/validation_manifest.json` |
| modify only if a real defect is exposed | `custodian/game/world/common/roof_occluder_2d.gd` |
| modify | `design/01_systems/ISOMETRIC_2_5D_REALIZATION_ROADMAP.md` |
| modify | `custodian/docs/ai_context/task_packets/README.md` |

If live code offers a cleaner existing presentation home at claim time, preserve this behavioral contract and avoid a parallel authority.

## Runtime contract

### IsometricPresentationProfile

Small Resource/data object. Required semantics:

```text
visual_elevation_px: float
depth_band: enum/StringName
sort_anchor_offset: Vector2
```

Bands:

```text
UNDERLAY       -300
VISTA          -200
SURFACE        -100
GROUND            0
STRUCTURE        40
ROOF_OCCLUSION   90
OVERHEAD        100
```

These are defaults, not a mass migration target.

### IsometricVisualAnchor2D

Preferred structure:

```text
IsometricVisualAnchor2D (ground/sort XY)
└── VisualRoot (elevation offset only)
```

Preferred public behavior:

```gdscript
@export var visual_root_path: NodePath
@export var profile: IsometricPresentationProfile

func apply_profile() -> void
func set_visual_elevation_px(value: float) -> void
func get_ground_world_position() -> Vector2
func get_sort_world_position() -> Vector2
```

Rules:

- root/global position is the ground contact;
- elevation offsets only `VisualRoot` vertically;
- sort anchor may use `sort_anchor_offset` but not elevated sprite top-left;
- no physics process;
- no collision/navigation ownership.

## Sorting fixture

Create a `Node2D` with `y_sort_enabled=true` and two anchors at different ground Y values. Give the rear object enough visual elevation to overlap the front object.

Prove draw/front-behind semantics still follow ground/base roots.

## Existing-authority reuse

Do not create another roof-occlusion class. Reuse `RoofOccluder2D`.

Do not create another actor-shadow authority. `blob_shadow.gd` remains the actor precedent; static presentation can use baked/dedicated shadows.

## Focused smoke

Manifest ID: `isometric_2_5d_presentation_foundation`.

Assert:

1. fixture loads;
2. elevation changes only VisualRoot offset;
3. anchor/global ground position stays identical;
4. helper owns no collision/navigation/body authority;
5. depth-band ordering is correct;
6. fixture sorting uses base/ground roots;
7. `RoofOccluder2D` is still loadable/reusable;
8. production main scene is unchanged;
9. no prohibited 3D type appears in the new runtime surface.

## Closeout

```bash
python custodian/tools/validation/run_validation.py --test isometric_2_5d_presentation_foundation
git diff --check
```

Update the realization roadmap and finish normally. Next workstream: `review-isometric-2-5d-presentation-foundation`; the Forum and Sundered showcase slices remain dependency-gated until that fresh-context review passes.


## Handoff

- Next workstream: `review-isometric-2-5d-presentation-foundation`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Next action: Finish the foundation, then let the paired fresh-context review claim before showcase consumers.
- Blockers or open questions: none.
