# CUSTODIAN — VAULTWING CREATURE, PREDATION, AND BOND SYSTEM

**Status:** design locked / wild Slice A and B.1 behavioral bond implemented / B.2 bonding presentation contract implemented; bonding art and production Vaultwing SFX pending
**Feature family:** ambient ecology / hostile fauna / companion progression  
**Initial creature:** Common Vaultwing  
**Runtime identity:** `vaultwing_common`  
**Asset V2 family:** `ambient_vaultwing_common`

## 1. Feature summary

Vaultwings are large, dangerous, pterosaur-like aerial predators and scavengers
that inhabit exposed CUSTODIAN environments. They provide world-scale wildlife,
readable aerial danger, learnable ecological behavior, and an earned path to
semi-feral companionship.

The intended progression is:

```text
FEAR IT → OBSERVE IT → UNDERSTAND IT → SURVIVE IT → EARN ITS TOLERANCE
→ BOND WITH IT → COMMAND IT → (future, optional) RIDE IT
```

Wild Vaultwings must never begin as friendly collectible pets. The first
impression is: **something large owns the sky above you.**

## 2. Creature identity and scale

The common name is **Vaultwing**; the initial species/archetype is **Common
Vaultwing** (`vaultwing_common`). “Pterodactyl” is player shorthand and does
not require an Earth-specific taxonomy.

The silhouette is inspired primarily by large azhdarchid pterosaurs:

- very long beak and neck;
- angular membrane wings;
- compact torso and strongly front-weighted profile;
- tall quadrupedal grounded stance;
- folded wings that read as forelimbs on the ground;
- large, readable flight profile;
- imposing landed posture rather than a bird-like floor pose.

Target apparent scale is roughly 1.5–2× Operator standing height and 3–4×
Operator width in visible wingspan. Tune exact world dimensions against the live
Operator sprite and collision scale. Visual wings may exceed the gameplay
collision footprint; collision prioritizes fairness.

Vaultwings are intelligent enough to learn routines, territorial, opportunistic,
food-motivated, suspicious, individually recognizable, and dangerous even when
not hunting. A bonded Vaultwing is allied, not domesticated.

## 3. Design pillars

1. **Fear before friendship.** The player meets wild threats before bonding is
   possible.
2. **Ecological readability.** Roost defense, carrion, bait, combat, and exposure
   produce understandable behavior rather than unexplained random aggression.
3. **Strong telegraphing.** A common dive is taught through cry, shadow, visible
   circling/descent, committed line, strike, and climb-out.
4. **Commitment creates counterplay.** Mobility is the strength; dive approach,
   post-strike climb, landing, takeoff, and stagger are vulnerability windows.
5. **Bonding is behavioral progression.** Attacks lessen, observation comes
   closer, food is accepted, grounded presence is tolerated, and recognition is
   earned over repeated peaceful contact.

## 4. Flight model

CUSTODIAN remains a 2D simulation with 2.5D presentation. Do not introduce
true 3D navigation. Altitude is a discrete state, not a second coordinate
authority.

| Band | Purpose | Rules |
|---|---|---|
| `HIGH` | ambient circling and migration | no Operator contact collision; generally not targetable; may select a point of interest |
| `ATTACK` | low passes, dive windup/strike, climb-out | combat-active; targetable; bounded hitbox; readable shadow |
| `GROUND` | feeding, stalking, fighting, taming, landing/takeoff, injury/death | ordinary world collision and walkable-space constraints |
| `PERCHED` | roosting, observing, ambience, taming | attached to a semantic perch marker; no normal locomotion |

### Ground projection and visual altitude

The Vaultwing has one real 2D gameplay position: the ground projection directly
beneath the creature. The gameplay actor, collision, navigation, targeting, and
shadow remain anchored to that position. Flight height is presentation-only.

```text
Vaultwing gameplay position
          ↓
        SHADOW
          |
          | visual altitude
          |
       VAULTWING
```

Conceptually:

