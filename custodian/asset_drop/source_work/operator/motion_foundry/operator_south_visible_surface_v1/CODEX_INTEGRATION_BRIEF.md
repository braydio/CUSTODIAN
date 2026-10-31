# CUSTODIAN Motion Foundry: South Visible-Surface Extraction Implementation Handoff

- Workstream: `operator-motion-foundry-south-rig-pixel-segmentation-v1`
- Chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
- Base design: `design/02_features/animation/CUSTODIAN_MOTION_FOUNDRY_V1.md`
- Scope: source-art extraction only. **Not** MF2 source bridge / publish, not runtime cutover, not MF1 reviewer repair.
- Package provenance: pinned original user-supplied Aseprite `61c7518b31a28d7b98af5efdb035316550b769abea7eb33ff0466544040172a3`, south frame index 4, 128×128, 2,440 original opaque pixels.

## One-time local import plan (no automatic writes by this document)

1. From clean current main, check `AGENTS.md`, `custodian/AGENTS.md`, current specialized Operator source schema, current profile/visual hashes, and the dispatcher. Treat the existing blocked MF1 review as protected, not as permission to promote.
2. Stage the exact complete unpacked bundle at `custodian/asset_drop/source_work/operator/motion_foundry/operator_south_visible_surface_v1/` (including scripts/source and all generated outputs); do not overwrite a previous candidate. Verify its original SHA-256 first.
3. If this extractor should become reusable repo tooling, copy reviewed script to `custodian/tools/operator/motion_foundry/extract_flattened_operator_rig.py` and tests to `custodian/tools/validation/operator_motion_foundry_south_rig_extract_smoke.py`, register the new smoke with the existing validation manifest owner rather than modifying MF1 core acceptance. Keep an art-specific source hash and region calibration, do not genericize unknown anatomy.
4. Re-run seven bundled tests from source_work; validate the 23 layer hashes, 2,440 unique CSV pixel records, 23 nearest-assignment flags, exact RGBA bytes, 5 explicit occluded blank layers, Aseprite 1f/128px layer reconstruction, and 494 reported cross-part seam-review pixels. Reject any source drift; no auto rescaling.
5. Confirm actual Aseprite opens `extracted/operator_south_segmented_source.aseprite` with 23 named layers and 1 frame. Treat failure as an art-editor compatibility defect, not reason to overwrite original.
6. **Only after MF1 independent acceptance:** invoke actual MF1 `plan` and `check` on `extracted/rig.json`, `extracted/motion_static_proof.json`, `extracted/parts/` with `--output-root .ai/operator_motion_foundry`; optionally run `render --write` to ignored candidate space. Expect 1920×128 containing 15 identical 128px neutral frames. This is a pipeline smoke, not a new animation.
7. Review the 23 polygon/fallback assigned pixels and major seams (cowl/pauldrons, hands/cuffs, gold-tabard folds) at pixel scale. Commission hidden upper-thigh, pelvis, cape and joint underpainting before any dynamic joint proof. Any donated hidden art must be separately authored, hashed, reviewed, and ingested under specialized Operator authority.
8. Only then plan MF3 motion/keyframes. Do not write Asset V2 inbox, canonical PNG, accepted Aseprite art, timing or runtime resources from this script.

## Exact local reproducibility commands

```bash
cd custodian/asset_drop/source_work/operator/motion_foundry/operator_south_visible_surface_v1
python3 scripts/test_extract_operator_south_rig.py
python3 scripts/extract_operator_south_rig.py --source source/CUSTODIAN_OPERATOR_RUNTIME_REFERENCE_128.aseprite --out extracted
```

After review gate, MF1 verification example from repo root (adjust the package location if source_work was staged elsewhere):

```bash
python3 -m custodian.tools.operator.motion_foundry.cli plan \
  --rig custodian/asset_drop/source_work/operator/motion_foundry/operator_south_visible_surface_v1/extracted/rig.json \
  --motion custodian/asset_drop/source_work/operator/motion_foundry/operator_south_visible_surface_v1/extracted/motion_static_proof.json \
  --source-root custodian/asset_drop/source_work/operator/motion_foundry/operator_south_visible_surface_v1/extracted/parts \
  --output-root .ai/operator_motion_foundry
python3 -m custodian.tools.operator.motion_foundry.cli check \
  --rig custodian/asset_drop/source_work/operator/motion_foundry/operator_south_visible_surface_v1/extracted/rig.json \
  --motion custodian/asset_drop/source_work/operator/motion_foundry/operator_south_visible_surface_v1/extracted/motion_static_proof.json \
  --source-root custodian/asset_drop/source_work/operator/motion_foundry/operator_south_visible_surface_v1/extracted/parts \
  --output-root .ai/operator_motion_foundry
```

Check live CLI module invocation and cwd before using the commands. Do not assume this separate package has access to live repository tooling.

## Acceptance and no-go list

- Exact source SHA and calibration enforced; 2,440/2,440 visible pixels accounted for in stable 18 populated + 5 blank topology layers.
- Neutral source/reassembly RGBA **byte equality**; even one altered pixel fails.
- Source work has binary-alpha RGBA 128px 1f layer files, profile SHA matches current approved 128px registration, root=(64,106).
- Every visible pixel has one explicit owner; inspect all boundary assignments, not just green counts.
- MF1 compatibility verified later in real repo; no false claim that this bundle is an accepted animated sprite.
- No Git/worktree/archived reviewer mutation, no in-game/runtime assets, no redesign of enemy 96px cutout rig.
- No assumed hidden pixels, auto palette changes, inferred FPS, auto Asset Pipeline V2 `ingest`.

**Next owner:** an art author/reviewer should validate the seam mask on the generated native Aseprite and decide which hidden/overlapping surfaces to hand-paint first. Once MF1 is accepted, a separate small Codex integration smoke can use this rig with MF1 and submit its evidence without touching the protected reviewer worktree.
