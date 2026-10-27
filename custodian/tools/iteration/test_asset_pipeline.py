"""Unit tests for the Operator 3D asset workflow (custodian/asset_drop/source_work/operator/operator_3d_master/scripts/asset_pipeline).
Fast synthetic tests need no Blender, no network and no Dropbox secrets. Optional integration (real Blender): CUSTODIAN_BLENDER_TESTS=1.
Run: python3 -m unittest custodian.tools.iteration.test_asset_pipeline -v"""
import contextlib, hashlib, io, json, math, os, pathlib, shutil, stat, struct, subprocess, sys, tempfile, unittest
from unittest import mock

CUSTODIAN = pathlib.Path(__file__).resolve().parents[2]
MOD = CUSTODIAN / 'asset_drop/source_work/operator/operator_3d_master'
PIPE = MOD / 'scripts/asset_pipeline'
sys.path.insert(0, str(PIPE)); sys.path.insert(0, str(MOD / 'scripts'))
import asset_pipeline_lib as L  # noqa: E402
import run_asset as R  # noqa: E402

CANON = MOD.parent / 'operator_2_5d_first_animation/unarmed_posture_idle_relaxed_01_full_body_v1_source.png'
CANON_OK = CANON.is_file() and not L.is_lfs_pointer(CANON) and L.sha256_file(CANON) == L.CANONICAL_IDLE_SHA
MESHOPT_FIXTURE = MOD / 'meshy_candidates/meshy-002_textured/source/operator_meshy_model3_meshopt_compressed.glb'
FIXTURE_OK = MESHOPT_FIXTURE.is_file() and not L.is_lfs_pointer(MESHOPT_FIXTURE)

def tiny_png(bad=False):
    import zlib
    def ch(t, d): return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xFFFFFFFF)
    out = b'\x89PNG\r\n\x1a\n' + ch(b'IHDR', struct.pack('>IIBBBBB', 2, 2, 8, 6, 0, 0, 0)) + ch(b'IDAT', zlib.compress((b'\x00' + b'\xff\x80\x40\xff' * 2) * 2)) + ch(b'IEND', b'')
    return out[:-20] + b'\x00' * 8 + out[-12:] if bad else out
