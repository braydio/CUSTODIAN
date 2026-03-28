# CUSTODIAN Camera System Design

> **readability → weight → immersion**

## Implementation Status

Current live status in `custodian/scenes/camera.gd`: approximately **80-85% implemented**.

Implemented in runtime:
- smooth follow with weighted lerp
- movement lookahead
- micro bob with combat suppression
- off-center framing
- combat state machine with transient state holds
- attack push and screen shake
- manual zoom and follow toggle
- runtime map bounds clamping
- sector-entry state trigger on procgen handoff
- light threat-aware framing toward nearby active enemies

Still partial or intentionally simplified:
- no dedicated `ShakeOffset` child node; shake is applied in controller space
- sector entry does not yet recenter to authored sector centers
- attack-frame sync is event-driven from combat code, not animation callback tracks
- no explicit per-room cinematic transitions beyond the current sector-entry hold

---

## 1. Core Philosophy

The CUSTODIAN camera must achieve three simultaneous goals:

1. **Readability** - Top-down tactical clarity (Into the Breach style)
2. **Weight** - Subtle cinematic motion that gives movement mass
3. **Immersion** - Reactive feedback that connects player to combat

The camera should NOT feel like a static RTS view or a chaotic action cam. It should feel like a character—a subtle, intelligent partner that anticipates your needs.

---

## 2. Target Feel Summary

| Aspect | Target |
|--------|--------|
| **Base View** | Top-down tactical |
| **Movement Feel** | Responsive with cinematic lead |
| **Combat Feel** | Punchy, reactive, synced to frames |
| **Idle Feel** | Subtle life, not sterile |
| **Bad Feel** | Snap-to-player, no lookahead, centered |

---

## 3. Base Camera Setup (Godot)

### Node Hierarchy

```
Camera2D (script: CameraController)
├── ShakeOffset (Node2D - for screen shake)
└── (child nodes as needed)
```

### Godot Properties

```gdscript
Camera2D:
  - smoothing_enabled = true
  - smoothing_speed = 8.0
  - zoom = Vector2(0.6, 0.6)
  - position = player.position
```

---

## 4. Camera Components

### 4.1 Lookahead (Most Important)

**Concept:** Camera slightly leads the player in movement direction.

**Implementation:**

```gdscript
var lookahead = player_velocity.normalized() * LOOKAHEAD_STRENGTH
# LOOKAHEAD_STRENGTH = 40.0 pixels
```

**Why it matters:**
- Shows where player is going before they arrive
- Makes movement feel responsive
- Adds subtle cinematic quality

**Tuning:**
- Too little (0-20px) → feels laggy, dead
- Sweet spot (30-50px) → responsive + cinematic
- Too much (60px+) → disorienting

---

### 4.2 Smooth Follow (Weight)

**Concept:** Don't snap to player—follow with weighted lag.

**Implementation:**

```gdscript
var target_position = player.position + offset + lookahead
camera.position = camera.position.lerp(target_position, LERP_SPEED)
# LERP_SPEED = 0.1
```

**Tuning:**
- 0.05 or less → sluggish, floaty
- 0.08-0.12 → sweet spot for weight
- 0.15+ → jittery, nervous

---

### 4.3 Micro Camera Bob (Immersion)

**Concept:** Very subtle vertical oscillation while moving.

**Implementation:**

```gdscript
if is_moving:
    var bob = sin(Time.get_ticks_msec() * 0.005) * BOB_STRENGTH
    camera.position.y += bob
    # BOB_STRENGTH = 2.0 pixels
else:
    # decay bob to zero
```

**Rules:**
- Only while player is moving
- Stop during combat windup
- Smooth decay when stopping

---

### 4.4 Player Off-Center (Subtle Power)

**Concept:** Don't center player—offset toward top of screen.

**Implementation:**

```gdscript
var base_offset = Vector2(0, -40)  # player appears lower on screen
# This shows more of what lies ahead
```

**Why:**
- Shows more of what's ahead
- Feels more cinematic
- Improves combat awareness (see enemies before they see you)

---

## 5. Combat Camera System

### 5.1 Camera States

The camera operates in distinct states:

```gdscript
enum CameraState {
    EXPLORE,       # Normal walking
    COMBAT,       # In active combat
    HEAVY_ATTACK, # Windup/heavy attack
    HITSTUN,      # Player took damage
    SECTOR_ENTRY, # Entering new sector
}
```

### 5.2 State Modifiers

Each state modifies camera behavior:

| State | Zoom | Smoothing | Bob | Offset |
|-------|------|-----------|-----|--------|
| EXPLORE | 0.6 | 0.1 | On | -40px Y |
| COMBAT | 0.58 | 0.12 | Off | -30px Y |
| HEAVY_ATTACK | 0.55 | 0.08 | Off | -20px Y |
| HITSTUN | 0.65 | 0.15 | Off | -50px Y |
| SECTOR_ENTRY | 0.65 | 0.08 | Off | -40px Y |

---

### 5.3 Attack Reactions

**Fast Attack (Light):**

```gdscript
camera.position += attack_direction * 10
# Duration: instant, decay over 0.1s
```

**Heavy Attack:**

```gdscript
camera.position += attack_direction * 20
camera.zoom = Vector2(0.55, 0.55)  # slight zoom in
# Zoom recovery: lerp back over 0.3s
```

**Attack Windup:**
- Camera tightens slightly
- Stops micro bob
- Increases smoothing (0.08)

---

### 5.4 Impact Reactions

**On Player Hit:**

```gdscript
shake(intensity=5, duration=0.15)
camera.position += hit_direction * 15
```

**On Enemy Kill:**

```gdscript
shake(intensity=2, duration=0.08)  # lighter
# Optional: slight zoom out then back
```

---

