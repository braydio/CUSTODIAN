# Owner Review Exception Direct PR Provenance Recovery V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-owner-review-exception-direct-pr-provenance-recovery-v1`
- Category: `agent-ops`
- Status: `complete`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `agent-owner-review-exception-closeout-recovery-v1`
- Locks: `agent-workflow`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-owner-review-exception-direct-pr-provenance-recovery-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: The source-span resolver is a trust boundary. This bounded fallback authenticates one owner-authorized V2/direct-PR landing whose ordinary lifecycle trace was never published, and must be independently falsified before the preserved review can resume.
- Reviewed main: `a3fb2f8b4fe854af9607ee71a8beb3022014de58`
- Implementation commit: `f6ced9e60ceb6b6b57ee04b5bbd5dc0392140d7b`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af253c2-3c40-83ea-bd81-7ba163d4602e
- Visual review: `none`
- Goal: Let paired-review host validation verify the exact source-bearing commit span for the previously owner-authorized PR #126 fallback, so the preserved correction review can be planned and continued without inventing lifecycle events.
- Completion boundary: Add one private, fail-closed source-span verifier for the exact correction workstream, archived packet, archive introduction commit, V2 acquisition, authorized handoff, PR merge ancestry, and source/test blobs below. The normal resolver must return the actual source commit as the validation span. Every later resolver call must rederive and authenticate the same identities from Git and the immutable local acquisition receipt. No other archive, workstream, or landing gains fallback behavior.
- Current measured state: PR #130 landed on `origin/main` at `268d5d1abc9061278c16a3abd31e1d165aaac512`. The implementation source commit is `f6ced9e60ceb6b6b57ee04b5bbd5dc0392140d7b`, and the mandatory post-land identity preflight confirms `resolve_target_implementation_commit()` selects that exact source commit and `resolve_validation_source_span()` returns `d793f198a8abf74450c2eb4d6d4e1073187ffcc3` to `f6ced9e60ceb6b6b57ee04b5bbd5dc0392140d7b`. The paired provenance review remains ready/auto and has not launched; the older correction review remains preserved in `host_validation_recovery` with no verdict.
- Historical baseline: At reviewed main `a3fb2f8b4fe854af9607ee71a8beb3022014de58`, the pre-fix resolver failed with `split landing has missing or ambiguous exact workstream trace provenance`; no local or published target diagnostics refs existed. The preserved review run `20261110T060821Z-f29fdcb6eb2f` had zero reviewer launches and no verdict.
- Evidence: Exact commit ancestry and trees for source base `d64f588bcf74ccc10ba7e976729e6215acfbdc71`, source commit `74b22e1775f09ae50e3da5cd9f19d5108d97dc1a`, archive introduction `f6cd173576ddf54142f141afda7e81ca88915605`, owner-authorized handoff `9359fa3c5080b18a5c33707d6d8ce1f6b1fbb476`, PR branch merge `8b8c038678eafb4e7883141f85dc008deb650cc9`, and PR #126 merge `8e23d8b5418d7298dccc438c430652fe66d96333`; source-tree and archived-packet blob identities; host-private V2 acquisition receipt at `<git-common-dir>/custodian-turn-dispatcher-v2/acquisitions/e675dd2bc8ed480b9e1a3fb7a33cefdb.json`, SHA-256 `ae765606f58b2bb8dc8bf749f28fa6095bad5b74c971d98b669fd00fc82f7880`; exact review run metadata and preserved coordinator checkout.
- Task-specific authority: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/paired_review_runner.py`; archived target `custodian/docs/ai_context/task_packets/archived/AGENT_OWNER_REVIEW_EXCEPTION_CLOSEOUT_RECOVERY_V1.md`; source commit `74b22e1775f09ae50e3da5cd9f19d5108d97dc1a`; handoff `custodian/docs/ai_context/turn_handoffs/agent-owner-review-exception-closeout-recovery-v1.md` at `9359fa3c5080b18a5c33707d6d8ce1f6b1fbb476`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; existing resolver consumers in `custodian/tools/agent/paired_review_runner.py`.
- Publication inputs: `none`
- Change: Add a private verifier and invoke it only for the exact target `agent-owner-review-exception-closeout-recovery-v1`, archived target path `custodian/docs/ai_context/task_packets/archived/AGENT_OWNER_REVIEW_EXCEPTION_CLOSEOUT_RECOVERY_V1.md`, and archive introduction `f6cd173576ddf54142f141afda7e81ca88915605`. Authenticate: (1) source base `d64f588bcf74ccc10ba7e976729e6215acfbdc71` is the parent of source-bearing commit `74b22e1775f09ae50e3da5cd9f19d5108d97dc1a`; (2) `f6cd173576ddf54142f141afda7e81ca88915605` has that source commit as its sole parent and introduces the exact archived packet blob `0ba283ddb0f627ed5dee0a8bd98a6c6097fe12db`; (3) handoff `9359fa3c5080b18a5c33707d6d8ce1f6b1fbb476` is the exact child of the archive and carries the owner-authorized V2/direct-PR fallback record; (4) PR branch merge `8b8c038678eafb4e7883141f85dc008deb650cc9` has ordered parents `[9359fa3c5080b18a5c33707d6d8ce1f6b1fbb476, 2adb9f165328ee9e6176a44b24ee6d513c10cdf6]`; (5) final PR #126 merge `8e23d8b5418d7298dccc438c430652fe66d96333` has ordered parents `[2adb9f165328ee9e6176a44b24ee6d513c10cdf6, 8b8c038678eafb4e7883141f85dc008deb650cc9]` and its exact merge subject identifies PR #126; (6) each pinned commit and tree is available, the target archived packet blob is identical at the archive introduction and the supplied reviewed main, and the reviewed main descends from the final PR merge; (7) the exact source commit diff is derived from Git and consists of the root closing summary plus those four Python paths: `AGENT_OWNER_REVIEW_EXCEPTION_CLOSEOUT_RECOVERY_V1_CLAUDE_SUMMARY.md`, `custodian/tools/agent/dispatch.py`, `custodian/tools/agent/paired_review_host_validation.py`, `custodian/tools/agent/test_dispatch.py`, and `custodian/tools/agent/test_paired_review_runner.py`; the source-code subset is exactly the four Python paths, and their source-commit blobs are respectively `9debea3ae3df60027b88642d5774c3afbfdcb252`, `3e484a6ac581bfc2536a31e72a5b1e2929212a0b`, `4e83f9639dff5a3e80096b34dcd631db15b2f174`, and `d856442df64323fe9f33c1434c7c9d571022c261`, identical at the supplied reviewed main; (8) the exact V2 acquisition JSON is read-only, has the expected schema/workstream/turn/run/branch/checkout/source/task-definition identities, and its bytes match the pinned SHA-256; (9) the exact handoff file blob `ed3286c1459a2bf2ee29cca96dd842de199241a5` is pinned and its content records the owner-authorized fallback and failed V2 checkpoint; and (10) no local or published diagnostics trace for the target workstream conflicts with or ambiguously substitutes for this proof. Return `base=d64f588bcf74ccc10ba7e976729e6215acfbdc71`, `head=74b22e1775f09ae50e3da5cd9f19d5108d97dc1a`, `commits=[74b22e1775f09ae50e3da5cd9f19d5108d97dc1a]`, the exact Git-derived source diff paths, and a provenance object containing only these revalidated immutable identities. Recompute the complete proof whenever `resolve_validation_source_span()` is called, including post-review verification. If any pinned identity, receipt byte, owner handoff, parent order, path/blob identity, ancestry, or no-conflict check fails, raise `HostValidationError`.
- Preserve: Original V2 acquisition JSON and checkout byte-for-byte; original and correction review run directories and claims; unresolved chassis-review truth; all existing generic and special-case source-span rules; the reviewed correction and all unrelated source paths; G branch/worktree.
- Non-goals: No synthetic lifecycle/landing/teardown trace events; no V2 checkpoint/finish/retirement receipt; no acquisition receipt edits; no review claim re-acquisition; no recovery-plan apply or reviewer launch; no owner-exception activation or PASS fabrication; no general source-span relaxation or arbitrary PR fallback; no G checkout, Operator runtime, or chassis implementation changes.
- Acceptance: The exact archive resolves to the precise source-bearing span and an independently checkable PR/V2 provenance object; every expected source/test path is Git-derived and blob-identical through reviewed main; the exact private acquisition receipt and owner handoff are authenticated without writes; normal generic source-span logic remains unchanged for every other workstream; absent, malformed, changed, or mismatched acquisition/handoff evidence fails closed; adversarial tests reject incorrect workstream, archive commit, source/archive parent, tree, PR branch merge parent/order, final merge parent/order, PR identity, reviewed-main ancestry, packet blob, source path, source blob, root-summary/source path inventory, receipt bytes/identity, handoff bytes/authorization fields, and ambiguous/conflicting lifecycle traces; focused tests and all packet/changed-file validation gates pass. Only after this implementation lands may the exact preserved review's read-only `--recover-host-validation --plan` be rerun; its plan must not be applied in this workstream.
- Validation: `python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`; focused exact-history positive and negative verifier tests; `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json` with complete changed-file coverage; `python3 custodian/tools/agent/check_ai_context.py --json`; `python3 custodian/tools/agent/task_packet_index.py`; targeted paired authoring/category checks; `python3 custodian/tools/agent/validate_review_pairing.py`; `git diff --check`. Verify the host-private receipt read-only with `sha256sum "$(git rev-parse --path-format=absolute --git-common-dir)/custodian-turn-dispatcher-v2/acquisitions/e675dd2bc8ed480b9e1a3fb7a33cefdb.json"`; it must equal the pinned digest above. This receipt is owned by the current CUSTODIAN host, must not be committed/copied/rewritten, and is indispensable; if absent or changed, stop and report that the host prerequisite is unavailable.
- Task overrides: `none`
- Deferred: Only after the paired provenance review is independently accepted and its receipt lands may the preserved correction review's read-only host-validation recovery plan be rerun. Do not apply that plan until the orchestrator separately authorizes it; then continue only from the exact preserved review run. The original owner-exception review, owner-exception activation, and Operator slices remain later gates.

- Publication hold: Resolved. The implementation/review pair was published together, the automatic authoring handoff promoted both to ready/auto, and implementation PR #130 landed at `268d5d1abc9061278c16a3abd31e1d165aaac512`.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: The verifier authenticates the exact source-bearing span and pinned receipt/handoff/PR history on each resolution. The focused adversarial suite and full paired-review runner suite passed (313 tests); changed-file validation covered both modified Python files completely; PR #130 landed at `268d5d1abc9061278c16a3abd31e1d165aaac512`. Independent paired review is still pending and is not represented as accepted or passed.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: The first V2 finish attempt stopped because the handoff omitted required headings. After correcting it, V2 finish checkpointed and retired the implementation turn but did not archive or complete the task packet, so the paired review correctly remained blocked.
- Root cause / contributing factors: The lifecycle guide describes packet archival before finish while V2 finish is a turn checkpoint/retirement boundary and explicitly does not assert task completion.
- Prevention / pipeline improvement: Build the V2 handoff with all required fields before checkpointing, then run an explicit post-land packet closeout that records the implementation SHA before starting its paired review.
- Tooling / docs drift discovered: `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md` conflates pre-finish packet archival with V2 finish, although V2 finish only checkpoints and retires the turn.
- Follow-up: `manual-follow-up`
- What worked: Pinned receipt and Git evidence stayed immutable; the landed source-span proof selects the source commit rather than the archive/closeout commit.

## Handoff

- Next workstream: `review-agent-owner-review-exception-direct-pr-provenance-recovery-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af253c2-3c40-83ea-bd81-7ba163d4602e
- Summary backlink: include this exact Authoring chat URL in every durable summary and final next handoff.
- Refresh reason: `none`

## Context Pack

- Repomix: `none`
