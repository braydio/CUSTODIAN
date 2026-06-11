# Sundern Keep — Lore Reference

> **Canonical name:** Continuity Port Bastion S-DRN / Authority Gate 7 / Archive Custody Fortress
> **Post-collapse name:** Sundern Keep (also rendered as *Sundered Keep* in runtime data)
> **Design ID:** sundered_keep
> **Status:** Design reference — not all elements are implemented in runtime
> **Cross-reference:** See `design/00_canon/CORE_LORE.md` for master lore canon, `design/03_content/factions/` for faction profiles
> **Terminology note:** "Penitents of Static" corrected to "Pale Bell Penitents" (early) per ASH_BELL_AND_DESIGN_GUIDANCE.md. "The Severance" corrected to "The Severing" (public term). "Unnarrival" → "Unnarrival" (canonical spelling).

---

## One-Line Identity

**Sundern Keep is a continuity fortress built to hold a strategic Lattice aperture, now temporally adrift after the Great Severing caused several incompatible versions of the same keep to converge into one playable ruin.**

It looks like a castle because later cultures misunderstood it as a fortress-monastery. It was originally:

- orbital intake bastion
- continuity-port gatehouse
- archive custody fort
- military verification citadel
- emergency Lattice anchor
- sealed transit authority complex
- post-collapse mythic castle

The player experiences it as a haunted sci-fi castle. The truth is stranger: it is a **dead piece of institutional transit infrastructure wearing the shape of a keep because that is how survivors learned to describe it.**

---

## Canon Role

Sundern Keep sits at the intersection of three established canon concepts:

### Continuity Port
It was connected to verified transit: personnel, packets, tools, archive matter, authority, and possibly bodies. Continuity Ports are ideal CUSTODIAN sites because they tie movement, verification, and contested access together.

### Lattice Reality Pocket
The keep is not stable territory. It is a bounded Lattice field whose local history keeps trying to resolve into a single version, but never fully can. CUSTODIAN is about keeping Lattice reality pockets alive long enough for meaning to exist inside them — not permanently saving the world.

### Provenance Failure
Its main wound is not "time travel" in the simple sense. The keep has broken relationships between **object, origin, witness, time, use, and meaning**. This is consistent with the canon Severing framework: The Unnarrival damaged reality's ability to maintain shared cause, memory, witness, and origin; information collapse is the observable symptom; knowledge recovery is provenance stabilization.

---

## What Happened Here

Before the Severing, Sundern Keep was not called a keep.

It was something like:

> **Continuity Port Bastion S-DRN / Authority Gate 7 / Archive Custody Fortress**

Its job was to protect and adjudicate a major transit node. Anything passing through had to be verified: personnel, archive freight, field operators, sealed records, dead matter, machine cores, and emergency command authority.

Then the Great Severing hit.

The keep did not simply collapse. It was caught mid-function. Its systems were verifying transit, sealing gates, routing authority, and preserving witness records when The Unnarrival damaged the causal substrate. Because of this, different procedural states of the keep became lodged together.

The keep is now simultaneously:

1. **Before the breach** — intact, staffed, sealed, waiting.
2. **During the assault** — gates falling, alarms active, defenders dying.
3. **After abandonment** — ruined, flooded, scavenged, mythologized.
4. **Later misremembered** — treated as a holy castle, cursed keep, or forbidden court.
5. **Unnarrived** — containing structures, corpses, and records whose origins cannot be placed.

---

## Core Theme

> **A fortress built to preserve continuity is now evidence that continuity failed.**

Sundern Keep is not just a "castle level." It is the first location where players see that even the institutions built to maintain reality were not immune to the Pale. Every design decision should support this.

---

## The Central Contradiction

> **The keep successfully sealed something that had not arrived yet.**

This is stronger than "the keep is drifting in time." It is a provenance paradox:

```
GATE STATUS: SEALED
SEALING EVENT: CONFIRMED
BREACH EVENT: ABSENT
BREACH CAUSE: UNARRIVED
```

Or:

```
The West Gate was sealed after the breach.
The West Gate prevented the breach.
The West Gate was built because the breach had already been prevented.
```

This lets the keep tie directly into The Unnarrival without revealing what The Unnarrival is. The Unnarrival remains ambiguous, appearing through events without origins, artifacts that precede manufacture, sealed rooms with fresh blood, saints awaited after their relics exist, and similar scars.

---

## Why It Is Called Sundern Keep

The name is post-collapse.

**"Sundern"** comes from survivor language: sundered, severed, split, broken across itself.

In old records, the site had sterile designations:

- `S-DRN Continuity Bastion`
- `Authority Gate 7`
- `Custody Port Sunder Node`
- `Archive Transit Bastion`
- `Lattice Intake Fortress`

