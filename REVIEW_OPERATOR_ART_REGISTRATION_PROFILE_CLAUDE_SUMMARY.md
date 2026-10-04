# Review: Operator Art Registration Profile

Reviewed live `origin/main` at `907dc2bf0` across code, architecture, asset-pipeline, and workflow contracts. The profile authority, shared-scale clipping refusal, v1 plan compatibility, MCP surface, Aseprite guide exclusion, and focused regressions passed. All five focused smokes passed, including the real Aseprite guide test.

## Findings

- **R0-01 — correctness / asset-pipeline:** The approved normalization plan is not bound to an expected digest before production use. In a fresh temporary Source Session, changing the valid `destination_x` from 248 to 250 was accepted by the converter; regenerating output from that plan also passed `verify_production()`. A correction packet requires an independently persisted approved-plan digest, explicit replan invalidation, and a mutation negative control.
- **R0-02 — material evidence gap / tooling:** Workbench `registration_report()` calls `profile_report()` without a plan, and the reporter only fills transformed landmarks/residuals when a plan is supplied. The Workbench report therefore omits promised coordinate-space comparison and scale evidence. A correction packet defines report values in the already registered 96×96 Workbench canvas and keeps deviations advisory.

Both findings are in the archived implementation packet's `## Independent Review` receipt. The implementation was not modified. The correction and paired re-review packets are staged as ready after this review lands.

## Validation

- Registration profile smoke: PASS
- Source Session smoke: PASS
- Art Agent semantic smoke: PASS
- Art Agent MCP smoke: PASS
- Aseprite smoke: PASS (guide visible in editor, clean render unchanged, repeated apply safe, no publish binding)
- Independent temporary mutation reproduction: confirmed modified plan accepted

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: The implementation's focused suite did not exercise plan mutation or assert Workbench report projections.
- Root cause / contributing factors: Production verification derives a digest from the mutable plan after reading it; Workbench report has no transform input and leaves projections empty.
- Prevention / pipeline improvement: Created bounded corrections for both findings and a paired correction-review packet.
- Tooling / docs drift discovered: The fresh review worktree had no code-review graph database; a minimal build did not complete, so evidence came from direct source analysis and independent fixture behavior.
- Follow-up: operator-art-registration-profile-review-corrections-1
- What worked: All prescribed focused smokes passed, while a separate temporary fixture falsified the plan-mutation acceptance claim.
