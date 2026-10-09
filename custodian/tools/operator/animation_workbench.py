#!/usr/bin/env python3
"""Controller for disposable semantic Operator Aseprite workbenches."""
from __future__ import annotations
import json, os, shutil, subprocess
from dataclasses import asdict
from datetime import datetime, timezone
from pathlib import Path
from PIL import Image
import animation_workbench_model as m
import animation_frame_contract as fc

DEFAULT_ROOT=m.REPO_ROOT/".ai/operator_animation_workbench"
LUA=m.CUSTODIAN_ROOT/"tools/aseprite/operator_animation_workbench.lua"
GENERATED_OPERATOR_RESOURCES=[
    m.CUSTODIAN_ROOT/"content/sprites/operator/runtime/operator_runtime_frames.tres",
]
HORIZONTAL_COUNTERPARTS={"e":"w","w":"e","ne":"nw","nw":"ne","se":"sw","sw":"se"}

def horizontal_counterpart(direction):
    return HORIZONTAL_COUNTERPARTS.get(direction)

def mirror_strip_frames(source, target, frames, frame_size):
    """Mirror every cell without reversing the strip's temporal ordering."""
    fw,fh=map(int,frame_size)
    with Image.open(source) as opened:
        image=opened.convert("RGBA")
        if image.size!=(fw*int(frames),fh):
            raise m.WorkbenchError(f"mirror candidate dimensions {image.size} do not match {frames}x{fw}x{fh}: {source}")
        mirrored=Image.new("RGBA",image.size)
        for index in range(int(frames)):
            cell=image.crop((index*fw,0,(index+1)*fw,fh))
            mirrored.paste(cell.transpose(Image.Transpose.FLIP_LEFT_RIGHT),(index*fw,0))
        target.parent.mkdir(parents=True,exist_ok=True)
        mirrored.save(target)

def _counterpart_target(binding, direction):
    key=m.SCHEMA.OperatorAssetKey(binding["owner"],binding["layer"],binding["profile"],binding["group"],binding["action"],direction,binding["workspace_contract"]["frames"],*binding["frame_size"])
    return m.CUSTODIAN_ROOT/m.SCHEMA.canonical_source_path(key)

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
    if manifest.get("creation"):
        generation = manifest.get("creation", {}).get("art_generation", "legacy_96")
        for binding in manifest.get("layers", ()):
            source = m.REPO_ROOT / binding.get("source_path", "")
            runtime = m.REPO_ROOT / binding.get("runtime_path", "")
            collision = (source.exists() or Path(str(source)+".import").exists()
                or m.BUILDER.timing_sidecar_path(source).exists())
            if generation == "legacy_96":
                collision = collision or runtime.exists() or Path(str(runtime)+".import").exists() or m.BUILDER.timing_sidecar_path(runtime).exists()
            if collision: return "NEW / COLLISION"
        if not wb.exists(): return "NEW / UNSAVED"
        baseline = manifest.get("aseprite", {}).get("last_synced_sha256")
        if baseline and m.file_sha256(wb) == baseline: return "NEW / UNSAVED"
        return "NEW / READY TO PUBLISH"
    edited=bool(manifest.get("pending_migration")) or (wb.exists() and manifest["aseprite"].get("last_synced_sha256") not in (None,m.file_sha256(wb)))
    stale=any(
        (m.REPO_ROOT/x["source_contract"]["path"]).exists()
        if x.get("source_contract",{}).get("operation")=="CREATE"
        else (not (m.REPO_ROOT/x["source_contract"]["path"]).exists() or m.file_sha256(m.REPO_ROOT/x["source_contract"]["path"])!=x["source_contract"].get("file_sha256"))
        for x in manifest["layers"]
    )
    return "EDITED+STALE" if edited and stale else "EDITED" if edited else "STALE" if stale else "CLEAN"