Survivors heard broken system fragments:

```
S-DRN
S-DRN
SUNDER NODE
SUNDERN
```

Over generations, "Sundern Keep" became the mythic name. (Runtime data uses "sundered_keep" — a later translation of the same survivor name.)

---

## Zone Breakdown

### 1. The Return Causeway
**Function:** Entry approach / dead cosmic intake / first post
**Temporal state:** After abandonment, contaminated by a restored terminal state
**Mood:** Awe, silence, duty

The Custodian follows:
```
RETURN TO POST.
RETURN TO POST.
RETURN TO POST.
```

The causeway is not a normal road. It is a dead orbital or interstellar Lattice intake collapsed onto planetary surface: archive-mass rails, aperture ribs, gravity-anchor plates, dead alignment pylons, and the half-buried Field Terminal.

**Runtime status:** Implemented as the entry causeway in phase 1. Visuals are currently gothic castle stone rather than visible orbital intake infrastructure — the sci-fi origin is implied but not yet visually explicit.

---

### 2. The Gatehouse of Unheld Authority
**Function:** First gate into Sundern Keep
**Temporal state:** Still checking credentials from three different eras
**Mood:** Procedure turned hostile

System language:
```
CLEARANCE CHAIN INVALID
NO ACCEPTABLE OPERATOR SIGNATURE
POST AUTHORITY CONTESTED
```
Gameplay: identity scanner puzzle, broken defense turret, first Feral Defense Remnant patrol, optional side room with field tags, gate opens only after the Custodian restores partial authority.

**Runtime status:** The Main Gate portcullis and gatehouse structure exist. The authority-restoration mechanic is partially represented through the gate key pickup (`sundered_gate_key`).

---

### 3. The Split Ward
**Function:** Outer courtyard / processing yard
**Temporal state:** Intact lanes and ruined battlefield overlap
**Mood:** Grand confusion, readable routes

One half of the courtyard is cleanly marked with old transit lanes; the other is collapsed into siege rubble. Bodies face different directions as if defending different attacks. Machine barricades are embedded into old stonework. Starship-grade cargo rails run under castle masonry.

Split path: archive lane vs utility trench. One route has combat, one has traversal/elevation.

**Runtime status:** Courtyard area exists. The split-path design is partially implemented through the courtyard layout and under-bridge traversal. Sci-fi transit lane markings and cargo rail infrastructure are not yet visually present.

---

### 4. The Great Hall of Repeated Assembly
**Function:** Muster hall / archive tribunal / command floor
**Temporal state:** Repeatedly assembling different groups from different eras
**Mood:** Institutional sacredness

The Great Hall should look like: military briefing hall, parliament chamber, archive court, cathedral nave without religion, command post, data reliquary. Seat rows with terminal plaques, old authority dais, hanging cable-vaults, dead wall screens, seal-lock doors, ash-black floor sigils that are actually routing diagrams.

Potential tableau: A row of empty seats faces a command dais. Each station contains a field tag. Every tag names the same operator, but the deaths are dated in different centuries.

**Runtime status:** The Great Hall exists with columns, banquet tables, throne, banners, chandelier. The marine ambush triggers here. The sci-fi institutional elements (terminal plaques, cable vaults, floor sigils as routing diagrams) are not yet represented.

---

### 5. The Lattice Framework
**Function:** Structural aperture / continuity transit spine / recontextualization passage
**Temporal state:** Active, but holding incompatible readings
**Mood:** Scale shift, vertigo, the moment it clicks

This is the zone where the player realizes Sundern Keep is not a castle.

After passing through the Great Hall, the route opens into an exposed Lattice aperture: the structural core of what was once the Continuity Port's transit spine. Here the player sees the infrastructure the castle masonry was built *around* — aperture ribs, alignment pylons, gravity-anchor plates, dead cargo rail cradles, the massive ring-frame where verified transit was once routed.

This is where the temporal drift becomes *visible as structure* rather than just environmental clutter. A single rib may show:

- original polished alloy near its base
- siege damage midway up
- post-collapse moss and salt scarring near the top
- a maintenance patch applied before the alloy was forged

The Lattice field here is still faintly active — shimmering, flickering, occasionally rendering a ghost transit that never arrived or already passed. The player can see the keep's different temporal states pressing against each other, held apart by the dying field.

This is the zone where the grammar clicks. The player has already experienced the contradictions (gatehouse, split ward, great hall). Now they see the *infrastructure* that produced them.

**System language on entry:**
```
LATTICE APERTURE DETECTED
CONTINUITY FIELD: UNSTABLE
TEMPORAL BANDWIDTH: MULTIPLE
PROVENANCE CONVERGENCE: FAILED
```

