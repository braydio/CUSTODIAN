# Authored Vault Grunt Loot Marine Wiring

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-06-02
- Created: 2026-06-02
- Last updated: 2026-06-02

## Task

Place a first authored vault room in the active gothic compound map, begin the enemy grunt loot table using practical CUSTODIAN salvage resources, and wire `enemy_marine` with its full idle suite from a stable runtime directory.

## Authority

- Root routing: `/home/braydenchaffee/Projects/CUSTODIAN/AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Relevant design/runtime docs: `design/02_features/enemy_objective/GRUNT_COMBAT_PROFILE.md`, `design/02_features/animation/ENEMY_GRUNT_RUNTIME_WIRING.md`, `design/02_features/resource_fabrication/RESOURCE_FABRICATION_PIPELINE.md`

## Work Surface

- Expected changes:
  - `custodian/game/world/gothic_compound/gothic_compound_map.gd`
  - `custodian/game/actors/enemies/enemy.gd`
  - `custodian/game/enemies/procgen/grunt_animation_library.gd`
  - `custodian/game/actors/enemies/enemy_marine.tscn`
  - `design/02_features/enemy_objective/GRUNT_LOOT_TABLE.md`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
- Expected reads:
  - `custodian/autoload/resource_ledger.gd`
  - `custodian/game/actors/storage/vault_storage.tscn`
  - `custodian/content/sprites/enemies/enemy_marine/runtime/body/`

## Constraints

- Keep vault storage assets in their permanent runtime home; do not scatter new vault art paths.
- Use the existing `ResourceLedger` ids for lore salvage instead of inventing a parallel resource namespace.
- Preserve the old generic parts pickup fallback when `ResourceLedger` is unavailable.
- The marine currently has idle runtime strips only; movement and combat suites are out of scope unless source slices are promoted later.

## Implementation Plan

1. Add an authored vault room node to `GothicCompoundMap` after successful compound generation.
2. Add a data-driven enemy loot table path and configure the grunt table for `ruin_scrap`, `structural_alloy`, and rare `power_components`.
3. Extend the existing enemy animation library to build `enemy_marine` 8-direction idle frames from runtime strips.
4. Add `enemy_marine.tscn` as a live scene using the custom marine animation set.
5. Update design/context docs and run focused Godot validation.

## Acceptance

- Gothic compound map creates a named authored vault room containing real `VaultStorage` instances.
- Grunts have a loot table that awards CUSTODIAN salvage resources through `ResourceLedger` when available.
- The old parts pickup still spawns when typed loot cannot be awarded.
- `enemy_marine.tscn` loads and can idle in all eight directions from `content/sprites/enemies/enemy_marine/runtime/body`.
- Validation commands complete without script parse/load failures.

## Notes

- No pre-existing practical salvage X grunt drop spec was found in `design/`; this packet will add the first conservative table.
- Missing marine non-idle runtime body/FX sheets should be tracked if/when the marine is promoted into wave composition.

## Completion Notes

- Implemented: added `AuthoredVaultRoom` placement to `GothicCompoundMap` with three real `VaultStorage` caches and `VaultEnemyExit`; added data-driven typed loot table exports to `Enemy`; configured `enemy_grunt.tscn` with the lore-specced `practical_salvage_x_grunt` table; documented that table in `design/02_features/enemy_objective/GRUNT_LOOT_TABLE.md`; added new provenance/salvage ids to `ResourceLedger` and `resource_defs.json`; extended `GruntAnimationLibrary` and `Enemy` to support `enemy_marine`; added `enemy_marine.tscn`; wired `marine_scene` / `"marine"` through `WaveManager`, `EnemyDirector`, `EnemyFactory`, and `scenes/game.tscn`; tracked missing marine non-idle production assets in both `REQUIRED_ASSETS.md` copies.
- Validated: `godot --headless --path custodian --script res://tools/validation/authored_vault_grunt_loot_marine_smoke.gd` passed; `godot --headless --path custodian --quit` passed with the existing shutdown ObjectDB/resource-in-use warnings.
- Deferred: physical typed loot pickup art/UI, marine run/melee/stagger/death suites, marine-specific behavior profile, vault room collision/door art pass, and in-editor readability tuning.

## Next Steps

- Next action: promote marine movement/combat sheets into `content/sprites/enemies/enemy_marine/runtime/` and replace idle fallback movement/attack presentation.
- Best starting files: `custodian/game/enemies/procgen/grunt_animation_library.gd`, `custodian/game/actors/enemies/enemy_marine.tscn`, `custodian/game/world/gothic_compound/gothic_compound_map.gd`.
- Validation to run: `godot --headless --path custodian --script res://tools/validation/authored_vault_grunt_loot_marine_smoke.gd`, `godot --headless --path custodian --quit`.
