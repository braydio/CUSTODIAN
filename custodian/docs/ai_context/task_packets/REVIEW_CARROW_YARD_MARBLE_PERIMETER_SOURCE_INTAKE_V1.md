# REVIEW: CARROW YARD MARBLE PERIMETER SOURCE INTAKE V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-carrow-yard-marble-perimeter-source-intake-v1`
- Authoring handoff: `auto`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `carrow-yard-marble-perimeter-source-intake-v1`
- Locks: `carrow-yard-art, asset-pipeline`
- Review: `none`
- Review target workstream: `carrow-yard-marble-perimeter-source-intake-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/CARROW_YARD_MARBLE_PERIMETER_SOURCE_INTAKE_V1.md`
- Reviewed main: `9c607b6d5df1`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad5eb5a-598c-83ea-b982-531d4ff5418f`
- Visual review: `required`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `asset-pipeline, visual, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently falsify the provenance, exact crop reproduction, integrity, safe SOURCE_READY_NEEDS_TUNE staging and runtime-seam evidence of the marble Carrow perimeter source intake without awarding production readiness.
- Reviewed implementation acceptance: All A1–A7 of the archived `CARROW_YARD_MARBLE_PERIMETER_SOURCE_INTAKE_V1.md` and its explicit human gate.
- Review evidence: Dropbox SHA-256 archive `9079d308412f3c1cef3840d730bb9234da074ad8f09232e8db6be20509b92392`, package `MANIFEST.json`, original clean 1312x1199 master, three extracted files and hashes, independent exact reconstructed pixels, latest main source_work, source provenance, native 32px Operator/Camera2D seam screenshots, original 7-source source state inventory, the preserved `d033eef4f` historical donor and a live dispatcher audit.
- Correction threshold: Any unchecked source hash, cropped mismatch, non-RGBA or missing pixel, skipped installer collision, destroyed/replaced source or protected previous claim, false independent seam claim, non-empty normalized inbox before human approval, auto claim of blocked old workstream, or incorrect asset-family state is a material defect.
- Focused validation: Re-run SHA-256 checks and maintained `verify_marble_slices.py`; verify source destinations unchanged aside from exact expected additions; independently rebuild L from crop coordinates and compare pixels; inspect actual E-W and N-S seam offsets and occlusion, not merely exact L reconstruction; run Asset V2 family status / doctor and native scale focused preview if present; inspect dispatcher evidence and changed-file checks.
- Review focus: Documented source transport available to claimed worker, correct SHA-256, transport not confused with family contract, three-state distinction, correct no-inbox boundary, explicit reusable N-S underlap evaluation, no collision-alpha inference, old branch preserved, remaining docs accurate.
- Acceptance: Findings-first fresh review with stable finding IDs and independent evidence; do not patch the reviewed source-intake implementation.
- Non-goals: Do not normalize, ingest, approve, regenerate, implement traversal, redesign camera, change route ownership, land blocked historical donor or use unapproved imagery.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only durable review receipt, review packet lifecycle/archive metadata, closing summary, and bounded correction/re-review packets; do not edit reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `carrow-yard-volumetric-perimeter`
- Next packet state: `human-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad5eb5a-598c-83ea-b982-531d4ff5418f`
- Refresh reason: Runtime-integrated tiling and original protected volumetric workstream may proceed only with fresh reconciliation and explicit human art approval.
- Next action: Report source staging findings, repeat offsets and visual evidence before unblocking any runtime art.
- Blockers or open questions: Native repeat seams and anchors are not yet accepted.
