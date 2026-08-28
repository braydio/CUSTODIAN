#!/usr/bin/env python3
"""Explicit Operator animation frame-contract migration planning and transforms."""
from __future__ import annotations
import json,re
from dataclasses import dataclass,asdict
from pathlib import Path
from PIL import Image

@dataclass
class Dependency:
    level:str; path:str; field:str; detail:str

def transform_strip(source:Path,target:Path,frames:int,size:list[int],operation:str,position:int,fill:str="duplicate-prev"):
    fw,fh=size
    with Image.open(source) as im:
        im=im.convert("RGBA")
        if im.size!=(frames*fw,fh): raise ValueError(f"strip contract mismatch: {im.size}")
        cells=[im.crop((i*fw,0,(i+1)*fw,fh)) for i in range(frames)]
    if operation=="add":
        if position<0 or position>frames: raise ValueError("--after is outside the frame contract")
        if fill=="blank": cell=Image.new("RGBA",(fw,fh))
        elif fill=="duplicate-next": cell=cells[min(position,frames-1)].copy()
        else: cell=cells[max(0,position-1)].copy()
        cells.insert(position,cell)
    elif operation=="remove":
        if frames<=1: raise ValueError("cannot remove the final animation frame")
        if position<1 or position>frames: raise ValueError("--frame is outside the frame contract")
        cells.pop(position-1)
    else: raise ValueError(operation)
    out=Image.new("RGBA",(len(cells)*fw,fh))
    for i,cell in enumerate(cells): out.paste(cell,(i*fw,0))
    target.parent.mkdir(parents=True,exist_ok=True); out.save(target)

def automatic_set(manifest:dict,layers:str="auto"):
    editable=[b for b in manifest["layers"] if b.get("editable",True) and b.get("role")!="reference"]
    clock=manifest["timeline"]["workspace_clock_frames"]
    if layers not in ("auto","all"):
        wanted=set(layers.split(',')); missing=wanted-{b['binding_id'] for b in editable}
        if missing: raise ValueError(f"unknown binding ids: {sorted(missing)}")
        return [b for b in editable if b['binding_id'] in wanted],[]
    if layers=="all": return editable,[]
    body_layers={b["layer"] for b in editable}
    affected=[]; excluded=[]
    for b in editable:
        reason="independent clock"
        include=False
        if b["layer"] in ("lower_body","upper_body") and {"lower_body","upper_body"}<=body_layers: include=True
        elif b["layer"]=="full_body" and not ({"lower_body","upper_body"}<=body_layers): include=True
        elif b["layer"] in ("head","cape","weapon") and b["workspace_contract"]["frames"]==clock: include=True
        elif b["layer"]=="fx": reason="FX is independent by default"
        if include: affected.append(b)
        else: excluded.append({"binding_id":b["binding_id"],"reason":reason})
    return affected,excluded

def audit_dependencies(repo:Path,manifest:dict,affected:list[dict]):
    ident=manifest["identity"]; action=ident["action"]; deps=[]
    # Posture/locomotion/presentation actions have no attack-frame gameplay authority.
    is_attack=ident["group"] in ("attack","defense") or any(x in action for x in ("fast","heavy","strike","fire","block","parry"))
    if is_attack:
        for path in (repo/"custodian/game/actors/operator").glob("*_definition.tres"):
            text=path.read_text()
            if manifest["context"].get("weapon_id") and manifest["context"]["weapon_id"] not in text: continue
            for field in ("hit_windows","animation_fire_frame","fast_chain_queue_open_frames","fast_chain_queue_close_frames","fast_chain_commit_frames"):
                if re.search(rf'^\s*{field}\s*=',text,re.M): deps.append(Dependency("RED",str(path.relative_to(repo)),field,"gameplay frame authority"))
        for path in (repo/"custodian/game/actors/operator/attacks").glob("*.tres"):
            text=path.read_text()
            if "hit_window_frames" in text and any(token in path.stem for token in action.split('_')): deps.append(Dependency("RED",str(path.relative_to(repo)),"hit_window_frames","melee attack profile"))
    sockets=repo/"custodian/content/data/operator/generated/operator_weapon_sockets.generated.json"
    if sockets.exists():
        tracks=json.loads(sockets.read_text()).get("tracks",{})
        needles=(ident["profile"],ident["group"],action,ident["direction"])
        for key,track in tracks.items():
            if all(n in key for n in needles) and isinstance(track,list): deps.append(Dependency("YELLOW",str(sockets.relative_to(repo)),key,f"per-frame socket track ({len(track)} records)"))
    level="RED" if any(d.level=="RED" for d in deps) else "YELLOW" if deps else "GREEN"
    return {"level":level,"dependencies":[asdict(d) for d in deps]}

def migration_report(manifest,operation,position,fill,layers,repo):
    affected,excluded=automatic_set(manifest,layers); audit=audit_dependencies(repo,manifest,affected)
    old=manifest["timeline"]["workspace_clock_frames"]; new=old+(1 if operation=="add" else -1)
    if new<1: raise ValueError("migration would create a zero-frame animation")
    return {"kind":"frame_count","operation":operation,"position":{"after":position} if operation=="add" else {"frame":position},"fill":fill,"old_clock_frames":old,"new_clock_frames":new,"affected_bindings":[b["binding_id"] for b in affected],"excluded_bindings":excluded,"dependency_audit":audit,"status":"pending"}
