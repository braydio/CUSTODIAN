# Sepulcher Modular Environment Playtest: Four-Asset Source Pilot V1

**Status:** Proposed and reversible **pilot planning**, not an artwork-generation approval, not a registered Asset V2 contract, not a runnable Godot scene, and not a task packet. This probe should be discussed/reviewed before any wholesale change to the existing 72-core artwork program.
**Authoring chat backlink:** awaiting user-supplied current chat URL; do not invent.
**Machine-readable planning manifest:** [SEPULCHER_MODULAR_PLAYTEST_ASSET_PILOT_V1.json](SEPULCHER_MODULAR_PLAYTEST_ASSET_PILOT_V1.json).
**Inspected main:** `1fb718fe908d3f4c8bd293c79000eda165ec55bf`.

## Hypothesis and smallest credible experiment

Build one sandbox playtest using the real Operator, normal gameplay camera and an authored neutral 32px collision/walkability grid. Prove that **a seamless detailed floor tile + sparse alpha damage + one deliberate civic inlay + one separate wall module** can look more detailed and more coherent than repeatedly reprojecting one complete AI-rendered map. Do not require the entire 1152×1408 Sepulcher level art or any new grave-event behavior.

**Pilot canvas:** 1024×768 world pixels (32×24 cells, each 32px). Floor texture base repeats at 1 source pixel per world unit; the 512px base repeats twice horizontally and is clipped/continued vertically without stretching. Test-level navigation/collision is authored by Codex, not extracted from art. The wall sits at a deliberate **nonwalkable north boundary** of this sandbox only. The live full-Gardens walkability remains untouched.

## Four assets to generate and individually review

| Priority | Manifest state | Exact PNG source canvas | Composition role |
|---|---|---:|---|
| 1 | `hub_first_set_sepulcher_gardens_floor_materials/paving_base` | 512×512, 1 frame | primary repeated walkable paving |
| 2 | `hub_first_set_sepulcher_gardens_floor_materials/paving_damage_overlay` | 512×512, 1 frame | sparse variation over same base, no full-floor redraw |
| 3 | `hub_first_set_sepulcher_gardens_floor_materials/witness_ring_inlay` | 512×512, 1 frame | single deliberate focal detail, tests material integration and aliasing |
| 4 | `hub_first_set_sepulcher_gardens_dressing/retaining_wall_segment` | 256×128, 1 frame | wall for architecture projection/contact/collision comparison, placed only on sandbox nonwalkable edge |

**Asset Pipeline V2 contract planning:** `hub_first_set_sepulcher_gardens_floor_materials` is a *new proposed, not registered* `kind=tile` family. All three states have 512×512 one-frame omni canvases, `paving_base` is an opaque base; `paving_damage_overlay` and `witness_ring_inlay` are true-alpha overlays. `hub_first_set_sepulcher_gardens_dressing/retaining_wall_segment` reuses a **proposed existing V1 manifest state** at 256×128 rather than inventing another wall family. The actual `custodian.asset_family.v2` schema, kind, canvas, routing and consumers must be checked by the live Asset V2 owner before ingest. This JSON is explicitly NOT a runtime family schema.

### Complete individual generation briefs and exact filenames

#### 1. `hub_first_set_sepulcher_gardens_floor_materials/paving_base`

**Image specification:** 512×512px · 1 frame · `tile` · `background` · opaque.

**Prompt:** Produce one independent 512×512 pixel top-down overhead orthographic CUSTODIAN Sepulcher Gardens floor MATERIAL source. This is a uniformly traversable, seamless, tileable 16×16-cell area of 32px-scale paving, not an illustrated map. Detailed but restrained institutional basalt and chalk-limestone flagstones; 32px structural rhythm with larger coherent stone slabs, worn chipped mortar edges, ash dust, hairline cracks, subtle old bronze registration flecks, natural texture variance and nonuniform but consistent lighting. Rich fine masonry texture must remain legible when an Operator roughly 128px tall moves over it. EXACTLY seamless left/right and top/bottom, including corners; no special middle motif, no border, no vignette, no wall shadow, no debris pile, no raised stones, no false void, no tombs, no objects, no portals, no lettering, no characters. Production-facing 90-degree camera and a flat uniform walkable ground plane, not an isometric diorama. This is a single standalone texture, not a swatch chart or map.

**Required source filename:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_gardens_floor_materials/paving_base_source.png`

**Accepted normalized inbox filename:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_gardens_floor_materials/paving_base.png`

