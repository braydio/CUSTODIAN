# Paired Review Host Godot Validation V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-host-godot-validation-v1`
- Kind: `implementation`
- Status: `complete`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-godot-cache-access-v1`
- Locks: `paired-review-host-validation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-host-godot-validation-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `trusted host execution, sandbox separation, exact validation provenance and receipt integrity need independent adversarial review`
- Reviewed main: `32597efc72d8c5bf2ae1c7edb349f651d3d257dd`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e`
- Visual review: `none`
- Goal: Remove the recurring restricted-Codex Godot TCP-listener/import failure from independent paired review validation without broadening Codex sandbox network or Git authority.
- Completion boundary: The existing paired-review coordinator runs canonical import-dependent validation with ordinary host socket capability, real Godot locks and the original claimed worktree; the independent restricted reviewer reads exact pinned, immutable coordinator evidence and authors its own verdict; the existing receipt/finish gate fails closed on any absent or mismatched validation.
- Current measured state: Paired reviews now run canonical changed-file validation in the trusted coordinator before launching the restricted fresh reviewer. The coordinator pins the implementation parent, claimed worktree and target SHA; records atomic raw report and provenance evidence; and rechecks report and implementation source hashes before closeout. The reviewer prompt names its exact root summary output and protects the implementation summary as read-only. The complete changed-file suite passed 42/42 with zero failures, skips, timeouts or infrastructure errors.
- Evidence: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/godot_project_lock.py`; `custodian/tools/agent/review_receipt_delta.py`; `REVIEW_ASSET_WORKBENCH_REVIEW_STUDIO_R1_CLAUDE_SUMMARY.md`; the archived PGA-2 implementation `675ccf726bb79397b7242ef3059971a6f1a39448`. The Ritualant and PGA-2 stranded reviewer run evidence is host-local and must not be rewritten.
- Task-specific authority: Coordinator `paired_review_runner.py` owns trusted process launch and run evidence; `run_validation.py` owns tests and import truth; `godot_project_lock.py` owns machine-wide budget and per-project lock; `review_receipt_delta.py` / `workstream.py finish` retain their existing immutable review and landing gates.
- Work surface: `custodian/tools/agent/paired_review_runner.py`, `custodian/tools/agent/test_paired_review_runner.py`, optional focused `custodian/tools/agent/paired_review_host_validation.py` and tests only if needed, and `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/VALIDATION_RECIPES.md` for exact host/reviewer separation. Use the existing `run_validation.py` unchanged where possible.
- Change:
  1. Run the exact canonical changed-file gate from the **trusted coordinator** outside the restricted `codex exec` sandbox, under the existing `GodotProjectLock` and `GodotJobBudget`. A host-only local socket + writable Godot HOME preflight may distinguish environment failure before expensive import; never bypass a real red test. No sudo, `--no-godot-lock`, global sandbox/network relaxation, monkey-patching Godot, cache deletion or extra engine authority.
  2. Pin original claimed worktree, original reviewed-main SHA, archived target identity, resolved immutable implementation SHA, and exact implementation-parent base for changed-file selection. Prove selected changed-file coverage actually includes the reviewed implementation's diff. Invoke `run_validation.py --changed --base <exact-reviewed-implementation-parent-SHA> --json` from the claimed checkout; reject empty/vacuous selection, missing changed-file coverage, incorrectly scoped git ancestry, failed import, failed/timeout/skipped checks, and false coverage. Do not run against mutable root checkout or infer base from the new HEAD.
  3. Write separately named coordinator validation result and capture process return code, command/base, reviewed-main/worktree HEAD, git status/content fingerprint and SHA-256 of the raw report in **the existing** run-evidence directory. Use bounded atomic writes and preserve any earlier `validation.json` and failure report byte-for-byte. Reject source drift, dirty implementation files, missing/ambiguous execution output or metadata. Never silently substitute a previously successful implementation-side report.
  4. Present the fresh restricted reviewer with that immutable coordinator evidence and its exact failure/pass metadata. Reviewer independently inspects canonical source/diff, relevant focused evidence, negative controls and the coordinator report; explicitly authors `passed` / `findings` / `human_required` or blocked. No coordinator-authored verdict. Its local sandbox need not rerun Godot to establish proven host results, but **must not** call a failed/missing host report PASS. It may run non-socket unit/static checks where useful.
  5. Coordinator verifies the host report byte hash and pinned identities again after reviewer completion and before any `coordinator_finish_review` / `workstream.py finish`. Existing exact-byte archived-target receipt checks and reviewer provenance remain mandatory. Passing report must have `schema=custodian.validation.result.v1`, `passed=true`, complete coverage, nonempty tests, zero skipped/failed/timeout/infrastructure errors and a matching exact selection. Green report is necessary but not sufficient for PASS; a reviewer-authored valid receipt remains essential.
  6. Fail closed and preserve original claimed worktree, run records, review lock and branch if host validation fails, the reviewer disagrees, evidence changes, Git ancestry drifts, a process dies or another supervisor is active. Do not create duplicate claims; do not automatically finalize protected historical reviews from this new capability.