```gdscript
ground_position = global_position
body.position.y = -visual_altitude_px
shadow.position = Vector2.ZERO
```

Never move the actor's world Y northward to represent ascent. The body receives
an independent screen-facing vertical offset while the shadow stays at the
ground projection. Vertical lift does most of the altitude work:

```text
GROUND       0 px
ATTACK       roughly 40–100 px above shadow
HIGH         roughly 140–240+ px above shadow
```

The presentation may continue climbing until the body leaves the camera view.
The shadow remains in-world, so a later moving shadow can reveal a hidden
Vaultwing overhead. `HIGH` has two presentation targets, not two simulation
states: `HIGH_VISIBLE` and `HIGH_ABOVE_CAMERA`.

Use a continuous presentation altitude value, for example:

```text
0.00 grounded
0.20 takeoff
0.35 low flight
0.55 attack altitude
0.75 high visible flight
1.00 above-camera flight
```

Scale reinforces distance but does not carry altitude alone:

```text
GROUND       1.00x
low ATTACK   0.95x
high ATTACK  0.88x
HIGH         0.78–0.85x
```

The shadow is an altitude instrument. Grounded shadows are dark, sharp, and
close beneath the body. As altitude increases, the shadow becomes lighter,
softer, lower-contrast, and more separated. At maximum HIGH altitude the body
may be completely off-camera while the projected shadow remains visible and
travels with the hidden creature's ground projection. It must not remain glued
to the Operator.

During a dive, body and shadow visibly converge. Shadow convergence is a primary
attack telegraph and must remain synchronized with the committed dive timeline:

```text
ominous shadow → darker/sharper convergence → body re-enters from above
→ body/shadow convergence accelerates → DIVE_STRIKE
```

This presentation contract does not add behavior states or a second movement
authority.

## 5. Behavior ownership and states

Vaultwing behavior has its own focused controller. Do not put predator behavior
inside `AmbientCritterManager`, and do not add Vaultwing-specific branches to
`EnemyBehaviorStateMachine`.

Conceptual ownership:

```text
Vaultwing actor → VaultwingBehaviorController → VaultwingBondState
                                      ↘ existing semantic creature presentation
```

Recommended states:

```text
HIGH_PATROL      CIRCLE_INTEREST      LOW_PASS
DIVE_WINDUP      DIVE_STRIKE         CLIMB_OUT
PERCH_IDLE       PERCH_ALERT          LAND
GROUND_IDLE      GROUND_STALK         GROUND_ATTACK
TAKEOFF          AIR_STAGGER           GROUND_STAGGER
RETREAT          DEAD
```

`HIGH_PATROL` follows a broad deterministic circuit, occasionally changes
heading, visits known perches, and ignores trivial activity. `CIRCLE_INTEREST`
responds to fresh combat, carrion, bait, roost intrusion, sustained loud
activity, or another Vaultwing event, then chooses whether to leave, perch,
land, low-pass, attack, or approach bait.

Aggression is reliably caused by territorial intrusion, direct attack, contested
food, or prolonged exposed-target interest. Do not use invisible health-based
aggro, unexplained off-screen attacks, permanent hostility from one accidental
proximity event, or attack-on-spawn.

## 6. Attack and counterplay contract

### Dive strike

```text
CIRCLE_INTEREST → DIVE_WINDUP → DIVE_STRIKE → CLIMB_OUT
```

Windup emits a distinct cry, visibly orients toward the target, accelerates the
shadow toward the projected strike line, and commits the attack direction. The
strike traverses a line through or beside the target during a bounded active
window; it cannot perfectly home after commitment. Climb-out is readable and
punishable.

### Ground attacks

`GROUND_ATTACK` includes a fast forward-committed beak strike with meaningful
recovery. An optional wing/body shove discourages hugging during takeoff and is
less damaging than the beak strike.

Do not implement Operator snatching in the initial version. It creates camera,
collision, escape, and fairness complexity. Small ambient prey, carrion, bait,
and loose world objects may be snatched later.

