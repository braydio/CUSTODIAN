# CUSTODIAN — Animation Requirements Spec

**Created:** 2026-03-21  
**Status:** Active

---

## Katana Position Fix Applied

**File:** `fallen_star_katana_definition.tres`  
**Change:** `weapon_sprite_position` from `Vector2(-18, 10)` to `Vector2(-18, 0)`  
**Effect:** Katana moved UP by 10 pixels in stance/idle

---

## Missing Animations — Requirements

### 1. Operator: Interact Animation

**Purpose:** Player interaction with objects (turrets, terminals, pickups)

| Property | Value |
|----------|-------|
| **Frames** | 4-6 |
| **Frame Size** | 96x96 pixels |
| **Layout** | Horizontal strip |
| **Loop** | No |
| **Speed** | 10 FPS |

**Frame Contents:**
| Frame | Action | Duration |
|-------|--------|----------|
| 1 | Reach out (arm extended) | 100ms |
| 2 | Contact/object interaction | 100ms |
| 3 | Activation/confirm | 100ms |
| 4 | Return to idle | 100ms |

**Style:** 
- Single arm extended forward
- Hand open at end
- Slight body lean forward
- Match existing operator aesthetic

**File:** `operator/runtime/interact/interact_right.png`

---

### 2. Operator: Reload Animation

**Purpose:** Weapon reload for ranged weapons

**Variants Needed:**

| Variant | Frames | Purpose |
|---------|--------|---------|
| **reload_pistol** | 4 | 1H weapons |
| **reload_rifle** | 6 | 2H weapons (carbine) |
| **reload_heavy** | 8 | Heavy weapons |

**Common Specs:**
| Property | Value |
|----------|-------|
| **Frame Size** | 96x96 pixels |
| **Layout** | Horizontal strip |
| **Loop** | No |

**Frame Contents (rifle reload):**
| Frame | Action |
|-------|--------|
| 1 | Current stance |
| 2 | Magazine release/drop |
| 3 | Magazine out/new grab |
| 4 | Magazine insert |
| 5 | Charging handle |
| 6 | Ready position |

**File:** `weapons/carbine_rifle/animations/reload.png`

---

### 3. Drone: Move Animation

**Purpose:** Drone movement/patrol state

| Property | Value |
|----------|-------|
| **Frames** | 6 |
| **Frame Size** | 96x96 pixels |
| **Layout** | Horizontal strip |
| **Loop** | Yes |
| **Speed** | 12 FPS |

**Frame Contents:**
| Frame | Action |
|-------|--------|
| 1 | Hover - slight tilt right |
| 2 | Thrust forward |
| 3 | Level hover |
| 4 | Tilt left |
| 5 | Thrust forward |
| 6 | Level hover (loop) |

**Style:**
- Hovering bob motion (up/down)
- Slight banking left/right
- Engine glow pulses
- Propeller/blade blur effect

**File:** `enemies/drone/runtime/move/drone_move.png`

---

### 4. Drone: Missiles Animation

**Purpose:** Drone missile launcher deployment and fire

| Property | Value |
|----------|-------|
| **Frames** | 8 |
| **Frame Size** | 96x96 pixels |
| **Layout** | Horizontal strip |
| **Loop** | No |
| **Speed** | 10 FPS |

**Frame Contents:**
| Frame | Action |
|-------|--------|
| 1 | Missile pods hidden |
| 2 | Pod deployment start |
| 3 | Pods extended |
| 4 | Missile igniting |
| 5 | Missile launch |
| 6 | Second missile launch |
| 7 | Pods retracting |
| 8 | Return to idle |

**Style:**
- Clean 96x96 frames (currently irregular)
- Missile smoke trail effect
- Engine flash on launch
- Military/industrial drone aesthetic

**File:** `enemies/drone/runtime/attack/drone_missiles.png`

---

### 5. Operator: Death Animation

**Purpose:** Player death state

| Property | Value |
|----------|-------|
| **Frames** | 6 |
| **Frame Size** | 96x96 pixels |
| **Layout** | Horizontal strip |
| **Loop** | No |
| **Speed** | 8 FPS |

**Frame Contents:**
| Frame | Action |
|-------|--------|
| 1 | Stagger/react |
| 2 | Fall start |
| 3 | Mid-fall |
| 4 | Impact |
| 5 | Crumple |
| 6 | Final position (loop final frame) |

