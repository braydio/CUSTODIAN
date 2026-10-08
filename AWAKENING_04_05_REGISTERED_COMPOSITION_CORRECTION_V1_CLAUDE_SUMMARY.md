# Awakening 04→05 Registered Composition Correction V1

The three production layers now use the supplied registered 1502×2048 canvas under one shared root at `(349,-2585)`, scale `(1,1)`, rotation `0`. Dust, connector, and Locker keep the exact registered PNG bytes, layer order, bounds, and overlap; the retired independent connector fit/rotation is gone. The separate P-9 Designation Locker and gameplay geometry remain unchanged.

All four registered references matched their pinned hashes, dimensions, and RGBA mode. Asset V2 registered outputs are archived and bound to the existing three families. Runtime checks measured the expected 17,979 Dust/connector and 10,979 connector/Locker overlap pixels, zero Dust/Locker overlap, and 1,267 edge-only differences against the supplied composite. Bidirectional live Operator traversal recorded 1,025 samples on walkable floor with registered art beneath the Operator. The compact GL compatibility capture passed at 640×720 with visible bounds `[65,12,575,708]`.

The first changed-file validation run had one failure: the existing late-seams Moment Forge fixture required the retired Zone 05 room underlay and foreground to share bounds. Updated that fixture to probe the three registered runtime layers and require one common world canvas. Its no-capture Moment Forge run passed, and changed-file validation then passed all 28 selected checks with complete coverage and no failures or timeouts. The original test failure was a stale assertion, not a runtime registration defect. The finish coverage gate also revealed that the manually-run renderer smoke had no manifest entry; added an Xvfb-backed integration wrapper covering the capture. The final 28 selected checks all passed and coverage is complete. `git diff --check` passed. Asset V2 doctor reported healthy; the focused Awakening scene, progression, geometry, P-9, startup, pixel-contract, and traversal checks passed.

A renderer probe initially used the headless dummy renderer, which has no viewport pixels; reran through Xvfb with GL compatibility. Asset V2 imports were run per family after the first chained invocation stopped after Dust. Project-wide imports also generated unrelated Operator `.png.import` sidecars; those were removed and excluded from the change.

`origin/main` was fetched and merged at `d79741aa`; the merge completed without conflicts. No gameplay geometry, foreground redesign, 05→06 spine work, or unrelated roadmap behavior was included.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: renderer backend mismatch, stale Moment Forge bounds assertion, and missing manifest coverage for the renderer smoke required correction.
- Root cause / contributing factors: dummy headless mode cannot produce viewport pixels; scenario contract lagged the new shared canvas.
- Prevention / pipeline improvement: use GL compatibility for renderer capture; updated the late-seams scenario to assert all three registered layers share bounds and added its renderer wrapper to the validation manifest.
- Tooling / docs drift discovered: pre-registration Zone 05 underlay/foreground bounds equality and missing renderer-smoke manifest coverage; both fixed in-scope.
- Follow-up: fixed-in-scope
- What worked: hash-verified Asset V2 inputs and live Operator traversal provided independent asset and gameplay evidence.

## Next Handoff
- Next workstream: review-awakening-04-05-registered-composition-correction-v1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9
- Refresh reason: none
- Next action: land implementation and claim paired review from a fresh reviewer context, then continue to awakening-lower-upper-spine-connection if eligible.
- Blockers or open questions: none
