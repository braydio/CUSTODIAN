# Architecture Organization Pass

Status: in progress

## Problem Statement

The runtime works, but several files have become ownership aggregates. Future work needs a clear spine for app boot, persistent state, campaign/run state, world lifecycle, world construction, simulation, actors, presentation, and developer tooling.

## Target Organization

Use `custodian/docs/ARCHITECTURE.md` as the detailed map and `custodian/docs/ai_context/ARCHITECTURE_OWNERSHIP_MAP.md` as the compact agent routing guide. Existing large files remain compatibility facades until extraction passes move logic safely.

## Non-Goals

- No runtime path moves in the scaffold pass.
- No scene, `.tscn`, `.tres`, resource UID, autoload, or content path rewrites.
- No gameplay behavior changes while creating docs/scaffold.
- No broad folder cleanup or legacy deletion.

## Migration Phases

1. Phase 0: architecture map, ownership map, task packet, scaffold READMEs, validation script.
2. Phase 1: add helper/service boundaries without moving existing scene/script paths.
3. Phase 2: extract stable services such as foliage, candidate metrics, road graph metrics, and placement resolvers.
4. Phase 3: move scenes/scripts only after facade delegation and reference scans pass.
5. Phase 4: install the world lifecycle/campaign spine.
6. Phase 5: archive stale docs after primary authorities and indexes are updated.

## Iteration 1

- Foliage generation extracted to `custodian/game/world/procgen/foliage/procgen_foliage_spawner.gd`.
- `ProcGenTilemap` remains the facade and host for world/procgen query Callables.
- Remaining follow-up: foliage occlusion runtime update can be extracted later only if it stays presentation-only and safe.

## Acceptance Criteria

- New architecture docs exist and are indexed.
- Architecture path drift under `design/04_architecture` is corrected.
- Scaffold folders exist with README files.
- Architecture ownership smoke passes.
- Foliage service smoke passes after iteration 1.
- No runtime scene/resource paths are moved.

## Validation Commands

```bash
python custodian/tools/validation/architecture_ownership_smoke.py
cd custodian
godot --headless --path . --script res://tools/validation/procgen_foliage_spawner_smoke.gd
```

## Docs Drift Checklist

- `CURRENT_STATE.md` describes active architecture organization and foliage ownership.
- `CONTEXT.md` warns that overburdened files are facade candidates.
- `FILE_INDEX.md` points to new docs, scaffold, service, and validation scripts.
- `VALIDATION_RECIPES.md` includes architecture and foliage validation.

## Rollback Plan

For docs/scaffold, remove the new docs and scaffold READMEs and restore corrected headers only if the physical `design/04_architecture` location changes back. For foliage extraction, revert `proc_gen_tilemap.gd`, remove `procgen_foliage_spawner.gd`, and remove the focused foliage smoke; no content or scene assets should need rollback.
