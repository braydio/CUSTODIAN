# Operator Animation State Machine Implementation Plan

**Project:** CUSTODIAN  
**Last Updated:** 2026-03-19  
**Purpose:** Map state transitions and document missing animation states for implementation

---

## Current State Analysis

### Existing State Machine Structure

The animation state machine is defined at:
- **State machine:** `custodian/entities/operator/animations/animation_state_machine.gd`
- **Base state:** `custodian/entities/operator/animations/states/animation_state.gd`
- **States:** `custodian/entities/operator/animations/states/`

### Current Integration State

The state machine is now connected to the live operator attack + locomotion request path, but body animation playback is still rendered by `operator.gd` rather than fully delegated to state-owned visual handlers.

Holstered movement currently gets a small locomotion bonus so the operator feels lighter when fully unarmed.
Committed melee attack swings and heavy windup currently lock locomotion so attacks read as planted actions rather than sliding strikes.

```gdscript
func _update_animation():
    # Still resolves directional body clips here
    # while the state machine owns logical state requests
```

The remaining migration work is about moving more of the visual playback policy behind state-aware helpers, not about first-time hookup.

---

## State Transition Map

### Current States (Working)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           OPERATOR STATE MACHINE                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────┐     input      ┌───────┐     input      ┌──────────┐              │
│  │ IDLE │ ──────────────►│  WALK │ ──────────────►│  SPRINT │              │
│  │      │ ◄──────────────│       │ ◄──────────────│          │              │
│  └──┬───┘   no movement  └───┬───┘    CTRL held   └──────────┘              │
│     │                       │                                               │
│     │ attack                │ attack                                        │
│     ▼                       ▼                                               │
│  ┌──────────┐            ┌──────────┐                                      │
│  │ATTACK_FAST│◄──────────►│ATTACK_HEAVY│  (combo chain)                    │
│  └────┬─────┘            └─────┬─────┘                                      │
│       │                        │                                            │
│       │ animation end          │ animation end                               │
│       └────────┬───────────────┘                                            │
│                ▼                                                            │
│       ┌─────────────┐                                                        │
│       │   STAGGER   │ (on hit)                                              │
│       └──────┬──────┘                                                        │
│              │ animation end                                                │
│              ▼                                                              │
│       ┌──────────┐                                                          │
│       │  DEATH   │ (health <= 0)                                            │
│       └──────────┘                                                          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Current Transitions (as implemented in operator.gd)

| From State | To State | Trigger | Priority |
|------------|----------|---------|----------|
| idle | walk | movement input | 0 |
| idle | sprint | CTRL + movement | 1 |
| idle | attack_fast | LMB melee | 10 |
| idle | attack_heavy | Shift+LMB | 10 |
| idle | stagger | damage taken | 25 |
| idle | death | health <= 0 | 100 |
| walk | idle | no movement | 0 |
| walk | sprint | CTRL + movement | 1 |
| walk | attack_fast | LMB melee | 10 |
| walk | attack_heavy | Shift+LMB | 10 |
| walk | stagger | damage taken | 25 |
| sprint | walk | CTRL released | 1 |
| sprint | stagger | damage taken | 25 |
| attack_fast | idle | animation complete | - |
| attack_fast | attack_fast | buffer (combo) | 15 |
| attack_fast | attack_heavy | buffer (upgrade) | 15 |
| attack_heavy | idle | animation complete | - |
| attack_dash | idle | animation complete | - |
| stagger | idle | animation complete | - |
| death | (terminal) | N/A | - |

### Interrupt Priority System

From `animation_state.gd:7-8`:
```gdscript
var can_interrupt: bool = true
var interrupt_priority: int = 0
```

