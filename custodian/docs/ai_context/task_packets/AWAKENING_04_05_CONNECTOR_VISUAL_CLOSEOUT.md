# AWAKENING 04→05 CONNECTOR VISUAL CLOSEOUT

- Workstream: `awakening-reliquary-dust-lung-connector`
- Status: `ready`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `none`
- Locks: `awakening-04-05-connector-presentation`
- Goal: Remove the remaining visible straight room-canvas joins at the Dust Lung and Locker Reliquary ends of the 04→05 connector without changing traversal geometry, room placement, or the approved source art.
- Current measured state: `main@c53160b` replaced the rejected 832×384 route-only plate with a 1024×576 `full_plate_underlay` centered at `(352,-2464)`, with 96px architectural bleed and exact registered room-underlay pixels at both ends. Focused Awakening and Asset V2 validation passed. Direct runtime review still shows a straight room-canvas edge at the C/A joins. The runtime currently forces Zone04/Zone05 art to alpha 1.0 whenever the Operator is inside the merged connector envelope via `keep_opaque_in_connector`, even though the connector already contains exact registered room pixels for crossfade overlap. The optional foreground state remains intentionally unbound because the approved master is flattened RGB.
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
- Task overrides: `none`
- Deferred: Authored foreground occlusion remains deferred until a layered/alpha-separated source can support it without arbitrary cuts through baked lighting and shadows.

### Work Surface

- Files/systems to change: Awakening zone/connector presentation fade; focused smoke coverage; connector compositor only if overlap correction is still required; directly stale connector docs/evidence.
- Related consumers or tests: `awakening_first_return_smoke.gd`, `awakening_first_return_geometry_smoke.gd`, `awakening_first_return_progression_smoke.gd`; Asset V2 ingest validation only if the runtime texture changes.

### Plan

1. Prove or falsify the `keep_opaque_in_connector` seam hypothesis with the smallest runtime/presentation change and focused smoke assertions.
2. Capture C/B/A/overview. If the seam is gone, stop; do not touch the compositor.
3. Only if the seam persists, make a bounded room-overlap/mask correction in the existing compositor, reingest that family state, and recapture.
4. Correct the two known documentation-drift items and close with focused validation plus one changed-file sweep.

### Handoff

- Next action: Claim `awakening-reliquary-dust-lung-connector`, start from the live C/A seam captures, and test the room-opacity override before editing asset composition.
- Best starting files: `custodian/game/world/awakening/awakening_first_return.gd`; `custodian/tools/validation/awakening_first_return_smoke.gd`; `reports/awakening_connector_04_05/`.
- Blockers or open questions: None. Foreground occlusion is explicitly deferred and is not required for this closeout slice.
