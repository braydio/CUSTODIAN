# Power Systems Design

**Status:** Ready to Implement  
**Source:** Legacy Python `python-sim/design/10_systems/infrastructure/POWER_SYSTEMS.md`  
**Last Updated:** 2026-03-10

---

## Core Formula

```
effective_output = power_efficiency * integrity_modifier
```

This single formula applies to all powered structures.

---

## Power Tier Math

For every structure:

```
allocated_power = routed_power[structure_id]
min_power = minimum required
standard_power = normal operation
```

**Power Ratio:**
```
power_ratio = allocated_power / standard_power
```

### Power Tier Classification

| Condition | Tier | power_efficiency |
| --------- | ---- | ----------------- |
| allocated < min | OFFLINE | 0.0 |
| min ≤ allocated < standard | DEGRADED | allocated / standard |
| allocated ≥ standard | NORMAL | 1.0 |

---

## Structural Integrity

| State | integrity_modifier |
| ----- | ----------------- |
| OPERATIONAL | 1.0 |
| DAMAGED | 0.75 |
| OFFLINE | 0.0 |
| DESTROYED | 0.0 |

---

## Turret Performance

### Base Stats
```
base_fire_interval = 2.0 seconds
base_accuracy = 0.7
base_damage = 1
```

### Adjusted (when powered)
```
fire_interval = base_fire_interval / effective_output
accuracy = base_accuracy * effective_output
damage = base_damage * effective_output
```

### Misfire Rule
- If effective_output < 0.2 → turret misfires (no shot)

### Example
- Power: 50% (0.5)
- Status: DAMAGED (0.75)

```
effective_output = 0.5 * 0.75 = 0.375
```

Turret now:
- Fires every 5.33 seconds
- Accuracy = 26%
- Damage = 37%

---

## Power Failure Behavior

If insufficient power for all turrets, disable lowest priority first:

| Priority | Turret Type | Power Cost |
| -------- | ----------- | ----------- |
| 1 (first off) | Repeater | 10 |
| 2 | Gunner | 15 |
| 3 | Blaster | 25 |
| 4 (last off) | Sniper | 35 |

---

## Power Node Output

```
max_output = 100

100% HP → 100 power
50% HP → 60 power
25% HP → 30 power
0% HP → 0 power
```

---

## Visual Feedback

- **Green** - Full power, operational
- **Yellow** - Degraded power (< standard but ≥ min)
- **Red** - Critical power (< min)
- **Gray** - No power / offline

---

## Implementation Notes

- Store `power_ratio` per structure
- Recalculate when power changes (damage, routing, or node destroyed)
- Update UI bars in real-time
- Turrets should visibly degrade (muzzle flash rate slows, accuracy cone widens)
