# GOTHIC COMPOUND GENERATOR — ARCHITECTURE HARDENING

**Type:** Feature implementation spec / Codex instruction document
**Owner:** gameplay / procgen
**Status:** draft
**Last Updated:** 2026-05-19
**Target:** Codex agent implementing the next generation pass

---

## Context

The gothic compound procgen is working — it places the right *asset families* — but generates the wrong *layout grammar*. A recent screenshot showed a noisy, overfilled compound that reads as a dense asset collage rather than a fortified playable space.

This document is both a diagnostic and an instruction set for Codex. It describes what is already correct, what is still wrong, and exactly what to fix.

---

## Audit: What Is Already Done

Reviewing the live codebase at `custodian/game/world/procgen/gothic_compound/`:

| File | Status |
|------|--------|
| `gothic_compound_asset_defs.gd` | **Done.** Logical IDs, paths, kind, footprint, anchor, blocks, z. Top-left anchoring established. |
| `gothic_compound_sprite_context.gd` | **Done.** `sprite.centered = false`, `grid_to_world(cell)` for all spawns, metadata-aware collision, `_layer_for_kind()`. |
| `gothic_compound_generator.gd` | **Mostly done.** Zones defined, command keep placement is zone-aware, roads use chunked `_carve_horizontal_road_chunks()`, fixed light pools, quota-based small decals, exterior scatter checks `required_walkable`. |
| `gothic_compound_config.gd` | **Done.** `decorative_scatter_chance` already lowered to `0.012`. |
| `gothic_compound_result.gd` | **Done.** `flags` dict, `placement_errors` array. |
| `gothic_compound_validator.gd` | **Mostly done.** Perimeter topology validation, flag checks, placement error accumulation, does NOT clear errors before validating. |

---

## What Remains Wrong

### 1. Approach road scatter intrusion

`_place_scatter_and_decals()` iterates the *entire* `outer` rect (compound + 5-tile margin). The approach road runs outside the compound rect, from `map_size.y - 2` down to the gate. Since `required_walkable` marks the approach path, the `has(cell)` check should block scatter on it — but the loop runs over all of `outer`, including cells below the gate that are outside the compound rect. The approach road cells that happen to overlap the gate killzone or exterior_ruin_belt are not flagged in `required_walkable` until after `_carve_approach_road()` completes and calls `mark_required_path()`. The `_place_scatter_and_decals()` call happens *after* `_carve_approach_road()`, so the approach road IS marked before scatter runs — but the code should be explicit about this.

**Action:** Verify the ordering is safe and add an explicit guard: if scatter cell is in `approach_path`, skip it.

### 2. `_pick_inside_ground()` still uses per-cell noise

The generator defines `_fill_base_terrain()` correctly (using `terrain_stone_a` everywhere interior, then patching), but there is still a `_pick_inside_ground()` method that implements high-frequency per-cell noise. It is currently **not called** from the generation flow — `_fill_base_terrain()` uses the zone-based approach — but leaving it in the codebase is a drift risk.

**Action:** Delete `_pick_inside_ground()`. Use `_fill_base_terrain()` + `_apply_interior_floor_patches()` only.

### 3. Exterior scatter outside the compound margin

`_place_exterior_scatter()` iterates `outer = rect.grow(cfg.outer_margin_fill)` (5 cells). The approach road starts at `gate_cell.y + 1` and extends to `map_size.y - 2`. If the compound is placed in the lower half of the map, the approach road overlaps the exterior scatter zone. The `required_walkable` guard catches the path cells, but rubble/dead_tree/collapsed_spire adjacent to the path can visually crowd the road.

**Action:** Add a proximity guard: skip exterior scatter within 3 cells of any approach path cell.

### 4. Sandbag placement uses fixed magic offsets, not zone-aware positions

`_place_defenses()` uses hardcoded `gate + Vector2i(-7, -4)` offsets that assume a specific compound size. This is fragile for variable compound dimensions.

**Action:** Make sandbag positions relative to the `gate_killzone` zone defined in `_define_zones()`. Place 2 sandbags on each side of the gate within the killzone, and 2 stone covers flanking the inner yard path.

### 5. Validator does not check decal count or structure overlap

The validator ensures the perimeter is solid and paths are walkable, but it cannot catch:
- More than ~12 interior decals being placed (the quota is set but not validated)
- Large structures visually overlapping (footprints are marked blocked but there is no visual overlap check)

