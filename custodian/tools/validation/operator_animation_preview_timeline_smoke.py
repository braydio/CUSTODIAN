#!/usr/bin/env python3
import hashlib, json, sys, tempfile
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/"custodian/tools/operator"))
from animation_preview import (AnimationPreviewProvider, ReviewSequence, SemanticIdentity,
    TimelineClip, flatten_sequence, load_sequence, save_sequence)

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
    canonical=provider.load(preview.identity,"canonical"); assert canonical.frame_size==(96,96)
    sequence=ReviewSequence("boundary",[TimelineClip("melee_1h","attack","fast_01","e",8,2,0,0),TimelineClip("melee_1h","attack","fast_01","e",12,1,1,1),TimelineClip("melee_1h","attack","fast_01","e")])
    path=save_sequence(sequence,root/"sequences"); loaded=load_sequence(path)
    assert len(loaded.clips)==3 and len(flatten_sequence(loaded,provider))==5
    loaded.clips[0],loaded.clips[1]=loaded.clips[1],loaded.clips[0]; loaded.clips.pop(); assert len(loaded.clips)==2
    assert before==(sha(runtime),sha(source),sha(catalog))
print("operator_animation_preview_timeline_smoke ok")
