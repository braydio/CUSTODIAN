# VEHICLE PART FABRICATION AND RECOVERY V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vehicle-part-fabrication-recovery-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-vehicle-diagnosis-knowledge-v1`
- Locks: `vehicle-restoration-runtime, fabrication-runtime, vehicle-content, inventory-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, persistence`
- Paired review workstream: `review-vehicle-part-fabrication-recovery-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `cross-system recipe gating, persistent item output, atomic component consumption, and recovery-grade enforcement`
- Reviewed main: `78dee2c0fd939f5e245ca779a6095deb459739bd`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Visual review: `none`
- Goal: Build the reusable component-recovery spine: R0 PATCHWORK profiles may still pay raw materials directly, while R1+ profiles require fabricated replacement assemblies; advanced component recipes can be locked by reviewed vehicle knowledge/pattern evidence; FabPipeline creates real part items in InventoryManager; restoration consumes those items atomically.
- Completion boundary: Done when restoration profiles have validated recovery grades and mutually exclusive requirement modes; `FabPipeline` centrally evaluates ARRN + vehicle knowledge/pattern recipe locks and can output persistent inventory items; `InventoryManager` has a fail-closed multi-item requirement/consumption API; `VehicleRestorationInteraction` can execute both R0 direct-material and R1+ component modes without duplicating lifecycle ownership; three starter-known Field Scout component recipes exist and fabricate real items; and validation proves generic R0, R1, and R2 contracts. This slice deliberately does **not** switch the production Scout profile: that is owned by `vehicle-field-scout-buggy-class-v1-recovery-1-review-corrections-1`.
- Current measured state: `VehicleRestorationInteraction` currently reads only `profile.cost`, checks/pays `ResourceLedger`, then calls `PilotableVehicle.restore_from_wreck()`. `VehicleDefinition.validate()` requires every restoration profile to have a non-empty `cost`, so R1+ component recovery cannot be represented. `FabPipeline` owns payment/jobs and supports `build_token`, `unlock`, `resource`, and bounded Operator consumable outputs; recipe locking is ARRN-only. `FabricationTerminalViewModel` independently re-derives ARRN lock state, creating a second lock-policy implementation. `InventoryManager` owns persistent stackable items but has only single-item add/remove/has methods. The reviewed Scout class has a blocking R0-01 because production still pays raw resources at the wreck; the separate Scout correction is already authored and depends on this workstream's paired review.
- Evidence: `design/02_features/vehicles/VEHICLE_RECOVERY_REVERSE_ENGINEERING.md`; reviewed diagnosis/knowledge predecessor; `custodian/game/vehicles/{vehicle_restoration_interaction,vehicle_definition,pilotable_vehicle}.gd`; `custodian/content/vehicles/vehicle_restoration_profiles.json`; `custodian/autoload/fab_pipeline.gd`; `custodian/content/fabrication/fab_recipes.json`; `custodian/game/ui/terminal/fabrication_terminal_view_model.gd`; `custodian/game/systems/core/systems/inventory_manager.gd`; Scout review finding R0-01 and its active correction packet.
- Task-specific authority: `VEHICLE_RECOVERY_REVERSE_ENGINEERING.md`; reviewed `VehicleKnowledgeState` public requirement-query API; `ResourceLedger` raw-material mutation; `FabPipeline` recipe/job/output authority; `InventoryManager` ordinary carried-item authority; `PilotableVehicle` wreck/health lifecycle.
- Work surface: New `custodian/content/vehicles/vehicle_components.json`; `custodian/content/vehicles/vehicle_restoration_profiles.json` schema/data contract; `custodian/game/vehicles/{vehicle_component_catalog,vehicle_definition,vehicle_restoration_interaction}.gd` (new catalog helper if useful); `custodian/autoload/fab_pipeline.gd`; `custodian/content/fabrication/fab_recipes.json`; `custodian/game/ui/terminal/fabrication_terminal_view_model.gd`; `custodian/game/systems/core/systems/inventory_manager.gd`; new focused validation/fixtures and `validation_manifest.json`. Do not edit `field_scout_recovery_light` into R1 in this slice.
- Change: Implement the exact contracts below. Keep recipe-lock policy centralized in `FabPipeline`; keep component mutation centralized in `InventoryManager`; keep vehicle lifecycle centralized in `PilotableVehicle`.
- Preserve: Existing Fabricator power/service/job timing; existing ARRN `requires_arrn_benefit`; ResourceLedger payment-at-job-start; BuildInventory construction tokens; Operator consumable output; held restoration cancellation semantics; same-instance restoration; current Scout runtime until the dependent correction migrates its profile.
- Non-goals: No production Scout profile migration, no Scout class smoke rewrite, no physical loose-part actors, no advanced fabricator tier, no R3/R4 runtime, no freeform crafting grid, no production art, no economy-wide rebalance.
- Acceptance: (1) Restoration profile validation recognizes only `PATCHWORK, SERVICE, TECHNICAL, RESTRICTED, RELIC`. (2) PATCHWORK requires a non-empty raw `cost` and rejects component-only ambiguity; SERVICE+ requires non-empty `required_components` and rejects raw direct `cost`. (3) `FabPipeline` can output `inventory_item` to InventoryManager and reports failure rather than silently dropping output if inventory authority is unavailable. (4) Existing ARRN recipe locks still work. (5) Vehicle knowledge and pattern requirements are checked by `FabPipeline`, not by terminal UI. (6) Terminal work orders receive one authoritative lock state/reason and can display `KNOWLEDGE INSUFFICIENT` / `PATTERN UNKNOWN` style reasons instead of generic unlock text. (7) InventoryManager can preflight and consume a dictionary of component counts without partial mutation. (8) R0 fixture still pays raw ResourceLedger materials only after the held restoration completes. (9) R1 fixture refuses raw resources, reports missing items, cancels for free, consumes exact fabricated items once, then restores the same vehicle. (10) R2 fixture remains locked until both configured knowledge and pattern requirements pass, then fabricates through normal FabPipeline resource payment/job completion. (11) Three production Scout component recipes exist as starter-known `inventory_item` recipes but production Scout binding remains for its downstream correction.
- Validation: Add `vehicle_part_fabrication_recovery` manifest coverage. Re-run `vehicle_diagnosis_knowledge`, fabrication terminal command/clickable/readability tests affected by recipe state, `vehicle_wreck_restoration`, `vehicle_registry_contract`, lifecycle/exit checks, InventoryManager focused persistence tests if present, packet contracts, then changed-file closeout. Validation must include a synthetic/fixture R0 profile and synthetic R1/R2 definitions so the generic API is proven without stealing the production Scout correction's acceptance.
- Task overrides: `none`
- Deferred: Production Scout profile migration is the already-authored correction; R3 advanced-fabricator capability; R4 Archive/donor requirements; physical part props; final recipe balance.

## Required implementation shape

### 1. Recovery-grade schema

Extend the restoration-profile contract consumed by `VehicleDefinition.validate()`.

Canonical grades:
```text
PATCHWORK
SERVICE
TECHNICAL
RESTRICTED
RELIC
```

Rules:
- `PATCHWORK`: must have non-empty `cost`; `required_components` must be empty/absent.
- `SERVICE`, `TECHNICAL`, `RESTRICTED`, `RELIC`: must have non-empty `required_components`; direct `cost` must be empty/absent.
- Every component count must be positive integer.
- Existing `initial_state=WRECKAGE`, positive `hold_duration`, and `restored_health_fraction in (0,1]` remain mandatory.

Do not interpret a missing grade as PATCHWORK for new data. If compatibility with the currently-landed Scout is needed during this slice, keep the legacy cost-only profile readable behind one explicit compatibility branch with a named removal condition: the downstream Scout correction. Do not let that compatibility become the new schema default.

### 2. Vehicle component catalog

Create `custodian/content/vehicles/vehicle_components.json` with at minimum:

```text
field_drive_coupler_mk1
custodian_control_relay_mk1
structural_brace_kit_mk1
```

Each row should provide a player-facing label, component family/domain tags, and optional description. Keep component identity separate from fabrication recipes so restoration/UI/art can resolve the same semantic part ID.

A small `vehicle_component_catalog.gd` helper is preferred over duplicating JSON parsing in the restoration interaction and terminal.

### 3. Scout starter recipes

Add these production recipes to `custodian/content/fabrication/fab_recipes.json`. They are **starter-known**: no vehicle-knowledge/pattern gate in V1.

#### `field_drive_coupler_mk1`
- label: `Field Drive Coupler Mk I`
- category: `vehicle`
- cost: `ruin_scrap: 5`, `structural_alloy: 2`
- build_seconds: `4.5`
- output_type: `inventory_item`
- output_id: `field_drive_coupler_mk1`
- output_amount: `1`

#### `custodian_control_relay_mk1`
- label: `Custodian Control Relay Mk I`
- category: `vehicle`
- cost: `ruin_scrap: 2`, `power_components: 1`
- build_seconds: `3.5`
- output_type: `inventory_item`
- output_id: `custodian_control_relay_mk1`
- output_amount: `1`

#### `structural_brace_kit_mk1`
- label: `Structural Brace Kit Mk I`
- category: `vehicle`
- cost: `ruin_scrap: 5`, `structural_alloy: 4`
- build_seconds: `4.0`
- output_type: `inventory_item`
- output_id: `structural_brace_kit_mk1`
- output_amount: `1`

Aggregate raw inputs intentionally equal the existing Scout direct-restoration bill (12 ruin scrap, 6 structural alloy, 1 power component). This migration therefore adds fabrication, logistics, and installation meaning without silently rebalance-taxing the first vehicle.

### 4. FabPipeline lock and output authority

In `custodian/autoload/fab_pipeline.gd`:

- add an `inventory_item` output branch that resolves `/root/InventoryManager` and calls its public add API;
- fail visibly if the output cannot be delivered; do not mark a job successfully completed while dropping its output;
- keep ResourceLedger payment at job start unchanged;
- extend the single recipe-lock policy to evaluate:
  1. existing `requires_arrn_benefit`;
  2. optional vehicle-domain requirements;
  3. optional vehicle-pattern requirements through `/root/VehicleKnowledgeState`;
- expose one public/read-model lock reason so terminal UI does not reimplement policy.

Preferred recipe requirement shape supports multiple future gates:
```json
{
  "requires_vehicle_knowledge": [
    {"domain": "POWERTRAIN", "level": 2}
  ],
  "requires_vehicle_patterns": [
    {"pattern_id": "advanced_power_conditioner", "evidence": 2}
  ]
}
```

Accepting the previously-authored single-object shape for compatibility is fine if normalized immediately at load/query time. Do not create two permanent schema forms.

### 5. Fabrication terminal projection

`FabricationTerminalViewModel` currently re-checks ARRN itself in `_is_recipe_locked()`. Remove that policy duplication.

Recommended change:
- `FabPipeline.get_all_recipes()` annotates recipes with `locked` and `lock_reason`, or expose an equivalent read method;
- ViewModel consumes that result only;
- add `vehicle` to `CATEGORY_PRIORITY` / `CATEGORY_PURPOSE`;
- render `inventory_item` results as replacement components, not Ready Builds;
- selected locked work order surfaces the authoritative reason:
  - `KNOWLEDGE INSUFFICIENT // MOBILITY 1/2`
  - `PATTERN UNKNOWN // POWER CONDITIONER 1/2`
  - retain existing ARRN language for ARRN locks.

