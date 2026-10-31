# Paired-review redacted final-outcome recovery

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-redacted-final-outcome-recovery-v1`
- Category: `agent-ops`
- Status: `complete`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `agent-paired-review-redacted-final-outcome-recovery`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-redacted-final-outcome-recovery-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: The change can administratively close a protected independent review, so exact-run identity, immutable evidence, capture transformation, claim/remote state, and a fresh independent review are required.
- Reviewed main: `09b09ee30727242f69c0d6aeb617b97795f9868a`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae29a85-767c-83ea-90bd-eebcc4b1f086
- Visual review: `none`
- Goal: Provide a safe, auditable way to recover an exact paired-review run when its operational JSONL redacts and truncates a long final message but the separately saved final message and independent review artifacts remain consistent.
- Completion boundary: Add a read-only exact-run recovery plan and a separate, explicitly authorized apply path to the paired-review runner. The apply may add a clearly coordinator-authored administrative outcome only after every pinned artifact and identity check succeeds. Implementation and paired review do not apply recovery to any protected run.
- Current measured state: At `09b09ee30727242f69c0d6aeb617b97795f9868a`, `paired_review_runner.safe_output()` sanitizes string values in JSONL records through `workflow_control.redact()`; that function defaults to 1,200 characters and slices `text[:limit]`. For run `review-agent-paired-review-closeout-coverage-policy-v1/20261030T162106Z-5f26233f5cdb`, the last `agent_message` is exactly 1,200 characters and equals the output of the pinned transformation applied to the saved `last-message.txt`. The original files have SHA-256 `86b4d0df00f145dfada677a299162bda5a39872aefc37f07611df8216059f51f` (`codex.jsonl`) and `ff8851fa3fabc89a42c8a90c7620d8eec8d3ff7d25254368dba1343ca49d1882` (`last-message.txt`). One reviewer turn started and completed; the run is fresh and exited 0. The reviewer-authored target receipt and summary say `passed`; host validation is 4/4 with zero failures, timeouts, skips, or infrastructure errors. The canonical archived review outcome is missing, so the runner remains in `post_exit_recovery`. The exact run evidence is host-private under Git common-dir workflow state and must be revalidated locally before any later apply.
- Evidence: `custodian/tools/agent/paired_review_runner.py` (`safe_output`, `recover-closeout`); `custodian/tools/agent/workflow_control.py` (`redact`); `custodian/tools/agent/review_outcome.py`; `custodian/tools/agent/review_receipt_delta.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; exact-run metadata, claim receipt, validation report, `codex.jsonl`, and `last-message.txt` identified above. Existing exact-run recovery precedents are not transferable to this run unless their workstream/run identity matches.
- Task-specific authority: Root `AGENTS.md` atomic task-packet publication, workstream, and independent-review policies; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/AGENT_PAIRED_REVIEW_FINISH_INDEX_CODEX_EXITED_PASS_RECOVERY_V1.md`; `custodian/docs/ai_context/AGENT_PAIRED_REVIEW_MISSING_ARCHIVED_DISPOSITION_CONTINUATION_V1.md`.
- Work surface: Primary owner `custodian/tools/agent/paired_review_runner.py`; tests in `custodian/tools/agent/test_paired_review_runner.py`; canonical outcome and receipt validation in `review_outcome.py` and `review_receipt_delta.py`; claim, run, and host evidence verification in `workflow_control.py` and `paired_review_host_validation.py`.
- Publication inputs: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/workflow_control.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/agent/review_receipt_delta.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/dispatch.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/validation/validation_manifest.json`; `custodian/tools/agent/test_review_outcome.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_PAIRED_REVIEW_FINISH_INDEX_CODEX_EXITED_PASS_RECOVERY_V1.md`; `custodian/docs/ai_context/AGENT_PAIRED_REVIEW_MISSING_ARCHIVED_DISPOSITION_CONTINUATION_V1.md`.
- Change:
  1. Add a read-only plan bound to the exact review workstream, run ID, claim run ID, reviewed-main SHA, reviewer branch/worktree, target implementation commit, original reviewer artifact paths, and current remote refs. Emit a canonical plan digest and all inspected file hashes; do not edit, stage, or normalize reviewer evidence.
  2. Verify the exact capture transformation associated with the run's pinned source version. For this supported redaction format, compare the final JSONL `agent_message` byte-for-byte with the deterministic sanitized/truncated representation of `last-message.txt`. Reject unknown source versions, missing source identity, arbitrary prefixes, and any nonmatching transformation.
  3. Independently validate one completed reviewer turn, fresh-session metadata, claim receipt identity, implementation/source-span identity, target PASS receipt, reviewer summary, host-validation report and digest, and all related run evidence. Search all captured messages and reports for contradictory findings, errors, or another verdict. Confirm the missing canonical archived outcome is the only unresolved acceptance artifact.
  4. Add a separate apply requiring explicit `--apply` plus the exact plan SHA-256. Recompute every file hash, claim identity, local/remote ref, and lock condition immediately before writing. Abort on any change or uncertainty.
  5. Preserve original reviewer files byte-for-byte. Add only the missing canonical administrative outcome and necessary lifecycle metadata through existing outcome/receipt/finish authorities. Label the record as coordinator-authored recovery, identify the original reviewer-authored PASS receipt separately, and bind the administrative record to the plan digest and evidence hashes. Never alter reviewer-authored words or represent a coordinator statement as reviewer text.
  6. Journal a bounded, fail-closed, idempotent recovery. Reject replay with a different plan, duplicate outcomes, unexpected files, symlinks/path escape, wrong claim/run/target, wrong branch or reviewed commit, changed remote refs, missing coverage, bad receipt, contradictory PASS/findings, tampered output, or an unapproved truncation rule.
  7. Route successful closeout through the canonical workstream finish and landing verification. Do not release a claim or lock unless the existing canonical finish gate independently succeeds.
