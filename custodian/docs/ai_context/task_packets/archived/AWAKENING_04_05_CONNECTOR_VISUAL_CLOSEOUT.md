# AWAKENING 04→05 CONNECTOR VISUAL CLOSEOUT

- Workstream: `awakening-reliquary-dust-lung-connector`
- Status: `complete`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `none`
- Locks: `awakening-04-05-connector-presentation`
- Goal: Remove the remaining visible straight room-canvas joins at the Dust Lung and Locker Reliquary ends of the 04→05 connector without changing traversal geometry, room placement, or the approved source art.
- Current measured state: `main@791eb9a62` contained the 1024×576 `full_plate_underlay` centered at `(352,-2464)`, 96px architectural bleed, and registered room pixels at both ends. Direct captures reproduced straight paste boundaries. This slice removed the connector opacity override, fades Zone04/Zone05 art down across a 128px connector-facing band, and feathers the two compositor room-overlap masks by 32px. The optional foreground state remains intentionally unbound because the approved master is flattened RGB.
- Task-specific authority: `design/04_architecture/AWAKENING_FIRST_RETURN.md`; `custodian/game/world/awakening/awakening_first_return.gd`; `custodian/scenes/awakening_first_return.tscn`; `custodian/tools/assets/compose_awakening_connector_full_plate.py`; `custodian/content/metadata/assets/families/awakening_reliquary_dust_lung_connector.asset.json`.
- Change:
  1. Remove the binary Zone04/Zone05 “keep opaque while inside connector” presentation behavior and let those room plates transition through the existing distance-based zone fade while the connector underlay remains driven by the merged A/B/C envelope. Preserve `ZONE_ART_FADE_DISTANCE`.
  2. Verify the existing exact room-pixel overlap produces a seamless crossfade at both ends. If a hard seam remains, adjust only the room-end overlap crop/mask/registration in the existing compositor; preserve the 1024×576 canvas, `Vector2(352,-2464)` center, approved `full_plate_source.png`, and locked route registration.
  3. Update focused smoke coverage so the Dust Lung and Reliquary room art is not forced opaque solely because the Operator is inside the connector, connector art remains visible through the dogleg, and backtracking restores the expected room presentation without a pop.
  4. Produce new direct runtime captures at connector C, B, A, and an overview and compare them against the currently committed evidence. Do not call visual acceptance green unless the straight rectangular room-canvas joins are no longer visible in motion or stills.
  5. Correct directly related documentation drift: `FILE_INDEX.md` still describes the retired 832×384 full plate, and `AWAKENING_RELIQUARY_DUST_LUNG_CONNECTOR_CLAUDE_SUMMARY.md` contains a contradictory trailing statement that the landed repair is “uncommitted.” Keep the design/required-assets wording unchanged unless this slice changes their owned truth.
- Preserve: `awakening_layout.gd` A/B/C rectangles and merged 832×384 traversal envelope; Zone04/Zone05 positions and room plates; 1024×576 connector visual canvas and Asset V2 family identity; 128px fade distance/curve; traversal, collision, progression, P-9, triggers, camera reveals, lighting geometry, and source provenance.
- Non-goals: No new generated art; no room movement; no new connector geometry; no HUD/UI work; no P-9/progression redesign; no fabricated foreground extraction from the flattened RGB master; no unrelated Awakening cleanup.
- Acceptance:
  - Dust Lung → connector and connector → Locker Reliquary no longer expose a straight rectangular room-canvas boundary in direct runtime captures or while backtracking.
  - No doubled stair/threshold, brightness pop, missing floor, or floating architectural fragment appears during the crossfade.
  - `Connector04_05_Underlay` remains centered at `Vector2(352,-2464)`, 1024×576, presentation-only, and the merged A/B/C traversal geometry remains unchanged.
  - Focused smoke asserts the corrected alpha lifecycle at representative C/A transition positions and passes with geometry/progression regressions.
  - If compositor pixels change, Asset V2 ingest/status/doctor and the asset pipeline ingest smoke pass for the family with no stale runtime state.
  - New C/B/A/overview evidence is committed under the existing `reports/awakening_connector_04_05/` convention and the closing summary records whether visual acceptance is actually green.
- `FILE_INDEX.md` and the connector closing summary no longer state superseded runtime truth.

### Completion

- `awakening_first_return_smoke.gd` asserts the 128px room-to-connector crossfade at Reliquary and Dust Lung midpoints/thresholds, connector visibility at C/B/A, reverse traversal, and full room-art restoration.
- The compositor feathers only its registered room-overlap crop edges by 32px; canvas size/center, approved source, route registration, and Layout A/B/C are unchanged.
- The user-authorized WAV compatibility repair converted `hit_medium_body_01.wav` from PCM signed 24-bit to PCM signed 16-bit; mono, 48 kHz, and 0.683542-second duration are preserved. Its existing `.import` descriptor imported successfully, and validation ownership now routes this runtime dependency through the Awakening integration test.
- New renderer-backed 1920×1080 captures at C, B, A, and overview are saved in `reports/awakening_connector_04_05/`. Direct review confirms the previous rectangular room-paste joins are no longer visible; exterior transparency remains intentional. Visual acceptance is green.
- Targeted Asset V2 replace ingest completed with Godot import. The source-work master was not changed. The optional foreground remains deferred.
- Task overrides: user-authorized WAV import compatibility conversion, preserving mono, 48 kHz, and duration.
- Deferred: Authored foreground occlusion remains deferred until a layered/alpha-separated source can support it without arbitrary cuts through baked lighting and shadows.
- Scope extension authorized by user: Convert the unrelated-but-blocking `custodian/content/audio/sfx/combat/hit_medium_body_01.wav` from PCM 24-bit to Godot-importable PCM 16-bit while preserving mono, 48 kHz, and duration. The `.import` descriptor already exists; this is source-format repair, not descriptor regeneration.

### Work Surface

- Files/systems to change: Awakening zone/connector presentation fade; focused smoke coverage; connector compositor only if overlap correction is still required; directly stale connector docs/evidence.
- Related consumers or tests: `awakening_first_return_smoke.gd`, `awakening_first_return_geometry_smoke.gd`, `awakening_first_return_progression_smoke.gd`; Asset V2 ingest validation only if the runtime texture changes.

### Plan

1. Prove or falsify the `keep_opaque_in_connector` seam hypothesis with the smallest runtime/presentation change and focused smoke assertions.
2. Capture C/B/A/overview. If the seam is gone, stop; do not touch the compositor.
3. Only if the seam persists, make a bounded room-overlap/mask correction in the existing compositor, reingest that family state, and recapture.
4. Correct the two known documentation-drift items and close with focused validation plus one changed-file sweep.

### Handoff

- Closed: connector crossfade and crop feathering are implemented, direct evidence reviewed, task files documented, and changed-file validation passed. The user-authorized WAV import compatibility repair is included in this task branch.
- Deferred: foreground occlusion remains pending a layered or alpha-separated source. No blocking questions remain.
