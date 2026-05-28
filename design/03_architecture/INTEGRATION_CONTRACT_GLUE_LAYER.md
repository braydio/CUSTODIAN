# `design/03_architecture/INTEGRATION_CONTRACT_GLUE_LAYER.md`

# Integration Contract (Glue Layer)

**Project:** CUSTODIAN
**Status:** Final Core Architecture Spec for the 7-file campaign/runtime expansion set
**Priority:** Critical
**Depends On:** Runtime World & Camera Stabilization, Hub System (Meta Progression), World Transition System, Region Generation System, Compound Tile System, Campaign Flow & Game Loop
**Blocks:** Reliable end-to-end implementation, refactor-safe growth, save/load confidence, system ownership clarity
**Runtime Target:** Godot 4.x (`custodian/`)
**Last Updated:** 2026-03-27

---

## 1. Purpose

Define the integration contract that binds all major runtime and meta systems into one coherent architecture without allowing ownership drift, hidden coupling, duplicate authority, or state mutation ambiguity.

This file exists because the other six design docs intentionally separate concerns:

* world/camera stabilization
* Hub system
* world transition
* region generation
* compound tile system
* campaign flow and game loop

That separation is correct. However, separation alone is not enough. Once implementation begins, those systems will start talking to each other constantly. Without an explicit glue-layer contract, the project will very quickly develop all the classic integration failures:

* multiple systems believing they own the same state
* UI mutating simulation directly
* world generation happening inside transition code
* campaign outcomes being applied twice
* save/load reconstructing contexts differently than live transitions
* procgen worlds becoming implicitly authoritative without formal registration
* compound, Hub, and campaign state leaking into each other

The purpose of this document is to make those failures structurally impossible or at least trivially detectable.

This file is the final authority on:

* who owns what
* who may call what
* in what order systems are allowed to communicate
* what payloads cross boundaries
* what never crosses boundaries
* which state is persistent vs transient
* how deterministic reconstruction happens
* how one runtime slice hands off to another without ambiguity

This is the “do not let the architecture rot” document.

---

## 2. Why This File Must Exist

The project already has strong signs of real architectural maturity:

* the Godot pivot is complete and active runtime authority is in `custodian/`, not the legacy Python runtime 
* the runtime already includes wave spawning, operator movement, turret slices, contract/procgen promotion, terminal integration, and a fixed-step model  
* the repository guidance explicitly requires deterministic simulation, separation of simulation from rendering/UI, and active-vs-legacy doc authority clarity 
* multiple systems are already partially integrated, and at least one known issue exists specifically because runtime ownership and rebinding were not fully formalized during procgen handoff, particularly camera/world authority drift 

That last point is the warning shot.

The project is no longer small enough to “just know where things go.”

You are now building a game with:

* persistent strategic state
* transient campaign worlds
* home-world runtime
* procgen generation
* structural tile systems
* mission outcome distillation
* terminal-driven interfaces
* deterministic save/load expectations

At this level, the system boundaries must be authored just as deliberately as the feature docs.

That is what this file does.

---

## 3. Scope

This document governs the integration contract across the following systems:

1. Runtime World & Camera Stabilization
2. Hub System (Meta Progression)
3. World Transition System
4. Region Generation System
5. Compound Tile System
6. Campaign Flow & Game Loop

It also governs cross-cutting concerns:

* save/load
* deterministic reconstruction
* event signaling
* runtime registration
* service discovery
* active-world authority
* campaign lifetime
* outcome application
* UI access boundaries
* debug and failure semantics

---

## 4. Non-Goals

This file does **not** re-specify the internals of the six core systems. It does not replace their feature docs.

It does **not** define:

* exact biome template content
* exact compound wall HP values
* exact UI layout
* exact objective logic
* exact animation assets
* exact combat tuning

It defines the contracts between systems, not the internals of each system.

---

## 5. Core Architectural Principle

This is the foundational rule of the entire integration layer:

> Every important game fact must have exactly one authoritative owner.

If more than one system can authoritatively mutate the same fact, the architecture is already degrading.

Examples:

* The Hub owns persistent historical state.
* The campaign runtime owns transient mission state.
* The transition manager owns context switches.
* The region generator owns scenario-to-region construction.
* The compound tile system owns structural tile runtime semantics.
* The campaign flow manager owns phase progression.

