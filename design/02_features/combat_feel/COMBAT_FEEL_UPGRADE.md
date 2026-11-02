# Combat Feel Upgrade — Implementation Plan

**Created:** 2026-03-25
**Status:** 📋 PLANNED
**Source:** `design/UPGRADE_FIGHT_MECHANICS.md`

---

## 1. Overview

Improve combat feel by tightening the feedback chain around existing combat moments. Focus on:
- Attack frame clarity
- Enemy reaction readability
- Recovery and cancel feel
- Fast vs heavy differentiation
- Anticipation and trailing effects
- Contact effects on operator

---

## 2. Priority System

### Phase 1: Hit Feedback (Highest Priority)
| Issue | Solution | Files |
|-------|----------|-------|
| Weak hit confirmation | Tune hitstop by attack type | `operator.gd` |
| Unclear fast/heavy distinction | Different camera shake per type | `operator.gd` |
| Poor impact placement | Exact spark/impact at contact frame | `combat.gd`, effects |
| Generic audio | Weight-based attack sounds | `operator.gd` |

### Phase 2: Enemy Reactions
| Issue | Solution | Files |
|-------|----------|-------|
| Hits feel weak | Add directional hit flinch | `enemy.gd` |
| No stagger system | Add stagger tiers by attack type | `enemy.gd` |
| Weak knockback | Clarify knockback rules | `enemy.gd` |
| Flat death reactions | Death reactions match overkill | `enemy.gd` |

### Phase 3: Recovery Tuning
| Issue | Solution | Files |
|-------|----------|-------|
| Awkward recovery | Tune movement resume timing | `operator.gd` |
| Poor attack chaining | Improve next-attack buffer | `operator.gd` |
| Slow block responsiveness | Block out of recovery | `operator.gd` |
| Aim/facing lag | Faster aim updates during attacks | `operator.gd` |

### Phase 4: Fast vs Heavy Differentiation
| Fast Attack | Heavy Attack |
|-------------|--------------|
| Responsive | Committed |
| Chainable | Space-clearing |
| Precise | Dangerous |
| Lower hitstop | Higher hitstop |
| Light knockback | Heavy knockback |
| Small shake | Large shake |
| Quick recovery | Long recovery |

### Phase 5: Anticipation Effects
| Animation | Path | Frames |
|-----------|------|--------|
| heavy_anticipation_body | `operator/runtime/body/melee_2h/heavy_anticipation_body.png` | 2-3 |
| heavy_anticipation_weapon | `operator/runtime/overlay/melee_2h/heavy_anticipation_weapon.png` | 2-3 |
| fast_recovery_body | `operator/runtime/body/melee_2h/fast_recovery_body.png` | 2-3 |
| heavy_recovery_body | `operator/runtime/body/melee_2h/heavy_recovery_body.png` | 3-4 |
| block_impact_body | `operator/runtime/body/melee_2h/block_impact_body.png` | 2-3 |
| block_impact_weapon | `operator/runtime/overlay/melee_2h/block_impact_weapon.png` | 2-3 |

### Phase 6: Operator Contact Effects
| Effect | Trigger |
|--------|---------|
| Tiny lunge on fast | Fast attack swing |
| Strong planted step on heavy | Heavy attack swing |
| Brief recoil on block impact | Successful block |
| Stance settle after combo end | Combo completion |

---

## 3. Animation Assets Required

### Operator Animations
```
custodian/assets/sprites/operator/runtime/
├── body/melee_2h/
│   ├── heavy_anticipation_body.png     # 2-3 frames
│   ├── fast_recovery_body.png          # 2-3 frames
│   ├── heavy_recovery_body.png         # 3-4 frames
│   └── block_impact_body.png           # 2-3 frames
└── overlay/melee_2h/
    ├── heavy_anticipation_weapon.png   # 2-3 frames
    └── block_impact_weapon.png         # 2-3 frames
```

### Enemy Animations
```
custodian/assets/sprites/enemies/runtime/
├── shared/
│   ├── hit_light_[enemy_type].png      # 2-3 frames per enemy
│   ├── hit_heavy_[enemy_type].png       # 3-4 frames per enemy
│   └── death_heavy_[enemy_type].png     # 4-6 frames per enemy
```

### Effect Animations
```
custodian/assets/sprites/effects/runtime/
└── melee/
    ├── fast_hit_arc.png                 # 3-4 frames
    ├── heavy_hit_arc.png                # 4-6 frames
    ├── block_slam.png                   # 3-4 frames
    └── heavy_ground_burst.png            # 4-5 frames (optional)
```

---

## 4. Code Changes Required

### 4.1 Hitstop System