def pad4(b, fill=b'\x00'): return b + fill * ((4 - len(b) % 4) % 4)
def make_glb(textured=False, nan=False, bad_index=False, version=2, truncate=0, len_delta=0, req_ext=None, idx_count=3, magic=b'glTF', no_json_first=False, solid=False, bad_png=False):
    pos = [(0, 0, 0), (1, 0, 0), (0, 1, 0), (0, 0, 1)]
    if nan: pos[1] = (float('nan'), 0, 0)
    idx = [0, 1, 2] if idx_count == 3 else [0, 1, 2, 3]
    if solid: idx = [0, 2, 1, 0, 1, 3, 0, 3, 2, 1, 2, 3]   # closed tetrahedron, outward CCW winding (renders from every direction)
    if bad_index: idx = [0, 1, 9]
    pb = b''.join(struct.pack('<3f', *p) for p in pos); ib = struct.pack(f'<{len(idx)}H', *idx); ib = pad4(ib)
    ub = b''.join(struct.pack('<2f', x, y) for x, y in ((0, 0), (1, 0), (0, 1), (1, 1)))
    png = tiny_png(bad_png)
    binb = pb + ib + (ub + pad4(png) if textured else b''); views = [{'buffer': 0, 'byteOffset': 0, 'byteLength': len(pb)}, {'buffer': 0, 'byteOffset': len(pb), 'byteLength': len(ib)}]
    accs = [{'bufferView': 0, 'componentType': 5126, 'count': 4, 'type': 'VEC3', 'min': [0, 0, 0], 'max': [1, 1, 1]}, {'bufferView': 1, 'componentType': 5123, 'count': len(idx), 'type': 'SCALAR'}]
    prim = {'attributes': {'POSITION': 0}, 'indices': 1}; j = {'asset': {'version': '2.0'}, 'scene': 0, 'scenes': [{'nodes': [0]}], 'nodes': [{'mesh': 0}], 'meshes': [{'primitives': [prim]}], 'buffers': [{'byteLength': len(binb)}]}
    if textured:
        views += [{'buffer': 0, 'byteOffset': len(pb) + len(ib), 'byteLength': len(ub)}, {'buffer': 0, 'byteOffset': len(pb) + len(ib) + len(ub), 'byteLength': len(png)}]
        accs.append({'bufferView': 2, 'componentType': 5126, 'count': 4, 'type': 'VEC2'}); prim['attributes']['TEXCOORD_0'] = 2; prim['material'] = 0
        tt = {'KHR_texture_transform': {'offset': [0, 0], 'scale': [4.0, 4.0]}}
        j.update({'images': [{'bufferView': 3, 'mimeType': 'image/png'}], 'textures': [{'source': 0}], 'extensionsUsed': ['KHR_texture_transform'],
                  'materials': [{'pbrMetallicRoughness': {'baseColorTexture': {'index': 0, 'extensions': tt}}, 'normalTexture': {'index': 0}}]})
    if req_ext: j['extensionsRequired'] = req_ext; j.setdefault('extensionsUsed', []).extend(req_ext)
    j['bufferViews'] = views; j['accessors'] = accs
    jb = pad4(json.dumps(j).encode(), b' '); bb = pad4(binb)
    chunks = struct.pack('<II', len(jb), 0x4E4F534A) + jb + struct.pack('<II', len(bb), 0x004E4942) + bb
    if no_json_first: chunks = struct.pack('<II', len(bb), 0x004E4942) + bb
    out = magic + struct.pack('<II', version, 12 + len(chunks) + len_delta) + chunks
    return out[:len(out) - truncate] if truncate else out

def write(path, data): pathlib.Path(path).write_bytes(data); return path
def fake_tool(path, body): write(path, ('#!/bin/sh\n' + body + '\n').encode()); os.chmod(path, 0o755); return str(path)

class Quiet:
    def __enter__(self): self.o, self.e = io.StringIO(), io.StringIO(); self.c1, self.c2 = contextlib.redirect_stdout(self.o), contextlib.redirect_stderr(self.e); self.c1.__enter__(); self.c2.__enter__(); return self
    def __exit__(self, *a): self.c2.__exit__(*a); self.c1.__exit__(*a)

class GlbAuditTests(unittest.TestCase):
    def audit(self, data, decoded=True): j, b = L.read_glb(data); return L.audit_gltf(j, b, decoded=decoded)
    def test_valid_untextured(self):
        a = self.audit(make_glb()); self.assertEqual((a['vertices'], a['triangles'], a['has_texcoord0'], a['materials']), (4, 1, False, 0))
    def test_valid_textured_with_uv_and_transform(self):
        a = self.audit(make_glb(textured=True)); self.assertTrue(a['has_texcoord0'] and a['texture_transform_used'] and a['has_base_color_texture'] and a['has_normal_texture']); self.assertEqual(a['images'], 1)
    def test_bad_container(self):
        for kw in ({'magic': b'GLTF'}, {'version': 1}, {'truncate': 9}, {'len_delta': 4}, {'no_json_first': True}):
            with self.subTest(kw), self.assertRaises(L.PipelineError) as c: self.audit(make_glb(**kw))
            self.assertEqual(c.exception.code, L.EXIT['INPUT'])
    def test_short_and_garbage(self):
        for d in (b'', b'glTF', os.urandom(64)):
            with self.assertRaises(L.PipelineError): L.read_glb(d)
    def test_nan_positions_and_bad_indices(self):
        for kw, frag in (({'nan': True}, 'non-finite'), ({'bad_index': True}, 'out of range'), ({'idx_count': 4}, 'multiple of 3')):
            with self.subTest(kw), self.assertRaises(L.PipelineError) as c: self.audit(make_glb(**kw))
            self.assertIn(frag, c.exception.msg)
    def test_unsupported_required_extension(self):
        with self.assertRaises(L.PipelineError) as c: self.audit(make_glb(req_ext=['KHR_materials_unlit_FAKE']))
        self.assertIn('unsupported required', c.exception.msg)
    def test_meshopt_after_decode_is_rejected(self):
        j, b = L.read_glb(make_glb()); j['extensionsUsed'] = ['EXT_meshopt_compression']
        with self.assertRaises(L.PipelineError) as c: L.audit_gltf(j, b, decoded=True)
        self.assertEqual(c.exception.stage, 'DECODE')
    def test_nonfinite_node_transform(self):
        j, b = L.read_glb(make_glb()); j['nodes'][0]['translation'] = [0, float('inf'), 0]
        with self.assertRaises(L.PipelineError): L.audit_gltf(j, b)