| State | Can Interrupt | Priority | Meaning |
|-------|--------------|----------|---------|
| idle | yes | 0 | Can be interrupted by anything priority 0+ |
| walk | yes | 1 | Can be interrupted by priority 1+ |
| sprint | yes | 1 | Can be interrupted by priority 1+ |
| attack_fast | **no** | 10 | Cannot interrupt during attack |
| attack_heavy | **no** | 10 | Cannot interrupt during attack |
| attack_dash | **no** | 15 | Highest combat priority |
| stagger | **no** | 25 | Very high - reactions override |
| death | **no** | 100 | Terminal state |
| **NEW: block** | no | 8 | Block interrupts attacks |
| **NEW: reload** | no | 7 | Reload interrupts fire |
| **NEW: interact** | yes | 2 | Can be interrupted by movement |
| **NEW: pickup** | yes | 2 | Can be interrupted |
| **NEW: repair** | no | 6 | Repairs lock movement |

---

## Missing States

### HIGH PRIORITY

#### 1. BLOCK State

**File:** `block_state.gd` (implemented)

**Purpose:** Melee-loadout guard with stamina-on-hit mitigation

**Triggers:**
- Input: `block` action held
- From: idle, walk, sprint, or melee attack

**Live behavior:**
- Plays `melee_2h_block_enter` → `melee_2h_block_hold` → `melee_2h_block_exit`
- Uses the authored katana row as a separate synced weapon overlay during block
- Locks locomotion while any block phase is active
- Disables melee/ranged attack input while block is active
- Spends stamina on successful blocked hits
- If stamina is insufficient, the hit goes through and block drops into exit

**Runtime files:**
- `custodian/entities/operator/animations/states/block_state.gd`
- `custodian/assets/sprites/operator/runtime/body/melee_2h/operator_body_melee_2h_block_enter.png`
- `custodian/assets/sprites/operator/runtime/body/melee_2h/operator_body_melee_2h_block_hold.png`
- `custodian/assets/sprites/operator/runtime/body/melee_2h/operator_body_melee_2h_block_exit.png`
- `custodian/assets/sprites/weapons/fallen_star_katana/animations/fallen_star_katana__melee_2h__block_enter_weapon.png`
- `custodian/assets/sprites/weapons/fallen_star_katana/animations/fallen_star_katana__melee_2h__block_hold_weapon.png`
- `custodian/assets/sprites/weapons/fallen_star_katana/animations/fallen_star_katana__melee_2h__block_exit_weapon.png`

---

#### 2. RELOAD State

**File:** `reload_state.gd` (create)

**Purpose:** Reload ranged weapon

> ⚠️ **From GAMEPLAY_NOTES.md (Run 001):** "Need to have the custodian movement speed slowed when reloading"

**Triggers:**
- Input: `reload` action pressed
- From: idle, walk, sprint, `ranged_2h_fire` (firing)
- Condition: has ranged weapon equipped, not full ammo

**Behavior:**
- Play reload animation
- Reset ammo count
- Lock locomotion while reloading
- Exit on: animation complete

```gdscript
# reload_state.gd
extends AnimationState

var reload_complete: bool = false

func _init(state_name: String = "reload"):
    name = state_name
    can_interrupt = false
    interrupt_priority = 7

func enter() -> void:
    reload_complete = false
    if state_machine and state_machine.sprite:
        if state_machine.sprite.sprite_frames.has_animation("reload"):
            state_machine.sprite.play("reload")
        else:
            # Fallback - short animation
            state_machine.sprite.play("reload_fallback")

func on_animation_event(event_name: String, event_type: String) -> void:
    match event_name:
        "reload_complete":
            reload_complete = true

func update(delta: float) -> String:
    # Check if animation finished
    if state_machine and state_machine.sprite:
        if not state_machine.sprite.is_playing():
            return "idle"
    return name
```

**Required animation:** `reload` (one-shot)

**Integration with operator.gd:**
```gdscript
# Add to operator.gd _handle_weapon_switch()
func _handle_reload_input():
    if Input.is_action_just_pressed("reload"):
        if _is_ranged_loadout_active() and not _has_full_ammo():
            _start_reload()
```

---

#### 3. INTERACT State

**File:** `interact_state.gd` (create)

**Purpose:** Interact with world objects (terminals, sectors, doors)

**Triggers:**
- Input: `interact` action pressed
- From: idle, walk
- Condition: near interactable object

**Behavior:**
- Play interact animation (short)
- Trigger interaction callback
- Exit on: animation complete

