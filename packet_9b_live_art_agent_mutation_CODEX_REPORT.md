# Packet 9B — Live Art Agent Mutation + Undo

## Commit

Pushed task commit: `39765d4d2712aa204f5583c59a8843e29a1f281c`
(`art agent live mutation, revision locking`).

## Files changed

- Shared Lua Art Agent executor and thin headless adapter.
- Persistent live-bridge protocol, live mutation/undo handlers, replay cache,
  revision stack, and presentation restoration.
- Relay mutation/undo routing and collision-safe fallback behavior.
- ArtSession live client/revision guards and service journaling/session rebasing.
- Focused relay fixture coverage and capability fixture updates.
- Packet 9B documentation in the live bridge, Art Agent, Workbench, current
  state, file index, and operator tooling docs.

## Results

- Full shared Lua executor: all listed read and mutation primitives route through
  `operator_live_bridge/art_agent_ops.lua`; the headless adapter only loads,
  validates through Ops, opens, saves changed workbenches, closes, and writes the
  response.
- Frame-count and capability/context validation: shared `Ops.validate` checks
  request/capability/manifest identity, context fingerprint, active document,
  canvas, and exact document frame count.
- ArtSession live revision model: additive `live_client_session_id` and
  `expected_live_revision` fields preserve old session JSON defaults.
- Live reads: matching reads use the in-memory sprite and rebase the session to
  the returned client/revision metadata.
- Live mutations: exact client/revision guards, one transaction callback,
  no-save behavior, one logical revision/document change per changed operation,
  and no headless fallback after a live match.
- Replay: session + operation key cache returns the first result and rejects
  request/payload mismatches.
- Failure handling: known failures report no-change; post-commit failures try
  one Aseprite undo; unprovable outcomes are reported separately and poison
  further live mutation/undo.
- Live undo: `command.art_agent_undo` uses Aseprite undo, checks the top Art
  Agent operation and exact revision/session, and never restores a disk backup.
  Human sprite changes clear Art Agent undo ownership.
- Collision guard: if the bridge endpoint is active while the relay is down,
  mutation refuses instead of launching a second headless Aseprite process.
- Draft/recolor: shared Ops routes draft primitives and recolor plans through
  the live-capable operation set; the existing headless draft/bake and semantic
  smoke passed.
- Disk Workbench immutability: headless regression preserves expected saved
  workbench behavior; live paths do not call saveAs.
- Production immutability: Art Agent smokes verify Operator source/runtime and
  actor production trees remain unchanged.

## Validation

Passed with the project Python environment:

```text
operator_art_agent_service_smoke.py
operator_art_agent_aseprite_smoke.py
operator_art_agent_live_relay_smoke.py
operator_live_bridge_smoke.py
operator_workbench_ui_smoke.py
operator_animation_preview_timeline_smoke.py
operator_animation_transition_smoke.py
operator_art_agent_transition_smoke.py
operator_motion_preview_smoke.py
```

The shared installed-Aseprite headless bridge and draft/semantic coverage both
passed. The focused live relay fixture covers read, mutation dispatch, stale
revision refusal, and undo command routing. A persistent GUI live mutation/undo
run was not available in this validation environment; no GUI lifecycle claim is
made here.

Changed validation selected 16 checks and reported 16 passed, 0 failed, and 0
timed out, but `run_validation.py --changed --json` returned exit code 6 and
`passed: false` because the changed-file selector includes the repository's
large unrelated dirty/generated tree. This remains validation-harness/reporting
drift, not a selected-check failure.

## Documentation drift

Packet 9A-deferred wording now points to Packet 10. Current State, File Index,
Art Agent System, Live Bridge, Workbench, and operator README describe live
reads, revision-locked unsaved mutation, replay, human invalidation, live undo,
and unknown-outcome fail-closed behavior.

## Packet 10

Packet 10 remains Workspace Polish. No gameplay, publication, Asset Pipeline,
or automatic-save work was added.
