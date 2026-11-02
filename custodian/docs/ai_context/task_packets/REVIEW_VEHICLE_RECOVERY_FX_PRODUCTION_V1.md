# REVIEW: VEHICLE RECOVERY FX PRODUCTION V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-vehicle-recovery-fx-production-v1`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `vehicle-recovery-fx-production-v1`
- Locks: `none`
- Kind: `review`
- Review: `none`
- Review target workstream: `vehicle-recovery-fx-production-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/VEHICLE_RECOVERY_FX_PRODUCTION_V1.md`
- Reviewed main: `f12717e61213d7d30ae6b3e670d45e71507cd784`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime, asset-pipeline`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently prove the six human-selected recovery FX were promoted through Asset V2 without source drift, frame/registration corruption, hard-coded runtime coupling, or a second vehicle/recovery state authority, and that the real scanner/install/recovery events drive the intended presentation while gameplay remains independent of it.
- Reviewed implementation acceptance: Verify every Acceptance clause in the archived implementation packet against live main, with special attention to source hashes, deterministic normalization receipts, generated SpriteFrames truth, event ordering, failure classification, and the presentation-only boundary.
- Review evidence: Reuse the implementation closing summary, immutable Dropbox handoff identity/hash, source-work/inbox/runtime hashes, normalization receipt, Asset V2 request/plan/status/doctor/needs evidence, `build_vehicle_recovery_fx_spriteframes.py --check`, `vehicle_recovery_fx_smoke.gd`, existing diagnosis/component-recovery/Scout lifecycle validations, changed files, and current live main. Gather fresh evidence only where needed to falsify acceptance.
- Correction threshold: Blocking findings include any source-byte mismatch; wrong state/frame/FPS/loop contract; per-frame independent scaling or unstable registration; runtime reference to Dropbox/asset_drop; hard-coded guessed canonical runtime PNG path where catalog/family authority should be used; duplicate scan/install/lifecycle state; FX gating payment/restoration/entry; missing fail-soft behavior; spurious cancellation on successful restoration; ordinary user cancellation producing failure ping; successful recovery not producing the exact ordered power-route/bootstrap/success sequence; or required-assets claiming unverified states complete.
- Focused validation: Re-run `python3 custodian/tools/pipelines/build_vehicle_recovery_fx_spriteframes.py --check`, `res://tools/validation/vehicle_recovery_fx_smoke.gd`, current `asset request/plan/status vehicle_recovery_fx_common`, `python3 custodian/tools/assets/asset.py doctor`, `python3 custodian/tools/assets/asset.py needs --check`, `python3 custodian/tools/validation/asset_pipeline_v21_production_smoke.py`, and the touched diagnosis/component-recovery/Scout lifecycle smokes. Use the exact implementation source/normalization receipts before any rendered inspection.
- Review focus: Confirm six exact source SHAs; center registration and one common scale per state; bootstrap 9->8 mapping is deterministic and justified; only install sparks loops; one generated SpriteFrames authority; one presenter instance on Scout; scanner only delegates presentation; held restoration signal order is `started` then either cancellation or completion, never both on success; failure-ping classification is not a new mechanics enum; success FX are cosmetic follow-through; presenter absence leaves mechanics green; active docs/required-assets match measured state.
- Acceptance: Publish findings-first durable review. A pass requires zero blocking defects, zero material evidence gaps, and explicit confirmation that source/normalization/runtime wiring all satisfy the archived implementation packet. Any blocking finding creates bounded correction/re-review work. Do not artistically regenerate or retune the human-approved sources during review.
- Non-goals: No subjective art re-direction; no new FX states; no component icons/props; no vehicle body/destruction art; no gameplay balance changes; no review-time fixes to the reviewed implementation.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## External Source Authority

The reviewer must compare landed source-work bytes against the immutable handoff, not against chat screenshots or generated runtime outputs:

- Dropbox: `/CUSTODIAN/implementation_inputs/custodian_vehicle_recovery_fx_common_production_source_handoff_v1_20261017.zip`
- Dropbox file ID: `id:8NXqdXuW6GUAAAAAAAAESA`
- Outer SHA256: `0bb201621172869a223fddbe79301b2ae576a0e7b748e048fd79c952e55e0623`
- Inner manifest: `custodian_vehicle_recovery_fx_common_production_source_handoff_v1_20261017/MANIFEST.json`

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Summary backlink: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh reason: `none`
- Next action: If passed, close V7 shared recovery FX production as reviewed and leave deferred component icons/props/body polish visible for later art work. If blocked, create only the bounded correction/re-review required by findings.
- Blockers or open questions: `none`