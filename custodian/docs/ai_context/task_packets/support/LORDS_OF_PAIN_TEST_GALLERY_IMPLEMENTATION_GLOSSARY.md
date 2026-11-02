# LORDS OF PAIN TEST GALLERY — IMPLEMENTATION GLOSSARY

Status: supporting implementation sidecar; **not a dispatchable task packet**  
Companion packet: `custodian/docs/ai_context/task_packets/archived/LORDS_OF_PAIN_TEST_GALLERY.md`
Workstream: `lords-of-pain-test-gallery`  
Reviewed main: `047e827f8846`

Purpose: keep the execution agent out of broad archaeology. This sidecar names the exact generated paths, existing authorities, recommended local classes, and code seams for the gallery. The task packet remains the closure/acceptance authority. If live main has moved and an API differs, preserve the behavioral contract and use the current live seam rather than creating a parallel system.

**Scope update (2026-10-03):** the user selected the available DEMO pack and approved excluding Cursor Gauntlet, Rocks, and Mushrooms because those entries have no source files. This scope supersedes the historical FULL-index examples and acceptance guidance below. Implement Warrior, Skeleton, Highlight, Loot Indicator, Gold Drop, Glint, Ground Stone, and the four DEMO actor animation entries; the manifest also maps the indexed Gold Drop animation.

## 1. Exact scaffold output

The live `LevelScaffoldGenerator._build_paths()` creates this shape for:

- level id: `lords_of_pain_test_gallery`
- region: `dev`

```text
custodian/game/world/levels/authored/dev/lords_of_pain_test_gallery/
    lords_of_pain_test_gallery.gd
    lords_of_pain_test_gallery.tscn
    lords_of_pain_test_gallery_playtest.tscn
    lords_of_pain_test_gallery_authoring.tscn
    README.md

custodian/content/levels/dev/lords_of_pain_test_gallery/
    lords_of_pain_test_gallery.json
    lords_of_pain_test_gallery.levelgen.json

custodian/tools/validation/levels/
    lords_of_pain_test_gallery_smoke.gd

design/05_levels/
    LORDS_OF_PAIN_TEST_GALLERY.md
```

The generator also updates:

```text
custodian/content/levels/levels.json
```

Do **not** hand-create a second playtest scene under `custodian/scenes/debug/`. The generated `lords_of_pain_test_gallery_playtest.tscn` is the standalone test wrapper and already owns the real Operator, PlayerController, Camera2D, and gameplay-profile systems.

### Packet-path correction

The task packet's earlier shorthand `.../authored/dev/lords_of_pain_gallery/` is not the generator output. The execution path is `.../authored/dev/lords_of_pain_test_gallery/`.

## 2. Scaffold command delta

Prefer the packet's scaffold command, but include a generated return exit up front so the normal route contract has a concrete node to bind:

```bash
godot --headless --path custodian \
  --script res://tools/level_authoring/create_level.gd -- \
  --level-id lords_of_pain_test_gallery \
  --display-name "Lords of Pain Test Gallery" \
  --region dev \
  --class-name LordsOfPainTestGallery \
  --spawn-id Spawn_Main \
  --return-spawn-id Return_Main \
  --exit return_world:ReturnWorld \
  --ingress-prompt "ENTER LORDS OF PAIN GALLERY" \
  --world-context campaign_region \
  --playtest-profile full \
  --canvas-size 4096x2560 \
  --presentation-profile gameplay \
  --cache-policy snapshot_and_unload \
  --state-policy reset_on_entry \
  --dry-run
```

Then rerun without `--dry-run`.

The generated `ReturnWorld` node will initially use `LevelExit2D`. For the production scene, change that node to the live `InteractableLevelExit2D` contract or replace it with a scene whose root extends `InteractableLevelExit2D`; keep:

```gdscript
exit_id = &"return_world"
prompt_text = "RETURN TO PROCGEN"
trigger_on_body_entered = false
arrival_guard_radius = 96.0
```

This is enough for `RouteTraversalManager.start_single_level_route()`, which already synthesizes the legal `return_world -> @world_origin` edge. Do not add a gallery-specific travel manager.