```gdscript
# interact_state.gd
extends AnimationState

var interaction_complete: bool = false

func _init(state_name: String = "interact"):
    name = state_name
    can_interrupt = true
    interrupt_priority = 2  # Can be interrupted by movement

func enter() -> void:
    interaction_complete = false
    if state_machine and state_machine.sprite:
        if state_machine.sprite.sprite_frames.has_animation("interact"):
            state_machine.sprite.play("interact")
        else:
            # Quick gesture fallback
            state_machine.sprite.play("interact_quick")

func on_animation_event(event_name: String, event_type: String) -> void:
    match event_name:
        "interaction_complete":
            interaction_complete = true
            # Trigger the actual interaction
            state_machine.trigger_event("do_interaction", "default")

func update(delta: float) -> String:
    # Exit if interaction triggered
    if interaction_complete:
        return "idle"
    
    # Check if animation finished
    if state_machine and state_machine.sprite:
        if not state_machine.sprite.is_playing():
            return "idle"
    return name
```

**Required animation:** `interact` (one-shot, ~0.5s)

---

### MEDIUM PRIORITY

#### 4. PICKUP/COLLECT State

**File:** `pickup_state.gd` (create)

**Purpose:** Pick up items (ammo, materials, health)

**Triggers:**
- Auto-trigger when entering item pickup radius
- From: idle, walk

**Behavior:**
- Play pickup animation
- Trigger item collection
- Show floating text

```gdscript
# pickup_state.gd
extends AnimationState

var pickup_complete: bool = false

func _init(state_name: String = "pickup"):
    name = state_name
    can_interrupt = true
    interrupt_priority = 2

func enter() -> void:
    pickup_complete = false
    if state_machine and state_machine.sprite:
        state_machine.sprite.play("pickup")

func on_animation_event(event_name: String, event_type: String) -> void:
    match event_name:
        "pickup_complete":
            pickup_complete = true
            state_machine.trigger_event("collect_item", event_type)

func update(delta: float) -> String:
    if pickup_complete:
        return "idle"
    if state_machine and state_machine.sprite:
        if not state_machine.sprite.is_playing():
            return "idle"
    return name
```

**Required animation:** `pickup` (one-shot)

---

#### 5. REPAIR State

**File:** `repair_state.gd` (create)

**Purpose:** Repair structures with H key

**Triggers:**
- Input: `repair` action held
- From: idle, walk (near structure)
- Condition: repair target in range

**Behavior:**
- Play repair animation (looping)
- Apply repair to target
- Exit on: repair released or target destroyed

```gdscript
# repair_state.gd
extends AnimationState

var repair_target: Node = null

func _init(state_name: String = "repair"):
    name = state_name
    can_interrupt = false
    interrupt_priority = 6

func enter() -> void:
    # Find repair target
    repair_target = _find_repair_target()
    if state_machine and state_machine.sprite:
        state_machine.sprite.play("repair")

func _find_repair_target() -> Node:
    # Implementation: find nearest damaged structure
    pass

func update(delta: float) -> String:
    # Check if repair input released
    if not Input.is_action_pressed("repair"):
        return "idle"
    
    # Check if target still valid
    if repair_target == null or not is_instance_valid(repair_target):
        return "idle"
    
    # Continue repair
    if repair_target.has_method("repair"):
        repair_target.call("repair", delta * repair_rate)
    
    return name
```

**Required animation:** `repair` (looping)

---

#### 6. CROUCH State

**File:** `crouch_state.gd` (create)

**Purpose:** Tactical crouch movement (optional)

**Triggers:**
- Input: `crouch` key held (e.g., C key)
- From: idle, walk

**Behavior:**
- Play crouch animation
- Reduce movement speed
- Exit on: crouch key released

```gdscript
# crouch_state.gd
extends AnimationState

func _init(state_name: String = "crouch"):
    name = state_name
    can_interrupt = true
    interrupt_priority = 1

func enter() -> void:
    if state_machine and state_machine.sprite:
        state_machine.sprite.play("crouch")

func update(delta: float) -> String:
    # Check if crouch released
    if not Input.is_key_pressed(KEY_C):
        return "idle"
    
    # Still allow movement in crouch
    return name
```

