# `design/20_features/in_progress/HUB_SYSTEM_META_PROGRESSION.md`

# Hub System (Meta Progression)

**Project:** CUSTODIAN
**Status:** Required Early
**Priority:** Critical, but after runtime world/camera stabilization
**Depends On:** Runtime World & Camera Stabilization
**Blocks:** Campaign Flow, World Transition, Region Generation, Integration Contract
**Runtime Target:** Godot 4.x (`custodian/`)
**Last Updated:** 2026-04-08
**Content Canon Authority:** `design/03_content/GAME_PROTOCOLS_AND_WORLD_LORE.md`

---

## 1. Purpose

Define the Hub as the persistent strategic and epistemic layer that exists across campaigns. The Hub is not a menu, not a generic metagame wrapper, and not a power-escalation system. It is the persistent historical layer that survives campaign disposal, surfaces scenario proposals, mutates from campaign outcomes, and accumulates knowledge, interpretation, and irreversible loss. The canonical split is already established: Hub is persistent, Campaign World is transient, and accepting a scenario instantiates a disposable campaign state that returns a mutation back into the Hub on win, loss, or abandonment.  

This file locks the Hub as a **knowledge-state machine** rather than a resource economy. The Hub tracks what is known, suspected, lost, and pattern-repeated. Persistent rewards are not raw buffs; they are interpretive leverage that changes what can be understood, surfaced, or chosen later. 

This file is the **system authority** for Hub structure and behavior. For fiction semantics, tone, faction lore, Great Severance framing, and player-facing interpretive language, defer to `design/03_content/GAME_PROTOCOLS_AND_WORLD_LORE.md`.

---

## 1A. Canon Alignment

The Hub implementation must remain aligned with the following content-facing rules:

- The Hub is a surviving adjudication layer, not a generic mission board.
- Contracts are bounded historical interventions, not ordinary quests.
- Campaigns are transient operational worlds whose outcomes mutate the historical record.
- Hub outputs should present confidence-bearing interpretation rather than omniscient fact when surfaced to the player.
- Archive loss is existential because loss of context can permanently narrow what reality can still be responsibly claimed.

---

## 2. Why This System Exists

The active runtime already contains a playable Godot combat slice with procgen contract world loading, a local command terminal, wave combat, turrets, sprint, melee, repair, and contract/map previews. What it does **not** yet have is campaign persistence, mission offer semantics, outcome-to-meta mutation, or a persistent archive layer that turns repeated runs into a coherent larger game. Project status explicitly calls out save/snapshot persistence and campaign progression as not yet implemented or medium-priority gaps. 

The Hub exists to solve that gap without breaking the current architecture. The earlier design guidance is explicit that this is a layering change, not a rewrite: current world simulation becomes `CampaignState`, a distinct `HubState` persists outside it, a `CampaignOutcome` is produced on resolution, applied to `HubState`, and the campaign state is discarded. Deterministic ticks, assault logic, expedition logic, and transient sector/base logic remain intact. 

---

## 3. Canonical Ontology

The Hub doc must start by locking terminology, because the entire campaign layer gets fuzzy if the nouns drift.

### 3.1 Required Terms

* **Contract**: the interface object formalizing the Custodian’s operational commitment
* **Scenario**: a generated configuration bundle surfaced by the Hub
* **Campaign**: a transient world instantiated from a selected scenario
* **Reward**: a Hub mutation justified by accumulated context, such as unlocks, capability changes, archive entries, or hypothesis changes 

When shown in player-facing UI or supporting docs, a Contract should be framed as a **bounded historical intervention**.

### 3.2 Two Worlds, Two Timescales

The Hub is the only persistent world. Campaign worlds are transient, created on acceptance, destroyed on resolution, and not revisitable. There is no free travel, no shared map continuity, and no rollback to preserve failed worlds. That distinction is not flavor text; it is the core architectural rule. 

### 3.3 Canonical State Transition

The authoritative flow is:

