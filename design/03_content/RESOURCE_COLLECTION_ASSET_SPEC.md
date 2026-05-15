# Resource Asset Spec — Starter Tier

Production-ready sprite spec for the seven CUSTODIAN starter resources. Includes exact
pipeline inbox filenames, runtime output paths, frame counts, and per-frame descriptions.

> **Naming convention source:** `content/sprites/_pipeline/README.md`
> - Items: `items__<item_type>__<item_name>__<frames>f__<frame_size>.png`
> - Harvesting nodes: `props__harvesting_nodes__<node_type>__node__<state>__<frames>f__<frame_size>.png`
> - Output paths are relative to `res://content/sprites/`

---

## Shared Standards

### Inventory Icon
```
Size:        32x32
Frame count: 1
Background:  transparent
Style:       dark industrial sci-fi pixel art, readable at 16x16
             no text, no numbers, no logos
```

### Pickup Shimmer
```
Size:        24x24
Layout:      horizontal strip
Frame count: per-resource (4–8)
FPS:         5–10
Background:  transparent
Use:         floating world drop / resource notification
```

### Harvest-Source State Sheet
```
Size:        varies (48x48, 48x64, or 64x48)
Layout:      horizontal strip — 4 states
Frames:      state_0 → state_1 → state_2 → state_3
             (intact → damaged → stripped → depleted)
Background:  transparent
Use:         map object visual state driven by `HarvestableResourceNode.work_remaining`
```

---

## 1. Ruin Scrap

**Gameplay role:** Common generic fabrication feedstock. Source: wreckage piles.
**Visual read:** Bent plating, rusted brackets, broken bolts, copper wire slivers, faded hazard-yellow panel fragment. Uneven triangular scrap pile — not a generic gray rock.

### Inventory Icon
| Field | Value |
|-------|-------|
| Inbox filename | `items__resources__ruin_scrap__1f__32.png` |
| Runtime output | `items/resources/ruin_scrap__icon__1f__32x32.png` |
| Size | 32x32 |
| Frames | 1 |

### Pickup Shimmer
| Field | Value |
|-------|-------|
| Inbox filename | `items__resources__ruin_scrap__pickup__4f__24.png` |
| Runtime output | `items/resources/ruin_scrap__pickup__4f__24x24.png` |
| Layout | horizontal strip — 96×24 total |
| Frames | 0: dim pile → 1: cyan glint on wire → 2: amber glint on yellow stripe → 3: glints fade, cable pixel shifts |
| FPS | 6 |

### Harvest-Source States (wreckage/salvage pile)
| Field | Value |
|-------|-------|
| Inbox filename | `props__harvesting_nodes__wreckage_pile__node__state_0__4f__64.png` |
| Runtime output | `props/harvesting_nodes/wreckage_pile/wreckage_pile__node__state_0__4f__64x48.png` |
| Layout | horizontal strip — 256×48 total |
| Frame size | 64×48 |
| States | 0: Large collapsed machine shell, visible plating, cables, exposed frame<br>1: Several panels removed, interior ribs visible, loose scrap scattered<br>2: Major plates missing, central cavity exposed, bent frame and cables remain<br>3: Flat wreckage outline, mostly empty ribs, tiny dust remains |

### Harvest Hit FX
| Field | Value |
|-------|-------|
| Inbox filename | `effects__resources__ruin_scrap__hit__4f__32.png` |
| Runtime output | `effects/resources/hit/ruin_scrap__hit__4f__32x32.png` |
| Layout | horizontal strip — 128×32 total |
| Frames | white-hot contact pixel, orange sparks, gray chips, fade |

---

## 2. Structural Alloy

**Gameplay role:** Uncommon metal material. Source: alloy veins / broken pylons.
**Visual read:** Fractured piece of buried megastructure — jagged, charcoal metal, cold silver edges, blue-gray internal fractures, clean geometric cut-lines, faint cyan seam glow. Sharp vertical shard cluster.

### Inventory Icon
| Field | Value |
|-------|-------|
| Inbox filename | `items__resources__structural_alloy__1f__32.png` |
| Runtime output | `items/resources/structural_alloy__icon__1f__32x32.png` |
| Size | 32x32 |
| Frames | 1 |

