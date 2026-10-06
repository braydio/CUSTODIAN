# OPERATOR WORKBENCH BROWSER PREVIEW DISCONNECT OWNERSHIP CORRECTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-workbench-browser-preview-disconnect-ownership-correction`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `operator-workbench-ui`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-operator-workbench-browser-preview-disconnect-ownership-correction`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `f64ee5c71ebb42ed7e192fccb71dec4fba3664d9`
- Human authorization basis: `R2-01 from the exhausted browser/PREVIEW correction chain was returned to this authoring chat. The user supplied that human-required handoff here; this packet is the explicit bounded successor decision, not automatic cycle 3 of the exhausted lineage.`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Make Live Bridge preview results valid only for the exact bridge connection/session lifetime that issued them, so a disconnect or reconnect cannot authorize a held asynchronous or synchronous preview result merely because document path, revision, UI generation, and selection still match.
- Completion boundary: Done when actual Live Bridge disconnect and disconnect→reconnect transitions invalidate in-flight/held preview ownership across every live-image await; document path/revision may remain preserved as last-known presentation metadata, but they cannot independently authorize result application; accepted Preview/comparison/transition/frame/play/widget state remains unchanged on stale results; fresh results from the current connection still apply; the expanded pinned UI smoke invokes the real disconnect transition rather than simulating it by clearing only the document path; FX-layer adoption is dependency-gated on the paired review.
- Finding authority:
  - `R2-01` in `REVIEW_OPERATOR_WORKBENCH_BROWSER_PREVIEW_REFRESH_HARDENING_REVIEW_CORRECTIONS_1_REVIEW_CORRECTIONS_2_CLAUDE_SUMMARY.md`.
  - Reviewed implementation target recorded there: landed main `032d5f037bc846a0b7d291d27300645fcab2ea34`; correction commit `b2b5b155b40fb32211da63802a3ef27336e4719e`.
  - The independent reproduction exercises real app debounce → controller issue context → server command/result → actual `BridgeState.disconnect()` while the image loader is held, and proves stale bytes reach the primary Preview/widget state.
- Current measured state:
  - `live_bridge/state.py::disconnect()` sets `connection=DISCONNECTED`, clears `client_session_id` and pending commands, but intentionally preserves `active_document_path` and `document_revision`.
  - `ui/app.py::_live_document_matches_selection()` currently checks only the preserved active path against the selected Workbench path. It does not require a connected bridge or continuity with the client session that issued the result.
  - `ui/live_bridge_controller.py::_preview_request_context` records only UI generation, semantic identity, and source. `LiveBridgeEvent` therefore cannot prove which client connection lifetime issued a command result.
  - Synchronous `request_preview_export()` validates the detached result payload but does not expose or enforce bridge-session ownership across the later image-loader await.
  - The existing UI smoke models disconnect by setting `active_document_path=None`, which is not the real state transition and therefore misses the defect.
  - Document-switch ownership guards from correction cycle 2 are otherwise working; this task must preserve them and add the missing independent connection/session dimension.
