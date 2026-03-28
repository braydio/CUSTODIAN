# `design/20_features/in_progress/CAMPAIGN_FLOW_AND_GAME_LOOP.md`

# Campaign Flow & Game Loop

**Project:** CUSTODIAN
**Status:** Required After Runtime Stabilization, Hub Foundation, World Transition, Region Generation, and Compound Structural Baseline
**Priority:** Critical
**Depends On:** Runtime World & Camera Stabilization, Hub System (Meta Progression), World Transition System, Region Generation System, Compound Tile System
**Blocks:** Integration Contract, end-to-end playable campaign loop
**Runtime Target:** Godot 4.x (`custodian/`)
**Last Updated:** 2026-03-27

---

## 1. Purpose

Define the full player-facing campaign loop and the authoritative runtime progression model that connects:

- compound presence
- Hub access
- scenario selection
- campaign deployment
- region play
- objective progression
- extraction or failure
- outcome processing
- persistent Hub mutation
- return to compound
- next-cycle continuation

This file exists because the project already has several strong but isolated systems:

- a Godot-authoritative combat/runtime slice with operator, waves, turrets, repair, and procgen world promotion
- a persistent/transient split between Hub and Campaign in the strategic model
- a defined world-transition layer for moving between contexts
- a region-generation layer for building scenario-conditioned campaign worlds
- a compound structural layer that makes the home base materially real

What is still missing is the **actual full loop contract**. This file defines how the game is played as a campaign rather than as disconnected systems or a single combat sandbox.

This is the document that answers:

- what happens first?
- what is the player doing in each phase?
- when do systems turn on and off?
- how is success measured?
- how does failure propagate?
- what actually constitutes one “run,” one “campaign,” one “cycle,” and one “return”?

---

## 2. Why This System Exists

Without an explicit Campaign Flow and Game Loop spec, the game risks fragmenting into:

- a compound sandbox with no strategic stakes
- a Hub that surfaces offers without meaningful operational cadence
- campaign regions that load and unload but do not belong to a coherent loop
- procedural missions that feel like standalone skirmishes rather than part of a campaign history
- partial and failure states that never become real game structure

The project direction already makes clear that the game is no longer terminal-first, and the active Godot runtime is intended to become a full embodied, real-time tactical experience rather than a disconnected prototype.

The campaign loop is the layer that turns:

- systems into structure
- missions into consequences
- exploration into choice
- failure into history
- repetition into progression

---

## 3. Design Intent

The Campaign Flow and Game Loop should satisfy the following design goals.

### 3.1 Preserve the Hub/Campaign Split

The persistent Hub and transient Campaign World must remain distinct. A campaign is instantiated from a scenario, resolved into an outcome, and then discarded, while the Hub persists and mutates.

### 3.2 Make the Compound Matter

The compound is not just a menu backdrop. It is the embodied preparation and return layer, a physical place where the player orients, accesses the terminal, reads campaign state, performs prep interactions, and re-enters the strategic layer.

### 3.3 Make Missions Structurally Different

Deployment should feel like leaving home for a temporary but consequential operational world.

### 3.4 Support Partial Success and Failure

Campaigns should not collapse into binary success/failure. Existing design direction already explicitly values partial victory and abandonment as first-class outcomes.

### 3.5 Produce a Repeatable but Finite Macro Loop

The game should support repeated cycles of selection, deployment, outcome, and return, but not in the form of endless stat inflation. Persistent gain should be primarily interpretive and doctrinal, not raw combat power.

### 3.6 Keep Runtime Ownership Clear

At any point, one system should know:

- what phase the game is in
- which world context is active
- which objectives are active
- whether the player is in prep, active mission, extraction, or resolution

---

## 4. Non-Goals

This file does **not** define in full detail:

- biome generation internals
- world-transition implementation internals
- compound tile damage internals
- save-file serialization schema
- exact UI widget layout or final art treatment
- low-level enemy AI
- exact balance values for reward rates, mission duration, or economy

It does define the authoritative macro loop and the runtime state contracts those systems must follow.

---

## 5. Core Principle

The game loop is not:

> “enter map, fight, repeat.”

The game loop is:

> **Compound Presence -> Hub Interpretation -> Scenario Selection -> Deployment -> Campaign Execution -> Outcome Distillation -> Hub Mutation -> Return**

