# CUSTODIAN · Codebase Systems Audit Packet Roadmap

[← Overview / index](../CODEBASE_SYSTEMS_AUDIT.md)

> **State:** conceptual packet registry only, **not an implementation queue**. Baseline `main@e089e8b8a099`, October 8, 2026. All new slot decisions **unlocked**; **zero task packets created** by this audit.
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

### CS-F03-A
- **Intent:** HUD/terminal command-ownership map and extraction contract.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_HUD_TERMINAL_COMMAND_SEAM.md` (**not created**, not a link to a file).
- **Authorization:** BLOCKED pending F03 item-level audit, evidence and explicit decision lock.
- **Do not implement before:** Audit must precede packet creation; avoid conflicting with already-live terminal/view-model APIs.

### CS-F03-B
- **Intent:** Screen-state and projection consolidation, conditional on the mapped ownership findings.
- **Proposed future location:** `custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_HUD_VIEWMODEL_CONTRACTION.md` (**not created**, not a link to a file).
- **Authorization:** BLOCKED pending F03 item-level audit, evidence and explicit decision lock.
- **Do not implement before:** Audit must precede packet creation; avoid conflicting with already-live terminal/view-model APIs.

**Existing related packets:** none assigned; check live queue on audit completion.


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
