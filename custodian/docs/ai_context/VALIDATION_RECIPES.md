# VALIDATION RECIPES

Canonical validation guide for CUSTODIAN agent work.

Use the narrowest recipe that proves the change, then broaden only when the change affects shared runtime behavior, scenes, imports, or workflow routing.

Prefer RTK subcommands for compact output when they support the command shape. RTK is not a blind prefix: use `rtk git status`, `rtk grep ...`, `rtk find ...`, etc. For unsupported commands where token tracking still helps, use `rtk proxy <command> ...`. Use the raw command when RTK changes argument ordering or hides information needed for debugging.

## Selection Rules

- Doc-only change: validate paths, links, status labels, and discoverability.
- Agent workflow change: validate `AGENTS.md`, `custodian/AGENTS.md`, `docs/ai_context/*`, any affected task packets, and prompt indexes.
- Runtime GDScript change: run a Godot headless check when feasible.
- Scene or asset import change: run Godot import before headless boot when feasible.
- Sprite pipeline change: run dry-run ingest first, then targeted ingest only when outputs are intended.
- Generic runtime-ready asset intake: run the persistent drop router in dry-run mode before apply.
- Tile pipeline change: run Python syntax checks plus the relevant tile generator command.
- Commit/staging task: inspect status with RTK, but do not stage or commit without explicit user approval.

## Common Commands

Run from the repository root unless the recipe says otherwise.

```bash
rtk git status
rtk git diff
rtk grep "pattern" path
rtk find path -maxdepth 3 -type f
```

Correction examples:

```bash
# Git status goes through the git subcommand:
rtk git status

# Exact porcelain status should stay raw:
git status --short

# Raw ripgrep can stay raw or go through proxy:
rg -n "pattern" path
rtk proxy rg -n "pattern" path
```

RTK grep argument order:

```bash
rtk grep "pattern" path --glob "*.md"
```

For complex ripgrep expressions, use raw `rg` or pass the raw command through `rtk proxy`:

```bash
rtk proxy rg -n --glob "*.md" "pattern" path
```

## Architecture / Documentation Organization Validation

Use for architecture docs, ownership map, task packet, and folder scaffold changes.

```bash
python custodian/tools/validation/architecture_ownership_smoke.py
```

This validates:

- new architecture docs exist (`ARCHITECTURE.md`, `ARCHITECTURE_OWNERSHIP_MAP.md`, `ARCHITECTURE_ORGANIZATION_PASS.md`)
- scaffold README.md files exist
- no stale `design/03_architecture` references remain inside `design/04_architecture/`
- reports line counts for overburdened coordinator files (warning only)

## Doc-Only Validation

Use for markdown, routing, task packet, and context-pack edits.

```bash
rtk grep "referenced/path" AGENTS.md custodian/AGENTS.md custodian/docs/ai_context
rtk find custodian/docs/ai_context -maxdepth 3 -type f
```

Check:

- referenced files exist or are explicitly described as future work
- `CURRENT_STATE.md` reflects meaningful workflow/status changes
- `FILE_INDEX.md` indexes new docs, prompts, task packets, and ownership changes
- task packet status and completion notes match the actual work state when a packet exists

## Godot Runtime Validation

Use for runtime GDScript, scene wiring, autoload, input, or gameplay behavior changes.

```bash
cd custodian
godot --headless --quit
```

For turret placement resource and dismantle behavior:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/turret_placement_smoke.gd
```

For token-driven Light Barricade fabrication and placement, including Basic Turret regression:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/build_structure_placement_smoke.gd
```

Use import first when scenes/assets/resources changed:

```bash
cd custodian
godot --headless --import --quit
godot --headless --quit
```

Known caveat: current headless validation may exit with existing object/resource leak warnings. Treat new parse errors, missing resources, broken script loads, or changed fatal errors as blockers.

For Operator combat-resource feedback, compact HUD pressure state, and weapon-local presentation isolation:

```bash
cd custodian
env HOME=/tmp/custodian-godot-home godot --headless --path . --import --quit
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/ranged_combat_balance_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/combat_resource_feedback_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/operator_primary_ranged_modular_fire_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/operator_weapon_socket_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/operator_ranged_ready_input_smoke.gd
```

