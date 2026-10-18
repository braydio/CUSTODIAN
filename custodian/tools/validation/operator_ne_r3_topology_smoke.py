#!/usr/bin/env python3
"""Focused R3 synthetic regression; never declares real rig art accepted."""
import hashlib,json,subprocess,sys
from pathlib import Path
root=Path(__file__).resolve().parents[3]
tool=root/'custodian/tools/operator/ne_walk_retarget'
ref=root/'custodian/asset_drop/source_work/operator/operator_ne_walk_cleanup_r1'
source=json.loads((root/'docs/R3_PACKAGE_MANIFEST.json').read_text())
assert source['schema']=='custodian.operator_ne_r3_package.v1'
for name,digest in source['files'].items():
    p=root/name
    assert p.is_file(),f'R3 member missing {name}'
    assert hashlib.sha256(p.read_bytes()).hexdigest()==digest,f'R3 member changed {name}'
assert hashlib.sha256((tool/'clean_silhouette_r2.py').read_bytes()).hexdigest()=='9f96809956afe538df519cd62fa9fd0390b41de206392dea026121244c019b68'
subprocess.run([sys.executable,str(tool/'smoke_clean_silhouette_r3.py'),
    '--original-rig-fixture',str(tool/'fixtures/SINGLE_FRAME.aseprite'),
    '--style-fixture',str(ref/'single_frame_style_source.png'),
    '--alternate-fixture',str(ref/'alternate_walk_15f_source.png')],cwd=root,check=True)
print('PASS registered R3 topology smoke, full authored member hashes and unchanged R2 code')
