# Camera-Combat Integration Design

> **Purpose:** Wire frame-perfect camera reactions into CUSTODIAN's combat system for AAA feel

---

## Current State

### What's Working
- Camera has basic shake method (`shake(power)`)
- Operator calls `_trigger_camera_shake()` on hit confirmation
- Separate hitstop applied via `_apply_hit_stop()`

### What's Missing
- No camera state transitions on attack windup/impact
- No frame-aware reactions (same shake regardless of which frame hit)
- No sync between hitstop duration and camera intensity
- No push/zoom effects on attacks (uses simple offset only)

---

## Design Goals

1. **Frame-aware reactions** — Camera reacts differently on frame 4 vs frame 7
2. **State transitions** — Camera enters COMBAT/HEAVY_ATTACK states
3. **Hitstop sync** — Shake intensity matches hitstop duration
4. **Push on impact** — Forward push on attacks (not just shake)
5. **Zoom compression** — Heavy attacks slightly zoom in

---

## Code Changes Required

### 1. Update Operator — Replace `_trigger_camera_shake()`

**File:** `custodian/entities/operator/operator.gd`

**Current (lines ~1019-1023):**
```gdscript
func _trigger_camera_shake() -> void:
    var camera = _get_world_camera()
    if camera and camera.has_method("shake"):
        var power := melee_fast_camera_shake_power if _melee_attack_kind == "fast" else melee_heavy_camera_shake_power
        camera.call("shake", power if power > 0.0 else melee_camera_shake_power)
```

**Replace with:**
```gdscript
func _trigger_camera_reaction() -> void:
    var camera = _get_world_camera()
    if not camera:
        return
    
    var is_heavy = _melee_attack_kind == "heavy"
    var current_frame = animated_sprite.frame if animated_sprite else 0
    
    # Notify windup state (camera adjusts smoothing/zoom)
    if camera.has_method("on_attack_windup"):
        camera.on_attack_windup(is_heavy)
    
    # Get frame-aware intensity
    var hit_data = _get_hit_frame_data(current_frame, is_heavy)
    
    # Apply frame-aware impact (push + shake + optional zoom)
    if camera.has_method("on_attack_impact"):
        camera.on_attack_impact(_melee_forward, is_heavy, hit_data.shake_power)
    
    # Apply synchronized hitstop
    _apply_hit_stop_with_camera_sync(hit_data.hitstop_frames)


func _get_hit_frame_data(frame: int, is_heavy: bool) -> Dictionary:
    # Frame-aware reaction values from ATTACK_HIT_TIMING.md
    
    # Fast attack frames: 2, 3, 4, 7, 8
    # Heavy attack frames: 3, 4, 6, 7
    
    if is_heavy:
        match frame:
            3: return {"shake_power": 4.0, "hitstop_frames": 5, "push_strength": 25.0}
            4: return {"shake_power": 4.5, "hitstop_frames": 6, "push_strength": 28.0}
            6: return {"shake_power": 5.0, "hitstop_frames": 7, "push_strength": 30.0}
            7: return {"shake_power": 6.0, "hitstop_frames": 8, "push_strength": 35.0}
            _: return {"shake_power": 3.0, "hitstop_frames": 4, "push_strength": 20.0}
    else:
        match frame:
            2: return {"shake_power": 1.5, "hitstop_frames": 2, "push_strength": 8.0}
            3: return {"shake_power": 2.0, "hitstop_frames": 3, "push_strength": 12.0}
            4: return {"shake_power": 2.5, "hitstop_frames": 4, "push_strength": 15.0}  # Main hit
            7: return {"shake_power": 2.0, "hitstop_frames": 3, "push_strength": 12.0}
            8: return {"shake_power": 1.5, "hitstop_frames": 2, "push_strength": 8.0}
            _: return {"shake_power": 1.0, "hitstop_frames": 2, "push_strength": 5.0}


func _apply_hit_stop_with_camera_sync(hitstop_frames: int) -> void:
    # Original hitstop
    _apply_hit_stop()
    
    # Sync camera intensity with hitstop
    var camera = _get_world_camera()
    if camera and camera.has_method("set_hitstop_intensity"):
        camera.set_hitstop_intensity(hitstop_frames)
```

