# Crosshair System Design

## Overview

Implement a visual crosshair that follows the player's aim direction when using arrow key (joystick) aiming. Shows where the player will fire.

---

## Current State

- Arrow key aiming exists (`arrow_aim_enabled` toggle)
- Basic crosshair Label exists in UI (but hidden)
- Aim direction calculated in operator via `_get_keyboard_aim_direction()`
- UI shows crosshair as hidden always

---

## Implementation Plan

### 1. Create Crosshair Scene

**File:** `custodian/scenes/crosshair.tscn`

Create a proper crosshair sprite/control:
- Center dot
- Directional indicator showing aim direction
- Optional: range indicators

### 2. Update UI to Position Crosshair

**File:** `custodian/scenes/ui.gd`

```gdscript
func _update_crosshair():
    if not crosshair_label:
        return
    
    var ws = _get_world_state()
    if not ws:
        crosshair_label.visible = false
        return
    
    var arrow_enabled = ws.get("arrow_aim_enabled", false)
    var aim_direction = ws.get("aim_direction", Vector2.RIGHT)
    var player_pos = ws.get("player_position", Vector2.ZERO)
    
    if not arrow_enabled:
        # Use mouse position when in mouse aim mode
        crosshair_label.visible = false
        return
    
    # Calculate crosshair position based on aim direction
    var aim_distance = 150.0  # Pixels from player
    var crosshair_pos = player_pos + aim_direction * aim_distance
    
    # Convert to screen position
    var camera = get_node_or_null("/root/GameRoot/World/Camera2D")
    if camera:
        var screen_pos = camera.unproject_position(crosshair_pos)
        crosshair_label.position = screen_pos
        crosshair_label.visible = true
```

### 3. Add Aim Direction to World State

**File:** `custodian/entities/operator/operator.gd`

In `_get_world_state()` add:
```gdscript
"aim_direction": aim_direction,
"arrow_aim_enabled": arrow_aim_enabled,
```

### 4. Make Crosshair Visible

**File:** `custodian/scenes/ui.gd`

Update the crosshair section to show when arrow aiming is enabled.

---

## File Changes

| File | Action |
|------|--------|
| `custodian/scenes/crosshair.tscn` | CREATE - Crosshair scene |
| `custodian/scenes/ui.gd` | MODIFY - Show/position crosshair |
| `custodian/entities/operator/operator.gd` | MODIFY - Export aim_direction |

---

## Testing

- [ ] Press key to toggle arrow aim mode
- [ ] Crosshair appears when using arrow keys
- [ ] Crosshair moves in aim direction
- [ ] Crosshair disappears when using mouse aim
- [ ] Crosshair follows player as they move

---

*Document created: 2026-03-29*