- Task-specific authority: Live Bridge state/server/controller ownership semantics and the active Operator Workbench PREVIEW acceptance contract. Historical correction packets remain evidence, not executable authority.
- Work surface: `custodian/tools/operator/live_bridge/state.py`, `custodian/tools/operator/live_bridge/server.py`, `custodian/tools/operator/ui/live_bridge_controller.py`, `custodian/tools/operator/ui/app.py`, `custodian/tools/validation/operator_workbench_ui_smoke.py`, and only narrowly necessary Workbench docs/current-state/index text.
- Change:
  1. Add one monotonic bridge connection/session ownership generation in the Live Bridge state. It must advance on every accepted client connection. A disconnect leaves the last-known editor metadata available for presentation, but marks it non-owning because the bridge is disconnected. A subsequent reconnect, even to the same path/revision, has a different ownership generation.
  2. Expose one immutable ownership snapshot/token for live result authorization. At minimum it must prove: bridge is CONNECTED, current connection generation, current client session identity when available, selected/active document path, and requested document revision. Prefer a small typed value/helper over repeated ad-hoc tuple assembly.
  3. Capture that ownership snapshot at the exact command-issue boundary for asynchronous `export_preview`. Extend the existing preview request context / `LiveBridgeEvent` projection so the result retains its issuing connection ownership alongside UI generation, animation identity, and source.
  4. Capture the same ownership for synchronous `request_preview_export()`. The detached export contract or a controller-owned wrapper must carry enough issue-time ownership to revalidate after every later await. Do not make callers infer ownership from current state after the fact.
  5. Replace path-only live-document authorization with one shared guard that requires the current bridge to be CONNECTED and the current ownership snapshot to match the issue-time ownership when accepting a result. Preserve the existing path/revision/generation/selection/source checks as additional independent gates.
  6. Revalidate ownership at **every mutation boundary after an await** in the asynchronous result path, including after detached image loading and immediately before accepted Preview/widget state mutation. A disconnect while bytes are loading must leave all accepted Preview/comparison/transition object identities, frame/play state, raster/filmstrip bytes, and persistent widget content unchanged.
  7. Apply the same post-await ownership barrier to the synchronous live-export/image-loader path. On ownership loss, fall back to the existing saved/canonical preview behavior where that path already defines a fallback; do not apply the detached live image.
  8. Handle disconnect→reconnect explicitly: a held result issued by connection A must remain stale after connection B reconnects to the identical Workbench at the identical revision. A fresh result issued by B must still apply.
  9. Do **not** clear `active_document_path` or reset `document_revision` merely to make tests pass. Last-known editor state may remain visible/readable while disconnected; authorization must come from connection ownership, not metadata erasure.
  10. Update the pinned UI smoke to use the actual disconnect transition used by `LiveBridgeServer._handle_client(...).finally`: connected state → `state.disconnect()` and client removal. Keep document path/revision equal in the negative control so the test proves ownership, not path mismatch.
  11. Add a reconnect negative control with the same document path/revision and a fresh connection generation. Prove the pre-disconnect held result is rejected and a new current-session result applies.
  12. Keep this slice presentation-only. No FX-layer adoption, saved-layer inspection, publication, asset mutation, animation/gameplay timing, or general Live Bridge redesign.
- Preserve:
  - Last-known document path/revision metadata across disconnect unless a separate existing state contract already clears it for another reason.
  - Existing document-switch, generation, selection, source, output-path, revision, comparison, transition, frame/play, and widget preservation barriers from R0/R1/R2.
  - Live Bridge loopback/server lifecycle and Art Agent relay behavior outside result ownership.
  - Saved/canonical fallback semantics.
  - Existing browser stabilization and atomic PREVIEW refresh behavior.
- Non-goals:
  - No automatic reconnect policy.
  - No clearing/rebuilding the entire UI on disconnect.
  - No changes to Aseprite document contents.
  - No Workbench FX adoption or publish-path work.
  - No attempt to reconstruct the historic crash; this packet closes the reproduced ownership defect only.
  - No acceptance exception for R2-01.
- Acceptance:
  1. The exact executable R2-01 asynchronous reproduction from the cycle-2 review now passes with the final safety assertion: actual disconnect during held live-image loading does not change accepted preview object, comparison/transition state, frame/play state, raster/filmstrip bytes, or persistent widget content.
  2. The synchronous image-loader reproduction rejects a result after actual disconnect and uses the existing saved fallback; the document-switch control continues to pass.
  3. A new disconnect→reconnect fixture holds path, revision, animation identity, preview generation, and source constant. Result issued by connection A is rejected after B connects; result freshly issued by B applies.
  4. A simple disconnect with no reconnect cannot pass `_live_document_matches_selection` or the new ownership authorization guard solely because last-known document metadata matches.
  5. A current connected result with unchanged ownership still applies, proving the guard is not a blanket live-preview disable.
  6. Existing R0-01/R0-02/R0-03 fixes and R1 document-switch controls remain green.
  7. The UI smoke invokes the real state disconnect path; no test fakes disconnect only by setting `active_document_path=None`.
  8. No production code clears document path/revision as a substitute for ownership validation.
  9. Changed-file validation has complete coverage and `git diff --check` is green.
