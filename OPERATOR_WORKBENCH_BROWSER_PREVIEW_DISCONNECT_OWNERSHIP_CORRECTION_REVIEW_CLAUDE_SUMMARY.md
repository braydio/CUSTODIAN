# Independent review: Operator Workbench Preview disconnect ownership

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab

## Findings

### R0-01 — Review packet target hash predates the ownership correction

- Class: `non_blocking_issue`
- Domain: `pipeline`
- Affected acceptance: Review the landed ownership correction against live main and record the exact reviewed target.
- Evidence: The review packet records `f64ee5c71ebb42ed7e192fccb71dec4fba3664d9`, whose diff changes only `AWAKENING_ROOM_CONNECTORS_POLISH.md`. The ownership implementation is commit `c4652e6b7248a6f60dcae9993742b7fcdaa8826c`; reviewed live main is `c463a1cfde5363e3e2eeac2e9c5b20362c6e9f67`. Exact target files are unchanged between the implementation commit and reviewed HEAD. The archived implementation packet and closing summary identify the intended behavior unambiguously.
- Disposition: `no_action`
- Rationale: This metadata issue does not prevent independent acceptance proof. This review's lifecycle metadata and archived target's Independent Review receipt record the exact reviewed HEAD; no implementation correction is warranted.

## Review result

Disposition: `passed` — zero blocking defects, zero material evidence gaps, one non-blocking pipeline finding. Reviewer context: `fresh`; reviewer provenance: `same-agent-fresh-context`. Reconstructed the task from durable root/local authority, current review and archived implementation packets, the implementation summary, original cycle-2 R2-01 receipt/executable proofs, active Workbench design, current-state/index/validation authority, live diff/source, and fresh executable controls. No reviewed implementation was edited.

The implementation captures immutable connection-generation/session/document/revision ownership before asynchronous command send and synchronous request await. Async cause projection retains that captured token; acceptance does not synthesize it from current state after return. `BridgeState.connect()` increments connection generation, `disconnect()` preserves document path/revision while clearing connected status/client identity, and the shared token guard revalidates at each loader/comparison/transition await and immediately before accepted mutation. Synchronous F5 uses the same ownership token and saved Workbench fallback.

### Retained findings

| ID | Disposition | Independent evidence |
| --- | --- | --- |
| R2-01 | fixed | Actual disconnect during the held live-image loader preserves accepted Preview/examiner/frame/play state and widget bytes. Last-known path, revision 42, and UI generation 2 stay equal. Synchronous disconnected loading uses saved fallback. |
| R1-01 | fixed | Existing document-switch controls pass; actual disconnect and reconnect are independently rejected at image, comparison, and transition-analysis await boundaries. |
| R0-04 (original lineage) | fixed | Pinned ownership/selection/source/examiner matrix passes; actual disconnect control now uses `BridgeState.disconnect()` with transport client removal, rather than document metadata erasure. |
| R0-01/R0-02/R0-03 (original lineage) | fixed | Expanded pinned browser/session/stable deletion controls pass; independent real app debounce → controller → server send/cause projection verifies issue context exists before send, rejects stale UI generation and accepts current results. |

### Independent negative and positive controls

- Original cycle-2 async proof adapted only to the new connected setup, typed `PreviewRequestContext`, and final expected safe assertions. Fake client replaces transport only; production app debounce, controller capture, server command send/on-issued callback, event projection, application guard, detached loader and `BridgeState.disconnect()` all execute.
- Actual disconnect with no reconnect: active path unchanged, document revision 42 unchanged, request/active UI generation both 2, `_live_document_matches_selection=False`, `stale_document_result_applied=False`, accepted object/widget snapshot changed indices `[]`.
- Disconnect→reconnect with the identical document, revision, semantic identity, source, UI generation **and identical client session ID**: document match returns true again, connection generation differs, old ownership stays invalid, stale A is rejected with snapshot changed indices `[]`, and a fresh B event applies the deliberately modified image. This proves connection-generation continuity independently from client ID or metadata equality.
- The same independent held-result controls run at compare-preview and transition-analysis awaits, both with disconnect-only and identical-session reconnect. All four preserve accepted identities, frame/play state, primary/compare raster bytes, filmstrip bytes, and persistent widget content; fresh reconnect results apply.
- Original synchronous image-loader proof: capture the issue-time ownership in its detached export fixture, hold service loading, then perform actual disconnect or document switch. Both produce `live_applied=False`, `saved_fallback=True`; disconnect preserves active path/revision. The complete pinned smoke additionally covers disconnect during the export await before any live loader call.
- No production path clears document metadata to make the negative controls pass. Exact code/diff review verifies the connected status and captured generation/session token independently gate application. The real server accepted-client `finally` path removes `_client` and calls `state.disconnect()`; the fixture invokes that same transition. The Live Bridge smoke exercises WebSocket disconnect/reconnect and command-result token projection.

