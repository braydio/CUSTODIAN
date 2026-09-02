from __future__ import annotations

from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
import hashlib, json, uuid
from pathlib import Path
from PIL import Image
from .palette import inspect, alpha_sha, silhouette_sha, relative_luminance
from .render import make_animation_gif, make_contact_sheet, make_before_after, make_diff

SCHEMA = "custodian.operator_art_recolor_plan.v1"

@dataclass
class RecolorMapping:
    mapping_id: str; scope: str; source_rgb: list[int]; destination_rgb: list[int] | None
    action: str; method: str; confidence: float; locked: bool; region_id: str = ""

@dataclass
class RecolorPlan:
    schema: str; plan_id: str; target_session_id: str; target_workbench_sha256: str
    reference_id: str; reference_hashes: dict[str,str]; target_layers: list[str]
    target_frames: list[int]; region_ids: list[str]; scopes: list[dict]
    mappings: list[RecolorMapping]; unmapped_colors: list[list[int]]; ambiguous_colors: list[list[int]]
    preserve_alpha: bool; status: str; preview_sha256: str | None; created_utc: str
    reference_palette_hashes: dict[str,str] = field(default_factory=dict)
    target_layer_frame_hashes: dict[str,str] = field(default_factory=dict)
    def to_json(self): return asdict(self)

def save(path:Path, plan:RecolorPlan):
    path.parent.mkdir(parents=True,exist_ok=True); path.write_text(json.dumps(plan.to_json(),indent=2)+"\n")

def load(path:Path)->RecolorPlan:
    value=json.loads(path.read_text())
    if value.get("schema")!=SCHEMA or value.get("preserve_alpha") is not True: raise ValueError("invalid recolor plan")
    value["mappings"]=[RecolorMapping(**item) for item in value["mappings"]]; return RecolorPlan(**value)

def plan_id_path(root:Path,plan_id:str)->Path:
    if not plan_id or any(c not in "0123456789abcdef" for c in plan_id): raise ValueError("invalid recolor plan id")
    return root/"recolor_plans"/f"{plan_id}.json"

def build(*,session_id:str,workbench_sha:str,reference:dict,scopes:list[dict],frames:list[int],target_reports:dict,reference_reports:dict,regions:list[str],fingerprints:dict)->RecolorPlan:
    mappings=[]; ambiguous=[]; unmapped=[]
    for scope in scopes:
        scope_id=scope.get("scope_id",scope["target_layer"]); src=[x["rgb"] for x in target_reports[scope_id]["colors"]]; dst=[x["rgb"] for x in reference_reports[scope_id]["colors"]]
        semi_mismatch=target_reports[scope_id]["semitransparent_pixel_count"]>0 and target_reports[scope_id]["semitransparent_pixel_count"]!=reference_reports[scope_id]["semitransparent_pixel_count"]
        exact=len(src)==len(dst) and bool(src) and not semi_mismatch
        for index,rgb in enumerate(src):
            choice=dst[round(index*(len(dst)-1)/max(1,len(src)-1))] if dst else None
            mappings.append(RecolorMapping(uuid.uuid4().hex[:12],scope_id,rgb,choice,"map" if choice else "preserve","luminance_rank",1.0 if exact else .5,exact,scope.get("region_id","")))
            if not exact: ambiguous.append(rgb)
            if choice is None: unmapped.append(rgb)
    ready=bool(mappings) and all(x.locked for x in mappings) and not unmapped
    return RecolorPlan(SCHEMA,uuid.uuid4().hex[:12],session_id,workbench_sha,reference["reference_id"],reference["source_hashes"],sorted({x["target_layer"] for x in scopes}),sorted(set(frames)),list(regions),scopes,mappings,[list(x) for x in sorted(set(map(tuple,unmapped)))],[list(x) for x in sorted(set(map(tuple,ambiguous)))],True,"READY" if ready else "NEEDS_REVIEW",None,datetime.now(timezone.utc).isoformat(),{k:v["palette_sha256"] for k,v in reference_reports.items()},fingerprints)

def readiness_issues(plan:RecolorPlan)->list[str]:
    issues=[]
    if not plan.mappings or any(not item.locked for item in plan.mappings): issues.append("unlocked mappings remain")
    for scope in sorted({item.scope for item in plan.mappings}):
        ordered=sorted((item for item in plan.mappings if item.scope==scope),key=lambda item:(relative_luminance(tuple(item.source_rgb)),item.source_rgb))
        destinations=[relative_luminance(tuple(item.source_rgb if item.action=="preserve" else item.destination_rgb or item.source_rgb)) for item in ordered]
        if any(right<left for left,right in zip(destinations,destinations[1:])): issues.append(f"luminance ordering inverted in {scope}")
        if len(ordered)>=3 and len({tuple(item.source_rgb if item.action=="preserve" else item.destination_rgb or item.source_rgb) for item in ordered})==1: issues.append(f"3+ value ramp collapsed in {scope}")
    return issues

def fingerprint(plan:RecolorPlan)->str:
    payload=plan.to_json();payload["status"]="";payload["preview_sha256"]=None
    return hashlib.sha256(json.dumps(payload,sort_keys=True,separators=(",",":")).encode()).hexdigest()

