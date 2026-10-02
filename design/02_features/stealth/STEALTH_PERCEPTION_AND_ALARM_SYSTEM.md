# CUSTODIAN - STEALTH PERCEPTION, AWARENESS, AND ALARM SYSTEM

**Status:** design draft; live primitives exist, shared architecture not yet implemented  
**Owner:** gameplay/stealth + actor perception + world alert systems  
**Runtime target:** Godot 4.x (`custodian/`)  
**Reviewed baseline:** `main@ba04d9e8ee` (2026-10-01)

## Purpose

Hearing is not a Vaultwing mechanic and it is not merely a gunfire side effect.
It is one sensory channel in CUSTODIAN's stealth and awareness model.

The live game already contains the beginning of this system: positional gunshot
noise, enemy vision cones, line-of-sight checks, hearing ranges, a detection
meter, suspicion/alert state, search memory, Operator stealth snapshots, and
material metadata for footstep noise and visibility. These pieces should
converge into a shared perception contract that can be consumed by ordinary
enemies, fauna, sentries, alarm devices, companions, and future social actors
without moving their behavior into one universal AI class.

The core rule is:

```text
world stimulus
    -> receiver-specific sensing
    -> local awareness / observation
    -> actor-specific interpretation and behavior
    -> optional explicit alert/alarm publication
```

An emitter never directly orders an enemy to aggro. A sensor never decides
species behavior. An alarm never grants supernatural knowledge to every actor
on the map.

## Live Foundation

At the reviewed baseline:

- `NoiseEventBus` is a generic autoload under
  `game/systems/stealth/`. Operator gunshots publish positional
  `NoiseEvent` objects with source, team, position, radius, kind, threat,
  loudness, suppression state, and a diagnostic timestamp.
- `EnemyPerceptionComponent` owns enemy visual LOS/cone checks, a detection
  accumulator, suspicion/alert thresholds, event hearing, investigation
  position, and last-known target memory.
- `EnemyBehaviorProfile` already exposes `vision_range_px`,
  `vision_cone_degrees`, `peripheral_vision_mult`, `hearing_range_px`,
  detection gain/decay, thresholds, and investigation memory. Different enemy
  archetypes already have meaningfully different values.
- Operator movement exposes a read-only stealth snapshot containing position,
  visibility, movement noise, and locomotion state. Discrete gunshots use
  `NoiseEventBus` instead of that continuous snapshot.
- Vaultwing has become a second real acoustic consumer, exposing the need for a
  cross-family sensing contract. Its current direct handler also exposed that
  the live `NoiseEvent` type is weakened to `Variant` at the bus boundary.
- `MaterialProfile` already carries `footstep_noise_mult`,
  `stealth_visibility_mult`, impact presentation identity, and a footstep
  sound family. V1 does not yet apply those material values to gameplay.
- The Combat Resource and Readability roadmap explicitly lists shared
  attention/alarm escalation as unimplemented.
- There is no production alarm network, camera/microphone sensor network,
  reinforcement escalation system, or normal-play awareness HUD.
- Carrow Yard already has an authored **Alarm Gantry** identity, but it is not
  yet a gameplay alarm device.

## Architectural Lock

### Awareness is receiver state

Noise is a stimulus. Sight is a stimulus. A tripped sensor is a stimulus.
"Alerted" belongs to the receiving actor or network, not to the event itself.

A gunshot therefore does not contain "make hostile." It contains facts about
the sound. Each receiver evaluates those facts according to its own senses,
relationship state, memory, and behavior policy.

### Sensing and behavior are separate

Shared stealth code may answer questions such as:

- was this stimulus detectable?
- where did it appear to originate?
- how strong/salient was it to this receiver?
- how certain is the observation?
- what sensory channel produced it?
- what source/relationship information is legitimately known?

Shared stealth code does **not** decide:

- dive the Operator;
- investigate with a squad;
- flee;
- bark;
- trigger a local alarm;
- ignore familiar allied machinery;
- approach bait;
- call for reinforcements.

Those remain actor/species/device policy.

### Relationships qualify response, not perception

A receiver may hear an ally, neutral creature, or unknown machine. Detection is
not equivalent to hostility.

Relationship resolution belongs after sensing and before hostile target
commitment. Neutral stimuli may still cause curiosity, investigation, alarm
logging, or environmental behavior.

### No psychic global alert meter

The default model is local and explicit:

```text
actor hears/sees something
    -> actor awareness changes
    -> actor may communicate
    -> nearby actor or alarm node receives that communication
    -> local network state may escalate
```

