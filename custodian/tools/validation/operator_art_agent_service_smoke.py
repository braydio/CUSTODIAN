#!/usr/bin/env python3
from __future__ import annotations

import json, shutil, sys, tempfile
from unittest.mock import patch
from pathlib import Path

ROOT=Path(__file__).resolve().parents[3]; sys.path.insert(0,str(ROOT/"custodian/tools/operator"))
import animation_workbench as workbench
import animation_workbench_model as model
from art_agent.drafts import DraftRecord, save as save_drafts
from art_agent.models import ArtIdentity, ArtSession, CAPABILITY_SCHEMA, RESPONSE_SCHEMA
from art_agent.service import ArtAgentService, write_json
from art_agent.aseprite_bridge import ArtAgentBridge


class FakeBridge:
    def __init__(self,**_): pass
    def execute(self,*,request_path,response_path,expected_request_id=None,expected_operation_key=None):
        request=json.loads(request_path.read_text()); operation=request["operation"]
        changed=operation.get("type")!="move_region" or operation.get("dx")!=0 or operation.get("dy")!=0
        if operation.get("force_fail"): raise model.WorkbenchError("forced failure")
        if changed: Path(request["workbench"]).write_bytes(Path(request["workbench"]).read_bytes()+b"x")
        payload={"schema":RESPONSE_SCHEMA,"request_id":request["request_id"],"operation_key":request["operation_key"],"ok":True,"changed":changed,"changed_pixels":1 if changed else 0,"changed_bbox":[0,0,1,1] if changed else None}
        write_json(response_path,payload); return payload


def fixture(root: Path):
    art=root/"art/s/f"; workspace=root/"workspace/x"; art.mkdir(parents=True); workspace.mkdir(parents=True)
    wb=workspace/"workbench.aseprite"; wb.write_bytes(b"fixture")
    manifest=workspace/"workbench.json"; context="fingerprint"
    write_json(manifest,{"schema":model.SCHEMA_NAME,"identity":{"profile":"p","group":"g","action":"a","direction":"e"},"context":{"fingerprint":context},"canvas":{"width":8,"height":8},"timeline":{"document_frames":1},"layers":[],"pending_migration":None,"aseprite":{"last_synced_sha256":model.file_sha256(wb)}})
    capability=art/"capability.json"; session_path=art/"session.json"; sha=model.file_sha256(wb)
    session=ArtSession.create(session_id="s",created_utc="now",identity=ArtIdentity("p","g","a","e"),workbench_manifest=str(manifest.resolve()),workbench_path=str(wb.resolve()),context_fingerprint=context,workbench_sha256=sha,capability_path=str(capability.resolve()))
    write_json(session_path,session.to_json()); write_json(capability,{"schema":CAPABILITY_SCHEMA,"session_id":"s","nonce":"n","context_fingerprint":context,"workbench_manifest":str(manifest.resolve()),"workbench":str(wb.resolve()),"preview_root":str((art/"previews").resolve())}); (art/"backups").mkdir(); (art/"requests").mkdir(); (art/"responses").mkdir(); (art/"previews").mkdir()
    return ArtAgentService(art_root=root/"art",workspace_root=root/"workspace",bridge_factory=FakeBridge),session_path,wb


def expect(fragment,callback):
    try: callback()
    except Exception as error: assert fragment in str(error),(fragment,error)
    else: raise AssertionError(f"expected {fragment}")


