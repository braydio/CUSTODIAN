
Below is a grounded but expressive system that integrates:

* Power tiers
* Autopilot
* Repairs
* Damage states
* Information fidelity
* Assault pressure

---

# POWER × PERFORMANCE — EXACT MATH

We formalize three axes:

1. **Power Tier**
2. **Structural Integrity**
3. **Operational Output**

Output is a function of both power and damage.

---

# 1️⃣ Power Tier Math

For every structure:

```
allocated_power = routed_power[structure_id]
min_power
standard_power
```

Define:

```
power_ratio = allocated_power / standard_power
```

Power Tier Classification:

| Condition                  | Tier     | power_efficiency     |
| -------------------------- | -------- | -------------------- |
| allocated < min            | OFFLINE  | 0.0                  |
| min ≤ allocated < standard | DEGRADED | allocated / standard |
| allocated ≥ standard       | NORMAL   | 1.0                  |

Note:

* We cap efficiency at 1.0.
* No overcharge in Phase I.

---

# 2️⃣ Structural Integrity Math

Structure states:

| State       | integrity_modifier |
| ----------- | ------------------ |
| OPERATIONAL | 1.0                |
| DAMAGED     | 0.75               |
| OFFLINE     | 0.0                |
| DESTROYED   | 0.0                |

(DESTROYED handled separately in routing.)

---

# 3️⃣ Final Operational Output

For any powered structure:

```
effective_output = power_efficiency * integrity_modifier
```

This produces a continuous scalar between 0.0 and 1.0.

This scalar drives:

* Fire rate
* Accuracy
* Range
* Repair speed
* Fabrication throughput
* Sensor fidelity modifier

---

# 4️⃣ Defense Performance (Exact)

## 4.1 Turret Example

Base stats:

```
base_fire_interval = 2 ticks
base_accuracy = 0.7
base_damage = 1
```

Adjusted:

```
fire_interval = base_fire_interval / effective_output
accuracy = base_accuracy * effective_output
damage = base_damage * effective_output
```

Clamp rules:

* If effective_output < 0.2 → turret misfires (no shot this tick)
* If effective_output == 0 → inoperable

Example:

* Power 1/2 (0.5)
* DAMAGED (0.75)

```
effective_output = 0.5 * 0.75 = 0.375
```

Turret now:

* Fires every 5.33 ticks
* Accuracy = 0.2625
* Damage = 0.375

That feels weak — and visibly so — but not binary.

---

## 4.2 Blast Door

Binary system.

If effective_output ≥ 0.5 → operational
If < 0.5 → opens slower
If 0 → fails open

Door open/close time:

```
open_time = base_open_time / max(effective_output, 0.25)
```

---

# 5️⃣ Fabricator Performance

Fabrication progress per tick:

```
progress += base_rate * effective_output
```

If below min power → zero progress
If damaged + low power → crawl speed

---

# 6️⃣ Mechanic Drone Repair Speed

Repair speed:

```
repair_ticks_remaining -= base_repair_rate * effective_output
```

This means:

Low power slows repairs.
Damaged drone system slows repairs.
Both stack multiplicatively.

---

# 7️⃣ Sensor Fidelity Modifier

Sensors influence information degradation.

Define:

```
sensor_effectiveness = effective_output
```

Information fidelity downgrade trigger:

| sensor_effectiveness | max fidelity |
| -------------------- | ------------ |
| ≥ 0.9                | FULL         |
| ≥ 0.6                | DEGRADED     |
| ≥ 0.3                | FRAGMENTED   |
| < 0.3                | LOST         |

This ties power decisions directly to informational clarity.

That’s powerful.

---

# 8️⃣ Repair System Integration

Now we integrate power into repairs.

---

# Repair State Machine Interaction

Repair progress is affected by:

1. Mechanic drone power
2. Sector power availability
3. Assault state

---

## 8.1 Base Repair Equation

For a structure under repair:

```
repair_speed = base_repair_speed
             * mechanic_drone_effective_output
             * sector_power_modifier
```

Where:

```
sector_power_modifier = 1.0 if sector has ≥ min_power
                        0.5 if degraded
                        0.0 if inoperable
```

So:

* Underpowered sector = slow repair
* Underpowered drones = slow repair
* Both underpowered = very slow repair

---

# 9️⃣ Repair During Assault — Creative but Grounded

During active assault:

Add instability penalty:

```
if state.in_assault:
    repair_speed *= 0.75
```

Additionally:

Each time the repaired structure’s sector takes damage:

```
repair_ticks_remaining += 1  # regression event
```

So repairs can slide backward under pressure.

No randomness required.

---

# 🔥 Risky Play: Field Power + Repair

If player banks portable power and deploys to a damaged turret mid-assault:

* Power raises effective_output
* Turret regains partial fire capability
* Repair speed increases if mechanic drones are powered

But:

Portable bank is finite.

So the player must choose:

* Power sensors?
* Power drones?
* Power turret?

Real decision.

---

# 10️⃣ Repair Cost Interaction with Power

Reconstruction (DESTROYED → OFFLINE):

Requires:

* Materials
* Minimum sector power online
* Mechanic drones powered at ≥ min

If either is not met:

Repair cannot start.

This forces infrastructure restoration before resurrection.

---

# 11️⃣ Cascading Failure Dynamics

Here’s where it gets interesting.

If:

* Player powers Fabricator heavily
* Leaves Defense underpowered

Then during assault:

* Turrets weak
* Repairs slow
* Sensor fidelity drops
* STATUS degrades

The world feels fragile.

But never unfair.

Because:

Everything is deterministic.

---

# 12️⃣ Edge Case Handling

## Case: Power removed mid-repair

If sector power falls below min:

* Repair pauses
* No progress lost
* Unless assault damage event triggers regression

---

## Case: System destroyed during repair

* Repair task cancelled
* Power freed
* Materials partially refunded (50%)

---

## Case: Mechanic drones unpowered

Repair_speed = 0
But manual player repair (future embodied mode) can bypass this.

---

# 13️⃣ Emergent Behavior Created

This system produces:

* Strategic triage
* Power-driven repair urgency
* Information loss from bad routing
* Visible degradation curve
* Recoverable but punishing mistakes

All without:

* Random spikes
* Hidden timers
* Background drains

---

# 14️⃣ Why This Is Grounded

We didn’t invent:

* Overcharge mechanics
* Arbitrary cooldowns
* Soft caps
* Artificial complexity

Everything is:

```
effective_output = power_ratio × integrity
```

One formula.
Applied everywhere.

Elegant systems scale.

---

# If You Want To Go Further

Next logical extension:

* Power load spike events during assault
* EMP causing temporary power_efficiency reduction
* Overload risk if reallocating during assault

But do not add that yet.

---

You now have:

* A unified power-performance equation
* Deterministic degraded math
* Repair interaction
* Assault interaction
* Information degradation linkage
* Tactical field routing impact

This is cohesive.

If you want, next we can:

* Write exact code patch diff plan
* Or simulate a first assault with this system numerically to test balance
