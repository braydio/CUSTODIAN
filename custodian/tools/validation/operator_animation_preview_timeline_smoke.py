#!/usr/bin/env python3
import hashlib, json, sys, tempfile
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/"custodian/tools/operator"))
from animation_preview import (AnimationPreviewProvider, ReviewSequence, SemanticIdentity,
    TimelineClip, flatten_sequence, load_sequence, save_sequence, scale_preview_frame)

def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()

with tempfile.TemporaryDirectory(prefix="operator_preview_") as raw:
    root=Path(raw); runtime=root/"runtime.png"; source=root/"source.png"
    strip=Image.new("RGBA",(312,96),(0,0,0,0)); strip.paste((255,0,0,255),(0,0,156,96)); strip.paste((0,255,0,255),(156,0,312,96)); strip.save(runtime)
    small=Image.new("RGBA",(192,96),(0,0,255,128)); small.save(source)
    catalog=root/"catalog.json"; key="melee_1h/attack/fast_01/e"
    catalog.write_text(json.dumps({"animations":{key:{"layers":{"full_body":{"path":"runtime.png","frames":2,"frame_size":[156,96]}}}}}))
    class K: frames=2; frame_width=96; frame_height=96
    provider=AnimationPreviewProvider(repo_root=root,catalog_path=catalog,source_index=lambda:{("operator","full_body","melee_1h","attack","fast_01","e"):(source,K())},workspace_root=root/".ai")
    before=(sha(runtime),sha(source),sha(catalog))
    preview=provider.load(SemanticIdentity("melee_1h","attack","fast_01","e"),"runtime")
    assert len(preview.frames)==2 and preview.frame_size==(156,96) and preview.frames[0].mode=="RGBA"
    native=scale_preview_frame(preview.frames[0],"1x")
    doubled=scale_preview_frame(preview.frames[0],"2x")
    assert native.size==(156,96) and native.tobytes()==preview.frames[0].tobytes()
    assert doubled.size==(312,192) and doubled.getpixel((2,2))==preview.frames[0].getpixel((1,1))
    square=Image.new("RGBA",(96,96),(7,8,9,0)); square.putpixel((2,3),(10,20,30,127))
    square_2x=scale_preview_frame(square,"2x")
    assert square_2x.size==(192,192) and square_2x.getpixel((4,6))==(10,20,30,127)
    canonical=provider.load(preview.identity,"canonical"); assert canonical.frame_size==(96,96)
    sequence=ReviewSequence("boundary",[TimelineClip("melee_1h","attack","fast_01","e",8,2,0,0),TimelineClip("melee_1h","attack","fast_01","e",12,1,1,1),TimelineClip("melee_1h","attack","fast_01","e")])
    path=save_sequence(sequence,root/"sequences"); loaded=load_sequence(path)
    assert len(loaded.clips)==3 and len(flatten_sequence(loaded,provider))==5
    loaded.clips[0],loaded.clips[1]=loaded.clips[1],loaded.clips[0]; loaded.clips.pop(); assert len(loaded.clips)==2
    assert before==(sha(runtime),sha(source),sha(catalog))

    # Equivalent presentation policy: modular body replaces full_body, while
    # authored FX remains on top. Full-body fallback still works by itself.
    def save_strip(name,color):
        path=root/name; Image.new("RGBA",(96,96),color).save(path); return path
    full=save_strip("full.png",(255,0,0,255)); lower=save_strip("lower.png",(0,0,255,255))
    upper=save_strip("upper.png",(0,0,0,0)); fx=save_strip("fx.png",(0,0,0,0))
    with Image.open(upper) as im:
        layer=im.convert("RGBA"); layer.putpixel((4,4),(0,255,0,255)); layer.save(upper)
    with Image.open(fx) as im:
        layer=im.convert("RGBA"); layer.putpixel((5,5),(255,255,0,200)); layer.save(fx)
    def row(path): return {"path":path.name,"frames":1,"frame_size":[96,96]}
    catalog.write_text(json.dumps({"animations":{
        key:{"layers":{"full_body":row(full),"lower_body":row(lower),"upper_body":row(upper),"fx":row(fx)}},
        "melee_1h/attack/fast_01/w":{"layers":{"full_body":row(full),"fx":row(fx)}}
    }}))
    modular=provider.load(SemanticIdentity("melee_1h","attack","fast_01","e"),"runtime")
    assert str(full) not in modular.paths and str(lower) in modular.paths and str(fx) in modular.paths
    assert modular.frames[0].getpixel((0,0))==(0,0,255,255)
    assert modular.frames[0].getpixel((4,4))==(0,255,0,255)
    assert modular.frames[0].getpixel((5,5))!=(0,0,255,255)
    fallback=provider.load(SemanticIdentity("melee_1h","attack","fast_01","w"),"runtime")
    assert str(full) in fallback.paths and fallback.frames[0].getpixel((0,0))==(255,0,0,255)
    class OneFrame: frames=1; frame_width=96; frame_height=96
    canonical_index={
        ("operator","full_body","melee_1h","attack","fast_01","e"):(full,OneFrame()),
        ("operator","lower_body","melee_1h","attack","fast_01","e"):(lower,OneFrame()),
        ("operator","upper_body","melee_1h","attack","fast_01","e"):(upper,OneFrame()),
        ("operator","fx","melee_1h","attack","fast_01","e"):(fx,OneFrame()),
    }
    equivalent=AnimationPreviewProvider(repo_root=root,catalog_path=catalog,source_index=lambda:canonical_index,workspace_root=root/"workspaces")
    canonical_modular=equivalent.load(SemanticIdentity("melee_1h","attack","fast_01","e"),"canonical")
    assert str(full) not in canonical_modular.paths and canonical_modular.frames[0].tobytes()==modular.frames[0].tobytes()
    workspace=root/"workspaces/melee_1h/attack/fast_01/e"; workspace.mkdir(parents=True)
    document=workspace/"workbench.aseprite"; document.write_bytes(b"saved-workbench")
    bindings=[]
    for name,path in (("full_body",full),("lower_body",lower),("upper_body",upper),("fx",fx)):
        bindings.append({"binding_id":name,"input_path":str(path),"frame_size":[96,96],"workspace_contract":{"frames":1}})
    (workspace/"workbench.json").write_text(json.dumps({"aseprite":{"path":str(document)},"layers":bindings}))
    workbench=equivalent.load(SemanticIdentity("melee_1h","attack","fast_01","e"),"workbench")
    assert str(full) not in workbench.paths and workbench.frames[0].tobytes()==modular.frames[0].tobytes()
print("operator_animation_preview_timeline_smoke ok")
