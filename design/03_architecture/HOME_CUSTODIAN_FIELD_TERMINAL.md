# Home Beginning: Custodian Field Terminal

**Status:** active V1 implementation
**Last Updated:** 2026-06-02
**Runtime Target:** Godot 4.x (`custodian/`)
**Runtime Slice:** `res://scenes/home_custodian_begin.tscn`
**Validation:** `res://tools/validation/custodian_home_begin_smoke.gd`

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

> The command is not merely electronic. It is a provenance echo — a repeating fragment of Custodian authority, archive memory, and impossible historical residue. The signal leaks because the Pale causes continuity states to converge: a local half-buried terminal has become contaminated by another continuity-state in which the same terminal has already been restored and used by the Custodian across many worlds.

The bleed expresses itself through frequencies, codes, procedural language, and authority patterns familiar to the Custodian. The terminal has already “knows” the Custodian because the Custodian has already restored this terminal in a different continuity.

The Custodian follows the command not because it understands the source, but because **answering dead authority is what it was made to do**. The first act of play is therefore not exploration for its own sake, but **return**: the Custodian comes back to a forgotten institutional post, anchors it, and refuses to relinquish its residual authority.

## V1 runtime implementation

The first implementation lives as a dedicated authored Home scene rather than replacing the current contract/procgen main scene:

```text
custodian/scenes/home_custodian_begin.tscn
custodian/game/world/home/custodian_home_begin.gd
custodian/game/world/home/field_terminal_interactable.gd
```

V1 uses the existing Road of Witnesses map, the existing Operator, the shared world camera, the Black Reliquary HUD, and existing command-terminal compatibility art as a placeholder Field Terminal visual. It is a real playable slice: the Operator starts at the lower Road of Witnesses, follows a distance-based Custodian-band signal, receives progressively stranger HUD status fragments, approaches the Field Terminal, and establishes witness contact through the normal `interact` action.

V1 intentionally does **not** promote this scene to `application/run/main_scene`; `res://scenes/game.tscn` remains the active project main scene until boot-flow ownership is changed deliberately. The Home beginning scene is the canonical implementation target for that later boot-flow handoff.

Runtime behavior:

- `CustodianHomeBegin` owns local objective state and signal-band presentation.
- `FieldTerminalInteractable` is a normal `interactable` group member discovered by the existing Operator interaction scan.
- The Black Reliquary HUD presents location, phase, objective, signal/provenance status, and prompt plaque text.
- Prompt text is rendered as real Godot labels through the HUD, not baked into textures.
- Witness contact changes objective state to terminal stabilization and unlocks a partial archive/status readout placeholder.
- Missing production art/audio is tracked in `REQUIRED_ASSETS.md`; the current scene uses existing assets as fallbacks.

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
- lawful reality anchor
- repair/fabrication interface
- provenance recorder
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

It is a **provenance carrier**.

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

The terminal does not recognize the Custodian as a sentient agent checking in against a database. The local half-buried terminal’s state has been contaminated by another continuity-state — a version of reality in which the same terminal was already restored and used by the Custodian across many worlds. The Pale causes these continuity states to converge. The bleed expresses itself through frequencies, codes, procedural language, and authority patterns familiar to the Custodian.

The signal leaks recognition because the terminal has already been restored by this Custodian somewhere else. That is the pale signal — not a broadcast, but a convergence leak.

It is saying:

```text
SOURCE: CUSTODIAN FIELD TERMINAL
STATUS: UNVERIFIED
AUTHORITY: PARTIAL
TARGET: [CUSTODIAN IDENTITY — CONVERGENCE FROM ANOTHER CONTINUITY]
LAST CONTACT: [UNFILED]
PROVENANCE: DAMAGED
REQUEST: WITNESS
COMMAND: RETURN TO POST
```

That last word is important.

The terminal does not need repair yet. It needs to be **witnessed** by a Custodian so lawful reality can decide what it is.

## Opening mission flow

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

The player does not know what happened. The game does not explain the Severance. It gives one concrete command.

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

The source is physically ahead, but provenance-wise it is “below” and “prior” — and originating from a continuity that should not converge with this one. That reinforces that the Custodian perceives reality through origin, continuity, and authority, and that the Pale is causing these states to bleed.

