# PROCGEN GENERATION STATE EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-generation-state-extraction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-candidate-runtime-path-demolition, review-procgen-distant-chunk-unload-review-corrections-1`
- Locks: `procgen-runtime`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `cdf5a2d4a1259df11d27605208a01401a7d80627`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Goal: Extract accepted-world generation snapshot/level-data export ownership from ProcGenTilemap into a focused generation-state authority.
- Completion boundary: The slice closes when immutable/base accepted-world generated-state capture, level-data assembly/serialization, deterministic fingerprints, and terrain/result export live behind one focused owner in the existing `custodian/game/world/procgen/generation/` package, with runtime mutation overlays represented separately and `ProcGenTilemap` delegating.
- Current measured state: `custodian/game/world/procgen/generation/README.md` already contains `candidate_evaluator.gd`, `candidate_semantic_adapter.gd`, and `procgen_candidate_materializer.gd`; it explicitly still names `ProcGenTilemap` as runtime topology/final-realization authority. `ProcGenTilemap` currently owns `_capture_generated_tile_state`, `get_level_data`, `_get_terrain_builder_level_data`, generated floor/wall debug/fingerprint accessors, terrain/result export, and numerous exported semantic dictionaries. Rejected candidates still construct live TileMap-backed state, so this D3 extraction must preserve the exact G2/G4/G5 contracts that feed the later GenerationGrid audit.
- Evidence: `custodian/game/world/procgen/generation/README.md`; `candidate_evaluator.gd`; `candidate_semantic_adapter.gd`; `procgen_candidate_materializer.gd`; current `proc_gen_tilemap.gd` capture/export functions; `custodian/tools/validation/procgen_candidate_promotion_smoke.gd`; `procgen_candidate_semantic_model_smoke.gd`; `procgen_spatial_normalization_smoke.gd`; `world_contract_prewarm_smoke.gd`; S1 fingerprint schema.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; S1 benchmark schema; current level-data consumers.
- Work surface: The accepted-world state/export owner belongs in the existing `custodian/game/world/procgen/generation/` package beside, but not merged with, the evaluator/semantic-adapter/materializer owners. Reuse their schemas/contracts; do not create a second candidate snapshot authority. `ProcGenTilemap` remains a façade/runtime host until the later GenerationGrid migration and D4 contraction.
- Change: Extract capture/export/serialization as one coherent owner. Preserve externally consumed level-data keys unless a versioned migration is unavoidable and explicitly tested.
- Preserve: Fingerprints, level-data keys, terrain/road/region/intent data, ContractWorldLoader consumers, minimap/debug consumers.
- Non-goals: No save-system work, no loader placement extraction here, no semantic model redesign.
- Acceptance: Prove fixed fingerprints/level-data parity, one accepted-world capture/export owner, explicit separation from mutable runtime overlays, no duplicate candidate snapshot/evaluator authority, and `ProcGenTilemap` delegation for migrated export/capture paths.
- Validation: Refresh after the cycle-1 M6 re-review. Expected focused suite: `res://tools/validation/procgen_candidate_promotion_smoke.gd`, `res://tools/validation/procgen_candidate_semantic_model_smoke.gd`, `res://tools/validation/procgen_spatial_normalization_smoke.gd`, `res://tools/validation/world_contract_prewarm_smoke.gd`, `res://tools/validation/procgen_accepted_world_export_smoke.gd` (new parity pin), S1 quick, and changed-file closeout.
- Task overrides: `none`
- Deferred: Facade contraction follows all ProcGenTilemap extraction siblings. The post-D1/D2/D3 GenerationGrid audit/migration initiative now sits before D4.


## Live Refresh Record (execution-agent, claimed 2026-10-07)

Re-audited against live `main` before implementing. D1 road authority and the M6/MR6R1 streaming surface are landed; Archive Resolve AR1/AR2/AR3 are archived complete (only the AR4 frontier-restraint review is open). Archive Resolve's request/commit/unload/reacquisition observation seams are presentation-only consumers and are untouched: this slice moves no streaming, reveal, road, or claim state. Mutable runtime state (`_generated_floor_cells`/`_generated_wall_cells`, mutated by runtime terrain commits and connector dry-runs at ~60 sites) deliberately stays hosted by `ProcGenTilemap`; only capture and export moved. Base-vs-overlay separation of the stores themselves is deferred to the GenerationGrid initiative (X1+), which is where the packet's deferral already places storage ownership.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.


## Refresh Planning Authority

- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Refresh instruction: Bring the landed predecessor implementation/review summary and any new live-state evidence back to this ChatGPT conversation. Re-derive this packet here with the user against current `main` before changing it to `ready/auto`. Do not let the execution agent silently reinterpret architecture, scope, sequencing, visual direction, or acceptance during the refresh.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `removed`
- Evidence: `ProcgenAcceptedWorldExport (generation/accepted_world_export.gd) owns TileMap-to-cell capture, the 69-key level-data schema with copy/serialize modes, the terrain-builder level-data summary, and the runtime authoring fingerprint; ProcGenTilemap delegates and keeps the live mutable cell stores. Fixed-seed 3716816988 72x64 level-data hash 2068075335 and fingerprint hash 2896026968 are identical before and after the extraction (stable across 3 baseline runs; random_floor_tiles and fingerprint health/foliage excluded and checked structurally). Candidate promotion, semantic model, spatial normalization, world contract prewarm, macro presentation, ash-bell generation and S1 quick (determinism_ok=true) all pass. Negative control: flipping one derived key fails the parity smoke.`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `The first claim attempt hit LOCAL DISPATCH BUSY from a live Codex claim; retried after it released. A fresh worktree had no .godot import cache, so the first smoke runs failed to parse until godot --import ran. level data is not byte-stable across runs (random_floor_tiles is RNG-sampled, fingerprint health is timing counters), so the first baseline hashes disagreed.`
- Root cause / contributing factors: `Packet said refresh-gated though its Refresh Planning Authority already named the execution agent as owner and set no user refresh; the dispatcher correctly treated it as ready/auto.`
- Prevention / pipeline improvement: `Parity smoke hashes exclude the nondeterministic keys and asserts them structurally.`
- Tooling / docs drift discovered: `Packet prose still described itself as refresh-gated after its deps archived; refresh guard section was removed in this slice. The validation recipes do not mention running godot --import in a fresh worktree before a --script smoke.`
- Follow-up: `fixed-in-scope`

## Handoff

- Next workstream: `procgen-generation-data-model-audit`
- Next packet state: `dependency-gated` (waits on D2)
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Next action: Finish normally. Once D1+D2+D3 are all complete, `procgen-generation-data-model-audit` becomes eligible. D4 no longer follows these siblings directly; it is blocked behind the measured GenerationGrid migration initiative.
- Best starting files: _capture_generated_tile_state, get_level_data, debug fingerprint helpers, generation/ semantic types.
- Blockers or open questions: None known at authoring time.