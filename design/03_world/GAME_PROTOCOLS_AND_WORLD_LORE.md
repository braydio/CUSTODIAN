# Game Protocols & World Lore

**Project:** CUSTODIAN  
**Created:** 2026-04-08  
**Status:** active — content-facing protocol authority  
**Last Updated:** 2026-07-29  
**Lore Canon Authority:** `design/03_world/lore/CORE_LORE.md` — this file is primary for all lore, terminology, and faction definitions. `design/03_world/RECIPROCAL_CONTINUITY_DOCTRINE.md` is the highest authority for cosmology and continuity physics. This doc is a content-facing downstream that references those authorities.  
**Supersedes:** `design/GAME_NOTES.md`, `design/GAME_NOTES_DRAFT.md` as canonical authority  
**Related Docs:** `design/03_world/lore/CORE_LORE.md`, `design/03_world/lore/CRECHE_AND_LOCKER_LORE.md`, `design/03_world/factions/`, `design/03_world/LATTICE_DOCTRINE.md`, `design/03_world/LATTICE_ARCHIVE_ENGINE_MEMORY_GLASS.md`, `design/03_world/PROCEDURAL_LORE_GENERATION.md`, `design/02_features/factions/FACTION_EXPRESSION_SYSTEM.md`, `design/04_architecture/HUB_SYSTEM_META_PROGRESSION.md`, `design/04_architecture/CAMPAIGN_FLOW_AND_GAME_LOOP.md`, `custodian/docs/ai_context/CURRENT_STATE.md`

> **CANONICAL MIGRATION OVERRIDE:** Contracts access persistent Lattice Domains.
> CampaignRegion runtime instances are transient representations only. Mission
> resolution does not destroy a Domain, and canon permits later revisitation when
> route and field conditions allow it. See
> `design/03_world/LATTICE_DOMAIN_COSMOLOGY_MIGRATION.md`.

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

1. **CUSTODIAN is mechanically a tactical systems game about operating inside and reinforcing Lattice Domains, but thematically it is about keeping meaning alive in damaged continuity — not saving the world permanently.**
2. **The world's central catastrophe is the Severing: the failure, fragmentation, or deliberate destruction of a civilization-scale Lattice network after continuity access became a propagation hazard. The initiating cause remains unresolved.**
3. **The Hub is persistent. Contracts access Lattice Domains: existing damaged regions held coherent by Archive infrastructure. CampaignRegion runtime instances are transient; Domains may persist, change, be revisited, or eventually collapse.**
4. **Knowledge progression outranks raw stat inflation as the game's long-horizon reward spine, because knowledge extends the stabilization field — it extends the Lattice.**
5. **Lore must be delivered primarily through evidence, procedure, environment, enemy behavior, and degraded interfaces — not long exposition dumps.**
6. **ARRN remains the knowledge backbone.** Its existing mechanical name, **Automated Relay Routing Network**, stays valid; in fiction it is the surviving field-facing relay layer of the old continuity lattice.
7. **The active runtime’s current wave/assault slice is a test harness and pressure mode, not the final total identity of the game.** Production identity remains broader than pure wave defense.

### Tier 2 — Current Canon, Open Detail
These are canonically true, but their full detail can be expanded later without contradiction.

- The civilization-wide collapse is called **the Severing**. (Obsolete variants — "the Great Severance" — appear only in corrupted records or earlier faction terminology.)
- The internal name for the historical catastrophe at the heart of the Ash-Bell event is **the Ash-Bell Unarrival**, originating from Station IX of the Meridian Office. The canonical spelling is **Unarrival** (single n). See `design/03_world/RECIPROCAL_CONTINUITY_DOCTRINE.md`.
- Pre-collapse society depended on a continuity-verification and interpretation lattice referred to here as the **Civic Mesh**.
- Custodians were continuity authorities: archivists, adjudicators, field operators, forensic restorers, and doctrinal auditors. Above all, they were built to operate, inspect, restore, isolate, and adjudicate Lattice infrastructure.
- Custodians are continuity authority because they operate, inspect, restore, isolate and adjudicate Lattice infrastructure. A Custodian might examine provenance because "Did this reactor come from our continuity?" is an extremely important engineering question — not because correct paperwork makes the reactor real.
- The Hub is the surviving adjudication layer of the Custodian order.
- Many surviving cultures are coherent but wrong; they are built on stable misinterpretations of intact machinery and partial records.
- Major remnant groups include the Indexers, Pale Bell Penitents, Leaseholders, Choir of Provenance, Buried Kins, and Feral Defense Remnants (see `design/03_world/factions/` for complete profiles).

### Tier 3 — Reserved Mystery
These must remain ambiguous in player-facing content until deliberately escalated.

- What first demonstrated reciprocal traversal?
- What was Null Warrant containing?
- Was the Severing deliberate?
- How many continuity routes survived?
- Are active Lattice restorations recreating dangerous paths?
- Is the Pale related to the original hazard?
- Has anything been following restored routes?

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

