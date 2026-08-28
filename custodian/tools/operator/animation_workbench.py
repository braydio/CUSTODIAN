#!/usr/bin/env python3
"""Controller for disposable semantic Operator Aseprite workbenches."""
from __future__ import annotations
import json, os, shutil, subprocess
from datetime import datetime, timezone
from pathlib import Path
from PIL import Image
import animation_workbench_model as m

DEFAULT_ROOT=m.REPO_ROOT/".ai/operator_animation_workbench"
LUA=m.CUSTODIAN_ROOT/"tools/aseprite/operator_animation_workbench.lua"

def resolve_aseprite(explicit=None, required=False):
    value=explicit or os.environ.get("ASEPRITE_BIN") or shutil.which("aseprite")
    if value and Path(value).is_file(): return Path(value).resolve()
    if required: raise m.WorkbenchError("Aseprite not found. Pass --aseprite PATH or set ASEPRITE_BIN.")
    return None

def workspace(root, identity): return Path(root)/identity["profile"]/identity["group"]/identity["action"]/identity["direction"]
def load(path): return json.loads(path.read_text())
def save(path,data): path.write_text(json.dumps(data,indent=2)+"\n")
def state(manifest, wb):
    edited=wb.exists() and manifest["aseprite"].get("last_synced_sha256") not in (None,m.file_sha256(wb))
    stale=any(not (m.REPO_ROOT/x["source_path"]).exists() or m.file_sha256(m.REPO_ROOT/x["source_path"])!=x["source_file_sha256"] for x in manifest["layers"])
    return "EDITED+STALE" if edited and stale else "EDITED" if edited else "STALE" if stale else "CLEAN"

def _baseline(plan, ws):
    base=ws/"baseline"; base.mkdir(parents=True,exist_ok=True); cw,ch=plan["canvas"].values(); frames=plan["timeline"]["frames"]
    composite=Image.new("RGBA",(cw*frames,ch))
    for b in plan["layers"]:
        src=m.REPO_ROOT/b["source_path"]; shutil.copy2(src,base/f"{b['binding_id']}.png")
        with Image.open(src) as im:
            fw,fh=b["frame_size"]; x,y=b["placement"]
            for i in range(min(b["frames"],frames)): composite.alpha_composite(im.convert("RGBA").crop((i*fw,0,(i+1)*fw,fh)),(i*cw+x,y))
    composite.save(base/"reference_composite.png")

def aseprite_run(binary, manifest, mode):
    subprocess.run([str(binary),"-b","--script-param",f"mode={mode}","--script-param",f"manifest={manifest.resolve()}","--script",str(LUA)],check=True)

def ensure(profile,action,direction,group="",weapon="",linked_profile="",root=DEFAULT_ROOT,aseprite=None):
    plan=m.build_plan(profile,action,direction,group,weapon,linked_profile); ws=workspace(root,plan["identity"]); mf=ws/"workbench.json"; wb=ws/"workbench.aseprite"
    if mf.exists() and wb.exists():
        old=load(mf); st=state(old,wb)
        if "STALE" in st: raise m.WorkbenchError("WORKBENCH STALE\ncanonical source changed; run operator anim refresh")
        return old,ws
    ws.mkdir(parents=True,exist_ok=True); plan["aseprite"]["path"]=str(wb.resolve()); _baseline(plan,ws); save(mf,plan)
    aseprite_run(resolve_aseprite(aseprite,True),mf,"assemble"); plan["aseprite"]["last_synced_sha256"]=m.file_sha256(wb); save(mf,plan); return plan,ws

def refresh(profile,action,direction,group="",weapon="",linked_profile="",root=DEFAULT_ROOT,aseprite=None,discard=False):
    fresh=m.build_plan(profile,action,direction,group,weapon,linked_profile); ws=workspace(root,fresh["identity"]); mf=ws/"workbench.json"; wb=ws/"workbench.aseprite"
    if mf.exists() and wb.exists():
        old=load(mf)
        if state(old,wb).startswith("EDITED") and not discard: raise m.WorkbenchError("workbench has unsynchronized edits; pass --discard-edits")
        stamp=datetime.now().strftime("%Y%m%dT%H%M%S"); (ws/"backups"/stamp).mkdir(parents=True,exist_ok=True); shutil.copy2(wb,ws/"backups"/stamp/"workbench.aseprite")
    if ws.exists(): shutil.rmtree(ws/"baseline",ignore_errors=True)
    fresh["aseprite"]["path"]=str(wb.resolve()); ws.mkdir(parents=True,exist_ok=True); _baseline(fresh,ws); save(mf,fresh); aseprite_run(resolve_aseprite(aseprite,True),mf,"assemble"); fresh["aseprite"]["last_synced_sha256"]=m.file_sha256(wb); save(mf,fresh); return fresh,ws

def publish(manifest, aseprite=None, force_stale=False, dry_run=False):
    ws=manifest.parent; data=load(manifest); st=state(data,ws/"workbench.aseprite")
    if "STALE" in st and not force_stale: raise m.WorkbenchError(f"publish refused: {st}; use scary --force-stale-source only after review")
    stamp=datetime.now().strftime("%Y%m%dT%H%M%S"); data["export_stamp"]=stamp; save(manifest,data); aseprite_run(resolve_aseprite(aseprite,True),manifest,"export")
    normalized=ws/"exports"/stamp/"normalized"; candidates=[]
    for b in data["layers"]:
        out=normalized/f"{b['binding_id']}.png"; m.extract_binding(ws/"exports"/stamp/"raw"/f"{b['binding_id']}.png",b,data["canvas"],out); candidates.append((b,out,m.REPO_ROOT/b["source_path"]))
    if dry_run: return [str(x[2]) for x in candidates]
    backup=ws/"backups"/stamp; backup.mkdir(parents=True,exist_ok=True)
    for b,c,dst in candidates: shutil.copy2(dst,backup/dst.name)
    try:
        for b,c,dst in candidates: tmp=dst.with_suffix(".png.workbench.tmp"); shutil.copy2(c,tmp); os.replace(tmp,dst)
        subprocess.run(["python3",str(m.PIPELINES/"build_operator_runtime.py"),"--strict","--remove-superseded"],check=True,cwd=m.REPO_ROOT)
    except Exception:
        for b,c,dst in candidates: shutil.copy2(backup/dst.name,dst)
        subprocess.run(["python3",str(m.PIPELINES/"build_operator_runtime.py"),"--strict","--remove-superseded"],cwd=m.REPO_ROOT); raise
    subprocess.run(["godot","--headless","--path",str(m.CUSTODIAN_ROOT),"--import","--quit"],check=True)
    subprocess.run(["godot","--headless","--path",str(m.CUSTODIAN_ROOT),"--script","res://tools/pipelines/build_operator_animation_resources.gd"],check=True)
    subprocess.run(["python3",str(m.CUSTODIAN_ROOT/"tools/validation/operator_animation_contract_report.py")],check=True,cwd=m.REPO_ROOT)
    for b,_,dst in candidates: b["source_file_sha256"]=m.file_sha256(dst); b["source_pixel_sha256"]=m.pixel_sha256(dst)
    data["aseprite"]["last_synced_sha256"]=m.file_sha256(ws/"workbench.aseprite"); data["last_publish"]={"timestamp":datetime.now(timezone.utc).isoformat(),"validation_status":"passed"}; save(manifest,data); return [str(x[2]) for x in candidates]