```plaintext
HUB
 ├─ generate campaign scenario proposals
 ├─ player selects scenario
 └─ ACCEPT → instantiate CampaignWorld

CAMPAIGN WORLD
 ├─ run expeditions
 ├─ collect loot / progress victory condition
 ├─ WIN | LOSE | ABANDON
 └─ RETURN → apply rewards → destroy campaign state

HUB (mutated)
```

This exact persistent/transient split must remain invariant across all later docs. 

---

## 4. Design Intent

The Hub is not there to make the player stronger. It is there to make the player more informed, more selective, and more capable of interpreting future scenarios. Existing design guidance already locks that CUSTODIAN’s persistent progression is based on discovered truths, doctrines, biomes, and enemy archetypes, not character-stat inflation. You do not get stronger; you get more informed. 

The system should therefore produce:

* long-term meaning without power creep
* finite, winnable arcs instead of endless scaling
* partial failure that still matters historically
* procedural replayability anchored by persistent interpretation
* a natural closure state, where Hub saturation or archive resolution feels like an endgame rather than endless treadmill accumulation 

---

## 5. Non-Goals

This file does **not** define:

* region geometry generation
* compound tile construction rules
* combat balance
* world streaming
* detailed transition scene loading
* camera handoff
* low-level save-file serialization format for all systems

It does define the Hub-side data model those systems must respect.

---

## 6. Core Principle: The Hub Is a Knowledge State Machine

This is the single most important conceptual lock.

The Hub tracks:

* what is known
* what is suspected
* what is irretrievably lost
* what patterns appear to repeat

It does not primarily track money, gear tier, or XP. Persistent bonuses are not conventional stat buffs; they are interpretive leverage that alters capability and choice. 

This immediately implies four things:

1. The Hub must preserve ambiguity, not eliminate it completely.
2. Recon should refine interpretation, not guarantee safety.
3. Failure must still mutate the Hub.
4. Archive loss must be mechanically meaningful and existential.

Even a failed campaign can invalidate a hypothesis or mark some truth as no longer recoverable. That is one of the best parts of the design and should be kept intact. 

---

## 7. Hub Responsibilities

The Hub system owns the following responsibilities and nothing outside this list should be silently folded into it.

### 7.1 Persistent Historical State

Store all information that survives campaign disposal.

### 7.2 Scenario Proposal Surfacing

Generate or refine mission offers from current Hub knowledge and capability state.

These offers should read as proposals to resolve uncertainty, preserve or quarantine knowledge, or intervene in contested interpretation — not as flavorless mission tickets.

### 7.3 Recon Refinement

Reveal more about a proposal before acceptance based on recon-related capabilities.

### 7.4 Campaign Acceptance

Convert a scenario proposal into an instantiated transient campaign contract.

### 7.5 Outcome Mutation

Apply campaign outcomes back into the Hub.

### 7.6 Archive / Knowledge Graph Management

Record recoveries, revelations, contradictions, partial truths, and irretrievable loss.

This layer should preserve the distinction between:

- observed facts
- interpreted models
- correlated truths
- canonical doctrine
- sealed conclusions

### 7.7 Campaign History

Maintain a record of what was attempted, what succeeded, how it succeeded, and what was lost.

### 7.8 Progression Without Power Creep

Unlock new scenario archetypes, doctrine possibilities, information fidelity, and route selection without flattening challenge. 

---

## 8. What the Hub Must Not Become

To protect the tone and architecture, the Hub must not drift into any of the following:

### 8.1 Generic Mission Board

Campaigns are not “quests from NPCs.” Existing design guidance is clear that scenarios should be surfaced as structured proposals to resolve gaps in understanding, not social-fiction tasks from intact institutions. 

### 8.2 Traditional RPG Meta Currency Store

No soft currency loop that buys flat buffs.

### 8.3 Global Gear Locker

Campaign loot is not the same thing as Hub persistence; keep expedition-only tools distinct from persistent Hub mutations. 

### 8.4 Lore Dump Browser

Archive entries must do mechanical work, not merely accumulate prose.

---

## 9. Structural Model

The strongest earlier design note should be preserved here: Hub and Campaign are two different states with two different lifetimes.

### 9.1 Structural Split