**Action:** Add a `max_interior_decals` check to the validator (count sprites in DecalLayer or track `placed_decals`). This is a soft warning, not a hard failure.

### 6. Utility structure placement uses magic offsets instead of zones

`_place_utility_structures()` has hardcoded positions like `Vector2i(rect.position.x + 6, rect.end.y - 9)` for the bell frame instead of using the defined zones.

**Action:** Place utility structures within their defined zones. Bell frame should be in or adjacent to the inner yard. Utility fan and machine house should be constrained to `west_utility_pad` and `east_utility_pad` zones.

### 7. `spawn_asset()` collision offset comment is misleading

The collision rect is placed at `rect.size * 0.5` relative to the StaticBody. Since the parent sprite is top-left anchored at `grid_to_world(cell)`, the StaticBody's world position equals the sprite's world position + `rect.size * 0.5`. That is correct — the collision body is centered on the footprint. No code change needed, but add a clarifying comment.

**Action:** Add doc comment to `_add_collision_rect()` explaining the centering logic.

---

## Complete Instruction Set for Codex

Paste this as a task packet or direct prompt:

---

### TASK: Gothic Compound Generator Architecture Hardening

The gothic compound procgen at `custodian/game/world/procgen/gothic_compound/` is mostly correct but has 7 remaining issues that cause visual clutter, fragile placement, and weak validation.

**Files to change:**
- `gothic_compound_generator.gd`
- `gothic_compound_validator.gd`
- `gothic_compound_sprite_context.gd` (comment only)

**Do not change:**
- `gothic_compound_asset_defs.gd` — already correct
- `gothic_compound_config.gd` — already correct
- `gothic_compound_result.gd` — already correct
- `gothic_compound_sprite_context.gd` — architecture is correct, only add a comment

---

#### Fix 1: Delete `_pick_inside_ground()`

Delete the entire method `_pick_inside_ground()` from `gothic_compound_generator.gd`. It is unused and is a drift risk. The interior floor uses `_fill_base_terrain()` + `_apply_interior_floor_patches()` only.

---

#### Fix 2: Guard approach path from exterior scatter

In `_place_scatter_and_decals()`, after calling `_place_fixed_light_pools()` and `_place_small_floor_decals()`, iterate `outer`. Before placing exterior scatter, check:

```gdscript
if result.approach_path.has(cell):
    continue
# Also skip cells within 3 tiles of approach path
var near_approach := false
for ap in result.approach_path:
    if ap.distance_to(cell) <= 3.0:
        near_approach = true
        break
if near_approach:
    continue
```

This prevents debris from visually crowding the approach road.

---

#### Fix 3: Make defenses zone-aware

Replace the hardcoded defense placements in `_place_defenses()` with zone-relative offsets:

```gdscript
func _place_defenses(ctx: Object, result, rect: Rect2i) -> void:
    var gate: Vector2i = result.gate_cell
    var killzone: Rect2i = result.zones.get("gate_killzone", Rect2i())

    # Gate killzone: sandbags flanking the gate opening
    var sandbag_positions := [
        Vector2i(gate.x - 3, killzone.position.y + 1),
        Vector2i(gate.x + 1, killzone.position.y + 1),
        Vector2i(gate.x - 3, killzone.end.y - 2),
        Vector2i(gate.x + 1, killzone.end.y - 2),
    ]
    for cell in sandbag_positions:
        if _in_map(ctx, cell) and not ctx.call("is_blocked", cell):
            _place_prop_checked(ctx, result, cell, _asset("sandbag_h").get("footprint", Vector2i.ONE), _asset("sandbag_h"), true)

    # Gate exterior: spike barricades outside gate approach
    var spike_positions := [
        gate + Vector2i(-2, 2),
        gate + Vector2i(1, 2),
    ]
    for cell in spike_positions:
        if _in_map(ctx, cell) and not ctx.call("is_blocked", cell):
            _place_prop_checked(ctx, result, cell, _asset("spike_h").get("footprint", Vector2i.ONE), _asset("spike_h"), true)

    # Inner yard: stone covers flanking the main path
    var yard: Rect2i = result.zones.get("inner_yard", rect)
    var path_center_x := int((yard.position.x + yard.end.x) / 2)
    var stone_cover_positions := [
        Vector2i(yard.position.x + 3, yard.position.y + 2),
        Vector2i(yard.end.x - 6, yard.position.y + 2),
    ]
    for cell in stone_cover_positions:
        if _in_map(ctx, cell) and not ctx.call("is_blocked", cell):
            _place_prop_checked(ctx, result, cell, _asset("stone_cover_h").get("footprint", Vector2i.ONE), _asset("stone_cover_h"), true)
```

