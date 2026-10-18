#!/usr/bin/env python3
"""R2 reference provenance test, including formerly uncovered docs/REFERENCE_MANIFEST.json."""
import hashlib,json,sys
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[3]
base=root/'custodian/asset_drop/source_work/operator/operator_ne_walk_cleanup_r1'
manifest=root/'docs/REFERENCE_MANIFEST.json'
assert manifest.is_file(),'reference manifest missing'
source=json.loads(manifest.read_text())
assert isinstance(source,dict) and source,'empty reference manifest'
refs={
'alternate_walk_10f_source.png':('897de4c4ca235fab60fa92c8d3f040f997fc14d20c6916ed059b5c924f1e7b06',(1280,128)),
'single_frame_style_source.png':('00a04e87a93ebf6c4de9040538453c2e44f72fbdf1a417bc8529aa22a2cc5551',(128,128)),
'alternate_walk_15f_source.png':('2ecbde5f764bea4b86666abb26f5acf54e18f103d180290b491663b5129de2ea',(1920,128)),
'idle_lock_15f_source.png':('451eed81d8451aa0b5f81ce50144af05253d641c19cf04be74c96f348c1de802',(1920,128))}
blob=manifest.read_text()
for name,(digest,size) in refs.items():
 p=base/name
 assert p.is_file(),name+' missing'
 assert hashlib.sha256(p.read_bytes()).hexdigest()==digest,name+' hash mismatch'
 with Image.open(p) as im:
  assert im.size==size and im.mode=='RGBA',name+' geometry mismatch'
  assert set(im.getchannel('A').getextrema())<={0,255},name+' unexpected alpha range'
 assert name in blob or digest in blob,name+' absent from manifest provenance'
print('PASS R2 reference manifest: 4 exact RGBA source images, docs/REFERENCE_MANIFEST.json covered')
