#!/usr/bin/env python3
"""Non-destructive synthetic and real-repository workbench checks."""
import sys,tempfile
from pathlib import Path
from PIL import Image
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"operator"))
import animation_workbench_model as m

def strip(path,frames,w,h,color):
    im=Image.new("RGBA",(frames*w,h));
    for i in range(frames): im.putpixel((i*w+w//2,h//2),color)
    path.parent.mkdir(parents=True,exist_ok=True); im.save(path)

def main():
    with tempfile.TemporaryDirectory() as td:
        root=Path(td); raw=root/"raw.png"; out=root/"out.png"; source=root/"source.png"
        strip(source,2,96,96,(255,0,0,255)); canvas=Image.new("RGBA",(312,96))
        with Image.open(source) as src:
            for i in range(2): canvas.alpha_composite(src.crop((i*96,0,(i+1)*96,96)),(i*156+30,0))
        canvas.save(raw); b={"binding_id":"lower","frames":2,"frame_size":[96,96],"placement":[30,0]}; m.extract_binding(raw,b,{"width":156,"height":96},out)
        assert m.pixel_sha256(source)==m.pixel_sha256(out)
        bad=Image.open(raw); bad.putpixel((0,0),(1,1,1,255)); bad.save(raw)
        try: m.extract_binding(raw,b,{"width":156,"height":96},out); raise AssertionError("outside pixel accepted")
        except m.WorkbenchError: pass
    p=m.build_plan("melee_1h","idle_relaxed_01","e",weapon_id="vigil_pattern_dagger")
    assert [(x["profile"],x["layer"]) for x in p["layers"]]==[("melee_1h","lower_body"),("melee_1h","upper_body"),("melee_1h_dagger","weapon")]
    assert p["timeline"]["frames"]==4 and p["canvas"]=={"width":96,"height":96}
    print("PASS operator_animation_workbench_smoke: synthetic pixel roundtrip, bounds rejection, real Vigil resolution")
if __name__=="__main__": main()
