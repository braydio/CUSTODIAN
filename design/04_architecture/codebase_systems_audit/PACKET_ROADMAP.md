# CUSTODIAN · Codebase Systems Audit Packet Roadmap

[← Overview / index](../CODEBASE_SYSTEMS_AUDIT.md)

> **State:** conceptual packet registry only, **not an implementation queue**. Baseline `main@e089e8b8a099`, October 8, 2026. All new slot decisions **unlocked**; **zero task packets created** by this audit. F03 expanded from 2 to 8 conceptual slices on October 8, 2026, without authorization.
>
> **F03 audit refresh:** source inspection on `main@ac87c8ad`; eight proposed F03 slots, none executable. Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
>
> An item-level audit and locked decision are mandatory before authoring ANY new packet. Existing packets listed below already belong to their own separate authority/DAG and remain unaffected.

## Registry rules
1. Review the linked [focus detail](../CODEBASE_SYSTEMS_AUDIT.md#focus-item-index). Complete callsite and runtime audit, list confirmed/disproved findings, and record chosen behavioral owner plus invariants.
2. Lock the decision and user-owned artistic/feature choices in that focus file. An explicit **no refactor** or **existing work owns it** decision is valid.
3. Verify live `main`, dependencies and current canonical design; detect duplicate coverage from existing packets.
4. Only then author the necessary `custodian.task_packet.v2` packet with exact behavior/owner/non-goals, named focused validation and a fresh reviewer pair if needed. Update packet index and existing roadmap rather than producing a competing series.
5. Replace the conceptual slot with an actual `blob/main/...` file link **only after it exists**. This document is not dispatch authority.

## Existing-program protection
- Operator: existing F1/F2/F3/F5/F6/G program. No parallel actor decomposition.
- Procgen: active V1, generator/placement, performance and V2 authoring program. No third speculative DAG.
- NPA: existing Marine/Savage→shared-actor sequence and refresh gates.
- Hub/death: existing H-series plus R1/R2, exactly-once outcome and reintegration.
- Agent tooling: existing dispatcher/review/queue-hardening rules take precedence.

## Proposed slots (not files, not assigned/claimable)

**F01: [Operator runtime and combat](F01_OPERATOR_COMBAT.md)**

### CS-F01-A
- **Intent:** Post-extraction Operator ownership/debt verification, only if existing Slice G does not close evidence gaps.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_OPERATOR_POST_G_VERIFY.md` (**not created**, not a link to a file).
- **Authorization:** BLOCKED pending F01 item-level audit, evidence and explicit decision lock.
- **Do not implement before:** Existing Operator program and its current review gates; do not bypass queued F1–F6/G.

**Existing related packets:** [`OPERATOR_LOADOUT_DOMAIN_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_LOADOUT_DOMAIN_EXTRACTION.md), [`OPERATOR_MELEE_DOMAIN_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_MELEE_DOMAIN_EXTRACTION.md), [`OPERATOR_RANGED_DOMAIN_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_RANGED_DOMAIN_EXTRACTION.md), [`OPERATOR_INTERACTION_DOMAIN_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_INTERACTION_DOMAIN_EXTRACTION.md), [`OPERATOR_RECOVERY_DOMAIN_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_RECOVERY_DOMAIN_EXTRACTION.md), [`OPERATOR_RUNTIME_SHELL_COLLAPSE`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_RUNTIME_SHELL_COLLAPSE.md).


**F02: [Procedural generation and Contract-world installation](F02_PROCGEN_WORLD_INSTALLATION.md)**

