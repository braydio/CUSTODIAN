# CUSTODIAN — Combat Resource and Readability System

## Packet Status

- Status: draft
- Owner: Brayden / Codex
- Target runtime: Godot 4.x
- Target folder: `design/20_features/in_progress/`
- Proposed filename: `COMBAT_RESOURCE_AND_READABILITY_SYSTEM.md`

## Purpose

CUSTODIAN combat currently risks becoming too easy when the player can rely on ranged spam, especially assault rifle fire, without meaningful tactical cost. This system adds combat resource pressure, weapon limitations, readable enemy responses, defensive timing, and physical world logistics so that the player must make tactical decisions instead of simply gunning down every enemy.

The goal is not to make the game slower. The goal is to make each combat choice carry a cost.

Core design statement:

> CUSTODIAN is real-time tactical survival combat: the player acts in real time, but every action affects resources, noise, durability, recovery, route safety, and future survival.

---

# 1. Immediate Problem

## Current issue

Ranged combat is too dominant.

The player can:

- use the assault rifle as the default answer
- fire constantly
- avoid melee risk
- avoid meaningful ammo pressure
- ignore fabrication/resource economy during combat
- clear rooms without needing turrets, traps, repair tools, melee, or parry

## Required correction

Ranged combat should become a **burst tool**, not a permanent firehose.

The player should still enjoy shooting, but should have to decide when it is worth spending:

- ammo
- weapon heat
- noise/attention
- durability
- reload/vent time
- opportunity cost of not using tools, melee, guard, traps, or turrets

---

# 2. Design Pillars

## Pillar A — Ranged is powerful but costly

Ranged weapons should be strong, readable, and satisfying, but they should create pressure.

Costs may include:

- ammo consumption
- magazine/reload downtime
- weapon heat
- increased enemy attention
- durability wear
- reduced movement while firing
- vulnerability during reload/vent
- limited supply in the field

## Pillar B — Melee is useful but dangerous

Melee should conserve resources and feel grounded.

Melee should be favored when:

- enemies are weak or isolated
- the player wants to preserve ammo
- stealth/noise matters
- the enemy is vulnerable after parry, stagger, or hit react

Melee should be risky when:

- enemies have armor
- enemies have long reach
- enemies swarm
- the player mistimes commitment
- ranged enemies force spacing

## Pillar C — Defense is an active skill

Defense should not be passive.

Core defensive actions:

- tap secondary while not aiming = parry
- hold secondary while not aiming = guard
- dodge = reposition, not free invulnerability spam

Parry should be high-risk/high-reward.
Guard should be safer but resource-draining.
Dodge should solve positioning but create recovery vulnerability.

## Pillar D — The battlefield is part of combat

Combat should not only be Operator vs enemy.

The player should be able to clear areas through:

- direct melee/ranged combat
- repairing local turrets
- placing portable turrets
- setting traps
- using drone allies
- luring enemies into hazards
- sealing doors or restoring gates
- retreating to supply caches
- rerouting power
- using tool loadouts instead of weapon loadouts

## Pillar E — Resources must matter outside fabrication

Resources currently matter mostly for fabrication. They need to matter during combat and area control.

Combat should create demand for:

- ammo
- repair supplies
- weapon parts
- batteries / power cells
- coolant / heat sinks
- armor patches
- drone parts
- turret kits
- trap kits
- field medical supplies

---

# 3. Core Combat Resources

## 3.1 Ammo

Ammo should no longer fall from the sky in enough quantity to trivialize combat.

### Rules

- Assault rifle ammo should be useful but limited.
- Enemies should not universally drop ammo.
- Ammo drops should be contextual:
  - soldier-type enemies may drop ammo
  - beasts/cosmic enemies should not
  - ruins may contain ammo caches
  - storage lockers may hold ammo if previously stocked

- Ammo should compete with fabrication use.

### Design effect

The player should think:

> “Do I spend rifle ammo here, or save it for the gatehouse?”

---

## 3.2 Weapon Heat

There should be a physical weapon heat resource, separate from enemy attention.

### Definition

Weapon heat represents the weapon becoming mechanically unstable from sustained fire.

### Applies to

- assault rifle
- energy sidearm
- beam weapons
- automatic weapons
- certain heavy tools

### Behavior

Each shot adds heat.
Heat dissipates over time.
High heat reduces performance.
Overheat forces a vent/recovery window.