- Preserve: All original run directories and reviewer evidence; reviewer-authored receipt, summary, and message bytes; implementation and paired-review identities; existing claims, branches, worktrees, locks, and historical reports; normal canonical outcome and finish gates.
- Non-goals: Apply recovery to run `20261030T162106Z-5f26233f5cdb` or any other run; accept the review in this implementation task; launch a reviewer for either held review; release or park either protected claim/lock; change the original capture files; weaken generic review acceptance; create a new verdict from host validation alone.
- Acceptance:
  1. Plan mode is read-only and emits a stable exact-run digest over all relevant evidence and identities.
  2. The pinned `safe_output()` transformation exactly explains the known 1,200-character event; a raw prefix alone, altered sanitizer, unknown source, or tampered final file fails closed.
  3. PASS recovery requires corroborating reviewer receipt and summary, matching target/claim/run/source-span identities, valid completed session metadata, passing host validation, no contradictory session evidence, and the canonical outcome being the sole missing acceptance artifact.
  4. Apply requires an explicit exact plan digest and rejects any post-plan file, lock, claim, or remote-ref change before mutation.
  5. Original reviewer-owned artifacts remain byte-identical after apply; administrative provenance is clearly distinguished and cannot be mistaken for reviewer authorship.
  6. Apply is bounded and idempotent; replay is safe and any conflicting replay or repeated outcome fails.
  7. Negative regression tests reject forged/replayed/contradictory PASS, edited `last-message.txt`, mismatched transformation, unapproved truncation, wrong run/claim/branch/target, missing evidence/coverage, changed remote refs, lock changes, path escape, and incomplete or repeated reviewer turns.
  8. No recovery apply, new reviewer launch, claim release, or lock release occurs during implementation or its paired review.
- Validation: Run focused unit tests for recovery-plan/apply and existing `test_paired_review_runner.py`, `test_review_outcome.py`, and `test_paired_review_findings_closeout.py`; run the canonical changed-file validation from `custodian/tools/validation/run_validation.py --changed --base <implementation-parent> --json`; run `git diff --check`; run targeted task-packet authoring and category checks before publication. Paired review reruns the focused suites, inspects every negative test, checks changed-file coverage and commit identity, and proves the existing closeout paths remain unchanged.
- Task overrides: `none`
- Deferred: Applying a verified plan to the protected run requires a later matching coordinator control after this implementation lands and its fresh independent paired review passes. The original host-private evidence owner must run the plan against the preserved Git-common-dir run directory; if that evidence is missing or differs, stop without recovery.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `paired_review_runner.py` provides a source-pinned exact capture transform, exact-run read-only plan, and SHA-256-bound separately authorized apply with strict journal validation. The 12 `RedactedFinalCaptureTests` cover exact transformation, the actual supported reviewer PASS form, claim/run identity, symlink/path safety, tampering, changed refs, and replay. The protected run's read-only plan reproduced the 1,200-character JSONL event exactly and preserved all original run hashes. Changed-file validation passed both selected groups with complete coverage; no protected recovery apply or reviewer launch occurred.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: The required combined runner/outcome/closeout unittest invocation exposed one pre-existing closeout assertion mismatch. The same failure reproduces on clean `origin/main`: the fixture expects a later receipt-delta error, while coordinator verification correctly stops earlier because the fixture metadata does not authenticate a pinned PASS. The packet's canonical changed-file validation passed all selected tests.
- Root cause / contributing factors: The unrelated closeout test fixture and expected error message have drifted from the current coordinator gate order.
- Prevention / pipeline improvement: Update that fixture or expected predicate in a separately scoped test-maintenance change; it was left untouched here to keep this implementation's work surface bounded.
- Tooling / docs drift discovered: none
- Follow-up: `manual-follow-up`
- What worked: The read-only plan was exercised against the exact protected run without mutating its artifacts, and its recorded claim run ID and original file hashes matched the preserved evidence.

## Handoff
- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae29a85-767c-83ea-90bd-eebcc4b1f086
- Summary backlink: include the exact Authoring chat URL in every durable summary and final Next Handoff
- Refresh reason: `none`
- Next action: After implementation and fresh paired review land, await separate authorization before planning or applying recovery to any protected run.
- Blockers or open questions: The exact target run's files are host-private, immutable prerequisites for any later plan/apply and must be verified at the owner-controlled host.
