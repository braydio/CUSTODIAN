# F14-C1 Real Enemy Physical/Abstract Handoff

Workstream: `living-world-entity-reification-handoff`
Branch: `agent/living-world-entity-reification-handoff`
Run: `20261009T140835Z-918053e16944`

## Delivered

- Added domain-scoped stable `actor_id`, representation mode and bounded Grunt projection to abstract group state. Abstract state schema v2 reads v1, and world snapshot migration recalculates schema-v5 fingerprints when upgrading v1 abstract state, including pre-correction event IDs.
- Added a fixed-step boundary signal to `SimulationKernel` and a Grunt-specific coordinator. Requests are queued until the next boundary; the coordinator validates identity/site/lifecycle state, removes the actor tree before abstract ownership, and stages the actual Grunt with its projected state before enabling it under physical ownership.
- Abstract patrol advancement now suspends while physical ownership is recorded and follows the group’s location while abstract. Actor IDs are unique within a domain; projection fields, health fraction and location are validated before state mutation.
- Added and registered a focused smoke using the real `enemy_grunt.tscn`, synthetic locations A/B, snapshot restore, deterministic continuation, repeated unload/reentry, and negative ownership checks. No production geography, camp, procgen streaming or runtime auto-binding was added.

## Validation

- `godot_import_preflight.py --project-dir custodian`: PASS.
- Focused handoff smoke: PASS. Includes two unload/reentry cycles; same-boundary duplicate requests; duplicate actor identity; pending spawn/projectile; active attack; dying/corpse/loot; invalid site; rejected projection commit with actor rollback; rejected staged Grunt restore with no leaked actor; physical tick suspension; schema-v5 legacy event ID restore; and deterministic replay fingerprint/event comparison.
- Existing abstract activity, kernel, macro-state and snapshot-roundtrip smokes: PASS.
- `procgen_ambient_enemy_real_world_spawn_smoke.gd`: exited successfully.
- `run_validation.py --changed --json`: PASS, 15/15 selected validations, 0 failed. The generated-region lifecycle validation emitted its expected negative-path diagnostics while passing.
- `git diff --check`: PASS.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: The first direct smoke run caught an indentation error in the state deserializer change.
- Root cause / contributing factors: A narrow edit changed indentation inside the nested event-validation loop.
- Prevention / pipeline improvement: Ran the focused parser and smoke before the broader validation sweep.
- Tooling / docs drift discovered: none
- Follow-up: `review-living-world-entity-reification-handoff`
- What worked: The focused real-Grunt smoke gave deterministic evidence for both ownership directions and migration without expanding into production streaming.

## Next Handoff

- Next workstream: `review-living-world-entity-reification-handoff`
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Refresh reason: none
- Next action: Claim the paired post-land review from a fresh reviewer context and review only the landed implementation evidence.
- Blockers or open questions: none