Do not add a separate vehicle research page in this slice.

### 6. Atomic carried-component mutation

In `inventory_manager.gd`, add a narrow generic multi-item API, recommended:
```gdscript
func can_remove_items(requirements: Dictionary) -> bool
func remove_items(requirements: Dictionary) -> bool
```

Requirements:
- validate every requested count before mutating anything;
- reject invalid/non-positive counts;
- do not expose or mutate `_items` from vehicle code;
- complete all item changes or none;
- emit ordinary per-item count signals and one coherent final inventory-changed notification;
- keep `CANONICAL_RESOURCE_ITEMS` / ResourceLedger routing behavior safe. Vehicle component requirements are ordinary inventory items, not ResourceLedger aliases.

### 7. VehicleRestorationInteraction dual mode

Refactor `vehicle_restoration_interaction.gd` so configuration captures:
- `recovery_grade`;
- PATCHWORK `resource_cost` **or** R1+ `required_components`;
- hold duration/fraction.

Preflight:
- PATCHWORK queries ResourceLedger.
- R1+ queries InventoryManager.
- Missing R1+ components must block starting the hold and make `get_interaction_prompt()` name missing components using the component catalog.
- No resource/item mutation occurs at start.

Completion:
1. revalidate target is still wreckage and actor/hold contract is valid;
2. revalidate target can accept restoration (add a side-effect-free `PilotableVehicle.can_restore_from_wreck()` helper if needed rather than duplicating private lifecycle conditions);
3. PATCHWORK: atomic `ResourceLedger.pay()`;
4. R1+: atomic `InventoryManager.remove_items()`;
5. call `restore_from_wreck()`;
6. if the lifecycle transition unexpectedly rejects after a successful component/resource commit, fail loudly and restore/refund the committed requirements before returning. Never strand paid requirements on an un-restored wreck.