Every other system may:

* observe
* query
* request
* subscribe
* consume structured outputs

But it may not silently assume ownership.

---

## 6. Canonical Architecture Layers

The full architecture should be understood in layers.

### 6.1 Layer A — Persistent Meta Layer

Owns long-lived campaign history and strategic state.

Primary authority:

* Hub System

### 6.2 Layer B — World Lifecycle Layer

Owns world instantiation, shutdown, rebinding, and context authority.

Primary authority:

* World Transition System

### 6.3 Layer C — Runtime World Construction Layer

Owns creation of playable spatial worlds from accepted inputs.

Primary authorities:

* Region Generation System
* Compound Tile System
* existing procgen contract world builder where applicable

### 6.4 Layer D — Campaign Runtime Layer

Owns active mission flow, objective progression, resolution, and return routing.

Primary authority:

* Campaign Flow & Game Loop

### 6.5 Layer E — Embodied Interaction Layer

Owns operator input, combat execution, local interactions, camera behavior, and world-space embodiment.

Primary authorities:

* existing runtime systems under `custodian/`
* Runtime World & Camera Stabilization contract for rebinding correctness

### 6.6 Layer F — Presentation Layer

Owns UI display, terminal surfaces, overlays, debug rendering, and summaries.

Primary rule:

* presentation reflects state; it does not authoritatively invent or mutate core state

This layering is critical. When a bug appears, you should be able to say immediately which layer owns the truth.

---

## 7. The Seven Authoritative Owners

Lock these now.

### 7.1 Runtime World Binding Owner

Owns:

* active world-space binding correctness
* camera bounds rebinding
* player/world/camera/input coherence
* navigation/collision alignment after world activation

### 7.2 Hub Owner

Owns:

* `HubState`
* offer bundle
* capability flags
* knowledge archive
* campaign history
* archive loss pressure
* scenario interpretation layer

### 7.3 World Transition Owner

Owns:

* current world context
* target world context
* context handoff phase
* teardown/build/bind/finalize sequence

### 7.4 Region Generation Owner

Owns:

* accepted scenario to generated region mapping
* region graph
* region layout solve
* objective/extraction anchors at world-construction level
* generated region payload

### 7.5 Compound Tile Owner

Owns:

* structural tile runtime registry
* tile damage/repair semantics
* conduit/mount structural semantics
* sector-level structural aggregation inputs

### 7.6 Campaign Flow Owner

Owns:

* macro phase progression
* mission active state
* objective progression contract at loop level
* outcome production timing
* reintegration and game-over routing

### 7.7 Integration Contract Owner

This document is not a runtime node, but its runtime embodiment should live in a small integration layer or common service registry that enforces the rules below.

---

## 8. System Registry and Service Discovery Contract

The project should use controlled service discovery rather than fragile ad hoc scene-tree digging whenever possible.

### 8.1 Problem This Solves

Without a controlled registry, systems start doing:

* `get_tree().get_first_node_in_group("camera")`
* hardcoded `/root/GameRoot/...` paths
* scene-name assumptions
* hidden sibling lookups

Some of that already exists in the runtime and has already produced failures, such as camera-group assumptions and stale procgen handoff behavior. 

### 8.2 Required Solution

A lightweight service registry should expose authoritative runtime services by role, not by scene guesswork.

Recommended path:

```plaintext id="55iivu"
custodian/core/systems/integration/runtime_services.gd
```

### 8.3 Required Responsibilities

`runtime_services.gd` should provide typed registration and lookup for:

* hub manager
* world transition manager
* campaign flow manager
* active camera controller
* active navigation system
* compound tile system
* contract world loader
* active world root
* active player/operator
* region generator

### 8.4 Important Rule

Service registry is for discovery, not ownership. Registering a service does not move authority.

### 8.5 Example Interface

```gdscript id="dghd2c"
class_name RuntimeServices
extends Node

var _services: Dictionary = {}

func register_service(key: StringName, service: Object) -> void:
    _services[key] = service

func unregister_service(key: StringName) -> void:
    _services.erase(key)

func get_service(key: StringName) -> Object:
    return _services.get(key, null)
```

