# Paired Review Chassis Metadata Source-Scope Correction V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-chassis-metadata-source-scope-v1`
- Category: `agent-ops`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `agent-operator-chassis-seal-source-scope-attestation-v1`
- Locks: `paired-review-chassis-seal-metadata-source-scope-v1`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-chassis-metadata-source-scope-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `This exact historical exception changes a coordinator trust boundary and must be independently verified before the preserved prelaunch review can use it.`
- Reviewed main: `0d074c73343a4695994b01d545f5cbf96e5d54c2`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aef1f35-9d0c-83ea-9916-59c5660da5fd
- Visual review: `none`
- Authoring handoff: `auto`
- Goal: Allow the preserved chassis-attestation review's exact source archive to pass source-span validation while keeping the syntax-only paired-review packet edit outside implementation source ownership.
- Completion boundary: Add one post-hoc, exact-history metadata-path exception for the authorized `Publication inputs` delimiter repair in landing `7e1458d13a93619db4631d54b1ef217412b6d34e`. Authenticate its parent, path, mode, before/after blobs, packet identity and exact bytes. Do not generalize the exception or change the archived implementation packet's Work surface.
- Current measured state: The fresh paired review of `agent-operator-chassis-seal-source-scope-attestation-v1` stopped before reviewer launch in run `20261107T172009Z-95b97875a887`, claim `20261107T172038Z-f5f7b6f1d140`, with `archive-only landing contains unrelated paths`. Exact landing `7e1458d13a93619db4631d54b1ef217412b6d34e` has sole parent `dc48e1e9e8511abe160aad266ed44493f11e8666`, tree `d3c79bda78283b2ecd17b0ce4b2088fa47d278de`, and is an ancestor of pinned main `0d074c73343a4695994b01d545f5cbf96e5d54c2`. The sole rejected path is `custodian/docs/ai_context/task_packets/REVIEW_AGENT_OPERATOR_CHASSIS_SEAL_SOURCE_SCOPE_ATTESTATION_V1.md`, mode `100644`, blob `715b2551122294eb3451165a2ea88ceceaf3e97e` before and `c252ea91434bff599ad5dee6d2dd2ad92ac43733` after. Its only content change converts separators in `Publication inputs` from commas to semicolons. An archived packet with a related but different canonical authoring-chat exception exists; no packet covers these exact identities.
- Evidence: Git objects for landing, parent and packet blobs above; failed host-validation run/claim above; exact preserved worktree and report under `.git/custodian-review-runs/review-agent-operator-chassis-seal-source-scope-attestation-v1/20261107T172009Z-95b97875a887/`. Existing analogous implementation: `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_CANONICAL_METADATA_SOURCE_SPAN_V1.md` (different archive, path, and byte transition; use only as design precedent).
- Task-specific authority: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; archived implementation packet `custodian/docs/ai_context/task_packets/archived/AGENT_OPERATOR_CHASSIS_SEAL_SOURCE_SCOPE_ATTESTATION_V1.md`; active held review packet `custodian/docs/ai_context/task_packets/REVIEW_AGENT_OPERATOR_CHASSIS_SEAL_SOURCE_SCOPE_ATTESTATION_V1.md` (read-only); `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`. Do not edit either chassis-attestation packet, its archived source commit, the held review worktree/run/claim/evidence, or the original chassis-seal review.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/task_packet_contract.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/agent/review_receipt_delta.py`; `custodian/tools/agent/review_receipt.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/validation/validation_manifest.json`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/TASK_PACKET_CATEGORIES.json`; `custodian/docs/ai_context/task_packets/README.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_CANONICAL_METADATA_SOURCE_SPAN_V1.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_OPERATOR_CHASSIS_SEAL_SOURCE_SCOPE_ATTESTATION_V1.md`; `custodian/docs/ai_context/task_packets/REVIEW_AGENT_OPERATOR_CHASSIS_SEAL_SOURCE_SCOPE_ATTESTATION_V1.md`.
- Change: Add a dedicated verifier for exactly the historical review-packet metadata transition identified above. Require the exact target implementation workstream and archived packet, exact review packet path and identity, exact landing/parent/tree, regular `100644` mode, and exact before/after Git blob IDs. Verify the only byte change is the existing comma-to-semicolon normalization of the `Publication inputs` list, with the exact path sequence and values unchanged. Admit only this exact Markdown path as paired-review metadata and keep it out of implementation/source paths. Keep all general undeclared-path checks, packet Work surface checks, source-code ownership rules, and accepted-review gates unchanged.
- Preserve: The current held chassis-attestation review run, claim, lock, worktree and reports; the original chassis-seal review's claim, lock, worktree, source history, evidence and no-verdict status; current main and all other source-scope exceptions; exact original implementation packet Work surface; the chassis attestation's requirement for this correction's own accepted independent PASS.
- Non-goals: No generic review-Markdown allowlist; no suffix, prefix, filename-only or caller-supplied path permission; no retroactive edit or expansion of archived packets; no activation of the original chassis attestation; no retry/bypass of the held review's failed report; no original reviewer launch or recovery apply; no gameplay, asset, or Operator runtime change.
- Acceptance: (1) `resolve_validation_source_span()` resolves the actual `7e1458d...` archive on its exact `dc48e1...` parent and pinned `0d074c...` main. (2) The exact review Markdown file is authenticated by path, mode, source archive identity, packet identity, and both pinned blobs, then excluded from implementation source ownership. (3) The archive retains only its declared validator/test files and predecessor-declared attestation JSON as source-owned paths; the paired-review Markdown never enters implementation ownership, and unrelated `.md` paths remain rejected. (4) Real-Git adversarial tests reject a changed parent/landing/tree, wrong path/workstream/target packet, wrong mode, either changed blob, any byte edit beyond the exact delimiter normalization, changed/reordered Publication input paths, extra changed paths, and a substitute review packet. (5) Existing canonical metadata tests and all source-scope/attestation tests remain unchanged in behavior. The original chassis review still rejects `custodian/tools/agent/test_workstream.py` before its separate attestation receives accepted PASS. (6) The held review run/claim/evidence remains byte-identical and no reviewer launches during this correction. (7) After this correction and its fresh paired review receive authenticated PASS, use the held run's same-claim `--recover-host-validation --plan` only; record the plan and stop before `--apply` or reviewer launch.
- Validation: Actual historical `resolve_validation_source_span()` positive against the pinned archive; actual Git negative mutations for path/blob/mode/identity/extra-field/extra-path cases; existing canonical metadata and chassis-attestation adversarial suites; `python3 -m unittest custodian.tools.agent.test_paired_review_runner`; `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json` with complete coverage; `python3 -m py_compile custodian/tools/agent/paired_review_host_validation.py custodian/tools/agent/test_paired_review_runner.py`; `python3 custodian/tools/agent/task_packet_index.py`; `git diff --check`. Do not run a host-validation recovery plan before the correction's accepted paired-review PASS.
- Task overrides: `none`
- Deferred: Once the correction lands and its independent pair is accepted, the correction paired-review lifecycle may generate the preserved run's read-only host-validation recovery plan for run `20261107T172009Z-95b97875a887`. Stop after reporting the exact plan and SHA-256. A separate next authorization is required before apply or reviewer launch.

