# Awakening Collision Mapper Authoring Bridge V1 — Checkpoint Summary

## Outcome

Partial implementation is committed to the workstream branch and remains open.
The Awakening-specific authoring bridge and its changed-file suite are green, but
the packet's required existing Sundered Keep mapper smoke fails against current
main's existing Sundered data. AP0 was not retried because this implementation
pair is not finished and main has not been landed/synchronized.

## Changes

- Replaced Awakening's generic source-writing mapper entrypoint with a scoped
  Awakening mapper. Enter/U only finish a chain; Ctrl+S writes an atomic,
  parse/readback-verified JSON draft with Layout/scene Git blob SHAs, exact world
  vertices, owner, purpose, geometry type, snap, source-collider replacement
  intent, and source-art coordinates when a sprite covers the geometry.
- Added actual instantiated `CollisionShape2D` and `CollisionPolygon2D` inventory
  with world-space points, canonical zone IDs, owner paths and blocker/trigger
  classification. The preview keeps actual art visible and disables target
  gameplay processing.
- Added zone focus, 1px/4px snap, proposal edit/insert/delete/undo/redo, protected
  route/Layout/collider/registered-art overlays, source-collider adjustment
  proposals, and truthful disabling of unimplemented marker/region modes.
- Added dry-run guards for malformed/missing-owner/stale drafts, connector and
  threshold overlap, 05→06 passage closure, 128px route narrowing, 11px Operator
  clearance, protected spawn/locker/lift overlap, and a 16px occupancy route
  failure. Production Layout and runtime scene/script remain untouched.

## Validation

- `awakening_collision_mapper_bridge`: PASS (1/1), including gate pylon center
  and 240×496 bounds, 272px gap, real wall/void/Road collision inventory,
  registered 04→05 sprite bounds, process isolation, runtime-file immutability,
  serialization, provenance/route negatives, and source-owner undo/redo.
- `awakening_first_return`: PASS (1/1).
- `awakening_first_return_geometry`: PASS (1/1).
- `authored_level_mapper_framework_smoke.gd`: PASS.
- `level_collision_poi_mapper_smoke.gd`: PASS.
- `sundered_keep_mapper_smoke.gd`: FAIL (5 assertions). The underlying current
  level JSON already has `mapper_placements`, contrary to the smoke's expected
  empty initial placement set; the same test reports preview, rail-count, and
  spawn-parity mismatches. Generic/Sundered mapper code and data were not changed.
- `run_validation.py --changed --base origin/main --json`: PASS, 40 selected,
  40 passed, 0 failed, 0 timed out, 0 skipped.
- `check_ai_context.py --json`: PASS; `task_packet_index.py`: PASS;
  `validate_review_pairing.py`: PASS (101 pairs); `git diff --check`: PASS.
- Moment Forge: not run — this changes the mapper authoring tool, not game feel,
  movement, timing, or production presentation.
- Human visual review: not requested; subjective baseline acceptance is not part
  of this tool bridge, and the post-land reviewer remains required.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: blocked
- Friction severity: medium
- What went wrong: the explicit Sundered Keep preservation smoke failed despite
  40/40 changed-file checks passing.
- Root cause / contributing factors: the Sundered smoke's initial-placement,
  preview, rail-count, and spawn expectations disagree with current main's
  authored Sundered documents; those files are outside this workstream.
- Prevention / pipeline improvement: reconcile that smoke in its own scoped
  task before using it as a green preserve gate.
- Tooling / docs drift discovered: standalone Sundered regression failure is not
  selected by changed-file validation when no Sundered owner files changed.
- Follow-up: manual-follow-up
- What worked: keeping all new preview/persistence behavior Awakening-specific
  preserved the generic mapper implementation.

## Next Handoff

- Next workstream: awakening-collision-mapper-authoring-bridge-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: reconcile the Sundered smoke against current main in a scoped
  change or obtain an authoritative baseline result, then rerun the required
  focused preserve set and finish the mapper packet through workstream.py.
- Blockers or open questions: Sundered smoke fails five assertions; user-authored
  collision promotion remains deferred; paired post-land review remains required.