### 8.6 Why This Matters

It gives you one obvious place to ask:

* who is the active world transition authority?
* which camera is authoritative?
* what is the active compound tile owner?
* who owns current campaign flow state?

This dramatically reduces hidden coupling.

---

## 9. Canonical Data Boundaries

This is one of the most important sections in the document.

Each system must communicate using typed data contracts, not implicit scene state whenever possible.

### 9.1 Persistent Contracts

These survive across world destruction:

* `HubState`
* campaign history records
* capability flags
* archive loss state
* active offer bundle
* knowledge nodes
* invalidated hypotheses
* irretrievable losses

### 9.2 Transient Contracts

These exist only while a campaign is alive:

* `CampaignSessionState`
* mission objective records
* region-local entity state
* extraction status
* local hazard state
* local damage states in campaign world
* temporary loot/resources

### 9.3 Crossing-Boundary Contracts

Only specific, typed objects should cross major boundaries:

* `CampaignScenario` from Hub to transition/deploy path
* `GeneratedRegion` from region generation to world activation
* `CampaignOutcome` from mission runtime to Hub mutation
* `WorldTransitionRequest` and `WorldTransitionResult` across context handoff
* compound structural delta state into save/load or aggregation surfaces

### 9.4 Strong Rule

Never let a transient campaign world directly mutate `HubState` during live mission play.

All mission-to-Hub mutation must happen through a distilled `CampaignOutcome`. This is already a core rule established in prior docs and must remain absolute. 

---

## 10. Canonical Lifetime Classes

Every major object must belong to one lifetime class.

### 10.1 Persistent

Survives multiple missions and compound returns.

Examples:

* `HubState`
* global settings
* long-term archive data

### 10.2 World-Persistent Within Current Context

Lives as long as the current active world context exists.

Examples:

* compound world root
* campaign region world root
* current navigation graph
* active camera bounds
* active structural registries

### 10.3 Mission-Transient

Lives only during an active campaign session.

Examples:

* mission objectives
* extraction availability
* local hazard escalations
* mission-specific caches
* campaign-only state flags

### 10.4 Frame-Transient / Presentation

Safe to destroy and rebuild frequently.

Examples:

* overlays
* summary screens
* selection highlights
* tooltips
* debug visuals

### 10.5 Strong Rule

Persistent systems may observe or consume transient outputs, but transient systems must never own persistent truth.

---

## 11. Canonical World Authority Contract

At any given moment, exactly one world context is authoritative for embodied gameplay.

This is already strongly implied by the World Transition System and the runtime stabilization spec, but the glue layer needs to lock it as a top-level rule.

### 11.1 Valid World Authority States

* no authoritative world during startup or active transition phase
* compound world authoritative
* campaign region authoritative
* transit/interstitial authoritative if later implemented

### 11.2 Invalid State

Two different contexts simultaneously owning:

* player
* camera target logic
* objective systems
* navigation truth
* active interaction routing

### 11.3 Required Registration

When a new world is finalized, the integration layer should update the authoritative pointers:

* active world context type
* active world root
* active floor tilemap(s)
* active structural systems
* active player context
* active camera target/bounds source

This should happen in one place during world finalization, not piecemeal.

---

## 12. Canonical Event Flow Model

The systems should integrate primarily through explicit requests, explicit outputs, and explicit signals.

### 12.1 Preferred Flow Shape

```plaintext id="2q736h"
System A requests action from owner of domain
Owner validates
Owner mutates its own state
Owner emits result / signal / output contract
Observers react
```

Not:

```plaintext id="zvpx1s"
System A reaches into System B internals and changes fields directly
```

### 12.2 Why This Matters

It preserves:

* ownership
* debuggability
* deterministic replay
* save/load correctness
* refactorability

---

## 13. Canonical Request/Result Pattern

Every major cross-system action should follow the same structure:

1. **Request**
2. **Validation**
3. **Mutation by owner**
4. **Structured result**
5. **Optional signal emission**
6. **Observers consume, but do not re-own**

This pattern should govern at least:

* mission acceptance
* world transitions
* campaign resolution
* outcome application
* tile damage/rebuild requests
* region generation requests
* save/load reconstruction

---

## 14. Full End-to-End Flow Contract

