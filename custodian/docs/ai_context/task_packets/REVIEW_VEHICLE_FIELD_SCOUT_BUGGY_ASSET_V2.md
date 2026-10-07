# REVIEW: VEHICLE FIELD SCOUT BUGGY ASSET V2

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-vehicle-field-scout-buggy-asset-v2`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `vehicle-field-scout-buggy-asset-v2`
- Locks: `none`
- Review: `none`
- Review target workstream: `vehicle-field-scout-buggy-asset-v2`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/VEHICLE_FIELD_SCOUT_BUGGY_ASSET_V2.md`
- Reviewed main: `5020df4b88a2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, asset-pipeline, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that vehicle Asset V2 support is genuinely family/owner driven and the Scout family, directional seam, fallbacks, and required-assets truth are coherent.
- Reviewed implementation acceptance: Verify every Acceptance clause from the archived packet against landed main.
- Review evidence: Archived packet/summary, live family/schema/tooling/runtime, Asset V2 CLI output, focused fixtures/probes.
- Correction threshold: Correct only confirmed acceptance defects/material proof gaps; defer non-blocking improvements; subjective art direction remains human-owned.
- Focused validation: Run `python3 custodian/tools/validation/asset_pipeline_v21_production_smoke.py`, `python3 custodian/tools/validation/asset_pipeline_cli_ux_smoke.py`, `res://tools/validation/validate_vehicle_registry.gd`, and `python3 custodian/tools/assets/asset.py doctor`, then the implementation-created vehicle-family/post-process smoke recorded in the archived packet.
- Review focus: Look for a disguised second hard-coded importer, wrong direction/mirroring request, stale light_buggy targets, accidental firing-art requirements, consumer/doctor gaps, hover fallback regression, missing wreck/restore state contracts, and tests that never exercise a non-hover owner.
- Acceptance: Publish a findings-first independent review/durable receipt with stable R0-NN IDs. Blocking defects/material gaps create `vehicle-field-scout-buggy-asset-v2-review-corrections-1` plus paired review. Do not patch implementation.
- Non-goals: No global Asset V2 redesign, production art generation, subjective aesthetic approval, gameplay tuning, or implementation fixes.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: If passed, return to https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b for the separate production-art creation/ingest decision.
- Blockers or open questions: `none`
