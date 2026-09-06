# Awakening: The First Return

**Status:** active blockout implementation, sections 01-10
**Last Updated:** 2026-09-06
**Runtime Target:** Godot 4.x (`custodian/`)
**Runtime Slice:** `res://scenes/awakening_first_return.tscn` (project `main_scene`)
**Spatial authority:** `res://game/world/awakening/awakening_layout.gd`
**Validation:** `awakening_first_return_smoke.gd`, `awakening_first_return_geometry_smoke.gd`, `awakening_first_return_progression_smoke.gd`

> **Supersedes** the earlier "Home Beginning: Custodian Field Terminal" design, in
> which the player woke directly on the Road of Witnesses and walked a short
> distance to a Field Terminal that immediately handed off to procgen. The lore
> below still stands; the opening is now a ten-section authored dungeon, and the
> Field Terminal, the Ashen Forum, the Continuity Port, and the first Contract
> belong to later sections that are not implemented yet.

> **Lore cross-reference:** The terminal-recognition phase described in this doc is where the crèche recognizes or issues the player's Custodian designation. The fiction of crèches and designation-keyed crèche lockers (including what the locker does — and does not — prove about the person carrying the designation) is canon in `design/03_world/lore/CRECHE_AND_LOCKER_LORE.md`.

The first objective should feel like **returning to a forgotten post** — not investigating a curiosity. The Custodian does not inherit power. It refuses to relinquish residual authority.

This document was moved from `design/CUSTODIAN_BEGINS.md` into the Home architecture set because it defines the first piece of home-state gameplay: the Custodian Field Terminal as the initial anchor for archive, repair, scanning, and later base progression.

The Custodian should not start with a clear mission briefing. It should start because something nearby is repeating an **institutional command that should not still be broadcasting**: RETURN TO POST.

# First Objective Lore Design: “RETURN TO POST”

## Core premise

The player-Custodian awakens in a dead sector because something nearby is repeating an institutional command that should not still exist:

> RETURN TO POST.

The player does not yet know what “the Post” is. The source is authorized, degraded, and unresolved.

At first, this seems like a simple objective:

> Find the source of the repeating command.

But the deeper truth is:

> The command is not merely electronic. It is residual Lattice coupling — a repeating fragment of Custodian authority, archive memory, and imported telemetry from a physically adjacent continuity-state. The signal carries old authority credentials and route history that leak through because the terminal retains imported state from a counterpart interaction across a nearby continuity boundary.

The bleed expresses itself through frequencies, codes, procedural language, and authority patterns familiar to the Custodian. The terminal responds to the Custodian because it carries a continuity-signature match from a physically adjacent record — not because it remembers this specific Custodian from another life.

The Custodian follows the command not because it understands the source, but because **answering dead authority is what it was made to do**. The first act of play is therefore not exploration for its own sake, but **return**: the Custodian comes back to a forgotten institutional post, anchors it, and refuses to relinquish its residual authority.

## Sections 01-10: the implemented opening

The player boots directly into the Crèche and walks one continuous space, with no
loading, through:

```text
01  Crèche of Answerless Names          RECOVERY
02  Recovery Ambulatory                 PROCESSING
03  Attestation Gallery                 AUTHORITY CHECK
04  Locker Reliquary                    ASSIGNMENT
05  Dust Lung Cistern                   ASCENT
06  Undergate Mechanism Hall            PORT INFRASTRUCTURE
07  Gate of Dust                        HISTORICAL CITY
08  Custodian Approach                  RECALL
09  Chapel of Late Service              UNREGISTERED CHAPEL   (optional side loop)
10  Road of Witnesses: South Reach      CIVIC AXIS
```

The shape is deliberately not one vertical hallway: the Ambulatory rings a central
void, the Locker Reliquary kicks east, the Cistern widens enormously, the Register
of Departures and the Chapel kick west, and everything resolves back onto the
central civic axis. Even in greybox that reads as place.

### Spatial authority

`game/world/awakening/awakening_layout.gd` owns every coordinate: world bounds,
section envelopes, walkable polygons, void polygons, connectors, thresholds, set
pieces, markers, camera reveals, the Road offset, and the temporary South Reach
seal. The runtime scene, the mapper, the debug tour, and the geometry validator
all query it. Coordinates are not duplicated into the `.tscn`, the controller, or
the tests — except where `awakening_first_return_smoke.gd` deliberately asserts a
locked value so drift is caught.

