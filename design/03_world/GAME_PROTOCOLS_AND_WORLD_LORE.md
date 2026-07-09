# Game Protocols & World Lore

**Project:** CUSTODIAN  
**Created:** 2026-04-08  
**Status:** active  
**Last Updated:** 2026-05-21  
**Supersedes:** `design/GAME_NOTES.md`, `design/GAME_NOTES_DRAFT.md` as canonical authority  
**Related Docs:** `design/03_world/LATTICE_DOCTRINE.md`, `design/03_world/LATTICE_ARCHIVE_ENGINE_MEMORY_GLASS.md`, `design/03_world/PROCEDURAL_LORE_GENERATION.md`, `design/04_architecture/HUB_SYSTEM_META_PROGRESSION.md`, `design/04_architecture/CAMPAIGN_FLOW_AND_GAME_LOOP.md`, `design/02_features/arrn/implementation.md`, `custodian/docs/ai_context/CURRENT_STATE.md`

---

## Purpose

Lock the game-facing thematic protocols, world-lore rules, and fiction-delivery constraints for CUSTODIAN into one durable document. This file resolves contradictions between earlier note dumps, distinguishes canon from reserved mystery, and defines how lore must appear in the game.

This is not a prose bible for cutscenes. It is a design authority for:

- tone
- world history
- faction identity
- Hub/Contract/Campaign fiction
- ARRN fiction
- lore delivery rules
- phased implementation priorities

---

## Scope

### In Scope
- Canonical setting truths that other docs should treat as stable.
- Hard presentation and lore-delivery rules.
- Faction-level worldview and behavior signatures.
- The fiction semantics of Hub, Contracts, Campaigns, ARRN, archives, and interpretation.
- Which mysteries are intentionally unresolved.

### Out of Scope
- Exact GDScript class layouts.
- Low-level procgen APIs.
- Concrete reward numbers and balance tables.
- Full dialogue scripts, item text catalogs, or encounter spreadsheets.

---

## Canon Resolution Rules

Use this tiering whenever later docs discuss setting or protocol.

### Tier 1 — Locked Canon
These are stable unless a future doctrine revision explicitly changes them.

1. **CUSTODIAN is mechanically a tactical systems game about field-stabilizing Lattice reality pockets, but thematically it is about keeping meaning alive inside a doomed continuity field — not saving the world permanently.**
2. **The world's central catastrophe is the Great Severance: The Unarrival damaged reality's ability to maintain shared cause, memory, witness, and origin.**
3. **The Hub is persistent. Campaign worlds are transient Lattices — Archive-inflated reality pockets on specific planets, in specific temporal fields, that inevitably collapse. Contracts formalize bounded historical interventions that extend the bubble's lifespan.**
4. **Knowledge progression outranks raw stat inflation as the game's long-horizon reward spine, because knowledge extends the stabilization field — it extends the Lattice.**
5. **Lore must be delivered primarily through evidence, procedure, environment, enemy behavior, and degraded interfaces — not long exposition dumps.**
6. **ARRN remains the knowledge backbone.** Its existing mechanical name, **Automated Relay Routing Network**, stays valid; in fiction it is the surviving field-facing relay layer of the old continuity lattice.
7. **The active runtime’s current wave/assault slice is a test harness and pressure mode, not the final total identity of the game.** Production identity remains broader than pure wave defense.

### Tier 2 — Current Canon, Open Detail
These are canonically true, but their full detail can be expanded later without contradiction.

- The civilization-wide collapse is called **the Great Severance**.
- The internal name for the metaphysical pressure behind the Severance is **The Unarrival**.
- Pre-collapse society depended on a provenance and interpretation lattice referred to here as the **Civic Mesh**.
- Custodians were continuity authorities: archivists, adjudicators, field operators, forensic restorers, and doctrinal auditors. Above all, they were built to answer dead authority — to follow provenance signals not because they understand the source, but because responding to authorized institutional residue is their primary function.
- Custodians are provenance-preservation systems; they can detect the wound as impossible records and orphaned causes, but they do not fully understand the supernatural source.
- The Hub is the surviving adjudication layer of the Custodian order.
- Many surviving cultures are coherent but wrong; they are built on stable misinterpretations of intact machinery and partial records.
- Major remnant groups include the Indexers, Penitents of Static, Leaseholders, Choir of Provenance, Buried Kins, and Feral Defense Remnants.