**Gameplay:** Traversal across exposed aperture architecture — narrow ribs, gap jumps, gravity-anchor platforms, partially collapsed transit cradles. Enemies here are sparse but significant: Feral Defense Remnants still trying to route transit that will never come, or Pale Bell Penitents jamming the aperture to prevent any single reading from stabilizing.

**Runtime status:** Not yet implemented. Requires new visual assets (aperture ribs, alignment pylons, Lattice field effects) distinct from the castle stonework of earlier zones.

---

### 6. The Drowned Causeway / Collapsed Sea Cut
**Function:** Breach in the fortress edge
**Temporal state:** Sea/void/collapse intruding through incompatible geography
**Mood:** Vertigo, cosmic exposure

Castle wall ends in a black ocean or starless void. Lower causeway visible below. Broken bridge passing under upper bridge. Water/void occupying places where interior rooms should be. Distant orbital debris visible through collapsed masonry.

Elevated traversal, cliff/void boundary kit, enemies use ramps and stairs, possible route under the bridge on the shore.

**Runtime status:** Ocean void tiles, cliff edges, and lower shore lanes exist. The under-bridge passage is partially implemented. The black ocean/starless void is represented by `ocean_void_01` tiles.

---

### 7. The Black Archive Annex
**Function:** Sealed archive vault
**Temporal state:** Records exist, but their meaning does not
**Mood:** Cold, dangerous knowledge

Canon defines Black Archives as sealed or damaged archive vaults — some intact, some poisoned by false reconstruction or corrupt cross-reference.

Gameplay: scan records, choose which record to stabilize, risk corrupting local map/state, unlock enemy/faction truth, possible Indexer encounter.

System language:
```
ARCHIVAL SEAL BREACH SUSPECTED
RECORD CONFLICT: SOURCE EXISTS / SOURCE NEVER EXISTED
CONFIDENCE: CONTESTED
```

**Runtime status:** Not yet implemented. Would tie into the existing Black Archive canon and provenance stabilization mechanics.

---

### 8. The Bell Court / Ash-Bell Continuity Scar
**Function:** Optional deep-lore chamber
**Temporal state:** Imported from another continuity
**Mood:** Quiet dread

Where Ash-Bell motifs appear without taking over the whole keep: Ninth Bell references, white thread, bell clapper without tower, kneeling machines or corpses, sealed door with fresh blood, terminal fragment whose status says `POST HELD` before the player arrives. Not explained. Not native to Sundern Keep.

**Runtime status:** The Ash-Bell / Forlorn-Ritualant module exists as a separate encounter. Could be linked to Sundern Keep through a future Bell Court sub-zone.

---

### 9. The West Gate That Was Never Built
**Function:** Major objective gate
**Temporal state:** Exists only because it was sealed
**Mood:** Impossible authority

The keep's central mystery. Facts the player can discover:

- Maps from before the breach show no West Gate
- Later maps show it sealed
- Defenders died holding it
- Maintenance logs request parts for its construction *after* its collapse
- The gate blocks a route to something the keep may have been built to prevent

Diagnostic:
```
OBJECT: WEST GATE
INSTALLATION: ABSENT
SEAL: CONFIRMED
BREACH: PREVENTED
CLASSIFICATION: UNNARRIVED SOURCE
```

**Runtime status:** Not yet implemented. The level has a main gate (south) and great hall doors, but no West Gate area.

---

## Faction Usage

### Feral Defense Remnants
Best starter presence. They are not ideological — they are the keep's dead systems still enforcing fragments of clearance, lockdown, routing, and friend-or-foe tables. Use for gate sentries, patrol loops, dormant turrets, scanner pylons, armor drones, old oath-guards.

**Runtime alignment:** Current wave enemies (drones, grunts, fast, heavy) are not yet tagged with faction identity. The marine ambush could be framed as a Feral Defense Remnant.

### Choir of Provenance
Best mid-zone antagonist. They believe every object must be returned to its correct source before the world can stop bleeding. They would seal contradictory rooms, destroy impossible records, assign forced origins to artifacts, mark doors as `FALSE SOURCE`. Their philosophy should feel dangerously reasonable.

**Runtime alignment:** Choir of Provenance is established in canon docs but not yet present in Sundern Keep runtime.

### Pale Bell Penitents
Best for signal/anomaly areas. They treat contradictory records as holy mercy. They jam systems, corrupt readouts.

**Runtime alignment:** Not yet present.

### Leaseholders
Excellent optional faction. Claim legal continuity over the keep using procedural entitlement: "The gate remained sealed. Title therefore survived." Weaponize old access law, route precedence, inheritance claims, jurisdiction locks.