class PreflightTests(unittest.TestCase):
    def setUp(self): self.tmp = pathlib.Path(tempfile.mkdtemp()); self.addCleanup(shutil.rmtree, self.tmp, True)
    def test_names(self):
        for bad in ('../x', '/abs', 'a/b', '', 'UPPER', 'x' * 70, '..', 'a..b', '.hidden', 'sp ace', None, 'x\n'):
            with self.subTest(bad), self.assertRaises(L.PipelineError): L.validate_name(bad)
        for ok in ('meshy-003', 'a', 'x1.2_y'): L.validate_name(ok)
    def test_params(self):
        L.validate_params(85, 45, 50)
        for bad in ((float('nan'), 45, 50), (85, float('inf'), 50), (-1, 45, 50), (85, 0, 50), (85, 90, 50), (85, 45, 0), (True, 45, 50), ('85', 45, 50), (85, 45, -50)):
            with self.subTest(bad), self.assertRaises(L.PipelineError): L.validate_params(*bad)
    def test_collision_symlink_and_root_symlink(self):
        (self.tmp / 'taken').mkdir()
        with self.assertRaises(L.PipelineError): L.safe_out_dir(self.tmp, 'taken')
        os.symlink(self.tmp / 'taken', self.tmp / 'link')
        with self.assertRaises(L.PipelineError): L.safe_out_dir(self.tmp, 'link')
        os.symlink(self.tmp, self.tmp.parent / (self.tmp.name + '_root'))
        try:
            with self.assertRaises(L.PipelineError): L.safe_out_dir(self.tmp.parent / (self.tmp.name + '_root'), 'fresh')
        finally: os.unlink(self.tmp.parent / (self.tmp.name + '_root'))
        self.assertEqual(L.safe_out_dir(self.tmp, 'fresh'), self.tmp / 'fresh')
    def test_missing_tool(self):
        with mock.patch.dict(os.environ, {'CUSTODIAN_BLENDER': str(self.tmp / 'nope')}), self.assertRaises(L.PipelineError) as c: L.find_tool('CUSTODIAN_BLENDER', 'blender')
        self.assertEqual(c.exception.code, 2)

class StagingTests(unittest.TestCase):
    def setUp(self): self.tmp = pathlib.Path(tempfile.mkdtemp()); self.addCleanup(shutil.rmtree, self.tmp, True)
    def test_failure_leaves_nothing(self):
        try:
            with L.Staging(self.tmp / 'c') as st: (st / 'f').write_text('x'); raise RuntimeError('boom')
        except RuntimeError: pass
        self.assertEqual(list(self.tmp.iterdir()), [])
    def test_commit_is_atomic_and_final(self):
        s = L.Staging(self.tmp / 'c')
        with s as st: (st / 'f').write_text('x'); s.commit()
        self.assertEqual([p.name for p in self.tmp.iterdir()], ['c']); self.assertTrue((self.tmp / 'c/f').exists())
    def test_commit_never_overwrites(self):
        s = L.Staging(self.tmp / 'c')
        with s as st:
            (self.tmp / 'c').mkdir()
            with self.assertRaises(L.PipelineError): s.commit()
        self.assertEqual(list(self.tmp.glob('.staging-*')), [])