**Proposed family contract:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_gardens_floor_materials.asset.json`

**Seam/anchor validation:** repeatable all four sides and corners, pixel-level 1:1 test. No direct runtime copying. Human-approved source and SHA-256 required before Dropbox and Asset V2.

#### 2. `hub_first_set_sepulcher_gardens_floor_materials/paving_damage_overlay`

**Image specification:** 512×512px · 1 frame · `tile` · `overlay` · true RGBA.

**Prompt:** Produce one independent 512×512 pixel TRUE TRANSPARENT RGBA CUSTODIAN Sepulcher Gardens floor-wear OVERLAY. Create small irregular groups of surface-only hairline cracks, pale mineral abrasion, soot/dust deposits, chipped mortar tracery and extremely sparse bronze dust flecks, isolated on genuine alpha. All details must lie flat in a 90-degree overhead ground plane. The overlay is intended to be placed in different parts of an existing seamless basalt-limestone paving texture to break repetition, not a new paving surface. Leave at least 70 percent of the canvas completely transparent, keep edges nearly empty so placement can be varied, maintain highly detailed but low-contrast subtle wear at 1px-to-1-world-unit scale. No rectangles or opaque patches, no full tiles, no painted checkerboard, no cast shadows, no debris with height, no vegetation, no large circles, no UI, text, objects or architecture. Preserve texture fidelity rather than making it cartoony or simplified. One isolated PNG layer, no multiple-assets collage.

**Required source filename:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_gardens_floor_materials/paving_damage_overlay_source.png`

**Accepted normalized inbox filename:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_gardens_floor_materials/paving_damage_overlay.png`

**Proposed family contract:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_gardens_floor_materials.asset.json`

**Seam/anchor validation:** nonrepeating transparent detail layer; edges must be mostly transparent; at least 70% canvas unobscured. No direct runtime copying. Human-approved source and SHA-256 required before Dropbox and Asset V2.

#### 3. `hub_first_set_sepulcher_gardens_floor_materials/witness_ring_inlay`

**Image specification:** 512×512px · 1 frame · `tile` · `overlay` · true RGBA.

**Prompt:** Generate one single 512×512 TRUE TRANSPARENT RGBA overhead floor INLAY for the Sepulcher Gardens CUSTODIAN playable scene. An understated institutional witness registration motif, old concentric interrupted circular/rectilinear bronze grooves set flush into stone, fragmented by centuries of abrasion. This is a modest carefully drafted architectural floor motif, not a grand magic ritual arena, glowing portal, symbol with legible text, compass UI, tombstone or raised object. Accurate 90-degree overhead plane, uniform 32px civic architectural registration, isolated subtle bronze/limestone engraving marks, precise delicate stroke craft and high-detail patina. Everything outside the inlaid strokes is genuine transparent alpha, especially the outer canvas; no paving base beneath, no image-wide vignette, no shadows, no perspective tilt, no characters, no UI. Intended to compose over a separate detailed paving texture at world scale. Single independent image.

**Required source filename:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_gardens_floor_materials/witness_ring_inlay_source.png`

**Accepted normalized inbox filename:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_gardens_floor_materials/witness_ring_inlay.png`

