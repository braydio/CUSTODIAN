"""Validated V1/V2 asset-family contracts."""
from __future__ import annotations
import json, re, string
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

SCHEMA_VERSION = "custodian.asset_family.v2"
READABLE_SCHEMAS = {"custodian.asset_family.v1", SCHEMA_VERSION}
FAMILIES_DIR = Path(__file__).resolve().parents[2] / "content/metadata/assets/families"
DIRECTIONS = ("n", "ne", "e", "se", "s", "sw", "w", "nw")
POLICY_DIRECTIONS = {"omni": ("omni",), "4dir": ("n", "e", "s", "w"), "8dir": DIRECTIONS, **{d: (d,) for d in DIRECTIONS}}
TOKEN = re.compile(r"^[a-z0-9][a-z0-9_-]*$")
TEMPLATE_TOKENS = {"domain","owner","kind","layer","action_group","variant","direction","frames","frame_width","frame_height","frame_size","filename"}

def _token(value: Any, label: str) -> str:
    if not isinstance(value, str) or not TOKEN.fullmatch(value): raise ValueError(f"{label} must be a lowercase semantic token")
    return value

@dataclass(frozen=True)
class AssetStateContract:
    id: str; layer: str; action_group: str; variant: str
    required: bool=False; recommended: bool=False; animation: bool=False; fps: float|None=None
    layout: str="auto"; columns: int|None=None; rows: int|None=None; min_direction_count: int=1
    required_directions: tuple[str,...]=(); frame_width: int|None=None; frame_height: int|None=None

@dataclass(frozen=True)
class AssetFamilyContract:
    id: str; kind: str; runtime_domain: str; runtime_owner: str; frame_width: int; frame_height: int
    direction_policy: str; states: dict[str,AssetStateContract]; auto_mirror: bool=False
    runtime_template: str|None=None; filename_policy: str|None=None; filename_template: str|None=None
    aliases: dict[str,str]=field(default_factory=dict); consumers: tuple[dict[str,Any],...]=(); schema: str=SCHEMA_VERSION
    @property
    def allowed_directions(self)->tuple[str,...]: return POLICY_DIRECTIONS[self.direction_policy]
    def resolve_state(self,name:str)->tuple[str|None,str]:
        if name in self.states: return name,f"exact state id '{name}'"
        if name in self.aliases: return self.aliases[name],f"alias '{name}' -> '{self.aliases[name]}'"
        return None,f"no state or alias for '{name}'"
    def state_frame_size(self,state:AssetStateContract)->tuple[int,int]: return state.frame_width or self.frame_width,state.frame_height or self.frame_height

def load_family(path:Path)->AssetFamilyContract: return parse_family(json.loads(path.read_text(encoding="utf-8")))
def load_all_families(directory:Path|None=None)->dict[str,AssetFamilyContract]:
    result={}
    for path in sorted((directory or FAMILIES_DIR).glob("*.asset.json")):
        family=load_family(path)
        if family.id in result: raise ValueError(f"duplicate family id: {family.id}")
        result[family.id]=family
    return result

def parse_family(raw:dict[str,Any])->AssetFamilyContract:
    if not isinstance(raw,dict) or raw.get("schema") not in READABLE_SCHEMAS: raise ValueError(f"unknown family schema: {raw.get('schema') if isinstance(raw,dict) else None}")
    family_id,kind=_token(raw.get("id"),"family.id"),_token(raw.get("kind"),"family.kind")
    runtime,canvas=raw.get("runtime"),raw.get("canvas")
    if not isinstance(runtime,dict) or not isinstance(canvas,dict): raise ValueError("runtime and canvas must be objects")
    domain=str(runtime.get("domain","")); owner=_token(runtime.get("owner"),"runtime.owner")
    if not domain or domain.startswith(("/","content/")) or ".." in Path(domain).parts: raise ValueError("runtime.domain must be below content/")
    width,height=canvas.get("width"),canvas.get("height")
    if not isinstance(width,int) or isinstance(width,bool) or width<=0 or not isinstance(height,int) or isinstance(height,bool) or height<=0: raise ValueError("canvas dimensions must be positive integers")
    policy=str(raw.get("direction_policy",""))
    if policy not in POLICY_DIRECTIONS: raise ValueError(f"unsupported direction_policy '{policy}'")
    states_raw=raw.get("states")
    if not isinstance(states_raw,dict) or not states_raw: raise ValueError("states must be a non-empty object")
    states={}
    for sid,data in states_raw.items():
        _token(sid,"state id")
        if not isinstance(data,dict): raise ValueError(f"states.{sid} must be an object")
        layout=str(data.get("layout","auto"))
        if layout not in {"auto","copy","horizontal_strip","vertical_strip","grid"}: raise ValueError(f"states.{sid}.layout invalid")
        columns,rows=data.get("columns"),data.get("rows")
        if layout=="grid" and (not isinstance(columns,int) or columns<=0 or not isinstance(rows,int) or rows<=0): raise ValueError(f"states.{sid}: grid requires columns/rows")
        required_dirs=tuple(data.get("required_directions",()))
        if any(d not in POLICY_DIRECTIONS[policy] for d in required_dirs): raise ValueError(f"states.{sid}: required direction outside policy")
        minimum=data.get("min_direction_count",1)
        if not isinstance(minimum,int) or minimum<1 or minimum>len(POLICY_DIRECTIONS[policy]): raise ValueError(f"states.{sid}: impossible min_direction_count")
        animation=bool(data.get("animation",False))
        if animation and layout=="copy": raise ValueError(f"states.{sid}: animation cannot use copy layout")
        for dimension in (data.get("frame_width"), data.get("frame_height")):
            if dimension is not None and (not isinstance(dimension,int) or isinstance(dimension,bool) or dimension<=0): raise ValueError(f"states.{sid}: frame override must be a positive integer")
        states[sid]=AssetStateContract(sid,_token(data.get("layer"),f"states.{sid}.layer"),_token(data.get("action_group"),f"states.{sid}.action_group"),_token(data.get("variant"),f"states.{sid}.variant"),bool(data.get("required",False)),bool(data.get("recommended",False)),animation,data.get("fps"),layout,columns,rows,minimum,required_dirs,data.get("frame_width"),data.get("frame_height"))
    aliases=raw.get("aliases",{})
    if not isinstance(aliases,dict) or any(target not in states for target in aliases.values()): raise ValueError("unresolved aliases")
    consumers=raw.get("consumers",[])
    if not isinstance(consumers,list) or any(not isinstance(c,dict) for c in consumers): raise ValueError("consumers must be objects")
    filename_policy=runtime.get("filename_policy")
    if filename_policy is not None and filename_policy not in {"canonical","template"}: raise ValueError("invalid runtime filename_policy override")
    runtime_template=runtime.get("template")
    filename_template=runtime.get("filename_template")
    for label,value in (("runtime.template",runtime_template),("runtime.filename_template",filename_template)):
        if value is None: continue
        if not isinstance(value,str) or not value or value.startswith(("/","content/")) or ".." in Path(value).parts: raise ValueError(f"{label} must stay below content/")
        names={name for _,name,_,_ in string.Formatter().parse(value) if name}
        if names-TEMPLATE_TOKENS: raise ValueError(f"{label} has unsupported tokens")
    if filename_policy=="template" and not filename_template: raise ValueError("template filename policy override requires filename_template")
    return AssetFamilyContract(family_id,kind,domain,owner,width,height,policy,states,bool(raw.get("auto_mirror",False)),runtime_template,filename_policy,filename_template,dict(aliases),tuple(consumers),str(raw["schema"]))