### CS-F02-A
- **Intent:** Cross-boundary generation→placement→realization parity audit after existing contractions, only if gaps survive.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_WORLD_HANDOFF_PARITY.md` (**not created**, not a link to a file).
- **Authorization:** BLOCKED pending F02 item-level audit, evidence and explicit decision lock.
- **Do not implement before:** Existing procgen V1, placement P-series, D-series and review gates; no speculative owner/API cutover.

**Existing related packets:** [`PROCGEN_TILEMAP_FACADE_CONTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/PROCGEN_TILEMAP_FACADE_CONTRACTION.md), [`PROCGEN_GENERATION_DATA_MODEL_AUDIT`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/PROCGEN_GENERATION_DATA_MODEL_AUDIT.md), [`PROCGEN_AUTHORED_CLAIM_REGISTRY_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/PROCGEN_AUTHORED_CLAIM_REGISTRY_EXTRACTION.md), [`CONTRACT_WORLD_LOADER_CONTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/CONTRACT_WORLD_LOADER_CONTRACTION.md), [`PROCGEN_RENDER_ATTRIBUTION_V1`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/PROCGEN_RENDER_ATTRIBUTION_V1.md), [`PROCGEN_RUNTIME_OPTIMIZATION_V2_SERIES_AUTHORING`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/PROCGEN_RUNTIME_OPTIMIZATION_V2_SERIES_AUTHORING.md).


**F03: [HUD, terminal and command UI](F03_HUD_TERMINAL_UI.md)**

> **F03 diagnostic status:** source-level ownership audit captured on `main@ac87c8ad`; execution still unapproved. All eight slots below are CONCEPTUAL, not task-packet files. Source-of-truth and test gaps are in [F03](F03_HUD_TERMINAL_UI.md). The July [terminal design audit](../../02_features/terminal/TERMINAL_DESIGN_AUDIT.md) already contains an early registry-extraction proposal; preserve and reconcile that work.

### CS-F03-A
- **Intent:** Canonical command schema and behavior-parity inventory, including help/completion/validation/refresh/confirmation and negative cases.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_HUD_TERMINAL_COMMAND_SEAM.md` (**not created**).
- **Gate:** F03 decision lock; current parser and July verified-audit corrections reconciled.
- **Acceptance sketch:** stable command-action table and targeted tests that can fail independently of the CanvasLayer.

### CS-F03-B
- **Intent:** Extract navigation and read-only command handlers from the HUD legacy interpreter.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_TERMINAL_NAVIGATION_COMMANDS.md` (**not created**).
- **Gate:** A passes; avoid creating a second page/navigation authority.
- **Acceptance sketch:** exact existing page/fidelity/transcript behavior on both valid and invalid commands.

### CS-F03-C
- **Intent:** Migrate power, repair, assault, turret and other world-mutating command adapters onto existing simulation authority calls, with explicit result contracts.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_TERMINAL_WORLD_ACTIONS.md` (**not created**).
- **Gate:** B and target authority inventory; never implement gameplay rules in HUD/router.
- **Acceptance sketch:** one effect per command, preserved guards and errors, no direct gameplay writes in presenters.

### CS-F03-D
- **Intent:** Fabrication and ARRN domain-command parity, including clickable actions and placement follow-through.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_TERMINAL_DOMAIN_COMMANDS.md` (**not created**).
- **Gate:** C and live FabPipeline/ARRN validation ownership.
- **Acceptance sketch:** terminal buttons and text commands produce equivalent outcomes; no duplicate resources or extra privileges.

### CS-F03-E
- **Intent:** Conditional command-buffer scheduling correction and lifecycle hardening (not assumed necessary).
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_TERMINAL_COMMAND_SCHEDULING.md` (**not created**).
- **Gate:** F03 explicit decision on UI-time vs simulation-tick admission; A's parity fixtures.
- **Acceptance sketch:** determinism, ordering, pause/rate/close/reopen and replay behavior meet a locked contract.

### CS-F03-F
- **Intent:** Cohesive screen-state/projection consolidation, preserving existing snapshots, Overview/Fabrication/Sensors view models, fidelity and thirteen-page design.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_HUD_VIEWMODEL_CONTRACTION.md` (**not created**).
- **Gate:** B–D and full caller matrix; F07 inventory remains separate.
- **Acceptance sketch:** reduced state ownership in HUD and identical layout, links, selection, navigation, scroll and focus.

