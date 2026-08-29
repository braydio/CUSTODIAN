#!/usr/bin/env python3
"""Controller for disposable semantic Operator Aseprite workbenches."""
from __future__ import annotations
import json, os, shutil, subprocess
from datetime import datetime, timezone
from pathlib import Path
from PIL import Image
import animation_workbench_model as m
import animation_frame_contract as fc

DEFAULT_ROOT=m.REPO_ROOT/".ai/operator_animation_workbench"
LUA=m.CUSTODIAN_ROOT/"tools/aseprite/operator_animation_workbench.lua"
COMPATIBILITY_SCRIPT=m.PIPELINES/"update_operator_compatibility_resources.py"
GENERATED_OPERATOR_RESOURCES=[
    m.CUSTODIAN_ROOT/"game/actors/operator"/name for name in (
        "operator_runtime_frames.tres",
        "operator_weapon_frames.tres",
        "operator_melee_overlay_frames.tres",
        "operator_ranged_fx_frames.tres",
        "operator_modular_lower_body_frames.tres",
        "operator_modular_upper_body_frames.tres",
        "operator_modular_sidearm_frames.tres",
        "operator_modular_upper_fx_frames.tres",
        "operator_modular_cape_frames.tres",
        "operator_modular_head_frames.tres",
        "operator_animation_catalog_frames.tres",
    )
]

def resolve_aseprite(explicit=None, required=False):
    value=explicit or os.environ.get("ASEPRITE_BIN") or shutil.which("aseprite")
    if value and Path(value).is_file(): return Path(value).resolve()
    if required: raise m.WorkbenchError("Aseprite not found. Pass --aseprite PATH or set ASEPRITE_BIN.")
    return None

def workspace(root, identity): return Path(root)/identity["profile"]/identity["group"]/identity["action"]/identity["direction"]
def load(path,upgrade=True):
    data=json.loads(path.read_text())
    if upgrade and data.get("schema")=="custodian.operator_animation_workbench.v1":
        backup=path.with_name("workbench.v1.backup.json")
        if not backup.exists(): shutil.copy2(path,backup)
        data=m.upgrade_v1_manifest_to_v2(data); save(path,data)
    return data
def save(path,data): path.write_text(json.dumps(data,indent=2)+"\n")
def state(manifest, wb):
    edited=bool(manifest.get("pending_migration")) or (wb.exists() and manifest["aseprite"].get("last_synced_sha256") not in (None,m.file_sha256(wb)))
    stale=any(not (m.REPO_ROOT/x["source_contract"]["path"]).exists() or m.file_sha256(m.REPO_ROOT/x["source_contract"]["path"])!=x["source_contract"]["file_sha256"] for x in manifest["layers"])
    return "EDITED+STALE" if edited and stale else "EDITED" if edited else "STALE" if stale else "CLEAN"

def _baseline(plan, ws):
    base=ws/"baseline"; base.mkdir(parents=True,exist_ok=True); cw,ch=plan["canvas"].values(); frames=plan["timeline"]["document_frames"]
    composite=Image.new("RGBA",(cw*frames,ch))
    for b in plan["layers"]:
        src=m.REPO_ROOT/b["source_path"]; shutil.copy2(src,base/f"{b['binding_id']}.png")
        b["input_path"]=str((base/f"{b['binding_id']}.png").resolve())
        with Image.open(src) as im:
            fw,fh=b["frame_size"]; x,y=b["placement"]
            for i in range(min(b["frames"],frames)): composite.alpha_composite(im.convert("RGBA").crop((i*fw,0,(i+1)*fw,fh)),(i*cw+x,y))
    composite.save(base/"reference_composite.png")
    for r in plan.get("references",[]):
        src=m.REPO_ROOT/r["source_path"]; dst=base/f"{r['binding_id']}.png"; shutil.copy2(src,dst); r["input_path"]=str(dst.resolve())

