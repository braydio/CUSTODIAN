# Awakening 04→05 connector visual-envelope repair

## Current implementation status — landed with visual QA follow-up

- Immutable approved source master: `custodian/asset_drop/source_work/awakening/awakening_reliquary_dust_lung_connector/full_plate_source.png` (1374×1145 RGB). The source was not edited.
- The earlier 832×384 full plate is **rejected**: it cleared architecture outside the three traversal rectangles and produced floating floor strips. Its V2 state/runtime catalog entry was retired transactionally; prior ingest provenance remains archived.
- The compositor now uses expanded source extractions registered to the locked route anchors, a uniform Lanczos scale per extraction, and authored geometric silhouette masks. It does not color-key dark pixels. It also copies existing 04/05 room underlay pixels into the 96px shared canvases at exact world registration to prevent doubled threshold/stair art. Result: 1024×576 RGBA underlay, centered at `(352,-2464)`, with the unchanged traversal regions at local `(96,96,128,96)`, `(160,192,704,128)`, `(800,320,128,160)`.
- Source extraction anchors/crops: hall `(250,530)`, crop `(140,400,1374,850)`, scale `0.79368658`; Dust Lung `(143,370)`, crop `(0,204,520,650)`, scale `0.59813084`; Reliquary `(1030,691)`, crop `(860,600,1374,1145)`, scale `0.59813084`. The crops overlap; ordered composition retains both architectural elbows and landing surrounds.
- Runtime: `custodian/content/levels/awakening/04_05_connector/awakening_reliquary_dust_lung_connector_full_plate_underlay_1024x576.png`, bound as the required Asset V2 `full_plate_underlay` state. Old A/B/C provenance remains; those sprites are not scene-wired.
- Foreground extraction was attempted conceptually but is unsafe from this flattened RGB master: tall architecture, floor shadows, and illumination are inseparable. No fabricated foreground state or node is published. The optional V2 `full_plate_foreground` state remains unbound; occlusion layering is a known limitation.
- Scene node: `World/AwakeningZones/Traversal/ProductionArt/Connector04_05_Underlay`, centered at `(352,-2464)`. It has no gameplay children. The existing fade is derived from merged Layout A/B/C rectangles and remains 128px; it also supports the optional foreground node if one is later authored.
- `awakening_layout.gd` was not changed. A/B/C and their union remain exact; traversal, collision, progression, triggers, P-9, room positions, and lighting geometry are unchanged.

## Validation and direct visual review

- Asset V2 plan: exactly one 1024×576 underlay output. Ingest/import succeeded; status reports the required underlay bound and no stale `full_plate` catalog record. Doctor's only warning is the unrelated unregistered Operator inbox.
- Focused: `awakening_first_return_smoke.gd` PASS; `awakening_first_return_geometry_smoke.gd` PASS; `awakening_first_return_progression_smoke.gd` PASS; `asset_pipeline_ingest_smoke.py` PASS (including transactional optional-state retirement).
- Focused validation on the fresh-main integration worktree: Asset V2 ingest smoke PASS; Awakening geometry smoke PASS; Awakening scene and progression smoke assertions PASS. Godot logs an unrelated invalid WAV import and existing camera conversion errors during scene/progression runs. Asset doctor reports no connector error; its only warning is the unrelated unregistered Operator inbox. A full changed-file sweep was not rerun in this isolated integration worktree.
- Windowed Vulkan captures were generated and inspected directly:
  - `reports/awakening_connector_04_05/connector_C.png`
  - `reports/awakening_connector_04_05/connector_B.png`
  - `reports/awakening_connector_04_05/connector_A.png`
  - `reports/awakening_connector_04_05/connector_overview.png`
- Review confirms the expanded plate restores walls/parapets, lamps, route lines, both turns, and a transparent exterior silhouette. Exact registered room pixels and z-order remove doubled threshold/stair details, but the latest C/A captures still show a noticeable straight join at the room-canvas edge; visual acceptance remains unresolved against the no-hard-seam criterion. The flattened layer also cannot independently render tall structures over the Operator. The capture paths are evidence for the current state, not final acceptance. The user authorized landing this connector slice with that visual follow-up explicitly recorded.

## Rejected-version history

The previous 832×384 screenshots under `reports/awakening_visual_walkthrough/connector_full_plate_pass_20260926/` document the rejected composition only. Their earlier “no hard crop seam / visually acceptable” verdict is superseded by the user's review and must not be used as acceptance evidence. The present implementation remains uncommitted pending a clean, directly reviewed room join.
