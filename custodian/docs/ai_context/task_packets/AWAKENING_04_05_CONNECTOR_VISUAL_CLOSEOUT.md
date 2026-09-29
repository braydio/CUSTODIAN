# AWAKENING 04→05 CONNECTOR VISUAL CLOSEOUT

- Workstream: `awakening-reliquary-dust-lung-connector`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `awakening-04-05-connector-presentation`
- Goal: Remove the remaining visible straight room-canvas joins at the Dust Lung and Locker Reliquary ends of the landed 04→05 connector while preserving the approved connector art, room placement, traversal geometry, and Asset V2 identity.
- Current measured state: The landed connector implementation (`c53160b`, reverified on current main immediately before this packet was promoted to auto-dispatch) contains: one 1024×576 `full_plate_underlay` centered at `Vector2(352,-2464)`, 96px architectural bleed, exact registered room-underlay overlap at both ends, unchanged A/B/C traversal geometry, and no fabricated foreground layer from the flattened RGB source. Focused Awakening/Asset V2 validation passed for that implementation, but direct runtime review still shows straight rectangular room-canvas joins at the Dust Lung and Locker Reliquary handoffs. `awakening_first_return.gd` currently forces Zone04/Zone05 art to alpha 1.0 whenever the Operator is inside the merged connector envelope via `keep_opaque_in_connector`, preventing the normal 128px distance fade from owning that handoff.
- Task-specific authority: `design/04_architecture/AWAKENING_FIRST_RETURN.md`; `custodian/game/world/awakening/awakening_first_return.gd`; `custodian/scenes/awakening_first_return.tscn`; `custodian/tools/assets/compose_awakening_connector_full_plate.py`; `custodian/content/metadata/assets/families/awakening_reliquary_dust_lung_connector.asset.json`; current `custodian/AGENTS.md`; current validation recipes.
- Change:
  1. Remove the binary Zone04/Zone05 `keep_opaque_in_connector` presentation override so those room plates transition through the existing distance-based zone fade while the connector underlay remains driven by the merged A/B/C connector envelope. Preserve `ZONE_ART_FADE_DISTANCE` and its current curve.
  2. Update focused smoke coverage to prove Zone04/Zone05 are not forced opaque solely because the Operator is inside the connector, the connector remains visible throughout the dogleg, and forward/backtracking transitions do not pop.
  3. Produce fresh direct runtime captures at representative C, B, A, and overview positions and inspect them before editing the compositor.
  4. Only if a straight join remains after Step 1, make the smallest bounded correction to the existing registered room-overlap crop/mask/registration in `compose_awakening_connector_full_plate.py`. Preserve the 1024×576 visual canvas, `Vector2(352,-2464)` center, approved `full_plate_source.png`, uniform-scale source transforms, and locked route registration. Reingest through Asset Pipeline V2 only if connector pixels change.
  5. Correct directly related documentation drift: `FILE_INDEX.md` must describe the live 1024×576 `full_plate_underlay` rather than the retired 832×384 plate, and `AWAKENING_RELIQUARY_DUST_LUNG_CONNECTOR_CLAUDE_SUMMARY.md` must remove the stale trailing claim that the landed implementation is “uncommitted.”
- Preserve: `awakening_layout.gd` A/B/C rectangles and their merged 832×384 traversal envelope; Zone04/Zone05 positions and room plates; 1024×576 connector registration and Asset V2 family/state identity; source provenance; traversal, collision, progression, P-9, triggers, camera reveals, lighting geometry, and unrelated Awakening presentation.
- Non-goals: No new generated art; no room movement; no new connector geometry; no HUD/UI work; no P-9/progression redesign; no invented foreground extraction from the flattened RGB master; no global fade retuning; no unrelated Awakening cleanup.
- Acceptance:
  - Dust Lung → connector and connector → Locker Reliquary no longer expose a conspicuous straight rectangular room-canvas boundary in direct runtime stills or while traversing/backtracking.
  - No doubled stair/threshold, brightness pop, disappearing floor, floating architectural fragment, or new black-gap defect is introduced.
  - `Connector04_05_Underlay` remains 1024×576, centered at `Vector2(352,-2464)`, presentation-only, and the Layout A/B/C traversal geometry remains unchanged.
  - Focused smoke covers the corrected alpha lifecycle at representative C/A transition positions and passes with geometry/progression regression checks.
  - Run the narrowest relevant Moment Forge presentation scenario selected by `python3 custodian/tools/iteration/run_moment.py --changed`; use evidence/full capture only as required for final visual judgment. If no applicable stable scenario exists, record that and rely on the required direct C/B/A/overview runtime evidence rather than inventing a broad sweep.
  - If compositor pixels change, Asset V2 plan/ingest/status/doctor plus the relevant ingest smoke pass with no stale connector runtime state.
  - New C/B/A/overview evidence is committed under `reports/awakening_connector_04_05/`, and the closing summary records whether visual acceptance is actually green.
  - `FILE_INDEX.md` and the connector closing summary reflect live runtime truth.
  - Complete/archival/finish follow the current workstream lifecycle on the task branch.
- Task overrides: `none`
- Deferred: Authored foreground occlusion remains deferred until a layered/alpha-separated source can support it without arbitrary cuts through baked lighting and shadows.

### Work Surface

- Files/systems to change: `custodian/game/world/awakening/awakening_first_return.gd`; focused Awakening smoke coverage; `custodian/tools/assets/compose_awakening_connector_full_plate.py` only if fade-first review still shows a seam; directly related connector docs/evidence.
- Related consumers or tests: `custodian/scenes/awakening_first_return.tscn`; `awakening_first_return_smoke.gd`; `awakening_first_return_geometry_smoke.gd`; `awakening_first_return_progression_smoke.gd`; Asset V2 connector family/status if pixels change; relevant Moment Forge presentation selection.

### Plan

1. Inspect current live main/AGENTS and sync/reuse the existing workstream through dispatcher/workstream tooling. Do not implement in the coordination checkout.
2. Remove only the `keep_opaque_in_connector` override and add the focused alpha-lifecycle assertions.
3. Run focused smoke, then capture C/B/A/overview and inspect the actual images. If the seam is gone, stop the visual implementation here.
4. Only if the seam persists, make one bounded registered room-overlap/mask correction in the existing compositor, reingest the family, rerun focused validation, and recapture.
5. Run the narrowest relevant Moment Forge presentation check, correct the two known documentation-drift items, perform the changed-file validation closeout, write/update the closing summary, mark this packet complete and archive it, then finish/land through the standard workstream lifecycle.

### Handoff

- Next action: Auto-claim `awakening-reliquary-dust-lung-connector`; begin with the room-opacity override hypothesis before touching asset composition.
- Best starting files: `custodian/game/world/awakening/awakening_first_return.gd`; `custodian/tools/validation/awakening_first_return_smoke.gd`; `reports/awakening_connector_04_05/`.
- Blockers or open questions: None. The packet is safe for automatic claim because the implementation order, stop condition, preservation boundary, and visual acceptance evidence are explicit.
