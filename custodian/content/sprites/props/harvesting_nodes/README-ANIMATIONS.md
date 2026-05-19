# Harvesting Node Animation Guide

Reference for player harvest animations, node state sheets, and per-resource hit FX.

---

## Timing Baseline

| Phase | Duration |
|-------|----------|
| Total action length | 0.35–0.55s |
| Impact frame | ~40% into anim |
| Node shake | 0.08–0.12s |
| FX sheet duration | 4–8 frames @ 12–14 FPS |

State progression per resource: `state_0 → state_1 → state_2 → state_3 (depleted)`

---

## Player Harvest Animations (4 reusable)

All 64x64, south/east-facing OK for V1.

| Animation | Used For | Frames | FPS |
|-----------|----------|--------|-----|
| `harvest_gather` | resin_clot, fiber_moss, small loose items | 5 | 10–12 |
| `harvest_cut` | blackwood_deadfall, resin pod, root mass | 6 | 12 |
| `harvest_mine` | alloy_vein, collapsed pylon, buried rail, bulkhead | 7 | 12 |
| `harvest_salvage` | machine shell, power node, capacitor bank, relay, archive terminal | 6 | 10 |

Inbox filenames (drop into `_pipeline/inbox/`):

```
operator__body__interaction__harvest_gather__s__5f__64.png
operator__body__interaction__harvest_cut__s__6f__64.png
operator__body__interaction__harvest_mine__s__7f__64.png
operator__body__interaction__harvest_salvage__s__6f__64.png
```

---

## Standard Size

All node state sheets and node idle FX: **96×96** (consistent with blackwood_deadfall). Hit FX remain at 32×32 as standalone effects.

### Existing: Blackwood Deadfall → Timber

> **Note:** Currently has 5-frame idle; will be updated to 6 frames (6f).

| Sheet | Size | Frames | Inbox filename | Runtime output |
|-------|------|--------|---------------|----------------|
| Idle | 96×96 | 6 | `props__harvesting_nodes__blackwood_deadfall__node__idle__6f__96.png` | `props/harvesting_nodes/blackwood_deadfall/blackwood_deadfall__node__idle__6f__96.png` |
| Depleted | 96×96 | 1 | `props__harvesting_nodes__blackwood_deadfall__node__depleted__1f__96.png` | `props/harvesting_nodes/blackwood_deadfall/blackwood_deadfall__node__depleted__1f__96.png` |

---

### 1. Wreckage Pile → Ruin Scrap

| Sheet | Size | Frames | Inbox filename | Runtime output |
|-------|------|--------|---------------|----------------|
| State sheet | 96×96 | 4 | `props__harvesting_nodes__wreckage_pile__node__state_0__4f__96.png` | `props/harvesting_nodes/wreckage_pile/wreckage_pile__node__state_0__4f__96x96.png` |
| Hit FX | 32×32 | 5 | `effects__resources__ruin_scrap__hit__5f__32.png` | `effects/resources/hit/ruin_scrap__hit__5f__32x32.png` |

**States:** intact shell → panel pried off → frame exposed, cables hanging → stripped ribs and debris  
**FX:** white contact pixel → orange/cyan sparks → gray chips scatter → sparks fade → smoke

---

### 2. Alloy Vein → Structural Alloy

| Sheet | Size | Frames | Inbox filename | Runtime output |
|-------|------|--------|---------------|----------------|
| State sheet | 96×96 | 4 | `props__harvesting_nodes__alloy_vein__node__state_0__4f__96.png` | `props/harvesting_nodes/alloy_vein/alloy_vein__node__state_0__4f__96x96.png` |
| Hit FX | 32×32 | 5 | `effects__resources__structural_alloy__hit__5f__32.png` | `effects/resources/hit/structural_alloy__hit__5f__32x32.png` |

**States:** jagged seam → top shard chipped → protrusions removed → flat dull streaks  
**FX:** white-hot contact → orange sparks + blue-white chip → gray shards fly → dust fades

---

### 3. Power Node → Power Components

| Sheet | Size | Frames | Inbox filename | Runtime output |
|-------|------|--------|---------------|----------------|
| State sheet | 96×96 | 4 | `props__harvesting_nodes__power_node__node__state_0__4f__96.png` | `props/harvesting_nodes/power_node/power_node__node__state_0__4f__96x96.png` |
| Idle pulse | 96×96 | 6 | `props__harvesting_nodes__power_node__fx__idle__6f__96.png` | `effects/harvesting_nodes/power_node/power_node__fx__idle__6f__96x96.png` |
| Hit FX | 32×32 | 6 | `effects__resources__power_components__hit__6f__32.png` | `effects/resources/hit/power_components__hit__6f__32x32.png` |

**States:** closed cracked node → cover pried open → inner modules removed → empty casing  
**Idle pulse:** amber indicator brightens → cyan side spark → flicker → fade → repeat  
**FX:** casing contact glint → cyan arc → amber spark + smoke → extracted component glint → collapse → fade

---

### 4. Resin Pod → Resin Clot

