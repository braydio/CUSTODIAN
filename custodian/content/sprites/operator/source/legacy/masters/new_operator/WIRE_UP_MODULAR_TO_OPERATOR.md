# Wiring Modular Sprites to the Operator

> Instructions for Codex: Integrate the modular fast attack sprite suite from `new_operator/modular/fast_attack/` into the operator's runtime system so the character uses these sprites in-game.

## System Overview

```
[new_operator/modular/fast_attack/]
  └─ __modular_upper_body__, __modular_lower_body__, __modular_upper_fx__
       │  Composite via review_modular_body_pairs.py
       ▼
[combined baked PNGs]     ← flat upper+lower sheet for the pipeline
       │
       ▼
[runtime/body/unarmed/]   ← pipeline reads from here
       │
       ▼
[update_operator_curated_resources.gd]
       │  Reads PNGs → writes SpriteFrames .tres
       ▼
[operator_runtime_frames.tres]  ← loaded by operator.tscn AnimatedSprite2D
       │
       ▼
[unarmed_definition.tres]  ← maps intent names ("melee_fast") → animation names ("unarmed_attack_fast")
       │
       ▼
[State machine]  ← attack_fast_state.gd calls start_attack("melee_fast")
```

## What We Have

### Modular Sprites in `new_operator/modular/fast_attack/`

| Animation | Part | Directions | Frames | Status |
|-----------|------|-----------|--------|--------|
| `fast_strike_01` | upper_body | **ALL 8** | 3f | ✅ Complete |
| `fast_strike_01` | lower_body | E,NE,NW,SE,SW,W (6/8) | 3f | ⚠️ Missing N,S lower |
| `fast_strike_01` | upper_fx (FX) | **ALL 8** | 3f | ✅ Complete |
| `fast_windup_01` | upper_body | **ALL 8** | 3f | ✅ Complete |
| `fast_windup_01` | lower_body | **ALL 8** | 3f | ✅ Complete |
| `fast_windup_01` | upper_fx (FX) | — | — | ❌ Not created yet |

### Current Runtime (what the operator actually uses)

The existing `unarmed_attack_fast` animation is currently sourced from:
- `runtime/body/unarmed/operator__body__unarmed__fast_01__{s,e,w,n}__{6,5,5,6}f__96.png` — 4 directions only, **baked** (not modular)
- `runtime/overlay/unarmed/operator__fx__unarmed__fast_01__{s,e,n}__{6,3,6}f__96.png` — 3 directions only

These are flat sprite sheets — one PNG per animation+direction combination. The **modular system splits upper/lower/FX** and requires compositing before it can be consumed by the pipeline.

## Step-by-Step Plan

There are two approaches. **Approach A** is recommended (pragmatic, matches existing architecture). **Approach B** is for if you want the cleanest result but requires more work.

---

### Approach A: Composite via Review Tool, Then Feed to Pipeline

#### Phase 1: Generate Combined Body & FX Sheets

> **⚠️ Frame width caveat:** The `__96` suffix in filenames is correct for most directions but **wrong for E/W**.
> E/W sprites have 128px-wide frames (3 × 128 = 384px total), not 96px. The review tool's `parse_sheet_meta` uses the suffix as frame width, so E/W composites will be incorrectly cropped to 96px.
>
> **Fix:** Run the tool once for non-EW directions, then separately for E/W with `--frame-width 128`.
> Or use the manual compositing script in Step 1c instead.

**1a. Run `review_modular_body_pairs.py` for non-EW directions**

```bash
python3 tools/review_modular_body_pairs.py \
  --root custodian/content/sprites/operator/new_operator/modular/fast_attack \
  --out /tmp/fast_composites \
  --fx-offset-x 0 --fx-offset-y 0
```

This produces combined body PNGs (upper+lower composited) and FX overlay composites for all directions in `/tmp/fast_composites/`.

**1b. Re-run with correct frame width for E/W**

The `__dir__e__` and `__dir__w__` files need frame_width=128:

