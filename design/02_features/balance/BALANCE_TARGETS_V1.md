# BALANCING TARGETS (POWER + REPAIR ECONOMY)

**File target**

```
design/20_features/in_progress/BALANCE_TARGETS_V1.md
```

---

# Design Goals

Balance should support:

```
defensive tension
repair triage decisions
sector power attacks
```

Players should **not** be able to keep everything repaired.

---

# Power Economy Targets

### Power Nodes

```
max_output = 100
```

Health scaling:

```
100% HP → 100 power
50% HP → 60 power
25% HP → 30 power
0% HP → 0 power
```

---

# Turret Power Costs

| Turret   | Cost |
| -------- | ---- |
| Gunner   | 15   |
| Blaster  | 25   |
| Repeater | 10   |
| Sniper   | 35   |

Example sector:

```
power node = 100
```

Supports roughly:

```
4–6 turrets
```

---

# Power Failure Behavior

If insufficient power:

```
lowest priority turret disables
```

Priority order:

```
Repeater
Gunner
Blaster
Sniper
```

Snipers should stay online longest.

---

# Repair Economy

Repair requires **fabrication resources**.

Resources:

```
metal
components
```

---

# Repair Costs

```
1 HP repair = 1 metal
```

Example turret:

```
max_hp = 100
full rebuild cost = 100 metal
```

---

# Repair Rate

Custodian repair tool:

```
repair_rate = 12 HP/sec
```

Repairing a destroyed turret:

```
~8 seconds
```

---

# Fabrication Production

Fabrication nodes produce:

```
3 metal/sec
```

If damaged:

```
production = base_rate * health_ratio
```

---

# Repair Decision Pressure

Example scenario:

```
3 turrets damaged
power node damaged
metal supply limited
```

Player must decide:

```
repair defenses
repair power
build economy
```

This is the **core gameplay tension loop**.

---

# Repair Interrupt Behavior

If player stops repairing:

```
progress persists
```

Repairs are **incremental**, not all-or-nothing.

---

# Economic Targets

Desired player state mid-game:

```
income ≈ damage pressure
```

Meaning:

```
player cannot repair everything
```

They must choose priorities.

---

# Target Game Loop

```
enemy wave damages systems
        ↓
power drops
        ↓
turrets weaken
        ↓
player repairs critical nodes
        ↓
economy strains
```

This creates the **Custodian fantasy**:

```
maintaining a failing facility
```

---

# Next System

Now that we have:

```
turrets
power
repairs
game-over
```

The next critical piece is the **Enemy Behavior Director**.

That system determines:

```
what enemies spawn
where they attack
how waves escalate
```

and it controls the **entire pacing of the game**.