Every major feature should be locatable somewhere inside that loop.

If a feature cannot be placed in that sequence, it is likely underspecified or belongs in a different system.

---

## 6. Canonical Gameplay Layers

The full game consists of three major layers.

### 6.1 Persistent Strategic Layer: Hub

The Hub tracks persistent historical state, knowledge, archive pressure, capability flags, and campaign history. It is the only long-lived metagame authority.

### 6.2 Embodied Home-State Layer: Compound

The compound is the lived-in, immediate home context where the player physically exists between campaigns, interacts with the terminal, optionally performs prep actions, and returns after mission resolution.

### 6.3 Transient Operational Layer: Campaign Region

A campaign region is an instantiated world built from a chosen scenario, played through, resolved, and destroyed.

The Campaign Flow system must connect all three without blurring them.

---

## 7. Canonical Player Loop

At the highest level, one full campaign cycle should be:

```plaintext id="2ggs54"
COMPOUND
    -> access HUB
    -> review persistent state and mission offers
    -> select / refine / accept scenario
    -> deploy

CAMPAIGN REGION
    -> enter mission
    -> orient / traverse / engage
    -> pursue objectives
    -> optionally complete subobjectives
    -> choose to continue / extract / abandon / fail

RESOLUTION
    -> generate CampaignOutcome
    -> apply outcome to Hub
    -> destroy campaign world
    -> return to compound

COMPOUND
    -> reorient
    -> inspect consequences
    -> choose next action
```

That is the macro loop. The rest of this file formalizes it.

---

## 8. Required Runtime Phase Model

This system should define an authoritative game-loop phase enum distinct from world-context type. World context says _where_ the player is. Campaign flow phase says _what part of the loop the game is currently in_.

```gdscript id="7g569q"
enum CampaignFlowPhase {
    BOOT,
    COMPOUND_IDLE,
    HUB_ACCESS,
    HUB_REVIEW,
    HUB_RECON,
    HUB_SELECTION_LOCK,
    DEPLOYMENT_TRANSITION,
    CAMPAIGN_ENTRY,
    CAMPAIGN_ACTIVE,
    CAMPAIGN_OBJECTIVE_COMPLETE_PENDING_EXFIL,
    CAMPAIGN_EXTRACTION,
    CAMPAIGN_RESOLUTION,
    RETURN_TRANSITION,
    RETURN_REINTEGRATION,
    CAMPAIGN_FAILURE_STATE,
    GAME_OVER
}
```

### 8.1 Why a Separate Flow Enum Is Necessary

Because the player can still be in the `COMPOUND` world context while different flow phases exist:

- idle
- reviewing Hub offers
- post-return reintegration
- game-over archive state

Likewise, the player can be in a `CAMPAIGN_REGION` world context but in very different flow states:

- entry/orientation
- objective-active
- extraction-required
- already-resolved but waiting on return transition

Without a flow-phase model, too much logic gets keyed to scene identity.

---

## 9. High-Level Campaign Loop State Machine

The canonical high-level state machine is:

```plaintext id="x47rgl"
BOOT
 -> COMPOUND_IDLE
 -> HUB_ACCESS
 -> HUB_REVIEW
 -> HUB_RECON (optional)
 -> HUB_SELECTION_LOCK
 -> DEPLOYMENT_TRANSITION
 -> CAMPAIGN_ENTRY
 -> CAMPAIGN_ACTIVE
 -> CAMPAIGN_OBJECTIVE_COMPLETE_PENDING_EXFIL (optional)
 -> CAMPAIGN_EXTRACTION (optional)
 -> CAMPAIGN_RESOLUTION
 -> RETURN_TRANSITION
 -> RETURN_REINTEGRATION
 -> COMPOUND_IDLE

Failure branches:
CAMPAIGN_ACTIVE -> CAMPAIGN_RESOLUTION
RETURN_REINTEGRATION -> GAME_OVER (if archive loss exceeded or terminal fail state reached)
```

This state machine is the backbone of the entire game.

---

## 10. Definitions

To prevent drift, these terms are locked for this file.

### 10.1 Cycle

A single persistent Hub-side step of generating, choosing, resolving, and returning from a campaign.

### 10.2 Campaign

A transient world instantiated from a selected scenario.

### 10.3 Mission

