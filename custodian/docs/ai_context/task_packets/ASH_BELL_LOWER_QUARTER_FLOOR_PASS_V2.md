# Ash-Bell Lower Quarter Floor Pass V2

## Status

**Spec-only, blocked on master art.** As of 2026-09-02 no Gothic-futurist
floor source master exists anywhere in the repo (`asset_drop/inbox`,
`asset_drop/source_work`). The live runtime still preloads
`custodian/content/tiles/ash_bell/lower_quarter/meridian_civic_floor_atlas_512.png`
(the original tiled-plaza atlas) via `MeridianCivicArtPresenter.FLOOR`, and
every Lower Quarter district draws from it.

Walls and props already have Gothic-futurist masters in
`custodian/asset_drop/source_work/lower_quarter_region/`
(`lower_quarter_gothic_scifi_walls__master__1448x1086.png`,
`lower_quarter_gothic_scifi_props__master__1448x1086.png`). Floor does not,
and is the one piece still missing before the district reads as authored
rather than showroom.

## Why floor comes first

In-engine review of the current Lower Quarter shows a uniformly tiled
32px-seam plaza: every seam is equally readable, the dark plaza reads as
near-uniform, the grey route reads pasted on top, and there is no
architectural floor hierarchy telling the player where buildings, gates,
plazas, alleys, transit routes, or containment infrastructure belong.
Placing the new Gothic walls on top of that floor now would be decorating
graph paper. Sequencing is therefore:

```
Floor V2 -> gameplay-scale floor review -> wall structural pass -> prop dressing pass
```

Do not resume wall/prop integration concurrently with this pass — judge each
step against a foundation that is not already known to be temporary.

## Source contract

```
custodian/asset_drop/source_work/lower_quarter_region/
    lower_quarter_gothic_scifi_floor__master__1024x1024.png
```

