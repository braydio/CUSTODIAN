# Inherited-Main Resume Provenance Correction 1 — Closeout

- Workstream: `agent-workstream-inherited-main-resume-provenance-v1-review-corrections-1`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae73140-7bb8-83e8-8a42-705d683aa2fb
- Correction finding: `R0-01`
- Implementation base: `75430438df027524f1365902a313e307891e0ac1`

## Result

Added direct real-Git consumer coverage for inherited-main resume source-span classification, including a positive history and adversarial trace/object mutations. The tests found a real source-inventory defect: the validator skipped the authenticated inherited merge, but still included earlier upstream-only commits in the inherited fast-forward prefix as task-owned source paths.

The bounded fix authenticates the exact same-run resume event and the full claim-base-to-resume first-parent prefix, verifies parent continuity and deterministic merge trees, excludes all prefix commits from authored paths, and preserves ordered merge provenance. The fixture proves upstream-only pre-resume files are excluded and genuine task source/test files after resume remain included. Adversarial cases reject missing, forged, mismatched, duplicated/reordered/conflicting resume records; invalid ancestry and merge parents/tree; authored or uncheckpointed merges misrepresented as inherited; tampered checkpoints; and undocumented source paths.

## Verification

- `PYTHONPATH=custodian/tools/agent:custodian/tools python3 -m unittest custodian.tools.agent.test_paired_review_runner -v` — 275 passed.
- `python3 -m unittest custodian.tools.agent.test_workstream -v` — 89 passed.
- `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json` — passed; complete coverage for both changed source/test files, no skips, timeouts, failures, infrastructure errors, or source mutation.
- `python3 custodian/tools/agent/check_ai_context.py --json` — passed, zero findings.
- Packet category checks, paired authoring validation, review pairing, managed task packet index, Python compilation, and `git diff --check` — passed.

Only the scoped validator and consumer test files changed as implementation outputs. The independent paired review remains the acceptance gate; this closeout does not change the parent review’s findings verdict.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `The inherited-main exception omitted the merge commit from ordinary merge handling but left upstream-only commits earlier in the resumed fast-forward prefix in the task-owned source inventory.`
- Root cause / contributing factors: `The consumer logic authenticated the inherited merge without excluding its complete first-parent fast-forward prefix.`
- Prevention / pipeline improvement: `Authenticate the exact resume and first-parent history, verify ordered merge provenance, exclude the full prefix, and keep the temporary-Git consumer matrix as a regression gate.`
- Tooling / docs drift discovered: `none`
- Follow-up: `fixed-in-scope; obtain the separately paired fresh-context review`

## Next Handoff

- Next workstream: `review-agent-workstream-inherited-main-resume-provenance-v1-review-corrections-1`
- Next packet state: `ready after implementation landing and archive`
- Next action: `After canonical finish and teardown, confirm live dispatch eligibility, then launch the exact paired review once through paired_review_runner.py in fresh context.`
- Protected prior review findings, original summary-rename workstream, and unrelated claimed work remain untouched.
