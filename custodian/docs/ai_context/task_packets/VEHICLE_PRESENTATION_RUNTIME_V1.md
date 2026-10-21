# VEHICLE PRESENTATION RUNTIME V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vehicle-presentation-runtime-v1`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `review-vehicle-presentation-contract-v1`
- Locks: `vehicle-presentation-runtime, vehicle-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-vehicle-presentation-runtime-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial reusable vehicle architecture and production pipeline change`
- Reviewed main: `ad846c21ef7f3d41cb437a9042555e907c3a2a63`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Visual review: `none`
- Goal: Add one reusable VehiclePresentationRig/Controller, including compositional component-socket overlays, and remove body animation-selection authority from PilotableVehicle.
- Completion boundary: Done when PilotableVehicle emits semantic motion/lifecycle/event intent, the rig owns state/direction/fallback/procedural playback, V7 recovery FX are composed once, and missing presentation cannot affect mechanics.
- Current measured state: PilotableVehicle directly owns idle/idle_loop/move selection and manipulates its AnimatedSprite2D; Scout scene has no reusable presentation rig.
- Evidence: `design/04_architecture/VEHICLE_INTEGRATION_SYSTEM_V1.md`; `design/02_features/vehicles/VEHICLE_INITIAL_FLEET_ASSET_PROGRAM_V1.md`; live vehicle registry/runtime; Asset V2 and sprite-import owners; relevant predecessor packets/reviews.
- Task-specific authority: `VEHICLE_INTEGRATION_SYSTEM_V1.md` plus the existing owner of each touched domain; do not move gameplay authority into presentation/tooling.
- Work surface: new `custodian/game/vehicles/presentation/{vehicle_presentation_controller.gd,vehicle_presentation_rig.tscn,vehicle_body_presenter.gd,vehicle_component_socket_presenter.gd,vehicle_attachment_presenter.gd}`; narrow PilotableVehicle and Scout/base-scene compatibility wiring.
- Change: Implement only this bounded slice using existing owners and deterministic generated projections.
- Preserve: Vehicle lifecycle, movement, health, recovery, inventory/resources, registry identity and Asset V2 ownership unless explicitly named by this slice. Runtime never reads Dropbox/source_work.
- Non-goals: No production second vehicle; no gameplay rebalance; no unrelated asset-pipeline redesign.
- Acceptance: (1) PilotableVehicle contains no canonical body animation IDs after migration; (2) centralized deterministic 8dir/mirror/fallback resolution; (3) compatibility Scout still plays correctly; (4) engine idle/start/brake/ordinary-impact presets are presentation-only; (5) one recovery presenter only; (6) absent/malformed presentation leaves movement/damage/destruction/restoration/entry functional; (7) no per-frame source/catalog parsing; (8) `ComponentSocketRoot` can show/hide the resolved failed/missing overlay for a declared socket without mutating inventory, fabrication, health, recovery eligibility, or lifecycle.
- Validation: Focused slice validation first, then relevant vehicle/Asset V2 regressions, then `python3 custodian/tools/validation/run_validation.py --changed --json` and `git diff --check`.
- Task overrides: `none`
- Deferred: art normalization/skin baking, integrator CLI, canonical Scout art ingest.

## Handoff

- Next workstream: `review-vehicle-presentation-runtime-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Summary backlink: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh reason: `none`
- Next action: Independently verify mechanics/presentation separation.
- Blockers or open questions: `none`
