# Construction Placement V1

- Status: `implemented_validation_passed`
- Authority: `design/02_features/infrastructure/CONSTRUCTION_PLACEMENT_V1.md`
- Goal: Extract Capacitor Bank placement into a permanent-infrastructure controller with zones, full-footprint validation, atomic tokens, and dedicated UI.
- Files: infrastructure runtime/content, `game.tscn`, terminal HUD/view model, focused validation, canonical docs.
- Constraints: Capacitor only; preserve tactical turret/barricade flow; no production art; no save migration; no push.
- Acceptance: user brief sections 27–31.
- Completed: Design ownership, permanent placement runtime, dedicated UI, transaction safety, behavioral smokes, and changed-file validation.
- Deferred: later structure catalog, demolition/repositioning, upgrades, cables, construction agents, production art.

## Ownership And Timing

- Owner: Codex
- Agent/session: Construction Placement V1 implementation
- Created: 2026-08-13
- Last updated: 2026-08-13

## Work Surface

- Read: infrastructure/fabrication design, current-state/index/validation docs, scene, placement/UI/definitions/registry/inventory, existing smokes.
- Change: permanent placement authority and its terminal boundary.
- Out of scope: tactical placement refactor and expanded infrastructure catalog.

## Plan

1. Establish design authority and catalog/definition contracts.
2. Implement zone, validator, preview, controller, scene/HUD wiring.
3. Route Ready Builds and preserve tactical compatibility.
4. Add behavioral smokes, docs, graphical review, and scoped commit.

## Drift Review

- Primary authority: update infrastructure and resource-fabrication docs.
- `CURRENT_STATE.md`: record new placement ownership.
- `CONTEXT.md`: no general working-model change expected.
- `FILE_INDEX.md`: index new runtime/design/test entrypoints.
- Local routing/readmes: correct `content/fabrication/REQUIRED_ASSETS.md` Light Barricade drift.

## Handoff

- Next action: reconcile the fixed world-origin Fabricator yard with the seed-dependent generated compound floor before final production placement review.
- Best starting files: `game.tscn`, `contract_world_loader.gd`, and the procgen compound anchors returned by `ProcGenTilemap.get_level_data()`.
- Validation run: changed selector plus new and existing focused smokes pass.
- Blocker: the production run found no generated floor beneath the fixed `FieldFabricatorMk1` at `(1120, -480)`; the nearest floor was seed-dependent and about 1,000 px away. The bounded zone is intentionally not enlarged to mask that pre-existing authoring mismatch.
