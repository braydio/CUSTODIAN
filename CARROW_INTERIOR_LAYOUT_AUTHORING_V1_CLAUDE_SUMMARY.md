# Carrow Interior Layout Authoring V1 — Completion Summary

Workstream: `carrow-interior-layout-authoring-v1`

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc3bfd-cf88-83ea-9156-be4e5c2851c0

## Delivered

- Added the Carrow-specific adapter and draft mapper scene on the existing `AuthoredLevelMapper` framework.
- Added the three approved 32px grids: West 24×18 (768×576), East 30×22 (960×704), and Operations 36×26 (1152×832). The mapper retains the actual Operator capsule and CameraController base zoom 0.84.
- The neutral preview starts with registered `slab_plain_01`, no authored prop placements or floor overrides, five boundary collision rectangles split around the current three-cell south portal, and the original room-specific storage resource IDs/contents.
- Added explicit paint/erase, named prop placement and transforms, independent collision rectangle editing, portal movement, storage binding, named clearance waypoints, save/load, validation, and validation-report export. Drafts and reports are confined to ignored `reports/carrow_layout_authoring/`; export never marks a human layout approved.
- Canonical serialization normalizes JSON-parsed integer geometry/resource values before hashing. Invalid drafts fail validation and cannot replace a valid saved draft.
- Production Carrow room code, production geometry, and Asset V2 registrations were not edited.

## Validation Evidence

- `carrow_interior_layout_mapper_smoke.gd`: PASS. Covers all room configurations, actual capsule clearance, authored mutations, invalid/stale/overlap/portal cases, stable digest and JSON round-trip, confined draft paths, save/reopen layout and preview equivalence, and invalid-save preservation.
- `carrow_machine_house_scale_calibration_smoke.gd`: PASS.
- `carrow_yard_interior_smoke.gd`: PASS.
- `carrow_operations_house_interior_smoke.gd`: PASS.
- `carrow_backdrop_isolation_smoke.gd`: PASS.
- `authored_level_mapper_framework_smoke.gd`: PASS.
- `run_validation.py --changed --base origin/main --json`: PASS, 38/38 selected checks, no uncovered changed files.
- `git diff --check`: PASS.
- Packet index check: run during closeout.

## Awkward Bits / Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `The fresh worktree lacked the Godot imported-texture cache. One post-sync full-import retry segfaulted at 99% before tests; rerunning with the verified coordination cache linked completed successfully. Initial JSON round-trip testing exposed integer geometry/resource values becoming floats after parsing, and an early test assumed storage records retained source-array order.`
- Root cause / contributing factors: `Ignored Godot import caches are local to each checkout; the incomplete local cache triggered a broad reimport that crashed once; canonical hashing did not initially normalize JSON numeric types; storage records are deliberately sorted by stable resource ID.`
- Prevention / pipeline improvement: `Normalize integer geometry/resource fields before digesting and assert byte-stable round-trip. Tests now find storage by ID and exercise save/reopen plus fail-closed overwrite behavior. The existing verified import cache was linked for validation, and the final post-sync changed-file retry passed 38/38 checks.`
- Tooling / docs drift discovered: `none`
- Follow-up: `fixed-in-scope`
- What worked: `Focused negative controls caught the digest mismatch and the full changed-file suite passed after repair.`

## Next Handoff

- Next workstream: `review-carrow-interior-layout-authoring-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc3bfd-cf88-83ea-9156-be4e5c2851c0
- Refresh reason: `none`
- Next action: `Launch the paired independent technical review after this implementation lands. If it passes, return the three editor entrypoints and wait for user-authored floors, props, and collision before any production conversion.`
- Blockers or open questions: `Human layout approval remains required before production conversion; it does not block paired technical review.`