**Proposed family contract:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_gardens_floor_materials.asset.json`

**Seam/anchor validation:** isolated inset work; transparent background. No direct runtime copying. Human-approved source and SHA-256 required before Dropbox and Asset V2.

#### 4. `hub_first_set_sepulcher_gardens_dressing/retaining_wall_segment`

**Image specification:** 256×128px · 1 frame · `world_prop` · `architectural_visual` · true RGBA.

**Prompt:** Create one independent 256×128 TRUE TRANSPARENT RGBA ruined civic Sepulcher Gardens RETAINING WALL module for CUSTODIAN. One 256px-wide piece of weathered basalt and pale limestone burial-terrace masonry, physically coherent 32px construction rhythm, dark recessed joints, fractured capstones, controlled thin bronze institutional trim, subtle vertical face shading and visible structural thickness. Camera design: plan/top surface must register to strict overhead floor; a modest controlled downward-facing wall elevation may be shown ONLY as a separate vertical facade belonging to this object, anchored on an explicitly documented ground-contact baseline at the bottom of the sprite. No camera tilt of the pavement or oblique scene perspective. Symmetrical light direction and consistent nonmirrored construction, clean horizontal endpoints that can join two copies without obvious doubled pillars, no unrelated floor tile, no corridor, arch, prop cluster, people, text or UI. Transparent everywhere beyond structure, with no dark rectangular background or cast scene-wide shadow. This wall will be placed at the NONWALKABLE NORTH TEST BOUNDARY with authored collision, never over a current live Gardens route.

**Required source filename:** `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_gardens_dressing/retaining_wall_segment_source.png`

**Accepted normalized inbox filename:** `custodian/asset_drop/inbox/hub_first_set_sepulcher_gardens_dressing/retaining_wall_segment.png`

**Proposed family contract:** `custodian/content/metadata/assets/families/hub_first_set_sepulcher_gardens_dressing.asset.json`

**Seam/anchor validation:** horizontal 256px module with crisp left/right endpoints; contact baseline documented. No direct runtime copying. Human-approved source and SHA-256 required before Dropbox and Asset V2.

## Codex build sequence (no formal implementation packet until source/claim gates)

**Step 0, before generated assets:** In the approved workstream lifecycle, author a standalone sandbox with **procedural neutral rectangles/placeholders** and existing real Operator/Camera2D bootstrap. Recommended path: `custodian/game/world/levels/authored/dev/sepulcher_modular_material_pilot/`; main test scene `sepulcher_modular_material_pilot.tscn`. Reuse the standalone scene pattern from `custodian/game/world/levels/authored/dev/kenney_isometric_blockout_playtest/`; do not reuse its Kenney artwork or claim it as Sepulcher art. One 1024×768 surface, authored north wall collision, safe spawn and clear 128px path. `1` neutral baseline, `2` assembled modular presentation, Tab toggle; same player, camera, geometry and collision. A preview in Godot without new art is useful and does not require Dropbox.

**Step 1, source reviews:** Generate **one independent image at a time** in the priority order above, not a 4-up atlas. Validate real pixel dimensions, alpha and tile seams; correct in the original source rather than repainting a whole level. Human makes separate art approval for each. Use the first rejected mixed CAL-01 illustration as a materials/style reference **only**, not as any runtime floor/geometry master. For a generator that cannot output exact PNG target dimensions or transparency, keep honest raw source dimensions and normalize carefully only after approval; no nonuniform resizing.

**Step 2, reviewed handoff:** Place each unprocessed source master under its declared `source_work` path and accepted normalized PNG under exact `inbox` path. Create reviewed `custodian.asset_handoff.v1` package with `README.md`, `MANIFEST_GAME32.md`, `MANIFEST.json`, `CODEX_IMPLEMENTATION.md`, the exact source/normalized bytes, and byte-identical current `custodian/tools/assets/asset_handoff_installer.py` as `INSTALL_INTO_REPO.py`. Upload to connected Dropbox with actual file IDs/revisions/hashes; package installer stages only and cannot silently ingest.

**Step 3, material presentation:** Codex (under an authorized independent workstream) validates/registers the two family contracts and consumes the approved source via Asset V2 `plan/status/doctor/ingest`; build repeatable floor presentation with local deterministic seeded decal placements, one inlay focal point, and wall segment(s) aligned to authored nonwalkable geometry. Presentation must never own collision, real Hub routes or persistence. A/B toggle switches presentation only.

**Step 4, acceptance:** Focused Godot smoke validates startup, Operator and camera identity, 32px bounds, no production Hub modification, collision independence and predictable deterministic art placement. Then capture **two matching-camera minimal ROI screenshots** for human A/B verdict (neutral versus art). At actual Operator scale assess detail retention, repetitive tiling, seam visibility, wall/floor contact, architectural projection and navigational legibility. Do not use a large screenshot sweep or unrelated CI.

## Dependencies and ownership boundaries

- This planning manifest and prompts are **publication-ready input**, but no raster sources exist at publication. **Do not publish an `auto/ready` Codex implementation packet that claims these art bytes already exist.** Codex may separately build only the asset-independent placeholder sandbox first, with real art wiring gated on reviewed source delivery.
- Existing Sepulcher grave event / ready independent review packet remains untouched; do not modify its script or persistence for the pilot.
- This experiment does not change the 72 required / 12 optional production plan, the `CAL-01` command, or the Dust Lung V2 DL0 source manifest. A successful human comparison is the decision gate for replacing the earlier large-plate approach.
- Known documentation drift: Dust Lung's source manifest mixes floor and structure underlays despite spatial doctrine separating gameplay/depth. Address in the eventual DL0 owner, not by adapting its current contracted source files mid-pilot.

## Success, failure and next decision

**Pass if:** normal real-Operator playtest looks detailed and coherent in motion, materials remain rich, repeats/seams are acceptable, wall perspective/contact and collision are correct, and no false affordance appears. **Fail/iterate if:** surfaces become bland, tiling reads as stamping, inlay dominates, or 2.5D wall creates a camera illusion or collision contradiction. Fix only the deficient individual asset or deterministic composition.

**On pass:** make a deliberate, reviewed change to the larger Hub/Sepulcher production inventory and generation order, then apply the method selectively to Dust Lung by its separate owner. **On failure:** retain the concept reference and try one bounded alternative before authorizing district-scale art.