### Pickup Shimmer
| Field | Value |
|-------|-------|
| Inbox filename | `items__resources__structural_alloy__pickup__4f__24.png` |
| Runtime output | `items/resources/structural_alloy__pickup__4f__24x24.png` |
| Layout | horizontal strip — 96×24 total |
| Frames | 0: dark alloy shard, no glow → 1: cyan seam lights along fracture → 2: highlight crawls to upper edge → 3: seam glow recedes |
| FPS | 6 |

### Harvest-Source States (alloy vein / broken pylon)
| Field | Value |
|-------|-------|
| Inbox filename | `props__harvesting_nodes__alloy_vein__node__state_0__4f__48.png` |
| Runtime output | `props/harvesting_nodes/alloy_vein/alloy_vein__node__state_0__4f__48x48.png` |
| Layout | horizontal strip — 192×48 total |
| Frame size | 48×48 |
| States | 0: Jagged alloy seam protruding from cracked concrete or dark stone<br>1: Top shard chipped, fresh bright cut marks visible<br>2: Most high-value protrusions removed, only base seam remains<br>3: Flattened cracked ground with dull metallic streaks |

### Harvest Hit FX
| Field | Value |
|-------|-------|
| Inbox filename | `effects__resources__structural_alloy__hit__5f__32.png` |
| Runtime output | `effects/resources/hit/structural_alloy__hit__5f__32x32.png` |
| Layout | horizontal strip — 160×32 total |
| Frames | white-hot contact, orange sparks, gray chips, fade |

---

## 3. Power Components

**Gameplay role:** Rare salvage for powered systems. Source: dead power nodes / relay boxes.
**Visual read:** Cluster of intact power modules — sealed black ceramic casings, tiny transformer blocks, gold/copper contacts, one cracked but still-lit amber status lens. Rare intact electronics — not generic batteries.

### Inventory Icon
| Field | Value |
|-------|-------|
| Inbox filename | `items__resources__power_components__1f__32.png` |
| Runtime output | `items/resources/power_components__icon__1f__32x32.png` |
| Size | 32x32 |
| Frames | 1 |

### Pickup Shimmer
| Field | Value |
|-------|-------|
| Inbox filename | `items__resources__power_components__pickup__6f__24.png` |
| Runtime output | `items/resources/power_components__pickup__6f__24x24.png` |
| Layout | horizontal strip — 144×24 total |
| Frames | 0: dim module cluster → 1: amber light turns on → 2: amber brightens → 3: tiny cyan diagnostic blink → 4: amber dims → 5: dark idle |
| FPS | 8 |

### Harvest-Source States (dead power node / relay box)
| Field | Value |
|-------|-------|
| Inbox filename | `props__harvesting_nodes__power_node__node__state_0__4f__48.png` |
| Runtime output | `props/harvesting_nodes/power_node/power_node__node__state_0__4f__48x48.png` |
| Layout | horizontal strip — 192×48 total |
| Frame size | 48×48 |
| States | 0: Cracked wall/floor power node with casing, cables, one weak amber light<br>1: Front cover pried open, interior blocks exposed<br>2: Power cores removed, wires hanging, amber light gone<br>3: Empty casing shell, torn cable loops, scorch marks only |

### Harvest Hit FX (optional)
| Field | Value |
|-------|-------|
| Inbox filename | `effects__resources__power_components__hit__5f__24.png` |
| Runtime output | `effects/resources/hit/power_components__hit__5f__24x24.png` |
| Layout | horizontal strip — 120×24 total |
| Frames | electrical pop, sparks, fade |

---

## 4. Resin Clot

**Gameplay role:** Uncommon organic adhesive/sealant material. Source: resin pods / blackwood resin wounds.
**Visual read:** Dark amber-black clot of hardened organic resin — irregular, glossy, with tiny blackwood fibers or fungal strands inside. Sticky, heavy, vaguely alive. Not a potion.

### Inventory Icon
| Field | Value |
|-------|-------|
| Inbox filename | `items__resources__resin_clot__1f__32.png` |
| Runtime output | `items/resources/resin_clot__icon__1f__32x32.png` |
| Size | 32x32 |
| Frames | 1 |

