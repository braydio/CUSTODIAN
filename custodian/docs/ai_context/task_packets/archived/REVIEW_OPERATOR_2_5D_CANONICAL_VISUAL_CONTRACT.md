# REVIEW OPERATOR 2.5D CANONICAL VISUAL CONTRACT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-2-5d-canonical-visual-contract`
- Kind: `review`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-2-5d-canonical-visual-contract`
- Locks: `operator-art-agent, operator-source-normalization, operator-aseprite-tooling`
- Review: `none`
- Review target workstream: `operator-2-5d-canonical-visual-contract`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_2_5D_CANONICAL_VISUAL_CONTRACT.md`
- Reviewed main: `8574dfff5d6153e9638886729e1d34be5cc3bca1`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Visual review: `conditional`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, visual, asset-pipeline, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the exact user-supplied design lock was hardened as the accepted visual authority and the exact relaxed-idle sheet was hardened as the first canonical `operator_2_5d_128` animation family, while preserving deterministic dual-profile migration, direction-specific registration truth, and non-leaking anti-drift guides/QA.
- Non-goals: no art regeneration, no runtime animation replacement, no subjective redesign.
- Required evidence: design lock source hash `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`, 2048x256 geometry and N/NE/E/SE/S/SW/W/NW order; first-animation source hash `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`, 1920x1024 geometry, 15x8 layout and 128x128 cells; immutable source-work copies; specialized Operator schema ownership; semantic identity `unarmed/posture/idle_relaxed_01/full_body`; exact-pixel preservation through intake; profile v1/v2 backward compatibility; accepted canonical-128 profile/reference hashes; reproducible landmarks/measurements; deterministic palette/brightness/silhouette reports; Aseprite guide exclusion; intentional drift fixtures caught.
- Acceptance: zero blocking source-integrity/profile-migration/guide-leak defects; exact supplied bytes remain unchanged; the design sheet is the accepted lock; the relaxed idle is the first canonical family rather than a synthetic target or legacy fallback; no runtime cutover is smuggled into this slice. Subjective redesign is forbidden because the user already locked the visual authority.
- Validation: focused canonical visual-contract + registration-profile tests + `git diff --check` only.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Agent Handoff / Planning Decisions — 2026-10-08

The implementation's human review gate is already resolved in the authoring chat. **Do not reopen these decisions during paired review unless the landed implementation contradicts them or cannot encode them safely.**

- Accepted registration: frame 128x128, center_x 64, projected_world_root `[64,106]`, shadow_origin/ground `[64,107]`, common across all eight directions. Lowest alpha is not semantic-root authority.
- Legacy east `fast_02` overflow is non-authoritative proxy evidence and does not require a larger global canvas, root shift, or scale reduction. The accepted 128 profile is a body/reference registration frame with universal action-envelope fit explicitly unasserted. Future true canonical overflow may use root-preserving action-specific envelopes/modular presentation.
- Normalized reference SHA `e529df0e0ceaeb941f67ed18ce93799755053b7c516a9f02a5b6929248e25fb9` is accepted unchanged; no cleanup pixels are authorized.
- `operator_2_5d_128` may be accepted/canonical once the implementation records the above semantics.
- Relaxed-idle FPS/timing remains unknown/null and is not a visual-contract blocker; do not infer it from the PNG.
- Ranged aim, wide block-hit and all-direction extreme-envelope proof are future per-action evidence, not grounds to fail this review by themselves.
- Reviewer focus: verify the implementation encoded these decisions exactly, preserved source/reference hashes, preserved legacy-96 compatibility, did not smuggle in runtime cutover, and cleaned/closed the reviewed human-handoff state.

## Handoff

- Next workstream: `operator-2-5d-workbench-cockpit-foundation`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: `the paired review passed; WB25-1 needs the accepted profile/reference hashes and first-family source hash in the authoring chat before it is refreshed to ready/auto`
- Next action: `return this passed review receipt, profile hash 05e92192af68b2f4e7516f59a0938e536926f3525a31b42dd7695f61d77ca761, reference hash e529df0e0ceaeb941f67ed18ce93799755053b7c516a9f02a5b6929248e25fb9, and first-family source hash d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3 to the authoring chat; refresh WB25-1 in place to ready/auto before claim`
- Blockers or open questions: `none`