This section ties the entire architecture together.

### 14.1 Compound Idle to Hub Review

**Owner chain**

* Campaign Flow owns phase
* Hub owns offer bundle
* Presentation reflects Hub state

**Flow**

1. Player interacts with terminal in compound
2. Campaign Flow enters `HUB_ACCESS` / `HUB_REVIEW`
3. Hub Manager surfaces current stable offer bundle
4. UI displays it read-only

### 14.2 Hub Review to Mission Acceptance

**Owner chain**

* Hub owns offer validity
* Campaign Flow owns macro phase change
* World Transition owns deploy context change

**Flow**

1. Player selects a scenario
2. Campaign Flow enters selection-lock phase
3. Hub validates selected scenario and locks or consumes it as appropriate
4. Campaign Flow creates a deployment intent
5. World Transition receives a `WorldTransitionRequest` targeting campaign region
6. Region Generation is not yet invoked by Hub directly; it is downstream of transition/build authority

### 14.3 Campaign Deployment

**Owner chain**

* World Transition owns context change
* Region Generation owns world construction
* Runtime World Binding owns rebind correctness
* Campaign Flow owns post-entry phase state

**Flow**

1. World Transition validates request
2. Current compound context shuts down cleanly
3. Region Generation receives selected `CampaignScenario`
4. Region Generator returns `GeneratedRegion`
5. World Transition builds/binds campaign world
6. Runtime binding rebinds player/camera/navigation/input against new world
7. On successful bind, Campaign Flow enters `CAMPAIGN_ENTRY`, then `CAMPAIGN_ACTIVE`

### 14.4 Active Campaign Play

**Owner chain**

* Campaign Flow owns macro mission phase
* Mission/objective runtime owns detailed objective progress
* Region world owns transient spatial state
* Compound does not participate directly
* Hub does not mutate directly

**Flow**

1. Player plays the mission
2. Objective signals update mission records
3. Extraction or failure states become available
4. Campaign Flow tracks macro completion state only

### 14.5 Campaign Resolution

**Owner chain**

* Campaign Flow owns the decision that mission is resolving
* Mission systems provide the facts
* Campaign Flow produces `CampaignOutcome`
* Hub owns persistent mutation
* World Transition owns return to compound

**Flow**

1. Campaign Flow detects full success / partial / failure / abandonment
2. Campaign Flow freezes mission progression
3. Campaign Flow builds `CampaignOutcome`
4. Outcome is handed to Hub-side mutation path
5. World Transition receives return request
6. Campaign world is destroyed only after outcome distillation and handoff are safe

### 14.6 Return to Compound

**Owner chain**

* World Transition owns return
* Runtime World Binding owns rebind correctness
* Campaign Flow owns reintegration
* Hub owns post-mutation persistent state

**Flow**

1. Compound world is rebuilt or reactivated
2. Player/camera/navigation/interaction are rebound
3. Campaign Flow enters `RETURN_REINTEGRATION`
4. UI may present archive gains/losses/unlocks
5. Flow returns to `COMPOUND_IDLE`

This is the authoritative full loop. Nothing should bypass it casually.

---

## 15. The “Never Bypass the Owner” Rules

These rules are absolute and should be treated as architectural law.

### 15.1 Hub Rules

* UI must not directly mutate `HubState`
* Campaign runtime must not directly mutate `HubState`
* Region generator must not directly mutate `HubState`
* Only Hub-owner pathways consume `CampaignOutcome`

### 15.2 World Transition Rules

* no UI screen should manually swap worlds
* no Hub code should directly instantiate campaign scene roots
* no campaign runtime code should directly rebuild compound on success
* all world-context changes go through World Transition

### 15.3 Region Generation Rules

* region generator consumes scenario and returns generated output
* it must not decide phase progression
* it must not directly enter gameplay
* it must not apply Hub rewards

### 15.4 Compound Tile Rules

* other systems may query or request tile operations
* other systems do not directly rewrite structural tile registry state
* tilemap semantics remain spatial truth

### 15.5 Campaign Flow Rules

* campaign flow decides when mission is in entry/active/extract/resolve/reintegrate
* it must not directly perform world teardown/build internals
* it consumes mission facts, not internal scene assumptions

---