### Pickup Shimmer
| Field | Value |
|-------|-------|
| Inbox filename | `items__resources__resin_clot__pickup__4f__24.png` |
| Runtime output | `items/resources/resin_clot__pickup__4f__24x24.png` |
| Layout | horizontal strip — 96×24 total |
| Frames | 0: resin clot compressed → 1: glossy highlight shifts left → 2: internal dark strand appears to move → 3: highlight settles |
| FPS | 5 |

### Harvest-Source States (resin pod / blackwood wound)
| Field | Value |
|-------|-------|
| Inbox filename | `props__harvesting_nodes__resin_pod__node__state_0__4f__48.png` |
| Runtime output | `props/harvesting_nodes/resin_pod/resin_pod__node__state_0__4f__48x48.png` |
| Layout | horizontal strip — 192×48 total |
| Frame size | 48×48 |
| States | 0: Bulging resin pod or blackwood wound swollen with glossy amber-black resin<br>1: Surface sliced open, resin dripping, exposed darker interior<br>2: Pod collapsed inward, sticky streaks remain<br>3: Dry husk / sealed scar with dull amber residue |

### Harvest Drip FX
| Field | Value |
|-------|-------|
| Inbox filename | `effects__resources__resin_clot__drip__4f__16.png` |
| Runtime output | `effects/resources/hit/resin_clot__drip__4f__16x16.png` |
| Layout | horizontal strip — 64×16 total |
| Frames | resin bead swells, falls, stretches, disappears |

---

## 5. Capacitor Dust

**Gameplay role:** Uncommon electro-reactive dust. Source: ruptured capacitor banks.
**Visual read:** Cracked black ceramic capacitor fragment spilling luminous pale blue-white dust. Powdery but dangerous, tiny static arcs, violet shadow. Feels electrical and industrial — not magic powder.

### Inventory Icon
| Field | Value |
|-------|-------|
| Inbox filename | `items__resources__capacitor_dust__1f__32.png` |
| Runtime output | `items/resources/capacitor_dust__icon__1f__32x32.png` |
| Size | 32x32 |
| Frames | 1 |

### Pickup Shimmer
| Field | Value |
|-------|-------|
| Inbox filename | `items__resources__capacitor_dust__pickup__6f__24.png` |
| Runtime output | `items/resources/capacitor_dust__pickup__6f__24x24.png` |
| Layout | horizontal strip — 144×24 total |
| Frames | 0: dust mound idle → 1: one static arc on left → 2: two bright specks rise → 3: central blue-white spark → 4: sparks scatter outward → 5: dim dust again |
| FPS | 10 |

### Harvest-Source States (ruptured capacitor bank)
| Field | Value |
|-------|-------|
| Inbox filename | `props__harvesting_nodes__capacitor_bank__node__state_0__4f__48.png` |
| Runtime output | `props/harvesting_nodes/capacitor_bank/capacitor_bank__node__state_0__4f__48x48.png` |
| Layout | horizontal strip — 192×48 total |
| Frame size | 48×48 |
| States | 0: Broken capacitor housing leaking visible pale dust<br>1: Dust spill larger, casing cracked further, tiny sparks active<br>2: Most dust removed, only residue in cracks<br>3: Dry broken casing, faint scorch mark, no glow |

### Static Spark FX
| Field | Value |
|-------|-------|
| Inbox filename | `effects__resources__capacitor_dust__hit__6f__24.png` |
| Runtime output | `effects/resources/hit/capacitor_dust__static_pop__6f__24x24.png` |
| Layout | horizontal strip — 144×24 total |
| Frames | tiny blue-white electrical pop, no big explosion |

---

## 6. Signal Filament

**Gameplay role:** Rare delicate signal fiber. Source: broken signal relays / cable bundles.
**Visual read:** Hair-thin coherent signal fiber wound around a small black relay splinter. Thin cyan filament, silver pin contacts, subtle blue-white glow. A coil or loose loop — not a wire bundle. Fragile and precious.

### Inventory Icon
| Field | Value |
|-------|-------|
| Inbox filename | `items__resources__signal_filament__1f__32.png` |
| Runtime output | `items/resources/signal_filament__icon__1f__32x32.png` |
| Size | 32x32 |
| Frames | 1 |

