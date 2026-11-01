# Inherited-Main Resume Provenance: Canonical Finish Correction

- Packet schema: custodian.task_packet.v2
- Authoring handoff: auto
- Workstream: agent-workstream-inherited-main-resume-provenance-v1
- Category: agent-ops
- Status: draft
- Dispatch: manual
- Priority: P0
- Depends on: none
- Locks: workstream-source-span-provenance
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, workflow
- Paired review workstream: review-agent-workstream-inherited-main-resume-provenance-v1
- Review cycle: 0
- Max automatic review cycles: 0
- Review rationale: A canonical finish currently rejects an inherited upstream merge as an unwitnessed workstream-authored sync. Because this is an acceptance and teardown authority, both producer and independent paired-review consumer need adversarial real-Git verification in a fresh context.
- Reviewed main: 0e5da248e93f0395f084f0abb7feba8285132bc0
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae73140-7bb8-83e8-8a42-705d683aa2fb
- Visual review: none
- Goal: Allow canonical finish and paired host review to distinguish exactly authenticated upstream first-parent history inherited through a clean workstream resume from synchronization authored by that workstream, without adding a source-scope or review bypass.
- Completion boundary: Correct the source-span provenance authority and its read-only preflight in the existing workstream lifecycle, independently align the paired-review host consumer, validate against real-Git positive and adversarial cases, land and tear down only this correction via canonical finish, then obtain a separate independent review. This task does not finish or alter the protected summary-rename workstream itself.
- Current measured state: The protected original summary-rename claim/run 20261101T155437Z-d8cfaa2f3336 has committed clean source 5724273819d885a514dda94fa9bc4693137018b9 and a green source-bound 9/9 validation report. Its first finish attempt stopped before checkpoint/synchronization because workstream.py::_source_span_sync_merge_witness_error requires an exact checkpoint for inherited upstream merge 38545e4c12b848861284d77c299790c046df6f62. The original claim base is 878009b2ba90e801b3d20a4abd675732e51f137a; matching recorded clean resumes ended at 0aee8bf0450dcb7368196201f731f45b0f4cd3d9 and 8bc0fe40184dec741ccc5a92997052f96e0deb43. The producer preflight had reported ready_before_sync=true, blockers=[] before this failure. That workstream remains claimed, locked and attached; no landing or teardown occurred.
- Evidence: Current workstream.py source-span witness validator and resume/sync_main behavior; paired_review_host_validation.py source-span verification; protected original run trace and finish diagnostic ref on the operator's Arch host; AGENT_WORKSTREAM_LIFECYCLE.md resume/claim provenance guidance; archived AGENT_PAIRED_REVIEW_CHECKPOINT_RESUME_MERGE_PROVENANCE_V1 and PAIRED_REVIEW_RESUMED_WORKTREE_PROVENANCE_V1 as precedents, not automatic authority. The source 57242738 and host-private run reports are not currently part of main and must be verified in place, never represented as published inputs.
- Task-specific authority: AGENTS.md; custodian/AGENTS.md; custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md; custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md; custodian/docs/ai_context/task_packets/README.md; custodian/docs/ai_context/reports/RETIREMENT_CAMPAIGN_CREATION_EXCEPTION_20261101.md.
- Work surface: custodian/tools/agent/workstream.py (source-span producer and read-only preflight); custodian/tools/agent/paired_review_host_validation.py (independent consumer); custodian/tools/agent/test_workstream.py; custodian/tools/agent/test_paired_review_runner.py; custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md. Source/test/document changes only where needed for this single provenance distinction.
- Publication inputs: custodian/tools/agent/workstream.py; custodian/tools/agent/paired_review_host_validation.py; custodian/tools/agent/test_workstream.py; custodian/tools/agent/test_paired_review_runner.py; custodian/tools/agent/workflow_control.py; custodian/tools/agent/dispatch.py; custodian/tools/agent/task_packet_contract.py; custodian/tools/agent/validate_task_packet_authoring.py; custodian/tools/agent/validate_review_pairing.py; custodian/tools/agent/check_packet_categories.py; custodian/tools/agent/task_packet_index.py; custodian/tools/validation/run_validation.py; custodian/tools/validation/validation_manifest.json; custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md; custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_CHECKPOINT_RESUME_MERGE_PROVENANCE_V1.md; custodian/docs/ai_context/task_packets/archived/PAIRED_REVIEW_RESUMED_WORKTREE_PROVENANCE_V1.md; custodian/docs/ai_context/TASK_PACKET_CATEGORIES.json; custodian/docs/ai_context/reports/RETIREMENT_CAMPAIGN_CREATION_EXCEPTION_20261101.md
- Change:
  1. Reproduce the exact blocked source-span shape using a disposable bare remote and attached linked worktree: published claim at 878009b2, later clean resume heads 0aee8bf and 8bc0fe4, inherited first-parent Wire merge 38545e4, then source and archive commits. Confirm the old producer fails for missing checkpoint while the authentic inherited prefix is present in origin/main. Do not alter the preserved original run.
  2. Design one fail-closed inherited-history boundary within the existing producer verifier. Authenticate original claim commit/tree, published worktree identity, original branch, ordered same-run resume records, Git ancestry, recorded resume HEADs and the exact remote/main history. Admit upstream-only first-parent history inherited through an authenticated no-unique-work clean fast-forward; do not attribute imported merges or files to this workstream's authored source.
  3. Do not infer inheritance solely from current main reachability or a forged resume event. Prove that the workstream had no uncheckpointed unique source before the resume, using original remote/checkpoint state and immutable trace/Git evidence. If historical pre-resume state cannot be authenticated, remain blocked and report the precise missing proof rather than hard-code a broad allowance.
  4. Apply the unchanged existing checkpoint -> ordered main_sync/worktree_resumed -> deterministic merge-tree -> after-sync validation requirements to genuinely workstream-authored two-parent merges occurring after the authenticated inherited prefix. Keep source-path, modes, landing, completion-truth and independent-review gates unchanged; no synthetic checkpoint or validation event.
  5. Independently verify the same inherited-versus-authored boundary in paired_review_host_validation.py using Git objects and reviewer-held trace evidence, not the producer's boolean or summary. Refuse altered identity, ambiguous inheritance, out-of-main history, duplicate/reordered or spoofed resumes, moved remote refs, missing after-sync reports, and changed source after validation.
  6. Align workstream.py preflight with the finish-time source-span gate when an original trace exists. Report a specific source-provenance blocker rather than ready_before_sync=true when finish would reject the same source. Preflight remains read-only; do not fetch, mutate traces or claims, or attempt synchronization.
  7. Document the proof boundary and preservation rule narrowly. Keep the original blocked summary-rename claim/lock/checkout, historical Wire merge, timeout commits and all archived/reviewer evidence byte-identical.