**Runtime alignment:** Not yet present.

---

## Key Items and Drops

### Common
- Ruin Scrap
- Spent Charge Cell
- Frayed Signal Filament
- Broken Seal Pin
- Archive Plate Fragment
- Gatehouse Fuse

### Lore / Provenance Items
- Cracked Field Tag
- Mismatched Custody Writ
- Pre-Breach Repair Order
- Unissued Gate Key
- Bell-Marked Thread
- Memory Glass Fragment
- West Gate Seal Fragment
- Dead Operator Token
- Ash-Bell Clapper Shard

### Major Relics
- **The Seal That Preceded the Gate:** A heavy authority seal stamped for a gate whose installation record is absent.
- **The Ninth Bell Clapper:** A clapper from a bell tower that no map agrees existed.
- **The Custody Writ:** A legal/operational order granting authority to the Custodian, dated after the keep's collapse and before the Custodian's arrival.
- **The Black Archive Index:** Unlocks the first strong clue that Sundern Keep is not merely decayed, but temporally misfiled.

**Runtime alignment:** Grunt loot table already includes `cracked_field_tag`, `memory_glass_fragment`, `white_thread_knot`. The lore-specific items are not yet implemented.

---

## Environmental Motifs

Repeated motifs to make the keep feel authored:

- White thread tied to handles, trigger guards, seal locks, bell hardware
- Burned warning paint over ceremonial-looking floor diagrams
- Field tags arranged as offerings
- Dead terminals still printing clearance failures
- Rooms with two incompatible repair states
- Doors sealed from both sides
- Banners made from repurposed civic signage
- Cable bundles threaded through castle stone like roots
- Bell shapes hidden inside scanner frames
- Water/void/sky visible through impossible wall breaks

**Runtime alignment:** `temporal_echo_overlay_01` tile exists. The banner and brazier props exist. White thread and provenance-specific environmental details are not yet implemented.

---

## Statusline Examples

On entering Sundern Keep:
```
LATTICE STATUS: CONTESTED
PALE INDEX: LOW
ANOMALOUS ACTIVITY: STRUCTURAL
AUTHORITY: RESIDUAL
SITE: SUNDERN KEEP
```

At the Great Hall:
```
LATTICE STATUS: PARTIAL
PALE INDEX: RISING
ANOMALOUS ACTIVITY: WITNESS LOOP
AUTHORITY: CONTESTED
POST: UNHELD
```

At the West Gate:
```
LATTICE STATUS: FRAYING
PALE INDEX: ACTIVE
ANOMALOUS ACTIVITY: UNNARRIVED SOURCE
AUTHORITY: SEALED
GATE: NOT BUILT / CLOSED
```

After stabilizing the first terminal:
```
LATTICE STATUS: ANCHORED
PALE INDEX: CONTAINED
ANOMALOUS ACTIVITY: RECORDED
AUTHORITY: PARTIAL
POST: HELD
```

**Runtime alignment:** The command terminal could display these as location-based status readouts. Not yet implemented.

---

## Gameplay Meaning

Sundern Keep should teach that the game is not about clearing dungeons. It is about deciding what can be stabilized.

Mechanically, it should introduce:
- Elevation and under-bridge traversal
- Terminal activation
- Room provenance tags
- Route choice through broken institutional systems
- First meaningful faction behavior
- First Black Archive evidence
- First hard provenance contradiction
- First optional lore-object that changes Hub interpretation

The player is not just "exploring a castle." They are moving through a **collapsed argument about what the castle ever was.**

---

## The Keep's Strongest Final Truth

> The keep was not built to defend against an invader.
> It was built to defend against a conclusion.

The old institution discovered that some transit records pointed to an arrival that could not be allowed to become true. They sealed the site, severed its provenance, and let the keep become temporally adrift rather than permit the continuity chain to complete.

This keeps the mystery ladder intact: the player sees the world's interpretive collapse first, then begins to suspect the contradictions are patterned, then eventually asks whether the Custodians or their institution performed a terrible amputation to stop something worse.

---

## Design Lock

> Sundern Keep is a temporally adrift Continuity Port bastion: a fortress-shaped Lattice wound where several incompatible states of the same institutional site have collapsed into one playable ruin. Its castle form is a post-collapse misinterpretation of old authority infrastructure. Its central contradiction is the West Gate: a sealed structure whose construction record is absent, whose seal predates its installation, and whose purpose was to prevent an arrival that had not yet occurred. The Custodian does not conquer the keep; they stabilize enough of its provenance to hold the post, recover its surviving truth, and decide which contradictions are safe to preserve.
