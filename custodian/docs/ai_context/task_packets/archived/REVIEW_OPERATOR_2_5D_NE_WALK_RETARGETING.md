# Review Operator 2.5D NE Walk Retargeting

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-2-5d-ne-walk-retargeting`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `operator-2-5d-ne-walk-retargeting`
- Locks: `operator-ne-walk-authoring`
- Review: `none`
- Review target workstream: `operator-2-5d-ne-walk-retargeting`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_2_5D_NE_WALK_RETARGETING.md`
- Reviewed main: `675ccf726bb79397b7242ef3059971a6f1a39448`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe`
- Visual review: `conditional`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, visual, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently falsify the final, user-visually-accepted NE walk retargeting implementation after implementation closeout/land, without reauthoring human art decisions.
- Reviewed implementation acceptance: `custodian/docs/ai_context/task_packets/archived/OPERATOR_2_5D_NE_WALK_RETARGETING.md` final acceptance: exact immutable 15x128x128 NE donor/rig/source, reproducible 1920x128 binary-alpha source-palette output, human-accepted gait crossover and support/secondary/occlusion/seam, 15/15 existing geometry/contact/continuity, honest solver fitting/pitch costs, valid Dropbox visual-review decisions/cleanup, and no unauthorized runtime/FPS promotion.
- Review evidence: Exact landed commit and root summary, archived implementation packet and iteration ledger/receipts, accepted hashes and current tests, prior Dropbox manifest IDs and retained decision reports. All visual material is advisory; user approval must be present in durable receipts.
- Correction threshold: Wrong source/rig/annotation authority, bad crossover/lead, missing evidence of 15/15 true rendered contact, vacuous threshold/smoothing pass, mutated locked source, invalid phase/occlusion, missing human acceptance, implicit runtime/FPS publication, broken per-iteration hold/Dropbox route, or unregistered validation coverage.
- Focused validation: `python3 custodian/tools/validation/operator_ne_motion_plan_smoke.py`; `python3 custodian/tools/validation/operator_ne_rigid_raster_smoke.py` where Aseprite available; compare pinned hashes and rendered report; `python3 custodian/tools/validation/run_validation.py --changed --base HEAD --json` as applicable; `git diff --check`. Avoid redundant full-capture or broad expensive sweeps.
- Review focus: Source authority and data provenance, no duplicate solver, IK continuity and both crossover signs, 6→7/13→14 support, F15→1 seam, published evidence accuracy, source lock, alpha/robe/sole diagnostic honesty, human visual decisions, approval-versus-runtime segregation, and workstream/Dropbox pause lifecycle.
- Acceptance: Fresh-context findings-first receipt with stable R<cycle>-NN classification and zero blocking defects or material evidence gaps for PASS. Bounded correction workstreams only for confirmed implementation faults or proof gaps; route genuine unresolved subjective judgments to human-required. Do not patch the reviewed implementation from this review packet.
- Non-goals: No second user-art-review process, no regrading art that ChatGPT/user approved, no new reference or rig, no runtime import/selector modification, no auto-promotion of source or FPS.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Review Hold

This draft review is not a current dispatch target. The implementation is a single continuing workstream with explicit human visual review after each local branch checkpoint. Until ChatGPT/user has accepted the entire loop, and the implementation has been legitimately landed/archived, DO NOT claim or promote this review packet.

The authoritative review conversation is this exact [CUSTODIAN planning/review chat](https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe). The authoritative human visual lane is **only**:
`/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/` through `publish_review_artifacts.py`, using its exact iteration manifests and the user-authored ChatGPT conversation. A fresh technical reviewer reuses durable evidence and cannot grant subjective approval.

## Procedure

1. Confirm implementation `operator-2-5d-ne-walk-retargeting` archived complete on origin/main and a genuine source-locked human animation acceptance receipt exists.
2. Begin a genuinely fresh context, reconstruct from the live implementation/accepted evidence rather than prior Luna reasoning, and verify the technical acceptance from real source and tests.
3. Focus on incorrect crossover-sign regressions, filled-part raster holes versus true costume seams, inaccurate boot contact/occlusion claims, phony fitting reductions, and unbounded workstream automation. Never infer artist acceptance from green probes.
4. Return independent findings by ID, domain, class and disposition, plus focused validations; require exact repro for corrections.
5. Reuse previously uploaded Dropbox evidence, if still present. A new important Dropbox review handoff is allowed only for a newly exposed material human visual decision, still under the same stable implementation review root and with a unique run-id; otherwise do not recapture.
6. Do not change implementation files in this review; do not request a new live human animation decision for an already accepted unchanged loop.

## Next Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe`
- Refresh reason: `none; final post-land technical acceptance review`
- Next action: `Review final accepted landed implementation only after the dependency is complete; do not claim while human iteration remains open`
- Blockers or open questions: `Implementation is active and animation visual approval is pending`