### 5.5 Screen Shake System

**Implementation:**

```gdscript
var shake_offset = Vector2.ZERO
var shake_intensity = 0.0
var shake_decay = 5.0  # per second

func shake(intensity, duration):
    shake_intensity = intensity
    shake_duration = duration

func _process(delta):
    if shake_intensity > 0:
        shake_offset = Vector2(
            randf_range(-shake_intensity, shake_intensity),
            randf_range(-shake_intensity, shake_intensity)
        )
        shake_intensity = lerp(shake_intensity, 0.0, shake_decay * delta)
```

**Shake Intensity Rules:**

| Event | Intensity | Duration |
|-------|------------|----------|
| Light attack hit | 2px | 0.08s |
| Heavy attack hit | 5px | 0.15s |
| Player damaged | 6px | 0.2s |
| Enemy death | 3px | 0.1s |
| Explosions | 8px | 0.25s |

---

## 6. Sector/Room Framing

### 6.1 Sector Entry

When entering a new sector:

```gdscript
# Zoom out slightly
target_zoom = Vector2(0.65, 0.65)

# Camera recenters on sector center
var sector_center = get_current_sector_center()
# Smooth transition over 0.5s
```

### 6.2 Combat in Sector

When combat starts:

```gdscript
# Zoom back in
target_zoom = Vector2(0.6, 0.6)
```

### 6.3 Multi-Enemy Awareness

If multiple enemies detected:

```gdscript
# Calculate centroid of all threats
var threat_center = calculate_threat_centroid()
# Shift camera slightly toward threats
# This shows incoming danger
```

---

## 7. Zoom System

### 7.1 Base Zoom Levels

| Mode | Zoom | Use Case |
|------|------|----------|
| TACTICAL | 0.7 | Large-scale exploration |
| COMBAT | 0.6 | Normal gameplay |
| HEAVY | 0.55 | Intense combat |
| FOCUS | 0.5 | Zoomed view |

### 7.2 Zoom Transitions

```gdscript
func set_target_zoom(new_zoom: Vector2, duration: float = 0.3):
    zoom_target = new_zoom
    zoom_tween = create_tween()
    zoom_tween.tween_property(self, "zoom", new_zoom, duration)
```

---

## 8. Input Integration

### 8.1 Camera Controls

| Input | Action |
|-------|--------|
| Mouse Wheel | Manual zoom |
| C | Toggle follow mode |
| Middle Mouse | Pan (optional) |

### 8.2 Follow Toggle

```gdscript
func toggle_follow():
    follow_enabled = !follow_enabled
    if follow_enabled:
        # Return to player with smoothing
    else:
        # Stay at current position
```

---

## 9. Integration with Combat System

### 9.1 Frame-Perfect Sync

The camera MUST sync with attack frames:

```gdscript
# In attack animation callback
func _on_attack_frame(frame: int):
    match frame:
        2:  # Windup complete
            camera.set_state(CameraState.COMBAT)
            camera.start_bob_decay()
        4:  # Impact frame
            camera.apply_shake(3, 0.1)
            camera.push_forward(attack_direction * 15)
```

### 9.2 State Transitions

| Combat Phase | Camera Transition |
|--------------|-------------------|
| Idle → Windup | Smooth zoom in, stop bob, tighter lerp |
| Windup → Attack | Push forward, light shake |
| Attack → Recovery | Gentle return to neutral |
| Recovery → Idle | Resume bob, normal zoom |

---

## 10. Implementation Checklist

### Phase 1: Base Camera (Priority: Critical)
- [x] Set up Camera2D with smoothing
- [x] Implement smooth follow with lerp
- [x] Add lookahead based on velocity
- [x] Test movement feel

### Phase 2: Micro Feel (Priority: High)
- [x] Add micro bob while moving
- [x] Add player offset (off-center)
- [x] Tune lerp speed (0.08-0.12)

### Phase 3: Combat Integration (Priority: High)
- [x] Create camera states enum
- [x] Add attack reaction (push forward)
- [x] Add screen shake system
- [x] Sync with attack frames

### Phase 4: Polish (Priority: Medium)
- [~] Sector entry/exit transitions
- [x] Manual zoom controls
- [x] Follow toggle
- [~] Tune all values

---

## 11. Tuning Values (Starting Point)

```gdscript
# Base Settings
const BASE_ZOOM = Vector2(0.6, 0.6)
const LOOKAHEAD_STRENGTH = 40.0  # pixels
const LERP_SPEED = 0.1
const BOB_STRENGTH = 2.0
const BOB_FREQUENCY = 0.005

# Off-center offset
const PLAYER_OFFSET = Vector2(0, -40)

# Combat
const ATTACK_PUSH_LIGHT = 10.0
const ATTACK_PUSH_HEAVY = 20.0
const SHAKE_DECAY = 5.0
```

---

## 12. Common Mistakes to Avoid

| ❌ Wrong | ✅ Right |
|----------|----------|
| Perfectly centered player | Off-center (shows ahead) |
| No lookahead | 30-50px lead |
| Too much shake (8px+) | Max 6px, quick decay |
| Instant snapping | Smooth lerp |
| Too zoomed out (0.8+) | 0.55-0.65 range |
| No combat state changes | Reactive to attacks |

---

## 13. What Makes It Feel "AAA"

Not big effects. This:

- Camera reacts **1 frame after input**
- Subtle forward push on attacks
- Slight zoom compression during heavy hits
- Smooth return to neutral
- Micro bob while walking stops in combat

---

## Next Steps

1. **Create CameraController.gd** - Drop-in script with all features
2. **Wire to combat system** - Connect attack states to camera states
3. **Test and tune** - Adjust values for feel

The goal: **feels insanely good to play** — not "nice camera," but "can't play without it."