**Style:**
- Dramatic but quick
- Matches operator color scheme
- Ends in defeated pose
- Optional: fade out at end

**File:** `operator/runtime/death/death_right.png`

---

### 6. Operator: Run Animation (Per-Weapon)

**Purpose:** Sprinting while equipped

**Variants Needed:**

| Variant | Frames | Weapon |
|---------|--------|--------|
| **run_katana** | 6 | Katana |
| **run_rifle** | 6 | Carbine |

**Common Specs:**
| Property | Value |
|----------|-------|
| **Frame Size** | 96x96 pixels |
| **Layout** | Horizontal strip |
| **Loop** | Yes |
| **Speed** | 14 FPS |

**Frame Contents (run_katana):**
| Frame | Action |
|-------|--------|
| 1 | Right foot forward |
| 2 | Push off |
| 3 | Float |
| 4 | Left foot forward |
| 5 | Push off |
| 6 | Float (loop) |

**Style:**
- Weapon held ready
- Slight bob up/down
- Dynamic running pose
- Arm position matches weapon type

**Files:**
- `weapons/fallen_star_katana/animations/run.png`
- `weapons/carbine_rifle/animations/run.png`

---

### 7. Drone: Death Animation

**Purpose:** Drone destruction

| Property | Value |
|----------|-------|
| **Frames** | 6 |
| **Frame Size** | 96x96 pixels |
| **Layout** | Horizontal strip |
| **Loop** | No |
| **Speed** | 10 FPS |

**Frame Contents:**
| Frame | Action |
|-------|--------|
| 1 | Spark/flash |
| 2 | Explosion core |
| 3 | Expanding debris |
| 4 | Fire/smoke |
| 5 | Fade out |
| 6 | Empty (wreckage) |

**Style:**
- Red/orange explosion
- Mechanical debris
- Screen shake on frame 2-3
- Fade to transparent

**File:** `enemies/drone/runtime/death/drone_death.png`

---

## Quick Reference — All Required Animations

### Operator (Player)

| Animation | Frames | Size | Priority |
|-----------|--------|------|----------|
| idle | 3 | 96x96 | ✅ Done |
| walk | 8 | 96x96 | ✅ Done |
| run (default) | 8 | 100x100 | ⚠️ Needs per-weapon |
| **run_katana** | 6 | 96x96 | ❌ NEED |
| **run_rifle** | 6 | 96x96 | ❌ NEED |
| melee_fast | 12 | 96x96 | ✅ Done |
| melee_heavy | 8 | 96x96 | ✅ Done |
| ranged_stance | 3 | 96x96 | ✅ Done |
| ranged_fire | 2 | 96x96 | ✅ Done |
| **interact** | 4-6 | 96x96 | ❌ NEED |
| **reload_pistol** | 4 | 96x96 | ❌ NEED |
| **reload_rifle** | 6 | 96x96 | ❌ NEED |
| block_enter | 4 | 96x96 | ✅ Done |
| block_hold | 1 | 96x96 | ✅ Done |
| block_exit | 2 | 96x96 | ✅ Done |
| **death** | 6 | 96x96 | ❌ NEED |

### Drone (Enemy)

| Animation | Frames | Size | Priority |
|-----------|--------|------|----------|
| idle | 2 | 128x128 | ⚠️ Resize to 96x96 |
| **move** | 6 | 96x96 | ❌ NEED |
| firing | 4 | 128x128 | ⚠️ Resize to 96x96 |
| **missiles** | 8 | 96x96 | ❌ NEED (irregular) |
| hit/stagger | 2 | 96x96 | ✅ Done |
| **death** | 6 | 96x96 | ❌ NEED |

---

## Asset Deliverable Checklist

When sourcing/creating sprites:

- [ ] **Format:** PNG with transparency
- [ ] **Palette:** Match existing CUSTODIAN aesthetic
- [ ] **Frame size:** 96x96 (player/enemies), 32x32 (tiles)
- [ ] **Layout:** Horizontal strip (frame 0 at x=0, frame 1 at x=96, etc.)
- [ ] **Naming:** `<animation_name>_<direction>.png`
- [ ] **Import:** Generate .import file with compress settings

---

## Related Documentation

- `design/ANIMATION_SYSTEM_MIGRATION.md` — System overview
- `design/SIZING_STRATEGY.md` — Sprite sizing rules
- `design/DRONE_ASSETS_NEEDED.md` — Drone-specific requirements