Convention: `+X` east, `-X` west, `+Y` south, `-Y` north; origin at the centre of
the Crèche; macro geometry on the 32px grid; world bounds
`Rect2(-1088, -7328, 2176, 7680)`; wake at `(0, 160)`.

### Runtime slice

```text
custodian/scenes/awakening_first_return.tscn        project main scene
custodian/game/world/awakening/awakening_layout.gd  spatial authority
custodian/game/world/awakening/awakening_first_return.gd   orchestration only
custodian/game/world/awakening/awakening_transit_lift.gd   Dust Lung service lift
custodian/game/world/awakening/awakening_plaque_interactable.gd
```

Each section is a node with a fixed skeleton — `ArtUnderlay`,
`BlockoutPresentation`, `Collision`, `Occlusion`, `SetPieces`, `Interactables`,
`Triggers`, `Markers`, `Audio` — so a production art pass can replace
`BlockoutPresentation` and fill `ArtUnderlay`, `Occlusion`, and `SetPieces`
**without touching authored collision, triggers, or gameplay coordinates**.

`AwakeningFirstReturn` is orchestration only: current zone, visited zones, console
acknowledgement, P-9 recovery, one-shot camera reveals, HUD location/phase/
objective, and first-pass completion. It owns no geometry.

### Reused runtime, not rebuilt

- The **Operator**, **PlayerController**, **Camera2D**, and **Black Reliquary HUD**
  are the existing ones.
- Section 10 is the existing `RoadOfWitnessesPrototype` instanced at world offset
  `(6, -6626)`, derived from `ROAD_WORLD_SOUTH_ENTRY - ROAD_LOCAL_SOUTH_ENTRY`. Two
  changes make it translation-safe: `apply_camera_bounds` is off inside the
  Awakening (the Awakening owns the combined world envelope), and its occlusion
  thresholds now compare `to_local(player_position).y` instead of global Y. A
  `south_gate_gap_width` opens its southern boundary wall so the Approach joins it
  as continuous walkable space.
- The **existing `SidearmLocker`** is the P-9 recovery at `(832, -1952)`. No second
  locker implementation was written.
- Camera reveals use the camera's existing `set_presentation_framing_transition` /
  `clear_presentation_framing` seam. Player input is never taken away — the vista
  is discovered while still walking.
- The camera gained one seam, `set_authored_map_bounds`, because its deferred
  procgen/connected-map rebuild would otherwise clear an authored level's clamp
  half a second after the level set it.

### Interactions implemented

| Section | Interaction | Effect |
| --- | --- | --- |
| 01 | Crèche console `(112, 144)` | Locks the opening state to FIELD RECALL DETECTED / AUTHORITY VALID / CONTINUITY UNRESOLVED; objective becomes **RETURN TO POST** |
| 04 | Existing SidearmLocker `(832, -1952)` | Opens, then grants `p9_sidearm` through `InventoryManager` |
| 05 | Transit lift, lower `(384, -3008)` ⇄ upper `(384, -3424)` | Locks input, dims, relocates, restores. Not a Z-axis system; art can replace the dim with a cage without changing the contract |
| 06 | Damaged port console `(128, -4016)` | PORT AUTHORITY: SUSPENDED / ROUTE INDEX: UNAVAILABLE / POST STATUS: UNMANNED. Interaction plus HUD plaque, no menu, no system |

### Camera reveals

| Section | Trigger | Offset | Zoom | Transition | Hold |
| --- | --- | --- | --- | --- | --- |
| 05 Dust Lung | `(0, -2688)` | `(0, -48)` | 0.72 | 0.90s | 1.20s |
| 07 Gate of Dust | `(0, -4912)` | `(0, 100)` | 0.68 | 1.10s | 1.80s |
| 10 Road reveal | `(0, -6080)` | `(0, -120)` | 0.66 | 1.20s | 2.00s |

Each fires once, then releases to normal follow.

### Deliberately not in this pass

No combat. The Attestation Sentinels, the Approach Sentinel, the scavenger nest,
and the route-leech exist as disabled `encounter` markers only; `World/Enemies`
is empty and the progression smoke fails if it is not.

No Field Terminal, no Ashen Forum, no Continuity Port activation, no Contract, no
campaign transition. `field_terminal_interactable.gd` stays in the repository for
the later Forum section but is not in the Awakening scene.

