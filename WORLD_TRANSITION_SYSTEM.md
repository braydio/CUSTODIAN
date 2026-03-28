# `design/20_features/in_progress/WORLD_TRANSITION_SYSTEM.md`

# World Transition System

**Project:** CUSTODIAN
**Status:** Required After Runtime Stabilization and Hub Foundation
**Priority:** High
**Depends On:** Runtime World & Camera Stabilization, Hub System (Meta Progression)
**Blocks:** Campaign Flow & Game Loop, Integration Contract, Region Deployment
**Runtime Target:** Godot 4.x (`custodian/`)
**Last Updated:** 2026-03-27

---

## 1. Purpose

Define the runtime system that moves the player and simulation authority between major world contexts without corrupting state, breaking camera/input binding, or blurring the distinction between the persistent Hub and transient campaign worlds.

This system is not just scene loading. It is the authoritative contract for entering, leaving, unloading, and re-binding runtime contexts such as:

* compound home state
* campaign region state
* optional transit/interstitial state
* post-resolution return to compound

The project already has an active Godot runtime, procgen map promotion, contract-based map generation, and a local in-world terminal. It also already has a documented target mission flow moving from briefing to prep to assault and beyond.   What it does not yet have is a clean, explicit, reusable world transition layer that says:

> this world is shutting down, this next world is now authoritative, these systems must unbind, these systems must rebind, and this is the exact point at which player control resumes.

That is what this file defines.

---

## 2. Why This System Exists

The current runtime has already outgrown a single-scene, single-context model.

Active project state already includes:

* a playable Godot combat slice
* runtime procgen contract map loading
* world promotion into live runtime
* a local command terminal
* wave combat and turrets
* free-roam pre-assault planning as an active implementation direction
* a Hub design that separates persistent Hub state from transient campaign state   

Once the Hub exists and can surface offers, the project needs a formal answer to:

* how do we leave the compound?
* what exactly gets unloaded?
* what survives into the mission?
* how does the mission world get instantiated?
* how do we return?
* what applies before return?
* when is campaign destruction legal?

Without a dedicated transition system, those responsibilities get scattered across UI, procgen loaders, scenario generators, and scene scripts. That produces state leaks, nondeterministic handoff bugs, duplicate ownership, and brittle world boot logic.

---

## 3. Design Intent

The World Transition System must satisfy five design goals simultaneously.

### 3.1 Preserve the Hub/Campaign Split

The Hub is persistent. Campaign worlds are disposable. Transition logic must never quietly merge those lifetimes. Accepting a proposal creates a campaign world. Resolving or abandoning it returns a distilled outcome to the Hub and destroys the campaign world. 

### 3.2 Make Context Changes Explicit

There must be a single authority that knows:

* current world context
* target world context
* transition phase
* blocking conditions
* completion conditions

### 3.3 Rebind Runtime Correctly Every Time

The earlier runtime stabilization doc established that camera, aim, navigation, anchors, and collision must all rebind correctly after procgen handoff. Transition logic must reuse that same discipline every time a world context changes.  

### 3.4 Keep Transitions Deterministic and Auditable

The repository-level guidance is explicit: keep simulation deterministic and separate from rendering/UI. Transition logic must therefore be state-machine driven, not timing-hack driven. 

### 3.5 Support Gradual Growth

The first implementation can begin with:

* compound world
* campaign region world
* return flow

But the system must be structured so later additions such as transit cutscenes, special one-off deployments, exfil states, and multi-stage operations fit without rewriting ownership.

---

## 4. Non-Goals

This file does **not** define:

* biome generation rules
* mission geometry generation
* compound wall tile construction
* Hub scenario generation logic
* combat system tuning
* save serialization schema in full detail
* cinematic presentation specifics
* shader/loading-screen polish

It does define the world-level lifecycle contract those systems must follow.

---

## 5. Core Principle

A world transition is not “open another scene.”

A world transition is:

> the ordered shutdown of one authoritative runtime world context and ordered activation of another, with explicit state transfer, binding, validation, and player-control gating.

The critical word is **authoritative**.

At any given moment, there must be exactly one active gameplay world authority. During transition, there may be zero active gameplay authorities for a brief controlled interval, but there may never be two simultaneous active authorities competing for player, camera, AI, or input ownership.

---

## 6. Canonical Transition Cases

This system must support the following transition cases from the start.

### 6.1 Compound Boot

