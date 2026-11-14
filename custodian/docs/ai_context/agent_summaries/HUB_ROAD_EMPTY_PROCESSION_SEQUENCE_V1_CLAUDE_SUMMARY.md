# Hub Road Empty Procession Sequence V1

## Result

Implemented the first playable authored Hub event in the post-Awakening `HubRuntimeHost` / `HubFirstSetMap`. A real Operator walks from `Spawn_SouthReach` north through three spatial triggers toward ForumSouth. Each ordered beat creates a short local lamp glow and bell tone. Beat progress persists in `HubState`; a partial restore resumes at the next beat, and a completed event does not replay.

The Hub map integration reads the existing Hub campaign authority and adds one local sequence controller. It does not use the Awakening Road prototype, alter Road collision/navigation or plates, create a Contract, or add global event/lighting/audio systems. Presentation uses temporary runtime lights and generated tones; no commissioned art was required.

## Evidence

- `python3 custodian/tools/validation/run_validation.py --changed --test hub_road_empty_procession --json`: PASS; real Operator moved from `(-6, 162)` to `(-6, -2508.583)`, completed south/middle/north order, and restored a partial save at middle/north with no Hub generation or Contract prewarm.
- `python3 custodian/tools/validation/run_validation.py --test hub_first_set_blockout --json`: PASS; H1 route and clearance.
- `python3 custodian/tools/validation/run_validation.py --test world_transition_handoff --json`: PASS; Hub handoff and authority invariants.
- `python3 custodian/tools/validation/run_validation.py --test hub_forum_adjudication --json`: PASS; Forum/Dais route and campaign authority.
- `godot --headless --path custodian --script res://tools/validation/campaign_outcome_exactly_once_smoke.gd`: PASS.
- `git diff --check`, manifest JSON parse, and task-packet index check: PASS.

## Friction and deferred work

The fresh worktree initially lacked Godot's import/class cache, so the first direct script launch failed before the smoke could run. Import preflight and project import resolved it. An early backward-compatibility fixture also omitted the existing `campaign_history` snapshot field; it was corrected to derive from the actual old HubState snapshot. Neither issue remains.

The event intentionally has no testimony content, permanent regional state, new artwork, or subjective visual signoff. Any later aesthetic review should focus on the compact in-game presentation. The paired independent review will verify the landed implementation and real-Operator route.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The fresh worktree lacked Godot's import/class cache on the first direct launch; an initial backward-compatibility fixture omitted the existing campaign_history field. Both were resolved before final validation.
- Root cause / contributing factors: First-run Godot import state was absent; the test fixture did not use the actual legacy HubState snapshot shape.
- Prevention / pipeline improvement: Run import preflight and project import before focused Godot smokes in fresh worktrees; derive legacy fixtures from HubState.snapshot() and remove only newly introduced fields.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: Physical Operator traversal and restored event snapshots gave deterministic route, order, and idempotency evidence.

## Next Handoff
- Next workstream: review-hub-road-empty-procession-sequence-v1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: Run the paired fresh-context review through paired_review_runner.py.
- Blockers or open questions: none
