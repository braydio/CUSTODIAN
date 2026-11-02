#!/usr/bin/env python3
from pathlib import Path
import sys,tempfile
from PIL import Image
ROOT=Path(__file__).resolve().parents[3];sys.path[:0]=[str(ROOT/"custodian/tools/operator")]
from art_agent import palette,recolor
from art_agent.edit_scope import save,assert_allowed
frames=[]
for i in range(4):
    image=Image.new("RGBA",(4,4),(0,0,0,0));image.putpixel((i,0),(80,60,40,255));image.putpixel((0,1),(20,20,20,128));frames.append(image)
reference=[Image.new("RGBA",(4,4),(120,90,45,255)) for _ in range(4)]
source_report=palette.inspect(frames,"upper_body");reference_report=palette.inspect(reference,"upper_body")
plan=recolor.build(session_id="fixture",workbench_sha="abc",reference={"reference_id":"ref","source_hashes":{"upper_body":"def"}},scopes=[{"target_layer":"upper_body","reference_layer":"upper_body"}],frames=[1,2,3,4],target_reports={"upper_body":source_report},reference_reports={"upper_body":reference_report},regions=[],fingerprints={})
for item in plan.mappings:item.destination_rgb=[120,90,45];item.action="map";item.locked=True
plan.status="READY";before_alpha=palette.alpha_sha(frames);after,stats=recolor.apply_mapping({"upper_body":frames},plan);assert palette.alpha_sha(after["upper_body"])==before_alpha;assert palette.silhouette_sha(after["upper_body"])==palette.silhouette_sha(frames);assert stats["changed_pixel_count"]==8
assert all(image.getpixel((i,0))[:3]==(120,90,45) for i,image in enumerate(after["upper_body"]))
with tempfile.TemporaryDirectory() as tmp:
    scope=save(Path(tmp)/"scope.json",[{"layer":"upper_body","frames":[3,4]}],["paint_pixels","recolor_plan"])
    try:assert_allowed(scope,"paint_pixels",[("upper_body",2)]);raise AssertionError("scope did not reject")
    except ValueError:pass
    assert_allowed(scope,"paint_pixels",[("upper_body",4)])
print("operator_art_agent_recolor_smoke ok")