Preserve existing release/target-loss/range/UI/death cancellation behavior from the reviewed hold correction.

### 8. Generic fixtures, not premature Scout binding

Create validation-only fixtures for:
- R0 PATCHWORK direct cost;
- R1 SERVICE components;
- R2 TECHNICAL components plus one knowledge requirement and one pattern requirement.

The production Scout recipes may land here, but **do not edit `field_scout_recovery_light` or the Scout class smoke**. The active Scout correction owns that final production migration.

### 9. Validation ownership

Create `custodian/tools/validation/vehicle_part_fabrication_recovery_smoke.gd` and register `vehicle_part_fabrication_recovery`.

It must prove:
- existing ARRN lock still works;
- R2 lock reason differs for missing knowledge vs missing pattern;
- material payment on part recipe happens once at Fab start;
- inventory item arrives only at job completion;
- R1 raw materials at wreck do nothing;
- missing components are reported;
- interrupted install consumes none;
- completed install consumes exact components;
- reentrant completion cannot double-consume;
- R0 direct-material fixture still works;
- BuildInventory does not receive replacement parts.

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh instruction: Reconcile the reviewed `VehicleKnowledgeState` public API and current restoration helper names. Preserve the slice boundary: generic component machinery here; production Scout profile migration remains in its existing correction packet.

## Handoff

- Next workstream: `review-vehicle-part-fabrication-recovery-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Summary backlink: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh reason: `none`
- Next action: Review generic R0/R1/R2 recovery and fabrication authority before releasing the Scout R0-01 correction.
- Blockers or open questions: `none`
