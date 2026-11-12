# Procgen Dressing Clusters V1 + Carrow Auto Travel Summary

## Starting state

- Packet expected `51c5ab8e15ee04f8992cca6fd7c9dbd058ae2372`; actual `origin/main` and isolated worktree start were `36bb17093942f65584c44f20a5a984d8e5fcc043`.
- Implemented in scoped branch `codex/procgen-dressing-clusters-carrow-auto`.

## Cluster composition

Added the data-only dressing cluster resources, catalog, planner, and realizer under `custodian/game/world/procgen/dressing/`, plus the catalog and three Rocky Upland proof profiles under `custodian/content/procgen/dressing_clusters/rocky_upland/`:

- `rocky_tree_scrub_small_01`
- `rocky_tree_scrub_large_01`
- `rocky_scrub_pocket_01`

The planner is deterministic and clearance-aware. Tilemap integration plans after macro presentation, retains child/suppression maps for streaming, and realizes children through the existing foliage spawner. Authored tree/shrub placement reuses foliage selection, tint, wind, occlusion, collision, fruit, and bookkeeping. Rocky Upland `natural_rock` residual foliage uses multiplier `0.62`; other biomes remain at `1.0`.

Fixed-seed review (`824790`) measured target 4 / placed 2 clusters / 9 children. Profiles: one scrub pocket and one small tree scrub. Baseline foliage was 9; composed scene foliage was 9 total, with 9 authored cluster children and 0 residual scatter. Route audit passed. Candidate evaluation had no realized foliage, and direct-final, candidate, and promotion fingerprints agreed. Captures:

- `reports/procgen_dressing_clusters/seed_824790_clusters_off.png`
- `reports/procgen_dressing_clusters/seed_824790_clusters_on.png`
- `reports/procgen_dressing_clusters/seed_824790_summary.json`

Visual review showed grouped foliage and macro cliffs retaining dominance. This is evidence for review, not automatic approval. Rock/boulder vocabulary remains deferred pending approved natural-rock assets.

## Carrow transfer frames

Added shared route activation and endpoint registration to `GothicCompoundMap`. First use remains explicit: the gate plays its existing six-frame, 9 FPS boot sequence, reaches ACTIVE, waits a rendered frame, applies the existing `portal_teleport_lock_until_frame` metadata for 24 physics frames, then travels. Once activated, registered endpoints become ACTIVE and player body entry triggers travel without interaction. Cooldown prevents immediate bounce; prompt/group behavior follows route state. Existing map travel authority and procgen portal behavior were left intact.

## Validation

Focused checks recorded green:

- `procgen_dressing_clusters`
- `procgen_macro_presentation`
- `procgen_combat_readability`
- `carrow_yard_interior`
- direct `procgen_foliage_spawner_smoke.gd`
- JSON parse of `validation_manifest.json`
- `git diff --check`

Changed validation initially ran 19/19 tests but failed coverage because the new review helper lacked an owner. Added the review helper to the dressing-cluster test ownership and reran: `--changed` passed 19/19, with zero failures, timeouts, skips, infrastructure errors, and uncovered files. The initial review harness failed to obtain its SubViewport texture in headless mode; the capture was rerun using the available Vulkan display backend. The focused foliage-spawner script has no manifest test ID, so it was run directly.

## Documentation and known visual debt

Updated the procgen macro phase ledger: Phase 2c dressing clusters is complete; Landmark Vocabulary V1 is next; other biome surface expansions and environment/weather finish remain deferred. Current state and file index now describe the cluster subsystem and Carrow route activation. Recorded the 2026-09-27 gameplay-zoom observation that two ruined-road areas read as dark isolated patches. Road generation/material semantics and the 15-piece renderer were not changed.

## Awkward implementation findings

- Actual starting main differed from the packet's recorded HEAD; current main was used.
- Initial planner iteration over-constrained children to anchor biome/material/band constraints and produced no viable plans; child validation was narrowed to the specified gameplay-safe floor/clearance requirements while anchors retain Rocky Upland/natural-rock/band requirements.
- Godot import scanning generated unrelated Operator `.import` and existing procgen `.uid` sidecars; they are left unstaged.

## Landing

Changed validation passed 19/19 after the coverage ownership fix. Commit, autonomous landing, and root-project synchronization are pending.
