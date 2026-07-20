# PROJECT CONTEXT PRIMER — CUSTODIAN

Last updated: 2026-07-20

## Purpose

Operational handoff summary for active Godot implementation work.
Use this directory as the current AI-facing context pack, not `python-sim/ai/`.
Use `custodian/AGENTS.md` as the first local stop before using this pack.

## One-Paragraph Summary

CUSTODIAN is a Godot-native tactical base-defense game with an embodied operator, deterministic runtime simulation, contract-driven deployment, and an in-world command terminal. The active game lives in `custodian/`, the active implementation specs live in `design/`, and the old Python simulation/terminal stack remains preserved only as migration and design history.

## Current Lore Canon

The Great Severance is no longer framed as a collapse caused by lost shared context. The internal root cause is The Unarrival: a supernatural/cosmic provenance wound that damaged reality's ability to maintain shared cause, memory, witness, and origin. Shared-context collapse, contradictory archives, and fragmented histories are symptoms. Knowledge recovery should be treated as provenance stabilization across object, origin, witness, time, use, and meaning.

## Canonical Runtime Facts

- Engine: Godot 4.x
- Main scene: `res://scenes/game.tscn`
- Beginning/Home scene: `res://scenes/home_custodian_begin.tscn` implements Objective 01, tracing the Custodian-band frequency to a damaged Field Terminal and establishing witness contact; it is a dedicated scene and not yet the application main scene.
- Runtime authority: Godot only
- Active command shell: HUD terminal in `custodian/game/ui/hud/ui.gd`, with terminal helper modules under `custodian/game/ui/terminal/`
- Current gameplay HUD style: compact Black Reliquary gothic/brass UI. Assets live in `custodian/content/ui/black_reliquary/`; reusable theme/components/HUD scenes live under `custodian/game/ui/`. Prompt text must be real Godot labels, not baked into images, the minimap frame should embed the shared live tactical minimap renderer rather than static marker art, authored-map-specific HUD content must only show inside its owning map, debug diagnostics should live in the dedicated F12/`debug_hud` debug screen instead of normal HUD labels, and terminal focus must mask gameplay overlays without re-showing inactive map-local HUDs.
- Command-terminal typography is a shipped two-font system: IBM Plex Sans Condensed owns display hierarchy, IBM Plex Mono owns data/input hierarchy, and the vendored TTF/OFL files live under `content/ui/fonts/`. Theme/page switches must preserve semantic fonts and sizes; bounded text ellipsizes instead of enabling horizontal scroll.
- Contract/runtime coupling: contract planet generation feeds procgen world generation through a shared world profile. `CustodianContractMap` owns candidate map generation: it disables child `ProcGen` ready-time auto-generation before tree entry, evaluates candidates without cosmetic prop/nav passes, then regenerates the selected map once in full visual mode.
- Input prompts: interaction UI should derive from `InputMap`, not hardcoded keys
- Operator combat selection: Fists/unarmed is a first-class `OperatorWeaponDefinition` profile selected with `toggle_unarmed`; normal weapon cycling excludes Fists and only cycles armed profiles. The offhand secondary button (`aim_hold` / `attack_secondary`, right mouse or LT) contextually selects primary ranged-ready, equipped sidearm-ready, or tap parry / held guard. Two-handed raise/lower clips may retarget without restarting, use separate 0.22s/0.12s targets and a 0.70 ready threshold, and shots commit direction through recoil. The read-only procedural reticle reflects exposed aim accuracy/fire readiness. `Shift+primary` remains the melee/unarmed heavy chord; movement supports WASD/left stick, mouse/right-stick aim, and movement-first dodge with idle aiming backstep. The Carbine phase-1 hybrid contract in `design/02_features/operator_modular_weapon/HYBRID_WEAPON_SOCKET_SYSTEM.md` uses generated `e/w/se/sw` frame sockets for placement, muzzle/ejection, and draw order while existing modular weapon strips remain compatibility art. Camera aim zoom/lead is camera-controller presentation state and must remain additive with shake/bounds rather than becoming Operator-owned final framing.
- Parry-critical ownership is split across standalone vulnerability and paired execution contracts: the grunt owns enter/hold/recover at its independent post-knockback world root and suppresses normal targeting through recovery. Atomic reservation begins the separate shared-root execution; the Operator then owns alignment, the shared nonuniform eight-frame body/FX/victim timeline, source-frame-5 damage, the 110ms paired contact freeze, impact feedback, final settle, and unified cleanup. Matched S/E/W exports use grunt `melee__` names and a zero Operator offset because all paired full-cell exports preserve one canvas origin; vertical approaches use south until north art exists.
- Ranged balance authority: typed reserve caps, persistent weapon magazines, projectile falloff/range, weapon heat, positional gunshot noise, enemy search/leash behavior, and ambient hostile camps are defined by `design/02_features/combat_feel/RANGED_COMBAT_BALANCE_AND_STEALTH_SYSTEM.md`. `NoiseEventBus` is the shared autoload boundary for gunfire and future explosion/door/vehicle noise; emitters must not call enemy scripts directly.
- Combat resource/readability integration authority: `design/02_features/combat_feel/COMBAT_RESOURCE_AND_READABILITY_SYSTEM.md` tracks cross-system current state and remaining milestones. Completed V1 behavior stays authoritative in its permanent feature spec and Godot runtime home; the umbrella must link rather than restate ownership. Its current order is combat-pressure feedback, Field Patch healing, hit taxonomy/full riposte, durability, then traps and drone logistics.
- Forest Shrumb cognitive drops now have a v1 foundation through `InventoryManager`, `CognitiveState`, `cognitive_pickup`, `shrumb_dropper`, and the live `ambient_shrumb.tscn` actor. Ambient spawning now uses this shrumb actor directly; the former scav droid scene path is removed.
- Procedural ruin prop variants have a v1 visual-only foundation under `custodian/content/props/ruins/`, using seeded layer assembly from authored sprites, overlays, rubble pieces, and a conservative palette shader. Collision remains authored and stable through `PropDefinition.collision_scene`.
- Procgen terrain construction now has a dedicated metadata-first `TerrainBuilder` pass under `game/world/procgen/terrain/`; elevation/cliff visuals remain separate from `ElevationMap` height/traversal rules and resolve through registered terrain sources in `procgen_world_tileset.tres`.
- Procgen world progression now has a route-first Intent Graph / Ascent V1 layer. `ProcGenTilemap.world_shape_mode` defaults to `ASCENT_FIELD`, which does not use the old BSP/corridor/cellular cave mask as the base world substrate. It builds a deterministic ascent spine, broad exterior route, terraces, branch pockets, sparse cliff/ruin blockers, and story/faction reservations from the world profile, then exports the graph/summary/reserved regions in level data. `LEGACY_CAVE` keeps the old generator path available. TerrainBuilder consumes intent required cells and reserved regions for guarded height/traversal metadata. Elevation traversal query API is live; actor/enemy pathfinding enforcement is deferred.
- Sundered Keep is the first registered authored destination under `game/world/sundered_keep/`. Production main-map placement is registry-driven through `WorldIngressSpawner`; its definition declares the named `EntrySpawn`, while the special procgen ingress → Vista Approach → optional Return Causeway → 112×80 front-gate chain remains approach-owned. `LevelLoader` keeps one authored branch active and named-spawn failure is authoritative. The front-gate map is built from `content/levels/sundered_keep/sundered_keep_front_gate_large.json`; interaction state remains in `sundered_keep_map.gd`, including Return Mooring, key/gate, Great Hall, and minimap authority. `ContractWorldLoader`'s old Sundered placement helper remains compatibility/debug-only.
- Enemy marine dash is now a documented heavy commitment attack, not just forced sprite playback: windup/telegraph locks direction, dash travel owns the only active hit window, impact/recovery enforce a punish window, and feel comes from hitstop, knockback, camera shake, and Operator impact-lock feedback. Current runtime uses the east body/FX strip as fallback while directional dash body/FX sheets and the dash audio stack are tracked in `REQUIRED_ASSETS.md`.
- Enemy Savage is a low-discipline rushdown role, not a stronger grunt. `enemy_savage.tscn` uses the no-theft `raider_savage` profile, low durability/poise thresholds, a two-hit guard-pressure chain, and a distinct interruptible pounce with locked travel and punishable recovery. `enemy.gd` owns its fixed-step combat timing; current directional idle art remains presentation fallback until dedicated action sheets arrive.