## 3. Existing authorities to reuse

| Concern | Existing authority | Use in gallery |
|---|---|---|
| Authored level lifecycle | `custodian/game/world/levels/authored_level_2d.gd` | Production scene root extends this. Keep it thin. |
| Level registration | `custodian/game/world/levels/level_registry.gd` + `custodian/content/levels/levels.json` | Let the scaffold generator register the definition. |
| Loading/return | `custodian/game/world/levels/level_loader.gd` | Do not bypass. |
| Route transitions | `custodian/game/world/routes/route_traversal_manager.gd` | Single-level route owns enter/return. |
| Procgen ingress discovery | `custodian/game/world/levels/world_ingress_spawner.gd` | It automatically discovers registered levels tagged `world_ingress`. No procgen registry patch should be necessary. |
| Procgen ingress behavior | `custodian/game/world/procgen/ingress/world_ingress_site.gd` | Custom gallery ingress presentation should subclass this, not reimplement transition logic. |
| Return interaction | `custodian/game/world/levels/interactable_level_exit_2d.gd` | Use for the gallery-side return frame. |
| District Transfer Frame art | `custodian/content/metadata/assets/families/district_transfer_frame.asset.json` | Reuse runtime textures/presentation vocabulary. |
| District Transfer Frame reference layout | `custodian/game/world/gothic_compound/gothic_compound_travel_gate.gd` | Reference its sprite offsets/state visuals only. Do not reuse its connected-map travel logic. |
| Generic structure damage helper | `custodian/game/systems/core/systems/damageable.gd` | Use only if the live Operator hit path composes cleanly. Do not modify global combat just to make gallery props damageable. |
| Harvest/inventory-backed node | `custodian/game/resources/resource_node.gd` | **Do not** use for Gold/Gemstone samples unless a safe dev-only resource definition exists; it writes to `ResourceLedger`. Prefer local pickup behavior. |

## 4. Recommended gallery-local file set

Keep temporary behavior local under the generated level directory:

```text
custodian/game/world/levels/authored/dev/lords_of_pain_test_gallery/
    lords_of_pain_test_gallery.gd                    # generated level authority
    lords_of_pain_test_gallery.tscn                  # generated production scene
    lords_of_pain_test_gallery_playtest.tscn         # generated standalone wrapper
    lords_of_pain_test_gallery_authoring.tscn        # generated authoring view

    lords_of_pain_gallery_strip_player.gd            # local horizontal-strip player
    lords_of_pain_gallery_interaction_adapter.gd     # break/light/pickup/vfx/reset modes
    lords_of_pain_gallery_actor_display.gd           # animation + direction cycling
    lords_of_pain_gallery_ui_lab.gd                  # Cursor/Filter/Highlight/Loot preview
    lords_of_pain_gallery_ingress_site.gd            # extends WorldIngressSite
    lords_of_pain_gallery_ingress_site.tscn
    lords_of_pain_gallery_return_frame.gd            # extends InteractableLevelExit2D
    lords_of_pain_gallery_return_frame.tscn
```

Supplemental gallery data:

```text
custodian/content/data/dev/lords_of_pain/
    gallery_manifest.json
```

Do not add global helpers unless the gallery proves the project already needs them elsewhere.

## 5. Recommended strip-player seam

Many Lords of Pain files are frame strips. Keep one local runtime player instead of hand-authoring one `SpriteFrames` resource per demo state.

Suggested implementation:

```gdscript
extends AnimatedSprite2D
class_name LordsOfPainGalleryStripPlayer

func configure_strip(
    texture: Texture2D,
    frame_size: Vector2i,
    frame_count: int,
    fps: float,
    loop: bool
) -> void:
    var frames := SpriteFrames.new()
    frames.add_animation("clip")
    frames.set_animation_loop("clip", loop)
    frames.set_animation_speed("clip", fps)

    for index in range(frame_count):
        var atlas := AtlasTexture.new()
        atlas.atlas = texture
        atlas.region = Rect2(
            index * frame_size.x,
            0,
            frame_size.x,
            frame_size.y
        )
        frames.add_frame("clip", atlas)

    sprite_frames = frames
    play("clip")
```

