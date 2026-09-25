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

def transform_canvas_strip(source:Path,target:Path,frames:int,old_size:list[int],new_size:list[int],binding_id:str="layer"):
    """Center-copy an RGBA strip into a new per-frame canvas without resampling."""
    old_w,old_h=map(int,old_size); new_w,new_h=map(int,new_size)
    if min(old_w,old_h,new_w,new_h)<=0: raise ValueError("canvas dimensions must be positive")
    dx,dy=new_w-old_w,new_h-old_h
    if dx%2 or dy%2: raise ValueError("center canvas migration requires integer offsets")
    ox,oy=dx//2,dy//2
    with Image.open(source) as opened:
        image=opened.convert("RGBA")
        if image.size!=(frames*old_w,old_h): raise ValueError(f"strip contract mismatch: expected {(frames*old_w,old_h)}, got {image.size}")
        output=Image.new("RGBA",(frames*new_w,new_h),(0,0,0,0))
        for index in range(frames):
            cell=image.crop((index*old_w,0,(index+1)*old_w,old_h))
            if new_w<old_w or new_h<old_h:
                left=max(0,-ox); top=max(0,-oy); right=min(old_w,new_w-ox); bottom=min(old_h,new_h-oy)
                alpha=cell.getchannel("A"); outside=Image.new("L",cell.size,255)
                outside.paste(0,(left,top,right,bottom))
                lost=Image.composite(alpha,Image.new("L",cell.size,0),outside)
                bbox=lost.getbbox()
                if bbox:
                    raise ValueError(f"CANVAS MIGRATION WOULD CROP VISIBLE PIXELS\nlayer={binding_id}\nframe={index+1}\nbbox={bbox}\nold={old_w}x{old_h}\ntarget={new_w}x{new_h}")
            output.paste(cell,(index*new_w+ox,oy))
        target.parent.mkdir(parents=True,exist_ok=True); output.save(target)

def canvas_affected_set(manifest:dict,scope:str="animation"):
    bindings=[b for b in manifest.get("layers",[]) if b.get("editable",True) and b.get("role")!="reference"]
    ident=manifest.get("identity",{})
    operator_authored=lambda b:b.get("owner")=="operator" and b.get("profile")==ident.get("profile")
    if scope not in ("animation","body","all"): raise ValueError(f"unknown canvas migration scope: {scope}")
    if scope=="all": affected=bindings
    elif scope=="body":
        names={b.get("layer") for b in bindings if operator_authored(b)}
        wanted={"lower_body","upper_body"} if {"lower_body","upper_body"}<=names else {"full_body"}
        affected=[b for b in bindings if operator_authored(b) and b.get("layer") in wanted]
    else:
        # Animation scope follows authored Operator presentation ownership only;
        # linked/weapon-owned layers remain untouched.
        affected=[b for b in bindings if operator_authored(b) and b.get("layer") in {"lower_body","upper_body","full_body","head","cape","weapon","fx"}]
    if not affected: raise ValueError("canvas migration affected set is empty")
    excluded=[{"binding_id":b.get("binding_id",""),"reason":"not selected by canvas scope"} for b in bindings if b not in affected]
    return affected,excluded

def audit_canvas_dependencies(repo:Path,manifest:dict,affected:list[dict]):
    # Pixel-coordinate authorities are not translated implicitly by this migration.
    sockets=repo/"custodian/content/data/operator/generated/operator_weapon_sockets.generated.json"
    dependencies=[]; ident=manifest["identity"]
    if sockets.exists():
        tracks=json.loads(sockets.read_text()).get("tracks",{})
        affected_layers={b.get("layer") for b in affected}
        for key,track in tracks.items():
            parsed=_socket_track_identity(key)
            if parsed and parsed[:4]==(ident["profile"],ident["group"],ident["action"],ident["direction"]) and parsed[4] in affected_layers:
                dependencies.append(asdict(Dependency("YELLOW",str(sockets.relative_to(repo)),key,"pixel-coordinate socket track requires a separate explicit migration")))
    return {"level":"YELLOW" if dependencies else "GREEN","dependencies":dependencies}

