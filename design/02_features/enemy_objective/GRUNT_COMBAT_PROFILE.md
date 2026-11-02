# GRUNT_COMBAT_PROFILE — CUSTODIAN Standard Human Enemy

**Status:** draft  
**Owner:** gameplay/combat, content  
**Depends On:** Wave Spawning System, Enemy Objective System, Combat Feel System  
**Last Updated:** 2026-05-19

---

## 1. Purpose

CUSTODIAN's standard grunt is a **combat grammar piece** — not a walking HP bag, but the baseline enemy that teaches spacing, pressure, interruption, targeting priority, and the command-vs-field tradeoff.

CUSTODIAN is not "kill everything." It is about preserving knowledge, defending infrastructure, and choosing where your physical presence matters. The Command Center/field split, dumb autopilot, phased assaults, and "you cannot be everywhere" premise are already stronger than a normal action game enemy setup.

The grunt becomes interesting because it forces the player to fight for **position, time, and infrastructure** — not just HP.

### Boring grunt
> See player → walk toward player → attack → die.

### CUSTODIAN grunt
> Enter sector → identify objective → pressure Custodian only if blocked → damage/steal/sabotage something → retreat, panic, regroup, or call others.

### Scope rules

- **Strategic layer** (threat budgets, lane selection, wave composition) → `enemy_director/implementation.md`  
- **Combat feel** (hitstop, camera shake, player attack timing) → `combat_feel/COMBAT_FEEL_SYSTEM.md`  
- **This spec** → individual grunt tactical behavior: state machine, combat verbs, hit reactions, morale, objective pressure, encounter rules.

---

## 2. Five Behavioral Axes

### 2.1 Advance Under Threat

The grunt does not just chase. It alternates between closing distance, pausing to aim, sidestepping, short bursts of aggression, and backing off if staggered. This creates rhythm — the player reads "he is about to commit" rather than "AI blob moving at me."

### 2.2 Directional Hit Reactions

Three hit types, each with a distinct response:

| Hit type         | Enemy response  | Effect                                          |
|------------------|-----------------|------------------------------------------------|
| Light hit        | Small flinch    | Interrupts aim; does not cancel movement        |
| Heavy / stagger  | Stagger         | Cancels attack windup; opens punish window      |
| Back or side hit | Stumble-turn    | Rewards player positioning                      |

Stun is **conditional** — not every hit stuns. Stun triggers on: heavy attack, timed parry, hit during windup, explosive impact, or attack from behind. Consistent light hits keep the player engaged without becoming mush.

### 2.3 Telegraphed Attacks

The grunt clearly shows windup, active danger, and recovery phases — even for firearms. Give a visible "raise weapon / aim / fire" beat rather than instant shots. For melee: shoulder dip, weapon arm pullback, or forward foot plant.

**Baseline timing targets:**

```
melee_windup:   0.25s
melee_active:   0.12s
melee_recovery: 0.35s

ranged_aim:     0.45s
ranged_fire:    instant (projectile spawn moment)
ranged_recover: 0.30s
```

The player thinks: "I can interrupt this," "I need to dodge," or "I can tank this to finish the repair."

### 2.4 Morale / Panic

A human grunt should feel human. A single morale variable drives behavioral variance.

**Morale drops when:**
- Nearby grunt dies
- Turret hits them
- Heavy stagger occurs
- They are alone
- Sector lights/power flicker
- They walk into a trap

**Low morale causes:**
- Slower aim
- Worse accuracy
- Brief hesitation
- Retreat to cover
- Reckless panic swing
- Calling for help

This matches the design note that mental state variance should be subtle through timing/accuracy — not big RNG spikes. Morale is not a binary "scared / not scared"; it is a continuous scalar.

### 2.5 Objective Pressure

Give the grunt a reason to ignore the player sometimes.

**Possible objectives:**
- Damage a turret
- Rip wiring from a power node
- Steal a schematic fragment
- Vandalize a console
- Open a door for later enemies
- Mark a sector for artillery/drone breach
- Drag scrap away

This turns combat into triage:

> Do I kill the grunt, repair the turret, reroute power, or stop the sabotage?

### Encounter Rules

These five behaviors make encounters interesting without adding enemy complexity.