### Possible heat states

```text
0%–49%   Stable
50%–79%  Hot: slight spread/recoil increase
80%–99%  Critical: accuracy loss, warning VFX/audio
100%     Overheated: weapon cannot fire until vented
```

### Design effect

Ranged fire becomes burst-based.

The player can still unload, but doing so creates a tactical pause where they must:

- dodge
- guard
- switch weapon
- melee
- retreat
- use turret/trap support

---

## 3.3 Attention / Noise

This is separate from physical heat.

### Definition

Attention represents the world/enemy director noticing combat activity.

Gunfire, explosions, generator repair, turret activation, and terminal pulses increase attention.

### Sources

- firing loud weapons
- using heavy tools
- activating terminals
- restoring power
- placing or activating turrets
- triggering traps
- prolonged combat
- enemies sounding alarms

### Effects

At higher attention:

- nearby patrols investigate
- dormant enemies wake up
- reinforcements spawn
- thieves attempt resource raids
- ritualists accelerate objectives
- sector danger increases

### Design effect

The player should think:

> “I can shoot my way out, but I might wake the whole wing.”

---

## 3.4 Durability

Durability should be added next after ranged balance.

### Applies to

- melee weapons
- firearms
- armor
- guard tools
- utility tools
- deployables
- drones
- turrets

### Behavior

Durability should degrade from use, blocking, enemy impacts, overheat events, and heavy attacks.

### Important distinction

Durability should not be annoying maintenance spam. It should create strategic tension.

Good durability design:

- weapons do not break instantly
- degradation is predictable
- field repair is possible but costly
- high-tier gear still needs care
- blocking heavy hits damages equipment
- overheating accelerates wear

### Design effect

The player should think:

> “I can guard this brute, but my shield tool is going to take a beating.”

---

## 3.5 Health

Health needs to exist as a combat survival resource with a healing mechanic.

### Desired direction

Healing should be limited, physical, and tactical. It should not be free regeneration.

Recommended healing model:

## Field Repair / Med-Gel Hybrid

The Custodian is not a normal human. Healing should feel like emergency maintenance.

Possible names:

- Field Patch
- Redundant Life Support
- Tissue Sealant
- Biofoam Canister
- Custodian Repair Dose
- Emergency Stitch Charge
- Vital Sealant

### Suggested mechanic

The player carries a small number of **Field Patches**.

Using one:

- locks the player briefly in an animation
- restores part of health
- consumes a physical resource
- can be interrupted
- can be upgraded later
- may restore less if used while taking damage

### Recommended early values

```text
Max Field Patches: 2
Use time: 1.1–1.4 seconds
Restore amount: 35% max health
Can move slowly while using: optional
Interrupted by heavy hit: yes
```

### Strategic layer

Field Patches are crafted or restocked from resources:

```text
fibrous moss
resin clot
medical salvage
power components
sterile thread
memory glass fragment, later upgraded
```

### Design effect

The player should think:

> “If I heal now, I survive the fight, but I may not have enough supplies for the return route.”

---

## 3.6 Stamina / Poise / Guard Integrity

The player needs a defensive limiter.

### Applies to

- dodge
- guard
- heavy melee
- parry failure
- blocking large enemies

### Suggested model

Do not necessarily call it “stamina” in UI if that feels too fantasy. Possible names:

- Stability
- Brace
- Poise
- Servo Load
- Balance
- Guard Integrity

### Behavior

- Dodge consumes stability.
- Guard drains stability while absorbing hits.
- Parry failure causes stability damage.
- Heavy enemy hits can break guard.
- Stability refills after a short delay.

### Design effect

The player cannot infinitely dodge or turtle.

---

# 4. Ranged Balance Implementation

## 4.1 Assault Rifle

The assault rifle should be powerful but controlled.

### Proposed characteristics

```text
Role: sustained burst weapon
Strength: suppresses light enemies, interrupts channels
Weakness: heat, ammo use, noise, reload downtime
```

### Required limits

- magazine size
- recoil/spread increase during burst
- heat buildup
- reload animation
- ammo scarcity
- noise/attention spike
- reduced accuracy while moving
- less effective against armored enemies unless hitting weak points

### Anti-spam rule

The assault rifle should never be the cheapest answer.

If it is the safest answer, it should be expensive.
If it is cheap, it should be risky.
If it is both safe and cheap, it breaks the game.