---

### 2. Add Hitstop Sync to CameraController

**File:** `custodian/scenes/camera.gd`

**Add to class:**
```gdscript
# Hitstop sync
var hitstop_intensity: float = 0.0
var hitstop_shake_boost: float = 0.0

func set_hitstop_intensity(frames: float) -> void:
    hitstop_intensity = frames
    hitstop_shake_boost = frames * 0.5  # More hitstop = more shake


func _update_shake(delta: float):
    # Apply hitstop boost
    var effective_power = _shake_power + hitstop_shake_boost
    
    if effective_power <= 0.0:
        _shake_offset = Vector2.ZERO
        return
    
    _shake_offset = Vector2(
        randf_range(-effective_power, effective_power),
        randf_range(-effective_power, effective_power)
    )
    
    # Decay both
    _shake_power = max(0.0, _shake_power - shake_decay_speed * delta)
    hitstop_shake_boost = max(0.0, hitstop_shake_boost - shake_decay_speed * delta)
    hitstop_intensity = max(0.0, hitstop_intensity - delta * 2.0)
```

---

### 3. Update `on_attack_impact` in CameraController

**File:** `custodian/scenes/camera.gd`

**Current:**
```gdscript
func on_attack_impact(direction: Vector2, is_heavy: bool = false):
    apply_attack_push(direction, is_heavy)
    apply_shake(3.0 if is_heavy else 1.5)
```

**Replace with:**
```gdscript
func on_attack_impact(direction: Vector2, is_heavy: bool = false, shake_power: float = -1.0):
    # Use provided shake_power if passed, otherwise use defaults
    var actual_shake = shake_power if shake_power >= 0.0 else (3.0 if is_heavy else 1.5)
    
    # Push forward in attack direction
    var push_strength = attack_push_heavy if is_heavy else attack_push_light
    _push_offset += direction.normalized() * push_strength
    
    # Apply shake with frame-aware intensity
    apply_shake(actual_shake)
    
    # Heavy attacks: slight zoom compression
    if is_heavy:
        var target = zoom
        zoom = zoom.lerp(heavy_zoom, 0.3)
        # Auto-recover after short delay
        await get_tree().create_timer(0.25).timeout
        zoom = zoom.lerp(target_zoom, 0.2)
```

---

### 4. Enhance Attack State Machine in CameraController

**File:** `custodian/scenes/camera.gd`

**Current state handling:**
```gdscript
func set_state(new_state: CameraState):
    if current_state == new_state:
        return
    current_state = new_state
    
    match new_state:
        CameraState.COMBAT:
            target_zoom = Vector2(0.58, 0.58)
            follow_lerp_speed = 10.0
```

**Enhance with smooth transitions:**
```gdscript
func set_state(new_state: CameraState):
    if current_state == new_state:
        return
    
    var old_state = current_state
    current_state = new_state
    
    # Handle state transitions
    match new_state:
        CameraState.EXPLORE:
            target_zoom = base_zoom
            follow_lerp_speed = 8.0
            player_offset = Vector2(0, -40)
            _current_bob = 0.0  # Reset bob
        
        CameraState.COMBAT:
            # Tighten zoom, faster follow, reduce offset
            target_zoom = Vector2(0.58, 0.58)
            follow_lerp_speed = 10.0
            player_offset = Vector2(0, -30)
            _current_bob = 0.0  # Stop bob in combat
        
        CameraState.HEAVY_ATTACK:
            # Heavy zoom, slower follow (weight), minimal offset
            target_zoom = heavy_zoom
            follow_lerp_speed = 6.0
            player_offset = Vector2(0, -20)
            _current_bob = 0.0
        
        CameraState.HITSTUN:
            # Zoom out for awareness, fast follow
            target_zoom = Vector2(0.65, 0.65)
            follow_lerp_speed = 12.0
            player_offset = Vector2(0, -50)
            _current_bob = 0.0
        
        CameraState.IDLE:
            target_zoom = base_zoom
            follow_lerp_speed = 6.0
            player_offset = Vector2(0, -40)
    
    # Print state for debugging
    print("[Camera] State: ", CameraState.keys()[new_state])
```

