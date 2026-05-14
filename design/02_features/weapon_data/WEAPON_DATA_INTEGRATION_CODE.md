# Weapon Data Integration - Implementation Code

> **Proposal Sheet** - Copy these files verbatim to implement
> Reference: `WEAPON_DATA_INTEGRATION.md`

---

## File 1: weapon_data_loader.gd

**Path:** `custodian/core/systems/weapon_data_loader.gd`

```gdscript
class_name WeaponDataLoader
extends Node

const WEAPON_DATA_PATH := "res://assets/weapons/data/"
const REGISTRY_PATH := "res://assets/weapons/registry.json"

var _weapon_cache: Dictionary = {}
var _registry: Dictionary = {}

func _ready() -> void:
	load_registry()
	load_all_weapons()

func load_registry() -> void:
	var file := FileAccess.open(REGISTRY_PATH, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		var json = JSON.parse_string(json_text)
		if json is Dictionary:
			_registry = json
		file.close()

func load_all_weapons() -> void:
	if _registry.is_empty() or not _registry.has("weapons"):
		push_warning("[WeaponDataLoader] Registry empty or missing weapons list")
		return
	
	for weapon_id in _registry["weapons"]:
		load_weapon(weapon_id)

func load_weapon(weapon_id: String) -> Dictionary:
	var path = WEAPON_DATA_PATH + weapon_id + ".json"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("[WeaponDataLoader] Failed to load: " + path)
		return {}
	
	var json_text = file.get_as_text()
	var json = JSON.parse_string(json_text)
	file.close()
	
	if json is Dictionary:
		_weapon_cache[weapon_id] = json
		return json
	return {}

func get_weapon_data(weapon_id: String) -> Dictionary:
	return _weapon_cache.get(weapon_id, {})

func get_weapon_stats(weapon_id: String) -> Dictionary:
	var data = get_weapon_data(weapon_id)
	return data.get("stats", {})

func get_weapon_ammo(weapon_id: String) -> Dictionary:
	var data = get_weapon_data(weapon_id)
	return data.get("ammo", {})
```

---

## File 2: weapon_definition_factory.gd

**Path:** `custodian/core/systems/weapon_definition_factory.gd`

```gdscript
class_name WeaponDefinitionFactory
extends Node

var weapon_data_loader: WeaponDataLoader

func _ready() -> void:
	weapon_data_loader = WeaponDataLoader.new()
	add_child(weapon_data_loader)

func create_weapon_definition(weapon_id: String) -> OperatorWeaponDefinition:
	var def = OperatorWeaponDefinition.new()
	var data = weapon_data_loader.get_weapon_data(weapon_id)
	
	if data.is_empty():
		push_warning("[WeaponDefinitionFactory] No data for weapon: " + weapon_id)
		return def
	
	def.weapon_id = StringName(weapon_id)
	
	var stats = data.get("stats", {})
	def.damage = float(stats.get("damage", 12.0))
	def.fire_rate_rps = float(stats.get("fire_rate_rps", 7.5))
	def.magazine_size = int(stats.get("magazine_size", 28))
	def.reload_time_sec = float(stats.get("reload_time_sec", 1.7))
	def.range_px = float(stats.get("range_px", 300.0))
	def.accuracy = float(stats.get("accuracy", 0.86))
	def.spread_deg = float(stats.get("spread_deg", 2.0))
	def.recoil = float(stats.get("recoil", 0.35))
	def.projectile_speed_px = float(stats.get("projectile_speed_px", 950.0))
	def.penetration = int(stats.get("penetration", 1))
	
	var ammo = data.get("ammo", {})
	def.ammo_type = String(ammo.get("ammo_type", "kinetic"))
	def.reserve_ammo = int(ammo.get("reserve", 112))
	def.reload_style = String(ammo.get("reload_style", "magazine"))
	
	def.current_magazine = def.magazine_size
	
	var weapon_class = data.get("weapon_class", "carbine")
	match weapon_class:
		"pistol":
			def.weapon_type = &"ranged_1h"
		"shotgun", "smg", "carbine", "rifle", "minigun", "sniper":
			def.weapon_type = &"ranged_2h"
	
	return def
```

