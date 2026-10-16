# Carrow Interior Scale Calibration V1 Paired Review

Workstream: `review-carrow-interior-scale-calibration-v1`

## Findings first

No blocking defects, material evidence gaps, non-blocking issues, or optional improvements were found. The technical review passes for the user's hands-on evaluation of the three debug fixtures. It does not choose a production size or make an aesthetic recommendation.

## Reconstructed target

Reviewed implementation commit: `200fb5ba3` (`carrow interior scale calibration, fixed debug fixtures [skip render]`). The implementation creates three individually launchable scenes:

- `res://scenes/debug/carrow_machine_house_scale_24x18.tscn` — 24×18 cells, 768×576 px, 432 floor cells, 154 solid cells.
- `res://scenes/debug/carrow_machine_house_scale_30x22.tscn` — 30×22 cells, 960×704 px, 660 floor cells, 174 solid cells.
- `res://scenes/debug/carrow_machine_house_scale_36x26.tscn` — 36×26 cells, 1152×832 px, 936 floor cells, 194 solid cells.

All use one shared fixture controller, the shipped Operator and capsule, CameraController, 0.84 base zoom, 150 px/s movement speed, native 32 px floors, 13 registered Carrow assets and three East storage identities. No production room router is instantiated.

## Independent evidence

- Fresh fixture smoke: PASS, 1/1. It checks exact variant dimensions and counts, cell ownership, aisle/doorway, art/storage identity, actual Operator physics clearance, camera settings, controls/reset and malformed-configuration/art negative controls.
- Existing Carrow Operations House regression: PASS, 1/1.
- Existing Carrow yard regression (East and West): PASS, 1/1.
- Backdrop isolation regression: PASS, 8 transitions.
- Independently regenerated renderer evidence: nine images, all exactly 768×576. SHA256 values:
  - 24×18 ENTRY `38f90689848ef4a41112e30a63c7d90b5f98604c5accf113e8450a5e5dc054c2`, CENTER `7266f7657ba5f585a956ad42c695ae36021617d33ee66c7832210b2efd31588e`, NORTH `296b03aeca2ce353c01b5f28c76cbc97c6ef81f429e83f9a654523515c3a5968`.
  - 30×22 ENTRY `96b3d7192f6b29fb8202cb780979a888b607e48d9f0676fcea6f63227ef13f15`, CENTER `a44a1d7df983cda92eee1f7438ea72cd3dc6b721c97afc31fc18a23347e87a17`, NORTH `b06c97995af0dff296bace0235586a8780b77d0a482dfde87f20f78ea1c610fb`.
  - 36×26 ENTRY `9ddfbabeece8b3f4dc87808b8cf3d95765018f8645f81bc49f60ac04d3964b4d`, CENTER `2896366b8c0cb8f0c3e56fb694f5f846ab96fabb70ddccfcce21f2f2768dc306`, NORTH `f873fb530c73fd30c23dbf1572dcca9ac87df7c1709abdbcb9b16613c8787fc9`.
- All three independently generated `geometry.json` files report `passed: true`, three viewport-sized captures and zero failures. `comparison.json` contains only numeric variant facts and matches all expected values.
- The diff from the packet's pinned base (`9e0912dff173a65f808da14df698923aea426c8d`) to implementation commit contains no production `custodian/game/world/gothic_compound/` or Carrow structure-art files. `gothic_compound_map.gd` and `carrow_machine_house_door.gd` are byte-identical to base. Existing production behavior is also covered by the two named regressions above.
- `check_ai_context.py`: PASS. `git diff --check`: PASS. Changed-file validation selected zero implementation tests because only the review closing summary was uncommitted and that path is excluded; focused implementation and regression tests were run explicitly instead. `task_packet_index.py` check/write, `validate_review_pairing.py` (101 pairs), and `check_ai_context.py` passed.

Regenerated evidence is under the ignored review-worktree path `reports/carrow_scale_calibration/`; the original implementation run remains locally available under `.git/custodian-review-runs/carrow-interior-scale-calibration-v1/20261016T012240Z-44c5ccfe48e1/`. No review evidence binaries were added to Git. The review packet asks that the entrypoints and evidence identifiers be published to the authoring chat; this environment exposes no chat write tool, so the exact handoff is included in the durable summary and final response for the user to carry into that conversation.

## Process feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: first editor import took time and produced three unrelated `.uid` cache files.
- Root cause / contributing factors: fresh isolated worktree had no Godot import cache.
- Prevention / pipeline improvement: none required; generated files were identified and removed.
- Tooling / docs drift discovered: none.
- Follow-up: none.
- What worked: fresh numeric and renderer evidence plus focused regressions independently confirmed the fixture contract.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc3bfd-cf88-83ea-9156-be4e5c2851c0

## Next Handoff

- Next workstream: none
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc3bfd-cf88-83ea-9156-be4e5c2851c0
- Refresh reason: user-owned production size choice after trying the three fixtures, or request for additional fixed candidates.
- Next action: launch the listed scenes and report the chosen production size (or requested additional variants) in the authoring chat.
- Blockers or open questions: no technical review blockers; production sizing awaits the human decision.
