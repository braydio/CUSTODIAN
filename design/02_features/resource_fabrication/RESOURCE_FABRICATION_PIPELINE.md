
Yes — make this **resource-node harvesting**, not a full survival-crafting system.

Your existing doctrine already supports this: recon/gathering should output **Scrap, Power Components, Sensor Data, Threat Indicators**, and Fabrication turns materials into defenses/infrastructure. The base also starts with a **Fabricator**, so harvested resources should feed that pipeline directly. 

## V1 feature shape

Implement:

```text
Blackwood deadfall / alloy vein / wreckage source in world
        ↓
Player presses interact near it
        ↓
Node takes harvest damage
        ↓
Node depletes into stump / exhausted vein
        ↓
ResourceLedger receives blackwood / structural_alloy / ruin_scrap
        ↓
Fabricator consumes ResourceLedger costs
```

Do **not** start with dropped items, physics pickups, tool durability, or freeform building. That will bloat fast.

## Files I would add

```text
custodian/autoload/resource_ledger.gd
custodian/game/resources/resource_node.gd
custodian/game/resources/player_resource_harvester.gd
custodian/game/fabrication/fabricator_resource_bridge.gd
custodian/content/resources/resource_defs.json
design/02_features/resource_fabrication/RESOURCE_FABRICATION_SYSTEM.md
```

The repo guidance says active runtime is `custodian/`, active docs are under `custodian/docs/`, and Godot runtime behavior changes should update `./design/` first.  The tree map also shows `custodian/autoload` and `custodian/content`, so those are reasonable places to add the ledger and resource data. 

## Resource types for V1

Use canonical CUSTODIAN-flavored resource IDs directly in the ledger and recipes:

```json
{
  "blackwood": {
    "label": "Blackwood",
    "fab_role": "cheap structure material"
  },
  "structural_alloy": {
    "label": "Structural Alloy",
    "fab_role": "metal input"
  },
  "ruin_scrap": {
    "label": "Ruin Scrap",
    "fab_role": "fabrication feedstock"
  },
  "power_components": {
    "label": "Power Components",
    "fab_role": "gated electronics / power recipes"
  },
  "resin_clot": {
    "label": "Resin Clot",
    "fab_role": "sealant / patching material"
  },
  "capacitor_dust": {
    "label": "Capacitor Dust",
    "fab_role": "conductive electronics input"
  },
  "signal_filament": {
    "label": "Signal Filament",
    "fab_role": "sensor / archive signal input"
  },
  "memory_glass_fragment": {
    "label": "Memory Glass Fragment",
    "fab_role": "archive-pattern decode input"
  },
  "fiber_moss": {
    "label": "Fiber Moss",
    "fab_role": "organic binding fiber"
  }
}
```

Do not map `blackwood` back to `timber`, `structural_alloy` back to `ore`, or `ruin_scrap` back to `scrap` as the long-term economy. If legacy aliases exist, they should normalize old generic inputs forward to the flavored IDs.

## Core script: `resource_ledger.gd`

```gdscript
# res://autoload/resource_ledger.gd
extends Node

signal changed(snapshot: Dictionary)
signal resource_added(resource_id: String, amount: int, new_total: int)
signal resource_spent(cost: Dictionary)

var _resources: Dictionary = {
	"blackwood": 0,
	"structural_alloy": 0,
	"ruin_scrap": 0,
	"power_components": 0,
	"resin_clot": 0,
	"capacitor_dust": 0,
	"signal_filament": 0,
	"memory_glass_fragment": 0,
	"fiber_moss": 0,
}

func get_amount(resource_id: String) -> int:
	return int(_resources.get(resource_id, 0))

func get_snapshot() -> Dictionary:
	return _resources.duplicate(true)

func add(resource_id: String, amount: int) -> void:
	if amount <= 0:
		return

	var new_total := get_amount(resource_id) + amount
	_resources[resource_id] = new_total

	resource_added.emit(resource_id, amount, new_total)
	changed.emit(get_snapshot())

func can_pay(cost: Dictionary) -> bool:
	for resource_id in cost.keys():
		if get_amount(str(resource_id)) < int(cost[resource_id]):
			return false
	return true

func pay(cost: Dictionary) -> bool:
	if not can_pay(cost):
		return false

	for resource_id in cost.keys():
		var id := str(resource_id)
		_resources[id] = get_amount(id) - int(cost[id])

	resource_spent.emit(cost.duplicate(true))
	changed.emit(get_snapshot())
	return true

func debug_grant_starting_resources() -> void:
	add("blackwood", 20)
	add("structural_alloy", 12)
	add("ruin_scrap", 30)
	add("power_components", 2)
	add("capacitor_dust", 6)
	add("signal_filament", 1)
	add("memory_glass_fragment", 2)
	add("resin_clot", 4)
```

