# F03 · HUD, terminal and command UI — source-level architecture audit

[← Audit overview / index](../CODEBASE_SYSTEMS_AUDIT.md) · [Packet-roadmap registry](PACKET_ROADMAP.md#cs-f03-a)

> **Audit state:** source-level diagnosis complete; runtime parity / playtest / full call-site verification outstanding  
> **Decision state:** **NOT LOCKED**. No new task-packet authoring, dispatch or implementation authorized.  
> **Source baseline:** live `main@ac87c8ade9cc010c819c2fa5113dde905df17cb9`, October 8, 2026 (EDT). This audit updates the original October 8 baseline rather than pretending all systems are static.  
> **Workstream:** `codebase-systems-audit` · proposed branch `agent/codebase-systems-audit`  
> **Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
>
> **Audit-method limit:** current GitHub code/docs/packet/validation-recipe inspection. No Godot runtime was launched, no frame-time profile or interactive UI review was performed, and no implementation was changed.

## Executive verdict

**P0 architectural migration candidate, not authorization for an indiscriminate rewrite.** The HUD is a multi-domain integration authority with a partially completed terminal extraction. Its biggest *verified* debt is that `TerminalCommandRouter` parses and checks verb names but dispatches every execution back into `ui.gd::_execute_local_terminal_command_legacy()`. World state, placement actions, local terminal display, modal focus, and command timing therefore still meet in the CanvasLayer. The high-ROI path is **finish the existing command migration, protect the existing projection/fidelity architecture, and contract the shell behind parity tests**. A brand-new UI architecture is not justified.

### Snapshot / existing healthy components

| Surface | Observed live evidence | Owner assessment |
| --- | --- | --- |
| [HUD `ui.gd`](https://github.com/braydio/CUSTODIAN/blob/ac87c8ade9cc010c819c2fa5113dde905df17cb9/custodian/game/ui/hud/ui.gd) | 319,111 bytes in live tree; 7,007 lines; 302 top-level functions by static `func` scan. Approx. 120 `@onready` node references and 91 top-level `var` declarations. | CanvasLayer currently combines ordinary HUD, debug/developer console, terminal, fabrication page interactions, placement UI, previews and command handling. Raw counts are **size indicators**, not independent debt findings. |
| [Command router](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/ui/terminal/terminal_command_router.gd) | `VALID_VERBS`, `SNAPSHOT_REFRESH_VERBS`, `parse()`, `is_known_verb()`; `execute(ui, parsed)` calls the HUD legacy method. | Parser and compatibility bridge only; **not** yet authoritative command execution. |
| [World-action service](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/ui/terminal/terminal_world_action_service.gd) | Six methods: sector power toggle, priority, repair, fabrication start, turret token placement, construction token placement. | Real service seam exists; insufficient to claim every mutating command is migrated. Uses scene-root lookups rather than injected target dependencies. |
| [Terminal snapshot](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/ui/terminal/terminal_snapshot.gd) | `build(ui)` collects authoritative sectors, threats, simulation tick, fidelity, infrastructure, ARRN, intelligence and contract state. | Reuse this source. It still traverses groups/root nodes through a passed UI instance; `_collect_sensor_truth()` calls `collect_now()` during a read refresh, so refresh-side mutation/expense needs measurement before changing it. |
| [View models and presenters](https://github.com/braydio/CUSTODIAN/tree/main/custodian/game/ui/terminal) | Overview scoring, Sensors view model, Fabrication view model, status formatter, fidelity policy, map and planet previews are already separate. | **Preserve.** Audit should not recreate them or presume they are missing. |
| [Inventory UI](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/ui/inventory/inventory_ui.gd) | Separate ~90 KB authority. | Cross-screen focus, HUD overlay and equipment presentation boundary only here; full architecture belongs to F07. |
| [Standalone HUD](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/ui/hud/custodian_hud.gd) | Separate ~28 KB script in same directory. | Audit consumer overlap before renaming/removing either HUD. No proof of redundant runtime authority yet. |

## Findings ledger (confirmed / risk / disproved)

**F03-01 · P0 · CONFIRMED · Compatibility bridge retains command ownership in HUD.**
- `terminal_command_router.gd::execute(ui, parsed)` calls `_execute_local_terminal_command_legacy`.
- `ui.gd` around [L3425–3465](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/ui/hud/ui.gd#L3425-L3465) queues, emits terminal status, and performs routing; [L5377–6090](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/ui/hud/ui.gd#L5377-L6090) retains the legacy handler. No migration can be called complete until the HUD no longer interprets command semantics. Existing [terminal design audit](../../02_features/terminal/TERMINAL_DESIGN_AUDIT.md) already proposed a registry + command-domain modules: reuse or refine that, do not create a competing scheme.
- **Validation target:** build an exact command/alias/help/completion/confirmation/refresh parity matrix; test command results independently of full HUD where possible.

**F03-02 · P0 · CONFIRMED · Mixed simulation action ownership / incomplete world-service coverage.**
- Legacy command cases call simulation/world authorities directly: `GameState.start_assault()`, `GameState.add_materials()` (`SCAVENGE`), `Power.set_sector_priority()` (`REROUTE`), and selected placement operations. Nearby [L6868–6948](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/ui/hud/ui.gd#L6868-L6948) partially delegate repair/priority through `TerminalWorldActionService` but directly resolve TurretPlacement for deploy.
- **Risk:** different UI entry paths can bypass shared preconditions or drift in error/confirmation behavior. This is **not** evidence of specific production exploits or a tested divergence.
- **Direction:** one command-domain adapter resolves intent; existing game-world authority validates and mutates; HUD displays an explicit result. Do not migrate authority into `TerminalWorldActionService` if that service would merely reimplement gameplay policy.

**F03-03 · P1 · CONFIRMED implementation distinction; determinism defect UNPROVEN · UI-time buffered commands.**
- [`_process(delta)`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/ui/hud/ui.gd#L1274) advances `_process_terminal_command_queue(delta)`; [L3425–3465](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/ui/hud/ui.gd#L3425-L3465) dispatches once elapsed time meets `TERMINAL_COMMAND_QUEUE_INTERVAL := 0.12`, and prints `QUEUED FOR SIM BUFFER`.
- **Do not assert fixed-step determinism has been violated yet**: determine intended command admission tick vs UI feedback latency, pause/time-scale behavior, and replay contracts. Lock exactly whether timed visual acknowledgement or simulation-tick scheduling is authoritative before any queue rewrite.
- **Validation target:** seeded tick/command result parity, queue order, terminal close with pending items, pause/reopen, rate changes, duplicate submission, command rejection and replay where supported.

**F03-04 · P1 · CONFIRMED · Large, independently evolving UI state cluster.**
- [L293–374](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/ui/hud/ui.gd#L293-L374) includes terminal boot/open state, command queue/inflight/history/autocomplete, snapshot, page navigation, sector highlighting, overlay flags, fabricator selection and map interactions; [L1822–1910](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/ui/hud/ui.gd#L1822-L1910) implements modal lifecycle.
- [L3970–5268](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/ui/hud/ui.gd#L3970-L5268) has page-specific rendering and fabrication action callbacks. Actual cross-module state ownership, direct reads and reentrancy require a complete call-site matrix before extracting arbitrary chunks.
- **Direction:** extract cohesive screen-local selection/projection and command-controller state; retain scene-owned nodes, focus and visuals in the UI facade until signal contracts permit further contraction.

**F03-05 · P1 · CONFIRMED · Per-frame HUD projection and direct lookups; performance cost NOT measured.**
- [`_process(delta)` L1274+](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/ui/hud/ui.gd#L1274-L1548) queries game-state, Operator, camera and related runtime facts while also advancing terminal queue and debug state. `show_debug_hud := false` makes a number of sections disabled in that implementation, so **do not count them as observed runtime load**.
- The terminal poll timer rebuilds snapshots/pages. Measure actual call frequency, allocations, repeated tree lookups and update cost before making performance claims or replacing polling with signals.

**F03-06 · P1 · CONFIRMED · Focus, placement and modal transitions are cross-system dependencies.**
- [Open/close](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/ui/hud/ui.gd#L1822-L1910) changes mouse mode, modal visibility, boot readiness, queued commands and poll timer. Close prioritizes cancelling placement mode, which may require an additional close action. [L2012–2167](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/ui/hud/ui.gd#L2012-L2167) handles preview mouse capture, keyboard focus/history and input routing.
- This behavior must be regression-pinned before moving ownership. Do not treat the placement-cancellation contract or focus management as accidental dead code.

**F03-07 · DOC DRIFT CONFIRMED · Canonical terminal authority was incorrectly cited.**
- The earlier F03 document linked [`design/01_systems/COMMAND_TERMINAL_UI.md`](../../01_systems/COMMAND_TERMINAL_UI.md) as related source of truth. That file explicitly labels itself a **concept archive** and redirects to [`design/02_features/terminal/COMMAND_TERMINAL_SPEC.md`](../../02_features/terminal/COMMAND_TERMINAL_SPEC.md). Use the latter for behavior and [`TERMINAL_AUDIT_VERIFICATION.md`](../../02_features/terminal/TERMINAL_AUDIT_VERIFICATION.md) for corrections to the July audit.
- The legacy packet [`UI_GD_FIXES.md`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/UI_GD_FIXES.md) still claims `in_progress` from May and contains a partially unchecked checklist despite several completion notes. This is **queue/document status drift to reconcile**, not proof that its old compile defects persist.
- The July design audit itself has an explicit verification erratum: fidelity policy, status formatter, Overview model and corresponding smokes were **already implemented**. Do not create these a second time.

**F03-08 · DISPROVED · "Terminal has no modular architecture".** Existing router, snapshots, policy, status formatter, view models, previews and world service disprove that blanket claim. A new all-purpose terminal manager would likely increase complexity.

## Target ownership graph (provisional, not locked)

```text
CanvasLayer HUD / terminal scene
  = display nodes, input focus, modal lifecycle, visual acknowledgements
      ↓ normalized user intent
Command registry / router
  = syntax + aliases + validation + dispatch + refresh policy
      ↓ typed request (no HUD Node dependency)
Domain command adapters
  = terminal-specific targeting, permission mapping, result translation
      ↓
Existing simulation authority
  = GameState, Power, FabPipeline, placement, ARRN, etc.
      ↓ read-only snapshots / domain events
TerminalSnapshot + fidelity policy + existing view models
  = information visibility, diagnostic priority, screen projections
      ↓
Terminal page presenters (HUD-local visual layer)
```

Keep terminal-local ephemeral focus/page/selection/transcript state distinct from world truth. This is a **recommended boundary for approval**, not a claim that all calls currently conform. No parallel power, fabrication, repair, sector or sensor authority.

## Parity and risk matrix required before decision lock

| Behavior family | Existing authoritative path | Migration concern / mandatory parity proof |
| --- | --- | --- |
| Parse/help/autocomplete | Router + HUD completion table + HUD legacy help | One registry or explicit compatibility mechanism must preserve documented command forms, invalid feedback, confirmations and completion ordering |
| Snapshot/fidelity | `TerminalSnapshot`, fidelity policy, status formatter, Overview/Sensors models | Field/Command asymmetry; omission of forbidden sensor facts; real sectors; deterministic simulation clock |
| Navigation/attention | HUD page buttons, transcript links, sector focus, map selections | Keyboard/mouse/gamepad focus, scroll position, screen hierarchy and 1366×768 safe layout |
| World mutations | GameState/Power/FabPipeline/ARRN/placement via HUD and service | Same target, same command result, same safety gate, once-only effects, no new alternate simulation policy |
| Queue and life cycle | HUD `_process`, modal open/close, boot and poll | Explicit admission/execution timing, pause/rate behavior, ordering and close/cancel |
| Fabrication | Existing fabrication model + HUD interactive rows + FabPipeline | Button and text command equivalence, quantity/queue/cancel, placement after craft |
| Debug/HUD | HUD regular health/reticle + devconsole/debug + separate `custodian_hud.gd` | Avoid breaking developer tests or cutting live in-world HUD features based on a filename alone |
| Inventory overlay | Independent `inventory_ui.gd` (F07) | Only shared input/focus and overlay contracts; inventory mutability audit remains F07 |

## Validation: existing coverage vs gaps

Use current [`VALIDATION_RECIPES.md`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/VALIDATION_RECIPES.md) and the `validation_manifest.json` owner mapping when a packet is authorized. Existing targeted smokes include:

- `terminal_status_fidelity_smoke.gd`, `terminal_snapshot_sector_identity_smoke.gd`, `terminal_overview_semantics_smoke.gd`, `terminal_overview_live_snapshot_smoke.gd`, `terminal_overview_layout_smoke.gd`;
- `terminal_defense_semantics_smoke.gd`, `terminal_sensors_intelligence_smoke.gd`, `terminal_sensors_layout_smoke.gd`, `terminal_overlay_visibility_smoke.gd`;
- `fabrication_terminal_command_smoke.gd`, `fabrication_terminal_clickable_smoke.gd`, `fabrication_terminal_layout_smoke.gd`, `fabrication_terminal_readability_smoke.gd`, `terminal_typography_smoke.gd`.

**Not verified in this audit:** current pass/fail status, complete regression ownership, physical keyboard/controller acceptance, fixed-tick admission semantics, duplicate world mutations, scene initialization ordering and frame time. Future packets must add focused command-contract/queue/controller tests rather than rely on a generic Godot parse/import success. Initial validation should be the smallest focused test set, then changed-file selection; reserve interactive review for focus/readability behavior that structured checks cannot prove.

### Documentation-drift disposition

1. **Corrected in this audit:** replace archived `design/01_systems/COMMAND_TERMINAL_UI.md` as behavioral authority with the active feature spec; link the July verification corrections and existing architecture.
2. **Flagged, not silently edited:** `UI_GD_FIXES.md` May `in_progress` packet and the earlier terminal audit maturity claims. Review queue state before modifying historical packet records.
3. **Future implementation obligation:** update `CURRENT_STATE.md`, `FILE_INDEX.md`, validation manifest, and any actual affected spec only when behavior/ownership changes. Keep completed historical receipts intact.

## Broad task-packet roadmap (conceptual only)

These are **proposed slots** and **not files**. Each slot remains blocked until this document has an explicit owner, behavior/non-goals, validation acceptance and decision lock. [Master roadmap](PACKET_ROADMAP.md#cs-f03-a) records names and dependencies.

| Slot | Proposed implementation slice | Dependency / gate | Broad acceptance |
| --- | --- | --- | --- |
| **CS-F03-A** | Command contract/parity fixture and canonical command schema plan | First, after lock. Reconcile July command-registry proposal and current forms. | Inventory of all commands, aliases, permissions, confirmations, help/completion and results; positive/negative parity tests |
| **CS-F03-B** | Migrate navigation/read-only commands out of legacy HUD | A | Pure router/adapters; identical page, transcript, fidelity and action-link outcomes |
| **CS-F03-C** | Route world-mutating commands through existing authority adapters | B; confirm target service/API ownership | Same action once, same failure reason, no world write in page presenter |
| **CS-F03-D** | Consolidate fabrication/ARRN commands and clickable-action parity | C; avoid duplicating live pipeline/ARRN rules | Button/command equivalence and focus-safe feedback, no extra authorizations |
| **CS-F03-E** | Decide and implement command-buffer timing ownership **only if required** | A and determinism design lock | Tick/order/replay and pause/close invariants proven; no invented clock authority |
| **CS-F03-F** | Extract cohesive screen-local state and projection glue | B–D, preservation of snapshot policy | Same thirteen-page navigation, stable snapshot/fidelity, layouts, focus and scroll |
| **CS-F03-G** | Separate developer/debug/ordinary HUD glue; contract `ui.gd` only after consumers verified | F; consider F07 overlap | Reduced central mutable authority; no broken external calls, no speculative `custodian_hud.gd` deletion |
| **CS-F03-H** | Integration/parity/performance closeout and docs/validation mapping | B–G actually approved and landed | Real-scene keyboard/mouse/controller paths, representative gameplay commands, focused smoke, measured before/after ownership and frame-time evidence |

**Order is provisional.** E may prove unnecessary; B–D can be further split by coherent domain; F/G must not begin until their current callers are mapped. No visual redesign, art production, new gameplay mechanics, world-balance changes or new terminal feature promises are included.

## Decision lock record

- **Source diagnosis:** confirmed for F03-01, -02, -04, -05 (structural, not performance), -06 and documentation issue -07; F03-03 command timing implementation confirmed but defect status unresolved; broad `no modularity` premise disproved.
- **Chosen boundary and owner:** proposed graph above, **not approved**.
- **Behavioral changes allowed:** **none** in audit phase. Preserve command content, fidelity, timing until E resolves authority, thirteen pages, UI/modal contracts and existing game systems.
- **Design questions for human/ChatGPT:** whether queue timing is intended to be simulation-step authoritative; whether any HUD layout/mental-load redesign should be a separate F12/UI feel item; whether to prioritize pure architectural parity first.
- **Validation remaining:** targeted Godot smokes plus real-scene keyboard/focus and command-order acceptance; no benchmarks or manual visual baseline yet.
- **Packet authorization:** **UNLOCKED / NONE AUTHORIZED.** Each slot must be reviewed against live main and locked explicitly here before its executable packet is authored.
- **Next audit step:** complete command-case callsite/mutation inventory and runtime/interaction parity baseline, decide the command queue clock boundary, then record explicit user/ChatGPT approval and lock the affected packet scopes. F07 remains independently scoped.