---

### 5. Add Weapon Definition Hit Windows Integration

**File:** `custodian/entities/operator/operator.gd`

**Currently:** Weapon definitions have `hit_windows` but camera doesn't use frame data.

**Add integration:**
```gdscript
func _get_camera_reaction_from_weapon() -> Dictionary:
    var weapon_def = _get_equipped_primary_weapon_definition()
    if weapon_def and weapon_def.camera_reaction is Dictionary:
        return weapon_def.camera_reaction
    
    # Fallback to class defaults
    return {
        "fast": {"shake": 2.0, "hitstop": 3, "push": 10.0},
        "heavy": {"shake": 5.0, "hitstop": 6, "push": 25.0}
    }
```

---

## Complete Flow After Changes

```
Player presses attack
    ↓
Animation plays (frames 1-10)
    ↓
_on_attack_frame_changed() called every frame
    ↓
_is_melee_hit_frame_active() checks weapon hit_windows
    ↓ (on hit frame)
_on_melee_hit_confirmed()
    ↓
_trigger_camera_reaction()  ← NEW: replaces _trigger_camera_shake()
    ↓
_get_hit_frame_data(frame, is_heavy)  ← Frame-aware values
    ↓
_notify_camera_attack_impact(direction, is_heavy, shake_power)
    ↓
CameraController.on_attack_impact()  ← Push + shake + zoom
    ↓
_apply_hit_stop_with_camera_sync()  ← Hitstop + camera sync
    ↓
Result: Punchy, synced combat feel
```

---

## Values Reference Table

### Fast Attack (per frame)

| Frame | Shake | Hitstop | Push | Notes |
|-------|-------|---------|------|-------|
| 2 | 1.5px | 2 frames | 8px | Early hit |
| 3 | 2.0px | 3 frames | 12px | |
| **4** | **2.5px** | **4 frames** | **15px** | **Main hit** |
| 7 | 2.0px | 3 frames | 12px | Secondary |
| 8 | 1.5px | 2 frames | 8px | Late |

### Heavy Attack (per frame)

| Frame | Shake | Hitstop | Push | Notes |
|-------|-------|---------|------|-------|
| 3 | 4.0px | 5 frames | 25px | Windup release |
| 4 | 4.5px | 6 frames | 28px | |
| 6 | 5.0px | 7 frames | 30px | |
| **7** | **6.0px** | **8 frames** | **35px** | **Main hit** |

---

## Testing Checklist

- [ ] Fast attack frame 4 has stronger feel than frame 8
- [ ] Heavy attack feels weightier than fast
- [ ] Hitstop duration matches shake intensity
- [ ] Camera pushes forward on attack direction
- [ ] Heavy attacks slightly zoom in then recover
- [ ] Camera transitions smoothly between states
- [ ] Bob stops during combat
- [ ] Player damage causes appropriate reaction (HITSTUN state)

---

## Implementation Order

1. **Step 1:** Update CameraController `on_attack_impact` signature
2. **Step 2:** Add hitstop sync to CameraController
3. **Step 3:** Enhance state machine in CameraController
4. **Step 4:** Replace operator's `_trigger_camera_shake()` with new method
5. **Step 5:** Add frame data lookup
6. **Step 6:** Add hitstop sync call
7. **Step 7:** Test and tune values

---

## Related Files

| File | Changes |
|------|---------|
| `custodian/scenes/camera.gd` | Add hitstop sync, enhance `on_attack_impact`, state machine |
| `custodian/entities/operator/operator.gd` | Replace `_trigger_camera_shake()`, add frame data |
| `design/CAMERA_SYSTEM.md` | Already complete |
| `design/ATTACK_HIT_TIMING.md` | Already complete |

---

## Next Step

After implementing these changes, the combat will feel significantly punchier with:
- Frame-accurate camera reactions
- Synced hitstop + shake
- Heavy attacks feeling heavier
- Smooth camera state transitions

This is what separates "nice camera" from "feels insanely good to play."