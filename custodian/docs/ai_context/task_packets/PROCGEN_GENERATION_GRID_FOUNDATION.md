# PROCGEN GENERATION GRID FOUNDATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-generation-grid-foundation`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-procgen-generation-data-model-audit`
- Locks: `procgen-generation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-procgen-generation-grid-foundation`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `f2bc848515b8454f362167f57eb87bfe823ac184`
- Goal: Introduce the neutral generation-cell storage seam proven by the audited post-D1/D2/D3 call graph, with a TileMap-backed compatibility backend that preserves current behavior and a plain-data-capable contract that later migration slices can target without inventing another storage API.
- Completion boundary: Done when one focused GenerationGrid contract owns the exact semantic cell operations identified by the reviewed audit; a TileMap-backed implementation can satisfy that contract against the existing live generation path without behavior change; semantic cell state is explicitly separated from render/materialization metadata; focused contract/parity tests exist; and only the smallest evidence-backed canary integration needed to prove the seam is usable is routed through it. Broad helper migration is not part of this packet.
- Current measured state: The reviewed predecessor audit is the authority for the exact remaining helper count, cell-operation count/categories, semantic-vs-presentation split, and minimum API. Before that audit, pre-D-lane ProcGenTilemap had ~40 generation helpers and 147 direct TileMapLayer cell-operation call sites, but those numbers must not be assumed current here.
- Evidence: Reviewed `procgen-generation-data-model-audit` inventory; live `proc_gen_tilemap.gd`; `procgen.gd`; post-D1/D2/D3 owners; G2 candidate semantic model/evaluator; S1 fixed fingerprints.
- Task-specific authority: Reviewed audit's versioned GenerationGrid contract and migration graph; `PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`; current generation/fingerprint contracts.
- Work surface: Prefer new focused files under `custodian/game/world/procgen/generation/`, e.g. `generation_grid.gd` and `tilemap_generation_grid.gd`, unless the reviewed audit establishes a better exact seam. Add focused validation under `custodian/tools/validation/`. Touch `proc_gen_tilemap.gd` only for the minimal canary/dependency injection proven safe by the audit.
- Change: Implement only the capabilities the reviewed audit proves current generation requires. The contract must model generation-semantic floor/wall/blocker state independent of Node/TileMap types and must not expose TileMapLayer-specific atlas/source/render details as core semantic storage. Implement a TileMap-backed compatibility backend that reads/writes the existing TileMapLayer state with identical semantics. Add deterministic snapshot/fingerprint support sufficient to compare backend-visible semantic state. Route a minimal canary helper or narrowly bounded operation group through the seam only if the audit identifies one that can prove integration without beginning the broad migration; otherwise prove the backend contract directly in tests and leave production routing for the generated migration series.
- Preserve: Current production generation path/output, TileMap painting, G1-G5 evaluator/materializer behavior, D1/D2/D3 ownership, M/P lanes, S1 fingerprints and deterministic ordering.
- Non-goals: No pure-data backend used by production; no broad `_fill_tilemaps()` migration; no candidate-loop cutover; no deletion of TileMap-backed generation; no D4 façade cleanup.
- Acceptance: One canonical GenerationGrid API exactly covers the reviewed audit's minimum semantic capabilities and no speculative extras; TileMap-backed backend parity is proven against current semantic reads/writes; contract types contain no Node/TileMapLayer dependency; semantic snapshot/fingerprint parity is deterministic; any canary production integration preserves fixed-seed world/evaluator fingerprints; no helper outside the explicitly bounded canary is silently migrated.
- Validation: New GenerationGrid contract/backend smoke; fixed-seed semantic snapshot parity; any canary-specific regression; G2 candidate semantic-model/evaluator smoke; S1 quick determinism; `check_ai_context.py --json`; one changed-file closeout; `git diff --check`.
- Task overrides: `none`
- Deferred: Broad helper migration, pure-data backend, production candidate cutover, legacy evaluation backend demolition.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: `<fill at closeout; TileMap-backed production is intentionally preserved for later migration>`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `<fill at closeout>`
- Friction severity: `<fill at closeout>`
- What went wrong: `<fill at closeout>`
- Root cause / contributing factors: `<fill at closeout>`
- Prevention / pipeline improvement: `<fill at closeout>`
- Tooling / docs drift discovered: `<fill at closeout>`
- Follow-up: `<fill at closeout>`

## Handoff

- Next action: After paired review passes, `procgen-generation-grid-migration-series-authoring` becomes eligible.
- Best starting files: reviewed audit artifact; preferred new `custodian/game/world/procgen/generation/generation_grid.gd`; preferred TileMap-backed adapter in the same package; current `proc_gen_tilemap.gd`; candidate semantic/evaluator tests.
- Blockers or open questions: The exact method names and any canary helper are outputs of the reviewed audit. Do not invent extra API to make future migrations hypothetically easier.
