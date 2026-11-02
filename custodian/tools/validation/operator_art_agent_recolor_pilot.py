#!/usr/bin/env python3
from __future__ import annotations
from datetime import datetime,timezone
from pathlib import Path
import json,sys
from PIL import Image
ROOT=Path(__file__).resolve().parents[3];sys.path.insert(0,str(ROOT/"custodian/tools/operator"))
import animation_workbench_model as model
from art_agent.service import ArtAgentService
from art_agent.palette import relative_luminance

def production_hashes()->dict[str,str]:
    runtime=model.CUSTODIAN_ROOT/"content/sprites/operator/runtime"
    paths=list(model.SOURCE_ROOT.rglob("*.png"))+list(runtime.rglob("*.png"));return {str(p):model.file_sha256(p) for p in paths}

def main()->int:
    stamp=datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ");root=ROOT/".ai/operator_art_agent/pilots/recolor"/stamp
    service=ArtAgentService(art_root=root/"sessions",workspace_root=root/"workbench",aseprite=Path("/usr/bin/aseprite")); protected=production_hashes()
    session=service.start_session(profile="melee_1h",group="posture",action="idle_ready_01",direction="e",weapon="vigil_pattern_dagger")
    baseline=service.render(session,mode="layer",layer="upper_body",include_drafts=False); baseline_sha=model.file_sha256(Path(service.status(session)["workbench_path"]));baseline_frame_sha=service._layer_frame_hash(session,"upper_body",1)
    with Image.open(baseline["frames"][0]) as image:
        rgba=image.convert("RGBA"); pixels=list(rgba.getdata()); opaque=sorted({p[:3] for p in pixels if p[3]==255},key=lambda rgb:(relative_luminance(rgb),rgb))
        original_rgb=off_rgb=None
        for candidate in opaque:
            for channel,value in enumerate(candidate):
                if not value: continue
                trial=list(candidate);trial[channel]-=1;trial=tuple(trial)
                if trial not in opaque and not any(relative_luminance(trial)<relative_luminance(other)<relative_luminance(candidate) for other in opaque): original_rgb,off_rgb=candidate,list(trial);break
            if original_rgb is not None:break
        assert original_rgb is not None and off_rgb is not None
        original=(*original_rgb,255);off=[*off_rgb,255];index=next(i for i,p in enumerate(pixels) if p==original);x,y=index%rgba.width,index//rgba.width
    service.set_edit_scope(session,allowed=[{"layer":"upper_body","frames":[1,2,3,4,5]}],operations=["paint_pixels","recolor_plan"])
    service.apply_operation(session,{"type":"paint_pixels","frame":1,"layer":"upper_body","pixels":[{"x":x,"y":y,"rgba":off}]},operation_key="pilot-off-palette")
    off_sha=model.file_sha256(Path(service.status(session)["workbench_path"]))
    reference=service.reference_resolve(session,profile="melee_1h",group="posture",action="idle_ready_01",direction="e",weapon="vigil_pattern_dagger",linked_profile="melee_1h_dagger")
    plan=service.recolor_plan(session,reference_id=reference["reference_id"],scopes=[{"target_layer":"upper_body","reference_layer":"upper_body"}],frames=[1,2,3,4,5])
    for mapping in plan["mappings"]:
        if mapping["source_rgb"]==off[:3]: action,destination="map",list(original[:3])
        else: action,destination="preserve",None
        plan=service.recolor_set_mapping(session,plan_id=plan["plan_id"],mapping_id=mapping["mapping_id"],action=action,destination_rgb=destination)
    assert plan["status"]=="READY"
    preview=service.recolor_preview(session,plan_id=plan["plan_id"]); applied=service.recolor_apply(session,plan_id=plan["plan_id"],operation_key="pilot-recolor"); review=service.recolor_review(session,plan_id=plan["plan_id"]);assert review["status"]=="GREEN"
    assert service._layer_frame_hash(session,"upper_body",1)==baseline_frame_sha
    undo_recolor=service.undo_last(session);assert model.file_sha256(Path(service.status(session)["workbench_path"]))==off_sha
    undo_injection=service.undo_last(session);assert model.file_sha256(Path(service.status(session)["workbench_path"]))==baseline_sha
    assert production_hashes()==protected
    report={"status":"PASS","session":str(session),"plan_id":plan["plan_id"],"preview":preview,"review":review,"atomic_undo":True,"baseline_restored":True,"production_unchanged":True}
    (root/"pilot_report.json").write_text(json.dumps(report,indent=2)+"\n");print(json.dumps(report,indent=2));return 0
if __name__=="__main__":raise SystemExit(main())