Game boots into compound world or into a saved hub-side world context.

### 6.2 Compound to Campaign Region

Player accepts a Hub proposal and deploys into a transient campaign world.

### 6.3 Campaign Region to Compound

Campaign resolves via victory, partial success, failure, or abandonment; outcome is applied to Hub; campaign world is destroyed; player returns to compound.

### 6.4 Compound to Compound Rebuild

Optional internal refresh where the compound is regenerated, reconfigured, or reset without leaving the broader hub context.

### 6.5 Campaign-to-Campaign Direct Handoff

Not required initially, but the transition system should not make it impossible.

### 6.6 Transit/Interstitial

An optional non-interactive or semi-interactive layer between world contexts. This is not required for first ship, but the state machine should leave room for it.

---

## 7. World Context Taxonomy

Lock the available context types now so naming does not drift later.

```gdscript id="egrv43"
enum WorldContextType {
    NONE,
    COMPOUND,
    CAMPAIGN_REGION,
    TRANSIT,
    POST_CAMPAIGN_RESOLUTION
}
```

### 7.1 `NONE`

Used only during startup or active transition shutdown window. No gameplay world should be simulating here.

### 7.2 `COMPOUND`

The home-state runtime context that hosts:

* the persistent player presence
* in-world terminal access
* hub access surface
* local preparation loops
* local traversal and support systems

### 7.3 `CAMPAIGN_REGION`

A transient mission world instantiated from a selected `CampaignScenario`.

### 7.4 `TRANSIT`

Optional interstitial presentation or logic layer between contexts.

### 7.5 `POST_CAMPAIGN_RESOLUTION`

Optional short-lived bookkeeping state used after mission resolution but before full return. This is useful if you want to stage outcome application, stats presentation, archive mutation summaries, or delayed return logic without letting gameplay resume.

---

## 8. Transition State Machine

This file must define a real transition state machine, not just a helper function.

```gdscript id="avv6nj"
enum TransitionPhase {
    IDLE,
    REQUESTED,
    VALIDATING,
    PRE_SHUTDOWN,
    SHUTTING_DOWN_CURRENT_WORLD,
    BUILDING_TARGET_WORLD,
    BINDING_TARGET_WORLD,
    VALIDATING_TARGET_WORLD,
    FINALIZING,
    COMPLETE,
    FAILED
}
```

### 8.1 Why This Matters

Without explicit phases, transition bugs become impossible to diagnose. You end up with:

* UI already hidden but world not unloaded
* world loaded but player not spawned
* camera bound before bounds exist
* input restored before navigation rebuild finishes
* save/load mutating target state during build

The phase model prevents those classes of bugs.

---

## 9. Transition Authority

This system needs one owner.

### 9.1 Required Owner

```plaintext
custodian/core/systems/world/world_transition_manager.gd
```

This manager is the authoritative owner of:

* current world context
* pending target world context
* active transition phase
* transition lock state
* transition result
* world bootstrap/shutdown callbacks

### 9.2 What It Must Not Own

It must not own:

* Hub scenario generation
* region geometry generation
* camera follow behavior internals
* navigation algorithms
* operator combat behavior

It coordinates those systems; it does not replace them.

---

## 10. Structural Responsibilities

The World Transition Manager must own the following responsibilities.

### 10.1 Request Intake

Receive transition requests from:

* Hub UI
* boot flow
* campaign resolution flow
* save/load flow
* debug/dev tools

### 10.2 Validation

Check that transition is legal before any state mutation happens.

### 10.3 Current World Shutdown

Pause input, freeze relevant systems, emit teardown events, and destroy or detach the outgoing world correctly.

### 10.4 Target World Construction

Instantiate or load the target world context and associated runtime data.

### 10.5 Binding

Rebind:

* player
* camera
* navigation
* anchors
* world-specific systems
* UI state

### 10.6 Validation of Target World

Verify the new world is actually playable before control is returned.

### 10.7 Outcome and Return Routing

For region-to-compound flow, ensure campaign outcome is applied before campaign teardown finalization.

---

## 11. World Transition Data Contracts

The system needs explicit request/result payloads.

---

## 12. `WorldTransitionRequest`

