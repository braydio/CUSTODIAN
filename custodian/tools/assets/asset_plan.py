"""Pure, batch-aware, multi-output asset planning."""
from __future__ import annotations
import hashlib
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from asset_classifier import AssetResolution,ResolutionConfidence,classify_input
from asset_contract import AssetFamilyContract
from asset_inspector import AssetInspection,FrameLayout,inspect_png
from asset_key import AssetKey
from asset_router import AssetKindSchema,load_kind_schemas,resolve_runtime_target
from asset_naming import parse_canonical_filename
MIRRORS={"e":"w","w":"e","ne":"nw","nw":"ne","se":"sw","sw":"se"}
class AssetOperation(str,Enum): CREATE="create"; DUPLICATE="duplicate"; REPLACE="replace"; CONFLICT="conflict"; SKIP="skip"
@dataclass(frozen=True)
class PlannedOutput:
    state_id:str; key:AssetKey; canonical_filename:str; target_relative_path:Path; operation:AssetOperation
    existing_target:Path|None; provenance:str; source_asset:str|None=None
    superseded_targets:tuple[Path,...]=(); stale_consumers:tuple[str,...]=()
@dataclass(frozen=True)
class PlannedAsset:
    source_path:Path; family_id:str; state_id:str|None; confidence:ResolutionConfidence; resolution:AssetResolution
    inspection:AssetInspection; backend:str; outputs:tuple[PlannedOutput,...]; warnings:tuple[str,...]=(); post_process:tuple[str,...]=()
    @property
    def key(self): return self.outputs[0].key if self.outputs else AssetKey("unknown","unknown","unknown","unknown",self.source_path.stem,"omni",0,self.inspection.frame_width,self.inspection.frame_height)
    @property
    def canonical_filename(self): return self.outputs[0].canonical_filename if self.outputs else ""
    @property
    def target_relative_path(self): return self.outputs[0].target_relative_path if self.outputs else Path()
    @property
    def operation(self): return self.outputs[0].operation if self.outputs else AssetOperation.CONFLICT
    @property
    def existing_target(self): return self.outputs[0].existing_target if self.outputs else None
@dataclass(frozen=True)
class AssetPlan:
    family_id:str; assets:tuple[PlannedAsset,...]; errors:tuple[str,...]=(); warnings:tuple[str,...]=(); post_process:tuple[str,...]=()
    @property
    def outputs(self): return tuple(output for asset in self.assets for output in asset.outputs)
    @property
    def can_apply(self): return not self.errors and all(asset.confidence!=ResolutionConfidence.AMBIGUOUS for asset in self.assets)