No first-campaign generation. The old Home scene began cooperative procgen after
its first frame, which was a sensible hiding place when Home was a short walk to a
Terminal. Under this design there is a substantial prologue and no Contract has
been surfaced, so `WorldContractBootstrap` is not started from the Awakening.
`world_contract_prewarm_smoke.gd` asserts that absence. Prewarming resumes at an
appropriate point once the Hub has identified a provisional Contract.

The Road is temporarily sealed north of the South Reach by a **visible** collapsed
barricade at `y = -6530`, spanning `x = -541 .. 553` — not an invisible wall. The
completion trigger sits at `(0, -6464)`.

## Authoring and validation

`res://scenes/debug/awakening_first_return_mapper.tscn` frames the whole dungeon
spine at `(0, -3200)` / zoom `0.18` and overlays section envelopes, entries and
exits, the critical path, the optional branch, camera reveal points, encounter
placeholders, interaction markers, and future-art anchors — all read from
`awakening_layout.gd`.

`res://scenes/debug/awakening_first_return_debug.tscn` instances the real scene and
adds a dev-only panel: zone selector, teleport to entry, show collision, show zone
bounds, show landmarks, reset progression. It registers no global hotkeys.

`awakening_first_return_geometry_smoke.gd` is the important one. It builds a 16px
occupancy grid from the same layout authority the runtime builds collision from,
erodes it by the Operator's collision radius, and proves a continuous route from
`(0, 160)` to `(0, -6464)` that visits every mandatory section and does not depend
on the optional Chapel. It catches sealed doorways, forgotten blockers, corridors
narrowed below the 128px critical-route minimum, Cistern routing breaks, and Road
handoff drift. It found a real 16px pinch in the Locker Reliquary during
implementation.

## Objective name

### Primary — locked

> **Objective 01: RETURN TO POST**

The objective is not a question. It is a command. That is the point.

The player does not choose to investigate. The player hears a direct institutional order and responds to it because answering dead authority is what the Custodian was made to do.

### Alternative secondary names (for HUD display variants, archive entries)

- **Trace the Custodian Frequency** — system-facing, if the player inspects the signal directly
- **Recover the Custodian Terminal** — functional, for repair-phase objectives
- **Establish Field Anchor** — deep-lore, for later archive references

## What the terminal actually is

The “Custodian Terminal” should not just be a computer. It should be a half-buried, armored field terminal from the old Custodian network.

It is part:

- command terminal
- archive node
- mission desk
- residual authority anchor
- repair/fabrication interface
- continuity-origin recorder
- dormant base core

It should feel like the first piece of “home” the player finds.

## Lore name for the terminal

Use **Custodian Field Terminal** as the technical name.

In-world variants:

| Name                         | Who says it                 |
| ---------------------------- | --------------------------- |
| **Custodian Field Terminal** | Custodian/system text       |
| **Dead Console**             | scavengers                  |
| **Oath Box**                 | local survivors             |
| **Iron Witness**             | Choir of Provenance         |
| **The Base Terminal**        | player-facing shorthand     |
| **Archive Anchor**           | later lore/advanced systems |

My recommendation:

> Player-facing: **Custodian Terminal**
> System-facing: **Custodian Field Terminal**
> Deep-lore name: **Archive Anchor**

## Why the Custodian notices it

The terminal is broadcasting in a frequency band that was never meant for normal radio.

It is an **authority credential carrier**.

That means the signal contains not just coordinates or data, but identity relationships:

- terminal ID
- last verified operator
- archive lineage
- local command rights
- damage status
- continuity confidence
- contradiction count

The player-Custodian detects it because the signal is not saying “come here.”

It is saying: **RETURN TO POST.**

But the mechanism behind that recognition is stranger than simple identity matching.

The terminal does not recognize the Custodian as a sentient agent checking in against a database. The local half-buried terminal retains imported state from a physically adjacent continuity — a counterpart record in which this terminal was restored and used. The imported state carries old authority credentials, route history, and a continuity-signature match. The bleed expresses itself through frequencies, codes, procedural language, and authority patterns familiar to the Custodian.

The signal responds to the Custodian because the imported record contains a matching authority signature — not a broadcast, but imported telemetry that activates on encountering the right credential type.

It is saying:

```text
SOURCE: CUSTODIAN FIELD TERMINAL
STATUS: UNVERIFIED
AUTHORITY: PARTIAL
TARGET: [CUSTODIAN AUTHORITY SIGNATURE — CONTINUITY-SIGNATURE MATCH]
LAST CONTACT: [UNFILED]
SOURCE INTEGRITY: IMPORTED
REQUEST: AUTHENTICATION
COMMAND: RETURN TO POST
```