- Validation:
  - Re-run the cycle-2 executable async disconnect proof and synchronous image-loader proof from the durable review summary, updating only imports/fixture seams mechanically if live paths moved.
  - Extend `custodian/tools/validation/operator_workbench_ui_smoke.py` with real disconnect, reconnect/same-document, and current-session positive controls.
  - Run the pinned Textual environment used by the prior review, not a runner that skips optional Textual coverage.
  - Run the smallest relevant Live Bridge/controller focused tests if present.
  - Finish with `python3 custodian/tools/validation/run_validation.py --changed --json` and `git diff --check`.
  - No renderer capture, Moment Forge, or subjective visual review is required.
- Task overrides: `HUMAN OVERRIDE (2026-10-06): the authoring conversation explicitly selects a bounded disconnect-ownership correction after automatic review cycle 2 reached its cap. This is a new human-authorized successor workstream with its own paired review, not automatic correction cycle 3 of the exhausted lineage.`
- Deferred: Any broader connection-status UX cleanup or generic session-lease abstraction beyond what this defect needs.

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh instruction: Re-read live state/server/controller/app and the cycle-2 review reproduction before mutation. Mechanical line/path drift may be reconciled. If current main has materially changed the connection-ownership model or already closes R2-01, stop and prove that instead of layering a duplicate mechanism.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `intentionally-preserved; existing document-switch and saved-preview fallback paths remain in use`
- Evidence: `PreviewOwnership tokens bind each live result to the connected bridge generation, client session, active document path, and revision. The pinned UI smoke exercised actual disconnect, same-document reconnect, stale A rejection, current B acceptance, and the synchronous saved-preview fallback. Changed validation passed all 7 selected checks with complete coverage; git diff --check passed. See OPERATOR_WORKBENCH_BROWSER_PREVIEW_DISCONNECT_OWNERSHIP_CORRECTION_CLAUDE_SUMMARY.md.`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `The system python3 changed-file run could not import websockets. The finalized unfiltered changed run also selected review_pairing_contract, which fails on the unrelated REVIEW_OPERATOR_2_5D_CANONICAL_VISUAL_CONTRACT packet's missing bounded TASK OVERRIDE. The pinned Operator UI interpreter's Operator-tagged changed run passed all 7 scoped checks with complete coverage.`
- Root cause / contributing factors: `The default interpreter lacks the optional Operator UI websockets dependency; a separate active review packet predates the required review-artifact commit override.`
- Prevention / pipeline improvement: `Use the documented pinned Operator UI interpreter when changed validation selects Live Bridge or Textual UI coverage; repair the separately named review packet before expecting the unfiltered packet-doc sweep to pass.`
- Tooling / docs drift discovered: `REVIEW_OPERATOR_2_5D_CANONICAL_VISUAL_CONTRACT.md lacks the bounded TASK OVERRIDE required by review_pairing_contract.`
- Follow-up: `manual-follow-up: REVIEW_OPERATOR_2_5D_CANONICAL_VISUAL_CONTRACT`
- What worked: `Issue-time ownership tokens made disconnect and reconnect invalidation explicit while preserving last-known editor metadata.`

## Handoff

- Next action: Claim the paired fresh-context review and verify the durable implementation evidence before any FX-layer adoption.
- Best starting files: `live_bridge/state.py`, `ui/live_bridge_controller.py`, `ui/app.py`, `operator_workbench_ui_smoke.py`, and the cycle-2 review summary.
- Blockers or open questions: None.
