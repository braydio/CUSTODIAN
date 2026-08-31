#!/usr/bin/env python3
from __future__ import annotations
import hashlib, subprocess, sys, tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]; sys.path.insert(0,str(ROOT/"custodian/tools/operator"))
import animation_workbench as workbench
import animation_workbench_model as model
from art_agent.aseprite_bridge import ArtAgentBridge
from art_agent.service import ArtAgentService, write_json

def tree_hashes(root):
    return {str(path.relative_to(ROOT)):hashlib.sha256(path.read_bytes()).hexdigest() for path in sorted(root.rglob("*")) if path.is_file()} if root.exists() else {}

def main():
    if workbench.resolve_aseprite() is None:
        print("SKIP operator_art_agent_aseprite_smoke: Aseprite executable unavailable"); return
    subprocess.run([sys.executable,str(ROOT/"custodian/tools/validation/operator_art_agent_smoke.py"),"--aseprite-child"],check=True)
    protected=[ROOT/"custodian/content/sprites/operator/source/animations",ROOT/"custodian/content/sprites/operator/runtime/animations",ROOT/"custodian/game/actors/operator"]
    before={str(path):tree_hashes(path) for path in protected}
    with tempfile.TemporaryDirectory() as td:
        temp=Path(td); service=ArtAgentService(art_root=temp/"art",workspace_root=temp/"workbench",aseprite=workbench.resolve_aseprite())
        session=service.start_session(profile="melee_1h",group="locomotion",action="walk_01",direction="e",weapon="vigil_pattern_dagger")
        inspection=service.inspect(session); assert inspection["frames"]==8 and inspection["canvas"]=={"width":96,"height":96}
        loaded=service.load_session(session); root=session.parent; bridge=ArtAgentBridge(aseprite=workbench.resolve_aseprite())
        def expect(fragment, request):
            path=root/"requests/security.json"; response=root/"responses/security.json"; write_json(path,request)
            try: bridge.execute(request_path=path,response_path=response,expected_request_id=request["request_id"],expected_operation_key=request["operation_key"])
            except Exception as error: assert fragment in str(error),(fragment,error)
            else: raise AssertionError(f"expected {fragment}")
        bad=service._build_request(loaded,"security_nonce",{"type":"inspect"},"security_nonce_key"); bad["nonce"]="wrong"; expect("capability mismatch",bad)
        outside=service._build_request(loaded,"security_output",{"type":"render_clean","output":str((temp/"outside.png").resolve())},"security_output_key"); expect("outside authorized preview root",outside)
        initial=Path(service.load_session(session).workbench_path).read_bytes(); service.render(session)
        service.set_landmarks(session,[{"frame":1,"name":"head_center","x":48,"y":30,"semantic_side":"center","confidence":0.5,"provenance":"heuristic"},{"frame":1,"name":"hip_center","x":48,"y":55,"semantic_side":"center","confidence":0.5,"provenance":"heuristic"},{"frame":1,"name":"knee_near","x":53,"y":67,"semantic_side":"near","confidence":0.5,"provenance":"heuristic"},{"frame":1,"name":"knee_far","x":43,"y":65,"semantic_side":"far","confidence":0.5,"provenance":"heuristic"}])
        applied=0
        def layer_hash(layer,frame):
            frames=service.render(session,mode="layer",layer=layer)["frames"]; return model.file_sha256(Path(frames[frame-1]))

        # part-schema validation: unknown part and disallowed layer binding both fail closed
        try:
            service.define_mask(session,frame=1,layer="lower_body",part="not_a_real_part",polygon=[[48,54],[56,55],[55,70],[49,68]]); raise AssertionError("unknown part must be rejected")
        except model.WorkbenchError as error:
            assert "unknown Operator part" in str(error)
        try:
            service.define_mask(session,frame=1,layer="lower_body",part="head",polygon=[[48,54],[56,55],[55,70],[49,68]]); raise AssertionError("part/layer mismatch must be rejected")
        except model.WorkbenchError as error:
            assert "not a permitted binding" in str(error)

        # shift: registry-backed draft, exact target binding, temporary bake
        near=service.define_mask(session,frame=1,layer="lower_body",part="thigh_near",polygon=[[48,54],[56,55],[55,70],[49,68]])
        draft=service.create_draft(session,kind="shift",mask_id=near["mask_id"],dx=1,dy=0); applied+=1
        assert draft["response"]["draft_id"].startswith("__ART_DRAFT__")
        assert draft["draft"]["status"]=="ACTIVE" and draft["draft"]["kind"]=="shift" and draft["draft"]["source_mask_id"]==near["mask_id"]
        draft_id=draft["response"]["draft_id"]; assert draft["draft"]["draft_id"]==draft_id
        near_before=layer_hash("lower_body",1)
        bake=service.bake_draft(session,draft_id=draft_id); applied+=1
        assert bake["draft"]["status"]=="BAKED" and bake["response"]["needs_gap_repair"] is True
        assert layer_hash("lower_body",1)!=near_before

        forged=draft_id.rsplit("__",1)[0]+"__deadbeef"
        try:
            service.bake_draft(session,draft_id=forged); raise AssertionError("forged draft id must not bake")
        except model.WorkbenchError as error:
            assert "unknown Art Agent draft" in str(error)

        # copy: draft does not clear source
        far=service.define_mask(session,frame=1,layer="lower_body",part="thigh_far",polygon=[[40,53],[48,54],[47,68],[40,66]])
        copy_draft=service.create_draft(session,kind="copy",mask_id=far["mask_id"],destination_frame=3,dx=0,dy=0); applied+=1
        far_before=layer_hash("lower_body",1)
        copy_bake=service.bake_draft(session,draft_id=copy_draft["response"]["draft_id"]); applied+=1
        assert copy_bake["response"]["needs_gap_repair"] is False
        assert layer_hash("lower_body",1)==far_before

        # derived masks: boolean ops persist new records with parent tracking; sources untouched
        extra=service.define_mask(session,frame=1,layer="lower_body",part="foot_far",rect=[40,64,8,4])
        union=service.mask_union(session,far["mask_id"],extra["mask_id"],part="far_leg")
        assert union["provenance"]=="derived" and sorted(union["parents"])==sorted([far["mask_id"],extra["mask_id"]])
        assert len(union["spans"])>=len(far["spans"]) and len(union["spans"])>=len(extra["spans"])
        by_id={m["mask_id"]:m for m in service.get_masks(session)}
        assert by_id[far["mask_id"]]["status"]=="CURRENT" and by_id[extra["mask_id"]]["status"]=="CURRENT"

        # replace: requires a destination mask; bake clears destination only, source untouched.
        # Must run before the mirror test below, which clears this same frame1 far-leg region.
        far_source=service.define_mask(session,frame=1,layer="lower_body",part="thigh_far",polygon=[[40,53],[48,54],[47,68],[40,66]])
        far_dest=service.define_mask(session,frame=2,layer="lower_body",part="thigh_far",polygon=[[40,53],[48,54],[47,68],[40,66]])
        try:
            service.create_draft(session,kind="replace",mask_id=far_source["mask_id"]); raise AssertionError("replace without destination mask must be rejected")
        except ValueError as error:
            assert "destination_mask" in str(error)
        replace_draft=service.create_draft(session,kind="replace",mask_id=far_source["mask_id"],destination_mask_id=far_dest["mask_id"]); applied+=1
        assert replace_draft["draft"]["destination_mask_id"]==far_dest["mask_id"] and replace_draft["draft"]["destination_frame"]==2
        frame2_before=layer_hash("lower_body",2); frame1_before=layer_hash("lower_body",1)
        replace_bake=service.bake_draft(session,draft_id=replace_draft["response"]["draft_id"]); applied+=1
        assert layer_hash("lower_body",2)!=frame2_before
        assert layer_hash("lower_body",1)==frame1_before

        # mirror: deterministic, requires axis_x. Clears the original far-leg region at frame1.
        far_mirror=service.define_mask(session,frame=1,layer="lower_body",part="thigh_far",polygon=[[40,53],[48,54],[47,68],[40,66]])
        try:
            service.create_draft(session,kind="mirror",mask_id=far_mirror["mask_id"]); raise AssertionError("mirror without axis_x must be rejected")
        except ValueError as error:
            assert "axis_x" in str(error)
        mirror_draft=service.create_draft(session,kind="mirror",mask_id=far_mirror["mask_id"],axis_x=48); applied+=1
        mirror_bake=service.bake_draft(session,draft_id=mirror_draft["response"]["draft_id"]); applied+=1
        assert mirror_bake["draft"]["kind"]=="mirror"

        # stale draft refuses to bake, and is still discardable
        stale_source=service.define_mask(session,frame=4,layer="lower_body",part="thigh_far",polygon=[[40,53],[48,54],[47,68],[40,66]])
        stale_draft=service.create_draft(session,kind="shift",mask_id=stale_source["mask_id"],dx=1,dy=0); applied+=1
        service.apply_operation(session,{"type":"paint_pixels","frame":4,"layer":"lower_body","pixels":[{"x":44,"y":60,"rgba":[1,2,3,4]}]},operation_key="stale-mutation"); applied+=1
        try:
            service.bake_draft(session,draft_id=stale_draft["response"]["draft_id"]); raise AssertionError("stale draft must not bake")
        except model.WorkbenchError as error:
            assert "stale" in str(error).lower()
        service.discard_draft(session,stale_draft["response"]["draft_id"]); applied+=1

        service.render(session); qa=service.run_qa(session,required_landmarks=["head_center","hip_center","knee_near","knee_far"]); assert qa["publish_authorized"] is False

        while applied:
            service.undo_last(session); applied-=1
        assert Path(service.load_session(session).workbench_path).read_bytes()==initial
    assert before=={str(path):tree_hashes(path) for path in protected}
    print("PASS operator_art_agent_aseprite_smoke: V1 bridge, draft registry, safe bake, kind semantics, staleness")
if __name__=="__main__": main()
