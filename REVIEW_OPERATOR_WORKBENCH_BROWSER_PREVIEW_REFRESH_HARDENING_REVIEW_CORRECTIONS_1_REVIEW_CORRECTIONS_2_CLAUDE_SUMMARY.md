# Independent review: Operator Workbench browser / PREVIEW correction cycle 2

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab

Disposition: `human_required` — one confirmed blocking defect at automatic review cycle 2 of maximum 2. Reviewed landed main `032d5f037bc846a0b7d291d27300645fcab2ea34`, including correction commit `b2b5b155b40fb32211da63802a3ef27336e4719e`. Reviewer context: `fresh`; reviewer provenance: `same-agent-fresh-context`. Reconstructed the target from root/local instructions, archived parent/correction/review packets and summaries, active Workbench design/current-state/index/validation authority, exact live diff/source, and fresh probes. No reviewed implementation was edited.

## Findings

### R2-01 — Real bridge disconnect leaves a held live result eligible for application

- Class: `blocking_defect`
- Domain: `implementation`
- Affected acceptance: R1-01 requires disconnected-editor rejection without accepted preview/examiner/frame/widget mutation. R0-04 requires direct live ownership negative controls; preserved parent document/result safety applies across loader awaits.
- Evidence: `custodian/tools/operator/live_bridge/state.py:51` sets connection DISCONNECTED and clears client session/pending commands, preserving active_document_path and document_revision. The real server disconnect finally path at `live_bridge/server.py:151` clears `_client` and invokes this method. `_live_document_matches_selection` at `ui/app.py:302` checks only active/result path equality; it ignores bridge connection/session lifetime. Async acceptance guards at `app.py:447` and `:481`, and synchronous guards at `:964`/`:1021`, continue accepting the cached document after disconnect.
- Independent actual app route: app debounce → controller → real server send/on_issued context → command cause/result → `_apply_live_preview`; hold live-image load, call the actual state disconnect and clear transport client exactly as the real server finally does, release at unchanged revision 42 and preview generation 2. Observed connection=`disconnected`, active_document_matches_selection=`True`, stale_document_result_applied=`True`. Accepted primary Preview identity changed; fixture-modified RGBA bytes reached preview canvas/filmstrip. Comparison/transition references and frame/play state stayed unchanged, so the violation is the detached primary/widget application, not an unrelated timer event.
- Independent synchronous live-image barrier: `_load_preview` receives its export contract, blocks the service image loader, performs actual disconnect, then releases. Observed document_match=`True`, live_applied=`True`, saved_fallback=`False`. The parallel document-switch control yields document_match=`False`, live_applied=`False`, saved_fallback=`True`.
- Why expanded smoke missed it: `operator_workbench_ui_smoke.py:1562` sets `active_document_path=None` to model disconnect; it never invokes the real disconnect transition that preserves that value. The suite passes despite this defect.
- Disposition: `human_required`
- Rationale: This is a confirmed violation of explicit disconnected-editor acceptance, not a speculative crash diagnosis. Cycle 2 is the automatic cap; the authoring conversation must decide a bounded follow-up or explicit acceptance exception. No cycle-3 packet is created.

## Retained finding dispositions

| ID | Disposition | Independent evidence |
| --- | --- | --- |
| R0-01 | fixed | Expanded browser/session ordering, accepted snapshot/tree/session preservation, direct stale session controls pass. |
| R0-02 | fixed | PREVIEW deletion failure preserves prior state; stabilized retry produces one fallback and one event. |
| R0-03 | fixed | Independent real send/on_issued callback asserts issue-time generation/identity/source exists before transport send; stale generation rejects and current result applies. |
| R0-04 | unresolved | Required selection/source/examiner-mode comparison and transition barrier matrix is now present and passes; invalid document/revision/output/missing context and document-switch awaits pass. Actual-disconnect control is false and remains material through R2-01. |
| R1-01 | unresolved (document-switch portion fixed) | Async document switch rejects with accepted preview/comparison/transition object identities, frame/play state, and raster/filmstrip/persistent widget data unchanged. Synchronous export and image-loader document switches use saved fallback. Actual disconnect still applies the detached result. |

## Validation and limits

