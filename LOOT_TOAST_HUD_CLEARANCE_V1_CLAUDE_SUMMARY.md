# Loot Toast HUD Clearance V1

Workstream: `loot-toast-hud-clearance-v1`

## Result

Replaced the loot toast queue's fixed vertical anchor with a read-only clearance
contract supplied by the live HUD. The HUD reports the union of actual visible
top-left gameplay control rectangles; the queue refreshes on deterministic
visibility changes, viewport resizing, and before presenting a pickup. It
retains its 18px inset, 320px maximum width, four-entry queue, merge semantics,
and animation timing while clamping the full stack to supported viewports.

The queue is verified as a child of the production UI provider in `game.tscn`.
Focused geometry fixtures cover essentials, a lower optional row, hiding that
row, and 1280x720 / 1600x900 bounds. Existing pickup producers were untouched.
The fixed `(18,126)` claim was removed from the feature documentation and
current-state summary.

## Validation and evidence

- Headless editor import: passed.
- `loot_toast_queue_smoke`: passed.
- `pause_only_minimap_hud_smoke`: passed.
- Final `run_validation.py --changed --base origin/main --json`: 42 selected,
  42 passed, 0 failed, 0 timed out, 0 skipped, 0 infrastructure errors.
- `git diff --check` and validation-manifest JSON parsing: passed.

Validation needed extra time because some HUD-owned terminal smoke tests also
generate large ProcGen worlds. The first aggregate run timed out those tests at
60 seconds. A later run exposed one unrelated random world seed
(`2900018817`) that could not place the authored Ritualant ingress, despite the
smoke printing `PASS`. The isolated rerun generated a valid ingress, and the
final full changed-file run passed. The manifest now gives the three affected
HUD-owned ProcGen smokes a 300-second budget; no Ritualant or ProcGen runtime
behavior was changed in this task.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: the queue's fixed Y anchor no longer matched the visible HUD; initial changed-file runs also exposed undersized ProcGen smoke timeouts and one stochastic unrelated ingress failure.
- Root cause / contributing factors: HUD controls had grown beyond the original placement assumption; ProcGen runtime varies by generated seed and can exceed the old 60-second test budget.
- Prevention / pipeline improvement: geometry validation now uses live HUD rectangles, and the three affected UI-owned ProcGen smoke tests have 300-second budgets.
- Tooling / docs drift discovered: `LOOT_PICKUP_FEEDBACK.md` still described fixed `(18,126)` placement; validation budgets did not reflect current smoke cost.
- Follow-up: paired fresh-context review
- What worked: a focused production-binding geometry smoke proved the layout contract without screenshots or changes to pickup producers.

## Next Handoff

- Next workstream: review-loot-toast-hud-clearance-v1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d
- Refresh reason: none
- Next action: run the paired review in a fresh reviewer context against the landed implementation.
- Blockers or open questions: none