def create_animation(profile, action, direction, *, group, frames, frame_size=m.DEFAULT_FRAME_SIZE,
                     fps=8.0, loop=True, template="full_body", root=DEFAULT_ROOT,
                     aseprite=None, dry_run=False, source_root=None, weapon_root=None,
                     repo_root=None, art_generation="legacy_96", initial_sources=None):
    """Create an ignored authoring session for a new semantic animation."""
    repo = Path(repo_root or m.REPO_ROOT)
    plan = m.build_creation_plan(profile, group, action, direction, frames, frame_size,
        fps, loop, template, repo_root=repo,
        source_root=Path(source_root or m.SOURCE_ROOT), weapon_root=Path(weapon_root or m.WEAPON_ROOT),
        art_generation=art_generation)
    identity = asdict(plan.identity)
    ws_root = Path(root) / art_generation if art_generation != "legacy_96" else Path(root)
    ws = workspace(ws_root, identity)
    manifest = ws / "workbench.json"
    document = ws / "workbench.aseprite"
    targets = [row["source_path"] for row in plan.layers]
    if dry_run:
        return {"identity": identity, "template": template, "frames": frames,
                "frame_size": list(plan.frame_size), "fps": fps, "loop": bool(loop),
                "layers": [{"layer": row["layer"], "source": row["source_path"], "runtime": row["runtime_path"], "operation": "CREATE"} for row in plan.layers],
                "references": list(plan.references),
                "collisions": list(plan.collisions), "status": plan.status,
                "already_present": False, "workspace": str(ws)}
    if plan.status != "READY":
        raise m.WorkbenchError("ANIMATION CREATE COLLISION\n" + "\n".join(plan.collisions))
    binary = resolve_aseprite(aseprite, True)
    if manifest.exists() or document.exists():
        if manifest.is_file() and document.is_file() and initial_sources:
            existing = load(manifest)
            creation = existing.get("creation", {})
            expected_identity = {"profile": profile, "group": group, "action": action, "direction": direction}
            if (existing.get("identity") == expected_identity
                    and creation.get("art_generation", "legacy_96") == art_generation
                    and creation.get("import_sources") == dict(initial_sources)
                    and creation.get("template") == template):
                return existing, ws
            raise m.WorkbenchError(f"import Workbench exists with a different target/source proof: {ws}")
        if manifest.is_file() and not document.exists():
            existing = load(manifest)
            expected = {"profile": profile, "group": group, "action": action, "direction": direction}
            timeline=existing.get("timeline",{}); canvas=existing.get("canvas",{})
            requested_size=list(plan.frame_size)
            if (existing.get("creation", {}).get("template") != template or existing.get("identity") != expected
                    or int(timeline.get("workspace_clock_frames",0))!=int(frames)
                    or [int(canvas.get("width",0)),int(canvas.get("height",0))]!=requested_size
                    or float(timeline.get("fps",0))!=float(fps) or bool(timeline.get("loop"))!=bool(loop)):
                raise m.WorkbenchError(f"creation workspace exists with a different contract: {ws}")
            aseprite_run(binary, manifest, "assemble")
            existing["aseprite"]["last_synced_sha256"] = m.file_sha256(document)
            save(manifest, existing)
            return existing, ws
        raise m.WorkbenchError(f"creation workspace already exists; refusing to replace it: {ws}")
    if ws.exists() and any(child.name != "baseline" for child in ws.iterdir()):
        raise m.WorkbenchError(f"creation workspace contains unrecognized files; preserving them: {ws}")
    # Revalidate immediately before creating any files, including collisions introduced
    # after the read-only plan was shown.
    confirmed = m.build_creation_plan(profile, group, action, direction, frames, frame_size,
        fps, loop, template, repo_root=repo,
        source_root=Path(source_root or m.SOURCE_ROOT), weapon_root=Path(weapon_root or m.WEAPON_ROOT),
        art_generation=art_generation)
    if confirmed.status != "READY":
        raise m.WorkbenchError("ANIMATION CREATE COLLISION\n" + "\n".join(confirmed.collisions))
    ws.mkdir(parents=True, exist_ok=True)
    width, height = plan.frame_size
    layer_rows = []
    for row in plan.layers:
        key = row["key"]
        layer = row["layer"]
        layer_rows.append({
            "binding_id": layer, "aseprite_layer_name": layer, "role": "editable",
            "editable": True, "owner": "operator", "profile": profile,
            "group": group, "action": action, "direction": direction, "layer": layer,
            "source_path": row["source_path"], "runtime_path": row["runtime_path"],
            "source_file_sha256": "", "source_pixel_sha256": "", "frames": int(frames),
            "frame_size": [width, height], "placement": [0, 0], "timeline_mapping": "exact",
            "semantic_identity": {"owner": "operator", "layer": layer, "profile": profile, "group": group, "action": action, "direction": direction},
            "source_contract": {"path": row["source_path"], "frames": int(frames), "frame_size": [width, height], "operation": "CREATE"},
            "workspace_contract": {"frames": int(frames), "frame_size": [width, height], "placement": [0, 0], "timeline_slots": list(range(1, int(frames) + 1))},
            "publish_contract": {"path": row["source_path"], "frames": int(frames), "frame_size": [width, height]},
            "input_path": str(Path(initial_sources[layer]).resolve()) if initial_sources and layer in initial_sources else "",
        })
    reference_rows=[]
    baseline=ws/"baseline"; baseline.mkdir(parents=True,exist_ok=True)
    for reference in plan.references:
        item=dict(reference)
        source=Path(item["source_path"])
        if not source.is_absolute(): source=repo/source
        target=baseline/f"{item['binding_id']}.png"
        shutil.copy2(source,target)
        item["input_path"]=str(target.resolve())
        reference_rows.append(item)
    timing = {"fps": float(fps), "loop": bool(loop), "durations": [1.0] * int(frames)}
    ident = identity
    context = {"weapon_id": "", "linked_profile": "", "presentation_mode": ""}
    context["fingerprint"] = m.context_fingerprint(ident, None)
    data = {"schema": m.SCHEMA_NAME, "identity": ident, "context": context,
        "weapon_context": None, "creation": {"state": "NEW / UNSAVED", "template": template,
            "art_generation": art_generation,
            "authoring_identity": f"{art_generation}:{profile}/{group}/{action}/{direction}",
            "import_sources": dict(initial_sources or {}), "plan": {"layers": targets}},
        "timeline": {"frames": int(frames), "source_clock_frames": int(frames),
            "workspace_clock_frames": int(frames), "document_frames": int(frames),
            "preview_fps": float(fps), "fps": float(fps), "loop": bool(loop),
            "durations": timing["durations"], "frame_durations_ms": [1000.0 / float(fps)] * int(frames),
            "timing_authority": True, "clock_owner": layer_rows[0]["layer"]},
        "canvas": {"width": width, "height": height},
        "aseprite": {"path": str(document.resolve()), "last_synced_sha256": None},
        "layers": layer_rows, "references": reference_rows, "pending_migration": None,
        "last_publish": {"timestamp": None, "validation_status": None}}
    save(manifest, data)
    aseprite_run(binary, manifest, "assemble")
    data["aseprite"]["last_synced_sha256"] = m.file_sha256(document)
    save(manifest, data)
    return data, ws

def source_contract_freshness(manifest, repo_root=None):
    """Return per-binding drift from the exact canonical source contract."""
    root=Path(repo_root or m.REPO_ROOT); problems={}; timeline=manifest.get("timeline",{})
    for binding in manifest.get("layers",[]):
        contract=binding.get("source_contract",{}); relative=str(contract.get("path",binding.get("source_path","")))
        label="/".join(str(manifest.get("identity",{}).get(key,"")) for key in ("profile","group","action","direction"))
        label=f"{label}/{binding.get('layer',binding.get('binding_id','layer'))} ({relative or 'missing path'})"
        path=root/relative
        if contract.get("operation")=="CREATE":
            if path.exists(): problems[label]="CREATE target appeared after creation planning; refusing collision"
            continue
        if not relative or not path.is_file():
            problems[label]="canonical source is missing"
            continue
        try:
            actual_hash=m.file_sha256(path)
            if actual_hash!=contract.get("file_sha256",binding.get("source_file_sha256")):
                problems[label]="canonical source bytes changed since this Workbench baseline"
                continue
            fw,fh=map(int,contract.get("frame_size",binding.get("frame_size",(0,0))))
            with Image.open(path) as source: size=source.size
            frames=int(contract.get("frames",binding.get("frames",0)))
            if fw<=0 or fh<=0 or size!=(fw*frames,fh):
                problems[label]=f"canonical strip is {size}, expected {frames} frames of {fw}x{fh}"
                continue
            expected_pixel=contract.get("pixel_sha256",binding.get("source_pixel_sha256"))
            if expected_pixel and m.pixel_sha256(path)!=expected_pixel:
                problems[label]="canonical pixel identity changed since this Workbench baseline"
                continue
            if binding.get("layer")==timeline.get("clock_owner") and timeline.get("timing_authority"):
                timing_path=m.BUILDER.timing_sidecar_path(path)
                try: timing=json.loads(timing_path.read_text(encoding="utf-8"))
                except (OSError,json.JSONDecodeError): timing=None
                expected=m.timing_payload_from_timeline({**timeline,"workspace_clock_frames":timeline.get("source_clock_frames",frames)})
                if timing is None or expected is None or any(timing.get(key)!=expected.get(key) for key in ("frames","loop","durations")) or abs(float(timing.get("fps",0))-float(expected["fps"]))>1e-9:
                    problems[label]="canonical timing sidecar changed since this Workbench baseline"
        except (OSError,ValueError) as error:
            problems[label]=f"canonical source contract could not be read: {error}"
    return problems

def inspect_saved_layers(manifest, aseprite=None):
    manifest=Path(manifest); data=load(manifest); ws=manifest.parent; wb=ws/"workbench.aseprite"
    if not wb.is_file(): raise m.WorkbenchError("saved Workbench document is missing")
    report_path=ws/".layer_inspection.json"
    try:
        aseprite_run(resolve_aseprite(aseprite,True),manifest,"inspect_layers")
        report=json.loads(report_path.read_text(encoding="utf-8"))
    finally:
        report_path.unlink(missing_ok=True)
    expected=(int(data["canvas"]["width"]),int(data["canvas"]["height"]))
    if (int(report.get("width",0)),int(report.get("height",0)))!=expected or int(report.get("frames",0))!=int(data["timeline"]["document_frames"]):
        raise m.WorkbenchError("SAVED ASEPRITE CONTRACT MISMATCH; save/resolve the pending frame or canvas migration before FX adoption")
    return report