### Pickup Shimmer
| Field | Value |
|-------|-------|
| Inbox filename | `items__resources__signal_filament__pickup__8f__24.png` |
| Runtime output | `items/resources/signal_filament__pickup__8f__24x24.png` |
| Layout | horizontal strip — 192×24 total |
| Frames | 0: dim coil → 1: small cyan pulse begins at lower-left → 2: pulse travels along first loop → 3: pulse reaches top curve → 4: pulse crosses inner coil → 5: pulse exits right → 6: faint afterglow → 7: dim again |
| FPS | 10 |

### Harvest-Source States (broken signal relay / cable bundle)
| Field | Value |
|-------|-------|
| Inbox filename | `props__harvesting_nodes__signal_relay__node__state_0__4f__48.png` |
| Runtime output | `props/harvesting_nodes/signal_relay/signal_relay__node__state_0__4f__48x64.png` |
| Layout | horizontal strip — 192×64 total |
| Frame size | 48×64 |
| States | 0: Broken signal relay with exposed luminous fiber loops threaded through casing<br>1: Panel removed, filament strands visible and glowing<br>2: Most filament pulled out, only torn strands remain<br>3: Dead relay shell, loose dark cables, no coherent glow |

### Signal Pulse FX
| Field | Value |
|-------|-------|
| Inbox filename | `effects__resources__signal_filament__pulse__8f__32.png` |
| Runtime output | `effects/resources/hit/signal_filament__pulse__8f__32x32.png` |
| Layout | horizontal strip — 256×32 total |
| Frames | thin cyan pulse tracing a curved fiber path |

---

## 7. Memory Glass Fragment

**Gameplay role:** Rare archive data substrate relic. Source: shattered archive terminals / command cores.
**Visual read:** Smoky translucent shard of ancient data glass — dark, with frozen internal circuitry and ghostly memory bands. Cold cyan inner lines, violet shadows, white fractured edge glints. The most "legendary" starter resource. Sacred and ominous.

### Inventory Icon
| Field | Value |
|-------|-------|
| Inbox filename | `items__resources__memory_glass_fragment__1f__32.png` |
| Runtime output | `items/resources/memory_glass_fragment__icon__1f__32x32.png` |
| Size | 32x32 |
| Frames | 1 |

### Pickup Shimmer
| Field | Value |
|-------|-------|
| Inbox filename | `items__resources__memory_glass_fragment__pickup__8f__24.png` |
| Runtime output | `items/resources/memory_glass_fragment__pickup__8f__24x24.png` |
| Layout | horizontal strip — 192×24 total |
| Frames | 0: dark glass shard → 1: inner line flickers → 2: ghost band appears near center → 3: bright edge glint climbs upward → 4: internal circuit trace lights → 5: ghost band splits into two pixels → 6: glow fades → 7: dark shard again |
| FPS | 8 |

### Harvest-Source States (archive terminal / command core)
| Field | Value |
|-------|-------|
| Inbox filename | `props__harvesting_nodes__archive_terminal__node__state_0__4f__48.png` |
| Runtime output | `props/harvesting_nodes/archive_terminal/archive_terminal__node__state_0__4f__48x64.png` |
| Layout | horizontal strip — 192×64 total |
| Frame size | 48×64 |
| States | 0: Ruined archive terminal with visible memory glass panel cracked but still glowing<br>1: Outer shell opened, glass substrate shards visible inside<br>2: Most large shards removed, only small glowing fragments remain<br>3: Dead terminal cavity, black screen, glass dust, empty sockets |

### Archive Flicker FX
| Field | Value |
|-------|-------|
| Inbox filename | `effects__resources__memory_glass_fragment__flicker__8f__32.png` |
| Runtime output | `effects/resources/hit/memory_glass_fragment__flicker__8f__32x32.png` |
| Layout | horizontal strip — 256×32 total |
| Frames | cyan/violet glitch flicker, tiny square memory fragments, no text |

### Lore-Unlock Burst (optional)
| Field | Value |
|-------|-------|
| Inbox filename | `effects__resources__memory_glass_fragment__lore_unlock__12f__48.png` |
| Runtime output | `effects/resources/hit/memory_glass_fragment__lore_unlock__12f__48x48.png` |
| Layout | horizontal strip — 576×48 total |
| Frames | shard emits brief halo of square data motes, then collapses inward |

---

## Summary Table