```bash
# Move the wrong E/W composites out of the way
mkdir -p /tmp/fast_composites/e_w_correct
python3 tools/review_modular_body_pairs.py \
  --root custodian/content/sprites/operator/new_operator/modular/fast_attack \
  --out /tmp/fast_composites/e_w_correct \
  --frame-width 128
# Then copy the E/W combined strips from the corrected run
cp /tmp/fast_composites/e_w_correct/combined/*__e__* /tmp/fast_composites/combined/
cp /tmp/fast_composites/e_w_correct/combined/*__w__* /tmp/fast_composites/combined/
cp /tmp/fast_composites/e_w_correct/combined/*__plus_fx__*__e__* /tmp/fast_composites/combined/
cp /tmp/fast_composites/e_w_correct/combined/*__plus_fx__*__w__* /tmp/fast_composites/combined/
```

**1b. Generate separate FX-only sheets**

The review tool creates body+FX composites for preview, but the pipeline needs **separate** body and FX sheets. You'll need a small script to extract/regenerate FX-only sheets from the modular FX files. Use `review_modular_flat_png_pairs.py` or write a quick PIL script that:

- Reads each `operator__modular_upper_fx__unarmed__fast_strike_01__{dir}__3f__96.png`
- Slices frames: `width / 3` per frame (128px for E/W, 96px for all others)
- Outputs flat PNG strips to match the current FX naming

**1c. Create the windup FX sheets**

`fast_windup_01` has no FX overlays yet. These must be created from scratch (Aseprite/artwork) or left out initially.

#### Phase 2: Stage into Runtime

**2a. Copy combined body sheets to `runtime/body/unarmed/`**

| Source (composite output) | Destination (runtime) |
|---------------------------|----------------------|
| `fast_strike_01__s__3f__96.png` (if N/S lower exists) | `operator__body__unarmed__fast_strike_01__s__3f__96.png` |
| `fast_strike_01__e__3f__96.png` | `operator__body__unarmed__fast_strike_01__e__3f__96.png` |
| `fast_strike_01__ne__3f__96.png` | `operator__body__unarmed__fast_strike_01__ne__3f__96.png` |
| ... etc for all 8 dirs | ... |
| `fast_windup_01__s__3f__96.png` | `operator__body__unarmed__fast_windup_01__s__3f__96.png` |
| ... etc for all 8 windup dirs | ... |

Naming convention: `operator__body__unarmed__{anim}__{dir}__{N}f__96.png`
Frame width: E/W = 128px, all others = 96px.

**2b. Copy FX sheets to `runtime/overlay/unarmed/`**

Same pattern: `operator__fx__unarmed__fast_strike_01__{dir}__3f__96.png`

**2c. Git add the new runtime files**

```bash
git add custodian/content/sprites/operator/runtime/body/unarmed/*fast_strike_01* runtime/overlay/unarmed/*fast_strike_01*
git add custodian/content/sprites/operator/runtime/body/unarmed/*fast_windup_01* runtime/overlay/unarmed/*fast_windup_01*
```

#### Phase 3: Update the Pipeline Script

**3a. Add new constants to `update_operator_curated_resources.gd`**

```gdscript
# --- New modular fast strike sheets ---
const UNARMED_FAST_STRIKE_SOUTH_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__fast_strike_01__s__3f__96.png"
const UNARMED_FAST_STRIKE_EAST_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__fast_strike_01__e__3f__96.png"
const UNARMED_FAST_STRIKE_WEST_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__fast_strike_01__w__3f__96.png"
const UNARMED_FAST_STRIKE_NORTH_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__fast_strike_01__n__3f__96.png"
const UNARMED_FAST_STRIKE_NORTHEAST_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__fast_strike_01__ne__3f__96.png"
const UNARMED_FAST_STRIKE_NORTHWEST_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__fast_strike_01__nw__3f__96.png"
const UNARMED_FAST_STRIKE_SOUTHEAST_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__fast_strike_01__se__3f__96.png"
const UNARMED_FAST_STRIKE_SOUTHWEST_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__fast_strike_01__sw__3f__96.png"

# --- New modular fast windup sheets ---
const UNARMED_FAST_WINDUP_SOUTH_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__fast_windup_01__s__3f__96.png"
# ... (add all 8 directions)

# --- FX sheets ---
const UNARMED_FAST_STRIKE_FX_SOUTH_SHEET := "res://content/sprites/operator/runtime/overlay/unarmed/operator__fx__unarmed__fast_strike_01__s__3f__96.png"
# ... (add all 8 dirs for FX)
```

