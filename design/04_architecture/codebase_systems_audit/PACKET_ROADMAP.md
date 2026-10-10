# CUSTODIAN · Codebase Systems Audit Packet Roadmap

[← Overview / index](../CODEBASE_SYSTEMS_AUDIT.md)

> **State:** audit roadmap and registry, **not implementation dispatch authority**. Initial baseline `main@e089e8b8a099` (2026-10-08), reconciled with F14-B + R0-01 landed correction and F11 locked runner (2026-10-09). Proposed slots remain conceptual unless explicitly linked to an authorized real packet. F03 expanded to eight unapproved slots; **F11 and F14-B have real packet workstreams**, not zero.
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
- **Intent:** External paired-review launch/supervision using fresh Codex Exec contexts while preserving the existing dispatcher/workstream/review lineage.
- **Status:** **AUTHORIZED / PACKET AUTHORED** by the F11 decision lock on 2026-10-09.
- **Implementation packet:** [`CODEBASE_AUDIT_AUTONOMOUS_REVIEW_RUNNER.md`](../../../custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_AUTONOMOUS_REVIEW_RUNNER.md).
- **Paired review:** [`REVIEW_CODEBASE_AUDIT_AUTONOMOUS_REVIEW_RUNNER.md`](../../../custodian/docs/ai_context/task_packets/REVIEW_CODEBASE_AUDIT_AUTONOMOUS_REVIEW_RUNNER.md).
- **Dependency satisfied:** queue-stranding hardening and its correction/re-review chain are archived complete.
- **Boundary:** synchronous wrapper above `workstream.py finish`; exact paired-review successor only; `codex exec --ephemeral`; no replacement queue, no daemon, no implicit global queue hopping.

**Existing related packets:** archived `TASK_PACKET_QUEUE_STRANDING_HARDENING*`, `AGENT_REVIEW_PIPELINE*`, `AGENT_DISPATCH_CLAIM_RECEIPT_HARDENING`, and active `ULTRA_CODEX_PACKET_WORKER` remain separate authority.


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

> **Status:** F14 V1 **BOUNDED** behavior locked; baseline evidence fulfilled. **F14-B plus R0-01 correction and a distinct fresh correction re-review all archived/accepted** (`main@7d9fe1872361`, zero findings). **F14-C1 one-real-Enemy synthetic A/B ownership handoff** is implemented, corrected and independently re-reviewed PASS (R0-01/02/03 fixed; no new findings). Production F14-C2 geographic residency and D/E remain unapproved. See [F14 acceptance/C1 lock](F14_LIVING_WORLD_SIMULATION.md) and [F15 geography](F15_CAMPAIGN_WORLD_GEOGRAPHY.md).

