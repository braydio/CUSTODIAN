# Weapons — Animation System

**See:** `ANIMATION_SYSTEM.md` for full documentation

---

## Quick Reference

### Naming

```
<weapon_id>__<category>__<variant>.png
```

### Weapon Definition

Each weapon needs `weapon_definition.json`:

```json
{
  "weapon_id": "weapon_name",
  "animations": {
    "idle": { "file": "...", "frames": 3, "speed": 7.0 },
    "melee_fast": { "file": "...", "frames": 12, "speed": 14.0 }
  }
}
```

---

## Current Weapons

| Weapon | Status |
|--------|--------|
| fallen_star_katana | Legacy - migrate |
| carbine_rifle | Legacy - migrate |
| carbine_rifle_mk1 | Needs setup |

---

## Full Documentation

**Main Docs:** `ANIMATION_SYSTEM.md`

**Migration:** `design/ANIMATION_SYSTEM_MIGRATION.md`

**Sizing:** `design/SIZING_STRATEGY.md`
