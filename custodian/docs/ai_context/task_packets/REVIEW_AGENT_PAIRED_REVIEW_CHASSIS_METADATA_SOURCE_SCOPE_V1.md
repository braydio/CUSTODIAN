# REVIEW: Paired Review Chassis Metadata Source-Scope Correction V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-paired-review-chassis-metadata-source-scope-v1`
- Category: `agent-ops`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P0`
- Depends on: `agent-paired-review-chassis-metadata-source-scope-v1`
- Locks: `paired-review-chassis-seal-metadata-source-scope-v1`
- Review: `none`
- Review target workstream: `agent-paired-review-chassis-metadata-source-scope-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_CHASSIS_METADATA_SOURCE_SCOPE_V1.md`
- Reviewed main: `0d074c73343a4695994b01d545f5cbf96e5d54c2`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aef1f35-9d0c-83ea-9916-59c5660da5fd
- Visual review: `none`
- Authoring handoff: `auto`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently establish that the exact historical metadata exception unblocks only the authorized chassis-attestation archive and does not weaken source ownership or approval gates.
- Reviewed implementation acceptance: Exact landing `7e1458d13a93619db4631d54b1ef217412b6d34e`, parent `dc48e1e9e8511abe160aad266ed44493f11e8666`, tree `d3c79bda78283b2ecd17b0ce4b2088fa47d278de`, and review-packet blobs `715b2551122294eb3451165a2ea88ceceaf3e97e` -> `c252ea91434bff599ad5dee6d2dd2ad92ac43733` at mode `100644`.
- Review evidence: Recompute actual Git identities/diff; run the exact historical source-span resolution and adversarial tests from the implementation packet; inspect the paired-review runner's canonical prelaunch report. Preserve and compare the currently held chassis-attestation review run/claim and original chassis-seal evidence.
- Correction threshold: Create correction work only for confirmed acceptance defects or evidence gaps that prevent confidence; subjective human decisions remain `human_required`.
- Focused validation: Independently run actual-history source-span positive and negative tests, existing canonical metadata tests, source ownership checks, and the coordinator changed-file report with complete coverage. Verify no reviewer verdict is inferred from validation alone.
- Review focus: Wrong or broadened metadata path, landing, parent/tree, mode/blob, paired identity, Publication input path set/order, additional byte edits, substitute packet, changed source ownership, or early activation of the original chassis attestation. Confirm that only the semicolon normalization is recognized and the review Markdown never enters implementation source paths.
- Acceptance: Findings-first fresh-context review. PASS only if the exact actual archive passes source-span and coordinator validation, hostile Git mutations fail closed, existing historical cases remain unchanged, and all preserved claims/evidence stay intact. Record stable cycle-scoped IDs and disposition for any findings. Do not patch reviewed code.
- Non-goals: No original review claim/run/worktree change; no original review reviewer launch, verdict, recovery plan/apply; no general `.md` permission; no new exception for other packets; no gameplay/runtime changes.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Reconstruct the correction from current main, archived packet, and exact Git objects in a fresh reviewer context.
2. Verify the source-span result and review packet exclusion using the actual `7e1458d...` history; inspect all exact pins and adversarial fixtures.
3. Run the prescribed independent validation, preserve the held review run and original chassis review, and record an evidence-based outcome.
4. Only after this correction's authenticated PASS lands, run the existing held review's read-only recovery plan:

   ```bash
   python3 custodian/tools/agent/paired_review_runner.py \
     review-agent-operator-chassis-seal-source-scope-attestation-v1 \
     --continue-run 20261107T172009Z-95b97875a887 \
     --recover-host-validation --plan
   ```

   Record exact plan output and SHA-256. Stop before apply or reviewer launch; a separate authorization is required.

## Handoff
- Next workstream: `review-agent-operator-chassis-seal-source-scope-attestation-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aef1f35-9d0c-83ea-9916-59c5660da5fd
- Refresh reason: `none`
- Next action: After accepted correction PASS, prepare the held run's same-claim read-only recovery plan and stop before apply or reviewer launch.
- Blockers or open questions: The held chassis-attestation review remains in host-validation recovery until the next authorization.