```gdscript id="muo20a"
class_name WorldTransitionRequest
extends Resource

var request_id: String
var source_context: int = 0
var target_context: int = 0

var scenario_id: String = ""
var campaign_id: String = ""
var hub_cycle_index: int = 0

var target_seed: int = 0
var target_payload: Dictionary = {}
var preserve_player_node: bool = true
var preserve_hub_state: bool = true
var apply_campaign_outcome: bool = false
var campaign_outcome: CampaignOutcome

var transition_reason: String = ""
var spawn_mode: String = "default"
var debug_flags: Dictionary = {}
```

### 12.1 Notes

* `request_id` makes transitions traceable in logs and save/load state.
* `source_context` and `target_context` are typed with `WorldContextType`.
* `scenario_id` and `campaign_id` are populated when deploying into or returning from a mission.
* `target_seed` is the deterministic construction seed when target world generation depends on one.
* `target_payload` is an extensibility bucket for strongly-typed or semi-structured target boot data.
* `preserve_player_node` is important because you likely want to persist the player entity object across context changes rather than destroy/recreate it every time.
* `apply_campaign_outcome` controls whether a provided outcome must be consumed before transition finalization.
* `spawn_mode` can support later distinctions like `mission_entry`, `compound_return`, `resume_save`, `forced_debug_spawn`.

---

## 13. `WorldTransitionResult`

```gdscript id="a9uczt"
class_name WorldTransitionResult
extends Resource

var request_id: String
var succeeded: bool = false
var final_context: int = 0
var final_phase: int = 0
var failure_reason: String = ""

var built_world_root_path: NodePath
var world_seed: int = 0
var spawned_player_position: Vector2 = Vector2.ZERO
var bounds_rect: Rect2 = Rect2()

var notes: Array[String] = []
```

This is both a debug artifact and a useful save/load audit artifact.

---

## 14. Current and Target World Definitions

The system should define a typed concept of “world spec” rather than passing raw strings around.

---

## 15. `WorldSpec`

```gdscript id="m3y1xe"
class_name WorldSpec
extends Resource

var context_type: int
var world_id: String
var scene_path: String = ""
var generation_mode: String = ""   # static_scene / procgen_contract / scenario_region / saved_resume
var seed: int = 0
var payload: Dictionary = {}
```

### 15.1 Why `WorldSpec` Exists

Because `COMPOUND` and `CAMPAIGN_REGION` may both be implemented by:

* static scene loads
* scene + procgen population
* fully generated runtime instances
* save-resumed reconstruction

A `WorldSpec` cleanly captures what the target world is without hardcoding every transition path into one giant `match` block.

---

## 16. Transition Entry Points

The following public entry points are recommended.

```gdscript id="a74h7f"
func request_boot_to_compound()
func request_deploy_to_campaign(scenario: CampaignScenario)
func request_return_to_compound(outcome: CampaignOutcome)
func request_resume_saved_world(save_payload: Dictionary)
func request_debug_transition(spec: WorldSpec)
```

### 16.1 Important Rule

Only these public request methods should be used by outside systems. Internal phase changes should be private. This keeps the state machine authoritative and prevents rogue scene scripts from skipping validation.

---

## 17. Legal Transition Matrix

Define what transitions are legal. Anything not legal should fail fast.

| Source                   | Target          | Legal         | Notes                                 |
| ------------------------ | --------------- | ------------- | ------------------------------------- |
| NONE                     | COMPOUND        | Yes           | boot flow                             |
| NONE                     | CAMPAIGN_REGION | Yes           | save resume / debug only              |
| COMPOUND                 | CAMPAIGN_REGION | Yes           | normal deploy                         |
| CAMPAIGN_REGION          | COMPOUND        | Yes           | normal resolution/abandonment         |
| COMPOUND                 | COMPOUND        | Yes           | internal rebuild/resume               |
| CAMPAIGN_REGION          | CAMPAIGN_REGION | Not initially | reserve for multi-mission chain later |
| TRANSIT                  | COMPOUND        | Yes           | optional                              |
| TRANSIT                  | CAMPAIGN_REGION | Yes           | optional                              |
| POST_CAMPAIGN_RESOLUTION | COMPOUND        | Yes           | optional intermediate                 |

### 17.1 Fast-Fail Rule

If a request violates this matrix, the transition should fail in `VALIDATING` phase with no state mutation.

---

## 18. Integration with Hub System

The World Transition System is downstream of Hub selection but upstream of Campaign Flow.

### 18.1 On Mission Selection

Hub UI or Hub Manager should:

1. identify selected `CampaignScenario`
2. mark acceptance in hub state if needed
3. issue `request_deploy_to_campaign(scenario)`

The World Transition System then becomes responsible for:

* building the campaign runtime world
* moving player into it
* ensuring target context becomes authoritative

### 18.2 On Mission Resolution

Campaign flow produces `CampaignOutcome`. Transition system then:

1. receives return request
2. routes outcome application to Hub Manager / Knowledge System
3. tears down campaign world
4. restores compound world
5. rebinds player/camera/UI
6. resumes player control in compound

This preserves the architecture already established in the Hub doc: campaign world is destroyed after its distilled outcome mutates the hub. 

---

## 19. Integration with Runtime World Stabilization

This file assumes the world/camera stabilization work is complete. That means the transition system should not invent a separate rebind path; it should call into the same runtime world binding contract.

When a target world is built, the transition system must invoke the equivalent of:

* active world root registration
* bounds calculation from actual runtime world
* camera target bind
* camera bounds rebind
* navigation rebuild against active floor/wall tilemaps
* anchor placement validation
* aim-space correctness validation gate

This is mandatory because project status already identifies camera and aim correctness as fragile under procgen handoff. 

---

## 20. World Lifecycle Phases in Detail

This is the heart of the file.

---

## 21. `IDLE`

No transition active. One world context is authoritative, or none during startup.

### Entry Conditions

* no request pending
* current world stable

### Exit Conditions

* request accepted

---

## 22. `REQUESTED`

A request object exists but no mutation has occurred.

### Responsibilities

* copy request into manager
* lock additional requests
* emit transition-start debug event

### Important Rule

No world shutdown yet.

---

## 23. `VALIDATING`

Validate legality and prerequisites before touching runtime.

### Checks

#### 23.1 Request Validity

* request object present
* source/target contexts legal
* required IDs/seeds exist

#### 23.2 Hub Preconditions

For `COMPOUND -> CAMPAIGN_REGION`:

* selected `CampaignScenario` exists
* scenario still valid
* hub not in invalid state
* offer bundle not stale or already consumed incorrectly

#### 23.3 Outcome Preconditions

For `CAMPAIGN_REGION -> COMPOUND`:

* if `apply_campaign_outcome` is true, outcome object must be present
* campaign ID must match active campaign

#### 23.4 Save/Resume Preconditions

* required save payload fields available

### Failure Behavior

* set phase `FAILED`
* emit failure reason
* do not mutate runtime

---

## 24. `PRE_SHUTDOWN`

Prepare outgoing world for teardown.

### Responsibilities

* disable new input
* stop acceptance of combat interactions
* freeze mission or compound systems that should not tick during teardown
* stage UI for transition
* optionally snapshot outgoing campaign state if needed for diagnostics/save

### Important Rule

This is where you stop *interaction*, not where you destroy the world yet.

---

## 25. `SHUTTING_DOWN_CURRENT_WORLD`

Outgoing world authority is being dismantled.

### Responsibilities

#### 25.1 Pause Runtime Mutation

The current world should stop progressing simulation. Since the project is fixed-step and deterministic, no additional simulation advancement should occur after teardown starts unless explicitly designed. 

#### 25.2 Detach World-Owned Systems

Unbind or clear:

* world-specific navigation references
* world-specific anchors
* world-specific spawn nodes
* world-specific objective nodes
* world-specific wave manager ownership

#### 25.3 Handle Player Strategy

Preferred early approach:

* preserve player node
* detach from outgoing world parent if necessary
* move into transition-safe container
* clear transient combat/runtime state inappropriate to carry across contexts

#### 25.4 Destroy or Archive Outgoing World

* compound may be preserved and hidden for some flows
* campaign region should generally be destroyed after outcome processing
* do not leave dead world nodes active in scene tree

### Important Rule

After this phase, there should be no ambiguity about which world is active. Usually the answer is “none yet.”

---

## 26. `BUILDING_TARGET_WORLD`

Construct or load the target world.

### 26.1 Compound Build Modes

Possible modes:

* existing compound scene reactivation
* fresh compound scene load
* compound procgen rebuild
* saved compound resume

### 26.2 Campaign Region Build Modes

Possible modes:

* scenario-driven region generation
* scenario-driven scene + procedural population
* saved campaign resume

### 26.3 Required Output

This phase must produce:

* target world root node
* target world context type
* world bounds candidate
* target tilemap and/or navigation authority references
* target spawn resolution inputs

