# Runtime Stutter Performance Pass

- Status: `complete`
- Authority: `design/01_systems/INTEREST_MANAGEMENT_SYSTEM.md`, `design/02_features/debug_ui/DEVELOPER_OBSERVATORY_SYSTEM.md`, `design/02_features/visuals/WORLD_ATMOSPHERE_SHADER_SYSTEM.md`, `design/00_meta/PROCGEN_WALL_COLLISION_FIX.md`
- Goal: Remove periodic global scans and rebuild bursts, bound foliage and targeting work spatially, make distance tiers suppress dormant simulation, and compact runtime-wall bodies without making presentation or camera visibility gameplay authority.
- Files: Observatory, procgen streaming/foliage/walls, enemy interest tiers, camera threat framing, combat drones, atmosphere shader, focused smokes, and named authority/current-state docs.
- Constraints: Deterministic simulation ownership remains local; screen visibility may suppress presentation only; dormant reactivation remains manager-owned; destructible wall hits must resolve the contacted tile exactly; preserve unrelated worktree changes.
- Acceptance: Hidden Observatory performs no periodic tree scans and export forces one snapshot; enabled sampling performs one tree walk; reveal batches avoid per-tile debug/full rebuilds; foliage uses at most tree/shrub shared materials and local z inspections; tier classification runs at 5 Hz with dormant physics suppression; camera/drone scans are throttled; atmosphere skips disabled cosmic noise; wall compaction is enabled only with contacted-tile validation.
- Completed: Hidden Observatory sampling gate and consolidated tree walk; deferred streaming rebuilds; shared spatially bounded foliage work; dormant tier workload suppression; throttled interest/camera/drone scans; chunk wall bodies with exact contacted-tile destruction; reduced/short-circuited atmosphere FBM; focused validation and authority/current-state reconciliation.
- Deferred: Background-tier abstract ticking/hysteresis, merged rectangular wall shapes, release-export autoload stripping, camera-shake consolidation, behavior dictionary versioning, scrolling atmosphere noise texture, and frame cap/VSync policy.

## Ownership And Timing

- Owner: gameplay systems / procgen / world presentation / developer tooling
- Agent/session: Codex `/root`
- Created: 2026-07-19
- Last updated: 2026-07-19

## Work Surface

- Read: local primer, four primary design authorities, current state, file index, validation recipes, runtime feature prompt, adjacent runtime and focused smokes.
- Change: bounded performance corrections and observability proving their workload contracts.
- Out of scope: screen-visibility-driven gameplay culling, broad release-preset restructuring, speculative ballistics changes, and balance tuning.

## Plan

1. Gate and consolidate Observatory scans.
2. Defer streaming derived rebuilds and share foliage materials/localize z inspection.
3. Apply conservative tier workload semantics and target-scan throttles.
4. Add safe chunk wall bodies with exact impact-to-tile resolution if validation proves the contact contract.
5. Reduce atmosphere FBM work, update docs, and run focused/integrated smokes.

## Drift Review

- Primary authority: update all four named design docs to describe live budgets and ownership.
- `CURRENT_STATE.md`: record implemented performance contracts and any deferred wall mode.
- `CONTEXT.md`: update only if the cross-system ownership model changes beyond existing guidance.
- `FILE_INDEX.md`: add new wall runtime/validation entrypoints if created.
- Local routing/readmes: update foliage README if its material ownership changes.

## Handoff

- Next action: profile a live production-size regeneration/traversal session before choosing rectangle-shape merging or background abstract ticking as the next performance slice.
- Best starting files: `game/world/procgen/runtime_wall_chunk.gd`, `game/systems/simulation/simulation_interest_manager.gd`, and the Observatory export.
- Validation run: focused Observatory, foliage, telemetry, drone, procgen collision/authority, atmosphere, ballistics, and startup smokes listed in `VALIDATION_RECIPES.md`.
- Blockers or open questions: none for this slice; release export stripping remains separately scoped.
