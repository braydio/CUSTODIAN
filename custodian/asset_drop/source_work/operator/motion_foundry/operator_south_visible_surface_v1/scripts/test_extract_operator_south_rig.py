#!/usr/bin/env python3
"""Independent bounded regression tests for the exact pinned visible-surface split."""
from __future__ import annotations
import csv
import hashlib
import importlib.util
import json
import shutil
import tempfile
import unittest
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'source/CUSTODIAN_OPERATOR_RUNTIME_REFERENCE_128.aseprite'
SCRIPT=ROOT/'scripts/extract_operator_south_rig.py'
spec=importlib.util.spec_from_file_location('operator_south_rig_extract',SCRIPT)
assert spec and spec.loader
mod=importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


class ExtractorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp=tempfile.TemporaryDirectory(prefix='operator_south_rig_test_')
        cls.out=Path(cls.temp.name)/'pass'
        cls.report=mod.write_outputs(SRC,cls.out)

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def test_original_source_and_pixel_ledger(self):
        self.assertEqual(mod.sha(SRC.read_bytes()),mod.SOURCE_SHA256)
        src=Image.open(self.out/'source_south_visible_frame.png').convert('RGBA')
        with (self.out/'pixel_ownership.csv').open(newline='') as f: rows=list(csv.DictReader(f))
        self.assertEqual(len(rows),2440)
        self.assertEqual(len({(int(r['x']),int(r['y'])) for r in rows}),2440)
        for record in rows:
            x,y=int(record['x']),int(record['y'])
            self.assertEqual(src.getpixel((x,y)),tuple(int(record[k]) for k in ('r','g','b','a')))
        self.assertEqual(sum(row['assignment_method']=='nearest_fallback' for row in rows),23)

    def test_partition_and_aseprite_exact_reassembly(self):
        src=Image.open(self.out/'source_south_visible_frame.png')
        out=Image.open(self.out/'reassembled_exact.png')
        self.assertEqual(src.tobytes(),out.tobytes())
        native,names=mod.read_layered_aseprite((self.out/'operator_south_segmented_source.aseprite').read_bytes())
        self.assertEqual(native[0].tobytes(),src.tobytes())
        self.assertEqual(names,[p[0] for p in mod.PARTS])

    def test_mf1_structure_hierarchy_parts_and_absolute_registration(self):
        rig=json.loads((self.out/'rig.json').read_text())
        m=json.loads((self.out/'motion_static_proof.json').read_text())
        self.assertEqual(rig['schema'],'custodian.motion_foundry.rig.v1')
        self.assertEqual(m['schema'],'custodian.motion_foundry.motion.v1')
        self.assertEqual(rig['root'],[64,106]);self.assertEqual(rig['ground'],[64,107])
        self.assertEqual(rig['frame_size'],[128,128])
        self.assertEqual(rig['reference_profile_sha256'],mod.PROFILE_SHA256)
        self.assertEqual(len(rig['parts']),23)
        self.assertEqual(m['frame_count'],15)
        self.assertIsNone(m['fps'])
        self.assertEqual(len(m['tracks']),len(rig['parts']))
        self.assertEqual(len({x['draw_order'] for x in rig['parts']}),len(rig['parts']))
        names={x['id'] for x in rig['parts']}
        for p in rig['parts']:
            self.assertIn(p['parent'],names|{None})
            img=Image.open(self.out/'parts'/p['source'])
            self.assertEqual(img.size,(128,128));self.assertEqual(img.mode,'RGBA')
            self.assertLessEqual(set(img.getchannel('A').tobytes()),{0,255})
            self.assertEqual(mod.sha((self.out/'parts'/p['source']).read_bytes()),p['sha256'])
        for k in mod.HIDDEN_PLACEHOLDERS:
            self.assertEqual(Image.open(self.out/'parts'/f'{k}.png').getchannel('A').getbbox(),None)

    def test_static_15_frame_sample_is_not_claimed_as_real_motion(self):
        parts=[(p[0],Image.open(self.out/'parts'/f'{p[0]}.png')) for p in mod.PARTS]
        src=Image.open(self.out/'source_south_visible_frame.png')
        sheet=Image.new('RGBA',(1920,128))
        for fi in range(15):
            canvas=Image.new('RGBA',(128,128))
            for name,img in parts:canvas.alpha_composite(img)
            self.assertEqual(canvas.tobytes(),src.tobytes())
            sheet.alpha_composite(canvas,(fi*128,0))
        self.assertEqual(sheet.size,(1920,128))
        self.assertTrue(all(tr['keys'][0]['offset']==[0,0] and tr['keys'][-1]['offset']==[0,0]
                            for tr in json.loads((self.out/'motion_static_proof.json').read_text())['tracks']))

    def test_reproducibility(self):
        other=Path(self.temp.name)/'repeat'
        mod.write_outputs(SRC,other)
        def inventory(base):
            return {p.relative_to(base).as_posix():hashlib.sha256(p.read_bytes()).hexdigest()
                    for p in base.rglob('*') if p.is_file()}
        self.assertEqual(inventory(self.out),inventory(other))

    def test_mutated_source_rejects_before_any_output(self):
        corrupt=Path(self.temp.name)/'corrupt.aseprite'
        raw=bytearray(SRC.read_bytes());raw[-1]^=1;corrupt.write_bytes(raw)
        rejected=Path(self.temp.name)/'reject'
        with self.assertRaisesRegex(ValueError,'Original character source has changed'):
            mod.write_outputs(corrupt,rejected)
        self.assertFalse(rejected.exists())

    def test_no_hidden_geometry_invented(self):
        j=json.loads((self.out/'segmentation_manifest.json').read_text())
        self.assertEqual(j['visible_pixel_count'],2440)
        self.assertEqual(set(j['blank_occluded_rig_parts']),mod.HIDDEN_PLACEHOLDERS)
        self.assertFalse(j['hidden_geometry_reconstructed'])
        self.assertFalse(j['occluded_pixels_known'])
        self.assertTrue(j['original_pixel_reassembly_exact'])
        self.assertTrue(j['aseprite_layered_file_roundtrip_exact'])


if __name__=='__main__':
    unittest.main(verbosity=2)