- `/tmp/custodian-opui/bin/python custodian/tools/validation/operator_workbench_ui_smoke.py`: PASS. Textual `0.89.1`; all expanded Pilot portions execute, including reachability, browser stabilization/generation/session, repeated F5/atomic handoff, live generation/document fixtures, selection/source/examiner-mode matrix, tick controls, Fast-chain retention, PUBLISH coalescing, and dismissible errors. Log `/tmp/custodian-r2-pinned-ui.log`.
- `/tmp/custodian-opui/bin/python /tmp/custodian-r2-independent-live.py .`: PASS for real app/server issue context, stale generation/current result, async document-switch full accepted-state preservation, and synchronous export-switch saved fallback. Log `/tmp/custodian-r2-independent-live.log`.
- `/tmp/custodian-opui/bin/python /tmp/custodian-r2-disconnect.py .`: Confirmed R2-01, then deliberately fails the unchanged-state safety assertion (exit 1); log `/tmp/custodian-r2-disconnect.log` contains connection/document/generation and accepted object/widget byte differences. This red acceptance probe is the finding, not a validation infrastructure failure.
- `/tmp/custodian-opui/bin/python /tmp/custodian-r2-sync-loader.py .`: PASS as a falsification probe: proves document-switch fallback and reproduces synchronous disconnected-live application. Log `/tmp/custodian-r2-sync-loader.log`.
- Changed-artifact closeout validation: PASS 2/2 (`review_pairing_contract`, `visual_review_handoff`), complete coverage, zero failed/timed-out/skipped/infrastructure errors. Report `/tmp/custodian-r2-review-validation.json`. `git diff --check` and `task_packet_index.py`: PASS. This validates bounded review metadata; R2-01 remains a failed implementation acceptance.
- Graph-first change/flow queries returned zero symbols/flows in the isolated checkout; original graph discovery reports build `cbc4acc`, stale against current head. Exact source and diff supplied current line/await evidence; absent graph coverage is not interpreted as absent tests.
- Moment Forge: not run — deterministic authoring-tool state review. Renderer/media capture and animation Workbench smoke: not run — no discovery, runtime, art, or pixel-baseline change.
- Historic production crash traceback remains unavailable; no crash root-cause claim is made.

## Executable independent disconnect proof

Extract this block to `/tmp/custodian-r2-disconnect.py` and run with the pinned Python and repository-root argument. The fake client replaces transport only; send/on_issued context, app debounce, controller cause projection, application guards, real state disconnect, and detached loader completion are exercised. The final safety assertion intentionally fails on the reviewed main.

