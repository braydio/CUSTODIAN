#!/usr/bin/env python3
import argparse,json,subprocess,sys
from pathlib import Path
import animation_workbench_model as m
import animation_workbench as w

def common(p,identity=True):
    if identity: p.add_argument("profile"); p.add_argument("action"); p.add_argument("direction")
    p.add_argument("--group",default=""); p.add_argument("--weapon",default=""); p.add_argument("--linked-profile",default=""); p.add_argument("--aseprite",type=Path); p.add_argument("--workspace-root",type=Path,default=w.DEFAULT_ROOT); p.add_argument("--json",action="store_true"); p.add_argument("--dry-run",action="store_true")
def main():
    ap=argparse.ArgumentParser(prog="operator"); a=ap.add_subparsers(dest="area",required=True); anim=a.add_parser("anim").add_subparsers(dest="cmd",required=True)
    lp=anim.add_parser("list"); lp.add_argument("profile"); lp.add_argument("--group",default=""); lp.add_argument("--json",action="store_true")
    for name in ("status","edit","refresh","publish"): common(anim.add_parser(name))
    anim.choices["edit"].add_argument("--no-open",action="store_true"); anim.choices["refresh"].add_argument("--discard-edits",action="store_true"); anim.choices["publish"].add_argument("--force-stale-source",action="store_true"); anim.choices["publish"].add_argument("--full-validate",action="store_true")
    x=ap.parse_args()
    try:
        if x.cmd=="list":
            idx=m.source_index(); rows={}
            for sid,(p,k) in idx.items():
                if sid[0]=="operator" and sid[2]==x.profile and (not x.group or sid[3]==x.group): rows.setdefault((sid[3],sid[4]),[]).append({"direction":sid[5],"layer":sid[1],"frames":k.frames,"frame_size":[k.frame_width,k.frame_height]})
            out=[{"group":k[0],"action":k[1],"assets":v} for k,v in sorted(rows.items())]
        else:
            plan=m.build_plan(x.profile,x.action,x.direction,x.group,x.weapon,x.linked_profile); ws=w.workspace(x.workspace_root,plan["identity"]); mf=ws/"workbench.json"; wb=ws/"workbench.aseprite"
            if x.cmd=="status": out={**plan,"workbench_state":w.state(w.load(mf),wb) if mf.exists() else "ABSENT","aseprite":str(w.resolve_aseprite(x.aseprite) or "unavailable"),"workspace":str(ws)}
            elif x.cmd=="edit":
                out,ws=w.ensure(x.profile,x.action,x.direction,x.group,x.weapon,x.linked_profile,x.workspace_root,x.aseprite)
                if not x.no_open: subprocess.run([str(w.resolve_aseprite(x.aseprite,True)),str(ws/"workbench.aseprite")],check=True)
            elif x.cmd=="refresh": out,ws=w.refresh(x.profile,x.action,x.direction,x.group,x.weapon,x.linked_profile,x.workspace_root,x.aseprite,x.discard_edits)
            else: out={"changed_sources":w.publish(mf,x.aseprite,x.force_stale_source,x.dry_run)}
        if getattr(x,"json",False): print(json.dumps(out,indent=2))
        else:
            if x.cmd=="status": print(f"OPERATOR ANIMATION\n{x.profile} / {out['identity']['group']} / {x.action} / {x.direction}\ntimeline: {out['timeline']['frames']} frames, common canvas {out['canvas']['width']}x{out['canvas']['height']}\neditable layers:"); [print(f"  {b['aseprite_layer_name']}\n    source: {b['source_path']}\n    {b['frames']}f {b['frame_size'][0]}x{b['frame_size'][1]}\n    canonical: YES") for b in out['layers']]; print(f"workbench: {out['workbench_state']}\naseprite: {out['aseprite']}")
            elif x.cmd=="list": [print(f"{r['group']}/{r['action']}: {r['assets']}") for r in out]
            else: print(json.dumps(out,indent=2))
    except (m.WorkbenchError,subprocess.CalledProcessError) as e: print(f"operator: {e}",file=sys.stderr); return 2
    return 0
if __name__=="__main__": raise SystemExit(main())
