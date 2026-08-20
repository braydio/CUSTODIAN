#!/usr/bin/env python3
"""Production front door for non-Operator CUSTODIAN asset intake."""
from __future__ import annotations
import argparse, hashlib, json, shutil, sys
from pathlib import Path

ASSETS_DIR=Path(__file__).resolve().parent
PROJECT_DIR=ASSETS_DIR.parent.parent
INBOX_ROOT=PROJECT_DIR/"asset_drop/inbox"
FAMILIES_DIR=PROJECT_DIR/"content/metadata/assets/families"
if str(ASSETS_DIR) not in sys.path: sys.path.insert(0,str(ASSETS_DIR))
from asset_catalog import CatalogEntry,file_hash,load_catalog,save_catalog,update_catalog_entry
from asset_contract import SCHEMA_VERSION,load_all_families,parse_family
from asset_doctor import run_doctor
from asset_plan import AssetOperation,generate_plan
from asset_router import load_kind_schemas
from asset_status import get_family_status

def render_plan(plan):
    print(f"\n{plan.family_id.upper()}")
    for error in plan.errors: print(f"  ERROR: {error}")
    for asset in plan.assets:
        print(f"  {asset.source_path.name}: {asset.confidence.value} ({asset.resolution.reason})")
        print(f"    {asset.inspection.width}x{asset.inspection.height}; {asset.inspection.layout.value}; {asset.inspection.frame_count} frame(s); backend {asset.backend}")
        for output in asset.outputs:
            print(f"    {output.provenance} -> {output.target_relative_path} [{output.operation.value}]")
            for superseded in output.superseded_targets:
                print(f"      supersedes: {superseded}")
            for consumer in output.stale_consumers:
                print(f"      BLOCKED stale consumer: {consumer}")
    for warning in plan.warnings: print(f"  WARNING: {warning}")

def cmd_plan(args,families):
    selected=_selected(args.family,families)
    if selected is None:return 2
    bad=False
    for family in selected:
        plan=generate_plan(family,INBOX_ROOT/family.id,PROJECT_DIR,no_mirror=getattr(args,"no_mirror",False)); render_plan(plan); bad|=not plan.can_apply
    return 2 if bad else 0

