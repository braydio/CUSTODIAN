# REVIEW: HUB MUSTER + CONTINUITY PORT DEPLOYMENT — H5

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-hub-muster-continuity-port-deployment`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `hub-muster-continuity-port-deployment`
- Locks: `hub-runtime, world-lifecycle, contract-bootstrap`
- Review: `none`
- Review target workstream: `hub-muster-continuity-port-deployment`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/HUB_MUSTER_CONTINUITY_PORT_DEPLOYMENT.md`
- Reviewed main: `348d00eea51e`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime`
- Visual review: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify the landed implementation against its archived packet and live runtime behavior.
- Reviewed implementation acceptance: Reuse every acceptance claim from the archived implementation packet.
- Review evidence: Archived implementation packet/summary, live code, focused smoke(s), affected regressions, changed-file evidence.
- Correction threshold: Confirmed acceptance defects or material proof gaps create correction work; optional improvements go next-slice/deferred.
- Focused validation: Run H5 Port deploy smoke, world_contract_prewarm, startup, ContractWorldLoader/WorldSimulation, H2/H3, then changed-file closeout.
- Review focus: GENERATING/FAILED/READY gating; deterministic retry; same accepted scenario/seed/map; no duplicate bootstrap; Campaign session injection; CLAIMED ordering; Hub/Campaign exclusivity.
- Acceptance: Produce a findings-first independent review of live main; record passed or stable cycle findings. Blocking defects/proof gaps create `hub-muster-continuity-port-deployment-review-corrections-1` plus paired review. Do not patch reviewed runtime here.
- Non-goals: Do not implement the next Hub slice or redesign adjacent systems.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Refresh Note

If the implementation packet is refreshed after its predecessor review, refresh this review's exact paths/focus alongside it when necessary.

## Handoff

- Next action: Follow the Hub roadmap after clean/non-blocking review.
- Blockers or open questions: implementation dependency only.
