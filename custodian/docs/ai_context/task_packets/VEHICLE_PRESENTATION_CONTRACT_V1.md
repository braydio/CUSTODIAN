# VEHICLE PRESENTATION CONTRACT V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vehicle-presentation-contract-v1`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `review-vehicle-recovery-fx-production-v1`
- Locks: `vehicle-presentation-contract, vehicle-registry-data`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-vehicle-presentation-contract-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial reusable vehicle architecture and production pipeline change`
- Reviewed main: `ad846c21ef7f3d41cb437a9042555e907c3a2a63`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Visual review: `none`
- Goal: Replace the two-field visual-kit compatibility mapping with validated visual-kit V2 inheritance, semantic states, component-socket presentation metadata, anchors and shared-FX fitting data.
- Completion boundary: Done when the registry resolves one typed/read-only presentation definition per vehicle, v2 inheritance/failure rules are validated, and schema-v1 Scout compatibility remains behaviorally readable until migration.
- Current measured state: `vehicle_visual_kits.json` is schema v1 with only SpriteFrames/default/move; PilotableVehicle reparses it directly; there is no inheritance, semantic state map, fitting policy or anchor contract.
- Evidence: `design/04_architecture/VEHICLE_INTEGRATION_SYSTEM_V1.md`; `design/02_features/vehicles/VEHICLE_INITIAL_FLEET_ASSET_PROGRAM_V1.md`; live vehicle registry/runtime; Asset V2 and sprite-import owners; relevant predecessor packets/reviews.
- Task-specific authority: `VEHICLE_INTEGRATION_SYSTEM_V1.md` plus the existing owner of each touched domain; do not move gameplay authority into presentation/tooling.
- Work surface: `custodian/content/vehicles/vehicle_visual_kits.json`; new presentation definition/catalog under `custodian/game/vehicles/presentation/`; `vehicle_definition.gd`; `vehicle_registry.gd`; focused validator.
- Change: Implement only this bounded slice using existing owners and deterministic generated projections.
- Preserve: Vehicle lifecycle, movement, health, recovery, inventory/resources, registry identity and Asset V2 ownership unless explicitly named by this slice. Runtime never reads Dropbox/source_work.
- Non-goals: No production second vehicle; no gameplay rebalance; no unrelated asset-pipeline redesign.
- Acceptance: (1) resolved v2 kit exposes body/derived/procedural/shared-FX/component-socket/anchor/skin/attachment data; (2) deterministic inheritance and cycle rejection; (3) anchors validate normalized [0,1]; (4) fitting policies limited to CENTER/BOUNDS/ANCHOR/PATH; (5) v1 Scout compatibility still resolves unchanged; (6) registry resolves once so vehicle instances do not parse visual-kit JSON; (7) validation-only sibling kit inherits body without duplicate body references; (8) socket definitions validate stable socket ID, domain, anchor, compatible component IDs and visual-state mapping without owning inventory/restoration state.
- Validation: Focused slice validation first, then relevant vehicle/Asset V2 regressions, then `python3 custodian/tools/validation/run_validation.py --changed --json` and `git diff --check`.
- Task overrides: `none`
- Deferred: runtime rig, art derivation, generated resources, CLI and Scout canonical-art migration.

## Handoff

- Next workstream: `review-vehicle-presentation-contract-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Summary backlink: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh reason: `none`
- Next action: Review the contract, then release VI2 and VI3.
- Blockers or open questions: `none`