class CliPreflightTests(unittest.TestCase):
    def setUp(self):
        self.tmp = pathlib.Path(tempfile.mkdtemp()); self.addCleanup(shutil.rmtree, self.tmp, True); self.out = self.tmp / 'out'
        self.glb = write(self.tmp / 'a.glb', make_glb(textured=True)); self.ok_tool = fake_tool(self.tmp / 'ok.sh', 'exit 0'); self.bad_tool = fake_tool(self.tmp / 'bad.sh', 'echo failing; exit 1')
    def run_cli(self, *args, env=None):
        with mock.patch.dict(os.environ, env or {}), Quiet() as q: rc = R.main(list(args)); return rc, q.e.getvalue(), q.o.getvalue()
    def base(self, name='t1'): return ['run', str(self.glb), '--name', name, '--out-root', str(self.out)]
    def test_nonexistent_and_garbage_input(self):
        self.assertEqual(self.run_cli('run', str(self.tmp / 'nope.glb'), '--name', 'x', '--out-root', str(self.out))[0], 3)
        g = write(self.tmp / 'g.glb', b'not a model at all, definitely'); self.assertEqual(self.run_cli('run', str(g), '--name', 'x', '--out-root', str(self.out))[0], 3)
        self.assertFalse(self.out.exists())
    def test_bad_glb_variants_create_nothing(self):
        for kw in ({'version': 1}, {'truncate': 12}, {'nan': True}):
            p = write(self.tmp / 'b.glb', make_glb(**kw)); rc = self.run_cli('run', str(p), '--name', 'bad', '--out-root', str(self.out), env={'CUSTODIAN_BLENDER': self.ok_tool})[0]
            self.assertIn(rc, (3, 4), kw)
        self.assertEqual(list(self.out.iterdir()) if self.out.exists() else [], [])
    def test_unsafe_name_and_params(self):
        for args in (['--name', '../x'], ['--name', 'ok', '--target-height', 'nan'], ['--name', 'ok', '--elev', '-5'], ['--name', 'ok', '--px-per-m', '0']):
            self.assertEqual(self.run_cli('run', str(self.glb), *args, '--out-root', str(self.out), env={'CUSTODIAN_BLENDER': self.ok_tool})[0], 2, args)
        self.assertFalse(self.out.exists())
    def test_meshy_requires_explicit_flag_and_version(self):
        m = write(self.tmp / 'x.meshy', b'MESHY.AI' + struct.pack('<H', 1) + os.urandom(9000)); rc, err, _ = self.run_cli('run', str(m), '--name', 'x', '--out-root', str(self.out))
        self.assertEqual(rc, 2); self.assertIn('confirm-authorized', err)
        m2 = write(self.tmp / 'y.meshy', b'MESHY.AI' + struct.pack('<H', 7) + os.urandom(9000)); self.assertEqual(self.run_cli('run', str(m2), '--name', 'y', '--confirm-authorized', '--out-root', str(self.out))[0], 3)
        self.assertFalse(self.out.exists())
    def test_missing_blender_is_a_clean_error(self):
        rc, err, _ = self.run_cli(*self.base(), env={'CUSTODIAN_BLENDER': str(self.tmp / 'missing')}); self.assertEqual(rc, 2); self.assertIn('blender', err); self.assertFalse(self.out.exists())
    @unittest.skipUnless(FIXTURE_OK, 'meshopt fixture not materialised')
    def test_missing_node_for_meshopt_input(self):
        rc, err, _ = self.run_cli('run', str(MESHOPT_FIXTURE), '--name', 'x', '--out-root', str(self.out), env={'CUSTODIAN_BLENDER': self.ok_tool, 'CUSTODIAN_NODE': str(self.tmp / 'nonode')}); self.assertEqual(rc, 2); self.assertIn('node', err)
    @unittest.skipUnless(CANON_OK, 'canonical idle bytes not materialised')
    def test_dry_run_creates_nothing(self):
        rc, _, out = self.run_cli(*self.base(), '--dry-run', env={'CUSTODIAN_BLENDER': self.ok_tool}); self.assertEqual(rc, 0); self.assertTrue(json.loads(out)['dry_run']); self.assertFalse(self.out.exists())
    @unittest.skipUnless(CANON_OK, 'canonical idle bytes not materialised')
    def test_blender_failure_is_nonzero_clean_and_never_uploads(self):
        calls = []; real = subprocess.run
        def spy(cmd, *a, **k): calls.append([str(c) for c in cmd]); return real(cmd, *a, **k)
        with mock.patch.object(R.subprocess, 'run', spy):
            rc, err, _ = self.run_cli(*self.base(), env={'CUSTODIAN_BLENDER': self.bad_tool})
        self.assertEqual(rc, 5); self.assertIn('Blender render failed', err)
        self.assertEqual([p.name for p in self.out.iterdir()], [], 'no half-built candidate or staging dir may remain')
        self.assertFalse([c for c in calls if any('publish_review' in x or 'rclone' in x for x in c)], 'run must never publish')
    @unittest.skipUnless(CANON_OK, 'canonical idle bytes not materialised')
    def test_blender_without_output_json_fails(self):
        rc, _, _ = self.run_cli(*self.base(), env={'CUSTODIAN_BLENDER': self.ok_tool}); self.assertEqual(rc, 5); self.assertEqual(list(self.out.iterdir()), [])
    @unittest.skipUnless(CANON_OK, 'canonical idle bytes not materialised')
    def test_existing_name_is_never_overwritten(self):
        (self.out / 't1').mkdir(parents=True); (self.out / 't1/keep').write_text('x')
        rc, err, _ = self.run_cli(*self.base(), env={'CUSTODIAN_BLENDER': self.ok_tool}); self.assertEqual(rc, 2); self.assertEqual((self.out / 't1/keep').read_text(), 'x')
    def test_backwards_compatible_invocation_and_help(self):
        with self.assertRaises(SystemExit) as c, Quiet(): R.main(['--help'])
        self.assertEqual(c.exception.code, 0)
        p = R.build_parser(); a = p.parse_args(['run', 'f.glb', '--name', 'n']); self.assertTrue(a.evidence and not a.dry_run)
    def test_run_source_has_no_publish_or_freeze_path(self):
        import inspect; src = inspect.getsource(R.cmd_run); self.assertNotIn('publish', src); self.assertNotIn('freeze', src.lower().replace('frozen', ''))