The focused feedback smoke validates progress fields, dry/reload priority, held-input debounce, hot/critical/overheat/recovery transitions, monotonic reload transfer, per-weapon persistence, zero presentation `NoiseEventBus` emissions, and read-only HUD consumption. The modular fire and ready-input smokes additionally validate raise/lower direction retargeting without progress reset, committed shot direction, recovery-to-current-aim, posture/readiness status, and upper/weapon direction plus frame-clock synchronization. The socket smoke validates generated Carbine phase-1 metadata, socket-derived muzzle/draw order, transition timing, and camera-owned zoom/lead cancellation. Missing optional authored vent/HUD art warns without failing because the V1 presenter supplies a procedural vent and label fallback.

For allied drone fire/formation/guard-anchor commands:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/drone_follower_commands_smoke.gd
godot --headless --path . --script res://tools/validation/main_scene_allied_droid_smoke.gd
godot --headless --path . --script res://tools/validation/operator_primary_ranged_modular_fire_smoke.gd
```

These checks cover Operator/order-point anchor state, close/far/roam goals around guard points, guard return limits,
marker and replacement-drone inheritance, `K` restoring both Operator anchor and tactical FOLLOW, manager-owned InputMap actions, hold-fire cancellation, and suppression
of accidental Operator primary fire while issuing an order. The follower smoke also frees a live explicit command target
and verifies the drone clears that stale reference before entering typed targeting code.

For Developer Observatory telemetry and JSON session export:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/dev_observatory_smoke.gd
godot --headless --path . --script res://tools/validation/dev_observatory_audit_smoke.gd
godot --headless --path . --script res://tools/validation/dev_observatory_director_population_smoke.gd
godot --headless --path . --script res://tools/validation/operator_ammo_reconciliation_smoke.gd
godot --headless --path . --script res://tools/validation/operator_dodge_overlap_telemetry_smoke.gd
```

This proves bounded telemetry storage, F9/F10 action registration, stable and timestamped JSON output, JSON-safe Variant
conversion, event-buffer retention, success-event logging, failure-warning routing, numeric accumulation, and basic heatmap accumulation.
The audit smoke additionally reconciles a shared enemy attack ID through incoming-hit/player-damage events, proves a
live bullet owns a projectile-classified collision shape, and checks cumulative damage/healing/chip amounts, ranged
failure/cancellation categories, performance/leak peaks, last-live post-death context, Field Patch prompt
severity/ignored-on-death accounting, and the structured player-death snapshot. The Falcon and paired-critical smokes
cover detailed special terminals plus vulnerable-window open/consume/expire and critical start/hit telemetry. The
procgen stuck-pocket smoke checks structured remediation warning context. The ammo smoke emits 18 real projectiles and reconciles a fresh carbine from 24/48 to 6/48 without a weapon
swap. The dodge smoke classifies 20 deliberate overlaps one-for-one across iframe, late-active, and recovery phases.
The director-population smoke deliberately enables two profile-managed enemies beside one legacy enemy and reconciles
the split population gauges plus the director behavior-sample surface.

For the local exported-session report tool, run from the repository root:

```bash
python3 -m py_compile tools/analyze_dev_observatory_session.py
python3 tools/analyze_dev_observatory_session.py /path/to/latest_session.json
```

After sourcing the repo aliases, `obsreport` runs the same analyzer and discovers
the stable latest-session export when no path is supplied.

Omit the path to analyze the stable export in the standard Godot user-data location when it exists.

For authored parry critical-open phases and paired execution:

```bash
cd custodian
godot --headless --path . --import --quit
godot --headless --path . --script res://tools/validation/grunt_falcon_punch_smoke.gd
godot --headless --path . --script res://tools/validation/grunt_parry_crit_reaction_smoke.gd
godot --headless --path . --script res://tools/validation/debug_grunt_spawn_modes_smoke.gd
godot --headless --path . --script res://tools/validation/grunt_animation_smoke.gd
godot --headless --path . --script res://tools/validation/operator_modular_defense_ranged_smoke.gd
godot --headless --path . --script res://tools/validation/operator_knockdown_animation_smoke.gd
```