## Active Architecture Snapshot

- Contract layer: contract map generation plus promoted runtime metadata
- World layer: procgen tilemap/runtime world systems
- Simulation layer: deterministic Godot runtime systems
- Cognitive layer: autoloaded inventory ledger and cognitive state values expose drop/combat modifier getters, with only pickup/drop feedback wired in v1
- UI layer: HUD + command terminal pages/widgets; terminal command parsing, authoritative snapshot projection, fidelity policy, canonical STATUS formatting, ranked Overview diagnosis, map preview, and planet preview helpers live under `game/ui/terminal/`. Physics-frame time and simulation state remain upstream truth; terminal modules only project read-only information.
- Black Reliquary UI layer: `game/ui/theme/` centralizes palette/styles/assets, `game/ui/components/` owns reusable compact panels/prompts/minimap/icon labels, and `game/ui/hud/custodian_hud.tscn` is the first local gameplay HUD shell used by Sundered Keep and Home. The Black Reliquary minimap component wraps `game/ui/minimap/minimap_panel.tscn` so it stays live while using gothic/brass chrome.
- Debug UI layer: `game/ui/hud/debug_screen.tscn` owns F12/`debug_hud` diagnostics as a read-only tabbed overlay fed by `game/ui/hud/ui.gd`. Dear ImGui is approved only for developer tooling through the F3 CUSTODIAN Director Console (`debug/debug_bus.gd`, `debug/debug_snapshot_collector.gd`, `debug/debug_imgui_console.gd`); player HUD, terminal, inventory, dialogue, and pause surfaces stay Godot `Control` UI.
- Debug data flow: gameplay systems expose read-only snapshots or group membership, `DebugSnapshotCollector` copies them after normal runtime updates, `DebugBus` stores bounded stats/events/overrides/commands, and ImGui reads the bus. Dev mutations must use `DebugBus.queue_command(...)` or debug overrides and be applied by runtime owners at safe boundaries.
- Terminal overlay policy: `game/ui/hud/ui.gd` owns terminal-open suppression for legacy HUD labels, minimap/crosshair, `gameplay_overlay` HUD scenes, and the debug screen; a full-viewport dark scrim blocks pointer input beneath the terminal while keeping the terminal panel above it. Context-aware overlays such as the Sundered Keep HUD preserve their map-local active state when terminal suppression is removed. OVERVIEW prioritizes compact diagnosis cards and the shared live tactical map; the planet globe remains contextual to STATUS/CONTRACTS/ARCHIVE.
- Home beginning layer: `game/world/home/` owns the first Field Terminal witness-contact slice, using the Road of Witnesses prototype map and Black Reliquary HUD as the current presentation shell.
- Actor layer: operator, enemies, structures, defenses, ambient entities
- Authored-level layer: `AuthoredLevel2D` owns production level content/lifecycle, generated playtest wrappers own temporary Operator/controller/camera nodes, registry definitions own ingress/spawn identity, and `WorldIngressSpawner` owns deterministic procgen placement. See `design/04_architecture/AUTHORED_LEVEL_AUTHORING_PIPELINE.md`.
- Enemy dash layer: `enemy_marine.tscn` enables the shared enemy phased dash values; `enemy.gd` owns the generic marine dash phases and impact feedback; `operator.gd` exposes `apply_enemy_dash_impact(...)`; Sundered Keep's local hallway ambush mirrors the same heavy dash tuning.
- Stealth/perception layer: Operator movement exposes a read-only stealth snapshot, discrete loud actions publish through `NoiseEventBus`, enemy perception owns LOS/hearing, and the existing enemy behavior state machine owns investigate/pursue/search/return-home transitions. UI remains a read-only consumer of weapon status.