- Preserve: RC-119 and existing historical pinned compatibility; normal no-op, checkpoint/resume, one- and multi-sync, source-bearing archive and direct-child canonical summary rename behaviors; after-sync source/tree/status matching; task-packet checks and independently reviewed receipts; all external agent claims, root-dirty files and private host artifacts.
- Non-goals: No changes to the original summary-rename source 57242738 or its original run, no fabricated lifecycle event, no branch rewrite or force push, no automatic orphan recovery, no GC/process-scan modification, no worktree-retirement changes, no dispatcher policy change, no edits to W1, Agent Wire, Sepulcher, timeout, Operator or Ritualant. Do not change the campaign's default 2:1 rule or add further packets under this exception.
- Acceptance:
  - Genuine failing-first real-Git fixture reproduces the missing exact checkpoint at 38545e4 and the misleading green preflight on pre-change source; corrected producer/consumer accept only fully proven inherited-main history, with first-parent authored source inventory unchanged.
  - Negative controls reject forged/reordered/duplicate resumes; noncanonical or missing claim/worktree; local branch-only or post-resume authored merge with no checkpoint; detached/moved history; remote/main ancestry mismatch; altered tree/extra path; missing, duplicate or mismatched main_sync and validation_after_sync evidence; dirty or unique source at the alleged clean fast-forward; and stale/forged source validation. An unprovable historical boundary fails closed.
  - Existing normal sync/resume, RC-119, archive-first, canonical rename, preflight and protected review-source fixtures remain green.
  - Focused producer and consumer full suites, AI-context, packet category/authoring/pairing/index, and canonical changed-file validation all pass with complete coverage and no failures, skips, timeouts or infrastructure errors. Record exact commit/tree/status and report SHA-256.
  - Implementation lands and retires its own checkout through normal workstream.py finish. Protected summary-rename remains blocked until this correction is independently accepted and its original same-claim finish is rechecked; do not count any other retirement.
- Validation:
  - Run a disposable real-Git failing-first probe, plus positive and all security-negative variants.
  - python3 -m unittest custodian.tools.agent.test_workstream -v
  - PYTHONPATH=custodian/tools/agent python3 -m unittest custodian.tools.agent.test_paired_review_runner -v
  - python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json
  - python3 custodian/tools/agent/check_ai_context.py --json
  - python3 custodian/tools/agent/check_packet_categories.py
  - python3 custodian/tools/agent/validate_review_pairing.py
  - python3 custodian/tools/agent/task_packet_index.py
  - git diff --check
- Task overrides: none
- Deferred: Retiring the protected original summary-rename checkout, re-running its finish, repairing historical W1 or the procfs GC limitation, and any additional implementation/review pair all require their own existing authority or new explicit approval.

## Handoff

- Next workstream: review-agent-workstream-inherited-main-resume-provenance-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae73140-7bb8-83e8-8a42-705d683aa2fb
- Refresh reason: none
- Next action: After this correction lands and is canonically torn down, run the one fresh-context paired review. Only a genuine passing verdict may authorize another original-claim summary-rename finish attempt.
- Blockers or open questions: Historic resume proof for the protected target must be independently reconstructible. If not, fail closed and report the exact missing witness.
