# Weapon Data Integration Design

## Status: ✅ IMPLEMENTED

**Implemented:** 2026-03-29

| Component | Status |
|-----------|--------|
| JSON weapon data loader | ✅ Complete |
| Weapon definition factory | ✅ Complete |
| OperatorWeaponDefinition stats | ✅ Complete |
| Factory integration in equip | ✅ Complete |
| Game scene setup | ✅ Complete |
| UI reload indicator | ✅ Complete |

---

## Overview

Wire the existing JSON weapon definitions (`assets/weapons/data/*.json`) into the runtime game so weapon stats like clip size, fire rate, and damage are actually used instead of hardcoded values.

---

## Current State

### What Exists

| Component | Status |
|-----------|--------|
| JSON weapon data | ✅ Complete (`carbine_mk1.json`, `pistol_mk1.json`, etc.) |
| `OperatorWeaponDefinition.gd` | ⚠️ Minimal - only has animation/socket data |
| Player ammo | ⚠️ Global variables (`ammo_standard`, `ammo_heavy`) |
| Fire rate | ⚠️ Hardcoded in `_fire_ranged()` (~0.3s) |
| Damage | ⚠️ Determined by projectile, not weapon |

### What Needs to Change

1. **Load JSON weapon data** at runtime
2. **Extend `OperatorWeaponDefinition`** to include stats
3. **Wire weapon stats** to player/ranged fire system
4. **Update UI** to show clip size (current ammo / magazine size)

---

## JSON Weapon Data Structure

Each weapon JSON (`carbine_mk1.json`, etc.) contains:

```json
{
  "id": "carbine_mk1",
  "stats": {
    "damage": 12,
    "fire_rate_rps": 7.5,
    "magazine_size": 28,
    "reload_time_sec": 1.7,
    "range_px": 300,
    "accuracy": 0.86,
    "spread_deg": 2.0,
    "recoil": 0.35
  },
  "ammo": {
    "ammo_type": "kinetic",
    "capacity": 28,
    "reserve": 112,
    "reload_style": "magazine"
  }
}
```

---

## Implementation Plan

### Phase 1: JSON Loader System

Create `WeaponDataLoader.gd` to load and parse weapon JSON files.

**File:** `custodian/core/systems/weapon_data_loader.gd`

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
        var json = JSON.parse_string(file.get_as_text())
        _registry = json as Dictionary
        file.close()

func load_all_weapons() -> void:
    if _registry.is_empty() or not _registry.has("weapons"):
        return
    
    for weapon_id in _registry["weapons"]:
        load_weapon(weapon_id)

func load_weapon(weapon_id: String) -> Dictionary:
    var path = WEAPON_DATA_PATH + weapon_id + ".json"
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_warning("[WeaponDataLoader] Failed to load: " + path)
        return {}
    
    var json = JSON.parse_string(file.get_as_text())
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

### Phase 2: Extend OperatorWeaponDefinition

Add weapon stats to the resource class.

**File:** `custodian/entities/operator/operator_weapon_definition.gd`

**Add these exports:**

```gdscript
# Combat Stats (from JSON)
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

# Ammo
@export var ammo_type: String = "kinetic"
@export var reserve_ammo: int = 112
@export var reload_style: String = "magazine"

# Runtime state
var current_magazine: int = 0
var is_reloading: bool = false
var reload_timer: float = 0.0
```

---

### Phase 3: Weapon Definition Factory

Create a factory to build `OperatorWeaponDefinition` from JSON.

**File:** `custodian/core/systems/weapon_definition_factory.gd`

```gdscript
class_name WeaponDefinitionFactory
extends Node

var weapon_data_loader: WeaponDataLoader

func _ready() -> void:
    weapon_data_loader = WeaponDataLoader.new()
    add_child(weapon_data_loader)

func create_weapon_definition(weapon_id: String) -> OperatorWeaponDefinition:
    var def := OperatorWeaponDefinition.new()
    var data = weapon_data_loader.get_weapon_data(weapon_id)
    
    if data.is_empty():
        push_warning("[WeaponDefinitionFactory] No data for: " + weapon_id)
        return def
    
    # Set ID
    def.weapon_id = StringName(weapon_id)
    
    # Set stats from JSON
    var stats = data.get("stats", {})
    def.damage = stats.get("damage", 12.0)
    def.fire_rate_rps = stats.get("fire_rate_rps", 7.5)
    def.magazine_size = stats.get("magazine_size", 28)
    def.reload_time_sec = stats.get("reload_time_sec", 1.7)
    def.range_px = stats.get("range_px", 300.0)
    def.accuracy = stats.get("accuracy", 0.86)
    def.spread_deg = stats.get("spread_deg", 2.0)
    def.recoil = stats.get("recoil", 0.35)
    def.projectile_speed_px = stats.get("projectile_speed_px", 950.0)
    def.penetration = stats.get("penetration", 1)
    
    # Set ammo from JSON
    var ammo = data.get("ammo", {})
    def.ammo_type = ammo.get("ammo_type", "kinetic")
    def.reserve_ammo = ammo.get("reserve", 112)
    def.reload_style = ammo.get("reload_style", "magazine")
    
    # Initialize magazine
    def.current_magazine = def.magazine_size
    
    # Set type based on class
    var weapon_class = data.get("weapon_class", "carbine")
    match weapon_class:
        "pistol":
            def.weapon_type = &"ranged_1h"
        "shotgun", "smg", "carbine", "rifle":
            def.weapon_type = &"ranged_2h"
        "sniper":
            def.weapon_type = &"ranged_2h"
        "minigun":
            def.weapon_type = &"ranged_2h"
    
    return def
```

---

### Phase 4: Wire to Operator

