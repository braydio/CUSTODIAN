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
- Reviewed main: `7913903704aee8fdd2c645891df441fa31fb6cca`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Goal: Introduce the neutral generation-cell storage seam proven by the audited post-D1/D2/D3 call graph, with a TileMap-backed compatibility backend that preserves current behavior and a plain-data-capable contract that later migration slices can target without inventing another storage API.
- Completion boundary: REFRESH-GATED on the passed `review-procgen-generation-data-model-audit`. Do not implement a GenerationGrid API from this pre-audit packet. After XR1, rewrite this same packet in place to the exact minimum capabilities, exact owner paths, parity contract, and smallest canary proven by the reviewed post-D audit.
- Current measured state: The prerequisite post-D1/D2/D3 audit has not run yet, so there is no reviewed helper inventory, cell-operation count, semantic-vs-presentation split, or minimum GenerationGrid interface to implement. Current live generation still uses `custodian/game/world/procgen/proc_gen_tilemap.gd` as TileMap-backed working memory; existing generation package files are `candidate_evaluator.gd`, `candidate_semantic_adapter.gd`, and `procgen_candidate_materializer.gd`. Any concrete `generation_grid.gd` API authored now would be speculative.
- Evidence: blocked/ready X1 audit packet and paired review; current `custodian/game/world/procgen/proc_gen_tilemap.gd`; `custodian/game/world/procgen/procgen.gd`; existing `custodian/game/world/procgen/generation/README.md` and candidate owner files; D1/D2/D3 refresh-gated packets.
- Task-specific authority: The **reviewed** X1 audit once it exists; `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`; current generation/fingerprint contracts.
- Work surface: Intentionally not frozen while blocked. The eventual seam belongs in the existing `custodian/game/world/procgen/generation/` package, but exact filenames/classes/API/canary must be taken from the reviewed X1 inventory. Do not pre-create a parallel storage abstraction before that review.
- Change: None while blocked. After XR1 passes, rewrite this packet from the audit's exact capability table, then implement only that reviewed semantic-storage seam with a compatibility backend/parity proof and the smallest justified integration.
- Preserve: Current production generation path/output, TileMap painting, G1-G5 evaluator/materializer behavior, D1/D2/D3 ownership, M/P lanes, S1 fingerprints and deterministic ordering.
- Non-goals: No pure-data backend used by production; no broad `_fill_tilemaps()` migration; no candidate-loop cutover; no deletion of TileMap-backed generation; no D4 façade cleanup.
- Acceptance: Not implementation-ready. The refreshed packet must bind every API method to a reviewed X1 capability/operation category, name the exact legacy path disposition, prove TileMap-backed parity, separate semantic state from render metadata, and forbid speculative extras.
- Validation: Not implementation-ready. Re-author after XR1 using exact audit outputs and then name only existing focused tests plus any new smoke created within the implementation workstream.
- Task overrides: `none`
- Deferred: Broad helper migration, pure-data backend, candidate cutover, and legacy rejected-candidate path demolition remain for the later measured migration series.

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


## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Refresh instruction: Bring the landed predecessor implementation/review summary and any new live-state evidence back to this ChatGPT conversation. Re-derive this packet here with the user against current `main` before changing it to `ready/auto`. Do not let the execution agent silently reinterpret architecture, scope, sequencing, visual direction, or acceptance during the refresh.

## Handoff

- Next action: After paired review passes, `procgen-generation-grid-migration-series-authoring` becomes eligible.
- Best starting files: reviewed audit artifact; preferred new `custodian/game/world/procgen/generation/generation_grid.gd`; preferred TileMap-backed adapter in the same package; current `proc_gen_tilemap.gd`; candidate semantic/evaluator tests.
- Blockers or open questions: The exact method names and any canary helper are outputs of the reviewed audit. Do not invent extra API to make future migrations hypothetically easier.