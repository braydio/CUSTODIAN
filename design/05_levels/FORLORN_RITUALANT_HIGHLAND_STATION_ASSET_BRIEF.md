# Ritualant Highland Station — Asset V2 Production Brief

**Status:** approved planning inventory; no image asset has been generated or ingested by this document.
**Workstream:** ritualant-highland-station-redesign
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
**Authority:** `design/05_levels/FORLORN_RITUALANT_HIGHLAND_STATION_DESIGN_LOCK.md`.
**Live source conventions:** `custodian/content/metadata/assets/families/ritualant_underground_environment.asset.json` (`custodian.asset_family.v2` kind `backdrop`) and `ritualant_underground_hazard_fx.asset.json` (kind `effect`).

The user is reviewing the existing Ritualant package. **Inventory and classify existing art before generating replacements.** This file describes approved missing roles and useful provisional sizes, not a claim of twelve new required sprites. Asset Pipeline V2 `plan/status/doctor/needs` and family-specific runtime templates control the eventual output basename and metadata. No direct runtime drop bypassing V2.

## Group A — original station architecture

**Proposed family:** `ritualant_highland_station_infrastructure`
**Schema:** `custodian.asset_family.v2`, start from existing Ritualant environment family, kind `backdrop`; validate actual manifest/tool schema before registration.
**Provisional source intake:** `custodian/asset_drop/inbox/ritualant_highland_station_infrastructure/`
**Proposed runtime directory:** `custodian/content/tiles/encounters/ritualant_set/highland_station/`
**Family metadata:** `custodian/content/metadata/assets/families/ritualant_highland_station_infrastructure.asset.json`

| State filename in proposed inbox | Art purpose | Canvas px | Frames |
| --- | --- | --- | --- |
| `highland_station__structure__lift_service_apron__512x512.png` | old dock and service floor tie-in | 512×512 | 1 |
| `highland_station__structure__reinforced_tunnel_span__512x512.png` | stone-reinforced service crossing; alpha edges | 512×512 | 1 |
| `highland_station__structure__conduit_trench__512x256.png` | floor-mounted conduit/rail/maintenance trench | 512×256 | 1 |
| `highland_station__structure__receiver_gallery__1024x768.png` | **hero support structure**, isolated receiver load-bearing mass | 1024×768 | 1 |
| `highland_station__structure__chapel_station_seam__768x512.png` | native station bones under displaced chapel geometry | 768×512 | 1 |
| `highland_station__structure__north_isolation_throat__512x512.png` | spatially convincing north-seal transition; do not author exit authority in art | 512×512 | 1 |

Sizes are **starting canvases**, not authority to replace accepted 2594×1737 arena master or distort the current 32px world grid. Avoid embedded text too small to read at gameplay zoom.

## Group B — receiver and exploration props

**Proposed family:** `ritualant_highland_station_receiver_props`
**Schema:** `custodian.asset_family.v2`; choose a tool-validated prop/tile copy-family form after inspecting existing `meridian_civic_props.asset.json`, rather than inventing an unverified `kind`.
**Provisional inbox:** `custodian/asset_drop/inbox/ritualant_highland_station_receiver_props/`
**Proposed runtime directory:** `custodian/content/props/ash_bell/highland_station/`
**Family metadata:** `custodian/content/metadata/assets/families/ritualant_highland_station_receiver_props.asset.json`

| Source name | Role | Canvas px | Frames |
| --- | --- | --- | --- |
| `receiver_key__item__pickup__64x64.png` | Receiver Key physical world pickup away from chapel | 64×64 | 1 |
| `receiver_key__ui__inventory__64x64.png` | readable inventory silhouette | 64×64 | 1 |
| `receiver__body__unkeyed__256x256.png` | exposed port / missing reference-seat cue | 256×256 | 1 |
| `receiver__body__keyed__256x256.png` | properly seated and terminated configuration | 256×256 | 1 |
| `receiver__body__settled__256x256.png` | quiet/normal operation or inactive outcome | 256×256 | 1 |
| `station__prop__duty_cabinet__128x128.png` | recovery alcove/tool storage | 128×128 | 1 |
| `station__prop__service_placard__128x64.png` | technical label / provenance cue | 128×64 | 1 |
| `station__prop__reference_cradle__128x128.png` | unmistakable keyed socket close to receiver | 128×128 | 1 |

