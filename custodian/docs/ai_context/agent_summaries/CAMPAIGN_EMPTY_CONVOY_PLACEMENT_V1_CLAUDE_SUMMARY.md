# Empty Convoy Placement V1

## Result

Implemented the first Empty Convoy slice as a deterministic optional generated-world site. The authored 12x10 pocket is inserted only when its complete footprint belongs to the main playable component and its two-tile clearance avoids route, ingress, road, parking, objective, escape, and reserved-region semantics. Candidate safety is rechecked immediately before tile authority is claimed. Unsafe seeds skip without failing generation.

The scene presents three outward-facing static wreck silhouettes around an empty cargo cradle and a physical manifest plate. The manifest is inspectable and reports `IN TRANSIT / DISPATCH ABSENT / RECEIPT UNACKNOWLEDGED`; it does not mutate campaign state. Streaming reveal/unload/reveal retains one site and the same placement fingerprint.

The active task packet was updated before closeout to enumerate the exact changed paths and record this authoring chat.

## Evidence

- Focused iteration smoke: 4/4 generated seed scenarios passed, with 3 valid placements and 1 safe skip. It checked deterministic planning, footprint navigation and protected semantics, real scene realization, manifest inspection, and reveal idempotence.
- Committed-source changed-file validation: `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json` — 5/5 selected checks passed; complete changed-file coverage; zero failures, timeouts, skips, or infrastructure errors.
- Validation report: `/tmp/campaign-empty-convoy-placement-validation.json`, SHA-256 `bc0db96d3a41e6cbb32ba06935eb1464c0d96a0ee1cfbfe8b63ee63d35219b50`.
- Validated source commit `47fd0755203dc22fb7149889253154741c78689b`, tree `afec464c5925c6e4d3666c73677157e3b1f0a607`; worktree was clean and unchanged during validation.
- The Godot smoke emitted the existing report-classified `known_exit_object_leak` and `known_exit_resource_leak` warnings.

## Friction and deferred work

The first smoke drafts exposed dynamically typed test arguments, a fixture that was too small to yield a valid pocket, and an invalid attempt to free a `RefCounted` helper. These were corrected; the final focused and committed-source validations passed. No unrelated infrastructure or visual review was added. C2 security and C3 trace/salvage remain out of scope.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: Initial smoke iterations used untyped arrays for a dynamically called typed API, assumed a 96x80 map would contain a 12x10 navigable pocket, and attempted to free a `RefCounted` helper.
- Root cause / contributing factors: Dynamic GDScript calls enforce typed-array signatures at runtime; generated terrain at the smaller fixture size did not contain an eligible site; `RefCounted` objects are released by reference lifetime.
- Prevention / pipeline improvement: Keep fixture arguments explicitly typed, use sufficiently large generated maps for large authored pockets, and do not manually free `RefCounted` helpers.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: Four real generated seeds verified safe placement/skip behavior and streaming idempotence before committed-source coverage validation.

## Next Handoff

- Next workstream: `review-campaign-empty-convoy-placement-v1`
- Next packet state: audit the paired review after implementation lands; launch only if eligible and authorized by the coordinator
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae7eb07-c554-83e9-911a-1335e640e4d0
- Refresh reason: none
- Next action: canonical `workstream.py finish`, then report actual paired-review eligibility without launching a reviewer under the current control
- Blockers or open questions: none reported; landing and teardown receipts pending
