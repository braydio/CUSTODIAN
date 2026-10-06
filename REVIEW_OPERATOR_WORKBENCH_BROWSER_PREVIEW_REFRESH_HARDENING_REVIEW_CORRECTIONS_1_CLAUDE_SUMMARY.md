# Independent review: Operator Workbench browser / PREVIEW correction cycle 1

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab

Disposition: `findings` — one blocking defect and one retained material evidence gap. Correction cycle 2 is the immediate successor. Reviewed live main and correction commit `18d5f1f7392dc44ba1b70e4465e615866b7837ca`. Reviewer context: `fresh`; reviewer provenance: `same-agent-fresh-context`. Reconstructed authority from archived correction/parent packets, parent review probes, correction summary, active Workbench design, live source, and fresh deterministic probes. No reviewed implementation was edited.

## Findings

### R1-01 — Live results can apply after the active editor document changes during loading

- Class: `blocking_defect`
- Domain: `implementation`
- Affected acceptance: Preserve document/revision/output safety and reject document switches during loader awaits (explicit correction-cycle-1 R0-03 acceptance and preserved parent safety).
- Evidence: `custodian/tools/operator/ui/app.py:413` checks the event document via `_live_document_matches_selection(event.document_path)`, whose explicit path overrides the active editor path (`app.py:302`). The guards after `service.live_preview` at `app.py:443` and immediately before commit at `app.py:473` recheck revision and UI generation/selection/source, but omit active editor document ownership. `_load_preview`'s synchronous live-export branch (`app.py:915`) has the same defect: independently block `request_preview_export`, change active editor document at revision 42, release; `active_document_matches_selection=False`, `old_document_live_applied=True`.
- Independent reproduction: The real app debounce calls the controller, real `LiveBridgeServer.send_command` records issue-time context before a fake client send, and the command cause returns through `_on_message`. The generation fix rejects the old result and accepts a valid current result. Then a valid current result blocks in the live loader; change `active_document_path` to another Workbench while keeping revision 42 and generation 2; release. Output: `active_document_matches_selection=False`, `stale_document_result_applied=True`. This is a confirmed stale application, independent of the uncaptured historic crash.
- Disposition: `correction`
- Rationale: Document identity is an independent guard; equal revision numbers across documents must never authorize an old document's result. Validate both originating/result path and the active editor document at all asynchronous boundaries that precede accepted mutation.

### R0-04 — Required ownership negative controls remain incomplete

- Retained disposition: `unresolved` (substantial portions fixed).
- Class: `evidence_gap`
- Domain: `implementation`
- Affected acceptance: Direct stale comparison/transition rejection across selection/source/mode generations, and preservation of live document/revision/output-path safety across loader awaits.
- Evidence: `preview_negative_controls_smoke` (`operator_workbench_ui_smoke.py:1501`) blocks comparison and transition but supersedes each only by calling `_next_preview_generation()`; it does not exercise selection/source/mode changes or assert the complete accepted frame/widget state. `live_preview_generation_smoke` (`:1431`) covers old/current UI generation, but does not exercise wrong-result document/path or an active document switch during loading. Older Pilot document-change cases test suppression of export issuance and stale revision, rather than result acceptance across document switches. The independent R1-01 probe demonstrates why this missing control is material.
- Fixed portions: Reachability reads once/action LIVE priority, transient Fast 02/03 tree/session preservation, one successful fallback load/removal event, Search-hidden F5 with one session and no Search scans, unchanged refresh one session projection, repeated preview F5, tick empty/replacing/identity/source/index controls, and PUBLISH no in-flight scan plus exactly one deferred refresh all pass.
- Disposition: `correction`
- Rationale: Finish the small requested ownership matrix against real application seams and retain the document-switch probe as a regression. No renderer proof is needed.

## Retained finding dispositions

| ID | Disposition | Independent evidence |
| --- | --- | --- |
| R0-01 | fixed | Barrier A in session, B blocked in discovery; releasing A changes no accepted snapshot/tree/selection/session/preview/detail. Direct selection latest-wins remains covered by expanded smoke. |
| R0-02 | fixed | In PREVIEW mode, failed stabilized deletion fallback retains snapshot/tree/selection/session/usable preview, reports one error and zero removal events. Retry succeeds with exactly one fallback load/event. |
| R0-03 | fixed | Originating UI generation/identity/source is registered before real server send and returned by command cause; stale generation rejected, valid current result accepted. R1-01 records the separate preserved document-ownership defect. |
| R0-04 | unresolved | Most specified controls now pass; the direct selection/source/mode comparison/transition and live document/path/await controls above remain incomplete. |

## Validation and limits

- `/tmp/custodian-opui/bin/python custodian/tools/validation/operator_workbench_ui_smoke.py`: PASS, with pinned Textual `0.89.1` and all expanded Pilot portions; no optional-dependency skip.
- `/tmp/custodian-opui/bin/python /tmp/custodian-r1-browser-probe.py .`: PASS for independent R0-01 accepted projections and R0-02 PREVIEW-mode failed/successful deletion proofs.
- `/tmp/custodian-opui/bin/python /tmp/custodian-r1-live-probe.py .`: PASS for R0-03 issue-to-result generation proof; reproduced R1-01 (`revision=42`, request/active generation `2`, active document mismatch, old document result accepted).
- `python3 custodian/tools/validation/operator_animation_workbench_smoke.py`: PASS supporting discovery/source-authority preservation.
- Scoped graph change/callee analysis was used first; graph is stale at `cbc4acc` and exact source/diff reads supplied current evidence. Graph test gaps are not treated as proof that smoke coverage is absent.
- Changed-artifact closeout validation: PASS 2/2 (`review_pairing_contract`, `visual_review_handoff`), complete coverage, zero failed/timed-out/skipped; report `/tmp/custodian-r1-review-validation-renamed.json`. `git diff --check`: PASS.
- Moment Forge: not run — deterministic authoring-tool state/concurrency review. Renderer/media capture: not required.
- Original production crash traceback remains unavailable; no crash-root-cause claim is made.

