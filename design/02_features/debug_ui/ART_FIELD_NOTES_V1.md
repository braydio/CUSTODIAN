# Art Field Notes V1: in-game missing-art flags and incremental runtime installation

**Status:** implementation proposal with first evidence-capture slice in a draft branch; no source approval or runtime-art publication.
**Owner:** developer tooling + artwork integration.
**Program:** `hub-sepulcher-awakening-art-v1`.
**Authority:** `HUB_SEPULCHER_AWAKENING_ART_V1_MANIFEST.json`, `SEPULCHER_GARDENS_GEOMETRY_V1.json`, `ASSET_PIPELINE_V2.md`, `DEVELOPER_OBSERVATORY_SYSTEM.md`, and live consumers.
**Scope:** observation, triage and small guarded installations. Not a second asset pipeline, geometry owner, task dispatcher, or gameplay editor.

## Why this exists

A playable world can remain visually sparse even when many standalone art candidates exist. The player/developer can identify the exact missing stretch while seeing it in its real gameplay context. A flag ties that observation to spatial evidence; Codex can then find the responsible art state, validate its immutable human-approved source and prepare a focused installation. Work is grouped into small verifiable world stretches rather than waiting for completion of every source prompt.

## V1 operator experience

- In a `DevMode` developer session, press `I` once while the Operator is in world. Do not intercept focused UI typing. In a release build, this initial implementation additionally requires `--custodian-art-inspection` **and** an explicit `DevMode` enable flag such as `--custodian-dev`; this enables the existing debug suite and is only appropriate for a trusted private playtest build, not a broadly exposed public production launch. Future dedicated inspector-only gating should be reviewed before shipping broadly.
- A brief in-game receipt appears and one `custodian.art_inspection_flag.v1` JSON and one screenshot PNG are written to `user://art_inspector/flags/`. Filenames contain the UTC timestamp, scene, and rounded Operator world x/y; a monotonic suffix prevents collisions.
- Record player world, mouse world and camera positions, current scene, viewport, screenshot status, and a capped list of visible actors from existing groups. Do not run a full recursive tree scan, modify simulation, or collect unbounded telemetry.
- Include the *last existing* F10 export path if present; `I` does not trigger an F10 export, alter F9, or stop/reset F11 performance recorder. F10 remains the owner's telemetry export path under `user://dev_observatory/`. F12/debug shell remain unchanged.
- The screenshot and JSON remain on the player's local machine. No background upload, network connection, account information, or personal telemetry transfer. Screenshot contents may include private UI/chat and must be reviewed before sharing.
- Use `ProjectSettings.globalize_path("user://art_inspector/flags")` or console output to find the exact OS path. The directory is persistent across restarts, not stored in the repository.
- This initial slice is an **evidence recorder**, not a full annotation UI: `intent=missing_art`, optional notes can be added later to the record in a downstream triage tool. It does not automatically install art.

## Read-only Codex collector

`python3 custodian/tools/art/collect_art_flags.py --dir "/absolute/path/to/flags" --format markdown`

The collector reads the JSONs, warns on invalid records, groups samples by scene and 256px world buckets, reports screenshot presence and classifies Gardens positions against the existing 96x84 binary mask, D1-D7 polygons and nearby landmarks. The binary mask remains authoritative for live traversal; the design polygons only inform triage. An optional `--format json` produces stable machine-readable output.

**Triage rule:** a location is not itself an asset identity. Codex must inspect flags and screenshots, match to exact manifest asset IDs, check current runtime consumers and Asset V2 family states, then create a scoped installation proposal. A visible blank spot may actually be a deliberate nonwalkable gap, an occlusion issue, a camera/lighting issue, or an unfinished material; flag classification never overrides geometry.

## Incremental installation protocol (one reviewable stretch at a time)