* `HubState`: long-lived persistent meta layer
* `CampaignState`: run-local simulation and progression layer
* `CampaignOutcome`: distilled result contract produced on campaign resolution
* `CampaignScenario`: proposal contract surfaced by the Hub and accepted into a campaign instance 

### 9.2 Required Lifecycle

1. Hub boot or load
2. Generate/refine scenario offers
3. Accept scenario
4. Instantiate campaign from accepted scenario and current hub conditions
5. Run campaign
6. Resolve campaign into outcome
7. Apply outcome to hub
8. Destroy campaign state
9. Return to mutated hub

This must be one-way and explicit. No hidden sharing of campaign-local mutable data after destruction.

---

## 10. Data Model Overview

The previous roadmap already introduced the right high-level objects: `HubState`, `CampaignScenario`, `KnowledgeSystem`, and scenario generation. This file expands them into an authoritative spec.  

---

## 11. `HubState` Specification

`HubState` is the root persistent resource for the Hub.

### 11.1 Required Semantics

`HubState` must be serializable, deterministic under seeded offer generation, and free of scene-node references.

### 11.2 Required Fields

```gdscript
class_name HubState
extends Resource

var hub_seed: int
var cycle_index: int = 0
var archive_loss_count: int = 0
var archive_loss_tolerance: int = 3

var capability_flags: Dictionary = {}
var unlocked_scenario_archetypes: Array[String] = []
var unlocked_victory_modifiers: Array[String] = []
var unlocked_biomes: Array[String] = []
var unlocked_enemy_archetypes: Array[String] = []
var unlocked_doctrines: Array[String] = []

var active_offer_bundle: Array[CampaignScenario] = []
var active_offer_seed: int = 0
var active_offer_generation_index: int = 0

var knowledge_nodes: Array[KnowledgeNode] = []
var knowledge_archive: Array[ArchiveEntry] = []
var invalidated_hypotheses: Array[HypothesisRecord] = []
var irretrievable_losses: Array[LossRecord] = []

var campaign_history: Array[CampaignRecord] = []
var campaign_slots: int = 3
var recon_depth: int = 0
var subvictory_detection: int = 0
var abandonment_penalty_modifier: float = 1.0
```

### 11.3 Notes

* `hub_seed` is persistent and should anchor deterministic offer generation.
* `cycle_index` increments whenever new offers are generated or accepted/resolved, depending on final policy.
* `archive_loss_count` and `archive_loss_tolerance` track existential failure pressure. Existing plan text already uses `archive_loss_tolerance` as a capability flag, and earlier design notes emphasize archive loss as existential.  
* `active_offer_bundle` is persistent so reloads do not silently reroll mission choices.
* `knowledge_nodes` are the real currency and should be the richest persistent payload in the system. Existing design notes define them in terms of category, origin, confidence, and implications. 

---

## 12. `KnowledgeNode` Specification

This is the actual intellectual currency of the Hub.

```gdscript
class_name KnowledgeNode
extends Resource

var id: String
var category: String            # biotech, propulsion, governance, cognition, warfare, etc.
var origin: String              # civilization / era / unknown
var confidence: String          # inferred / partial / confirmed
var concrete_recovery: String   # device/process/material fact, if any
var contextual_revelation: String
var implications: Array[String] = []
var discovered_in_campaign_id: String = ""
var related_region_ids: Array[String] = []
var tags: Array[String] = []
var is_irretrievable: bool = false
```

The important point is not the exact field names. The important point is that each node contains both a concrete recovery axis and a contextual revelation axis, because prior guidance explicitly states that successful campaigns return one or both of those surface forms, and together they form the real persistent Hub knowledge. 

---

## 13. `CampaignScenario` Specification

This object is the Hub’s scenario contract. It is not merely a mission ID.

The prior design already identified the right direction: scenario contains seed, region, difficulty, setting, threat profile, victory conditions, uncertainty, optional subvictories, and reward profile. 

### 13.1 Required Fields