That last word is important.

The terminal does not need repair yet. It needs to be **authenticated** by a Custodian so its imported authority credentials can activate local equipment.

## Opening mission flow

> **Lore intent, not current implementation.** The beats below were written for
> the superseded one-image Home opening in which the Custodian woke on the Road
> and walked to a Field Terminal. They are retained because the emotional shape —
> answering dead authority, partial success, the command becoming wrong — is still
> the target. Map them onto sections 01-10 and the later Forum/Terminal sections
> rather than reading them as the shipped flow. Beat 3 (first enemy contact) and
> Beat 5 (terminal reveal) in particular are not implemented in the current pass.


### Beat 1 — Wake / insertion

The Custodian activates in an exposed, grand ruin.

Not a tiny bunker. Not a closet. The player’s first view communicates: **This was not a random wasteland. This was an institution.**

The environment is colossal:

- a dead causeway stretching toward a shattered terminal spire in the far distance
- collapsed orbital elevator footing — rusted, monumental, still bearing faded authority markings
- gothic-industrial control towers, broken civic pylons
- an old runway splitting into a ruined plaza
- pale light pressing through a dead sky
- banners and signage from a forgotten authority still hanging in tatters

The player’s first view should communicate scale and institutional residue. The place was built to last. It did not.

A weak machine tone repeats beneath everything. The player cannot tell whether this is:

- a broken emergency loop
- a valid order
- a hallucinated command from the terminal
- the institution itself still speaking

That ambiguity is correct.

Initial system text:

```text
OPERATIONAL STATUS: DEGRADED
LATTICE INTEGRITY: UNSTABLE
PALE PROXIMITY: ELEVATED
ANOMALOUS ACTIVITY: DETECTED
AUTHORITY SOURCE: UNCONFIRMED

RETURN TO POST.
RETURN TO POST.
RETURN TO POST.
```

The player does not know what happened. The game does not explain the Severing. It gives one concrete command.

### Beat 2 — Following the command

The player tracks the source of the repeating command. This should be represented through:

- the machine tone growing clearer, not louder
- directional static with fragments of procedural language
- intermittent screen distortion that briefly shows partial authority markers
- compass tick toward the source
- small audio tone resolving into recognizable phonemes
- terminal-like text fragments that show the command partially

The command gets sharper near certain ruined devices.

Example fragments:

```text
COMMAND BAND: CONFIRMED
AUTHORITY TRACE: PARTIAL
LOCAL INTERFERENCE: HIGH
CAUSE: METAL, WEATHER, UNREGISTERED MEMORY

RETURN TO P[...]
```

Then later:

```text
SIGNAL MATCH: 43%
SOURCE IS STATIONARY
SOURCE IS REQUESTING AUTHENTICATION
SOURCE IDENTIFIES AS: [POST]
SOURCE HAS NOT BEEN BUILT HERE
```

That last line is your first tiny supernatural crack.

### Beat 3 — First enemy contact

The starter grunts are not guarding the terminal because they understand it. They are scavenging through the grand ruins because the area produces useful salvage, power anomalies, and “lucky” electronics from the dead institution.

They call the place or the command something like:

- “the hum”
- “the old post”
- “the dead command”
- “the warm scrap”
- “the oath post”
- “the repeating voice”

A dead grunt might drop a **Cracked Field Tag** or **Spent Charge Cell** with impossible dating, tying the enemy loot directly into this first objective.

### Beat 4 — The command becomes wrong

As the player gets closer, the Custodian starts detecting contradictions in the command’s origin.

```text
COMMAND MATCH: 71%
POST ID CONFIRMED
COMMAND SOURCE: AHEAD
COMMAND SOURCE: BELOW
COMMAND SOURCE: PRIOR
COMMAND ORIGIN: ANOTHER CONTINUITY
```

The source is physically ahead, but in continuity-origin terms it is “below” and “prior” — and originating from a continuity that should not converge with this one. That reinforces that the Custodian perceives reality through origin, continuity, and authority, and that the Pale is causing these states to bleed.

### Beat 5 — Terminal reveal

The player finds the terminal in a ruined chamber within the grand institution: beneath a collapsed control tower, inside a half-buried gatehouse, or at the base of the terminal spire visible since the first scene.