**Required animation:** `crouch` (looping)

---

### LOW PRIORITY

#### 7. VICTORY State

**File:** `victory_state.gd` (create)

**Purpose:** Post-assault celebration

**Triggers:**
- Event: waves completed, mission success
- From: idle

**Behavior:**
- Play victory animation
- Exit on: animation complete

---

#### 8. TAUNT/EMOTE States

**File:** `emote_state.gd` (create)

**Purpose:** Character expression

**Triggers:**
- Input: quick key combo
- From: idle (only)

---

## Complete State Transition Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        COMPLETE STATE MACHINE                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                              ┌──────┐                                       │
│                         ┌────│ IDLE │────┐                                 │
│                         │    └──┬───┘    │                                 │
│    ┌────────────────────┼────────┼────────┼────────────────────┐          │
│    │                    │        │        │                    │          │
│    ▼                    ▼        ▼        ▼                    ▼          │
│ ┌───────┐          ┌───────┐ ┌───────┐ ┌────────┐          ┌────────┐      │
│ │ PICKUP │          │  WALK │ │INTERACT│ │ SPRINT │          │  CROUCH│      │
│ └────┬──┘          └───┬───┘ └───┬───┘ └───┬────┘          └───┬────┘      │
│      │                 │        │        │                   │            │
│      │ movement       │ attack │ anim   │ CTRL held         │ C held    │
│      │ released       │        │ done   │                   │            │
│      ▼                 ▼        ▼        ▼                   ▼            │
│    (idle)         ┌────────────────────────────────────────────┐         │
│                   │              ATTACK_FAST                   │         │
│                   │                   │                        │         │
│                   │    ┌──────────────┼──────────────┐         │         │
│                   │    │              │              │         │         │
│                   │    ▼              ▼              ▼         │         │
│                   │ ┌────────┐ ┌──────────┐ ┌──────────┐      │         │
│                   │ │COMBO_2 │ │COMBO_3   │ │(buffer)  │      │         │
│                   │ └────┬───┘ └────┬─────┘ └────┬─────┘      │         │
│                   │      │         │            │            │         │
│                   │      │         │            │            │         │
│                   │      └─────────┴────────────┘            │         │
│                   │                   │                      │         │
│                   │                   ▼                      │         │
│                   │            ┌──────────┐                  │         │
│                   │            │ATTACK_HEAVY│                 │         │
│                   │            └─────┬─────┘                  │         │
│                   │                  │                       │         │
│                   └──────────────────┼───────────────────────┘         │
│                                      │                                   │
│   ┌──────────────────────────────────┼─────────────────────────────┐   │
│   │                                  │                             │   │
│   ▼                                  ▼                             ▼   │
│ ┌─────────┐                   ┌──────────┐                   ┌─────────┐ │
│ │  RELOAD │                   │  BLOCK  │                   │  REPAIR │ │
│ └────┬────┘                   └────┬────┘                   └────┬────┘ │
│      │                            │                            │       │
│      │ anim complete              │ block released            │ H held│
│      ▼                            ▼                            ▼       │
│    (prev)                    (prev state)                  (prev)    │
│                                                                             │
│   ┌────────────────────┐                                                      │
│   │                    │                                                      │
│   ▼                    ▼                                                      │
│ ┌──────────┐     ┌──────────┐                                                  │
│ │  STAGGER │────►│   DEATH  │                                                  │
│ └──────────┘     └──────────┘ (terminal)                                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Implementation Order

### Phase 1: Critical (Week 1)

| Task | File | Dependencies |
|------|------|--------------|
| 1.1 Wire state machine to operator | Modify `operator.gd` | Existing states |
| 1.2 Create block state | `block_state.gd` | Animation: block |
| 1.3 Create reload state | `reload_state.gd` | Animation: reload |
| 1.4 Create interact state | `interact_state.gd` | Animation: interact |

### Phase 2: Gameplay (Week 2)