## 16. The “Allowed to Know” Matrix

A system can know about another system without owning it. This matrix clarifies the intended visibility.

| System         |            May Query Hub |     May Query Transition | May Query Region Gen | May Query Compound Tiles |  May Query Campaign Flow |
| -------------- | -----------------------: | -----------------------: | -------------------: | -----------------------: | -----------------------: |
| Hub            |                     Self |                  Limited |       No direct need |           No direct need |                      Yes |
| Transition     |                      Yes |                     Self |                  Yes |                  Limited |                      Yes |
| Region Gen     |   No direct Hub mutation |                       No |                 Self |                       No |                       No |
| Compound Tiles |                       No |                       No |                   No |                     Self |                  Limited |
| Campaign Flow  |                      Yes |                      Yes |              Limited |                  Limited |                     Self |
| UI             | Read-only through owners | Read-only through owners |                   No | Read-only through owners | Read-only through owners |

### 16.1 Interpretation

“May query” does not mean “may mutate.”
The UI row is especially important: UI should not be reaching around owners into lower layers.

---

## 17. Canonical Save/Load Integration Contract

Save/load is where weak architectures get exposed. This project needs a single save/load integration contract across all systems.

### 17.1 Save Coordinator

Recommended path:

```plaintext id="tr1h5o"
custodian/core/systems/integration/save_integration_manager.gd
```

This does not replace specialized serialization inside owners, but it coordinates the save surface.

### 17.2 Save Ownership Rules

Each authoritative owner serializes only its own truth:

* Hub serializes `HubState`
* World Transition serializes current world context and active `WorldSpec` if needed
* Campaign Flow serializes current macro phase and active `CampaignSessionState`
* Region world serializes campaign-world-specific deltas or enough source data to rebuild
* Compound Tile System serializes structural deltas for compound where appropriate

### 17.3 Strong Rule

No system should serialize another system’s truth “for convenience.”

Example of bad pattern:

* UI serializes campaign phase because it happens to know which screen was open

Example of correct pattern:

* Campaign Flow serializes current phase
* UI derives itself from restored phase later

### 17.4 Save Validity Rules

Preferred early implementation:

* allow saves only in stable phases/states
* disallow save during active world transition
* disallow save during unresolved mission outcome application
* disallow save during partial world bind

This matches the conservative approach already recommended in earlier docs.

### 17.5 Resume Contract

Load should reconstruct through the same authoritative pathways as live play:

* load `HubState`
* reconstruct current flow/context
* reconstruct current `WorldSpec`
* request authoritative world activation through transition system
* bind runtime correctly
* restore campaign flow phase

Do not use a completely different resume path that bypasses live transition/build contracts.

---

## 18. Determinism Contract Across Systems

The repository guidance explicitly requires determinism and separation of simulation logic from rendering.  This integration layer must enforce how that works across system boundaries.

### 18.1 Deterministic Inputs

The following must be treated as deterministic inputs:

* hub seed
* scenario seed
* region seed
* current campaign session state
* structural tile deltas
* current offer generation index

### 18.2 Deterministic Outputs

The following should be reproducible from the same deterministic inputs:

* scenario offer bundle
* generated region layout
* campaign resolution summary from equivalent mission facts
* compound structural state after equivalent damage/rebuild sequence

### 18.3 Strong Rule

No cross-system action should use:

* wall-clock time
* UI frame order
* presentation animation timing
* nondeterministic scene child order
  as a source of truth for game-state mutation.

### 18.4 Integration Implication

Every system-to-system request should include enough stable data that the receiving owner does not need to “guess” hidden inputs.

---

## 19. Runtime Registration Lifecycle

The integration contract must define when systems become discoverable and when they stop being valid.

### 19.1 Registration Stages

#### Stage A — Boot Registration

Long-lived managers register themselves:

* Hub Manager
* World Transition Manager
* Campaign Flow Manager
* save integration manager
* runtime service registry

#### Stage B — World Activation Registration

Current active world-specific services register:

* active world root
* active camera controller
* active navigation system
* active compound tile system or active region-world service bundle

#### Stage C — World Deactivation Unregistration

When a world context shuts down, world-specific services unregister before new ones bind.

### 19.2 Strong Rule

