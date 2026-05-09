# Agent Task Packets

Last updated: 2026-05-08

Task packets are short, task-scoped planning and handoff files for CUSTODIAN agents.

Use a packet when work affects runtime behavior, architecture, validation workflow, asset workflow, documentation routing, or more than one file. For a trivial one-line edit, a packet is optional unless the user asks for one.

## Workflow

1. Copy `../AGENT_TASK_PACKET_TEMPLATE.md` into this folder.
2. Rename it after the task in uppercase snake case, for example `VALIDATION_RECIPES.md`.
3. Fill the task, outcome, authority, work surface, constraints, plan, and acceptance sections before implementation starts.
4. Keep the packet current if scope, blockers, validation, next steps, or documentation requirements change.
5. Before handoff, blocked status, or completion, update `Next Steps` with the next action, best starting files, required context, validation to run, and blockers/open questions.
6. Mark it `complete` only after implementation, docs updates, feasible validation, completion notes, and next-step notes are done.

## Ownership

- Reuse a packet only when it is scoped to the current task.
- Create a new packet for a different task, even if related files overlap.
- Do not update another agent's in-progress packet unless the user asks or that packet is explicitly the active task surface.
- Set `Agent/session` in new packets with a stable handle, such as `Codex 2026-05-03T11:xx`.
- Update `Last updated` whenever a packet changes.

## Current Packets

- `AGENT_WORKFLOW_AUTOMATION.md` - completed packet for task-packet next steps, ownership rules, and automation backlog.
- `ATTACK_PRIMARY_SECONDARY_INPUT_FIX.md` - completed packet for fixing plain M1 fast attack versus Shift+M1 heavy attack input routing.
- `VALIDATION_RECIPES.md` - completed implementation packet for canonical validation recipes and prompt-template cleanup.
- `COGNITIVE_STATE_PHASE_B.md` - in-progress runtime packet for cognitive modifier integration and debug panel validation.
- `COMBAT_MOVING_ATTACK_PROFILES.md` - completed packet for phase-based operator attack movement profiles.
- `ENEMY_VARIANT_SYSTEM.md` - completed packet for the first procedural wolf enemy variant runtime slice.
- `ENEMY_ANIMATION_STABILITY_AND_PIPELINE.md` - completed packet for Shrumb flee animation stabilization, wolf directional row selection, and the first enemy animation intake pipeline hook.
- `ENEMY_WALL_REROUTE_RECOVERY.md` - completed packet for enemy and passive critter wall-stuck recovery.
- `FAB_PIPELINE_V1.md` - completed packet for the first build-token-first resource/fabrication runtime spine.
- `INDOOR_OUTDOOR_PROCGEN_REGIONS.md` - completed runtime packet for the first region-aware indoor/outdoor procgen slice.
- `INTERIOR_TILE_ART_WIRING.md` - completed packet for organizing interior tile art and wiring constructed procgen regions to the new tile family.
- `KNIGHT_OPERATOR_TEST_SKIN.md` - completed packet for the DevConsole-toggleable Knight operator test skin.
- `MINIMAP_SYSTEM.md` - completed packet for replacing the addon minimap with a custom data-driven tactical HUD minimap.
- `MINIMAP_PASSIVE_CREATURE_ICONS.md` - completed packet for splitting hostile red dots from passive creature minimap markers.
- `MINIMAP_EXPAND_AND_UTILITY_MARKERS.md` - completed packet for expanding the HUD minimap with `M` and adding terminal, vehicle, and turret markers.
- `MOB_FOLIAGE_OCCLUSION.md` - completed packet for extending procgen foliage fade bubbles to nearby enemy, Shrumb, and mob-group actors.
- `OPERATOR_FAST_MOVING_ATTACK_INGEST.md` - completed packet for ingesting the latest operator fast moving attack body/weapon/FX sheets.
- `PLACEHOLDER_TILESET_SOURCE_RELOCATION.md` - completed packet for moving the old placeholder tileset into `content/tiles/source` and restoring world TileSet loading.
- `PRIMARY_SECONDARY_ATTACK_MODEL.md` - completed packet for aligning unarmed/melee/ranged attack modes to primary/secondary intent routing.
- `PROCGEN_WALL_PASSAGE_VISIBILITY.md` - completed packet for making generated passage wall tiles visible on normal procgen wall runs.
- `PROCGEN_WALL_COLLISION_SYNC.md` - completed packet for keeping visible procgen wall cells synchronized with runtime wall bodies during streaming reveal.
- `PROCGEN_PROP_STREAMING_VISIBILITY.md` - completed packet for preserving outdoor ruin and interior runtime props through streaming reveal setup.
- `PROCGEN_PORTAL_PAIR_TELEPORT.md` - completed packet for paired portal-ring teleport behavior in procgen maps.
- `PROCGEN_PORTAL_SAFE_PLACEMENT.md` - completed packet for adding portal-specific safe placement, unsafe portal replacement, and jitter-free portal endpoint positioning.
- `PORTAL_CENTER_TRIGGER_AND_ANIMATION.md` - completed packet for tightening portal activation to the center and defining portal animation asset needs.
- `PORTAL_AND_MOVING_ATTACK_SPRITE_INGEST.md` - completed packet for ingesting portal teleport FX and moving attack layer sheets.
- `PORTAL_FX_PLAYBACK_WIRING.md` - completed packet for wiring portal idle, activation, and arrival FX playback.
- `PROCGEN_WALL_TOP_SOURCE_PREPROCESSING.md` - completed packet for adding `--top-source` preprocessing support to the wall atlas builder.
- `RANGED_PHYSICS_ALIGNMENT.md` - completed packet for ranged muzzle obstruction, swept projectile movement, and temporary stance-band socket rotation clamps.
- `SHRUMB_LOCAL_WANDER_HOME.md` - completed packet for anchoring passive Shrumb wander to their generated spawn position.
- `TERMINAL_LIVE_MINIMAP.md` - completed packet for replacing the terminal placeholder tactical map with the shared live custom minimap.
- `TILESET_RENAME_ALIGNMENT.md` - completed packet for renaming the canonical world/procgen TileSet to `custodian_world_tileset.tres`.
- `UI_MINIMAP_INVENTORY_VERIFY.md` - completed packet for keeping the custom minimap visible in the normal HUD and mounting the inventory overlay on `I`.