### Beat 5 — Terminal reveal

The player finds the terminal in a ruined chamber within the grand institution: beneath a collapsed control tower, inside a half-buried gatehouse, or at the base of the terminal spire visible since the first scene.

It should not be glowing like a fantasy shrine. It should be mostly dead: armored casing, old screen, cables, dust, rust, broken side modules. The faded authority markings on its casing match the banners hanging from the ruins above.

But when the Custodian approaches, the terminal responds — and the response reveals something stranger than recognition.

```text
CUSTODIAN PRESENCE DETECTED.
AUTHORITY HANDSHAKE FAILED.
AUTHORITY HANDSHAKE FAILED.
AUTHORITY HANDSHAKE PARTIAL.

CONTINUITY CONVERGENCE CONFIRMED.
THIS TERMINAL HAS BEEN RESTORED BY THIS UNIT ELSEWHERE.
WITNESS ACCEPTED.
PROVENANCE ANCHOR ESTABLISHED.

RETURN TO POST.
POST ACCEPTED.
```

The terminal does not verify the Custodian’s identity by checking it against a database. The terminal’s state has been contaminated by another continuity — a version of events in which this Custodian already restored this terminal across many worlds. The Pale causes the states to converge. The command to RETURN TO POST was always the terminal calling the Custodian back to a post it already occupied in a different continuity.

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
- The terminal also records the first “provenance anomaly.”

Objective completion text:

```text
POST ACCEPTED.
CUSTODIAN FIELD TERMINAL LOCATED.
WITNESS STATE: ESTABLISHED
ARCHIVE LINK: PARTIAL
LOCAL COMMAND: DEGRADED
REPAIR CAPACITY: MINIMAL
CONTINUITY CONVERGENCE: CONFIRMED

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

Custodian Field Terminals were deployed as local continuity anchors in contested, damaged, or low-trust sectors. Each terminal maintained command access, repair logs, witness records, local infrastructure maps, and provenance chains for recovered assets.

This unit was found repeating an institutional command without confirmed grid authority: RETURN TO POST.

Recovered signal structure suggests the terminal was not transmitting a location or a request. It was transmitting a command from an institutional post that should not still exist. The command’s authority signature shows continuity convergence — this terminal’s state has been contaminated by another continuity in which it was already restored and active.

Status:
- Archive memory damaged
- Local authority partial
- Fabrication rights restricted
- Provenance index unstable
- Continuity convergence: confirmed

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
- first provenance anomaly
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
Witness contact established. Continuity convergence confirmed.

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
  - first_provenance_anomaly_detected
```

## Best name for the frequency

Do not call it “radio frequency” in system text. Give it a better term.

Options:

- **Custodian-band frequency**
- **Provenance carrier**
- **Witness-band signal**
- **Archive-band pulse**
- **Continuity-band signal**
- **Authority carrier**
- **Lineage signal**

Best combination:

> The terminal emits a **Custodian-band frequency**.
> Later, the Custodian identifies it as a **provenance carrier**.

Early game term: understandable.
Deep lore term: weirder.

## How to connect it to The Unarrival

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

The player should not know what “Unarrived” means yet. The terminal may not even use the noun “The Unarrival” yet. It should classify the problem as:

```text
UNFILED ORIGIN STATE
```

or:

```text
PROVENANCE FAILURE: SOURCE ABSENT
```

Then later the player learns this is part of the same cosmic wound.

## Design lock

I would lock this as the first objective thesis:

> **The Custodian awakens in a grand ruin beneath a repeating institutional command: RETURN TO POST. The command leaks from a terminal whose state is contaminated by another continuity — a version of events where this Custodian already restored this post. The Custodian follows not because it understands, but because answering dead authority is what it was made to do. The first act is not exploration. It is return. Finding the terminal establishes the first anchor of lawful reality, archive, repair, and player purpose.**

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
The first objective is not “explore.” It is **RETURN TO POST**. The Custodian awakens in a grand institution ruin beneath a repeating command from a terminal whose state has been contaminated by another continuity. The Custodian answers the command because responding to dead authority is what it was built to do. Witness contact establishes the first local anchor of lawful reality, archive, repair, scanning, and future base progression — and confirms that the Custodian is not inheriting power, but refusing to relinquish residual authority.
```
