# Operator Workbench Browser Preview Disconnect Ownership Correction

## Result

Added immutable `PreviewOwnership` snapshots containing the bridge connection generation, client session ID, active document path, and requested revision. The generation advances at each accepted connection. Disconnect preserves last-known path and revision metadata but invalidates ownership.

Asynchronous preview command results now carry their issue-time ownership through the command cause context and projected event. The Workbench checks that token before loading and after each relevant await, including immediately before applying Preview, comparison, transition, and frame state. Synchronous F5 export carries the same token through image loading and returns to the saved Workbench preview when ownership is lost.

The pinned UI smoke now removes the fake client and calls the real `BridgeState.disconnect()` transition. It keeps path and revision intact, rejects a held result after disconnect and after reconnect to the same document/revision, verifies that a fresh connection result applies, and checks accepted object identities, frame/play state, raster data, filmstrip data, and persistent widget content. The Live Bridge smoke verifies ownership reaches projected command-result events.

## Validation

- `/tmp/custodian-opui/bin/python custodian/tools/validation/operator_workbench_ui_smoke.py` — passed, including optional Textual pilot.
- `/tmp/custodian-opui/bin/python custodian/tools/validation/operator_live_bridge_smoke.py` — passed.
- `/tmp/custodian-opui/bin/python custodian/tools/validation/run_validation.py --changed --json --tag operator` — passed; 7 selected checks, 7 passed, 0 skipped, complete changed-code coverage. This includes the Live Bridge, Workbench UI, and Godot motion-calibration integration checks.
- `git diff --check` — passed.

The first `python3 ... run_validation.py --changed --json` attempt used the system interpreter, which lacks `websockets`; its Live Bridge unit failed and dependent integration was skipped. The finalized unfiltered run under the pinned interpreter selected nine tests and exposed a separate existing `review_pairing_contract` failure: `REVIEW_OPERATOR_2_5D_CANONICAL_VISUAL_CONTRACT.md` lacks the required bounded `TASK OVERRIDE`. The Operator-tagged changed run passed all seven checks with complete changed-code coverage. The separate packet issue is recorded for manual follow-up and was left untouched.

## Negative Controls and Deferred Work

- Disconnect preserves active path/revision, but `_live_document_matches_selection` and token ownership fail while disconnected.
- A result issued on connection A remains stale after connection B reconnects to the identical document and revision; a fresh B result applies.
- Existing document-switch, UI generation, selection, source, output path, revision, compare/transition await, and saved-preview fallback controls remain green.
- No FX-layer adoption, publication, asset mutation, gameplay timing, or renderer work was performed. FX-layer adoption remains gated on the paired review.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: System Python lacked `websockets`; the finalized unfiltered changed run also exposed an unrelated review-packet override contract failure.
- Root cause / contributing factors: The default interpreter lacks the Operator UI optional dependency; the existing 2.5D review packet lacks the bounded override required by the review-pairing test.
- Prevention / pipeline improvement: Use the pinned Operator UI interpreter for Operator coverage and add the required override when that review packet is next maintained.
- Tooling / docs drift discovered: `REVIEW_OPERATOR_2_5D_CANONICAL_VISUAL_CONTRACT.md` lacks a bounded `TASK OVERRIDE`.
- Follow-up: manual-follow-up: `REVIEW_OPERATOR_2_5D_CANONICAL_VISUAL_CONTRACT`
- What worked: Ownership tokens provide an explicit connection lifetime while retaining last-known editor metadata.

## Next Handoff
- Next workstream: review-operator-workbench-browser-preview-disconnect-ownership-correction
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab
- Refresh reason: none
- Next action: Claim the paired fresh-context review and verify the durable implementation evidence before any FX-layer adoption.
- Blockers or open questions: none
