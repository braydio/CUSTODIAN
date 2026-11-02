# CORRECTION: R0-01 Independent Consumer Inherited-Main Real-Git Proof

- Packet schema: custodian.task_packet.v2
- Authoring handoff: auto
- Workstream: agent-workstream-inherited-main-resume-provenance-v1-review-corrections-1
- Category: agent-ops
- Kind: correction
- Status: `ready`
- Dispatch: `auto`
- Priority: P0
- Depends on: review-agent-workstream-inherited-main-resume-provenance-v1
- Locks: workstream-source-span-provenance
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, workflow
- Paired review workstream: review-agent-workstream-inherited-main-resume-provenance-v1-review-corrections-1
- Review cycle: 1
- Max automatic review cycles: 1
- Review rationale: Independently validating the new inherited-main consumer classification and source-inventory exclusion is required before accepting the prior provenance fix or attempting the protected summary-rename finish. A single fresh post-land review is specifically user-authorized, not an extension of the exhausted automatic loop.
- Reviewed main: 9c9fb5c29c97c84d142184af7dfa6d2f41b52df7
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae73140-7bb8-83e8-8a42-705d683aa2fb
- Visual review: none
- Parent implementation: agent-workstream-inherited-main-resume-provenance-v1; custodian/docs/ai_context/task_packets/archived/AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1.md; landed 40b8126d6abdd57d36528b7e7f8efd68df2e88f6.
- Parent review: review-agent-workstream-inherited-main-resume-provenance-v1; custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1.md; nonpassing canonical findings/R0-01 landed 9c9fb5c29c97c84d142184af7dfa6d2f41b52df7.
- Findings addressed: R0-01
- Affected acceptance: Parent implementation acceptance requires independently reproducible real-Git positive/adversarial consumer evidence: clean first-parent main-inherited resume merges excluded from owned source/test paths, genuine authored source retained, and forged/mismatched/out-of-boundary resume histories rejected; checkpoint-resume, sync and after-sync checks must remain fail-closed.
- Current defect/evidence: The original independent review documented zero focused real-Git consumer fixtures exercising the new inherited-main classification branch or its authored-path exclusion; producer fixture(s) exist and broad consumer suite passed 274/274, but that alone does not establish the consumer branch contract. The reviewer did not reproduce a source-provenance bypass. Prior verdict and finding are immutable.
- Goal: Close R0-01 with focused, reproducible real-Git tests of the independently authoritative inherited-main consumer source-span classification, without changing production validation logic unless one of those tests proves an actual defect.
- Completion boundary: Add the smallest coherent consumer real-Git fixture and positive/adversarial matrix under test_paired_review_runner.py; retain all existing test coverage; validate full producer/consumer suites and canonical changed-file checks; land this correction and canonically retire its own checkout. Its separately paired review determines acceptance afterward. This packet does not retroactively convert the original findings review to PASS.
- Current measured state: On main 9c9fb5c29c97c84d142184af7dfa6d2f41b52df7, implementation and original review are both archived complete; original review outcome is findings/R0-01; test_paired_review_runner.py contains checkpoint-resume and other historical real-Git fixtures but no focused coverage for provenance.inherited_main_merges. Implementation suite last reported 89/89 PASS; consumer suite 274/274 PASS; review host validation 9/9 PASS. The protected original summary-rename workstream remains claimed, with source 5724273819d885a514dda94fa9bc4693137018b9 and no authorized finish.
- Evidence: custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1.md; REVIEW_AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1_CLAUDE_SUMMARY.md; custodian/docs/ai_context/task_packets/archived/AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1.md; AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1_CLAUDE_SUMMARY.md; source commit acc88b8585361c2a075f4f63499629bf0f22b168; correction landing 40b8126d6abdd57d36528b7e7f8efd68df2e88f6; exact parent review landing 9c9fb5c29c97c84d142184af7dfa6d2f41b52df7; host-private validation/trace reports remain with their original owners and may be read but never altered.
- Task-specific authority: AGENTS.md; custodian/AGENTS.md; custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md; custodian/docs/ai_context/task_packets/archived/AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1.md; custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1.md; custodian/docs/ai_context/AGENT_CORRECTION_PACKET_TEMPLATE.md; custodian/docs/ai_context/reports/RETIREMENT_CAMPAIGN_CREATION_EXCEPTION_20261101.md. This pair is the one explicit human-authorized exception after the parent zero-cycle review cap; no other correction cycle is authorized.
- Work surface: custodian/tools/agent/test_paired_review_runner.py (primary, expected only source/test change); custodian/tools/agent/paired_review_host_validation.py (read-only consumer contract, conditional minimal fix only upon demonstrated reproducible failing test); custodian/tools/agent/test_workstream.py and custodian/tools/agent/workstream.py (read-only producer/regression references); canonical root closing summary AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/test_workstream.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/validation/validation_manifest.json`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/AGENT_CORRECTION_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1.md`; `custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1.md`; `AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1_CLAUDE_SUMMARY.md`; `REVIEW_AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1_CLAUDE_SUMMARY.md`; `custodian/docs/ai_context/reports/RETIREMENT_CAMPAIGN_CREATION_EXCEPTION_20261101.md`; `custodian/docs/ai_context/TASK_PACKET_CATEGORIES.json`; `custodian/tools/agent/validate_task_packet_authoring.py`; `custodian/tools/agent/check_packet_categories.py`; `custodian/tools/agent/validate_review_pairing.py`; `custodian/tools/agent/task_packet_index.py`
- Required correction:
  1. Use an isolated disposable real-Git repository, not mocked booleans, to construct a clean original claim, an upstream two-parent main first-parent merge that changes a distinguishable upstream-only path, an exact same-run clean resumed HEAD, later authored code/test path(s), and a canonical source-bearing archived correction/implementation landing. Authenticate trace identity and actual Git object lineage using the existing fixture builders where possible.
  2. Directly call paired_review_host_validation.resolve_validation_source_span() in the positive case. Assert provenance.inherited_main_merges contains the exact authenticated merge, correct ordered parents/tree and resume event; assert returned authored source/test paths contain every genuine task-owned path and exclude the upstream-only path. Do not prove the behavior solely by testing the producer, a stub, or a broad end-to-end exit code.
  3. Mutate real objects/refs/events in separate negative subtests: missing, forged, wrong-run, wrong-worktree, wrong-branch, duplicated/reordered and conflicting resume; merge absent from reviewed-main first-parent; altered deterministic merge tree or parents; uncheckpointed locally authored merge misrepresented as inherited; locally unique pre-resume source or extra undocumented path; tampered checkpoint event that must not reclassify into inherited; changed after-sync/source identity. Every mutation must be rejected for the intended trust boundary. If a different earlier fail-closed gate fires, prove it validates the manipulated identity, not an incidental fixture failure.
  4. Retain and execute valid legacy checkpoint/resume and witnessed main_sync positive cases, historical source-bearing/archived review, RC-119, preflight parity and changed-source validation. Do not remove or dilute previous 274 consumer or 89 producer tests to make this correction green.
  5. Test first: if a new negative case is accepted when it should reject, retain a failing-first reproduction and propose the smallest possible fix ONLY in paired_review_host_validation.py within the inherited-main consumer gate. If the change would need workstream.py, dispatch, trace schema, reviewer runner behavior, or another production authority, STOP and report the precise boundary. Do not silently expand this packet or fabricate provenance evidence.
  6. Preserve one-to-one R0-01 evidence mapping, exact baseline source/trace and prior review verdict, and do not edit inherited-main original implementation/archived review history. Report fixture cases, negative rejection reasons and source inventory. Record material task feedback and documentation drift only when a concrete active statement became false.