---

## 4.2 Sidearm

The sidearm should be reliable but not dominant.

### Role

The sidearm is the fallback ranged weapon.

### Suggested behavior

- lower damage than rifle
- lower heat
- better quick draw
- useful for interrupts
- limited range
- lower noise
- can be used when no primary ranged weapon is equipped
- can possibly be used while carrying a utility tool

### Control rule

```text
Hold aim + primary = current ranged weapon
Hold aim + tap secondary = sidearm/offhand shot
No aim + tap secondary = parry
No aim + hold secondary = guard
```

This keeps defensive actions and ranged actions from fighting each other.

---

## 4.3 Utility Tool vs Gun Slot

The wrench/repair tool should compete with weapon readiness.

### Rule

The player should not have full gun access and full repair/tool access at the exact same time.

Possible loadout states:

```text
Primary weapon equipped
Secondary/sidearm available
Utility tool equipped
Deployable selected
```

### Example tradeoff

If the player equips the utility wrench:

- can repair turrets/gates/conduits faster
- can interact with machinery in combat
- may lose access to rifle
- may only retain sidearm fallback
- becomes more dependent on traps, turrets, melee, or drones

### Design effect

The player chooses between:

```text
direct killing power
field control
repair capability
defensive safety
resource recovery
```

---

# 5. Enemy Readability

Enemies need clearer combat communication.

## Required enemy animation states

Every combat enemy should ideally support:

```text
idle
move
windup
active attack
recovery
hit react
stagger
parried / opened
death
```

Special enemies may also support:

```text
guard
parry
counterattack
channel
interrupt
flee with stolen resource
call alarm
```

## 5.1 Windups

Windups must be readable.

A good enemy attack should show:

- body orientation
- weapon/limb preparation
- timing cue
- threat direction
- whether it is parryable
- whether it should be dodged instead

## 5.2 Hit Reacts

Enemies need hit reacts so the player understands that attacks matter.

### Types

```text
Light hit react
Heavy hit react
Armor deflect
Interrupt react
Stagger
Parry-opened state
```

### Important rule

Not every hit should fully stun every enemy.

Light enemies can flinch often.
Heavy enemies should resist light flinch.
Armored enemies may only react to heavy hits, weak points, parries, or explosives.

## 5.3 Custodian Hit Reacts

The player also needs hit reacts.

Required states:

```text
light hit
heavy hit
guard impact
guard break
parry success
parry fail
knockdown / stagger
healing interrupted
death / critical
```

The player should be able to feel when they made a mistake.

---

# 6. Parry System

## 6.1 Player Parry

Parry should become a fully animated mechanic, not just a timing flag.

### Required player animations

```text
parry_start
parry_active
parry_success
parry_fail
parry_recovery
riposte_start
riposte_hit
riposte_recovery
```

### Timing model

```text
startup frames: player begins parry
active window: incoming parryable attack can be caught
success branch: enemy enters opened/parried state
fail branch: player enters recovery or gets hit
recovery: player cannot immediately spam parry
```

### Suggested starting values

```text
startup: 0.08–0.12s
active window: 0.12–0.18s
success freeze/hitstop: 0.06–0.10s
fail recovery: 0.35–0.50s
success recovery: 0.15–0.25s
riposte window: 0.7–1.0s
```

These values should be tuned in-game.

---

## 6.2 Enemy Parried State

When an enemy is parried, it should visibly enter a vulnerable state.

Required enemy states:

```text
parried_start
parried_loop / opened
riposte_received
riposte_recovery or death
```

### Visual language

A parried enemy should show:

- weapon knocked aside
- torso opened
- head/limb recoil
- brief exposed posture
- clear riposte opportunity

The player should immediately understand:

> “Now. Punish.”

---

## 6.3 Riposte / Special Punish

There should be a special follow-up attack after a successful parry.

### Behavior

After successful parry:

- enemy enters opened state
- player gets a short riposte window
- primary melee input performs special punish
- punish deals high damage or armor break
- animation should be unique and satisfying

### Possible CUSTODIAN-flavored punish names

- Breach Strike
- Severance Thrust
- Custodian Rebuttal
- Return Blow
- Execution Seal
- Systemic Rupture

Recommended neutral term:

```text
Riposte
```

Use plain terminology in code. Flavor can be applied in UI later.

---