It should not be glowing like a fantasy shrine. It should be mostly dead: armored casing, old screen, cables, dust, rust, broken side modules. The faded authority markings on its casing match the banners hanging from the ruins above.

But when the Custodian approaches, the terminal responds — and the response reveals something stranger than recognition.

```text
CUSTODIAN PRESENCE DETECTED.
AUTHORITY HANDSHAKE FAILED.
AUTHORITY HANDSHAKE FAILED.
AUTHORITY HANDSHAKE PARTIAL.

CONTINUITY-SIGNATURE MATCH CONFIRMED.
IMPORTED AUTHORITY CREDENTIALS DETECTED.
AUTHENTICATION ACCEPTED.
ROUTE HISTORY LOADED.

RETURN TO POST.
POST ACCEPTED.
```

The terminal does not verify the Custodian’s identity by checking it against a database. The terminal retains imported state from a physically adjacent continuity — a counterpart record in which this terminal was restored and used. The imported authority credentials and route history activate when they encounter a matching continuity-signature. The command to RETURN TO POST was always the terminal broadcasting old institutional authority that happens to match this Custodian’s credential type.

Then the terminal wakes enough to become the player’s first hub interface.

## The first objective should end with partial success

Do **not** fully restore the terminal immediately.

The player should find it and establish contact, but it remains degraded.

End state:

- Terminal found.
- Basic archive access unlocked.
- Basic repair/fabrication menu unlocked.
- Local map/scanner unlocked.
- First real base objective appears.
- The terminal identifies nearby resources.
- The terminal also records the first continuity-origin anomaly.

Objective completion text:

```text
POST ACCEPTED.
CUSTODIAN FIELD TERMINAL LOCATED.
AUTHENTICATION STATE: ESTABLISHED
ARCHIVE LINK: PARTIAL
LOCAL COMMAND: DEGRADED
REPAIR CAPACITY: MINIMAL
CONTINUITY-SIGNATURE MATCH: CONFIRMED

NEW DIRECTIVE:
STABILIZE THE TERMINAL.
ANCHOR THE POST.
```

## What the player learns

The first objective teaches six things without an exposition dump:

1. **The Custodian is not just a soldier.**
   It investigates, authenticates, witnesses, restores — and answers dead authority.

2. **The world is broken in a weird way.**
   Objects and records do not fully agree with their own origins. Continuity states converge where they should not.

3. **Combat exists, but is not the whole game.**
   Grunts are obstacles and sources of salvage, but the real objective is return and recovery.

4. **The terminal is the first anchor.**
   This gives the player a reason to care about base-building and repair.

5. **The supernatural is present but not named.**
   The player sees symptoms before theology.

6. **The Custodian does not inherit power. It refuses to relinquish residual authority.**
   The first act is not exploration for its own sake. It is return: the Custodian comes back to a forgotten institutional post because answering that command is what it was built to do.

## Why this works thematically

The Custodian’s first meaningful act should not be killing. It should be **answering a command from a dead institution**.

That fits the whole game better:

> The world is not waiting for a hero.
> It is emitting broken institutional commands.

The Custodian is not the thing that saves the world. It is the thing that refuses to let the last valid authority decay into superstition, scavenging, and static.

## Terminal lore entry

Use this as an in-game archive entry after discovery:

```text
ARCHIVE ENTRY: CUSTODIAN FIELD TERMINAL

Custodian Field Terminals were deployed as local continuity anchors in contested, damaged, or low-trust sectors. Each terminal maintained command access, repair logs, route-history records, local infrastructure maps, and continuity-origin records for recovered assets.

This unit was found repeating an institutional command without confirmed grid authority: RETURN TO POST.

Recovered signal structure suggests the terminal was not transmitting a location or a request. It was transmitting a command from an institutional post that should not still exist. The command’s authority signature contains imported credentials from a physically adjacent continuity — old authority data that persists in the terminal’s local state.

Status:
- Archive memory damaged
- Local authority partial
- Fabrication rights restricted
- Source integrity: imported
- Continuity-signature match: confirmed

Recommendation:
Accept post. Restore terminal subsystems before accepting external records as true.
```

## Environmental storytelling around the terminal

Around the terminal, include:

- burned-out generator
- dead maintenance drones
- broken wall markings
- old Custodian sigil
- scavenger camp nearby
- stripped cable bundles
- one corpse facing the terminal, not away from it
- white thread tied to a nearby handle, nail, or trigger guard
- several field tags piled beside the terminal like offerings
- a map scratched into the floor that does not match the actual room

