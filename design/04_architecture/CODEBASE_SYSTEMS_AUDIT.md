# CUSTODIAN · Major Systems Codebase Audit

**Date:** October 8, 2026  
**Workstream:** `codebase-systems-audit`  
**Evidence baseline:** [`main@e089e8b8a099`](https://github.com/braydio/CUSTODIAN/commit/e089e8b8a0993a0276596797e3a95798e33eb422)  
**Program phase:** 15 focuses inventoried; F03/F11/F14/F15 advanced beyond initial reconnaissance. F11 is source-audited/decision-locked; F14-B plus R0-01 correction independently accepted in a fresh re-review; real-Grunt F14-C1 synthetic handoff and R0-01/02/03 correction cycle independently accepted; production F14-C2 / F15 geographic identity and scene residency remain design-gated.  
**Full-focus decisions locked:** 1 of 15 (F11) · **Partial design locks:** F14 V1 bounded behavior + F15 continuous travel · **F14-B lifecycle:** implementation, R0-01 correction and independent re-review archived PASS; **F14-C1:** implementation, correction and fresh re-review archived PASS; **F14-C2/F15:** production geography/residency still conceptual, not claimable; **F11:** new runner/review pair ready and dependency-gated.  
**Current authoring chat URL:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31 (October 8, 2026 F03/F14/F15 continuation).

## Purpose and architecture
Create a durable trail from system-level diagnosis through evidence-backed decisions to independently executable implementation contracts. This is **not** a mandate to rewrite major systems, and it does not override existing design, runtime, queue or review authorities.

```text
CODEBASE_SYSTEMS_AUDIT.md         (overview, prioritization, index)
  ├─ codebase_systems_audit/Fxx_*.md  (system-level evidence, alternatives, decision lock)
  └─ codebase_systems_audit/PACKET_ROADMAP.md (real existing packets + unapproved proposed slots)
       └─ custodian/docs/ai_context/task_packets/*.md (ONLY AFTER item-level decision lock)
```

**Audit governance:** This index is a decision/evidence ledger, not dispatch authority. F11 and F14 have authorized real packet workstreams; other proposed slots remain conceptual unless individually promoted in their focus. Only the current [active/archived packet lifecycle](https://github.com/braydio/CUSTODIAN/tree/main/custodian/docs/ai_context/task_packets) and dispatcher govern claimability. See [repository AGENTS](https://github.com/braydio/CUSTODIAN/blob/main/AGENTS.md).

## Executive findings
1. **Operator:** F0 dependency injection and F4 Dodge extraction documented complete. Existing F1/F2/F3/F5/F6/G packets should be finished before commissioning any competing generic extraction.
2. **Procgen/world installation:** Many focused helpers already exist, while `ProcGenTilemap` and `ContractWorldLoader` remain major coordination authorities. Complete existing domain migration and measure real coupling/soak before new refactors.
3. **HUD/terminal (F03 updated October 8):** Source-level audit confirms partial migration: the terminal router delegates execution into the HUD's ~700-line legacy command handler; game-state/placement mutations and modal/queue/UI state still converge in `ui.gd`. Existing snapshot, fidelity, Overview/Sensors/Fabrication models must be preserved. The 0.12-second `_process` command queue requires a determinism contract decision, not an assumed bug fix. [Evidence, drift and eight conditional packet slots](codebase_systems_audit/F03_HUD_TERMINAL_UI.md).
4. **Enemy/non-player agents:** Marine Dash extracted; six-family composition roadmap exists; complete NPA slices without turning `Enemy` into a universal NPC superclass.
5. **Campaign and continuity:** The first complete production campaign loop and R2 death/reintegration deserve integration priority over more detached features.
6. **Game feel:** Motion-consistent upper/lower presentation, enemy telegraph readability, hit feedback, vehicle response, interaction acknowledgement and camera behavior have strong potential ROI, but require playtest/telemetry evidence.
7. **Living world (F14):** Original six baseline Godot checks reported PASS. F14-B then added deterministic abstract geographic-group activity to the existing clock/kernel with snapshot v5, v4 migration and causal events; its implementation landed and first fresh review found blocking **R0-01** (valid dotted IDs collided in event IDs, breaking restore). A length-prefixed correction landed on **`main@d67cf70e0`** and its focused smokes passed; **fresh correction re-review passed at `main@7d9fe1872361` (no new findings)**. **Synthetic physical↔abstract real-Grunt handoff is implemented and independent correction re-review passed (R0-01/02/03 fixed).** Production actor/geographic residency, disk persistence and multi-site handoff are still unproven/unapproved. **V1 bounded behavior is partially locked; full focus is not.** [F14 evidence and lifecycle](codebase_systems_audit/F14_LIVING_WORLD_SIMULATION.md).
8. **Campaign-world geography (F15 added October 8):** Hub is canonically the Historical City continuation; normal campaign ingress is Muster Court's Continuity Port, not the Awakening Gate of Dust. Current procgen is a finite local map revealed in chunks, not a large multi-biome, multi-settlement geographic campaign world. A distinct geographic topology/world-session design must precede F14 unloaded-actor continuity integration or new procgen world-scale work. [F15 audit](codebase_systems_audit/F15_CAMPAIGN_WORLD_GEOGRAPHY.md) · [design discussion draft](CAMPAIGN_WORLD_GEOGRAPHY_AND_TOPOLOGY.md).
9. **Agent orchestration:** Native dispatcher, isolated worktrees, automatic landing and paired reviews exist. The F11 source-level audit **locked** the missing fresh external reviewer-launch seam; `CODEBASE_AUDIT_AUTONOMOUS_REVIEW_RUNNER` and its paired review are real ready/auto packets, but a successful independent runner rollout is not yet recorded here.

## Source-size hotspots (non-generated; indicative only)
| Runtime file | Approx. source bytes | Interpretation |
| --- | ---: | --- |
| `game/actors/operator/operator.gd` | 580,978 | Existing extraction program; don't compete |
| `game/world/procgen/proc_gen_tilemap.gd` | 482,788 | Facade/domain ownership to validate |
| `game/ui/hud/ui.gd` | 319,111 | New, high-value decomposition investigation |
| `game/actors/enemies/enemy.gd` | 178,699 | Existing non-player actor extraction program |
| `game/world/sundered_keep/sundered_keep_map.gd` | 128,752 | Candidate level-specific integration debt |
| `game/systems/core/systems/contract_world_loader.gd` | 104,279 | Existing placement/domain contraction |
| `game/ui/inventory/inventory_ui.gd` | 89,622 | UI/equipment authority boundary |

These are tree metadata at the baseline SHA, **not** line-level debt measurements, test outcomes, runtime profiling or proof of bad architecture. Generated catalog code is excluded. Use actual state owners, coupling, test scope, call paths and duplicate mutations when awarding implementation priority.

## Focus-item index
**P0/P1/P2 are provisional audit priority**, not a new dispatch priority or permission to edit. Only F11 is fully decision-locked; F14 and F15 have partial experience/behavior locks. Remaining rows require detailed evidence and explicit decision closure.

| ID | Item detail | Priority | Audit state | Decision |
| --- | --- | --- | --- | --- |
F01 | [Operator runtime and combat](codebase_systems_audit/F01_OPERATOR_COMBAT.md) | P0 | Initial evidence recorded; detailed audit pending | Not locked
F02 | [Procedural generation and Contract-world installation](codebase_systems_audit/F02_PROCGEN_WORLD_INSTALLATION.md) | P0 | Initial evidence recorded; detailed audit pending | Not locked
F03 | [HUD, terminal and command UI](codebase_systems_audit/F03_HUD_TERMINAL_UI.md) | P0 | Source-level findings captured; runtime parity and final decision pending | Not locked
F04 | [Enemy and non-player actor runtime](codebase_systems_audit/F04_NON_PLAYER_ACTORS.md) | P1 | Initial evidence recorded; detailed audit pending | Not locked
F05 | [Authored level and encounter coordinators](codebase_systems_audit/F05_AUTHORED_LEVEL_RUNTIME.md) | P1 | Initial evidence recorded; detailed audit pending | Not locked
F06 | [Campaign, Hub, continuity, death and recovery](codebase_systems_audit/F06_CAMPAIGN_DEATH_RECOVERY.md) | P1 | Initial evidence recorded; detailed audit pending | Not locked
F07 | [Inventory and equipment UI](codebase_systems_audit/F07_INVENTORY_EQUIPMENT_UI.md) | P1 | Initial evidence recorded; detailed audit pending | Not locked
F08 | [Power, fabrication, defense and logistics](codebase_systems_audit/F08_INFRASTRUCTURE_SYSTEMS.md) | P2 | Initial evidence recorded; detailed audit pending | Not locked
F09 | [Vehicle runtime, class identity and driving feel](codebase_systems_audit/F09_VEHICLES.md) | P1 | Existing Scout/lifecycle/recovery DAG; major campaign travel importance user-confirmed; detailed audit pending | Not locked
F10 | [Camera, streaming and environmental presentation](codebase_systems_audit/F10_CAMERA_STREAMING_ENVIRONMENT.md) | P2 | Initial evidence recorded; detailed audit pending | Not locked
F11 | [Agent execution, validation and paired review handoff](codebase_systems_audit/F11_AGENT_VALIDATION_AUTOMATION.md) | P1 | Source-level reviewer-launch audit complete; implementation/review pair authorized and active | Locked
F12 | [Cross-system game-feel opportunities](codebase_systems_audit/F12_GAME_FEEL.md) | P1 | Initial evidence recorded; detailed audit pending | Not locked
F13 | [New-feature return on investment](codebase_systems_audit/F13_FEATURE_ROI.md) | P1 | Initial evidence recorded; detailed audit pending | Not locked
F14 | [Living-world simulation / interest / unloaded sector continuity](codebase_systems_audit/F14_LIVING_WORLD_SIMULATION.md) | P0 | B and C1 synthetic real-Enemy handoff independently re-reviewed PASS; production C2 geography/spawner residency unapproved | Partially locked
F15 | [Campaign-world geography and Domain-scale traversal](codebase_systems_audit/F15_CAMPAIGN_WORLD_GEOGRAPHY.md) | P0 | Continuous geography/Ports/vehicles player experience locked; topology/scale benchmark pending | Partially locked

## F03 detailed-audit update (October 8, 2026)

- [Item-level evidence and decision record](codebase_systems_audit/F03_HUD_TERMINAL_UI.md) traces command interpretation, world mutations, simulation-time buffering questions, screen-local mutable state and documented UI input dependencies.
- [Eight **conceptual** F03 packet slots](codebase_systems_audit/PACKET_ROADMAP.md#cs-f03-a) replace the original two high-level placeholders. This is an **unapproved roadmap**, not eight executable packets.
- Existing terminal [implementation spec](../02_features/terminal/COMMAND_TERMINAL_SPEC.md) supersedes the [archived concept](../01_systems/COMMAND_TERMINAL_UI.md). The July [audit verification](../02_features/terminal/TERMINAL_AUDIT_VERIFICATION.md) prevents duplicate work on already implemented terminal fidelity/Overview components.
- F03 remains **NOT LOCKED** until command-case callsite coverage, fixed-tick vs UI-time decision, focused Godot regression evidence and any human-owned UX boundaries are resolved. **F03 itself remains unlocked**; its eight conceptual slots are not executable. Program-wide counts are recorded in the current header and focus index, not frozen in this historical F03 update.

## F11 reviewer automation decision update (2026-10-09)

[The F11 detailed audit](codebase_systems_audit/F11_AGENT_VALIDATION_AUTOMATION.md) has **LOCKED** the narrow independent Codex review-runner boundary: one synchronous ephemeral fresh-context reviewer launched through the existing dispatcher with recoverable supervision evidence, rather than a replacement queue or implicit global worker daemon. Its [implementation](../../custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_AUTONOMOUS_REVIEW_RUNNER.md) and [paired review](../../custodian/docs/ai_context/task_packets/REVIEW_CODEBASE_AUDIT_AUTONOMOUS_REVIEW_RUNNER.md) are the authorized execution records; current runtime status must be checked through the queue, not inferred from this summary.

## F14 living-world audit addition (October 8, 2026)

[The F14 item-level record](codebase_systems_audit/F14_LIVING_WORLD_SIMULATION.md) corrects an omitted top-level architecture/feature program: deterministic macro campaign simulation is not the same capability as unloaded actors and sectors experiencing causal state changes and being correctly reconstructed upon return. It records observed near/nearby/background/dormant code, strategic macro state, WorldHistory limitations, the old Sector Activity Simulator proposal, drift, a received local audit receipt and a [five-slot conceptual roadmap](codebase_systems_audit/PACKET_ROADMAP.md#cs-f14-a). **F14 V1 bounded behavior LOCKED.** F14-B implementation was completed and archived; its fresh reviewer independently found **R0-01**, which was repaired in a landed archived correction. **The fresh correction re-review passed** and independently accepted B. A separate **one-real-Grunt C1 synthetic Domain A/B handoff** has since been implemented, corrected and independently re-reviewed PASS. [F14-C2/F15 planning refresh](F14_C2_F15_PRODUCTION_GEOGRAPHY_AND_RESIDENCY_REFRESH.md) identifies production geographic identity, scene/actor residency and spawner reservation as the next gated owners; no automatic C2 packet is authorized.

## F15 geography audit addition (October 8, 2026)

F15 separates the geography of a single broad physically traversable campaign from F14's near/far actor simulation and F02's existing procgen data/streaming hardening. [Item-level audit](codebase_systems_audit/F15_CAMPAIGN_WORLD_GEOGRAPHY.md) and [discussion draft](CAMPAIGN_WORLD_GEOGRAPHY_AND_TOPOLOGY.md) preserve Hub and Domain canon while proposing scale/wayfinding, global topology and streamed local materialization. [Three unapproved conceptual slots](codebase_systems_audit/PACKET_ROADMAP.md#cs-f15-a). **F15 continuous player experience LOCKED; technical streaming/topology architecture remains UNLOCKED, zero F15 executable packets.**

## Proposed work ordering
**Audit lane F: geographic world scale.** F15 reconciles Historical City / Hub / Continuity Port canonical routing, defines a geographically coherent single-campaign experience, and compares global topology/streamed areas against mere one-canvas expansion. It can design before procgen hardening completes; implementation must consume F02 and current route/persistence owners.

**Audit lane E: living-world continuity.** F14-B and its bounded R0-01 correction are landed, but the **correction re-review** is the next independent acceptance gate. Physical identity/reification work must be refreshed only after that review and F15 geography contract reconciliation; preserve REMAP, NPA and procgen owners.

**Audit lane A: existing-program reconciliation.** F01, F02, F04 and F06 map to active Operator, Procgen, NPA and Hub/Recovery programs. Determine whether any gap survives existing packet ownership; don't add duplicate scope.

**Audit lane B: likely overlooked architecture.** F03 HUD/terminal first, then F07 inventory and F05 authored levels. Trace actual source-level mutation seams, public APIs, validation ownership and player-facing correctness.

**Audit lane C: bounded integration + feel.** F08 infrastructure, F09 vehicles, F10 camera/environment, then F12 game-feel comparisons. Avoid extracting healthy, newly consolidated authorities.

**Audit lane D: the future full-auto program.** F11 verifies real reviewer-process spawning, transition receipts, crash recovery, and finite correction cycles. F13 locks player-value priorities only after playable campaign-loop evidence.

## Governance and decision states
- **Evidence recorded:** file tree, implementation/packet documentation, representative source or metrics observed on a named SHA. Claims requiring runtime confirmation remain explicitly hypotheses.
- **Audited:** exact responsibility/callsite inventory, duplication/ownership findings, risk, regression recipes, documentation-drift disposition, and alternatives are captured. Every finding is classified confirmed / disproved / deferred.
- **Decision locked:** chosen owner/seam and gameplay contract, exact in/out scope, acceptance/validation, predecessor compatibility, reviewer needs, and any user-owned visual/design decision recorded in the focus document.
- **Packet authorized:** only after decision lock, create/update the narrow implementation packet (and review packet when needed) in `custodian/docs/ai_context/task_packets/`, validate and index it. Proposals here do not change dispatch eligibility.

**Stop conditions:** ambiguous current authority, contradictory runtime/docs, missing playtest proof for subjective feel, unresolved user design choice or unsafe agent/review handoff. An audit may conclude **no refactor needed** or **defer to existing program**.

## Existing authority, methods and drift watch
- [Master design doctrine](https://github.com/braydio/CUSTODIAN/blob/main/design/00_meta/MASTER_DESIGN_DOCTRINE.md); [Architecture ownership map](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/ARCHITECTURE_OWNERSHIP_MAP.md); [Current runtime state](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/CURRENT_STATE.md).
- [Operator architecture](https://github.com/braydio/CUSTODIAN/blob/main/design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md); [Non-player architecture](https://github.com/braydio/CUSTODIAN/blob/main/design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md); [Procgen roadmap](https://github.com/braydio/CUSTODIAN/blob/main/design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md); [Hub roadmap](https://github.com/braydio/CUSTODIAN/blob/main/design/04_architecture/HUB_FIRST_SET_IMPLEMENTATION_ROADMAP.md).
- [Agent lifecycle](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md); [Task packet queue README](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/README.md); [Task packet authoring guide](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/CODEX_TASK_PACKET_GUIDE.md).
- **Observed documentation drift candidate:** `ARCHITECTURE_OWNERSHIP_MAP.md` retains the pre-F0/F4 Operator debt narrative (41 = 38 scene lookups + 3 runtime weapon fields), while CURRENT_STATE records F0/F4 complete. Re-measure live debt and refresh the map through appropriate owner work; don't overwrite historical packet baselines.
- **Other reconciliation needed:** older packet measured baselines, NPA refresh/manual state versus newer dispatch doctrine, ContractWorldLoader contraction assumptions, and procgen V2 deferred APIs. Treat a packet's `Status: ready` as distinct from actual dependency eligibility.
- **No runtime benchmarks or headless Godot tests were run for this overview.** Dedicated code-review graph was unavailable; live GitHub reads provided source and queue evidence.

## F14-C1 acceptance → F14-C2/F15 production refresh (October 9, 2026)

[New cross-system planning record](F14_C2_F15_PRODUCTION_GEOGRAPHY_AND_RESIDENCY_REFRESH.md) verifies the [fresh C1 correction re-review](../../REVIEW_LIVING_WORLD_ENTITY_REIFICATION_HANDOFF_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md): R0-01/02/03 fixed, no new findings, five focused smokes and independent deterministic replay PASS. It distinguishes **accepted explicit synthetic one-Grunt handoff** from **unimplemented real Domain/Location → physical locality residency, ambient camp spawn-slot reconciliation and multi-site player traversal**. F15's continuous travel goal remains locked, but world extent/topology/scene staging strategy remain undecided. F15-A evidence precedes F15-B address/materialization and F14-C2 automatic production binding. This update does not open new dispatchable packet work.

## Packet registry and next review
[**Packet roadmap / proposed slot registry**](codebase_systems_audit/PACKET_ROADMAP.md) records every item-to-existing-packet association and non-authorized future slot. **Next recommended cross-system audit:** F02/F15 procgen scale, physical geography and stable IDs, parallel to the already-identified F03 terminal timing/command-parity evidence gaps. F14-C1 is accepted after correction. Next: a bounded F15-A read-only geography/route/scene-residency and current travel-scale audit, then a design lock before any F14-C2 or F15-B production packet. Avoid duplicating existing F01/F02/F04 packet programs.
