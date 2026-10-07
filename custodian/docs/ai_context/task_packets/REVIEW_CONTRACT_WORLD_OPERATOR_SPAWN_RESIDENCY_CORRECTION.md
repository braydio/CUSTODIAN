# REVIEW: CONTRACT WORLD OPERATOR SPAWN RESIDENCY CORRECTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-contract-world-operator-spawn-residency-correction`
- Kind: `review`
- Status: `dependency-gated`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `contract-world-operator-spawn-residency-correction`
- Locks: `contract-world-loader, procgen-streaming, procgen-playability`
- Review: `none`
- Review target workstream: `contract-world-operator-spawn-residency-correction`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/CONTRACT_WORLD_OPERATOR_SPAWN_RESIDENCY_CORRECTION.md`
- Reviewed main: `0f0ccc439f53ff4ee198dab9c5e97cfc179b69d0`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent | same-agent-fresh-context`
- Review modes: `code, runtime`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Goal: Independently prove that the live invisible/frozen startup regression was caused by painted-presentation residency being mixed into spawn gameplay authority, and that the correction now selects canonically safe cells independently of paint while explicitly realizing only the chosen spawn before Operator control resumes.
- Reviewed implementation acceptance: Reuse every acceptance item from the archived implementation packet. In particular, do not accept a fix that merely unhides the Operator, widens spawn validity, reveals the whole map, or bypasses M5/M6/Archive Resolve.
- Review evidence: archived parent spawn-failsafe implementation/review; landed correction diff; real production-shaped unpainted-spawn fixture and mutation control; ProcGenTilemap lifecycle/payload/reveal code; loader install trace; previous accepted-component-72/safe-0 evidence; vehicle lifecycle smoke proving no auto vehicle possession.
- Correction threshold: Any spawn candidate still rejected solely for being unpainted; any Operator restored before selected floor realization; any reveal/topology bypass; any changed ingress-clearance/canonical-validity rule; any whole-map reveal; any failure to preserve genuine no-safe-cell fail-closed behavior; or any material evidence gap is correction-worthy.
- Focused validation: Run the new spawn-residency regression first. Verify its precondition actually has accepted component > 0 and selected canonical spawn unpainted. Mutation-disable the readiness seam and separately restore painted-floor candidate filtering; each must fail. Then independently run parent spawn-failsafe, playable-region validity, ingress clearance, Archive Resolve ingress, chunk lifecycle/cache/unload/pause-aware streaming, walkable boundary/navigation, vehicle lifecycle, S1 quick, changed-file checks and git diff check.
- Review focus: Trace selection and realization as two separate phases. Canonical selection must use valid-spawn + runtime-walkable + accepted-component + ingress-clearance authority only. Presentation realization must occur after one tile is selected and through one narrow map-owned seam. Verify the readiness seam is idempotent, uses existing lifecycle/payload/commit machinery, and does not become a generic discovery API. Confirm Operator visibility/process and camera/Archive ingress happen only after successful realization.
- Acceptance: Findings-first fresh-context review. Zero blocking defects/material gaps closes the correction. Blocking/material findings create `contract-world-operator-spawn-residency-correction-review-corrections-1` plus paired re-review.
- Non-goals: No vehicle redesign, map rescue/regeneration, Archive Resolve tuning, ingress relocation, or failure UX redesign.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, review packet lifecycle/archive metadata, required closing summary, and bounded correction/re-review packets; do not edit reviewed runtime code or unrelated work.`

## Handoff

- Next workstream: `procgen-archive-resolve-frontier-restraint`
- Next packet state: `resume-after-P0`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Refresh reason: `none`
- Next action: After this P0 passes, resume AR4's narrow tick-420 boundary-artifact tune and manual playtest.
- Blockers or open questions: implementation must land first.
