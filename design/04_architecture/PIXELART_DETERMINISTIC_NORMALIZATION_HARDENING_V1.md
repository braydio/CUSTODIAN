# Pixelart deterministic normalization hardening V1

**Status:** Design and packet contract amendment; NOT implemented or runtime-accepted
**Review baseline:** `braydio/CUSTODIAN main@f26cf189cf8b1a449d6eb6863ba1d966b3b1e777`, 2026-10-17
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc3bfd-cf88-83ea-9156-be4e5c2851c0
**Owners:** `tools/custodian_aliases.sh` and `custodian/tools/art/custodian_pixelart_converter.py` (conversion); staged `custodian/tools/assets/sprite_import/` (planned generic plans + objective QA); Asset Pipeline V2 (ingest). Never create a competing resizer.
**Related existing work:** `design/04_architecture/CODEX_ART_IMPORT_PIPELINE_V1.md`; five implementation/review pairs beginning `CODEX_ART_IMPORT_SHARED_TRANSFORM.md`, later `CODEX_ART_IMPORT_QUALITY_GATES.md`; `design/04_architecture/ASSET_PIPELINE_V2.md`.

## 1. Verified present behavior and precise problems

`pixelart` in `tools/custodian_aliases.sh` adds `--choose 1` unless caller supplied `--choose`. Converter: 2,241 Python lines. It computes three candidates every run, assembles a comparison preview, uses an intermediate canvas, and outputs the chosen PNG. `crisp` final reduction is nearest-neighbor. `balanced`/ `clustered` use BOX and quantization. All paths currently clamp final RGBA alpha to **0 or 255**, and optional bright-fringe cleanup deletes certain low-alpha pixels. By default single sources are auto-alpha-trimmed, scaled by `contain`, and centered; the default target is 96×96 unless filename tokens provide an inferred size. `--tile` chooses `cover` with zero margin (crop permitted). Animated sheets correctly share one union crop, scale and placement, and balanced/clustered use common palettes. `--normalization-plan` is read only in the sheet-mode branch. `--keep-candidates` keeps previews; sheet manifest is text, not a universal source→plan→output QA receipt.

The converter **does not currently** interpret a family/state contract, choose semantic component ROIs, locate left/right gate connections, verify a 160px world passage, detect guaranteed final silhouette truncation, stage through Asset V2, or emit a versioned generic per-state PASS report. Existing `pixelart_colors_smoke.py` principally covers palette-cap consistency, not architectural extraction. These omissions should not be reported as failed tests of a nonexistent feature.

Risks evident in live control flow:
- The 96×96 fallback, default trim and center anchor are unsafe *implicit decisions* for fixed-footprint buildings/assembly pieces.
- A visually complex illustrated building loses soft alpha via mandatory clamp. The nearest-neighbor preset can alias fine oblique features, while area/palette methods can discard fine geometry; neither can be ranked 'visually best' automatically.
- The output path is not rejected when equal to the input path; `--force` can overwrite the source PNG. Output and preview directories are created before completing all semantic validation. No atomic final write.
- An alpha-empty required source can yield a blank image without a source-visible-content error. Positive/nonzero source and target sizes, resource budget and unsafe extreme preparation canvases need explicit input checks.
- The caller can supply `--normalization-plan` on a single-image run, but the converter's replay validation exists only in its sheet branch; reject unsupported use instead of ignoring it.
- `tile_edge_contacts` checks any contact with an outside edge, not full edge coverage or seamlessness; a TRUE result cannot prove seamless floor tiles.
- No source hash, choice/policy digest, destination hash, alpha histogram, silhouette loss count, source-region coverage or composition evidence is emitted in a stable, auditable JSON contract on ordinary single-image conversion.

**Existing reuse:** `custodian/tools/art/extract_native_prop_sheet.py` and `auto_coordinate_assets.py` already implement alpha-connected-region extraction; `custodian/tools/art/extract_carrow_machine_house.py` extracts explicit semantic components; `custodian/tools/iteration/presentation_image_metrics.py` implements alpha bounds, matte/void, ROI difference and seam metrics; `custodian/tools/assets/asset.py` owns family plan/doctor/status/ingest. Compose these as read-only primitives, don't rewrite their owners.

## 2. Policy separation, never a one-size-fits-all converter

| Declared profile | Permitted filters | Alpha output | Purpose |
| --- | --- | --- | --- |
| `pixel_crisp` | nearest, no accidental smoothing | binary, 0 or 255 | Existing Operator/pixel-art, **unchanged**; alias default remains crisp |
| `illustrated_structure_soft` | explicitly declared area or Lanczos, selected by approved plan | preserve nonzero intermediate alpha and clean transparent RGB | 3D-looking static Carrow buildings/gantry; avoid aliasing roof silhouettes |
| `illustrated_structure_hard` | explicit source-preserving/area method | binary only when explicitly approved | Stylized hard-edge structure variant, not silent default |
| `terrain_edge` | contract-declared resampler | contract-declared opacity | Floor/road edge policy, no automatic `cover` without explicit cropping authority |