def main():
    with tempfile.TemporaryDirectory() as td:
        root=Path(td); service,session,wb=fixture(root)
        assert service.status(session)["external_change"] is False
        key="retry-key"; first=service.apply_operation(session,{"type":"paint_pixels"},operation_key=key); second=service.apply_operation(session,{"type":"paint_pixels"},operation_key=key); assert first==second
        before=wb.read_bytes(); noop=service.apply_operation(session,{"type":"move_region","dx":0,"dy":0},operation_key="noop"); assert noop["status"]=="NOOP" and wb.read_bytes()==before
        before=wb.read_bytes(); expect("forced failure",lambda:service.apply_operation(session,{"type":"paint_pixels","force_fail":True},operation_key="fail")); assert wb.read_bytes()==before; expect("previously failed",lambda:service.apply_operation(session,{"type":"paint_pixels"},operation_key="fail"))

        expect("unknown Art Agent draft",lambda:service.bake_draft(session,draft_id="__ART_DRAFT__ghost__f001__deadbeef"))
        expect("unknown Art Agent draft",lambda:service.discard_draft(session,"__ART_DRAFT__ghost__f001__deadbeef"))
        expect("unknown Art Agent draft",lambda:service.resolve_gap_repair(session,"__ART_DRAFT__ghost__f001__deadbeef"))

        fixture_draft=DraftRecord(draft_id="__ART_DRAFT__far_leg__f001__aaaaaaaa",kind="shift",part="far_leg",source_mask_id="m1",destination_mask_id=None,source_layer="lower_body",source_frame=1,destination_layer="lower_body",destination_frame=1,source_spans=[{"y":0,"x0":0,"x1":1}],destination_spans=None,source_mask_fingerprint="fp",source_cel_fingerprint="fp",destination_cel_fingerprint="fp",draft_cel_fingerprint="fp",dx=1,dy=0,axis_x=None,created_operation_key="draft-op-1",created_workbench_sha256="sha",status="DISCARDED",created_utc="now")
        drafts_path=session.parent/"drafts.json"; save_drafts(drafts_path,[fixture_draft])
        expect("draft is not ACTIVE",lambda:service.bake_draft(session,draft_id=fixture_draft.draft_id))
        expect("cannot discard draft in status",lambda:service.discard_draft(session,fixture_draft.draft_id))

        active_draft=DraftRecord(**{**fixture_draft.to_json(),"status":"ACTIVE"})
        save_drafts(drafts_path,[active_draft])
        expect("draft has no unresolved gap repair",lambda:service.resolve_gap_repair(session,active_draft.draft_id))
        got=service.get_drafts(session); assert len(got)==1 and got[0]["draft_id"]==active_draft.draft_id and got[0]["status"]=="ACTIVE"
        drafts_path.unlink()

        outside=root/"outside/session.json"; outside.parent.mkdir(); outside.write_text("{}"); expect("escapes authorized root",lambda:service.load_session(outside))
        link=root/"art/link"; link.symlink_to(root/"outside",target_is_directory=True); expect("escapes authorized root",lambda:service.load_session(link/"session.json"))
        payload=json.loads(session.read_text()); external=root/"outside/workbench.aseprite"; external.write_bytes(b"x"); payload["workbench_path"]=str(external); session.write_text(json.dumps(payload)); expect("escapes authorized root",lambda:service.load_session(session))
        request=root/"request.json"; response=root/"response.json"; request.write_text("{}")
        bridge=ArtAgentBridge.__new__(ArtAgentBridge); bridge.aseprite=Path("/fake/aseprite")
        def bridge_payload(value, expected):
            def fake_run(*_args,**_kwargs):
                response.write_text(json.dumps(value)); return type("Completed",(),{"returncode":0,"stderr":"","stdout":""})()
            with patch("subprocess.run",side_effect=fake_run):
                expect(expected,lambda:bridge.execute(request_path=request,response_path=response,expected_request_id="request",expected_operation_key="key"))
        bridge_payload({"schema":"bad","request_id":"request","operation_key":"key","ok":True},"response schema mismatch")
        bridge_payload({"schema":RESPONSE_SCHEMA,"request_id":"wrong","operation_key":"key","ok":True},"request ID mismatch")
        bridge_payload({"schema":RESPONSE_SCHEMA,"request_id":"request","operation_key":"wrong","ok":True},"operation key mismatch")
    print("PASS operator_art_agent_service_smoke: confinement, rollback, NOOP, idempotency, draft registry")


if __name__=="__main__": main()