## Executable independent live proof

Run the Python block below with the pinned environment and repository root argument. The fake client replaces transport only; app debounce, controller, actual server command construction/send callback, result cause projection, and application guards are exercised. Mount drain is incidental; race ordering uses explicit events.

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
            switched_live = replace(prior, paths=('review-after-document-switch',))
            started, release = asyncio.Event(), asyncio.Event()
            original_thread = app._thread
            async def controlled(function, *args, **kwargs):
                if getattr(function, 'func', None) == service.live_preview:
                    started.set()
                    await release.wait()
                    return switched_live
                return await original_thread(function, *args, **kwargs)
            app._thread = controlled
            load = asyncio.create_task(app._apply_live_preview(event_c))
            await asyncio.wait_for(started.wait(), 3)
            other_path = path.parent.parent / 'other-document' / 'workbench.aseprite'
            controller.server.state.active_document_path = str(other_path)
            # Keep the revision and UI generation equal: document identity is an independent guard.
            assert controller.server.state.document_revision == 42
            release.set()
            await load
            actual = {'revision':controller.server.state.document_revision,
                      'request_generation':event_c.request_generation,
                      'active_generation':app.state.preview_generation,
                      'active_document_matches_selection':app._live_document_matches_selection(),
                      'stale_document_result_applied':app.preview_view is switched_live}
            print('R1 document switch', actual, flush=True)
            assert app.preview_view is switched_live, 'document-switch defect did not reproduce'
        finally:
            app_module.LIVE_PREVIEW_DEBOUNCE_SEC = old_debounce
asyncio.run(probe())

async def synchronous_live_probe():
    service = smoke.PilotService()
    app = OperatorWorkbenchApp(service=service, startup=service.selection)
    async with app.run_test(size=(80,35)) as pilot:
        await pilot.pause(0.3)
        app.action_mode_preview(); await pilot.pause(0.2)
        previous = app.preview_view
        app.state.preview_source = 'workbench'
        path = app._selected_live_workbench_path()
        app.live_bridge.server.state.active_document_path = str(path)
        app.live_bridge.server.state.document_revision = 42
        started, release = asyncio.Event(), asyncio.Event()
        output = app.live_bridge._live_preview_path(path)
        async def export(_workbench, _revision):
            started.set(); await release.wait()
            return {'output_path':str(output), 'frames':6, 'frame_width':96, 'frame_height':96}
        app.live_bridge.request_preview_export = export
        live = replace(previous, source='live', paths=('review-sync-old-document',))
        service.live_preview = lambda *args, **kwargs: live
        load = asyncio.create_task(app._load_preview(generation=app._next_preview_generation()))
        await asyncio.wait_for(started.wait(),3)
        app.live_bridge.server.state.active_document_path = str(path.parent.parent/'other-document'/'workbench.aseprite')
        release.set(); await load
        print('R1 synchronous export document switch', {'active_document_matches_selection':app._live_document_matches_selection(), 'old_document_live_applied':app.preview_view is live},flush=True)
        assert app.preview_view is live
asyncio.run(synchronous_live_probe())
```

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Expanded green smoke still omitted direct document-switch-during-loader and selection/source/mode supersession controls. The first finish attempt rejected root-series cycle-2 filenames because its artifact scope requires the immediate review-target prefix; renamed the new packets/workstreams to that namespace while retaining review cycle 2/cap 2. The graph reports stale source positions; the first independent browser probe used the wrong ErrorDialog import and was corrected before execution.
- Root cause / contributing factors: Generation is now propagated correctly, but active editor document ownership is not rechecked around awaits; a generation-only comparison/transition fixture cannot prove all requested ownership triggers.
- Prevention / pipeline improvement: Cycle 2 names explicit guard/await checkpoints and an executable issue-to-result negative control; use Textual 0.89.1 and event barriers.
- Tooling / docs drift discovered: Finish packet naming must extend the immediate target correction workstream, yielding the nested cycle-2 identifier. Review packet Reviewed main is the prior review baseline, not the landed correction target; this receipt records the actual target 18d5f1f7392dc44ba1b70e4465e615866b7837ca. Graph build cbc4acc is stale, so exact references come from live source.
- Follow-up: operator-workbench-browser-preview-refresh-hardening-review-corrections-1-review-corrections-2
- What worked: Fresh isolated review and independent app/server issue-to-result probes reproduced the remaining defect while confirming the three original fixes.

## Next Handoff
- Next workstream: operator-workbench-browser-preview-refresh-hardening-review-corrections-1-review-corrections-2
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab
- Refresh reason: none
- Next action: Claim correction cycle 2, close R1-01 and the remaining R0-04 proof gap, then run its fresh paired review. This is the final automatic correction cycle.
- Blockers or open questions: FX adoption remains behind the browser correction/re-review lane; unresolved findings at review cycle 2 require human decision. Historic production crash traceback remains unavailable.
