# VEHICLE ART DERIVATION V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vehicle-art-derivation-v1`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `review-vehicle-presentation-contract-v1`
- Locks: `asset-pipeline-vehicle, vehicle-art-derivation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, asset-pipeline`
- Paired review workstream: `review-vehicle-art-derivation-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial reusable vehicle architecture and production pipeline change`
- Reviewed main: `3067be7817c1713f989a92753a7d199e913b82bc`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Visual review: `conditional`
- Goal: Generalize deterministic sprite import for irregular source regions, one family-level vehicle registration, derived parked/wreck states and non-destructive build-time skins.
- Completion boundary: Done when shared sprite-import supports explicit ordered regions with SHA-bound plans, vehicle body states reuse one registration envelope, declared derived states rebuild reproducibly, and skin outputs retain complete provenance before normal Asset V2 ingest.
- Current measured state: `sprite_import/shared_transform.py` already gives common transform/anchor rendering for fixed layouts but cannot encode irregular regions; V7 therefore needs a one-off migration and vehicle families have no generic derived-state lineage.
- Evidence: `design/04_architecture/VEHICLE_INTEGRATION_SYSTEM_V1.md`; live vehicle registry/runtime; Asset V2 and sprite-import owners; relevant predecessor packets/reviews.
- Task-specific authority: `VEHICLE_INTEGRATION_SYSTEM_V1.md` plus the existing owner of each touched domain; do not move gameplay authority into presentation/tooling.
- Work surface: `custodian/tools/assets/sprite_import/`; bounded vehicle derivation helper under `custodian/tools/vehicles/`; generated derivation/registration receipts; focused validation.
- Change: Implement only this bounded slice using existing owners and deterministic generated projections.
- Preserve: Vehicle lifecycle, movement, health, recovery, inventory/resources, registry identity and Asset V2 ownership unless explicitly named by this slice. Runtime never reads Dropbox/source_work.
- Non-goals: No production second vehicle; no gameplay rebalance; no unrelated asset-pipeline redesign.
- Acceptance: (1) explicit-region rectangles/order/source are part of plan digest; (2) out-of-bounds/ambiguous region sets fail closed; (3) common family root/ground/scale prevents state-size wobble; (4) parked derives from declared drive frame and wreck from declared destroy endpoint; (5) skin composition never overwrites base art and is deterministic; (6) existing fixed-grid imports remain green; (7) receipts include source/plan/rule/output hashes.
- Validation: Focused slice validation first, then relevant vehicle/Asset V2 regressions, then `python3 custodian/tools/validation/run_validation.py --changed --json` and `git diff --check`.
- Task overrides: `none`
- Deferred: runtime presentation and end-to-end orchestration.

## Handoff

- Next workstream: `review-vehicle-art-derivation-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Summary backlink: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh reason: `none`
- Next action: Review deterministic derivation and release VI4 when VI2 review is also complete.
- Blockers or open questions: `none`
