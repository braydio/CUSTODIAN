# CUSTODIAN — Forest Shrumb Runtime Implementation Delta

Status: draft implementation delta
Purpose: compact Codex/agent-facing runtime implementation instructions
Depends on: `design/features/implementation/FOREST_SHRUMB_COGNITIVE_DROPS.md` or equivalent Forest Shrumb lore/gameplay design document
Runtime target: Godot 4.x under `custodian/`

---

## 1. Scope

Do not restate the full Forest Shrumb lore design here. Agents should read the existing Forest Shrumb lore/gameplay item design for:

* The Tragedy of the Forest Shrumb.
* Item lore and descriptions.
* Item visual direction.
* Gameplay state philosophy.
* Cognitive states: `DRIFT`, `FLOW`, `ALIGNMENT`, `MIXED`.
* Intended item trio:

  * `faint_recollection`
  * `residual_instinct`
  * `ancient_bearing`

This document only defines the runtime delta required to make that design real in the current Godot project.

---

## 2. Confirmed Runtime State

Current validation indicates:

* There is **no inventory system currently**.
* There is **no `CognitiveStateSystem` currently**.
* There are **no item definitions** for:

  * Faint Recollection
  * Residual Instinct
  * Ancient Bearing
* There is **no cognitive pickup scene/script** currently.
* There is **no implemented cognitive drop table** for Forest Shrumbs currently.
* There is an existing `ambient_shrumb.tscn`, but it must not be blindly assumed to be the final lore-accurate Forest Shrumb actor.
* The current `ambient_shrumb.tscn` may currently behave like a scrap/droid-style ambient enemy and may already have scrap-drop behavior.
* The shrumb death/drop hook is a live check item. Inspect before adding duplicate death logic.

---

## 3. Required Pre-Implementation Checks

Before adding code, inspect the live runtime for:

1. `custodian/game/actors/enemies/ambient_shrumb.tscn`
2. The script attached to `ambient_shrumb.tscn`, if any.
3. Any inherited behavior from `custodian/game/actors/enemies/enemy.gd`.
4. Any existing death signal, `die()`, `_die()`, `on_death`, `health_depleted`, or drop callback.
5. Existing item pickup patterns:

   * `custodian/game/actors/items/scrap_pickup.gd`
   * `custodian/game/actors/items/ammo_cache.gd`
6. Existing autoloads in `custodian/project.godot`.
7. Existing data conventions under:

   * `custodian/content/`
   * `custodian/content/ammo_types/ammo_types.json`

If `ambient_shrumb.tscn` already has a death/drop hook, attach the Forest Shrumb cognitive dropper there.

If not, add one clean death signal path and do not duplicate existing enemy death behavior.

---

## 4. Actor Identity Correction

The current runtime has an `ambient_shrumb.tscn`, but validation suggests it may be acting as a scrap/droid-style enemy.

Do **not** mix the final Forest Shrumb lore drops into a droid actor by accident.

Choose one implementation path:

### Preferred Path

Create or preserve a true lore actor:

```text
custodian/game/actors/enemies/forest_shrumb.tscn
custodian/game/actors/enemies/forest_shrumb.gd
```

Then use that actor for the Forest Shrumb item drops.

If the existing `ambient_shrumb.tscn` is actually being used as a scrap droid, rename or duplicate it later into a better identity such as:

```text
custodian/game/actors/enemies/ambient_scav_droid.tscn
```

### Acceptable Temporary Path

If references make renaming too risky, keep `ambient_shrumb.tscn` as the runtime path but update its semantics carefully:

* Remove or disable scrap/droid-only drop behavior for true shrumb variants.
* Add the cognitive dropper only to actual shrumb instances.
* Avoid breaking existing test maps or ambient critter spawning.

---

## 5. Minimal Inventory Ledger

Because there is no inventory system, v1 must add a tiny stack-count ledger.

Do not build a full inventory UI.

Do not build equipment slots.

Do not build drag/drop, sorting, stash, grids, item inspection screens, or RPG bag logic.

Add:

```text
custodian/game/systems/core/systems/inventory_manager.gd
```

Autoload:

```text
InventoryManager -> res://game/systems/core/systems/inventory_manager.gd
```

Implementation:

```gdscript
class_name InventoryManager
extends Node

signal item_added(item_id: StringName, amount: int, new_total: int)
signal item_removed(item_id: StringName, amount: int, new_total: int)
signal item_count_changed(item_id: StringName, old_total: int, new_total: int)
signal inventory_changed

var _items: Dictionary = {}

func add_item(item_id: StringName, amount: int = 1) -> int:
	if item_id == &"" or amount <= 0:
		return get_count(item_id)

	var old_total := get_count(item_id)
	var new_total := old_total + amount
	_items[item_id] = new_total

	item_added.emit(item_id, amount, new_total)
	item_count_changed.emit(item_id, old_total, new_total)
	inventory_changed.emit()

	return new_total

func remove_item(item_id: StringName, amount: int = 1) -> bool:
	if item_id == &"" or amount <= 0:
		return false

	var old_total := get_count(item_id)
	if old_total < amount:
		return false

	var new_total := old_total - amount
	if new_total <= 0:
		_items.erase(item_id)
	else:
		_items[item_id] = new_total

	item_removed.emit(item_id, amount, new_total)
	item_count_changed.emit(item_id, old_total, new_total)
	inventory_changed.emit()

	return true

func has_item(item_id: StringName, amount: int = 1) -> bool:
	return get_count(item_id) >= amount

func get_count(item_id: StringName) -> int:
	return int(_items.get(item_id, 0))

func get_all_items() -> Dictionary:
	return _items.duplicate(true)

func clear() -> void:
	_items.clear()
	inventory_changed.emit()

func to_save_dict() -> Dictionary:
	var out := {}
	for key in _items.keys():
		out[String(key)] = int(_items[key])
	return out

func from_save_dict(data: Dictionary) -> void:
	_items.clear()
	for key in data.keys():
		var amount := int(data[key])
		if amount > 0:
			_items[StringName(str(key))] = amount
	inventory_changed.emit()
```

---

## 6. Cognitive State System

Add:

```text
custodian/game/systems/cognitive/cognitive_state_system.gd
```

Autoload:

```text
CognitiveState -> res://game/systems/cognitive/cognitive_state_system.gd
```

The implementation may copy the full `CognitiveStateSystem` from the main Forest Shrumb design doc.

Minimum v1 requirements:

* Track:

  * `recollection: float`
  * `instinct: float`
  * `bearing: float`
  * `instinct_meter: float`
* Support:

  * `add_from_item(item_id, amount)`
  * `add_recollection(amount)`
  * `add_instinct(amount)`
  * `add_bearing(amount)`
  * `get_weights()`
  * `get_dominant_state()`
  * `get_rare_drop_multiplier()`
  * `get_drop_rate_multiplier()`
  * `get_input_delay_variance()`
  * `get_move_speed_multiplier()`
  * `get_attack_recovery_multiplier()`
  * `get_player_accuracy_bonus()`
  * `get_player_crit_bonus()`
  * `get_enemy_accuracy_bonus()`
  * `get_enemy_tracking_bonus()`
  * `to_save_dict()`
  * `from_save_dict(data)`
* Emit:

  * `cognitive_values_changed`
  * `dominant_state_changed`
  * `instinct_action_requested`
  * `cognitive_item_collected`

Do not wire every modifier into combat in the first commit unless the hooks are obvious and low-risk. First commit may expose getters and add debug/HUD output only.

---

## 7. Item Definitions

Add item data under one of these approaches.

Preferred simple v1 path:

```text
custodian/content/items/shrumb_drops/shrumb_drops.json
```

With:

```json
{
  "items": [
    {
      "item_id": "faint_recollection",
      "display_name": "Faint Recollection",
      "description": "A faint recollection shed by forest shrumbs.\nIt stirs toward something once known, but does not gather enough to become it.",
      "stack_size": 999,
      "rarity": "common",
      "cognitive_axis": "recollection",
      "cognitive_value": 1.0
    },
    {
      "item_id": "residual_instinct",
      "display_name": "Residual Instinct",
      "description": "A dull instinct held among forest shrumbs.\nIt compels movement without aim, settling where decision never took hold.",
      "stack_size": 999,
      "rarity": "uncommon",
      "cognitive_axis": "instinct",
      "cognitive_value": 1.0
    },
    {
      "item_id": "ancient_bearing",
      "display_name": "Ancient Bearing",
      "description": "A fragment of orientation from the elder days, carried by the shrumb.\nIt suggests a place once held among the ordered things, though no memory of it remains.",
      "stack_size": 999,
      "rarity": "rare",
      "cognitive_axis": "bearing",
      "cognitive_value": 1.0
    }
  ]
}
```

If the project already has a stronger `.tres` resource pattern for item definitions, use that instead, but do not block implementation on building a universal item database.

---

## 8. Cognitive Pickup

Add one generic pickup:

```text
custodian/game/actors/items/cognitive_pickup.gd
custodian/game/actors/items/cognitive_pickup.tscn
```

The pickup must:

1. Export `item_id: StringName`.
2. Export `quantity: int`.
3. Detect the player entering its pickup area.
4. Add item count to `InventoryManager`.
5. Add cognitive value to `CognitiveState`.
6. Free itself.

Required pickup flow:

```gdscript
var inventory := get_node_or_null("/root/InventoryManager")
if inventory != null:
	inventory.add_item(item_id, quantity)

var cognitive := get_node_or_null("/root/CognitiveState")
if cognitive != null:
	cognitive.add_from_item(item_id, quantity)

queue_free()
```

Do not rely on `Engine.has_singleton()` for script autoloads. Use `/root/InventoryManager` and `/root/CognitiveState`.

---

## 9. Shrumb Dropper

Add reusable component:

```text
custodian/game/actors/items/shrumb_dropper.gd
```

or, if actor-specific components live near enemies:

```text
custodian/game/actors/enemies/shrumb_dropper.gd
```

Prefer the location that matches existing project convention after inspection.

The dropper must:

* Export `cognitive_pickup_scene: PackedScene`.
* Roll the drop table.
* Spawn `cognitive_pickup.tscn` at the shrumb death position.
* Apply cognitive modifiers from `CognitiveState` if available.
* Cap `ancient_bearing` chance at 8%.

Drop table:

| Item                 | Chance | Quantity |
| -------------------- | -----: | -------: |
| `faint_recollection` |    65% |        1 |
| `residual_instinct`  |    22% |        1 |
| `ancient_bearing`    |     5% |        1 |
| nothing              |     8% |        0 |

---

## 10. Death Hook Rule

Before adding any new death method, inspect the actor.

Required rule:

```text
Before adding new shrumb death logic, inspect ambient_shrumb.tscn and its attached script.
If a death/drop hook already exists, attach the ShrumbDropper there.
If not, add one clean death signal path and do not duplicate existing enemy death behavior.
```

If using inherited `enemy.gd` death behavior, prefer:

* Connect to an existing death signal.
* Override a single existing death callback.
* Call parent behavior if required.

Avoid:

* Duplicating `die()` in multiple scripts.
* Calling `queue_free()` before drops spawn.
* Adding two drop systems to the same actor.
* Leaving existing scrap drops enabled on the true Forest Shrumb unless intentionally desired.

---

## 11. Placeholder Assets

If final art does not exist, add placeholder sprites but clearly mark them as placeholders.

Expected final asset paths:

```text
custodian/content/sprites/items/shrumb_drops/faint_recollection.png
custodian/content/sprites/items/shrumb_drops/residual_instinct.png
custodian/content/sprites/items/shrumb_drops/ancient_bearing.png
```

Optional pickup animation sheets:

```text
custodian/content/sprites/items/shrumb_drops/faint_recollection_pickup_anim.png
custodian/content/sprites/items/shrumb_drops/residual_instinct_pickup_anim.png
custodian/content/sprites/items/shrumb_drops/ancient_bearing_pickup_anim.png
```

Placeholder rules:

* Use simple colored 32×32 sprites if needed.
* Do not pretend placeholder art is final.
* Do not bind large source/master sheets directly as runtime pickup animations.

---

## 12. HUD / Debug v1

Minimum useful feedback:

* On pickup, print or toast:

  * `Faint Recollection +1`
  * `Residual Instinct +1`
  * `Ancient Bearing +1`
* Add a temporary debug readout for:

  * `recollection`
  * `instinct`
  * `bearing`
  * dominant state

If HUD integration is risky, start with debug logs and keep UI integration separate.

---

## 13. Gameplay Modifier Integration Strategy

Do not wire everything at once.

### Phase A — Safe Foundation

Implement:

* Inventory ledger.
* Cognitive state autoload.
* Item data.
* Cognitive pickup.
* Shrumb dropper.
* Debug output.

### Phase B — Low-Risk Runtime Effects

Implement only low-risk modifiers first:

* `get_move_speed_multiplier()` queried by player movement if the hook is obvious.
* `get_rare_drop_multiplier()` queried by `ShrumbDropper`.
* `get_drop_rate_multiplier()` queried by `ShrumbDropper`.

### Phase C — Combat Feel Hooks

Implement after confirming operator/combat architecture:

* Input delay variance for discrete actions only.
* Attack recovery modifier.
* Accuracy/spread modifier.
* Enemy tracking/accuracy modifier.

### Phase D — Instinct Actions

Implement last:

* Auto-reposition.
* Auto-dodge.

Do not implement auto-attack in v1. It is too likely to interfere with animation commitment and combat state.

---

## 14. Acceptance Criteria

A successful v1 implementation proves:

1. `InventoryManager` autoload exists and tracks stack counts.
2. `CognitiveState` autoload exists and tracks the three cognitive axes.
3. The three item definitions exist.
4. Killing or triggering a true Forest Shrumb can spawn one of the three cognitive pickups.
5. Picking up the item increments inventory count.
6. Picking up the item increments the correct cognitive axis.
7. Cognitive values decay over time.
8. Dominant state changes between `DRIFT`, `FLOW`, `ALIGNMENT`, and `MIXED`.
9. Debug/HUD output confirms item and cognitive changes.
10. Existing scrap/ammo pickups still work.
11. Existing combat enemies still work.
12. No duplicate death/drop hook fires for the shrumb.

---

## 15. Documentation Updates Required

After implementation, update:

```text
custodian/docs/ai_context/CURRENT_STATE.md
custodian/docs/ai_context/FILE_INDEX.md
custodian/docs/ai_context/CONTEXT.md
```

If architecture changed materially, also update:

```text
custodian/docs/ARCHITECTURE.md
custodian/docs/SCENE_HIERARCHY.md
```

If the implementation spec lives under `design/features/implementation/`, update its status label from `draft` to `review` or `complete` according to actual implementation status.

---

## 16. One-Shot Codex Prompt

```text
Implement the Forest Shrumb runtime foundation from design/features/implementation/FOREST_SHRUMB_RUNTIME_IMPLEMENTATION_DELTA.md.

Assume the full Forest Shrumb lore/gameplay design already exists and should not be restated.

Confirmed runtime facts:
- There is no inventory system currently.
- There is no CognitiveStateSystem currently.
- The three shrumb items do not exist yet.
- The current ambient_shrumb.tscn must be inspected before use because it may be behaving as a scrap/droid-style enemy.
- A death/drop hook may already exist; inspect before adding duplicate death logic.

Implement v1 only:
1. Add minimal InventoryManager stack ledger and autoload it.
2. Add CognitiveStateSystem and autoload it.
3. Add item definitions for faint_recollection, residual_instinct, ancient_bearing.
4. Add generic CognitivePickup scene/script.
5. Add ShrumbDropper component with the specified drop table.
6. Attach the dropper only to the true Forest Shrumb path after inspecting ambient_shrumb.tscn and its script.
7. Use placeholder 32x32 sprites if final item art is missing.
8. Add debug or minimal HUD pickup feedback.
9. Do not implement full inventory UI.
10. Do not implement auto-attack.
11. Do not duplicate death/drop behavior.
12. Do not modify legacy python-sim runtime.
13. Update CURRENT_STATE.md, FILE_INDEX.md, and CONTEXT.md after runtime changes.

Validate by running the Godot project if feasible.
```