## Handoff
- Next workstream: `review-agent-paired-review-chassis-metadata-source-scope-v1`
- Next packet state: `ready/auto after archive`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aef1f35-9d0c-83ea-9916-59c5660da5fd
- Refresh reason: `none`
- Next action: Claim `review-agent-paired-review-chassis-metadata-source-scope-v1` after this implementation archives; independently review the exact-history verifier and actual-Git evidence. Only after accepted PASS, prepare the preserved held run's same-claim read-only recovery plan.
- Blockers or open questions: The prior chassis-attestation review remains claimed in host-validation recovery until this correction's accepted paired review and the next control.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Evidence: Exact-history positive and adversarial tests; paired-review runner suite 303/303; changed-file validation passed 3/3 with complete coverage; py_compile, packet authoring/category/index, and `git diff --check` passed.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: `The existing chassis-attestation approval fixtures assumed their predecessor packet remained active on current main after it had been archived. The first full-suite run exposed four failures in those fixtures.`
- Root cause / contributing factors: `The fixture base followed moving HEAD instead of the exact pre-landing commit required to reconstruct the synthetic lifecycle.`
- Prevention / pipeline improvement: `Pin history-sensitive lifecycle fixtures to the exact source archive parent and reconstruct the intended active packet state explicitly.`
- Tooling / docs drift discovered: `No tooling defect; this exact archive-bound fixture assumption was not documented.`

## Independent Review

### Review Receipt: review-agent-paired-review-chassis-metadata-source-scope-v1
- Schema: `custodian.paired_review.v1`
- Review workstream: `review-agent-paired-review-chassis-metadata-source-scope-v1`
- Review target workstream: `agent-paired-review-chassis-metadata-source-scope-v1`
- Status: `passed`
- Blocking defects: `0`
- Material gaps: `0`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Reviewed main: `ab22bda8d66bcd123c23ca5cd4f16d08ae3fd394`
- Reviewed implementation commit: `ab22bda8d66bcd123c23ca5cd4f16d08ae3fd394`