## 6.4 Enemy Parry

Some special enemies should be able to parry the player.

### Rule

Not all enemies can parry.

Enemy parry should belong to:

- elite duelists
- corrupted custodians
- special ruin knights
- ritual guardian enemies
- trained humanoid enemies

### Behavior

Enemy parry should punish predictable melee spam.

The enemy can:

- enter parry stance
- parry frontal melee attacks
- briefly stagger the player
- counterattack if the player keeps attacking
- be beaten by delay, ranged attacks, heavy attacks, flanking, traps, or tools

### Design effect

The player must read the enemy instead of mashing melee.

---

# 7. Physical Storage and Resource Theft

The game already has the idea that enemies can steal resources. This should become visible and physical.

## 7.1 Physical Storage Objects

Resources should be stored in world containers.

Examples:

```text
field cache
ammo crate
scrap locker
power cell rack
medical case
fabrication bin
drone parts case
turret kit crate
```

## 7.2 Visible Resource State

Storage should render its state.

Examples:

```text
empty
low
half full
full
damaged
being raided
locked
powered
```

The player should be able to see what is at risk.

## 7.3 Enemy Theft Behavior

Certain enemies should attempt to steal from storage.

Thief behavior:

```text
detect storage
path to storage
open/attack storage
extract resource bundle
carry visible bundle
flee to exit/nest
drop bundle if killed/staggered
successfully remove resource if escape completes
```

## 7.4 Gameplay Purpose

This makes resources matter spatially.

The player should care where resources are stored and whether the area is safe.

---

# 8. Deployables, Turrets, Traps, and Drones

The player should have multiple ways to clear a combat space.

## 8.1 Portable Turrets

Portable turrets let the player spend resources before or during a fight for area control.

### Costs

- turret kit
- ammo
- battery
- setup time
- durability
- retrieval time

### Strengths

- holds choke points
- supports tool loadouts
- covers retreats
- distracts enemies

### Weaknesses

- can be destroyed
- needs power/ammo
- creates attention/noise
- may be stolen or disabled
- takes time to deploy

---

## 8.2 Traps

Traps provide preparation-based combat.

Examples:

```text
shock snare
trip mine
scrap caltrops
signal lure
oil slick / ignition trap
collapse trigger
door charge
```

### Design rule

Traps should reward planning, not replace fighting entirely.

---

## 8.3 Combat Drones

The player needs combat drone allies animated and wired.

Drone roles:

```text
attack drone
shield drone
repair drone
lure drone
scanner drone
interceptor drone
```

Start simple.

Recommended first drone:

```text
Light combat drone
- follows player
- targets nearest hostile
- fires short bursts
- has limited battery
- can be damaged
- can be repaired
- returns to player when inactive
```

### Required drone animations

```text
idle hover
move hover
aim / acquire target
fire burst
hit react
disabled / falling
repair / reboot
death / destroyed
```

---

# 9. Healing System

Health and healing need to be implemented alongside combat difficulty.

## Recommended healing model

Use **Field Patches** as the first healing system.

### Field Patch behavior

```text
Input: quick item / heal button
Cost: 1 Field Patch
Animation: 1.1–1.4s
Effect: restore partial health
Risk: can be interrupted
Supply: limited
Restock: crafted or found in physical caches
```

### Why this works

It fits CUSTODIAN because healing is not magic. It is emergency maintenance of a damaged survivor.

### Possible ingredients

```text
fibrous moss
resin clot
medical salvage
sterile thread
power components
capacitor dust
```

### Upgrade path

Later upgrades can add:

- faster application
- higher restore amount
- overheal shield
- repair armor damage
- cure anomaly buildup
- drone-assisted heal
- emergency auto-injector

---

# 10. Implementation Order

## Phase 1 — Best immediate fix: ranged burst limitation

This is the highest-value fix because it directly solves the assault rifle problem.

Implement:

```text
weapon heat
magazine/reload if not already present
ammo scarcity tuning
shot noise/attention event
spread/recoil increase during sustained fire
overheat/vent state
```

### Codex instruction

Add a weapon heat component/resource path to the Operator ranged weapon flow. Each ranged shot should add heat. Heat should decay over time. At max heat, the weapon enters an overheated state and cannot fire until vented below a threshold. Automatic weapons should heat faster than sidearms. Add debug output or visible UI hooks so heat can be tuned.