If hydrated assets are stored as per-frame PNG sequences instead of strips, build the same `SpriteFrames` from ordered textures. Do not flatten or repack source destructively just to satisfy this helper.

## 6. Recommended interaction adapter

Use the real project `interactable` contract and keep state local.

Suggested shape:

```gdscript
extends StaticBody2D
class_name LordsOfPainGalleryInteractionAdapter

enum Mode {
    BREAKABLE,
    LIGHTABLE,
    PICKUP,
    VFX_TRIGGER,
    RESET,
}

signal gallery_event(event_id: StringName)

@export var mode: Mode = Mode.VFX_TRIGGER
@export var prompt_text := "ACTIVATE"
@export var interaction_distance := 72.0
@export var linked_targets: Array[NodePath] = []

var _broken := false
var _lit := false
var _collected := false


func _ready() -> void:
    add_to_group("interactable")


func get_interaction_prompt() -> String:
    return prompt_text


func get_interaction_position() -> Vector2:
    return global_position


func get_interaction_distance() -> float:
    return interaction_distance


func interact(_actor: Node) -> void:
    match mode:
        Mode.BREAKABLE:
            _break_or_reset()
        Mode.LIGHTABLE:
            _set_lit(not _lit)
        Mode.PICKUP:
            _collect_or_reset()
        Mode.VFX_TRIGGER:
            _emit_to_targets(&"play")
        Mode.RESET:
            _emit_to_targets(&"reset")


# Optional compatibility seam for real combat hits.
# Keep it gallery-local; do not change Operator/combat authority to target this.
func take_damage(amount: float, _strength: Variant = null) -> void:
    if mode == Mode.BREAKABLE and amount > 0.0 and not _broken:
        _break()


func _emit_to_targets(event_id: StringName) -> void:
    gallery_event.emit(event_id)
    for path in linked_targets:
        var target := get_node_or_null(path)
        if target != null and target.has_method("gallery_trigger"):
            target.call("gallery_trigger", event_id)
```

Implementation details may differ, but preserve these rules:

- `BREAKABLE`: `INTACT -> BREAK -> RESET`
- Barrel/Crate/Brazier may expose `take_damage(...)` so current hit callers can exercise them when compatible.
- Breaking a loot-bearing sample calls linked Gold Drop + Glint displays.
- `LIGHTABLE`: toggles Brazier/Torch body + Flame/Glow displays.
- `PICKUP`: hides/disables the local sample, then permits reset; do not mutate production economy by default.
- `VFX_TRIGGER`: plays Zone/Glint/Flame/Flames/Glow/Swoosh.
- Reset must be deterministic and testable.

## 7. Actor display seam

Use one actor display per semantic actor family, not one instance per direction.

Recommended API:

```gdscript
extends Node2D
class_name LordsOfPainGalleryActorDisplay

func configure_from_manifest(entry: Dictionary) -> void:
    pass

func cycle_animation(step := 1) -> void:
    pass

func cycle_direction(step := 1) -> void:
    pass

func reset_display() -> void:
    pass

func get_debug_state() -> Dictionary:
    return {
        "actor_id": actor_id,
        "animation": current_animation,
        "direction": current_direction,
        "frame_count": current_frame_count,
        "source": current_source,
    }
```

The control surface should expose the DEMO actor animations:

```text
Warrior:      armed_idle, armed_walk
Skeleton:     default_walk, special_death
```

Cycle only directions that exist in the hydrated source manifest. Do not assume 8/16-direction coverage from naming alone.

## 8. Supplemental gallery manifest

Use one deterministic supplemental manifest as the exact coverage truth. This is **not** a replacement for Asset V2 family contracts.

Recommended path:

```text
custodian/content/data/dev/lords_of_pain/gallery_manifest.json
```

Recommended conceptual shape:

