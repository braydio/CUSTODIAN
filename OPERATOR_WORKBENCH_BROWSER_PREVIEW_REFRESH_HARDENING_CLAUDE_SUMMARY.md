# Operator Workbench Browser / Preview Refresh Hardening

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac8f303-1b34-83ea-a74b-3e3973c9667d

Implemented the browser snapshot and PREVIEW generation contract in `custodian/tools/operator/ui/`. Discovery now returns immutable candidates; accepted browser rows live in `WorkbenchUIState`; Search and superseded filtering are pure projections. Destructive browser candidates use bounded semantic rescans, preserve the prior snapshot while unstable, and distinguish modular body clock mismatches from complete presentation. Refresh generations prevent older worker scans from replacing a newer accepted state.

PREVIEW loaders now stage results and apply only when selection, source, mode, and generation remain current. F5 on page 3 retains the rendered view while browser/session state and a replacement are prepared, then applies one coherent result. Repeated F5 carries the original play intent across the replacement chain. PUBLISH-time refresh is coalesced; Live Bridge export/result checks retain document/revision/path checks and compose them with UI generation guards. The preview tick checks replacement and active-view coherence before indexing frames. Programmatic tree restoration suppresses its selection event.

Regression evidence:

- `/tmp/custodian-opui/bin/python custodian/tools/validation/operator_workbench_ui_smoke.py` passed, including the pinned Textual Pilot, browser stabilization fixtures, out-of-order browser scan, Search without rediscovery, and repeated F5 with a blocked older preview result.
- `python3 custodian/tools/validation/run_validation.py --changed --json` passed all 14 selected validations with complete code coverage. The runner's nested UI smoke used the system Python and truthfully skipped optional Textual dependencies; the separate temporary pinned-dependency run executed and passed that Pilot.
- `git diff --check` passed.

Two failures found while adding guards were fixed in scope: transition target identity was changing as part of stabilization and invalidating its own result; a disconnected Live Bridge export prevented saved Workbench preview fallback. Repeated-F5 testing also verified that playback intent must be carried across an already-running replacement, now handled by `_browser_preview_play_intent`.

No Operator art, gameplay data, animation timing, combat logic, or publication transaction semantics changed. Paired independent post-land review is the immediate successor.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: Textual tests exposed a self-invalidating transition target and a disconnected-live-preview early return; initial fixture fallback needed adaptation to the new stateless discovery provider.
- Root cause / contributing factors: New generation checks surfaced an implicit target mutation; live export failure was treated as an overall preview failure.
- Prevention / pipeline improvement: Added barrier-controlled out-of-order browser/preview Pilots and used a temporary environment with pinned UI requirements.
- Tooling / docs drift discovered: none
- Follow-up: review-operator-workbench-browser-preview-refresh-hardening
- What worked: Deterministic barrier tests reproduced ordering defects without wall-clock race assumptions.

## Next Handoff
- Next workstream: review-operator-workbench-browser-preview-refresh-hardening
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac8f303-1b34-83ea-a74b-3e3973c9667d
- Refresh reason: none
- Next action: Claim the paired post-land review and independently verify browser/PREVIEW latest-request-wins behavior against the archived packet and validation evidence.
- Blockers or open questions: The exact historic production crash traceback is unavailable; the confirmed stale-worker and stale-preview races now have deterministic regression coverage.