The Falcon smoke validates stop-short travel, body/enemy separation, dedicated Operator impact, zero-drift recovery,
hard parry cancel/lockout, deterministic eligibility, ally-lane rejection, terminal diagnostic fields, and seven stationary
connection samples at each of 96, 136, and 176 pixels. The focused reaction smoke validates required S/E/W asset dimensions, independent post-knockback roots through enter/hold/recover, normal target-ring suppression through recovery, BREACH/ring lifetime, atomic reservation, approach-owned directional selection with vertical-to-south fallback, zero-offset shared execution roots, zero-local paired layers plus transform restoration, same-tick semantic playback through the nonuniform eight-frame duration table, source-frame-5 exactly-once damage, the 110ms paired contact freeze, final-settle ownership, lethal/nonlethal resolution, and cancellation cleanup. The debug-spawn smoke validates each critical-open/execution-ready preset, opportunity presentation, one-health lethal setup, and unknown-mode rejection. Required paired/open assets fail loudly; only optional posture-break and expiry presentation may warn without failing.

For Sundered Keep asset wiring specifically:

For the registered Sundered Keep ingress and active continuous approach:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/sundered_keep_ingress_smoke.gd
godot --headless --path . --script res://tools/validation/sundered_keep_approach_smoke.gd
godot --headless --path . --script res://tools/validation/sundered_keep_level_chain_smoke.gd
godot --headless --path . --script res://tools/validation/sundered_keep_approach_collision_runtime_smoke.gd
godot --headless --path . --script res://tools/validation/sundered_keep_approach_collision_mapper_smoke.gd
```

The ingress smoke proves registered entry and procgen/connected branch isolation. The active approach smoke proves the Vista scene contains no misplaced Keep-specific runtime nodes/blocker, its backdrop covers camera bounds plus framing slack, camera targets are wired, its endpoint has a visible directional affordance, and the default target is Sundered Keep directly. It also runs the first reveal at accelerated timings and asserts its threshold/controller bindings, one-shot completion, reveal camera target, lighting cue, and post-settle prompt release. The chain smoke proves representative harvest/aspect marker suppression plus both default Vista → Keep actor placement and the optional Vista → Causeway → Keep branch, including LevelLoader adoption, source branch deactivation, entry affordance, and Keep → Causeway return anchoring.

For the experimental route/stage wrapper:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/sundered_keep_approach_route_smoke.gd
godot --headless --path . --script res://tools/validation/sundered_keep_approach_route_visual_smoke.gd
```

```bash
cd custodian
godot --headless --script tools/validation/sundered_keep_asset_smoke.gd
```

This instantiates the authored Sundered Keep connected map and fails if any `Sprite2D` in the slice has a missing texture.

For the walkable Sundered Keep underlay-only gameplay debug scene:

```bash
cd custodian
godot --headless --script tools/validation/sundered_keep_underlay_gameplay_debug_smoke.gd
godot --headless --script tools/validation/sundered_keep_underlay_collision_mapper_smoke.gd
```

This loads `res://scenes/debug/sundered_keep_production_underlay_debug.tscn`, verifies the scene uses only the active main underlay texture without instantiating `SunderedKeepMap` or authored tile sprites, confirms the real Operator/controller/projectile/camera runtime shell, checks gameplay camera zoom/bounds rather than authoring-review zoom, and validates the companion collision mapper that applies world-space `UNDERLAY_BOUNDARY_SEGMENTS`.

For the Sundered Keep overlay-authoring guide pipeline:

```bash
python custodian/tools/levels/generate_sundered_keep_overlay_authoring.py
cd custodian
godot --headless --script tools/validation/sundered_keep_overlay_authoring_smoke.gd
```

This regenerates the deterministic tile-space guide from the master overlay and verifies the standalone review scene plus the live map linkage still load cleanly.

For fabrication terminal readability / work-order translation changes:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/terminal_stylebox_rendering_smoke.gd
godot --headless --path . --script res://tools/validation/terminal_typography_smoke.gd
godot --headless --path . --script res://tools/validation/fabrication_terminal_layout_smoke.gd
godot --headless --script tools/validation/fabrication_terminal_readability_smoke.gd
godot --headless --script tools/validation/fabrication_terminal_command_smoke.gd
godot --headless --path . --script res://tools/validation/fabrication_terminal_clickable_smoke.gd
```

This validates crisp terminal `StyleBoxTexture` rendering with border-only tile-fit frames and stretched single-center controls, the shipped display/mono font hierarchy and disciplined sizes, flat Fabrication row labels, selected-row/detail synchronization, structured resource rows, collapsed empty build status, fixed-width/no-page-scroll FABRICATION layout, the scrollable page rail, the live terminal translation layer, readable next-action text, the `BUILD PLACE <ready_build_id>` placement alias against runtime autoloads, and the dedicated clickable `FabricationWidgets` page in the main scene.

For command-terminal Overview hierarchy, header/nav fit, or modal containment changes:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/terminal_overview_layout_smoke.gd
godot --headless --path . --script res://tools/validation/terminal_overlay_visibility_smoke.gd
godot --headless --path . --script res://tools/validation/terminal_typography_smoke.gd
godot --headless --path . --script res://tools/validation/terminal_stylebox_rendering_smoke.gd
godot --headless --path . --script res://tools/validation/fabrication_terminal_layout_smoke.gd
```

