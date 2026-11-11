# Exact-Run Finish-Index PASS Recovery

Workstream: `agent-paired-review-finish-index-codex-exited-pass-recovery-v1`

## Result

Implemented a recovery limited to paired-review run `20261027T113425Z-50d9c7adf7a0` and its separate dispatcher claim run `20261027T113443Z-6f08c7ced9a2`. The original reviewer run, claim branch, reviewer checkout, and governance checkout were not modified.

The new `recover-finish-index-codex-exited-pass` command authenticates the pinned run manifest, original claim, remote branch and main identities, process/lock state, reviewer worktree changes, five-message/one-turn session, final message, findings-first summary, reviewer receipt, target baseline, and immutable 9/9 host-validation evidence. Its plan checks remote state with `git ls-remote`, does not fetch, and binds intended archive, target receipt, summary, and generated index bytes to the plan digest. Apply requires that exact digest, takes the original review lock, preserves both dirty reviewer artifacts byte-for-byte, journals before edits, and hands closeout to the original `workstream.py finish` path.

The general `_verified_reviewer_pass` rule remains unchanged. Normal coordinator closeout now checks for the archived review packet before attempting either receipt recovery path, returning a recoverable `RunnerError` before target edits when it is missing.

## Evidence

- Original historical plan-only run passed with plan digest `80b01ce7aa37de71d04023110d7b9fe0dcac05023b038a2ce4c62c7c8b5ce157`.
- The plan authenticated all nine original run-file SHA-256 values, including validation report `e6d94ebbca87e36b832c1cc93a41754eccfe2eb94950f5c1918f9bc5de67a244` and coordinator evidence `dd20a24b49c68d8ac136b784cc6b76d6e0ad77ec08ece53b3358ee14d97d0ec0`.
- Before/after snapshots confirmed the plan left `HEAD`, `origin/main`, and `FETCH_HEAD` unchanged.
- Disposable Git packet-tree fixture produced exactly one archived canonical PASS outcome, one target receipt, the bounded summary handoff, and a current managed index. A repeated preparation failed closed without duplicate artifacts.
- Missing-archive regressions passed both with no target receipt and with a pre-existing target receipt; the target bytes remained unchanged.
- Full paired-review runner suite: **203 passed**.
- `run_validation.py --test paired_review_runner_unit --json`: **1/1 selected check passed**, running 203 tests.
- `run_validation.py --changed --base origin/main --json`: **6/6 selected checks passed**, complete code coverage, no failures or timeouts.
- `validate_review_pairing.py`: PASS (141 auto-review pairs).
- `task_packet_index.py`: PASS.
- `check_ai_context.py`: PASS.
- `git diff --check`: PASS.

The prescribed direct unittest module command needed `PYTHONPATH=custodian/tools/agent` in this checkout; the canonical validation harness ran with the correct import environment.

## Deferred and preserved

The original review apply was intentionally not run. It still requires this correction's independent PASS and separate project-owner authorization. No review verdict was inferred from green tests, and no run phase, run artifact, original reviewer file, claim, lock, governance workstream, or unrelated checkout was changed.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: The historical runner exited after producing a final PASS but before canonical archive and receipt closeout; its five-message session did not meet the ordinary one-message verifier shape.
- Root cause / contributing factors: A missing archived review packet raised `FileNotFoundError` outside the runner's recoverable error path, and the normal PASS verifier intentionally rejects noncanonical session cardinality.
- Prevention / pipeline improvement: Add this one evidence-bound read-only plan/apply path and convert the ordinary missing-archive case to a controlled `RunnerError`; do not broaden generic PASS acceptance.
- Tooling / docs drift discovered: The direct unittest module invocation needs the agent tools directory on `PYTHONPATH`; the repository validation harness already supplies it.
- Follow-up: `review-agent-paired-review-finish-index-codex-exited-pass-recovery-v1`
- What worked: Exact run hashing, fresh remote identity checks without ref mutation, and the disposable Git artifact fixture verified the intended closeout surface.

## Next Handoff

- Next workstream: `review-agent-paired-review-finish-index-codex-exited-pass-recovery-v1`
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: Run the paired review in a fresh context. On accepted PASS, rerun the historical review plan and obtain separate owner authorization before apply.
- Blockers or open questions: Historical review apply remains unperformed pending that review and owner authorization; governance simplification remains unlanded.