## Validation

- Exact reviewed-implementation changed-file validation: PASS 9/9, complete coverage, zero failures/timeouts/skips/infrastructure errors. Report: `/tmp/custodian-do-review-implementation-validation.json`. Tests: `operator_animation_preview_timeline`, `operator_authoring_surface_contract`, `operator_live_bridge`, `operator_motion_preview`, `operator_workbench_mirror_publish`, `operator_workbench_ui`, `review_pairing_contract`, `visual_review_handoff`, and `operator_motion_calibration`. Command: `/tmp/custodian-opui/bin/python /tmp/custodian-do-review-changed.py .`; exact source is retained below.

- `/tmp/custodian-opui/bin/python custodian/tools/validation/operator_workbench_ui_smoke.py`: PASS with Textual `0.89.1` and websockets `15.0.1`; every optional Pilot block executes, including browser/session stabilization, F5 atomic handoff, real disconnect/reconnect ownership, stale generation/current acceptance, comparison/transition matrix, tick/clamp, Fast chain retention, PUBLISH coalescing, and error recovery. Log: `/tmp/custodian-do-review-ui.log`.
- `/tmp/custodian-opui/bin/python /tmp/custodian-do-review-async.py .`: PASS, original disconnect proof plus identical-session reconnect/stale-A/fresh-B control. Log: `/tmp/custodian-do-review-async.log`.
- `/tmp/custodian-opui/bin/python /tmp/custodian-do-review-sync.py .`: PASS, original synchronous loader document-switch and disconnect saved fallback. Log: `/tmp/custodian-do-review-sync.log`.
- `/tmp/custodian-opui/bin/python /tmp/custodian-do-review-examiner.py .`: PASS, four independent compare/transition await disconnect/reconnect controls. Log: `/tmp/custodian-do-review-examiner.log`.
- `/tmp/custodian-opui/bin/python custodian/tools/validation/run_validation.py --changed --json`: PASS 2/2 (`review_pairing_contract`, `visual_review_handoff`), complete coverage, zero failures/timeouts/skips/infrastructure errors. Report: `/tmp/custodian-do-review-artifacts-validation.json`. `task_packet_index.py`: PASS.
- `git diff --check`: PASS.

Graph-first exact change, symbol (`PreviewOwnership`), tests-for, and affected-flow queries return empty graph coverage in the isolated checkout. Targeted source/diff supplied current evidence; zero graph results were not treated as absent behavior or tests. No renderer, Moment Forge, subjective visual approval, FX adoption/publication, asset or gameplay change was required. No claim is made about the historical crash root cause.

## Executable independent proofs

The following two blocks are durable copies of the executed adapted original proofs. Extract to the named `/tmp` scripts and run with the pinned interpreter and repository root argument. The original proofs remain preserved in `REVIEW_OPERATOR_WORKBENCH_BROWSER_PREVIEW_REFRESH_HARDENING_REVIEW_CORRECTIONS_1_REVIEW_CORRECTIONS_2_CLAUDE_SUMMARY.md`.

### Async disconnect and identical-session reconnect

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