Ranged weapons are effective during windup, strike, climb-out, and low passes;
melee is effective after landing, while feeding, during grounded aggression,
takeoff, or after forced landing. Large-creature stagger must avoid trivial
stunlocking. A meaningful `AIR_STAGGER` may force a landing.

Retreat is valid wildlife behavior. Low health, repeated interruption, excessive
distance from territory, unreachable targets, or extended failed engagement may
produce `TAKEOFF → HIGH_PATROL/EXIT` or `CLIMB_OUT → EXIT` rather than death.

## 7. Perches, roosts, and spawning

Perches use semantic world markers, never coordinates embedded in presentation
art. Initial marker identity is `vaultwing_perch`; optional properties are
capacity, approach direction, territorial radius, roost weight, and whether
bonding is allowed. Valid examples include cliff ledges, ruined towers,
antennas, cranes, transfer infrastructure, roof edges, and authored rock
formations.

Vaultwings do not use the passive `AmbientCritterManager` spawn loop. Use a
fauna/predator-specific or narrow Vaultwing spawn authority. Initial population
is 0–2 wild Vaultwings per eligible region. Spawn selection considers biome and
region eligibility, open playable space, perch availability, Operator distance,
deterministic world seed, and existing population.

All simulation-affecting randomness comes from deterministic seeded streams.
Do not use `Time.get_ticks_*`, `get_instance_id()`, global `randf()`, or global
`randi()` for simulation authority.

## 8. Ecology

The baseline ecology requires perching, patrol, carrion/bait investigation, and
threatening the Operator. Predation of ambient critters is recommended after the
baseline works. This creates memorable unscripted events without bespoke
encounter scripts.

## 9. Bonding and companion progression

Use **bonding**, not instant taming. The same physical creature remains the
authority through wild → tolerant → bonded; do not replace an enemy instance
with a separate pet instance.

Bond stages:

```text
WILD → OBSERVING → TOLERANT → ACCEPTING → BONDED
```

The player reads progress through behavior rather than a mandatory large meter.

- `WILD`: ordinary hostility; distant bait investigation only.
- `OBSERVING`: remembers peaceful feeding; approaches closer and escalates less
  readily around bait.
- `TOLERANT`: remains grounded nearby and accepts repeated safe feeding.
- `ACCEPTING`: permits controlled approach and unlocks the bond trial.
- `BONDED`: recognizes the Operator as ally and exposes command behavior.

The feeding loop is:

```text
discover → observe → obtain bait → lure → keep safe distance → feed acceptance
→ repeat across encounters → approach permitted → bond trial → bonded
```

Progress advances only after completed feed acceptance. Attack, interruption,
rushing inside tolerance radius, or invalid bait interrupts the attempt without
erasing all prior progress. Bond does not decay through ordinary neglect.

The initial bond trial is a voluntary landing: the Vaultwing lands near the
Operator, enters guarded observation, permits approach, accepts a final direct
feed, performs a recognition beat, and becomes `BONDED`. Future variants may
use other trials.

Bonded defaults are semi-independent: follow at distance, circle nearby, perch
when idle, and relocate among valid nearby perches. Initial commands are:

- `RECALL` — return to the Operator vicinity;
- `PERCH` — choose a nearby valid perch;
- `STAY` — remain near the current perch/position;
- `ASSIST` — one combat pass against a valid hostile target, subject to cooldown.

Assist uses a subset of wild combat:

```text
acquire target → circle briefly → dive strike → climb out → return to orbit/perch
```

Do not make the companion a permanent autonomous damage turret. Use existing
team/faction semantics for allegiance and target filtering.

Persistence must preserve at least stable creature identity, species, bond stage
and value, bonded status, active companion assignment, and appropriate health
state. Do not key saves to volatile instance IDs. Permanent bonded death policy
is a later balance decision. Mounted flight is explicitly deferred pending review
of traversal, chasms, connectors, streaming, camera, collision, vehicles, and
progression.