## Architecture Organization Status

An explicit architecture organization pass is now documented and tracked.
- `custodian/docs/ARCHITECTURE.md` defines 9 runtime layers with ownership boundaries
- `custodian/docs/ai_context/ARCHITECTURE_OWNERSHIP_MAP.md` answers "who owns what" for every major runtime concern
- `custodian/docs/ai_context/task_packets/ARCHITECTURE_ORGANIZATION_PASS.md` defines 6 migration phases and extraction candidates
- Large files (`proc_gen_tilemap.gd`, `custodian_contract_map.gd`, `contract_world_loader.gd`, `enemy.gd`, `game_state.gd`) should be treated as coordinator/facade candidates rather than permanent dumping grounds
- No runtime code has been moved yet — the organization pass is currently documentation and scaffold only
- The `docs/ai_context/VALIDATION_RECIPES.md` now includes architecture documentation validation commands

## Working Rules

- Treat `custodian/` and `design/` as the active implementation surface.
- Put active feature specs under `design/02_features/`; `design/20_features/` is retired and must not receive new work.
- Treat root `REQUIRED_ASSETS.md` as the sole asset-tracker authority; the design-tree file is a deprecated pointer, not a synchronized copy.
- Start all local work by reading `custodian/AGENTS.md`, then this context pack.
- Use task packets as optional risk-control and handoff records: skip narrow low-risk work, use the compact template when durable scope or acceptance helps, and expand it only for high-risk or multi-session work.
- When a task packet exists, keep it current as scope, blockers, acceptance, or deferred work materially changes.
- Use `custodian/docs/ai_context/VALIDATION_RECIPES.md` for validation command selection.
- Use `custodian/docs/ai_context/prompts/` for reusable task prompts, and confirm prompt paths before acting.
- Keep deterministic simulation separate from rendering/UI logic.
- When runtime behavior changes materially, update this directory alongside the relevant design/runtime docs.
- Do not silently shift authority back to Python-era systems or docs.

## Immediate Priorities

### Tier 1 — High-impact gameplay gaps

