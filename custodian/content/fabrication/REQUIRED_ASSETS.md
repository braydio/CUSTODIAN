# Fabrication Pipeline — Required Assets

## Recipes (Defined in `fab_recipes.json`)

| Recipe ID | Label | Category | Cost | Build Time | Output |
|----------|-------|----------|------|------------|--------|
| `barricade_light` | Light Barricade | structure | blackwood:10, ruin_scrap:4 | 4s | build_token -> `barricade_light` |
| `turret_basic` | Basic Turret | defense | ruin_scrap:25, structural_alloy:8, power_components:1 | 7.5s | build_token -> `turret_basic` |
| `power_bank_patch` | Power Bank Patch | power | structural_alloy:6, ruin_scrap:12, power_components:2, capacitor_dust:2 | 6s | build_token -> `power_bank_patch` |
| `capacitor_bank_mk1` | Capacitor Bank Mk I | power | structural_alloy:8, ruin_scrap:14, power_components:2, capacitor_dust:8, resin_clot:1 | 6s | build_token -> `capacitor_bank_mk1` |
| `sensor_pylon_basic` | Basic Sensor Pylon | sensor | ruin_scrap:12, capacitor_dust:4, signal_filament:1 | 8s | build_token -> `sensor_pylon_basic` |
| `archive_sensor_pylon` | Archive Sensor Pylon | archive | structural_alloy:10, ruin_scrap:18, power_components:3, signal_filament:2, memory_glass_fragment:1 | 9s | build_token -> `archive_sensor_pylon` |
| `fabricator_pattern_decode_01` | Fabricator Pattern Decode I | archive | memory_glass_fragment:2, signal_filament:1 | 5s | unlock -> `fabricator_pattern_decode_01` |
| `field_sealant_patch` | Field Sealant Patch | support | resin_clot:4, fiber_moss:3, ruin_scrap:2 | 3.5s | build_token -> `field_sealant_patch` |

---

## Build Token → Scene Mapping

| Build Token | Scene File | Notes |
|-------------|------------|-------|
| `turret_basic` | `res://game/actors/structures/turrets/turret_gunner.tscn` | Existing tactical defense placement. |
| `barricade_light` | `res://game/actors/structures/barricade_light.tscn` | Existing tactical obstacle placement. |
| `capacitor_bank_mk1` | `res://game/infrastructure/structures/capacitor_bank_mk1.tscn` | Creates a timed foundation; storage registers only after commissioning. |

`power_bank_patch` remains a separate, currently non-placeable migration input. It is not an alias for the permanent Capacitor Bank.

**Turret types (from `turret_placement.gd`):**
| Type | Scene | Material Cost | Refund | Token |
|------|-------|--------------|--------|-------|
| gunner | `turret_gunner.tscn` | 10 | 5 | `turret_basic` |
| blaster | `turret_blaster.tscn` | 15 | 8 | — |
| repeater | `turret_repeater.tscn` | 20 | 10 | — |
| sniper | `turret_sniper.tscn` | 25 | 12 | — |

---

## Sprite Assets (Current State + Requirements)

### Turret Sprites

**Current placeholder (all turrets share):**
```
content/sprites/turrets/gunner/turret_sandbag_1frame.png
Size: 96×96 px  |  1 frame
Desc: Sandbag-style base sprite. Temporary placeholder.
Used by: turret.tscn, turret_gunner.tscn, turret_blaster.tscn, turret_repeater.tscn, turret_sniper.tscn
```

**Existing design sprites (not wired to scenes):**
```
content/sprites/turrets/gunner/turret-gunner-design.png
Size: 512×512 px  |  25 frames (5×5 grid) @ 96px/frame
Desc: Gunner turret idle stance from multiple angles/directions.

content/sprites/turrets/gunner/turret-gunner-firing.png
Size: 1024×512 px  |  50 frames (10×5 grid) @ 96px/frame
Desc: Gunner turret firing animation sequence.

content/sprites/turrets/blaster/turret-blaster-design.png
Size: 96×96 px  |  1 frame
Desc: Blaster turret design concept art. Only 1 frame — not an animation sheet.

content/sprites/turrets/blaster/turret-blaster-firing.png
Size: 1024×512 px  |  50 frames (10×5 grid) @ 96px/frame
Desc: Blaster turret firing animation sequence.

content/sprites/turrets/repeater/turret-repeater-design.png
Size: 512×512 px  |  25 frames (5×5 grid) @ 96px/frame
Desc: Repeater turret idle stance from multiple angles/directions.

content/sprites/turrets/repeater/turret-repeater-firing.png
Size: 1024×512 px  |  50 frames (10×5 grid) @ 96px/frame
Desc: Repeater turret firing animation sequence.

content/sprites/turrets/sniper/turret-sniper-design.png
Size: 512×512 px  |  25 frames (5×5 grid) @ 96px/frame
Desc: Sniper turret idle stance from multiple angles/directions.

content/sprites/turrets/sniper/turret-sniper-firing.png
Size: 1024×512 px  |  50 frames (10×5 grid) @ 96px/frame
Desc: Sniper turret firing animation sequence.
```

