# REVIEW: G2 HISTORICAL SOURCE-SCOPE ATTESTATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-paired-review-g2-source-scope-attestation-v1`
- Category: `agent-ops`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-g2-source-scope-attestation-v1`
- Locks: `paired-review-source-provenance`
- Kind: `review`
- Review: `none`
- Review target workstream: `agent-paired-review-g2-source-scope-attestation-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_G2_SOURCE_SCOPE_ATTESTATION_V1.md`
- Reviewed main: `c8e3957628e5d453a7ca10d49517ee71b78fd2bf`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae5d404-c86c-83ea-aec4-6cd3d75af933`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review modes: `code, architecture, workflow`
- Visual review: `none`
- Goal: Independently falsify the single G2 post-hoc validation-recipe scope exception and prove its approval-gated provenance cannot admit another file, landing, workstream, or review outcome.
- Reviewed implementation acceptance: The verifier authenticates only G2 archive `c8e3957628e5d453a7ca10d49517ee71b78fd2bf`, parent/tree and canonical archived packet blob, the exact complete source path inventory, and each path's Git mode/blob. The attestation names only the omitted `custodian/docs/ai_context/VALIDATION_RECIPES.md` blob. Its effect is inactive until this correction's canonical accepted independent PASS and target receipt are verified from main. The preserved original G2 review remains unlaunched until then.
- Review evidence: Landed correction implementation and attestation bytes; original G2 Git archive tree/blobs/modes; full disposable-Git historical replay; coordinator provenance digest/reverification; existing undeclared-path, Procession, Grunt and receipt regression cases; pre-approval rejection and exact post-approval acceptance.
- Correction threshold: Any early activation, extra path, identity drift, forged or noncanonical PASS, invalid receipt, changed provenance, or modification of G2 historical evidence is blocking. Report findings rather than weakening scope.
- Focused validation: Run the focused G2 historical attestation regression and related `paired_review_runner_unit` tests, compile the validator, and verify changed-file coverage. Use `/tmp` only for disposable fixtures; no Godot runtime suite.
- Review focus: Prove the source exception requires this correction's own accepted independent PASS, checks the complete pinned landing identity and admits exactly the one omitted recipe path, leaves every normal declared-path guard intact, and does not record a PASS or alter the original G2 reviewer run. Probe missing/forged/stale approval, wrong path/blob/mode/commit/packet/tree, extra source paths, mutated/ambiguous attestation origin and tampered coordinator evidence.
- Acceptance: Publish a findings-first independent review receipt. PASS only if the exact historical G2 replay fails before approval and passes after an authentic canonical accepted correction review; every listed negative remains rejected; the original G2 run is unchanged and unaccepted. No implementation edits from review context.
- Validation: `PYTHONPATH=custodian/tools/agent:custodian/tools python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`; compile `paired_review_host_validation.py`; `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json` with complete coverage; `git diff --check`. No Godot sweep.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only its durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`
- Deferred: If this review passes and lands, the coordinator will separately recover the exact original G2 host-validation run. This review is not G2's implementation verdict.

## Handoff
- Next workstream: `none`
- Next action: Following accepted PASS, continue the preserved G2 review using its exact run ID and a fresh recovery plan. No duplicate claim.
- Blockers or open questions: Original G2 review remains held before reviewer launch until its historical source span is admissible.