| Resource | Icon | Pickup Shimmer | Source State Sheet | Harvest FX |
|----------|-----:|--------------:|------------------:|-----------:|
| `ruin_scrap` | 32×32, 1f | 24×24, 4f @6fps | 64×48, 4 states | 4f metal spark |
| `structural_alloy` | 32×32, 1f | 24×24, 4f @6fps | 48×48, 4 states | 5f spark/chip |
| `power_components` | 32×32, 1f | 24×24, 6f @8fps | 48×48, 4 states | 5f electrical |
| `resin_clot` | 32×32, 1f | 24×24, 4f @5fps | 48×48, 4 states | 4f drip |
| `capacitor_dust` | 32×32, 1f | 24×24, 6f @10fps | 48×48, 4 states | 6f static pop |
| `signal_filament` | 32×32, 1f | 24×24, 8f @10fps | 48×64, 4 states | 8f pulse |
| `memory_glass_fragment` | 32×32, 1f | 24×24, 8f @8fps | 48×64, 4 states | 8f flicker + 12f lore |

---

## Prompt Template

Use for each asset generation:

```
Create a transparent-background pixel art resource asset for CUSTODIAN, a dark
industrial sci-fi survival tactics game with ruined dark-fantasy atmosphere.
Style: detailed readable pixel art, gritty dead-world salvage, muted industrial
palette, no text, no numbers, no logos, no background.

Asset: [INBOX_FILENAME from spec above]
Canvas: [SIZE from spec above]
Frame count: [N]
Layout: [single icon / horizontal spritesheet]
Description: [from resource entry above]
Animation states: [frame-by-frame description from spec above]
Must be readable at gameplay/UI scale.
```

Example for Memory Glass Fragment icon:

```
Create a transparent-background pixel art resource asset for CUSTODIAN, a dark
industrial sci-fi survival tactics game with ruined dark-fantasy atmosphere.
Style: detailed readable pixel art, gritty dead-world salvage, muted industrial
palette, no text, no numbers, no logos, no background.

Asset: items__resources__memory_glass_fragment__1f__32.png
Canvas: 32x32
Frame count: 1
Layout: single icon
Description: a smoky translucent shard of ancient data glass with cold cyan
internal circuit traces, violet shadows, white fractured edge glints. Sacred
ominous archive relic feel — not ordinary glass. Read as rare and valuable.
Must be readable at 16x16.
```

---

## Pipeline Inbox Structure

All files drop into `content/sprites/_pipeline/inbox/` with a JSON manifest of the same basename:

```
inbox/
  items__resources__ruin_scrap__1f__32.png
  items__resources__ruin_scrap__1f__32.png.json          ← manifest
  items__resources__ruin_scrap__pickup__4f__24.png
  items__resources__ruin_scrap__pickup__4f__24.png.json
  props__harvesting_nodes__wreckage_pile__node__state_0__4f__64.png
  props__harvesting_nodes__wreckage_pile__node__state_0__4f__64.png.json
  effects__resources__ruin_scrap__hit__4f__32.png
  effects__resources__ruin_scrap__hit__4f__32.png.json
  ... (and so on for all 7 resources)
```

Example manifest for the ruin_scrap pickup shimmer:

```json
{
  "source": "items__resources__ruin_scrap__pickup__4f__24.png",
  "mode": "strip",
  "frame_size": [24, 24],
  "outputs": [
    {
      "path": "items/resources/ruin_scrap__pickup__4f__24x24.png",
      "layout": "horizontal_strip",
      "select": { "type": "range", "start": 0, "count": 4 }
    }
  ]
}
```

Example manifest for the wreckage pile state sheet:

```json
{
  "source": "props__harvesting_nodes__wreckage_pile__node__state_0__4f__64.png",
  "mode": "strip",
  "frame_size": [64, 48],
  "outputs": [
    {
      "path": "props/harvesting_nodes/wreckage_pile/wreckage_pile__node__state_0__4f__64x48.png",
      "layout": "horizontal_strip",
      "select": { "type": "range", "start": 0, "count": 4 }
    }
  ]
}
```

---

## Update Targets

After assets are imported and wired, update:
- `custodian/docs/ai_context/CURRENT_STATE.md`
- `custodian/docs/ai_context/FILE_INDEX.md`