---

## Phase 2 — Ammo/resource economy pass

Implement:

```text
ammo inventory counts
ammo pickups reduced
enemy ammo drops restricted by enemy type
ammo caches as physical objects
fabrication recipes consuming ammo-related materials
```

### Codex instruction

Audit current ammo pickup/drop flow. Reduce universal ammo drops. Add enemy drop classification so only appropriate enemies can drop ammunition. Add cache/container support for ammo as a world resource instead of constant loose pickups.

---

## Phase 3 — Health and Field Patch healing

Implement:

```text
player health state
field patch item count
heal animation lock
heal interrupt rules
partial restore
resource-based restock/craft hook
```

### Codex instruction

Add a Field Patch healing action. The action should consume a limited healing item, play a use animation, restore partial health after a timed commit point, and be interruptible by heavy hit/stagger. Expose healing amount, use duration, and max carried patches as tunable values.

---

## Phase 4 — Hit reacts and readability

Implement:

```text
enemy hit react states
player hit react states
guard impact feedback
damage numbers optional, not required
hitstop and impact flash
animation hooks
```

### Codex instruction

Add a lightweight hit reaction state path for enemies and the Operator. Damage events should classify hit strength as light, heavy, interrupt, armor deflect, or stagger. Enemies should not all react the same way. Heavy enemies may ignore light flinch.

---

## Phase 5 — Parry full implementation

Implement:

```text
parry startup
active parry window
recovery
success state
fail state
enemy parried/opened state
riposte window
special punish attack
```

### Codex instruction

Replace placeholder parry behavior with an animation-timed parry state machine. Parry should have startup, active, success, fail, and recovery windows. On success, the enemy enters a parried/opened state. During the riposte window, primary melee should trigger a special punish attack.

---

## Phase 6 — Guard and stability resource

Implement:

```text
guard hold
guard drain
stability/poise resource
guard break
dodge cost
heavy impact stability damage
```

### Codex instruction

Add a Stability or Guard Integrity resource to the Operator. Dodge, guard, heavy impacts, and parry failure should interact with this resource. Guard should absorb or reduce damage while draining stability. If stability reaches zero, trigger guard break.

---

## Phase 7 — Durability

Implement:

```text
weapon durability
armor durability
tool durability
turret/drone durability
field repair
durability UI/debug display
```

### Codex instruction

Add durability data to weapons/tools/deployables. Durability should decrease from weapon use, guard impacts, overheating, heavy attacks, and enemy damage. Durability should affect performance before total breakage where appropriate. Add repair hooks using existing resource items.

---

## Phase 8 — Physical storage and visible theft

Implement:

```text
storage crate entities
visible fill state
enemy theft target selection
carry stolen resource bundle
drop-on-death behavior
escape success behavior
```

### Codex instruction

Create world storage objects that hold typed resources. Storage should expose its contents to enemy objective logic. Resource thief enemies should path to storage, extract a visible bundle, flee, and drop the bundle if killed before escape.

---

## Phase 9 — Deployables: portable turret and traps

Implement:

```text
portable turret deploy
trap placement
setup time
resource cost
retrieval/repair
enemy interaction with deployables
```

### Codex instruction

Add a deployable placement action that consumes an item/resource, previews a valid placement tile, and spawns a deployable turret or trap. Deployables should have health/durability, optional ammo/power limits, and enemy targeting.

---

## Phase 10 — Combat drone ally

Implement:

```text
drone follow behavior
target acquisition
burst fire
battery/durability
hit react
disabled state
repair/reboot
```

### Codex instruction

Add a simple combat drone ally with follow, acquire target, fire burst, damaged, disabled, and repair states. Keep the first version minimal and tunable. Do not overbuild drone command UI yet.

---

# 11. Required Animation Asset List

## Operator

Required:

```text
parry_start
parry_active
parry_success
parry_fail
parry_recovery
riposte_start
riposte_hit
riposte_recovery
guard_start
guard_loop
guard_impact_light
guard_impact_heavy
guard_break
light_hit_react
heavy_hit_react
heal_start
heal_apply
heal_recovery
reload
vent_overheat
```

## Enemy baseline

Required for most combat enemies:

```text
windup
attack_active
attack_recovery
light_hit_react
heavy_hit_react
stagger
parried_opened
riposte_received
death
```

## Special parry-capable enemies

Additional:

```text
enemy_parry_start
enemy_parry_active
enemy_parry_success
enemy_counterattack
enemy_parry_fail
```

## Drones

Required:

```text
idle_hover
move_hover
target_acquire
fire_burst
hit_react
disabled
repair
destroyed
```

## Storage and resources

Required:

```text
storage_empty
storage_low
storage_half
storage_full
storage_damaged
storage_being_raided
stolen_resource_bundle_carried
stolen_resource_bundle_dropped
```

---

# 12. Recommended First Milestone

The first milestone should not try to implement everything.

## Milestone 1: Stop ranged spam

Scope:

```text
weapon heat
overheat/vent
basic ammo scarcity
shot noise event
assault rifle tuning
sidearm distinction
debug UI
```

Success criteria:

- player cannot fire rifle forever
- rifle is still satisfying in bursts
- sidearm has a reason to exist
- melee becomes relevant again
- shooting creates tactical consequences
- ammo pickups stop trivializing combat

## Milestone 2: Make hits readable

Scope:

```text
enemy hit reacts
player hit reacts
guard impact
basic stagger
impact VFX/audio hooks
```

Success criteria:

- player can tell when enemies are hurt
- player can tell when attacks are blocked/deflected
- player can tell when they are punished
- enemy attacks feel fairer because feedback is clearer

## Milestone 3: Add survival pressure

Scope:

```text
health
Field Patch healing
healing animation lock
healing item scarcity
resource-based restock
```

Success criteria:

- damage matters
- healing is tactical
- resources matter during combat
- survival extends beyond the current room

## Milestone 4: Full parry/riposte

Scope:

```text
animation-timed parry
enemy opened state
riposte punish
parry failure recovery
special enemy parries later
```

Success criteria:

- parry feels physical
- parry is not spammable
- successful parry creates a satisfying punish
- enemy parry can later punish melee spam

---

# 13. Documentation Drift / Integration Notes

This system overlaps with the following existing or expected systems:

```text
COMBAT_FEEL_SYSTEM.md
TURRET_SYSTEM.md
ENEMY_OBJECTIVE_SYSTEM.md
ENEMY_BEHAVIOR_DIRECTOR.md
REPAIR_GAMEPLAY_SYSTEM.md
WAVE_SPAWNING_SYSTEM.md
SECTOR_DAMAGE_SYSTEM.md
```

Before implementation, check whether any of those docs already define:

- player health
- ammo economy
- turret deployment
- repair resources
- enemy theft behavior
- combat director attention
- parry/guard timing
- weapon data schema

If those docs already define these concepts, this document should either:

1. become the central combat-resource spec, with the others linking to it, or
2. be split into smaller specs:
   - `WEAPON_HEAT_AND_AMMO_SYSTEM.md`
   - `HEALTH_AND_FIELD_PATCH_SYSTEM.md`
   - `PARRY_AND_RIPOSTE_SYSTEM.md`
   - `PHYSICAL_RESOURCE_STORAGE_SYSTEM.md`
   - `DEPLOYABLE_COMBAT_SYSTEM.md`

Recommended action:

Start with this as one planning document. After Milestone 1, split it into smaller implementation specs if it becomes too large.

---

# 14. Codex Starter Task

Use this as the first implementation request:

```text
Implement Milestone 1 from design/20_features/in_progress/COMBAT_RESOURCE_AND_READABILITY_SYSTEM.md.

Goal:
Stop assault rifle/ranged spam by adding weapon heat, overheat/vent behavior, basic ammo scarcity hooks, and shot noise/attention events.

Requirements:
1. Add heat tracking to ranged weapons.
2. Each shot adds heat.
3. Heat decays over time.
4. At max heat, weapon enters overheated state.
5. Overheated weapons cannot fire until heat drops below a recovery threshold or vent completes.
6. Automatic weapons should build heat faster than sidearms.
7. Add tunable exported values for heat gain, heat decay, overheat threshold, recovery threshold, and vent duration.
8. Add debug UI/logging so heat behavior can be tuned.
9. Do not rewrite unrelated combat systems.
10. Preserve existing melee/ranged loadout behavior unless directly required.
11. Add documentation notes for any changed file paths or assumptions.

Also audit current ammo pickup/drop logic and report where ammo is currently created, dropped, or awarded. Do not fully rebalance ammo yet unless the change is trivial and isolated.
```
