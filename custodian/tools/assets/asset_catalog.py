"""Generated tooling catalog V2; never gameplay authority."""
from __future__ import annotations
import hashlib,json
from dataclasses import dataclass
from pathlib import Path
CATALOG_PATH=Path(__file__).resolve().parents[2]/"content/metadata/assets/generated/asset_catalog.generated.json"
@dataclass
class CatalogEntry:
    semantic_identity:list[str]; path:str; frames:int; frame_size:list[int]; sha256:str
    state_id:str=""; direction:str="omni"; provenance:str="authored"; source_asset:str|None=None
def asset_catalog_key(state_id:str,direction:str)->str: return f"{state_id}::{direction}"
def load_catalog(path:Path|None=None)->dict:
    p=path or CATALOG_PATH
    if not p.exists(): return {"schema":"custodian.asset_catalog.v2","families":{}}
    raw=json.loads(p.read_text(encoding="utf-8"))
    if raw.get("schema")=="custodian.asset_catalog.v2": return raw
    migrated={"schema":"custodian.asset_catalog.v2","families":{}}
    for fid,fdata in raw.get("families",{}).items():
        assets={}
        for sid,entry in fdata.get("states",{}).items():
            identity=entry.get("semantic_identity",[]); direction=identity[-1] if len(identity)>=6 else "omni"
            assets[asset_catalog_key(sid,direction)]={**entry,"state_id":sid,"direction":direction,"provenance":"authored","source_asset":None}
        migrated["families"][fid]={"kind":fdata.get("kind",""),"assets":assets}
    return migrated
def save_catalog(catalog:dict,path:Path|None=None)->None:
    p=path or CATALOG_PATH; p.parent.mkdir(parents=True,exist_ok=True); catalog["schema"]="custodian.asset_catalog.v2"; p.write_text(json.dumps(catalog,indent=2)+"\n",encoding="utf-8")
def update_catalog_entry(catalog:dict,family_id:str,state_id:str,entry:CatalogEntry,kind:str="")->None:
    family=catalog.setdefault("families",{}).setdefault(family_id,{"kind":kind,"assets":{}}); family["kind"]=kind or family.get("kind","")
    family.setdefault("assets",{})[asset_catalog_key(state_id,entry.direction)]={"state_id":state_id,"direction":entry.direction,"semantic_identity":entry.semantic_identity,"path":entry.path,"frames":entry.frames,"frame_size":entry.frame_size,"sha256":entry.sha256,"provenance":entry.provenance,"source_asset":entry.source_asset}
def file_hash(path:Path)->str: return hashlib.sha256(path.read_bytes()).hexdigest()