**3b. Add pipeline calls for the new animations**

In the `_init()` method, after existing unarmed animation calls:

```gdscript
# --- Fast Strike ---
_replace_animation_if_exists(body_frames, "unarmed_fast_strike", UNARMED_FAST_STRIKE_SOUTH_BODY_SHEET, 3, 0, 96, 96, 12.0, false)
_replace_animation_if_exists(body_frames, "unarmed_fast_strike_down", UNARMED_FAST_STRIKE_SOUTH_BODY_SHEET, 3, 0, 96, 96, 12.0, false)
_replace_animation_if_exists(body_frames, "unarmed_fast_strike_right", UNARMED_FAST_STRIKE_EAST_BODY_SHEET, 3, 0, 128, 96, 12.0, false)
_replace_animation_if_exists(body_frames, "unarmed_fast_strike_left", UNARMED_FAST_STRIKE_WEST_BODY_SHEET, 3, 0, 128, 96, 12.0, false)
_replace_animation_if_exists(body_frames, "unarmed_fast_strike_up", UNARMED_FAST_STRIKE_NORTH_BODY_SHEET, 3, 0, 96, 96, 12.0, false)
_replace_animation_if_exists(body_frames, "unarmed_fast_strike_up_right", UNARMED_FAST_STRIKE_NORTHEAST_BODY_SHEET, 3, 0, 96, 96, 12.0, false)
_replace_animation_if_exists(body_frames, "unarmed_fast_strike_up_left", UNARMED_FAST_STRIKE_NORTHWEST_BODY_SHEET, 3, 0, 96, 96, 12.0, false)
_replace_animation_if_exists(body_frames, "unarmed_fast_strike_down_right", UNARMED_FAST_STRIKE_SOUTHEAST_BODY_SHEET, 3, 0, 96, 96, 12.0, false)
_replace_animation_if_exists(body_frames, "unarmed_fast_strike_down_left", UNARMED_FAST_STRIKE_SOUTHWEST_BODY_SHEET, 3, 0, 96, 96, 12.0, false)

# --- Fast Windup ---
_replace_animation_if_exists(body_frames, "unarmed_fast_windup", UNARMED_FAST_WINDUP_SOUTH_BODY_SHEET, 3, 0, 96, 96, 10.0, false)
_replace_animation_if_exists(body_frames, "unarmed_fast_windup_down", UNARMED_FAST_WINDUP_SOUTH_BODY_SHEET, 3, 0, 96, 96, 10.0, false)
# ... (all 8 directions, same pattern as strike)

# --- Fast Strike FX ---
_replace_animation_if_exists(melee_overlay_frames, "unarmed_fast_strike_fx_down", UNARMED_FAST_STRIKE_FX_SOUTH_SHEET, 3, 0, 96, 96, 12.0, false)
_replace_animation_if_exists(melee_overlay_frames, "unarmed_fast_strike_fx_right", UNARMED_FAST_STRIKE_FX_EAST_SHEET, 3, 0, 128, 96, 12.0, false)
# ... (all 8 directions)
```

**Frame width note:** E/W sheets are 384×128 (3 frames × 128px width). All others are 288×96 (3 frames × 96px width). Use `frame_width=128` for east/west, `96` for all others.

#### Phase 4: Update Weapon Definition

**4a. Edit `unarmed_definition.tres`**

Add entries to `animation_map` for the new animations. The decision here is how to handle windup + strike:

**Option 4a-i (Replace existing fast):** Point `melee_fast` → `unarmed_fast_strike` instead of `unarmed_attack_fast`.

```gdscript
# animation_map changes:
"melee_fast"   -> "unarmed_fast_strike"   # was "unarmed_attack_fast"
"melee_fast_1" -> "unarmed_fast_strike"   # both combo slots use same
"melee_fast_2" -> "unarmed_fast_strike"
```

**Option 4a-ii (Add windup as a new animation):** Add a separate intent or use windup for one combo slot.

```gdscript
# animation_map additions:
"unarmed_fast_windup" -> "unarmed_fast_windup"   # new intent → new anim
```

**4b. Update `fx_map` to match**

```gdscript
"melee_fast"   -> { "fx_anim": "unarmed_fast_strike_fx" }
```

**4c. Update `hit_windows`**

The fast_strike is 3 frames (was 6 for the old fast). Adjust hit windows:

```gdscript
"melee_fast"   -> { "frames": [2] }   # frame 2/3 = roughly 66% through
```

#### Phase 5: Update Animation State Machine (If Adding New States)

If introducing `unarmed_fast_windup` as a separate animation phase:

**5a. Create `attack_windup_state.gd`** similar to `attack_fast_state.gd` but plays `"unarmed_fast_windup"` and auto-transitions to `"unarmed_fast_strike"` on completion.

**5b. Register the new state** in the state machine.

---

### Approach B: Build-Time Compositing (Cleaner but More Complex)

Instead of pre-compositing with Python, modify `update_operator_curated_resources.gd` to accept modular parts and composite them at `.tres` build time.

This would require:
1. Loading both upper and lower PNGs
2. Compositing them into a single texture in Godot (using `Image.blend_rect`)
3. Slicing frames from the composited result

This avoids the intermediate step of maintaining pre-composited PNGs but is more complex to implement. Only pursue if you're comfortable modifying the Godot pipeline script significantly.

---

## File Change Checklist

| File | Action |
|------|--------|
| `tools/review_modular_body_pairs.py` | ✅ Already updated (handles FX, offsets) |
| `new_operator/modular/fast_attack/*.png` | ✅ All files consistently named (`__3f__96.png`) |
| `runtime/body/unarmed/operator__body__unarmed__fast_strike_01__*.png` | **Create** — combined body sheets (×8) |
| `runtime/body/unarmed/operator__body__unarmed__fast_windup_01__*.png` | **Create** — combined body sheets (×8) |
| `runtime/overlay/unarmed/operator__fx__unarmed__fast_strike_01__*.png` | **Create** — FX sheets (×8) |
| `tools/pipelines/update_operator_curated_resources.gd` | **Edit** — add constants + pipeline calls |
| `game/actors/operator/unarmed_definition.tres` | **Edit** — update animation_map, fx_map, hit_windows |
| `game/actors/operator/operator_runtime_frames.tres` | **Auto-generated** — re-run pipeline |
| `game/actors/operator/operator_melee_overlay_frames.tres` | **Auto-generated** — re-run pipeline |
| State scripts (`attack_fast_state.gd` etc.) | **Possibly edit** — if adding windup state |

## Verification

1. Run the pipeline: `bun run pipeline_update_operator` (or the appropriate Godot invocation)
2. Verify new animation names appear in `operator_runtime_frames.tres`
3. Load the operator scene in Godot and check `unarmed_fast_strike` plays correctly
4. Test in-game: unarmed fast attack should use the modular sprites with 8-direction support

## Notes

- **Fast windup FX**: The modular suite has no windup FX overlays yet. You can skip FX for windup initially or create simple ones.
- **N/S lower body strike**: These frames don't exist. The lower body for N/S uses a neutral stance or the existing baked N/S frames. For a first pass, you can composite the upper body N/S strike over a generic lower body frame.
- **Frame width**: E/W = 128px per frame (total 384px). All others = 96px per frame (total 288px).
- **The `__ALTERNATE.png` FX file** is an intentional variant for the E direction. You can either include both or just use the main one.
