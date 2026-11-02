#!/usr/bin/env python3
from pathlib import Path
import sys,tempfile
from PIL import Image
ROOT=Path(__file__).resolve().parents[3];sys.path[:0]=[str(ROOT/"custodian/tools/operator")]
from art_agent import palette,recolor
with tempfile.TemporaryDirectory() as tmp:
    root=Path(tmp);original=Image.new("RGBA",(8,4),(0,0,0,0));candidate=original.copy()
    for frame in range(2):candidate.putpixel((frame*4+1,1),(80,60,40,255))
    original.save(root/"original.png");candidate.save(root/"candidate.png");original_bytes=(root/"original.png").read_bytes();candidate_bytes=(root/"candidate.png").read_bytes()
    frames=[candidate.crop((i*4,0,(i+1)*4,4)) for i in range(2)];report=palette.inspect(frames,"candidate")
    plan=recolor.build(session_id="source",workbench_sha="hash",reference={"reference_id":"ref","source_hashes":{}},scopes=[{"target_layer":"candidate","reference_layer":"body"}],frames=[1,2],target_reports={"candidate":report},reference_reports={"candidate":palette.inspect([Image.new("RGBA",(4,4),(120,90,45,255))],"body")},regions=[],fingerprints={})
    for m in plan.mappings:m.destination_rgb=[120,90,45];m.locked=True
    after,_=recolor.apply_mapping({"candidate":frames},plan);assert palette.alpha_sha(frames)==palette.alpha_sha(after["candidate"]);assert (root/"original.png").read_bytes()==original_bytes;assert (root/"candidate.png").read_bytes()==candidate_bytes
print("operator_art_source_recolor_smoke ok")