The player-facing operational experience inside that campaign world. For current purposes, “campaign” and “mission runtime” can be treated as near-synonymous, but keep “campaign” as the stronger systems term.

### 10.4 Outcome

The distilled result of campaign play, expressed as a `CampaignOutcome`, then applied back into the Hub.

### 10.5 Reintegration

The short post-return phase where the game has re-entered the compound but has not yet fully resumed ordinary idle state. This allows post-mission summaries, archive mutation presentation, or new unlock surfacing.

---

## 11. System Owner

This flow needs one authoritative coordinator.

### 11.1 Required Owner

```plaintext id="g7v9fy"
custodian/core/systems/campaign/campaign_flow_manager.gd
```

### 11.2 Responsibilities

The Campaign Flow Manager must own:

- current `CampaignFlowPhase`
- phase entry/exit logic
- phase preconditions
- integration with Hub Manager
- integration with World Transition Manager
- integration with objective/extraction systems
- production of `CampaignOutcome`
- compound return reintegration logic
- game-over checks

### 11.3 What It Must Not Own

It must not own:

- world transition internals
- region generation internals
- Hub scenario generation internals
- compound tile registry logic
- enemy AI internals
- camera follow logic

It coordinates them through contracts.

---

## 12. Relationship to Existing Docs

This file sits above several others:

### 12.1 Hub System

This file consumes:

- active Hub state
- offer bundle
- recon/refinement results
- outcome application pathways

### 12.2 World Transition System

This file requests:

- compound -> campaign deployment
- campaign -> compound return

### 12.3 Region Generation System

This file consumes generated campaign worlds indirectly through transition/build systems.

### 12.4 Compound Tile System

This file treats the compound as the embodied return/prep layer and may gate prep interactions or repair opportunities there.

---

## 13. Boot Flow

The first implementation should route boot through the campaign flow manager rather than allowing the game to materialize in arbitrary mid-state.

### 13.1 Canonical Boot Sequence

1. Initialize Hub state or load it
2. Enter `BOOT`
3. Request compound world through world transition manager
4. On successful compound bind, enter `COMPOUND_IDLE`

### 13.2 Important Rule

The game should not boot directly into mission combat by default once campaign flow is active. The earlier pre-assault walkthrough already identifies the need to move away from “boot straight into wave defense” and toward a contract/briefing/prep flow.

---

## 14. `COMPOUND_IDLE`

This is the baseline resting state.

### 14.1 Player Experience

The player is physically present in the compound. They can:

- move
- orient themselves
- inspect local space
- interact with terminal/Hub access surfaces
- optionally perform limited prep or structural interactions
- choose when to enter the strategic review layer

### 14.2 Systems That Should Be Active

- player movement
- compound camera
- compound interaction surfaces
- local ambient systems
- local repair/prep systems if present
- Hub access prompt availability

### 14.3 Systems That Should Not Be Active

- active campaign objective logic
- mission extraction logic
- campaign pressure systems
- campaign-specific hazard managers

### 14.4 Exit Conditions

- player accesses the Hub terminal/interface
- debug or save-resume path requests another phase

---

## 15. `HUB_ACCESS`

This is the transition from ordinary compound presence into strategic review.

### 15.1 Player Experience

The player interacts with the command terminal or equivalent surface, entering the Hub interface while still conceptually remaining in the compound context.

### 15.2 Responsibilities

- freeze or gate ordinary local interactions that should not overlap with Hub navigation
- initialize Hub UI state
- fetch current stable offer bundle from Hub Manager
- display compound-side persistent status

### 15.3 Required Display Surface

At minimum, Hub access should expose:

- archive pressure state
- active offer bundle
- current capability-driven information surface
- campaign history summary access
- recon/refine affordances if available

This aligns with the terminal-style mission surfacing already described in the Hub roadmap.

---

## 16. `HUB_REVIEW`

This is the main strategic browsing state.

### 16.1 Player Experience

The player reviews currently available campaign proposals, reading:

- biome
- difficulty descriptor
- threat profile
- victory type
- uncertainty
- reward archetype
- archive implications where visible

### 16.2 Responsibilities

- display active offer bundle without mutating it
- permit moving between offers
- surface visible fields according to Hub recon capability
- support entry into recon/refinement if unlocked

### 16.3 Important Rule

Review is read-only. Simply highlighting or browsing offers must not reroll, mutate, or consume them.