def adopt_fx_layer(manifest, layer_name, aseprite=None, *, live_document_path=None, live_modified=None, source_root=None, weapon_root=None, repo_root=None):
    """Explicitly bind one eligible saved editor layer to semantic FX."""
    manifest=Path(manifest); data=load(manifest); ws=manifest.parent; wb=ws/"workbench.aseprite"
    if live_modified is True and live_document_path:
        try: same=Path(live_document_path).resolve()==wb.resolve()
        except OSError: same=False
        if same: raise m.WorkbenchError("SAVE WORKBENCH BEFORE FX ADOPTION\nLive document has unsaved changes; save it, then retry.")
    report=inspect_saved_layers(manifest,aseprite)
    row=next((item for item in report.get("layers",()) if item.get("name")==layer_name),None)
    if row is None: raise m.WorkbenchError(f"saved Aseprite layer not found: {layer_name}")
    if not row.get("top_level") or int(row.get("depth",-1))!=0:
        raise m.WorkbenchError("FX adoption requires a top-level saved Aseprite layer")
    if row.get("reference") or layer_name.startswith("__"):
        raise m.WorkbenchError("reserved/reference layers cannot be adopted")
    if layer_name not in {"vfx","fx"}:
        raise m.WorkbenchError("only saved top-level layers named 'vfx' or 'fx' may be adopted as FX")
    if len([b for b in data.get("layers",()) if b.get("layer")=="fx"])!=0:
        raise m.WorkbenchError("exactly one FX binding is allowed")
    binding=m.fx_adoption_binding(data,layer_name,source_root=source_root or m.SOURCE_ROOT,weapon_root=weapon_root or m.WEAPON_ROOT,repo_root=repo_root or m.REPO_ROOT)
    data["layers"].append(binding); data["layers"].sort(key=lambda item:m.PRESENTATION_ORDER.index(item["layer"]))
    save(manifest,data)
    return {"binding":binding,"operation":binding["source_contract"]["operation"],"target":binding["publish_contract"]["path"],"saved_layer":layer_name,"cel_frames":row.get("cel_frames",[])}

def _git_metadata_preimages(repo_root, backup_root):
    """Capture clean, tracked import metadata bytes before canonical mutation."""
    if not (Path(repo_root)/".git").exists(): return []
    result=subprocess.run(["git","ls-files","-t","-z","--","*.import","*.uid"],cwd=repo_root,capture_output=True,check=False)
    if result.returncode: return []
    records=[]
    for raw in (result.stdout or b"").split(b"\0"):
        if not raw: continue
        flag,_,path_bytes=raw.partition(b" ")
        if flag==b"S": continue
        relative=path_bytes.decode("utf-8","surrogateescape")
        status=subprocess.run(["git","status","--porcelain=v1","--",relative],cwd=repo_root,capture_output=True,check=False)
        if status.stdout.strip():
            raise m.WorkbenchError(f"PRE-EXISTING IMPORT METADATA CHANGE BLOCKS PUBLISH\n{relative}")
        path=Path(repo_root)/relative
        if not path.is_file():
            raise m.WorkbenchError(f"TRACKED IMPORT METADATA IS MISSING\n{relative}")
        saved=Path(backup_root)/relative; saved.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(path,saved)
        records.append({"path":relative,"backup_path":str(saved),"existed":True,"sha256":m.file_sha256(path),"restored":False})
    return records

def _restore_import_metadata(journal, repo_root, protected_paths=()):
    """Restore only clean tracked metadata changed during this transaction."""
    errors=[]; protected=set(protected_paths)
    for item in journal.get("import_metadata_preimages",[]):
        if item["path"] in protected: continue
        path=Path(repo_root)/item["path"]
        current=path.read_bytes() if path.is_file() else None
        backup=Path(item["backup_path"])
        original=backup.read_bytes() if backup.is_file() else None
        if original is None:
            errors.append(item["path"]+": preimage backup missing"); continue
        if current!=original:
            try:
                temporary=path.with_name(path.name+".workbench-restore-tmp"); temporary.write_bytes(original); os.replace(temporary,path)
            except OSError as error:
                errors.append(item["path"]+f": {error}"); continue
        item["restored"]=True
        item["post_sha256"]=m.file_sha256(path)
    return errors

def _git_changed_paths(repo_root):
    if not (Path(repo_root)/".git").exists(): return None
    result=subprocess.run(["git","status","--porcelain=v1","-z","--untracked-files=all"],cwd=repo_root,capture_output=True,check=False)
    if result.returncode: return None
    fields=(result.stdout or b"").split(b"\0"); paths=set(); index=0
    while index<len(fields):
        entry=fields[index]; index+=1
        if not entry: continue
        if len(entry)>=4 and entry[:2]!=b"  ":
            paths.add(entry[3:].decode("utf-8","surrogateescape"))
            if b"R" in entry[:2] or b"C" in entry[:2]:
                if index<len(fields) and fields[index]:
                    paths.add(fields[index].decode("utf-8","surrogateescape"))
                index+=1
    return paths

def _failure_record(error, stage):
    record={"stage":stage,"operation":type(error).__name__,"message":str(error)}
    if isinstance(error,subprocess.CalledProcessError):
        record.update({"return_code":error.returncode,"command":error.cmd,"stderr":str(error.stderr or "")[-4000:],"stdout":str(error.stdout or "")[-2000:]})
    return record

def _verify_rollback_preimages(journal, repo_root, document_path, document_sha256):
    """Return exact unresolved paths unless every transaction-owned preimage is proved."""
    root=Path(repo_root); unresolved=[]
    def matches(relative, expected):
        path=root/relative
        actual=m.file_sha256(path) if path.is_file() else None
        return actual==expected
    for item in journal.get("sources",[]):
        old=item["old_path"]
        if item.get("operation")=="CREATE" and not item.get("created_by_transaction") and (root/old).exists():
            pass  # A concurrent creator owns this colliding path; preserve it.
        elif not matches(old,item.get("old_sha256")): unresolved.append(old)
        target=item["target_path"]
        if target!=old and (root/target).exists() and (item.get("operation")!="CREATE" or item.get("created_by_transaction")): unresolved.append(target)
    for item in journal.get("resources",[]):
        if not matches(item["path"],item.get("old_sha256")): unresolved.append(item["path"])
    for item in journal.get("import_metadata_preimages",[]):
        if not matches(item["path"],item.get("sha256")): unresolved.append(item["path"])
    if document_sha256 and (not Path(document_path).is_file() or m.file_sha256(document_path)!=document_sha256):
        unresolved.append(str(document_path))
    changed=_git_changed_paths(root)
    if changed: unresolved.extend(sorted(changed))
    return sorted(set(unresolved))

def _restore_source_backup_without_overwrite(saved, target):
    """Restore a transaction preimage only if its original path is still vacant."""
    try:
        os.link(saved,target)
    except FileExistsError as error:
        raise m.WorkbenchError(f"rollback target was recreated externally; preserving it: {target}") from error

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
    try:
        subprocess.run([str(binary),"-b","--script-param",f"mode={mode}","--script-param",f"manifest={manifest.resolve()}","--script",str(LUA)],check=True,capture_output=True,text=True)
    except subprocess.CalledProcessError as exc:
        detail = "\n".join(part.strip() for part in (exc.stdout or "", exc.stderr or "") if part and part.strip())
        message = detail[-4000:] or f"Aseprite exited with status {exc.returncode}"
        raise m.WorkbenchError("ASEPRITE WORKBENCH EXPORT FAILED\n" + message) from exc

