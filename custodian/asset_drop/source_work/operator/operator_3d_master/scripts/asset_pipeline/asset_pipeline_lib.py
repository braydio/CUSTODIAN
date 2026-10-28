"""Pure-Python (no Blender) helpers for the CUSTODIAN Operator 3D asset workflow: preflight, strict GLB audit, atomic staging, freeze/verify.
Everything here is deterministic and unit-testable. Nothing here uploads, selects, approves or touches runtime assets."""
import array, hashlib, json, math, os, pathlib, re, shutil, struct, subprocess

EXIT = {'OK': 0, 'USAGE': 2, 'INPUT': 3, 'DECODE': 4, 'RENDER': 5, 'COMPARE': 6, 'VERIFY': 7, 'PUBLISH': 8}
CANONICAL_IDLE_SHA = 'd4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3'
DESIGN_LOCK_SHA = '41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b'
STATUS_RUN = 'IMPORTED_REFERENCE_CANDIDATE_NOT_APPROVED'; STATUS_FROZEN = 'FROZEN_FOR_REVIEW_NOT_APPROVED'
FREEZE_SCHEMA = 'custodian.asset_candidate_freeze.v1'
NAME_RE = re.compile(r'^[a-z0-9][a-z0-9._-]{0,62}[a-z0-9]$|^[a-z0-9]$')
ALLOWED_REQUIRED_EXT = {'KHR_mesh_quantization', 'EXT_meshopt_compression', 'EXT_texture_webp', 'KHR_texture_transform', 'KHR_draco_mesh_compression'}
MAX_INPUT = 256 * 1024 * 1024

class PipelineError(Exception):
    def __init__(self, stage, msg): super().__init__(msg); self.stage = stage; self.code = EXIT[stage]; self.msg = msg