### 16.4 Exit Conditions

- player requests recon/refinement
- player selects an offer to lock
- player exits back to `COMPOUND_IDLE`

---

## 17. `HUB_RECON`

Optional but strategically important state.

### 17.1 Player Experience

The player uses recon capability to refine understanding of an offer before acceptance.

### 17.2 Responsibilities

- consume allowed recon action if such a cost/policy exists
- reveal or narrow hidden scenario fields
- update visible offer information without generating a new offer
- preserve deterministic recon results

### 17.3 Design Rule

Recon reduces misinterpretation, not danger. It should reveal enough to matter but never make the mission fully solved in advance. This follows the Hub philosophy already locked in earlier docs.

### 17.4 Exit Conditions

- recon completes and returns to `HUB_REVIEW`
- player exits recon without acceptance

---

## 18. `HUB_SELECTION_LOCK`

This is the moment an offer becomes committed.

### 18.1 Why This Phase Exists

Because selecting a scenario is not the same as finishing deployment. You need an explicit state between “player clicked mission” and “mission world is active” so the game can:

- validate that the offer is still legal
- mark acceptance cleanly
- prevent duplicate acceptance
- hand a stable scenario into the transition layer

### 18.2 Responsibilities

- lock selected `CampaignScenario`
- notify Hub Manager that the offer is being consumed
- create campaign ID / acceptance record if needed
- prepare `WorldTransitionRequest`
- block further Hub navigation

### 18.3 Failure Behavior

If acceptance validation fails, return to `HUB_REVIEW` with error-safe logging.

---

## 19. `DEPLOYMENT_TRANSITION`

The player is leaving the compound and entering the campaign.

### 19.1 Responsibilities

This phase hands control to the World Transition System to:

- tear down compound authority
- build target campaign world
- bind player/camera/navigation/UI
- validate target world

### 19.2 Campaign Flow Responsibilities During Transition

- freeze phase state progression
- preserve accepted scenario identity
- wait for transition success/failure callback
- on success, move to `CAMPAIGN_ENTRY`
- on failure, roll back to stable Hub/compound phase according to transition result

### 19.3 Important Rule

Campaign Flow should not manually instantiate regions or scenes itself. It requests deployment and waits for the authoritative transition result.

---

## 20. `CAMPAIGN_ENTRY`

This is the short post-deploy, pre-full-control mission entry phase.

### 20.1 Player Experience

The player has entered the region but may still be:

- orienting
- receiving mission summary
- seeing objective designation
- being positioned at entry

### 20.2 Why This Phase Matters

It separates:

- successful world load
  from
- full mission active state

This gives a clean place for:

- mission intro summary
- objective registration
- hazard initialization
- initial wave or pressure arming
- entry-safe camera snap or local context reveal

### 20.3 Responsibilities

- register active mission objectives
- register extraction status
- enable campaign HUD
- initialize mission timer / pacing state if used
- release into `CAMPAIGN_ACTIVE` once ready

---

## 21. `CAMPAIGN_ACTIVE`

This is the main operational phase of a mission.

### 21.1 Player Experience

The player traverses the region, fights, explores, interprets the environment, and pursues the scenario-defined objectives.

### 21.2 Required Active Systems

- player combat and traversal
- mission objective tracking
- region hazard systems
- encounter/spawn systems
- extraction readiness logic if relevant
- optional subvictory tracking
- resource and survivability tracking
- local mission failure detection

### 21.3 Gameplay Expectations

This phase should support:

- flexible pathing
- optional subobjective pursuit
- partial progress
- tactical retreat decisions
- objective completion without necessarily immediate mission end

### 21.4 Important Rule

Not all missions should end the moment the primary objective is technically satisfied. Some require extraction, stabilization hold, or survival to exit.

---

## 22. Mission Objective Model

Campaign flow needs a typed objective contract, not loose per-mission booleans.

### 22.1 Objective Categories

- primary objective(s)
- optional subvictories
- failure-critical conditions
- extraction condition(s)
- dynamic escalation conditions

### 22.2 Objective Lifecycle States

```gdscript id="hs3a2g"
enum ObjectiveState {
    INACTIVE,
    ACTIVE,
    COMPLETED,
    FAILED,
    LOCKED,
    OPTIONAL_EXPIRED
}
```