```gdscript
# In operator.gd - add attack-specific hitstop

const HITSTOP_BY_TYPE := {
    "fast": 0.05,      # 50ms - snappy
    "heavy": 0.15,     # 150ms - weighty
    "ranged": 0.08,    # 80ms - moderate
}

var current_hitstop := 0.0

func _apply_hitstop(attack_type: String):
    current_hitstop = HITSTOP_BY_TYPE.get(attack_type, 0.05)
    get_tree().paused = true
    await get_tree().create_timer(current_hitstop).timeout
    get_tree().paused = false
```

### 4.2 Camera Shake Differentiation

```gdscript
const SHAKE_BY_TYPE := {
    "fast": {"power": 3.0, "duration": 0.1},
    "heavy": {"power": 12.0, "duration": 0.25},
    "ranged": {"power": 5.0, "duration": 0.15},
    "block": {"power": 2.0, "duration": 0.08},
}

func _trigger_shake(attack_type: String):
    var shake = SHAKE_BY_TYPE.get(attack_type, SHAKE_BY_TYPE["fast"])
    _camera.apply_shake(shake.power, shake.duration)
```

### 4.3 Enemy Stagger System

```gdscript
# In enemy.gd - add stagger tiers

enum StaggerTier { NONE, LIGHT, MEDIUM, HEAVY, DOWN }

const STAGGER_THRESHOLDS := {
    "fast": {"threshold": 15.0, "tier": StaggerTier.LIGHT, "duration": 0.3},
    "heavy": {"threshold": 40.0, "tier": StaggerTier.HEAVY, "duration": 0.8},
}

var current_stagger := StaggerTier.NONE
var stagger_timer := 0.0

func apply_damage_stagger(damage: float, attack_type: String):
    var stagger_data = STAGGER_THRESHOLDS.get(attack_type)
    if stagger_data and damage >= stagger_data.threshold:
        _enter_stagger(stagger_data.tier, stagger_data.duration)

func _enter_stagger(tier: StaggerTier, duration: float):
    current_stagger = tier
    stagger_timer = duration
    _play_stagger_animation(tier)
```

### 4.4 Recovery Timing

```gdscript
const RECOVERY_BY_TYPE := {
    "fast": {
        "movement_resume": 0.15,
        "attack_buffer": 0.10,
        "total_recovery": 0.25,
    },
    "heavy": {
        "movement_resume": 0.40,
        "attack_buffer": 0.20,
        "total_recovery": 0.60,
    },
}
```

### 4.5 Attack Lunge

```gdscript
const ATTACK_LUNGE := {
    "fast": {"distance": 8.0, "duration": 0.08},
    "heavy": {"distance": 20.0, "duration": 0.20},
}

func _apply_attack_lunge(attack_type: String):
    var lunge = ATTACK_LUNGE.get(attack_type)
    if lunge:
        var tween = create_tween()
        tween.tween_property(self, "position", position + facing_direction * lunge.distance, lunge.duration)
        tween.tween_property(self, "position", position, lunge.duration)
```

---

## 5. Implementation Order

### Step 1: Placeholder-Based Code (No Art Required)
1. ✅ Add hitstop system with placeholder timings
2. ✅ Add camera shake differentiation
3. ✅ Add basic enemy stagger state machine
4. ✅ Tune recovery timings
5. ✅ Add attack lunge

### Step 2: Animation Integration (After Art)
1. Insert anticipation frames before heavy attacks
2. Insert recovery frames after attacks
3. Insert block impact frames on successful block
4. Wire enemy flinch animations to stagger system

### Step 3: Effect Polish
1. Add impact FX at exact hit frame
2. Add trail FX on attack swing
3. Tune all timings based on feel

---

## 6. Files to Modify

| File | Changes |
|------|---------|
| `entities/operator/operator.gd` | Hitstop, shake, lunge, recovery timing |
| `entities/enemies/enemy.gd` | Stagger system, flinch, knockback |
| `core/systems/combat.gd` | Impact FX spawning |
| `scenes/camera.gd` | Shake system enhancements |

---

## 7. Testing Checklist

- [ ] Fast attacks feel snappy and chainable
- [ ] Heavy attacks feel committed and powerful
- [ ] Hitstop varies by attack type
- [ ] Camera shake differs between fast/heavy
- [ ] Enemies flinch from light hits
- [ ] Enemies stagger from heavy hits
- [ ] Knockback scales with attack weight
- [ ] Movement resumes at correct time after attack
- [ ] Can buffer next attack during recovery
- [ ] Block works during/after recovery
- [ ] Attack anticipation readable before heavy
- [ ] Recovery settle visible after attacks
- [ ] Block impact has distinct feedback

---

## 8. Related Systems

- Animation System (`operator_runtime_frames.tres`)
- Enemy AI (`enemy.gd`)
- Combat System (`combat.gd`)
- Camera System (`camera.gd`)
- Sound System (future)

---

## 9. Future Upgrades

- Block cancel out of heavy recovery
- Perfect dodge system
- Counter-attack windows
- Combo counter UI
- Enemy armor affecting stagger
