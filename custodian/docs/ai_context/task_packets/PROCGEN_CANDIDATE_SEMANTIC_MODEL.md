# PROCGEN CANDIDATE SEMANTIC MODEL

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-candidate-semantic-model`
- Status: `ready`
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

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` and the matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Land the model/parity seam; procgen-semantic-candidate-generation then becomes eligible.
- Best starting files: generation/; proc_gen_tilemap.gd level-data/debug exports; candidate evaluator; S1 fixed cases.
- Blockers or open questions: None known at authoring time.
