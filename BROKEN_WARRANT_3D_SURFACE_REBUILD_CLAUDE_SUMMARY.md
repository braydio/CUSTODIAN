# Broken Warrant 3D Surface Rebuild — Implementation Summary

- Workstream: `broken-warrant-3d-surface-rebuild`
- Branch: `agent/broken-warrant-3d-surface-rebuild`
- Outcome: technical implementation and objective validation passed; human art acceptance remains pending.
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad67690-d998-83ea-a107-ff3417ee482a

## Delivered

- `custodian/tools/art/broken_warrant_3d/`: semantic material assignment, shared procedural PBR palette, 15-bone rigid rig, Blender build/reopen validation, deterministic native/4× render, emission masks, render-only LOD and concise proof assembly.
- Local packed master: `custodian/asset_drop/source_work/actors/broken_warrant_playable_knight_3d/broken_warrant_material_master_source.blend`.
- Local evidence: three transparent RGBA 128×128 PNGs, three 512×512 PNGs, three emission masks, source census, assignment report, material validation, pixel proof, render-only LOD and one comparison sheet in the source-work folder's `proof/`.
- Human review handoff: `/CUSTODIAN/visual_review/broken-warrant-3d-surface-rebuild/20261020T023328Z/REVIEW_MANIFEST.json`; Dropbox retention is `delete-after-review`.

## Verification

- Input manifest audit: all packaged files match recorded hashes; original GLB and reference hashes are unchanged.
- Blender 5.2.2 build/reopen: PASS; 503 meshes, 45,998 triangles, exactly one 15-bone armature, all meshes have one intentional opaque semantic material and complete rigid weights, and the packed reference resolves. Geometry fingerprint preserved.
- Focused tests: `python3 -m unittest discover -s custodian/tools/art/broken_warrant_3d -p 'test_*.py' -v` — 4 passed.
- Determinism: two independent Blender 5.2.2 reruns produced byte-identical native and 4× PNG files after the renderer strips volatile Blender metadata.
- Pixel proof: PASS for front, three-quarter and back; dimensions, RGBA, transparent corners, edge bounds, root `(64,106)`, ground alignment, emission masks and fixed orthographic settings all validate.
- `git diff --check`: PASS. Moment Forge: not run — this is source-only Blender tooling; no Godot runtime or game presentation changed.

## Documentation drift and scope

The source geometry is Z-up, while Blender's glTF import exposes height along world -Y; the builder keeps mesh vertex data and imported transforms intact and maps rig/cameras into that measured frame. The source uses 17 bone suffix tags despite the intended 15-bone hierarchy; `Hand.L`, `Foot.R`, and `Foot.L` map to `Forearm.L`, `LowerLeg.R`, and `LowerLeg.L`. These findings are in the tool README and task packet. No runtime art, NPA 96px art or Asset V2 records were changed.

## Process feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: the first rig/camera pass assumed an upright Blender import and produced an incorrectly framed oblique view; Blender PNG metadata also caused differing file hashes despite identical pixels.
- Root cause / contributing factors: importer axis conversion and source bone suffixes exceeding the intended rig count.
- Prevention / pipeline improvement: document the measured import frame, map all rig coordinates explicitly, strip volatile PNG metadata and gate review on byte-stable output plus automated registration/bounds.
- Tooling / docs drift discovered: source axis and bone-suffix mismatch above; current state and file index now link to this tool.
- Follow-up: user visual decision on the comparison sheet, review-artifact cleanup, and independent post-land technical review.
- What worked: the source census and machine-checked alpha/bounds constrained review to one sheet.

## Human decision pending

Please review the comparison sheet through the manifest above and answer: **Do these three views preserve Broken Warrant identity and distinct material classes at native 128px?** This technical pass does not claim artistic acceptance or production approval.
