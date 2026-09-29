# PROCGEN CANDIDATE SEMANTIC MODEL

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-candidate-semantic-model`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-candidate-evaluator-extraction`
- Locks: `procgen-generation`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Introduce the deterministic data-only candidate representation required to evaluate and later materialize procgen worlds without making rejected candidates live runtime scenes.
- Completion boundary: Done when the current generated candidate can be projected into one stable semantic candidate object/snapshot containing every evaluator-required fact, with round-trip/parity tests, while production still uses the existing live candidate path.
- Current measured state: Candidate evaluation consumes dictionaries and live ProcGenTilemap/level-data state. There is no canonical data-only object separating candidate semantics from runtime realization.
- Evidence: Reviewed S2 evaluator API; S1 schema/fingerprints; ProcGenTilemap get_level_data/debug fingerprint surfaces; current intent/terrain/region dictionaries.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; reviewed candidate evaluator; ProcgenSpatialContract and current level-data semantics.
- Work surface: game/world/procgen/generation/ candidate model/snapshot types and adapters; minimal ProcGenTilemap export hook only where authoritative data is not already exposed.
- Change: Define a deterministic candidate semantic payload containing floor/blocker topology, map bounds, regions, required routes/roads used by evaluation, elevation/terrain viability, compound/spawn anchors, required ingress facts, story/faction reservations, connectivity/playability facts, seed/config identity, and evaluator metadata. Add an adapter from the current generated candidate and prove stable serialization/fingerprint ordering. Evaluator consumes the semantic payload rather than reaching into live nodes.
- Preserve: All current generation behavior, candidate identity, level-data semantics, evaluator results, and runtime realization.
- Non-goals: Do not yet stop live candidate construction; no materializer; no runtime rendering/collision/nav changes.
- Acceptance: For S1 fixed cases, semantic snapshots are deterministic, evaluator results from snapshots equal current results exactly, and no evaluator call requires Node/TileMap references.
- Validation: New semantic-model parity smoke + evaluator smoke + S1 quick benchmark + candidate promotion; changed-file closeout.
- Task overrides: `none`
- Deferred: Direct semantics-first generation is the next packet.

## Context Economy / Low-Token Execution

This is a deliberate follow-up reminder for long-running Sonnet/Codex execution. Optimize context use without weakening correctness:

- treat this packet's Goal, Completion boundary, Change, Preserve, Acceptance, Validation, and Handoff as primary context;
- read the immediate predecessor closing summary and benchmark/roadmap evidence instead of rereading completed packets;
- do not re-audit the whole repository unless a packet assumption fails or a required dependency cannot be resolved;
- for very large files, especially `proc_gen_tilemap.gd`, search for the named functions/state first and read only the relevant ranges plus immediate callers/callees; do not load the full file by default;
- reuse landed S1 benchmark artifacts, prior slice summaries, and existing validation evidence rather than rediscovering established facts;
- inspect only the current authority, direct consumers, and direct dependencies needed for this slice;
- during iteration run focused validation only; run one normal changed-file closeout sweep after focused work is green;
- do not dump full logs, full diffs, or large source excerpts into progress/final responses; summarize failures and evidence compactly;
- do not restate this packet or narrate broad architecture before implementation unless a contradiction requires a decision;
- keep the closing summary factual and compact while still recording required evidence, drift, and handoff state.

Context economy is subordinate to correctness: expand scope only when a concrete failed assumption, test, or dependency proves that more repository context is required.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` and the matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Land the model/parity seam; procgen-semantic-candidate-generation then becomes eligible.
- Best starting files: generation/; proc_gen_tilemap.gd level-data/debug exports; candidate evaluator; S1 fixed cases.
- Blockers or open questions: None known at authoring time.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: two static-typing bugs and one real parity bug (missing null-map guard) in the first draft of the new snapshot code; all caught by the required parity smoke on the first real run.
- Root cause / contributing factors: mirroring an existing function's structure by eye missed one conditional early-return branch; GDScript's strict typed-var inference (warnings as errors) rejected a `Variant`-returning helper assigned via `:=`.
- Prevention / pipeline improvement: when mirroring a function for a new data source, diff the two implementations structurally (branch-by-branch) rather than re-deriving from the docstring/spec, and run the parity proof before anything else once both paths exist.
- Tooling / docs drift discovered: none new; `procgen_candidate_promotion_smoke.gd`'s pre-existing streaming-reveal assertion remains open, same as reported in S1 and G1.
- Follow-up: manual-follow-up (same pre-existing candidate-promotion streaming assertion tracked in S1/G1; still not owned by any packet in this series' scope).
