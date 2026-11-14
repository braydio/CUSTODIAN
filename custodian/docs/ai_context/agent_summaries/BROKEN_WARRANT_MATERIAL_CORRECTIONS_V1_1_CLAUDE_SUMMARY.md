# Broken Warrant Material Corrections V1.1 — Closing Summary

## Delivered

- Added `emission_canister` for all three backpack tank cores with base color
  `#F07323`, emission strength `0.65`, metallic `0.15`, roughness `0.30`, and
  opaque alpha. Visor, chest, and cannon retain `emission_amber` at strength
  `2.0`.
- Reduced fabric micro-noise and bump to the specified pixel-scale values.
- Updated both emission-mask branches and extended Blender validation to require
  exactly the three intended canister meshes, no other uses, emission strength
  `0.65`, and alpha `1.0`.
- Added an offline material contract test and registered focused changed-file
  validation for the Broken Warrant material tools.
- Rebuilt an editable source-only material master at
  `custodian/asset_drop/source_work/actors/broken_warrant_playable_knight_3d/correction_v1_1/broken_warrant_material_master_v1_1.blend`.
- Applied the separate shoulder and hood-cowl correction to a derived copy at
  `custodian/asset_drop/source_work/actors/broken_warrant_playable_knight_3d/correction_v1_1/broken_warrant_proportion_correction_v1_1.blend`.
  The bundled helper assumed source axes matched Blender local Y/Z; the current
  master maps source XYZ to Blender X,Z,-Y. The derived operation was adapted
  to that measured mapping, and its validation report confirms only the named
  23 hood-cowl parts and two pauldron shells changed.
- Produced one three-angle 128px comparison sheet and JSON receipts under the
  same `correction_v1_1/proof/` directory. Human art acceptance remains pending.

## Verification

- V1.1 ZIP integrity and all manifest hashes passed; original GLB and turnaround
  hashes remain `e1a9ef843561a7a31b0ba60600de97d909fbfe8a780b9c0882b3ef7bc6ea4ea6`
  and `5f7eaf60f54164896fe7284f8963cab13c00b18fc934fe982c5a1acb309cc7ac`.
- Patcher smoke passed dry-run, apply, repeat-run idempotency, both renderer
  branches, and fail-closed partial-migration checks. Post-apply dry-run reports
  no remaining changes.
- Eight focused Python tests passed. Task-filtered changed-file validation
  `broken_warrant_material_contract` passed with complete coverage.
- Blender 5.2.2 rebuilt and reopened the master: 503 meshes, 45,998 triangles,
  one 15-bone rig, three canister meshes assigned the new material, and all
  material/rig/source-hash checks passed.
- Native and supersampled renders repeated byte-identically. The assembler
  passed all three view, alpha, framing, orthographic-scale, registration, and
  comparison-sheet checks. The sheet is 1576×1118, SHA-256
  `c6bd2eeae64235e5caa981878bc3e43e14d62bf17968d336f65fc82a5f59deb7`.
- Derived-shape validation passed with unchanged mesh/triangle/bone counts and
  pauldron source-space extents `(0.630, 0.540, 0.460)` on both sides.
- `git diff --check` passed.

## Validation note

The unfiltered `run_validation.py --changed --json` run selected 37 checks because
`validation_manifest.json` is a shared owner. Twelve unit checks passed; the
unrelated `operator_unarmed_fast_chain_north_vfx_contract` failed because
`fast_01` source pixels differ from its inbox reference, so higher tiers were
skipped. The task-filtered changed-file run passed. No Operator files were
modified.

## Scope

All Blender masters and proof outputs remain ignored source-work artifacts. No
runtime art, Asset V2 family, NPA 96px output, or production-art approval was
created.
