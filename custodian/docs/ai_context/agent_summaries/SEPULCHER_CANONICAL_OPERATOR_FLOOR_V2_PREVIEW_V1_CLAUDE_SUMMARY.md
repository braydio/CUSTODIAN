# Sepulcher Canonical Operator + Floor V2 Preview — Implementation Summary

- Workstream: `sepulcher-canonical-operator-floor-v2-preview-v1`
- Authoring chat: `not-recorded`
- Implementation commit: `ba76204b8ef95224bd49ba0372b3c43000eb59b4`
- Scene: `custodian/game/world/levels/authored/dev/sepulcher_material_operator_v2/sepulcher_material_operator_v2.tscn`
- Result: standalone playable development preview using the actual `operator.tscn`, PlayerController, Camera2D, full playtest bootstrap, HUD and collision boundary. The accepted 128px 8-direction × 15-frame idle sheet is a byte-identical, SHA-pinned dev copy visible by default on that same moving Operator. `V` restores the live legacy render layers. Floor keys `1`–`4`, `Tab`, and `B` select the four required presentations and inlays. The camera stays scene-scoped at 1.25 zoom; every comparison preserves player/world/collision coordinates. No production Operator, V1 scene, Hub geometry, Asset V2, or source master was modified.
- Visual evidence: `/CUSTODIAN/visual_review/sepulcher-canonical-operator-floor-v2-preview-v1/20261101T135136Z/REVIEW_MANIFEST.json` (Dropbox; four matched 1280×720 PNGs: legacy courtyard, canonical courtyard, canonical quiet modular, canonical NW repeat diagnostic). Same actor position `(512,520)` and frozen camera transform/zoom across captures. Retention is `delete-after-review`.
- Review questions: Does the canonical body read at a suitable real gameplay scale/ground registration? Does the original masonry read at gameplay scale? Is the quiet 128px floor and sparse inlay convincing, and does the NW repeat expose seams/repetition?

## Validation

- `preview_stage_canonical_idle.py` dry-run: PASS; dev copy bytes equal the pinned source.
- Source SHA-256: `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`; RGBA 1920×1024; 120 exact 128×128 atlas frames checked.
- Fixed limestone and basalt AtlasTexture regions checked at exact native 128×128 size; deterministic 48-cell layout and the two required inlay routes asserted by smoke.
- `sepulcher_material_operator_v2` focused Godot smoke: PASS, including real Operator movement, V toggle, camera framing and unchanged presentation-mode coordinates/collision/navigation.
- `sepulcher_modular_material_pilot` neighboring V1 smoke: PASS; V1 files untouched.
- Renderer capture script under `xvfb-run`/GL Compatibility: PASS; four matched gameplay captures emitted.
- `run_validation.py --changed --base origin/main --json`: PASS, 4 selected / 4 passed, complete coverage, no uncovered files.
- `git lfs fsck --objects HEAD`: PASS; staged preview is an LFS pointer with the pinned source SHA and 541,981-byte size.
- `git diff --check`: PASS.

## Execution Feedback

- Outcome: `success`
- Friction severity: `low`
- What went wrong: Initial smoke caught invalid GDScript constant expressions and camera/position settling assumptions; all were corrected before the passing validation run.
- Root cause / contributing factors: GDScript does not constant-evaluate `Vector2.normalized()` or constructed `PackedVector2Array` values, and the existing global gameplay camera eases its zoom.
- Prevention / pipeline improvement: Keep preview vectors literal, create route arrays per scene instance, and apply fixed preview zoom through the existing scene-scoped framing API.
- Tooling / docs drift discovered: `none`
- Follow-up: `none`
- What worked: The real Operator/controller/bootstrap was retained, and structural plus renderer evidence now share one reproducible capture path.

## Outstanding Gates

- Human visual/art-direction decision remains pending; this preview grants no production artwork approval.
- A release-ready canonical 128px locomotion/combat cohort remains unavailable and is explicitly labeled `IDLE ONLY` in-scene.
- The normal isolated-scene `NavigationSystem` logs that no floor tilemap is present; the authored sandbox `NavigationRoot` is intentionally empty and unchanged across modes.