### CS-F03-G
- **Intent:** Debug/HUD shell ownership disentanglement, removal of proved-obsolete compatibility glue, and final CanvasLayer facade contraction.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_HUD_SHELL_CONTRACTION.md` (**not created**).
- **Gate:** F; compare actual use of `custodian_hud.gd` and scene consumers before deleting anything.
- **Acceptance sketch:** fewer mutable domains and external call paths in `ui.gd`; no lost HUD/console functionality.

### CS-F03-H
- **Intent:** Source/runtime parity, focused Godot validation, regression/performance measurement and documentation closeout.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_HUD_TERMINAL_CLOSEOUT.md` (**not created**).
- **Gate:** all actually authorized predecessor slices complete; E only if approved.
- **Acceptance sketch:** literal live-scene command, modal, focus, keyboard and representative controller checks; before/after measured debt, manifest/document reconciliation.

**Existing related documentation / historical packets:** [COMMAND_TERMINAL_SPEC](../../02_features/terminal/COMMAND_TERMINAL_SPEC.md) (active authority), [TERMINAL_AUDIT_VERIFICATION](../../02_features/terminal/TERMINAL_AUDIT_VERIFICATION.md) (July corrections), [TERMINAL_INPUT_FOCUS_FIX](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/TERMINAL_INPUT_FOCUS_FIX.md) (complete historical packet), [UI_GD_FIXES](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/UI_GD_FIXES.md) (stale `in_progress` metadata needing triage). No new F03 implementation packet has been authorized.


**F04: [Enemy and non-player actor runtime](F04_NON_PLAYER_ACTORS.md)**

### CS-F04-A
- **Intent:** NPA closure verification, only if NPA-11 leaves uncovered shared-actor contracts.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_NPA_CLOSURE_VERIFY.md` (**not created**, not a link to a file).
- **Authorization:** BLOCKED pending F04 item-level audit, evidence and explicit decision lock.
- **Do not implement before:** NPA predecessor review and authoring-chat gates remain authoritative.

**Existing related packets:** [`ENEMY_SAVAGE_POUNCE_ABILITY_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/ENEMY_SAVAGE_POUNCE_ABILITY_EXTRACTION.md), [`ENEMY_SAVAGE_CHAIN_ABILITY_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/ENEMY_SAVAGE_CHAIN_ABILITY_EXTRACTION.md).


**F05: [Authored level and encounter coordinators](F05_AUTHORED_LEVEL_RUNTIME.md)**

### CS-F05-A
- **Intent:** Representative authored-level owner and state-map extraction, only after level seams are audited.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_AUTHORED_LEVEL_OWNER_CONTRACT.md` (**not created**, not a link to a file).
- **Authorization:** BLOCKED pending F05 item-level audit, evidence and explicit decision lock.
- **Do not implement before:** Coordinate with existing Hub/Ash-Bell/Bridged Falls and route-transition series; preserve bespoke narratives.

**Existing related packets:** none assigned; check live queue on audit completion.


**F06: [Campaign, Hub, continuity, death and recovery](F06_CAMPAIGN_DEATH_RECOVERY.md)**

### CS-F06-A
- **Intent:** Cross-series outcome/death-return adversarial integration audit, only if H7/R2 do not already cover it.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_CAMPAIGN_RETURN_ADVERSARIAL.md` (**not created**, not a link to a file).
- **Authorization:** BLOCKED pending F06 item-level audit, evidence and explicit decision lock.
- **Do not implement before:** H2–H7, R1/R2 review and persistent-recovery progression are existing source of truth.

**Existing related packets:** [`HUB_AWAKENING_CONTEXT_HANDOFF`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/HUB_AWAKENING_CONTEXT_HANDOFF.md), [`HUB_CAMPAIGN_RETURN`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/HUB_CAMPAIGN_RETURN.md), [`HUB_FIRST_SET_INTEGRATION_CLOSEOUT`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/HUB_FIRST_SET_INTEGRATION_CLOSEOUT.md), [`CUSTODIAN_POST_RECOVERY_REINTEGRATION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/CUSTODIAN_POST_RECOVERY_REINTEGRATION.md).


**F07: [Inventory and equipment UI](F07_INVENTORY_EQUIPMENT_UI.md)**

### CS-F07-A
- **Intent:** Inventory equipment transaction boundary and view-model reconciliation.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_INVENTORY_EQUIPMENT_SEAM.md` (**not created**, not a link to a file).
- **Authorization:** BLOCKED pending F07 item-level audit, evidence and explicit decision lock.
- **Do not implement before:** Operator F1 and current inventory/registration authority; no UI-driven duplicate equipment simulation.

**Existing related packets:** [`OPERATOR_LOADOUT_DOMAIN_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_LOADOUT_DOMAIN_EXTRACTION.md).


