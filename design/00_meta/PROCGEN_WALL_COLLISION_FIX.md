# ProcGen Wall Collision Fix

**Issue:** No wall collision, unclear wall/floor tiles

**Root Cause:** The `custodian_world_tileset.tres` has NO physics layers configured. The procgen code calls `_rebuild_runtime_wall_collision()` which creates StaticBody2D nodes, but these have no CollisionShape2D with proper size, OR the tilemap layers lack proper physics layers.

---

## Two Problems to Fix

### Problem 1: TileSet has no physics layers

The tileset defines visual sources (floor, walls) but no collision shapes. Godot 4 TileMapLayer has two collision approaches:

**Option A: TileSet Physics Layers (per-tile collision)**
- Add physics layers to the TileSet
- Configure which tiles have collision in the atlas
- Pros: Automatic, per-tile control
- Cons: Requires editing every tile in the tileset

**Option B: Runtime Wall Collision (what proc_gen_tilemap tries to do)**
- Code creates StaticBody2D per wall tile
- Should work, but might be failing silently

Let me check if the runtime collision is actually running...

---

## Debugging Steps

### Step 1: Verify ProcGen is generating walls

In Godot, during gameplay:
1. Pause game
2. Inspect `ProcGenRuntime/ProcGenMap/Walls` TileMapLayer
3. Check if any cells have data (source_id >= 0)

If Walls TileMapLayer is empty → ProcGen didn't generate walls.

### Step 2: Check if collision is being built

Add debug print in `proc_gen_tilemap.gd`:

```gdscript
# Around line 820, in _rebuild_runtime_wall_collision()
func _rebuild_runtime_wall_collision(map_size: Vector2i) -> void:
    print("[DEBUG] Building wall collision for map size: ", map_size)
    var collision_root := walls_tilemap.get_node_or_null("RuntimeWallCollision")
    print("[DEBUG] Collision root exists: ", collision_root != null)
    # ... rest of function
```

### Step 3: Check collision bodies exist

In game, run:
```gdscript
var walls = get_node("/root/GameRoot/World/ProcGenRuntime/ProcGenMap/NavigationRegion2D/Walls/RuntimeWallCollision")
print("Wall bodies: ", walls.get_child_count())
```

---

## Most Likely Fix

The `_rebuild_runtime_wall_collision()` code creates collision bodies but **the shape size might be wrong** due to tilemap scale.

In `proc_gen_map.tscn`:
```
scale = Vector2(2, 2)
```

The ProcGenMap is scaled 2x. This affects how `map_to_local()` converts tile coords → world position.

**Fix in `proc_gen_tilemap.gd` around line 1081:**

```gdscript
# CURRENT (line 1081):
body.position = walls_tilemap.map_to_local(tile)

# FIX: Account for tilemap scale
var local_pos := walls_tilemap.map_to_local(tile)
# map_to_local already returns in local space, but with scale=2 
# the position is doubled. We need the collision body at the correct world position.
body.global_position = walls_tilemap.to_global(local_pos)
```

---

## TileSet Physics Layer Alternative

If runtime collision continues to fail, add physics directly to tileset:

1. Open `custodian_world_tileset.tres` in Godot
2. Select TileSet → Inspector → Physics Layers
3. Add 1 physics layer
4. For each wall source (1 and 2), configure collision:
   - Click the source in the list
   - In the atlas view, paint collision shapes on wall tiles
5. Save tileset
6. The TileMapLayer will automatically use these collisions

This is cleaner than runtime generation but requires more setup.

---

## Visual Clarity Fix

To make walls clearer vs floors:

In `proc_gen_tilemap.gd`, the wall variant selection should show visual difference. The code uses `_select_cohesive_wall_coord()` which picks from reference tile coords - this should already produce varied wall tiles.

If walls look like floors:
1. Check `wall_atlas_coord` export in ProcGenMap (line 30)
2. Verify source_id 1 has wall tiles in the tileset atlas
3. Check `walls_source_id = 11` in scene - this maps to source index 11 in the tileset

In the scene:
- `floor_source_id = 10` → sources[10] = grass tiles
- `walls_source_id = 11` → sources[11] = TX Tileset Wall (32x32, different from walls_low!)

This might be the issue - source 11 is different from source 1 (walls_low).

---

## Recommended Fix Order

1. **Quick test:** Change `walls_source_id` from 11 to 1 in `proc_gen_map.tscn`
   - This uses the actual walls_low tiles instead of TX Tileset Wall

2. **If that doesn't work:** Add debug prints to verify collision is being built

3. **If collision builds but doesn't work:** Fix the scale/position calculation in `_spawn_runtime_wall_body()`

4. **Long term:** Add proper physics layers to the TileSet for cleaner collision