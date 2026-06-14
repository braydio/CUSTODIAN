# Agent Task Packets

Last updated: 2026-06-12

Task packets are optional, task-scoped risk-control and handoff files for CUSTODIAN agents.

## Selection

- Skip packets for narrow, low-risk, single-session work.
- Use the compact template when scope, constraints, acceptance, or deferred work needs a durable record.
- Add full-packet sections only for high-risk, multi-session, architecture, ownership, migration, or substantial handoff work.
- Do not create a packet merely because several files change.

## Workflow

1. Decide whether a packet adds enough value to justify maintaining it.
2. If so, copy `../AGENT_TASK_PACKET_TEMPLATE.md` into this folder.
3. Rename it after the task in uppercase snake case, for example `VALIDATION_RECIPES.md`.
4. Fill the compact fields and delete unused optional sections.
5. Keep it current when scope, blockers, acceptance, or deferred work materially changes.
6. Mark it `complete` only after implementation, required docs updates, feasible validation, and completion notes are done.

## Ownership

- Reuse a packet only when it is scoped to the current task.
- Create a new packet for a different task, even if related files overlap.
- Do not update another agent's in-progress packet unless the user asks or that packet is explicitly the active task surface.
- Set `Agent/session` in new packets with a stable handle, such as `Codex 2026-05-03T11:xx`.
- Update `Last updated` whenever a packet changes.

## Archive

Completed packets are moved to `archived/`. They are preserved for historical reference but are no longer active task surfaces.

## Active Packets

### In Progress

- `GAME_OVER_FLOW.md` — Implement the game-over UX slice from `design/02_features/game_over/GAME_OVER_FLOW.md`: fail-state modal, stats snapshot, restart/menu actions, and validation.
- `PLAYABLE_SIEGE_LOOP_GATEHOUSE_SLICE.md` — Extend the Sundered Keep gatehouse into a playable siege loop with gate progression, enemy pressure, objective damage, repair, defense participation, debug feedback, and validation/docs updates.
- `COGNITIVE_STATE_PHASE_B.md` — Wire cognitive state modifiers into game systems and fix debug panel bugs. Implementation done; awaiting Godot runtime validation of move speed, attack recovery, accuracy bonus, and crit bonus modifiers. Manual test: F12 toggles debug panel, cognitive items change player stats visually.
- `UI_GD_FIXES.md` — Fix 11 hard compile blockers, runtime bugs, and performance issues in `ui.gd`. 10 of 11 fixes verified in code; Fix #11 (minimap rebuild performance) deferred. Boot sequence and stub cleanup still need Godot runtime confirmation.

### Recently Complete (awaiting archive)

