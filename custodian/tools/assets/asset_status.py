"""Truthful directional lifecycle status."""
from __future__ import annotations
from dataclasses import dataclass
from pathlib import Path
from asset_catalog import file_hash,load_catalog
from asset_contract import AssetFamilyContract
@dataclass(frozen=True)
class StateStatus:
    state_id:str; source_pending:bool; art_present:bool; imported:bool; bound:bool; runtime_verified:bool; runtime_path:str|None
    authored_directions:tuple[str,...]=(); mirrored_directions:tuple[str,...]=(); min_direction_count:int=1; required_directions:tuple[str,...]=()
@dataclass
class FamilyStatus:
    family_id:str; required_states:list[tuple[str,bool]]; recommended_states:list[tuple[str,bool]]; optional_states:list[tuple[str,bool]]
    inbox_exists:bool; inbox_files:list[str]; runtime_outputs:list[str]; consumers:list[dict]; completeness:str; states:dict[str,StateStatus]
def get_family_status(family:AssetFamilyContract,project_dir:Path)->FamilyStatus:
    inbox=project_dir/"asset_drop/inbox"/family.id; inbox_files=sorted(p.name for p in inbox.glob("*.png")) if inbox.exists() else []
    catalog=load_catalog(project_dir/"content/metadata/assets/generated/asset_catalog.generated.json")
    assets=catalog.get("families",{}).get(family.id,{}).get("assets",{}); statuses={}; runtime=[]
    for sid,state in family.states.items():
        entries=[entry for entry in assets.values() if entry.get("state_id")==sid]; authored=[]; mirrored=[]; imported=True; bound=False; verified=False; first=None; valid_count=0
        for entry in entries:
            rel=entry.get("path"); output=project_dir/rel if rel else None
            valid=bool(output and output.is_file() and entry.get("sha256")==file_hash(output))
            if not valid: continue
            valid_count += 1
            first=first or rel; runtime.append(rel); (mirrored if entry.get("provenance")=="mirrored" else authored).append(entry.get("direction","omni"))
            imported=imported and output.with_name(output.name+".import").exists(); verified=verified or bool(entry.get("validation_evidence"))
            bound=bound or _is_bound(family.consumers,project_dir,"res://"+rel)
        present=set(authored+mirrored); art=len(present)>=state.min_direction_count and set(state.required_directions).issubset(present)
        pending=any((Path(name).stem==sid or Path(name).stem.startswith(sid+"__")) for name in inbox_files)
        statuses[sid]=StateStatus(sid,pending,art,valid_count>0 and imported,bound,verified,first,tuple(sorted(authored)),tuple(sorted(mirrored)),state.min_direction_count,state.required_directions)
    def group(pred): return [(sid,statuses[sid].art_present) for sid,state in family.states.items() if pred(state)]
    required=group(lambda s:s.required); recommended=group(lambda s:not s.required and s.recommended); optional=group(lambda s:not s.required and not s.recommended)
    return FamilyStatus(family.id,required,recommended,optional,inbox.exists(),inbox_files,sorted(runtime),list(family.consumers),f"{sum(v for _,v in required)}/{len(required)} required",statuses)
def _is_bound(consumers,project_dir,expected):
    return any(str(c.get("path","")).startswith("res://") and (p:=project_dir/str(c["path"])[6:]).is_file() and expected in p.read_text(encoding="utf-8") for c in consumers)