Update `operator.gd` to use weapon definition stats.

**File:** `custodian/entities/operator/operator.gd`

#### 4.1 Add weapon factory reference

```gdscript
@onready var weapon_factory: WeaponDefinitionFactory = $WeaponDefinitionFactory
```

#### 4.2 Update ranged fire to use weapon stats

```gdscript
func _fire_ranged() -> void:
    var weapon_def = _get_equipped_primary_weapon_definition()
    if weapon_def == null:
        return
    
    # Check ammo from weapon definition
    if weapon_def.current_magazine <= 0:
        _start_reload()
        return
    
    # Use fire rate from weapon definition (convert RPS to cooldown)
    var fire_cooldown = 1.0 / weapon_def.fire_rate_rps
    fire_cooldown_remaining = fire_cooldown
    
    # Consume from magazine
    weapon_def.current_magazine -= 1
    _update_ammo_ui()
    
    # ... rest of fire logic
```

#### 4.3 Add reload logic

```gdscript
func _start_reload() -> void:
    var weapon_def = _get_equipped_primary_weapon_definition()
    if weapon_def == null or weapon_def.is_reloading:
        return
    
    weapon_def.is_reloading = true
    weapon_def.reload_timer = weapon_def.reload_time_sec

func _process_reload(delta: float) -> void:
    var weapon_def = _get_equipped_primary_weapon_definition()
    if weapon_def == null or not weapon_def.is_reloading:
        return
    
    weapon_def.reload_timer -= delta
    if weapon_def.reload_timer <= 0:
        # Reload complete
        weapon_def.is_reloading = false
        weapon_def.current_magazine = weapon_def.magazine_size
        _update_ammo_ui()
```

#### 4.4 Update ammo UI

```gdscript
func _update_ammo_ui() -> void:
    var weapon_def = _get_equipped_primary_weapon_definition()
    if weapon_def == null:
        return
    
    # Show: current_magazine / magazine_size | reserve
    var ammo_text = "AMMO %d/%d | %d" % [
        weapon_def.current_magazine,
        weapon_def.magazine_size,
        _get_reserve_ammo()
    ]
    # ... update UI label
```

---

### Phase 5: Update Projectile Damage

Update projectile creation to use weapon damage.

**File:** `custodian/entities/projectiles/bullet.gd` (or where projectiles are spawned)

```gdscript
func setup_from_weapon(weapon_def: OperatorWeaponDefinition, spawn_pos: Vector2, direction: Vector2) -> void:
    damage = weapon_def.damage
    speed = weapon_def.projectile_speed_px
    penetration = weapon_def.penetration
    
    # Apply accuracy/spread
    var spread = deg_to_rad(weapon_def.spread_deg)
    direction = direction.rotated(randf_range(-spread, spread))
    velocity = direction * speed
```

---

### Phase 6: UI Updates

Update UI to show clip/magazine info.

**File:** `custodian/scenes/ui.gd`

```gdscript
# In _update_player_stats or similar
var weapon_def = operator._get_equipped_primary_weapon_definition()
if weapon_def:
    var ammo_text = "AMMO %d/%d | RESERVE %d" % [
        weapon_def.current_magazine,
        weapon_def.magazine_size,
        _get_reserve_ammo()
    ]
    ammo_label.text = ammo_text
    
    # Show reload indicator
    if weapon_def.is_reloading:
        ammo_label.text += " [RELOADING...]"
```

---

## File Changes Summary

| File | Action |
|------|--------|
| `custodian/core/systems/weapon_data_loader.gd` | **CREATE** - JSON loader |
| `custodian/core/systems/weapon_definition_factory.gd` | **CREATE** - Factory for weapon defs |
| `custodian/entities/operator/operator_weapon_definition.gd` | **MODIFY** - Add stats exports |
| `custodian/entities/operator/operator.gd` | **MODIFY** - Use weapon stats for fire/reload |
| `custodian/entities/projectiles/bullet.gd` | **MODIFY** - Accept damage from weapon |
| `custodian/scenes/ui.gd` | **MODIFY** - Show magazine/clip size |

---

## Testing Checklist

- [ ] Carbine fires at correct rate (7.5 RPS = ~0.133s between shots)
- [ ] Magazine depletes (28 rounds)
- [ ] Auto-reload triggers at 0 rounds
- [ ] Reload takes correct time (1.7s)
- [ ] UI shows "AMMO 15/28 | RESERVE 112"
- [ ] Damage reflects weapon definition (12 damage)
- [ ] Other weapons (shotgun, sniper) load correctly

---

## Backward Compatibility

- Default values in `OperatorWeaponDefinition` ensure old code still works
- If JSON fails to load, falls back to hardcoded values
- Existing weapon definitions (if any .tres files) retain their values

---

## Future Enhancements

1. **Hot reload** - Reload JSON without restart for tuning
2. **Weapon switching** - Different weapons have different stats
3. **Reserve ammo** - Track reserve pool, refill from pickups
4. **Reloading animation** - Trigger reload animation during reload_timer

---

## Implementation Code Reference

**Detailed implementation code (copy verbatim):**
`design/02_features/weapon_data/WEAPON_DATA_INTEGRATION_CODE.md`

---

## Implementation Process

### For Codex Agent

- **Can implement IMMEDIATELY** without proposal sheets
- Copy code from `features/implementation/*.md` files
- Make changes directly

### For Other Agents (OpenCode, Claude, etc.)

- Must create **proposal sheet** with exact code first
- Place proposal in `features/implementation/PROPOSAL_*.md`
- Wait for human review/approval before implementing
- After approval, update status and implement

---

*Document created: 2026-03-27*
*Updated: 2026-03-29*
