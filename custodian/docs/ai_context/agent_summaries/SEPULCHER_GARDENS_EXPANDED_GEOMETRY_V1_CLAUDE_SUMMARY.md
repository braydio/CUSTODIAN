# Sepulcher Gardens Expanded Geometry V1

Workstream: `sepulcher-gardens-expanded-geometry-v1`
Authoring chat: not-recorded

## Result

Implemented the package's exact expanded Sepulcher Gardens mask in the live `hub_first_set` layout. The 96×84-cell authoring envelope maps to `Rect2(-4128,-4480,3072,2688)`; only the irregular 3,977 connected cells are walkable. Runtime builds the existing grid, collision boundary and navigation from 151 lossless row runs. Both Forum connectors remain four cells wide and preserve their original world rectangles. All other Hub markers and Road modules remain at their existing world positions.

Added an optional debug-build `F8` overlay for proposed water, obstacles, routes, landmarks and secret-site labels. It is hidden by default and owns no collision, navigation, rewards, event state or persistence. The playable test remains `res://scenes/hub_first_set_blockout_playtest.tscn`, using the real Operator, movement controller, camera and bootstrap. The capture runner binds the approved 128×128 idle-only Operator preview to that same gameplay actor; the animation coverage is not represented as production-complete.

The existing Sepulcher paving stays a material reference only. No artwork, item reward or Asset V2 family was generated, registered or approved. The old 1152×1408 Gardens underlay target is now explicitly blocked pending reconciliation to the expanded irregular geometry.

## Source provenance

- Input: `~/Downloads/CUSTODIAN_sepulcher_gardens_expanded_geometry_v1_20261102.zip`
- ZIP SHA-256: `402f9d0d92edcaf2ba0fa4d966ad61b30b19c64c97b8bf9238d769d55ac71200`
- Package geometry check: PASS; 3,977 connected cells, 151 runs, 10 landmarks, 7 obstacles, 8 paths, 5 proposed secrets, and 80px anchor-clearance preflight.
- Canonical Operator idle preview SHA-256: `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`.
- Latest synchronized implementation base: `origin/main` `3edbb939175109247da9200caaa963b03a044b10`.

## Validation

- `hub_first_set_blockout_smoke.gd`: PASS. Exact mask and envelope, full connectivity, both connectors, all prior Hub markers, unchanged Road modules, real Operator capsule clearance, 438 boundary segments, 13,996 safe cells, and F8 presentation-only invariance passed.
- `hub_sepulcher_grave_evidence_smoke.gd`: PASS; all three readings remain at their original coordinates and event records remain unchanged.
- `hub_sepulcher_grave_resolution_smoke.gd`: PASS; attested and unresolved resolution paths remain unchanged.
- `run_validation.py --changed --base origin/main --json`: PASS, 9 selected / 9 passed / 0 failed / 0 skipped / 0 infrastructure errors; complete changed-file coverage, stable source during validation.
- Godot project import: completed successfully.
- `git diff --check` and manifest JSON parse: PASS.

## Gameplay captures

Six matched 1280×720 gameplay captures show the overall mask, north and south Forum entries, grave approach, west water terraces, and southern orchard/proposed-secret paths with the 128px idle-only Operator on the real moving gameplay actor. Image hashes are in the Dropbox review manifest:

`/CUSTODIAN/visual_review/sepulcher-gardens-expanded-geometry-v1/20261102T075200Z/REVIEW_MANIFEST.json`

Local capture source directory during this run: `/tmp/sepulcher-gardens-geometry-v1-captures/`.

## Review gate

The implementation and geometry checks are technical evidence only. Human visual review remains pending for the proportions, wayfinding, gate readability and Operator scale. Production artwork registration and CAL-01 regeneration remain blocked until the art manifest is reconciled to the irregular floor mask.