A future strategic pressure system may summarize local alert state, but it must
not substitute for physical sensing/communication.

## Sensory Channels

### 1. Acoustic events

Discrete loud actions publish through the existing stealth event boundary.

Initial semantic kinds should include, as real emitters are added:

- `gunshot`
- `explosion`
- `footstep`
- `impact`
- `melee_impact`
- `door` / `forced_entry`
- `voice` / `shout`
- `creature_call`
- `vehicle`
- `machinery`
- `alarm`
- `distraction`

Do not emit an event every frame for continuous locomotion. Continuous sources
such as ordinary movement or engine hum should use a bounded cadence or a
receiver-queryable sensory snapshot so the event bus does not become a
per-frame broadcast storm.

The current `radius_px` remains the source-authored maximum propagation
envelope during compatibility. Receiver sensitivity then determines whether a
particular listener notices an event inside that envelope. Long term, loudness
and attenuation should carry more semantic weight than a one-size-fits-all
radius, but the migration must preserve current weapon tuning first.

### 2. Visual awareness

Visual sensing keeps:

- range;
- primary cone;
- peripheral region;
- physical LOS;
- target visibility modifier;
- detection accumulation and decay;
- memory after LOS loss.

The current Enemy perception implementation is the first working consumer, not
the permanent owner of the generic math.

### 3. Proximity and contact

Some actors or sensors need nonvisual close-range awareness even when LOS is
poor. Existing `operator_awareness_bubble_px` is an example. Treat this as an
explicit proximity channel rather than an invisible extension of the vision
cone.

### 4. Electronic / authored sensors

Future devices can consume the same observation model without pretending to be
ordinary enemies:

- directional cameras;
- microphones;
- trip sensors;
- pressure or doorway sensors;
- alarm panels;
- powered sentries;
- vehicle sensors;
- location-specific infrastructure such as the Carrow Yard Alarm Gantry.

A camera can be visual-only. A microphone can be acoustic-only. A combined
sentry can have both.

## Sensor Sensitivity

Different receivers should hear and see the same world differently.

A shared perception profile should eventually expose receiver-side values such
as:

```text
vision range / cone / peripheral sensitivity
visual detection gain / decay
acoustic sensitivity
semantic acoustic-kind multipliers
suppressed-source response
investigation threshold
alert threshold
memory duration
proximity radius
allowed sensory channels
```

Examples:

- a Raider Marine has strong visual detection and moderate hearing;
- a Savage has shorter hearing range but reacts aggressively to salient noise;
- a Pursuit Frame has broad visual/peripheral coverage and strong persistence;
- a Vaultwing may hear gunshots or creature calls at long range but interpret
  them through species-local behavior;
- a microphone sensor may ignore visual data entirely and strongly amplify
  gunshot/alarm categories;
- a camera has no hearing but may have a narrow long cone.

Do not put those responses in `NoiseEvent`. They belong to the receiver.

## Acoustic Attenuation And Environment

The first implementation should remain cheap and deterministic:

```text
source envelope
x receiver sensitivity
x distance attenuation
x semantic-kind multiplier
= perceived acoustic salience
```

Later passes can layer:

- walls/closed-door attenuation;
- material absorption/reflection classes;
- weather masking;
- ambient machinery masking;
- elevation/open-air modifiers;
- indoor/outdoor transitions;
- powered sensor quality.

These must be measured additions, not a full acoustic simulation.

`MaterialProfile.footstep_noise_mult` is the natural bridge for surface-driven
movement noise once the shared acoustic contract is stable.

## Awareness State

A shared observation contract should support, but not force, a common semantic
ladder:

```text
UNAWARE
  -> CURIOUS / SUSPICIOUS
  -> INVESTIGATING
  -> AWARE / ALERTED
  -> SEARCHING
  -> DE-ESCALATING
```

The existing enemy blackboard already models several of these concepts through
`is_suspicious`, `is_alerted`, investigation position/timer, last-heard
position, LOS memory, pursuit, and search.

Do not require every actor to use every state. A Vaultwing may map a suspicious
observation to circling, retreat, perching, or attacking. A static microphone
may map it to one alarm-network event. A civilian may flee.

## Local Alarm Networks

Alarm escalation should be explicit infrastructure, not an invisible global
flag.

A future `AlarmNetwork` should be keyed by authored/local network identity and
accept alert publications from valid devices or actors. Candidate consequences:

- audible alarm/siren events;
- local lights or warning beacons;
- doors/gates locking or unlocking;
- guards changing patrol/objective policy;
- local reinforcements becoming eligible;
- terminals/minimap exposing an alarm state where fictionally justified;
- theft/sabotage behavior changing;
- local objectives accelerating or failing;
- alarm devices becoming sabotage targets;
- alarms themselves generating acoustic stimuli that other actors can hear.