This ensures defenses scale with compound size and stay within the killzone / inner yard.

---

#### Fix 4: Make utility structures zone-aware

In `_place_utility_structures()`, replace hardcoded offsets with zone positions:

```gdscript
func _place_utility_structures(ctx: Object, result, rect: Rect2i) -> void:
    var west_pad: Rect2i = result.zones.get("west_utility_pad", Rect2i())
    var east_pad: Rect2i = result.zones.get("east_utility_pad", Rect2i())
    var yard: Rect2i = result.zones.get("inner_yard", rect)

    var candidates := []

    if west_pad.size != Vector2i.ZERO:
        candidates.append({"cell": west_pad.position, "asset": _asset("utility_fan")})

    if east_pad.size != Vector2i.ZERO:
        candidates.append({"cell": east_pad.position, "asset": _asset("machine_house")})

    # Bell frame: anchored to inner yard north edge, center-x
    if yard.size != Vector2i.ZERO:
        var bell_x := int((yard.position.x + yard.end.x) / 2) - 2
        candidates.append({"cell": Vector2i(bell_x, yard.position.y), "asset": _asset("bell_frame")})

    for entry in candidates:
        var def: Dictionary = entry["asset"]
        var fp: Vector2i = def.get("footprint", Vector2i.ONE)
        _place_prop_checked(ctx, result, entry["cell"], fp, def, bool(def.get("blocks", true)))
```

---

#### Fix 5: Add decal count to validator

In `gothic_compound_validator.gd`, add a soft warning for excessive interior decals. Track decal placement in the result and check it:

Add to `gothic_compound_result.gd`:
```gdscript
var placed_decals: int = 0
```

Increment in `_place_small_floor_decals()`:
```gdscript
result.placed_decals += 1
```

Increment in `_place_fixed_light_pools()`:
```gdscript
result.placed_decals += 1
```

Then in `gothic_compound_validator.gd`, add after the flag checks:
```gdscript
_require(result.placed_decals <= 25, validation_errors,
    "Too many interior decals: %d (expected <= 25)" % result.placed_decals)
```

This is a soft failure (warning), not a hard failure — decals do not break gameplay. Consider using `_warn()` pattern instead of `_require()` if you want it non-blocking.

---

#### Fix 6: Add clarifying comment to collision method

In `gothic_compound_sprite_context.gd`, add to `_add_collision_rect()`:

```gdscript
## Spawns a StaticBody2D collision rectangle centered on the asset footprint.
## Because the parent Sprite2D uses top-left anchoring (sprite.centered = false,
## positioned at grid_to_world(origin_cell)), the collision body must be offset
## by rect.size * 0.5 so its world-space center aligns with the footprint center.
func _add_collision_rect(parent: Node2D, size: Vector2i) -> void:
```

---

## Expected Result After Fixes

| Aspect | Before | After |
|--------|--------|-------|
| Interior floor | High-frequency per-cell noise | Calm stone base with large patches |
| Approach road | May have debris crowding it | Clear path, debris stays 3+ cells away |
| Decals | ~12 interior floor decals + fixed light pools | Same, capped at 25 total interior |
| Defenses | Hardcoded offsets, fragile | Zone-relative, scales with compound size |
| Utilities | Magic offsets | Zone-constrained |
| Collision | Centered on footprint (correct) | Documented |

---

## Validation Checklist

After implementing, verify in Godot:

- [ ] Compound rect appears in map
- [ ] Perimeter wall forms a complete ring with gate gap on south edge
- [ ] Gate is visually open, walkable
- [ ] Approach road runs from map edge to gate with no debris overlap
- [ ] Internal road connects gate to command keep
- [ ] Command keep is north-center, clearly the focal point
- [ ] Terminal is reachable from command keep area
- [ ] Decals feel intentional: 1-2 light pools near gate/keep/terminal, ~10-12 floor grates/sigils
- [ ] No debris visually crowding the approach road
- [ ] Sandbags are inside gate killzone, not forming the top perimeter
- [ ] Defenses scale correctly when compound size varies (min vs max)
- [ ] Validator passes without errors
- [ ] No visual overlap of large structures