```json
{
  "schema": "custodian.dev_lop_gallery_manifest.v1",
  "source_pack": "archive/dev/LordsOfPain",
  "license_path": "archive/dev/LordsOfPain/Licence.txt",
  "families": [
    {
      "semantic_id": "barrel",
      "family_id": "dev_lop_barrel",
      "states": [
        {
          "state_id": "intact",
          "source_path": "...",
          "runtime_path": "...",
          "dimensions": [0, 0],
          "frame_size": [0, 0],
          "frames": 1,
          "directions": ["omni"]
        }
      ]
    }
  ]
}
```

Fill dimensions/frame counts only from hydrated files.

## 9. Semantic family map

Use these as naming targets unless actual hydrated source/schema forces a split:

| FULL-index item | Suggested family |
|---|---|
| Bones x3 | `dev_lop_bones` variants 01-03 |
| Rocks | `dev_lop_rocks` |
| Mushrooms | `dev_lop_mushrooms` |
| Barrel + Break | `dev_lop_barrel`: intact, break |
| Gold Drop | `dev_lop_gold_drop` |
| Wall x3 | `dev_lop_wall` variants 01-03 |
| Tiles | `dev_lop_tiles` |
| Column x2 | `dev_lop_column` variants 01-02 |
| Bricks | `dev_lop_bricks` |
| Crate + Break | `dev_lop_crate`: intact, break |
| Gemstones x4 | `dev_lop_gemstones` variants 01-04 |
| Brazier + Lit + Break | `dev_lop_brazier`: intact, lit, break |
| Torch | `dev_lop_torch` |
| Zone | `dev_lop_zone` |
| Glint | `dev_lop_glint` |
| Flame + Glow | `dev_lop_flame` |
| Flames + Glow | `dev_lop_flames` |
| Glow | `dev_lop_glow` |
| Swoosh | `dev_lop_swoosh` |
| Ground Stone / Variation x2 / Darken | `dev_lop_ground_stone`: base, variation_01, variation_02, darken |
| Cursor Gauntlet x5 | `dev_lop_cursor_gauntlet` variants 01-05 |
| Filter Vignette | `dev_lop_filter_vignette` |
| Highlight x5 | `dev_lop_highlight` variants 01-05 |
| Loot Indicator x5 | `dev_lop_loot_indicator` variants 01-05 |
| Warrior | `dev_lop_warrior` |
| Knight | `dev_lop_knight` |
| Fighter | `dev_lop_fighter` |
| Subservient | `dev_lop_subservient` |
| Skeleton | `dev_lop_skeleton` |
| Demonlord | `dev_lop_demonlord` |

Do not guess Asset V2 `kind`, canvas, frame size, FPS, or state geometry from this table. Inspect live schema + hydrated pixels.

## 10. Procgen ingress recommendation

The generated level definition should keep the scaffolded `world_ingress` tag and ingress block, then add a custom site scene only for presentation:

```json
"ingress": {
  "ingress_id": "lords_of_pain_test_gallery",
  "prompt_text": "ENTER LORDS OF PAIN GALLERY",
  "target_spawn_id": "Spawn_Main",
  "site_scene_path": "res://game/world/levels/authored/dev/lords_of_pain_test_gallery/lords_of_pain_gallery_ingress_site.tscn",
  "interaction_distance": 92.0,
  "placement": {
    "...": "preserve generator/live placement fields"
  }
}
```

`WorldIngressSpawner` already loads registered definitions tagged `world_ingress`; do not patch procgen placement code merely to make this gallery appear.

Recommended ingress subclass:

```gdscript
extends WorldIngressSite
class_name LordsOfPainGalleryIngressSite


func _ready() -> void:
    requires_explicit_interaction = true
    super._ready()
    set_ingress_marker_visible(false)
    _build_district_transfer_frame_presentation()
```

Presentation may reuse the runtime textures listed in:

```text
custodian/content/metadata/assets/families/district_transfer_frame.asset.json
```

Copy only presentation behavior needed for this dev ingress. Do not copy `GothicCompoundTravelGate._travel_actor()`, `enter_from_main()`, or `return_to_main()` connected-map logic.

## 11. Gallery return frame recommendation

Use `InteractableLevelExit2D` as the root travel authority and decorate it with District Transfer Frame sprites.

Recommended root:

```gdscript
extends InteractableLevelExit2D
class_name LordsOfPainGalleryReturnFrame


func _ready() -> void:
    exit_id = &"return_world"
    prompt_text = "RETURN TO PROCGEN"
    trigger_on_body_entered = false
    arrival_guard_radius = 96.0
    super._ready()
    _build_district_transfer_frame_presentation()
```

The inherited `request_transition()` emits `transition_requested`; `RouteTraversalManager` binds it and resolves the synthetic single-level `return_world` edge. No direct calls to `LevelLoader` are needed here.

## 12. Section roots / scene structure

Recommended production hierarchy below the generator-owned roots:

```text
LordsOfPainTestGallery
├── UnderlayRoot
│   ├── StoneCourtTerrain
│   └── HardstandTerrain
├── PlayableRoot
│   ├── SpawnReturnConcourse
│   ├── StoneCourt
│   ├── HardstandInteractionYard
│   ├── ActorCombatBays
│   └── VfxUiLab
├── PropsRoot
├── Collision
├── Markers
├── Exits
│   └── ReturnWorld                  # InteractableLevelExit2D / return-frame scene
├── NavigationRoot
└── GalleryRuntime
```

Keep primary aisles >= 128 px and all layout on the 32 px vocabulary.

## 13. Standalone playtest note

The generated `full` playtest profile adds:

- real `Operator`
- `PlayerController`
- `Camera2D`
- `Combat`
- `NavigationSystem`
- `EnemyDirector`

The `full` profile additionally adds `WaveManager` and `CustodianHUD`.

Use `full` for this gallery. The live generator accepts `movement`, `combat`, or `full`; `gameplay` is rejected. The production level scene must not own the Operator, HUD, camera, or PlayerController.

## 14. Focused validation file

Extend the generator-owned smoke instead of creating a second overlapping gallery smoke:

```text
custodian/tools/validation/levels/lords_of_pain_test_gallery_smoke.gd
```

At minimum assert:

1. production scene has no Operator, PlayerController, or Camera2D;
2. level definition is registered and tagged `world_ingress`;
3. ingress target is `Spawn_Main`;
4. one `return_world` `LevelExit2D` exists;
5. gallery manifest covers all seven available DEMO semantics, five animation entries, all 16 available directions, and the three user-approved exclusions;
6. Ground Stone and the real Meridian hardened-floor surface are present in separate connected lanes;
7. Warrior/Skeleton displays change to the selected state and direction, and Gold Drop toggles available/collected/reset;
8. Highlight and Loot Indicator are screen-space UI samples;
9. no runtime resource path points into `archive/dev/LordsOfPain`;
10. procgen entry/return presentation uses District Transfer Frame around the normal route authority;
11. procgen enter -> gallery -> exact-origin return -> re-entry passes.

Then run the packet's already-verified existing validation entrypoints:

```text
custodian/tools/validation/level_scaffold_generator_smoke.gd
custodian/tools/validation/level_registry_contract_smoke.gd
custodian/tools/validation/world_ingress_spawner_smoke.gd
custodian/tools/validation/authored_level_ingress_return_smoke.gd
custodian/tools/validation/world_ingress_physics_reentry_smoke.gd
custodian/tools/validation/level_camera_rebind_smoke.gd
```

## 15. Known documentation drift

1. **Generated location drift:** packet shorthand says `authored/dev/lords_of_pain_gallery/`; generator truth is `authored/dev/lords_of_pain_test_gallery/`.
2. **Definition location drift:** definition is nested at `content/levels/dev/lords_of_pain_test_gallery/lords_of_pain_test_gallery.json`.
3. **Playtest location drift:** generated playtest lives beside the production authored level, not under `custodian/scenes/debug/`.
4. **Return node omission:** the packet's original scaffold command does not request a `return_world` exit. Add `--exit return_world:ReturnWorld` or author the same node immediately after generation.
5. **Superseded scope:** old FULL-index coverage guidance in the original packet/sidecar is historical only. The archived implementation packet's DEMO scope update and exclusion records are authoritative.

These are planning-document corrections, not runtime defects. The execution agent should follow generator/runtime truth and update durable docs at closeout where implementation makes the final paths concrete.