Carrow Yard's Alarm Gantry is a natural first authored proof because its
fictional identity already supports the mechanic. Do not mechanically activate
it until the site's encounter/current-occupant design requires it.

## Player Awareness

"Player awareness" has two distinct meanings and should not be collapsed.

### Player-facing awareness feedback

The UI may communicate that the Operator is being noticed without becoming AI
authority.

Possible production cues:

- a restrained directional suspicion arc;
- a short "noticed" edge cue as one observer crosses a threshold;
- escalating audio/visual tension when a local alarm network changes state;
- an optional accessibility setting for stronger detection feedback;
- debug-only full sensor cones and numeric meters.

Normal play should avoid omniscient x-ray knowledge. A hidden enemy behind a
wall should not automatically appear just because its internal detection meter
changed.

### Operator sensory awareness

The Operator may also receive world-sound information as a player affordance:

- directional off-screen gunshot/alarm cues;
- audible machinery or creature calls;
- optional terminal/sensor upgrades that reveal more precise bearings.

This is presentation of world stimuli, not enemy-state disclosure.

## Gameplay Opportunities

A shared perception system enables:

1. **Stealth routes.** Sprinting, footsteps, doors, surface material, weapons,
   and deliberate waiting become meaningful choices.
2. **Distraction play.** Thrown objects, machinery, alarms, creature calls, or
   other authored sources can pull attention without hard-coded enemy commands.
3. **Suppressors with real tradeoffs.** Suppression reduces acoustic salience
   rather than turning a weapon magically silent.
4. **Enemy differentiation.** Profiles can differ by cone, persistence,
   hearing, peripheral vision, and semantic sensitivity instead of only health
   and speed.
5. **Wildlife ecology.** Fauna can notice combat, vehicles, bait interactions,
   storms, calls, or alarms but retain species-local responses.
6. **Alarm sabotage.** Players can disable, trigger, spoof, or exploit authored
   alarm infrastructure.
7. **Search behavior.** Last-heard and last-seen evidence can produce different
   search origins and certainty.
8. **Sensor gameplay.** Cameras, microphones, sentries, doors, and terminals can
   use the same perception observations.
9. **World reactivity.** A fight can alter nearby behavior without aggroing the
   entire map.
10. **Readable risk.** Player-facing suspicion feedback can explain why stealth
    failed without exposing every hidden actor.

## Runtime Shape

Keep the existing acoustic emitter boundary and generalize around it.

Expected eventual ownership:

```text
game/systems/stealth/
    noise_event.gd
    noise_event_bus.gd
    perception_observation.gd
    perception_profile.gd
    perception_sensor_component.gd
    alarm_network.gd              # later slice
    alarm_sensor.gd               # later slice
```

The exact filenames may tighten during implementation. The ownership boundaries
are the contract.

### NoiseEvent

Make `NoiseEvent` typed end-to-end. Do not degrade it to `Variant` or
Dictionary semantics at the shared boundary.

The event owns emitted facts only. Receiver-derived salience, certainty,
relationship interpretation, and behavior do not belong on it.

### PerceptionObservation

A typed observation should carry receiver-derived information such as:

- sensory channel;
- semantic stimulus kind;
- observed position;
- source if legitimately identifiable;
- salience/strength;
- certainty;
- source relationship snapshot when applicable;
- sequence/tick identity for deterministic diagnostics.

Behavior consumers should depend on this observation seam rather than the raw
event implementation.

### PerceptionSensorComponent

Once Enemy + Vaultwing prove the same evaluation rules, extract reusable sensor
math into a compositional component/service.

It may own detection math and observation production. It must not own enemy
behavior states, Vaultwing states, target selection policy, faction policy, or
presentation.

## Determinism And Performance

- Gameplay awareness state advances on fixed simulation ticks.
- Wall-clock timestamps are diagnostic only and never drive awareness logic.
- Discrete acoustic events should be bounded and semantic.
- Continuous sensing respects the existing simulation-interest cadence.
- The current signal broadcast is acceptable for the small live population, but
  a future scale pass should replace global fanout with a generic perception
  spatial index or bounded candidate query if profiling shows it necessary.
- Do not reuse `EnemySpatialIndex` as permanent generic authority merely
  because it already exists. A cross-family spatial service must have a neutral
  owner.
- DevObservatory should record event counts, detected/ignored counts, alert
  transitions, and alarm-network changes without influencing gameplay.

## Implementation Roadmap

