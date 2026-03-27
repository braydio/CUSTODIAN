# Asset Layout and Naming Convention

Last updated: 2026-03-10

## Scope

This convention covers current Godot runtime assets in `res://assets/` with a concrete migration applied to operator animation textures referenced by:

- `res://entities/operator/operator.tscn`

## Standard Layout

```text
assets/
  sprites/
    <entity>/
      runtime/            # files directly loaded by scenes/resources
        attack/
        idle/
        move/
        fx/
      source/             # editable source files (.aseprite, .xcf, .psd, .gif)
      archive/            # deprecated but retained files not used by runtime
    enemies/
    raw/
  tiles/
  raw/
```

## Naming Rules

- Prefix by owner: `op_` (operator), `drone_` (drone), etc.
- Use role-oriented names: `*_sheet`, `*_frame`, `*_atlas`.
- Use zero-padded indices for ordered frame sets: `_01`, `_02`, ... `_13`.
- Use lowercase snake_case only.

## Operator Runtime Assets (Linked)

These files are now the canonical runtime-linked operator animation textures:

```text
res://assets/sprites/operator/runtime/attack/op_attack_combo_01.png
res://assets/sprites/operator/runtime/attack/op_attack_combo_02.png
res://assets/sprites/operator/runtime/attack/op_attack_combo_03.png
res://assets/sprites/operator/runtime/attack/op_attack_combo_04.png
res://assets/sprites/operator/runtime/attack/op_attack_combo_05.png
res://assets/sprites/operator/runtime/attack/op_attack_combo_06.png
res://assets/sprites/operator/runtime/attack/op_attack_combo_07.png
res://assets/sprites/operator/runtime/attack/op_attack_combo_08.png
res://assets/sprites/operator/runtime/attack/op_attack_combo_09.png
res://assets/sprites/operator/runtime/attack/op_attack_combo_10.png
res://assets/sprites/operator/runtime/attack/op_attack_combo_11.png
res://assets/sprites/operator/runtime/attack/op_attack_combo_12.png
res://assets/sprites/operator/runtime/attack/op_attack_combo_13.png
res://assets/sprites/operator/runtime/idle/op_idle_right_sheet.png
res://assets/sprites/operator/runtime/idle/op_idle_alt_sheet_a.png
res://assets/sprites/operator/runtime/idle/op_idle_alt_sheet_b.png
res://assets/sprites/operator/runtime/idle/op_idle_up_sheet_a.png
res://assets/sprites/operator/runtime/idle/op_idle_up_sheet_b.png
res://assets/sprites/operator/runtime/idle/op_idle_up_sheet_c.png
res://assets/sprites/operator/runtime/move/op_dash_sheet.png
res://assets/sprites/operator/runtime/move/op_walk_down_sheet.png
res://assets/sprites/operator/runtime/move/op_walk_right_sheet.png
res://assets/sprites/operator/runtime/move/op_walk_up_sheet_a.png
res://assets/sprites/operator/runtime/move/op_walk_up_sheet_b.png
```

## Operator Source Files (Moved)

Moved to `res://assets/sprites/operator/source/`:

- `Sprite-0001.aseprite`
- `Sprite-0003.aseprite`
- `Sprite-0003.gif`
- `custodian_idle_up.aseprite`
- `idle-alternative-spritemap.aseprite`
- `idle_up_alternative_spritesmap.aseprite`
- `walk_right_custodian.aseprite`
- `white-sprite-idle.aseprite`

## Notes

- Phase-2 cleanup completed: non-runtime/non-source operator files were moved to `res://assets/sprites/operator/archive/`.
- One compatibility exception remains at top-level:
  - `res://assets/sprites/operator/sprite-map-custodian-red.png`
  - Kept in place because it is referenced by `res://entities/custodian/custodian.tscn`.

## Effects Runtime Assets (Linked)

Combat impact effects now follow the same runtime/source split:

```text
res://assets/sprites/effects/runtime/hit_spark/hit_spark_4f_64.png
res://assets/sprites/effects/runtime/block_spark/block_spark_4f_128.png
res://assets/sprites/effects/source/hit_spark/*
res://assets/sprites/effects/source/block_spark/*
```

Runtime scenes:

- `res://entities/effects/impact_spark.tscn` (uses all 4 hit-spark frames)
- `res://entities/effects/block_spark.tscn` (uses first 2 of 4 block-spark frames)

## Enemy Drone Runtime Additions

Runtime-linked reaction/attack-readability strips:

```text
res://assets/sprites/enemies/drone/runtime/idle/drone_idle.png
res://assets/sprites/enemies/drone/runtime/attack/drone_firing.png
res://assets/sprites/enemies/drone/runtime/reaction/drone_hit.png
res://assets/sprites/enemies/drone/runtime/reaction/drone_stagger.png
res://assets/sprites/enemies/drone/runtime/attack/drone_attack_windup.png
```

These are currently registered into drone `SpriteFrames` at runtime by:

- `res://entities/enemies/enemy.gd`

## Assets Directory Audit Snapshot

Current `res://assets/` file counts:

- `png`: 118
- `import`: 118
- `aseprite`: 7
- `gif`: 1
- `xcf`: 2
- `tres`: 3

Immediate cleanup target:

- Operator legacy variants in `res://assets/sprites/operator/` not referenced by runtime scenes can be moved to `archive/` after final animation lock.