async def probe(reconnect=False):
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
        def connect():
            controller.server.state.connect(Message('review-identical-session', 1, MessageType.CLIENT_HELLO, {
                'aseprite_version':'review', 'api_version':'1', 'capabilities':[],
                'editor_state':{'document_path':str(path), 'revision':42}}))
        connect()
        issued = []
        class Client:
            async def send(self, raw):
                message = json.loads(raw)
                context = controller._preview_request_context[message['sequence']]
                assert (context.generation, context.identity, context.source) == (app.state.preview_generation, app.state.selection.identity, 'workbench')
                assert controller.server.state.owns_preview(context.ownership)
                assert context.ownership == controller.server.state.capture_preview_ownership(path, 42)
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
            assert controller.server.state.active_document_path == str(path)
            assert app.state.preview_generation == event_c.request_generation
            assert not app._live_document_matches_selection()
            assert not controller.server.state.owns_preview(event_c.request_ownership)
            if reconnect:
                connect()
                controller.server._client = Client()
                assert controller.server.state.client_session_id == event_c.request_ownership.client_session_id
                assert controller.server.state.connection_generation != event_c.request_ownership.connection_generation
                assert not controller.server.state.owns_preview(event_c.request_ownership)
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
            assert app.preview_view is prior, 'stale disconnected pixels applied'
            assert after == accepted, 'accepted state mutated'
            after = snapshot(app)
            print('snapshot changed indices', [i for i,(a,b) in enumerate(zip(accepted,after)) if a!=b], flush=True)
            assert after == accepted, 'accepted state changed after stale live result'
            if reconnect:
                fresh = await export_event()
                assert fresh.request_ownership != event_c.request_ownership
                await app._apply_live_preview(fresh)
                assert app.preview_view is switched_live
            print('PASS real disconnect/same-session reconnect', reconnect, flush=True)
        finally:
            app_module.LIVE_PREVIEW_DEBOUNCE_SEC = old_debounce
asyncio.run(probe())
asyncio.run(probe(True))
```

### Synchronous held loader

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
        state.connect(Message('sync-review-identical-session', 1, MessageType.CLIENT_HELLO, {
            'aseprite_version':'review', 'api_version':'1', 'capabilities':[],
            'editor_state':{'document_path':str(path), 'revision':42}}))
        async def export(*args):
            return {'output_path':str(app.live_bridge._live_preview_path(path)), 'frames':6,'frame_width':96,'frame_height':96,'ownership':state.capture_preview_ownership(path,42)}
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
        if disconnect:
            assert state.active_document_path == str(path) and state.document_revision == 42
            assert app.preview_view is previous, 'disconnected result failed saved fallback'
        else: assert app.preview_view is previous, 'document-switch rejection failed'
asyncio.run(sync_loader_probe())
asyncio.run(sync_loader_probe(True))
```

The examiner probe derives from the async block: use `barrier=compare|transition`, set `preview_examiner_mode` before issuing event C, initialize the transition target for transition mode, return the modified live image immediately, and hold `_thread` at `service.preview` (compare) or `animation_transition.analyze_transition` (transition). Run both disconnect and identical-session reconnect for each barrier; retain all equality/current-result assertions above.

### Exact implementation changed-file routing

Live main includes unrelated successors after the ownership correction. This wrapper substitutes only `changed_files()` with the exact reviewed commit's nine-file list; the unchanged repository runner still owns manifest selection, coverage checks, execution, and reporting. No test or coverage implementation is bypassed and no repository file is modified.

```python
from pathlib import Path
import sys, subprocess
root=Path(sys.argv[1]).resolve()
sys.path.insert(0,str(root/'custodian/tools/validation'))
import run_validation as r
files=[p for p in subprocess.check_output(['git','-C',str(root),'show','--format=','--name-only','c4652e6b7248a6f60dcae9993742b7fcdaa8826c'],text=True).splitlines() if p]
# Restrict routing to the reviewed commit, avoiding later unrelated main changes.
# Every coverage, selection, execution and reporting step uses the live repository runner.
r.changed_files=lambda base, repo_root: files
raise SystemExit(r.main(['--changed','--json']))
```

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The review packet carried a pre-implementation main hash; graph coverage is empty in the isolated checkout.
- Root cause / contributing factors: Reviewed-main metadata was inherited from planning; the worktree has no indexed graph nodes.
- Prevention / pipeline improvement: Refresh review lifecycle metadata to the actual reviewed HEAD and derive the review surface from the named implementation commit before changed-file routing.
- Tooling / docs drift discovered: R0-01 records the stale Reviewed main field; actual target was safely identified and the review metadata/receipt now record it.
- Follow-up: fixed-in-scope
- What worked: Identical-session reconnect controls prove ownership generation independently of path, revision, UI generation, and client identity.

## Next Handoff

- Next workstream: operator-workbench-fx-layer-adoption
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab
- Refresh reason: none
- Next action: Claim the existing FX adoption packet after this paired review lands and archives; reproduce its saved body-only Workbench plus vfx fixture first.
- Blockers or open questions: none