This validates the 1366×768 safe Overview composition, container-based status chips, collapsed secondary nav and reduced default actions, dominant shared tactical map, all diagnosis cards, actionable attention feed, command/transcript containment, visible-pointer modal behavior, a real GUI-routed page-button click through the full-viewport input-blocking scrim, gameplay-overlay suppression/restoration, typography, terminal skin rendering, and Fabrication layout compatibility.

For Field Patch healing or restock changes:

```bash
cd custodian
godot --headless --script tools/validation/field_patch_smoke.gd
```

This validates input binding, timed commit healing, interruption semantics, capped restock helpers, terminal fabrication restock, cap-blocked no-spend behavior, and emergency-cache fallback materials.

For the native Godot lighting layer:

```bash
cd custodian
env HOME=/tmp/custodian-godot-home \
  godot --headless --path . \
  --script res://tools/validation/lighting_system_smoke.gd

env HOME=/tmp/custodian-godot-home \
  godot --headless --path . \
  --script res://tools/validation/world_atmosphere_smoke.gd
```

The first command instantiates the standalone lighting playground plus the shadowed gatehouse reference room and checks
the `WorldLightingDirector`, `CanvasModulate`, `DirectionalLight2D`, authored light cookies, shadow/height/asymmetric
rig settings, darker `LightingZone2D`, major-geometry `LightOccluder2D` polygons, animated dust, and transient additive
flash pool. The second command checks live `game.tscn` lighting/profile/atmosphere wiring, UI layer separation, runtime
fog/cosmic propagation, the combined foliage wind/occlusion shader contract, and representative persistent light rigs.

For the Dear ImGui Director Console dev-tooling layer:

```bash
cd custodian
godot --headless --script res://tools/validation/director_console_imgui_smoke.gd
```

This validates the `/root/ImGui` plugin autoload, the F3 debug bus autoload, the read-only snapshot collector autoload, and the Director Console front-end wiring without requiring a rendered editor window.

For TerrainBuilder/procgen connectivity changes:

```bash
cd custodian
godot --headless --script res://tools/validation/terrain_builder_smoke.gd
godot --headless --script res://tools/validation/terrain_ballistics_smoke.gd
godot --headless --script res://tools/validation/procgen_terrain_required_cells_smoke.gd
godot --headless --path . --script res://tools/validation/terrain_gameplay_art_usage_smoke.gd
godot --headless --path . --script res://tools/validation/floor_value_clusters_smoke.gd
godot --headless --path . --script res://tools/validation/procgen_combat_readability_smoke.gd
```

The first command validates TerrainBuilder determinism and metadata behavior. The second validates deterministic projectile
tile tracing, directional ledge fire, hard wall/drop blocking, ramp/stair exceptions, generated edge profiles, and preserved
movement blocking. The third generates representative candidate-mode maps and verifies required-cell counts stay bounded
while terrain connectivity remains enforced. The fourth validates all gameplay-pack runtime source mappings, representative
TileMap paint paths, stable legacy mappings, and source-usage diagnostics. The fifth proves tile-value cluster determinism,
different-seed variation, semantic skips, metadata preservation, and safe missing-variant behavior. The sixth validates
combat/readability floor reporting, floor-cluster skips, and the combat foliage occlusion profile. These smokes are part of
the default procgen suite.
For production-sized contract rescue diagnostics, use the slow suite mode from the repository root:

```bash
RUN_SLOW_PROCGEN=1 bash custodian/tools/validation/run_procgen_validation_suite.sh
```