### Required Sprite Assets (Missing)

#### High Priority — Turret Idle Sprites
Each turret type needs its own idle sprite at **96×96 px, 1 frame**:
| File Path | Size | Frames | Desc |
|----------|------|--------|------|
| `content/sprites/turrets/gunner/turret_gunner_idle.png` | 96×96 | 1 | Gunner turret idle — unique sprite |
| `content/sprites/turrets/blaster/turret_blaster_idle.png` | 96×96 | 1 | Blaster turret idle — unique sprite |
| `content/sprites/turrets/repeater/turret_repeater_idle.png` | 96×96 | 1 | Repeater turret idle — unique sprite |
| `content/sprites/turrets/sniper/turret_sniper_idle.png` | 96×96 | 1 | Sniper turret idle — unique sprite |

#### Medium Priority — Barricade Sprites
| File Path | Size | Frames | Desc |
|----------|------|--------|------|
| `content/sprites/environment/props/barricade/barricade_light_idle.png` | 96×96 | 1 | Light barricade idle sprite |
| `content/sprites/environment/props/barricade/barricade_light_placed.png` | 96×96 | 1 | Barricade placed variant |

#### Low Priority — Turret Firing Animations (Already exist, need wiring)
The firing sprites already exist as 50-frame sheets. Need to slice and wire:
| Source File | Size | Frames | Usage |
|------------|------|--------|-------|
| `turrets/gunner/turret-gunner-firing.png` | 1024×512 | 50 (10×5) | Gunner firing |
| `turrets/blaster/turret-blaster-firing.png` | 1024×512 | 50 (10×5) | Blaster firing |
| `turrets/repeater/turret-repeater-firing.png` | 1024×512 | 50 (10×5) | Repeater firing |
| `turrets/sniper/turret-sniper-firing.png` | 1024×512 | 50 (10×5) | Sniper firing |

---

## Gaps / Missing Assets

### High Priority
1. **Per-turret idle sprites** — all turrets share `turret_sandbag_1frame.png`. Need 4 unique 96×96 idle sprites.
2. **Barricade scene + sprite** — `barricade_light` recipe outputs a build token but no scene/sprite exists.

### Medium Priority
3. **Firing animation wiring** — 50-frame firing sheets exist but turret scenes don't reference them.
4. **Power bank patch** — recipe exists but no placement scene/sprite found.

---

## Resource Types (Canonical)

From `resource_ledger.gd`:
| ID | Source Examples | Used In |
|----|-----------------|---------|
| `blackwood` | blackwood_deadfall, blackwood_root_mass | barricade_light cost |
| `structural_alloy` | alloy_vein, command-core braces | turret_basic, power_bank_patch, archive_sensor_pylon cost |
| `ruin_scrap` | machine_wreckage, power_node, broken_signal_relay | most recipe costs |
| `power_components` | power_node, intact capacitor banks | turret_basic, power_bank_patch, archive_sensor_pylon cost |
| `resin_clot` | fungal_resin_pod, blackwood_resin_wound | field_sealant_patch cost |
| `capacitor_dust` | ruptured_capacitor_bank, dead_drone_shell, shorted_floor_panel | power_bank_patch, sensor_pylon_basic cost |
| `signal_filament` | broken_signal_relay, relay harness | sensor_pylon_basic, archive recipes |
| `memory_glass_fragment` | shattered_archive_terminal, fractured_command_core | archive recipes |
| `fiber_moss` | moss_patch, fungal_resin_pod | field_sealant_patch cost |

---

## Script Files (Core)

| File | Path | Role |
|------|------|------|
| FabPipeline | `autoload/fab_pipeline.gd` | Recipe execution, job lifecycle |
| FabRecipeDatabase | `game/fabrication/fab_recipe_database.gd` | Recipe query helpers |
| FabricatorTerminal | `game/fabrication/fabricator_terminal.gd` | Interaction entry point |
| FabJob | `game/fabrication/fab_job.gd` | Per-job timing/progress |
| ResourceLedger | `autoload/resource_ledger.gd` | Resource tracking |
| TurretPlacement | `game/systems/core/systems/turret_placement.gd` | Turret building/dismantling |
| BuildInventory | (autoload) | Build token storage |

---

## Pipeline Flow

```
Recipe (fab_recipes.json)
    ↓
FabPipeline.try_start_recipe()
    ↓ costs from ResourceLedger
    ↓
FabJob.tick() → progress → complete
    ↓
output_type: build_token → BuildInventory.add(output_id)
output_type: unlock → unlock_completed signal
output_type: resource → ResourceLedger.add(output_id)
    ↓
BuildInventory consumed by TurretPlacement
```