def sha256_bytes(b): return hashlib.sha256(b).hexdigest()
def sha256_file(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for c in iter(lambda: f.read(1 << 20), b''): h.update(c)
    return h.hexdigest()
def is_lfs_pointer(p):
    with open(p, 'rb') as f: return f.read(40).startswith(b'version https://git-lfs')

# ---------- preflight ----------
def validate_name(name):
    if not isinstance(name, str) or not NAME_RE.fullmatch(name) or '..' in name: raise PipelineError('USAGE', f'unsafe --name {name!r}: use 1-64 chars [a-z0-9._-], starting/ending alphanumeric, no slashes or ..')
    return name
def validate_params(target_height, elev, px_per_m):
    for k, v, lo, hi in (('--target-height', target_height, 20.0, 200.0), ('--elev', elev, 1.0, 89.0), ('--px-per-m', px_per_m, 1.0, 1000.0)):
        if not isinstance(v, (int, float)) or isinstance(v, bool) or not math.isfinite(v) or not (lo <= v <= hi): raise PipelineError('USAGE', f'{k} must be finite in [{lo}, {hi}], got {v!r}')
def safe_out_dir(out_root, name):
    out_root = pathlib.Path(out_root); validate_name(name)
    if out_root.is_symlink(): raise PipelineError('USAGE', f'--out-root is a symlink: {out_root}')
    if out_root.exists() and not out_root.is_dir(): raise PipelineError('USAGE', f'--out-root is not a directory: {out_root}')
    final = out_root / name
    if os.path.lexists(final): raise PipelineError('USAGE', f'refusing to overwrite {final}; choose a new --name')
    if final.parent.resolve() != out_root.resolve(): raise PipelineError('USAGE', 'name escapes out-root')
    return final
def find_tool(env, default):
    p = os.environ.get(env) or shutil.which(default)
    if not p or not os.access(p, os.X_OK): raise PipelineError('USAGE', f'required tool not found: {default} (set {env} to override)')
    return p
def tool_version(exe, arg='--version'):
    try: return subprocess.run([exe, arg], capture_output=True, text=True, timeout=60).stdout.strip().splitlines()[0]
    except Exception: return 'unknown'
def check_canonical(path):
    p = pathlib.Path(path)
    if not p.is_file() or is_lfs_pointer(p) or sha256_file(p) != CANONICAL_IDLE_SHA: raise PipelineError('USAGE', 'canonical idle source missing, an LFS pointer, or not the locked bytes')

# ---------- staging ----------
class Staging:
    """Build under <out_root>/.staging-<name>-<pid>; commit() renames atomically to <out_root>/<name>. Any failure removes only the staging dir."""
    def __init__(self, final): self.final = pathlib.Path(final); self.dir = self.final.parent / f'.staging-{self.final.name}-{os.getpid()}'; self.committed = False
    def __enter__(self): self.final.parent.mkdir(parents=True, exist_ok=True); self.dir.mkdir(); return self.dir
    def commit(self):
        if os.path.lexists(self.final): raise PipelineError('USAGE', f'{self.final} appeared during the run; not overwriting')
        os.rename(self.dir, self.final); self.committed = True
    def __exit__(self, et, ev, tb):
        if not self.committed and self.dir.exists() and self.dir.name.startswith('.staging-') and self.dir.parent == self.final.parent: shutil.rmtree(self.dir, ignore_errors=True)
        return False
def hash_tree(root, exclude=()):
    root = pathlib.Path(root); return {str(p.relative_to(root)): sha256_file(p) for p in sorted(root.rglob('*')) if p.is_file() and p.name not in exclude}

# ---------- strict GLB ----------
def read_glb(data):
    if len(data) < 20 or data[:4] != b'glTF': raise PipelineError('INPUT', 'bad magic: not a binary glTF (GLB)')
    ver, declared = struct.unpack_from('<II', data, 4)
    if ver != 2: raise PipelineError('INPUT', f'unsupported GLB version {ver} (only 2)')
    if declared != len(data): raise PipelineError('INPUT', f'GLB length mismatch: header {declared}, actual {len(data)} (truncated or padded)')
    off, chunks = 12, []
    while off < len(data):
        if off + 8 > len(data): raise PipelineError('INPUT', 'truncated GLB chunk header')
        ln, kind = struct.unpack_from('<II', data, off)
        if off + 8 + ln > len(data) or ln % 4: raise PipelineError('INPUT', 'invalid GLB chunk length/alignment')
        chunks.append((kind, data[off + 8: off + 8 + ln])); off += 8 + ln
    if not chunks or chunks[0][0] != 0x4E4F534A or len(chunks) > 2 or (len(chunks) == 2 and chunks[1][0] != 0x004E4942): raise PipelineError('INPUT', 'expected JSON chunk then optional BIN chunk')
    try: j = json.loads(chunks[0][1].decode('utf-8'))
    except Exception as e: raise PipelineError('INPUT', f'GLB JSON chunk is not valid JSON: {e}')
    return j, (chunks[1][1] if len(chunks) == 2 else b'')

_CT = {5120: ('b', 1), 5121: ('B', 1), 5122: ('h', 2), 5123: ('H', 2), 5125: ('I', 4), 5126: ('f', 4)}; _NC = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}
def _view_has_meshopt(bv): return 'EXT_meshopt_compression' in (bv.get('extensions') or {})
def accessor_values(j, binb, i):
    a = j['accessors'][i]; bv = j['bufferViews'][a['bufferView']]; code, sz = _CT[a['componentType']]; nc = _NC[a['type']]; n = a['count'] * nc
    base = bv.get('byteOffset', 0) + a.get('byteOffset', 0); stride = bv.get('byteStride') or sz * nc
    if stride == sz * nc:
        arr = array.array(code); arr.frombytes(binb[base: base + n * sz]); return arr
    arr = array.array(code)
    for k in range(a['count']): arr.extend(struct.unpack_from('<' + code * nc, binb, base + k * stride))
    return arr
def _finite_list(v): return isinstance(v, list) and all(isinstance(x, (int, float)) and math.isfinite(x) for x in v)

