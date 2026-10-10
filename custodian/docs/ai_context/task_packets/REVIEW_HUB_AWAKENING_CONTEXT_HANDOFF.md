# REVIEW: HUB AWAKENING CONTEXT HANDOFF — H2

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-hub-awakening-context-handoff`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `hub-awakening-context-handoff`
- Locks: `hub-runtime, world-lifecycle`
- Review: `none`
- Review target workstream: `hub-awakening-context-handoff`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/HUB_AWAKENING_CONTEXT_HANDOFF.md`
- Reviewed main: `872f33b8e83c94446dbfb773e759417e6db3dff2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify the landed implementation against its archived packet and live runtime.
- Reviewed implementation acceptance: Reuse every acceptance claim from the archived implementation packet.
- Review evidence: Archived packet/summary, live changed runtime, focused smoke(s), directly affected regressions, changed-file closeout.
- Correction threshold: Create correction work only for confirmed acceptance/correctness defects or material proof gaps; optional improvements go next-slice/deferred; subjective decisions become `human_required`.
- Focused validation: Run H2 focused handoff smoke first. Include a real-Operator case beginning south of the completion volume with console+P-9 satisfied: prove the completion request freezes/transfers before the Operator can contact `SouthReachCollapse`, then prove the target Operator appears exactly at `Spawn_SouthReach`. Add incomplete-qualification and forced-target-failure cases proving the source remains playable and the rollback barrier stays intact. Then run reviewed Awakening/H1/startup/camera-navigation regressions and changed-file closeout.
- Review focus: Exactly-once completion consumption; major-context ownership versus authored traversal; active-world exclusivity; `Spawn_SouthReach`; successful qualified traversal must freeze/transfer before the Operator can collide with the temporary `SouthReachCollapse` barrier; incomplete/failed handoff retains the barrier as a safe source rollback seal; binding-before-input; rollback; zero Contract generation.
- Acceptance: Produce a findings-first independent review of live `main`; record passed or stable cycle findings. Blocking defects/proof gaps create `hub-awakening-context-handoff-review-corrections-1` plus paired review. Do not patch reviewed runtime here.
- Non-goals: Do not implement the next Hub slice or redesign adjacent systems.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Refresh Note

When the blocked implementation packet is refreshed after predecessors land, refresh this review's exact evidence paths/focus in the same docs change if needed.

## Handoff

- Next action: Follow the Hub roadmap after a clean/non-blocking review.
- Blockers or open questions: implementation dependency only.