### The Severing

The foundational catastrophe is **the Severing**: the failure, fragmentation, or deliberate destruction of a civilization-scale Lattice network after continuity access became a propagation hazard. The initiating cause remains unresolved.

The old civilization learned to use Lattice technology to establish access between adjacent continuities. Such paths are not fundamentally one-way: any continuity reached represented not only a destination, but a potential route back. The reciprocal nature of continuity access was the hazard that ultimately led to the Severing.

The Severing has three mandatory layers:

1. **Root cause:** unresolved. The leading hypothesis is a continuity propagation hazard — something propagating through the return paths that had been opened. Whether this was disaster, attack, containment, or all three remains unknown.
2. **Observable symptom:** isolated continuities, spreading Pale, failed Lattice pockets, cross-continuity debris, contradictory records from different continuity origins, institutional collapse, and technological regression.
3. **Gameplay expression:** knowledge recovery for Lattice calibration, anomaly classification, route safety, continuity-origin identification, historical reconstruction, and operational decision quality.

Before the Severing, the Lattice civilization maintained continuity infrastructure:

- verified transit between continuities
- route safety and calibration
- continuity-origin identification
- authority and containment records
- field telemetry and diagnostics

When the Severing destroyed or amputated much of that network, civilization did not simply go dark. It went **ambiguous**.

This distinction is mandatory. The setting should repeatedly communicate that:

- power survived
- machinery survived
- transit survived in fragments
- archives survived in fragments
- institutions survived in fragments
- **verified continuity-origin information did not**

Shared context is therefore **symptom-level language**, not root-cause language. The world lacks shared context because continuity routes were severed, institutions collapsed, and cross-continuity debris introduced contradictory material.

### The Open Interval and Ash-Bell

The Ash-Bell Unarrival is the player's most intimate demonstration of the Severing's physics. Before the Protocol, still humanoid figures began recurring around the Lower Quarter in places with no physical approach. Null Warrant recognized the sightings as a continuity hazard and was visibly afraid of them. Evacuation began; quarantine diversion and continuity instability collapsed the primary transit corridor's capacity; and the remaining crowd was sent toward West Gate. When Null Warrant could no longer verify the continuity origin and custody of that flow, black banners rose and the gate was sealed before the district was clear. During that emergency, the Meridian Office initiated the Ash-Bell Protocol — a nine-station synchronization procedure. Station IX, commanded by Precentor Orra, failed to answer within its required window. The system classified this as **Unarrival**.

Orra had deliberately diverted to rescue stranded civilians. Eight stations answered. Station IX did not. The resulting Open Interval physically coupled the Ash-Bell Continuity to the active world. People, matter, memories, and structures crossed. Orra eventually reached Station IX and gave the Ninth Answer, ending the wider coupling — but local catastrophe had already occurred.

Do not overexplain Ash-Bell directly in player-facing content. Present it through:

- a broken ordinary chapel bell
- the wrong basin where a fountain should be
- white thread marking boundaries
- a ghost procession of continuity drifters
- a phrase: "Orra Comes Late"
- ritual timing that echoes station synchronization
- a still figure where no route reaches it, and an armed Warrant officer who
  retreats instead of approaching
- the field order `NAME FIRST / WRIST SECOND`

Do not identify the figures as `NON-RECIPIENT`, the cause of the Severing, or a
known species. Null Warrant possessed fragments suggesting that a resembling
presentation had once incorporated human populations into coherent but
incomprehensible mass movement. Similarity explains institutional fear; it does
not settle identity or cause.

Do not write the world as random rubble. Write it as layered, functioning misinterpretation.

---

## Custodian, Hub, Contract, Campaign

### What Custodians Were

Custodians were the continuity arm of civilization.
Their job was to:

- inflate and maintain Archive stabilization fields (Lattice reality pockets)
- extend Lattice integrity through knowledge recovery and infrastructure restoration
- operate, inspect, restore, isolate, and adjudicate Lattice infrastructure
- recover damaged knowledge
- classify continuity anomalies and identify continuity origins
- authorize or refuse restoration
- preserve chain-of-trust between systems
- intervene where local reality has been contaminated by cross-continuity material

They were part archivist, part field technician, part stabilization operator, part doctrinal judge, part systems operator. A Custodian examines provenance because "Did this reactor come from our continuity?" is an extremely important engineering question — not because correct paperwork makes the reactor real.

Custodians are not omniscient lore machines. Because they operate Lattice infrastructure, they can feel the shape of continuity damage without fully understanding its source. To a Custodian, hazards first appear as continuity anomalies: imported artifacts with no local manufacture record, witnesses from adjacent states, structures that overlap incompatible histories, or route signatures that should not still be active. To extend the Lattice is to feel the Pale pressing in, to know the field is finite, and to choose what is worth preserving before the rupture.

