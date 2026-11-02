# Review: Vehicle Runtime Lifecycle Hardening V1

- Workstream: `review-vehicle-runtime-lifecycle-hardening-v1`
- Reviewed main: `b4759b996397227be19cee0f2e8d31ee7ad80688`
- Authoring chat: not-recorded
- Reviewer context: fresh
- Reviewer provenance: different-agent

## Result

**Passed; no blocking defects or material proof gaps.** The independent reviewer verified every archived acceptance clause against landed implementation and focused runtime evidence. The production `PilotableVehicle` is the sole lifecycle authority; `PlayerController` has one mutable current-vehicle reference; live legacy `VehicleBase`/`VehicleInteraction` consumers were not found. Blocked ordinary exit retains ownership and recovers; occupied disable, lethal destruction, and teardown restore the Operator and release controller/camera authority once; zero-health vehicles cannot be entered or driven; duplicate group discovery is removed; observability is transition-level.

Two non-blocking findings are deferred to the Field Scout lifecycle/class work:

- **R0-01, P2:** forced fallback initially places the pilot at the recorded entry coordinate even when blocked. A hostile 900×900 blocker probe confirmed the initial overlap, but Godot recovered the actor over 60 physics ticks (578.0738 px); no persistent softlock or acceptance failure was reproduced.
- **R0-02, P2:** destroying an already-disabled vehicle omits `vehicle_destroyed` because the disable transition returns early. Probe counts were release=1, disabled=1, destroyed=0. No live signal consumer exists, and all lifecycle acceptance behavior passed.

## Evidence

- `python3 custodian/tools/validation/run_validation.py --test vehicle_exit_clearance --json`: PASS, 1/1.
- `godot --headless --path custodian --script res://tools/validation/validate_vehicle_registry.gd`: PASS.
- `godot --headless --path custodian --script res://tools/validation/vehicle_runtime_lifecycle_smoke.gd`: PASS.
- Fresh hostile probe `/tmp/vehicle_runtime_hostile_review_v2.gd`: PASS; five enter/exit cycles, 10 camera handoffs, zero residual release connections, blocked-entry disable/lethal release restores actor and controller/camera state.
- The archived implementation packet and this review packet carry the durable findings and acceptance matrix.

Initial direct script attempts lacked the claimed worktree's import/class cache and were not used as evidence. The repository runner prepared imports, after which focused tests passed. The code-review graph was empty, so targeted source inspection followed its documented fallback. No reviewed implementation files were modified.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: Initial raw Godot script launches lacked the worktree's import/class cache.
- Root cause / contributing factors: Ephemeral checkout had not completed Godot import preparation.
- Prevention / pipeline improvement: Use the repository runner before direct focused Godot smokes in fresh checkouts.
- Tooling / docs drift discovered: Code-review graph was empty; source inspection used the documented fallback.
- Follow-up: vehicle-field-scout-buggy-class-v1
- What worked: Independent hostile probes measured repeated camera handoff and blocked-entry recovery directly.

## Next Handoff
- Next workstream: vehicle-field-scout-buggy-class-v1
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: Only live API/path reconciliation unless findings invalidate the class boundary.
- Next action: Claim the Field Scout class packet once this review is archived; carry R0-01 and R0-02 forward as deferred lifecycle hardening.
- Blockers or open questions: none
