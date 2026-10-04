# REVIEW: CONTRACT WORLD INGRESS SPAWN CLEARANCE FIX

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-contract-world-ingress-spawn-clearance-fix`
- Kind: `review`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `contract-world-ingress-spawn-clearance-fix`
- Locks: `contract-world-loader`
- Review: `none`
- Review target workstream: `contract-world-ingress-spawn-clearance-fix`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/CONTRACT_WORLD_INGRESS_SPAWN_CLEARANCE_FIX.md`
- Reviewed main: `5337c58f191a3b36f11b2a78049416b462cdb22a`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent | same-agent-fresh-context`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Review modes: `code, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the reproducible Forlorn Ritualant surface-ingress spawn collision is actually prevented by authority/order correctness rather than hidden by a seed-specific relocation hack.
- Reviewed implementation acceptance: Reuse all acceptance items from the implementation packet. Treat structural-ingress-before-Operator ordering, canonical clearance-query reuse, safe fallback selection, deterministic collision-clear spawn, required Ritualant ingress preservation, and no generation/AR2 drift as explicit obligations.
- Review evidence: Archived implementation packet/summary; live ContractWorldLoader install order; WorldIngressSpawner placement + dressing-clearance claim; ProcGenTilemap clearance query; focused overlap regression; Ash Bell/world-ingress required-contract regressions.
- Correction threshold: Any path that can still choose the Operator position before ingress structural claims, any spawn candidate allowed inside ingress clearance, any loss of required Ritualant ingress/route validity, nondeterministic fallback spawn, or a test that does not actually overlap the old preferred spawn with authored ingress collision is correction-worthy.
- Focused validation: First inspect/run the dedicated overlap regression and require it to demonstrate the pre-fix failure shape rather than only an arbitrary safe map. Verify the selected world position with a real Operator-sized collision query. Then rerun world-ingress, Ash Bell presentation, required-ingress sweep, population placement, stuck-pocket/camera regressions and changed-file checks.
- Review focus: Ensure one authority chain: ingress placement claims structural space, then ContractWorldLoader selects final actor position from the resulting map/clearance truth. Reject solutions that duplicate clearance rectangles in the loader, weaken Ash Bell collision, hardcode a different spawn, or paper over the issue with a one-frame teleport after physics begins.
- Acceptance: Produce a findings-first independent review. Blocking defects/material proof gaps create `contract-world-ingress-spawn-clearance-fix-review-corrections-1` plus paired re-review. A clean/non-blocking pass closes the hotfix.
- Non-goals: Do not review AR2 shader aesthetics, redesign world placement extraction, change Forlorn Underground, or broaden into generic collision resolution.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Refresh reason: `none`
- Next action: `No correction packet required; implementation review passed.`
- Blockers or open questions: none

## Review Result

- Outcome: `passed`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Reviewed on main: `5337c58f191a3b36f11b2a78049416b462cdb22a`
- Review modes: `code, runtime`
- Findings: `none`
- Focused evidence: `contract_world_ingress_spawn_clearance, world_ingress_spawner, ash_bell_lift_ingress_presentation, contract_world_population_placement_smoke.gd, camera_presentation_subject_constraint` all passed independently in this review worktree.
- Ancillary evidence: `required_ritualant_ingress_contract_sweep.gd --seed-count=1` placed the required Ritualant ingress and passed its required-ingress dry-run/presence path, then reproduced the previously recorded seed-0 Threadway approach-reachability and zero-cell failures. `procgen_stuck_pocket_smoke.gd` reproduced its pre-existing line-70 assertion and required a 45-second timeout because the failed SceneTree did not exit. Neither failing test path is changed by the reviewed commits.
- Review conclusion: `Registered ingress placement/clearance precedes sector and Operator placement; the loader reuses the canonical live clearance query for compound and fallback tiles; deterministic safe selection and the 96px-class collision probe pass. The implementation stays within the active Ash Bell ingress ownership contract. No correction-worthy defect or material proof gap remains.`
- Follow-up workstream: `none`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: `A concurrent broad validation run initially occupied the machine-wide Godot slot; after it finished, review regressions ran serially. The required-ingress sweep and stuck-pocket smoke reproduced known failures outside the changed code.`
- Root cause / contributing factors: `The required-ingress sweep also asserts seed-specific Threadway isolation and costs roughly two full procgen generations per seed; the unregistered stuck-pocket smoke leaves its SceneTree alive after its existing assertion fails.`
- Prevention / pipeline improvement: `Retain the bounded one-seed ingress-placement check and keep the known Threadway/stuck-pocket failures separate from spawn-clearance acceptance.`
- Tooling / docs drift discovered: `none`
- Follow-up: `manual-follow-up` (existing Threadway and stuck-pocket failures remain outside this review scope)
- What worked: `The focused overlap fixture plus canonical spawner/Ash Bell checks provided direct, reproducible evidence for clearance ownership and deterministic collision-free selection.`