**F08: [Power, fabrication, defense and logistics](F08_INFRASTRUCTURE_SYSTEMS.md)**

### CS-F08-A
- **Intent:** Cross-system infrastructure command and state ownership correction, only if concrete duplicates are found.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_INFRASTRUCTURE_COMMAND_CONTRACT.md` (**not created**, not a link to a file).
- **Authorization:** BLOCKED pending F08 item-level audit, evidence and explicit decision lock.
- **Do not implement before:** Existing power/build/repair contracts and Operator interaction extraction; gameplay values unchanged during audit.

**Existing related packets:** none assigned; check live queue on audit completion.


**F09: [Vehicle runtime, class identity and driving feel](F09_VEHICLES.md)**

### CS-F09-A
- **Intent:** Vehicle handling feel prototype and measurable acceptance, pending playtest/design lock.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_VEHICLE_HANDLING_FEEL.md` (**not created**, not a link to a file).
- **Authorization:** BLOCKED pending F09 item-level audit, evidence and explicit decision lock.
- **Do not implement before:** Recent vehicle lifecycle implementation remains authoritative; no new classes/asset families preapproved.

**Existing related packets:** none assigned; check live queue on audit completion.


**F10: [Camera, streaming and environmental presentation](F10_CAMERA_STREAMING_ENVIRONMENT.md)**

### CS-F10-A
- **Intent:** Cross-context camera follow/presentation handoff correction, only if runtime failures are confirmed.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_CAMERA_HANDOFF.md` (**not created**, not a link to a file).
- **Authorization:** BLOCKED pending F10 item-level audit, evidence and explicit decision lock.
- **Do not implement before:** Existing procgen render attribution and current camera/Archive Resolve authorities.

**Existing related packets:** [`PROCGEN_RENDER_ATTRIBUTION_V1`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/PROCGEN_RENDER_ATTRIBUTION_V1.md).


**F11: [Agent execution, validation and paired review handoff](F11_AGENT_VALIDATION_AUTOMATION.md)**

### CS-F11-A
- **Intent:** External reviewer-launch/supervision and bounded successor-loop feasibility proof.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_AUTONOMOUS_REVIEW_RUNNER.md` (**not created**, not a link to a file).
- **Authorization:** BLOCKED pending F11 item-level audit, evidence and explicit decision lock.
- **Do not implement before:** P0 queue-stranding correction plus existing dispatch/review contracts; implementation only after worker interface lock.

**Existing related packets:** [`TASK_PACKET_QUEUE_STRANDING_HARDENING`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/TASK_PACKET_QUEUE_STRANDING_HARDENING.md).


**F12: [Cross-system game-feel opportunities](F12_GAME_FEEL.md)**

### CS-F12-A
- **Intent:** Combat impact/telegraph feel proof, only after baseline and acceptance lock.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_COMBAT_FEEL_VERTICAL_SLICE.md` (**not created**, not a link to a file).
- **Authorization:** BLOCKED pending F12 item-level audit, evidence and explicit decision lock.
- **Do not implement before:** Subjective presentation approval and observed before/after evidence; don't replace existing Operator packet scope.

**Existing related packets:** [`OPERATOR_MELEE_DOMAIN_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_MELEE_DOMAIN_EXTRACTION.md), [`OPERATOR_RANGED_DOMAIN_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_RANGED_DOMAIN_EXTRACTION.md), [`OPERATOR_INTERACTION_DOMAIN_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_INTERACTION_DOMAIN_EXTRACTION.md).


**F13: [New-feature return on investment](F13_FEATURE_ROI.md)**