This includes `procgen_contract_rescue_diagnostic_smoke.gd`, which generates fixed production-sized candidate attempts
at `176x176`, `208x224`, and `224x224`, prints required-cell source/reason classification, compares layout walkability,
TerrainBuilder baseline floor/wall walkability, and semantic required walkability, reports component/bridge diagnostics,
and fails if baseline rescue, pre-terrain required connectivity, candidate acceptance, or forced failure-safe emission
regresses. The expected production rescue baseline is no TerrainBuilder baseline rescue for the selected seeds; authority
repair should happen through `game/world/procgen/diagnostics/` before TerrainBuilder receives the floor/wall graph, with
`ProcGenTilemap` acting as the context/state façade.

For a batch run that captures per-step exit codes while teeing a timestamped log, use:

```bash
custodian/tools/validation/run_procgen_validation_suite.sh
```

This wrapper fails the shell command if any included smoke fails, so assertion or script failures are not hidden by log piping.
Pass `--full` or set `RUN_SLOW_PROCGEN=1` to include the production contract rescue diagnostic; the default suite skips it
to stay quick.

For foliage extraction / deferred spawn changes:

```bash
cd custodian
godot --headless --script res://tools/validation/procgen_foliage_spawner_smoke.gd
godot --headless --script res://tools/validation/procgen_deferred_foliage_smoke.gd
godot --headless --path . --script res://tools/validation/procgen_combat_readability_smoke.gd
godot --headless --path . --script res://tools/validation/prop_collision_alignment_smoke.gd
godot --headless --path . --script res://tools/validation/procgen_stuck_pocket_smoke.gd
```

The first command validates the extracted foliage service's deterministic generate/remove/clear lifecycle. The second
checks that final-visual foliage queues batch into placed nodes over subsequent frames. The third validates combat-aware
canopy occlusion profile switching and readability clearance hooks. The fourth audits every ruin prop definition against
the bottom-contact collision contract and verifies per-instance collision debug. The fifth proves collision-owner blocker
lifecycle, definition-footprint rejection before instantiation, existing-blocker rejection, corrected global
prop-footprint registration, local escape detection/remediation, and required-route clearance without relying on a full
contract generation. Run `procgen_authored_scene_authority_smoke.gd` after placement-policy changes to confirm a full
seed produces no protected-zone backup warnings after portal routes are finalized.

## Manual Godot Validation

Use when behavior requires play, input, camera, animation, UI, collision, or visual confirmation.

```bash
cd custodian
godot
```

Check the specific acceptance path from the task packet when one exists; otherwise use the active spec and task request. For runtime gameplay changes, include deterministic concerns in the result notes: fixed-step simulation ownership, input mapping, and whether UI/rendering stayed out of simulation authority.

## Sprite Pipeline Validation

Use for sprite intake, runtime animation slices, and curated operator resources.

Read first:

- `custodian/content/sprites/_pipeline/README.md`
- `custodian/docs/SPRITE_PIPELINE_CHEATSHEET.md`
- `custodian/docs/ASSET_LAYOUT_CONVENTION.md`

Typical dry-run shape:

```bash
cd custodian
python tools/pipelines/ingest.py --dry-run <manifest_or_source>
```

Only run non-dry-run ingest when generated files are intended. Ingest writes and archives files but does not stage or commit them; inspect `git status --short` afterward.

For a mixed canonical inbox batch (including enemy, curated Operator, cape, and ranged-weapon modular sheets), generate manifests and ingest through the combined entrypoint so every declared post-process runs:

```bash
python custodian/tools/pipelines/generate_inbox_manifests.py --dry-run --remove-superseded
python custodian/tools/pipelines/generate_inbox_manifests.py --remove-superseded
```

For the current roll-exit/parry/execution/relaxed-carbine batch, follow the applied ingest with `operator_modular_fast_attack_smoke.gd`, `operator_modular_defense_ranged_smoke.gd`, `operator_primary_ranged_modular_fire_smoke.gd`, and `grunt_parry_crit_reaction_smoke.gd`.

For modular Operator naming/routing and generic action module generation:

```bash
python custodian/tools/validation/operator_modular_pipeline_smoke.py
```

For modular Operator contract coverage, suspicious filename/frame metadata, and next-batch reporting:

```bash
python custodian/tools/validation/operator_animation_contract_report.py
python custodian/tools/validation/operator_animation_contract_report.py --strict
python custodian/tools/validation/operator_animation_contract_report_smoke.py
```

