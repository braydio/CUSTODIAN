# REVIEW: Sepulcher Paving Native Quad Playtest V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-sepulcher-paving-native-quad-playtest-v1`
- Category: `assets-art`
- Authoring handoff: `auto`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `sepulcher-paving-native-quad-playtest-v1`
- Locks: `sepulcher-native-paving-playtest`
- Review: `none`
- Review target workstream: `sepulcher-paving-native-quad-playtest-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/SEPULCHER_PAVING_NATIVE_QUAD_PLAYTEST_V1.md`
- Reviewed main: `8beb9d9da9a0be46f470f959d111241d19169f88`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime, visual, asset-pipeline`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: `Independently falsify the playable preview's fixed crop/source provenance, real Operator/camera behavior, presentation-only switching, Godot loading, Git LFS source availability, and Asset V2 isolation.`
- Reviewed implementation acceptance: `A1-A6 as recorded in archived SEPULCHER_PAVING_NATIVE_QUAD_PLAYTEST_V1.md; technical preview only; human art approval outside reviewer authority.`
- Review evidence: `Pinned original source and LFS derivative hashes; four pixel rectangles and reconstruction proof; implementation closeout; actual loaded Godot node tree/movement assertions and three same-player/camera view images; host-focused smoke receipts and reviewer reproductions.`
- Correction threshold: `Wrong hash, resized/warped pieces, false pixel identity, placeholder/synthetic Operator, nonworking movement, mode-sensitive camera or collision, missing LFS objects, production Hub mutation, false Asset V2 approval, or false screenshot proofs block. Nonessential visual polish defers; subjective art verdict remains human_required.`
- Focused validation: `python3 custodian/tools/art/sepulcher_paving_native_quad.py --self-test; independent pixel proof with actual preview textures after source retrieval; Godot focused new Sepulcher scene smoke and existing kenney_isometric_blockout_playtest_smoke.gd; changed-file and source-scope checks. Use implementation's screenshot bundle before any recapture.`
- Review focus: `The four 512px pieces exactly reconstruct master crop [128,128,1152,1152]; outer edges are deliberately NOT seamless. All three modes retain the same real Operator and camera. Only dev-bound presentation changes; source_work/master and Asset V2 remain unapproved. Distinguish technical PASS from later human art direction.`
- Acceptance: `Findings-first fresh independent review with stable R0-NN classes/evidence and a canonical passed receipt or bounded correction/re-review; do not self-approve the artwork and do not patch the reviewed scene in this review.`
- Non-goals: `No implementation fixes in review, no separate material sources or wall art, no art approval, no production asset runtime binding or Hub collision edits.`
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after implementation archive complete on current main, with separate fresh reviewer context and original source/input bytes still verifiable.
2. Inspect source, four dev-only images, actual runtime scene and expected input actions; rerun focused independent spatial/render/camera/collision checks. Fail closed on inaccessible Git LFS data or missing source provenance.
3. Reuse exactly three existing same-camera captures; recapture only if absent/contradictory. Evaluate technical screenshot truth, not aesthetic desirability; ask user for subjective preference separately.
4. Publish reviewer receipt with stable findings and conditional human visual handoff. Do not approve art or Asset Pipeline V2.

## Next Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Summary backlink: `not-recorded`
- Refresh reason: `none; post-review human visual-art choice remains a separate unapproved production gate, not a dispatcher review eligibility blocker.`
- Next action: `Present three exact matched-camera screenshots with short specific review questions and an emitted evidence manifest, then return to the human visual decision. Do not mark source art approved automatically.`
- Blockers or open questions: `None for technical review; human visual decision remains separate and will require the current chat backlink if provided.`
