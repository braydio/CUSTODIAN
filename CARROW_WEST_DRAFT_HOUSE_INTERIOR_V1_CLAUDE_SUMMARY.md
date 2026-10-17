# Carrow West Draft House Interior V1

Workstream: `carrow-west-draft-house-interior-v1`

Implemented the named-room seam and a playable 12×10 West Draft House. The room is created only from the generator's `west_draft_house` site, placed off-map without overlapping the East Machine House, and uses the exact approved symbol grid, 120 registered floor tiles, eight existing registered art placements, two art-bound storage interactions, collision boundaries, lighting, and room-specific doors. One `active_interior_id` now selects room camera/environment bounds; existing East door APIs remain compatible and its 14×10 layout, 140 floor tiles, 13 art placements, three storage interactions, and debug shape are preserved.

The smoke verifies default and alternate generated-site binding, East/West room bounds, entry and exit, outdoor/indoor weather, camera selection, actor ownership, same-runtime storage depletion, malformed grid and doorway rejection, missing-site/art rejection, collision allocation overlap rejection, East parity, and the existing Transfer Frame behavior. A missing-art fixture initially generated loader errors, and the first typed-load guard exposed a GDScript cast precedence error. Both were fixed; the final focused run passes without warnings. Editor scanning also generated two unrelated `.uid` files; they were removed explicitly.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: A negative fixture using a missing art path logged loader errors, then an unparenthesized cast expression failed GDScript parsing during the guard correction.
- Root cause / contributing factors: Resource paths must be existence-checked before loading, and casts in compound boolean conditions need explicit parentheses.
- Prevention / pipeline improvement: The runtime guard now checks resource existence and type; the negative fixture verifies missing art fails closed without engine error output.
- Tooling / docs drift discovered: Editor scans produced unrelated `.uid` sidecars, explicitly removed before finalization.
- Follow-up: review-carrow-west-draft-house-interior-v1
- What worked: Focused real-scene validation covered site binding, room selection, camera/weather changes, storage persistence, and preserved East behavior.

## Validation
- `python3 custodian/tools/validation/run_validation.py --test carrow_yard_interior --json`: passed, no warnings.
- `python3 custodian/tools/validation/run_validation.py --test persistent_compound_layout --json`: passed.
- `godot --headless --path custodian --script res://tools/validation/carrow_backdrop_isolation_smoke.gd`: passed, four transitions.
- Changed-file validation report: `/tmp/carrow-west-changed-final.json`; 4 selected, 4 passed, 0 failed, 0 timed out, 0 skipped, complete coverage.
- `git diff --check`: passed. Packet index and review-pairing checks passed as part of the changed-file sweep. The targeted packet-authoring validator rejects archived packets by design, so it could not be rerun after archival.

## Next Handoff
- Next workstream: review-carrow-west-draft-house-interior-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: Run the paired independent review after this implementation lands and archives.
- Blockers or open questions: none