### CS-F13-A
- **Intent:** Differentiated Contract objectives design and vertical-slice feasibility, only after H7.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_CONTRACT_OBJECTIVES.md` (**not created**, not a link to a file).
- **Authorization:** BLOCKED pending F13 item-level audit, evidence and explicit decision lock.
- **Do not implement before:** Functional H7, live mission-loop evidence and explicit player-experience scope lock.

**Existing related packets:** [`HUB_FIRST_SET_INTEGRATION_CLOSEOUT`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/HUB_FIRST_SET_INTEGRATION_CLOSEOUT.md).

**F14: [Living-world simulation, interest management and unloaded-sector continuity](F14_LIVING_WORLD_SIMULATION.md)**

> **Status:** P0 AUDIT FOCUS, NOT LOCKED. **Read-only local characterization received: six focused Godot runs reported passing; no unloaded actor continuity test exists in that set.** The first diagnostic purpose of CS-F14-A is fulfilled by this receipt and should not generate a duplicate agent packet. Remaining slots are conceptual and non-executable. See [F14 local evidence and gaps](F14_LIVING_WORLD_SIMULATION.md). F15 owns stable geographic location identity.

### CS-F14-A
- **Intent:** Characterize interest tier, macro clock, actor serialization/identity, streaming, history, and current load/unload parity; profile baseline.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_WORLD_SIMULATION_HANDOFF_BASELINE.md` (**not created**).
- **Status:** READ-ONLY EVIDENCE FULFILLED by user-supplied local audit, 2026-10-08 (six reported passing runs). **Do not create a duplicate implementation packet.**
- **Remaining optional scope:** New tests only for actual descendant/noise processing and real unload/re-entry identity behavior, if those tests are selected during F14 decision lock. No claimed runtime reification proof.
- **Acceptance sketch:** exact current ownership map and falsifiable gap list, no new implementation or duplicate system.

### CS-F14-B
- **Intent:** Create the smallest deterministic, sector-scoped abstract-activity model for unloaded areas only where existing macro owners cannot serve.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_SECTOR_ACTIVITY_FOUNDATION.md` (**not created**).
- **Gate:** A's baseline report accepted as evidence (not as implementation), explicit abstract state/schema/tick and **F15 geographic location-ID interface** lock; reuse current `WorldSimulationRuntime` and `SimulationKernel`. Initial synthetic two-location unit proof need not wait for full world art/procgen expansion.
- **Acceptance sketch:** inactive sector changes reproducibly without loading scene; no autonomous second clock or parallel resource owner.

### CS-F14-C
- **Intent:** Stable entity/group identity and active↔abstract representation handoff with no duplicate spawn or identity reset.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_ENTITY_REIFICATION_HANDOFF.md` (**not created**).
- **Gate:** accepted baseline report, B (if authorized), NPA/procgen scene lifecycle, **F15 stable geographic identity**, and exact reentry/state-ownership contract. Do not conflate presentation chunk unload with actor unload.
- **Acceptance sketch:** deterministic loaded/unloaded crossings preserving consequences, goals and counts; no disabled physical actor still secretly doing loaded actions.

### CS-F14-D
- **Intent:** Durable, causally interpretable world history and save/restart reconciliation only where not already covered by REMAP-3.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_LIVING_WORLD_PERSISTENCE_INTEGRATION.md` (**not created**).
- **Gate:** existing REMAP-3 campaign persistence / Hub and route-state ownership; no independent competing disk persistence authority.
- **Acceptance sketch:** deterministic continuation and one outcome for each real event after restore, observability reasons.

### CS-F14-E
- **Intent:** Two-geographic-location living-world vertical slice, with active/inactive return, causal history, failure cases, perf budgets and docs closeout. Facility macro sector IDs are not geographic regions.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_LIVING_WORLD_PROOF_CLOSEOUT.md` (**not created**).
- **Gate:** all *actually approved* F14 predecessors; no hypothetical tasks treated as dependencies.
- **Acceptance sketch:** observer can leave one sector, encounter a meaningful repeatable change on return, and inspect the event cause; no duplicate actors; focused Godot regression suite green.

**Existing related authorities (do not duplicate):** [Interest Management spec](../../01_systems/INTEREST_MANAGEMENT_SYSTEM.md); [Sector Activity Simulator candidate](../../90_codex/simulation/sector_activity_simulator.md); [Godot macro simulation migration](../PYTHON_SIM_TO_GODOT_MIGRATION.md) and [REMAP tracker](../PYTHON_SIM_REMAP_TRACKER.md); F02 world installation, F04 NPA, F06 campaign, F08 infrastructure. Existing queue rights/review gates remain unchanged.