Each generic plan MUST pin target pixels, source ROI, source SHA, semantic family/state, orientation, authored anchor(s), strict contain or authorized cover, method, alpha mode, approved padding, output path under disposable staging, max source/output resource limits, renderer/tool version and normalized plan SHA. For a submitted high-resolution exterior, NO filename-based target-size fallback. The current Operator profile and legacy crisp behavior cannot change.

There is no algorithmic proof that a source illustration has correct camera perspective, reads convincingly as 3D or looks pleasing at runtime size. Those are human art gates.

## 3. Proposed deterministic commands (future CLI, not currently runnable)

```bash
python3 custodian/tools/assets/sprite_import/audit.py inspect \
  --source custodian/asset_drop/source_work/carrow_yard/carrow_yard_exterior_structures_v1/south_gate_source.png \
  --json

python3 custodian/tools/assets/sprite_import/audit.py verify \
  --plan .ai/art_import/carrow_gate/plan.json \
  --output .ai/art_import/carrow_gate/left_support.png \
  --json

python3 custodian/tools/assets/sprite_import/audit.py assembly \
  --spec .ai/art_import/carrow_gate/assembly.json --json
```

The implementation owner may expose these through an existing staged QA service rather than precisely these script names. The **stable input/output contract**, not invented private functions, is required. Commands must be read-only or write only disposable `.ai` previews; never edit input, inbox, runtime, family contracts or claimed worktrees. No extra Python image-vision model, OCR, screenshot interpretation, or machine aesthetic scoring.

### Inspection record: machine measurements

JSON includes `schema`, source path/bytes/SHA256/size/mode, alpha histogram buckets (`0`, `1..15`, `16..254`, `255`), occupied-pixel count at declared thresholds, bbox, edge-contact counts for ALL four edges, counts/areas/bounds of significant alpha-connected regions, warnings for near-opaque alpha or likely detached fringe, and deterministic ordering of all candidate regions. Component detection is **advisory**, never an authority to label detached antenna parts as a second sprite. Non-RGBA source and fully opaque source require declared semantic policy.

### Verify record: arithmetic and byte invariants

Required PASS checks: input PNG digest unchanged, source/plan/options/approved-family digest bound, exact target WxH, expected alpha mode, registered anchors inside declared bounds, output SHA256 and decoded pixel digest, preserved declared source ROI identity, no unapproved crop/clip, no pixels contributed by a foreign ROI, no artwork outside destination safe bounds, no missing required visible mask, byte-identical repeat of same pinned plan; correct Asset V2 pending status. Explicit allowed crop and legitimate overhangs use specified margins/ROIs, **never** guessed from alpha alone.

Report shape:
```json
{
  "schema": "custodian.normalization_qa.v1",
  "identity": {"family":"carrow_yard_exterior_structures_v1","state":"south_gate_left_support"},
  "source_sha256": "<64 hex supplied by tool>",
  "plan_sha256": "<64 hex supplied by tool>",
  "output_sha256": "<64 hex supplied by tool>",
  "geometry": {"source_roi_xywh":[0,0,0,0],"target_wh":[160,288],"alpha_policy":"illustrated_structure_soft"},
  "checks":[{"id":"SOURCE_PIN","status":"PASS"},{"id":"VISIBLE_MASK","status":"PASS"},{"id":"NO_UNAPPROVED_CLIP","status":"PASS"}],
  "summary":{"blocking_count":0,"warning_count":0,"status":"PASS"},
  "art_approval":"NOT_PERFORMED"
}
```
The zeroes in `source_roi_xywh` are schema placeholders, **not real Gate coordinates**. No proof can be PASS with a missing/placeholder ROI. Stable IDs, sorted checks, canonical JSON, fixed numeric rounding and defined JSON exit-code contract; no timestamps in digest input. `WARN` is advisory only, while missing required proof is `BLOCKED`, never PASS.

Advisory-only: opaque-region area retention vs declared mask/reference, edge/silhouette continuity changes after reduction, isolated pixel density, palette drift, edge halo risk, asymmetric resampling and bounding-box shift. Thresholds must be specified by profile or approved plan; no unqualified claim that lower palette size, harder edges, or a specific numeric aesthetic value is always superior. A lost thin pole may be a BLOCKED contract failure only when an approved critical-feature mask declares it required.

## 4. Modular South Gate: semantic assembly, not alpha-component guessing