@unittest.skipUnless(FIXTURE_OK and shutil.which('node'), 'needs real meshopt fixture + node')
class MeshoptTests(unittest.TestCase):
    def setUp(self): self.tmp = pathlib.Path(tempfile.mkdtemp()); self.addCleanup(shutil.rmtree, self.tmp, True)
    def decode(self, src):
        out = self.tmp / 'o.glb'; r = subprocess.run(['node', str(PIPE / 'meshopt_decode.mjs'), str(src), str(out)], capture_output=True, text=True, timeout=300); return r, out
    def test_existing_compressed_glb_decodes_and_audits(self):
        r, out = self.decode(MESHOPT_FIXTURE); self.assertEqual(r.returncode, 0, r.stderr[-500:]); a = L.audit_gltf(*L.read_glb(out.read_bytes()))
        self.assertEqual((a['triangles'], a['vertices'], a['has_texcoord0'], a['images']), (1251670, 660202, True, 3)); self.assertFalse(a['meshopt'])
    def test_corrupted_compressed_buffer_is_rejected(self):
        d = bytearray(MESHOPT_FIXTURE.read_bytes()); jl = struct.unpack_from('<I', d, 12)[0]; start = 20 + jl + 8 + 2_900_000
        for k in range(start, start + 4000): d[k] ^= 0xFF
        bad = write(self.tmp / 'bad.glb', bytes(d)); r, out = self.decode(bad)
        if r.returncode == 0:
            with self.assertRaises(L.PipelineError): L.audit_gltf(*L.read_glb(out.read_bytes()))   # decoder tolerated it: strict audit must still catch bad data
            self.skipTest('decoder produced output; audit path exercised')