def aseprite_run(binary, manifest, mode):
    subprocess.run([str(binary),"-b","--script-param",f"mode={mode}","--script-param",f"manifest={manifest.resolve()}","--script",str(LUA)],check=True)

def ensure(profile,action,direction,group="",weapon="",linked_profile="",root=DEFAULT_ROOT,aseprite=None):
    plan=m.build_plan(profile,action,direction,group,weapon,linked_profile); ws=workspace(root,plan["identity"]); mf=ws/"workbench.json"; wb=ws/"workbench.aseprite"
    if mf.exists() and wb.exists():
        old=load(mf); m.assert_context(old,plan); st=state(old,wb)
        if "STALE" in st: raise m.WorkbenchError("WORKBENCH STALE\ncanonical source changed; run operator anim refresh")
        return old,ws
    ws.mkdir(parents=True,exist_ok=True); plan["aseprite"]["path"]=str(wb.resolve()); _baseline(plan,ws); save(mf,plan)
    aseprite_run(resolve_aseprite(aseprite,True),mf,"assemble"); plan["aseprite"]["last_synced_sha256"]=m.file_sha256(wb); save(mf,plan); return plan,ws

def refresh(profile,action,direction,group="",weapon="",linked_profile="",root=DEFAULT_ROOT,aseprite=None,discard=False):
    fresh=m.build_plan(profile,action,direction,group,weapon,linked_profile); ws=workspace(root,fresh["identity"]); mf=ws/"workbench.json"; wb=ws/"workbench.aseprite"
    if mf.exists() and wb.exists():
        old=load(mf)
        if not discard:
            m.assert_context(old,fresh)
        if old.get("pending_migration") and not discard: raise m.WorkbenchError("WORKBENCH HAS PENDING CONTRACT MIGRATION\n--discard-edits also discards the pending migration")
        if state(old,wb).startswith("EDITED") and not discard: raise m.WorkbenchError("workbench has unsynchronized edits; pass --discard-edits")
        stamp=datetime.now().strftime("%Y%m%dT%H%M%S"); (ws/"backups"/stamp).mkdir(parents=True,exist_ok=True); shutil.copy2(wb,ws/"backups"/stamp/"workbench.aseprite"); shutil.copy2(mf,ws/"backups"/stamp/"workbench.json")
    if ws.exists(): shutil.rmtree(ws/"baseline",ignore_errors=True)
    fresh["aseprite"]["path"]=str(wb.resolve()); ws.mkdir(parents=True,exist_ok=True); _baseline(fresh,ws); save(mf,fresh); aseprite_run(resolve_aseprite(aseprite,True),mf,"assemble"); fresh["aseprite"]["last_synced_sha256"]=m.file_sha256(wb); save(mf,fresh); return fresh,ws

