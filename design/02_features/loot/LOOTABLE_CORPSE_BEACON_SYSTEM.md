# Lootable Corpse Beacon System

Status: review

## Purpose

Enemy death determines rewards exactly once, but collection delivers them later from the visible corpse. A lootable corpse holds its final death pose, presents a restrained reveal/beacon/ring treatment, and remains until collected. Collection removes the marker and hue while leaving an ordinary corpse for short-lived environmental persistence.

## Authority and lifecycle

`Enemy` owns combat death and the authoritative life state:

```text
ALIVE -> DYING -> LOOTABLE_CORPSE -> EMPTY_CORPSE
                \-----------------> EMPTY_CORPSE
```

- `ALIVE`: normal simulation, targeting, collision, and attacks.
- `DYING`: death bookkeeping runs once, loot is rolled once, live simulation is disabled, and the death animation completes.
- `LOOTABLE_CORPSE`: the final death pose and corpse-bound payload persist; only collection/VFX work remains.
- `EMPTY_CORPSE`: no reward remains; cleanup begins.

The legacy `dead` flag remains as a compatibility view. `life_state` is authoritative for new behavior.

## Payload contract

`EnemyCorpseLoot` owns the physical collection boundary and stores:

```gdscript
{
	"resource_ledger": {&"ruin_scrap": 2},
	"vault_recovery": {&"power_components": 1},
	"legacy_materials": 3,
	"items": [],
}
```

- `resource_ledger` calls `/root/ResourceLedger.add(resource_id, amount)`.
- `vault_recovery` calls `/root/VaultManager.recover_resources(resources)`.
- `legacy_materials` calls `/root/GameState.add_materials(amount)`.
- `items` is reserved and unused in this pass.
- Non-positive and malformed values are removed.
- Loot tables and legacy material fallback are rolled during death, never during collection.
- `EnemyLootCarrier.take_payload()` transfers carried resources into `vault_recovery`; the normal corpse flow does not spawn `stolen_resource_pickup.tscn`.
- A payload can be awarded at most once.

## Visual phases

`loot_corpse_marker.tscn` separates four phases: one-shot reveal, persistent beacon and ground-ring loops, and a one-shot collection collapse. Category hue is applied through `loot_corpse_hue.gdshader` or a controlled modulation fallback. Materials are duplicated per corpse and restored at collection. Presentation never owns loot state or reward delivery.

Default category is muted amber-white. `power`, `signal`, and `anomaly` may tune color, beam scale, and pulse strength without requiring colored sprite variants.

## Source and runtime assets

Source intake belongs under `custodian/content/sprites/_pipeline/aseprite/loot_marker/`. Runtime scenes reference only normalized assets under `custodian/content/sprites/effects/loot_marker/runtime/fx/interaction/`.

Required production strips are 768x96 (8x96 reveal), 384x160 (8x48x160 beacon), 576x160 (6x96x160 collapse), and 576x96 (6x96 ring), with bottom-center alignment, nearest filtering, no mipmaps, `omni`, and no mirroring.

Implementation review on 2026-08-01 found that the four requested 1536x1024 source files were absent from the workspace. Existing reveal and ring runtime strips match the contract; the existing beacon is 9 frames/432x160 and collapse is 8 cells/768x160. Those two files must not be presented as successfully normalized production art until the missing sources are supplied or the intended frame-selection contract is confirmed.

## Corpse simulation and cleanup

On death, Enemy disables AI/state-machine processing, navigation/path state, attack state, live collision/hurt behavior, health/threat UI, targeting groups, and separation participation. Corpse collision is not introduced.

Lootable corpses are never removed by empty-corpse cleanup. Empty corpses remain for at least 8 seconds, then may be freed outside the active camera plus a 96 px margin. They are hard-removed after 45 seconds only when no loot remains. Cleanup is timer/low-frequency driven.

## Persistence and performance

Corpse payloads are scene-local in this pass. They are not serialized across level unload, save/load, or route replacement. Only lootable corpses retain marker animation and collection detection. Empty corpses run no combat simulation and use low-frequency cleanup checks.

## Runtime paths

```text
custodian/game/actors/enemies/enemy.gd
custodian/game/actors/enemies/components/enemy_loot_carrier.gd
custodian/game/actors/enemies/components/enemy_corpse_loot.gd
custodian/game/vfx/loot/loot_corpse_marker.gd
custodian/game/vfx/loot/loot_corpse_marker.tscn
custodian/game/vfx/loot/loot_corpse_marker_frames.tres
custodian/game/vfx/loot/loot_corpse_hue.gdshader
custodian/tools/validation/lootable_corpse_beacon_smoke.gd
```

## Testing contract

Validation must prove roll-once/deliver-once behavior; final-frame persistence; reveal-to-loop sequencing; correct ResourceLedger, VaultManager, and GameState destinations; marker/hue removal; lootable-corpse immunity to cleanup; eventual empty-corpse cleanup; single enemy-director/wave death bookkeeping; and safe authored-frame/humanoid-cutout behavior.

The design status becomes `complete` only after headless import, the dedicated smoke, the existing authored grunt loot smoke, and relevant enemy/wave checks pass. Until exact beacon/collapse source normalization is resolved, visual asset acceptance remains explicitly incomplete.

## Implementation review evidence — 2026-08-01

Passing headless checks:

- `lootable_corpse_beacon_smoke.gd`
- `authored_vault_grunt_loot_marine_smoke.gd`
- `enemy_behavior_vault_smoke.gd`
- `wave_manager_debug_grunt_spawn_gate_smoke.gd`
- `enemy_savage_smoke.gd`
- `sundered_keep_vanguard_seal_acquisition_smoke.gd`

Godot script/class import completes without feature parse errors. The editor import still reports pre-existing Better Terrain/dear-imgui UID/plugin shutdown diagnostics. Status remains `review`, rather than `complete`, because the four source sheets required for authoritative art normalization are absent and the current beacon/collapse frame contracts do not match the requested production strips.