class FreezeVerifyTests(unittest.TestCase):
    def setUp(self):
        self.root = pathlib.Path(tempfile.mkdtemp()); self.addCleanup(shutil.rmtree, self.root, True)
        (self.root / 'cand').mkdir(); (self.root / 'cand/a.glb').write_bytes(b'glTFxxxx'); (self.root / 'cand/r.png').write_bytes(b'png-bytes'); write(self.root / 'canon.png', b'canonical-bytes')
        self.p = mock.patch.object(L, 'CANONICAL_IDLE_SHA', hashlib.sha256(b'canonical-bytes').hexdigest()); self.p.start(); self.addCleanup(self.p.stop)
    def manifest(self, **kw):
        m = L.build_freeze_manifest(self.root, 'c', ['cand/a.glb', 'cand/r.png'], {'src': 'x'}, {'elev': 45}, {'blender': 'b'}, {'s': 'abc'}, 'canon.png', **kw); f = self.root / 'lock.json'; f.write_text(json.dumps(m, indent=1, sort_keys=True)); return f, m
    def test_ok_and_status_fields(self):
        f, m = self.manifest(); self.assertEqual(L.verify_freeze(f, self.root), []); self.assertEqual((m['status'], m['approved'], m['best_candidate'], m['runtime_selection']), (L.STATUS_FROZEN, False, None, False)); self.assertEqual(m['schema'], L.FREEZE_SCHEMA)
    def test_manifest_is_stable(self):
        _, a = self.manifest(); _, b = self.manifest(); self.assertEqual(json.dumps(a, sort_keys=True), json.dumps(b, sort_keys=True))
    def test_tamper_missing_lfs_pointer_and_canonical(self):
        f, _ = self.manifest()
        (self.root / 'cand/a.glb').write_bytes(b'glTFyyyy'); self.assertTrue(any('MUTATED' in p for p in L.verify_freeze(f, self.root)))
        (self.root / 'cand/a.glb').write_bytes(b'glTFxxxx'); self.assertEqual(L.verify_freeze(f, self.root), [])
        (self.root / 'cand/r.png').unlink(); self.assertTrue(any('missing' in p for p in L.verify_freeze(f, self.root)))
        write(self.root / 'cand/r.png', b'version https://git-lfs.github.com/spec/v1\noid sha256:00\nsize 9\n'); self.assertTrue(any('LFS' in p for p in L.verify_freeze(f, self.root)))
        (self.root / 'cand/r.png').write_bytes(b'png-bytes'); write(self.root / 'canon.png', b'other'); self.assertTrue(any('canonical' in p for p in L.verify_freeze(f, self.root)))
    def test_cannot_claim_approval(self):
        f, m = self.manifest()
        for k, v in (('approved', True), ('best_candidate', 'x'), ('runtime_selection', True), ('status', 'APPROVED')):
            m2 = dict(m); m2[k] = v; f.write_text(json.dumps(m2)); self.assertTrue(L.verify_freeze(f, self.root), k)
    def test_freezing_an_lfs_pointer_or_outside_file_fails(self):
        write(self.root / 'cand/p.glb', b'version https://git-lfs.github.com/spec/v1\n')
        with self.assertRaises(L.PipelineError): L.build_freeze_manifest(self.root, 'c', ['cand/p.glb'], {}, {}, {}, {}, 'canon.png')
        with self.assertRaises(L.PipelineError): L.build_freeze_manifest(self.root, 'c', ['../x'], {}, {}, {}, {}, 'canon.png')

