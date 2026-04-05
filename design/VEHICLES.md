THE FOLLOWING IS VERSION 1.0 - THIS SHOULD BE CONSIDERED A ROUGH DRAFT OF THE LIVE VERSION BELOW

---

Below is a **clean, Godot-native implementation roadmap for your FIRST vehicle type** (keep it simple: **light hover vehicle / buggy**).

---

# 🚧 Phase 0 — Define the FIRST vehicle archetype (lock scope)

Start with **one constrained design**:

### Vehicle Type: Light Hover Buggy

* 360° movement (no turning radius complexity yet)
* Faster than operator
* No inertia (initially) → same “feel” as player movement
* One weapon (forward firing)
* No passengers
* Instant enter/exit (no animation yet)

👉 This avoids physics hell and lets you integrate cleanly.

---

# 🧱 Phase 1 — Core Architecture (THIS IS THE MOST IMPORTANT PART)

## 1. Introduce a shared interface: `ControllableActor`

Your operator and vehicles must conform to the same control contract.

```gdscript
# controllable_actor.gd
class_name ControllableActor
extends CharacterBody2D

func process_input(input_vector: Vector2, aim_vector: Vector2, is_firing: bool):
    pass

func get_velocity() -> Vector2:
    return velocity
```

---

## 2. Refactor Operator to conform

Your current operator script becomes:

```gdscript
extends ControllableActor

func process_input(input_vector, aim_vector, is_firing):
    velocity = input_vector * move_speed
    move_and_slide()

    if is_firing:
        fire_weapon(aim_vector)
```

---

## 3. Create Vehicle base class

```gdscript
# vehicle_base.gd
class_name VehicleBase
extends ControllableActor

@export var max_speed := 300.0

func process_input(input_vector, aim_vector, is_firing):
    velocity = input_vector * max_speed
    move_and_slide()

    if is_firing:
        fire_weapon(aim_vector)
```

---

# 🎮 Phase 2 — Control Handoff System (enter/exit vehicle)

This is your **core gameplay mechanic**.

## 1. Player Controller becomes a router

```gdscript
# player_controller.gd

var current_actor: ControllableActor

func _process(delta):
    var input_vector = get_movement_input()
    var aim_vector = get_aim_vector()
    var firing = Input.is_action_pressed("fire")

    current_actor.process_input(input_vector, aim_vector, firing)
```

---

## 2. Enter vehicle

```gdscript
func enter_vehicle(vehicle: VehicleBase):
    current_actor = vehicle
    operator.visible = false
```

---

## 3. Exit vehicle

```gdscript
func exit_vehicle():
    operator.global_position = current_actor.global_position
    operator.visible = true
    current_actor = operator
```

---

## 4. Vehicle interaction trigger

Vehicle scene includes:

```gdscript
# vehicle_interaction.gd
func _on_body_entered(body):
    if body is Operator:
        show_prompt("Press E to enter")
```

---

# 🧭 Phase 3 — Movement Model (keep it simple first)

### Version 1 (DO THIS FIRST):

* Direct velocity mapping (like player)
* No acceleration
* No drift

### Later (upgrade path):

* Acceleration curve
* Friction
* Drift / slide

---

# 🔫 Phase 4 — Weapon Integration

Reuse your existing weapon system.

### Key idea:

Vehicles use the SAME weapon interface.

```gdscript
func fire_weapon(aim_vector):
    weapon.fire(global_position, aim_vector)
```

---

## Optional constraint:

* Vehicle fires ONLY forward:

```gdscript
var forward = transform.x
weapon.fire(global_position, forward)
```

---

# 🧩 Phase 5 — Collision + Hitbox

Vehicles should:

* Have larger collision shape
* Take damage separately from operator
* Possibly protect operator

### Minimal implementation:

```gdscript
@export var health := 100

func take_damage(amount):
    health -= amount
    if health <= 0:
        explode()
```

---

# 💥 Phase 6 — Destruction Behavior

When destroyed:

```gdscript
func explode():
    spawn_explosion_fx()

    if player_inside:
        player_controller.exit_vehicle()

    queue_free()
```

---

# 🎨 Phase 7 — Sprite + Animation (IMPORTANT for your pipeline)

You will need:

### Request from yourself (per your own workflow rules ):

```
custodian/assets/sprites/vehicles/hover_buggy/
    buggy_idle.png
    buggy_move.png
```

### Requirements:

* Same 2.5D perspective as operator
* Footprint larger than 32x64 (try ~64x64 or 96x96)
* Clear forward direction

---

# 🧠 Phase 8 — Systems Integration (where this gets interesting)

Tie into your existing systems:

### 1. Power system

* Vehicle may require sector power

### 2. Defense grid

* Vehicles could be deployable units later

### 3. Damage system

* Vehicles interact with sector damage pipeline

---

# ⚠️ Common Failure Points (avoid these)

### ❌ Mistake 1: Separate input systems

→ ALWAYS route through one controller

### ❌ Mistake 2: Physics-based movement too early

→ You will lose weeks here

### ❌ Mistake 3: Treating vehicle as UI toggle

→ It must be a real actor in the world

---

# 🚀 Phase 9 — Immediate Build Order (DO THIS EXACTLY)

1. Create `ControllableActor`
2. Refactor operator to use it
3. Create `VehicleBase`
4. Implement player controller routing
5. Add enter/exit
6. Spawn 1 test vehicle in scene
7. Bind "E" to enter/exit
8. Add simple forward weapon

---

# 🔄 Phase 10 — Next Vehicle Types (future)

Once this works:

* Tank (turning radius)
* Mech (slow + heavy + stomp)
* Drone (flying layer)
* Transport (multi-seat)

---

# ⚡ Critical Insight (this is the real design win)

This system gives you:

* Seamless operator ↔ vehicle transitions
* Future AI can control vehicles using same interface
* Deterministic simulation compatibility (huge for your design goals)

---


# START LIVE VEHICLES.md - THIS IS SOURCE OF TRUTH AND SHOULD BE HARDENED TO DESIGN

---
`
I wrote **VEHICLES.md** in the canvas.

The roadmap is aligned to the active Godot-first repo guidance, which says runtime authority is now `custodian/`, design work should be documented in `./design/` first, and simulation logic should stay separate from presentation. It also fits your current game pillars: static sectorized base defense, command-vs-field asymmetry, knowledge-over-power progression, and enemy adaptation to player doctrine.  

The main conclusions I locked in are:

* **First vehicle should be the Light Interceptor / Patrol Buggy**
* **Vehicles should enter after combat/repair/perimeter foundations are readable**
* **Vehicles should be role-based tools, not raw upgrades**
* **Each archetype needs operational burden, counterplay, access restrictions, and doctrine interaction**
* **Heavy vehicles and remote platforms should come much later**
* **The biggest hidden risks are map-scale collapse, doorway/collision misery, dismount exploits, camera failure at speed, and vehicles becoming the default answer to every problem**

I also built in:

* archetype-by-archetype breakdown
* implementation order relative to the overall game
* system dependency mapping
* counterplay requirements
* hidden production and runtime pitfalls
* non-goals for the first implementation
* data/state structure recommendations
* asset planning notes
* testing requirements
* a current-state reconciliation section

One important caveat: the project design snapshot I could inspect is older than the repo guidance. The broad design material I found was created on **February 9, 2026**, while the active repo guidance I found is from **March 30, 2026**. I do **not** currently have a dated up-to-date devlog or current gamefile snapshot in this conversation, so this roadmap is broad and consistent with project doctrine, but not yet reconciled against the latest live implementation state.  

