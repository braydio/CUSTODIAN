Also, one important runtime note: your current procgen wall system is still built around **atlas-coordinate wall selection**, with connector/corner logic in `ProcGenTilemap`, so these single-file interior tiles are best treated as a **new interior tileset set**, not a direct drop-in replacement for the current connector atlas unless you later assemble/map them into a Godot tileset. That’s a real runtime-vs-asset-structure mismatch worth keeping in mind. 

---


## Global art spec to reuse in every prompt

Use this as the shared style block in every request:

> **Style:** pixel art, top-down / slight 2.5D game asset, industrial sci-fi military interior, worn but readable, clean silhouette, restrained grime, cool gray concrete, dark steel, muted olive accents, occasional subtle hazard yellow, no text, no mockup, no scene background.
> **Readability:** clear at gameplay distance, not overly noisy, not painterly, not photoreal.
> **CUSTODIAN feel:** utilitarian, militarized, abandoned but functional, subtle wear and damage.
> **Output:** single asset only unless otherwise specified.

---

# Recommended generation order

## Group 0 — Style anchors

Generate these first so later assets can match them.

### Files

* `floor_concrete_32.png`
* `wall_military_32.png`

### Why first

These define the **material language** for everything else:

* concrete floor tone
* wall metal tone
* wear level
* accent color usage

### Prompt idea

> Generate 2 separate pixel art game assets for a top-down industrial sci-fi military interior tileset. Asset 1 is a 32x32 concrete floor tile. Asset 2 is a 32x32 military wall tile. Style should be gritty but readable, with cool gray concrete, worn dark metal, subtle olive military accents, light grime, small cracks and edge wear, and no text. Keep the style clean and modular for use in a Godot tileset.

---

# Group 1 — Core floor set

These belong together because they are all floor-family assets.

### Files

* `floor_concrete_32.png`
* `floor_panel_32.png`
* `floor_grate_32.png`

### Why grouped

Same perspective, same scale, same lighting, same tile edge language.

### Notes

* These should be **full-tile** assets.
* Ask for **seamless/tileable edges**.
* No transparency needed unless you specifically want layered floor overlays.

### Prompt

> Generate 3 separate 32x32 pixel art floor tiles for a top-down sci-fi military interior tileset:
>
> 1. concrete floor tile
> 2. metal panel floor tile
> 3. grated industrial floor tile
>    All three should share the same visual style: industrial military interior, worn but readable, cool gray and steel palette, restrained grime, subtle edge wear, slight sci-fi detail, modular and tileable, clear at gameplay scale, no text, no scene background.

---

# Group 2 — Core wall structure set

These should be generated together because they need to visually match exactly.

### Files

* `wall_military_32.png`
* `wall_military_top_32.png`
* `wall_military_corner_32.png`

### Why grouped

These are the same wall family expressed in different structural roles.

### What each should communicate

* `wall_military_32.png`
  Main straight wall/body tile
* `wall_military_top_32.png`
  Top edge / cap / exposed upper wall surface
* `wall_military_corner_32.png`
  Corner transition tile matching the same wall construction

### Notes

* Keep these **much cleaner** than a decorative illustration.
* Prioritize readable edge definition over micro-detail.
* These should look like parts of the same construction kit.

### Prompt

> Generate 3 matching 32x32 pixel art wall tiles for a top-down industrial sci-fi military interior tileset:
>
> 1. a straight military wall tile
> 2. a military wall top / cap tile
> 3. a military wall corner tile
>    They must clearly look like the same wall system. Use worn dark metal, industrial panel seams, subtle olive military accents, restrained grime and damage, readable edges, modular construction, and strong clarity at gameplay scale. No text, no mockup, no background scene.

---

# Group 3 — Openings and transitions

These should be generated together because they bridge floors and walls.

### Files

* `doorway_military_32.png`
* `threshold_metal_32.png`

### Why grouped

These are both transition pieces and should feel like the same entry system.

### What each should communicate

* `doorway_military_32.png`
  Wall opening / doorframe / reinforced doorway
* `threshold_metal_32.png`
  Floor threshold strip / entry transition / metal sill

### Notes

* `doorway_military_32.png` may need **transparency** if the open portion should be empty.
* `threshold_metal_32.png` should be a **clean floor-transition tile**.

### Prompt

