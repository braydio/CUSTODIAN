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
    print("PASS operator_art_agent_semantic_smoke: landmarks, frame-local staleness, RLE masks, metrics, per-frame QA")


if __name__=="__main__": main()
