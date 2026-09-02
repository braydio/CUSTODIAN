from __future__ import annotations

import json
from pathlib import Path
from PIL import Image,ImageDraw
from .metrics import animation_metrics
from .render import make_animation_gif,make_contact_sheet,make_onion_skin,make_silhouette_sheet

def compare(target:list[Image.Image],reference:list[Image.Image],out:Path,*,tail:int=2,head:int=2,landmarks:list[dict]|None=None)->dict:
    frames=target[-tail:]+reference[:head]
    # Transition review must compare semantic animations even when their
    # authored canvas contracts differ (for example 128x96 workbench art
    # against a legacy 96x96 reference). Pad into one transparent review
    # canvas; never resample or alter source pixels.
    review_width=max(image.width for image in frames)
    review_height=max(image.height for image in frames)
    normalized=[]
    for image in frames:
        if image.size==(review_width,review_height):
            normalized.append(image.convert("RGBA"))
            continue
        canvas=Image.new("RGBA",(review_width,review_height),(0,0,0,0))
        # Center narrower authored canvases in the review canvas. This keeps
        # body coordinates comparable without changing either source raster.
        offset=((review_width-image.width)//2,(review_height-image.height)//2)
        canvas.alpha_composite(image.convert("RGBA"),offset)
        normalized.append(canvas)
    frames=normalized
    out.mkdir(parents=True,exist_ok=True); paths=[]
    for i,image in enumerate(frames,1):p=out/f"frame_{i:03d}.png"; image.save(p); paths.append(p)
    target_metric=animation_metrics([paths[tail-1]])["frames"][0]; ref_metric=animation_metrics([paths[tail]])["frames"][0]
    def delta(name):
        a,b=target_metric.get(name),ref_metric.get(name)
        if a is None or b is None:return None
        if isinstance(a,list):return [b[i]-a[i] for i in range(len(a))]
        return b-a
    metrics={"alpha_bbox_delta":delta("alpha_bbox"),"visual_centroid_delta":delta("visual_centroid"),"baseline_delta":delta("baseline_y")}
    marks=landmarks or []
    for name in ("head_center","hip_center","knee_near","knee_far","toe_near","toe_far","weapon_grip","weapon_tip"):
        a=next((x for x in marks if x.get("phase")=="target" and x.get("name")==name),None); b=next((x for x in marks if x.get("phase")=="reference" and x.get("name")==name),None)
        metrics[name+"_delta"]=[b["x"]-a["x"],b["y"]-a["y"]] if a and b else None
    make_contact_sheet(paths,out/"transition_contact_sheet.png"); make_animation_gif(paths,out/"transition.gif",fps=12); make_silhouette_sheet(paths,out/"transition_silhouette.png"); make_onion_skin(paths,out/"transition_onion_skin.png")
    value={"target_frames":list(range(len(target)-tail+1,len(target)+1)),"reference_frames":list(range(1,head+1)),"handoff_metrics":metrics,"artifacts":{k:str((out/v).resolve()) for k,v in {"contact_sheet":"transition_contact_sheet.png","animation":"transition.gif","silhouette":"transition_silhouette.png","onion_skin":"transition_onion_skin.png"}.items()}}
    (out/"transition_metrics.json").write_text(json.dumps(value,indent=2)+"\n"); value["artifacts"]["metrics"]=str((out/"transition_metrics.json").resolve()); return value