### 22.3 Required Objective Data

Each objective should expose:

- objective ID
- type
- required/optional status
- current progress
- completion threshold
- failure condition if applicable
- location anchor(s)

This should not all live in the Campaign Flow doc’s implementation, but the flow manager must know enough to reason about mission completion.

---

## 23. Mission Progression Patterns

Different missions can progress differently even inside `CAMPAIGN_ACTIVE`.

### 23.1 Direct Completion Pattern

Complete primary objective and mission ends immediately or nearly immediately.

### 23.2 Complete-Then-Extract Pattern

Complete primary objective, then move to extraction.

### 23.3 Multi-Stage Pattern

Objective A unlocks B, which unlocks extraction.

### 23.4 Hold/Stabilize Pattern

Reach site, activate process, then survive/maintain until threshold met.

### 23.5 Containment Collapse Pattern

Failure pressure rises over time and can force partial resolution or abandonment.

The Campaign Flow system should support all of these at the phase/contract level even if not all are implemented immediately.

---

## 24. `CAMPAIGN_OBJECTIVE_COMPLETE_PENDING_EXFIL`

This phase exists for missions where success is not final until the player leaves or stabilizes post-objective state.

### 24.1 Player Experience

The player has “done the thing,” but the world is not yet safely resolved. They may now need to:

- extract
- survive a final pressure wave
- carry recovered material
- route to an exit point

### 24.2 Responsibilities

- mark primary objective complete
- activate extraction or end-condition route
- possibly escalate pressure
- lock reward grade potential if such a system exists

### 24.3 Why This Matters

Without this phase, many mission types flatten into:

> touch objective -> instant win

That undermines pacing and post-objective tension.

---

## 25. `CAMPAIGN_EXTRACTION`

This phase governs the extraction route or extraction hold.

### 25.1 Player Experience

The player attempts to leave the mission space with whatever was secured.

### 25.2 Extraction Modes

As established in region generation:

- return to entry
- remote exfil
- unlocked exfil
- fallback exfil
- survival-until-evac window

### 25.3 Responsibilities

- determine extraction validity
- monitor player arrival or hold conditions
- allow abandonment-equivalent choices if appropriate
- allow death/failure during exfil to affect outcome grade

### 25.4 Important Rule

Extraction is part of mission success, not a cosmetic outro, in missions where it is required.

---

## 26. Mission Resolution Triggers

A mission should resolve under the following classes of trigger.

### 26.1 Full Success

Primary objectives complete, required extraction complete if applicable, failure conditions not exceeded.

### 26.2 Partial Success

Some meaningful portion of required objective work completed; enough to produce a non-zero `CampaignOutcome`.

### 26.3 Failure

Objective failed, player defeated, irreversible mission state collapse, or archive-critical loss occurred.

### 26.4 Abandonment

Player deliberately leaves or aborts under conditions the system treats as withdrawal.

These were already identified as first-class strategic states in earlier campaign design work and must remain distinct.

---

## 27. `CAMPAIGN_RESOLUTION`

This is the distillation phase.

### 27.1 Responsibilities

- freeze mission play
- compute final `CampaignOutcome`
- classify result as:
  - `COMPLETE_VICTORY`
  - `PARTIAL_VICTORY`
  - `FAILURE`
  - `ABANDONMENT`

- determine recovered items/knowledge/subvictories
- determine archive loss delta
- determine invalidated hypotheses or irretrievable losses
- notify Hub-side systems to apply the outcome
- prepare return transition

### 27.2 Important Rule

Campaign worlds do not mutate the Hub continuously during play. They resolve into a distilled outcome object and then that object mutates the Hub.

### 27.3 Outcome Contents

The `CampaignOutcome` structure already exists conceptually in the Hub doc and should be the only thing crossing the boundary from mission runtime into persistent Hub mutation.

---

## 28. Resolution Grading

The Campaign Flow system should support graded resolution, not just four coarse labels.

### 28.1 Recommended Grade Layer

- `S`, `A`, `B`, `C`, `D`, or similar if you want explicit grading later
- or simpler:
  - full
  - strong partial
  - weak partial
  - failure
  - abandonment

### 28.2 Inputs to Grade

- primary completion ratio
- optional objective completion
- extraction success
- archive damage/loss
- surviving recovered knowledge
- critical failure flags
- abandonment timing

