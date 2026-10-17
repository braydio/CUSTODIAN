# REVIEW PROCGEN ELEVATION CONNECTOR TOPOLOGY V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-procgen-elevation-connector-topology-v1`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `procgen-elevation-connector-topology-v1`
- Locks: `procgen-terrain, elevation-runtime`
- Kind: `review`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, runtime, architecture`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `fresh-context falsification of generated shelf-wrap connector topology`
- Review target workstream: `procgen-elevation-connector-topology-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PROCGEN_ELEVATION_CONNECTOR_TOPOLOGY_V1.md`
- Reviewed main: `<fill at claim>`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Goal: Prove A2 creates bounded deterministic multi-elevation routes through existing semantics without carving claims or smuggling presentation into topology.
- Completion boundary: Reconstruct the landed implementation from main, inspect actual changed owners rather than trusting its summary, run the focused falsification set, and record findings-first disposition.
- Current measured state: Reconstruct from landed main and the archived implementation packet/closing summary.
- Evidence: landed A2 diff/summary, connector fixtures, terrain/elevation/intent/navigation regressions.
- Task-specific authority: ASCENT_FIELD remains upstream shape authority; TerrainBuilder/ElevationMap own height/traversal; procgen claim/reservation APIs own footprints; presentation is downstream.
- Work surface: landed implementation files, directly affected tests, and only bounded review artifacts authorized below.
- Change:
  1. Re-run valid/invalid candidates including claim overlap, insufficient landing, illegal height and no-space cases.
  2. Verify exported geometry alone is sufficient to size/register art without pixel inference.
  3. Prove NavigationSystem sees standard ramp/stair edges and ordinary cliff edges remain closed.
- Preserve: accepted-seed determinism, route/claims, TerrainBuilder rollback/rescue, ordinary cliff semantics outside reservations, streaming and spawn validity.
- Non-goals: no redesign, unrelated cleanup, preference tuning, or implementation edits inside the review workstream.
- Acceptance:
  1. Connector planning/realization is deterministic, bounded, claim-safe, connected and non-vacuous.
  2. Negative controls fail for the intended reason; no passing fixture is vacuous or presentation-only where runtime behavior is claimed.
  3. No blocking defect or material evidence gap remains.
- Validation: connector + TerrainBuilder + ElevationMap + intent/ascent + navigation + reservation/playability + changed-file validation + `git diff --check`.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`
- Deferred: A3 owns production art; A4 owns cliff/presentation integration.

## Handoff
- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391`
- Refresh reason: `none`
- Next action: `If PASS, return exact footprint/anchor schema to this Authoring chat to refresh A3.`
- Blockers or open questions: `implementation dependency and the implementation packet's refresh gate`
