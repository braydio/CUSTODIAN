# Independent review: Operator Workbench browser / PREVIEW refresh hardening

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab

Disposition: `findings` — three blocking defects and one material evidence gap. Correction cycle 1 is ready after this review archives. Reviewed live main `83f5a9dcebf91df7e853a02fbaffbb652490b777`; implementation commit `ab6bfd008d871b63523cc23a2214d105b54d5ba4`, summary rename `328a46a76`, and later main changes were reconstructed independently. Reviewer context: `fresh`. Reviewer provenance: `same-agent-fresh-context`. No implementation files were modified.

## Findings

### R0-01 — An older browser refresh can still apply its session result

- Class: `blocking_defect`
- Domain: `implementation`
- Affected acceptance: An older browser request must perform zero accepted/UI mutation after a newer request exists; browser/session/preview handoff must remain coherent.
- Evidence: `custodian/tools/operator/ui/app.py:601` awaits `_load_session()` without passing browser request ownership. `_load_session()` at lines 655–672 checks only session generation. Barrier probe: A passes browser acceptance and blocks in session projection; B begins browser generation 3 and blocks in discovery; A's generation-2 session returns and changes accepted document frames from 6 to 101 while B is current. The subsequent browser-generation check happens after application.
- Disposition: `correction`
- Rationale: Session generation does not invalidate at the start of a newer browser request. Guard the browser-owned session projection before all accepted state/widget changes, while preserving direct-selection ownership.

### R0-02 — Failed session projection leaves a partially committed deletion refresh

- Class: `blocking_defect`
- Domain: `implementation`
- Affected acceptance: A refresh/projection failure preserves the accepted browser tree, selection, loaded session, and last usable preview rather than exposing a half-state.
- Evidence: `custodian/tools/operator/ui/app.py:557` commits the snapshot and rebuilds the tree before `_load_session()` succeeds. Probe supplies stable consecutive candidates deleting the selected direction and makes replacement session projection raise. The old session and selection remain accepted, but that selected identity is absent from the accepted snapshot and tree. The fallback activity event is emitted before fallback succeeds.
- Disposition: `correction`
- Rationale: Catching the exception preserves the session but does not restore the browser transaction. Stage dependent projections or restore the previous coherent state when projection fails. A successful stable deletion must still become visible once.

### R0-03 — Delayed Live Bridge results adopt the receiver's generation

- Class: `blocking_defect`
- Domain: `implementation`
- Affected acceptance: A delayed/debounced live export result cannot apply across a stale UI preview generation, in addition to document/revision/output-path checks.
- Evidence: `custodian/tools/operator/ui/app.py:399` sets `generation = self.state.preview_generation` when the result arrives. `_debounced_live_preview()` at lines 372–394 validates generation before sending but does not associate returned command sequence with that generation. The event's `cause` is not consumed for ownership. Probe issues export cause 17 in generation 1, prepares a generation-2 saved replacement for the same document/revision, then delivers generation-1 result. All document/revision/path checks pass and the older export overwrites the newer view.
- Disposition: `correction`
- Rationale: Generation must travel from export issue to result acceptance. Preserve existing Live Bridge guards and reject obsolete command results without widget/state mutation.

### R0-04 — Required end-to-end negative controls are missing

- Class: `evidence_gap`
- Domain: `implementation`
- Affected acceptance: F5/PUBLISH coalescing, 30 Hz negative controls, zero duplicate session projections, reachability single parse/action priority, Search-hidden selection plus F5, and end-to-end transient/stable deletion behavior.
- Evidence: `custodian/tools/validation/operator_workbench_ui_smoke.py:1162` tests stabilization helper return values but not Fast 02/03 tree preservation, selected session, or one fallback/event. `out_of_order_browser_smoke()` filters only after refresh, so it does not exercise Search-hidden selection during F5. `session_calls` is incremented but never asserted. No F5-while-PUBLISH barrier or one-parse/action-priority assertion exists. Existing live tests reject old document revisions, but did not test UI-generation supersession. The only added preview race fixture covers ordinary preview; explicit stale comparison/transition results and empty/replacing/wrong-identity/wrong-source/out-of-range tick assertions are absent.
- Disposition: `correction`
- Rationale: The omissions hide the confirmed defects and prevent confidence in mandatory concurrency guarantees. Add focused deterministic assertions against real application seams rather than only helper values; no renderer evidence is needed.