def inspect_saved_document_contract(manifest_path, aseprite=None):
    """Read the physical saved Aseprite canvas, frames, and timing without repairing it."""
    manifest_path=Path(manifest_path); wb=manifest_path.parent/"workbench.aseprite"
    if not manifest_path.is_file() or not wb.is_file():
        raise m.WorkbenchError("saved Workbench manifest or document is missing")
    report_path=manifest_path.parent/".document_contract.json"
    try:
        aseprite_run(resolve_aseprite(aseprite,True),manifest_path,"inspect_contract")
        report=json.loads(report_path.read_text(encoding="utf-8"))
        if not isinstance(report,dict) or not isinstance(report.get("durations"),list):
            raise ValueError("Aseprite returned an invalid document contract report")
        report["frames"]=int(report["frames"])
        report["width"]=int(report["width"])
        report["height"]=int(report["height"])
        report["durations"]=[float(value) for value in report["durations"]]
        if report["frames"]<1 or report["width"]<1 or report["height"]<1:
            raise ValueError("Aseprite returned non-positive document dimensions")
        return report
    except (OSError,ValueError,KeyError,TypeError,json.JSONDecodeError) as error:
        raise m.WorkbenchError(f"saved Aseprite document contract is unreadable: {error}") from error
    finally:
        report_path.unlink(missing_ok=True)

def reconcile_saved_document_contract(data, manifest_path, aseprite=None):
    """Inspect saved document timing and repair only a provably obsolete frame migration."""
    manifest_path=Path(manifest_path); ws=manifest_path.parent; wb=ws/"workbench.aseprite"
    if not wb.is_file(): return data
    report=inspect_saved_document_contract(manifest_path,aseprite)
    timeline=data.get("timeline",{}); migration=data.get("pending_migration")
    physical=int(report.get("frames",0)); dimensions=(int(report.get("width",0)),int(report.get("height",0)))
    canvas=(int(data.get("canvas",{}).get("width",0)),int(data.get("canvas",{}).get("height",0)))
    contracts=[int(binding.get("workspace_contract",{}).get("frames",0)) for binding in data.get("layers",[])]
    if dimensions!=canvas:
        raise m.WorkbenchError(f"SAVED ASEPRITE CONTRACT MISMATCH\nphysical canvas {dimensions}, manifest canvas {canvas}; saved document preserved. Use the explicit canvas migration flow.")
    durations=[float(value) for value in report.get("durations",[])]
    expected_duration=1.0/float(timeline.get("preview_fps",timeline.get("fps",0)) or 1)
    timing_ok=len(durations)==physical and all(abs(value-expected_duration)<=0.001 for value in durations)
    actual_contract=(physical==int(timeline.get("source_clock_frames",-1)) and bool(contracts) and physical==max(contracts))
    proposed_contract=(bool(migration) and migration.get("kind","frame_count")=="frame_count" and
                       physical==int(timeline.get("workspace_clock_frames",-1)) and bool(contracts) and
                       physical==max(contracts) and int(migration.get("new_clock_frames",-1))==physical)
    if migration and migration.get("kind","frame_count")=="frame_count" and actual_contract and timing_ok:
        # Only the manifest is rewritten. Back up both user document and manifest
        # first, and retain a local receipt proving the edited document hash.
        stamp=datetime.now().strftime("%Y%m%dT%H%M%S%f")
        backup=ws/"backups"/f"contract_reconcile_{stamp}"; backup.mkdir(parents=True,exist_ok=False)
        shutil.copy2(wb,backup/"workbench.aseprite"); shutil.copy2(manifest_path,backup/"workbench.json")
        receipt={"schema":"custodian.operator_workbench_contract_reconcile.v1","document_sha256":m.file_sha256(wb),"document_frames":physical,"document_durations":durations,"old_timeline":timeline,"obsolete_pending_migration":migration,"backup_manifest":str(backup/"workbench.json"),"backup_document":str(backup/"workbench.aseprite")}
        recovery=ws/"recovery"; recovery.mkdir(parents=True,exist_ok=True)
        (recovery/f"contract_reconcile_{stamp}.json").write_text(json.dumps(receipt,indent=2)+"\n",encoding="utf-8")
        data["timeline"]["workspace_clock_frames"]=physical
        data["timeline"]["document_frames"]=physical
        data["timeline"]["frames"]=physical
        data["pending_migration"]=None
        save(manifest_path,data)
        return data
    expected_frames=int(timeline.get("document_frames",0))
    if physical!=expected_frames or not timing_ok or (migration and not actual_contract and not proposed_contract):
        pending=f"; pending migration proposes {migration.get('new_clock_frames')} frames" if migration else ""
        raise m.WorkbenchError(
            "SAVED ASEPRITE FRAME CONTRACT MISMATCH\n"
            f"physical document: {physical} frames; manifest document: {expected_frames}; "
            f"source clock: {timeline.get('source_clock_frames')}; workspace clock: {timeline.get('workspace_clock_frames')}; "
            f"binding contracts: {contracts}; uniform manifest timing: {'yes' if timing_ok else 'no'}{pending}. "
            "Saved document bytes were preserved; use the explicit frame migration flow."
        )
    return data

def export_preview(manifest, aseprite=None):
    """Export saved workbench pixels into ignored review cache only."""
    manifest=Path(manifest); data=load(manifest); ws=manifest.parent
    stamp="preview_"+m.file_sha256(ws/"workbench.aseprite")[:16]
    normalized=ws/"exports"/stamp/"normalized"
    if normalized.exists(): return normalized
    data["export_stamp"]=stamp; save(manifest,data)
    aseprite_run(resolve_aseprite(aseprite,True),manifest,"export")
    normalized.mkdir(parents=True,exist_ok=True)
    for binding in data.get("layers",[]):
        raw=ws/"exports"/stamp/"raw"/f"{binding['binding_id']}.png"
        m.extract_binding(raw,binding,data["canvas"],normalized/f"{binding['binding_id']}.png")
    return normalized

def ensure(profile,action,direction,group="",weapon="",linked_profile="",root=DEFAULT_ROOT,aseprite=None):
    plan=m.build_plan(profile,action,direction,group,weapon,linked_profile); ws=workspace(root,plan["identity"]); mf=ws/"workbench.json"; wb=ws/"workbench.aseprite"
    if mf.exists() and wb.exists():
        old=load(mf); m.assert_context(old,plan); old=reconcile_saved_document_contract(old,mf,aseprite); st=state(old,wb)
        existing_ids={b.get("binding_id") for b in old.get("layers",()) if not b.get("adopted_from_saved_layer")}
        fresh_ids={b.get("binding_id") for b in plan.get("layers",())}
        if fresh_ids-existing_ids and st=="CLEAN":
            # Reassemble a clean document when canonical membership grows.
            # Edited documents remain intact so unbound saved vfx can be adopted.
            return refresh(profile,action,direction,group,weapon,linked_profile,root,aseprite,False)
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

