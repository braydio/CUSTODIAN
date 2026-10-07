# REVIEW: VEHICLE RUNTIME LIFECYCLE HARDENING V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-vehicle-runtime-lifecycle-hardening-v1`
- Kind: `review`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `vehicle-runtime-lifecycle-hardening-v1`
- Locks: `none`
- Review: `none`
- Review target workstream: `vehicle-runtime-lifecycle-hardening-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/VEHICLE_RUNTIME_LIFECYCLE_HARDENING_V1.md`
- Reviewed main: `b4759b996397227be19cee0f2e8d31ee7ad80688`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently prove that vehicle disable/destruction/exit lifecycle cannot strand the Operator and that ownership truth is singular after the hardening lands.
- Reviewed implementation acceptance: Verify every Acceptance clause from the archived implementation packet against landed main, not the implementation summary.
- Review evidence: Archived packet/closing summary, live implementation, focused validation, and fresh hostile transition probes.
- Correction threshold: Create correction work only for confirmed acceptance defects or material proof gaps. Route non-blocking issues/optional improvements to next-slice/deferred; subjective choices use `human_required`.
- Focused validation: Re-run `res://tools/validation/vehicle_exit_clearance_smoke.gd` and `res://tools/validation/validate_vehicle_registry.gd`, then the implementation-created lifecycle smoke named in the archived packet and one fresh hostile transition probe.
- Review focus: Attack occupied disable/destruction, blocked exit, repeated enter/exit, duplicate-group discovery, stale controller/camera targets, and any retained legacy VehicleBase path. An exit-only green smoke is insufficient proof.
- Acceptance: Produce a findings-first independent review of live main with stable R0-NN IDs and durable receipt. Blocking defects/material proof gaps create `vehicle-runtime-lifecycle-hardening-v1-review-corrections-1` plus paired review. Do not patch reviewed implementation code.
- Non-goals: Do not redesign the vehicle system, tune handling, add features/art, or fix implementation directly.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Independent Review

- Status: `passed`
- Review workstream: `review-vehicle-runtime-lifecycle-hardening-v1`
- Reviewed on main: `b4759b996397227be19cee0f2e8d31ee7ad80688`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime`
- Blocking defects: `0`
- Material evidence gaps: `0`
- Non-blocking issues: `2`
- Optional improvements: `0`
- Correction finding IDs: `none`
- Next-slice finding IDs: `R0-01, R0-02`
- Human-decision finding IDs: `none`
- Detailed review receipt: `Independent Review section in the archived implementation packet and this review packet`
- Detailed review summary: `REVIEW_VEHICLE_RUNTIME_LIFECYCLE_HARDENING_V1_CLAUDE_SUMMARY.md`
- Follow-up workstream: `vehicle-field-scout-buggy-class-v1`

### Findings

#### R0-01 — P2, forced release can initially overlap blocked geometry

- Class: `non_blocking_issue`
- Domain: `runtime`
- Affected acceptance: Occupied disable/destruction must release and restore the Operator; preserve safe-exit semantics and avoid stranding.
- Evidence: `custodian/game/vehicles/pilotable_vehicle.gd:201-204,281-297,398-410`. When exit search rejects all positions, forced fallback returns the recorded entry position without rechecking collision/navigation. The fresh hostile probe used a 900×900 blocker; disable and lethal damage initially released at `(0,0)` while clearance was false, despite a clear candidate at `(480,0)`. The actor’s visibility, processing, collision, controller ownership, and camera were restored. Over 60 physics ticks Godot recovered/ejected the actor by 578.0738 px; no persistent softlock was reproduced.
- Disposition: `deferred`
- Rationale: The implementation restores the control and actor properties required by Acceptance, and the hostile case recovered rather than stranding the Operator. The initial overlap remains a safe-placement hardening opportunity for the Field Scout lifecycle slice.

#### R0-02 — P2, destruction after disable suppresses the destruction notification

- Class: `non_blocking_issue`
- Domain: `runtime`
- Affected acceptance: Damage/destruction lifecycle signaling and idempotent ownership release.
- Evidence: `custodian/game/vehicles/pilotable_vehicle.gd:188-211`. Repro: enter, disable, destroy, destroy. Observed release count `1`, disabled count `1`, destroyed count `0`; `is_destroyed` is true and health is zero. `_transition_to_disabled()` returns on the already-disabled state before `vehicle_destroyed.emit()`. Source inspection found no live `vehicle_destroyed` consumers; entry/driving rejection and the one-time controller/camera release remain correct.
- Disposition: `deferred`
- Rationale: No current consumer relies on the signal and the archived Acceptance does not require a distinct destruction notification after prior disable. Preserve this as a future lifecycle event-seam concern.

## Handoff

- Next workstream: `vehicle-field-scout-buggy-class-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `Only live API/path reconciliation unless findings invalidate the class boundary.`
- Next action: Claim the Field Scout class packet after this review is archived; carry the two non-blocking lifecycle hardening observations forward.
- Blockers or open questions: `none`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: `The claimed worktree had no Godot import/class cache, so initial raw script runs were not valid review evidence. The repository runner prepared imports; the focused smokes and hostile probe then passed.`
- Root cause / contributing factors: `Ephemeral worktree began without imported Godot cache.`
- Prevention / pipeline improvement: `Use the repository validation runner to prepare/import the worktree before direct focused Godot smokes.`
- Tooling / docs drift discovered: `Code-review graph was empty in the claimed worktree; source inspection used the documented fallback.`
- Follow-up: `vehicle-field-scout-buggy-class-v1`
- What worked: `A fresh independent probe repeated enter/exit five times and tested blocked-entry forced release plus disable-to-destruction signaling.`