def generate_plan(family:AssetFamilyContract,inbox_dir:Path,project_dir:Path,*,no_mirror:bool=False,kind_schemas:dict[str,AssetKindSchema]|None=None)->AssetPlan:
    schemas=kind_schemas or load_kind_schemas(); schema=schemas.get(family.kind)
    if schema is None: return AssetPlan(family.id,(),(f"unsupported asset kind schema: {family.kind}",))
    if not inbox_dir.exists(): return AssetPlan(family.id,(),warnings=(f"inbox does not exist: {inbox_dir}",),post_process=schema.post_process)
    files=sorted(inbox_dir.glob("*.png"))
    if not files: return AssetPlan(family.id,(),warnings=(f"no PNG files found in {inbox_dir}",),post_process=schema.post_process)
    inspected=[]; errors=[]
    for png in files:
        provisional_sid = None
        try:
            canonical = parse_canonical_filename(png.name, family.kind)
            for sid, candidate in family.states.items():
                if (candidate.layer, candidate.action_group, candidate.variant) == (canonical.layer, canonical.action_group, canonical.variant):
                    provisional_sid = sid
                    break
        except (TypeError, ValueError):
            provisional_sid,_=family.resolve_state(png.stem.rsplit("__",1)[0] if "__" in png.stem else png.stem)
        state=family.states.get(provisional_sid) if provisional_sid else None
        fw,fh=family.state_frame_size(state) if state else (family.frame_width,family.frame_height)
        inspection=inspect_png(png,fw,fh,state.layout if state else "auto",state.columns if state else None,state.rows if state else None)
        resolution=classify_input(family,png.stem,inspection); inspected.append((png,inspection,resolution))
    authored={(resolution.state_id,resolution.direction) for _,_,resolution in inspected if resolution.state_id and resolution.direction}
    assets=[]; seen_targets={}
    for png,inspection,resolution in inspected:
        if resolution.confidence==ResolutionConfidence.AMBIGUOUS or resolution.state_id is None or resolution.direction is None:
            assets.append(PlannedAsset(png,family.id,None,resolution.confidence,resolution,inspection,"none",()))
            errors.append(f"{png.name}: {resolution.reason}"); continue
        state=family.states[resolution.state_id]
        if state.animation and inspection.frame_count<=1: errors.append(f"{png.name}: state '{state.id}' requires animation")
        if not state.animation and inspection.frame_count>1: errors.append(f"{png.name}: state '{state.id}' is static but has {inspection.frame_count} frames")
        if state.expected_frames is not None and inspection.frame_count!=state.expected_frames: errors.append(f"{png.name}: state '{state.id}' requires exactly {state.expected_frames} frames, found {inspection.frame_count}")
        backend=schema.backend_policy if schema.backend_policy!="auto" else ("sprite_ingest" if inspection.frame_count>1 or inspection.layout in {FrameLayout.GRID,FrameLayout.VERTICAL_STRIP} else "runtime_ready")
        directions=[(resolution.direction,"authored",None)]
        mirror=MIRRORS.get(resolution.direction)
        if family.auto_mirror and not no_mirror and mirror and (state.id,mirror) not in authored:
            directions.append((mirror,"mirrored",f"{state.id}::{resolution.direction}"))
        outputs=[]
        for direction,provenance,source_asset in directions:
            key=AssetKey(family.runtime_owner,family.kind,state.layer,state.action_group,state.variant,direction,inspection.frame_count,inspection.frame_width,inspection.frame_height)
            target=resolve_runtime_target(family=family,state=state,key=key,kind_schema=schema); full=project_dir/target
            semantic_siblings=_semantic_runtime_siblings(project_dir,family,key,target)
            superseded=tuple(path for path in semantic_siblings if path != target)
            stale_consumers=_find_stale_consumers(project_dir,family,superseded)
            if full.exists():
                operation=AssetOperation.DUPLICATE if provenance=="authored" and _hash(full)==_hash(png) and not superseded else AssetOperation.REPLACE
            elif semantic_siblings:
                operation=AssetOperation.REPLACE
            else:
                operation=AssetOperation.CREATE
            output=PlannedOutput(state.id,key,target.name,target,operation,full if full.exists() else (project_dir/semantic_siblings[0] if semantic_siblings else None),provenance,source_asset,superseded,stale_consumers)
            if stale_consumers:
                errors.append("blocked replacement for %s: stale consumer(s): %s" % ("/".join(key.semantic_identity), ", ".join(stale_consumers)))
            if target in seen_targets: errors.append(f"duplicate semantic output target: {target}")
            seen_targets[target]=output; outputs.append(output)
        assets.append(PlannedAsset(png,family.id,state.id,resolution.confidence,resolution,inspection,backend,tuple(outputs),(),schema.post_process))
    return AssetPlan(family.id,tuple(assets),tuple(errors),post_process=schema.post_process)
def _hash(path:Path)->str: return hashlib.sha256(path.read_bytes()).hexdigest()

def _semantic_runtime_siblings(project_dir:Path,family:AssetFamilyContract,key:AssetKey,target:Path)->tuple[Path,...]:
    target_parts=target.parts
    if "runtime" in target_parts:
        runtime_index=target_parts.index("runtime")
        owner_root=project_dir/Path(*target_parts[:runtime_index+1])
    else:
        owner_root=(project_dir/target).parent
    if not owner_root.exists(): return ()
    matches=[]
    for path in sorted(owner_root.rglob("*.png")):
        try: candidate=parse_canonical_filename(path.name,family.kind)
        except (TypeError,ValueError): continue
        if candidate.semantic_identity==key.semantic_identity:
            matches.append(path.relative_to(project_dir))
    return tuple(matches)

def _find_stale_consumers(project_dir:Path,family:AssetFamilyContract,targets:tuple[Path,...])->tuple[str,...]:
    if not targets: return ()
    needles={"res://"+target.as_posix() for target in targets}
    found=[]
    for consumer in family.consumers:
        rel=str(consumer.get("path",""))
        if not rel.startswith("res://"): continue
        path=project_dir/rel.removeprefix("res://")
        if not path.is_file(): continue
        try: text=path.read_text(encoding="utf-8")
        except UnicodeDecodeError: continue
        if any(needle in text for needle in needles): found.append(rel)
    return tuple(sorted(set(found)))
