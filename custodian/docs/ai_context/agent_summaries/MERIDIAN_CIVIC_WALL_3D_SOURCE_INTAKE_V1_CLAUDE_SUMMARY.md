# Meridian Civic Wall 3D Source Intake V1 — Codex Summary

- Workstream: `meridian-civic-wall-3d-source-intake-v1`
- Outcome: source preserved and decoder-derived GLB validated as archival evidence only.
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad3b05a-6b30-83e9-ae0a-97f0a88a751f

## Changed files

- `.gitattributes`: added a path-scoped Git LFS rule for the preserved `.meshy` source.
- `custodian/asset_drop/source_work/meridian_civic/meridian_wall_3d_v1/Meridian_Wall_3D_Textured_model.meshy`: source bytes preserved.
- `custodian/asset_drop/source_work/meridian_civic/meridian_wall_3d_v1/meridian_civic_wall_v1.glb`: canonical decoded GLB.
- `MERIDIAN_CIVIC_WALL_3D_V1.glb`: byte-identical root archival copy.
- `MERIDIAN_CIVIC_WALL_3D_V1.md`: provenance, decoder limitation and GLB inventory.

## Verification

- Both Downloads `.meshy` files and the preserved copy are byte-identical; SHA-256 `9ca53b5bd034380e9afe46dbed3138ce17aed1628830f2d035fe8fdb62188fc2`.
- Existing decoder produced GLB SHA-256 `342056035401bfa626233072c629ceaf0ff7517a5a6687ad564dc2d5cb49c666`; root and canonical copies match exactly.
- A second decode from the duplicate input reproduced the same GLB bytes.
- GLB 2.0 header, declared length, JSON and BIN chunk boundaries parsed; inventory: one mesh, one material, three images, three textures, two nodes; used extensions are listed in the root record.
- Existing `*.glb` LFS rule and the new source-specific `.meshy` LFS rule were verified with `git check-attr`.
- Decoder source was not modified. Its skipped authentication-tag check is documented; this is not proof of provider authenticity, Godot compatibility, 2.5D quality, or production suitability.
- Focused verification and `git diff --check` passed.

## Closeout

- Landing SHA: recorded by the normal `workstream.py finish` lifecycle.
- Independent review: pending fresh paired review after landing.
- Runtime and production status: unchanged; no integration or approval claimed.
