# Sundered Keep Procgen Frontage

- Status: `runtime complete; visual layering review open`
- Authority: `design/05_levels/SUNDERED_KEEP_PROCGEN_FRONTAGE.md`
- Goal: Generate the complete Sundered Keep approach inside the existing
  `ASCENT_FIELD` campaign world and place the Front Gate transition only at the
  generated terminal gate anchor.
- Files: procgen intent/frontage services, `ProcGenTilemap`, registered ingress
  placement, semantic presentation/camera scene, focused validators, and
  Sundered Keep/current-state documentation.
- Constraints: no special-room inserter; no authored floor rectangle; no
  route-master ground; no copied perimeter collision; no scene load before the
  gate; deterministic output; preserve the legacy approach as debug/reference.
- Acceptance: multi-seed structural smoke, renderer-backed eight-seed review,
  existing procgen/terrain/route/ingress regressions, continuous minimap and
  reversible world traversal.
- Completed: authority drift corrected; deterministic landmark intent and
  irregular frontage masks integrated into `ASCENT_FIELD`; generated terminal
  ingress and semantic presentation installed; route, terrain, blocker, and
  site protections validated; eight-seed renderer review generated.
- Deferred: additional frontage grammars beyond `curved_frontage_v1`.

## Ownership And Timing

- Owner: procgen intent graph / world landmark presentation
- Agent/session: Codex
- Created: 2026-07-30
- Last updated: 2026-08-10

## Work Surface

- Read: local primer, active/current Vista and authored-approach specs, procgen
  intent/ascent/playability pipeline, ingress placement, route contract,
  presentation scene, current state/index/validation guidance.
- Change: add landmark/frontage services, merge masks before playability and
  terrain, export semantic result, consume terminal anchor in ingress
  placement, replace production Vista presentation, validate and document.
- Out of scope: deleting the authored approach/mapper, expanding Front Gate,
  replacing core procgen substrate, four-grammar breadth, save-file authority.

## Plan

1. Correct design authority and packet.
2. Add deterministic landmark intent and irregular frontage generation.
3. Integrate result into `ASCENT_FIELD`, required cells, sites, and level data.
4. Place production ingress and presentation from semantic anchors.
5. Add structural and renderer-backed seed validation.
6. Run regressions and complete context documentation.

## Drift Review

- Primary authority: prior World Vista nine-tile authored-pocket design is
  superseded by `SUNDERED_KEEP_PROCGEN_FRONTAGE.md`.
- `CURRENT_STATE.md`: currently describes the authored pocket and direct
  presentation-only Vista; update after runtime behavior is proven.
- `CONTEXT.md`: currently prohibits Grand Vista/frontage systems in production;
  revise after the new semantic presentation is live.
- `FILE_INDEX.md`: index new services, presentation, spec, packet, and tests.
- Local routing/readmes: old approach must remain explicitly debug/reference.

## Handoff

- Next action: use the completed V1 as the baseline for human composition
  polish or a later second grammar; do not change playable-ground ownership.
- Best starting files:
  `proc_gen_tilemap.gd`, `ascent_field_builder.gd`,
  `world_ingress_placement_resolver.gd`, `world_ingress_spawner.gd`,
  `contract_world_loader.gd`, and the current Vista scene/script.
- Validation completed: focused 24-seed frontage smoke, procgen world-shape
  and route-clearance smokes, terrain-required-cells smoke, world and Keep
  ingress smokes, Vista presentation smoke, full route pipeline suite, and
  eight-seed 2560×1440 renderer review. The 2026-08-10 layering pass removed
  GateShadow, reduced/cooled the fortress components, crossfaded the initial
  landmark and reveal veil, and expanded storm coverage across semantic camera
  travel. Updated captures live in
  `reports/sundered_keep_layering_review_20260810/`; the final seam-corrected
  seed-1 proof is in `reports/sundered_keep_layering_review_20260810_final/`.
- Blockers or open questions: production art may still require later human
  composition tuning; structural V1 uses existing approved Vista assets. The
  existing Moment Forge first-reveal scenario intentionally remains a legacy
  authored-approach regression. Production visual evidence lives in
  `reports/sundered_keep_procgen_frontage/`. Descending Ward remains deferred:
  the reviewed skyline reads as a coherent atmospheric landmark without it.
