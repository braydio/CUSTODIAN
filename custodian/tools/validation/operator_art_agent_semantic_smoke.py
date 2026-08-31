#!/usr/bin/env python3
from __future__ import annotations

import sys, tempfile
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]; sys.path.insert(0,str(ROOT/"custodian/tools/operator"))
from art_agent.landmarks import Landmark, reconcile_hashes
from art_agent.masks import bounds, combine, image_to_spans, morphology, polygon, spans_to_image
from art_agent.metrics import animation_metrics, frame_metrics
from art_agent.qa import run_qa


def main():
    size=(16,16); spans=polygon(size,[[2,2],[8,2],[8,8],[2,8]]); assert spans==image_to_spans(spans_to_image(spans,size)); assert bounds(spans)==[2,2,7,7]
    other=polygon(size,[[6,6],[12,6],[12,12],[6,12]])
    assert len(combine(spans,other,size,"union"))>len(combine(spans,other,size,"intersect")); assert morphology(spans,size,"dilate")!=spans
    human=Landmark(1,"head_center",4,4,"center",1.0,"human",True,"old"); agent=Landmark(1,"hip_center",4,8,"center",.8,"agent",False,"old"); reconciled=reconcile_hashes([human,agent],{1:"new"}); assert len(reconciled)==1 and reconciled[0].status=="STALE"

    human_f1=Landmark(1,"head_center",4,4,"center",1.0,"human",True,"h1"); human_f2=Landmark(2,"head_center",4,4,"center",1.0,"human",True,"h2")
    frame_local=reconcile_hashes([human_f1,human_f2],{1:"h1-changed",2:"h2"}); by_frame={x.frame:x for x in frame_local}
    assert len(frame_local)==2 and by_frame[1].status=="STALE" and by_frame[2].status=="CURRENT"

    with tempfile.TemporaryDirectory() as td:
        p=Path(td)/"frame.png"; Image.new("RGBA",size,(0,0,0,0)).save(p); image=Image.open(p); image.putpixel((3,4),(255,0,0,255)); image.save(p); image.close()
        metric=frame_metrics(p); assert metric["alpha_bbox"]==[3,4,4,5] and metric["opaque_pixels"]==1
        assert metric["baseline_y"]==4 and metric["alpha_area"]==1
        assert metric["single_pixel_components"]==1 and metric["isolated_opaque_pixels"]==[[3,4]]
        animation=animation_metrics([p,p]); assert animation["duplicate_adjacent_frames"]==[2]
        qa=run_qa(animation,required_landmarks=["head_center"],landmarks=[],critiques=[]); assert qa["status"]=="NEEDS_HUMAN_REVIEW" and qa["publish_authorized"] is False

        triple=animation_metrics([p,p,p])
        partial=run_qa(triple,required_landmarks=["head_center"],landmarks=[{"frame":1,"name":"head_center","status":"CURRENT"},{"frame":3,"name":"head_center","status":"CURRENT"}],critiques=[])
        missing_frames={item["frame"] for item in partial["findings"] if item["issue"]=="missing required landmark"}
        assert missing_frames=={2}

        stale=run_qa(triple,required_landmarks=["head_center"],landmarks=[{"frame":1,"name":"head_center","status":"STALE"}],critiques=[])
        assert any(item["frame"]==1 for item in stale["findings"] if item["issue"]=="missing required landmark")

        each_frame=run_qa(triple,required_landmarks={"each_frame":["head_center"]},landmarks=[{"frame":1,"name":"head_center","status":"CURRENT"},{"frame":2,"name":"head_center","status":"CURRENT"},{"frame":3,"name":"head_center","status":"CURRENT"}],critiques=[])
        assert each_frame["status"]!="NEEDS_HUMAN_REVIEW" and not any(item["issue"]=="missing required landmark" for item in each_frame["findings"])

        multi=Path(td)/"multi.png"; Image.new("RGBA",size,(0,0,0,0)).save(multi)
        chain=Path(td)/"chain.png"; chain_image=Image.new("RGBA",size,(0,0,0,0))
        for x,color in enumerate([(1,1,1,255),(2,2,2,255),(3,3,3,255),(4,4,4,255),(5,5,5,255)]): chain_image.putpixel((x,0),color)
        chain_image.save(chain)
        chain_metric=frame_metrics(chain); single_metric=frame_metrics(p)
        assert single_metric["palette_size"]==1 and chain_metric["palette_size"]==5
        assert chain_metric["single_pixel_components"]==0

        scrambled=[
            {"frame":3,"name":"head_center","x":20,"y":0},
            {"frame":1,"name":"head_center","x":0,"y":0},
            {"frame":4,"name":"head_center","x":30,"y":0},
            {"frame":2,"name":"head_center","x":10,"y":0},
            {"frame":1,"name":"weapon_grip","x":0,"y":0},
            {"frame":2,"name":"weapon_grip","x":5,"y":0},
            {"frame":3,"name":"weapon_grip","x":10,"y":0},
        ]
        multi_metrics=animation_metrics([multi,multi,multi,multi],scrambled)
        assert [item[0] for item in multi_metrics["trajectories"]["head_center"]]==[1,2,3,4]
        assert multi_metrics["trajectories"]["head_center"]==[[1,0,0],[2,10,0],[3,20,0],[4,30,0]]
        seam=multi_metrics["loop_seam_metrics"]["head_center"]
        assert seam["loop_seam_displacement"]==30 and abs(seam["median_internal_step"]-10)<1e-6 and abs(seam["normalized_seam_ratio"]-3)<1e-6
        assert "weapon_grip" in multi_metrics["loop_seam_metrics"]
        assert multi_metrics["frames"][0]["landmarks"]=={"head_center":[0,0],"weapon_grip":[0,0]}

        near=polygon(size,[[2,2],[6,2],[6,6],[2,6]])
        mask_summary=animation_metrics([multi],masks=[{"mask_id":"m1","part":"thigh_near","frame":1,"layer":"lower_body","spans":[{"y":s.y,"x0":s.x0,"x1":s.x1} for s in near],"bounds":bounds(near)}])["masks"]
        assert mask_summary and mask_summary[0]["mask_id"]=="m1" and mask_summary[0]["span_pixel_count"]==sum(s.x1-s.x0+1 for s in near)
    print("PASS operator_art_agent_semantic_smoke: landmarks, frame-local staleness, RLE masks, metrics v2, per-frame QA")


if __name__=="__main__": main()