```python
import asyncio
import importlib.util
import json
import sys
from dataclasses import replace
from pathlib import Path

root = Path(sys.argv[1])
spec = importlib.util.spec_from_file_location('review_smoke', root / 'custodian/tools/validation/operator_workbench_ui_smoke.py')
smoke = importlib.util.module_from_spec(spec)
spec.loader.exec_module(smoke)
from ui.app import OperatorWorkbenchApp
from live_bridge.protocol import Message, MessageType
import ui.app as app_module

def snapshot(app):
    fields = ('preview_view', 'preview_compare_view', 'preview_comparisons', 'transition_candidates', 'transition_target_view', 'transition_analysis')
    widgets = ('#preview-canvas', '#preview-compare-canvas', '#preview-diff-metrics', '#preview-filmstrip', '#preview-controls')
    return (tuple(id(getattr(app, key)) for key in fields), app.state.preview_frame, app.state.preview_playing,
            tuple((getattr(app.main_screen.query_one(key), 'source_frame', None).tobytes() if getattr(app.main_screen.query_one(key), 'source_frame', None) is not None else None, str(getattr(app.main_screen.query_one(key), '_content', '')), getattr(app.main_screen.query_one(key), 'contact_sheet', None).tobytes() if getattr(app.main_screen.query_one(key), 'contact_sheet', None) is not None else None) for key in widgets))

async def probe():
    service = smoke.PilotService()
    app = OperatorWorkbenchApp(service=service, startup=service.selection)
    async with app.run_test(size=(80, 35)) as pilot:
        await pilot.pause(0.3)
        app.action_mode_preview()
        await pilot.pause(0.2)
        app.state.preview_source = 'workbench'
        controller = app.live_bridge
        path = app._selected_live_workbench_path()
        controller.server.state.active_document_path = str(path)
        controller.server.state.document_revision = 42
        issued = []
        class Client:
            async def send(self, raw):
                message = json.loads(raw)
                context = controller._preview_request_context[message['sequence']]
                assert context == (app.state.preview_generation, app.state.selection.identity, 'workbench')
                issued.append(message)
            async def close(self, **kwargs): pass
        controller.server._client = Client()
        old_debounce = app_module.LIVE_PREVIEW_DEBOUNCE_SEC
        app_module.LIVE_PREVIEW_DEBOUNCE_SEC = 0
        async def export_event():
            await app._debounced_live_preview(42, app.state.preview_generation, app.state.selection, str(path))
            sequence = issued[-1]['sequence']
            output = controller._live_preview_path(path)
            controller._on_message(Message(controller.server.state.bridge_session_id, sequence + 100,
                MessageType.COMMAND_RESULT, {'operation':'export_preview', 'ok':True,
                'document_path':str(path), 'output_path':str(output), 'revision':42,
                'frames':6, 'frame_width':96, 'frame_height':96}, cause=sequence))
            return await controller.next_event()
        try:
            event_a = await export_event()
            generation_a = event_a.request_generation
            generation_b = app._next_preview_generation()
            await app._load_preview(generation=generation_b)
            baseline = app.preview_view
            live = replace(baseline, source='live', paths=('review-live-result',))
            service.live_preview = lambda *args, **kwargs: live
            await app._apply_live_preview(event_a)
            assert app.preview_view is baseline
            event_b = await export_event()
            await app._apply_live_preview(event_b)
            assert app.preview_view is live
            print('PASS R0-03 real app debounce -> controller -> server send -> command cause -> stale rejection/current acceptance', flush=True)
            event_c = await export_event()
            prior = app.preview_view
            switched_frames = tuple(frame.copy() for frame in prior.frames)
            for frame in switched_frames: frame.putpixel((48, 48), (251, 0, 0, 255))
            switched_live = replace(prior, frames=switched_frames, paths=('review-after-disconnect',))
            started, release = asyncio.Event(), asyncio.Event()
            original_thread = app._thread
            async def controlled(function, *args, **kwargs):
                if getattr(function, 'func', None) == service.live_preview:
                    started.set()
                    await release.wait()
                    return switched_live
                return await original_thread(function, *args, **kwargs)
            app._thread = controlled
            app.state.preview_playing = False
            app._render_preview()
            accepted = snapshot(app)
            load = asyncio.create_task(app._apply_live_preview(event_c))
            await asyncio.wait_for(started.wait(), 3)
            other_path = path.parent.parent / 'other-document' / 'workbench.aseprite'
            from live_bridge.state import ConnectionState
            controller.server.state.connection = ConnectionState.CONNECTED
            controller.server.state.disconnect()
            controller.server._client = None
            # Keep the revision and UI generation equal: document identity is an independent guard.
            assert controller.server.state.document_revision == 42
            release.set()
            await load
            actual = {'revision':controller.server.state.document_revision,
                      'request_generation':event_c.request_generation,
                      'active_generation':app.state.preview_generation,
                      'active_document_matches_selection':app._live_document_matches_selection(),
                      'stale_document_result_applied':app.preview_view is switched_live}
            print('R2 actual disconnect', actual, flush=True)
            print('connection', controller.server.state.connection.value, flush=True)
            after = snapshot(app)
            print('accepted state changed indices', [i for i,(a,b) in enumerate(zip(accepted,after)) if a!=b], flush=True)
            assert app.preview_view is switched_live, 'disconnect defect did not reproduce'
            assert after != accepted, 'accepted state did not mutate'
            print('CONFIRMED R2-01: disconnected editor result changed accepted preview and rendered widgets', flush=True)
            after = snapshot(app)
            print('snapshot changed indices', [i for i,(a,b) in enumerate(zip(accepted,after)) if a!=b], flush=True)
            assert after == accepted, 'accepted state changed after stale live result'
        finally:
            app_module.LIVE_PREVIEW_DEBOUNCE_SEC = old_debounce
asyncio.run(probe())

```

## Executable synchronous image-loader proof