Add it as an autoload named:

```text
ResourceLedger
```

## Core script: `resource_node.gd`

```gdscript
# res://game/resources/resource_node.gd
extends StaticBody2D
class_name ResourceNode

signal harvested(node: ResourceNode, resource_id: String, remaining_work: int)
signal depleted(node: ResourceNode, resource_id: String, amount: int)

@export_enum(
	"blackwood_deadfall",
	"alloy_vein",
	"machine_wreckage",
	"power_node",
	"moss_patch",
	"fungal_resin_pod",
	"ruptured_capacitor_bank",
	"broken_signal_relay",
	"shattered_archive_terminal"
) var node_kind: String = "blackwood_deadfall"
@export_enum("cut", "mine", "salvage") var harvest_action: String = "cut"

@export var resource_id: String = "blackwood"
@export var harvest_label: String = "Harvest"
@export var work_required: int = 3
@export var yield_amount: int = 5

@export var secondary_yields: Dictionary = {}
@export var allow_repeat_harvest: bool = false

@export var standing_texture: Texture2D
@export var depleted_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _work_remaining: int
var _is_depleted := false

func _ready() -> void:
	add_to_group("resource_nodes")
	_work_remaining = max(1, work_required)

	if standing_texture != null and sprite != null:
		sprite.texture = standing_texture

func is_depleted() -> bool:
	return _is_depleted

func get_interaction_text() -> String:
	if _is_depleted:
		return ""

	return "%s %s (%d/%d)" % [
		harvest_label,
		resource_id.to_upper(),
		work_required - _work_remaining,
		work_required
	]

func can_harvest(action: String) -> bool:
	if _is_depleted:
		return false

	return action == harvest_action

func apply_harvest(action: String, work_amount: int = 1) -> bool:
	if not can_harvest(action):
		return false

	_work_remaining -= max(1, work_amount)
	harvested.emit(self, resource_id, _work_remaining)

	if _work_remaining <= 0:
		_deplete()

	return true

func _deplete() -> void:
	if _is_depleted:
		return

	_is_depleted = true

	if ResourceLedger:
		ResourceLedger.add(resource_id, yield_amount)

		for secondary_id in secondary_yields.keys():
			ResourceLedger.add(str(secondary_id), int(secondary_yields[secondary_id]))

	if depleted_texture != null and sprite != null:
		sprite.texture = depleted_texture

	if collision_shape != null:
		collision_shape.disabled = true

	depleted.emit(self, resource_id, yield_amount)

	if not allow_repeat_harvest:
		remove_from_group("resource_nodes")
```

## Player interaction component

Your scene already has an `InteractionLabel`, and the operator already has an `interaction_range` export, so this should integrate cleanly.  The operator instance also shows combat/melee/repair exports, so a player-side harvesting component can sit beside the controller without rewriting combat. 

```gdscript
# res://game/resources/player_resource_harvester.gd
extends Node
class_name PlayerResourceHarvester

@export var operator_path: NodePath
@export var interaction_label_path: NodePath
@export var interaction_range: float = 84.0

@export var cut_action_name: String = "interact"
@export var mine_action_name: String = "interact"
@export var salvage_action_name: String = "interact"

@onready var operator: Node2D = get_node(operator_path)
@onready var interaction_label: Label = get_node_or_null(interaction_label_path)

var _target: ResourceNode = null

func _process(_delta: float) -> void:
	_target = _find_nearest_resource_node()

	if interaction_label != null:
		interaction_label.text = _target.get_interaction_text() if _target != null else ""

	if _target == null:
		return

	if Input.is_action_just_pressed("interact"):
		_try_harvest_target()

func _find_nearest_resource_node() -> ResourceNode:
	if operator == null:
		return null

	var nearest: ResourceNode = null
	var nearest_dist := interaction_range

	for node in get_tree().get_nodes_in_group("resource_nodes"):
		if not is_instance_valid(node):
			continue
		if not node is ResourceNode:
			continue
		if node.is_depleted():
			continue

		var dist := operator.global_position.distance_to(node.global_position)
		if dist <= nearest_dist:
			nearest = node
			nearest_dist = dist

	return nearest

func _try_harvest_target() -> void:
	if _target == null:
		return

	var action := _target.harvest_action

	var did_harvest := _target.apply_harvest(action, 1)
	if not did_harvest and interaction_label != null:
		interaction_label.text = "WRONG TOOL / ACTION"
```