Never leave dead services registered after context teardown. That is how stale references cause cross-context bugs.

---

## 20. UI Boundary Contract

UI deserves its own section because it is one of the easiest places to break good architecture.

### 20.1 UI Is a Consumer, Not an Owner

UI may:

* request actions from owners
* display structured owner outputs
* react to signals
* present summaries
* show error/failure states

UI must not:

* directly change campaign flow phase
* directly mark objectives complete
* directly mutate `HubState`
* directly instantiate worlds
* directly destroy worlds
* directly rebuild structural tile state

### 20.2 Required UI Inputs

UI should obtain state from:

* Hub Manager
* Campaign Flow Manager
* World Transition Manager
* current objective service
* post-resolution summary objects

### 20.3 Important Rule

The terminal interface is still just UI over authoritative systems. Even if thematically it “is the command layer,” mechanically it should still go through the same owners.

---

## 21. Compound / Campaign Separation Contract

This deserves explicit protection.

### 21.1 Compound Is Not Hub

The compound is a world context and embodied home layer. The Hub is a persistent strategic state layer. They are related but not identical.

### 21.2 Campaign Is Not Region Generator

The campaign runtime consumes a generated region, but region generation does not own mission progression.

### 21.3 Return Is Not Reboot

Returning to compound after mission resolution should preserve persistent Hub mutation, campaign history, and reintegration semantics. It is not the same as fresh startup.

### 21.4 Strong Rule

Never use world-context identity as a shortcut for strategic-state identity.

---

## 22. Objective Contract Integration

Campaign Flow needs mission facts, but objective systems may vary by mission archetype. The integration layer therefore needs a common objective reporting contract.

### 22.1 Required Common Objective Surface

Every mission objective provider should be able to report:

* active primary objectives
* active optional objectives
* completion states
* extraction required/available/completed
* mission irrecoverable failure state
* partial-progress data

### 22.2 Why This Matters

Without a common reporting surface, Campaign Flow becomes tightly coupled to each mission archetype’s bespoke scripts.

### 22.3 Recommended Approach

A mission objective coordinator should expose a typed summary interface consumed by Campaign Flow rather than forcing Campaign Flow to inspect every objective node individually.

---

## 23. Error and Failure Contract

This system family needs consistent failure behavior.

### 23.1 Failure Classes

#### Integration Failure

The architecture contract itself was violated.
Examples:

* two active world authorities
* missing registered owner
* outcome applied twice

#### Transition Failure

World context switch failed.

#### Generation Failure

Region generation or compound reconstruction failed.

#### Runtime Validation Failure

World built but failed validity checks.

#### Gameplay Failure

Player failed campaign objective; this is not an architecture error.

### 23.2 Required Behavior

Architectural failures should:

* fail loudly
* produce structured logs
* not silently recover into undefined states
* prefer safe fallback to compound if possible

Gameplay failures should:

* route through campaign flow
* produce valid `CampaignOutcome`
* not be treated as system errors

### 23.3 Strong Rule

Do not conflate “player lost the mission” with “the architecture broke.”

---

## 24. Required Logging and Audit Trail

The integration layer should make end-to-end tracing possible.

### 24.1 Every Major Cross-System Transaction Should Log:

* request ID
* owning system
* source phase/context
* target phase/context
* key payload identifiers
* success/failure result

### 24.2 Examples

* mission selection lock
* deployment request
* world transition complete
* region generation complete
* mission resolution generated
* Hub mutation applied
* return reintegration complete

### 24.3 Why This Matters

Once all seven systems exist, you will need a way to answer:
“where did this state become wrong?”

Without traceable transactions, you will waste hours stepping through scene code.

---

## 25. Recommended Integration Nodes / Files

Recommended implementation footprint:

```plaintext id="dkb2v3"
custodian/core/systems/integration/
    runtime_services.gd
    integration_contracts.gd
    save_integration_manager.gd
    objective_integration_surface.gd
    world_authority_registry.gd
```

You do not necessarily need all five files immediately, but the roles should exist.

### 25.1 `runtime_services.gd`

Central service discovery.

### 25.2 `integration_contracts.gd`

Shared enums, typed contract helpers, validation helpers.

### 25.3 `save_integration_manager.gd`

