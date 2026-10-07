# PROCGEN GENERATION DATA MODEL AUDIT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-generation-data-model-audit`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-procgen-road-authority-extraction, review-procgen-authored-claim-registry-extraction, procgen-generation-state-extraction`
- Locks: `procgen-generation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `architecture, code, workflow`
- Paired review workstream: `review-procgen-generation-data-model-audit`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `bff2d89496c68f73072fb69caa7eb3d68abf6aca`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9`
- Goal: Re-derive the post-D1/D2/D3 generation core from live code and produce the authoritative migration contract for replacing TileMapLayer-as-working-memory with a deterministic plain-data generation grid, without changing runtime behavior yet.
- Completion boundary: Done when every remaining generation-phase helper reachable from `ProcGenTilemap._fill_tilemaps()` is classified by ownership and storage behavior; every direct generation-time TileMapLayer cell read/write is accounted for; presentation-only/runtime-only operations are separated from generation-semantic operations; the minimum generation-grid capability set is specified from evidence; coherent migration clusters and dependency edges are identified; and no procgen runtime behavior changes in this workstream.
- Current measured state: D1 road-authority extraction is landed and independently reviewed passed with 0 blocking defects / 0 material gaps. D3 generation-state extraction is landed: `ProcgenAcceptedWorldExport` owns accepted-world capture, the ordered 69-key level-data/export contract, terrain summary and runtime authoring fingerprint; mutable generated floor/wall storage deliberately remains in `ProcGenTilemap` for the measured GenerationGrid migration. D2 authored-claim extraction is now ready/auto because its D1 review gate has passed, but D2 has not yet landed/reviewed. Therefore X1 has exactly one remaining predecessor gate: the completed paired review of D2. The audit must re-measure the final post-D1/D2/D3 call graph after that review rather than use the pre-D counts below.
- Evidence: reviewed D1 implementation/review and `ProcgenRoadAuthority`; landed D3 `generation/accepted_world_export.gd` plus its parity smoke/closing summary; ready D2 packet/review contract; live `custodian/game/world/procgen/proc_gen_tilemap.gd`; `custodian/game/world/procgen/procgen.gd`; current generation/roads/authored_claims package boundaries; G2/G4/G5 and S1 fingerprint authorities.
- Task-specific authority: `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`; post-D1/D2/D3 generation owners; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md` Completion Truth and migration-authoring rules.
- Work surface: Read/analyze post-D `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/game/world/procgen/procgen.gd`, the landed owners under `procgen/roads/`, `procgen/authored_claims/`, and `procgen/generation/`, candidate evaluator/adapter/materializer, focused validation, and benchmark/fingerprint authorities. Primary deliverable remains a versioned architecture inventory under `design/02_features/procgen/`; runtime `.gd` edits stay out of scope except a tiny read-only diagnostic tool if reproducibility genuinely requires it.
- Change: Build a durable inventory of the remaining generation pipeline after D1-D3. For every helper reachable from `_fill_tilemaps()`, record: phase/order, owning subsystem, reads, writes, TileMapLayer operations, generated semantic facts, presentation/runtime side effects, mutability requirements, direct callers/callees, candidate-evaluation relevance, and whether it can migrate independently. Classify cell operations into floor semantic state, wall/blocker semantic state, visual tile identity/atlas metadata, neighborhood/used-cell queries, erase/clear operations, and any other evidence-backed category. From that inventory define the *minimum* GenerationGrid contract required by current code, explicitly separating semantic cell state from render/materialization metadata. Identify coherent migration clusters, but do not author their implementation packets here.
- Preserve: All live procgen runtime code/output; D1/D2/D3 ownership; G1-G5 evaluator/materializer contracts; S1 fingerprints; existing M/P lane behavior; current TileMap-backed production path.
- Non-goals: No generation helper migration; no new pure-data backend; no TileMap wrapper injected into production; no accepted-candidate materializer changes; no performance claim beyond static inventory; no broad D4 cleanup.
- Acceptance: The audit's helper inventory is complete for the post-D1/D2/D3 `_fill_tilemaps()` call graph; the TileMapLayer operation count is re-measured rather than copied from the pre-D-lane 147 figure; every remaining generation-time cell operation maps to exactly one evidence-backed capability/category; presentation/runtime-only operations are explicitly excluded from GenerationGrid semantics; a minimum interface contract and migration dependency graph are concrete enough that the next foundation packet can implement them without rediscovering the architecture; no runtime procgen behavior/file changes occur except explicitly justified audit tooling.
- Validation: Static inventory checker or reproducible search script if created; code-review graph/current call graph cross-check; exact operation-count reconciliation; `git diff --stat` confirms no procgen runtime implementation changes; `check_ai_context.py --json`; task-packet/index check; `git diff --check`. No Godot benchmark sweep is required for an architecture-audit-only slice.
- Task overrides: `none`
- Deferred: Implementing the GenerationGrid seam; migrating any helper cluster; pure-data backend; candidate cutover; legacy TileMap-backed evaluation demolition.


## Archive Resolve Classification Guard

Before executing this post-D1/D2/D3 audit, confirm the Archive Resolve packet set
was refreshed against reviewed MR6 and inspect the live implementation if it has
landed. Archive Resolve request/commit/unload/reacquisition state is runtime
presentation state, not GenerationGrid working memory. The audit must classify
that owner and its callbacks as presentation/runtime-only and explicitly exclude
them from GenerationGrid semantic capabilities and migration clusters.

If the AR packet set is still pre-refresh when this audit becomes eligible, stop
and resolve the ordering rather than folding speculative reveal state into the
generation-data model.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `<fill at closeout>`

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

- Next action: After paired review passes, `procgen-generation-grid-foundation` becomes eligible.
- Best starting files: post-D1/D2/D3 `custodian/game/world/procgen/proc_gen_tilemap.gd`; `custodian/game/world/procgen/procgen.gd`; D1/D2/D3 closing summaries/owners; `custodian/game/world/procgen/generation/`; S1/G2 fingerprint/evaluator tests.
- Blockers or open questions: The exact helper clusters and exact GenerationGrid API are intentionally outputs of this packet, not pre-authored assumptions.