- Preserve: Parent archived implementation and nonpassing review evidence, all previous checkpoint/resume/first-parent/after-sync gates, source ownership, original summary-rename claim/lock/checkout/source, persistent dirty coordination root, external W1/Agent Wire/Operator/Sepulcher claims, dispatcher policy and automatic reviewer independence.
- Non-goals: A second provenance architecture change; broad source-span refactor; model/asset production; new background workers; reopening the previous review; retroactive PASS; private trace rewriting; new packet/third review or automatic corrections; worktree GC/process-visibility repair; replacing the protected summary-rename claim.
- Acceptance:
  - R0-01 positive fixture returns exact inherited merge provenance, excludes every upstream-only path, includes every task-authored source/test path, and uses independently validated immutable Git objects.
  - R0-01 adversarial matrix rejects forged/reordered/duplicated identity and resume records, non-first-parent main history, altered merge tree/parents, locally unique source, hidden authored merge, checkpoint tampering, undocumented paths and stale source/after-sync evidence. Each case has a named reproducible test and explicit assertion.
  - Legacy checkpoint/resume positive and adversarial suites plus protected historical RC-119 and archive-first behavior continue passing; test counts do not fall below the prior consumer 274 and producer 89 without documented unrelated baseline change.
  - Production consumer and producer are byte-identical unless a real failing-first security/correctness test proves a defect within the narrow consumer scope; any conditional production edit has a reproduced failure, exact delta and complete adversarial regression.
  - Full consumer and producer suites pass, plus canonical changed-file validation of the final committed source and required AI-context, category, authoring, pairing, managed-index and diff checks. No unexpected skips/failures/timeouts/infra errors, source_changed_during_validation=false and complete coverage. Record full source/tree/status and SHA256 reports.
  - Correction archives with truthful Completion Truth, closing summary backlink, canonical finish and teardown; independently paired review alone may establish later acceptance. Prior findings review stays unchanged.
- Validation:
  - PYTHONPATH=custodian/tools/agent:custodian/tools python3 -m unittest custodian.tools.agent.test_paired_review_runner -v
  - python3 -m unittest custodian.tools.agent.test_workstream -v
  - python3 -m py_compile custodian/tools/agent/test_paired_review_runner.py custodian/tools/agent/paired_review_host_validation.py
  - python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json
  - python3 custodian/tools/agent/check_ai_context.py --json
  - python3 custodian/tools/agent/check_packet_categories.py
  - python3 custodian/tools/agent/validate_task_packet_authoring.py custodian/docs/ai_context/task_packets/AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1_REVIEW_CORRECTIONS_1.md custodian/docs/ai_context/task_packets/REVIEW_AGENT_WORKSTREAM_INHERITED_MAIN_RESUME_PROVENANCE_V1_REVIEW_CORRECTIONS_1.md
  - python3 custodian/tools/agent/validate_review_pairing.py
  - python3 custodian/tools/agent/task_packet_index.py
  - git diff --check
- Task overrides: none
- Deferred: Future clean-root coordination-sync and optional GC/path import defects belong to their own owners; no unrelated work in this exception.

## Handoff

- Next workstream: review-agent-workstream-inherited-main-resume-provenance-v1-review-corrections-1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae73140-7bb8-83e8-8a42-705d683aa2fb
- Refresh reason: none
- Next action: Only after this correction is landed, archived complete and canonically torn down may the previously published paired review be claimed in a fresh independent context. Do not resume summary-rename solely on this correction landing.
- Blockers or open questions: Original review findings are immutable. If an adversarial test exposes an out-of-scope production flaw, halt for a separate explicit user decision rather than widening the authorized work.