```gdscript
class_name CampaignScenario
extends Resource

var id: String
var scenario_seed: int
var proposal_index: int
var source_hub_cycle: int

var region_id: String
var region_similarity_hint: String
var biome: String
var environmental_tags: Array[String] = []

var difficulty_score: float
var difficulty_descriptor: String

var core_threat_type: String
var secondary_threat_types: Array[String] = []
var signal_confidence: float = 0.0

var archetype: String                 # recovery / excavation / containment / observation / interdiction
var victory_type: String              # recovery / stabilize / contain / neutralize
var primary_victory_target: String
var primary_completion_threshold: float

var optional_subvictories: Array[SubvictorySpec] = []
var constraints: Array[ConstraintSpec] = []
var uncertainty_band: Dictionary = {} # field_name -> uncertainty metadata
var reward_profile: RewardProfile
var recon_revealed_fields: Array[String] = []
var acceptance_locked: bool = false
```

### 13.2 Archetype vs Victory Type

Keep both.

* **Archetype** is the investigative shape of the campaign. Existing design notes propose recovery, excavation, containment, observation, and interdiction as the safe procedural layer that shapes layout tendencies, threat behavior, failure consequences, and reward types. 
* **Victory Type** is the explicit operational template such as recovery, stabilization, containment, or neutralization. The existing roadmap uses those four mission goals and they should remain typed, not bespoke.  

That distinction prevents the system from collapsing “what kind of investigation is this?” into “what exact win trigger fires?”

---

## 14. Difficulty Model

Difficulty must remain **selectable and descriptive**, not just punitive scaling. Existing design notes are explicit that difficulty should influence density, aggression, scarcity, and objective complexity, but must preserve agency and should not flatten all reward choice into strictly-better outcomes. 

### 14.1 Difficulty Fields

* `difficulty_score`: normalized float, usually 0.0 to 1.0
* `difficulty_descriptor`: player-facing descriptor
* `difficulty_tier`: optional coarse band for gating content

### 14.2 Recommended Descriptor Table

Use the proposed mapping as your first locked table:

* 0.0–0.2: LOW CONFIDENCE OPERATION
* 0.2–0.4: UNSTABLE CONDITIONS
* 0.4–0.6: HIGH RISK ENGAGEMENT
* 0.6–0.8: SEVERE OPERATIONAL COMPLEXITY
* 0.8+: EXTINCTION-LEVEL UNKNOWN 

### 14.3 Difficulty Inputs

Difficulty should be a composed value, not a single roll. Recommended weighted factors:

* biome baseline
* threat profile volatility
* victory complexity
* constraint load
* uncertainty severity
* current hub capability mismatch
* unlocked threat tiers
* archive pressure state

### 14.4 Important Rule

Difficulty is not linear punishment. The system should sometimes offer:

* medium-difficulty missions with unusually strong archive rewards
* high-difficulty missions with uncertain but not strictly better returns
* lower-difficulty missions useful for hypothesis refinement rather than escalation

This preserves choice instead of obvious optimal play. 

---

## 15. Scenario Fields and Player-Facing Information Bands

Scenario offers are not fully known objects by default. Recon exists to refine proposals before acceptance by narrowing uncertainty and revealing one or more categorical truths. Existing design notes explicitly define recon as Hub-side refinement, not campaign-side scouting. It reduces surprise, not danger. 

### 15.1 Information Bands

Each player-facing field should have one of four reveal states:

* `HIDDEN`
* `APPROXIMATE`
* `REVEALED`
* `CONFIRMED`

### 15.2 Candidate Fields to Gate

* exact threat composition
* environmental tag count
* optional subvictories
* reward archetype details
* archive risk
* abandonment penalty class
* mission modifiers
* region similarity hint
* signal confidence

### 15.3 Recon Output Rules

Recon should:

* reveal one categorical truth
* narrow one or more uncertainty ranges
* never guarantee safety
* never fully reveal all future events or encounter placement

This aligns directly with the earlier “reduces misinterpretation, not danger” rule. 

---

## 16. Reward Model

One of the strongest prior design locks is the reward split between **hub-persistent campaign rewards** and **campaign-scoped expedition loot**. Keep that split explicit. 