def cmd_ingest(args,families):
    family=families.get(args.family)
    if not family: print(f"Unknown family: {args.family}"); return 2
    plan=generate_plan(family,INBOX_ROOT/family.id,PROJECT_DIR,no_mirror=getattr(args,"no_mirror",False)); render_plan(plan)
    if not plan.can_apply: print("Plan cannot be applied."); return 2
    if args.dry_run: print("Dry run: no files changed."); return 0
    if not plan.assets: print("No pending intake files."); return 0
    if any(o.operation==AssetOperation.REPLACE for o in plan.outputs) and not args.replace: print("Replacement requires --replace."); return 2
    if plan.post_process:
        print("WARNING: delegated post-process hooks may touch bounded runtime resources outside the PNG plan; Godot cache is not transactional: " + ", ".join(plan.post_process))
    if not args.yes and input("Apply this plan? [y/N] ").strip().lower() not in {"y","yes"}: return 1
    from asset_transaction import begin_transaction,commit_transaction,new_job_id,rollback_transaction
    job_id=new_job_id(); record,staging=begin_transaction(job_id,PROJECT_DIR,list(plan.assets)); results=[]
    try:
        for asset in plan.assets:
            module=__import__(f"adapters.{asset.backend}",fromlist=["stage_asset"])
            result=module.stage_asset(asset,PROJECT_DIR,replace=args.replace,work_dir=staging)
            if not result.ok: raise RuntimeError("; ".join(result.errors))
            results.append(result)
        for output in plan.outputs:
            for superseded in output.superseded_targets:
                old_target=PROJECT_DIR/superseded
                if old_target.is_file(): old_target.unlink()
        catalog=load_catalog(); receipt_assets=[]
        for asset in plan.assets:
            input_hash=hashlib.sha256(asset.source_path.read_bytes()).hexdigest()
            for output in asset.outputs:
                target=PROJECT_DIR/output.target_relative_path
                if not target.is_file(): raise RuntimeError(f"missing declared output: {output.target_relative_path}")
                update_catalog_entry(catalog,family.id,output.state_id,CatalogEntry(list(output.key.semantic_identity),output.target_relative_path.as_posix(),output.key.frames,[output.key.frame_width,output.key.frame_height],file_hash(target),output.state_id,output.key.direction,output.provenance,output.source_asset),family.kind)
                receipt_assets.append({"state_id":output.state_id,"direction":output.key.direction,"semantic_identity":list(output.key.semantic_identity),"path":output.target_relative_path.as_posix(),"provenance":output.provenance,"source_asset":output.source_asset,"sha256":file_hash(target),"operation":output.operation.value,"superseded_paths":[path.as_posix() for path in output.superseded_targets],"backend":asset.backend})
        import_result=None
        if args.godot_import:
            from adapters.godot_import import run_godot_import
            import_result=run_godot_import(PROJECT_DIR)
            if not import_result.ok: raise RuntimeError(import_result.detail)
        save_catalog(catalog)
        archive_root=PROJECT_DIR/"asset_drop/archive"/job_id/family.id
        input_receipts=[]
        for asset in plan.assets:
            archive=archive_root/asset.source_path.name; archive.parent.mkdir(parents=True,exist_ok=True)
            digest=hashlib.sha256(asset.source_path.read_bytes()).hexdigest(); shutil.move(str(asset.source_path),str(archive)); record.archived_inputs[asset.source_path]=archive
            input_receipts.append({"path":asset.source_path.relative_to(PROJECT_DIR).as_posix(),"sha256":digest})
        receipt={"schema":"custodian.asset_ingest_job.v2","job_id":job_id,"timestamp":record.timestamp,"family":family.id,"kind":family.kind,"inputs":input_receipts,"outputs":receipt_assets,"backends":sorted({a.backend for a in plan.assets}),"post_process_hooks":list(plan.post_process),"godot_import":{"attempted":args.godot_import,"ok":import_result.ok if import_result else None},"validation_evidence":[],"result":"success"}
        commit_transaction(record,PROJECT_DIR,receipt); print(f"Ingest complete: {job_id}"); return 0
    except Exception as exc:
        rollback_transaction(record,PROJECT_DIR); print(f"Ingest failed and rolled back: {exc}"); return 2

def cmd_status(args,families):
    selected=_selected(args.family,families)
    if selected is None:return 2
    for family in selected:
        status=get_family_status(family,PROJECT_DIR); print(f"\n{family.id.upper()} — {status.completeness}")
        for sid,item in status.states.items():
            present=", ".join(item.authored_directions+item.mirrored_directions) or "none"
            print(f"  {sid}: present {present}; authored {', '.join(item.authored_directions) or 'none'}; mirrored {', '.join(item.mirrored_directions) or 'none'}; requirement >={item.min_direction_count}; ART_PRESENT {'yes' if item.art_present else 'no'}; IMPORTED {'yes' if item.imported else 'no'}; BOUND {'yes' if item.bound else 'no'}; RUNTIME_VERIFIED {'yes' if item.runtime_verified else 'no'}")
    return 0

def cmd_families(args,families):
    print("Registered families")
    for family in families.values(): print(f"  {family.id} ({family.kind})")
    print("Operator assets: delegated to the specialized Operator pipeline."); return 0