def audit_gltf(j, binb, decoded=True):
    """Strict structural audit. decoded=True demands plain buffers (post meshopt decode) and bounds-checks all geometry data."""
    if (j.get('asset') or {}).get('version') != '2.0': raise PipelineError('INPUT', 'glTF asset.version must be 2.0')
    req = set(j.get('extensionsRequired') or []); bad = sorted(req - ALLOWED_REQUIRED_EXT)
    if bad: raise PipelineError('INPUT', f'unsupported required glTF extensions: {bad}')
    meshopt_used = 'EXT_meshopt_compression' in (j.get('extensionsUsed') or [])
    if decoded and meshopt_used: raise PipelineError('DECODE', 'asset still declares EXT_meshopt_compression after decode')
    if not j.get('meshes'): raise PipelineError('INPUT', 'no meshes in asset')
    skinned = bool(j.get('skins')) or any('skin' in n for n in j.get('nodes', [])) or any(
        k in (p.get('attributes') or {}) for m in j['meshes'] for p in m.get('primitives', []) for k in ('JOINTS_0', 'WEIGHTS_0'))
    if skinned: raise PipelineError('INPUT', 'skinned/rigged glTF is not supported: this pipeline renders static models and would produce misleading renders (armature measured/cropped); use the rig_diag tools or a static export')
    bufs = j.get('buffers') or []; views = j.get('bufferViews') or []; accs = j.get('accessors') or []
    if not bufs or bufs[0].get('byteLength', 0) > len(binb) + 3: raise PipelineError('INPUT', 'buffer 0 larger than BIN chunk (truncated asset)')
    for k, bv in enumerate(views):
        ext = (bv.get('extensions') or {}).get('EXT_meshopt_compression')
        if ext:
            if ext['byteOffset'] + ext['byteLength'] > len(binb): raise PipelineError('INPUT', f'meshopt bufferView {k} exceeds BIN chunk')
        elif bv.get('buffer', 0) == 0 and bv.get('byteOffset', 0) + bv['byteLength'] > len(binb): raise PipelineError('INPUT', f'bufferView {k} exceeds BIN chunk')
    tris = verts = 0; has_uv = False
    for m in j['meshes']:
        for p in m.get('primitives', []):
            if p.get('mode', 4) != 4: raise PipelineError('INPUT', 'only TRIANGLES primitives are supported')
            pos = (p.get('attributes') or {}).get('POSITION')
            if pos is None or 'indices' not in p: raise PipelineError('INPUT', 'primitive needs POSITION and indices')
            has_uv = has_uv or 'TEXCOORD_0' in p['attributes']; vc = accs[pos]['count']; ic = accs[p['indices']]['count']; verts += vc
            if ic % 3: raise PipelineError('INPUT', 'index count is not a multiple of 3')
            tris += ic // 3
            if decoded:
                for name, ai in list(p['attributes'].items()) + [('indices', p['indices'])]:
                    a = accs[ai]; bv = views[a['bufferView']]; need = a.get('byteOffset', 0) + (bv.get('byteStride') or _CT[a['componentType']][1] * _NC[a['type']]) * (a['count'] - 1) + _CT[a['componentType']][1] * _NC[a['type']]
                    if need > bv['byteLength'] or bv.get('byteOffset', 0) + bv['byteLength'] > len(binb): raise PipelineError('INPUT', f'accessor {name} exceeds its bufferView/BIN chunk')
                idx = accessor_values(j, binb, p['indices'])
                if len(idx) and max(idx) >= vc: raise PipelineError('INPUT', f'index out of range: max {max(idx)} >= vertex count {vc}')
                if accs[pos]['componentType'] == 5126:
                    pv = accessor_values(j, binb, pos)
                    if any(not math.isfinite(x) for x in pv): raise PipelineError('INPUT', 'non-finite (NaN/Inf) vertex positions')
    for n in j.get('nodes', []):
        for key in ('translation', 'scale', 'rotation', 'matrix'):
            if key in n and not _finite_list(n[key]): raise PipelineError('INPUT', f'non-finite node {key}')
        if 'scale' in n and any(s == 0 for s in n['scale']): raise PipelineError('INPUT', 'zero node scale')
    mats = j.get('materials') or []; pbr = [(m.get('pbrMetallicRoughness') or {}) for m in mats]
    return {'extensions_used': j.get('extensionsUsed', []), 'extensions_required': sorted(req), 'meshopt': meshopt_used, 'meshes': len(j['meshes']), 'vertices': verts, 'triangles': tris,
            'has_texcoord0': has_uv, 'materials': len(mats), 'images': len(j.get('images') or []), 'textures': len(j.get('textures') or []),
            'has_base_color_texture': any('baseColorTexture' in p for p in pbr), 'has_metal_rough_texture': any('metallicRoughnessTexture' in p for p in pbr), 'has_normal_texture': any('normalTexture' in m for m in mats),
            'texture_transform_used': 'KHR_texture_transform' in (j.get('extensionsUsed') or [])}

