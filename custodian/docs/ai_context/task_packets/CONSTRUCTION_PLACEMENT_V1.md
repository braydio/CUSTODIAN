# Construction Placement V1

- Status: `implemented_validation_passed`
- Authority: `design/02_features/infrastructure/CONSTRUCTION_PLACEMENT_V1.md`
- Goal: Extract Capacitor Bank placement into a permanent-infrastructure controller with zones, full-footprint validation, atomic tokens, and dedicated UI.
- Files: infrastructure runtime/content, `game.tscn`, terminal HUD/view model, focused validation, canonical docs.
- Constraints: Capacitor only; preserve tactical turret/barricade flow; no production art; no save migration; no push.
- Acceptance: user brief sections 27–31.
- Completed: Design ownership, permanent placement runtime, dedicated UI, transaction safety, behavioral smokes, and changed-file validation.
- Deferred: later structure catalog, demolition/repositioning, upgrades, cables, construction agents, production art, an optional broader compound runtime root, and any repo-wide spatial-authority audit.

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

## Generated Contract Spatial Authority

- Procgen now owns deterministic `compound_fabricator_anchor` and
  `compound_construction_zone_anchor` tile-space semantics selected from the
  finalized compound layout.
- `ContractWorldLoader` converts those anchors through the procgen map's
  canonical transform and repositions the existing persistent Field Fabricator
  and construction-zone nodes without replacing their behavior or state.
- Both anchors must remain generated floor and outside walls/ocean/chasm;
  missing or invalid anchors produce a bounded placement diagnostic rather than
  silently using world origin.

## Handoff

- Next action: production placement review can now use the generated fabrication yard; broader spatial-authority refactors remain optional follow-up work.
- Best starting files: `persistent_compound_layout_planner.gd`, `proc_gen_tilemap.gd`, `contract_world_loader.gd`, and `contract_world_population_placement_smoke.gd`.
- Validation: the focused population smoke proves generated-floor containment,
  canonical transform placement, and same-seed anchor determinism.
- Resolved blocker: the Field Fabricator and bounded yard no longer retain their
  fixed world-origin-authored runtime positions in generated contracts.