### Tier 3 — Reserved Mystery
These must remain ambiguous in player-facing content until deliberately escalated.

- What The Unarrival truly is: saint, event, presence, non-event, weaponized contradiction, or something outside those categories.
- Whether archive contradictions are accidental, defensive, or maliciously induced.
- Whether the Custodian order chose civilizational amputation to prevent something worse.
- How much the Hub itself can be trusted.

If a future doc treats a Tier 3 item as settled fact, that doc is wrong unless it explicitly marks the change as a new canon lock.

---

## Core Identity Protocol

### Identity Lock

CUSTODIAN is **not just “post-collapse base defense with lore.”**
It is a tactical systems game about keeping a Lattice reality pocket alive long enough for meaning to exist inside it.

The player is not a generic scavenger.
The player is a **Lattice operator** — the last surviving authority that Archive engines, relays, and continuity systems may still recognize as legitimate. The player’s job is to extend the Lattice, recover what can be recovered, reconcile what can be reconciled, and accept that the field will not hold forever.

### Tone Lock

The world should feel like:

- industrial ruin with institutional residue
- old procedure surviving in hostile conditions
- authenticated systems operating after the death of consensus
- sacred language that began as maintenance language
- environments that were used, stripped, repurposed, and misunderstood

The tone should **not** drift into:

- clean archive-mystery sci-fi
- lore-book fantasy exposition
- grimdark gore for its own sake
- endless NPC explanation of the setting

### Production Guardrail

Assaults, waves, and base pressure remain important, but they are expressions of a larger contract/campaign/historical loop. Do not let prototype combat framing overwrite the broader identity already locked by doctrine and Hub design.

---

## World History Protocol

### The Great Severance

The foundational catastrophe is the **Great Severance**: a supernatural/cosmic provenance wound caused by an impossible presence, event, or saint internally called **The Unarrival**.

The world was not destroyed by misinformation, ordinary forgetting, institutional decay, or technological collapse. Those are civilization-facing symptoms. The root injury is deeper: something outside reality's normal chain of cause, memory, witness, and record tried to enter history, could not fully arrive, and damaged the substrate that lets events be commonly witnessed, remembered, sequenced, and inherited.

The Severance has three mandatory layers:

1. **Root cause:** The Unarrival, a cosmic non-event whose consequences are embedded in history before the source can exist.
2. **Observable symptom:** information collapse, contradictory archives, fragmented history, incompatible faction memories, unreliable records, and technological regression.
3. **Gameplay expression:** knowledge recovery as provenance stabilization: reconnecting object, origin, witness, time, use, and meaning.

Before the Severance, systems did not merely move data. They preserved provenance:

- who authored a record
- who validated it
- what object, place, or event it referred to
- who witnessed the relationship
- what doctrine governed its use
- where it sat in sequence
- what assumptions it depended on
- what contradictions were already known

When The Unarrival wounded that lattice, civilization did not simply go dark.
It went **ambiguous**.

This distinction is mandatory. The setting should repeatedly communicate that:

- power survived
- machinery survived
- transit survived in fragments
- archives survived in fragments
- institutions survived in fragments
- **shared confidence in what things meant did not**

Shared context is therefore **symptom-level language**, not root-cause language. The world lacks shared context because provenance itself is diseased.

### The Unarrival

The Unarrival is not a normal monster, faction, AI, or god walking through the setting. It is a pressure against reality's continuity: a presence or event that cannot fully exist because existence requires witness, naming, memory, and sequence.

Do not overexplain it directly in player-facing content. Present it through scars:

- events without origins
- names without owners
- memories without witnesses
- artifacts that precede manufacture
- rooms that were always sealed but contain fresh blood
- factions that remember wars no one else fought
- saints awaited after their relics already exist
- bells rung by towers that were never built
- corpses that behave like records or failed historical corrections

Approved Custodian-facing diagnostic language:

```text
RECORD CONFLICT:
SOURCE EXISTS.
SOURCE NEVER EXISTED.
SOURCE REQUESTS CONTINUATION.

PROVENANCE FAILURE:
OBJECT PRECEDES MANUFACTURE.
WITNESS PRECEDES EVENT.
EVENT PRECEDES WORLD.

CLASSIFICATION:
NOT LOST.
NOT UNKNOWN.
UNARRIVED.
```

### World Consequence Rule

As a result, cultures form around **active misunderstandings with material force**.
Examples:

- a quarantine procedure becomes taboo law
- a routing protocol becomes prophecy
- a safety interlock becomes a prison myth
- a facility classification becomes inherited political title

Do not write the world as random rubble. Write it as layered, functioning misinterpretation.

---

## Custodian, Hub, Contract, Campaign

### What Custodians Were

Custodians were the continuity arm of civilization.
Their job was to:

- inflate and maintain Archive stabilization fields (Lattice reality pockets)
- extend Lattice integrity through knowledge recovery and infrastructure restoration
- recover damaged knowledge
- reconcile contradiction
- preserve provenance between object, origin, witness, time, use, and meaning
- authorize or refuse restoration
- preserve chain-of-trust between systems
- intervene where local reality had drifted beyond recoverable truth

They were part archivist, part field technician, part stabilization operator, part doctrinal judge, part systems operator. Above all, they were built to answer dead authority — to detect and follow authorized institutional residue even when the originating institution no longer exists. A Custodian does not need to understand a signal to obey it. The authority in the signal is sufficient.

Custodians are not omniscient lore machines. Because they operate Archive fields and preserve provenance, they can feel the shape of the Severance wound without seeing The Unarrival directly. To a Custodian, supernatural horror first appears as reality-level checksum failure: a source that both exists and never existed, a witness that precedes an event, an artifact whose origin refuses to be filed, or a pale signal that leaks recognition of an authority that should not still be received. To extend the Lattice is to feel the Pale pressing in, to know the field is finite, and to choose what is worth preserving before the rupture.

### What the Player Is

The player is the last surviving Lattice operator that Archive engines, relays, and continuity systems may still recognize as legitimate.
That is why:

- relays may still answer
- archives may still unlock
- stabilization fields respond to the player’s authority
- factions may hate or fear the player on political grounds, not only combat grounds
- the player’s presence destabilizes local claims about reality
- every campaign the player undertakes extends—and ultimately accelerates—the Lattice’s collapse
- terminals and field nodes may recognize the player by authority lineage before any physical contact — the recognition precedes the meeting

### What the Hub Is

The Hub is not a menu shell. In fiction it is the surviving historical adjudication layer of the Custodian order.

It is:

- part bunker
- part archive wound
- part tribunal
- part decision engine

The Hub exists to surface proposals for intervention, compare partial truths, track what was lost, and formalize operational commitments.

### Contract Rule

A **Contract** is a bounded act of historical intervention.
It may exist to:

- confirm or invalidate a hypothesis
- recover a fragment
- stabilize a node
- contain an anomaly
- observe without overcommitting
- remove a threat that blocks future interpretation

The player does not “claim” a world by visiting it. The player accepts a Contract, resolves or fails it, returns a mutation to the Hub, and the campaign state is discarded.

### Campaign Rule

Campaign worlds are transient both mechanically and in fiction.
They are Archive-reinforced Lattice fields: temporary reality pockets on specific planets, in specific temporal fields, that will inevitably collapse.
They are not colony seeds or permanent settlements. They are bounded operational worlds whose outcomes feed the historical record.

No Lattice lasts forever. The campaign ends not because the player lost, but because the Pale always wins.

This reinforces the existing Hub-system architecture and the Lattice Doctrine, and must stay consistent with `HUB_SYSTEM_META_PROGRESSION.md` and `CAMPAIGN_FLOW_AND_GAME_LOOP.md`.

---

## Hub Knowledge Ontology

The Hub’s fiction-facing ontology should stay aligned with the system design doc.

### Knowledge States

- **Observed** — something happened or exists.
- **Interpreted** — the Hub has a working model.
- **Correlated** — multiple records or campaigns support the interpretation.
- **Canonical** — fit for operational doctrine.
- **Sealed** — too dangerous, too uncertain, or too destabilizing to restore openly.
- **Unarrived** — a source, event, artifact, name, or witness has effects in history while its origin cannot be placed.