### 28.3 Why Grade Matters

Not as score-chasing, but because different types of partial success should produce different Hub-side consequences.

---

## 29. Failure and Abandonment Philosophy

This needs to stay strong because it is one of the most interesting parts of the game’s design.

### 29.1 Failure Should Still Matter

A failed mission should:

- update history
- potentially invalidate assumptions
- possibly create irretrievable loss
- shape future offers
- count toward archive pressure when appropriate

### 29.2 Abandonment Should Be Strategic, Not Shameful

Abandonment should sometimes be the correct choice. It should:

- preserve some partial gain if justified
- prevent worse archive loss in some cases
- leave historical marks
- potentially incur separate penalties

### 29.3 Important Rule

Do not structure missions so “abandon” is equivalent to “reload later.” It must be a real strategic action with outcome semantics.

---

## 30. `RETURN_TRANSITION`

This phase requests return to the compound after resolution.

### 30.1 Responsibilities

- package `CampaignOutcome`
- request world transition back to compound
- ensure campaign world remains non-authoritative during return
- await return success/failure

### 30.2 Important Rule

Campaign world teardown should not precede outcome capture, but campaign play must not resume after resolution.

---

## 31. `RETURN_REINTEGRATION`

This is the post-mission recovery layer after the player is back in the compound.

### 31.1 Player Experience

The player has returned to the compound and should be able to:

- see what changed
- understand what was gained or lost
- inspect updated Hub condition
- optionally receive unlock or archive update feedback
- re-enter ordinary compound idle state

### 31.2 Why This Phase Exists

Without reintegration, mission completion can feel abrupt:

- mission ends
- player teleports home
- nothing contextualizes the outcome

This phase gives space for:

- outcome summary
- archive mutation surfacing
- new capability unlock surfacing
- archive-loss warning escalation
- narrative/ambient feedback
- structural or system consequences becoming visible

### 31.3 Exit Condition

Once post-return feedback is complete or dismissed, move to `COMPOUND_IDLE`.

---

## 32. `CAMPAIGN_FAILURE_STATE`

Optional but useful intermediate phase if you want a distinct state before full resolution on mission collapse.

### 32.1 Example Uses

- operator downed state before hard failure
- “all objectives irrecoverable” lock
- mission-critical archive collapse
- extraction no longer possible

### 32.2 Early Implementation Note

This phase can be collapsed directly into `CAMPAIGN_RESOLUTION` at first, but keeping the concept allows later richer failure staging.

---

## 33. `GAME_OVER`

This should exist as a real campaign-loop state.

### 33.1 What Triggers It

Most likely:

- archive loss exceeds tolerance
- unrecoverable persistent failure condition
- explicit campaign-ending event
- terminal doctrinal collapse if later systems warrant it

Existing Hub design already frames archive loss tolerance as a meaningful persistent threshold.

### 33.2 Important Rule

Game over should be a macro-state, not merely a screen overlay. It needs proper relation to:

- final Hub record
- campaign history
- restart/new-Hub initialization
- possible epilogue or archive summary

---

## 34. Required Data Contracts

The Campaign Flow layer should define or consume the following typed objects.

### 34.1 `CampaignSessionState`

```gdscript id="sokfg2"
class_name CampaignSessionState
extends Resource

var campaign_id: String = ""
var scenario_id: String = ""
var current_phase: int = 0
var world_context_type: int = 0

var mission_start_cycle: int = 0
var mission_end_cycle: int = 0

var primary_objective_ids: Array[String] = []
var optional_objective_ids: Array[String] = []
var extraction_required: bool = true
var extraction_unlocked: bool = false
var extraction_completed: bool = false

var completion_ratio: float = 0.0
var abandonment_requested: bool = false
var failure_flags: Array[String] = []
var mission_tags: Array[String] = []
```

This should represent the active transient campaign runtime state from the flow manager’s perspective.

### 34.2 `MissionObjectiveRecord`

```gdscript id="3x9pbt"
class_name MissionObjectiveRecord
extends Resource

var objective_id: String
var objective_type: String
var is_optional: bool = false
var state: int = 0
var current_progress: float = 0.0
var completion_threshold: float = 1.0
var failure_reason: String = ""
var anchor_ids: Array[String] = []
```

### 34.3 `CampaignResolutionSummary`

