# Turret System Implementation Notes (2026-03-06)

## Scope Implemented

This runtime pass implemented the requested turret-defense module with:

- `custodian/entities/defense/turret.gd`
- `custodian/entities/defense/turret.tscn`
- `custodian/entities/defense/bullet.gd`
- `custodian/entities/defense/bullet.tscn`

And integrated it into existing map variants:

- `custodian/entities/sector/turret_gunner.tscn`
- `custodian/entities/sector/turret_blaster.tscn`
- `custodian/entities/sector/turret_repeater.tscn`
- `custodian/entities/sector/turret_sniper.tscn`

## Runtime Behavior

### Turret types

`DefenseTurret` implements enum-based archetypes:

- `GUNNER`: range `250`, damage `10`, fire interval `0.6`
- `BLASTER`: range `180`, damage `25`, fire interval `1.1`
- `REPEATER`: range `200`, damage `4`, fire interval `0.2`
- `SNIPER`: range `400`, damage `40`, fire interval `1.8`

### Scene contract

`turret.tscn` node structure:

- `Turret` (`Node2D`)
- `BaseSprite` (`Sprite2D`)
- `Barrel` (`Node2D`)
- `Barrel/BarrelSprite` (`Sprite2D`)
- `RangeArea` (`Area2D`)
- `RangeArea/CollisionShape2D` (`CircleShape2D`)
- `Muzzle` (`Marker2D`)

### Targeting

- Uses `RangeArea` enter/exit callbacks to maintain `enemies_in_range`.
- Chooses nearest valid target.
- Cleans invalid/out-of-range targets each tick to avoid dangling references.

### Power dependency

- Turret checks parent `Sector.has_power` when `power_required = true`.
- If power is unavailable, firing and target lock are disabled and visuals dim.

### Damage/wreck state

- `take_damage()` lowers HP.
- On zero HP: turret disables processing/monitoring, hides barrel, and stays as a wreck (not freed).

## Team Projectile System

### New defense projectile

- `entities/defense/bullet.gd` introduces team-aware hit rules (`player`, `defense`, `enemy`, `neutral`).
- Turret bullets are emitted with `team = "defense"`.

### Shared projectile compatibility

- Updated `entities/projectiles/bullet.gd` to use generic team filtering so player/defense/enemy team logic is consistent.

## Enemy compatibility

`entities/enemies/enemy.gd` now:

- exports `team = "enemy"`
- joins both groups: `enemy` and `enemies`

This keeps compatibility with old and new systems.
