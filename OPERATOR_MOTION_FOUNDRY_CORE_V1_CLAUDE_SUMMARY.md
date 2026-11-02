# Operator Motion Foundry Core V1 — implementation summary

Workstream: `operator-motion-foundry-core-v1`

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488

## Delivered

- Added the pure-Python Motion Foundry package for versioned rig/motion validation, exact source SHA and path confinement, integer rational interpolation with signed half-away rounding, stable RGBA composition, and candidate QA.
- Added read-only `plan` and `check` commands and explicit `render --write`. Outputs are content-addressed beneath `.ai/operator_motion_foundry/runs/`; differing existing bytes are refused. Operator candidates use the existing V2 eight-token filename grammar.
- Reports and receipts remain `candidate` with `publication_authorized: false`. The test fixture creates three synthetic 128px parts and renders a 15-frame south strip; it does not use or claim approved Operator source art.
- Registered the focused smoke in `validation_manifest.json`. Negative controls cover wrong dimensions and hashes, direction/profile changes, duplicate identity/order, parent cycles, invalid keys, locked-part movement, bad contacts, clipping, symlink escape, and tampered repeated output.

## Evidence

- `operator_motion_foundry_core_smoke.py`: pass, including identical PNG/receipt hashes across separate temporary roots and unchanged canonical content/reference hashes.
- `operator_2_5d_canonical_visual_contract_smoke.py`: pass; accepted normalized reference hash remains `e529df0e0ceaeb941f67ed18ce93799755053b7c516a9f02a5b6929248e25fb9`.
- `run_validation.py --changed --json`: 39 selected, 39 passed, 0 failed.
- `python3 -m compileall -q ...` and `git diff --check`: pass.
- No production art, timing, Asset V2, runtime selector, Workbench, or canonical resource was written. Moment Forge is not relevant to this offline authoring-tool change.

## Rough edges

The first changed-file validation found no manifest owner for the new smoke; after adding the narrow manifest entry, the full changed sweep passed. A validation run waited on an active Godot project lock before continuing. During fixture development, assertion assumptions and the synthetic foot-contact pivot needed correction; the final negative-controlled smoke now exercises the intended contracts.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Initial validation uncovered missing manifest ownership; a first contact fixture did not align its semantic pivot; final issues were corrected before closeout.
- Root cause / contributing factors: New smoke scripts require explicit validation-manifest ownership; fixture contacts are defined at the part pivot.
- Prevention / pipeline improvement: Register each new smoke with its owned package files in the same implementation change and make semantic anchor assumptions explicit in fixtures.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: The isolated fixture proves deterministic bytes and protected-tree immutability without external services or canonical art writes.

## Next Handoff

- Next workstream: review-operator-motion-foundry-core-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
- Refresh reason: none
- Next action: Run the paired fresh-context review and its falsifying negative controls. Do not route candidates to runtime.
- Blockers or open questions: none
