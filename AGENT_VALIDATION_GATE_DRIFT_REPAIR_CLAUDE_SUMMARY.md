# Agent Validation Gate Drift Repair

The agent workflow smoke now checks the post-expiry state: the deleted expiry workflow stays absent and temporary routing markers remain absent from their former policy/tool targets. Its manifest owner list no longer names the deleted workflow and now includes `tools/custodian_aliases.sh`.

The shared packet contract preserves `custodian/tools/...`, `res://tools/...`, and `tools/...` references. It resolves Godot paths into `custodian/tools`, checks root `tools` before the project-tree fallback, and reports missing references with their original spelling and nearest tracked entrypoint. Regression coverage exercises both live roots and the missing-path block. The Operator registration packet now describes its future smoke generically until the file exists and names it in the Validation section before closeout.

The smoke and both packet test suites passed. The manifest-backed review-pairing gate initially reproduced the Operator packet defect because it validates committed candidate trees; after committing the corrected packet, the candidate-tree gates passed. The eight named ready workstreams no longer have validation-reference errors. No gameplay, asset, or runtime files changed.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The first candidate-tree gate run still saw the old committed packet and reproduced its forward-reference error.
- Root cause / contributing factors: The review-pairing wrapper intentionally reads committed `HEAD`, while packet edits were not committed yet.
- Prevention / pipeline improvement: Run candidate-tree manifest gates after committing packet lifecycle updates.
- Tooling / docs drift discovered: Validation-path syntax and tracked-root resolution no longer matched live packet conventions; the workflow smoke asserted pre-expiry state.
- Follow-up: fixed-in-scope
- What worked: Direct grammar tests and temporary-repository dispatch tests covered accepted paths and fail-closed behavior.
