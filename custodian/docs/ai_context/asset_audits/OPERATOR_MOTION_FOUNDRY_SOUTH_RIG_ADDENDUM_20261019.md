# Operator Motion Foundry South Visible-Surface V1: immutable addendum source lock

- Status: **external unapproved source-work candidate**, not runtime art, not accepted animation, not a revised Operator design lock.
- Workstream input owner: `operator-motion-foundry-south-rig-sourcework-v1`.
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
- Original art extraction owner: `operator-motion-foundry-south-rig-pixel-segmentation-v1`.
- Exact pre-existing Dropbox payload: `/CUSTODIAN/implementation_inputs/CUSTODIAN_OPERATOR_2_5D_MOTION_FOUNDRY_SOUTH_RIG_V1_ADDENDUM_20261019.zip`.
- Companion Dropbox integration instructions: `/CUSTODIAN/implementation_inputs/CUSTODIAN_OPERATOR_2_5D_MOTION_FOUNDRY_SOUTH_RIG_V1_ADDENDUM_HANDOFF_20261019.md`.
- Dropbox uploaded file metadata confirmed 2026-10-19: 197858 bytes, file id `id:8NXqdXuW6GUAAAAAAAAEfA`.
- ZIP SHA-256: `ea039bbbf945da4172c61d43a61beea793bf92a0f807c73d363cd7877673bf94`.
- ZIP layout: `operator_south_rig_v1/` containing **41 files** (single root, no ZIP path escape, no symlink), including source, two Python scripts, 23 transparent 128x128 PNGs, native layered Aseprite, JSON manifests, pixel ledger, previews.
- Original Aseprite source SHA-256: `61c7518b31a28d7b98af5efdb035316550b769abea7eb33ff0466544040172a3`.
- Source is 8 viewing directions, each **128x128, single flattened layer**, frame 4 zero-based is south. It is **not** eight sequential animation frames.
- Approved 128px Operator profile root = [64,106], floor [64,107]. The source is **not** identical to the separately approved 2048x256 2.5D design lock or the approved 8dir x 15f idle.
- Package's exact partition claim: 2440/2440 opaque visible south-frame pixels assigned once; RGBA-neutral reconstruction exactly equal; 23 semantic layers (18 populated, 5 intentionally blank for occluded geometry); 494 seam-adjacent pixels and 23 nearest-fallback pixels requiring subjective review; static 15f motion sample only, `fps=null`.
- Part layout target: `custodian/asset_drop/source_work/operator/motion_foundry/operator_south_visible_surface_v1/` with original `source/`, `scripts/`, `extracted/`, README, manifests and hash inventory.
- Family *context*: existing specialized `operator_2_5d`, generation `operator_2_5d_128`, not a new Asset Pipeline V2 schema. **Do not** write `custodian/asset_drop/inbox/operator_2_5d/`, canonical `content/` sprites, runtime resources or Workbench manifests in this slice.

## One-time offline staging procedure (Codex may use this in its claimed worktree)

The currently uploaded flat Dropbox addendum predates the canonical `implementation_handoff.py` handoff-ID/manifest layout. **Do not falsely invoke** `implementation_handoff.py fetch` against this flat ZIP or claim it has a `HANDOFF_MANIFEST.json`. For this exact existing immutable input, use rclone read-only transport and explicit SHA, first to disposable staging outside the checkout:

```bash
set -euo pipefail
tmp="$(mktemp -d)"
remote="${CUSTODIAN_IMPLEMENTATION_REMOTE:-dropbox:}"
rclone copyto "${remote}CUSTODIAN/implementation_inputs/CUSTODIAN_OPERATOR_2_5D_MOTION_FOUNDRY_SOUTH_RIG_V1_ADDENDUM_20261019.zip" "$tmp/addendum.zip"
printf '%s  %s\n' ea039bbbf945da4172c61d43a61beea793bf92a0f807c73d363cd7877673bf94 "$tmp/addendum.zip" | sha256sum -c -
python3 - "$tmp/addendum.zip" <<'PY'
import pathlib, stat, sys, zipfile
p = pathlib.Path(sys.argv[1])
with zipfile.ZipFile(p) as z:
    names = z.namelist()
    assert len(names) == 41 and len(set(names)) == len(names)
    assert all(x.startswith("operator_south_rig_v1/") and ".." not in pathlib.PurePosixPath(x).parts for x in names)
    assert all(not stat.S_ISLNK(x.external_attr >> 16) for x in z.infolist())
    assert z.testzip() is None
    print("verified 41-member source-work ZIP; no extraction performed")
PY
```

Codex must revalidate every member with `bundle_inventory.json` after extracting to an isolated directory; reject any unexpected/missing member, path escape, collision or conflicting existing source_work bytes. Only after that may it atomically place the package into the prescribed `source_work` tree, while keeping source and generated outputs semantically unapproved. If rclone is not available or hash differs, **stop** and report missing provenance; do not substitute another asset or an AI image.

For a future new upload, switch to canonical `custodian/tools/iteration/implementation_handoff.py prepare/fetch` with an exact workstream/handoff ID and `HANDOFF_MANIFEST.json` using `custodian.implementation_handoff.v1`. Do not alter this original Dropbox addendum as part of the current packet.

## Reproduction and review gate

The package runs `python3 scripts/test_extract_operator_south_rig.py` from the installed bundle root; all **7/7** passed in the authoring environment 2026-10-19. The explicit outputs are:
- `extracted/rig.json` under `custodian.motion_foundry.rig.v1`;
- `extracted/motion_static_proof.json` under `custodian.motion_foundry.motion.v1`, 15 identical zero-offset frames, not an accepted animation;
- `extracted/operator_south_segmented_source.aseprite`, 128x128 one frame with 23 named layers;
- `extracted/parts/*.png` (23 one-frame RGBA 128x128, including 5 deliberately transparent placeholders);
- `extracted/pixel_ownership.csv`, 2440 rows;
- `extracted/hierarchy_and_overlap.json`, explicit estimated pivots/occlusions/seams;
- `extracted/preview/*`, review-only previews, never normalized assets;
- `asset_handoff_manifest.json`, source-work provenance, not a runtime approval.

Next human visual gate: verify part semantics at cowl/pauldron joints, forearm cuffs, gold tabard folds, and draw/author hidden geometry for the 5 empty parts before motion. The existence of this package never supersedes the current design lock, MF1 reviewer, MF2 review, or any animation/pixel-clock authority.

## Documentation drift

`design/02_features/animation/CUSTODIAN_MOTION_FOUNDRY_V1.md` still says "not implemented" although MF1 code landed. The present packet is source-work **only**, not a status authority for MF1; record this drift and refresh the summary in a separately validated design-status edit after exact MF1 review disposition is known. Do not rewrite archived task packets.