Key source has **iron + insulating ceramic**, a mechanical keyed geometry/locking end and worn accessible handle. Avoid literal fantasy key teeth, glowing crystal, bell-clapper silhouette or magical relic ornament. The receiving seat must visibly accept it. User-facing item name: **Receiver Key**. Object belongs to local receiver system, not the Dry Fountain.

## Group C — localized overlap VFX

**Proposed family:** `ritualant_highland_station_overlap_fx`
**Schema:** `custodian.asset_family.v2`, kind `effect` using `ritualant_underground_hazard_fx` as validated template.
**Provisional inbox:** `custodian/asset_drop/inbox/ritualant_highland_station_overlap_fx/`
**Proposed runtime directory:** `custodian/content/sprites/effects/runtime/ritualant_highland_station_overlap/`
**Family metadata:** `custodian/content/metadata/assets/families/ritualant_highland_station_overlap_fx.asset.json`

| Source state | Usage | Per-frame px | Frames / total |
| --- | --- | --- | --- |
| `geometry_echo_mask` | ghost edge mask for threshold/parallax mismatch | 512×256 | 1, static |
| `receiver_reference_pulse` | short on-key confirmation, not world-wide flash | 192×192 | 8, 1536×192 strip |
| `chapel_memory_overlay` | selected chapel architecture overlap, layer-local | 512×384 | 1, static |

**Prefer shader/property animation for double-image offsets**, not a long baked sprite strip. Exact final filenames must be generated by the approved family `filename_template`, not these source-state aliases. 1–3px local offset, intermittent brief phase windows; reduced-flicker mode. Validate alpha of all masks, scene-local occlusion, native-scale pixel snapping and render performance before audiovisual acceptance.

## Group D — character idle and ambient (separate family decisions)

- Current Ritualant production art is `128×128` frame-based and should be reused for ordinary kneel/idle. Candidate new loop roles after animation audit: `count_on_fingers` **6 frames @ 5 FPS** (768×128 strip); `adjust_white_thread` **8 frames @ 5 FPS** (1024×128 strip); `glance_to_receiver` **6 frames @ 5 FPS** (768×128 strip); `settle_before_release` **8 frames @ 5 FPS, non-looping** (1024×128 strip). Respect existing action/direction/alpha ownership and pipeline; do not make the state names runtime authority yet.
- One possible station-duty echo **8× 96×128 frames @ 6 FPS** (768×128 horizontal) only after identifying whether an accepted procession/actor resource can be reused. One chapel silhouette may reuse existing procession FX; do not generate duplicates on speculation.
- No authored character source is approved by these proposals, and no extra live NPC AI is authorized. Human visual review at actual gameplay zoom is required before calling newly generated character states production-ready.

## Coverage, controls and validation

1. Run inventory against `forlorn_ritualant_underground.tscn`, `forlorn_ritualant_site.tscn`, the V2 catalog and the user's collected asset ZIP; classify H0/H1/H2/H3 for reused props.
2. Commission art only for confirmed missing states; don't create or ingest assets from this brief automatically.
3. Keep static alpha and occlusion independent of gameplay collision; procedural geometry/nav stays owned by level.
4. After creation, use source-work for any approved working masters under `custodian/asset_drop/source_work/ash_bell/highland_station/`; place single-family clean assets into the matching `asset_drop/inbox/<family>/`, create/validate family metadata, then use Asset V2 tooling to ingest.
5. Confirm state/size/frame count, visibility, collision independence, 32px-grid legibility, optional shader reduced motion, real camera zone visibility and independent user art approval. No new art is marked live by this spec.
