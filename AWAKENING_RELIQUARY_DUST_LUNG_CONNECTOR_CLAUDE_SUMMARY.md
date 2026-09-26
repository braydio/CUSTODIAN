# Awakening Reliquary–Dust Lung connector full-plate pass

## Source and normalization

- Approved master: root `connector_a.png`, **1374×1145 RGB**, SHA-256
  `8ff4fc38682bad5d27ef81293833e5a7629a08c030f39532ad08df9f5d6e1264`.
- Byte-identical source master:
  `custodian/asset_drop/source_work/awakening/awakening_reliquary_dust_lung_connector/full_plate_source.png`.
- No source was rejected or quarantined. Existing A/B/C source masters were left intact.
- Deterministic normalizer:
  `custodian/tools/assets/compose_awakening_connector_full_plate.py`.
  It performs uniform-scale Lanczos reductions, keeps the generated stone/shadow
  pixels, and clears alpha only outside the three target route regions.

| Segment | Source crop `(left, top, right, bottom)` | Source pixels | Target plate rect | Scale |
|---|---|---:|---|---:|
| Dust Lung threshold/run | `(143, 370, 357, 530)` | 214×160 | `(0, 0, 128, 96)` | 0.5981 |
| Eastward middle hall | `(250, 530, 1137, 691)` | 887×161 | `(64, 96, 768, 224)` | 0.7937 |
| Reliquary landing/south run | `(1030, 691, 1244, 958)` | 214×267 | `(704, 224, 832, 384)` | 0.5981 |

- Normalized intake: `custodian/asset_drop/inbox/awakening_reliquary_dust_lung_connector/full_plate.png`;
  Asset V2 archived the ingested inbox derivative after publication.
- Final plate: **832×384 RGBA**, one frame. All pixels outside the union of the
  three registered corridor regions are alpha 0; pixels within the authored
  regions are opaque, including intentional near-black stone/shadow.

## Runtime and layout

- Asset V2 family `awakening_reliquary_dust_lung_connector` now contains one
  required `full_plate` backdrop state, `background` / `connector`, `copy`,
  832×384, one frame, 0 FPS.
- Runtime output:
  `custodian/content/levels/awakening/04_05_connector/awakening_reliquary_dust_lung_connector_full_plate_832x384.png`.
- Scene presentation is one centered `Connector04_05_FullPlate` at
  `Vector2(352, -2464)` under
  `World/AwakeningZones/Traversal/ProductionArt`.
- The old A/B/C runtime files remain as historical assets but are no longer live
  scene sprites. Their stale generated catalog records were removed; no source
  provenance was deleted.
- `Layout.CONNECTORS` was not edited. Smoke assertions still lock the A/B/C
  rectangles and assert that their merged envelope is `Rect2(-64, -2656, 832,
  384)`. Collision, traversal, room envelopes, P-9, progression, triggers,
  camera reveals, and lighting geometry were not changed.
- Fade distance remains `ZONE_ART_FADE_DISTANCE`; runtime derives the nearest
  point from the merged Layout A/B/C envelope.

## Validation and visual QA

- Focused scripts: `awakening_first_return_smoke.gd` **PASS**;
  `awakening_first_return_geometry_smoke.gd` **PASS** (16,801 safe cells; 555
  route cells); `awakening_first_return_progression_smoke.gd` **PASS**.
- Asset V2 status: `full_plate` **READY / OMNI**. Asset doctor reports no
  errors; its one warning is an unrelated unregistered Operator inbox with 12
  PNGs.
- `python3 custodian/tools/validation/run_validation.py --changed --json`:
  **66 selected, 66 passed, 0 failed, 0 timed out**. The overall JSON `passed`
  field is false only because changed-file coverage is incomplete for 25 files:
  the raw root connector inputs (`connector_a/b/c.png`), concurrent Operator
  runtime/source outputs and inputs, and unrelated Reaper audio assets. No
  selected validation failed. Awakening smoke, geometry, and progression all
  passed in this sweep.
- Runtime evidence (windowed Vulkan render; the headless dummy renderer cannot
  capture SubViewport images) is saved under
  `reports/awakening_visual_walkthrough/connector_full_plate_pass_20260926/`:
  `center_C.png`, `center_B.png`, `center_A.png`, and `whole_transition.png`.
  Review found the route connected through both turns, the south threshold
  meets the Reliquary plate, operator scale is believable, and no hard crop seam,
  wall duplication, or stretched anatomy is visible. The transparent exterior
  reveals the existing dark world void as intended.

## Awkward failures and negative controls

- The first capture command used `--headless`, which selects Godot's dummy
  renderer and returned a null SubViewport texture. The capture was rerun using
  the windowed Vulkan renderer and produced all four reviewed images.
- Asset doctor initially found three stale A/B/C records in the generated
  catalog after the family migration. Those orphan catalog records were removed;
  the old runtime/source files remain preserved.
- An initial runner invocation used an incorrect test ID and returned a
  configuration error; the exact smoke scripts were then run directly and
  passed.
- Focused scene/progression scripts print the project's known exit-time
  ObjectDB/resource leak warnings while returning PASS.
- The locked Layout rectangles remain unchanged; the existing traversal and
  collision regression passed. No nearby room or gameplay geometry was moved.
