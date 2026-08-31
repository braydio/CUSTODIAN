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
    with tempfile.TemporaryDirectory() as td:
        p=Path(td)/"frame.png"; Image.new("RGBA",size,(0,0,0,0)).save(p); image=Image.open(p); image.putpixel((3,4),(255,0,0,255)); image.save(p); image.close()
        metric=frame_metrics(p); assert metric["alpha_bbox"]==[3,4,4,5] and metric["opaque_pixels"]==1
        animation=animation_metrics([p,p]); assert animation["duplicate_adjacent_frames"]==[2]
        qa=run_qa(animation,required_landmarks=["head_center"],landmarks=[],critiques=[]); assert qa["status"]=="NEEDS_HUMAN_REVIEW" and qa["publish_authorized"] is False
    print("PASS operator_art_agent_semantic_smoke: landmarks, RLE masks, metrics, QA")


if __name__=="__main__": main()