`--strict` is expected to fail while required art coverage or required metadata is incomplete. Treat that as a
production coverage report, not as a reason to fake missing assets.

For live modular Operator defense/ranged presentation wiring:

```bash
cd custodian
godot --headless --script res://tools/validation/operator_modular_defense_ranged_smoke.gd
```

This instantiates the Operator and verifies east-facing parry recovery resolves to modular lower/upper recovery
clips, and east two-handed ranged-ready stance uses the modular upper/weapon stack instead of falling through to
legacy full-body presentation.

For live modular Operator fast-attack playback wiring:

```bash
cd custodian
godot --headless --script res://tools/validation/operator_modular_fast_attack_smoke.gd
```

This checks existing fast-attack source/runtime PNG coverage against the lower-body, upper-body, and upper-FX
`SpriteFrames` resources, then instantiates the Operator and verifies windup, strike, and recovery helpers play the
modular layers for every direction where body coverage exists while preserving legacy fallback/timing ownership. It
also proves that fast primary can buffer during active dodge without cancelling iframes, consumes at roll exit,
preserves dodge cooldown, skips the ordinary unarmed windup, and selects the ingested combined body/FX/cape
presentation when those runtime sheets are present.

For the active Savage first runtime slice:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/savage_runtime_smoke.gd
```

This validates mixed frame-size idle strips, direction fallbacks, scene activation, and factory/wave/main-scene wiring.

For the Savage rushdown gameplay contract:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/enemy_savage_smoke.gd
```

This validates the approved stats and `raider_savage` profile, no-theft behavior, chain/pounce activation, both chain
hits, the stronger second-hit guard cost, and the pounce hit contract.

For the focused modular Operator ingest loop, use the thin repo-root wrapper. It defaults to dry-run; `--apply` runs
shared-inbox manifest generation, rebuilds modular Operator runtime sheets, runs Godot import, refreshes curated
SpriteFrames, runs the modular layer smoke, and writes an animation contract JSON report.

```bash
tools/operator_ingest.sh --dry-run
tools/operator_ingest.sh --apply
```

After sourcing `tools/custodian_aliases.sh`, the same focused wrapper is available as
`opingest --dry-run` or `opingest --apply`. For a generic inbox ingest that must also rebuild already-authored
Operator modular source, use:

```bash
python custodian/tools/pipelines/ingest.py --build-operator-runtime --remove-superseded
```

`--build-operator-runtime` runs only after successful ingest and also respects `--dry-run`.

For modular Operator action QA previews:

```bash
python custodian/tools/pipelines/operator_action_preview.py --loadout unarmed --action block_loop_01 --directions e,w --include-fx
python custodian/tools/pipelines/operator_action_preview.py --loadout unarmed --sequence fast_windup_01,fast_strike_01,fast_recovery_01 --include-fx
python custodian/tools/validation/operator_action_preview_smoke.py
```

Preview output under `custodian/animation_review/` is review-only and should not become runtime authority.

For new modular-compatible character production planning:

```bash
python custodian/tools/pipelines/scaffold_character_contract.py --owner enemy_ritualist --template humanoid_combat --frame-size 96 --directions s,se,e,ne,n,nw,w,sw
python custodian/tools/validation/scaffold_character_contract_smoke.py
```

For modular Operator asset inventory and visual review tool selection, read:

- `custodian/docs/ai_context/AGENT_TOOLING_BY_ASK.md`

For opt-in superseded-animation cleanup:

```bash
python custodian/tools/validation/sprite_superseded_cleanup_smoke.py
python custodian/tools/pipelines/generate_inbox_manifests.py --dry-run --remove-superseded
```

## Runtime-Ready Asset Drop Validation

Use for already-runtime-ready assets that do not require specialized sprite processing:

```bash
python custodian/tools/pipelines/runtime_ready_assets.py --dry-run
python custodian/tools/validation/runtime_ready_asset_pipeline_smoke.py
python custodian/tools/pipelines/runtime_ready_assets.py --apply --godot-import
```

The apply command rejects different existing targets unless `--replace` is intentionally supplied.

## Tile Pipeline Validation

Use for wall tile extraction, composition, and procgen wall atlas bridge work.

