# Field Fabricator Mk1 — Visual Integration Code

**Status:** partial production integration (idle/fabricate body, fabricate FX live)
**Scope:** visual replacement of placeholder geometry with production sprite art
**Authority:** `custodian/design/02_art_direction/CUSTODIAN_STRUCTURE_DESIGN_CONTRACT.md`
**Runtime target:** `custodian/game/infrastructure/structures/field_fabricator_mk1.tscn`

---

## 1. What Changes

Replace the placeholder `Polygon2D` geometry in the Field Fabricator Mk1 scene with
the progressive production presentation. The current runtime contract is a
96×96 frame canvas and 768×96 eight-frame strips; only inbox-present states are
ingested, while the full family vocabulary remains declared for future drops.

## 2. What Does NOT Change

* power allocation (10 / 25 / 40)
* fabrication service behavior
* infrastructure registration
* placement architecture
* persistence
* construction state semantics
* structure identity (`field_fabricator_primary`)
* definition resource
* balance numbers
* collision shape (initially)

---

## 3. Current Scene Tree

```text
FieldFabricatorMk1 (StaticBody2D)
├── Body (Polygon2D)              ← placeholder cyan hex
├── Core (Polygon2D)              ← placeholder cyan hex
├── CollisionShape2D              ← RectangleShape2D(92, 64)
├── PowerConsumer (node)
└── FabricationService (node)
```

## 4. Target Scene Tree

```text
FieldFabricatorMk1 (StaticBody2D)
├── Body (AnimatedSprite2D)       ← production 96×96 frame canvas
├── FX (AnimatedSprite2D)         ← optional matching 96×96 overlay
├── CollisionShape2D              ← RectangleShape2D(92, 64) — unchanged
├── PowerConsumer (node)          ← unchanged
└── FabricationService (node)     ← unchanged
```

The `Core` node is removed.

`Body` remains a direct child of the root node to preserve `InfrastructureStructure._update_presentation()` which looks for `get_node_or_null("Body")`.

---

## 5. Exact .tscn Replacement

```ini
[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://game/infrastructure/infrastructure_structure.gd" id="1_structure"]
[ext_resource type="Resource" path="res://content/infrastructure/definitions/fabrication/field_fabricator_mk1.tres" id="2_definition"]
[ext_resource type="Script" path="res://game/infrastructure/components/power_consumer_component.gd" id="3_consumer"]
[ext_resource type="Script" path="res://game/infrastructure/components/infrastructure_service_component.gd" id="4_service"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_fabricator"]
size = Vector2(92, 64)

[node name="FieldFabricatorMk1" type="StaticBody2D"]
script = ExtResource("1_structure")
definition = ExtResource("2_definition")
infrastructure_instance_id = &"field_fabricator_primary"
prebuilt_operational = true

[node name="Body" type="Sprite2D" parent="."]
texture = ExtResource("5_sprite")
centered = true
texture_filter = 0

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_fabricator")

[node name="PowerConsumer" type="Node" parent="."]
script = ExtResource("3_consumer")
minimum_power = 10.0
standard_power = 25.0
overdrive_power = 40.0
overdrive_efficiency = 1.35
priority = 30

[node name="FabricationService" type="Node" parent="."]
script = ExtResource("4_service")
service_id = &"FABRICATION"
```

Note: `load_steps` drops from 6 to 5 because the `Core` Polygon2D sub-resource is removed. An `ext_resource` for the sprite texture (id `"5_sprite"`) must be added pointing to the actual PNG path once the asset exists.

---

## 6. Sprite Asset Path

```text
custodian/content/sprites/environment/props/field_fabricator_mk1/runtime/body/interaction/
field_fabricator_mk1__body__interaction__idle__omni__8f__96.png
```

* 96 × 96 px per frame, 768 × 96 px strip for eight frames
* RGBA transparent
* nearest-neighbor filtered
* centered = true