1. **Hit taxonomy and riposte (Milestone C).** Normalize hit-strength metadata at the damage boundary, add differentiated enemy/Operator reactions with heavy-enemy resistance, add explicit guard-break presentation, and implement the enemy-opened state plus unique riposte action after successful parry. Players currently cannot distinguish hurt/deflect/stagger/parry-opened/guard-impact/guard-break; this is the most impactful remaining combat readability gap. See `design/02_features/combat_feel/COMBAT_RESOURCE_AND_READABILITY_SYSTEM.md` Milestone C and `PARRY_CRITICAL_BRANCHING_AND_VFX.md` for execution ownership.

2. **Enemy marine heavy dash art and audio.** Ingest or create the directional body sheets (minimum E/W/NE/NW/SE/SW), matching FX overlays, and five-part audio stack (windup, travel, impact, armor, recovery) tracked in `REQUIRED_ASSETS.md`. V1 gameplay is live with east-only fallback; production coverage is the single largest art gap blocking enemy combat readability.

3. **Melee profile consolidation.** Finish centralizing light/fast/heavy timing, active frames, recovery, range, arc, damage, knockback, hit-stop, camera impulse, and movement profile values into `MeleeAttackProfile` resources. The old operator melee exports remain deprecated fallbacks; completing this removes hidden per-weapon magic numbers and makes new enemy melee types cheaper to author.

### Tier 2 — World and systems depth

4. **Sundered Keep follow-up.** Encounter composition tuning, save/load persistence for gate/key state, and production labyrinth wall/void-edge/dressing art (currently `PLACEHOLDER_sundered_keep_labyrinth_*`). If the JSON-driven Sprite2D authored map becomes hard to maintain, begin the TileSet/TileMapLayer authoring migration documented in the level design spec.

5. **Home beginning scene transition decision.** Decide when `home_custodian_begin.tscn` becomes the boot/default entry, then wire it into the world-transition/campaign-flow spine without regressing the current contract/procgen sandbox. This is a content-flow milestone, not just an asset milestone — it requires the transition chain to handle first-run versus return.

6. **Terminal page extraction and richness.** Follow up on the decursification pass: extract remaining page renderers from `ui.gd` into dedicated scripts under `game/ui/terminal/`, deepen pages with richer live runtime data, and tighten layout polish. Terminal is the primary non-combat interaction surface and still has placeholder content on several pages.

7. **Elevation and terrain pathing enforcement.** The metadata-first TerrainBuilder and ElevationMap have traversal query APIs but do not yet enforce Operator, vehicle, or enemy path traversal. Wire enforcement for at least one enemy type and Operator movement so elevation has gameplay meaning beyond visuals and contract scoring.

### Tier 3 — Integration and polish

8. **Forest Shrumb cognitive surface.** Wire true Forest Shrumbs into the intended spawning/procgen path and decide which cognitive readout belongs in HUD versus debug. The v1 runtime foundation (InventoryManager, CognitiveState, cognitive_pickup, shrumb_dropper) is live but the player-facing feedback loop is still open.

9. **Ruin prop production assets.** Author additional `PropDefinition` resources, overlay/rubble artwork, and chip/dirt/vine/highlight overlays under `custodian/content/props/ruins/`. The procedural prop variant foundation and procgen placement are live; what's missing is enough authored art variety to make the system feel intentional rather than sparse.

10. **Architecture organization pass execution.** The 9-layer ownership model and extraction candidates are documented but no runtime code has been moved yet. Prioritize the largest coordinator/facade files (`proc_gen_tilemap.gd`, `custodian_contract_map.gd`, `contract_world_loader.gd`, `enemy.gd`, `game_state.gd`) when a natural feature boundary creates a safe extraction window — do not move code for its own sake.

### Cross-cutting

- **Keep Sundered Keep/Home prompts and normal-play status surfaces on the compact Black Reliquary HUD API.** Route diagnostics to the dedicated debug screen; do not reintroduce giant panels or debug labels during normal gameplay.
- **Preserve and extend planet-to-runtime world coupling** as procgen evolves. Contract planet data must keep driving world profile variation without silent coupling breaks.
- **Clean deprecated `attack_light` compatibility** remnants from animation-state documentation and any surviving asset references.

## Update Expectation

On significant architecture or behavior changes, update:

- `custodian/docs/ai_context/CURRENT_STATE.md`
- `custodian/docs/ai_context/CONTEXT.md`
- `custodian/docs/ai_context/FILE_INDEX.md`
- relevant files under `custodian/docs/ai_context/task_packets/`
- relevant files under `custodian/docs/ai_context/prompts/`
- `custodian/AGENTS.md` when local routing, migration flow, or operating rules change

Optionally also update legacy changelog/devlog material for historical continuity.