def cmd_new(args,families):
    schemas=load_kind_schemas(); schema=schemas.get(args.kind)
    if not schema: print(f"Unsupported kind (no registered schema): {args.kind}"); return 2
    path=FAMILIES_DIR/f"{args.family}.asset.json"
    if path.exists() and not args.force: print("Family exists; use --force."); return 2
    try:w,h=map(int,(args.size or "32x32").lower().split("x"))
    except ValueError: print("--size must be WxH"); return 2
    defaults=schema.defaults; direction=args.direction or defaults.get("direction","omni")
    auto=defaults.get("auto_mirror",False) if args.auto_mirror is None else args.auto_mirror
    raw={"schema":SCHEMA_VERSION,"id":args.family,"kind":args.kind,"runtime":{"domain":args.domain or defaults.get("domain"),"owner":args.owner or args.family},"canvas":{"width":w,"height":h},"direction_policy":direction,"auto_mirror":auto,"states":{"idle":{"required":True,"layer":defaults.get("layer","body"),"action_group":defaults.get("action_group","display"),"variant":"idle"}},"aliases":{},"consumers":[]}
    try: parse_family(raw)
    except ValueError as exc: print(f"Invalid family request: {exc}"); return 2
    path.parent.mkdir(parents=True,exist_ok=True); path.write_text(json.dumps(raw,indent=2)+"\n",encoding="utf-8"); inbox=INBOX_ROOT/args.family; inbox.mkdir(parents=True,exist_ok=True)
    print(f"Contract: {path}\nInbox: {inbox}\nEdit states or use 'asset request'."); return 0

def cmd_request(args,families):
    family=families.get(args.family)
    if not family: print(f"Unknown family: {args.family}"); return 2
    lines=[family.id.upper(),""]
    for sid,state in family.states.items():
        tag="REQUIRED" if state.required else "RECOMMENDED" if state.recommended else "OPTIONAL"; suffix="" if family.direction_policy=="omni" else "__<direction>"
        fw,fh=family.state_frame_size(state); detail="static" if not state.animation else f"{state.layout}/declared animation"
        lines += [f"{tag} {sid}{suffix}.png",f"  {fw}x{fh} {detail}; minimum directions: {state.min_direction_count}; required: {', '.join(state.required_directions) or 'none'}; auto mirror: {family.auto_mirror}"]
    text="\n".join(lines)+"\n"; print(text)
    if args.write:
        path=INBOX_ROOT/family.id/"README.txt"; path.parent.mkdir(parents=True,exist_ok=True); path.write_text(text,encoding="utf-8"); print(f"Written: {path}")
    return 0

def cmd_doctor(args,families):
    issues=run_doctor(PROJECT_DIR)
    for issue in issues: print(f"{issue.severity.upper()}: {issue.message}")
    if not issues: print("Asset Doctor: healthy")
    return 2 if any(i.severity=="error" for i in issues) else 0

def _selected(name,families):
    if name and name not in families: print(f"Unknown family: {name}"); return None
    return [families[name]] if name else [families[k] for k in sorted(families)]

def main():
    parser=argparse.ArgumentParser(prog="asset"); subs=parser.add_subparsers(dest="command",required=True)
    p=subs.add_parser("plan"); p.add_argument("family",nargs="?"); p.add_argument("--no-mirror",action="store_true")
    p=subs.add_parser("ingest"); p.add_argument("family"); p.add_argument("--yes",action="store_true"); p.add_argument("--dry-run",action="store_true"); p.add_argument("--replace",action="store_true"); p.add_argument("--godot-import",action="store_true"); p.add_argument("--no-mirror",action="store_true")
    p=subs.add_parser("status"); p.add_argument("family",nargs="?")
    subs.add_parser("families")
    p=subs.add_parser("new"); p.add_argument("family"); p.add_argument("--kind",required=True); p.add_argument("--size"); p.add_argument("--direction"); p.add_argument("--domain"); p.add_argument("--owner"); group=p.add_mutually_exclusive_group(); group.add_argument("--auto-mirror",dest="auto_mirror",action="store_true"); group.add_argument("--no-auto-mirror",dest="auto_mirror",action="store_false"); p.set_defaults(auto_mirror=None); p.add_argument("--force",action="store_true")
    p=subs.add_parser("request"); p.add_argument("family"); p.add_argument("--write",action="store_true")
    subs.add_parser("doctor")
    args=parser.parse_args(); families=load_all_families(); return globals()[f"cmd_{args.command}"](args,families)
if __name__=="__main__": raise SystemExit(main())