PUB_STUB = '''#!/usr/bin/env python3
import json, os, sys
a = sys.argv[1:]; open(os.environ["STUB_LOG"], "a").write(json.dumps(a) + "\\n")
if os.environ.get("STUB_FAIL"): sys.exit(1)
arts = [a[i + 1] for i, x in enumerate(a) if x in ("--artifact", "--source")]; rid = a[a.index("--run-id") + 1]
h = {"status": "dry_run" if "--dry-run" in a else os.environ.get("STUB_STATUS", "uploaded"), "run_id": rid, "dropbox_path": "/CUSTODIAN/visual_review/operator-3d-master/" + rid + "/", "manifest_path": "/CUSTODIAN/x/REVIEW_MANIFEST.json",
     "file_count": len(arts) + 1, "retention_policy": "retain" if "--retain-after-review" in a else "delete-after-review"}
if "--dry-run" in a: h = {"status": "dry_run", "manifest": {"artifacts": [{"name": os.path.basename(x)} for x in arts]}}
print("CUSTODIAN_VISUAL_REVIEW_HANDOFF_JSON:" + json.dumps(h))
'''
class PublishReviewTests(unittest.TestCase):
    def setUp(self):
        self.tmp = pathlib.Path(tempfile.mkdtemp()); self.addCleanup(shutil.rmtree, self.tmp, True); self.cand = self.tmp / 'cand'; self.pack = self.cand / 'review_pack'; self.pack.mkdir(parents=True)
        for n in ('a', 'b', 'c', 'd'): write(self.pack / f'{n}.png', b'\x89PNG' + n.encode() * 50)
        write(self.pack / 'REVIEW_NOTES.md', b'notes'); self.log = self.tmp / 'log.txt'; self.pub = write(self.tmp / 'pub.py', PUB_STUB.encode()); self.rc_ok = fake_tool(self.tmp / 'rc_ok.sh', 'exit 0'); self.rc_bad = fake_tool(self.tmp / 'rc_bad.sh', 'echo mismatch >&2; exit 1')
        self.env = {'CUSTODIAN_PUBLISHER': str(self.pub), 'STUB_LOG': str(self.log), 'CUSTODIAN_RCLONE': self.rc_ok}
    def pub_cli(self, *extra, env=None):
        e = dict(self.env); e.update(env or {}); e.pop('STUB_FAIL', None) if 'STUB_FAIL' not in (env or {}) else None
        with mock.patch.dict(os.environ, e), Quiet() as q: rc = R.main(['publish-review', str(self.cand), '--reason', 'r', '--question', 'q?', *extra]); return rc, q.e.getvalue(), q.o.getvalue()
    def test_dry_run_selects_every_staged_file(self):
        rc, _, out = self.pub_cli('--dry-run'); self.assertEqual(rc, 0); d = json.loads(out); self.assertEqual((d['selected'], d['staged']), (5, 5)); self.assertFalse((self.cand / 'PUBLISHED_REVIEW.json').exists())
    def test_success_writes_receipt_only_after_remote_verification(self):
        rc, _, out = self.pub_cli('--retain-after-review'); self.assertEqual(rc, 0); r = json.loads((self.cand / 'PUBLISHED_REVIEW.json').read_text()); self.assertEqual((r['status'], r['approved'], r['retention']), ('PUBLISHED_VERIFIED', False, 'retain')); self.assertEqual(len(r['files']), 5)
    def test_publisher_failure_is_not_published(self):
        rc, err, _ = self.pub_cli(env={'STUB_FAIL': '1'}); self.assertEqual(rc, 8); self.assertFalse((self.cand / 'PUBLISHED_REVIEW.json').exists())
    def test_remote_checksum_failure_is_not_published(self):
        rc, err, _ = self.pub_cli(env={'CUSTODIAN_RCLONE': self.rc_bad}); self.assertEqual(rc, 8); self.assertIn('remote verification FAILED', err); self.assertFalse((self.cand / 'PUBLISHED_REVIEW.json').exists())
    def test_wrong_status_is_not_published(self):
        rc, _, _ = self.pub_cli(env={'STUB_STATUS': 'dry_run_only'}); self.assertEqual(rc, 8); self.assertFalse((self.cand / 'PUBLISHED_REVIEW.json').exists())
    def test_caps_and_missing_evidence_stop_before_the_publisher(self):
        for n in range(8): write(self.pack / f'x{n}.png', b'p')
        rc, *_ = self.pub_cli(); self.assertEqual(rc, 8); self.assertFalse(self.log.exists(), 'publisher must not be called over the cap')
        shutil.rmtree(self.pack); self.pack.mkdir(); write(self.pack / 'only.md', b'x'); rc, *_ = self.pub_cli(); self.assertEqual(rc, 8); self.assertFalse(self.log.exists())
    def test_reason_and_question_are_mandatory(self):
        with mock.patch.dict(os.environ, self.env), Quiet(): self.assertEqual(R.main(['publish-review', str(self.cand)]), 2)
        self.assertFalse(self.log.exists())
    def test_staged_paths_leak_no_local_candidate_path(self):
        self.pub_cli('--dry-run'); logged = self.log.read_text(); self.assertNotIn(str(self.cand), logged); self.assertIn('custodian-review-', logged); self.assertIn('--important', logged)