1. **Capture.** Collect one or more flags. Preserve the raw JSON+PNG unchanged. Resolve scene, viewport/camera, Operator coordinates, visible actors and existing F10 reference. Assign a stable work item, e.g. `ARTSTRETCH-001`, with the exact flag IDs and world coverage.
2. **Diagnose.** Reproduce and classify each gap as missing ground, shoreline, vertical structural presentation, dressing, occlusion, or not an art defect. Identify exact program asset ID(s), authored 32px cell registration, expected mask/collision owner, source/inbox/family paths, scene consumer and nearest anchors. Confirm current Git SHA and detect drift against newer runtime. Avoid claiming one flag matches one particular asset without evidence.
3. **Authorize source.** Separate `PASS_CANDIDATE` and candidate Dropbox receipts from **human production-source approval**. For each selected state, demand an explicit SHA-256-pinned human source approval and matching actual bytes, alpha, dimensions, framing, seams and reference provenance. If missing, mark the work item `SOURCE_APPROVAL_BLOCKED`; report the flag, do not download-and-install a candidate. Preserve CAL-01 and CAL-02 human/attempt gates.
4. **Stage source, not runtime.** Use the existing approved Dropbox-to-source_work audit/stage route, verify SHA-256 on retrieved bytes and normalize into the exact manifest `inbox_path`. Do not use screenshots/contact sheets as source. Check proposed `family_contract_path`; extend/register Asset Pipeline V2 only with valid contracts and declared state mapping. No new family shortcuts.
5. **Plan a small runtime diff.** Explicitly identify which scene renderer, Asset V2 consumer and placement record will display the art. For CAL-01, a native 512px repeat source is clipped to the existing 96x84 walkable mask from world `(-4128,-4480)`; it is never a new rectangular ground map. For D6, alpha-bearing structure is clipped/registered against the real D6 nonwalkable polygon at its authorized origin. Do not invent doors, collision, walkable space, anchors, grave events or secret loot. Keep placement reversible and limited to the flagged stretch/approved state.
6. **Validate.** Run `python3 custodian/tools/assets/asset.py plan <family>`, `status <family>`, `doctor`, `needs --check`, focused geometry/scene/playtest tests, and actual in-game sampling at the flagged coordinates. Check 128px Operator readability, both Forum connectors, E0-E5 event clearances, mask edges, occlusion ordering, 3x3 joins where applicable, and original versus updated same-camera screenshot. Use F10 when further world-state evidence is needed; do not automatically generate full-frame screenshot series. Tests and review must pass before any release cutover.
7. **Close or reflag.** Persist a small reviewed receipt: flag IDs, exact source SHA-256/human approval receipt, Asset V2 family and job, runtime commit, screenshot/probe evidence, relevant test output, final disposition (`installed` / `blocked` / `not_art` / `needs_revision`). Do not mark a flag resolved based solely on Git commits or candidate staging. New flags can re-open the area.
8. **Next stretch.** Pick the next highest-impact flagged area with approved source and a safe consumer. Unrelated artwork can continue in candidate-only staging; this runtime lane must never advance the human approval cursor implicitly.

## Authority and safety invariants

- Gameplay ownership, walking mask, collision, authored anchors and event placement never move merely to accommodate a PNG.
- `DevMode` gates the key; flags only write bounded local developer evidence. No production player telemetry or remote uploads.
- F9 controls overlay only; F10 is Observatory export; F11 is incident recorder. ArtInspector does not call or shadow them.
- Candidate staging is NOT source approval; source approval is NOT Asset V2 registration; registration is NOT runtime visual acceptance.
- A flagged stretch never authorizes new image generation, Dropbox upload, asset approval, or runtime mutation by itself.
- Codex must use existing dispatcher/task-packet review and locks for write work. The collector is read-only. No unattended production writeback or auto-merge based on a flag.
- Generated screenshots and flags stay under `user://` or an explicitly chosen local report destination, not tracked in Git.
- Missing PNG, failed JSON write, wrong scene, missing Operator, corrupted record and missing F10 export must fail gracefully and remain observable.

## Delivery / test gates

**Slice A, first implementation:** ArtInspector autoload, guarded I key, screenshot+JSON, bounded visible actor scan, persistent local folder, read-only collector, manifest docs. No asset installation, no new user-facing menu, no automatic link to Dropbox.

**Slice B, requires playtest review:** In-game flags list/revisit and optional short annotation; indicator/counter; duplicate grouping and overlay on existing F9 page by Observatory owner, not a second F9 implementation.

**Slice C, requires separately approved automation:** Codex task creation from grouped flags and source status read-only audit; source approval resolution; scoped asset/install PR generation with validation evidence. Promotion requires ordinary reviews and existing asset pipeline gates.

**Recommended verification before merge:** Godot parse/import, DevMode smoke, new ArtInspector focus/input/capture test, correct JSON+PNG on real gameplay viewport, save directory survives restart, 20 repeated I presses without collisions, no screenshot in non-opt-in release, F9/F10/F11 behavior unchanged, collector rejects malformed JSON and groups spatially correctly. CI/packets do not constitute human visual source approval.