Coordinates save/load surfaces from authoritative owners.

### 25.4 `objective_integration_surface.gd`

Defines a common objective-reporting interface for Campaign Flow.

### 25.5 `world_authority_registry.gd`

Tracks which world context and root are authoritative right now.

---

## 26. Recommended Shared Enums and IDs

The integration layer should centralize certain cross-system enums so different systems do not redefine them inconsistently.

Candidate shared enums:

* `WorldContextType`
* `TransitionPhase`
* `CampaignFlowPhase`
* mission resolution states
* objective state
* save validity state

Candidate shared ID fields:

* `campaign_id`
* `scenario_id`
* `request_id`
* `region_seed`
* `hub_cycle_index`

This is not about making one god-file with everything in it. It is about preventing type drift between systems.

---

## 27. The “Single Path In” Rule

For every major action, define exactly one canonical path in.

### 27.1 Accept Mission

Canonical path:

* UI request -> Campaign Flow -> Hub validation -> World Transition request

### 27.2 Build Campaign World

Canonical path:

* World Transition -> Region Generation -> Transition bind/finalize

### 27.3 Apply Mission Outcome

Canonical path:

* Campaign Flow produces `CampaignOutcome` -> Hub mutation owner consumes it

### 27.4 Change World Context

Canonical path:

* World Transition only

### 27.5 Damage Structural Compound Tile

Canonical path:

* request to Compound Tile System only

### 27.6 Why This Matters

If there are multiple equally valid ways to perform the same high-level action, the architecture will fork and become inconsistent.

---

## 28. Anti-Corruption Rules for Legacy and Experimental Systems

The project still contains legacy reference layers and may also accumulate debug, test, or experimental systems. The integration contract must prevent those from accidentally becoming runtime authorities.

### 28.1 Legacy Rule

The Python terminal stack is legacy reference only, not active gameplay authority. This is already repository policy and must remain explicit.  

### 28.2 Experimental Rule

Temporary debug flows or prototype scenes must not become hidden alternate owners of:

* campaign selection
* mission loading
* persistent mutation
* save reconstruction

### 28.3 Strong Rule

Only documented owners in the active Godot runtime may mutate authoritative gameplay state.

---

## 29. Integration Test Scenarios

You should treat the integration layer as something that needs explicit test scenarios, even if they are only manual at first.

### 29.1 Test A — Fresh Boot to Compound

Confirms:

* service registration
* campaign flow initialization
* compound world authority
* no stale campaign state

### 29.2 Test B — Open Hub, Browse, Exit

Confirms:

* UI is consumer-only
* offer bundle stable
* no state mutation on review

### 29.3 Test C — Accept Mission and Deploy

Confirms:

* owner chain is correct
* scenario lock works
* world transition uses generated region
* campaign flow phase progression correct

### 29.4 Test D — Partial Success Return

Confirms:

* objective reporting
* outcome creation
* partial reward logic path
* reintegration and return

### 29.5 Test E — Failure Return

Confirms:

* architecture distinguishes gameplay failure from system failure
* Hub mutation on failure works
* return path still valid

### 29.6 Test F — Save/Load in Compound

Confirms:

* persistent state owned by correct systems
* active offers persist stably

### 29.7 Test G — Save/Load in Active Campaign

Confirms:

* campaign session reconstruction
* same world/spec rebuilt
* campaign flow phase resumes correctly

### 29.8 Test H — Structural Compound Damage Persistence

Confirms:

* compound tile deltas survive save/load
* no second structural truth was invented

---

## 30. Growth Path / Future-Proofing Rules

This system should support future additions without architectural collapse.

### 30.1 New Biomes

Must plug in through Region Generation and scenario conditioning, not through Campaign Flow hacks.

### 30.2 New Mission Types

Must expose the same objective/reporting contract.

### 30.3 New Compound Services

Must query compound tile authority rather than infer from scene visuals.

### 30.4 Multiplayer or Co-op Later

Would need a new authority model, but the current ownership clarity still helps isolate what would need to change.

### 30.5 Transit/Interstitial Presentation

May be added as a new world context without changing Hub ownership or campaign ownership.

---

## 31. Hard Architectural Prohibitions

These are not suggestions.

### 31.1 Do Not Let UI Own Core Game State

