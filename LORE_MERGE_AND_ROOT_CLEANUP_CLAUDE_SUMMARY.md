# Lore Merge and Root Cleanup Summary

Date: 2026-09-27

## Merge

Merged PR #22, `lore/twin-solaria-crown-route-court`, into `main` as
`a611942c0d188195d40f9b62cf1fa39e3efe45cb`.

The merge brings the Twin Solaria Crown Route Court / Second Crown canon,
specialized lore authority, level authority, Hub architecture drift fixes,
and `twin_solaria_canon_docs` validation onto main.

## Root cleanup

Removed obvious root-level ingest/review leftovers only:

- `fast 1 vfx.png`, `fast_2_vfx.png`, `fast_3_vfx.png`,
  `fast_4_vfx.png`
- `CRECHE_NEW_OVERLAY.png`, `CRECHE_NEW_UNDERLSAY.png`
- `CUSTODIAN_Awakening_Next10_Runtime_Assets_2026-09-20.zip`
- `CUSTODIAN_Visual_Identity_Art_Correction_Batch01.zip`
- `VALIDATION.json`
- retired `review_ranged/` staging/review tree

The four fast-chain VFX root files were verified byte-identical by LFS object
OID to their canonical copies under
`custodian/asset_drop/source_work/operator/unarmed_fast_chain_vfx_20260921/raw/`.

The two Creche root files were verified byte-identical by LFS object OID to
their canonical copies under
`custodian/asset_drop/source_work/awakening/awakening_creche_environment/`.

All six ranged master PNGs under `review_ranged/` were verified by LFS object
OID against the canonical raw masters under
`custodian/asset_drop/source_work/operator/operator_ranged_2h_refresh_v1/raw/`
before retiring the review tree.

The two root ZIP packages and one root validation JSON had no repository
consumers and remain recoverable from Git history.

## Recurrence guard

Added narrow root-level ignore rules for these retired ingest/review scratch
patterns. This does not ignore general PNG/ZIP authoring and does not interfere
with Asset Pipeline V2 inbox/source_work paths.

## Documentation drift check

The lore merge intentionally updates canonical Twin Solaria lore/level and Hub
architecture documents. Main's newer validation-economy and Vaultwing state
material must remain present after the merge; post-merge verification is part of
this closeout.

No runtime asset authority was moved or deleted by the cleanup.