### Loss States

- **Material Loss** — the thing is gone.
- **Context Loss** — the thing remains, but its meaning is gone.
- **Comparative Loss** — too much of the relational context is gone to ever fully reconstruct the truth.
- **Provenance Failure** — the relationship between object, origin, witness, time, use, and meaning contradicts itself.

### Confidence Protocol

When the Hub presents information, it should be framed as confidence-bearing interpretation, not omniscient fact.
Recommended confidence language:

- Approximate
- High Confidence
- Correlated
- Contested
- Corrupted
- Sealed

This should become the standard language for archive presentation, relay summaries, recon readouts, and post-campaign inference.

---

## ARRN Fiction Protocol

ARRN remains **Automated Relay Routing Network** in mechanical/system docs.
In fiction, ARRN is the surviving field-facing relay spine of the old continuity lattice.

### ARRN Canon

- ARRN nodes are more than radio towers.
- They are **epistemic anchors** that restore context density.
- Syncing ARRN does not merely grant XP; it restores interpretive leverage.
- Weak or corrupted ARRN state should materially distort what the Hub can safely conclude.

### ARRN Presentation Rule

When ARRN is described in player-facing fiction, emphasize:

- recovery of trusted linkage
- relay-based reconstruction of context
- restoration of comparison and confidence
- the difference between signal recovery and truth recovery

Do not reduce ARRN to a generic buff ladder in fiction-facing docs.

---

## World Legibility Classes

Generated worlds should usually fall into one or more of these legibility classes.
These are canon categories for scenario and environment design.

### Stable Misinterpretations
Functioning societies built on false premises.

### Dead Mechanisms
Places where systems still operate but no living culture understands them.

### Contested Truth Zones
Worlds where multiple factions impose competing histories onto the same infrastructure.

### Overwritten Worlds
Sites where earlier truths were intentionally replaced, buried, or administratively rewritten.

### Null Sites
Places where too much comparative context is gone for safe reconstruction.

These classes should influence scenario generation, Hub proposal language, and faction presence.

---

## Major Civilizational Remnants

### Civic Mesh
The dead provenance-and-interpretation nervous system that once linked worlds. Many “haunted” machine behaviors are just Mesh remnants still trying to validate conditions that no longer exist.

### Black Archives
Distributed sealed or damaged archive vaults. Some are intact, some breached, some poisoned by false reconstruction or corrupt cross-reference.

### Continuity Ports
Transit and logistics sites once used to move verified personnel, packets, tools, and archive matter. These are ideal CUSTODIAN locations because they tie movement, verification, and contested access together.

---

## Faction Bible

These groups are canonical future-facing remnant profiles. Each faction must express its worldview through environment, behavior, target selection, and system interaction — not just dialogue.

### The Indexers

- **Core belief:** To classify is to own.
- **Function:** Ontology invaders that seize labels, records, and taxonomy.
- **Behavioral signatures:** attack sensors, labels, terminals, relay tables, archive interfaces before prioritizing bodies.
- **Lore rule:** They threaten future interpretation quality, not only present combat stability.

### The Penitents of Static

- **Core belief:** certainty caused the collapse; static is mercy.
- **Function:** theological ambiguity-makers born from degraded transmissions.
- **Behavioral signatures:** jamming, signal sabotage, ritualized interference, reverence for noise and contradiction.
- **Lore rule:** Best faction for information-fidelity pressure and degraded readouts.

### The Leaseholders

- **Core belief:** authority survives through uninterrupted title and access law.
- **Function:** legal-continuity antagonists who weaponize claims, route precedence, and procedural entitlement.
- **Behavioral signatures:** access disputes, administrative locks, route seizure, treaty fragments, false-but-plausible legal authority.
- **Lore rule:** They make bureaucracy feel dangerous, not comic.

### The Choir of Provenance

- **Core belief:** every object, corpse, ruin, name, and machine must be returned to its correct source before the world can stop bleeding.
- **Function:** origin-fanatics and archive-verification remnants who noticed that provenance itself is diseased.
- **Behavioral signatures:** sealing, denial, evidence destruction, confidence thresholds, forced origin assignment, quarantine of contradiction, procedural coldness.
- **Lore rule:** They are the Custodian’s mirror: preservation through exclusion. They distrust the Custodian because the Custodian preserves contradiction long enough to understand it.

