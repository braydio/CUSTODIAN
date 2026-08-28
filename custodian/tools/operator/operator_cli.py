#!/usr/bin/env python3
import argparse,json,subprocess,sys
from pathlib import Path
import animation_workbench_model as m
import animation_workbench as w

def common(p,identity=True,dry_run=False):
    if identity: p.add_argument("profile"); p.add_argument("action"); p.add_argument("direction")
    p.add_argument("--group",default=""); p.add_argument("--weapon",default=""); p.add_argument("--linked-profile",default=""); p.add_argument("--aseprite",type=Path); p.add_argument("--workspace-root",type=Path,default=w.DEFAULT_ROOT); p.add_argument("--json",action="store_true")
    if dry_run: p.add_argument("--dry-run",action="store_true")
def main():
    ap=argparse.ArgumentParser(prog="operator"); a=ap.add_subparsers(dest="area",required=True); anim=a.add_parser("anim").add_subparsers(dest="cmd",required=True)
    lp=anim.add_parser("list"); lp.add_argument("profile"); lp.add_argument("--group",default=""); lp.add_argument("--json",action="store_true")
    for name in ("status","edit","refresh"): common(anim.add_parser(name))
    common(anim.add_parser("publish"),dry_run=True)
    frame=anim.add_parser("frame").add_subparsers(dest="frame_cmd",required=True)
    add=frame.add_parser("add"); common(add,dry_run=True); add.add_argument("--after",type=int,required=True); add.add_argument("--fill",choices=("duplicate-prev","duplicate-next","blank"),default="duplicate-prev"); add.add_argument("--layers",default="auto")
    remove=frame.add_parser("remove"); common(remove,dry_run=True); remove.add_argument("--frame",type=int,required=True); remove.add_argument("--layers",default="auto")
    anim.choices["edit"].add_argument("--no-open",action="store_true"); anim.choices["refresh"].add_argument("--discard-edits",action="store_true"); anim.choices["publish"].add_argument("--force-stale-source",action="store_true"); anim.choices["publish"].add_argument("--full-validate",action="store_true")
    x=ap.parse_args()
    try:
        if x.cmd=="list":
            idx=m.source_index(); rows={}
            for sid,(p,k) in idx.items():
                if sid[0]=="operator" and sid[2]==x.profile and (not x.group or sid[3]==x.group): rows.setdefault((sid[3],sid[4]),[]).append({"direction":sid[5],"layer":sid[1],"frames":k.frames,"frame_size":[k.frame_width,k.frame_height]})
            out=[{"group":k[0],"action":k[1],"assets":v} for k,v in sorted(rows.items())]
        elif x.cmd=="frame":
            operation=x.frame_cmd; position=x.after if operation=="add" else x.frame
            out=w.frame_migrate(x.profile,x.action,x.direction,operation,position,getattr(x,"fill","duplicate-prev"),x.layers,x.group,x.weapon,x.linked_profile,x.workspace_root,x.aseprite,x.dry_run)
        else:
            plan=m.build_plan(x.profile,x.action,x.direction,x.group,x.weapon,x.linked_profile); ws=w.workspace(x.workspace_root,plan["identity"]); mf=ws/"workbench.json"; wb=ws/"workbench.aseprite"
            if x.cmd=="status":
                if mf.exists(): data=w.load(mf); m.assert_context(data,plan); out={**data,"workbench_state":w.state(data,wb),"contract_state":"MIGRATION_PENDING" if data.get("pending_migration") else "NONE","aseprite":str(w.resolve_aseprite(x.aseprite) or "unavailable"),"workspace":str(ws)}
                else: out={**plan,"workbench_state":"ABSENT","contract_state":"NONE","aseprite":str(w.resolve_aseprite(x.aseprite) or "unavailable"),"workspace":str(ws)}
            elif x.cmd=="edit":
                out,ws=w.ensure(x.profile,x.action,x.direction,x.group,x.weapon,x.linked_profile,x.workspace_root,x.aseprite)
                if not x.no_open: subprocess.run([str(w.resolve_aseprite(x.aseprite,True)),str(ws/"workbench.aseprite")],check=True)
            elif x.cmd=="refresh": out,ws=w.refresh(x.profile,x.action,x.direction,x.group,x.weapon,x.linked_profile,x.workspace_root,x.aseprite,x.discard_edits)
            else: out={"changed_sources":w.publish(mf,x.aseprite,x.force_stale_source,x.dry_run,x.full_validate,plan)}
        if getattr(x,"json",False): print(json.dumps(out,indent=2))
        else:
            if x.cmd=="status": print(f"OPERATOR ANIMATION\n{x.profile} / {out['identity']['group']} / {x.action} / {x.direction}\nsource contract: {out['timeline']['source_clock_frames']}f\nworkspace contract: {out['timeline']['workspace_clock_frames']}f\ndocument frames: {out['timeline']['document_frames']}\neditable layers:"); [print(f"  {b['aseprite_layer_name']}\n    source: {b['source_contract']['path']}\n    {b['source_contract']['frames']}f -> {b['publish_contract']['frames']}f {b['frame_size'][0]}x{b['frame_size'][1]}\n    canonical: YES") for b in out['layers']]; print(f"migration: {out['contract_state']}\nworkbench: {out['workbench_state']}\naseprite: {out['aseprite']}")
            elif x.cmd=="list": [print(f"{r['group']}/{r['action']}: {r['assets']}") for r in out]
            else: print(json.dumps(out,indent=2))
    except (m.WorkbenchError,subprocess.CalledProcessError) as e: print(f"operator: {e}",file=sys.stderr); return 2
    return 0
if __name__=="__main__": raise SystemExit(main())
