# REVIEW: OPERATOR WORKBENCH BROWSER PREVIEW DISCONNECT OWNERSHIP CORRECTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-workbench-browser-preview-disconnect-ownership-correction`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `operator-workbench-browser-preview-disconnect-ownership-correction`
- Locks: `operator-workbench-ui`
- Review: `none`
- Review target workstream: `operator-workbench-browser-preview-disconnect-ownership-correction`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_BROWSER_PREVIEW_DISCONNECT_OWNERSHIP_CORRECTION.md`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `f64ee5c71ebb42ed7e192fccb71dec4fba3664d9`
- Human authorization basis: `fresh-context review of the human-authorized bounded successor that closes exhausted-lineage finding R2-01; this review is not cycle 3 of the original automatic correction chain`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Summary backlink: Include the exact Authoring chat URL above in every durable review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Independently prove that live Preview result ownership is tied to the exact bridge connection/session lifetime that issued it, including disconnect and disconnect→reconnect races, without erasing useful last-known document metadata or weakening the already-landed document/generation/selection guards.
- Review focus:
  - R2-01 reproduction is actually falsified, not hidden by clearing `active_document_path` or changing revision/generation;
  - connection/session ownership is captured at command issue and independently revalidated after loader awaits and immediately before accepted mutation;
  - reconnecting the same document/revision creates a new ownership lifetime, so an old result cannot revive;
  - asynchronous command-result and synchronous detached-export paths use equivalent ownership semantics rather than two unrelated fixes;
  - disconnected last-known document state remains informational only;
  - accepted Preview/comparison/transition/frame/play/raster/filmstrip/widget state is byte/object-stable under stale-result rejection;
  - current-session positive path still applies;
  - no FX-adoption/publication or unrelated Workbench behavior changed.
- Acceptance: Findings-first fresh-context review on live `main` either passes the bounded correction or creates only the narrow correction/re-review justified by a concrete defect/evidence gap. The reviewer must independently run actual disconnect and reconnect controls, not infer success from the implementation smoke.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Required Review Checks

1. Read the archived implementation packet/summary plus the original cycle-2 R2-01 review receipt and executable reproductions.
2. Inspect live `state.py`, `server.py`, `live_bridge_controller.py`, `app.py`, and the expanded pinned UI smoke.
3. Run the prior asynchronous actual-disconnect reproduction with path/revision/generation held constant. It must now preserve accepted Preview/widget state.
4. Run the prior synchronous loader reproduction. Actual disconnect must use saved fallback; document-switch behavior must remain green.
5. Independently exercise disconnect→reconnect to the same document at the same revision. A result from connection A must be stale after B connects; a fresh result from B must apply.
6. Verify the negative control truly uses `BridgeState.disconnect()` / real server disconnect semantics rather than clearing document metadata.
7. Verify no fix depends on resetting `active_document_path` or `document_revision`.
8. Verify issue-time ownership cannot be synthesized after the result returns and cannot accidentally match solely because the reconnecting client reopens the same document.
9. Re-run existing stale-generation/current-result and document-switch ownership controls.
10. Run changed-file validation with complete coverage and `git diff --check`.
11. Record findings first with stable IDs and disposition.
12. If the review passes, archive/close this gate and make `operator-workbench-fx-layer-adoption` claimable under its refreshed dependency.

## Handoff

- Next action: Auto-dispatch after `operator-workbench-browser-preview-disconnect-ownership-correction` lands and archives.
- Blockers or open questions: Dependency only.
