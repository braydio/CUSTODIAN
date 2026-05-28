# Animation State Transitions

## State Groups

### Movement
- `idle` - Standing still
- `walk` - Normal movement
- `sprint` - Running

### Combat
- `attack_fast` - Quick attack
- `attack_heavy` - Heavy attack
- `attack_dash` - Dash attack
- `equip_weapon` - Weapon equip/unequip

### Reaction
- `hit_recoil` - Knockback from damage
- `stagger` - Stunned state
- `death` - Player death

## Transition Rules

```
FROM          TO                CONDITION
─────────────────────────────────────────────
idle          walk              velocity > 0
idle          sprint            sprint_pressed
idle          attack_fast       attack_pressed
idle          attack_heavy      heavy_attack_pressed
idle          hit_recoil       took_damage
idle          stagger           heavy_damage
idle          death             health <= 0

walk          idle              velocity == 0
walk          sprint            sprint_pressed
walk          attack_fast       attack_pressed
walk          hit_recoil       took_damage
walk          death             health <= 0

sprint        idle              sprint_released
sprint        walk              velocity_low
sprint        attack_dash       attack_pressed
sprint        hit_recoil       took_damage

attack_fast   idle              animation_finished
attack_fast   attack_fast       compatibility_combo_pressed
attack_fast   attack_heavy      heavy_combo_pressed
attack_fast   hit_recoil       took_damage (if interruptible)

attack_heavy  idle              animation_finished
attack_heavy  hit_recoil       took_damage

attack_dash   idle              animation_finished
attack_dash   hit_recoil       took_damage

hit_recoil    idle              animation_finished
hit_recoil    death             health <= 0

stagger       idle              animation_finished
stagger       death             health <= 0

death         [none]            Terminal state
```

## Priority System

States have interrupt priority:

| Priority | State | Can Interrupt |
|----------|-------|----------------|
| 100 | death | Nothing |
| 25 | stagger | - |
| 20 | hit_recoil | - |
| 15 | attack_dash | - |
| 10 | attack_fast/attack_heavy | - |
| 5 | equip_weapon | - |
| 1 | walk/sprint | Lower priority |
| 0 | idle | Can be interrupted by anything |

## Combo System

Default attack can chain into combos:
- `attack_fast` → (combo window) → `attack_fast`
- `attack_fast` → (combo window) → `attack_heavy`

Combo window: 0.3 seconds after animation ends