### S0 - Contract repair and live bug closure

- Type `NoiseEvent` end-to-end through its factory, bus signal, emitter, and
  current consumers.
- Reproduce and close the live Vaultwing gunshot-handler error.
- Keep current enemy hearing outcomes equivalent.
- Add focused real-event regressions for Enemy and Vaultwing.

### S1 - Shared perception foundation

- Introduce a typed receiver-side observation contract.
- Extract shared acoustic detection math after comparing the live Enemy and
  Vaultwing requirements.
- Extract reusable vision/proximity math only where the second consumer proves
  the contract.
- Keep Enemy blackboard/behavior and Vaultwing behavior species-local.
- Migrate tuning toward a focused receiver perception profile without deleting
  working compatibility fields until consumers have moved.

### S2 - Expanded acoustic emitters and material response

Add real emitters incrementally for high-value actions:

- sprint/footstep cadence;
- hard landings;
- melee/world impacts;
- forced doors/breakage;
- explosions;
- vehicle/machinery events;
- creature calls and authored distractions.

Apply `MaterialProfile.footstep_noise_mult` only once deterministic movement
noise cadence and receiver sensitivity are stable.

### S3 - Local alarms and authored sensors

- Add local `AlarmNetwork` identity/state.
- Add one visual or acoustic sensor device.
- Add explicit actor/device publication into the network.
- Add one bounded consequence, such as local guard policy or gate/light state.
- Use Carrow Yard Alarm Gantry as a candidate authored proof only if its
  encounter design is ready.

### S4 - Player awareness and readability

- Add debug sensor-cone/salience views first.
- Playtest whether normal play needs directional suspicion feedback.
- Add the smallest non-omniscient production cue that explains detection.
- Add directional world-sound cues separately if they improve navigation and
  threat readability.

### S5 - Acoustic occlusion and environmental masking

Only after S1-S4 are stable:

- wall/door attenuation;
- indoor/outdoor modifiers;
- weather and machinery masking;
- material acoustic response;
- scale-driven spatial routing.

### S6 - Cross-family adoption

Adopt the shared perception substrate where it is genuinely useful for:

- autonomous fauna;
- commanded companions;
- static sentries;
- bespoke encounters;
- future social NPCs.

Do not force actors that do not need sensing to implement it.

## Integration With Existing Roadmaps

- `COMBAT_RESOURCE_AND_READABILITY_SYSTEM.md` tracks the cross-cutting
  gameplay milestone for shared perception and local alarm escalation.
- `NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md` remains the actor-family
  architecture authority. NPA-8 must consume this stealth substrate if it has
  landed rather than creating a Vaultwing-only hearing system.
- The completed ranged V1 specification remains authority for current weapon
  noise tuning. This document expands the receiving/perception architecture
  around that completed mechanic rather than rewriting weapon balance.

## Non-goals

This design does not require:

- a universal NPC superclass;
- a single global alert meter;
- every sound becoming a gameplay event;
- physically accurate acoustic simulation;
- omniscient player detection UI;
- automatic reinforcements from every noise;
- moving species behavior into shared stealth code;
- changing current weapon noise values merely to fit the new architecture.

## Validation Direction

The first implementation slice should prove:

- typed `NoiseEvent` propagation through real emitters and consumers;
- deterministic distance/sensitivity evaluation;
- no self-detection;
- source relationship does not automatically imply hostility;
- Enemy existing investigate/search behavior remains equivalent;
- Vaultwing can hear the same event without owning a separate acoustic model;
- dormant/interest-tier rules remain respected;
- no normal-play UI mutation owns simulation state.

Later alarm slices should prove network locality, explicit propagation, bounded
consequences, restore/reset behavior, and absence of map-wide psychic aggro.

## Next Agent Slice

**Goal:** implement S0 plus the narrowest S1 seam needed to make Enemy and
Vaultwing consume the same typed acoustic observation contract.

**Files:** `game/systems/stealth/{noise_event,noise_event_bus}.gd`,
`game/actors/enemies/components/enemy_perception_component.gd`,
`game/actors/ambient/vaultwing/vaultwing_behavior_controller.gd`, receiver
profiles/adapters created by the slice, and focused validation.

**Constraints:** preserve current weapon noise tuning and Enemy search behavior;
do not add alarms, UI, material footsteps, global attention, or species behavior
to shared stealth code.

**Acceptance:** the reported Vaultwing gunshot error is impossible through the
typed contract, Enemy and Vaultwing consume one acoustic evaluation seam,
receiver sensitivity remains data-driven, and focused noise/perception
regressions are deterministic.
