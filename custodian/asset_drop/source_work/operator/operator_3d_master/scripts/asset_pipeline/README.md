# Asset pipeline (one command)

```bash
cd custodian/asset_drop/source_work/operator/operator_3d_master
uv run scripts/asset_pipeline/run_asset.py ~/Downloads/model.meshy --name meshy-003 --confirm-authorized   # .meshy (encrypted container)
uv run scripts/asset_pipeline/run_asset.py path/to/asset.glb --name meshy-004                              # GLB / meshopt GLB, no flag needed
```
Needs `uv`, `node`, `blender` on PATH (Python deps are inline: cryptography, pillow, numpy). Output `meshy_candidates/<name>/` (never overwrites):
`source/container.glb`, `asset_decoded.glb`, `renders/{128,512}_<DIR>.png`, `compare_8dir.png`, `pipeline_report.json`, `README.md`.

Pipeline: container (.meshy->GLB, needs `--confirm-authorized`) -> meshopt decode -> Blender: ground + one common scale (S height = `--target-height`, default 85 px) -> 8 unmirrored dirs at 45 deg / 50 px/m ortho, root (64,106), native 128 + 512 -> compare sheet vs the SHA256-locked canonical idle (+ optional reference experiment via `--compare-dir/--compare-label`, default exp-008).
It does NOT commit, select-best, approve art, or touch manifests/SpriteFrames/runtime/FPS. IoU is triage only.
Limitations: no rigging/posing/decimation/UV generation; asset pose is whatever the export has (meshy-001/002 are mid-stride); the scale is per-asset, chosen from the S view only.