- 1024x1024, RGBA, single frame
- 16x16 grid, 64x64 source px per cell
- downconvert each cell **independently** at exactly 0.5x (crop-then-resize,
  never resize-then-crop, so no cell can bleed into its neighbor's seam) into:

```
custodian/content/tiles/ash_bell/lower_quarter/
    lower_quarter_gothic_scifi_floor_atlas_512.png
```

- 512x512, 16x16 grid, 32x32 runtime px/cell. Source `[x,y]` maps directly to
  runtime `[x,y]` — no presenter coordinate migration, no gameplay change.
- Tooling: `custodian/tools/art/build_lower_quarter_floor_atlas_v2.py` (added
  by this packet) performs the crop-and-downscale once the master exists.

## Cell contract — addresses are load-bearing, do not move them

Every cell below is read by `MeridianCivicArtPresenter` and asserted by
`ash_bell_lower_quarter_floor_atlas_smoke.gd` via
`MeridianCivicArtPalette`. Repaint what each address *looks like*; do not
repaint what it *means* or where it lives.

| Const (`meridian_civic_art_palette.gd`) | Cells `(x,y)` | Current meaning | V2 visual direction |
|---|---|---|---|
| `SRC_CIVIC_LIGHT` / `BASE_CIVIC_FIELD` | `(0,0) (1,0) (2,0) (3,0) (10,0) (11,1) (12,1) (0,2)` | normal civic paving, clean | graphite-black composite slab, subtle seams, restrained axial geometry worked into the paving |
| `BASE_CIVIC_STRUCTURAL` | `(8,1) (10,2)` | normal paving with authored structural cutout | same slab family, cutout preserved for whatever sits on top |
| `SRC_CIVIC_LIGHT_WORN_A/B` / `WORN_CIVIC` | `(4,0) (5,0) (6,0) (7,0)` | normal paving, worn variant (~12% mix) | same slab, weathered: hairline cracks, dulled bronze channel, foot-worn sheen |
| `SRC_CIVIC_DARK` | `(8,0)` | dark plaza field | dark composite slab, iron expansion channel, narrow drainage cut, recessed technical access track |
| `SRC_CIVIC_DARK_WORN` | `(10,0)` | dark plaza, worn variant | same, weathered — do not let this or the base dark read as flat/uniform at tiled scale |
| `SRC_MARKET_BASE` | `(1,8)` | market/public ground | older, warmer civic slab — more stone character than the civic-light family |
| `SRC_MARKET_WORN_A/B` | `(2,8) (5,8)` | market ground, worn | warm slab, patch repair, decorative iron channel |
| `SRC_MARKET_DAMAGE_A/B` | `(3,9) (10,9)` | market ground, damaged | occasional damaged inset — cracked slab or lifted panel, not blanket rubble |
| `MARKET_GROUND` (full pool) | rows 8–9, all 16 cols except `(14,9)` | market/public ground field | warm large civic slabs, decorative iron channels, restrained patching |
| `SRC_ROAD_GREY` | `(2,5)` | personnel/arrival route base | industrial transit composite, embedded guide strip, subtle lane marking |
| `SRC_ROAD_DARK` | `(11,5)` | collapse/detour/arcade route base | worn dark transit composite, maintenance channel, heavy drainage, cracked containment-era repair |
| `ROAD_BASE` (full pool) | `(0,5) (1,5) (2,5) (3,5) (11,5) (12,5)` | road field | same industrial family as the two named cells above |
| `SRC_ROAD_LINE_H` | `(1,4)` | route marking, single line | brass/embedded status-strip line, not painted stripe |
| `SRC_ROAD_LINE_H_DOUBLE` | `(2,4)` | route marking, double line | brass double status strip |
| `SRC_ROAD_LINE_V_DASH` | `(5,4)` | route marking, dashed | dashed maintenance-track inlay |
| `SRC_ROAD_LINE_V_DOUBLE` | `(6,4)` | route marking, double vertical | double inlay variant |
| `SRC_ROAD_CROSSWALK_H` | `(0,4)` | crosswalk marking | threshold band motif, not a crosswalk stripe set |
| `SRC_ROAD_ARROW_N` | `(10,4)` | directional arrow | pointed-intersection directional motif |
| `SRC_ROAD_DASH_H` | `(12,4)` | dashed marking | dashed inlay variant |
| `TRANSIT_MARKINGS` (full pool) | rows 4–5, `(0..15,4)` + `(4..10,5) (13..15,5)` | route marking field | embedded cyan/amber status-strip family, functionally identical overlays |
| `CIVIC_ACCENTS` | row 7, `(0..12,7)` | civic ornament/accent overlay | long axial stone/metal inlay, pointed intersection motif, monumental-threshold-band fragments |
| `SERVICE_DETAILS` (overlay only) | `(9,2) (9,6) (14,10)` | rare overlay detail | small damage family: cracked slab, exposed conduit, ruptured drain — used sparingly, never as a base field |
| `TECHNICAL_DETAILS` (overlay only) | `(1,12) (4,12) (7,12) (2,13) (6,13) (10,13)` | rare overlay detail | scorched seam, lifted panel, collapsed-edge transition — sparingly, overlay only |

`SERVICE_DETAILS` and `TECHNICAL_DETAILS` are explicitly excluded from every
full-field ground pool in the current code (see the comment at
`meridian_civic_art_palette.gd:70-71`) — keep that exclusion. The "small
damage family" belongs there, not smeared across `BASE_CIVIC_FIELD` or
`ROAD_BASE`.

## Visual direction (repeated from review, condensed)

Think future urban civil engineering built by a civilization with Gothic
architectural taste — not Gothic wallpaper.

- **Normal civic ground**: large graphite-black composite slabs, subtle
  seams, occasional bronze/iron expansion channels, narrow drainage cuts,
  recessed technical access tracks, restrained pointed/axial geometry.
- **Gothic character comes from**: long axial stone/metal inlays, pointed
  intersection motifs, dark iron drainage tracery, monumental threshold
  bands, ornamental-but-functional service channels, brass structural
  seams, embedded cyan/amber status strips — not crosses or cathedral-floor
  ornament everywhere.
- **Road family**: worn dark transit composite, embedded guide strips,
  maintenance channels, subtle future lane markings, heavy drainage,
  cracked containment-era repairs.
- **Market/public family**: older and warmer — larger civic slabs, more
  stone/composite character, decorative iron channels, patch repairs,
  occasional damaged insets.
- **Damage family** (`SERVICE_DETAILS` + `TECHNICAL_DETAILS` only): cracked
  slab, lifted panel, scorched seam, exposed conduit, ruptured drain,
  collapsed-edge transition.

**Most important visual rule**: neighboring 32px cells must be edge-compatible
so borders do not all announce themselves equally. From gameplay camera
distance the read should be a *district composition* — broad dark civic
field, embedded service axis, threshold band, plaza — not a debug grid.
Kill the `┼─┼─┼` checkerboard read the current atlas produces.

## Runtime isolation (apply only once the atlas exists on disk)

Do not add this preload before the PNG exists — a `preload()` of a missing
resource breaks the scene at parse time. Once
`lower_quarter_gothic_scifi_floor_atlas_512.png` is in
`custodian/content/tiles/ash_bell/lower_quarter/`:

```gdscript
const FLOOR := preload(
    "res://content/tiles/ash_bell/lower_quarter/meridian_civic_floor_atlas_512.png"
)
const LOWER_QUARTER_FLOOR_V2 := preload(
    "res://content/tiles/ash_bell/lower_quarter/lower_quarter_gothic_scifi_floor_atlas_512.png"
)


func _floor_texture() -> Texture2D:
    if district == &"lower_quarter":
        return LOWER_QUARTER_FLOOR_V2
    return FLOOR
```

Replace floor draw calls with `_floor_texture()`. Do not touch the shared
`FLOOR` constant directly — Station IX and West Gate still read it today.

## Sequence once unblocked

1. Master lands in `asset_drop/source_work/lower_quarter_region/` (or
   `asset_drop/inbox/meridian_civic_floor/`) under the exact filename above.
2. Run `custodian/tools/art/build_lower_quarter_floor_atlas_v2.py` to produce
   the runtime atlas.
3. Wire `_floor_texture()` per above; district-scope it to `lower_quarter`
   only.
4. Extend `ash_bell_lower_quarter_floor_atlas_smoke.gd` with
   district-scoped source-cell assertions against the new atlas.
5. Gameplay-scale visual review (Moment Forge / real camera) before any wall
   or prop integration resumes — do not call this pass complete on headless
   validation alone.

## Blocker

No image-generation tool exists in this pipeline (`art_agent` reviews,
normalizes, and QAs already-painted source; it does not paint). The master
must be produced the same way the wall/prop Gothic masters were and dropped
in at the path above.

## Deferred

Wall structural pass and prop dressing pass — explicitly paused until this
lands and is visually reviewed at gameplay scale, per the sequencing rule
above.
