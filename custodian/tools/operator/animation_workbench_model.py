#!/usr/bin/env python3
"""Pure semantic model and pixel transforms for Operator animation workbenches."""
from __future__ import annotations

import hashlib, importlib.util, json, sys
from dataclasses import asdict, dataclass
from pathlib import Path
from PIL import Image

REPO_ROOT = Path(__file__).resolve().parents[3]
CUSTODIAN_ROOT = REPO_ROOT / "custodian"
PIPELINES = CUSTODIAN_ROOT / "tools/pipelines"
SOURCE_ROOT = CUSTODIAN_ROOT / "content/sprites/operator/source/animations"
WEAPON_ROOT = CUSTODIAN_ROOT / "content/sprites/weapons"
CATALOG = CUSTODIAN_ROOT / "content/data/operator/generated/operator_animation_catalog.generated.json"
SCHEMA_NAME = "custodian.operator_animation_workbench.v1"
PRESENTATION_ORDER = ("cape", "lower_body", "upper_body", "head", "weapon", "fx")

def _load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path); module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module; spec.loader.exec_module(module); return module

SCHEMA = _load("operator_asset_schema_workbench", PIPELINES / "operator_asset_schema.py")
BUILDER = _load("operator_runtime_builder_workbench", PIPELINES / "build_operator_runtime.py")

class WorkbenchError(RuntimeError): pass

@dataclass(frozen=True)
class ActionIdentity:
    profile: str; group: str; action: str; direction: str

@dataclass
class WeaponContext:
    weapon_id: str; animation_profile: str; presentation_mode: str

@dataclass
class LayerBinding:
    binding_id: str; aseprite_layer_name: str; role: str; editable: bool
    owner: str; profile: str; group: str; action: str; direction: str; layer: str
    source_path: str; runtime_path: str; source_file_sha256: str; source_pixel_sha256: str
    frames: int; frame_size: list[int]; placement: list[int]; timeline_mapping: str

def file_sha256(path: Path) -> str:
    h=hashlib.sha256()
    with path.open("rb") as f:
        for b in iter(lambda:f.read(1024*1024), b""): h.update(b)
    return h.hexdigest()

def pixel_sha256(path: Path) -> str:
    with Image.open(path) as im:
        im=im.convert("RGBA"); h=hashlib.sha256(); h.update(im.width.to_bytes(8,"big")); h.update(im.height.to_bytes(8,"big")); h.update(im.tobytes()); return h.hexdigest()

def rel(path: Path, repo_root: Path=REPO_ROOT) -> str:
    try: return path.resolve().relative_to(repo_root.resolve()).as_posix()
    except ValueError: return str(path.resolve())

def source_index(source_root: Path=SOURCE_ROOT, weapon_root: Path=WEAPON_ROOT):
    groups={}
    for path,key in BUILDER.scan_sources(source_root, weapon_root):
        sid=SCHEMA.semantic_identity(key); groups.setdefault(sid,[]).append((path,key))
    dup=[(sid,v) for sid,v in groups.items() if len(v)>1]
    if dup:
        lines=["ambiguous canonical source identity"]
        for sid,vals in dup: lines += [str(sid), *[f"  {p}" for p,_ in vals]]
        raise WorkbenchError("\n".join(lines))
    return {sid:v[0] for sid,v in groups.items()}

def resolve_group(index, profile, action, direction, requested=""):
    groups=sorted({sid[3] for sid in index if sid[0]=="operator" and sid[2]==profile and sid[4]==action and sid[5]==direction})
    if requested:
        if requested not in groups: raise WorkbenchError(f"group {requested!r} not found; candidates: {groups or 'none'}")
        return requested
    if len(groups)==1: return groups[0]
    if not groups: raise WorkbenchError(f"action not found; inferred suggestion: --group {SCHEMA.infer_action_group(action)}")
    raise WorkbenchError(f"ambiguous action group; candidates: {', '.join(groups)}; pass --group")

def resolve_weapon(weapon_id: str, linked_profile: str="", catalog_path: Path=CATALOG) -> WeaponContext|None:
    if not weapon_id and not linked_profile: return None
    if weapon_id and catalog_path.exists():
        item=json.loads(catalog_path.read_text()).get("weapons",{}).get(weapon_id)
        if item:
            return WeaponContext(weapon_id, linked_profile or item.get("animation_profile",""), item.get("presentation_mode","hybrid"))
    matches=[]
    if weapon_id:
        for p in (CUSTODIAN_ROOT/"game/actors/operator").glob("*_definition.tres"):
            text=p.read_text(); fields={}
            import re
            for name in ("weapon_id","animation_profile","weapon_presentation_mode"):
                m=re.search(rf'^\s*{name}\s*=\s*(?:&)?"([^"]*)"',text,re.M)
                if m: fields[name]=m.group(1)
            if fields.get("weapon_id")==weapon_id: matches.append((p,fields))
        if len(matches)!=1: raise WorkbenchError(f"weapon_id {weapon_id!r} resolved to {len(matches)} definitions")
        f=matches[0][1]; return WeaponContext(weapon_id, linked_profile or f.get("animation_profile",""), f.get("weapon_presentation_mode","hybrid"))
    return WeaponContext("linked_profile",linked_profile,"hybrid")