### 16.1 Campaign Rewards (Persistent)

These are applied only on campaign resolution and mutate the Hub.

Examples:

* unlock new scenario archetypes
* unlock new difficulty tiers
* unlock new victory templates
* improve intel before acceptance
* reduce abandonment penalties
* add archive entries
* add contextual revelations
* alter long-term doctrinal capabilities 

### 16.2 Expedition Loot (Transient)

These exist only in the campaign and are discarded at campaign end.

Examples:

* local upgrades
* consumables
* emergency reroutes
* partial objective items
* temporary defense improvements 

### 16.3 Why This Split Matters

Without it, the campaign layer turns into generic extraction-to-power treadmill. With it, Hub persistence remains about context and interpreted consequence, which fits the tone and prevents early-run obsolescence. 

---

## 17. `RewardProfile` Specification

```gdscript
class_name RewardProfile
extends Resource

var archetype: String                  # archival_knowledge / schematics / lost_technology / biological_data / cultural_records
var hub_unlocks: Array[String] = []
var capability_mutations: Dictionary = {}
var knowledge_node_templates: Array[String] = []
var archive_entry_templates: Array[String] = []
var loss_risk: float = 0.0
var partial_reward_policy: String = "scaled"
```

The existing roadmap already uses reward archetypes like `ARCHIVAL KNOWLEDGE`, `SCHEMATICS`, `LOST TECHNOLOGY`, `BIOLOGICAL DATA`, and `CULTURAL RECORDS`, mapping them to capability effects such as recon depth, archive loss tolerance, and secondary objective detection. Preserve that idea, but keep the actual mutation application centralized in one knowledge/outcome system rather than scattered throughout UI or scenario code. 

---

## 18. Capability Flags

These are persistent interpretive and doctrinal levers, not character-level stat upgrades.

The current roadmap identifies at least:

* `recon_depth`
* `archive_loss_tolerance`
* `subvictory_detection` 

Expand the structure while keeping the philosophy intact:

```gdscript
capability_flags = {
    "recon_depth": 0,
    "archive_loss_tolerance": 3,
    "subvictory_detection": 0,
    "offer_slot_count": 3,
    "abandonment_penalty_reduction": 0,
    "difficulty_band_access": 1,
    "signal_filtering": 0,
    "reward_confidence_refinement": 0
}
```

### Important Rule

Capability flags should do one or more of the following:

* reveal better information
* widen choice sets
* reduce ambiguity
* mitigate strategic penalties
* unlock new scenario shapes

They should not simply raise damage, HP, or generic combat throughput.

---

## 19. Partial Success, Failure, and Abandonment

Prior design work already identifies this as a key feature rather than an edge case. Campaigns should not be binary. Partial success must be a first-class resolution state, and abandonment should be costly but sometimes strategically correct. 

### 19.1 Required Resolution States

* `COMPLETE_VICTORY`
* `PARTIAL_VICTORY`
* `FAILURE`
* `ABANDONMENT`

### 19.2 Why This Is Essential

It creates:

* cutting-loss decision making
* strategic withdrawal
* degraded but meaningful returns
* loss records that matter historically

### 19.3 Example Policy

Victory condition: recover 3 archive fragments

* recover 3 → full reward
* recover 2 → partial reward + incomplete knowledge node
* recover 1 → minor archive mutation + unresolved hypothesis
* recover 0 → failure + possible irretrievable loss marker 

### 19.4 Abandonment Rules

Abandonment should:

* preserve campaign history
* mutate the hub negatively or ambiguously
* possibly retain some partial information
* never pretend nothing happened

---

## 20. `CampaignOutcome` Specification

```gdscript
class_name CampaignOutcome
extends Resource

var scenario_id: String
var campaign_id: String
var resolution_state: String           # complete_victory / partial_victory / failure / abandonment
var completion_ratio: float = 0.0
var recovered_items: Array[String] = []
var recovered_knowledge_nodes: Array[KnowledgeNode] = []
var contextual_revelations: Array[String] = []
var invalidated_hypotheses: Array[String] = []
var irretrievable_losses: Array[String] = []
var capability_mutations: Dictionary = {}
var archive_loss_delta: int = 0
var reward_grade: String = "none"
var history_tags: Array[String] = []
```