| Encounter | Purpose | Design |
|-----------|---------|--------|
| **One grunt, hallway** | Teach attack timing | Grunt advances; player learns dodge/attack/stagger. No objective. |
| **Two grunts, one saboteur** | Teach prioritization | One attacks Custodian; one damages a turret or console. Player must decide. |
| **Grunt enters powered sector** | Teach Command Center | If turret is powered, autopilot fires dumbly. Grunt may bait turret aim. Player can manually target better from Command Center. |
| **Grunt retreats** | Make survival matter | If low morale, grunt runs. If it escapes, later wave gets +1 alert level or alternate route. Killing is useful; preventing information leakage is also useful. |
| **Grunt drags something away** | Make enemy memorable | Grunt steals a data shard or power component, flees slowly while carrying it. Player can chase, shoot, or let autopilot try. Escaping has delayed consequence — not instant failure. |

The last one fits CUSTODIAN's guidance that interrupted enemy actions create delayed damage or future cost rather than immediate loss.

---

## 3. State Machine

One base enemy sprite, behavior state changes the encounter.

```
IDLE
PATROL
INVESTIGATE
APPROACH_OBJECTIVE
SABOTAGE
ENGAGE_PLAYER
AIM
ATTACK
STRAFE
TAKE_COVER
FLINCH
STAGGER
PANIC
RETREAT
DEAD
```

### Combat Verbs

```
- short_melee_strike     — close-range damage
- shove                  — guard-break, gap-close
- aimed_shot             — ranged attack
- sidestep               — reposition
- interruptible_sabotage — objective action, interruptible
- panic_retreat          — flee behavior
- callout                — alert nearby units
```

---

## 4. First Playable Slice

Do not start with parries, executions, advanced cover, squad tactics, or 15 weapons.

**Start with:**
- One grunt
- One melee attack
- One ranged attack
- One sabotage behavior
- One stagger state
- One panic/retreat state
- One field objective: damage a turret or steal a data shard

This gives: action combat, tactical decision pressure, enemy personality, CUSTODIAN theme, and a reason the player cares about more than HP bars.

### Combat Feel Implementation (v1)

These have minimal asset requirements and immediately improve feel:

1. Hit flash (modulate white → normal)
2. Knockback (directionally applied to velocity)
3. Directional flinch (animation plays in hit direction)
4. Screen shake — **only for heavy hits and explosions** (0.12s+), not for every hit
5. Brief hitstop (see values below)
6. Distinct enemy windup/recovery — readable by the player before damage lands
7. Audio: grunt bark, armor hit, stagger, death, panic

**Hitstop values:**

```
light hit:  0.035s
heavy hit:  0.070s
stagger:    0.090s
explosion:  0.120s
```

Do not overdo it. The goal is "crunch," not anime freeze-frame.

### Grunt Baseline Profile

| Parameter | Value |
|-----------|-------|
| HP | 30 |
| Move speed | 80.0 |
| Strafe speed | 60.0 |
| Melee damage | 8 |
| Melee range | 30.0 |
| Melee windup | 0.25s |
| Melee active | 0.12s |
| Melee recovery | 0.35s |
| Ranged damage | 6 |
| Ranged range | 180.0 |
| Ranged aim time | 0.45s |
| Ranged shot cooldown | 1.2s |
| Stagger threshold | 12.0 |
| Stagger duration | 0.45s |
| Morale max | 100.0 |
| Morale panic threshold | 25.0 |
| Sabotage duration | 2.5s |
| Sabotage damage | 10 |

---

## 5. Required Animation Assets

All animations are 8-directional (8dir) unless noted. Left-facing variants use flipped right-facing sprites unless explicitly overridden.

Each sprite strip should be requested with a clear save path:

```
custodian/assets/sprites/enemies/grunt/grunt_idle_8dir.png
  - 8 directions, 4 frames each
  - Alerted but not attacking; breathing idle

custodian/assets/sprites/enemies/grunt/grunt_walk_8dir.png
  - 8 directions, 6 frames each
  - Standard patrol/chase movement

custodian/assets/sprites/enemies/grunt/grunt_melee_windup_8dir.png
  - 8 directions, 3 frames each
  - Shoulder/torso commitment before strike

custodian/assets/sprites/enemies/grunt/grunt_melee_strike_8dir.png
  - 8 directions, 3 frames each
  - Fast active frame, readable arc

custodian/assets/sprites/enemies/grunt/grunt_ranged_aim_8dir.png
  - 8 directions, 3 frames each
  - Weapon raised, strong readable aim line

custodian/assets/sprites/enemies/grunt/grunt_ranged_fire_8dir.png
  - 8 directions, 2 frames each
  - Muzzle flash should be a separate FX overlay, not baked in

custodian/assets/sprites/enemies/grunt/grunt_flinch_8dir.png
  - 8 directions, 2 frames each
  - Small impact reaction

custodian/assets/sprites/enemies/grunt/grunt_stagger_8dir.png
  - 8 directions, 4 frames each
  - Bigger readable recoil, clear punish window

custodian/assets/sprites/enemies/grunt/grunt_sabotage_8dir.png
  - 8 directions, 6 frames each
  - Hands working on console/turret/wiring; interruptible

custodian/assets/sprites/enemies/grunt/grunt_death_8dir.png
  - 8 directions, 6 frames each
  - Short collapse, not too flashy
```