## 10. Runtime architecture

Reuse the existing semantic presentation layer:

```text
custodian/game/actors/ambient/
    ambient_creature_animation_set.gd
    ambient_creature_presentation_controller.gd
```

Do not put behavior in:

```text
custodian/game/systems/core/systems/ambient_critter_manager.gd
custodian/game/actors/enemies/enemy_behavior_state_machine.gd
```

The recommended implementation surface is:

```text
custodian/game/actors/ambient/vaultwing/
    vaultwing.gd
    vaultwing.tscn
    vaultwing_behavior_controller.gd
    vaultwing_bond_state.gd
    vaultwing_animation_set.gd
    vaultwing_animation_set.tres
```

Codex may collapse or adjust files when the live graph exposes a cleaner seam,
but one authority must own each concern:

| Concern | Authority |
|---|---|
| health, actor integration, public API | Vaultwing actor |
| aerial/ground behavior, aggro, state, targets, perches | behavior controller |
| bond stage/value, feeding, trial, relationship | bond state |
| semantic animation playback | ambient presentation controller |
| deterministic population | fauna/Vaultwing spawn authority |

Gameplay requests semantic actions such as `glide`, `flap`, `dive_windup`,
`dive_strike`, `climb_out`, `land`, `takeoff`, `ground_idle`, `ground_walk`,
`bite_attack`, `air_stagger`, `hurt`, `death`, `feed_accept`, and `bond_greet`.
Gameplay must never reference individual PNGs. Missing optional clips may use
the existing semantic fallback; missing required combat readability fails
validation rather than silently hiding the attack.

## 11. Asset V2 family and art contract

Family:

```text
family_id: ambient_vaultwing_common
kind: ambient_creature
runtime domain: sprites/ambient_creatures
runtime owner: vaultwing_common
```

Family authority:

```text
custodian/content/metadata/assets/families/ambient_vaultwing_common.asset.json
```

Raw/unprocessed art belongs under:

```text
custodian/asset_drop/source_work/fauna/ambient_vaultwing_common/
```

with source names such as `glide_e_source.png`, `dive_strike_e_source.png`, or
`perch_idle_s_source.png`. Normalized intake belongs under
`custodian/asset_drop/inbox/ambient_vaultwing_common/`; final filenames must
follow the current Asset V2 parser. Raw art must never enter runtime directly.

Every frame is a 256×256 RGBA cell with true alpha, no matte, floor rectangle,
labels, guides, bleed, or baked world shadow. Use stable scale and registration.
Ground states anchor between the hind feet/primary support footprint; flight
states anchor the projected body center. Wing motion occurs around the origin;
runtime movement owns travel. A dive frame shows compression, wing change, neck
extension, and strike posture, not whole-animal translation across the cell.
Shadows are runtime presentation so altitude and terrain separation remain valid.
They must implement the ground-projection/visual-altitude contract above rather
than being baked into body art.

## 12. Baseline animation family

Required hostile baseline:

| State | Frames | FPS | Loop |
|---|---:|---:|---|
| `glide` | 6 | 8 | yes |
| `flap` | 8 | 10 | yes |
| `dive_windup` | 4 | 10 | no |
| `dive_strike` | 6 | 14 | no |
| `climb_out` | 6 | 12 | no |
| `land` | 8 | 10 | no |
| `takeoff` | 8 | 12 | no |
| `perch_idle` | 6 | 6 | yes |
| `ground_idle` | 6 | 6 | yes |
| `ground_walk` | 8 | 8 | yes |
| `bite_attack` | 6 | 12 | no |
| `air_stagger` | 5 | 12 | no |
| `hurt` | 4 | 12 | no |
| `death` | 8 | 10 | no |

Bonding clips:

| State | Frames | FPS | Loop |
|---|---:|---:|---|
| `notice_bait` | 4 | 8 | no |
| `guarded_approach` | 6 | 8 | yes |
| `inspect_bait` | 5 | 8 | no |
| `feed_accept` | 6 | 8 | no |
| `watch_player` | 6 | 6 | yes |
| `bond_greet` | 8 | 10 | no |
| `command_ack` | 4 | 8 | no |