## Validation and limits

- `/tmp/custodian-opui/bin/python custodian/tools/validation/operator_workbench_ui_smoke.py`: PASS including pinned Textual Pilot, browser stabilization/ordering, repeated preview F5, and stale/error modal dismissal.
- `python3 custodian/tools/validation/operator_animation_workbench_smoke.py`: PASS; discovery/reachability/completeness changes warranted the conditional supporting check.
- Independent probes below: PASS as falsification probes; they assert and reproduce the three defects rather than certify the implementation.
- Retained implementation validation JSON `/tmp/operator-workbench-browser-validation.json`: 16/16 passed, complete changed-code coverage; its nested system-Python Pilot correctly skipped missing optional dependencies. This review reran the pinned Pilot separately.
- Graph was stale/missing in the fresh checkout; rebuilt without embeddings, then used scoped change, flow, and coverage queries. Graph provides no affected-flow results for these owners, so targeted source/test analysis supplied the evidence.
- Moment Forge: not run — deterministic tooling/UI concurrency review, no game runtime or art changes. Renderer/media review: not required.
- This review does not claim that any probe identifies the original uncaptured production crash traceback.
- Changed-artifact closeout validation: PASS 2/2 (`review_pairing_contract`, `visual_review_handoff`), complete coverage; `git diff --check`: PASS. All committed mutations are bounded review artifacts.

## Reproduction evidence

Run with the pinned UI environment. Extract the following Python block into a temporary script and invoke `python /tmp/review-probes.py <repository-root>`. It uses the repository's Pilot provider and asynchronous barriers. A short Pilot drain only allows UI mounting; race ordering is controlled by explicit events. The live test sets debounce to zero and restores it.