### Important Rule

Do not return control here. Build is not bind.

---

## 27. `BINDING_TARGET_WORLD`

This is where the target world becomes the runtime authority.

### Responsibilities

#### 27.1 Parent World into Active Runtime Container

The target world root must be attached to the correct runtime world container.

#### 27.2 Register Active World References

Global or system-level references to current world authority must now point to the target world.

#### 27.3 Spawn / Place Player

Player placement rules:

* use mission entry spawn when entering campaign
* use compound return spawn when returning home
* validate walkability and reachability
* never spawn inside walls or inaccessible pockets

#### 27.4 Rebind Camera

Use the stabilized camera contract:

* set target to player
* set bounds from actual world
* snap once to new target
* resume normal follow after snap

#### 27.5 Rebuild Navigation

Bind to active target tilemaps and rebuild navigation graph as needed. The existing nav system already supports floor/wall tilemap graph reconstruction and rebuilds. 

#### 27.6 Rebind UI

UI must reflect new context:

* compound UI surfaces on return
* mission HUD and mission-specific overlays on deploy

#### 27.7 Rebind World-Specific Systems

Examples:

* mission objective manager
* wave manager
* local terminal mode
* region hazard managers
* supply systems

### Important Rule

This is the phase most likely to accumulate bugs if it becomes informal. Keep it explicit and ordered.

---

## 28. `VALIDATING_TARGET_WORLD`

Before player control resumes, validate that the new world is actually coherent.

### Required Checks

#### 28.1 World Exists

* target root valid
* active references non-null

#### 28.2 Player Valid

* player node exists
* spawn point valid
* position reachable

#### 28.3 Camera Valid

* bounds non-empty
* target assigned
* snap/follow consistent

#### 28.4 Navigation Valid

* required tilemap refs assigned
* pathing system rebuilt if needed

#### 28.5 Input Valid

* aim-space correctness checks available if mission context uses mouse aim

#### 28.6 Required Interactables / Objectives Valid

Depending on context:

* compound terminal reachable
* mission objective anchors placed
* extraction point present if required
* mission-critical props not missing

### Failure Policy

If validation fails:

* go to `FAILED`
* do not hand back player control
* optionally destroy partial target world
* keep debug logs and transition result

---

## 29. `FINALIZING`

This is the final handoff phase.

### Responsibilities

* mark current context = target context
* clear pending request
* unlock input
* signal world-ready to dependent systems
* optionally emit analytics/debug hook
* transition UI out of loading/interstitial state

### Important Rule

This is the only safe place to restore player agency.

---

## 30. `COMPLETE`

Transition succeeded. Return to `IDLE` after publishing result.

---

## 31. `FAILED`

Transition failed.

### Responsibilities

* publish failure reason
* preserve enough state for debugging
* avoid leaving dual-active worlds
* optionally attempt rollback to known-safe context

### Rollback Policy

Early implementation may use a conservative rollback:

* if failure happened while entering campaign from compound, rebuild compound as safe fallback
* if failure happened on boot, remain in no-world state with debug-safe UI

Do not try to be too clever early. Safe fallback beats fragile rollback logic.

---

## 32. Compound-to-Campaign Deploy Flow

This should be the first fully implemented real-world transition.

### Sequence

1. Hub UI selects `CampaignScenario`
2. Transition request created
3. Validate scenario and Hub state
4. Freeze compound input
5. Shutdown compound runtime world authority
6. Build campaign region from `CampaignScenario`
7. Parent region into runtime
8. Place player at mission entry
9. Rebind camera/navigation/UI
10. Validate mission world
11. Resume control

### Notes

* Compound scene may be destroyed or preserved; either is acceptable initially as long as authority is unambiguous.
* If preserving the compound in memory, it must not continue simulating in the background unless explicitly designed.

---

## 33. Campaign-to-Compound Return Flow

This is the second mandatory flow.

### Sequence

1. Campaign resolves into `CampaignOutcome`
2. Transition request created with `apply_campaign_outcome = true`
3. Validate outcome and campaign identity
4. Freeze campaign input and mission progression
5. Apply outcome to Hub via Hub Manager / Knowledge System
6. Shutdown campaign world
7. Build or reactivate compound
8. Place player at return spawn
9. Rebind camera/navigation/UI
10. Validate compound world
11. Resume control

### Important Rule