### CS-F14-A
- **Intent:** Characterize interest tier, macro clock, actor serialization/identity, streaming, history, and current load/unload parity; profile baseline.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_WORLD_SIMULATION_HANDOFF_BASELINE.md` (**not created**).
- **Status:** READ-ONLY EVIDENCE FULFILLED by user-supplied local audit, 2026-10-08 (six reported passing runs). **Do not create a duplicate implementation packet.**
- **Remaining optional scope:** New tests only for actual descendant/noise processing and real unload/re-entry identity behavior, if those tests are selected during F14 decision lock. No claimed runtime reification proof.
- **Acceptance sketch:** exact current ownership map and falsifiable gap list, no new implementation or duplicate system.

### CS-F14-B
- **Status:** **IMPLEMENTATION/REVIEWS/CORRECTION ALL ARCHIVED; R0-01 FIXED AND INDEPENDENTLY PASSED.** Foundation adds deterministic synthetic geographic-group activity, schema v5 with v4 migration and length-prefixed event IDs with legacy schema-v5 reader compatibility. It does not implement physical handoff/reification, production map binding, combat or disk persistence.
- **Implementation evidence:** [archived F14-B](../../../custodian/docs/ai_context/task_packets/archived/LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION.md) · [archived first review](../../../custodian/docs/ai_context/task_packets/archived/REVIEW_LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION.md) · [archived R0-01 correction](../../../custodian/docs/ai_context/task_packets/archived/LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION_REVIEW_CORRECTIONS_1.md) · [archived independent correction re-review PASS](../../../custodian/docs/ai_context/task_packets/archived/REVIEW_LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION_REVIEW_CORRECTIONS_1.md).
- **Intent:** Add a small deterministically stepped, serializable offscreen group model using stable synthetic geographic IDs and existing `SimulationKernel` 60-fixed-tick macro cadence; prove one uninstantiated patrol produces a bounded causal state change and snapshot continuation.
- **Lock:** user approved Bounded offscreen simulation. Foundation does **not** include physical→abstract handoff, combat casualties, procgen infinite world or REMAP-3 persistence. First review exposed a snapshot-restore defect; bounded correction and fresh independent re-review both passed. No outstanding B blocker.
- **Acceptance sketch:** state-only B evolves while uninstantiated with reproducible event/snapshot, identity conserved, same-seed repeated run and legacy snapshot read green. No independent clock, actor double-spawn or parallel materials authority.

### CS-F14-C

- **C1: IMPLEMENTED / CORRECTED / INDEPENDENTLY RE-REVIEWED PASS.** [Archived implementation](../../../custodian/docs/ai_context/task_packets/archived/LIVING_WORLD_ENTITY_REIFICATION_HANDOFF.md), [initial review](../../../custodian/docs/ai_context/task_packets/archived/REVIEW_LIVING_WORLD_ENTITY_REIFICATION_HANDOFF.md), [correction](../../../custodian/docs/ai_context/task_packets/archived/LIVING_WORLD_ENTITY_REIFICATION_HANDOFF_REVIEW_CORRECTIONS_1.md), [fresh re-review PASS](../../../custodian/docs/ai_context/task_packets/archived/REVIEW_LIVING_WORLD_ENTITY_REIFICATION_HANDOFF_REVIEW_CORRECTIONS_1.md); R0-01/02/03 fixed, zero new findings. Real Grunt synthetic A/B handoff, stable ActorId+GroupId, health/intent, repeated crossings, fixed-boundary authority and old schema-v5 restore are proved. **Not a production geographic or ambient-spawner integration.**
- **C2: NOT AUTHORIZED, design slots only.** [F14-C2/F15 production planning refresh](../F14_C2_F15_PRODUCTION_GEOGRAPHY_AND_RESIDENCY_REFRESH.md) separates C2a actor/camp-spawner logical slot reservation from C2b production locality scene-residency → C1 coordinator transaction.
- **C2a proposed** `living-world-population-slot-reservations`: durable ActorId + GroupId reservation, reconcile queued pending ambient spawns/camp reactivation, no duplicate restored Grunt, unmanaged ambient unaffected; requires accepted C1 and approved F15 location address mapping.
- **C2b proposed** `living-world-locality-residency-binding`: real local scene unload/reenter and domain-location keyed safe anchors request physical↔abstract handoff at a canonical fixed boundary; failures rollback/pin resident; requires F15-B, C2a, active F02 scene/route APIs.
- **Next:** F15-A read-only geography, route and physical scene-residency evidence; lock real Domain/Location owner **before** making either C2 packet executable. Archive Resolve/M6 visual chunks do not unload actors.

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

> User **locked Continuous geography as the player-facing campaign traversal target**, and **Ports/vehicles as major travel infrastructure** (2026-10-09). Mountain passes are ordinary traversable geography, not cutscenes by default; Archive Resolve is visual presentation only and does not supply new world-scale generation. [Decision and draft](../CAMPAIGN_WORLD_GEOGRAPHY_AND_TOPOLOGY.md) do **not** yet lock macro topology, numeric sizes, infinite extent or F15 implementation. F15-A/B/C remain conceptual and not claimable; [production residency design refresh](../F14_C2_F15_PRODUCTION_GEOGRAPHY_AND_RESIDENCY_REFRESH.md) records alternatives and the gated execution order. Keep existing F09 vehicle-series ownership.

### CS-F15-A
- **Intent:** Current finite-world scale and wayfinding benchmark, canonical Hub/Port/Domain terms, local procgen vs global geography owner map and three architectural alternatives evaluated.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_CAMPAIGN_WORLD_SCALE_AND_TOPOLOGY_EVIDENCE.md` (**not created**).
- **Authorization:** Proposed **read-only next audit slice**, not yet claimable. Confirm no duplicate active F02/F15 audit; local fixed-seed measurements and actual region/scene lifecycle mapping still required.
- **Acceptance sketch:** fixed-seed current Operator travel/camera/landmark/biome and existing Scout route measurements, actual route stage/rollback and camp spawn queue inspection, verified Domain/Location/Route/Scene/Chunk identity map, comparison of finite graph-backed versus enlarged one-map versus expandable alternatives, and concrete doc drift disposition. No geometry rewrite.

### CS-F15-B
- **Intent:** Deterministic macro geographic backbone / stable location IDs and coherent route, water, biome-edge, settlement and domain-boundary metadata; preserve current procgen runtime ownership.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_CAMPAIGN_WORLD_GEOGRAPHIC_BACKBONE.md` (**not created**).
- **Authorization:** BLOCKED pending F15-A evidence, explicit player-scale/extent/scene-seam decision, current procgen/generation authority and single durable `(domain_id, location_id)` owner. Reuse existing F02 work if it covers the same seam.
- **Acceptance sketch:** stable topology and boundary test without creating a huge TileMap, renderer authority or new persistence silo.

### CS-F15-C
- **Intent:** One-campaign connected traversal proof across multiple distinct localities with a meaningful intervening landscape, persistent campaign identity, stable re-entry and readable geography.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_CAMPAIGN_WORLD_CONNECTED_TRAVERSAL_PROOF.md` (**not created**).
- **Authorization:** BLOCKED pending architecture review, B or approved existing topology owner, RouteTraversal/WorldTransition/Operator ingress and F14 identity integration decisions.
- **Acceptance sketch:** traverse two nonadjacent sites and one biome transition **on foot, continuously within the accepted campaign** (no ordinary mountain-pass cutscene); preserve route/world state and Operator; validate deterministic geographic seams, streamed semantics and Archive Resolve **presentation-only** continuity. Following the existing Field Scout/recovery/Asset V2 dependency chain, run an independent **vehicle-assisted long-route** proof preserving vehicle, Operator and route identity, not a duplicate vehicle controller. No new F15 assets until the visual grammar is approved.

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