def build_plan(profile, action, direction, group="", weapon_id="", linked_profile="", *, repo_root=REPO_ROOT, source_root=SOURCE_ROOT, weapon_root=WEAPON_ROOT, catalog_path=CATALOG):
    index=source_index(source_root,weapon_root); group=resolve_group(index,profile,action,direction,group)
    identity=ActionIdentity(profile,group,action,direction); selected=[]
    for layer in SCHEMA.LAYERS:
        sid=("operator",layer,profile,group,action,direction)
        if sid in index: selected.append(index[sid])
    available={k.layer for _,k in selected}
    if {"lower_body","upper_body"} <= available:
        selected=[x for x in selected if x[1].layer!="full_body"]
    weapon=resolve_weapon(weapon_id,linked_profile,catalog_path)
    if weapon and weapon.presentation_mode in {"authored_overlay","hybrid"}:
        for layer in ("weapon","fx"):
            candidates=[v for sid,v in index.items() if sid[1]==layer and sid[2]==weapon.animation_profile and sid[3:]==(group,action,direction)]
            selected += candidates
    if not selected: raise WorkbenchError("no canonical layers resolved")
    width=max(k.frame_width for _,k in selected); height=max(k.frame_height for _,k in selected)
    for _,k in selected:
        if (width-k.frame_width)%2 or (height-k.frame_height)%2: raise WorkbenchError(f"half-pixel centering required for {k.layer}")
    clock=next((x for name in ("lower_body","full_body","upper_body") for x in selected if x[1].layer==name),max(selected,key=lambda x:x[1].frames))
    ordered=sorted(selected,key=lambda x:PRESENTATION_ORDER.index(x[1].layer))
    bindings=[]
    for path,k in ordered:
        linked=k.animation_profile!=profile; bid=(f"{k.layer}__{weapon.weapon_id}" if linked and weapon else k.layer)
        bindings.append(LayerBinding(bid,bid,"linked_fx" if linked and k.layer=="fx" else "linked_weapon" if linked else "editable",True,k.owner,k.animation_profile,k.action_group,k.action,k.direction,k.layer,rel(path,repo_root),rel((CUSTODIAN_ROOT/SCHEMA.canonical_runtime_path(k)),repo_root),file_sha256(path),pixel_sha256(path),k.frames,[k.frame_width,k.frame_height],[(width-k.frame_width)//2,(height-k.frame_height)//2],"exact" if k.frames==clock[1].frames else "editor_sequential_only"))
    return {"schema":SCHEMA_NAME,"identity":asdict(identity),"weapon_context":asdict(weapon) if weapon else None,"timeline":{"frames":clock[1].frames,"preview_fps":12,"timing_authority":False,"clock_owner":clock[1].layer},"canvas":{"width":width,"height":height},"aseprite":{"path":"","last_synced_sha256":None},"layers":[asdict(x) for x in bindings],"references":[],"last_publish":{"timestamp":None,"validation_status":None}}

def extract_binding(raw: Path, binding: dict, canvas: dict, output: Path):
    with Image.open(raw) as im:
        im=im.convert("RGBA"); cw,ch=canvas["width"],canvas["height"]; frames=binding["frames"]
        if im.size != (cw*frames,ch): raise WorkbenchError(f"raw export contract changed: {im.size}")
        fw,fh=binding["frame_size"]; x,y=binding["placement"]; out=Image.new("RGBA",(fw*frames,fh))
        for i in range(frames):
            frame=im.crop((i*cw,0,(i+1)*cw,ch)); alpha=frame.getchannel("A"); legal=Image.new("L",(cw,ch)); legal.paste(255,(x,y,x+fw,y+fh))
            outside=Image.eval(legal,lambda v:255-v)
            bbox=Image.composite(alpha,Image.new("L",alpha.size),outside).getbbox()
            if bbox: raise WorkbenchError(f"illegal outside-canvas pixels: layer={binding['binding_id']} frame={i+1} bbox={bbox} legal={(x,y,x+fw,y+fh)}")
            out.paste(frame.crop((x,y,x+fw,y+fh)),(i*fw,0))
        output.parent.mkdir(parents=True,exist_ok=True); out.save(output)
