# REVIEW: VAULTWING WORLD SPAWN INTEGRITY RECOVERY V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-vaultwing-world-spawn-integrity-recovery-v1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `vaultwing-world-spawn-integrity-recovery-v1`
- Locks: `vaultwing-world-spawner`
- Review: `none`
- Review target workstream: `vaultwing-world-spawn-integrity-recovery-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/VAULTWING_WORLD_SPAWN_INTEGRITY_RECOVERY_V1.md`
- Reviewed main: `80bb91444`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `none`
- Summary backlink: Include the exact Authoring chat URL above in every durable review/correction/recovery/closeout summary and final `## Next Handoff`; do not shorten or replace it.
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that production Vaultwing spawn tracking, duplicate suppression, parenting, reset, and replacement work without typed-array errors or scene-header brittleness.
- Reviewed implementation acceptance: Reuse every acceptance claim from the archived implementation packet.
- Review evidence: Archived implementation packet and summary; exact runtime diff; `vaultwing_world_spawn`; Vaultwing runtime, bond, relationship, and complete changed-file reports.
- Correction threshold: Any lost live instance, duplicate spawn, wrong parent, failure to reset/repopulate, invalid-instance logging regression, brittle scene assertion, or incomplete changed-file coverage requires a bounded correction.
- Focused validation: Run `vaultwing_world_spawn`, `vaultwing_runtime`, `vaultwing_bond`, and `actor_relationship_contract`; inspect changed-file coverage and `git diff --check`.
- Review focus: typed retention and freeing semantics; actual spawn/reset behavior; scene assertion resilience; preserved caps, telemetry, family selection, behavior, and determinism.
- Acceptance: Fresh-context findings-first review records either a clean pass or a bounded correction/re-review pair. Reviewer must not edit the implementation.
- Non-goals: Do not modify H5, ambient ProcGen generation, Vaultwing behavior/bond systems, or unrelated spawning systems.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Next Handoff

- Next workstream: `procgen-ambient-real-world-spawn-recovery-v1`
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: none
- Next action: After this review passes, continue to the separately scoped ambient real-world spawn recovery lane.
- Blockers or open questions: none
