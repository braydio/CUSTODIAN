# REVIEW: Living-World Abstract Activity Foundation · F14-B

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-living-world-abstract-activity-foundation`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `living-world-abstract-activity-foundation`
- Locks: `world-simulation-runtime, living-world-abstract-activity`
- Review: `none`
- Review target workstream: `living-world-abstract-activity-foundation`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION.md`
- Reviewed main: `dbe29e53bc4b5c304ba9bae54102a0cd5c2ad45b`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify the newly landed F14-B group activity slice against its design lock and actual test evidence, with a clean fresh context; do not implement it a second time.
- Reviewed implementation acceptance: The archived `LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION.md` acceptance items 1–9 including one abstract group, no physical B actors, causal deterministic step, snapshot continuation, duplicate/invalid ID rejection, legacy v4 compatibility and regressions.
- Review evidence: Archived implementation packet/summary, current `main` source + `WorldSimulationState` snapshot, changed owner tests and focused seed/permutation/restore log from implementation run. Reuse reported evidence; do not pretend prior F14 baseline smokes prove this new behavior.
- Correction threshold: Only blocking acceptance defects or material evidence gaps become bounded correction/re-review packets; route optional movement/AI/world-scale enhancements to F14-C/F15 separately.
- Focused validation: Reproduce the new focused abstract-activity smoke and relevant `res://tools/validation/world_simulation_kernel_smoke.gd`, `res://tools/validation/world_simulation_macro_state_smoke.gd`, `res://tools/validation/world_simulation_snapshot_roundtrip_smoke.gd` if new behavior/fixture changes merit them. Verify legacy snapshot restore/fingerprint and pause/duplicate-negative controls; no broad sweep without a specific defect.
- Review focus: Single macro time authority; no `_process`-driven activity; no double-counted resource/assault system; stable domain/group/location identities; deterministic iteration/RNG; event deduplication; bounded logs; no accidental physical reification; no mistaken claim that Archive Resolve generates territory or that facility `Sector` IDs are geographic locations.
- Acceptance: Fresh-context findings-first independent review on landed implementation main; each substantive finding gets ID, severity/class, domain, acceptance link, evidence and disposition. Record `passed` or bounded corrections as appropriate. Do not patch reviewed implementation code.
- Non-goals: No gameplay rebalancing, vehicle changes, procgen map expansion, physical encounter simulation, actor reification, REMAP-3 disk persistence implementation or art.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure and authoring gate

The implementation and this review are intentionally `draft/manual` until targeted repository preflight proves they can become `ready/auto`. Follow `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md` and root/local AGENTS. Claim this review only after the implementation lands and archives `complete`. Begin a separate fresh context; review from public durable evidence. Confirm no duplicate population after repeated abstract ticks within this slice, and defer actual instantiated actor crossings to F14-C.

Authoring preflight (run from repository root before promoting both packets):
```bash
python3 custodian/tools/agent/validate_task_packet_authoring.py \
  custodian/docs/ai_context/task_packets/LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION.md \
  custodian/docs/ai_context/task_packets/REVIEW_LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION.md
```

## Next Handoff

- Next workstream: `living-world-entity-reification-handoff` (future, **not authorized/created**)
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Refresh reason: Review the actual B state/serialization/API surface before specifying F14-C loaded actor ownership, identity handoff and duplicate-prevention tests, and reconcile F15 geographic-ID contract.
- Next action: Return the reviewer verdict and B implementation evidence to this authoring chat for C contract refresh.
- Blockers or open questions: none for independent review after B lands; F14-C design remains gated.