**F15: [Campaign-World Geographic Scale, Topology and Traversable Domain](F15_CAMPAIGN_WORLD_GEOGRAPHY.md)**

> New P0 **design/audit** focus. [Discussion draft](../CAMPAIGN_WORLD_GEOGRAPHY_AND_TOPOLOGY.md) records user intent for one broad explorable campaign geography, but does **not** lock infinite maps, numeric world sizes or rewrite existing Hub/Lattice/Procgen owners. These are NOT implementation packets.

### CS-F15-A
- **Intent:** Current finite-world scale and wayfinding benchmark, canonical Hub/Port/Domain terms, local procgen vs global geography owner map and three architectural alternatives evaluated.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_CAMPAIGN_WORLD_SCALE_AND_TOPOLOGY_EVIDENCE.md` (**not created**).
- **Authorization:** BLOCKED pending F15 item-level evidence/decision lock and current F02 procgen authority check.
- **Acceptance sketch:** fixed seeds, live traversal/time/density/biome measures, region/route API trace, clear old-doc drift disposition; no geometry rewrite.

### CS-F15-B
- **Intent:** Deterministic macro geographic backbone / stable location IDs and coherent route, water, biome-edge, settlement and domain-boundary metadata; preserve current procgen runtime ownership.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_CAMPAIGN_WORLD_GEOGRAPHIC_BACKBONE.md` (**not created**).
- **Authorization:** BLOCKED pending A, explicit player-scale/extent/scene-seam choice, active GenerationGrid/procgen stage and one geographic data owner. May instead integrate with an existing procgen program packet.
- **Acceptance sketch:** stable topology and boundary test without creating a huge TileMap, renderer authority or new persistence silo.

### CS-F15-C
- **Intent:** One-campaign connected traversal proof across multiple distinct localities with a meaningful intervening landscape, persistent campaign identity, stable re-entry and readable geography.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_CAMPAIGN_WORLD_CONNECTED_TRAVERSAL_PROOF.md` (**not created**).
- **Authorization:** BLOCKED pending architecture review, B or approved existing topology owner, RouteTraversal/WorldTransition/Operator ingress and F14 identity integration decisions.
- **Acceptance sketch:** traverse two nonadjacent sites and one biome transition **without ending the accepted campaign**, preserve route/world state and Operator, validate perf/deterministic seed/seam, human review of wayfinding, no mandatory new assets.

**Preexisting authority:** [Lattice Doctrine](../../03_world/LATTICE_DOCTRINE.md), [Hub First Set Blockout](../HUB_FIRST_SET_BLOCKOUT.md), [World Transition](../WORLD_TRANSITION_SYSTEM.md), [Region Generation](../REGION_GENERATION_SYSTEM.md), [Procgen Optimization Roadmap](../../02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md), F02 procgen and F14 unloaded-world activity. No new art family or task-packet DAG has been authorized.


## Promotion checklist for each slot
- [ ] Current `main` and relevant active design/AGENTS reviewed.
- [ ] Finding ID, evidence/callsite, measured before-state and severity recorded in focus doc.
- [ ] Duplicates, alternative owners, and 'no change' option considered.
- [ ] Human-owned design, gameplay feel and/or art decisions made explicitly where material.
- [ ] One clear owner, preserved contracts and exact non-goals locked.
- [ ] Existing queue packets checked; merge scope into existing owner if applicable.
- [ ] Focused falsification, regression and independent review requirements specified.
- [ ] Packet authoring approved; only then make new file, run authoring/queue validators, and update links.

## Future autonomous program boundary
The eventual long-running controller is **not** authorized by this audit. It should orchestrate already-authorized small packets through existing dispatch → isolated implementation → finish/land → separately launched fresh-context review → pass or bounded correction/re-review → exact named successor, while stopping on user/ChatGPT decisions. [F11](F11_AGENT_VALIDATION_AUTOMATION.md) must prove actual process-level reviewer handoff rather than inferring it from repository instructions.
