# Operator 3D asset workflow

`run -> verify -> freeze -> publish-review`. Every step is explicit. **A plain `run` never uploads and never locks.** Nothing here rigs, poses, decimates,
selects a best candidate, approves art, or touches manifests / SpriteFrames / runtime / FPS. Status of every output: `IMPORTED_REFERENCE_CANDIDATE_NOT_APPROVED`
(after `freeze`: `FROZEN_FOR_REVIEW_NOT_APPROVED`).

```bash
cd custodian/asset_drop/source_work/operator/operator_3d_master        # or: uv run custodian/tools/iteration/asset_pipeline.py ...
uv run scripts/asset_pipeline/run_asset.py run asset.glb --name meshy-004 --dry-run      # preflight + plan, creates nothing
uv run scripts/asset_pipeline/run_asset.py run asset.glb --name meshy-004                 # also: `run_asset.py asset.glb --name meshy-004` (back-compatible)
uv run scripts/asset_pipeline/run_asset.py verify meshy_candidates/meshy-004              # hashes of every output vs output_hashes.json
uv run scripts/asset_pipeline/run_asset.py freeze meshy_candidates/meshy-004 --name meshy-004   # locks/meshy-004/FROZEN_CANDIDATE_MANIFEST.json
uv run scripts/asset_pipeline/run_asset.py publish-review meshy_candidates/meshy-004 \
   --reason "visual validation" --question "Is this a better modeling base?" --retain-after-review --dry-run   # then without --dry-run
```
Requirements: `uv`, `blender` (>= 5.x headless), `node` (only for meshopt-compressed input), Python deps inline (pillow, numpy; cryptography only for legacy `.meshy`). `rclone` + the existing Dropbox remote for `publish-review` only.
Overrides (tests/odd installs): `CUSTODIAN_BLENDER`, `CUSTODIAN_NODE`, `CUSTODIAN_PUBLISHER`, `CUSTODIAN_RCLONE`. Exit codes: 0 ok, 2 usage/preflight, 3 input, 4 decode, 5 render, 6 compare, 7 verify, 8 publish.

## Inputs and permissions
- **Default: a standard GLB** (plain or `EXT_meshopt_compression`, `KHR_mesh_quantization`, `EXT_texture_webp`, `KHR_texture_transform`, Draco). Unknown *required* extensions are rejected.
- **Legacy `.meshy` v1** is an isolated, gated branch (`meshy_container.py`): it needs `--confirm-authorized`, which is *your own assertion* that you are entitled to process the file (e.g. your own generation, provider permission) — not automated proof.
  The auth tag is skipped, so the result is never cryptographically authenticated. Do not extend or reuse that decoder without re-checking the provider's authorization and `cryptography` licence/policy.
  Prefer re-exporting a normal GLB from the provider.

## What `run` does (contract)
1. **Preflight before any directory exists:** readable regular non-symlink input, header/version, strict GLB (length, chunks, JSON, buffer views, finite transforms, plain-GLB indices/NaN), safe unique `--name` (`[a-z0-9._-]`, no `/`, `..`, symlinks, collisions), finite positive parameters, tools present, canonical idle SHA verified.
2. Build under `<out-root>/.staging-<name>-<pid>`, **atomic rename on complete success**; any failure removes only that staging dir and returns the stage's exit code (no half-valid candidate).
3. meshopt decode (node + local three.js decoder) -> strict re-audit of the decoded GLB (indices < vertex count, finite positions, accessor bounds, no leftover meshopt).
4. Blender: ground (min Z=0, xy centred) and apply **exactly one uniform scale** chosen from the S view only (default S = 85 px); render N NE E SE S SW W NW unmirrored at 45° above horizon, 50 px/m orthographic (ortho 2.56), root (64,106), native 128 + independent 512. An undecodable texture or an empty direction fails the run. PNG metadata (Blender writes date/host/path) is stripped, so renders are byte-stable across runs.
5. `compare_8dir.png` vs the locked canonical idle, optional reference-experiment row (`--compare-dir/--compare-label`; default exp-008 frames), `pipeline_report.json` (audit, params, scale search, tools, script blobs, limitations), `review_pack/` (11 files: native-128 and 512 contact sheets, eye-level views, three detail crops, material proof from the live Blender node tree, geometry proof incl. watertightness analysis, compare sheet, report, notes; `--no-evidence` skips it), `output_hashes.json` (sha256 of every output).
Known limits: the S-only scale fit makes other directions deviate (85–91 px typical); asset pose is kept (no rig/pose change/retopology); IoU is triage, never approval; view transform is Blender's default (AgX), which desaturates bright trim vs the pixel-art canon.

## verify / freeze / publish-review
- `verify <candidate-dir>` recomputes every output hash; `verify <FROZEN_CANDIDATE_MANIFEST.json>` fails on mutation, missing file, **Git LFS pointer instead of real bytes**, wrong canonical bytes, or any approval/selection field set.
- `freeze` records provenance, params, tool versions, script git blobs and per-file sha256; refuses to overwrite; re-verifies what it wrote.
- `publish-review` is opt-in and needs `--reason` + `--question`. It stages the review pack to a neutral temp dir (no local home paths in the shared manifest) and calls the **existing** `custodian/tools/iteration/publish_review_artifacts.py` (`--important`, optional `--retain-after-review`), checks the publisher selected *every* staged file (it otherwise slices silently), then verifies the remote bytes with `rclone check`. `PUBLISHED_REVIEW.json` is written only after that succeeds; any failure exits 8 and marks nothing published. Caps: <= 12 files, <= 50 MiB, >= 3 PNG views. Default Dropbox retention is delete-after-review; use `--retain-after-review` only for intentionally locked evidence.

```
input -> [preflight] -> staging -> decode -> blender(render) -> compare/evidence -> output_hashes -> ATOMIC rename -> meshy_candidates/<name>/
                                                                                        | verify                | freeze (opt-in)           | publish-review (opt-in)
                                                                                        v                       v                          v
                                                                                 hash check               locks/<name>/…MANIFEST     existing publisher -> Dropbox (+ rclone check)
```
Recovery: after any failure fix the cause and re-run with a **new** `--name`; existing candidates and locks are never overwritten. User approval boundary: this workflow cannot approve, select-best, or promote art; that needs explicit human review.

## Tests
`python3 -m unittest custodian.tools.iteration.test_asset_pipeline -v` (fast, synthetic, no Blender/Dropbox). Real Blender integration: `CUSTODIAN_BLENDER_TESTS=1 python3 -m unittest custodian.tools.iteration.test_asset_pipeline.BlenderIntegrationTests`.
