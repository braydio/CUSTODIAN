"""Validated schema-driven runtime routing."""
from __future__ import annotations
import json, string
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Any
from asset_contract import AssetFamilyContract, AssetStateContract
from asset_key import AssetKey
from asset_naming import canonical_filename
SCHEMAS_DIR=Path(__file__).resolve().parents[2]/"content/metadata/assets/schemas"
TOKENS={"domain","owner","kind","layer","action_group","variant","direction","frames","frame_width","frame_height","frame_size","filename"}
@dataclass(frozen=True)
class AssetKindSchema:
    kind:str; runtime_template:str; filename_policy:str; filename_template:str|None; backend_policy:str
    defaults:dict[str,Any]; post_process:tuple[str,...]; schema:str="custodian.asset_kind.v2"
def _validate_template(value:str,label:str)->str:
    if not isinstance(value,str) or not value or value.startswith(("/","content/")) or ".." in PurePosixPath(value).parts: raise ValueError(f"{label} must stay below content/")
    names={name for _,name,_,_ in string.Formatter().parse(value) if name}; unknown=names-TOKENS
    if unknown: raise ValueError(f"{label} has unsupported tokens: {sorted(unknown)}")
    return value
def load_kind_schemas(directory:Path|None=None)->dict[str,AssetKindSchema]:
    result={}
    for path in sorted((directory or SCHEMAS_DIR).glob("*.json")):
        raw=json.loads(path.read_text(encoding="utf-8"))
        if raw.get("schema")!="custodian.asset_kind.v2": raise ValueError(f"{path.name}: unsupported kind schema")
        kind=str(raw.get("kind","")); policy=str(raw.get("filename_policy","")); backend=str(raw.get("backend_policy",""))
        if not kind or policy not in {"canonical","template"} or backend not in {"auto","runtime_ready","sprite_ingest"}: raise ValueError(f"{path.name}: invalid kind policy")
        filename_template=raw.get("filename_template")
        if policy=="template" and not filename_template: raise ValueError(f"{path.name}: template filename policy requires filename_template")
        if filename_template: _validate_template(filename_template,"filename_template")
        if kind in result: raise ValueError(f"duplicate kind schema: {kind}")
        result[kind]=AssetKindSchema(kind,_validate_template(raw.get("runtime_template"),"runtime_template"),policy,filename_template,backend,dict(raw.get("defaults",{})),tuple(raw.get("post_process",())))
    return result
def resolve_runtime_target(*,family:AssetFamilyContract,state:AssetStateContract,key:AssetKey,kind_schema:AssetKindSchema)->Path:
    policy=family.filename_policy or kind_schema.filename_policy; filename_template=family.filename_template or kind_schema.filename_template
    values={"domain":family.runtime_domain,"owner":key.owner,"kind":key.kind,"layer":key.layer,"action_group":key.action_group,"variant":key.variant,"direction":key.direction,"frames":key.frames,"frame_width":key.frame_width,"frame_height":key.frame_height,"frame_size":f"{key.frame_width}x{key.frame_height}"}
    filename=canonical_filename(key) if policy=="canonical" else str(filename_template).format(**values)
    if not filename or PurePosixPath(filename).name != filename or ".." in PurePosixPath(filename).parts: raise ValueError("generated filename must be a non-empty basename")
    values["filename"]=filename; template=family.runtime_template or kind_schema.runtime_template
    rel=PurePosixPath(template.format(**values))
    if rel.is_absolute() or ".." in rel.parts or not rel.name: raise ValueError("generated runtime path escapes content")
    return Path("content")/Path(rel.as_posix())