# ---------- freeze / verify ----------
def git_blob(path, cwd): return subprocess.run(['git', 'hash-object', str(path)], capture_output=True, text=True, cwd=cwd).stdout.strip() or None
def build_freeze_manifest(module_root, name, files, provenance, params, tools, script_blobs, canonical_rel, base_note=''):
    root = pathlib.Path(module_root).resolve(); entries = []
    for rel in sorted(files):
        p = (root / rel).resolve()
        if root not in p.parents or not p.is_file(): raise PipelineError('VERIFY', f'cannot freeze {rel}: missing or outside module root')
        if is_lfs_pointer(p): raise PipelineError('VERIFY', f'{rel} is a Git LFS pointer, not materialised bytes')
        entries.append({'path': rel, 'sha256': sha256_file(p), 'bytes': p.stat().st_size})
    return {'schema': FREEZE_SCHEMA, 'name': name, 'status': STATUS_FROZEN, 'approved': False, 'best_candidate': None, 'runtime_selection': False, 'note': base_note or 'Frozen for visual review only; not approved, not selected, no runtime/manifest/SpriteFrames/FPS change.',
            'canonical': {'idle_source': canonical_rel, 'idle_sha256': CANONICAL_IDLE_SHA, 'design_lock_sha256': DESIGN_LOCK_SHA}, 'provenance': provenance, 'render_params': params, 'tools': tools, 'script_blob_revisions': script_blobs, 'files': entries}
def verify_freeze(manifest_path, module_root):
    """Return a list of problems (empty = OK). Fails on mutation, missing/LFS-pointer files, bad status or wrong canonical bytes."""
    root = pathlib.Path(module_root).resolve(); problems = []
    try: m = json.loads(pathlib.Path(manifest_path).read_text())
    except Exception as e: return [f'manifest unreadable: {e}']
    if m.get('schema') != FREEZE_SCHEMA: problems.append('wrong schema')
    if m.get('status') != STATUS_FROZEN: problems.append(f"status must be {STATUS_FROZEN}, got {m.get('status')!r}")
    if m.get('approved') is not False or m.get('best_candidate') is not None or m.get('runtime_selection') is not False: problems.append('approval/selection fields must be false/null')
    c = m.get('canonical', {}); cp = (root / c.get('idle_source', '')).resolve()
    if c.get('idle_sha256') != CANONICAL_IDLE_SHA: problems.append('manifest canonical sha is not the locked value')
    if not cp.is_file() or is_lfs_pointer(cp) or sha256_file(cp) != CANONICAL_IDLE_SHA: problems.append('canonical idle bytes missing, LFS pointer, or wrong')
    if not m.get('files'): problems.append('no files listed')
    for e in m.get('files', []):
        p = (root / e['path']).resolve()
        if root not in p.parents: problems.append(f"{e['path']}: outside module root"); continue
        if not p.is_file(): problems.append(f"{e['path']}: missing"); continue
        if is_lfs_pointer(p): problems.append(f"{e['path']}: Git LFS pointer (object not materialised)"); continue
        if p.stat().st_size != e['bytes'] or sha256_file(p) != e['sha256']: problems.append(f"{e['path']}: MUTATED (hash/size differs)")
    return problems

def strip_png_metadata(directory):
    """Blender writes File/Date/Time/host text chunks into every PNG (nondeterministic + local-path leakage). Re-save pixels only."""
    from PIL import Image
    for p in sorted(pathlib.Path(directory).glob('*.png')):
        im = Image.open(p); im.load(); im.save(p, format='PNG')
