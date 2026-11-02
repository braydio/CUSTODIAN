# Runtime World & Camera Stabilization — Implementation Plan

**Feature:** Runtime World & Camera Stabilization
**Last Updated:** 2026-04-10

---

## Implementation Approach

The fix requires explicit bindings at each handoff step rather than relying on auto-discovery or fallbacks. The existing code has 80% of the infrastructure—we need to wire it up explicitly and remove the legacy fallbacks.

---

## Step 1: Add Camera Snap to ContractWorldLoader

**File:** `custodian/core/systems/contract_world_loader.gd`

**Current:** `_refresh_camera(map_instance)` calls `camera.set_runtime_map(map_instance)`

**Change:** Add explicit snap call after setting runtime map:

```gdscript
func _refresh_camera(map_instance: Node) -> void:
    var camera := get_node_or_null(camera_path)
    if camera == null:
        return
    if camera.has_method("set_runtime_map"):
        camera.call("set_runtime_map", map_instance)
    # NEW: Explicit snap to player spawn
    if camera.has_method("snap_to_player_spawn"):
        var operator := get_node_or_null(operator_path)
        if operator:
            camera.call("snap_to_player_spawn", operator.global_position)
```

---

## Step 2: Add Camera Snap Method

**File:** `custodian/scenes/camera.gd`

**Add method:**

```gdscript
func snap_to_player_spawn(spawn_position: Vector2) -> void:
    # Instant snap - no lerp on first frame
    global_position = spawn_position + player_offset
    _last_position = global_position
    # Reset any momentum
    _lookahead = Vector2.ZERO
    _current_bob = 0.0
```

**Modify `set_runtime_map`:**

```gdscript
func set_runtime_map(map_instance: Node) -> void:
    _runtime_map = map_instance
    _rebuild_bounds()
    on_sector_entry()
    # NEW: Don't lerp from old position, snap directly
    if follow_enabled and operator_ref:
        snap_to_player_spawn(operator_ref.global_position)
```

---

## Step 3: Force Procgen Bounds, Remove Legacy Fallback

**File:** `custodian/scenes/camera.gd`

**Current problem:** `_rebuild_bounds()` falls back to legacy sectors if procgen fails

**Fix:** Make procgen the ONLY source, remove fallback:

```gdscript
func _rebuild_bounds() -> bool:
    # ALWAYS try procgen first - no fallback to legacy
    var result := _rebuild_bounds_from_procgen()
    
    if not result:
        push_warning("[Camera] Procgen bounds failed - camera will be unclamped")
        # Set invalid bounds to disable clamping rather than use legacy
        map_bounds = Rect2()
        return false
    
    return result
```

**Remove or disable `_rebuild_bounds()` legacy fallback code (lines 595-631)**

---

## Step 4: Add Navigation Rebuild Call to ContractWorldLoader

**File:** `custodian/core/systems/contract_world_loader.gd`

**Current:** No navigation rebuild call

**Add after repositioning:**

```gdscript
# Add export for navigation system path
@export var navigation_system_path: NodePath = NodePath("/root/GameRoot/NavigationSystem")

# Add to _on_contract_generated:
if reposition_camera_from_contract:
    _refresh_camera(map_instance)

# NEW: Rebuild navigation with explicit tilemap references
_rebuild_navigation(map_instance)

# Then mark ready
_mark_contract_ready()
```

**Add method:**

```gdscript
func _rebuild_navigation(map_instance: Node) -> void:
    var nav := get_node_or_null(navigation_system_path)
    if nav == null:
        return
    if not nav.has_method("rebuild"):
        return
    
    # Get explicit tilemap references from procgen
    if map_instance is ProcGenTilemap:
        var pg := map_instance as ProcGenTilemap
        if pg.floor_tilemap:
            nav.floor_tilemap = pg.floor_tilemap
        if pg.walls_tilemap:
            nav.walls_tilemap = pg.walls_tilemap
    
    nav.rebuild()
```

---

## Step 5: Ensure Camera Group Registration

**File:** `custodian/scenes/camera.gd`

**Current:** Camera adds itself to "camera" group in `_ready()`

**Verify:** Ensure `add_to_group("camera")` is present (it is on line 155)

**Add guard in `set_runtime_map`:**

```gdscript
func set_runtime_map(map_instance: Node) -> void:
    # Ensure we're in camera group
    if not is_in_group("camera"):
        add_to_group("camera")
    _runtime_map = map_instance
    # ... rest of method
```

---

## Step 6: Mouse Aim Verification (Debug)

**Test procedure (not code):**
1. Boot into generated contract world
2. Place player in center of visible map
3. Move mouse to edge of screen - verify cursor maps to correct world position
4. Fire weapon - verify bullet travels toward cursor, not offset

**Optional debug code in operator:**

```gdscript
# In operator.gd - temporary debug
func _process(delta):
    if Input.is_action_just_pressed("debug_aim_check"):
        var mouse := get_global_mouse_position()
        print("[DEBUG] Mouse world: ", mouse, " Player: ", global_position)
        print("[DEBUG] Distance: ", mouse.distance_to(global_position))
```

---

## Implementation Order

1. **Complete** — `ContractWorldLoader` now snaps camera and explicitly rebinds navigation tilemaps
2. **Complete** — `Camera` now has `snap_to_player_spawn()` and resets motion state on handoff
3. **Complete** — `Camera` now uses procgen-only bounds with unclamped fallback on failure
4. **Complete** — `Operator` aim path now resolves through the active camera first
5. **Next** — Boot game and verify camera, aim, anchors, and navigation in one procgen session

---

## Key Files Modified

| File | Changes |
|------|---------|
| `custodian/game/systems/core/systems/contract_world_loader.gd` | Camera snap on handoff, explicit navigation tilemap rebinding, active map accessor, group registration |
| `custodian/game/world/camera.gd` | Add `snap_to_player_spawn()`, force procgen-only bounds, reassert camera group |
| `custodian/game/systems/core/systems/navigation_system.gd` | Explicit runtime tilemap setter, rebuild state reset |
| `custodian/game/actors/operator/operator.gd` | Camera-authoritative mouse aim lookup |

---

## What NOT to Change

- Don't change procgen layout algorithms
- Don't change entity repositioning logic (already works)
- Don't add new systems—just wire up existing ones
- Don't modify combat mechanics