- `ASH_BELL_FORLORN_RITUALANT.md` — Added the centralized authored-scene procgen authority reservation API and wired Ash-Bell dev placement to claim its canonical room footprint before instantiation.
- `PROCGEN_ASCENT_STYLE_FACTION_STORY_V1.md` — Added distance-band world progression, connectivity-safe gradual ascent metadata, deterministic faction activity anchors, environmental story-room candidates, placeholder markers, and enemy ambient routines.
- `OPERATOR_MODULAR_SIDEARM_PLAYBACK.md` — Corrected facing ownership and wired four-diagonal synchronized sidearm draw/fire lower, upper, pistol, and FX layers with draw-complete gating, held final draw pose, fire-to-held return, and Operator-local alignment.
- `OPERATOR_MODULAR_SIDEARM_INGEST.md` — Validated the supplied modular sidearm draw filenames, added `modular_sidearm` shared-inbox routing, and built stable lower-body, upper-body, and sidearm weapon-layer runtime modules for `draw_sidearm_01`.
- `OPERATOR_DODGE_PIPELINE_AND_SIDEARM.md` — Added split dodge/recovery runtime and pipeline support, introduced the default pistol sidearm slot for no-primary ranged-ready fallback, mapped sidearm V1 to current ranged placeholder animations, and tracked missing production dodge/sidearm clips.
- `OPERATOR_MODULAR_IDLE_AND_INGEST.md` — Fixed Fists idle so the modular lower/upper layer stack renders before legacy authored-body fallback, separated lower movement direction from upper action/aim direction, and routed modular Operator sprite inbox files through the live module rebuild/SpriteFrames refresh path.
- `ROAD_TILE_LANE_ROLE_PLACEHOLDERS.md` — Updated procgen road overlays to use the 32x32 lane-role contract `center`, `left_1`, `left_2`, `right_1`, and `right_2`, with placeholder manifest aliases and focused smoke validation.
- `FABRICATION_BALANCE_PIPELINE.md` — Added a deterministic offline fabrication/resource balance pipeline with explicit 30-minute scenario inputs, build/drop-rate simulation, lore-aware drop-table checks, Markdown report output, and JSON-only balance proposals.
- `OPERATOR_TWIN_STICK_DODGE_INPUT.md` — Added keyboard/mouse plus Xbox twin-stick movement/aim bindings, held ranged-ready aliases, RT/LMB panic ranged shot support, movement-first dodge, idle aiming backstep, focused smoke coverage, and missing directional dodge asset tracking.
- `ENEMY_MARINE_DASH_ATTACK.md` — Hardened enemy marine dash as a heavy commitment move with locked windup telegraph, dash-only hit window, hitstop/knockback/camera feedback, recovery punish window, Sundered Keep ambush tuning, validation coverage, and required body/FX/audio asset tracking.
- `TERMINAL_OVERLAY_SUPPRESSION.md` — Hid compact gameplay HUD/debug overlays while the terminal interface is open and added focused smoke coverage for open/close restoration.
- `BLACK_RELIQUARY_LIVE_MINIMAP.md` — Made the Black Reliquary HUD minimap compact and live by embedding the shared tactical minimap renderer and exporting Sundered Keep authored floor/wall minimap data.
- `SUNDERED_KEEP_HUD_SCOPE.md` — Restricted Sundered Keep-specific quest/status/prompt/minimap HUD content to the active keep map and preserved that state through terminal overlay suppression.
- `SIDEARM_UNLOCK.md` — Progression-locked the P-9 sidearm fallback and added the one-time Sundered Keep Great Hall field-retention locker unlock.
- `OPERATOR_RANGED_READY_INPUT.md` — Changed ranged secondary into held ranged-ready/aim, moved right mouse off block, kept primary as the ranged fire confirm while ready, and added focused smoke validation.
- `DEBUG_SCREEN_UI.md` — Added the dedicated F12/`debug_hud` tabbed debug screen, moved diagnostics out of scattered normal HUD labels, and added focused smoke validation.
- `UI_COMPACT_DEBUG_GATING.md` — Reduced normal-play HUD footprint, changed Black Reliquary vitals to a header-style strip, tightened prompt/minimap component minima, and moved unformatted diagnostics behind explicit debug HUD visibility.
- `SUNDERED_KEEP_GAMEPLAY_ELEVATION_OCCLUSION.md` — Implemented the `design/GAMEPLAY.md` Sundered Keep elevation/underpass/keep-roof cutaway slice with authored region metadata, shadow/support dressing, roof occluders, and smoke coverage.
- `CUSTODIAN_HOME_BEGINNING.md` — Moved the first-objective design into the Home architecture docs and added the dedicated Home beginning scene with Field Terminal witness-contact interaction, Black Reliquary HUD presentation, validation, and required asset tracking.
- `AUTHORED_VAULT_GRUNT_LOOT_MARINE_WIRING.md` — Placed the first authored gothic vault room, added the practical salvage grunt loot table, and wired `enemy_marine` as a late-unlock idle-backed wave enemy with missing non-idle assets tracked.
- `VAULT_STORAGE_RAIDING_REVIEW_RUNTIME.md` — Reviewed vault/resource raiding specs, created the permanent vault storage runtime sprite home, added storage integrity/visual states, and wired enemy storage sabotage alongside theft.
- `OPERATOR_MODULAR_LAYERED_RUNTIME_RIG.md` — Added the first optional upper/lower modular locomotion layer rig for Fists idle/walk/run, generated upper-body runtime modules with fallbacks, and tracked remaining modular source-art gaps.
- `OPERATOR_MODULAR_LOWER_BODY_RUNTIME.md` — Added the modular operator runtime module builder/folder, generated lower-body locomotion modules, wired Fists movement defaults to module strips, corrected fast-strike east/west `96px` runtime slicing, and tracked missing modular source sheets.
- `OPERATOR_MODULAR_FAST_ACTION_RUNTIME.md` — Created the dedicated operator action-runtime folder, generated modular-derived unarmed fast strike body/FX sheets, wired Fists fast attack through existing shared attack states, and tracked missing source art.
- `CONTENT_DIRECTORY_STABILIZATION.md` — Documented content-root domains, added a duplicate/loose-file audit, moved the Road of Witnesses prototype map out of loose content root, moved remaining loose sprite/tile source files into owner folders, and cleared `content/unregistered/` by moving vault art into vault-owned source quarantine.
- `SUNDERED_KEEP_PHASE_1.md` — Implemented the first Sundered Keep connected-map slice with generated runtime assets, Main Gate/Courtyard/Great Hall layout, traversal stubs, and contract-world entry gate.
- `CHANGE_CONTROL_BUNDLE_SCRIPT.md` — Adds a change-control bundler that writes current git-changed files to `custodian/docs/change_control/<TASK_PACKET_NAME>.md` and copies the bundle to the clipboard when available.
- `GOTHIC_COMPOUND_LAYOUT_GRAMMAR.md` — Hardens gothic compound asset metadata, zoning, decal quotas, anchoring, footprint placement, and perimeter validation.