def canvas_migrate(profile,action,direction,width,height,scope="animation",group="",weapon="",linked_profile="",root=DEFAULT_ROOT,aseprite=None,dry_run=False):
    requested=m.build_plan(profile,action,direction,group,weapon,linked_profile); ws=workspace(root,requested["identity"]); mf=ws/"workbench.json"; wb=ws/"workbench.aseprite"
    if not mf.exists() or not wb.exists(): raise m.WorkbenchError("workbench absent; run operator anim edit first")
    data=load(mf); m.assert_context(data,requested)
    if "STALE" in state(data,wb): raise m.WorkbenchError("WORKBENCH STALE")
    if data.get("pending_migration"): raise m.WorkbenchError("WORKBENCH HAS PENDING CONTRACT MIGRATION")
    try: report=fc.canvas_migration_report(data,int(width),int(height),scope,m.REPO_ROOT)
    except ValueError as error: raise m.WorkbenchError(str(error)) from error
    if dry_run: return report
    if report["dependency_audit"]["level"]!="GREEN": raise m.WorkbenchError("CANVAS MIGRATION BLOCKED BY PIXEL-COORDINATE AUTHORITY\n"+json.dumps(report["dependency_audit"],indent=2))
    stamp=datetime.now().strftime("%Y%m%dT%H%M%S"); backup=ws/"backups"/f"canvas_{stamp}"; backup.mkdir(parents=True,exist_ok=True); shutil.copy2(wb,backup/"workbench.aseprite"); shutil.copy2(mf,backup/"workbench.json")
    data["export_stamp"]=f"canvas_migration_{stamp}"; save(mf,data); aseprite_run(resolve_aseprite(aseprite,True),mf,"export")
    raw=ws/"exports"/data["export_stamp"] / "raw"; staging=ws/"migrations"/stamp; affected=set(report["affected_bindings"])
    try:
        for binding in data["layers"]:
            current=staging/"current"/f"{binding['binding_id']}.png"; m.extract_binding(raw/f"{binding['binding_id']}.png",binding,data["canvas"],current)
            target=staging/"target"/f"{binding['binding_id']}.png"
            if binding["binding_id"] in affected:
                old=list(binding["workspace_contract"]["frame_size"]); new=[int(width),int(height)]
                fc.transform_canvas_strip(current,target,binding["workspace_contract"]["frames"],old,new,binding["binding_id"])
                binding["frame_size"]=new; binding["workspace_contract"]["frame_size"]=new
                binding["publish_contract"]["frame_size"]=new
                key=m.SCHEMA.OperatorAssetKey(binding["owner"],binding["layer"],binding["profile"],binding["group"],binding["action"],binding["direction"],binding["workspace_contract"]["frames"],*new)
                binding["publish_contract"]["path"]=m.rel(m.CUSTODIAN_ROOT/m.SCHEMA.canonical_source_path(key))
            else: shutil.copy2(current,target)
            binding["input_path"]=str(target.resolve())
        for binding in data.get("layers",[]):
            binding["workspace_contract"]["placement"]=report["placements"][binding["binding_id"]]; binding["placement"]=report["placements"][binding["binding_id"]]
        for reference in data.get("references",[]): reference["placement"]=report["placements"][reference["binding_id"]]
        data["canvas"]={"width":report["new_document_size"][0],"height":report["new_document_size"][1]}
        # Keep a clean reference composite in the new document geometry.
        frames=int(data["timeline"]["document_frames"]); cw,ch=data["canvas"]["width"],data["canvas"]["height"]
        composite=Image.new("RGBA",(cw*frames,ch))
        for binding in data["layers"]:
            with Image.open(binding["input_path"]) as opened:
                strip=opened.convert("RGBA"); fw,fh=binding["frame_size"]; x,y=binding["placement"]
                for index in range(min(frames,binding["workspace_contract"]["frames"])):
                    composite.alpha_composite(strip.crop((index*fw,0,(index+1)*fw,fh)),(index*cw+x,y))
        baseline=ws/"baseline"; baseline.mkdir(parents=True,exist_ok=True); composite.save(baseline/"reference_composite.png")
        report["layer_changes"]=[{**change,"new_placement":report["placements"][change["binding_id"]]} for change in report["layer_changes"]]
        data["pending_migration"]=report; save(mf,data); aseprite_run(resolve_aseprite(aseprite,True),mf,"assemble"); data["aseprite"]["last_synced_sha256"]=m.file_sha256(wb); save(mf,data)
    except Exception:
        shutil.copy2(backup/"workbench.aseprite",wb); shutil.copy2(backup/"workbench.json",mf); raise
    return report

def _validation_commands(data,full_validate=False):
    cmds=[["python3",str(m.CUSTODIAN_ROOT/"tools/validation/operator_animation_contract_report.py")],["python3",str(m.CUSTODIAN_ROOT/"tools/validation/operator_animation_workbench_smoke.py")],["godot","--headless","--path",str(m.CUSTODIAN_ROOT),"--script","res://tools/validation/operator_modular_layers_smoke.gd"]]
    if data["identity"]["profile"]=="melee_1h" and data["identity"]["group"]=="posture": cmds.append(["godot","--headless","--path",str(m.CUSTODIAN_ROOT),"--script","res://tools/validation/operator_melee_posture_smoke.gd"])
    if data.get("context",{}).get("weapon_id")=="vigil_pattern_dagger": cmds.append(["godot","--headless","--path",str(m.CUSTODIAN_ROOT),"--script","res://tools/validation/operator_vigil_dagger_smoke.gd"])
    if full_validate: cmds.append(["python3",str(m.CUSTODIAN_ROOT/"tools/validation/run_validation.py"),"--changed","--json"])
    return cmds

def _journal_stage(path,journal,state,stage):
    journal["state"]=state
    if stage and stage not in journal["validation_stages_completed"]: journal["validation_stages_completed"].append(stage)
    save(path,journal)

def _godot_import():
    preflight=m.CUSTODIAN_ROOT/"tools/pipelines/godot_import_preflight.py"
    subprocess.run(["python3",str(preflight),"--project-dir",str(m.CUSTODIAN_ROOT)],check=True)
    subprocess.run(["godot","--headless","--path",str(m.CUSTODIAN_ROOT),"--import","--quit"],check=True)

def _catalog_build():
    subprocess.run(["godot","--headless","--path",str(m.CUSTODIAN_ROOT),"--script","res://tools/pipelines/build_operator_runtime_frames.gd"],check=True)

def _operator_scene_consistency():
    subprocess.run(["godot","--headless","--path",str(m.CUSTODIAN_ROOT),"--script","res://tools/validation/operator_modular_layers_smoke.gd"],check=True)