The canonical family also declares `startup`, `fabricate_complete`, `offline`,
and future damage/destruction states. Missing states fall back deterministically
to idle; missing FX remains hidden. Asset V2 ingests only files actually present
in `asset_drop/inbox/field_fabricator_mk1/`.

---

## 7. Collision Decision

**Preserve existing:** `RectangleShape2D(92, 64)`

Rationale:

* 92 × 64 sits comfortably inside the 4 × 3 (128 × 96) construction footprint
* Represents the solid machinery body, not antenna/pipes/ramp
* Only adjust if runtime testing shows player walking through core mass

---

## 8. Presentation / State Wiring

`InfrastructureStructure._update_presentation()` at line 314 of `infrastructure_structure.gd`:

```gdscript
func _update_presentation() -> void:
    var body := get_node_or_null("Body") as CanvasItem
    if body == null:
        return
    match construction_state:
        STATE_FOUNDATION, STATE_UNDER_CONSTRUCTION:
            body.modulate = Color(0.58, 0.62, 0.58, 1.0)
        STATE_DAMAGED:
            body.modulate = Color(0.82, 0.55, 0.42, 1.0)
        STATE_DESTROYED:
            body.modulate = Color(0.22, 0.22, 0.24, 0.8)
        _:
            body.modulate = Color.WHITE
```

This works unchanged with `Sprite2D` because `Sprite2D` extends `CanvasItem`. No code changes required.

State behavior:

| State | Modulate | Effect |
|-------|----------|--------|
| Foundation / Under Construction | `(0.58, 0.62, 0.58)` | Desaturated gray-green |
| Operational | `Color.WHITE` | Full intended art |
| Damaged | `(0.82, 0.55, 0.42)` | Warm damaged tint |
| Destroyed | `(0.22, 0.22, 0.24, 0.8)` | Darkened |

---

## 9. GDScript Changes

**None required.**

The existing `infrastructure_structure.gd` presentation logic works with `Sprite2D` identically to `Polygon2D`. No shared infrastructure code changes needed.

---

## 10. Validation Commands

```bash
cd custodian

# Powered fabricator smoke test
godot --headless --path . \
  --script res://tools/validation/powered_fabricator_slice_smoke.gd

# Power grid component registration
godot --headless --path . \
  --script res://tools/validation/power_grid_component_registration_smoke.gd

# Full project parse check
godot --headless --quit
```

---

## 11. Manual Review Checklist

After implementation:

* [ ] cyan hex placeholder completely gone
* [ ] structure reads immediately as machinery
* [ ] fabrication chamber is primary focal point
* [ ] front approach side is obvious
* [ ] silhouette survives normal gameplay zoom
* [ ] asset does not visually resemble a shrine
* [ ] teal illumination is restrained
* [ ] insignia does not dominate
* [ ] visual footprint agrees with 4×3 gameplay footprint
* [ ] player does not visibly walk through primary machine mass
* [ ] structure does not look like miniature RTS headquarters
* [ ] structure visually belongs beside existing Custodian compound architecture
* [ ] no background/checkerboard in PNG
* [ ] PNG has real alpha
* [ ] no runtime scaling blur
* [ ] FABRICATION service still works
* [ ] power demand remains 10 / 25 / 40
* [ ] structure remains unique and prebuilt operational
* [ ] infrastructure registry behavior unchanged
* [ ] powered fabricator smoke passes

---

## 12. Missing Assets

**The production sprite does not yet exist.**

Exact required path:

```text
custodian/assets/sprites/infrastructure/fabrication/field_fabricator_mk1/field_fabricator_mk1__idle__128x96.png
```

If this asset is not supplied, the .tscn update cannot be completed. The scene update and the asset creation are coupled.

---

## 13. Scope Exclusions

This task does NOT:

* redesign fabrication gameplay
* add upgrade tiers
* add new recipes
* create free placement
* alter power balance
* implement a new interaction system
* create construction animations
* redesign Capacitor Bank art
* propagate visual refactor through every structure
* generate replacement art silently