This is the single object the Hub should consume after campaign disposal.

---

## 21. Scenario Generation System

The existing roadmap already sketches `ScenarioGenerator.generate_scenario(hub, seed)` and `generate_offers(hub, count=3)`. That is the correct entry point. 

### 21.1 Inputs

* `HubState`
* deterministic offer seed
* optional forced tutorial tags
* optional explicit campaign slot or arc constraints

### 21.2 Outputs

A stable offer bundle, not a single one-off scenario.

### 21.3 Generator Phases

1. Determine valid archetype pool from hub unlocks
2. Determine biome pool from hub progression
3. Determine threat pool from known/unlocked factions and historical pattern weights
4. Generate candidate scenarios
5. Score for diversity, not just raw difficulty spread
6. Apply recon visibility rules
7. Persist active offer bundle in `HubState`

### 21.4 Diversity Constraints

Offer bundles should not:

* surface three near-identical biomes
* surface three same-threat proposals unless a deliberate arc demands it
* collapse into one obviously optimal pick

Recommended bundle diversity axes:

* biome
* threat family
* victory type
* reward archetype
* uncertainty character
* archive risk class

### 21.5 Historical Feedback

Campaign history should feed future offer weighting:

* overrepresented factions create pattern memory
* repeated use of specific doctrinal play may bias counterfactions
* unresolved hypotheses can resurface as improved offers
* irretrievable losses can close some branches and open compensatory ones

This harmonizes well with the earlier “patterns repeat” language for the Hub. 

---

## 22. Hypothesis Model

One of the strongest creative ideas in the earlier design notes is that offers should arise from gaps in understanding, not just random mission rolls. Preserve that.

### 22.1 `HypothesisRecord`

```gdscript
class_name HypothesisRecord
extends Resource

var id: String
var subject: String
var confidence: float = 0.0
var status: String = "open"      # open / refined / confirmed / invalidated / lost
var related_knowledge_node_ids: Array[String] = []
var spawned_archetypes: Array[String] = []
var notes: Array[String] = []
```

### 22.2 Hub Offer Logic

A new scenario should often answer one of:

* a known gap
* a contradictory knowledge node
* a recurring cross-campaign pattern
* an unresolved archive threat
* a progression gate requiring a missing category

That gives procedural generation thematic spine rather than feeling arbitrary.

---

## 23. Knowledge and Archive System

The roadmap already identifies a `KnowledgeSystem` responsible for applying outcome and producing recon bonuses. Expand that into the actual authoritative mutation layer. 

### 23.1 Responsibilities

* apply `CampaignOutcome` to `HubState`
* add or merge `KnowledgeNode`s
* add archive entries
* mark hypothesis invalidation
* mark irretrievable loss
* mutate capability flags
* record campaign history
* trigger unlocks
* determine if archive-loss fail state has been exceeded

### 23.2 Merge Rules

When a recovered node matches an existing category/origin cluster:

* increase confidence
* append implications
* enrich archive entry
* possibly unlock new scenario archetypes

When a new node contradicts an existing assumption:

* create or update invalidation record
* possibly unlock contradiction-driven campaigns

When something is lost:

* mark category/subject as partially or fully irretrievable
* update archive-loss counters if appropriate

### 23.3 Persistence Principle

The Hub should remember:

* what it learned
* what it disproved
* what it can no longer learn

That triad is more interesting than plain unlock count.

---

## 24. Archive Loss

Archive loss is not just a UI stat. Earlier design notes explicitly frame archive loss as existential because even failure tells you what can no longer be known. 

### 24.1 What Archive Loss Represents

* destroyed evidence
* corrupted context
* permanently inaccessible historical reconstruction
* failed preservation of critical interpretive chain

### 24.2 What It Should Do

* pressure campaign selection
* limit tolerated repeated catastrophic failure
* gate some endings
* shape the Hub’s historical tone
* possibly increase desperation in future offers