The current accepted **visual design** is three separate parts. Preserve exact user-approved source masters and use authored named ROIs, with auto-connected-component detection as advisory evidence. The gate source sheet may contain small floating highlights and multiple islands per part. Reject an ambiguous source and request explicit region coordinates rather than 'autofixing' segmentation.

Provisional initial target canvases, **not locked gameplay scale**: `south_gate_left_support` 160×288, `south_gate_right_support` 160×288, `south_gate_overhead_girder` 224×64, static one frame each, true alpha according to approved soft structure policy. `alarm_gantry` is an independent single static sprite with a proposed 128×224 canvas. Each image's source_work master and normal inbox state live under:
```text
custodian/asset_drop/source_work/carrow_yard/carrow_yard_exterior_structures_v1/<state>_source.png
custodian/asset_drop/inbox/carrow_yard_exterior_structures_v1/<state>.png
custodian/content/metadata/assets/families/carrow_yard_exterior_structures_v1.asset.json
```
These paths are **planned**, not proof that families/images are already registered; the generated source concept sheet is not an ingest-ready family itself.

The assembly spec pins world px transforms/anchors with explicit `left_support`, `right_support`, `overhead_girder` identities, left and right connector attachment points, permitted joint tolerance (initially 0 world pixels for the locked authoring coordinate), collision-footprint AABBs, passable corridor rectangle, camera layer/z/depth relationships, and actual Gate owner identity. The required **160px clear walkable corridor** must be checked from collision geometry and Operator clearance, not the image's visual alpha. Girder must draw over the actor in the declared overhead region; support towers and road underlay retain separate z/collision authorities. An elevated beam can visually cover road without blocking it. Measure join endpoint residuals and exact corridor width; no resizing to 'look right', no auto collision from opaque masks.

A deterministic Godot smoke validates assembled nodes (textures exist, anchors meet, no duplicate overlaps, route open 160px, Operator traverse with current shape, one Gate owner, renderer order). A static PNG checker alone cannot prove actual in-engine occlusion.

## 5. Exact negative fixtures and exit behavior

- The source and destination resolve to the same file with `--force`: **BLOCKED** without any source write.
- Input is all-alpha-empty, target is 0px/negative, absurd preparation dimensions, invalid ROI, missing hash, corrupted PNG or an output that reaches a prohibited image edge: **BLOCKED** when required policy forbids it.
- Premultiplied dark halo, near-opaque 253-valued body pixels and isolated antialias edge: report numeric facts; **WARN** unless a measurable approved contract explicitly makes it blocking.
- Three-parts input with swapped left/right ROIs, duplicate ROI masks, one missing tower, foreign visible pixels in ROI, source cropped through support, or girder endpoint mismatch: **BLOCKED**.
- Gate clearance 159px instead of 160px, colliders occupying passable lane, wrong Girder z or physically blocking Operator, or duplicate scene owner: **BLOCKED** by Godot fixture.
- Valid disconnected antenna/rail/horn pixels should not be erased merely because they form multiple connected islands. Check explicit critical-feature masks/ROIs.
- Existing Operator crisp sheets, 6f/8f frame strip, tile/terrain policy and `pixelart_colors_smoke.py` remain unchanged/green; non-Operator soft profile is an explicit opt-in.
- Repeat the same source+plan+tool version twice: identical source/output decoded/pixel hashes and canonical QA facts; no silent source_work or Asset V2 inbox mutations.

## 6. Implementation order and documentation drift

1. Existing `codex-art-import-shared-transform`: add path/dimension/empty-mask fail-closed rules, approved non-Operator soft/rectangular profile, deterministic plan/alpha mode; preserve Operator crisp.
2. Existing `codex-art-import-registration`: support explicit world-footprint/contact and girder connector anchors without inferring world geometry from source alpha; no family schema edit without explicit compatibility review.
3. Existing `codex-art-import-quality-gates`: emit inspect/verify/assembly JSON and deterministic warning/block behavior; reuse `presentation_image_metrics.py` and existing extractor algorithms; integrate Godot assembly smoke.
4. Existing MCP and Asset V2 handoff pairs: surface these read-only QA reports and prohibit promotion until objective QA and *separate human artwork approval* exist.

Drift found: `tools/custodian_aliases.sh` says crisp is default, which is true for the wrapper; generic converter docs describe interactive three-way selection without mentioning that wrapper default. The older `SPRITE_PIPELINE_SYSTEM.md` describes a generic 24-color balanced recommendation, which is not the normal `pixelart` alias path. Reconcile only the documentation affected by each real landing. The proposed art-import roadmap is not shipped functionality; don't mark it complete.

**No artwork generation, runtime normalization, semantic image approval, source cleanup or GitHub ingest is authorized by this document alone.**
