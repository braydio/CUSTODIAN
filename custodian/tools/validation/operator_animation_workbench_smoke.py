#!/usr/bin/env python3
"""Non-destructive Workbench V2 semantic, pixel, and migration checks."""
import json,os,shutil,subprocess,sys,tempfile
from pathlib import Path
from PIL import Image
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"operator"))
import animation_workbench_model as m
import animation_frame_contract as fc
import animation_workbench as w
import ui.service as service_module
from ui.service import WorkbenchService
from ui.state import AnimationSelection

def strip(path,n,w=8,h=8):
 im=Image.new("RGBA",(n*w,h))
 for i in range(n): im.paste((10+i,20+i,30+i,255),(i*w,0,(i+1)*w,h))
 path.parent.mkdir(parents=True,exist_ok=True); im.save(path)
def pixels(path,n,w=8):
 with Image.open(path) as im:return [im.crop((i*w,0,(i+1)*w,im.height)).convert("RGBA").tobytes() for i in range(n)]
def key(owner,layer,profile="melee_1h",n=4):return m.SCHEMA.OperatorAssetKey(owner,layer,profile,"posture","idle_relaxed_01","e",n,8,8)
def source(root,k):
 p=root/m.SCHEMA.canonical_source_path(k);strip(p,k.frames);return p

