# Agent Validation Gate Drift Repair Review Corrections 1

Closed review finding `R0-01` by making the post-expiry workflow smoke use explicit marker targets. `custodian/AGENTS.md` checks the procgen routing markers, expired policy text, and `TEMP_LFS_DEGRADED_MODE_START`; the former `workstream.py`, `land_main.py`, and alias targets each check the LFS marker. The deleted expiry workflow assertion remains intact, and manifest ownership already covered the alias path.

`agent_workflow_smoke.py` passed, as did the `agent_workflow_contract` manifest gate. A temporary fixture that injected `TEMP_LFS_DEGRADED_MODE_START` into `custodian/AGENTS.md` failed with the expected file and marker. No runtime/game files changed. The paired re-review remains dependency-gated on this correction landing.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The parent smoke did not guard the removed LFS marker family.
- Root cause / contributing factors: Its shared marker tuple preserved the former procgen-only assertion set.
- Prevention / pipeline improvement: Explicit per-file marker targets make each expired marker family's expected location reviewable.
- Tooling / docs drift discovered: none.
- Follow-up: review-agent-validation-gate-drift-repair-review-corrections-1
- What worked: A fixture-level negative control proved a reintroduced marker is rejected.