Outcome application must occur before campaign destruction is considered complete, because the entire architecture depends on campaign state distilling into Hub mutation before the transient world is discarded. 

---

## 34. Boot Flow

The boot path should reuse the same system rather than special-casing ad hoc initialization.

### Sequence

1. No current context
2. Request `NONE -> COMPOUND`
3. Build compound
4. Bind player/camera/UI
5. Validate
6. Resume control

### Why

This ensures every later transition path is using the same machinery as the very first world entry.

---

## 35. Save / Load Interaction

This system must support world reconstruction from persistent data without silently bypassing validation.

### 35.1 Save Implications

At save time, the following must be sufficient to reconstruct:

* current world context
* world spec
* player handoff position or spawn mode
* hub state reference or serialized payload
* campaign state reference or serialized payload if in mission
* active transition state if saving during transition is allowed

### 35.2 Recommended Early Restriction

Do not allow saving during active transition in first implementation. Require `TransitionPhase.IDLE` for normal saves. This removes a large class of mid-handoff corruption bugs.

### 35.3 Resume Flow

Load should effectively create:

* `WorldSpec`
* context type
* required persistent state
* transition request into that world

This keeps boot and resume under one architecture.

---

## 36. Player Persistence Policy

This decision matters enough to be explicit.

### Recommended Policy: Preserve the Player Node

The same operator node persists across world transitions, but world-specific transient state is sanitized on entry.

### Benefits

* stable input bindings
* stable camera target identity
* less scene churn
* easier UI references

### Required Reset Surface

On entering a new world context, decide what resets:

* velocity
* hit reaction state
* temporary campaign-only buffs
* target lock
* mission-local consumables if not persistent
* animation transient states

### Important Rule

Preserving the node does not mean preserving all runtime combat state.

---

## 37. World-Specific Service Binding

Different world contexts require different active services.

### 37.1 Compound Context Services

* terminal hub access
* local prep systems
* compound interactables
* non-mission traversal
* possibly no wave manager or only local test events

### 37.2 Campaign Region Services

* objective manager
* extraction logic
* hazard managers
* mission-specific encounter systems
* scenario-specific local terminal mode if present

### Implementation Recommendation

Use service registration on entry rather than `if context == ...` scattered through unrelated systems.

Example concept:

```gdscript id="ymu0ek"
func bind_services_for_context(context_type: int, world_root: Node):
    match context_type:
        WorldContextType.COMPOUND:
            _bind_compound_services(world_root)
        WorldContextType.CAMPAIGN_REGION:
            _bind_campaign_services(world_root)
```

---

## 38. UI Transition Contract

UI must be transition-aware.

### During Transition

* disable interaction with world-facing menus
* optionally show loading/interstitial state
* prevent duplicate mission acceptance or input bleed

### On Compound Entry

* enable compound HUD surfaces
* enable hub terminal interaction cues
* hide mission-only overlays

### On Campaign Entry

* enable mission HUD
* enable objective displays
* disable or adapt hub-only presentation

### Important Rule

UI should react to authoritative world context, not infer context from scene names.

---

## 39. Error Handling Philosophy

Transition failures are high-severity because they strand the player between worlds. Error handling must therefore be conservative.

### 39.1 Fail Fast

Reject bad requests before mutating state.

### 39.2 Fail Loud

Produce:

* request ID
* phase
* failure reason
* context pair
* any relevant world spec

### 39.3 Prefer Safe Fallback

If possible, restore or rebuild the compound rather than leaving partially-loaded campaign state active.

### 39.4 No Silent Partial Success

If camera bound but navigation failed, that is failure, not success with warnings.

---

## 40. Required Debug Instrumentation

This system will need extensive debug support during implementation.

### 40.1 Transition Trace Log

Every phase change should log:

* request ID
* from context
* to context
* phase entered
* timestamp or tick
* outcome

### 40.2 Active Context Debug Overlay

Optional dev overlay:

* current context
* current phase
* world root path
* active campaign ID
* active scenario ID

### 40.3 Binding Audit

On finalization, log:

* player position
* camera bounds
* world root
* floor tilemap path
* walls tilemap path
* critical anchor presence

### 40.4 Failure Snapshots

On failure, dump enough structured data to reproduce the issue.

---

## 41. Integration with Existing Procgen Contract Map System

The contract map system already defines a deterministic payload pairing contract seed, planet, and map, and already re-parents the generated `ProcGenMap` into live runtime under active world containers. 