def creation_smoke():
 if not shutil.which("aseprite"):
  print("SKIP NEW ANIMATION ASEPRITE INTEGRATION: aseprite executable unavailable")
  return
 with tempfile.TemporaryDirectory(prefix="operator_animation_create_") as temporary:
  root=Path(temporary);repo=root/"repo";custodian=repo/"custodian"
  source_root=custodian/"content/sprites/operator/source/animations";weapon_root=custodian/"content/sprites/weapons"
  workspace_root=root/"workbench";source_root.mkdir(parents=True);weapon_root.mkdir(parents=True)
  old=(m.REPO_ROOT,m.CUSTODIAN_ROOT,m.SOURCE_ROOT,m.WEAPON_ROOT)
  m.REPO_ROOT=repo;m.CUSTODIAN_ROOT=custodian;m.SOURCE_ROOT=source_root;m.WEAPON_ROOT=weapon_root
  try:
   valid=("unarmed","cosmetic","create_validation_01","e",6,(96,96),8.0,True,"full_body")
   for options in (("bad_profile",*valid[1:]),(valid[0],"bad_group",*valid[2:]),
       (valid[0],valid[1],"Bad_Action",*valid[3:]),(valid[0],valid[1],valid[2],"bad_direction",*valid[4:]),
       (valid[0],valid[1],valid[2],valid[3],0,*valid[5:]),
       (valid[0],valid[1],valid[2],valid[3],valid[4],(0,96),*valid[6:]),
       (valid[0],valid[1],valid[2],valid[3],valid[4],valid[5],0.0,*valid[7:]),
       (valid[0],valid[1],valid[2],valid[3],valid[4],valid[5],valid[6],"yes",valid[8]),
       (*valid[:-1],"head_only")):
    try:m.build_creation_plan(*options,repo_root=repo,source_root=source_root,weapon_root=weapon_root);raise AssertionError(f"invalid creation plan accepted: {options}")
    except m.WorkbenchError:pass
   data,ws=w.create_animation("unarmed","create_fixture_01","e",group="cosmetic",frames=6,
      frame_size=(96,96),fps=8,loop=True,template="full_body",root=workspace_root,
      source_root=source_root,weapon_root=weapon_root,repo_root=repo)
   manifest=ws/"workbench.json";document=ws/"workbench.aseprite"
   target=repo/data["layers"][0]["source_path"]
   assert not target.exists() and w.state(data,document)=="NEW / UNSAVED"
   author=root/"author.lua"
   author.write_text('local p=app.params["document"]; local s=app.open(p); local l=s.layers[1]; for i=1,6 do local im=Image(s.width,s.height,ColorMode.RGB); im:putPixel(i+2,12,Color{r=20+i,g=40,b=60,a=255}); s:newCel(l,i,im,Point(0,0)); end; s:saveAs(p); s:close()\n')
   subprocess.run(["aseprite","-b","--script-param",f"document={document}","--script",str(author)],check=True,capture_output=True,text=True)
   data=w.load(manifest);assert w.state(data,document)=="NEW / READY TO PUBLISH"
   normalized=w.export_preview(manifest)
   with Image.open(normalized/"full_body.png") as image:
    assert image.size==(6*96,96)
    for frame in range(6):assert image.getpixel((frame*96+frame+3,12))==(21+frame,40,60,255)
   targets=w.publish(manifest,dry_run=True,requested=data)
   assert targets==[str(target)] and not target.exists()
   resource=custodian/"content/sprites/operator/runtime/operator_runtime_frames.tres"
   resource.parent.mkdir(parents=True,exist_ok=True);resource.write_bytes(b"generated resource preimage\\n")
   document_preimage=m.file_sha256(document);old_resources=w.GENERATED_OPERATOR_RESOURCES;old_rel=m.rel
   old_commands=w._validation_commands;old_run=w.subprocess.run;sync_calls=[0]
   def fixture_rel(path,repo_root=None):
    try:return Path(path).resolve().relative_to(repo.resolve()).as_posix()
    except ValueError:return str(Path(path).resolve())
   m.rel=fixture_rel
   w.GENERATED_OPERATOR_RESOURCES=[resource];w._validation_commands=lambda *_args:[]
   def injected_pipeline(command,*args,**kwargs):
    if Path(str(command[0])).name=="aseprite":return old_run(command,*args,**kwargs)
    if any("sync_operator_runtime_assets.py" in str(part) for part in command):
     sync_calls[0]+=1
     if sync_calls[0]==1:raise subprocess.CalledProcessError(1,command,stderr="injected after source CREATE")
    return subprocess.CompletedProcess(command,0,stdout="",stderr="")
   w.subprocess.run=injected_pipeline
   try:
    try:w.publish(manifest,aseprite="/usr/bin/aseprite",requested=data)
    except m.WorkbenchError as error:assert "WORKBENCH PUBLISH FAILED" in str(error)
    else:raise AssertionError("injected source CREATE failure did not stop publication")
   finally:
    w.subprocess.run=old_run;w._validation_commands=old_commands;w.GENERATED_OPERATOR_RESOURCES=old_resources;m.rel=old_rel
   assert not target.exists() and not Path(str(target)+".import").exists()
   assert not m.BUILDER.timing_sidecar_path(target).exists()
   assert resource.read_bytes()==b"generated resource preimage\\n" and m.file_sha256(document)==document_preimage
   journal=json.loads(sorted((ws/"transactions").glob("*/transaction.json"))[-1].read_text())
   assert journal["state"]=="ROLLED_BACK" and journal["primary_failure"] and not journal["recovery_failure"]
   # Route successful creation through the same service boundary used by OPUI
   # and the CLI. The guarded art publisher is intercepted only at its checkout
   # boundary; the real Workbench transaction, source export, rollback journal,
   # timing, and manifest normalization still run against this disposable repo.
   old_run=w.subprocess.run;old_commands=w._validation_commands;old_rel=m.rel
   w._validation_commands=lambda *_args:[];w.GENERATED_OPERATOR_RESOURCES=[resource];m.rel=fixture_rel
   def successful_pipeline(command,*args,**kwargs):
    if any("sync_operator_runtime_assets.py" in str(part) for part in command):
     for source_file in source_root.rglob("*.png"):
      key=m.SCHEMA.parse_filename(source_file.name)
      runtime=custodian/m.SCHEMA.canonical_runtime_path(key);runtime.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source_file,runtime)
      source_timing=m.BUILDER.timing_sidecar_path(source_file)
      if source_timing.exists():shutil.copy2(source_timing,m.BUILDER.timing_sidecar_path(runtime))
    if Path(str(command[0])).name=="aseprite":return old_run(command,*args,**kwargs)
    return subprocess.CompletedProcess(command,0,stdout="",stderr="")
   repo_plan=repo/"design/02_features/animation/OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json"
   repo_plan.parent.mkdir(parents=True,exist_ok=True);repo_plan.write_text(json.dumps({"schema":"custodian.operator_animation_implementation_plan.v2","items":[]}))
   catalog=custodian/"content/data/operator/generated/operator_animation_catalog.generated.json"
   catalog.parent.mkdir(parents=True,exist_ok=True);catalog.write_text(json.dumps({"animations":{},"weapons":{}}))
   service=WorkbenchService(repo_root=repo,source_root=source_root,weapon_root=weapon_root,
      catalog_path=catalog,workspace_root=workspace_root,aseprite=Path("/usr/bin/aseprite"))
   service.coordination_root=repo;service.coordination_root_configured=False
   service.checkout_identity=lambda:__import__("types").SimpleNamespace(publish_allowed=True,kind="ART BRANCH")
   old_prepare=service_module.operator_art_worktree.prepare_publish_checkout
   old_publisher=service_module.operator_art_worktree.publish_to_main
   service_module.operator_art_worktree.prepare_publish_checkout=lambda *_a,**_k:__import__("types").SimpleNamespace(status="ready",blockers=(),preparations=())
   publisher_calls=[]
   def guarded_publisher(**kwargs):
    publisher_calls.append((set(kwargs["canonical_paths"]),set(kwargs["allowlist"])))
    return {"status":"fixture_published","published":kwargs["publish_once"]()}
   service_module.operator_art_worktree.publish_to_main=guarded_publisher
   w.subprocess.run=successful_pipeline
   try:
    selection=AnimationSelection("unarmed","cosmetic","create_fixture_01","e")
    review=service.publish_preview(selection)
    assert review.publish_enabled and review.readiness_status=="ready"
    reviewed_manifest=manifest.read_bytes();saved_document_hash=m.file_sha256(document)
    original_manifest=json.loads(reviewed_manifest)
    corruptions=(
     lambda value:value["layers"][0].update(owner="enemy"),
     lambda value:value["layers"][0].update(layer="head"),
     lambda value:value["layers"][0]["semantic_identity"].update(action="forged_action"),
     lambda value:value["layers"][0].update(source_path="custodian/content/forged.png"),
     lambda value:value["layers"][0]["source_contract"].update(path="custodian/content/forged.png"),
    )
    for corrupt in corruptions:
     candidate=json.loads(reviewed_manifest);corrupt(candidate);w.save(manifest,candidate)
     try:service.publish(selection)
     except (m.WorkbenchError,service_module.operator_art_worktree.ArtWorktreeError):pass
     else:raise AssertionError("invalid creation publication contract passed service guard")
     assert not publisher_calls and m.file_sha256(document)==saved_document_hash and not target.exists()
    w.save(manifest,original_manifest)
    target.write_bytes(b"raced target must survive")
    try:service.publish(selection)
    except m.WorkbenchError as error:assert "NOT READY TO PUBLISH" in str(error) or "changed after preview" in str(error) or "already exists" in str(error)
    else:raise AssertionError("service publish overwrote a target created after preview")
    assert target.read_bytes()==b"raced target must survive" and m.file_sha256(document)==saved_document_hash
    target.unlink()
    published=service.publish(selection)
    assert len(publisher_calls)==2 and any(path.endswith(target.name) for path in publisher_calls[-1][0]), publisher_calls
    assert target.as_posix() in published["published"]
   finally:
    w.subprocess.run=old_run;w._validation_commands=old_commands;m.rel=old_rel
    service_module.operator_art_worktree.prepare_publish_checkout=old_prepare
    service_module.operator_art_worktree.publish_to_main=old_publisher
   runtime=custodian/m.SCHEMA.canonical_runtime_path(m.SCHEMA.parse_filename(target.name))
   data=w.load(manifest)
   assert published["published"]==[str(target)] and "creation" not in data and w.state(data,document)=="CLEAN"
   assert data["layers"][0]["source_contract"].get("operation") is None
   assert m.pixel_sha256(target)==m.pixel_sha256(runtime)==m.pixel_sha256(normalized/"full_body.png")
   timing=json.loads(m.BUILDER.timing_sidecar_path(target).read_text())
   assert timing["fps"]==8.0 and timing["loop"] is True and timing["durations"]==[1.0]*6
   records=service.discover_browser_records()
   record=next(row for row in records if row.selection==selection)
   assert record.reachability_status=="DORMANT"
   # A canonical collision that appears after the plan is reviewed fails before
   # the ignored creation session is assembled or altered.
   race_action="create_race_01"
   plan=m.build_creation_plan("unarmed","cosmetic",race_action,"e",6,(96,96),8,True,"full_body",
       repo_root=repo,source_root=source_root,weapon_root=weapon_root)
   assert plan.status=="READY"
   race_target=repo/plan.layers[0]["source_path"];race_target.parent.mkdir(parents=True,exist_ok=True)
   strip(race_target,6,96,96)
   raced=m.build_creation_plan("unarmed","cosmetic",race_action,"e",6,(96,96),8,True,"full_body",
       repo_root=repo,source_root=source_root,weapon_root=weapon_root)
   assert raced.status=="COLLISION" and raced.collisions
   try:
    w.create_animation("unarmed",race_action,"e",group="cosmetic",frames=6,frame_size=(96,96),
       root=workspace_root,source_root=source_root,weapon_root=weapon_root,repo_root=repo)
    raise AssertionError("target-appeared creation race was accepted")
   except m.WorkbenchError as error:assert "COLLISION" in str(error)
   assert not (workspace_root/"unarmed/cosmetic"/race_action/"e").exists()
   # Modular template exports both synchronized body clocks from the saved
   # document, before either layer has canonical source authority.
   modular,modular_ws=w.create_animation("unarmed","create_modular_01","e",group="cosmetic",frames=6,
      frame_size=(96,96),fps=8,loop=False,template="modular_body",root=workspace_root,
      source_root=source_root,weapon_root=weapon_root,repo_root=repo)
   modular_doc=modular_ws/"workbench.aseprite";modular_author=root/"modular.lua"
   modular_author.write_text('local p=app.params["document"]; local s=app.open(p); for _,name in ipairs({"lower_body","upper_body"}) do local l=nil; for _,candidate in ipairs(s.layers) do if candidate.name==name then l=candidate end end; for i=1,6 do local im=Image(s.width,s.height,ColorMode.RGB); im:putPixel(i+1,name=="lower_body" and 40 or 20,Color{r=name=="lower_body" and 200 or 30,g=50,b=70,a=255}); s:newCel(l,i,im,Point(0,0)); end end; s:saveAs(p); s:close()\n')
   subprocess.run(["aseprite","-b","--script-param",f"document={modular_doc}","--script",str(modular_author)],check=True,capture_output=True,text=True)
   modular_exports=w.export_preview(modular_ws/"workbench.json")
   assert {row["layer"] for row in modular["layers"]}=={"lower_body","upper_body"}
   assert modular["timeline"]["source_clock_frames"]==modular["timeline"]["workspace_clock_frames"]==6
   for layer in ("lower_body","upper_body"):
    with Image.open(modular_exports/f"{layer}.png") as image:assert image.size==(6*96,96) and image.getchannel("A").getbbox() is not None
   # The synchronized modular creation also crosses WorkbenchService.publish;
   # verify both source/runtime strips retain the authored layer pixels.
   modular_selection=AnimationSelection("unarmed","cosmetic","create_modular_01","e")
   old_run=w.subprocess.run;old_commands=w._validation_commands;old_resources=w.GENERATED_OPERATOR_RESOURCES;old_rel=m.rel
   old_prepare=service_module.operator_art_worktree.prepare_publish_checkout
   old_publisher=service_module.operator_art_worktree.publish_to_main
   w._validation_commands=lambda *_args:[];w.GENERATED_OPERATOR_RESOURCES=[resource];m.rel=fixture_rel
   w.subprocess.run=successful_pipeline
   service_module.operator_art_worktree.prepare_publish_checkout=lambda *_a,**_k:__import__("types").SimpleNamespace(status="ready",blockers=(),preparations=())
   service_module.operator_art_worktree.publish_to_main=guarded_publisher
   try:
    modular_view=service.publish_preview(modular_selection)
    assert modular_view.publish_enabled and modular_view.readiness_status=="ready"
    modular_published=service.publish(modular_selection)
   finally:
    w.subprocess.run=old_run;w._validation_commands=old_commands;w.GENERATED_OPERATOR_RESOURCES=old_resources;m.rel=old_rel
    service_module.operator_art_worktree.prepare_publish_checkout=old_prepare
    service_module.operator_art_worktree.publish_to_main=old_publisher
   assert len(modular_published["published"])==2
   modular_data=w.load(modular_ws/"workbench.json")
   assert "creation" not in modular_data
   for layer in ("lower_body","upper_body"):
    row=next(binding for binding in modular_data["layers"] if binding["layer"]==layer)
    src=repo/row["source_path"];runtime=repo/row["runtime_path"]
    assert m.pixel_sha256(src)==m.pixel_sha256(runtime)==m.pixel_sha256(modular_exports/f"{layer}.png")
   modular_records=service.discover_browser_records()
   modular_record=next(row for row in modular_records if row.selection==modular_selection)
   assert modular_record.reachability_status=="DORMANT"
  finally:
   m.REPO_ROOT,m.CUSTODIAN_ROOT,m.SOURCE_ROOT,m.WEAPON_ROOT=old

