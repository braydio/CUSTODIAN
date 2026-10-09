# VEHICLE DIAGNOSIS AND KNOWLEDGE V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vehicle-diagnosis-knowledge-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-vehicle-wreck-restoration-foundation-v1-review-corrections-1`
- Locks: `vehicle-knowledge, vehicle-diagnostics, operator-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-vehicle-diagnosis-knowledge-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `new persistent progression authority, production input seam, scan anti-farming, and data-driven pattern evidence`
- Reviewed main: `78dee2c0fd939f5e245ca779a6095deb459739bd`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Visual review: `none`
- Goal: Add the vehicle diagnosis/reverse-engineering layer: the Operator can service-scan real vehicles, learn named mechanical domains, collect specific assembly-pattern evidence, and query deterministic fabrication prerequisites without scanning repairing the vehicle or granting physical parts.
- Completion boundary: Done when current main has one persistent `VehicleKnowledgeState` authority, data-owned knowledge thresholds/diminishing returns, data-owned per-vehicle scan profiles, one production Operator service-scan path using the existing fixed-tick input architecture, deterministic per-instance anti-farming, condition-aware pattern observability, save/load-facing serialization, and focused validation proving intact/disabled/wreck scans and repeated-example behavior. No fabrication recipe or restoration payment may be changed by this slice.
- Current measured state: The held wreck-restoration correction is independently passed on main. `PilotableVehicle` owns wreck/health/entry lifecycle and already distinguishes operational vs wrecked state. The registry loads archetype, movement, durability, restoration, hardpoint/loadout/visual data but has no scan-profile identity. `project.godot` has an existing `repair` action, and `OperatorInputRouter.ACTIONS` already samples it; `operator.gd` currently owns interaction dispatch while the separate `operator-interaction-domain-extraction` packet may later move that seam. There is no vehicle knowledge state, no vehicle pattern-evidence store, and no production scan action. ARRN's `RELAY_RECOVERY` knowledge is unrelated and must remain separate.
- Evidence: `design/02_features/vehicles/VEHICLE_RECOVERY_REVERSE_ENGINEERING.md`; `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`; `custodian/game/state/persistent/README.md`; `custodian/game/actors/operator/input/{operator_input_frame,operator_input_router}.gd`; `custodian/game/actors/operator/operator.gd`; `custodian/game/vehicles/{pilotable_vehicle,vehicle_definition,vehicle_registry}.gd`; `custodian/content/vehicles/{vehicle_archetypes,vehicle_registry_schema}.json`; reviewed wreck-restoration correction/re-review.
- Task-specific authority: `VEHICLE_RECOVERY_REVERSE_ENGINEERING.md` for progression semantics; `OperatorInputRouter` for raw-input ownership; `PilotableVehicle` for runtime condition; new `VehicleKnowledgeState` for durable scan knowledge.
- Work surface: New `custodian/game/state/persistent/vehicle_knowledge_state.gd`; new `custodian/content/vehicles/vehicle_knowledge_progression.json`; new `custodian/content/vehicles/vehicle_scan_profiles.json`; `custodian/project.godot`; `custodian/content/vehicles/{vehicle_archetypes,vehicle_registry_schema}.json`; `custodian/game/vehicles/{vehicle_definition,vehicle_registry,pilotable_vehicle}.gd`; a focused Operator-side scanner component under `custodian/game/actors/operator/interaction/`; minimal Operator orchestration or the landed `OperatorInteractionController` seam; `custodian/tools/validation/vehicle_diagnosis_knowledge_smoke.gd`; `validation_manifest.json`.
- Change: Implement the exact contracts below. Prefer the named files/APIs when they fit current main; if claim-time Operator interaction extraction has landed, integrate through that authority rather than recreating logic in `operator.gd`.
- Preserve: ARRN remains relay knowledge only; `ResourceLedger`, `FabPipeline`, `InventoryManager`, `BuildInventory`, and restoration payment are not mutated; scan never changes vehicle HP/wreck state; vehicle enter/exit and field repair stay unchanged; `OperatorInputRouter` remains the only raw `Input.*` reader.
- Non-goals: No fabrication recipes, no replacement-part output, no restoration-profile migration, no research terminal/page, no scan combat debuffs, no world-object persistence redesign, no production art, no new generalized RPG skill tree.
- Acceptance: (1) A first service-scan of one configured Field Scout instance grants deterministic configured domain XP and observable pattern evidence. (2) Re-scanning the same instance grants zero. (3) Scanning a distinct second exemplar of the same archetype grants reduced domain XP according to data-owned diminishing returns. (4) A previously unseen observable pattern on a repeated archetype still grants its evidence. (5) WRECKAGE never teaches patterns marked destroyed/unobservable for wreck condition. (6) Operational/disabled/wreck condition multipliers are applied from data, not hard-coded in the UI. (7) `VehicleKnowledgeState` serializes/deserializes domain XP, pattern evidence, scanned fingerprints, and archetype scan counts without duplicate gains after round-trip. (8) Requirement queries are side-effect free. (9) Production input reaches the scanner through `OperatorInputFrame`; no vehicle/knowledge script calls `Input.*`. (10) Existing vehicle lifecycle/restoration validations remain green.
- Validation: Add `vehicle_diagnosis_knowledge` to `validation_manifest.json` with direct ownership of all new scan/knowledge files and the narrow Operator seam. Smoke must drive the real Operator input frame using `repair` service intent, prove first scan, same-instance rejection, second-exemplar diminishing return, new-pattern evidence, condition observability, serialization round-trip, and no HP/resource/inventory mutation. Re-run `vehicle_wreck_restoration`, `vehicle_runtime_lifecycle`, `vehicle_registry_contract`, `vehicle_exit_clearance`, relevant Operator input-frame validation, packet contract tests, then changed-file closeout once focused checks pass.
- Task overrides: `none`
- Deferred: Research UI, scan VFX/audio, exact long-run XP balance, durable cross-reconstructed-world object identity beyond the V1 stable fingerprint seam, R3/R4 authored knowledge sources.

## Required implementation shape

### 1. Persistent knowledge authority

Create `custodian/game/state/persistent/vehicle_knowledge_state.gd` and register it as autoload `VehicleKnowledgeState` in `custodian/project.godot`.

It owns only:
- XP totals per canonical domain: `CHASSIS`, `MOBILITY`, `POWERTRAIN`, `CONTROL`, `SPECIALTY`;
- derived domain levels from progression data;
- integer evidence per assembly-pattern ID;
- exact scan fingerprints already consumed;
- per-archetype successful scan counts used for diminishing returns;
- save/load-facing serialization.

Recommended public surface:
```gdscript
func get_domain_xp(domain: StringName) -> int
func get_domain_level(domain: StringName) -> int
func get_pattern_evidence(pattern_id: StringName) -> int
func has_scanned(fingerprint: String) -> bool
func record_vehicle_scan(scan: Dictionary) -> Dictionary
func meets_requirements(requirements: Dictionary) -> bool
func get_requirement_status(requirements: Dictionary) -> Dictionary
func to_save_dict() -> Dictionary
func from_save_dict(data: Dictionary) -> void
```

`record_vehicle_scan()` should return a structured result containing accepted/rejected, XP gained by domain, pattern evidence gained, resulting levels/evidence, and a rejection reason such as `ALREADY_SCANNED`. Callers must not mutate internal dictionaries directly.

### 2. Progression data

Create `custodian/content/vehicles/vehicle_knowledge_progression.json`.

It must own:
- valid domain list;
- XP thresholds for levels;
- repeated-archetype diminishing multipliers;
- vehicle-condition multipliers;
- minimum multiplier/floor if one exists.

Do not embed those values in `VehicleKnowledgeState` or UI code. Exact balance may be modest V1 values, but validation must read this file and calculate expected gains from it.

### 3. Scan-profile data

Create `custodian/content/vehicles/vehicle_scan_profiles.json`.

Each profile should include:
- `id`;
- base XP contribution by domain;
- pattern entries with `pattern_id`, base evidence, and observable conditions;
- optional tags/notes useful to later presentation but not runtime authority.

Add `scan_profile` to `custodian_ground_buggy_scout_light` in `vehicle_archetypes.json`. Add the field to registry schema/definition loading and resolve `scan_profile_data` in `VehicleRegistry.load_registry()`, following the existing restoration/durability profile-loading pattern.

The Field Scout scan profile may expose its standard service patterns even though its three starter recipes will not require research. This lets the Scout contribute useful knowledge for later related machines.

### 4. Runtime condition and stable fingerprint

`PilotableVehicle` should expose a read-only scan snapshot rather than letting scanner code infer private state. Recommended shape:
```gdscript
func get_vehicle_scan_snapshot() -> Dictionary
```
Include registry/archetype ID, scan profile ID/data, condition (`OPERATIONAL`, `DISABLED`, `WRECKAGE`), stable scan fingerprint, and observable pattern context.

Do not make `VehicleKnowledgeState` depend on live nodes.

For V1 fingerprinting, add one explicit stable instance-key seam. The resolver/authored scene path should provide a deterministic key when available. A fallback may combine registry ID + scene identity + quantized spawn origin for current deterministic worlds, but document that reconstructed-world object identity is deferred. Never use `Object.get_instance_id()` as durable anti-farm identity.

### 5. Operator-side scan input

Use the already-sampled `repair` action as the V1 **service/diagnostic** intent. Do not add direct `Input.is_action_*` reads.

Preferred implementation:
- new focused component under `custodian/game/actors/operator/interaction/operator_vehicle_scanner.gd`;
- it receives Operator position plus the current `OperatorInputFrame`/semantic press from the existing actor or, if F5 has landed, from `OperatorInteractionController`;
- it selects the nearest eligible node in a dedicated `vehicle_scannable` group within an explicit range;
- on `repair` press, it requests the target scan snapshot and submits it to `VehicleKnowledgeState`;
- it emits a structured scan result for HUD/log/presentation consumers.

Do not put scan progression state into `operator.gd`. The actor/controller change should be orchestration only.

### 6. Feedback contract

No full research page is required, but the runtime must expose enough structured result data for later presentation:
- vehicle display name;
- accepted/rejected reason;
- XP gains and any domain level-up;
- pattern evidence gains;
- whether no new information was learned.

If an existing transient notification/log seam is cheap to reuse, surface a compact message. Do not invent a second HUD system.

### 7. Validation ownership

Create `custodian/tools/validation/vehicle_diagnosis_knowledge_smoke.gd` and add a `vehicle_diagnosis_knowledge` manifest entry. Its owners should include:
- new knowledge/progression/scan-profile files;
- `vehicle_definition.gd`, `vehicle_registry.gd`, and the narrow `pilotable_vehicle.gd` scan seam;
- scanner component and the exact Operator orchestration file;
- relevant JSON.

The smoke must use two distinct vehicle instances and at least one fixture profile whose pattern observability differs by condition.

## Handoff

- Next workstream: `review-vehicle-diagnosis-knowledge-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Summary backlink: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh reason: `none`
- Next action: Land the focused diagnosis/knowledge authority, then review anti-farming, persistence, input ownership, and condition observability before fabrication consumes it.
- Blockers or open questions: `none; if operator-interaction-domain-extraction is concurrently active, logical/file lock must serialize the narrow Operator seam rather than merging competing interaction ownership.`
