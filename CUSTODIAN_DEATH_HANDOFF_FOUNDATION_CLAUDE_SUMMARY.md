# Custodian Death Handoff Foundation — Checkpoint

Implemented R1 on `agent/custodian-death-handoff-foundation`; **not landed**.
Required changed-file closeout is blocked by pre-existing validation drift.
The isolated worktree and remote recovery branch are retained for resumption.

## Change

Operator emits one `operator_down(context)` snapshot after existing death
cancellation/presentation requests. The same context feeds telemetry, including
position, health, stamina, patch availability, enemy counts and lethal attack
context. The death latch now precedes cancellation callbacks. An attached
`OperatorDeathCampaignBinding` latches before resolution callbacks, routes one
started unresolved session through `WorldSimulationRuntime.resolve_campaign`
and only then invokes the transitional Game Over modal. No-session, unstarted
and already-resolved sessions use the safe fallback without creating a campaign
or another outcome. The actor no longer decrements legacy lives. Outcome sealing
remains exclusively in `CampaignSession`; no inventory, weapons, fabrication,
facility failure or death animation/timer behavior was changed.

## Validation

- Focused `operator_death_campaign_handoff`: PASS (4.0 seconds). Checks one
  handoff/outcome, callback reentrancy, structured context, failure reason,
  resolution-before-Game-Over, unchanged lives, no revive, and no-runtime /
  unstarted / already-resolved negative controls.
- `game_over_flow_smoke.gd`: PASS; modal/restart/stat and legacy direct callers.
- `campaign_outcome_exactly_once_smoke.gd`: PASS; outcome/Hub dedup and restore.
- `world_simulation_live_scene_smoke.gd`: PASS assertions, with pre-existing
  missing Vaultwing bonding texture errors and exit resource/object warnings.
  `vaultwing-bonding-art-final-ingest` is an independently claimed workstream;
  this task did not edit its assets or hide those diagnostics.
- Changed-file closeout: **FAIL**, 50 selected, 10 passed, 2 failed, 38 skipped.
  `agent_workflow_contract` still reads deleted
  `.github/workflows/expire-lfs-degraded-mode.yml` and requires expired primer
  routing markers. `review_pairing_contract` rejects stale validation paths in
  six contract-world placement packets, procgen render attribution, and the
  absent Operator art registration profile smoke. Coverage has no gaps.
- Selected actor regressions: **PASS**, 34 selected/passed, zero failures/timeouts. The separate actor run proves runtime regressions despite the unrelated unit-tier block; it does not waive that block.
- `git diff --check`: PASS.
- Moment Forge: not run — death presentation/timing are unchanged; structured
  state proves the handoff contract.

## Deferred / Resume

No `workstream.py finish` or main landing was attempted after the required gate
failed. R1 stays blocked, unarchived. A bounded validation-drift repair packet is
authored; R2 is authored against the live binding, Hub application and existing
local-return seams but remains dependency-blocked. Post recovery and all R3–R8
equipment/infrastructure behavior remain unimplemented. The roadmap records
this pending state rather than claiming R1 or the program complete.

Resume after the validation repair lands, merge the new main normally, rerun
required closeout, update this receipt and the roadmap, archive R1 and finish.
Never use the focused green report to bypass the failed required gate.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `blocked`
- Friction severity: `medium`
- What went wrong: Required changed-file closeout failed on two pre-existing unit gates; higher tiers were skipped.
- Root cause / contributing factors: The workflow smoke still demands expired routing artifacts; unrelated ready packets carry stale or absent validation script paths.
- Prevention / pipeline improvement: Authored bounded `agent-closeout-validation-drift-repair`; retain strict gates and resume R1 after repair.
- Tooling / docs drift discovered: `agent_workflow_smoke.py` expiry assumptions and active-packet validation references; `--list` lists all tests even with `--changed`.
- Follow-up: `agent-closeout-validation-drift-repair`
