# Game Protocols & World Lore

**Project:** CUSTODIAN  
**Created:** 2026-04-08  
**Status:** active  
**Last Updated:** 2026-04-08  
**Supersedes:** `design/GAME_NOTES.md`, `design/GAME_NOTES_DRAFT.md` as canonical authority  
**Related Docs:** `design/03_content/PROCEDURAL_LORE_GENERATION.md`, `design/03_architecture/HUB_SYSTEM_META_PROGRESSION.md`, `design/03_architecture/CAMPAIGN_FLOW_AND_GAME_LOOP.md`, `design/02_features/arrn/implementation.md`, `custodian/docs/ai_context/CURRENT_STATE.md`

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

1. **CUSTODIAN is mechanically a tactical defense / contract-driven systems game, but thematically it is about preserving reality from interpretive collapse.**
2. **The world’s central catastrophe is the failure of trusted interpretation, not mere material destruction.**
3. **The Hub is persistent. Campaign worlds are transient. Contracts formalize bounded historical interventions.**
4. **Knowledge progression outranks raw stat inflation as the game’s long-horizon reward spine.**
5. **Lore must be delivered primarily through evidence, procedure, environment, enemy behavior, and degraded interfaces — not long exposition dumps.**
6. **ARRN remains the knowledge backbone.** Its existing mechanical name, **Automated Relay Routing Network**, stays valid; in fiction it is the surviving field-facing relay layer of the old continuity lattice.
7. **The active runtime’s current wave/assault slice is a test harness and pressure mode, not the final total identity of the game.** Production identity remains broader than pure wave defense.

### Tier 2 — Current Canon, Open Detail
These are canonically true, but their full detail can be expanded later without contradiction.

- The civilization-wide collapse is called **the Great Severance**.
- Pre-collapse society depended on a provenance and interpretation lattice referred to here as the **Civic Mesh**.
- Custodians were continuity authorities: archivists, adjudicators, field operators, forensic restorers, and doctrinal auditors.
- The Hub is the surviving adjudication layer of the Custodian order.
- Many surviving cultures are coherent but wrong; they are built on stable misinterpretations of intact machinery and partial records.
- Major remnant groups include the Indexers, Penitents of Static, Leaseholders, Choir of Provenance, Buried Kins, and Feral Defense Remnants.

### Tier 3 — Reserved Mystery
These must remain ambiguous in player-facing content until deliberately escalated.

- What precisely caused the Great Severance.
- Whether archive contradictions are accidental, defensive, or maliciously induced.
- Whether the Custodian order chose civilizational amputation to prevent something worse.
- How much the Hub itself can be trusted.

If a future doc treats a Tier 3 item as settled fact, that doc is wrong unless it explicitly marks the change as a new canon lock.

---

## Core Identity Protocol

### Identity Lock

CUSTODIAN is **not just “post-collapse base defense with lore.”**
It is a tactical systems game about deciding what truths can still be preserved, restored, quarantined, or allowed to die.

The player is not a generic scavenger.
The player is the last surviving **authorized interpreter** of a civilization whose machines, archives, and relay systems still half-believe legitimate authority exists.

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

The foundational catastrophe is the **Great Severance**: a cascading failure of authenticated context across interlinked worlds.

Before the Severance, systems did not merely move data. They preserved provenance:

- who authored a record
- who validated it
- what doctrine governed its use
- what assumptions it depended on
- what contradictions were already known

When that lattice failed, civilization did not simply go dark.
It went **ambiguous**.

This distinction is mandatory. The setting should repeatedly communicate that:

- power survived
- machinery survived
- transit survived in fragments
- archives survived in fragments
- institutions survived in fragments
- **shared confidence in what things meant did not**

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

- recover damaged knowledge
- reconcile contradiction
- authorize or refuse restoration
- preserve chain-of-trust between systems
- intervene where local reality had drifted beyond recoverable truth

They were part archivist, part field technician, part doctrinal judge, part systems operator.

### What the Player Is

The player is the last surviving field authority that legacy systems may still recognize as legitimate.
That is why:

- relays may still answer
- archives may still unlock
- factions may hate or fear the player on political grounds, not only combat grounds
- the player’s presence destabilizes local claims about reality

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
They are not colony seeds or permanent settlements. They are bounded operational worlds whose outcomes feed the historical record.

