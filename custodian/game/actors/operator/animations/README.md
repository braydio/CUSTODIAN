# Operator Animation System

Structured animation system for the Custodian player character.

## Node Structure

```
Custodian (CharacterBody2D)
├─ AnimationPlayer        # Controls animation timing and events
├─ AnimatedSprite2D       # Visual sprite playback
├─ HitboxRoot            # Damage hitbox for attacks
│   └─ [Hitbox shapes]
├─ Hurtbox               # Receives damage
│   └─ [Hurtbox shapes]
└─ CameraShake           # Screen shake on impacts
```

## Animation Groups

### Movement
| Animation | Description | Loop |
|-----------|-------------|------|
| `idle` | Standing still | Yes |
| `walk` | Normal walking | Yes |
| `sprint` | Running | Yes |

### Combat
| Animation | Description | Loop | Key Events |
|-----------|-------------|------|------------|
| `attack_light` | Standard melee | No | start → windup → active → recovery |
| `attack_fast` | Quick melee | No | start → windup → active → recovery |
| `attack_heavy` | Heavy melee | No | start → windup → active → recovery |
| `attack_dash` | Dash + attack | No | start → windup → active → recovery |
| `equip_weapon` | Draw/holster weapon | No | start → active → recovery |

### Reaction
| Animation | Description | Loop | Key Events |
|-----------|-------------|------|------------|
| `hit_recoil` | Knockback response | No | start → end |
| `stagger` | Stunned state | No | start → end |
| `death` | Death animation | No | start (terminal) |

## Animation Phases

Each combat animation has phases:

```
┌──────┐ ┌───────┐ ┌───────┐ ┌──────────┐
│START │ │WINDUP │ │ACTIVE │ │RECOVERY │
└──────┘ └───────┘ └───────┘ └──────────┘
   │        │        │          │
   └────────┴────────┴──────────┘
              Timeline
```

| Phase | Interruptible | Game Effect |
|-------|---------------|-------------|
| START | Yes | Animation begins |
| WINDUP | Yes* | Weapon charging |
| ACTIVE | No | Damage applied! |
| RECOVERY | No | Return to neutral |

*Can cancel into other attacks during windup

## File Structure

```
animations/
├── animation_state_machine.gd   # Main state machine
├── states/
│   ├── animation_state.gd       # Base state class
│   ├── idle_state.gd
│   ├── walk_state.gd
│   ├── sprint_state.gd
│   ├── attack_light_state.gd
│   ├── attack_fast_state.gd
│   ├── attack_heavy_state.gd
│   ├── attack_dash_state.gd
│   ├── equip_weapon_state.gd
│   ├── hit_recoil_state.gd
│   ├── stagger_state.gd
│   └── death_state.gd
├── events/
│   └── README.md               # Event definitions
└── transitions/
    └── README.md               # Transition rules
```

## Usage

```gdscript
# Initialize state machine
var asm = AnimationStateMachine.new()
asm.animation_player = $AnimationPlayer
asm.sprite = $AnimatedSprite2D

# Register states
asm.register_state(IdleState.new())
asm.register_state(WalkState.new())
asm.register_state(AttackFastState.new())

# Process each frame
func _process(delta):
    asm.update(delta)

# Handle animation events
func _on_animation_event(event_name, event_type):
    asm.current_state.on_animation_event(event_name, event_type)
```

## State Manager Contract

- The state machine owns deterministic transition sequencing, per-state elapsed time, priorities, and enter/exit calls.
- States may opt into same-state re-entry with `can_reenter = true`; attack states use this so a valid repeated light attack restarts cleanly instead of silently no-oping.
- Combat state remains authoritative. Attack states call into `operator.gd` to start attacks and query `is_attack_state_complete(kind)` to finish.
- `AnimatedSprite2D.is_playing()` is not combat authority. Sprite playback can support presentation, but lockout, recovery, hit windows, and completion must come from gameplay state.
- Animation events should notify gameplay systems; they should not replace deterministic gameplay timers or profile data.

## Integration with Operator

The animation system integrates with the existing operator.gd:
- Request state transitions through `AnimationStateMachine.request(state_name, priority)`.
- Use state entry to call gameplay methods such as `start_attack("melee_light")`.
- Use operator gameplay state to determine when attack/block states complete.
- Connect combat system to frame windows and damage frames.
- Connect hurtbox to hit_recoil state.
