# Projectile VFX System

Status: in_progress
Runtime target: Godot 4.x
Primary runtime files:

- `custodian/game/actors/projectiles/bullet.gd`
- `custodian/game/actors/projectiles/bullet.tscn`
- `custodian/game/vfx/one_shot_animated_vfx.gd`

## Contract

Projectile VFX are presentation-only. Bullet movement, swept collision, damage, range falloff, team filtering, and terrain-ballistics authority stay in `bullet.gd` and are not driven by animation frames.

Travel art points east/right in source art. The projectile node rotates to `direction.angle()`, so no north/south/diagonal projectile sheets are required.

Impact effects are separately spawned one-shot scenes at the collision point. They are not children of the projectile, do not apply damage, and free themselves when their animation finishes.

## Carbine MK1 Slice

The Carbine MK1 uses the existing generic bullet scene with weapon-data presentation assignment:

- projectile scene: `res://game/actors/projectiles/bullet.tscn`
- travel frames: `res://assets/resources/vfx/weapons/carbine_mk1/carbine_mk1_projectile_travel_loop_01_frames.tres`
- hard impact scene: `res://game/vfx/weapons/carbine_mk1/carbine_mk1_impact_hard_vfx.tscn`
- impact frames: `res://assets/resources/vfx/weapons/carbine_mk1/carbine_mk1_impact_hard_01_frames.tres`

The current repository production PNGs are under `res://content/sprites/effects/weapons/carbine_mk1/`, not the requested `res://assets/sprites/...` directory:

- `carbine_mk1_projectile_travel_loop_01.png`
- `carbine_mk1_projectile_impact_hard_01.png`

Current dimension drift is intentionally warned by validation:

- requested travel sheet: `144x16`, current sheet: `96x32`
- requested impact sheet: `384x64`, current sheet: `576x96`

The resources keep the requested frame regions so the final production replacement can land without code changes.

## Extension Path

Future weapons should add weapon-data fields instead of new projectile physics scripts:

- `projectile.visual_sprite_frames`
- `projectile.visual_animation`
- `projectile.visual_scale`
- `projectile.impact_scene`

Future impact families should use separate one-shot scenes for flesh, shield, stone, metal, and energy impacts. Selection should remain data-driven and should not add weapon-specific string checks inside `bullet.gd`.