def frame_migrate(profile,action,direction,operation,position,fill="duplicate-prev",layers="auto",group="",weapon="",linked_profile="",root=DEFAULT_ROOT,aseprite=None,dry_run=False):
    requested=m.build_plan(profile,action,direction,group,weapon,linked_profile); ws=workspace(root,requested["identity"]); mf=ws/"workbench.json"; wb=ws/"workbench.aseprite"
    if not mf.exists() or not wb.exists(): raise m.WorkbenchError("workbench absent; run operator anim edit first")
    data=load(mf); m.assert_context(data,requested)
    if "STALE" in state(data,wb): raise m.WorkbenchError("WORKBENCH STALE")
    if data.get("pending_migration"): raise m.WorkbenchError("WORKBENCH HAS PENDING CONTRACT MIGRATION")
    try:
        report=fc.migration_report(data,operation,position,fill,layers,m.REPO_ROOT)
    except ValueError as error:
        raise m.WorkbenchError(str(error)) from error
    if report["dependency_audit"]["level"]!="GREEN": raise m.WorkbenchError("FRAME MIGRATION BLOCKED BY GAMEPLAY FRAME AUTHORITY\n"+json.dumps(report["dependency_audit"],indent=2))
    if dry_run: return report
    stamp=datetime.now().strftime("%Y%m%dT%H%M%S"); backup=ws/"backups"/f"frame_{stamp}"; backup.mkdir(parents=True,exist_ok=True); shutil.copy2(wb,backup/"workbench.aseprite"); shutil.copy2(mf,backup/"workbench.json")
    data["export_stamp"]=f"migration_{stamp}"; save(mf,data); aseprite_run(resolve_aseprite(aseprite,True),mf,"export")
    raw=ws/"exports"/data["export_stamp"]/"raw"; staging=ws/"migrations"/stamp; affected=set(report["affected_bindings"])
    try:
        for b in data["layers"]:
            current=staging/"current"/f"{b['binding_id']}.png"; m.extract_binding(raw/f"{b['binding_id']}.png",b,data["canvas"],current)
            target=staging/"target"/f"{b['binding_id']}.png"
            if b["binding_id"] in affected:
                fc.transform_strip(current,target,b["workspace_contract"]["frames"],b["workspace_contract"]["frame_size"],operation,position,fill)
                new_frames=b["workspace_contract"]["frames"]+(1 if operation=="add" else -1); b["workspace_contract"]["frames"]=new_frames; b["workspace_contract"]["timeline_slots"]=list(range(1,new_frames+1)); b["frames"]=new_frames
                key=m.SCHEMA.OperatorAssetKey(b["owner"],b["layer"],b["profile"],b["group"],b["action"],b["direction"],new_frames,*b["frame_size"])
                target_path=m.CUSTODIAN_ROOT/m.SCHEMA.canonical_source_path(key); b["publish_contract"]={"path":m.rel(target_path),"frames":new_frames,"frame_size":b["frame_size"]}
            else: shutil.copy2(current,target)
            b["input_path"]=str(target.resolve())
        data["timeline"]["workspace_clock_frames"]=report["new_clock_frames"]; data["timeline"]["document_frames"]=max([b["workspace_contract"]["frames"] for b in data["layers"]]+[r["frames"] for r in data.get("references",[])]); data["timeline"]["frames"]=data["timeline"]["document_frames"]; data["pending_migration"]=report; save(mf,data); aseprite_run(resolve_aseprite(aseprite,True),mf,"assemble"); data["aseprite"]["last_synced_sha256"]=m.file_sha256(wb); save(mf,data)
    except Exception:
        shutil.copy2(backup/"workbench.aseprite",wb); shutil.copy2(backup/"workbench.json",mf); raise
    return report

def _validation_commands(data,full_validate=False):
    cmds=[["python3",str(COMPATIBILITY_SCRIPT),"--check"],["python3",str(m.CUSTODIAN_ROOT/"tools/validation/operator_animation_contract_report.py")],["python3",str(m.CUSTODIAN_ROOT/"tools/validation/operator_animation_workbench_smoke.py")],["godot","--headless","--path",str(m.CUSTODIAN_ROOT),"--script","res://tools/validation/operator_modular_layers_smoke.gd"]]
    if data["identity"]["profile"]=="melee_1h" and data["identity"]["group"]=="posture": cmds.append(["godot","--headless","--path",str(m.CUSTODIAN_ROOT),"--script","res://tools/validation/operator_melee_posture_smoke.gd"])
    if data.get("context",{}).get("weapon_id")=="vigil_pattern_dagger": cmds.append(["godot","--headless","--path",str(m.CUSTODIAN_ROOT),"--script","res://tools/validation/operator_vigil_dagger_smoke.gd"])
    if full_validate: cmds.append(["python3",str(m.CUSTODIAN_ROOT/"tools/validation/run_validation.py"),"--changed","--json"])
    return cmds

def _journal_stage(path,journal,state,stage):
    journal["state"]=state
    if stage and stage not in journal["validation_stages_completed"]: journal["validation_stages_completed"].append(stage)
    save(path,journal)