### 24.3 What It Should Not Be

* instant permadeath after one mistake
* generic HP bar for the metagame

---

## 25. Campaign History

Campaign history is not just for a statistics page. It is the record by which the Hub knows how the player won, failed, abandoned, or revealed something.

### 25.1 `CampaignRecord`

```gdscript
class_name CampaignRecord
extends Resource

var campaign_id: String
var scenario_id: String
var started_at_cycle: int
var resolved_at_cycle: int
var biome: String
var threat_profile: Array[String] = []
var victory_type: String
var resolution_state: String
var completion_ratio: float
var reward_archetype: String
var archive_loss_delta: int
var key_revelations: Array[String] = []
var key_losses: Array[String] = []
var doctrine_tags: Array[String] = []
```

### 25.2 Why It Matters

History can feed:

* future offer weighting
* endgame evaluation
* archive UI
* faction memory systems later
* narrative recap without authored scripting

---

## 26. Hub UI Contract

The prior roadmap already sketches the correct terminal-style Hub interface showing archive losses, campaign streak, and three offers with region ID, difficulty, threat, objective, and reward. 

Player-facing Hub language should follow the confidence protocol defined in `design/03_content/GAME_PROTOCOLS_AND_WORLD_LORE.md`. Favor terms such as `Approximate`, `High Confidence`, `Contested`, `Corrupted`, and `Sealed` over flat omniscient statements.

### 26.1 Required UI Responsibilities

The Hub UI must:

* show persistent Hub status
* show offer bundle
* reflect uncertainty cleanly
* support recon refinement if available
* accept mission selection
* show campaign history summary
* show archive/knowledge progression without dumping full lore wall by default

### 26.2 Information Priority Order

Top priority:

1. archive pressure
2. active offers
3. reward archetype
4. risk and uncertainty
5. campaign history summary
6. archive details / node browser

### 26.3 Interface Style Rule

Because the terminal is already an in-world command surface in the Godot runtime, the Hub should first ship through that same command/terminal paradigm rather than a separate meta-menu aesthetic. The active runtime already has a local in-game terminal and contract/world snapshot previews. 

---

## 27. File/Module Targets

The prior roadmap already proposes the right folder direction:

```plaintext
custodian/core/systems/hub/
    hub_manager.gd
    hub_data.gd
    scenario_generator.gd
    knowledge_system.gd
    hub_ui.gd
```

Keep `region_generator.gd` out of this file’s implementation scope except where interface contracts must be named. 

### 27.1 Recommended Module Responsibilities

#### `hub_manager.gd`

* owns active `HubState`
* manages offer generation lifecycle
* accepts campaign selection
* consumes outcomes

#### `hub_data.gd`

* defines `HubState`, `CampaignScenario`, `RewardProfile`, `CampaignOutcome`, `KnowledgeNode`, etc.

#### `scenario_generator.gd`

* deterministic offer bundle generation
* diversity balancing
* recon refinement pass

#### `knowledge_system.gd`

* apply outcome to hub
* archive merge/invalidation/loss handling
* unlock and capability mutation logic

#### `hub_ui.gd`

* terminal-oriented presentation and selection flow

---

## 28. Determinism Requirements

The repository-level guidance emphasizes fixed-step determinism and separation of simulation logic from rendering/UI. This file must honor that. 

### 28.1 Deterministic Requirements

* scenario generation from the same `HubState` + offer seed must reproduce the same offer bundle
* recon actions must produce deterministic reveal changes
* applying the same `CampaignOutcome` to the same `HubState` must produce the same result
* UI ordering must never affect generated content

### 28.2 Anti-Patterns to Avoid

* using `Time.get_ticks_msec()` for offer generation
* rerolling offers on UI open
* mutating hub state during read-only preview
* tying unlock logic to scene timing or animation events

---

## 29. Save / Load Requirements

The project status explicitly notes that campaign persistence is not yet implemented, so this doc needs a clear save contract from the start. 

### 29.1 Minimum Save Surface

Hub persistence must include:

* `HubState`
* active offer bundle
* offer seed and generation index
* knowledge graph
* archive history
* invalidated hypotheses
* irretrievable losses
* campaign history
* capability flags

### 29.2 Important Rule

An active offer bundle should survive save/load exactly. Reloading the game should not silently refresh the proposal set unless the player explicitly refreshes and that refresh is itself stateful and deterministic.

---

## 30. Recommended Build Order

Earlier guidance already provides a strong ordered roadmap:

1. structural split
2. scenario generator
3. campaign rewards
4. partial victory
5. thematic procedural rewards 

Adapted to Godot runtime, the build order should be:

### Phase 1 — Structural Split

* define `HubState`
* define `CampaignScenario`
* define `CampaignOutcome`
* separate hub from campaign lifecycle

### Phase 2 — Deterministic Offer Bundle

* implement stable scenario generation
* persist active offers in `HubState`
* surface basic terminal UI

### Phase 3 — Outcome Mutation

* implement `KnowledgeSystem.apply_outcome`
* add capability flags
* add archive loss
* add campaign history

### Phase 4 — Recon and Uncertainty

* implement reveal bands
* implement recon refinement
* connect recon depth capability

### Phase 5 — Advanced Knowledge Graph

* add hypothesis records
* add contradiction handling
* add irretrievable loss semantics
* add endgame saturation conditions

---

## 31. Failure Cases to Explicitly Guard Against

### 31.1 Hub Drifts into Power Store

Bad outcome: the player buys flat buffs and the tone collapses.

### 31.2 Scenario Offers Feel Random

Bad outcome: procedural generator produces flavorless mission board behavior.

### 31.3 Recon Becomes Safety Guarantee

Bad outcome: player perfectly predicts all campaign risk.

### 31.4 Failure Feels Disposable

Bad outcome: losing a campaign changes nothing in hub history.

### 31.5 Persistence Becomes Lore Graveyard

Bad outcome: archive accumulates text with no mechanical consequence.

### 31.6 Offer Bundle Is Not Stable

Bad outcome: save/load rerolls or UI rerenders mutate offers.

### 31.7 Outcome Logic Leaks into UI

Bad outcome: preview screens accidentally mutate `HubState`.

---

## 32. Acceptance Criteria

This file is complete when all of the following are true:

### Structural

* [ ] `HubState`, `CampaignScenario`, and `CampaignOutcome` are formal runtime data types
* [ ] Hub and Campaign lifetimes are clearly separated

### Offer Generation

* [ ] Hub generates deterministic offer bundles
* [ ] Offer bundles are stable across save/load
* [ ] Offer bundles show meaningful diversity

### Progression

* [ ] Persistent rewards mutate the Hub, not player stats directly
* [ ] Campaign-scoped loot remains separate from persistent rewards
* [ ] Partial victory, failure, and abandonment all produce different hub mutations

### Knowledge

* [ ] Hub tracks knowledge, hypotheses, and irretrievable loss
* [ ] At least one campaign outcome can invalidate a prior assumption
* [ ] Archive loss is tracked and mechanically meaningful

### UI

* [ ] Terminal Hub interface can show persistent status and available offers
* [ ] Uncertainty/recon reveal bands are supported

### Philosophy

* [ ] The player accumulates context, not just power
* [ ] The Hub feels like the historical layer of the game, not a mission board menu

---

## 33. Exit Condition

This file is done when you can:

1. boot into the compound,
2. open the Hub,
3. see a deterministic offer bundle,
4. accept one proposal into a transient campaign,
5. resolve it into a `CampaignOutcome`,
6. return to the Hub,
7. observe persistent mutation in knowledge, capability, or history,
8. and destroy the campaign state without losing the larger historical record.

That is the minimum viable Hub.

---

# Progress Tracking

## Completed Files

* [1] Runtime World & Camera Stabilization
* [2] Hub System (Meta Progression)

## Still To Go

* [3] World Transition System
* [4] Region Generation System
* [5] Compound Tile System
* [6] Campaign Flow & Game Loop
* [7] Integration Contract (Glue Layer)