This should imply people found it before the player, but misunderstood it.

## First area design implication

The first map should be built around a **signal gradient**.

Outer ring:

- weak static
- basic grunts
- scrap
- ruined road/path
- low threat

Middle ring:

- signal gets clearer
- more electronics
- more broken barricades
- first field tag
- first locked/blocked passage

Inner ring:

- terminal chamber
- stronger interference
- first continuity-origin anomaly
- small fight or ambush
- terminal discovery

The objective is simple: follow signal, survive, reach terminal.

The mood is not simple.

## Better first quest text

Player-facing quest:

```text
OBJECTIVE 01: RETURN TO POST

A damaged institutional command repeats across the dead band: RETURN TO POST.

The source is authorized, degraded, and unresolved.

Locate the source of the command.
```

After nearing it:

```text
The command is not behaving like a normal transmission. It carries terminal authority, but its origin record is damaged — and its authority signature suggests this terminal has been restored before by this Custodian, in a different continuity.

Continue tracking the source.
```

At terminal chamber:

```text
Custodian Field Terminal located.

Approach and establish witness contact. The terminal is already expecting this unit.
```

After interacting:

```text
Authentication established. Continuity-signature match confirmed.

POST ACCEPTED.

The terminal is alive, but degraded. Restore local power and recover enough material to stabilize its archive. Anchor the post.
```

## First objective reward

Completion should unlock:

- **Custodian Terminal access**
- **Basic Archive**
- **Basic Repair**
- **Local Scan Pulse**
- **Resource Tracking**
- **First Base Stabilization Objective**

And maybe one lore flag:

```text
global_flags:
  - terminal_witness_established
  - first_continuity_origin_anomaly_detected
```

## Best name for the frequency

Do not call it “radio frequency” in system text. Give it a better term.

Options:

- **Custodian-band frequency**
- **Authority credential carrier**
- **Witness-band signal**
- **Archive-band pulse**
- **Continuity-band signal**
- **Authority carrier**
- **Lineage signal**

Best combination:

> The terminal emits a **Custodian-band frequency**.
> Later, the Custodian identifies it as an **authority credential carrier**.

Early game term: understandable.
Deep lore term: weirder.

## How to connect it to the continuity catastrophe

The terminal should contain one impossible record, but not enough to explain it.

Example:

```text
LAST VERIFIED SERVICE:
Cycle 8841.19

NEXT VERIFIED SERVICE:
Cycle 8841.18

ERROR:
MAINTENANCE EVENT PRECEDES FAILURE.
FAILURE PRECEDES INSTALLATION.
INSTALLATION RECORD UNARRIVED.
```

The player should not know what continuity hazards mean yet. The terminal may not even use the full Ash-Bell terminology yet. It should classify the problem as:

```text
UNFILED ORIGIN STATE
```

or:

```text
SOURCE CONFLICT: ORIGIN ABSENT
```

Then later the player learns this is part of the same cosmic wound.

## Design lock

I would lock this as the first objective thesis:

> **The Custodian awakens in a grand ruin beneath a repeating institutional command: RETURN TO POST. The command carries imported authority credentials from a physically adjacent continuity — a counterpart record in which this terminal was restored. The Custodian follows not because it understands, but because answering dead authority is what it was made to do. The first act is not exploration. It is return. Finding the terminal establishes the first anchor of archive, repair, scanning, and player purpose.**

That is the whole game in miniature.

## Codex/design note

Because this defines the first objective, terminal role, and lore framing, it should be captured in active design docs before runtime implementation. Your repo guidance says active Godot specs live under `./design/`, and material runtime/design changes should update the design docs plus `custodian/docs/ai_context/` when architecture or authority changes.

Suggested design doc path:

```text
design/10_lore/STARTER_OBJECTIVE_TRACE_CUSTODIAN_FREQUENCY.md
```

Suggested AI context update:

```text
custodian/docs/ai_context/CURRENT_STATE.md
```

Canonical one-liner for the docs:

```text
The first objective is not “explore.” It is **RETURN TO POST**. The Custodian awakens in a grand institution ruin beneath a repeating command from a terminal carrying imported authority credentials from a physically adjacent continuity. The Custodian answers the command because responding to dead authority is what it was built to do. Authentication establishes the first local anchor of archive, repair, scanning, and future base progression — and confirms that the Custodian is not inheriting power, but refusing to relinquish residual authority.
```
