# 8-BIT PLAYER WEAPON SYSTEM DESIGN

**Created:** 2026-03-12
**Status:** Design Document
**Sprite Size:** 32x64 (LOCKED IN)

---

## PRODUCTION SPEC (LOCKED)

| Property | Value |
|----------|-------|
| Body sprite | **32x64** pixels |
| Frame size | **96x96** pixels (draw/export) |
| Draw scale | 128x256 (4x for detail) |
| Scale in-engine | ~1.0-1.05 (uniform, no per-direction scaling) |
| Gun sprites | 32px width, heights 8-16px |

---

## Overview

Design for adding multiple weapon types to the 8-bit CUSTODIAN player character, following the existing patterns in the codebase (Operator weapon profiles + Turret types).

---

## Current Architecture

### Player Weapon System (operator.gd)

- **2 weapon profiles** in `WEAPON_PROFILES` array (lines 74-95):
  - STANDARD: cooldown=0.16, speed=780, damage=16, spread=2°
  - HEAVY: cooldown=0.34, speed=620, damage=32, spread=4°
- **Weapon switching** via keys 1-2 (`_handle_weapon_switch()`)
- **Ammo system**: `ammo_standard` / `ammo_heavy`
- **Firing**: `_fire_bullet()` uses profile to set bullet properties

### Turret System (defense/turret.gd)

- **4 turret types** via `TurretType` enum: GUNNER, BLASTER, REPEATER, SNIPER
- **Properties**: range, damage, fire_rate, max_health
- **Configuration**: `configure_turret_type()` sets stats based on type

---

## Proposed System

### Weapon Types (Enum)

```gdscript
enum WeaponType {
    PISTOL,    # Default sidearm - fast, low damage
    RIFLE,     # Balanced - medium rate, medium damage  
    SHOTGUN,   # Close range - spread, high damage
    SNIPER,    # Long range - slow, high damage, precision
    MINIGUN,   # Suppression - very fast, low damage per shot
}
```

### Weapon Profile Structure

Each weapon type has a `WeaponProfile` dictionary:

```gdscript
{
    "type": WeaponType,
    "name": "PISTOL",
    "cooldown": 0.15,        # Seconds between shots
    "speed": 800.0,          # Bullet velocity
    "damage": 12.0,          # Damage per hit
    "spread": 1.5,           # Accuracy spread (degrees)
    "recoil_kick": 1.0,      # Screen shake magnitude
    "radius": 3.0,           # Bullet size
    "color": Color(...),     # Bullet tint
    "ammo_type": "standard", # Ammo category
    "muzzle_offset": 20.0,   # Distance from player center
    "fire_mode": "auto",     # auto | semi | burst
    "burst_count": 0,        # For burst mode
    "burst_delay": 0.0,      # Between burst shots
}
```

### Sprite Architecture

**Recommended: Separate gun sprite**

```
PlayerEntity/
├── BodySprite2D       # Body (static or simple animation)
├── GunSprite2D         # Weapon sprite (rotates independently)
│   ├── pistol.png
│   ├── rifle.png  
│   ├── shotgun.png
│   ├── sniper.png
│   └── minigun.png
└── MuzzleMarker2D      # Bullet spawn point
```

**Gun sprite responsibilities:**
- Rotate to face aim direction (like turret barrel)
- Weapon-specific sprite (swapped on equip)
- Recoil animation on fire

---

## Implementation Plan

### Phase 1: Core System

1. **Create `weapon_profile.gd`** - New resource file for weapon definitions
2. **Extend `WEAPON_PROFILES`** - Add 3 new weapon types (PISTOL is default)
3. **Add gun sprite node** - `GunSprite2D` to operator scene
4. **Update `_fire_bullet()`** - Use weapon-specific muzzle offset
5. **Update weapon switching** - Keys 1-5 for 5 weapon types

### Phase 2: Visual Polish

1. **Create gun sprites** - 32xN sprites for each weapon type
2. **Add recoil animation** - Scale/position offset on fire
3. **Add equip animation** - Weapon swap transition
4. **Update bullet colors** - Match weapon type

### Phase 3: Gameplay Integration

1. **Ammo types** - Add ammo_standard, ammo_heavy, ammo_sniper
2. **Pickup system** - Find/equip weapons from world
3. **UI updates** - Show current weapon, ammo counts
4. **Sound effects** - Per-weapon fire sounds