def canvas_migration_report(manifest:dict,width:int,height:int,scope:str,repo:Path):
    if width<=0 or height<=0: raise ValueError("target canvas dimensions must be positive")
    affected,excluded=canvas_affected_set(manifest,scope)
    changes=[]
    sizes=[]
    for binding in manifest.get("layers",[]):
        size=list(binding.get("workspace_contract",{}).get("frame_size",binding.get("frame_size",[0,0])))
        if binding in affected: size=[width,height]
        sizes.append(size)
        if binding in affected:
            old=list(binding.get("workspace_contract",{}).get("frame_size",binding.get("frame_size",[0,0])))
            dx,dy=width-old[0],height-old[1]
            if dx%2 or dy%2: raise ValueError(f"center canvas migration requires integer offsets for {binding['binding_id']}")
            changes.append({"binding_id":binding["binding_id"],"old_size":old,"new_size":[width,height],"offset":[dx//2,dy//2]})
    sizes.extend([list(r.get("frame_size",[0,0])) for r in manifest.get("references",[])])
    doc_w=max(size[0] for size in sizes); doc_h=max(size[1] for size in sizes)
    placements={}
    for binding,size in zip(manifest.get("layers",[]),sizes[:len(manifest.get("layers",[]))]):
        if (doc_w-size[0])%2 or (doc_h-size[1])%2: raise ValueError(f"document cannot center {binding['binding_id']} on integer pixels")
        placements[binding["binding_id"]]=[(doc_w-size[0])//2,(doc_h-size[1])//2]
    for reference,size in zip(manifest.get("references",[]),sizes[len(manifest.get("layers",[])):]):
        if (doc_w-size[0])%2 or (doc_h-size[1])%2: raise ValueError(f"document cannot center {reference['binding_id']} on integer pixels")
        placements[reference["binding_id"]]=[(doc_w-size[0])//2,(doc_h-size[1])//2]
    shrinks=any(width<change["old_size"][0] or height<change["old_size"][1] for change in changes)
    crop_status="requires_staging_validation" if shrinks else "impossible"
    return {"kind":"frame_canvas","operation":"resize_canvas","old_document_size":[manifest["canvas"]["width"],manifest["canvas"]["height"]],"new_document_size":[doc_w,doc_h],"target_size":[width,height],"scope":scope,"affected_bindings":[b["binding_id"] for b in affected],"excluded_bindings":excluded,"layer_changes":changes,"placements":placements,"dependency_audit":audit_canvas_dependencies(repo,manifest,affected),"crop_audit":{"status":crop_status},"status":"pending"}

def automatic_set(manifest:dict,layers:str="auto"):
    editable=[b for b in manifest["layers"] if b.get("editable",True) and b.get("role")!="reference"]
    clock=manifest["timeline"]["workspace_clock_frames"]
    if layers not in ("auto","all"):
        wanted=set(layers.split(',')); missing=wanted-{b['binding_id'] for b in editable}
        if missing: raise ValueError(f"unknown binding ids: {sorted(missing)}")
        affected=[b for b in editable if b['binding_id'] in wanted]
        clock_owner=manifest["timeline"].get("clock_owner","")
        if not affected: raise ValueError("explicit migration selection is empty")
        if not any(b["layer"]==clock_owner or b["binding_id"]==clock_owner for b in affected):
            raise ValueError(f"explicit migration selection excludes clock owner: {clock_owner}")
        return affected,[]
    if layers=="all":
        if not editable: raise ValueError("automatic migration set is empty")
        return editable,[]
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
    if not affected: raise ValueError("automatic migration set is empty")
    return affected,excluded

def _socket_track_identity(key:str):
    parts=key.split('/')
    if len(parts)==5:
        return tuple(parts)
    match=re.fullmatch(r"ranged_2h_(stance|aim|fire)_modular_(right|left|down_right|down_left)",key)
    if not match: return None
    action_token,direction_token=match.groups()
    action={"stance":"stance_01","aim":"aim_01","fire":"fire_01"}[action_token]
    group="posture" if action_token=="stance" else "cosmetic"
    direction={"right":"e","left":"w","down_right":"se","down_left":"sw"}[direction_token]
    return ("ranged_2h",group,action,direction,"upper_body")

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
        for key,track in tracks.items():
            track_identity=_socket_track_identity(key)
            if track_identity is None or not isinstance(track,list): continue
            profile,group,track_action,direction,layer=track_identity
            if (profile,group,track_action,direction)!=(ident["profile"],ident["group"],action,ident["direction"]): continue
            tied=any(
                b.get("layer")==layer
                and int(b.get("workspace_contract",{}).get("frames",b.get("frames",0)))==len(track)
                for b in affected
            )
            if tied: deps.append(Dependency("YELLOW",str(sockets.relative_to(repo)),key,f"per-frame socket track ({len(track)} records)"))
    level="RED" if any(d.level=="RED" for d in deps) else "YELLOW" if deps else "GREEN"
    return {"level":level,"dependencies":[asdict(d) for d in deps]}

def migration_report(manifest,operation,position,fill,layers,repo):
    affected,excluded=automatic_set(manifest,layers); audit=audit_dependencies(repo,manifest,affected)
    old=manifest["timeline"]["workspace_clock_frames"]; new=old+(1 if operation=="add" else -1)
    if new<1: raise ValueError("migration would create a zero-frame animation")
    return {"kind":"frame_count","operation":operation,"position":{"after":position} if operation=="add" else {"frame":position},"fill":fill,"old_clock_frames":old,"new_clock_frames":new,"affected_bindings":[b["binding_id"] for b in affected],"excluded_bindings":excluded,"dependency_audit":audit,"status":"pending"}