Animation event requirements:
- `damage_start` — hitbox activation begins
- `damage_end` — hitbox deactivation
- `cancel_start` — input buffering window opens (recovery phase)

---

## 6. Implementation Reference

### 6.1 Grunt Combat Profile Resource

```gdscript
# grunt_combat_profile.gd
extends Resource
class_name GruntCombatProfile

@export var max_hp: int = 30
@export var move_speed: float = 80.0
@export var strafe_speed: float = 60.0

@export var melee_damage: int = 8
@export var melee_range: float = 30.0
@export var melee_windup: float = 0.25
@export var melee_active: float = 0.12
@export var melee_recovery: float = 0.35

@export var ranged_damage: int = 6
@export var ranged_range: float = 180.0
@export var ranged_aim_time: float = 0.45
@export var ranged_shot_cooldown: float = 1.2

@export var stagger_threshold: float = 12.0
@export var stagger_duration: float = 0.45

@export var morale_max: float = 100.0
@export var morale_panic_threshold: float = 25.0
@export var morale_recovery_per_second: float = 4.0

@export var sabotage_duration: float = 2.5
@export var sabotage_damage: int = 10
```

### 6.2 Hit Reaction Component

```gdscript
# hit_reaction_component.gd
extends Node
class_name HitReactionComponent

signal flinched(direction: Vector2)
signal staggered(direction: Vector2)
signal died()

@export var max_hp: int = 30
@export var stagger_threshold: float = 12.0
@export var stagger_duration: float = 0.45
@export var knockback_force: float = 90.0

var hp: int
var stagger_meter: float = 0.0
var is_staggered: bool = false

func _ready() -> void:
    hp = max_hp

func apply_hit(
    damage: int,
    stagger_damage: float,
    hit_direction: Vector2,
    is_heavy: bool = false
) -> void:
    hp -= damage
    stagger_meter += stagger_damage

    if hp <= 0:
        died.emit()
        return

    if is_heavy or stagger_meter >= stagger_threshold:
        stagger_meter = 0.0
        is_staggered = true
        staggered.emit(hit_direction.normalized())
        await get_tree().create_timer(stagger_duration).timeout
        is_staggered = false
    else:
        flinched.emit(hit_direction.normalized())
```

### 6.3 Morale Component

```gdscript
# morale_component.gd
extends Node
class_name MoraleComponent

signal panicked()
signal recovered()

@export var morale_max: float = 100.0
@export var panic_threshold: float = 25.0
@export var recovery_per_second: float = 4.0

var morale: float
var is_panicked: bool = false

func _ready() -> void:
    morale = morale_max

func apply_morale_damage(amount: float) -> void:
    morale = maxf(0.0, morale - amount)

    if morale <= panic_threshold and not is_panicked:
        is_panicked = true
        panicked.emit()

func recover(delta: float) -> void:
    if is_panicked:
        return

    morale = minf(morale_max, morale + recovery_per_second * delta)

func force_recover() -> void:
    is_panicked = false
    morale = morale_max * 0.5
    recovered.emit()
```

---

## 7. Notes

- Morale events fire signals (`panicked`, `recovered`) so the grunt's animation tree, audio system, and Director telemetry can respond independently.
- Grunt state transitions should be driven by signal listeners on `HitReactionComponent` and `MoraleComponent`, not polled every frame.
- When a grunt is in `SABOTAGE` state, the animation must be interruptible by any hit that triggers `flinched`. Stagger interrupts and restarts the sabotage timer.
- Hitstop is applied on the player side (`operator.gd` / `combat_manager.gd`), not inside the grunt — it pauses time scale briefly on confirmed hit.
- Screen shake for heavy hits uses the same `Camera2D.shake()` path as player attacks, gated by a `shake_on_heavy` flag or separate `heavy_hit_shake_power` export.