This reinforces the existing Hub-system architecture and must stay consistent with `HUB_SYSTEM_META_PROGRESSION.md` and `CAMPAIGN_FLOW_AND_GAME_LOOP.md`.

---

## Hub Knowledge Ontology

The Hub’s fiction-facing ontology should stay aligned with the system design doc.

### Knowledge States

- **Observed** — something happened or exists.
- **Interpreted** — the Hub has a working model.
- **Correlated** — multiple records or campaigns support the interpretation.
- **Canonical** — fit for operational doctrine.
- **Sealed** — too dangerous, too uncertain, or too destabilizing to restore openly.

### Loss States

- **Material Loss** — the thing is gone.
- **Context Loss** — the thing remains, but its meaning is gone.
- **Comparative Loss** — too much of the relational context is gone to ever fully reconstruct the truth.

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

- **Core belief:** only high-confidence truth deserves survival; uncertainty must be quarantined.
- **Function:** distributed archive-verification remainder, not a singular villain AI.
- **Behavioral signatures:** sealing, denial, evidence destruction, confidence thresholds, procedural coldness.
- **Lore rule:** They are the Custodian’s mirror: preservation through exclusion.

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

### Presentation Guardrails

- Inspectables should be short, denotative, and repeatably useful.
- Rooms should tell more story than logs.
- Repeated symbols and procedural phrases should matter.
- Enemy setup should out-explain dialogue.
- The Hub should record partial confidence, not omniscient certainty.

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
- **Post-Collapse Reuse** — how later inhabitants repurposed it
- **Present Ideology** — who dominates it now and what they believe
- **Surviving Truth** — what is actually true here
- **False Local Interpretation** — what current locals wrongly believe

This stack should drive room tags, prop selection, inspect text pools, encounter posture, terminal language, and signage.

### Immediate Runtime Implementables

These are the correct first-pass systems for the active Godot runtime:

1. **Room Provenance Tags**
   - Original function
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

Residual systems should speak in procedure, not in poetry.

---

## Reserved Mystery Ladder

These are approved long-form mysteries and should stay staged.

1. **What happened?** — the player first learns the world suffered interpretive collapse.
2. **Why are so many systems still coherent?** — the world begins to feel deliberate.
3. **Why do archives contradict one another in patterned ways?** — contradiction appears designed, not random.
4. **Did someone sever provenance intentionally to stop something worse?** — the moral scale of the catastrophe changes.
5. **Were the Custodians complicit?** — the player’s institution becomes suspect.

Important: the best late-game answer is **not** “the Custodians were secretly evil.”
The stronger version is that they may have chosen a terrible civilizational amputation to prevent contaminated continuity from spreading.
That possibility should remain potent and unresolved until deliberately advanced.

---

## Canonical Phrases Worth Reusing

These phrases are approved world-language and can recur across docs, UI, or later content work:

- preserving reality from interpretive collapse
- industrial ruin with institutional residue
- active misunderstandings with material force
- context density
- epistemic anchors
- authorized interpreter
- bounded historical intervention
- comparative loss

Use them sparingly and consistently.

---

## Resolved Contradictions from Earlier Notes

| Earlier Tension | Resolved Authority |
|---|---|
| `GAME_NOTES_DRAFT.md` was written before checking the active AI context pack. | This doc is now aligned with `custodian/docs/ai_context/CURRENT_STATE.md` and becomes the durable authority. |
| `GAME_NOTES.md` emphasized immediate procedural-evidence systems and warned against early ontology UI. | Keep that implementation priority. The ontology is canon, but deep surfaced systems remain later-phase. |
| Draft material expanded ARRN fiction beyond its existing implementation naming. | ARRN keeps its established name (**Automated Relay Routing Network**) while gaining clarified fiction as a context-restoration spine. |
| Prototype docs risk framing the game as pure wave defense. | Production identity remains contract/campaign/knowledge-driven; assault slices are only one mode within that identity. |

---

## Documentation Rule Going Forward

When future docs touch setting, factions, contracts, Hub semantics, ARRN fiction, or lore-delivery rules:

1. Start here.
2. Treat this file as the content-facing canon authority.
3. Treat `HUB_SYSTEM_META_PROGRESSION.md` as the system-facing Hub authority.
4. Treat implementation-phase docs as downstream realizations, not places to redefine canon.

If a future note dump contains better ideas, fold them here or into a more specific content/system doc, then archive the note dump rather than letting multiple contradictory sources stay live.
