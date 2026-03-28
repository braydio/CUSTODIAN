# Runtime World & Camera Stabilization — Tasks

**Feature:** Runtime World & Camera Stabilization
**Last Updated:** 2026-03-27

---

## Task List

### T-001: Add Navigation Rebuild Call to ContractWorldLoader

**File:** `custodian/core/systems/contract_world_loader.gd`

**Steps:**
1. Add export: `@export var navigation_system_path: NodePath = NodePath("/root/GameRoot/NavigationSystem")`
2. Add method `_rebuild_navigation(map_instance: Node)`:
   ```gdscript
   func _rebuild_navigation(map_instance: Node) -> void:
       var nav := get_node_or_null(navigation_system_path)
       if nav == null:
           return
       if not nav.has_method("rebuild"):
           return
       if map_instance is ProcGenTilemap:
           var pg := map_instance as ProcGenTilemap
           if pg.floor_tilemap:
               nav.floor_tilemap = pg.floor_tilemap
           if pg.walls_tilemap:
               nav.walls_tilemap = pg.walls_tilemap
       nav.rebuild()
   ```
3. Call `_rebuild_navigation(map_instance)` in `_on_contract_generated()` after `_refresh_camera()`

**Verification:** Print "[ContractWorldLoader] Navigation rebuilt" after rebuild

---

### T-002: Add Camera Snap Method

**File:** `custodian/scenes/camera.gd`

**Steps:**
1. Add new method after `set_runtime_map()`:
   ```gdscript
   func snap_to_player_spawn(spawn_position: Vector2) -> void:
       global_position = spawn_position + player_offset
       _last_position = global_position
       _lookahead = Vector2.ZERO
       _current_bob = 0.0
   ```
2. Modify `set_runtime_map()` to call `snap_to_player_spawn()` instead of direct position assignment

**Verification:** Camera snaps instantly on world load, no lerp from old position

---

### T-003: Force Procgen Bounds, Remove Legacy Fallback

**File:** `custodian/scenes/camera.gd`

**Steps:**
1. Modify `_rebuild_bounds()`:
   - Remove the call to legacy fallback (`_rebuild_bounds_from_procgen()` returning false triggers fallback)
   - Make procgen the ONLY bounds source
   - If procgen fails, set `map_bounds = Rect2()` to disable clamping rather than use legacy

2. Remove or comment out legacy fallback code (lines 595-631 in `_rebuild_bounds()`)

**Verification:** Camera uses only procgen map bounds, never legacy sectors

---

### T-004: Ensure Camera Group Registration

**File:** `custodian/scenes/camera.gd`

**Steps:**
1. Verify `add_to_group("camera")` is in `_ready()` (it is, line 155)
2. Add guard in `set_runtime_map()`:
   ```gdscript
   func set_runtime_map(map_instance: Node) -> void:
       if not is_in_group("camera"):
           add_to_group("camera")
   ```

**Verification:** `get_tree().get_first_node_in_group("camera")` returns valid camera

---

### T-005: Boot Test — Camera Behavior

**Steps:**
1. Run Godot project: `cd ~/Projects/CUSTODIAN/custodian && godot -d`
2. Generate new contract world
3. Observe:
   - Camera snaps to player position on load (no drift from old world)
   - Camera follows within procgen map bounds
   - Camera doesn't show areas outside generated map
4. Move to map edges — camera clamps correctly

**Pass:** Camera behaves correctly in generated world
**Fail:** Camera drifts, clamps to wrong area, or shows empty space

---

### T-006: Boot Test — Mouse Aim

**Steps:**
1. In same session as T-005
2. Position player in center of visible map
3. Aim mouse at specific world position (use debug marker if needed)
4. Fire weapon
5. Observe bullet trajectory

**Pass:** Bullet travels toward mouse cursor position
**Fail:** Bullet travels offset from cursor (indicates camera/aim desync)

---

### T-007: Boot Test — Terminal and Anchors

**Steps:**
1. In same session
2. Locate terminal — should be reachable (walkable path from player)
3. Locate item caches — should be reachable
4. Verify no anchors stuck in walls or isolated pockets

**Pass:** All interactables in reachable walkable space
**Fail:** Anchors unreachable or inside walls

---

### T-008: Boot Test — Navigation

**Steps:**
1. In same session
2. Trigger enemy spawn (or use debug spawn)
3. Observe enemy pathing

**Pass:** Enemies path through visible walkable space
**Fail:** Enemies try to path through walls or get stuck

---

## Debug Tools (Optional)

### Bounds Visualization

Add to camera `_draw()` or use debug overlay:
```gdscript
func _draw():
    draw_rect(map_bounds, Color(1, 0, 0, 0.3), false, 2.0)
```

### Tilemap Authority Log

Add to `_refresh_camera()`:
```gdscript
print("[Camera] Runtime map: ", _runtime_map)
print("[Camera] Map bounds: ", map_bounds)
```

---

## Completion Criteria

All tasks T-001 through T-008 must pass for feature complete.

| Task | Description | Status |
|------|-------------|--------|
| T-001 | Navigation rebuild in ContractWorldLoader | ⬜ |
| T-002 | Camera snap method | ⬜ |
| T-003 | Force procgen bounds | ⬜ |
| T-004 | Camera group registration | ⬜ |
| T-005 | Boot test — Camera behavior | ⬜ |
| T-006 | Boot test — Mouse aim | ⬜ |
| T-007 | Boot test — Terminal and anchors | ⬜ |
| T-008 | Boot test — Navigation | ⬜ |