```bash
python3 -m py_compile tools/tiles/extract_wall_parts.py tools/tiles/compose_wall_variants.py tools/tiles/build_procgen_wall_atlas.py
```

Then run the specific generator command documented in the relevant design or README file.

## Terrain Gameplay Pack Pipeline Validation

Use for terrain gameplay pack ingest, TileSet registration, and pack integrity checks.

```bash
# Ingest all three packs (connector, ascent, chasm+bridge) from source sheets
python custodian/tools/tiles/ingest_generated_terrain_packs.py

# Register runtime PNGs into procgen_world_tileset.tres
python custodian/tools/tiles/register_terrain_gameplay_packs.py --dry-run

# Validate packs, registration report, and active TileSet atlas-source resolution
cd custodian
godot --headless --script res://tools/validation/terrain_gameplay_packs_smoke.gd
godot --headless --path . --script res://tools/validation/terrain_gameplay_art_usage_smoke.gd
```

Validates:
- All runtime PNGs exist in `runtime/{connector,ascent,chasm_bridge}/`
- All PNGs are 32×32 RGBA with valid alpha
- Manifests reference every runtime file
- Symbolic IDs in `terrain_tile_ids.gd` match runtime filenames
- Non-walkable tiles (chasm void/edge/corner, broken gap) resolve correctly
- `procgen_world_tileset.tres` loads and resolves every registered connector/ascent/chasm_bridge runtime PNG as a TileSetAtlasSource
- `ProcGenTilemap.TERRAIN_TILESET_SOURCES` resolves all 62 gameplay-pack IDs and representative tiles paint the expected floor/wall source
- Expected atlas source ID ranges exist: connector `60..77`, ascent `80..99`, chasm_bridge `100..123`
- Each registered source uses `32x32` texture regions and contains atlas coord `(0, 0)`
- `reports/terrain_pack_ingest/terrain_gameplay_tileset_sources.json` has expected counts and no duplicate source IDs
- No checkerboard artifacts in runtime images

Ingest reports are written to `reports/terrain_pack_ingest/terrain_pack_ingest_report.md`.
TileSet source maps are written to `reports/terrain_pack_ingest/terrain_gameplay_tileset_sources.json`.
Direction/corner review notes belong in `reports/terrain_pack_ingest/terrain_direction_review.md`.

Current terrain gameplay pack status:

- Connector, Ascent, and Chasm+Bridge are registered as TileSet atlas sources, not as Godot TileSet terrain/autotile terrain sets.
- Connector centerlines and authority-repair/rescue floors use deterministic Connector visuals; existing industrial/compound ramps use directional Ascent wide-ramp visuals.
- Existing chasm/drop visuals may resolve to Chasm Pack void/gap art without changing drop semantics. New chasm topology, directional stair selection without direction metadata, and bridge placement remain deferred.

The smoke test runs in the default procgen validation suite:
```bash
custodian/tools/validation/run_procgen_validation_suite.sh
```

The slow production rescue diagnostic remains opt-in:

```bash
RUN_SLOW_PROCGEN=1 custodian/tools/validation/run_procgen_validation_suite.sh
custodian/tools/validation/run_procgen_validation_suite.sh --full
```

## Fabrication Balance Pipeline Validation

Use for the offline fabrication/resource economy simulator and proposal generator.

```bash
python -m py_compile custodian/tools/balance/fabrication_balance_pipeline.py
python custodian/tools/balance/fabrication_balance_pipeline.py --seeds 100
```

Check:

- `reports/fabrication_balance/fabrication_balance_report.md` exists and lists affordability, optimality, bottlenecks, and lore-drop review.
- `reports/fabrication_balance/proposed_changes.json` is proposal-only JSON and does not imply runtime data was applied.
- Lore violations are understood before using `--strict-lore` in automated checks.

## Review Validation

Use for code review, docs drift review, or handoff review.

```bash
rtk git status
rtk git diff
rtk grep "changed_symbol_or_path" custodian design
```

Findings should prioritize:

- behavior regressions
- determinism risks
- simulation/UI authority leaks
- stale paths or docs drift
- missing validation
- unsafe staging or commit assumptions

## When Validation Is Deferred

If a feasible validation step cannot run, record it in the task packet completion notes when a packet exists, or in the final handoff otherwise:

- command that was skipped or failed
- reason
- risk left behind
- exact next validation command