## Counterpart promotion is opt-in and is also presented explicitly in UI review.
def publish(manifest, aseprite=None, force_stale=False, dry_run=False,full_validate=False,requested=None,mirror_counterpart=False):
    ws=manifest.parent; data=load(manifest)
    if data.get("creation", {}).get("art_generation", "legacy_96") == "operator_2_5d_128":
        raise m.WorkbenchError("2.5D runtime publication is disabled in guided ingress")
    data=reconcile_saved_document_contract(data,manifest,aseprite); st=state(data,ws/"workbench.aseprite")
    if requested: m.assert_context(data,requested)
    if data.get("creation") and st != "NEW / READY TO PUBLISH":
        raise m.WorkbenchError("NEW ANIMATION IS NOT READY TO PUBLISH\nSave authored pixels in Aseprite, then retry.")
    pending=[path for path in sorted((ws/"transactions").glob("*/transaction.json")) if path.is_file()]
    for journal_path in reversed(pending):
        try: previous=json.loads(journal_path.read_text(encoding="utf-8"))
        except (OSError,json.JSONDecodeError): raise m.WorkbenchError(f"WORKBENCH RECOVERY REQUIRED\nunreadable transaction journal: {journal_path}")
        if previous.get("state")=="RECOVERY_REQUIRED":
            raise m.WorkbenchError(f"WORKBENCH RECOVERY REQUIRED\nresolve transaction journal before publishing: {journal_path}")
    freshness=source_contract_freshness(data)
    if freshness and not force_stale:
        details="\n".join(f"- {identity}: {reason}" for identity,reason in freshness.items())
        raise m.WorkbenchError("WORKBENCH REBASE/REFRESH REQUIRED\n"+details+"\nRefresh the selected Workbench before export or canonical source mutation.")
    if "STALE" in st and not force_stale: raise m.WorkbenchError(f"WORKBENCH REBASE/REFRESH REQUIRED\n{st}; refresh the selected Workbench before export or canonical source mutation")
    stamp=datetime.now().strftime("%Y%m%dT%H%M%S"); data["export_stamp"]=stamp; save(manifest,data); aseprite_run(resolve_aseprite(aseprite,True),manifest,"export")
    counterpart=horizontal_counterpart(data["identity"]["direction"])
    if mirror_counterpart and counterpart is None:
        raise m.WorkbenchError(f"no mirrored counterpart for direction: {data['identity']['direction']}")
    counterpart_index=m.source_index() if mirror_counterpart else {}
    migration=data.get("pending_migration"); normalized=ws/"exports"/stamp/"normalized"; candidates=[]
    for b in data["layers"]:
        if data.get("creation"):
            identity=data["identity"]
            key=m.SCHEMA.OperatorAssetKey("operator",b["layer"],identity["profile"],identity["group"],identity["action"],identity["direction"],int(b["publish_contract"]["frames"]),*map(int,b["publish_contract"]["frame_size"]))
            canonical=(Path("custodian")/m.SCHEMA.canonical_source_path(key)).as_posix()
            runtime=(Path("custodian")/m.SCHEMA.canonical_runtime_path(key)).as_posix()
            contract=b.get("source_contract",{})
            if (b.get("source_path")!=canonical or contract.get("path")!=canonical
                    or b.get("runtime_path")!=runtime or b.get("publish_contract",{}).get("path")!=canonical
                    or contract.get("operation")!="CREATE" or contract.get("file_sha256") or contract.get("pixel_sha256")):
                raise m.WorkbenchError(f"NEW ANIMATION CREATE CONTRACT IS INVALID: {b.get('binding_id')}")
        out=normalized/f"{b['binding_id']}.png"; m.extract_binding(ws/"exports"/stamp/"raw"/f"{b['binding_id']}.png",b,data["canvas"],out)
        if data.get("creation"):
            with Image.open(out) as authored:
                if authored.getchannel("A").getbbox() is None:
                    raise m.WorkbenchError(f"new animation layer has no authored pixels: {b['binding_id']}")
        contract=b.get("source_contract",{}); operation=contract.get("operation")
        target=m.REPO_ROOT/b["publish_contract"]["path"]; old=m.REPO_ROOT/contract.get("path",b["source_path"])
        if b.get("adopted_from_saved_layer"):
            semantic=b.get("semantic_identity",{}); identity=data.get("identity",{})
            expected={"owner":"operator","layer":"fx","profile":identity.get("profile"),"group":identity.get("group"),"action":identity.get("action"),"direction":identity.get("direction")}
            if any(semantic.get(key)!=value or b.get(key)!=value for key,value in expected.items()):
                raise m.WorkbenchError("adopted FX semantic identity no longer matches selected Workbench")
            if b.get("aseprite_layer_name") not in {"vfx","fx"}:
                raise m.WorkbenchError("adopted FX editor-layer authority is invalid")
            key=m.SCHEMA.OperatorAssetKey("operator","fx",identity["profile"],identity["group"],identity["action"],identity["direction"],int(b["publish_contract"]["frames"]),*map(int,b["publish_contract"]["frame_size"]))
            canonical=(Path("custodian")/m.SCHEMA.canonical_source_path(key)).as_posix()
            if b["publish_contract"].get("path")!=canonical or contract.get("path")!=canonical:
                raise m.WorkbenchError("adopted FX publication target is not schema-derived")
            if operation not in {"CREATE","REPLACE"}:
                raise m.WorkbenchError("adopted FX binding is missing its CREATE/REPLACE source contract")
            if operation=="CREATE" and (contract.get("file_sha256") or contract.get("pixel_sha256")):
                raise m.WorkbenchError("CREATE source contract must not fabricate prior source hashes")
            if operation=="REPLACE" and not contract.get("file_sha256"):
                raise m.WorkbenchError("REPLACE source contract is missing its baseline hash")
        existed=operation!="CREATE"
        candidates.append({"binding":b,"candidate":out,"target":target,"old":old,"mirror":False,"existed":existed,
                           "expected_old_sha256":contract.get("file_sha256") if existed else None})
        if mirror_counterpart:
            mirrored=normalized/f"mirror__{b['binding_id']}.png"
            mirror_strip_frames(out,mirrored,b["workspace_contract"]["frames"],b["frame_size"])
            target=_counterpart_target(b,counterpart)
            sid=(b["owner"],b["layer"],b["profile"],b["group"],b["action"],counterpart)
            existing=counterpart_index.get(sid)
            old=existing[0] if existing else target
            candidates.append({"binding":b,"candidate":mirrored,"target":target,"old":old,"mirror":True,"existed":existing is not None,
                               "expected_old_sha256":m.file_sha256(old) if existing is not None else None})
    if dry_run: return [str(x["target"]) for x in candidates]
    review=data.get("publish_review")
    if review:
        expected=review.get("target_hashes",{})
        for item in candidates:
            relative=m.rel(item["target"]); actual=m.file_sha256(item["target"]) if item["target"].is_file() else None
            if relative not in expected or expected[relative]!=actual:
                raise m.WorkbenchError(f"publish target changed after preview; reopen the publish review: {relative}")
    if migration:
        affected=[b for b in data["layers"] if b["binding_id"] in migration["affected_bindings"]]
        current_audit=(fc.audit_canvas_dependencies(m.REPO_ROOT,data,affected) if migration.get("kind")=="frame_canvas" else fc.audit_dependencies(m.REPO_ROOT,data,affected))
        if current_audit["level"]!="GREEN":
            authority="PIXEL-COORDINATE" if migration.get("kind")=="frame_canvas" else "GAMEPLAY FRAME"
            raise m.WorkbenchError(f"{migration.get('kind','frame_count').upper()} MIGRATION BLOCKED BY {authority} AUTHORITY\n"+json.dumps(current_audit,indent=2))
    for item in candidates:
        b,c,dst,old=item["binding"],item["candidate"],item["target"],item["old"]
        if data.get("creation"):
            if item["mirror"]:
                mirrored_key=m.SCHEMA.parse_filename(dst.name)
                runtime=Path(m.REPO_ROOT)/"custodian"/m.SCHEMA.canonical_runtime_path(mirrored_key)
            else:
                runtime=Path(m.REPO_ROOT)/b["runtime_path"]
            runtime_import=Path(str(runtime)+".import")
            runtime_timing=m.BUILDER.timing_sidecar_path(runtime)
            source_timing=m.BUILDER.timing_sidecar_path(dst)
            if not item["existed"] and (runtime.exists() or runtime_import.exists() or runtime_timing.exists() or source_timing.exists()):
                raise m.WorkbenchError(f"new animation runtime CREATE target appeared after preview: {runtime}")
        if (not item["existed"] and dst.exists()) or (dst!=old and dst.exists()):
            raise m.WorkbenchError(f"target frame contract already exists or changed after preview: {dst}")
        if item["existed"] and not old.is_file(): raise m.WorkbenchError(f"REPLACE source disappeared before publish: {old}")
    tx=ws/"transactions"/stamp; backup=tx/"backups"; source_backup=backup/"sources"; resource_backup=backup/"resources"; source_backup.mkdir(parents=True,exist_ok=True); resource_backup.mkdir(parents=True,exist_ok=True)
    journal_path=tx/"transaction.json"
    journal={"transaction_id":stamp,"state":"PREPARED","sources":[],"resources":[],"pending_migration":migration,"validation_stages_completed":[],"import_metadata_preimages":[],"restored_import_metadata":[],"unresolved_paths":[],"primary_failure":None,"recovery_failure":None,"mirror_promotion":{"enabled":bool(mirror_counterpart),"source_direction":data["identity"]["direction"],"target_direction":counterpart if mirror_counterpart else None,"bindings":[b["binding_id"] for b in data["layers"]] if mirror_counterpart else []}}
    for item in candidates:
        b,c,dst,old=item["binding"],item["candidate"],item["target"],item["old"]
        prefix="mirror__" if item["mirror"] else ""
        saved=source_backup/f"{prefix}{b['binding_id']}.png"
        if item["existed"]: shutil.copy2(old,saved)
        sidecar=old.with_suffix(old.suffix+".import")
        saved_sidecar=source_backup/f"{prefix}{b['binding_id']}.png.import"
        if sidecar.exists(): shutil.copy2(sidecar,saved_sidecar)
        timing=m.BUILDER.timing_sidecar_path(old); saved_timing=source_backup/f"{prefix}{b['binding_id']}.animation.json"
        if timing.exists(): shutil.copy2(timing,saved_timing)
        source_record={"binding_id":b["binding_id"],"mirror":item["mirror"],"operation":"REPLACE" if item["existed"] else "CREATE","old_path":m.rel(old),"old_sha256":m.file_sha256(old) if item["existed"] else None,"expected_old_sha256":item.get("expected_old_sha256"),"target_path":m.rel(dst),"target_sha256":m.file_sha256(c),"backup_path":m.rel(saved) if saved.exists() else "","import_backup_path":m.rel(saved_sidecar) if saved_sidecar.exists() else "","timing_backup_path":m.rel(saved_timing) if saved_timing.exists() else "","created_by_transaction":False,"swapped_by_transaction":False}
        journal["sources"].append(source_record); item["journal_source"]=source_record
    for resource_index,resource in enumerate(GENERATED_OPERATOR_RESOURCES):
        saved=resource_backup/f"{resource_index:03d}_{resource.name}"
        shutil.copy2(resource,saved)
        journal["resources"].append({"path":m.rel(resource),"old_sha256":m.file_sha256(resource),"target_sha256":None,"backup_path":str(saved)})
    saved_document=ws/"workbench.aseprite"
    document_preimage=m.file_sha256(saved_document) if saved_document.is_file() else None
    journal["saved_document_path"]=str(saved_document)
    journal["saved_document_sha256"]=document_preimage
    journal["import_metadata_preimages"]=_git_metadata_preimages(m.REPO_ROOT,backup/"import-metadata")
    journal["initial_git_paths"]=sorted(_git_changed_paths(m.REPO_ROOT) or [])
    if journal["initial_git_paths"]:
        raise m.WorkbenchError("PUBLISH BLOCKED BEFORE SOURCE MUTATION\npre-existing Git changes: "+", ".join(journal["initial_git_paths"]))
    save(journal_path,journal)
    current_stage="source_swap"
    try:
        for item in candidates:
            b,c,dst,old=item["binding"],item["candidate"],item["target"],item["old"]
            dst.parent.mkdir(parents=True,exist_ok=True); tmp=dst.with_suffix(".png.workbench.tmp"); shutil.copy2(c,tmp)
            if item["existed"]:
                expected=item.get("expected_old_sha256")
                backup_path=source_backup/f"{('mirror__' if item['mirror'] else '')}{b['binding_id']}.png"
                current=m.file_sha256(old) if old.is_file() else None
                backup_hash=m.file_sha256(backup_path) if backup_path.is_file() else None
                if not expected or current!=expected or backup_hash!=expected:
                    tmp.unlink(missing_ok=True)
                    raise m.WorkbenchError(f"REPLACE source changed after adoption; refusing overwrite: {old}")
            if dst!=old:
                old.unlink()
                item["old_removed"]=True
                old.with_suffix(old.suffix+".import").unlink(missing_ok=True)
                m.BUILDER.timing_sidecar_path(old).unlink(missing_ok=True)
            if not item["existed"]:
                try: os.link(tmp,dst)
                except FileExistsError as error: raise m.WorkbenchError(f"CREATE target appeared during publish; refusing overwrite: {dst}") from error
                finally: tmp.unlink(missing_ok=True)
            else: os.replace(tmp,dst)
            item["swapped"]=True
            item["journal_source"]["swapped_by_transaction"]=True
            if item["journal_source"]["operation"]=="CREATE": item["journal_source"]["created_by_transaction"]=True
            save(journal_path,journal)
        timing_payload=m.timing_payload_from_timeline(data["timeline"])
        if timing_payload is not None:
            clock=next(b for b in data["layers"] if b["layer"]==data["timeline"]["clock_owner"])
            for item in candidates:
                if item["binding"] is clock:
                    timing_path=m.BUILDER.timing_sidecar_path(item["target"])
                    timing_path.write_text(json.dumps(timing_payload,indent=2)+"\n",encoding="utf-8")
        _journal_stage(journal_path,journal,"SOURCE_SWAPPED","source_swap")
        current_stage="runtime_build"
        subprocess.run(["python3",str(m.PIPELINES/"sync_operator_runtime_assets.py"),"--strict","--remove-superseded"],check=True,cwd=m.REPO_ROOT)
        _journal_stage(journal_path,journal,"RUNTIME_BUILT","runtime_build")
        current_stage="godot_import"
        journal["import_window_before_paths"]=sorted(_git_changed_paths(m.REPO_ROOT) or [])
        save(journal_path,journal)
        _godot_import(); _journal_stage(journal_path,journal,"GODOT_IMPORTED","godot_import")
        journal["import_window_after_paths"]=sorted(_git_changed_paths(m.REPO_ROOT) or [])
        changed_in_import=set(journal["import_window_after_paths"])-set(journal["import_window_before_paths"])
        metadata_paths={item["path"] for item in journal["import_metadata_preimages"]}
        protected=set()
        for item in journal["sources"]:
            for key in ("target_path","old_path"):
                relative=Path(item[key]).as_posix()
                protected.update({relative,relative+".import",str(Path(relative).with_suffix(".animation.json"))})
                if "/source/animations/" in relative:
                    runtime=relative.replace("/source/animations/","/runtime/animations/",1)
                    protected.update({runtime,runtime+".import",str(Path(runtime).with_suffix(".animation.json"))})
        protected|={item["path"] for item in journal["resources"]}
        unexpected_import=sorted(path for path in changed_in_import if path not in metadata_paths and path not in protected)
        if unexpected_import:
            journal["unresolved_paths"].extend(unexpected_import)
            raise m.WorkbenchError("IMPORT RECOVERY REQUIRED\nGodot import changed unexpected non-metadata paths: "+", ".join(unexpected_import))
        current_stage="catalog_resource_generation"
        _catalog_build()
        for item in journal["resources"]: item["target_sha256"]=m.file_sha256(m.REPO_ROOT/item["path"])
        _journal_stage(journal_path,journal,"RESOURCES_BUILT","catalog_resource_generation")
        current_stage="mandatory_validation"
        for cmd in _validation_commands(data,full_validate):
            subprocess.run(cmd,check=True,cwd=m.REPO_ROOT)
            _journal_stage(journal_path,journal,journal["state"],"validation:"+Path(cmd[-1]).name)
        current_stage="import_metadata_restore"
        metadata_errors=_restore_import_metadata(journal,m.REPO_ROOT,protected)
        journal["restored_import_metadata"]=[item["path"] for item in journal["import_metadata_preimages"] if item.get("restored")]
        if metadata_errors:
            journal["unresolved_paths"].extend(metadata_errors)
            raise m.WorkbenchError("IMPORT METADATA RECOVERY REQUIRED\n"+"\n".join(metadata_errors))
        _journal_stage(journal_path,journal,"VALIDATED","mandatory_validation")
    except Exception as primary_error:
        journal["primary_failure"]=_failure_record(primary_error,current_stage)
        save(journal_path,journal)
        try:
            for item in candidates:
                b,dst,old=item["binding"],item["target"],item["old"]
                target_removed=False
                source_record=item.get("journal_source",{})
                if item.get("swapped") and dst.exists():
                    if m.file_sha256(dst)==source_record.get("target_sha256"):
                        dst.unlink(); target_removed=True
                    else:
                        journal["unresolved_paths"].append(m.rel(dst))
                if target_removed:
                    dst.with_suffix(dst.suffix+".import").unlink(missing_ok=True)
                    m.BUILDER.timing_sidecar_path(dst).unlink(missing_ok=True)
                prefix="mirror__" if item["mirror"] else ""
                saved=source_backup/f"{prefix}{b['binding_id']}.png"
                restore_old=item.get("old_removed") or (target_removed and dst==old)
                restored_old=False
                if restore_old and saved.exists():
                    try:
                        _restore_source_backup_without_overwrite(saved,old); restored_old=True
                    except m.WorkbenchError:
                        journal["unresolved_paths"].append(m.rel(old))
                side=source_backup/f"{prefix}{b['binding_id']}.png.import"
                if restored_old and side.exists(): shutil.copy2(side,old.with_suffix(old.suffix+".import"))
                if restored_old:
                    old_timing=m.BUILDER.timing_sidecar_path(old); old_timing.unlink(missing_ok=True)
                    timing=source_backup/f"{prefix}{b['binding_id']}.animation.json"
                    if timing.exists(): shutil.copy2(timing,old_timing)
            for resource_index,resource in enumerate(GENERATED_OPERATOR_RESOURCES):
                shutil.copy2(resource_backup/f"{resource_index:03d}_{resource.name}",resource)
            subprocess.run(["python3",str(m.PIPELINES/"sync_operator_runtime_assets.py"),"--strict","--remove-superseded"],check=True,cwd=m.REPO_ROOT)
            _godot_import(); _catalog_build(); _operator_scene_consistency()
            recovery_errors=_restore_import_metadata(journal,m.REPO_ROOT)
            if recovery_errors:
                journal["recovery_failure"]={"stage":"rollback_consistency","message":"; ".join(recovery_errors)}
                journal["unresolved_paths"].extend(recovery_errors)
                journal["state"]="RECOVERY_REQUIRED"
            else:
                unresolved=_verify_rollback_preimages(journal,m.REPO_ROOT,saved_document,document_preimage)
                if unresolved:
                    journal["state"]="RECOVERY_REQUIRED"
                    journal["unresolved_paths"]=sorted(set(journal.get("unresolved_paths",[]))|set(unresolved))
                    journal["recovery_failure"]={"stage":"rollback_preimage_verification","message":"rollback did not prove all transaction preimages"}
                else:
                    _journal_stage(journal_path,journal,"ROLLED_BACK","rollback_consistency")
        except Exception as recovery_error:
            journal["state"]="RECOVERY_REQUIRED"
            journal["recovery_failure"]=_failure_record(recovery_error,"rollback_consistency")
            changed=_git_changed_paths(m.REPO_ROOT) or set()
            journal["unresolved_paths"]=sorted(set(journal.get("unresolved_paths",[]))|changed)
        save(journal_path,journal)
        message=f"WORKBENCH PUBLISH FAILED at {current_stage}\n{primary_error}"
        if journal.get("recovery_failure"):
            message+="\nRECOVERY FAILED: "+str(journal["recovery_failure"].get("message","unknown recovery error"))
            message+="\nUnresolved paths: "+", ".join(journal.get("unresolved_paths",[]))
        raise m.WorkbenchError(message) from primary_error
    for item in candidates:
        if item["mirror"]: continue
        b,dst=item["binding"],item["target"]
        b["source_path"]=m.rel(dst); b["source_file_sha256"]=m.file_sha256(dst); b["source_pixel_sha256"]=m.pixel_sha256(dst); b["source_contract"]={"path":m.rel(dst),"frames":b["workspace_contract"]["frames"],"frame_size":b["frame_size"],"file_sha256":b["source_file_sha256"],"pixel_sha256":b["source_pixel_sha256"]}; b["publish_contract"]={"path":m.rel(dst),"frames":b["frames"],"frame_size":b["frame_size"]}; b.pop("adopted_from_saved_layer",None)
    data.pop("publish_review",None); data.pop("creation",None); data["timeline"]["source_clock_frames"]=data["timeline"]["workspace_clock_frames"]; data["pending_migration"]=None; _baseline(data,ws); data["aseprite"]["last_synced_sha256"]=m.file_sha256(ws/"workbench.aseprite"); data["last_publish"]={"timestamp":datetime.now(timezone.utc).isoformat(),"validation_status":"passed"}; _journal_stage(journal_path,journal,"COMMITTED","manifest_sync"); save(manifest,data); return [str(x["target"]) for x in candidates]