The six Slice-B actions above are requested through a behavior-owned presentation
override, so state playback cannot replace a cue on the next frame. Timed
recognition/feed/greeting cues use presentation-only durations; grounded bait
approach and inspection follow their behavior phases; `watch_player` persists
through trial readiness and clears on completion/interruption. None of these
animation durations gates feed, trial, or bond progression. Until dedicated art
is published, `VaultwingAnimationSet` recognizes the actions and semantic
fallbacks resolve them to existing wild clips. `command_ack` remains deferred
until Slice C.

Later candidates include `ground_shove`, `preen`, `sleep/perch_rest`,
`feed_idle`, `roost_warning`, `carry_small_prey`, `landing_heavy`, and
`companion_excited`.

Author east, south, and north first. Permit Asset V2 mirroring for west from
east only when the design is symmetric. Author west where asymmetry requires it;
never mirror scars, markings, harnesses, or equipment that would become wrong.

## 13. Sound and observability

Initial sound vocabulary is distant call, territorial warning, dive cry, wing
pass, landing impact, ground threat, feed vocalization, bond recognition call,
hurt, and death. Distant call and dive cry are gameplay telegraphs.

Use `DevObservatory` at transition/event level, not per-frame telemetry. Events:

```text
vaultwing_spawned / despawned
vaultwing_dive_started / dive_hit / dive_missed
vaultwing_air_staggered / landed
vaultwing_feed_accepted / feed_rejected
vaultwing_bond_stage_changed / bond_completed
vaultwing_command_received / assist_started
```

Useful gauges are `active_vaultwings` and `bonded_vaultwings`.

## 14. Validation and Moment Forge

Add focused checks when Slice A is implemented:

```text
custodian/tools/validation/vaultwing_runtime_smoke.gd
custodian/tools/validation/vaultwing_asset_contract_smoke.py
```

Runtime smoke must cover deterministic spawn/behavior, stable initial state,
legal bands, committed non-perfect-homing dives, bounded active windows,
retreat termination, aerial stagger to ground, non-overlapping landing/takeoff,
feeding restrictions while hostile, valid bond progression, bonded Operator
allegiance, and command target filtering.

Asset smoke must cover 256×256 cells, RGBA/real transparency, declared frame
counts and strip widths, bleed, canonical Asset V2 identities, required
directions, and the rule that source_work/inbox art cannot silently enter
runtime. Register both checks in `validation_manifest.json`.

Recommended Moment Forge scenarios are `vaultwing_dive_readability`,
`vaultwing_forced_landing`, and `vaultwing_first_bond`. Review shadow timing,
silhouette, attack commitment, punishment window, voluntary landing, approach,
feeding, recognition, and bonded response.

## 15. Implementation slices

### Slice A — Wild Vaultwing foundation

Implement actor, deterministic spawn, patrol, perch behavior, discrete bands,
circle/interest, dive, landing/takeoff, ground attack, damage/death/retreat,
semantic presentation hooks, and focused validation. Slice A must implement the
ground-projection/visual-altitude contract: persistent shadow, independent body
lift, modest scale shift, intentional above-camera HIGH presentation, and
synchronized body/shadow convergence during committed dives. Bonding is
interface-only at this stage.

### Slice B — Bonding

Implement bait recognition, feeding, bond state/progression, bond trial,
persistence, and bonded allegiance.

### Slice C — Companion behavior

Implement follow/orbit, perch, recall, stay, assist dive, and command cooldown.

### Slice D — Ecology expansion

Consider ambient prey hunting, corpse scavenging, nest defense, weather response,
group interactions, and juveniles/variants.

### Slice E — Mount feasibility

Design review only until separately approved. Do not add mounted-flight logic to
the bonding implementation.

## 16. Non-goals

