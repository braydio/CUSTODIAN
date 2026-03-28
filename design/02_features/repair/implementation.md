# CUSTODIAN — Repair Gameplay System Implementation Plan

**Created:** 2026-03-05
**Status:** In Progress (Runtime Slice Implemented: Hold-R Repair + Prompt + Destroyed Lockout)
**Depends On:** Sector Damage System

---

## 1. Overview

The player can repair damaged structures. This creates the core gameplay tension: defend vs repair during combat.

### Repair Mechanic

1. Player approaches damaged structure
2. Holds repair action (e.g., Hold R or Right Click)
3. Structure repairs over time
4. Must balance combat vs repair

---

## 2. Repair Tool System

### Option A: Repair Action (Simple)

Add repair functionality to existing interaction system.

**Modify:** `res://entities/operator/operator.gd`

```gdscript
# Add to operator.gd

@export var repair_rate: float = 15.0  # HP per second
var repair_target: Node = null

func _process(delta):
    # ... existing code ...
    
    # Handle repair input
    if Input.is_key_pressed(KEY_R):
        _try_repair(delta)

func _try_repair(delta):
    # Find nearest damageable structure
    var candidates = get_tree().get_nodes_in_group("structure")
    
    var nearest: Node = null
    var nearest_dist := interaction_range
    
    for candidate in candidates:
        if candidate is Damageable:
            var dist = global_position.distance_to(candidate.global_position)
            if dist < nearest_dist and candidate.current_health < candidate.max_health:
                nearest_dist = dist
                nearest = candidate
    
    if nearest and nearest is Damageable:
        _repair_structure(nearest, delta)

func _repair_structure(structure: Damageable, delta: float):
    var repair_amount = repair_rate * delta
    structure.repair(repair_amount)
    
    # Show repair feedback
    if randf() < 0.1:  # Don't spam
        print("[Repair] Repairing ", structure.name)
```

### Option B: Repair Tool Selection (More Control)

Switch between weapons and repair tool.

**Modify:** `res://entities/operator/operator.gd`

```gdscript
# Add weapon profile for repair

const WEAPON_PROFILES = [
    # ... existing weapons ...
    {
        "name": "REPAIR",
        "cooldown": 0.0,
        "rate": 15.0,
        "range": 80.0,
    },
]

# Add keybind for repair mode
func _handle_weapon_switch():
    if Input.is_key_pressed(KEY_1):
        weapon_profile = 0
    elif Input.is_key_pressed(KEY_2):
        weapon_profile = 1
    elif Input.is_key_pressed(KEY_3):
        weapon_profile = 2  # Repair tool
```

---

## 3. Visual Feedback for Repair

### Repair Indicator

Add a repair prompt when near damaged structure:

**Modify:** `res://scenes/ui.gd`

```gdscript
func _update_repair_prompt():
    var operator = get_node_or_null("/root/GameRoot/World/Operator")
    if operator == null:
        return
    
    var candidates = get_tree().get_nodes_in_group("structure")
    var nearest: Node = null
    var nearest_dist := operator.interaction_range
    
    for candidate in candidates:
        if candidate is Damageable:
            var dist = operator.global_position.distance_to(candidate.global_position)
            if dist < nearest_dist and candidate.current_health < candidate.max_health:
                nearest_dist = dist
                nearest = candidate
    
    if nearest:
        var hp_percent = int((nearest.current_health / nearest.max_health) * 100)
        show_prompt("Hold R to repair " + nearest.name + " (" + str(hp_percent) + "% HP)")
    else:
        hide_prompt()
```

---

## 4. Repair Kit Pickup (Optional)

Add ammo-like system for repairs.

**File:** `res://entities/items/repair_kit.tscn`

```gdscript
extends Area2D
class_name RepairKit

@export var heal_amount: float = 30.0

func _ready():
    add_to_group("pickup")

func interact(operator):
    operator.pickup_repair_kit(heal_amount)
    queue_free()
```

**Add to operator.gd:**

```gdscript
var repair_kits: int = 3
var max_repair_kits: int = 10

func pickup_repair_kit(amount: float):
    repair_kits = min(max_repair_kits, repair_kits + 1)

func use_repair_kit():
    if repair_kits > 0:
        repair_kits -= 1
        # Apply to nearest damaged structure
```

---

## 5. Repair Priority Decision

During combat, player must choose:

| Situation | Best Choice |
|-----------|-------------|
| Enemies approaching Command Post | Repair Command Post |
| Power Node critical | Repair Power Node |
| Many turrets down | Repair Turrets |
| Player HP low | Combat (kill enemies) |

This creates meaningful decisions.

---

## 6. Testing Checklist

- [x] Player can repair damaged structures
- [ ] Repair rate is balanced (not too fast/slow)
- [x] Visual feedback shows repair prompt
- [x] Cannot repair destroyed structures
- [x] Repair competes with combat (decision tension)

---

## 6.1 Clarification — Repair Economy Targets (2026-03-07)

These targets define the baseline balancing contract for repair gameplay:

- Manual repair baseline: `15 HP/sec` (held action).
- Pause-menu emergency repair baseline: `50 HP` for `25` power.
- Operational objective:
  - One operator can stabilize one critical structure under light pressure.
  - One operator cannot fully out-repair sustained multi-lane assault damage.
- Priority pressure objective:
  - During low power (`< 30%`), repairing power nodes should usually be the highest-value choice.
  - Repairing Command Post in `critical` state should trade off direct combat output and be risky.
- Anti-exploit guardrails:
  - Destroyed structures (`state == destroyed`) are not repairable in-combat unless explicitly rebuilt by a future build/recovery system.
  - Repair actions should respect interaction/range constraints and line-of-risk (player exposed while repairing).

---

## 7. Full Gameplay Loop

Now complete:

```
Wave Spawning → Enemies spawn
      ↓
Enemy Objective → Enemies attack structures
      ↓
Sector Damage → Structures degrade
      ↓
Player Choice → Fight or Repair?
      ↓
   [If Repair] → Repair System → Structure restored
   [If Fight] → Kill enemies → Wave cleared
      ↓
   Repeat with harder waves
```

---

## 8. Optional: Repair Station

For later, add fixed repair stations:

```gdscript
# Auto-repair nearby structures when powered
class_name RepairStation

@export var repair_rate: float = 5.0
@export var range: float = 150.0

func _physics_process(delta):
    if not is_powered():
        return
    
    var nearby = get_tree().get_nodes_in_group("structure")
    for structure in nearby:
        if structure is Damageable:
            var dist = global_position.distance_to(structure.global_position)
            if dist < range:
                structure.repair(repair_rate * delta * 0.1)  # Slow auto-repair
```

---

## 9. Summary

The Repair System completes the core gameplay loop:

1. **Wave** → Enemies spawn
2. **Attack** → Enemies damage structures
3. **Damage** → Efficiency decreases
4. **Decision** → Fight or repair?
5. **Repair** → Restore functionality
6. **Escalate** → Next wave harder

This creates the tension that makes CUSTODIAN feel like a game.
