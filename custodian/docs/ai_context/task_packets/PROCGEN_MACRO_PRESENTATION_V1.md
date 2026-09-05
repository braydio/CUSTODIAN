# Procgen Macro Presentation V1

- Status: `in_progress`
- Authority: `design/02_features/procgen/PROCGEN_MACRO_PRESENTATION_SYSTEM.md`
- Goal: Introduce a deterministic region-first macro presentation layer for
  rocky-upland procgen while preserving the existing semantic grid as complete
  gameplay authority.
- Files: planned `game/world/procgen/presentation/`, biome profile resources,
  procgen integration, focused validation, debug observability, and rocky-upland
  content contracts.
- Constraints: no alpha collision, semantic mutation, navigation ownership,
  giant map texture, or new presentation responsibilities inside the
  `ProcGenTilemap` monolith; preserve current TileMap fallback.
- Acceptance: deterministic placement, contained non-overlapping footprints,
  unchanged semantic fingerprints, valid depth roots, safe fallback, existing
  procgen validation green, and an approved fixed-seed V1 visual review.
- Completed: hardened authority reconciliation, final-state biome sequencing,
  pure region/planner/catalog foundations, presentation roots and realization,
  streaming visibility gating, separate dressing clearance, level summary,
  observability, empty production catalog, and focused smoke foundation.
- Deferred: production art/profile population and fixed-seed visual acceptance.

## Ownership And Timing

- Owner: CUSTODIAN procgen/world presentation
- Agent/session: Codex 2026-09-04
- Created: 2026-09-04
- Last updated: 2026-09-04

## Work Surface

- Read: active procgen/elevation/environment specs; `CURRENT_STATE.md`;
  `CONTEXT.md`; `FILE_INDEX.md`; live terrain, biome, foliage-clearance,
  authored-claim, streaming, and depth-presentation code.
- Change: the active design authority, new presentation subsystem, minimal
  integration seams, biome presentation fields, content resources, focused
  validation, and required AI-context indexes after implementation.
- Out of scope: changing procgen topology, replacing semantic TileMaps, deriving
  gameplay from art, implementing all biomes at once, or automatically approving
  visual baselines.

## Migration Ledger

| Phase | Deliverable | Gate | Status |
| --- | --- | --- | --- |
| 0 | Hardened contract reconciliation and live API audit | Paths, schemas, ownership, deterministic rules, and validation commands locked | validated |
| 1 | Rocky-upland region extraction and macro stamp foundation | Determinism, containment, no semantic mutation, fallback smoke | in_progress |
| 2 | Cluster and hardstand composition | Clearance/readability rules preserved; quiet-ground ratios reviewable | pending |
| 3 | Minor/major/hero landmark placement | Deterministic cadence and authored-claim compatibility proven | pending |
| 4 | Woodland, wetland, and scrubland vocabularies | Per-biome fallback and regression coverage proven | pending |
| 5 | Lighting/weather/surface-overlay finish | Existing environment authorities retained; visual review approved | pending |

Allowed ledger states are `waiting_spec`, `pending`, `in_progress`, `blocked`,
`validated`, and `deferred`.

## Dependency And Risk Register

| Area | Dependency or risk | Required resolution |
| --- | --- | --- |
| Semantics | Presentation accidentally becomes collision/nav authority | Snapshot semantic inputs and assert unchanged output fingerprints |
| Determinism | Catalog iteration or weighted choice becomes order-sensitive | Stable IDs, sorted candidates, seeded selection, explicit tie-breakers |
| Depth | Macro art crosses actors, structures, and foreground bands | Lock root/z/occlusion contract before scene integration |
| Streaming | Sparse large sprites may appear, duplicate, or reroll on reveal | Define lifecycle against accepted-candidate promotion and reveal |
| Claims | Stamps or later clusters invade authored/route/combat clearances | Reuse a named existing claim/clearance API after live audit |
| Performance | Large textures and many Sprite2D nodes exceed budgets | Set texture, node, culling, and per-screen budgets in hardened spec |
| Art | Visual footprint and semantic footprint disagree | Require explicit masks/anchors and debug footprint overlays |
| Inventory | Production family contains 19 specified runtime assets | Keep catalog empty until approved art and masks exist |
| Fallback | Missing assets make terrain invisible or invalid | Keep current TileMap sources authoritative and visible |
| Scope | Biome/profile work expands into classification rewrite | Add presentation fields only; retain classifier ownership |

## Planned Implementation Sequence

1. Reconcile the hardened spec and resolve every open decision in the active
   design document.
2. Audit live APIs and record exact integration symbols and ownership.
3. Add data-only profiles/catalogs and validation fixtures.
4. Add region extraction with deterministic, inspectable outputs.
5. Add fitting/placement without scene mutation, then prove selection rules.
6. Add back/ground/front scene roots and presentation-only instantiation.
7. Integrate accepted-candidate promotion, streaming lifecycle, and clearances.
8. Register the rocky-upland vertical-slice content vocabulary.
9. Run focused and existing procgen validation plus fixed-seed visual review.
10. Update current state/indexes only when runtime truth changes.

## Acceptance Matrix

| Contract | Evidence required | State |
| --- | --- | --- |
| Same seed + semantics selects identical stamps | focused smoke across named seeds | pending |
| Stamp footprint is contained by qualifying input region | mask/region assertions | pending |
| Required cells and claims never overlap | focused claim/route assertions | pending |
| Terrain, biome, collision, and nav semantics are unchanged | before/after fingerprints | pending |
| Nodes appear only in valid depth roots | scene-tree assertions | pending |
| No-fitting-stamp case preserves current rendering | explicit empty-catalog fixture | pending |
| Rejected candidates expose stable reasons | debug snapshot/event assertions | pending |
| Existing procgen/elevation/foliage/streaming behavior remains green | repository validation recipes | pending |
| V1 reaches the rocky-upland visual target | fixed-seed Moment Forge/manual review | pending |

## Drift Review

- Primary authority: new draft at
  `design/02_features/procgen/PROCGEN_MACRO_PRESENTATION_SYSTEM.md`.
- `CURRENT_STATE.md`: no update now; no runtime behavior changed.
- `CONTEXT.md`: no update now; repository working model is unchanged.
- `FILE_INDEX.md`: update when implementation entrypoints exist.
- Local routing/readmes: update when the new runtime/content directories exist.

## Handoff

- Next action: complete the required regression suite, then await approved
  rocky-upland art/profile masks for visual acceptance.
- Best starting files: the authority document, this packet,
  `ELEVATED_WORLD_PRESENTATION.md`, the environment/biome spec, and the live
  procgen/terrain integration points discovered during the audit.
- Validation to run now: documentation path/link checks and `git diff --check`.
- Validation after implementation: focused macro-presentation smoke plus the
  existing terrain, elevation, route, foliage, streaming, and full procgen
  recipes named by the hardened spec.
- Blockers or open questions: no approved rocky-upland production PNGs or stamp
  masks are currently registered, so the required visual acceptance cannot yet
  be completed without fabricating forbidden placeholder art.