Optional helper for UI/reintegration display.

```gdscript id="ewmcmw"
class_name CampaignResolutionSummary
extends Resource

var campaign_id: String
var scenario_id: String
var resolution_state: String
var completion_ratio: float
var recovered_knowledge_count: int
var optional_objectives_completed: int
var archive_loss_delta: int
var unlocks_gained: Array[String] = []
var losses_recorded: Array[String] = []
var summary_lines: Array[String] = []
```

---

## 35. Campaign Flow Manager Responsibilities

The `campaign_flow_manager.gd` should own:

### 35.1 Phase Authority

Track and mutate the current phase.

### 35.2 Campaign Session Tracking

Track whether a campaign is active, its IDs, and its current mission progression state.

### 35.3 Integration with Hub Manager

- get active offers
- lock selection
- consume outcome
- reintegrate into compound phase

### 35.4 Integration with World Transition Manager

- request deploy
- request return
- react to transition success/failure

### 35.5 Objective State Ownership

At least at the high level, know whether objectives are active, complete, failed, optional, or extraction-gated.

### 35.6 Failure and Abandonment Handling

Recognize when the mission has transitioned into one of those resolution classes.

### 35.7 Reintegration and Game-Over Routing

Post-return or post-fail macro routing.

---

## 36. Interaction with Compound Systems

The campaign loop must define what the compound is for beyond being a return point.

### 36.1 Required Compound Functions in the Loop

- spawn/orientation space
- terminal/Hub access
- post-mission consequence surface
- optional repair/prep actions
- possibly local resource management later
- doctrinal or archive interaction surfaces later

### 36.2 Important Rule

Do not turn the compound into a dead hallway between menus. It is the embodied anchor of the loop.

---

## 37. Interaction with Mission Runtime

Campaign flow should be able to ask the mission runtime questions such as:

- are all primary objectives complete?
- is extraction required?
- is extraction available?
- has the player triggered abandonment?
- is the mission irrecoverably failed?
- what optional objectives were completed?
- what recoveries were secured?

The flow manager should not hardcode all mission-specific logic, but the mission runtime must export a standard result surface.

---

## 38. Objective and Extraction Contracts

This is worth stating separately.

### 38.1 Required Objective Signals

Recommended signals from mission/objective systems:

```gdscript id="q0s87r"
signal primary_objective_completed(objective_id: String)
signal optional_objective_completed(objective_id: String)
signal mission_failure_triggered(reason: String)
signal extraction_unlocked(anchor_id: String)
signal extraction_completed(anchor_id: String)
signal abandonment_requested()
```

### 38.2 Why This Matters

Without a standard event contract, every mission archetype will start improvising its own completion logic and the macro loop will become brittle.

---

## 39. Save / Load Semantics

Campaign flow is one of the most important save/load surfaces.

### 39.1 Save Requirements

At minimum, save:

- current `CampaignFlowPhase`
- active world context
- current `HubState`
- current `CampaignSessionState` if in mission
- active offer bundle if in compound
- accepted scenario ID if deployment started
- pending resolution summary if return started but not completed

### 39.2 Recommended Early Restriction

As with world transition, avoid allowing saves in the middle of fragile phase boundaries at first. Prefer save points when:

- in `COMPOUND_IDLE`
- in `HUB_REVIEW`
- in stable `CAMPAIGN_ACTIVE`
- after `RETURN_REINTEGRATION` completes

### 39.3 Resume Rule

Resuming a saved game must restore the same macro phase, not reinterpret it heuristically from world context alone.

---

## 40. Determinism Requirements

The repository guidance is explicit about fixed-step determinism and clean separation of simulation from presentation. The campaign loop must preserve that.

### 40.1 Deterministic Requirements

- the same accepted scenario should yield the same campaign-world build inputs
- the same mission progression state should yield the same valid resolution outcomes
- objective completion should not depend on UI frame timing
- reintegration should not mutate Hub state twice

### 40.2 Anti-Patterns to Avoid

- hidden rerolls on mission entry
- phase changes driven directly by animation finish callbacks with no state validation
- recomputing outcome from partially destroyed mission state after teardown
- UI code mutating phase directly

---

## 41. Failure Cases to Guard Against

### 41.1 Boot-to-Combat Regression

