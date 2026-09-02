from __future__ import annotations

from dataclasses import asdict,dataclass
from datetime import datetime,timezone
import hashlib,json,uuid
from pathlib import Path
from typing import Literal
from PIL import Image
import animation_workbench_model as model
from .render import make_animation_gif,make_contact_sheet,make_onion_skin,make_silhouette_sheet

@dataclass(frozen=True)
class ReferenceIdentity:
    profile:str; group:str; action:str; direction:str; weapon:str=""; linked_profile:str=""
@dataclass
class ReferenceRecord:
    reference_id:str; identity:ReferenceIdentity; authority:Literal["canonical_source","workbench_reference","runtime_reference"]
    resolved_paths:list[str]; source_hashes:dict[str,str]; frame_count:int; frame_width:int; frame_height:int
    context_fingerprint:str; created_utc:str; layers:dict[str,str]
    def to_json(self): return asdict(self)

def _load(path:Path)->list[dict]: return json.loads(path.read_text()).get("references",[]) if path.exists() else []
def get(root:Path,reference_id:str)->dict:
    for x in _load(root/"references.json"):
        if x["reference_id"]==reference_id:return x
    raise model.WorkbenchError(f"unknown immutable reference: {reference_id}")

def resolve(root:Path,manifest:dict,*,profile:str,group:str,action:str,direction:str,weapon:str="",linked_profile:str="")->dict:
    index=model.source_index(model.SOURCE_ROOT,model.WEAPON_ROOT); layers={}
    weapon_context=model.resolve_weapon(weapon,linked_profile)
    resolved_linked=weapon_context.animation_profile if weapon_context else linked_profile
    profiles=[profile]+([resolved_linked] if resolved_linked else [])
    for (owner,layer,p,g,a,d),hit in sorted(index.items()):
        if p in profiles and (g,a,d)==(group,action,direction): layers[layer]=str(Path(hit[0]).resolve())
    if not layers: raise model.WorkbenchError("semantic canonical reference did not resolve")
    # Match the Workbench presentation rule: modular body supersedes full_body.
    if {"lower_body","upper_body"} <= set(layers): layers.pop("full_body",None)
    first=next(iter(layers.values()))
    with Image.open(first) as sample:
        frame_height=sample.height; frame_count=next(hit[1].frames for key,hit in index.items() if str(Path(hit[0]).resolve())==first); frame_width=sample.width//frame_count
    identity=ReferenceIdentity(profile,group,action,direction,weapon,linked_profile)
    hashes={k:model.file_sha256(Path(v)) for k,v in sorted(layers.items())}
    digest=hashlib.sha256(json.dumps([asdict(identity),hashes],sort_keys=True).encode()).hexdigest()[:12]
    record=ReferenceRecord(digest,identity,"canonical_source",list(layers.values()),hashes,frame_count,frame_width,frame_height,
                           manifest.get("context",{}).get("fingerprint",""),datetime.now(timezone.utc).isoformat(),layers).to_json()
    items=[x for x in _load(root/"references.json") if x["reference_id"]!=digest]+[record]
    (root/"references.json").write_text(json.dumps({"schema":"custodian.operator_art_references.v1","references":items},indent=2)+"\n")
    return record

def layer_frames(record:dict,layer:str)->list[Image.Image]:
    path=record["layers"].get(layer)
    if not path: raise model.WorkbenchError(f"reference layer unavailable: {layer}")
    with Image.open(path) as image:
        image=image.convert("RGBA"); w=record["frame_width"]; h=record["frame_height"]
        return [image.crop((i*w,0,(i+1)*w,h)) for i in range(record["frame_count"])]

def composite_frames(record:dict)->list[Image.Image]:
    result=[Image.new("RGBA",(record["frame_width"],record["frame_height"]),(0,0,0,0)) for _ in range(record["frame_count"])]
    order=["lower_body","full_body","upper_body","cape","head","weapon","fx"]
    for layer in order:
        if layer not in record["layers"]:continue
        for base,overlay in zip(result,layer_frames(record,layer)):base.alpha_composite(overlay)
    return result

def render(root:Path,record:dict,frames:list[int]|None=None)->dict:
    selected=composite_frames(record); selected=[selected[i-1] for i in frames] if frames else selected
    out=root/"references"/record["reference_id"]/"renders"; (out/"frames").mkdir(parents=True,exist_ok=True)
    paths=[]
    for i,image in enumerate(selected,1): p=out/"frames"/f"frame_{i:03d}.png"; image.save(p); paths.append(p)
    strip=out/"strip.png"; canvas=Image.new("RGBA",(selected[0].width*len(selected),selected[0].height));
    for i,image in enumerate(selected):canvas.alpha_composite(image,(i*image.width,0))
    canvas.save(strip); make_contact_sheet(paths,out/"contact_sheet.png"); make_silhouette_sheet(paths,out/"silhouette.png"); make_onion_skin(paths,out/"onion_skin.png"); make_animation_gif(paths,out/"animation.gif",fps=12)
    return {"strip":str(strip.resolve()),"frames":[str(x.resolve()) for x in paths],"contact_sheet":str((out/"contact_sheet.png").resolve()),"silhouette":str((out/"silhouette.png").resolve()),"onion_skin":str((out/"onion_skin.png").resolve()),"animation":str((out/"animation.gif").resolve())}