---

## File Changes

### New Files

| File | Purpose |
|------|---------|
| `entities/operator/weapon_data.gd` | WeaponProfile resource class |
| `assets/sprites/operator/guns/` | Gun sprite PNGs |
| `assets/sprites/operator/guns/pistol.png` | 32x16 default gun |
| `assets/sprites/operator/guns/rifle.png` | 32x20 |
| `assets/sprites/operator/guns/shotgun.png` | 32x24 |
| `assets/sprites/operator/guns/sniper.png` | 32x28 |
| `assets/sprites/operator/guns/minigun.png` | 32x32 |

### Modified Files

| File | Changes |
|------|---------|
| `entities/operator/operator.gd` | Add WeaponType enum, extend WEAPON_PROFILES, gun sprite handling |
| `entities/operator/operator.tscn` | Add GunSprite2D node |
| `scenes/ui.gd` | Update weapon/ammo HUD |

---

## Sprite Specifications

### Gun Sprites (32px width, variable height)

| Weapon | Size | Notes |
|--------|------|-------|
| Pistol | 32x16 | Simple rectangle shape |
| Rifle | 32x20 | Extended barrel |
| Shotgun | 32x24 | Wide muzzle |
| Sniper | 32x28 | Long barrel + scope bump |
| Minigun | 32x32 | Wide body, multiple barrels |

### Animation

- **Idle**: Subtle bob (2 frames)
- **Fire**: Recoil back (1 frame) → return (1 frame)
- **Equip**: Lower → swap → raise (3 frames)

---

## Input Mapping

| Key | Action |
|-----|--------|
| 1 | Equip PISTOL |
| 2 | Equip RIFLE |
| 3 | Equip SHOTGUN |
| 4 | Equip SNIPER |
| 5 | Equip MINIGUN |
| Q | Cycle next weapon |
| E | Cycle previous weapon |

---

## Backward Compatibility

- **Default behavior**: PISTOL replaces current STANDARD profile
- **Ammo**: Existing ammo_standard maps to PISTOL/RIFLE/SNIPER, ammo_heavy maps to SHOTGUN
- **Input**: Keys 1-2 still work (map to PISTOL/RIFLE)

---

## Data Structure

### File Organization (SPLIT FOR PERFORMANCE)

```
assets/
  weapons/
    data/
      carbine_mk1.json
      pistol_mk1.json
      shotgun_mk1.json
      sniper_mk1.json
      minigun_mk1.json
    registry.json
    weapon_schema.json
  mods/
    data/
      mods.json
  ammo_types/
    ammo_types.json
```

**Benefits:**
- Faster loading (load only needed weapons)
- Modding support
- DLC/content packs
- Easier debugging
- Per-weapon balancing

---

### Stat Naming Convention (EXPLICIT UNITS)

| Old | New | Notes |
|-----|-----|-------|
| `fire_rate` | `fire_rate_rps` | Rounds per second |
| `range` | `range_px` | Pixels |
| `speed` | `projectile_speed_px` | Pixels/sec |
| `spread` | `spread_deg` | Degrees |
| `reload_time` | `reload_time_sec` | Seconds |
| `muzzle_offset` | `muzzle_offset_px` | Pixels |

---

### Key Fields

**Weapon:**
- `weapon_class` - Category (pistol, rifle, carbine, etc.)
- `archetype` - Stat inheritance base
- `projectile` - Bullet/grenade/laser definition
- `mod_slots.mod_capacity` - Max mods allowed
- `ai_usage.threat_score` - AI weapon weighting

**Ammo Types:**
- `damage_type` - physical/energy/explosive/fire
- `armor_penetration` - Multiplier against armor
- `status_effect` - burn, stun, etc.

---

## Reference Implementation

See existing patterns:
- `entities/operator/operator.gd` - Weapon profile usage (lines 74-95, 291-330)
- `entities/defense/turret.gd` - TurretType enum and configuration (lines 4-82)
- `assets/sprites/turrets/` - Existing weapon sprite organization

---

## Open Questions

1. **Attachment point**: Should gun attach to hand position or center-body?
2. **Scope**: Are weapon pickups or class selection? (Pickups = more complex)
3. **Animation reuse**: Can existing attack frames work with new guns, or need new frames?