```python
import asyncio
import importlib.util
import sys
from dataclasses import replace
from pathlib import Path

root = Path(sys.argv[1])
spec = importlib.util.spec_from_file_location('ui_smoke', root / 'custodian/tools/validation/operator_workbench_ui_smoke.py')
smoke = importlib.util.module_from_spec(spec)
spec.loader.exec_module(smoke)
from ui.app import OperatorWorkbenchApp
from ui.state import AnimationRecord, AnimationSelection
from ui.widgets import AnimationTree

async def stale_browser_session():
    service = smoke.PilotService()
    app = OperatorWorkbenchApp(service=service, startup=service.selection)
    async with app.run_test(size=(80,35)) as pilot:
        await pilot.pause(0.3)
        baseline = app.session_view
        session_started = asyncio.Event()
        session_release = asyncio.Event()
        scan_started = asyncio.Event()
        scan_release = asyncio.Event()
        old_thread = app._thread
        scans = 0
        sessions = 0
        async def controlled(fn, *args, **kwargs):
            nonlocal scans, sessions
            if fn == app.features['animations'].refresh:
                scans += 1
                if scans == 2:
                    scan_started.set()
                    await scan_release.wait()
                return fn(*args, **kwargs)
            if fn == service.session:
                sessions += 1
                if sessions == 1:
                    session_started.set()
                    await session_release.wait()
                    return replace(fn(*args, **kwargs), document_frames=101)
            return await old_thread(fn, *args, **kwargs)
        app._thread = controlled
        first = asyncio.create_task(app._reload_browser())
        await asyncio.wait_for(session_started.wait(), 3)
        old_gen = app.state.browser_refresh_generation
        second = asyncio.create_task(app._reload_browser())
        await asyncio.wait_for(scan_started.wait(), 3)
        session_release.set()
        await first
        print('R0-01', {'older_browser_generation': old_gen, 'active_browser_generation': app.state.browser_refresh_generation,
                        'baseline_frames': baseline.document_frames, 'accepted_stale_session_frames': app.session_view.document_frames})
        assert app.session_view.document_frames == 101, 'suspected stale session application did not reproduce'
        scan_release.set()
        await second

async def failed_session_preservation():
    service = smoke.PilotService()
    app = OperatorWorkbenchApp(service=service, startup=service.selection)
    async with app.run_test(size=(80,35)) as pilot:
        await pilot.pause(0.3)
        previous_snapshot = app.state.browser_snapshot
        previous_session = app.session_view
        removed = service.selection
        service.browser_provider = lambda: tuple(row for row in previous_snapshot if row.selection != removed)
        async def no_wait(seconds):
            return None
        app._sleep = no_wait
        def failed_session(selection):
            raise RuntimeError('review controlled projection failure')
        service.session = failed_session
        await app._reload_browser()
        tree = app.main_screen.query_one('#animation-tree',AnimationTree)
        tree_ids = {node.data.identity for node in tree._walk_nodes() if isinstance(node.data,AnimationSelection)}
        print('R0-02', {'snapshot_changed_after_failed_projection': app.state.browser_snapshot != previous_snapshot,
                        'selected_identity_missing_from_tree': removed.identity not in tree_ids,
                        'previous_session_retained': app.session_view is previous_session,
                        'selection_preserved': app.state.selection == removed})
        assert app.state.browser_snapshot != previous_snapshot and removed.identity not in tree_ids
        await pilot.pause(0.1)

async def main():
    await stale_browser_session()
    await failed_session_preservation()
    await stale_live_result()

async def stale_live_result():
    from ui.live_bridge_controller import LiveBridgeEvent
    from live_bridge.protocol import MessageType
    import ui.app as app_module
    service = smoke.PilotService()
    app = OperatorWorkbenchApp(service=service, startup=service.selection)
    async with app.run_test(size=(80,35)) as pilot:
        await pilot.pause(0.3)
        app.action_mode_preview()
        await pilot.pause(0.2)
        app.state.preview_source = 'workbench'
        path = app._selected_live_workbench_path()
        app.live_bridge.server.state.active_document_path = str(path)
        app.live_bridge.server.state.document_revision = 42
        issued = []
        async def export(workbench, revision):
            issued.append((app.state.preview_generation, revision))
            return 17
        app.live_bridge.export_preview = export
        original_debounce = app_module.LIVE_PREVIEW_DEBOUNCE_SEC
        app_module.LIVE_PREVIEW_DEBOUNCE_SEC = 0
        try:
            await app._debounced_live_preview(42, app.state.preview_generation, app.state.selection, str(path))
        finally:
            app_module.LIVE_PREVIEW_DEBOUNCE_SEC = original_debounce
        request_generation = issued[0][0]
        new_generation = app._next_preview_generation()
        await app._load_preview(generation=new_generation)
        latest = app.preview_view
        live = replace(latest, source='live', paths=('older-export-request-17',))
        service.live_preview = lambda *args, **kwargs: live
        output = app.live_bridge._live_preview_path(path)
        event = LiveBridgeEvent(MessageType.COMMAND_RESULT, document_path=str(path), revision=42,
                                cause=17, operation='export_preview', ok=True, output_path=str(output),
                                frame_count=6, frame_width=96, frame_height=96)
        await app._apply_live_preview(event)
        print('R0-03', {'request_generation':request_generation,'active_generation':new_generation,
                       'old_export_overwrote_current_view':app.preview_view is live})
        assert app.preview_view is live
asyncio.run(main())
```

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Existing green UI smoke omitted multiple required race and negative-control assertions. The initial review failure probe exited before the error modal mounted and produced shutdown noise; allowing the Pilot to drain removed it.
- Root cause / contributing factors: The implementation completion receipt treated helper-only stabilization checks as complete end-to-end acceptance; export-request generation and browser-owned session projection were not exercised.
- Prevention / pipeline improvement: Correction cycle 1 explicitly maps durable end-to-end assertions to R0-01 through R0-04; reproduction code is retained below.
- Tooling / docs drift discovered: Reviewed main in the original packet is a preimplementation baseline; actual implementation is ab6bfd008 plus summary rename 328a46a76. Implementation summary says 14 validations, while retained JSON reports 16 passed.
- Follow-up: operator-workbench-browser-preview-refresh-hardening-review-corrections-1
- What worked: Pinned Textual environment, fresh independent probes, and isolated bounded review checkout.

## Next Handoff
- Next workstream: operator-workbench-browser-preview-refresh-hardening-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab
- Refresh reason: none
- Next action: Claim correction cycle 1, resolve R0-01 through R0-04, then run its paired independent review before continuing the FX-adoption lane.
- Blockers or open questions: none; the original production crash traceback remains unavailable and is not used to infer a crash root cause.
