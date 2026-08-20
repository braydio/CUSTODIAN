#!/usr/bin/env python3
"""Focused V2.1 production-kind, layout, direction, and catalog acceptance."""
from __future__ import annotations
import json,sys,tempfile
from types import SimpleNamespace
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]; ASSETS=ROOT/"tools/assets"
sys.path.insert(0,str(ASSETS))
from asset_catalog import CatalogEntry,asset_catalog_key,load_catalog,save_catalog,update_catalog_entry
from asset_contract import load_all_families,load_family
from asset_inspector import FrameLayout,inspect_png
from asset_plan import generate_plan
from asset_router import load_kind_schemas
from asset_transaction import begin_transaction,rollback_transaction
import asset as asset_cli

def png(path,size):
    path.parent.mkdir(parents=True,exist_ok=True); Image.new("RGBA",size,(31,63,127,255)).save(path)

def main():
    schemas=load_kind_schemas(); assert set(schemas)=={"world_prop","enemy","tile","effect","vehicle","weapon","ui","backdrop"}
    families=load_all_families(); tile=families["void_cliff_face"]; enemy=families["enemy_grunt"]
    with tempfile.TemporaryDirectory() as tmp:
        root=Path(tmp); inbox=root/"asset_drop/inbox/void_cliff_face"
        for sid in tile.states: png(inbox/f"{sid}.png",(32,32))
        plan=generate_plan(tile,inbox,root); assert plan.can_apply and len(plan.outputs)==6
        expected={f"content/tiles/mountain_cliffs/void_fascia/void_cliff_face_{sid}_32.png" for sid in tile.states}
        assert {o.target_relative_path.as_posix() for o in plan.outputs}==expected
        assert all(a.backend=="runtime_ready" and a.inspection.layout==FrameLayout.COPY and a.inspection.frame_count==1 for a in plan.assets)

        asset_cli.FAMILIES_DIR=root/"families"; asset_cli.INBOX_ROOT=root/"inbox"
        for family_id,kind,size,direction in (("test_enemy","enemy","96x96","8dir"),("test_tile","tile","32x32","omni")):
            args=SimpleNamespace(family=family_id,kind=kind,size=size,direction=direction,domain=None,owner=None,auto_mirror=None,force=False)
            assert asset_cli.cmd_new(args,{})==0
            assert load_family(root/"families"/f"{family_id}.asset.json").kind==kind

        einbox=root/"asset_drop/inbox/enemy_grunt"; png(einbox/"fast_01__e.png",(96*5,96))
        eplan=generate_plan(enemy,einbox,root); assert eplan.can_apply and len(eplan.outputs)==2
        assert [(o.key.direction,o.provenance) for o in eplan.outputs]==[("e","authored"),("w","mirrored")]
        assert all("content/sprites/enemies/enemy_grunt/runtime/body/melee/" in o.target_relative_path.as_posix() for o in eplan.outputs)
        # Every authored/mirrored target and the catalog participate in rollback.
        authored_target=root/eplan.outputs[0].target_relative_path; authored_target.parent.mkdir(parents=True,exist_ok=True); authored_target.write_bytes(b"old")
        rollback_plan=generate_plan(enemy,einbox,root)
        record,_=begin_transaction("rollback",root,list(rollback_plan.assets))
        for output in rollback_plan.outputs:
            target=root/output.target_relative_path; target.parent.mkdir(parents=True,exist_ok=True); target.write_bytes(b"new")
        catalog_path=root/"content/metadata/assets/generated/asset_catalog.generated.json"; catalog_path.parent.mkdir(parents=True,exist_ok=True); catalog_path.write_text("changed")
        rollback_transaction(record,root)
        assert authored_target.read_bytes()==b"old"

        png(einbox/"fast_01__w.png",(96*5,96)); both=generate_plan(enemy,einbox,root)
        assert sorted((o.key.direction,o.provenance) for o in both.outputs)==[("e","authored"),("w","authored")]

        png(root/"copy.png",(96,96)); png(root/"horizontal.png",(192,96)); png(root/"vertical.png",(96,384)); png(root/"grid.png",(384,192)); png(root/"ambiguous.png",(192,192))
        assert inspect_png(root/"copy.png",96,96).layout==FrameLayout.COPY
        assert inspect_png(root/"horizontal.png",96,96).layout==FrameLayout.HORIZONTAL_STRIP
        assert inspect_png(root/"vertical.png",96,96).layout==FrameLayout.VERTICAL_STRIP
        assert inspect_png(root/"grid.png",96,96,"grid",4,2).frame_count==8
        assert inspect_png(root/"ambiguous.png",96,96).layout==FrameLayout.AMBIGUOUS

        old=root/"catalog.json"; old.write_text(json.dumps({"schema":"custodian.asset_catalog.v1","families":{"x":{"states":{"idle":{"semantic_identity":["x","enemy","body","locomotion","idle","s"],"path":"p","frames":1,"frame_size":[1,1],"sha256":"h"}}}}}))
        catalog=load_catalog(old); assert catalog["schema"]=="custodian.asset_catalog.v2" and "idle::s" in catalog["families"]["x"]["assets"]
        update_catalog_entry(catalog,"x","idle",CatalogEntry(["x"],"q",1,[1,1],"z","idle","e"),"enemy"); save_catalog(catalog,old)
        assert set(json.loads(old.read_text())["families"]["x"]["assets"])=={"idle::s","idle::e"}
    print("PASS: V2.1 kinds, exact tile routing, directions/mirroring, layouts, catalog migration")
if __name__=="__main__": main()