def _compatibility_update():
    subprocess.run(["python3",str(COMPATIBILITY_SCRIPT)],check=True,cwd=m.REPO_ROOT)

def _compatibility_check():
    subprocess.run(["python3",str(COMPATIBILITY_SCRIPT),"--check"],check=True,cwd=m.REPO_ROOT)

def _godot_import():
    subprocess.run(["godot","--headless","--path",str(m.CUSTODIAN_ROOT),"--import","--quit"],check=True)

def _catalog_build():
    subprocess.run(["godot","--headless","--path",str(m.CUSTODIAN_ROOT),"--script","res://tools/pipelines/build_operator_animation_resources.gd"],check=True)

def _operator_scene_consistency():
    _compatibility_check()
    subprocess.run(["godot","--headless","--path",str(m.CUSTODIAN_ROOT),"--script","res://tools/validation/operator_modular_layers_smoke.gd"],check=True)

def publish(manifest, aseprite=None, force_stale=False, dry_run=False,full_validate=False,requested=None):
    ws=manifest.parent; data=load(manifest); st=state(data,ws/"workbench.aseprite")
    if requested: m.assert_context(data,requested)
    if "STALE" in st and not force_stale: raise m.WorkbenchError(f"publish refused: {st}; use scary --force-stale-source only after review")
    stamp=datetime.now().strftime("%Y%m%dT%H%M%S"); data["export_stamp"]=stamp; save(manifest,data); aseprite_run(resolve_aseprite(aseprite,True),manifest,"export")
    migration=data.get("pending_migration"); normalized=ws/"exports"/stamp/"normalized"; candidates=[]
    for b in data["layers"]:
        out=normalized/f"{b['binding_id']}.png"; m.extract_binding(ws/"exports"/stamp/"raw"/f"{b['binding_id']}.png",b,data["canvas"],out); candidates.append((b,out,m.REPO_ROOT/b["publish_contract"]["path"],m.REPO_ROOT/b["source_contract"]["path"]))
    if dry_run: return [str(x[2]) for x in candidates]
    if migration:
        affected=[b for b in data["layers"] if b["binding_id"] in migration["affected_bindings"]]; current_audit=fc.audit_dependencies(m.REPO_ROOT,data,affected)
        if current_audit["level"]!="GREEN": raise m.WorkbenchError("FRAME MIGRATION BLOCKED BY GAMEPLAY FRAME AUTHORITY\n"+json.dumps(current_audit,indent=2))
    for b,c,dst,old in candidates:
        if dst!=old and dst.exists(): raise m.WorkbenchError(f"target frame contract already exists: {dst}")
    tx=ws/"transactions"/stamp; backup=tx/"backups"; source_backup=backup/"sources"; resource_backup=backup/"resources"; source_backup.mkdir(parents=True,exist_ok=True); resource_backup.mkdir(parents=True,exist_ok=True)
    journal_path=tx/"transaction.json"
    journal={"transaction_id":stamp,"state":"PREPARED","sources":[],"resources":[],"pending_migration":migration,"validation_stages_completed":[]}
    for b,c,dst,old in candidates:
        saved=source_backup/f"{b['binding_id']}.png"; shutil.copy2(old,saved)
        sidecar=old.with_suffix(old.suffix+".import")
        saved_sidecar=source_backup/f"{b['binding_id']}.png.import"
        if sidecar.exists(): shutil.copy2(sidecar,saved_sidecar)
        journal["sources"].append({"binding_id":b["binding_id"],"old_path":m.rel(old),"old_sha256":m.file_sha256(old),"target_path":m.rel(dst),"target_sha256":m.file_sha256(c),"backup_path":m.rel(saved),"import_backup_path":m.rel(saved_sidecar) if saved_sidecar.exists() else ""})
    for resource in GENERATED_OPERATOR_RESOURCES:
        saved=resource_backup/resource.name; shutil.copy2(resource,saved)
        journal["resources"].append({"path":m.rel(resource),"old_sha256":m.file_sha256(resource),"target_sha256":None,"backup_path":m.rel(saved)})
    save(journal_path,journal)
    try:
        for b,c,dst,old in candidates:
            if dst!=old:
                old.unlink()
                old.with_suffix(old.suffix+".import").unlink(missing_ok=True)
            tmp=dst.with_suffix(".png.workbench.tmp"); shutil.copy2(c,tmp); dst.parent.mkdir(parents=True,exist_ok=True); os.replace(tmp,dst)
        _journal_stage(journal_path,journal,"SOURCE_SWAPPED","source_swap")
        subprocess.run(["python3",str(m.PIPELINES/"build_operator_runtime.py"),"--strict","--remove-superseded"],check=True,cwd=m.REPO_ROOT)
        _journal_stage(journal_path,journal,"RUNTIME_BUILT","runtime_build")
        _compatibility_update()
        for item in journal["resources"]: item["target_sha256"]=m.file_sha256(m.REPO_ROOT/item["path"])
        _compatibility_check()
        _journal_stage(journal_path,journal,"COMPATIBILITY_BUILT","compatibility_resource_generation")
        _godot_import(); _journal_stage(journal_path,journal,"GODOT_IMPORTED","godot_import")
        _catalog_build()
        for item in journal["resources"]: item["target_sha256"]=m.file_sha256(m.REPO_ROOT/item["path"])
        _journal_stage(journal_path,journal,"RESOURCES_BUILT","catalog_resource_generation")
        for cmd in _validation_commands(data,full_validate):
            subprocess.run(cmd,check=True,cwd=m.REPO_ROOT)
            _journal_stage(journal_path,journal,journal["state"],"validation:"+Path(cmd[-1]).name)
        _journal_stage(journal_path,journal,"VALIDATED","mandatory_validation")
    except Exception:
        try:
            for b,c,dst,old in candidates:
                if dst.exists(): dst.unlink()
                dst.with_suffix(dst.suffix+".import").unlink(missing_ok=True)
                shutil.copy2(source_backup/f"{b['binding_id']}.png",old)
                side=source_backup/f"{b['binding_id']}.png.import"
                if side.exists(): shutil.copy2(side,old.with_suffix(old.suffix+".import"))
            for resource in GENERATED_OPERATOR_RESOURCES: shutil.copy2(resource_backup/resource.name,resource)
            subprocess.run(["python3",str(m.PIPELINES/"build_operator_runtime.py"),"--strict","--remove-superseded"],check=True,cwd=m.REPO_ROOT)
            _compatibility_update(); _compatibility_check(); _godot_import(); _catalog_build(); _operator_scene_consistency()
            _journal_stage(journal_path,journal,"ROLLED_BACK","rollback_consistency")
        except Exception: journal["state"]="RECOVERY_REQUIRED"
        save(journal_path,journal); raise
    for b,_,dst,old in candidates:
        b["source_path"]=m.rel(dst); b["source_file_sha256"]=m.file_sha256(dst); b["source_pixel_sha256"]=m.pixel_sha256(dst); b["source_contract"]={"path":m.rel(dst),"frames":b["workspace_contract"]["frames"],"frame_size":b["frame_size"],"file_sha256":b["source_file_sha256"],"pixel_sha256":b["source_pixel_sha256"]}; b["publish_contract"]={"path":m.rel(dst),"frames":b["frames"],"frame_size":b["frame_size"]}
    data["timeline"]["source_clock_frames"]=data["timeline"]["workspace_clock_frames"]; data["pending_migration"]=None; _baseline(data,ws); data["aseprite"]["last_synced_sha256"]=m.file_sha256(ws/"workbench.aseprite"); data["last_publish"]={"timestamp":datetime.now(timezone.utc).isoformat(),"validation_status":"passed"}; _journal_stage(journal_path,journal,"COMMITTED","manifest_sync"); save(manifest,data); return [str(x[2]) for x in candidates]