That means this system should not replace it. It should wrap it.

### Recommended Role Split

* `custodian_contract_map.gd` generates contract map payload
* `contract_world_loader.gd` performs world-promotion details
* `world_transition_manager.gd` decides **when** and **why** that flow runs, and treats its result as the target-world build phase output

This prevents procedural world generation logic from becoming the de facto world lifecycle owner.

---

## 42. File Targets

Recommended implementation targets:

```plaintext id="w4h7s7"
custodian/core/systems/world/world_transition_manager.gd
custodian/core/systems/world/world_spec.gd
custodian/core/systems/world/world_transition_request.gd
custodian/core/systems/world/world_transition_result.gd
```

Likely integration touch points:

```plaintext id="9t5zlu"
custodian/core/systems/contract_world_loader.gd
custodian/scenes/camera.gd
custodian/entities/operator/operator.gd
custodian/core/systems/navigation_system.gd
custodian/core/systems/hub/hub_manager.gd
custodian/core/systems/hub/knowledge_system.gd
custodian/scenes/game.tscn
```

---

## 43. Recommended Build Order

### Phase 1 — Core State Machine

* create transition manager
* define context enums
* define request/result types
* define legal transition matrix
* implement phase logging

### Phase 2 — Boot and Compound Baseline

* route initial compound load through transition manager
* validate world binding contract

### Phase 3 — Compound to Campaign Deploy

* integrate with Hub selection
* construct campaign world
* bind and validate

### Phase 4 — Campaign Return

* consume `CampaignOutcome`
* apply hub mutation
* destroy campaign world
* restore compound

### Phase 5 — Save/Resume Integration

* support resume through world spec / request path

### Phase 6 — Optional Transit / Polish

* add interstitial context
* add loading presentation
* add richer rollback rules

---

## 44. Failure Cases to Guard Against

### 44.1 Dual World Authority

Compound and region both remain active and both own input/camera-relevant nodes.

### 44.2 Input Leak During Transition

Player attacks or moves while world teardown/build is incomplete.

### 44.3 Stale Camera Binding

Camera remains bound to old world bounds or old player position after target build.

### 44.4 Partial Hub Mutation

Campaign outcome partially applies, then world teardown fails, leaving inconsistent persistent state.

### 44.5 Offer Consumption Drift

Scenario gets consumed in Hub, but deploy transition fails and no recovery policy exists.

### 44.6 Save/Load Reroll

Resuming a saved campaign produces a different generated world than the one originally accepted.

### 44.7 Transition-Owned Logic Leak

Scenario generation, mission objective logic, or region generation starts mutating state from inside transition manager instead of their own systems.

---

## 45. Acceptance Criteria

This file is complete when all of the following are true.

### Structural

* [ ] There is one authoritative world transition manager
* [ ] Transition phases are explicit and logged
* [ ] Context types are typed and stable

### Functional

* [ ] Boot enters compound through the transition system
* [ ] Compound-to-campaign deploy works through the transition system
* [ ] Campaign-to-compound return works through the transition system
* [ ] Player control is disabled during transition and restored only after final validation

### Binding

* [ ] Camera rebind occurs as part of transition
* [ ] Navigation rebind occurs as part of transition
* [ ] UI context switches correctly
* [ ] Player spawn/placement is validated on entry

### Hub Integration

* [ ] Selected scenario can be deployed into a campaign world
* [ ] `CampaignOutcome` can be applied before return finalization
* [ ] Campaign world is destroyed after outcome application

### Determinism / Persistence

* [ ] Same request + same source state produces same target world spec
* [ ] Save/resume re-enters world through the same transition architecture
* [ ] No hidden rerolls occur during resume

---

## 46. Exit Condition

This file is done when you can:

1. boot into the compound through the transition manager,
2. open the Hub,
3. select an offer,
4. deploy into a campaign world,
5. complete or abandon the mission,
6. return to the compound,
7. observe correct Hub mutation,
8. and confirm that at no point were two gameplay worlds simultaneously authoritative.

That is the minimum viable World Transition System.

---

# Progress Tracking

## Completed Files

* [1] Runtime World & Camera Stabilization
* [2] Hub System (Meta Progression)
* [3] World Transition System

## Still To Go

* [4] Region Generation System
* [5] Compound Tile System
* [6] Campaign Flow & Game Loop
* [7] Integration Contract (Glue Layer)