The initial implementation does not include true 3D flight, free-flying Operator
mounts, Operator snatch/grab, breeding, hatchling raising, genetics, giant flock
simulation, a new faction architecture solely for Vaultwings, a duplicate
companion framework, per-frame telemetry, hard-coded PNG loading, Vaultwing logic
inside `operator.gd`, or scattered Vaultwing-specific weapon branches.

## 17. Acceptance criteria

The hostile baseline succeeds when a deterministic eligible world can spawn a
Vaultwing that patrols independently of passive critters, perches, enters a
readable committed dive, provides enough audiovisual information to dodge, can
be damaged during valid windows, can be staggered into vulnerability, and can
land, fight, retreat, take off, and die without state overlap. Presentation must
be semantic and optional-art fallback must not erase required combat readability.

Bonding succeeds when wild hostility and bonding are one coherent lifecycle,
valid bait produces controlled interaction, repeated peaceful feeding changes
observable behavior, aggression interrupts rather than completes progress, the
bond trial is distinct, BONDED persists through save/load, commands support
recall/perch/stay/assist, bond does not decay through neglect, and the same
physical creature remains authoritative.

## 18. Documentation and next-agent slice

When implementation changes runtime truth, update this authority plus:

```text
custodian/docs/ai_context/CURRENT_STATE.md
custodian/docs/ai_context/FILE_INDEX.md
REQUIRED_ASSETS.md   # only if it remains the live missing-asset tracker
```

Do not create a second missing-asset tracker. Register the Asset V2 family and
use the current `asset.py` plan/status/doctor commands rather than inventing
pipeline commands.

The Actor Relationship Foundation V1/V1.1 seam is complete: shared allegiance
and targetability semantics now precede bonding, while legacy groups remain
compatibility indexes. Slice B.1 now supplies the same-instance behavioral bond
loop: safe interruptible feed attempts, encounter separation, stage-specific
approach/escalation policy, voluntary landing and guarded trial, bonded
allegiance, provenance-derived stable identity, and a versioned bond/health save
record. The local record contract is not global save orchestration. B.2 now
owns the six Slice-B semantic animation cues and protects them from ordinary
state playback; the Asset V2 family and canonical missing-assets tracker list
the six art families plus feed and recognition SFX. Next, generate and ingest
the six bonding families, then review `combat/vaultwing_first_bond`; production
SFX and bait/global-save integration follow, and companion behavior remains
Slice C. Preserve
unrelated working-tree changes; keep simulation deterministic; do not expand
`AmbientCritterManager`; reuse semantic ambient presentation; keep flight as
discrete bands; put tunable timing/range/damage in appropriate data/config; do
not require mounting; and never reference source_work or inbox assets at
runtime.

## 19. Design lock

The following decisions are locked unless explicitly revisited:

- creature name: Vaultwing;
- initial species: Common Vaultwing;
- large azhdarchid-inspired silhouette;
- wild Vaultwings are dangerous and eventually bondable;
- bonding is gradual and behavioral and does not decay through ordinary neglect;
- bonded creatures remain semi-feral in presentation;
- mounted flight is deferred;
- flight uses discrete aerial bands, not true 3D navigation;
- aerial altitude is an independent body presentation offset from a persistent
  2D ground projection;
- body scale changes modestly with altitude and never substitutes for lift;
- shadow sharpness, opacity, contrast, and separation communicate altitude;
- HIGH presentation may intentionally leave the body above the camera while its
  shadow remains in-world;
- body/shadow convergence is synchronized to the committed dive timeline;
- hostile behavior has its own focused authority;
- `AmbientCritterManager` does not own Vaultwing combat;
- the generic enemy state machine does not become Vaultwing-specific;
- the Asset V2 family kind is `ambient_creature`;
- family ID is `ambient_vaultwing_common`;
- runtime cells are 256×256;
- body art contains no baked world shadow;
- runtime movement, not frame translation, owns dive travel;
- production art enters through Asset Pipeline V2.