For now, this assumes the Custodian’s field multitool can cut, mine, and salvage. Later you can require explicit tool modules.

## Minimal Fabricator bridge

```gdscript
# res://game/fabrication/fabricator_resource_bridge.gd
extends Node
class_name FabricatorResourceBridge

signal build_started(recipe_id: String)
signal build_failed(recipe_id: String, reason: String)

const RECIPES := {
	"barricade_light": {
		"blackwood": 10,
		"ruin_scrap": 4
	},
	"turret_basic": {
		"ruin_scrap": 25,
		"structural_alloy": 8,
		"power_components": 1
	},
	"power_bank_patch": {
		"ruin_scrap": 12,
		"structural_alloy": 6,
		"power_components": 2,
		"capacitor_dust": 2
	},
	"sensor_pylon_basic": {
		"ruin_scrap": 12,
		"capacitor_dust": 4,
		"signal_filament": 1
	},
	"fabricator_pattern_decode_01": {
		"memory_glass_fragment": 2,
		"signal_filament": 1
	}
}

func can_build(recipe_id: String) -> bool:
	if not RECIPES.has(recipe_id):
		return false

	return ResourceLedger.can_pay(RECIPES[recipe_id])

func try_start_build(recipe_id: String) -> bool:
	if not RECIPES.has(recipe_id):
		build_failed.emit(recipe_id, "Unknown recipe")
		return false

	var cost: Dictionary = RECIPES[recipe_id]
	if not ResourceLedger.pay(cost):
		build_failed.emit(recipe_id, "Insufficient resources")
		return false

	build_started.emit(recipe_id)
	return true
```

## Recommended node presets

### Blackwood deadfall source

```text
node_kind: blackwood_deadfall
harvest_action: cut
resource_id: blackwood
harvest_label: CUT
work_required: 3
yield_amount: 6
secondary_yields:
  ruin_scrap: 1
```

### Alloy vein source

```text
node_kind: alloy_vein
harvest_action: mine
resource_id: structural_alloy
harvest_label: MINE
work_required: 4
yield_amount: 5
secondary_yields:
  ruin_scrap: 2
```

### Machine wreckage source

```text
node_kind: machine_wreckage
harvest_action: salvage
resource_id: ruin_scrap
harvest_label: SALVAGE
work_required: 2
yield_amount: 8
secondary_yields:
  power_components: 1
```

Wreckage should be rarer than blackwood deadfalls and alloy veins because it can drop `power_components` or `capacitor_dust`.

### Moss patch source

```text
node_kind: moss_patch
harvest_action: cut
resource_id: fiber_moss
harvest_label: GATHER
work_required: 2
yield_amount: 4
secondary_yields: {}
```

Moss patches should not drop blackwood by default. Use `blackwood_root_mass` or `blackwood_resin_wound` as a future source kind if blackwood root growth is intended.

### Broken signal relay source

```text
node_kind: broken_signal_relay
harvest_action: extract
resource_id: signal_filament
harvest_label: EXTRACT
work_required: 4
yield_amount: 1
secondary_yields:
  capacitor_dust: 2
  ruin_scrap: 2
```

## One-time scaffold script

Run from repo root:

```bash
#!/usr/bin/env bash
set -euo pipefail

mkdir -p \
  custodian/game/resources \
  custodian/game/fabrication \
  custodian/content/resources \
  design/02_features/resource_fabrication

cat > custodian/content/resources/resource_defs.json <<'EOF'
{
  "blackwood": {
    "label": "Blackwood",
    "description": "Petrified root mass and deadfall suitable for crude structures."
  },
  "structural_alloy": {
    "label": "Structural Alloy",
    "description": "Exposed metal-bearing deposits and ruin-veins."
  },
  "ruin_scrap": {
    "label": "Ruin Scrap",
    "description": "Fabrication feedstock recovered from wreckage."
  },
  "power_components": {
    "label": "Power Components",
    "description": "Rare salvage used for powered systems and fabricator upgrades."
  }
}
EOF

cat > design/02_features/resource_fabrication/RESOURCE_FABRICATION_SYSTEM.md <<'EOF'
# RESOURCE COLLECTION SYSTEM

Status: draft

## Purpose

Add rudimentary blackwood cutting, alloy mining, and salvage collection so recon/exploration can feed the Fabricator pipeline.

## Scope

- ResourceNode world objects.
- ResourceLedger autoload.
- PlayerResourceHarvester component.
- FabricatorResourceBridge helper.
- V1 resources: blackwood, structural_alloy, ruin_scrap, power_components.

## Non-goals

- No survival crafting.
- No loose item physics.
- No tool durability.
- No freeform base building.
- No procedural economy simulation.

## Design fit

This supports the existing recon loop: return with materials, reinforce the base, survive assaults, repeat.

## Runtime files

- res://autoload/resource_ledger.gd
- res://game/resources/resource_node.gd
- res://game/resources/player_resource_harvester.gd
- res://game/fabrication/fabricator_resource_bridge.gd
- res://content/resources/resource_defs.json

## Validation

- Add ResourceLedger autoload.
- Place a ResourceNode near the Operator.
- Press interact three times on blackwood_deadfall node.
- Confirm blackwood increases.
- Try a fabricator recipe and confirm resources are spent.
EOF

echo "Scaffolded resource collection docs/data folders."
echo "Next: add the GDScript files and register ResourceLedger as an autoload."
```

## Codex implementation prompt

Use this:

```text
Implement a v1 resource collection system for CUSTODIAN in Godot 4.x.

Goal:
- Add blackwood deadfall cutting, structural alloy mining, and wreckage salvage as simple interactable resource nodes.
- Feed collected resources into a central ResourceLedger autoload.
- Add a minimal FabricatorResourceBridge that can consume resource costs for early build recipes.
- Keep it deterministic and lightweight.
- Do not add a full survival crafting system, inventory UI, dropped item physics, or tool durability.

Required files:
- custodian/autoload/resource_ledger.gd
- custodian/game/resources/resource_node.gd
- custodian/game/resources/player_resource_harvester.gd
- custodian/game/fabrication/fabricator_resource_bridge.gd
- custodian/content/resources/resource_defs.json
- design/02_features/resource_fabrication/RESOURCE_FABRICATION_SYSTEM.md

Integration:
- Register ResourceLedger as an autoload.
- Add PlayerResourceHarvester near the existing PlayerController / Operator scene setup.
- Use the existing Operator interaction_range if accessible, otherwise default to 84 px.
- Use the existing InteractionLabel if available to show nearest node prompt.
- ResourceNode should be reusable for source-object node kinds such as blackwood_deadfall, alloy_vein, machine_wreckage, broken_signal_relay, and fungal_resin_pod via exported fields.
- Harvesting should require repeated interact presses, then mark the node depleted and add resources to ResourceLedger.
- Add a debug recipe bridge with barricade_light, turret_basic, power_bank_patch, sensor_pylon_basic, and fabricator_pattern_decode_01 recipes.

Validation:
- Place one test blackwood_deadfall, one alloy_vein, and one machine_wreckage node in the current playable scene.
- Confirm interacting depletes each node and updates ResourceLedger.
- Confirm FabricatorResourceBridge.try_start_build("barricade_light") spends resources only when enough are available.
- Update custodian/docs/ai_context/CURRENT_STATE.md to mention the new resource collection layer.
```

## Asset requests

No production animation is required for V1. Use static placeholders first.

When you want final art, make these:

```text
custodian/assets/sprites/resources/blackwood_deadfall_standing_01.png
custodian/assets/sprites/resources/blackwood_deadfall_depleted_01.png
custodian/assets/sprites/resources/alloy_vein_standing_01.png
custodian/assets/sprites/resources/alloy_vein_depleted_01.png
custodian/assets/sprites/resources/wreckage_salvage_01.png
custodian/assets/sprites/resources/wreckage_depleted_01.png
```

If you later add animation:

```text
custodian/assets/sprites/resources/blackwood_chop_fx_01.png
custodian/assets/sprites/resources/ore_mine_fx_01.png
custodian/assets/sprites/resources/salvage_spark_fx_01.png
```

## Documentation drift check

Current design docs already say early recon should recover materials and specifically list **Scrap**, **Power Components**, and other intelligence outputs, so the feature fits.  The drift is that the runtime/doc set does not appear to have a dedicated resource collection spec yet. Add `RESOURCE_COLLECTION_SYSTEM.md`, then update `custodian/docs/ai_context/CURRENT_STATE.md` after implementation so future agents know resources are no longer just design intent.