def main():
 creation_smoke()
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
  adopted_create=m.fx_adoption_binding(a,"vfx",source_root=sr,weapon_root=wr,repo_root=root)
  assert adopted_create["layer"]=="fx" and adopted_create["aseprite_layer_name"]=="vfx"
  assert adopted_create["source_contract"]["operation"]=="CREATE" and not adopted_create["source_contract"].get("file_sha256")
  assert adopted_create["publish_contract"]["path"].startswith("custodian/content/sprites/operator/source/animations/")
  assert adopted_create["workspace_contract"]["timeline_slots"]==[1,2,3,4]
  assert w.source_contract_freshness({"identity":a["identity"],"timeline":a["timeline"],"layers":[adopted_create]},root)=={}
  created_target=root/adopted_create["publish_contract"]["path"];created_target.parent.mkdir(parents=True,exist_ok=True);created_target.write_bytes(b"external target")
  assert "CREATE target appeared" in next(iter(w.source_contract_freshness({"identity":a["identity"],"timeline":a["timeline"],"layers":[adopted_create]},root).values()))
  fx_key=key("operator","fx"); canonical_source_root=root/"custodian/content/sprites/operator/source/animations"
  existing_fx=canonical_source_root/fx_key.animation_profile/fx_key.action_group/fx_key.action/m.SCHEMA.canonical_filename(fx_key);strip(existing_fx,fx_key.frames)
  adopted_replace=m.fx_adoption_binding(a,"fx",source_root=canonical_source_root,weapon_root=wr,repo_root=root)
  assert adopted_replace["source_contract"]["operation"]=="REPLACE" and adopted_replace["source_contract"]["file_sha256"]==m.file_sha256(existing_fx)
  for invalid_layer in ("scratch","__REFERENCE_GUIDE"):
   try:m.fx_adoption_binding(a,invalid_layer,source_root=sr,weapon_root=wr,repo_root=root);raise AssertionError(f"ineligible FX layer accepted: {invalid_layer}")
   except m.WorkbenchError:pass
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
  assert canvas_report["crop_audit"]["status"]=="impossible"
  assert canvas_report["new_document_size"]==[128,128] and canvas_report["placements"]["lower_body"]==[0,0]
  assert "weapon__vigil" in {x["binding_id"] for x in canvas_report["excluded_bindings"]}
  assert set(fc.canvas_affected_set(canvas_manifest,"body")[0][i]["layer"] for i in range(2))=={"lower_body","upper_body"}
  assert "weapon__vigil" in {b["binding_id"] for b in fc.canvas_affected_set(canvas_manifest,"all")[0]}
  mismatch=json.loads(json.dumps(canvas_manifest));mismatch["layers"][0]["frame_size"]=[100,96];mismatch["layers"][0]["workspace_contract"]["frame_size"]=[100,96]
  try:fc.canvas_migration_report(mismatch,129,128,"animation",root);raise AssertionError("half-pixel centering accepted")
  except ValueError:pass
  shrink_report=fc.canvas_migration_report(canvas_manifest,64,64,"animation",root)
  assert shrink_report["crop_audit"]["status"]=="requires_staging_validation"
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
  # Obsolete pending frame metadata can be reconciled only when the saved
  # physical document still matches the canonical source/workspace contract.
  reconcile_ws=root/"reconcile"; reconcile_ws.mkdir(); reconcile_manifest=reconcile_ws/"workbench.json"; document=reconcile_ws/"workbench.aseprite"; document_bytes=b"saved edited document bytes\x00";document.write_bytes(document_bytes)
  reconcile_data={"identity":{"profile":"unarmed","group":"locomotion","action":"walk_01","direction":"n"},"canvas":{"width":96,"height":96},"timeline":{"source_clock_frames":8,"workspace_clock_frames":9,"document_frames":9,"frames":9,"preview_fps":12},"layers":[{"binding_id":"lower_body","workspace_contract":{"frames":8}}],"pending_migration":{"kind":"frame_count","new_clock_frames":9},"aseprite":{"last_synced_sha256":m.file_sha256(document)}}
  w.save(reconcile_manifest,reconcile_data); old_run,old_resolve=w.aseprite_run,w.resolve_aseprite
  try:
   w.resolve_aseprite=lambda *_args,**_kwargs:Path("/bin/true")
   def inspect_run(_binary,path,mode):
    assert mode=="inspect_contract"
    (path.parent/".document_contract.json").write_text(json.dumps({"frames":8,"width":96,"height":96,"durations":[1/12]*8}))
   w.aseprite_run=inspect_run
   reconciled=w.reconcile_saved_document_contract(reconcile_data,reconcile_manifest)
   assert reconciled["pending_migration"] is None and reconciled["timeline"]["workspace_clock_frames"]==8
   assert document.read_bytes()==document_bytes
   receipts=list((reconcile_ws/"recovery").glob("contract_reconcile_*.json"));assert len(receipts)==1
   assert Path(json.loads(receipts[0].read_text())["backup_document"]).read_bytes()==document_bytes
   try:
    bad={**reconcile_data,"timeline":{**reconcile_data["timeline"],"source_clock_frames":7,"workspace_clock_frames":9},"pending_migration":{"kind":"frame_count","new_clock_frames":9}}
    w.reconcile_saved_document_contract(bad,reconcile_manifest)
    raise AssertionError("unmatched saved document frame contract was accepted")
   except m.WorkbenchError as error: assert "SAVED ASEPRITE FRAME CONTRACT MISMATCH" in str(error)
   assert document.read_bytes()==document_bytes
  finally:w.aseprite_run,w.resolve_aseprite=old_run,old_resolve
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
   # Counterpart promotion is opt-in; the CLI default matches Workbench review.
   default=subprocess.run([sys.executable,str(cli),"anim","publish",*common,"--dry-run","--json"],check=True,capture_output=True,text=True);default_targets=json.loads(default.stdout)["changed_sources"]
   assert len(default_targets)==3 and all("__e__" in p for p in default_targets),default_targets
   mirrored=subprocess.run([sys.executable,str(cli),"anim","publish",*common,"--mirror-counterpart","--dry-run","--json"],check=True,capture_output=True,text=True);both=json.loads(mirrored.stdout)["changed_sources"]
   assert len(both)==6 and all(f"__{old_clock+1}f__96.png" in p for p in both),both
   assert sum(1 for p in both if "__w__" in p)==3 and sum(1 for p in both if "__e__" in p)==3,both
   # A saved editor-authored vfx layer remains unbound until the explicit CLI
   # action, then exports to the exact transparent/full-clock FX strip.
   adopt_root=Path(td)/"adopt";adopt_common=["melee_1h","idle_relaxed_01","e","--group","posture","--workspace-root",str(adopt_root)]
   subprocess.run([sys.executable,str(cli),"anim","edit",*adopt_common,"--no-open"],check=True,stdout=subprocess.DEVNULL)
   document=adopt_root/"melee_1h/posture/idle_relaxed_01/e/workbench.aseprite"; add_script=Path(td)/"add_vfx.lua"
   add_script.write_text('local path=app.params["document"]; local s=app.open(path); local layer=s:newLayer(); layer.name="vfx"; local image=Image(s.width,s.height,ColorMode.RGB); image:putPixel(2,3,Color{r=11,g=22,b=33,a=255}); s:newCel(layer,1,image,Point(0,0)); s:saveAs(path); s:close()\n')
   subprocess.run(["aseprite","-b","--script-param",f"document={document}","--script",str(add_script)],check=True,capture_output=True,text=True)
   manifest_path=adopt_root/"melee_1h/posture/idle_relaxed_01/e/workbench.json"
   before=json.loads(manifest_path.read_text());assert all(binding["layer"]!="fx" for binding in before["layers"])
   subprocess.run([sys.executable,str(cli),"anim","layer","adopt",*adopt_common,"--aseprite-layer","vfx","--as","fx","--json"],check=True,capture_output=True,text=True)
   adopted=json.loads(manifest_path.read_text());fx=next(binding for binding in adopted["layers"] if binding["layer"]=="fx")
   assert fx["aseprite_layer_name"]=="vfx" and fx["source_contract"]["operation"]=="CREATE" and not fx["source_contract"].get("file_sha256")
   normalized=w.export_preview(manifest_path)
   with Image.open(normalized/"fx.png") as strip_image:
    strip_pixels=strip_image.convert("RGBA");assert strip_pixels.size==(fx["workspace_contract"]["frames"]*fx["frame_size"][0],fx["frame_size"][1])
    assert strip_pixels.getpixel((2,3))==(11,22,33,255) and strip_pixels.getpixel((fx["frame_size"][0]+2,3))[3]==0,(strip_pixels.getpixel((2,3)),strip_pixels.getpixel((fx["frame_size"][0]+2,3)))
 else: print("SKIP ASEPRITE INTEGRATION: aseprite executable unavailable")
 # Exercise the live Fast 02 candidate at its current size, including during publish.
 fast02=m.build_plan("unarmed","fast_02","e",group="attack")
 target_width=fast02["canvas"]["width"]+32;target_height=fast02["canvas"]["height"]+32
 fast02_report=fc.canvas_migration_report(fast02,target_width,target_height,"animation",m.REPO_ROOT)
 assert set(fast02_report["affected_bindings"])=={"lower_body","upper_body","fx"}
 assert fast02_report["new_document_size"]==[target_width,target_height] and fast02["timeline"]["workspace_clock_frames"]==6
 if shutil.which("aseprite"):
  with tempfile.TemporaryDirectory() as td:
   cli=Path(__file__).resolve().parents[1]/"operator/operator_cli.py";common=["unarmed","fast_02","e","--group","attack","--workspace-root",td]
   subprocess.run([sys.executable,str(cli),"anim","edit",*common,"--no-open"],check=True,stdout=subprocess.DEVNULL)
   subprocess.run([sys.executable,str(cli),"anim","canvas","resize",*common,"--width",str(target_width),"--height",str(target_height),"--scope","animation"],check=True,stdout=subprocess.DEVNULL)
   manifest_path=Path(td)/"unarmed/attack/fast_02/e/workbench.json";staged=json.loads(manifest_path.read_text())
   assert staged["canvas"]=={"width":target_width,"height":target_height} and staged["timeline"]["workspace_clock_frames"]==6
   assert all(b["source_contract"]["frame_size"]==original["source_contract"]["frame_size"] and b["workspace_contract"]["frame_size"]==[target_width,target_height] and b["publish_contract"]["frame_size"]==[target_width,target_height] for original,b in zip(fast02["layers"],staged["layers"]))
   size_token=str(target_width) if target_width==target_height else f"{target_width}x{target_height}"
   assert all(f"__6f__{size_token}.png" in b["publish_contract"]["path"] for b in staged["layers"])
   with Image.open(Path(staged["layers"][0]["input_path"])) as migrated: assert migrated.size==(6*target_width,target_height)
   # Every source RGBA cell is preserved byte-for-byte at the centered offset.
   original_plan=m.build_plan("unarmed","fast_02","e",group="attack")
   for old_binding,new_binding in zip(original_plan["layers"],staged["layers"]):
    with Image.open(m.REPO_ROOT/old_binding["source_contract"]["path"]) as original, Image.open(new_binding["input_path"]) as migrated:
     old=original.convert("RGBA");new=migrated.convert("RGBA")
     assert new.size==(6*target_width,target_height)
     source_width,source_height=old_binding["source_contract"]["frame_size"]
     offset_x=(target_width-source_width)//2;offset_y=(target_height-source_height)//2
     for frame in range(6):assert old.crop((frame*source_width,0,(frame+1)*source_width,source_height)).tobytes()==new.crop((frame*target_width+offset_x,offset_y,frame*target_width+offset_x+source_width,offset_y+source_height)).tobytes(),(new_binding["binding_id"],frame+1)
   exported=subprocess.run(["aseprite","-b",str(Path(td)/"unarmed/attack/fast_02/e/workbench.aseprite"),"--sheet",str(Path(td)/"assembled.png"),"--sheet-type","horizontal"],check=True,capture_output=True,text=True)
   with Image.open(Path(td)/"assembled.png") as assembled:assert assembled.size==(6*target_width,target_height),exported.stdout+exported.stderr
 else: print("SKIP ASEPRITE CANVAS INTEGRATION: aseprite executable unavailable")
 print("PASS operator_animation_workbench_smoke: new full-body/modular creation, saved Aseprite preview, schema validation, collision race, frame/canvas migrations, RGBA preservation, ownership and compatibility")
if __name__=="__main__":main()