Game accidentally still boots straight into wave defense, bypassing compound/Hub flow. The pre-assault walkthrough already identifies this as a structural problem to solve.

### 41.2 Mission Without Reintegration

Player returns home but sees no clear consequence or mutation presentation.

### 41.3 Scenario Acceptance Drift

Player selects mission, deploy fails, offer is consumed incorrectly, and state becomes inconsistent.

### 41.4 Extraction Collapse

Mission objectives complete but no extraction path/state exists.

### 41.5 False Binary Resolution

Partial progress gets lost because the system only knows win/lose.

### 41.6 Compound Devaluation

Home base becomes a glorified menu layer with no physical role.

### 41.7 Double Outcome Application

Campaign outcome mutates the Hub twice due to reintegration/load bug.

### 41.8 World/Flow Desync

World context says compound while flow phase still says campaign active.

---

## 42. Recommended Build Order

### Phase 1 — Core Macro State Machine

- define `CampaignFlowPhase`
- implement `campaign_flow_manager.gd`
- support `BOOT -> COMPOUND_IDLE -> HUB_REVIEW -> COMPOUND_IDLE`

### Phase 2 — Hub Selection to Deploy

- integrate selected `CampaignScenario`
- implement `HUB_SELECTION_LOCK`
- request deployment transition

### Phase 3 — Mission Entry and Active Runtime

- implement `CAMPAIGN_ENTRY`
- bind objective tracking
- enter `CAMPAIGN_ACTIVE`

### Phase 4 — Resolution Logic

- detect objective completion/failure/abandonment
- build `CampaignOutcome`
- enter `CAMPAIGN_RESOLUTION`

### Phase 5 — Return and Reintegration

- request return transition
- apply Hub mutation
- implement `RETURN_REINTEGRATION`
- return to `COMPOUND_IDLE`

### Phase 6 — Game Over and Advanced Cases

- archive-loss-driven fail state
- richer reintegration
- optional multi-stage missions and compound prep gating

---

## 43. Recommended File Targets

```plaintext id="knx0od"
custodian/core/systems/campaign/campaign_flow_manager.gd
custodian/core/systems/campaign/campaign_session_state.gd
custodian/core/systems/campaign/mission_objective_record.gd
custodian/core/systems/campaign/campaign_resolution_summary.gd
```

Likely integration touch points:

```plaintext id="xe2qtw"
custodian/core/systems/hub/hub_manager.gd
custodian/core/systems/hub/knowledge_system.gd
custodian/core/systems/world/world_transition_manager.gd
custodian/core/systems/region/region_generator.gd
custodian/scenes/ui.gd
custodian/scenes/game.tscn
```

---

## 44. Acceptance Criteria

This file is complete when all of the following are true.

### Macro Loop

- [ ] game boots into a stable compound phase
- [ ] player can access Hub from compound
- [ ] player can review and select offers
- [ ] accepted offer leads into deployment
- [ ] mission runtime enters active campaign phase
- [ ] mission can resolve into outcome
- [ ] player returns to compound
- [ ] Hub mutation is visible on return

### Phase Authority

- [ ] `CampaignFlowPhase` is authoritative and queryable
- [ ] world context and flow phase do not drift
- [ ] invalid phase transitions are blocked

### Outcome Diversity

- [ ] full success supported
- [ ] partial success supported
- [ ] failure supported
- [ ] abandonment supported

### Compound Role

- [ ] compound is a real home-state layer, not just a menu wrapper
- [ ] post-mission reintegration exists

### Persistence

- [ ] save/load can restore macro phase correctly
- [ ] accepted scenarios and outcomes do not duplicate or disappear

---

## 45. Exit Condition

This file is done when you can:

1. boot into the compound,
2. enter the Hub,
3. choose a mission,
4. deploy into a campaign region,
5. complete, partially complete, fail, or abandon that mission,
6. return to the compound,
7. see the persistent consequences applied,
8. and then continue into the next cycle from a stable `COMPOUND_IDLE` state.

That is the minimum viable Campaign Flow and Game Loop.

---

# Progress Tracking

## Completed Files

- [1] Runtime World & Camera Stabilization
- [2] Hub System (Meta Progression)
- [3] World Transition System
- [4] Region Generation System
- [5] Compound Tile System
- [6] Campaign Flow & Game Loop

## Still To Go

- [7] Integration Contract (Glue Layer)