---

## File 3: operator_weapon_definition.gd (ADDITIONS)

**Path:** `custodian/entities/operator/operator_weapon_definition.gd`

**Replace the entire file with:**

```gdscript
extends Resource
class_name OperatorWeaponDefinition

@export var weapon_id: StringName = &"carbine_rifle"
@export var weapon_type: StringName = &"ranged_2h"
@export var frames_resource: SpriteFrames
@export var animation_map: Dictionary = {
	"ranged_stance": "ranged_2h_stance",
	"ranged_fire": "ranged_2h_fire"
}
@export var hit_windows: Dictionary = {}
@export var fx_map: Dictionary = {}
@export var authored_body_stance_animation: StringName = &""

# Socket positions
@export var right_hand_socket_position: Vector2 = Vector2(10, -16)
@export var left_hand_socket_position: Vector2 = Vector2(2, -12)
@export var weapon_socket_position: Vector2 = Vector2(12, -16)
@export var weapon_sprite_position: Vector2 = Vector2.ZERO
@export var weapon_sprite_scale: Vector2 = Vector2.ONE
@export var weapon_sprite_rotation_degrees: float = 0.0
@export var muzzle_socket_position: Vector2 = Vector2(20, 2)

# Direction variants
@export var right_hand_socket_position_up: Vector2 = Vector2(10, -18)
@export var left_hand_socket_position_up: Vector2 = Vector2(0, -14)
@export var weapon_socket_position_up: Vector2 = Vector2(12, -18)
@export var muzzle_socket_position_up: Vector2 = Vector2(20, 0)

@export var right_hand_socket_position_down: Vector2 = Vector2(10, -14)
@export var left_hand_socket_position_down: Vector2 = Vector2(3, -10)
@export var weapon_socket_position_down: Vector2 = Vector2(12, -14)
@export var muzzle_socket_position_down: Vector2 = Vector2(20, 4)

# === WEAPON STATS (from JSON) ===

@export_group("Combat Stats")
@export var damage: float = 12.0
@export var fire_rate_rps: float = 7.5
@export var magazine_size: int = 28
@export var reload_time_sec: float = 1.7
@export var range_px: float = 300.0
@export var accuracy: float = 0.86
@export var spread_deg: float = 2.0
@export var recoil: float = 0.35
@export var projectile_speed_px: float = 950.0
@export var penetration: int = 1

@export_group("Ammo")
@export var ammo_type: String = "kinetic"
@export var reserve_ammo: int = 112
@export var reload_style: String = "magazine"

# === RUNTIME STATE ===
@export_group("Runtime State")
@export var current_magazine: int = 0
@export var is_reloading: bool = false
@export var reload_timer: float = 0.0
```

---

## File 4: operator.gd (DIFF)

**Path:** `custodian/entities/operator/operator.gd`

### Change 1: Add factory reference (near top of file, with other @onready)

```gdscript
# Add after other @onready declarations:
@onready var weapon_factory: Node = get_node_or_null("/root/GameRoot/World/WeaponDefinitionFactory")
```

### Change 2: Update _fire_ranged() function

**Find:** `_fire_ranged()` and replace with:

```gdscript
func _fire_ranged() -> void:
	var weapon_def = _get_equipped_primary_weapon_definition()
	if weapon_def == null:
		return
	
	# Check magazine ammo
	if weapon_def.current_magazine <= 0:
		_start_reload()
		return
	
	# Use fire rate from weapon definition
	var fire_cooldown = 1.0 / max(0.1, weapon_def.fire_rate_rps)
	fire_cooldown_remaining = fire_cooldown
	
	# Consume from magazine
	weapon_def.current_magazine -= 1
	_update_ammo_ui()
	
	# ... rest of existing fire logic remains the same
```

### Change 3: Add reload functions (at end of file, before final closing)

