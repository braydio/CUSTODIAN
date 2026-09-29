# Awakening 04→05 Connector Visual Closeout

Implemented and visually reviewed the 04→05 connector room transition closeout.

- Removed the Zone04/Zone05 `keep_opaque_in_connector` override and applied the existing 128px distance fade from each room edge into the connector. The connector underlay still follows the merged A/B/C envelope.
- Direct capture review showed the room crop still read as a rectangular seam after the opacity change, so the compositor now feathers only the registered room-overlap crop edges by 32px. The canvas remains 1024×576 at `(352,-2464)`; route geometry, room placement, registration, and approved source master are unchanged.
- At the user's request, converted `custodian/content/audio/sfx/combat/hit_medium_body_01.wav` from PCM signed 24-bit to PCM signed 16-bit after Godot rejected its previous encoding. It remains mono, 48 kHz, and 0.683542 seconds. The existing `.import` descriptor imported cleanly after conversion. Added the audio resource and direct-capture script to the Awakening integration test's validation ownership so changed-file selection covers both.
- Captures at `reports/awakening_connector_04_05/connector_C.png`, `_B.png`, `_A.png`, and `_overview.png` show no straight rectangular joins, doubled thresholds, missing floors, or floating fragments. Intentional transparency outside the art silhouette remains. Visual acceptance is green.
- Focused smoke covers connector visibility at C/B/A, room fade values at both connector ends, and reverse traversal/full room restoration. Asset V2 replace ingest ran with Godot import. The source-work master remains unchanged; the optional foreground remains deferred because the approved master is flattened RGB.

Validation:

- `awakening_first_return_smoke.gd`: PASS.
- `awakening_first_return_geometry_smoke.gd`: PASS (136×480 grid, 16,801 safe cells, 555 route cells).
- `awakening_first_return_progression_smoke.gd`: PASS.
- `asset_pipeline_ingest_smoke.py`: PASS.
- `run_validation.py --changed --json`: PASS (15 selected, 15 passed, 0 failed, 0 skipped; complete coverage).
- Moment Forge `traversal/awakening_underlays_zones_01_05` full capture: passed all assertions (300-frame run, report under `reports/moment_forge/traversal/awakening_underlays_zones_01_05/20260928T201622-0400`).
- `asset doctor --json` reports only the existing unrelated unregistered `operator` inbox family (12 PNGs).

The first geometry command used the repository root as Godot's project path and failed to locate the script; rerunning with `--path custodian` passed. Before the requested audio conversion, the changed-file sweep surfaced the unsupported PCM 24-bit import and incomplete validation ownership; both were resolved and the final sweep is green. Progression and renderer-backed capture still emit existing camera `bool`/`String` constructor errors, but return success and their assertions pass. The test runner's fixture ingest smoke generated its normal temporary fixture archive. No unrelated generated artifacts are included.

The earlier `AWAKENING_RELIQUARY_DUST_LUNG_CONNECTOR_CLAUDE_SUMMARY.md` was corrected to describe the prior landed slice without claiming its repair is still uncommitted. Its stale statement was an inaccurate status tail, not a remaining code change.
