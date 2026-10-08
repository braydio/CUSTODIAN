# REVIEW OPERATOR 2.5D CANONICAL VISUAL CONTRACT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-2-5d-canonical-visual-contract`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-2-5d-canonical-visual-contract`
- Locks: `operator-art-agent, operator-source-normalization, operator-aseprite-tooling`
- Review: `none`
- Review target workstream: `operator-2-5d-canonical-visual-contract`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_2_5D_CANONICAL_VISUAL_CONTRACT.md`
- Reviewed main: `91e8ba079681fbf5e8ce2b2a4263e451f106ffa2`
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
## Handoff

- Next workstream: `operator-2-5d-workbench-cockpit-foundation`
- Next packet state: `refresh-required`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: `after this review passes, all WB25-1 prerequisites are satisfied; return accepted profile/reference hashes and first-family provenance to the planning chat for the final ready/auto refresh`
- Next action: `return the passed review receipt plus accepted design-reference/profile hashes and first-family source hash to the authoring chat; refresh WB25-1 in place to ready/auto before claim`
- Blockers or open questions: `none if the exact-input hardening and profile acceptance pass; any byte mismatch or unresolved semantic-root contradiction is blocking`
