#!/usr/bin/env python3
"""Non-destructive Workbench V2 semantic, pixel, and migration checks."""
import json,os,shutil,subprocess,sys,tempfile
from pathlib import Path
from PIL import Image
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"operator"))
import animation_workbench_model as m
import animation_frame_contract as fc

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
  fc.transform_strip(src,add,4,[8,8],"add",2,"duplicate-prev");assert pixels(add,5)==[old[0],old[1],old[1],old[2],old[3]]
  fc.transform_strip(add,back,5,[8,8],"remove",3);assert pixels(back,4)==old
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
  sr=root/"owners/source";wr=root/"owners/weapons";source(sr,key("operator","lower_body"));source(sr,key("operator","upper_body"));source(wr,key("weapon_a","weapon","melee_1h_dagger"));source(wr,key("weapon_b","weapon","melee_1h_dagger"))
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
  dep=root/"dependencies";defs=dep/"custodian/game/actors/operator";defs.mkdir(parents=True);(defs/"test_definition.tres").write_text('weapon_id = &"weapon_a"\nhit_windows = {}\n')
  attack=json.loads(json.dumps(a));attack["identity"].update({"group":"attack","action":"fast_01"});attack["context"]["weapon_id"]="weapon_a"
  assert fc.audit_dependencies(dep,attack,attack["layers"])["level"]=="RED"
  (defs/"test_definition.tres").unlink();sockets=dep/"custodian/content/data/operator/generated/operator_weapon_sockets.generated.json";sockets.parent.mkdir(parents=True);sockets.write_text(json.dumps({"tracks":{"melee_1h/attack/fast_01/e/upper_body":[{},{}]}}))
  assert fc.audit_dependencies(dep,attack,attack["layers"])["level"]=="YELLOW"
 real=m.build_plan("melee_1h","idle_relaxed_01","e",weapon_id="vigil_pattern_dagger");r=fc.migration_report(real,"add",2,"duplicate-prev","auto",m.REPO_ROOT)
 assert [x["binding_id"] for x in real["layers"]]==["lower_body","upper_body","weapon__vigil_pattern_dagger"] and r["new_clock_frames"]==5 and r["dependency_audit"]["level"]=="GREEN"
 if shutil.which("aseprite"):
  with tempfile.TemporaryDirectory() as td:
   cli=Path(__file__).resolve().parents[1]/"operator/operator_cli.py"; common=["melee_1h","idle_relaxed_01","e","--weapon","vigil_pattern_dagger","--workspace-root",td]
   subprocess.run([sys.executable,str(cli),"anim","edit",*common,"--no-open"],check=True,stdout=subprocess.DEVNULL)
   subprocess.run([sys.executable,str(cli),"anim","frame","add",*common,"--after","2"],check=True,stdout=subprocess.DEVNULL)
   manifest=json.loads((Path(td)/"melee_1h/posture/idle_relaxed_01/e/workbench.json").read_text());assert manifest["timeline"]["workspace_clock_frames"]==5 and manifest["pending_migration"]["affected_bindings"]==["lower_body","upper_body","weapon__vigil_pattern_dagger"]
   published=subprocess.run([sys.executable,str(cli),"anim","publish",*common,"--dry-run","--json"],check=True,capture_output=True,text=True);targets=json.loads(published.stdout)["changed_sources"];assert len(targets)==3 and all("__5f__96.png" in p for p in targets)
 else: print("SKIP ASEPRITE INTEGRATION: aseprite executable unavailable")
 print("PASS operator_animation_workbench_smoke: V2 add/remove, bounds, duplicates, owner/context, upgrade, mixed clocks, real Vigil GREEN")
if __name__=="__main__":main()