```python
import asyncio
import importlib.util
import json
import sys
from dataclasses import replace
from pathlib import Path

root = Path(sys.argv[1])
spec = importlib.util.spec_from_file_location('review_smoke', root / 'custodian/tools/validation/operator_workbench_ui_smoke.py')
smoke = importlib.util.module_from_spec(spec)
spec.loader.exec_module(smoke)
from ui.app import OperatorWorkbenchApp
from live_bridge.protocol import Message, MessageType
import ui.app as app_module

def snapshot(app):
    fields = ('preview_view', 'preview_compare_view', 'preview_comparisons', 'transition_candidates', 'transition_target_view', 'transition_analysis')
    widgets = ('#preview-canvas', '#preview-compare-canvas', '#preview-diff-metrics', '#preview-filmstrip', '#preview-controls')
    return (tuple(id(getattr(app, key)) for key in fields), app.state.preview_frame, app.state.preview_playing,
            tuple((getattr(app.main_screen.query_one(key), 'source_frame', None).tobytes() if getattr(app.main_screen.query_one(key), 'source_frame', None) is not None else None, str(getattr(app.main_screen.query_one(key), '_content', '')), getattr(app.main_screen.query_one(key), 'contact_sheet', None).tobytes() if getattr(app.main_screen.query_one(key), 'contact_sheet', None) is not None else None) for key in widgets))

async def sync_loader_probe(disconnect=False):
    import threading
    from live_bridge.state import ConnectionState
    service = smoke.PilotService()
    app = OperatorWorkbenchApp(service=service, startup=service.selection)
    async with app.run_test(size=(80,35)) as pilot:
        await pilot.pause(0.3)
        app.action_mode_preview(); await pilot.pause(0.2)
        previous=app.preview_view
        app.state.preview_source='workbench'
        path=app._selected_live_workbench_path()
        state=app.live_bridge.server.state
        state.active_document_path=str(path); state.document_revision=42
        state.connection=ConnectionState.CONNECTED
        async def export(*args):
            return {'output_path':str(app.live_bridge._live_preview_path(path)), 'frames':6,'frame_width':96,'frame_height':96}
        app.live_bridge.request_preview_export=export
        started, release=threading.Event(),threading.Event()
        live=replace(previous, source='live', paths=('sync-held',))
        def loader(*args,**kwargs):
            started.set(); assert release.wait(3); return live
        service.live_preview=loader
        service.preview=lambda *args,**kwargs: previous
        pending=asyncio.create_task(app._load_preview(generation=app._next_preview_generation()))
        assert await asyncio.to_thread(started.wait,3)
        if disconnect: state.disconnect(); app.live_bridge.server._client=None
        else: state.active_document_path=str(path.parent.parent/'other'/'workbench.aseprite')
        release.set(); await pending
        result={'disconnect':disconnect,'revision':state.document_revision,'document_match':app._live_document_matches_selection(),'live_applied':app.preview_view is live,'saved_fallback':app.preview_view is previous}
        print('SYNC LIVE IMAGE BARRIER',result,flush=True)
        if disconnect: assert app.preview_view is live, 'disconnect defect did not reproduce'
        else: assert app.preview_view is previous, 'document-switch rejection failed'
asyncio.run(sync_loader_probe())
asyncio.run(sync_loader_probe(True))

```

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The pinned expanded smoke passes while the real disconnect transition still authorizes a held export result. The independent snapshot probe initially compared freshly allocated Container render wrappers; it was corrected to compare accepted object identities, raster/filmstrip bytes, and persistent widget content before drawing conclusions.
- Root cause / contributing factors: The disconnect fixture clears active_document_path, whereas LiveBridgeState.disconnect preserves document path/revision. UI document ownership checks omit connection/session lifetime. Graph coverage in the isolated worktree returns no changed symbols/flows and is insufficient for current-source review.
- Prevention / pipeline improvement: A human-authorized follow-up should exercise the actual server/state disconnect and reconnect transitions at each live await, with document/revision/generation held equal and accepted state/widget snapshots; validate connection/session ownership independently of path equality.
- Tooling / docs drift discovered: Review packet Reviewed main points at the cycle-1 baseline; this receipt records actual landed target 032d5f037bc846a0b7d291d27300645fcab2ea34 and implementation commit b2b5b155b40fb32211da63802a3ef27336e4719e. The system runner still skips optional Textual; pinned environment supplies UI evidence.
- Follow-up: manual-follow-up
- What worked: Fresh issue-to-result transport probes and live-image barriers distinguish passing document-switch rejection from the confirmed disconnect defect.

## Next Handoff

- Next workstream: operator-workbench-fx-layer-adoption
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab
- Refresh reason: Final automatic review cycle 2 confirms R2-01; R1-01/R0-04 disconnect acceptance remains unresolved. No automatic cycle 3 is authorized.
- Next action: Return to the exact authoring conversation with this review summary and decide the bounded disconnect correction/re-review or an explicit acceptance exception before FX adoption may proceed.
- Blockers or open questions: R2-01 accepts detached live pixels after actual bridge disconnect. FX packet still depends on review-operator-workbench-browser-preview-refresh-hardening; its lane cannot proceed while this final review is human_required. Historic production traceback remains unavailable.
