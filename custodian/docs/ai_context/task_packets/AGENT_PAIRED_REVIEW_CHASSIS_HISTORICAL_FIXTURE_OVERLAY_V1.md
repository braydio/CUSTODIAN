# Historical Chassis Fixture Overlay V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-chassis-historical-fixture-overlay-v1`
- Category: `agent-ops`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `review-agent-paired-review-chassis-metadata-source-scope-v1`
- Locks: `paired-review-chassis-historical-fixture-overlay-v1, paired-review-runner-tests`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, workflow`
- Paired review workstream: `review-agent-paired-review-chassis-historical-fixture-overlay-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `A temporary test-only overlay participates in trusted paired-review host validation and must be independently checked for exact identity binding, confinement, and source preservation.`
- Reviewed main: `19661bc02ad8825451c4d5e3b21886d0744ab5b3`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aef1f35-9d0c-83ea-9916-59c5660da5fd
- Visual review: `none`
- Goal: Let the preserved chassis-attestation review's canonical host validation run its four historical approval-fixture tests by repairing one obsolete fixture base only inside a disposable validation checkout.
- Completion boundary: Extend the existing exact historical Procession fixture-overlay mechanism for one chassis-attestation identity. Authenticate reviewed main `0d074c73343a4695994b01d545f5cbf96e5d54c2`, target workstream `agent-operator-chassis-seal-source-scope-attestation-v1`, target packet `custodian/docs/ai_context/task_packets/archived/AGENT_OPERATOR_CHASSIS_SEAL_SOURCE_SCOPE_ATTESTATION_V1.md`, implementation archive `7e1458d13a93619db4631d54b1ef217412b6d34e`, and test blob/mode `228a2bd55666f9a0d110493d47a8a70024ea9d13` / `100644`. Replace the exact dynamic-HEAD fixture expression in `_build_operator_chassis_scope_approval_history` with pre-archive parent `dc48e1e9e8511abe160aad266ed44493f11e8666` only in the disposable validation checkout. The held review's remaining recovery attempt is not consumed by this implementation.
- Current measured state: Preserved held review `review-agent-operator-chassis-seal-source-scope-attestation-v1`, run `20261107T172009Z-95b97875a887`, claim `20261107T172038Z-f5f7b6f1d140`, is at `host_validation_failed` after its one authorized continuation. Immutable continuation report SHA-256 is `cd5c56d84f59849380c45fba3ec2cd4a3cd6ccfe9030390154dd1a232901abba`; 3/4 validation entries passed. Four tests fail because the pinned test fixture expects an active correction packet although pinned reviewed main already has the packet archived. The accepted metadata-source-scope correction and its fresh paired review are complete on main at `19661bc02ad8825451c4d5e3b21886d0744ab5b3`.
- Evidence: Exact pinned test blob and mode above; original held run/claim metadata under `.git/custodian-review-runs/review-agent-operator-chassis-seal-source-scope-attestation-v1/20261107T172009Z-95b97875a887/`; previous accepted overlay precedent in `paired_review_host_validation.py` and `test_paired_review_runner.py`; Chat authorization in the Authoring chat.
- Task-specific authority: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/test_paired_review_runner.py`; active held review packet `custodian/docs/ai_context/task_packets/REVIEW_AGENT_OPERATOR_CHASSIS_SEAL_SOURCE_SCOPE_ATTESTATION_V1.md` (read-only); archived implementation packet `custodian/docs/ai_context/task_packets/archived/AGENT_OPERATOR_CHASSIS_SEAL_SOURCE_SCOPE_ATTESTATION_V1.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`.
- Publication inputs: `AGENTS.md`; `custodian/AGENTS.md`; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/TASK_PACKET_CATEGORIES.json`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/validation/validation_manifest.json`; `custodian/docs/ai_context/task_packets/archived/PROCESSION_TEST_FIXTURE_REPAIR_V1.md`; `custodian/docs/ai_context/task_packets/REVIEW_PROCESSION_TEST_FIXTURE_REPAIR_V1.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_CHASSIS_METADATA_SOURCE_SCOPE_V1.md`; `custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_PAIRED_REVIEW_CHASSIS_METADATA_SOURCE_SCOPE_V1.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_OPERATOR_CHASSIS_SEAL_SOURCE_SCOPE_ATTESTATION_V1.md`; `custodian/docs/ai_context/task_packets/REVIEW_AGENT_OPERATOR_CHASSIS_SEAL_SOURCE_SCOPE_ATTESTATION_V1.md`.
- Change: Extend the existing `_expected_validation_fixture` and disposable validation-checkout mechanism. Pin the exact review/implementation identity and original test blob/mode; isolate the target method; require the original dynamic-HEAD snippet exactly once; replace only that snippet with the literal pre-archive parent; record original and repaired file hashes, exact identities, and protected-checkout preservation; require the temporary diff to contain exactly the test file. Carry the authenticated overlay evidence through host-validation creation and verification. Keep the existing Procession fixture case unchanged.
- Preserve: The pinned reviewed source tree, original test blob and source history; held run, claim, worktree, reports and evidence; the immutable failed continuation-01 report; Procession overlay behavior; all source ownership, review and host-validation gates; false operator-attestation fields; remaining recovery retry.
- Non-goals: No edits to the held review checkout or original run; no recovery apply/retry or reviewer launch; no test skip/xfail or validation bypass; no broad source or fixture overlay; no runtime changes; no mutation of the historical commit or test blob.
- Acceptance: (1) Only the exact reviewed-main, target workstream, target packet and implementation archive identity activates the overlay. (2) The test path must be the regular `100644` file with exact blob `228a2bd55666f9a0d110493d47a8a70024ea9d13`; altered blob/mode and any identity substitution fail closed. (3) Only `_build_operator_chassis_scope_approval_history` receives the exact one-snippet replacement to `dc48e1e9e8511abe160aad266ed44493f11e8666`; missing, duplicate or changed source bytes fail closed. (4) The temporary checkout's diff contains exactly `custodian/tools/agent/test_paired_review_runner.py`; original protected checkout bytes/status remain unchanged and hashes are recorded. (5) All four named chassis attestation tests pass using the pinned historical source plus the overlay, without changing original source or historical review evidence. (6) The original chassis attestation remains inactive before its own accepted independent review; Procession overlay tests and behavior remain unchanged. (7) Actual-history coordinator validation runs in a new disposable evidence directory, not the held run directory; canonical changed validation and complete paired-review runner suite pass. (8) After this implementation's fresh independent PASS, prepare a new read-only recovery plan for the held review and stop; any subsequent apply, remaining retry, or reviewer launch requires separate authorization.
- Validation: Add focused real-Git positive and adversarial overlay tests; run the four named historical chassis tests in the temporary checkout; preserve and run the existing Procession overlay tests; execute actual-history `run_coordinator_validation` in a new disposable run directory and inspect its authenticated overlay report; run `PYTHONPATH=custodian/tools/agent:custodian/tools python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`; run `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json` with complete coverage; run paired-review pairing/category checks, `py_compile`, and `git diff --check`.
- Task overrides: `none`
- Deferred: After implementation and its independent paired review pass, generate only the held review's new read-only recovery plan and return it to the Authoring chat. Do not apply it in this workstream.

## Handoff

- Next workstream: `review-agent-paired-review-chassis-historical-fixture-overlay-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aef1f35-9d0c-83ea-9916-59c5660da5fd
- Refresh reason: `none`
- Next action: Claim after dependency and both shared locks clear; implement, run the exact historical disposable fixture proof, and finish through the workstream lifecycle.
- Blockers or open questions: The active Procession fixture review currently holds `paired-review-runner-tests`; the preserved chassis review holds `paired-review-source-provenance`. Do not claim until dispatch confirms both locks are free.