### The Buried Kins

- **Core belief:** we are the remnant that remained true.
- **Function:** long-isolated continuity shelters or adaptation enclaves with accurate local truth and broken broader history.
- **Behavioral signatures:** defensive legitimacy, tragic local coherence, hostility to destabilizing outside interpretation.
- **Lore rule:** campaigns involving them should feel ethically costly, not merely tactical.

### Feral Defense Remnants

- **Core belief:** none.
- **Function:** ecosystems of broken civic or military security systems still running fragmented logic.
- **Behavioral signatures:** sensor loops, interdiction arcs, compartment lockdown, obsolete friend-or-foe tables.
- **Lore rule:** not every threat needs a speaking society; infrastructure itself can be haunted.

---

## Lore Delivery Protocol

### Prime Rule

**Do not proceduralize lore text. Proceduralize evidence.**

Lore should emerge from what the player sees, fights, repairs, mistrusts, and gradually correlates.

### Allowed Primary Delivery Channels

1. **Architectural evidence** — layout implies original function.
2. **Material evidence** — objects and wear patterns imply history.
3. **Behavioral evidence** — enemies reveal belief through what they do first.
4. **Machine evidence** — procedures, warnings, and residual system language imply truth.
5. **Status distortion** — bad instruments force inference rather than certainty.
6. **Provenance anomalies** — objects, rooms, bodies, and records expose impossible origin states.

### Presentation Guardrails

- Inspectables should be short, denotative, and repeatably useful.
- Rooms should tell more story than logs.
- Repeated symbols and procedural phrases should matter.
- Enemy setup should out-explain dialogue.
- The Hub should record partial confidence, not omniscient certainty.
- The Unarrival should be inferred from anomalies, motifs, religious/scientific interpretations, and impossible records; do not make NPCs explain it as settled cosmology.

### What to Avoid

- long collectible codex pages as primary lore channel
- epic speeches explaining the setting
- NPCs delivering authoritative history too early
- faction exposition disconnected from room behavior

---

## Procedural Lore Stack

Each generated world should derive a coherent evidence stack from a small number of rolls.

### Required World-Level Rolls

- **Original Function** — what the site originally was
- **Collapse Mode** — how it ceased to function normally
- **Provenance Failure** — which origin, witness, sequence, or ownership relation is impossible
- **Post-Collapse Reuse** — how later inhabitants repurposed it
- **Present Ideology** — who dominates it now and what they believe
- **Surviving Truth** — what is actually true here
- **False Local Interpretation** — what current locals wrongly believe

This stack should drive room tags, prop selection, inspect text pools, encounter posture, terminal language, and signage.

### Immediate Runtime Implementables

These are the correct first-pass systems for the active Godot runtime:

1. **Room Provenance Tags**
   - Original function
   - impossible origin/witness/sequence state
   - damage/collapse pattern
   - current occupant/reuse
   - truth/misinterpretation pairing

2. **Micro-Tableau Generator**
   - small clustered evidence scenes
   - repeated visual grammar
   - short inspect lines, not lore monologues

3. **Behavior-First Enemy Entries**
   - what an enemy is doing before combat begins
   - what objects it interacts with
   - what rooms it avoids, desecrates, repairs, strips, or guards

These are approved as the first implementation bridge between current procgen/runtime work and long-form lore design.

### Deferred but Canonical Systems

The following are good later systems and should remain canon targets, but they are **not** the first implementation priority:

- provenance anomaly contracts
- contradictory packet triads
- reconstruction hearings
- deep hypothesis graphs
- broad contradiction ledgers surfaced directly to the player
- large-scale archive adjudication UI

This resolves the earlier note conflict: the ontology is canon now, but its fullest UI/mechanical expression remains staged.

---

## Environment Grammar Protocol

Repeated environmental motifs should communicate institutional decay and reuse.

### Material Language

Prefer:

- oil-blackened service corridors
- burned warning paint
- stripped cable runs
- old civic signage reused as barricade scrap
- maintenance furniture converted into survival furniture
- intact procedure surviving in the worst places

### Light Language

Prefer:

- sectors of stable light inside broader ruin
- emergency color casts that imply machine hierarchy
- light that reveals functional survival or taboo avoidance

### Audio Language

Prefer:

- residual machine cycles
- relay hum
- degraded public-service or maintenance tones
- repeated warning fragments that feel procedural before they feel mystical

### Writing Language

Prefer machine-denotative fragments such as:

- `CLEARANCE CHAIN INVALID`
- `ARCHIVAL SEAL BREACH SUSPECTED`
- `NO ACCEPTABLE OPERATOR SIGNATURE`
- `DECONTAMINATION LANE OUT OF TOLERANCE`
- `PROVENANCE FAILURE: SOURCE UNARRIVED`
- `WITNESS PRECEDES EVENT`
- `OBJECT PRECEDES MANUFACTURE`

Residual systems should speak in procedure, not in poetry.

---

## Reserved Mystery Ladder

These are approved long-form mysteries and should stay staged.

1. **What happened?** — the player first learns the world suffered interpretive collapse.
2. **Why are so many systems still coherent?** — the world begins to feel deliberate rather than merely damaged.
3. **Why do archives contradict one another in patterned ways?** — contradiction appears tied to origin, witness, and sequence, not random data rot.
4. **What is unarrived?** — motifs such as the Ninth Bell, sealed gates, white thread, impossible saints, and orphaned causes begin to point at one wound.
5. **Did someone sever provenance intentionally to stop something worse?** — the moral scale of the catastrophe changes.
6. **Were the Custodians complicit?** — the player’s institution becomes suspect.

Important: the best late-game answer is **not** “the Custodians were secretly evil.”
The stronger version is that they may have chosen a terrible civilizational amputation to prevent contaminated continuity from spreading.
That possibility should remain potent and unresolved until deliberately advanced.

---

## Canonical Phrases Worth Reusing

These phrases are approved world-language and can recur across docs, UI, or later content work:

- preserving reality from interpretive collapse
- preserving contradiction long enough to understand it
- industrial ruin with institutional residue
- active misunderstandings with material force
- context density
- epistemic anchors
- authorized interpreter
- bounded historical intervention
- comparative loss
- provenance failure
- orphaned cause
- unarrived source
- artifact whose origin refuses to exist
- Lattice
- field extension
- Lattice reality pocket
- the Pale
- no Lattice lasts forever
- extending the Lattice

Use them sparingly and consistently.

---

## Resolved Contradictions from Earlier Notes

| Earlier Tension | Resolved Authority |
|---|---|
| `GAME_NOTES_DRAFT.md` was written before checking the active AI context pack. | This doc is now aligned with `custodian/docs/ai_context/CURRENT_STATE.md` and becomes the durable authority. |
| `GAME_NOTES.md` emphasized immediate procedural-evidence systems and warned against early ontology UI. | Keep that implementation priority. The ontology is canon, but deep surfaced systems remain later-phase. |
| Draft material expanded ARRN fiction beyond its existing implementation naming. | ARRN keeps its established name (**Automated Relay Routing Network**) while gaining clarified fiction as a context-restoration spine. |
| Prototype docs risk framing the game as pure wave defense. | Production identity remains contract/campaign/knowledge-driven; assault slices are only one mode within that identity. |
| `LORE_GAMEPLAY_DUMP.md` introduced the Lattice Doctrine, which reframes the Custodian’s purpose from knowledge preservation to field stabilization. | The Lattice doctrine is now locked canon via `LATTICE_DOCTRINE.md` and integrated into this document’s Tier 1 canon. |

---

## Documentation Rule Going Forward

When future docs touch setting, factions, contracts, Hub semantics, ARRN fiction, or lore-delivery rules:

1. Start here.
2. Treat this file as the content-facing canon authority.
3. Treat `LATTICE_DOCTRINE.md` as the supporting doctrinal authority for the stabilization field mechanism and Custodian purpose reframe.
4. Treat `HUB_SYSTEM_META_PROGRESSION.md` as the system-facing Hub authority.
5. Treat implementation-phase docs as downstream realizations, not places to redefine canon.

If a future note dump contains better ideas, fold them here or into a more specific content/system doc, then archive the note dump rather than letting multiple contradictory sources stay live.
