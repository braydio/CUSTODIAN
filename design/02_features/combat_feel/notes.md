# Attack Hit Timing Specification

**Project:** CUSTODIAN
**Last Updated:** 2026-03-24
**Purpose:** Document enemy hit frames for combat feel and animation synchronization

---

## Overview

This document defines exact hit frames for melee attacks to ensure proper feedback timing. Hit frames determine when damage is applied and hit effects (hitstop, sparks, screen shake) trigger.

Combat feel tuning is critical — players need stronger confirmation at exact hit frames.

---

## Attack Frame Notation

- Frame 1 = First frame of attack animation
- All hit frames are exact — hit triggers on that specific frame

---

## Fast Attack

### Right Side Enemies

| Hit Frame | Enemies Hit | Notes |
|----------|-------------|-------|
| Frame 4 | East (right) | First hit window |
| Frame 7 | East (right) | Second hit window |

### Fast Attack Coverage Summary

| Frame | Enemies Hit |
|-------|-------------|
| 2 | Northwest, North |
| 3 | Northeast, East |
| 4 | East, South, West, Northwest |
| 7 | South, Southeast, East |
| 8 | Northeast, North |

### Fast Attack Design Intent

Fast should feel: responsive, chainable, precise
- Lower hitstop (3-4 frames)
- Lighter camera shake
- Quick recovery for chaining
- Lower knockback

---

## Heavy Attack

### Right Side (East)
- **Frame 7** — Hits enemies to the right of operator

### Down/South Side
- **Frame 6** — Hits enemies below the operator

### Left Side (West)
- **Frame 4** — Hits enemies to the left of the operator

### Northwest Side
- **Frame 3** — Hits enemies northwest of operator

### Heavy Attack Coverage Summary

| Frame | Direction |
|-------|-----------|
| 3 | Northwest |
| 4 | West |
| 6 | South |
| 7 | East |

### Heavy Attack Design Intent

Heavy should feel: committed, space-clearing, dangerous
- Heavier hitstop (5-6 frames)
- Stronger camera shake
- Longer recovery
- Higher knockback
- Distinct target priorities (structures before enemies?)

---

## Direction Mapping

| Direction | Position Relative to Operator |
|-----------|----------------------------|
| North | Above (y - 1) |
| South | Below (y + 1) |
| East | Right (x + 1) |
| West | Left (x - 1) |
| Northeast | Above-Right (x + 1, y - 1) |
| Northwest | Above-Left (x - 1, y - 1) |
| Southeast | Below-Right (x + 1, y + 1) |
| Southwest | Below-Left (x - 1, y + 1) |

---

## Combat Feel Tuning (Priority Items)

### 1. Hit Confirmation at Exact Frames

Current state: Getting better, but player needs stronger confirmation at exact hit frame.

**Tune:**
- Heavier hitstop on confirmed heavy hits
- Stronger camera shake differences between fast and heavy
- Cleaner spark/impact placement at contact
- Sharper attack audio separation by weight

### 2. Enemy Reaction Readability

Hits feel weak if enemies don't sell them.

**Add:**
- Directional hit flinch
- Short stagger tiers by attack type
- Clearer knockback rules
- Death reactions that match overkill / heavy finishers

### 3. Recovery and Cancel Feel

A lot of "bad combat feel" is really awkward recovery.

**Review:**
- When movement resumes after fast/heavy
- When the next attack can buffer
- Block responsiveness out of recovery
- How quickly aim/facing updates during attacks

### 4. Fast vs Heavy Aggressive Differentiation

They should not just be "small hit" and "big hit."

**Fast:**
- Responsive
- Chainable
- Precise

**Heavy:**
- Committed
- Space-clearing
- Dangerous

That means different hitstop, knockback, screen shake, recovery, and maybe even distinct target priorities.

### 5. Anticipation and Trailing Effects

Attacks need clearer wind-up and follow-through.

**Add:**
- Brief anticipation pose before heavy
- Stronger arc/trail FX on heavy
- Lighter, shorter streaks on fast
- Subtle motion burst on attack start

### 6. Contact Affects Operator Too

Good melee feels like force transfers through the player character.

**Add:**
- Tiny lunge on fast
- Stronger planted step on heavy
- Brief recoil on block impact
- Stance settle after combo end

---

## Implementation Priority

If making the next concrete pass in code:

1. **Tune hitstop and camera shake by attack type**
2. **Add enemy flinch/stagger reactions**
3. **Tighten attack recovery/buffer timings**
4. **Add better impact/trail FX on exact authored hit frames**

---

## Implementation Notes

### ATTACK_HIT_FRAMES Structure

```gdscript
const ATTACK_HIT_FRAMES := {
    "fast": {
        2: ["northwest", "north"],
        3: ["northeast", "east"],
        4: ["east", "south", "west", "northwest"],
        7: ["south", "southeast", "east"],
        8: ["northeast", "north"],
    },
    "heavy": {
        3: ["northwest"],
        4: ["west"],
        6: ["south"],
        7: ["east"],
    },
}

const ATTACK_FEEL := {
    "fast": {
        "hitstop_frames": 3,
        "camera_shake": 2.0,
        "knockback": 50.0,
        "recovery_frames": 8,
        "combo_window": 6,
    },
    "heavy": {
        "hitstop_frames": 5,
        "camera_shake": 5.0,
        "knockback": 120.0,
        "recovery_frames": 15,
        "combo_window": 10,
    },
}
```

### Hit Detection Algorithm

```gdscript
func _check_hits(attack_type: String, current_frame: int) -> void:
    var hit_data := ATTACK_HIT_FRAMES[attack_type]
    var feel := ATTACK_FEEL[attack_type]
    
    if not hit_data.has(current_frame):
        return
    
    var directions: Array = hit_data[current_frame]
    for dir in directions:
        var hit_zone := _get_zone_from_direction(dir)
        _damage_enemies_in_zone(hit_zone)
        _apply_hit_feel(feel, hit_zone)
```

---

## Animation Duration Guidelines

| Attack | Total Frames | Hit Frames |
|--------|--------------|------------|
| Fast | ~10-12 | 3, 4, 7, 8 |
| Heavy | ~15-18 | 3, 4, 6, 7 |

---

## Related Documents

- `COMBAT_FEEL_SYSTEM.md` — Hitstop, screen shake, spark effects
- `OPERATOR_ANIMATION_STATE_MACHINE.md` — Animation states
- `8BIT_ANIMATION_GUIDE.md` — Sprite animation setup