Lost, damaged, or long-absent Custodians were returned to service through institutional recovery sites called **crèches** — processing centers that reissue a designation and its equipment without confirming continuity of personhood. See `design/03_world/lore/CRECHE_AND_LOCKER_LORE.md` for the full canon, including the rule that a designation-keyed locker (such as the one holding the P-9 sidearm) releases assigned equipment without proving who the person bearing the designation is.

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
- part archive
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

The player does not “claim” a Domain by visiting it. The player accepts a Contract, resolves or fails it, returns a mutation to the Hub, and the active CampaignRegion runtime instance is unloaded.

### Campaign Rule

CampaignRegion runtime instances are transient mechanically. They represent
bounded operational access to persistent Lattice Domains whose outcomes feed the
historical record. A Domain is not a colony seed or an Archive-created bubble;
its field may expand, contract, persist, or eventually fail in-world.

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

### Loss States

- **Material Loss** — the thing is gone.
- **Context Loss** — the thing remains, but its meaning is gone.
- **Comparative Loss** — too much of the relational context is gone to ever fully reconstruct the truth.
- **Provenance Conflict** — forensic evidence shows contradictory origin, witness, sequence, or ownership relations.

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
The dead continuity-verification and interpretation nervous system that once linked worlds. Many “haunted” machine behaviors are just Mesh remnants still trying to validate conditions that no longer exist.

### Black Archives
Distributed sealed or damaged archive vaults. Some are intact, some breached, some poisoned by false reconstruction or corrupt cross-reference.

### Continuity Ports
Transit and logistics sites once used to move verified personnel, packets, tools, and archive matter. These are ideal CUSTODIAN locations because they tie movement, verification, and contested access together.

---

## Faction Bible

> **This section is now a summary.** For complete faction profiles, see `design/03_world/factions/`. For the implementation taxonomy, gameplay boundaries, and behavior contracts, see `design/02_features/factions/FACTION_EXPRESSION_SYSTEM.md`. For the lore canon framework (Severing, Ash-Bell Unarrival, Null Warrant Office), see `design/03_world/lore/CORE_LORE.md` and `design/03_world/RECIPROCAL_CONTINUITY_DOCTRINE.md`.

The six canonical factions are **different answers to the collapse of trustworthy civilization**:

| Faction | Severing Interpretation | Gameplay Pressure |
|---|---|---|
| **Pale Bell Penitents** | Cosmic disclosure — arrival was never guaranteed | Temporal-perceptual distortion |
| **Indexers** | Classification catastrophe — universe became unfiled | Metadata corruption |
| **Leaseholders** | Access-chain breach — rightful claims were broken | Access denial |
| **Choir of Provenance** | Provenance contamination — context detached from things | Quarantine choices |
| **Buried Kins** | Abandonment — help never came | Relational (conditional polity) |
| **Feral Defense Remnants** | None — protocol continued without command | Spatial denial (hazard layer) |

### Design rule (repeated from the implementation spec)

Each faction must express its worldview through **environment, behavior, target selection, and system interaction** — not just dialogue. The player should learn what a faction is by walking into a room and noticing what has been done to it.

### Feral Defense note

Feral Defense Remnants are classified as a **hazard layer**, not a living polity. They are composable security/automation ecology that can overlay any region. They have no beliefs, no dialogue, and no ideological behavior.

### Buried Kins note

The Buried Kins are a **conditional polity**, not a default hostile population. Combat is a failure state. They require relationship tracking and conditional hostility gates before implementation.

### Faction implementation priority

Per the full spec, the first production target per faction is:
1. One unmistakable environmental tableau
2. One pre-combat activity
3. One target-selection doctrine
4. One signature gameplay pressure
5. At most two faction-specific combat roles

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
- Continuity hazards and Ash-Bell history should be inferred from anomalies, motifs, religious/scientific interpretations, and impossible records; do not make NPCs explain the full cosmology as settled truth.

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
- **Provenance Conflict** — forensic evidence of contradictory origin, witness, sequence, or ownership
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

- continuity anomaly contracts
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
- `PROVENANCE CONFLICT: ORIGIN UNRESOLVED`
- `WITNESS PRECEDES EVENT`
- `OBJECT PRECEDES MANUFACTURE`

Residual systems should speak in procedure, not in poetry.

---

## Reserved Mystery Ladder

These are approved long-form mysteries and should stay staged.

1. **What happened?** — the player first learns the world suffered interpretive collapse.
2. **Why are so many systems still coherent?** — the world begins to feel deliberate rather than merely damaged.
3. **Why do archives contradict one another in patterned ways?** — contradiction appears tied to continuity origin, not random data rot.
4. **What was Null Warrant containing?** — motifs such as sealed gates, classified routes, and institutional terror begin to point at containment.
5. **Was the Severing deliberate?** — the moral scale of the catastrophe changes.
6. **Were the Custodians complicit?** — the player's institution becomes suspect.

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
- continuity anomaly
- foreign-origin artifact
- imported structure
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