def apply_mapping(images:dict[str,list[Image.Image]],plan:RecolorPlan,allowed_points:dict[str,dict[int,set[tuple[int,int]]]]|None=None)->tuple[dict[str,list[Image.Image]],dict]:
    output={k:[x.copy() for x in v] for k,v in images.items()}; changed_frames={}; changed_maps={x.mapping_id:0 for x in plan.mappings}; total=0
    scope_layers={x.get("scope_id",x["target_layer"]):x["target_layer"] for x in plan.scopes}; grouped={}
    for item in plan.mappings:
        if not item.locked: raise ValueError("recolor plan contains unlocked mappings")
        destination=item.source_rgb if item.action=="preserve" else item.destination_rgb
        if destination is None: raise ValueError("mapping destination is unresolved")
        grouped.setdefault(item.scope,{})[tuple(item.source_rgb)]=(tuple(destination),item.mapping_id)
    for scope,mapping in grouped.items():
        layer=scope_layers[scope]
        for frame in plan.target_frames:
            image=output[layer][frame-1].convert("RGBA"); pixels=image.load(); points=allowed_points.get(scope,{}).get(frame) if allowed_points is not None else None; count=0
            for y in range(image.height):
                for x in range(image.width):
                    if points is not None and (x,y) not in points: continue
                    r,g,b,a=pixels[x,y]; hit=mapping.get((r,g,b)) if a else None
                    if hit and hit[0]!=(r,g,b): pixels[x,y]=(*hit[0],a); count+=1; changed_maps[hit[1]]+=1
            output[layer][frame-1]=image; key=f"{layer}:{frame}"; changed_frames[key]=changed_frames.get(key,0)+count; total+=count
    return output,{"changed_pixel_count":total,"changed_pixel_count_by_frame":changed_frames,"changed_pixel_count_by_mapping":changed_maps}

def preview(root:Path,plan:RecolorPlan,images:dict[str,list[Image.Image]],allowed_points:dict[str,dict[int,set[tuple[int,int]]]]|None=None)->dict:
    after,stats=apply_mapping(images,plan,allowed_points); out=root/"previews/recolor"/plan.plan_id; out.mkdir(parents=True,exist_ok=True); before_paths=[]; after_paths=[]
    layer_hashes_before={};layer_hashes_after={};layer_alpha_before={};layer_alpha_after={};layer_silhouette_before={};layer_silhouette_after={}
    for layer in plan.target_layers:
        layer_dir=out/"layers"/layer;layer_dir.mkdir(parents=True,exist_ok=True)
        for frame in plan.target_frames:
            before_layer=images[layer][frame-1].convert("RGBA");after_layer=after[layer][frame-1].convert("RGBA");key=f"{layer}:{frame}"
            before_layer.save(layer_dir/f"before_{frame:03d}.png");after_layer.save(layer_dir/f"after_{frame:03d}.png")
            layer_hashes_before[key]=hashlib.sha256(before_layer.tobytes()).hexdigest();layer_hashes_after[key]=hashlib.sha256(after_layer.tobytes()).hexdigest()
            layer_alpha_before[key]=alpha_sha([before_layer]);layer_alpha_after[key]=alpha_sha([after_layer]);layer_silhouette_before[key]=silhouette_sha([before_layer]);layer_silhouette_after[key]=silhouette_sha([after_layer])
            if layer_alpha_before[key]!=layer_alpha_after[key] or layer_silhouette_before[key]!=layer_silhouette_after[key]:raise ValueError(f"recolor preview changed layer alpha or silhouette: {key}")
    for frame in plan.target_frames:
        before=Image.new("RGBA",images[plan.target_layers[0]][0].size); result=before.copy()
        for layer in plan.target_layers: before.alpha_composite(images[layer][frame-1]); result.alpha_composite(after[layer][frame-1])
        bp=out/f"before_{frame:03d}.png"; ap=out/f"after_{frame:03d}.png"; before.save(bp); result.save(ap); before_paths.append(bp); after_paths.append(ap)
    before_images=[Image.open(x).convert("RGBA") for x in before_paths]; after_images=[Image.open(x).convert("RGBA") for x in after_paths]
    if alpha_sha(before_images)!=alpha_sha(after_images): raise ValueError("recolor preview changed alpha")
    if silhouette_sha(before_images)!=silhouette_sha(after_images): raise ValueError("recolor preview changed silhouette")
    make_contact_sheet(before_paths,out/"baseline_contact_sheet.png"); make_contact_sheet(after_paths,out/"recolor_contact_sheet.png"); make_before_after(out/"baseline_contact_sheet.png",out/"recolor_contact_sheet.png",out/"before_after.png"); make_diff(out/"baseline_contact_sheet.png",out/"recolor_contact_sheet.png",out/"diff.png"); make_animation_gif(after_paths,out/"animation.gif",fps=12)
    payload={**stats,"plan_fingerprint":fingerprint(plan),"alpha_sha_before":alpha_sha(before_images),"alpha_sha_after":alpha_sha(after_images),"silhouette_sha_before":silhouette_sha(before_images),"silhouette_sha_after":silhouette_sha(after_images),"layer_pixel_sha_before":layer_hashes_before,"layer_pixel_sha_after":layer_hashes_after,"layer_alpha_sha_before":layer_alpha_before,"layer_alpha_sha_after":layer_alpha_after,"layer_silhouette_sha_before":layer_silhouette_before,"layer_silhouette_sha_after":layer_silhouette_after,"palette_before":inspect(before_images,"composite"),"palette_after":inspect(after_images,"composite"),"artifacts":{name:str((out/name).resolve()) for name in ["baseline_contact_sheet.png","recolor_contact_sheet.png","before_after.png","diff.png","animation.gif"]}}
    payload["preview_sha256"]=hashlib.sha256(json.dumps(payload,sort_keys=True).encode()).hexdigest(); (out/"recolor_preview.json").write_text(json.dumps(payload,indent=2)+"\n"); return payload