| Task | File | Dependencies |
|------|------|--------------|
| 2.1 Create pickup state | `pickup_state.gd` | Phase 1 |
| 2.2 Create repair state | `repair_state.gd` | Phase 1 |
| 2.3 Add crouch state | `crouch_state.gd` | None |

### Phase 3: Polish (Week 3+)

| Task | File | Dependencies |
|------|------|--------------|
| 3.1 Victory state | `victory_state.gd` | Phase 2 |
| 3.2 Emote states | Various | Phase 2 |
| 3.3 State transition polish | All states | All above |

---

## Animation Requirements

### Animations to Create (per direction)

| Animation | Loops? | Frames | Directional? | Purpose |
|-----------|--------|--------|--------------|---------|
| idle_* | yes | 4-10 | 8 dirs | Base state |
| walk_* | yes | 6-8 | 8 dirs | Movement |
| run_* / sprint_* | yes | 8-12 | 8 dirs | Sprint |
| attack_fast_* | no | 4-6 | 4 dirs | Fast melee |
| attack_heavy_* | no | 6-8 | 4 dirs | Heavy melee |
| attack_dash_* | no | 8-12 | 4 dirs | Dash attack |
| **block** | yes | 2-4 | yes | Blocking |
| **reload** | no | 8-15 | 4 dirs | Ranged reload |
| **interact** | no | 3-6 | 4 dirs | World interaction |
| **pickup** | no | 4-8 | 4 dirs | Item collection |
| **repair** | yes | 2-4 | 4 dirs | Structure repair |
| **crouch** | yes | 2-4 | 4 dirs | Tactical crouch |
| stagger | no | 4-8 | 4 dirs | Hit reaction |
| death | no | 8-12 | 4 dirs | Death |
| **victory** | no | 10-20 | 4 dirs | Mission success |

### Sprite Sheet Guidelines

- **Resolution:** 100x100 or 128x128 per frame
- **Directions:** 8 (N, NE, E, SE, S, SW, W, NW) for movement; 4 for combat
- **Style:** Consistent with existing Tiny RPG placeholder style
- **Animation speed:** 7-12 FPS for movement, 10-15 FPS for combat

---

## Integration Checklist

### Step 1: Connect State Machine

In `operator.gd`, replace direct sprite manipulation with state machine:

```gdscript
# Current (line 286-363):
func _update_animation():
    if is_moving:
        animated_sprite.play("walk_right")
    else:
        animated_sprite.play("idle_right")

# Should be:
@onready var anim_state_machine: AnimationStateMachine = $AnimationStateMachine

func _update_animation():
    # Pass input to state machine
    var input_state := _collect_input_state()
    # State machine handles all transitions
```

### Step 2: Create Input Collector

```gdscript
func _collect_input_state() -> Dictionary:
    return {
        "moving": velocity.length() > 0,
        "sprinting": is_sprinting,
        "attacking": Input.is_action_pressed("attack"),
        "blocking": Input.is_action_pressed("block"),
        "interacting": Input.is_action_just_pressed("interact"),
        "reloading": Input.is_action_just_pressed("reload"),
    }
```

### Step 3: Update States to Use Input

Each state file needs to read from the input state to determine transitions.

---

## Open Questions

1. **State machine vs direct control:** Should we fully adopt the state machine, or keep direct control for simplicity?
2. **Animation asset source:** Use placeholder sprites (Tiny RPG) or create custom?
3. **Direction handling:** 8 directions for all states, or 4 for combat?
4. **Event-driven vs polling:** States check Input.is_action_* each frame, or receive events?

---

## Reference Files

| File | Purpose |
|------|---------|
| `custodian/entities/operator/operator.gd` | Main operator, currently drives animation directly |
| `custodian/entities/operator/animations/animation_state_machine.gd` | State machine backbone |
| `custodian/entities/operator/animations/states/animation_state.gd` | Base state class |
| `custodian/entities/operator/animations/states/idle_state.gd` | Example state implementation |
| `design/20_features/in_progress/8BIT_SPRITE_INTEGRATION.md` | Sprite system documentation |

---

*This document maps the complete state machine for implementation. Update as states are created.*