- Preserve: Genuine independent reviewer judgment, Godot global job budget/project lock, single original claim, pinned original review target, restricted reviewer Git access, dirty root checkout, all non-Godot tests and source ownership, original failure receipts.
- Non-goals: No fixes to Ritualant music, PGA-2 exhibit art/code, procgen, Asset V2, or Godot; no simulation of passing tests; no generic remote validation service, MCP server, CI token delegation, or arbitrary command execution in the reviewer sandbox; no implicit revival of exited `--ephemeral` reviewer sessions.
- Acceptance: Unit/fault fixtures prove host-run command uses exact isolated worktree/implementation parent and locks; reviewer argv remains restricted; negative tests reject mismatched SHA/base, vacuous coverage, injected/corrupt/edited reports, failed import, missing provenance, duplicate supervisor, illegal reviewer write, forged PASS, failed reviewer disposition, and report replacement; reviewer may independently PASS with a genuine immutable green host report and exact receipt; original run records unchanged. Include a fixture reproducing sandbox socket bind failure and showing coordinator host validation does not alter review policy.
- Validation: Focused `python3 -m unittest test_paired_review_runner` and new helper tests; `godot_project_lock_smoke.py`, paired receipt-delta/workstream fixtures, targeted authoring/index and complete changed-file validation with canonical locks; `git diff --check`. Do not claim executable Godot success without actually running it.
- Task overrides: `none`
- Deferred: The distinct `agent-paired-review-same-run-continuation-v1` supplies guarded continuation for already-protected PGA-2 and Ritualant claims **after** this host execution seam is reviewed and available; do not turn old blocked runs into an automatic PASS.

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Evidence: `test_paired_review_runner` (34/34); `test_workstream` and `test_workstream_artifacts`; `godot_project_lock_smoke.py`; targeted packet-authoring preflight; complete changed-file report `/tmp/agent-paired-review-host-validation-changed-final.json` (42/42 passed, complete coverage).

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: `The original reviewer prompt did not name its summary output or protect the implementation summary, enabling a reviewer write to collide with the implementation handoff.`
- Root cause / contributing factors: `The prompt described a durable summary generically while the coordinator bounded allowed paths but did not make the two exact summary identities explicit to the reviewer.`
- Prevention / pipeline improvement: `The prompt now names the exact review summary and read-only implementation summary; the coordinator verifies bounded changed paths, and host validation evidence is atomically written and digest-checked.`
- Tooling / docs drift discovered: `The changed-file manifest did not list the new host-validation helper as an owner; its paired-review unit route now covers it.`
- Follow-up: `agent-paired-review-same-run-continuation-v1`
- What worked: `Pinned host-side validation preserves the existing Godot lock and job budget while keeping verdict ownership with the fresh reviewer.`

## Next Handoff
- Next workstream: `review-agent-paired-review-host-godot-validation-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e`
- Refresh reason: `independent verification of trusted-host/restricted-reviewer split`
- Next action: `Land and archive; independently review; then reconcile continuation V1 against this host evidence API before retrying the preserved PGA-2 and Ritualant reviews.`
- Blockers or open questions: `Bootstrap exception: existing cache-access independent review is currently claimed under agent-workflow and itself may need the trusted Godot host validator. This narrowly scoped fix depends on the landed cache-access implementation rather than its unaccepted review and uses a distinct paired-review-host-validation lock. It does not approve that review. The cache review must still receive its own independent disposition. Host execution evidence is mandatory.`

## Bootstrap dependency rationale
- This task is deliberately **not** gated on `review-agent-paired-review-godot-cache-access-v1`: that active review requires the host validation seam to overcome restricted reviewer socket failures. Depending on the stuck review would deadlock the repair.
- The new `paired-review-host-validation` lock is distinct from the old `agent-workflow` lock so the repair can be claimed without stealing/releasing the original cache reviewer. During implementation do not enter/edit the old claimed review worktree; operate only in the new dispatcher checkout. Independently review this new change before any positive recovery of the old claims.

## Publication Gate
- Explicit `draft/manual` with `Authoring handoff: auto`: the existing GitHub authoring-handoff workflow may promote **both** paired packets only if its targeted preflight passes; do not treat this authored packet or the dependency as an implementation claim.