@unittest.skipUnless(os.environ.get('CUSTODIAN_BLENDER_TESTS') == '1' and shutil.which('blender') and CANON_OK, 'set CUSTODIAN_BLENDER_TESTS=1 with Blender + canonical bytes')
class BlenderIntegrationTests(unittest.TestCase):
    def test_textured_and_untextured_run_is_deterministic_and_verifiable(self):
        tmp = pathlib.Path(tempfile.mkdtemp()); self.addCleanup(shutil.rmtree, tmp, True); out = tmp / 'o'; hashes = []
        for name, kw in (('t-a', {'textured': True, 'solid': True}), ('t-b', {'textured': True, 'solid': True}), ('u-a', {'solid': True})):
            g = write(tmp / f'{name}.glb', make_glb(**kw))
            with Quiet(): rc = R.main(['run', str(g), '--name', name, '--out-root', str(out), '--no-evidence', '--compare-dir', str(tmp / 'none'), '--timeout', '600'])
            self.assertEqual(rc, 0, name); hashes.append(L.hash_tree(out / name / 'renders'))   # compare sheet labels carry the candidate name, so determinism is asserted on the raw renders
            with Quiet(): self.assertEqual(R.main(['verify', str(out / name)]), 0)
            rep = json.loads((out / name / 'pipeline_report.json').read_text()); self.assertEqual(rep['status'], L.STATUS_RUN); self.assertEqual(len(rep['asset']['scale_search_[scale,S_height_px]']) >= 1, True)
        self.assertEqual(hashes[0], hashes[1], 'same input must give identical renders')
        g = write(tmp / 'badtex.glb', make_glb(textured=True, solid=True, bad_png=True))
        with Quiet() as q: rc = R.main(['run', str(g), '--name', 'badtex', '--out-root', str(out), '--no-evidence', '--timeout', '600'])
        self.assertEqual(rc, 5, 'undecodable texture must fail the render stage'); self.assertFalse((out / 'badtex').exists())
        (out / 't-a/renders/128_S.png').write_bytes(b'tamper')
        with Quiet(): self.assertEqual(R.main(['verify', str(out / 't-a')]), 7)

if __name__ == '__main__': unittest.main()
