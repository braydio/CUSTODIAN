#!/usr/bin/env python3
"""Non-destructive Workbench V2 semantic, pixel, and migration checks."""
import json,os,shutil,subprocess,sys,tempfile
from pathlib import Path
from PIL import Image
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"operator"))
import animation_workbench_model as m
import animation_frame_contract as fc
import animation_workbench as w

def strip(path,n,w=8,h=8):
 im=Image.new("RGBA",(n*w,h))
 for i in range(n): im.paste((10+i,20+i,30+i,255),(i*w,0,(i+1)*w,h))
 path.parent.mkdir(parents=True,exist_ok=True); im.save(path)
def pixels(path,n,w=8):
 with Image.open(path) as im:return [im.crop((i*w,0,(i+1)*w,im.height)).convert("RGBA").tobytes() for i in range(n)]
def key(owner,layer,profile="melee_1h",n=4):return m.SCHEMA.OperatorAssetKey(owner,layer,profile,"posture","idle_relaxed_01","e",n,8,8)
def source(root,k):
 p=root/m.SCHEMA.canonical_source_path(k);strip(p,k.frames);return p

def main():
 with tempfile.TemporaryDirectory() as td:
  root=Path(td); src=root/"4.png"; add=root/"5.png"; back=root/"back.png";strip(src,4); old=pixels(src,4)
  directional=root/"directional.png"; mirrored=root/"mirrored.png"
  image=Image.new("RGBA",(15,2))
  for frame in range(5):
   image.putpixel((frame*3,0),(frame+1,0,0,255));image.putpixel((frame*3+2,1),(0,frame+1,0,255))
  image.save(directional);w.mirror_strip_frames(directional,mirrored,5,[3,2])
  with Image.open(mirrored) as result:
   assert [result.getpixel((frame*3+2,0))[0] for frame in range(5)]==[1,2,3,4,5]
   assert [result.getpixel((frame*3,1))[1] for frame in range(5)]==[1,2,3,4,5]
  assert [(d,w.horizontal_counterpart(d)) for d in ("e","ne","se","w","nw","sw","n","s","omni")]==[("e","w"),("ne","nw"),("se","sw"),("w","e"),("nw","ne"),("sw","se"),("n",None),("s",None),("omni",None)]
  fc.transform_strip(src,add,4,[8,8],"add",2,"duplicate-prev");assert pixels(add,5)==[old[0],old[1],old[1],old[2],old[3]]
  fc.transform_strip(add,back,5,[8,8],"remove",3);assert pixels(back,4)==old
  # Canvas changes translate exact pixels into a centered transparent cell; they
  # never scale or reorder the animation.
  canvas_source=root/"canvas_96.png";canvas_target=root/"canvas_128.png";sheet=Image.new("RGBA",(6*96,96))
  for frame in range(6):
   sheet.putpixel((frame*96+frame+2,10+frame),(frame+10,20,30,255))
   sheet.putpixel((frame*96+50,50),(1,2,3,255))
  sheet.save(canvas_source);fc.transform_canvas_strip(canvas_source,canvas_target,6,[96,96],[128,128],"lower_body")
  with Image.open(canvas_target) as expanded:
   assert expanded.size==(768,128)
   for frame in range(6):
    assert expanded.getpixel((frame*128+frame+18,26+frame))==(frame+10,20,30,255)
    assert expanded.getpixel((frame*128+66,66))==(1,2,3,255)
   assert expanded.getpixel((0,0))==(0,0,0,0)
  for frame in range(6):
   with Image.open(canvas_source) as original,Image.open(canvas_target) as expanded:
    assert original.crop((frame*96,0,(frame+1)*96,96)).tobytes()==expanded.crop((frame*128+16,16,frame*128+112,112)).tobytes()
  shrink_source=root/"shrink_source.png";shrink_target=root/"shrink_target.png";shrinking=Image.new("RGBA",(128,128));shrinking.putpixel((16,16),(9,8,7,255));shrinking.save(shrink_source)
  fc.transform_canvas_strip(shrink_source,shrink_target,1,[128,128],[96,96],"safe")
  with Image.open(shrink_target) as shrunk: assert shrunk.size==(96,96) and shrunk.getpixel((0,0))==(9,8,7,255)
  shrinking.putpixel((0,0),(255,1,1,255));shrinking.save(shrink_source)
  try:fc.transform_canvas_strip(shrink_source,shrink_target,1,[128,128],[96,96],"upper_body");raise AssertionError("visible crop accepted")
  except ValueError as error:assert "layer=upper_body" in str(error) and "frame=1" in str(error) and "bbox=" in str(error)
  raw=root/"raw.png";out=root/"out.png";canvas=Image.new("RGBA",(24,8))
  with Image.open(src) as im:
   for i in range(2):canvas.alpha_composite(im.crop((i*8,0,(i+1)*8,8)),(i*12+2,0))
  canvas.save(raw);b={"binding_id":"x","frames":2,"frame_size":[8,8],"placement":[2,0],"workspace_contract":{"frames":2,"frame_size":[8,8],"placement":[2,0]}}
  m.extract_binding(raw,b,{"width":12,"height":8},out)
  bad=Image.open(raw);bad.putpixel((0,0),(1,1,1,255));bad.save(raw)
  try:m.extract_binding(raw,b,{"width":12,"height":8},out);raise AssertionError("outside pixel accepted")
  except m.WorkbenchError:pass
  sr=root/"dup";p=source(sr,key("operator","lower_body"));q=sr/"other"/p.name;q.parent.mkdir();shutil.copy2(p,q);os.utime(q,(1,1))
  try:m.source_index(sr,root/"none");raise AssertionError("duplicate accepted")
  except m.WorkbenchError:pass
  sr=root/"owners/source";wr_base=root/"owners/weapons";wr=wr_base/"content/sprites/weapons";source(sr,key("operator","lower_body"));source(sr,key("operator","upper_body"));source(wr_base,key("weapon_a","weapon","melee_1h_dagger"));source(wr_base,key("weapon_b","weapon","melee_1h_dagger"))
  cat=root/"catalog.json";cat.write_text(json.dumps({"weapons":{x:{"animation_profile":"melee_1h_dagger","presentation_mode":"authored_overlay"} for x in ("weapon_a","weapon_b")}}))
  a=m.build_plan("melee_1h","idle_relaxed_01","e",weapon_id="weapon_a",source_root=sr,weapon_root=wr,catalog_path=cat,repo_root=root);bb=m.build_plan("melee_1h","idle_relaxed_01","e",weapon_id="weapon_b",source_root=sr,weapon_root=wr,catalog_path=cat,repo_root=root)
  assert [x["owner"] for x in a["layers"] if x["layer"]=="weapon"]==["weapon_a"]
  try:m.assert_context(a,bb);raise AssertionError("context mismatch accepted")
  except m.WorkbenchError:pass
  v1={"schema":"custodian.operator_animation_workbench.v1","identity":a["identity"],"weapon_context":a["weapon_context"],"timeline":{"frames":4},"layers":[]}
  fields=("binding_id","aseprite_layer_name","role","editable","owner","profile","group","action","direction","layer","source_path","runtime_path","source_file_sha256","source_pixel_sha256","frames","frame_size","placement","timeline_mapping")
  v1["layers"]=[{k:x[k] for k in fields} for x in a["layers"]];up=m.upgrade_v1_manifest_to_v2(v1);assert up["schema"]==m.SCHEMA_NAME and up["layers"][0]["workspace_contract"]["timeline_slots"]==[1,2,3,4]
  mixed=json.loads(json.dumps(a));mixed["layers"]=[x for x in mixed["layers"] if x["layer"]!="weapon"];mixed["timeline"]["workspace_clock_frames"]=10
  for x in mixed["layers"][:2]:x["workspace_contract"]["frames"]=10
  fx=json.loads(json.dumps(mixed["layers"][0]));fx.update({"binding_id":"fx","layer":"fx","role":"linked_fx"});fx["workspace_contract"]["frames"]=8;mixed["layers"].append(fx)
  report=fc.migration_report(mixed,"add",2,"duplicate-prev","auto",m.REPO_ROOT);assert set(report["affected_bindings"])=={"lower_body","upper_body"} and report["excluded_bindings"][0]["binding_id"]=="fx"
  canvas_manifest=json.loads(json.dumps(mixed));canvas_manifest["identity"].update({"profile":"unarmed","group":"attack","action":"fast_02","direction":"e"});canvas_manifest["canvas"]={"width":96,"height":96};canvas_manifest["references"]=[]
  for layer in canvas_manifest["layers"]:
   layer["owner"]="operator";layer["profile"]="unarmed";layer["frame_size"]=[96,96];layer["workspace_contract"]["frame_size"]=[96,96]
  fx_binding=json.loads(json.dumps(canvas_manifest["layers"][0]));fx_binding.update({"binding_id":"fx","layer":"fx","frame_size":[96,96]});fx_binding["workspace_contract"]["frame_size"]=[96,96];canvas_manifest["layers"].append(fx_binding)
  linked_binding=json.loads(json.dumps(canvas_manifest["layers"][0]));linked_binding.update({"binding_id":"weapon__vigil","layer":"weapon","owner":"weapon_vigil","profile":"melee_1h"});canvas_manifest["layers"].append(linked_binding)
  canvas_report=fc.canvas_migration_report(canvas_manifest,128,128,"animation",root)
  assert set(canvas_report["affected_bindings"])=={"lower_body","upper_body","fx"}
  assert canvas_report["new_document_size"]==[128,128] and canvas_report["placements"]["lower_body"]==[0,0]
  assert "weapon__vigil" in {x["binding_id"] for x in canvas_report["excluded_bindings"]}
  assert set(fc.canvas_affected_set(canvas_manifest,"body")[0][i]["layer"] for i in range(2))=={"lower_body","upper_body"}
  assert "weapon__vigil" in {b["binding_id"] for b in fc.canvas_affected_set(canvas_manifest,"all")[0]}
  mismatch=json.loads(json.dumps(canvas_manifest));mismatch["layers"][0]["frame_size"]=[100,96];mismatch["layers"][0]["workspace_contract"]["frame_size"]=[100,96]
  try:fc.canvas_migration_report(mismatch,129,128,"animation",root);raise AssertionError("half-pixel centering accepted")
  except ValueError:pass
  try:fc.migration_report(mixed,"add",2,"duplicate-prev","upper_body",m.REPO_ROOT);raise AssertionError("clock-owner exclusion accepted")
  except ValueError as error:assert "clock owner" in str(error)
  empty=json.loads(json.dumps(mixed));empty["layers"]=[fx]
  try:fc.migration_report(empty,"add",2,"duplicate-prev","auto",m.REPO_ROOT);raise AssertionError("empty automatic migration accepted")
  except ValueError as error:assert "empty" in str(error)
  dep=root/"dependencies";defs=dep/"custodian/game/actors/operator";defs.mkdir(parents=True);(defs/"test_definition.tres").write_text('weapon_id = &"weapon_a"\nhit_windows = {}\n')
  attack=json.loads(json.dumps(a));attack["identity"].update({"group":"attack","action":"fast_01"});attack["context"]["weapon_id"]="weapon_a"
  assert fc.audit_dependencies(dep,attack,attack["layers"])["level"]=="RED"
  (defs/"test_definition.tres").unlink();sockets=dep/"custodian/content/data/operator/generated/operator_weapon_sockets.generated.json";sockets.parent.mkdir(parents=True);sockets.write_text(json.dumps({"tracks":{"melee_1h/attack/fast_01/e/upper_body":[{} for _ in range(4)]}}))
  assert fc.audit_dependencies(dep,attack,attack["layers"])["level"]=="YELLOW"
  legacy=json.loads(json.dumps(a));legacy["identity"]={"profile":"ranged_2h","group":"cosmetic","action":"fire_01","direction":"e"};legacy_upper=json.loads(json.dumps(legacy["layers"][1]));legacy_upper["layer"]="upper_body";legacy_upper["workspace_contract"]["frames"]=6
  sockets.write_text(json.dumps({"tracks":{"ranged_2h_fire_modular_right":[{} for _ in range(6)]}}));assert fc.audit_dependencies(dep,legacy,[legacy_upper])["level"]=="YELLOW"
  canvas_attack=json.loads(json.dumps(canvas_manifest));canvas_attack["identity"].update({"group":"attack","action":"fast_02"})
  sockets.write_text(json.dumps({"tracks":{"unarmed/attack/fast_02/e/upper_body":[{} for _ in range(6)]}}))
  assert fc.audit_canvas_dependencies(dep,canvas_attack,canvas_attack["layers"])["level"]=="YELLOW"
  recontext=root/"recontext";ident={"profile":"melee_1h","group":"posture","action":"idle_relaxed_01","direction":"e"};ws=w.workspace(recontext,ident);ws.mkdir(parents=True);wb=ws/"workbench.aseprite";wb.write_bytes(b"edited weapon A")
  old_manifest={"schema":m.SCHEMA_NAME,"identity":ident,"context":{"fingerprint":"weapon-a"},"timeline":{"document_frames":1},"canvas":{"width":8,"height":8},"layers":[],"references":[],"pending_migration":None,"aseprite":{"path":str(wb),"last_synced_sha256":m.file_sha256(wb)}};w.save(ws/"workbench.json",old_manifest)
  fresh=json.loads(json.dumps(old_manifest));fresh["context"]={"fingerprint":"weapon-b"};fresh["aseprite"]["last_synced_sha256"]=None
  old_build,old_run,old_resolve=m.build_plan,w.aseprite_run,w.resolve_aseprite
  try:
   m.build_plan=lambda *_args,**_kwargs:json.loads(json.dumps(fresh))
   w.resolve_aseprite=lambda *_args,**_kwargs:Path("/bin/true")
   def fake_run(_binary,manifest_path,_mode):
    generated=json.loads(manifest_path.read_text());Path(generated["aseprite"]["path"]).write_bytes(b"weapon B")
   w.aseprite_run=fake_run
   refreshed,_=w.refresh("melee_1h","idle_relaxed_01","e",weapon="weapon_b",root=recontext,discard=True)
   assert refreshed["context"]["fingerprint"]=="weapon-b" and list((ws/"backups").glob("*/workbench.aseprite"))
  finally:m.build_plan,w.aseprite_run,w.resolve_aseprite=old_build,old_run,old_resolve
 real=m.build_plan("melee_1h","idle_relaxed_01","e",weapon_id="vigil_pattern_dagger");r=fc.migration_report(real,"add",2,"duplicate-prev","auto",m.REPO_ROOT)
 old_clock=real["timeline"]["workspace_clock_frames"]
 assert [x["binding_id"] for x in real["layers"]]==["lower_body","upper_body","weapon__vigil_pattern_dagger"] and r["new_clock_frames"]==old_clock+1 and r["dependency_audit"]["level"]=="GREEN"
 if shutil.which("aseprite"):
  with tempfile.TemporaryDirectory() as td:
   cli=Path(__file__).resolve().parents[1]/"operator/operator_cli.py"; common=["melee_1h","idle_relaxed_01","e","--weapon","vigil_pattern_dagger","--workspace-root",td]
   subprocess.run([sys.executable,str(cli),"anim","edit",*common,"--no-open"],check=True,stdout=subprocess.DEVNULL)
   subprocess.run([sys.executable,str(cli),"anim","frame","add",*common,"--after","2"],check=True,stdout=subprocess.DEVNULL)
   manifest=json.loads((Path(td)/"melee_1h/posture/idle_relaxed_01/e/workbench.json").read_text());assert manifest["timeline"]["workspace_clock_frames"]==old_clock+1 and manifest["pending_migration"]["affected_bindings"]==["lower_body","upper_body","weapon__vigil_pattern_dagger"]
   # Opting out isolates the frame migration: three bindings, one direction.
   solo=subprocess.run([sys.executable,str(cli),"anim","publish",*common,"--no-mirror-counterpart","--dry-run","--json"],check=True,capture_output=True,text=True);targets=json.loads(solo.stdout)["changed_sources"];assert len(targets)==3 and all(f"__{old_clock+1}f__96.png" in p for p in targets),targets
   # The default now also publishes the mirrored counterpart, so the same edit
   # covers both directions. This is the halved-authoring policy; if it silently
   # reverted, this assertion is what notices.
   mirrored=subprocess.run([sys.executable,str(cli),"anim","publish",*common,"--dry-run","--json"],check=True,capture_output=True,text=True);both=json.loads(mirrored.stdout)["changed_sources"]
   assert len(both)==6 and all(f"__{old_clock+1}f__96.png" in p for p in both),both
   assert sum(1 for p in both if "__w__" in p)==3 and sum(1 for p in both if "__e__" in p)==3,both
 else: print("SKIP ASEPRITE INTEGRATION: aseprite executable unavailable")
 # Production Fast 02 E candidate set remains a useful canvas-migration contract.
 fast02=m.build_plan("unarmed","fast_02","e",group="attack")
 fast02_report=fc.canvas_migration_report(fast02,128,128,"animation",m.REPO_ROOT)
 assert set(fast02_report["affected_bindings"])=={"lower_body","upper_body","fx"}
 assert fast02_report["new_document_size"]==[128,128] and fast02["timeline"]["workspace_clock_frames"]==6
 if shutil.which("aseprite"):
  with tempfile.TemporaryDirectory() as td:
   cli=Path(__file__).resolve().parents[1]/"operator/operator_cli.py";common=["unarmed","fast_02","e","--group","attack","--workspace-root",td]
   subprocess.run([sys.executable,str(cli),"anim","edit",*common,"--no-open"],check=True,stdout=subprocess.DEVNULL)
   subprocess.run([sys.executable,str(cli),"anim","canvas","resize",*common,"--width","128","--height","128","--scope","animation"],check=True,stdout=subprocess.DEVNULL)
   manifest_path=Path(td)/"unarmed/attack/fast_02/e/workbench.json";staged=json.loads(manifest_path.read_text())
   assert staged["canvas"]=={"width":128,"height":128} and staged["timeline"]["workspace_clock_frames"]==6
   assert all(b["source_contract"]["frame_size"]==[96,96] and b["workspace_contract"]["frame_size"]==[128,128] and b["publish_contract"]["frame_size"]==[128,128] for b in staged["layers"])
   assert all("__6f__128.png" in b["publish_contract"]["path"] for b in staged["layers"])
   with Image.open(Path(staged["layers"][0]["input_path"])) as migrated: assert migrated.size==(768,128)
   # Every source RGBA cell is preserved byte-for-byte at the centered offset.
   original_plan=m.build_plan("unarmed","fast_02","e",group="attack")
   for old_binding,new_binding in zip(original_plan["layers"],staged["layers"]):
    with Image.open(m.REPO_ROOT/old_binding["source_contract"]["path"]) as original, Image.open(new_binding["input_path"]) as migrated:
     old=original.convert("RGBA");new=migrated.convert("RGBA")
     assert new.size==(768,128)
     for frame in range(6):assert old.crop((frame*96,0,(frame+1)*96,96)).tobytes()==new.crop((frame*128+16,16,frame*128+112,112)).tobytes(),(new_binding["binding_id"],frame+1)
   exported=subprocess.run(["aseprite","-b",str(Path(td)/"unarmed/attack/fast_02/e/workbench.aseprite"),"--sheet",str(Path(td)/"assembled.png"),"--sheet-type","horizontal"],check=True,capture_output=True,text=True)
   with Image.open(Path(td)/"assembled.png") as assembled:assert assembled.size==(768,128),exported.stdout+exported.stderr
 else: print("SKIP ASEPRITE CANVAS INTEGRATION: aseprite executable unavailable")
 print("PASS operator_animation_workbench_smoke: frame and centered canvas migrations, RGBA preservation, crop guard, scopes, Fast 02 Aseprite assembly and contracts, ownership and compatibility")
if __name__=="__main__":main()