```gdscript
# === RELOAD SYSTEM ===

func _start_reload() -> void:
	var weapon_def = _get_equipped_primary_weapon_definition()
	if weapon_def == null or weapon_def.is_reloading:
		return
	
	weapon_def.is_reloading = true
	weapon_def.reload_timer = weapon_def.reload_time_sec
	print("[Operator] Reloading: ", weapon_def.magazine_size, " rounds in ", weapon_def.reload_time_sec, "s")


func _process_reload(delta: float) -> void:
	var weapon_def = _get_equipped_primary_weapon_definition()
	if weapon_def == null or not weapon_def.is_reloading:
		return
	
	weapon_def.reload_timer -= delta
	if weapon_def.reload_timer <= 0:
		weapon_def.is_reloading = false
		weapon_def.current_magazine = weapon_def.magazine_size
		_update_ammo_ui()
		print("[Operator] Reload complete: ", weapon_def.current_magazine, " / ", weapon_def.magazine_size)


func _update_ammo_ui() -> void:
	var weapon_def = _get_equipped_primary_weapon_definition()
	if weapon_def == null:
		return
	
	# Update the global ammo counts to match weapon magazine
	# This keeps the existing UI working while using weapon-specific mags
	ammo_standard = weapon_def.current_magazine
```

### Change 4: Add to _process() to call reload

**Find:** `_process(delta: float)` and add this call:

```gdscript
func _process(delta: float):
	# ... existing code ...
	
	# Process weapon reload
	_process_reload(delta)
```

---

## File 5: bullet.gd (or projectile)

**Path:** `custodian/entities/projectiles/bullet.gd`

### Add setup method

```gdscript
# Add this function to the bullet class:
func setup_from_weapon(weapon_def: OperatorWeaponDefinition, spawn_pos: Vector2, direction: Vector2) -> void:
	global_position = spawn_pos
	damage = weapon_def.damage
	speed = weapon_def.projectile_speed_px
	penetration = weapon_def.penetration
	
	# Apply accuracy/spread
	var spread_rad = deg_to_rad(weapon_def.spread_deg)
	var final_direction = direction.rotated(randf_range(-spread_rad, spread_rad))
	velocity = final_direction * speed
```

### Update where bullet is spawned in operator.gd

**Find:** where bullet is instantiated and update:

```gdscript
# Find this in _fire_ranged():
var bullet = bullet_scene.instantiate()

# Change to:
var bullet = bullet_scene.instantiate()
if weapon_def and bullet.has_method("setup_from_weapon"):
	bullet.setup_from_weapon(weapon_def, muzzle_global_position, aim_direction)
```

---

## File 6: ui.gd (DIFF)

**Path:** `custodian/scenes/ui.gd`

### Update ammo display

**Find:** where ammo_label is updated (around line 261):

```gdscript
# Replace the ammo text generation:
if ammo_label:
	var weapon_def = null
	if operator and operator.has_method("_get_equipped_primary_weapon_definition"):
		weapon_def = operator._get_equipped_primary_weapon_definition()
	
	if weapon_def and weapon_def.current_magazine > 0:
		var ammo_text = "AMMO %d/%d" % [weapon_def.current_magazine, weapon_def.magazine_size]
		if weapon_def.is_reloading:
			ammo_text += " [RELOADING...]"
		ammo_label.text = ammo_text
	else:
		ammo_label.text = "AMMO --/--"
```

---

## Scene Setup

### Add WeaponDefinitionFactory to game scene

**File:** `custodian/scenes/game.tscn` (or equivalent)

1. Add new node: `WeaponDefinitionFactory` (Node type)
2. Set script: `weapon_definition_factory.gd`
3. Ensure it loads before operator

---

## Testing Checklist

- [ ] Carbine fires at correct rate (7.5 RPS ≈ 0.133s between shots)
- [ ] Magazine depletes after 28 rounds
- [ ] Auto-reload triggers at 0 rounds
- [ ] Reload takes 1.7 seconds
- [ ] UI shows "AMMO 15/28"
- [ ] Damage reflects weapon definition (12 damage)
- [ ] Different weapons load different stats

---

## Rollback Notes

If issues occur:
1. Revert operator.gd changes to restore hardcoded fire rate
2. Weapon definitions retain default values if JSON fails to load

---

*Implementation code - copy verbatim to implement*