No UI-authored phase or world mutations.

### 31.2 Do Not Let Campaign Worlds Mutate Hub State Live

Only `CampaignOutcome` crosses that boundary.

### 31.3 Do Not Let Region Generation Decide Phase Progression

Generation builds worlds; it does not own game-loop state.

### 31.4 Do Not Let Transition Manager Reimplement Hub Logic

Transition moves worlds; it does not own scenario meaning or persistent reward logic.

### 31.5 Do Not Let Compound Structural Truth Split from TileMap Truth

TileMap remains spatial authority.

### 31.6 Do Not Let Save/Load Bypass Live Contracts

Resume should reconstruct through the same owner pathways where possible.

### 31.7 Do Not Maintain Multiple Active World Authorities

Ever.

---

## 32. Recommended Build Order for the Glue Layer

This document is last in the design set, but implementation should start before all features are “done,” because it supports them.

### Phase 1 — Service Registry and World Authority Registry

* runtime service lookup
* active world authority tracking
* manager registration

### Phase 2 — Shared Contract Types

* shared enums
* request/result ID helpers
* typed cross-system payload definitions where missing

### Phase 3 — Objective Integration Surface

* normalize mission reporting to campaign flow

### Phase 4 — Save Integration Manager

* owner-based save/load coordination
* forbid save during invalid transition states

### Phase 5 — Full End-to-End Transaction Logging

* request/result logs
* phase/context traceability
* owner mutation trace points

---

## 33. Acceptance Criteria

This file is complete when all of the following are true.

### Ownership

* [ ] every major game fact has one authoritative owner
* [ ] no two systems compete for active world authority
* [ ] persistent vs transient state boundaries are explicit

### Communication

* [ ] major cross-system actions use request/result/signal patterns
* [ ] systems primarily consume typed outputs rather than infer hidden state
* [ ] UI is consumer-only for core game state

### Save/Load

* [ ] save/load coordinates through owner systems
* [ ] restore paths do not bypass transition/build contracts
* [ ] no system serializes another system’s truth “for convenience”

### Runtime Safety

* [ ] service discovery is explicit
* [ ] stale world-specific services unregister correctly
* [ ] campaign outcome is applied exactly once

### Debuggability

* [ ] major cross-system actions can be traced
* [ ] failures can be classified as integration/transition/generation/runtime/gameplay
* [ ] end-to-end deploy/resolve/return can be audited

### Architectural Integrity

* [ ] Hub remains persistent meta owner
* [ ] campaign worlds remain transient
* [ ] transition remains the sole world-context owner
* [ ] compound tile system remains structural tile owner
* [ ] campaign flow remains phase owner

---

## 34. Exit Condition

This file is done when you can:

1. boot the game,
2. verify every major service registers cleanly,
3. enter the Hub from the compound,
4. accept a mission through the canonical path,
5. deploy through the world transition layer,
6. generate and enter a campaign region through the region-generation layer,
7. complete, partially complete, fail, or abandon the mission,
8. produce a single authoritative `CampaignOutcome`,
9. return to the compound through the canonical path,
10. see Hub mutation applied exactly once,
11. save and reload in stable phases without desynchronizing ownership,
12. and audit the whole sequence without guessing which system owned what.

That is the minimum viable Integration Contract.

---

## 35. Final Architectural Summary

If the previous six files defined the body, this file defines the connective tissue.

The architecture should now be readable as:

```plaintext id="zfy31f"
Hub System
    owns persistent strategic truth

Campaign Flow
    owns macro loop phase truth

World Transition
    owns world-context handoff truth

Region Generation
    owns scenario-conditioned mission world construction truth

Compound Tile System
    owns structural compound truth

Runtime World/Camera Stabilization
    owns active world-space binding correctness

Integration Contract
    ensures all of the above communicate without ownership drift
```

That is the full game architecture.

---

# Progress Tracking

## Completed Files

* [1] Runtime World & Camera Stabilization
* [2] Hub System (Meta Progression)
* [3] World Transition System
* [4] Region Generation System
* [5] Compound Tile System
* [6] Campaign Flow & Game Loop
* [7] Integration Contract (Glue Layer)

## Still To Go

* None in this 7-file expansion set

