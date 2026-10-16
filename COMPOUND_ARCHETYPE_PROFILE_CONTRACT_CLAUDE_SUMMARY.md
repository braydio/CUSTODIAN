# Compound Archetype Profile Contract

Workstream: `compound-archetype-profile-contract`

The persistent compound planner now accepts the validated `legacy`,
`walled_yard`, and `connected_bunker` profile IDs from a single versioned JSON
catalog. The runtime selector defaults to `legacy`. Explicit profile selection
adds versioned archetype and layer metadata to rooms, connectors, and exported
level data while retaining the current surface geometry, room IDs, Sector
mapping, connector identities, minimap inputs, and old planner calls. The
unqualified planner call still returns the prior layout dictionary shape.

The two new archetype IDs are selectors and data contracts only. They do not
claim the future walled perimeter, gates, subsurface room graph, or physical
vertical links. All profiles report `layer_id: surface` until downstream
blockout and traversal work adds real geometry.

## Changed files

- `custodian/game/world/compound/rooms/profiles/compound_archetype_profiles_v1.json`
- `custodian/game/world/compound/rooms/persistent_compound_layout_planner.gd`
- `custodian/game/world/procgen/proc_gen_tilemap.gd`
- `custodian/game/world/procgen/generation/accepted_world_export.gd`
- `custodian/tools/validation/compound_archetype_profile_smoke.gd`
- `custodian/tools/validation/procgen_accepted_world_export_smoke.gd`
- `custodian/tools/validation/validation_manifest.json`
- `design/02_features/procgen/COMPOUND_ARCHETYPES_AND_SECURITY_V1.md`
- `design/02_features/procgen/PERSISTENT_COMPOUND_LAYOUT_SYSTEM.md`
- `custodian/game/world/compound/rooms/README.md`
- `custodian/docs/ai_context/CURRENT_STATE.md`
- `custodian/docs/ai_context/VALIDATION_RECIPES.md`
- `custodian/docs/ai_context/task_packets/COMPOUND_ARCHETYPE_PROFILE_CONTRACT.md` (archived at closeout)

## Acceptance and validation

The focused profile smoke passed across seeds `1, 2, 3, 10, 42, 99, 1337` for
all three IDs. It checks repeated output equality, profile metadata, unchanged
legacy geometry and connectors, unknown-ID fail-closed behavior, unique room
IDs, valid room/connector references, and the three level-data export fields.
The existing `persistent_compound_layout_smoke` also passed.

The existing `persistent_compound_runtime_smoke` passed after the worktree's
Godot import cache was populated. Godot still reports three resources in use at
exit; the smoke emitted its pass sentinel and returned success. The accepted
world export parity smoke first caught the intentional three-key level-data
addition (`69` to `72` keys). Its expected hash and key count were updated; the
fixed parity run is included in the changed-file sweep below.

Changed-file validation:

- Command: `python3 custodian/tools/validation/run_validation.py --changed --base HEAD --json`
- First result: 43 passed; `procgen_accepted_world_export_parity` failed on its stale expected hash/key count; 30 higher-tier tests were skipped.
- Corrective change: updated the exact export hash to `2224671067` and key count to `72`; the runtime fingerprint hash remained `2896026968`.
- Final result: passed, 74/74 selected tests, zero failures, timeouts, skipped checks, infrastructure errors, or uncovered changed files. Machine-readable report: `/tmp/compound-archetype-changed-validation-rerun.json`.

`git diff --check` and JSON parsing of the profile catalog passed. No image or
renderer review was needed because this slice changes metadata and selector
behavior only.

## Negative controls and deferred work

The explicit invalid profile `unknown_profile` returns `valid: false` with
`failure_reason: unknown_archetype_id`. The test compares each selected profile
to the unqualified legacy planner result after removing only the newly added
metadata, so profile selection cannot silently alter the graph or current
geometry.

Physical archetype generation, gates/security, continuous subsurface travel,
and runtime recovery gameplay remain deferred to their dependency-gated
workstreams. No art was created or ingested.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: the coordination checkout was 52 commits behind and had an unrelated dirty packet; a stale claim observation referenced a review packet absent from current `origin/main`; the export parity fixture required a deliberate update after adding the three metadata keys.
- Root cause / contributing factors: dispatch state was first observed before fetching `origin/main`; the parity test pins the entire level-data schema by hash and key count.
- Prevention / pipeline improvement: fetch current `origin/main` before interpreting claim state; update the parity fixture whenever an additive level-data contract changes.
- Tooling / docs drift discovered: `paired_review_runner.py` correctly rejected the stale review observation because no active packet existed; no implementation scope changed.
- Follow-up: none
- What worked: isolated dispatcher claim, deterministic fixed-seed acceptance, and the existing single-owner level-data export path.

## Next Handoff

- Next workstream: `review-compound-archetype-profile-contract`
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-9156-be4e5c2851c0
- Refresh reason: none
- Next action: after implementation lands and archives complete, start the fresh-context paired review with `paired_review_runner.py`.
- Blockers or open questions: none; physical archetype geometry and gameplay are explicitly deferred.
