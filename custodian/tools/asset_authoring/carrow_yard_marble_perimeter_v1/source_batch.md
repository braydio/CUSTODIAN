# Carrow marble perimeter · source-batch authority

**Family:** `carrow_yard_perimeter_walls_v1` · **Workstream:** `carrow-yard-marble-perimeter-source-intake-v1`
**Planning chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad5eb5a-598c-83ea-b982-531d4ff5418f

## Durable Dropbox transport (verified uploaded 2026-10-21)

`/CUSTODIAN/asset_batches/custodian_carrow_yard_marble_corner_slices_handoff_v1.zip`
SHA-256: `9079d308412f3c1cef3840d730bb9234da074ad8f09232e8db6be20509b92392`

All three extracted PNGs, three original images, `MANIFEST.json`, deterministic slicer, `CODEX_IMPLEMENTATION.md`, and source/reconstruction previews are included INSIDE the uploaded archive. Also separately uploaded under the same Dropbox directory: `carrow_marble_clean_ne_master.png`, `carrow_marble_double_ns_reference.png`, and `carrow_marble_damaged_right_end_reference.png`; use the archive, not loose convenience copies, for verifiable processing.

The archive's top-level directory is `custodian_carrow_yard_marble_corner_slices_handoff_v1/`. Clean image master is `reference/masters/image_20261021_031639_clean_ne_master.png` (1312×1199; SHA-256 `132525dc9487b56b2b62d244bcf580786f654bb17c03832a1ec6cb6422c83c95`).

| State | Crop `(x0,y0,x1,y1)` | PNG dimensions | SHA-256 |
| --- | --- | --- | --- |
| `wall_marble_ew_straight_01` | `(0,505,805,1189)` | 805×684 | `af152f20218ee342c15ce8e51e28a95e936900d31271a82c7f4a31c565613368` |
| `wall_marble_ns_straight_01` | `(820,0,1312,505)` | 492×505 | `68e8d14f24baf0e46496df6fd2ea9e0ccb06b1d56d1551c66512c18db42d65c2` |
| `wall_marble_corner_ne_01` | `(805,505,1312,1189)` | 507×684 | `f9074c4b64baa5301c3d74261e1dafa078a55ba3ac78e1176200e8dd4c487032` |

- Source-work (source only): `custodian/asset_drop/source_work/carrow_yard/carrow_yard_perimeter_walls_v1/<state>_source.png`.
- Proposed normalized inbox (BLOCKED): `custodian/asset_drop/inbox/carrow_yard_perimeter_walls_v1/<state>.png`.
- Provisional existing family authority (must reconcile before edit): `custodian/content/metadata/assets/families/carrow_yard_perimeter_walls_v1.asset.json`.
- No gameplay-world anchors, repeat pitch, drawn elevation, validated traversal width or final runtime dimensions are yet approved.
- The three source crops reconstruct the CLEANED original L exactly after discarding ONLY alpha<=3 pixels. This is **not** proof that arbitrary repetitions tile.
- One optional E-W repeat sample at x=320..790 is review-only and not a registered state.
- Historic seven-source Carrow Dropbox batch remains distinct and should not be overwritten or ingested again.
- Unrelated locker asset catalog hash drift is outside the current family.

## Safe implementation start

```bash
set -euo pipefail
STAGE="$(mktemp -d)"
rclone copyto 'git-dropbox-sync:/CUSTODIAN/asset_batches/custodian_carrow_yard_marble_corner_slices_handoff_v1.zip' "$STAGE/marble.zip"
printf '9079d308412f3c1cef3840d730bb9234da074ad8f09232e8db6be20509b92392  %s\n' "$STAGE/marble.zip" | sha256sum -c -
unzip -q "$STAGE/marble.zip" -d "$STAGE"
PACKAGE="$STAGE/custodian_carrow_yard_marble_corner_slices_handoff_v1"
python3 custodian/tools/asset_authoring/carrow_yard_marble_perimeter_v1/verify_marble_slices.py "$PACKAGE"
cp custodian/tools/assets/asset_handoff_installer.py "$PACKAGE/INSTALL_INTO_REPO.py"
python3 "$PACKAGE/INSTALL_INTO_REPO.py" --repo "$(git rev-parse --show-toplevel)" --dry-run
```

Run actual staging only in a dispatcher-owned isolated worktree and after checking historical claim ownership. Archive is immutable source evidence, and the inspected installer is permitted to stage only `source_work` entries marked `SOURCE_READY_NEEDS_TUNE`. Review images are not production sprites.

**Status:** Source bundle exists in Dropbox. `0/3` states are accepted for normalized Asset V2 runtime intake. The new packet is a **source intake/validation** task, not authorization to mark art visually approved.