> Generate 2 matching 32x32 pixel art transition tiles for a top-down industrial sci-fi military interior tileset:
>
> 1. a reinforced military doorway tile / doorframe
> 2. a metal threshold floor tile for the doorway transition
>    Both should match a gritty industrial military interior style with dark steel, cool grays, subtle olive accents, restrained wear, and high gameplay readability. The doorway should read clearly as an opening in the wall system. No text, no mockup, no full scene background.

---

# Group 4 — Minimum practical MVP set

If you want the fastest possible usable first pass, do only this batch first.

### Files

* `floor_concrete_32.png`
* `wall_military_32.png`
* `wall_military_top_32.png`
* `doorway_military_32.png`

### Why this set

This is your minimum viable interior kit:

* one base floor
* one wall body
* one wall cap/top
* one opening

### Prompt

> Generate 4 matching 32x32 pixel art tiles for a top-down industrial sci-fi military interior kit:
>
> 1. concrete floor tile
> 2. military wall tile
> 3. military wall top tile
> 4. military doorway tile
>    The set should share one consistent art direction: gritty but readable, cool gray concrete, worn metal, muted olive accents, restrained grime, modular construction, clear gameplay readability, no text, no mockup, no background scene.

---

# Group 5 — Optional props: storage / environmental clutter

These should be on **transparent backgrounds** and are better as a separate prop batch.

## 5A — Storage props

### Files

* `crate_stack_01.png`
* `barrel_01.png`
* `locker_01.png`

### Why grouped

These are all passive storage/environment props.

### Prompt

> Generate 3 separate pixel art props for a top-down industrial sci-fi military interior, each on a transparent background:
>
> 1. stacked crates
> 2. industrial barrel
> 3. military locker
>    Style should match a gritty but readable CUSTODIAN interior: dark steel, muted olive accents, worn surfaces, subtle grime, strong silhouette, clear at gameplay scale, no text.

---

## 5B — Tech / utility props

### Files

* `console_01.png`
* `cable_bundle_01.png`
* `hazard_marker_01.png`

### Why grouped

These are all utility/set-dressing pieces rather than storage.

### Prompt

> Generate 3 separate pixel art props for a top-down industrial sci-fi military interior, each on a transparent background:
>
> 1. small control console
> 2. cable bundle / coiled cables
> 3. hazard marker / industrial warning prop
>    Style should match a gritty CUSTODIAN-like military interior with dark metal, restrained hazard color accents, subtle wear, readable silhouette, and strong gameplay clarity. No text.

---

# Best practical grouping summary

## If you want the cleanest workflow:

### Pass 1

* `floor_concrete_32.png`
* `wall_military_32.png`

### Pass 2

* `floor_panel_32.png`
* `floor_grate_32.png`

### Pass 3

* `wall_military_top_32.png`
* `wall_military_corner_32.png`

### Pass 4

* `doorway_military_32.png`
* `threshold_metal_32.png`

### Pass 5

* `crate_stack_01.png`
* `barrel_01.png`
* `locker_01.png`

### Pass 6

* `console_01.png`
* `cable_bundle_01.png`
* `hazard_marker_01.png`

---

# Strong recommendation on consistency

For best results, do **not** ask for all of these from scratch independently.

Do this instead:

1. Generate `floor_concrete_32` and `wall_military_32` first.
2. Use those as **reference images** for the rest.
3. Then generate the other floor variants.
4. Then generate wall-top and corner.
5. Then doorway/threshold.
6. Then props.

That will keep your palette and material language far more coherent.

---

# Important asset-specific rules

## Floors

* full tile
* seamless edges
* no transparent background required

## Walls

* modular
* readable silhouette
* consistent wall thickness language
* avoid overly noisy detail

## Doorway

* should clearly read as a wall opening
* transparency is okay if needed

## Props

* transparent background
* centered
* no floor shadow baked in unless you intentionally want it

---

# One-line version

If you want the most logical batches, use:

1. **Style anchors:** `floor_concrete_32`, `wall_military_32`
2. **Floor family:** `floor_panel_32`, `floor_grate_32`
3. **Wall family:** `wall_military_top_32`, `wall_military_corner_32`
4. **Transitions:** `doorway_military_32`, `threshold_metal_32`
5. **Storage props:** `crate_stack_01`, `barrel_01`, `locker_01`
6. **Utility props:** `console_01`, `cable_bundle_01`, `hazard_marker_01`

If you want, I can next turn this into a **copy-paste prompt pack** with **one exact prompt per file**.