| Sheet | Size | Frames | Inbox filename | Runtime output |
|-------|------|--------|---------------|----------------|
| State sheet | 96×96 | 4 | `props__harvesting_nodes__resin_pod__node__state_0__4f__96.png` | `props/harvesting_nodes/resin_pod/resin_pod__node__state_0__4f__96x96.png` |
| Idle drip | 96×96 | 4 | `props__harvesting_nodes__resin_pod__fx__drip_idle__4f__96.png` | `effects/harvesting_nodes/resin_pod/resin_pod__fx__drip_idle__4f__96x96.png` |
| Hit FX | 32×32 | 5 | `effects__resources__resin_clot__hit__5f__32.png` | `effects/resources/hit/resin_clot__hit__5f__32x32.png` |

**States:** swollen glossy pod → cut open leaking → collapsed drained → dry husk  
**Idle drip:** amber highlight grows → resin bead lowers 1px → bead snaps back  
**FX:** dark cut line → amber splash → sticky strands stretch → droplets fall → glossy residue

---

### 5. Capacitor Bank → Capacitor Dust

| Sheet | Size | Frames | Inbox filename | Runtime output |
|-------|------|--------|---------------|----------------|
| State sheet | 96×96 | 4 | `props__harvesting_nodes__capacitor_bank__node__state_0__4f__96.png` | `props/harvesting_nodes/capacitor_bank/capacitor_bank__node__state_0__4f__96x96.png` |
| Static idle | 96×96 | 6 | `props__harvesting_nodes__capacitor_bank__fx__static_idle__6f__96.png` | `effects/harvesting_nodes/capacitor_bank/capacitor_bank__fx__static_idle__6f__96x96.png` |
| Hit FX | 32×32 | 6 | `effects__resources__capacitor_dust__hit__6f__32.png` | `effects/resources/hit/capacitor_dust__hit__6f__32x32.png` |

**States:** leaking dust → spill disturbed, sparks → most dust scooped → dry casing  
**Static idle:** faint glow → blue spark → motes rise → white pop → dim → no spark  
**FX:** tool contact → blue-white dust puff → static arcs → motes rise → arcs vanish → dust settles

---

### 6. Signal Relay → Signal Filament

| Sheet | Size | Frames | Inbox filename | Runtime output |
|-------|------|--------|---------------|----------------|
| State sheet | 96×96 | 4 | `props__harvesting_nodes__signal_relay__node__state_0__4f__96.png` | `props/harvesting_nodes/signal_relay/signal_relay__node__state_0__4f__96x96.png` |
| Signal pulse idle | 96×96 | 8 | `props__harvesting_nodes__signal_relay__fx__pulse_idle__8f__96.png` | `effects/harvesting_nodes/signal_relay/signal_relay__fx__pulse_idle__8f__96x96.png` |
| Hit FX | 32×32 | 8 | `effects__resources__signal_filament__hit__8f__32.png` | `effects/resources/hit/signal_filament__hit__8f__32x32.png` |

**States:** relay glowing → panel open, strands exposed → strands pulled → dead shell  
**Idle pulse:** base pulse → climbs strand → reaches loop → crosses coil → flickers → afterglow → dim  
**FX:** cyan contact → filament tenses → line pulls → pulse travels → glint → strand snaps → blue motes → fade

---

### 7. Archive Terminal → Memory Glass Fragment

| Sheet | Size | Frames | Inbox filename | Runtime output |
|-------|------|--------|---------------|----------------|
| State sheet | 96×96 | 4 | `props__harvesting_nodes__archive_terminal__node__state_0__4f__96.png` | `props/harvesting_nodes/archive_terminal/archive_terminal__node__state_0__4f__96x96.png` |
| Archive flicker idle | 96×96 | 8 | `props__harvesting_nodes__archive_terminal__fx__flicker_idle__8f__96.png` | `effects/harvesting_nodes/archive_terminal/archive_terminal__fx__flicker_idle__8f__96x96.png` |
| Hit FX | 32×32 | 8 | `effects__resources__memory_glass_fragment__hit__8f__32.png` | `effects/resources/hit/memory_glass_fragment__hit__8f__32x32.png` |
| Lore-unlock burst (optional) | 48×48 | 12 | `effects__resources__memory_glass_fragment__lore_unlock__12f__48.png` | `effects/resources/hit/memory_glass_fragment__lore_unlock__12f__48x48.png` |

**States:** cracked terminal glowing → casing open, glass exposed → shards removed → black screen  
**Flicker idle:** faint glow → cyan line → violet ghost band → glow cuts → motes appear → edge glints → fade → dead  
**FX:** contact glint → crack brightens → shard lifts → cyan ghost trace → violet motes scatter → shard flashes → motes collapse → fade  
**Lore burst:** internal line wakes → violet halo → motes orbit → halo brightens → white flash → ring forms → collapses → dim → motes fall → afterimage → clear

---

## State Progression Formula

```
state_index = min(3, floor(harvest_progress_ratio * 3))
```

For a 3-hit node:
```
0 hits → state 0
1 hit  → state 1
2 hits → state 2
3 hits → state 3 (depleted)
```
