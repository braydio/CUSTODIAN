# Routebreaker Frame

- **Status:** draft / planned
- **Owner:** allied units / encounter design
- **Runtime:** `custodian/` Godot 4.x

## Summary

The Routebreaker Frame is a **temporary battlefield ally / setpiece** — a ruined Custodian war-frame that the player powers up for specific encounters. It is not a permanent pet. It is slow, huge, loud, devastating, and has limited uptime.

**Fantasy:** "This thing is on your side, barely."

**Gameplay:** walking artillery bunker, not a second player. It blocks space, draws enemy aggro, fires heavy bursts, and has a heat/cooldown system that prevents constant use.

**First encounter location:** Sundered Keep / Return Causeway arc — dormant on the mainland ascent, activated for the hilltop reveal traversal, anchored at the Sundered Keep gate siege.

## Core Constraints

### Should
- Move slowly
- Block space / body-block enemies
- Draw enemy aggro
- Fire heavy burst attacks
- Have a heat and cooldown system
- Need player resources to activate (power link / signal filament / structural alloy)
- Struggle with stairs and narrow paths
- Only activate in specific authored zones

### Should NOT
- Follow the player everywhere
- Fit through normal doors
- Path perfectly through tight map geometry
- Shoot constantly
- Replace the player's combat choices

## Encounter Sequence

```
1. Player finds dormant mech half-buried near the mainland ascent.
2. It is too damaged to move.
3. Player restores a power link / signal filament / structural alloy.
4. Mech wakes up during a siege or ambush.
5. It joins for one major combat stretch (hilltop → lateral traverse).
6. At the gate/overlook, it anchors itself and becomes a defensive turret / obstruction.
```

## Gameplay Kit

### Passive Behavior
- Follows player only in wide outdoor zones
- Stops at `mech_boundary` markers (cannot enter interiors or narrow paths)
- Holds position when enemies are nearby
- Turns slowly toward threats
- Prioritizes enemies targeting the player

### Main Attack: Anchor Cannon
A slow burst weapon with windup, fire, and recover phases.

| Property | Value |
|---|---|
| Windup | 0.75s |
| Fire | explosive projectile / beam / heavy slug |
| Cooldown | 2.5s |
| Cost | heat |
| Effect | knockback + armor break |

### Secondary Behavior: Guardian Intercept
When an enemy gets close to the player, the mech does a heavy stomp.

| Property | Value |
|---|---|
| Range | short (melee contact) |
| Cooldown | 5s |
| Effect | stagger enemies, buys breathing room |

### Weaknesses
- Cannot chase fast enemies well
- Cannot enter interiors
- Overheats (heat must decay before firing again)
- Can be disabled by sustained enemy pressure
- Draws special enemy focus when active

## Visual Design

Not sleek. A cursed industrial relic.

**Silhouette:**
- Wide shoulders
- One ruined arm cannon
- One manipulator claw / shield arm
- Hunched reactor back
- Heavy legs
- Red-black gothic plating
- Tiny pale eye slit
- Custodian field markings
- Exposed cabling
- Worn mechanical halo / sensor mast

**Scale:**

| Element | Size |
|---|---|
| Visual frame | 160×160 or 192×192 |
| Collision body | ≈52×60 |
| Navigation footprint | 2×2 tiles |

## MVP Animation Set

Save under `custodian/assets/sprites/allies/routebreaker_frame/`:

```
idle_south.png
idle_southeast.png
idle_east.png

walk_south.png
walk_southeast.png
walk_east.png

cannon_windup_south.png
cannon_fire_south.png
cannon_recover_south.png

stomp_south.png
hit_south.png
disabled_south.png
wake_up_south.png
```

Mirror east → west where possible. Add north-facing only after MVP works.

## Godot Implementation

### Scene Structure

```
RoutebreakerFrame (CharacterBody2D)
├── AnimatedSprite2D
├── CollisionShape2D
├── DetectionArea (Area2D)
│   └── CollisionShape2D
├── AttackOrigin (Marker2D)
├── StompArea (Area2D)
│   └── CollisionShape2D
├── CooldownTimer (Timer)
└── NavigationAgent2D
```

### Runtime Files

| Path | Type | Role |
|---|---|---|
| `res://game/actors/allies/routebreaker_frame.tscn` | Scene | Mech actor with AnimatedSprite2D, collision, areas, timer |
| `res://game/actors/allies/routebreaker_frame.gd` | Script | State machine: dormant / waking / idle / walk / cannon_windup / cannon_fire / cannon_recover / anchored / disabled |
| `res://game/actors/allies/routebreaker_projectile.tscn` | Scene | Anchor cannon projectile (optional, could be hitscan) |
| `res://game/world/sundered_keep/routebreaker_activation_area.gd` | Script | Area2D that calls `activate()` when player enters |

### Activation Area Script

Attach to an Area2D placed at the hilltop / gate approach. When the player enters, it triggers the mech wake sequence.

## Balance Limits

Three hard limits prevent the mech from breaking combat:

1. **Heat** — cannot fire forever. Heat decays over time. Overheat = disabled until fully cooled.
2. **Anchor zones** — only fully fights in outdoor siege spaces with `mech_boundary` markers.
3. **Enemy response** — when active, special enemies target it or try to disable it.

## Integration with Sundered Keep Approach

The mech is tightly coupled to the Sundered Keep approach sequence:

1. Player walks up mainland hill → sees dormant mech beside ruined pylons
2. Player reaches overlook → vista opens: Sundered Keep across the sea
3. Mech wakes behind player with heavy servo sound
4. Player traverses laterally along cliff wall
5. First ambush hits → mech fires once and deletes a heavy enemy
6. Mech overheats → player fights normally while it cools down
7. At Sundered Keep gate → mech anchors and becomes a defensive turret for the siege

## First Milestone Checklist

- [ ] Static dormant mech prop (animated disabled sprite)
- [ ] Activation trigger (Area2D + script)
- [ ] Wake animation playback
- [ ] Follow player in wide outdoor zone (movement state machine)
- [ ] One cannon attack (windup → fire → recover)
- [ ] Anchor mode at Sundered Keep gate (turret behavior)
- [ ] Heat system (build, decay, overheat, cooldown)

## Future Work

- Guardian Intercept stomp attack
- Damage / hit reaction states
- Repair interaction (player spends resources to restore HP)
- Overheat visual FX (steam, glow, sputter)
- Enemy AI that specifically targets or disables the mech
- Full 8-direction animation set
- Production art for all states

## Related Files

- `design/05_levels/SUNDERED_KEEP_PHASE_1.md` — Sundered Keep level context
- `design/features/implementation/SUNDERED_KEEP_VISTA_APPROACH.md` — approach sequence where mech first appears
- `custodian/game/actors/allies/combat_drone.gd` — existing allied-unit template for reference
- `custodian/game/systems/drone/drone_manager.gd` — existing DroneManager (mech is not a drone but shares some ally patterns)
