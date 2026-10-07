# VEHICLE WRECK RESTORATION FOUNDATION V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vehicle-wreck-restoration-foundation-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-vehicle-runtime-lifecycle-hardening-v1`
- Locks: `vehicle-content, vehicle-runtime-scene, vehicle-restoration-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-vehicle-wreck-restoration-foundation-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `new world-spawn lifecycle, resource payment, interaction, and destruction-to-recovery state transition`
- Reviewed main: `5020df4b88a2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Visual review: `none`
- Goal: Make ordinary world-spawned pilotable vehicles enter the world as zero-health recoverable wreckage and require an explicit ResourceLedger-backed restoration interaction before they can be entered or driven.
- Completion boundary: Done when registry data can name a restoration profile, the Scout profile is live, both resolver-spawned and authored/fallback vehicles initialize as WRECKAGE without emitting fake destruction, wreckage is non-pilotable but exposes one hold-to-restore interaction, successful recovery pays exactly once and transitions the same instance to 40% operational health, later destruction returns that instance to recoverable wreckage, and focused validation proves cancellation/payment/group/lifecycle semantics.
- Current measured state: Reviewed lifecycle V1 now centralizes lethal damage and pilot release in `PilotableVehicle`. `VehicleSpawnResolver` still unconditionally adds a pilotable definition to `pilotable_vehicles`; `PilotableVehicle._ready()` also adds itself to pilotable/interactable groups and initializes healthy/UNOCCUPIED. Registry definitions have no restoration profile. `FieldRepairInteraction` already implements proximity + hold + `ResourceLedger.can_pay/pay`, but intentionally rejects zero-health targets, so it is a useful pattern rather than a wreck-restoration authority. `ResourceLedger` provides canonical atomic `can_pay()` / `pay()`. The original Field Scout class workstream has an existing remote claim with zero commits and must be recovered before overlapping vehicle-content locks can proceed.
- Evidence: `custodian/game/vehicles/pilotable_vehicle.gd`; `vehicle_definition.gd`; `vehicle_spawn_resolver.gd`; `custodian/autoload/resource_ledger.gd`; `custodian/game/infrastructure/repair/field_repair_interaction.gd`; `custodian/content/vehicles/vehicle_archetypes.json`; `vehicle_registry_schema.json`; `design/02_features/vehicles/{VEHICLES,FIELD_SCOUT_BUGGY_MK1}.md`; archived/reviewed lifecycle V1 packet.
- Task-specific authority: `design/02_features/vehicles/VEHICLES.md` world-spawn recovery rule; `design/02_features/vehicles/FIELD_SCOUT_BUGGY_MK1.md` first profile values; `ResourceLedger` material mutation; reviewed `PilotableVehicle` lifecycle ownership.
- Work surface: `custodian/content/vehicles/vehicle_restoration_profiles.json`; vehicle archetype/schema/definition loading; `custodian/game/vehicles/pilotable_vehicle.gd`; `vehicle_spawn_resolver.gd`; new focused `vehicle_restoration_interaction.gd` (or clearly equivalent vehicle-owned component); focused validation and validation-manifest ownership.
- Change: Add restoration-profile identity to vehicle definitions and require a valid profile for ordinary spawnable+pilotable world vehicles. Add `field_scout_recovery_light`: `initial_state=WRECKAGE`, cost `{ruin_scrap:12, structural_alloy:6, power_components:1}`, hold `4.0`, restored-health fraction `0.40`, repeatable after destruction. `PilotableVehicle` owns `is_wreckage()`, initialization into wreckage, and `restore_from_wreck()`; initial wreck setup must not emit `vehicle_destroyed`. While wrecked, retain generic vehicle identity/placement collision but remove operational `pilotable_vehicles` and parent vehicle interaction exposure. Add one restoration interaction component that follows the existing FieldRepair interaction pattern: range/hold, `can_pay` before starting, no spend on cancellation, atomic `pay` only after re-checking target contract at completion, then call `restore_from_wreck(0.40)`. Restoration re-enables operational interaction groups and emits `vehicle_restored`. Later lethal destruction reactivates the same restoration interaction and returns to wreck presentation/state. Remove resolver ownership of operational pilotable-group registration where it would override the vehicle lifecycle state.
- Preserve: Reviewed pilot release/exit safety; vehicle registry stable IDs/classification; movement tuning; world placement positions/counts; ResourceLedger as sole resource mutation authority; FieldRepairInteraction's >0 HP contract; generic Operator interaction flow; no resource spend on interrupted holds.
- Non-goals: No production art creation, no save/load persistence across reconstructed worlds, no fuel, scanner, cargo, passengers, mounted weapons, collision damage, full repair rebalance, or new generic crafting system.
- Acceptance: A freshly instantiated world-spawned Scout reports WRECKAGE, 0 HP, disabled/destroyed lifecycle, cannot enter/drive, is absent from `pilotable_vehicles`, and exposes exactly one restoration interaction. Insufficient resources refuses without mutation; interrupted/out-of-range restoration spends zero; successful restoration spends exactly 12 scrap/6 alloy/1 power component once, restores the same instance to 40/100 HP and operational groups, and allows entry. A later lethal hit emits one real destruction event, returns to wreckage, and permits the same recovery flow again. Initial spawn emits no destruction event. Resolver and direct/fallback scene paths have parity.
- Validation: Run the exact lifecycle smoke recorded by archived V1, `res://tools/validation/validate_vehicle_registry.gd`, and `res://tools/validation/vehicle_exit_clearance_smoke.gd`. Add an implementation-created focused wreck-restoration smoke covering fresh spawn, direct scene fallback, groups, prompt/target, insufficient resources, cancellation, exact payment, 40% health, entry after restore, lethal re-wreck, and repeat restoration; record exact path and add validation-manifest ownership before closeout.
- Task overrides: `none`
- Deferred: Save/load persistence across world reconstruction; class-specific restoration presentation; economy tuning after playtest.

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh instruction: Reconcile only landed lifecycle helper/signal names. Do not revive the pre-restoration class packet. If the empty original class claim still holds overlapping locks, stop and surface claim recovery rather than running vehicle-content work concurrently.

## Handoff

- Next workstream: `review-vehicle-wreck-restoration-foundation-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Summary backlink: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh reason: `none`
- Next action: Finish normally so fresh-context review can prove the recovery lifecycle before the Scout class recovery runs.
- Blockers or open questions: `Existing empty claim agent/vehicle-field-scout-buggy-class-v1 must be recovered if it still holds overlapping locks.`
