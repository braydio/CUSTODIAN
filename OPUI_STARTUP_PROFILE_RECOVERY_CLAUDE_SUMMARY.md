# opui startup profile recovery

Recovered the local Operator Workbench startup on 2026-10-02. No runtime or launcher code changed. The dedicated art checkout was clean but had two extra sparse patterns (`custodian/docs/ai_context/task_packets` and `design/02_features/procgen`). The launcher treated the profile as unhealthy and refused migration because the checkout had LAND PENDING and diverged from origin/main (178 ahead / 360 behind).

Backed up HEAD, branch, sparse patterns, and pending publication receipt under `.git/operator-startup-recovery/20261002T204149Z`. Reapplied the current Operator sparse profile through the repository helper. Verified profile health, unchanged HEAD, byte-identical pending receipt, and clean tracked/untracked status. `opui --help` passed through the actual alias. A Textual headless startup mounted MainScreen with no exception.

The pending idle_relaxed_01 east/west publication remains unresolved. Its receipt names commit 84c3b7338 while current art HEAD is 96c4fce19; automatic publication retry may require separate history reconciliation. No commits were reset, rebased, or published from the art branch. Local profile repair is machine-local; this summary records it but does not alter other machines' checkout settings.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: profile drift blocked startup and access to the UI publication retry
- Root cause / contributing factors: sparse migration gate combines profile health with pending publication and branch divergence; pending receipt commit differs from HEAD
- Prevention / pipeline improvement: consider a read-only recovery entrypoint and actionable startup diagnostics for unhealthy pending checkouts
- Tooling / docs drift discovered: two extra sparse patterns in local art checkout
- Follow-up: manual-follow-up
- What worked: repairing only profile state restored startup while preserving art and receipt
