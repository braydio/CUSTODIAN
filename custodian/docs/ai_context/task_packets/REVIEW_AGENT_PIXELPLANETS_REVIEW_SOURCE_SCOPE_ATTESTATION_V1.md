# REVIEW: PixelPlanets Retirement Exact Held-Review Source-Scope Attestation

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-pixelplanets-review-source-scope-attestation-v1`
- Category: `agent-ops`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `agent-pixelplanets-review-source-scope-attestation-v1`
- Locks: `paired-review-source-provenance, paired-review-host-validation`
- Review: `none`
- Review target workstream: `agent-pixelplanets-review-source-scope-attestation-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_PIXELPLANETS_REVIEW_SOURCE_SCOPE_ATTESTATION_V1.md`
- Reviewed main: `5991a89b7aa52c2fd87d00d3032ed506453e9a54`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aeb925d-9748-83e9-ae97-11c4532466c2`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: `Independently falsify the exact PixelPlanets post-hoc attestation correction before it can authorize an original review source-span or validation-manifest exception.`
- Reviewed implementation acceptance: `One immutable original source, archived packet and held review identity; exactly two omitted source paths and their pinned Git modes/blobs; test-definition manifest delta authenticated; correction accepted PASS/receipt/ancestry mandatory before the exception becomes active; no unrelated source passes.`
- Review evidence: `Exact correction implementation commit and archived packet, attestation JSON Git blob, real-Git failing-first and adversarial regression reports, original PixelPlanets source/archive commit/path inventory, canonical changed-file coverage, before/after original host run hash inventory, correction's distinct reviewer-authored receipt.`
- Correction threshold: `Any fail-open exception before accepted correction PASS; omitted blob/mode/commit/review/run pin; mismatched test manifest selection; unbounded wildcard/path acceptance; forged PASS; mutation of original claim/evidence; false historical acceptance; uncovered changed files; or new original-review launch blocks PASS.`
- Focused validation: `Reconstruct exact historic source/archived packet and both missing files by Git objects; run failing-first and accepted-review synthetic real-Git regression positive and negatives, including changed manifest test-definition checks. Run PYTHONPATH=custodian/tools/agent:custodian/tools python3 -m unittest custodian.tools.agent.test_paired_review_runner -v, python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json, and git diff --check, with complete coverage; report any red gate rather than waiving it.`
- Review focus: `The existing source-span path gate and _attested_manifest_comparison both require exact authentication; the approved attestation is read only from accepted correction history and bound to original run/review, not to generic packet text. Wrong file/revision/blob/mode/manifest/new test, fabricated or stale acceptance, wrong source claim, extra third path, or another workstream must fail closed. Verify no original review claim, symlink, reviewer verdict, WIRE run, or unrelated authority changed.`
- Acceptance: `An independent findings-first reviewer records canonical PASS only with zero blocking defects and zero material gaps, all exact positive/negative tests passing, and original host evidence preserved. Otherwise enumerate stable R0-NN findings and use the bounded correction lifecycle. This review does not accept or launch the original PixelPlanets independent review.`
- Non-goals: `No work on old game runtime, reviewer claim recovery/apply, no cleanup of protected worktrees, no waiver or generic provenance-policy revision, no editing the implementation being reviewed, no altering WIRE/other historical reviews.`
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Review Procedure

1. Start only after the attestation implementation has been published, validated, archived, and dispatcher reports this review eligible for a fresh independent reviewer.
2. Read current AGENTS, exact source-span/manifest validation code, the correction diff, attestation record and baseline original review identity.
3. Rebuild immutable original Git identities; verify two omitted paths and manifest bytes match attested blobs, and original archived packet remains untouched.
4. Replay both historical rejection gates and exactly pinned approved-review cases in disposable repositories. An in-test synthetic PASS must never activate a real production attestation.
5. Validate accepted correction-review PASS/receipt authentication and prove each additional path, stale acceptance, changed blob/mode, forged outcome, or wrong run fails.
6. Submit canonical findings-first verdict and finish only through normal independent-review lifecycle.

## Next Handoff

- Next workstream: `none`
- Next packet state: `n/a`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aeb925d-9748-83e9-ae97-11c4532466c2`
- Refresh reason: `none`
- Next action: `After a genuinely accepted correction-review PASS on origin/main, run exactly one read-only --recover-host-validation --plan for the preserved review-procgen-pixelplanets-legacy-retirement-v1 run 20261105T150829Z-655fc0421dbb. Defer --apply and fresh reviewer launch to separately authorized plan-digest action.`
- Blockers or open questions: `The original PixelPlanets review remains claimed and may not be re-claimed; current source-provenance execution lock contention must be respected.`
