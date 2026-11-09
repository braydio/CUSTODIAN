# Meridian Civic Wall 3D V1 — archival source record

## Status

Archived source validation only. This record does not establish Godot import compatibility, suitability for 2.5D rendering, visual quality, Asset V2 readiness, or production approval.

## Canonical files

- Preserved source: `custodian/asset_drop/source_work/meridian_civic/meridian_wall_3d_v1/Meridian_Wall_3D_Textured_model.meshy`
- Canonical decoded model: `custodian/asset_drop/source_work/meridian_civic/meridian_wall_3d_v1/meridian_civic_wall_v1.glb`
- Root-level archival copy: `MERIDIAN_CIVIC_WALL_3D_V1.glb`
- The two GLB files are byte-identical; both SHA-256 hashes are `342056035401bfa626233072c629ceaf0ff7517a5a6687ad564dc2d5cb49c666` (1,628,556 bytes).

## Source provenance

The project owner supplied and authorized processing of `Meridian_Wall_3D_Textured_model.meshy` and `Meridian_Wall_3D_model.meshy` from the local Downloads directory. Both files were present, byte-identical, 1,628,604 bytes, and had SHA-256 `9ca53b5bd034380e9afe46dbed3138ce17aed1628830f2d035fe8fdb62188fc2`. The textured-named copy is preserved as the canonical source; no input bytes were changed.

The existing legacy reconstruction routine was used. It reconstructs the GLB container but skips verification of the source container's cryptographic authentication tag. The output must therefore be treated as an unauthenticated reconstruction of the supplied bytes, not as a cryptographically authenticated provider export.

## Decoder and reproducibility

- Decoder source: `meshy_decode.py` and `meshy_container.py`
- Decoder revision: commit `14298756db4493ab6f52e0a886a911ed0e01c2c0`
- Command: `uv run --no-project --with cryptography python meshy_decode.py custodian/asset_drop/source_work/meridian_civic/meridian_wall_3d_v1/Meridian_Wall_3D_Textured_model.meshy custodian/asset_drop/source_work/meridian_civic/meridian_wall_3d_v1/meridian_civic_wall_v1.glb --confirm-authorized`
- The second identical `.meshy` file was independently decoded to a temporary output and produced byte-identical GLB data.

## GLB inventory

- GLB 2.0; declared length 1,628,556 bytes; header and chunk lengths parse successfully.
- JSON chunk: 3,068 bytes. Binary chunk: 1,625,460 bytes.
- Generator: `gltfpack 1.2`
- Meshes: 1; materials: 1; images: 3; textures: 3; nodes: 2.
- Used extensions: `KHR_mesh_quantization`, `EXT_meshopt_compression`, `KHR_texture_transform`, `EXT_texture_webp`.
- Required extensions: `KHR_mesh_quantization`, `EXT_meshopt_compression`, `EXT_texture_webp`.

Both `.glb` files use the repository's existing Git LFS rule. The preserved `.meshy` source uses a path-scoped Git LFS rule in `.gitattributes`.
