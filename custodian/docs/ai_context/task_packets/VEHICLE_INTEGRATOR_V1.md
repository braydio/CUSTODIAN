# VEHICLE INTEGRATOR V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vehicle-integrator-v1`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `review-vehicle-presentation-runtime-v1, review-vehicle-art-derivation-v1`
- Locks: `vehicle-integration-tooling, vehicle-presentation-runtime, asset-pipeline-vehicle`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, asset-pipeline, workflow`
- Paired review workstream: `review-vehicle-integrator-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial reusable vehicle architecture and production pipeline change`
- Reviewed main: `ad846c21ef7f3d41cb437a9042555e907c3a2a63`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Visual review: `conditional`
- Goal: Deliver one guarded source-to-runtime Vehicle Integrator CLI, generated presentation/integration receipts, migrate the Field Scout through the first complete body/socket/recovery/destruction presentation loop, and prove same-chassis body reuse with a fixture sibling kit.
- Completion boundary: Done when inspect/plan/status/check are read-only, mutating stages explicitly delegate existing tools, generated presentation resources/receipts are deterministic, Scout no longer depends on direct hover animation ownership, and a sibling fixture inherits its body with zero duplicate body PNGs.
- Current measured state: There is no vehicle integrator/receipt; source staging, sprite import, Asset V2, runtime building and scene binding are separate; `update_vehicle_runtime_resources.gd` remains hover-specific and Scout still references compatibility frames.
- Evidence: `design/04_architecture/VEHICLE_INTEGRATION_SYSTEM_V1.md`; `design/02_features/vehicles/VEHICLE_INITIAL_FLEET_ASSET_PROGRAM_V1.md`; `design/02_features/vehicles/VEHICLE_RECOVERY_ART_MANIFEST.md`; Scout full-loop handoff `/CUSTODIAN/implementation_inputs/custodian_field_scout_buggy_full_vehicle_loop_handoff_v1_20261021.zip`, Dropbox `id:8NXqdXuW6GUAAAAAAAAEkg`, outer SHA256 `2ca1b82b3c83e84d607aed5ac79f55277cb764e3116919053687d644c721b2df`; live vehicle registry/runtime; Asset V2 and sprite-import owners; relevant predecessor packets/reviews.
- Task-specific authority: `VEHICLE_INTEGRATION_SYSTEM_V1.md` plus the existing owner of each touched domain; do not move gameplay authority into presentation/tooling.
- Work surface: new `custodian/tools/vehicles/{vehicle_integrator.py,build_vehicle_presentation.py,vehicle_integration_status.py}`; generated `custodian/content/vehicles/generated/`; generated `custodian/content/metadata/vehicles/generated/`; Scout kit/scene migration; focused end-to-end validation.
- Change: Implement only this bounded slice using existing owners and deterministic generated projections.
- Preserve: Vehicle lifecycle, movement, health, recovery, inventory/resources, registry identity and Asset V2 ownership unless explicitly named by this slice. Runtime never reads Dropbox/source_work.
- Non-goals: No production second vehicle; no gameplay rebalance; no unrelated asset-pipeline redesign.
- Acceptance: (1) CLI provides inspect/plan/stage/derive/ingest/build/wire/validate/status/integrate; (2) plan reports source/state/direction/derivation/procedural/shared/skin/attachment/output/consumer/missing/validation truth before mutation; (3) integrator delegates handoff, shared sprite import, Asset V2 and validation; (4) generated presentation resource and integration receipt reproduce exactly; (5) Scout runs through reusable rig with canonical Asset V2 art/shared FX fitting; (6) parked/wreck lineage is derived; (7) sibling fixture adds no duplicate body PNG; (8) no runtime Dropbox/source_work/inbox references; (9) hover-specific builder is removed iff zero production consumers; (10) stale generated projections are detected by check/status; (11) all focused vehicle/Asset V2 checks pass; (12) the Scout presentation resource can bind the three declared Phase-1 socket overlays plus directional destruction FX/shared smoke/recovery FX without making presentation a second component or lifecycle authority; current aggregate component restoration remains mechanically valid even if staged per-socket installation has not landed.
- Validation: Focused slice validation first, then relevant vehicle/Asset V2 regressions, then `python3 custodian/tools/validation/run_validation.py --changed --json` and `git diff --check`.
- Task overrides: `none`
- Deferred: first real sibling vehicle, first R2 vehicle, advanced attachment animation/LOD/3D pipeline.

## Handoff

- Next workstream: `review-vehicle-integrator-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Summary backlink: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh reason: `none`
- Next action: Review the end-to-end system before V8 content.
- Blockers or open questions: `none`
