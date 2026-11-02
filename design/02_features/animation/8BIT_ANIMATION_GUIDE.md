# ANIMATION GUIDE — 8-BIT CUSTODIAN

**Created:** 2026-03-12
**Status:** Reference Document
**Sprite Size:** 32x64 (LOCKED)
**Frame Size:** 96x96 (LOCKED)

---

## Core Ranged Animations

### 1. stance_ranged_2h

**Purpose:** Replaces idle when rifle equipped. Communicates ready to fire.

| Property | Value |
|----------|-------|
| Frames | 2-3 |
| Motion | Subtle breathing, rifle adjustment, antenna sway |
| Directional | 4 (N, S, E, W) |

---

### 2. walk_ranged_2h

**Purpose:** Walking while holding rifle.

| Property | Value |
|----------|-------|
| Frames | 6 |
| Motion | Rifle stays mostly stable, torso/legs move, slight bobbing |
| Directional | 4 (N, S, E, W) |

**Important detail:** Rifle stays stable while body walks.

---

### 3. attack_ranged (CRITICAL)

**Purpose:** The actual firing animation — most important for combat feel.

| Property | Value |
|----------|-------|
| Frames | 4 |

**Frame breakdown:**

| Frame | Name | Action |
|-------|------|--------|
| 1 | aim | Ready position |
| 2 | windup | Trigger pull |
| 3 | recoil | Muzzle flash here |
| 4 | settle | Return to ready |

**Weapon handles:** Muzzle flash, projectiles, shell ejection, recoil offset
**Body handles:** Posture, recoil reaction, timing

---

### 4. recover_ranged

**Purpose:** Short transition back to stance.

| Property | Value |
|----------|-------|
| Frames | 1-2 |

Often just frame 4 of attack looping back to stance.

---

## Optional Animations

### 5. aim_adjust

**Purpose:** Small animation when rotating to face target.

| Frames | Motion |
|--------|--------|
| 2 | Rifle lifts slightly, shoulders tighten |

---

### 6. reload (Optional)

**Purpose:** Visible reload mechanics.

| Frames | Sequence |
|--------|----------|
| 4-6 | Lower rifle → reload motion → raise rifle |

Many RTS games skip this.

---

### 7. damage_react (Optional)

**Purpose:** Small flinch when hit.

| Frames | Purpose |
|--------|---------|
| 1-2 | Helps combat feel responsive |

---

## Frame Count Summary

| Animation | Frames | Directional | Total |
|-----------|--------|------------|-------|
| stance_ranged_2h | 2-3 | 4 | 8-12 |
| walk_ranged_2h | 6 | 4 | 24 |
| attack_ranged | 4 | 4 | 16 |
| recover | 1-2 | 4 | 4-8 |
| **Total (minimal)** | | | **52-60** |

---

## Directional Requirement

4 directions required: **north, south, east, west**

Use horizontal flip for left-facing to cut work by 50%.

---

## Design Rule: Weapon/Body Separation

**Weapon entity handles:**
- Muzzle flash
- Projectiles
- Shell ejection
- Recoil offset

**Body animation handles:**
- Posture
- Recoil reaction
- Timing

This keeps animations reusable across many guns.

---

## Priority Order

If you only have time for one animation, polish:

**attack_ranged**

Players judge combat feel almost entirely from the recoil frame and impact timing.

---

## Asset Paths

```
assets/sprites/operator/
├── body/
│   ├── stance_ranged_2h_n.png   (96x96, 2-3 frames)
│   ├── stance_ranged_2h_s.png
│   ├── stance_ranged_2h_e.png
│   ├── stance_ranged_2h_w.png
│   ├── walk_ranged_2h_n.png     (96x96, 6 frames)
│   ├── walk_ranged_2h_s.png
│   ├── walk_ranged_2h_e.png
│   ├── walk_ranged_2h_w.png
│   ├── attack_ranged_n.png      (96x96, 4 frames)
│   ├── attack_ranged_s.png
│   ├── attack_ranged_e.png
│   └── attack_ranged_w.png
└── guns/
    └── runtime/
        └── carbine_2h_stance.png   (32x64)
```

---

## Minimal Working Set

Start with:

1. ✅ stance_ranged_2h
2. ✅ walk_ranged_2h  
3. ✅ attack_ranged

That's enough for a fully functional system.

---

## Export Settings

```
PNG
Transparent background
No scaling
Nearest neighbor
Filter: OFF
Repeat: OFF
```

---

## Godot Setup

```gdscript
# Animation naming convention
{animation}_{direction}
stance_ranged_2h_n
stance_ranged_2h_s
stance_ranged_2h_e
stance_ranged_2h_w
```

Switch based on facing direction in `_update_animation()`.
