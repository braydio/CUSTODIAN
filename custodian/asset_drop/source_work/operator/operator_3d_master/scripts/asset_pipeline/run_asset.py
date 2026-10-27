#!/usr/bin/env python3
# /// script
# dependencies = ["cryptography", "pillow", "numpy"]
# ///
"""CUSTODIAN Operator 3D asset workflow:  run -> verify -> freeze -> publish-review   (each step explicit; a plain `run` never uploads or locks)

  run             input (.glb default; legacy gated .meshy) -> strict audit -> meshopt decode -> Blender ground + ONE uniform scale ->
                  8 unmirrored directions at 45deg/50px/m (native 128 + 512) -> compare sheet vs the SHA-verified canonical idle -> review_pack/ (11 files)
  verify          check a candidate dir (output_hashes.json) or a frozen lock manifest; non-zero on any mutation / missing LFS bytes / wrong canonical bytes
  freeze          write locks/<name>/FROZEN_CANDIDATE_MANIFEST.json (status FROZEN_FOR_REVIEW_NOT_APPROVED); never approves or selects
  publish-review  stage the review pack to a neutral temp dir and hand it to the EXISTING custodian/tools/iteration/publish_review_artifacts.py (opt-in)

Back-compatible: `run_asset.py INPUT --name X` == `run_asset.py run INPUT --name X`. Exit codes: 0 ok, 2 usage/preflight, 3 input, 4 decode, 5 render, 6 compare, 7 verify, 8 publish.
Does NOT rig, pose, decimate, select-best, approve art, or touch manifests/SpriteFrames/runtime/FPS."""
import argparse, json, os, pathlib, shutil, subprocess, sys, tempfile, datetime
HERE = pathlib.Path(__file__).resolve().parent; ROOT = HERE.parents[1]; sys.path.insert(0, str(HERE)); sys.path.insert(0, str(ROOT / 'scripts'))
from asset_pipeline_lib import *  # noqa
SUBS = ('run', 'verify', 'freeze', 'publish-review')
REVIEW_FILES_MAX, REVIEW_MIB_MAX = 12, 50

def run_cmd(cmd, stage, timeout, what):
    try: r = subprocess.run([str(c) for c in cmd], capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired: raise PipelineError(stage, f'{what} timed out after {timeout}s')
    except OSError as e: raise PipelineError(stage, f'{what} could not start: {e}')
    return r
def tail(r): return (r.stdout + r.stderr).strip()[-1200:]

# ---------------------------------------------------------------- run
def cmd_run(a):
    validate_name(a.name); validate_params(a.target_height, a.elev, a.px_per_m)
    if not (isinstance(a.timeout, int) and 10 <= a.timeout <= 7200): raise PipelineError('USAGE', '--timeout must be 10..7200 seconds')
    final = safe_out_dir(a.out_root, a.name)
    inp = pathlib.Path(a.input)
    if inp.is_symlink() or not inp.is_file() or not os.access(inp, os.R_OK): raise PipelineError('INPUT', f'input is not a readable regular file: {inp.name}')
    size = inp.stat().st_size
    if size < 20 or size > MAX_INPUT: raise PipelineError('INPUT', f'input size {size} out of range')
    blob = inp.read_bytes(); rep = {'name': a.name, 'status': STATUS_RUN, 'input': {'basename': inp.name, 'sha256': sha256_bytes(blob), 'bytes': size}}
    if blob[:8] == b'MESHY.AI':
        if not a.confirm_authorized: raise PipelineError('USAGE', '.meshy is an encrypted legacy container: pass --confirm-authorized (your own assertion that you are entitled to process it); standard GLB export is the supported path')
        import meshy_container
        try: hv = meshy_container.header_info(blob)
        except ValueError as e: raise PipelineError('INPUT', str(e))
        if hv['version'] != meshy_container.SUPPORTED_VERSION: raise PipelineError('INPUT', f"unsupported Meshy container version {hv['version']} (only v1)")
        try: import cryptography  # noqa
        except ImportError: raise PipelineError('USAGE', 'missing dependency: cryptography (run via `uv run`)')
        try: glb = meshy_container.to_glb(blob)
        except ValueError as e: raise PipelineError('INPUT', str(e))
        rep['container'] = {'kind': 'meshy_v1', 'authenticated': False, 'note': 'auth tag skipped; --confirm-authorized is a user assertion, not proof'}
    elif blob[:4] == b'glTF': glb = blob; rep['container'] = {'kind': 'glb'}
    else: raise PipelineError('INPUT', 'unrecognised input: expected GLB (or gated legacy .meshy v1)')
    j, binb = read_glb(glb); caudit = audit_gltf(j, binb, decoded='EXT_meshopt_compression' not in (j.get('extensionsUsed') or []))   # plain GLB: full geometry audit now
    needs_node = caudit['meshopt']
    blender = find_tool('CUSTODIAN_BLENDER', 'blender'); node = find_tool('CUSTODIAN_NODE', 'node') if needs_node else None
    from build_review import SRC, DIRS, BG, src_cell
    check_canonical(SRC)
    plan = {'name': a.name, 'out': str(final), 'container': rep['container']['kind'], 'meshopt_decode': needs_node, 'audit': caudit,
            'params': {'elev_deg': a.elev, 'px_per_m': a.px_per_m, 'target_S_height_px': a.target_height}, 'evidence_pack': a.evidence}
    if a.dry_run: print(json.dumps({'dry_run': True, 'plan': plan}, indent=1)); return 0
    stg = Staging(final)
    with stg as st:
        (st / 'source').mkdir(); (st / 'renders').mkdir()
        (st / 'source/container.glb').write_bytes(glb); dec = st / 'asset_decoded.glb'
        if needs_node:
            r = run_cmd([node, HERE / 'meshopt_decode.mjs', st / 'source/container.glb', dec], 'DECODE', a.timeout, 'meshopt decode')
            if r.returncode or not dec.exists(): raise PipelineError('DECODE', f'meshopt decode failed (exit {r.returncode}): {tail(r)}')
            rep['meshopt'] = 'decoded locally (three.js decoder)'
        else: shutil.copyfile(st / 'source/container.glb', dec); rep['meshopt'] = 'not used'
        dj, db = read_glb(dec.read_bytes()); daudit = audit_gltf(dj, db, decoded=True)
        rep.update({'container_audit': caudit, 'decoded_audit': daudit, 'container_sha256': sha256_file(st / 'source/container.glb'), 'decoded_sha256': sha256_file(dec)})
        r = run_cmd([blender, '-b', '--python', HERE / 'blender_render.py', '--', dec, st / 'renders', a.elev, a.px_per_m, a.target_height], 'RENDER', a.timeout, 'Blender render')
        line = [l for l in r.stdout.splitlines() if l.startswith('PIPELINE_JSON')]
        if r.returncode or not line: raise PipelineError('RENDER', f'Blender render failed (exit {r.returncode}): {tail(r)}')
        rep['asset'] = json.loads(line[0][len('PIPELINE_JSON'):]); strip_png_metadata(st / 'renders')
        for d in DIRS:
            for res in (128, 512):
                if not (st / f'renders/{res}_{d}.png').is_file(): raise PipelineError('RENDER', f'missing render {res}_{d}.png')
        rep['render_contract'] = {'elev_deg': a.elev, 'px_per_m': a.px_per_m, 'ortho_scale': round(128 / a.px_per_m, 6), 'root_px': [64, 106], 'directions': list(DIRS), 'mirroring': False,
                                  'uniform_scale': rep['asset']['applied_scale'], 'scale_fit': 'S-view silhouette height only; ONE uniform scale per candidate; no per-direction, per-part or aesthetic transforms',
                                  'target_S_height_px': a.target_height, 'color_management': 'Blender default view transform (see evidence diagnostics)'}
        try: rep['compare'] = build_compare(st, a, DIRS, BG, src_cell, SRC)
        except Exception as e: raise PipelineError('COMPARE', f'compare sheet failed: {e}')
        rep['tools'] = {'blender': tool_version(blender), 'node': tool_version(node) if node else None}
        rep['script_blobs'] = {f.name: git_blob(f, HERE) for f in sorted(HERE.glob('*')) if f.suffix in ('.py', '.mjs') and f.name != '__pycache__'}
        rep['limitations'] = ['mid-stride/asset pose retained: no rig, pose change or retopology', 'one S-fit scale: other directions deviate', 'IoU is triage only: no approval, no best-candidate selection']
        (st / 'pipeline_report.json').write_text(json.dumps(rep, indent=1, sort_keys=True))
        if a.evidence:
            fr = st / '_frames'; r = run_cmd([blender, '-b', '--python', HERE / 'evidence_render.py', '--', dec, fr, rep['asset']['applied_scale'], a.elev, a.px_per_m], 'RENDER', a.timeout, 'Blender evidence render')
            if r.returncode or 'EVIDENCE_DONE' not in r.stdout: raise PipelineError('RENDER', f'evidence render failed: {tail(r)}')
            r = run_cmd([sys.executable, HERE / 'build_evidence.py', fr, st, dec, st / 'review_pack'], 'COMPARE', a.timeout, 'evidence composition')
            if r.returncode: raise PipelineError('COMPARE', f'evidence composition failed: {tail(r)}')
            shutil.rmtree(fr)
        (st / 'README.md').write_text(f"# {a.name}\n\nStatus: {STATUS_RUN} - not approved, not canonical, no runtime change.\nBuilt by `scripts/asset_pipeline/run_asset.py run`. See `pipeline_report.json`, `compare_8dir.png`, `review_pack/`, `output_hashes.json`.\n")
        (st / 'output_hashes.json').write_text(json.dumps(hash_tree(st, exclude=('output_hashes.json',)), indent=1, sort_keys=True))
        stg.commit()
    print(json.dumps({'out': str(final), 'status': STATUS_RUN, 'S_scale': rep['asset']['applied_scale'], 'asset_height_px_range': rep['compare']['asset_height_px_range'], 'mean_iou_triage_only': rep['compare']['mean_iou'], 'triangles': daudit['triangles']}, indent=1))
    return 0

def build_compare(st, a, DIRS, BG, src_cell, SRC):
    import numpy as np
    from PIL import Image, ImageDraw
    mask = lambda im: np.array(im.convert('RGBA'))[..., 3] > 32
    def box(m):
        ys, xs = np.where(m); return {'bbox_xyxy': [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())], 'height_px': int(ys.max() - ys.min() + 1), 'width_px': int(xs.max() - xs.min() + 1)}
    ref = a.compare_dir and pathlib.Path(a.compare_dir).is_dir() and all((pathlib.Path(a.compare_dir) / f'el45_{d}.png').exists() for d in DIRS)
    W = 256; H = W + 14; nrows = 4 if ref else 3
    sheet = Image.new('RGBA', (W * 8, H * nrows), BG); dr = ImageDraw.Draw(sheet); met = {}
    labels = ['SOURCE idle f0 (locked)', f'{a.name} @{a.elev:g}deg {a.px_per_m:g}px/m, one common scale (S={a.target_height:g}px)', 'overlay: red=source only, blue=asset only, white=both'] + ([a.compare_label] if ref else [])
    for c, d in enumerate(DIRS):
        s = src_cell(DIRS.index(d)).convert('RGBA'); m = Image.open(st / f'renders/128_{d}.png').convert('RGBA'); ms, mm = mask(s), mask(m)
        if not mm.any(): raise ValueError(f'empty render for {d}')
        ov = np.zeros((128, 128, 4), np.uint8); ov[..., 3] = 255; ov[ms & ~mm] = (230, 40, 40, 255); ov[mm & ~ms] = (60, 90, 255, 255); ov[ms & mm] = (235, 235, 235, 255)
        ims = [s, m, Image.fromarray(ov)] + ([Image.open(pathlib.Path(a.compare_dir) / f'el45_{d}.png')] if ref else [])
        for rI, im in enumerate(ims):
            cell = Image.new('RGBA', (128, 128), BG); cell.alpha_composite(im.convert('RGBA')); sheet.paste(cell.resize((W, W), Image.NEAREST), (W * c, H * rI + 14))
            if c == 0: dr.text((4, H * rI + 1), labels[rI], fill=(255, 255, 0, 255))
            dr.text((W * c + 4, H * rI + 16), d, fill=(255, 255, 0, 255))
        met[d] = {'asset': box(mm), 'source': box(ms), 'silhouette_iou': round(float((mm & ms).sum() / (mm | ms).sum()), 3)}
    sheet.convert('RGB').save(st / 'compare_8dir.png')
    return {'note': 'IoU is triage only; no approval, no best selection', 'per_direction': met, 'mean_iou': round(sum(v['silhouette_iou'] for v in met.values()) / 8, 3),
            'asset_height_px_range': [min(v['asset']['height_px'] for v in met.values()), max(v['asset']['height_px'] for v in met.values())]}

# ---------------------------------------------------------------- verify
def cmd_verify(a):
    t = pathlib.Path(a.target)
    if t.is_dir():
        oh = t / 'output_hashes.json'
        if not oh.is_file(): raise PipelineError('VERIFY', f'{t} has no output_hashes.json (not a pipeline candidate)')
        exp = json.loads(oh.read_text()); got = hash_tree(t, exclude=('output_hashes.json', 'PUBLISHED_REVIEW.json')); exp.pop('PUBLISHED_REVIEW.json', None)
        problems = [f'{k}: mismatch/missing/extra' for k in sorted(set(exp) | set(got)) if exp.get(k) != got.get(k)]
        rp = json.loads((t / 'pipeline_report.json').read_text()) if (t / 'pipeline_report.json').is_file() else {}
        if rp.get('status') != STATUS_RUN: problems.append('pipeline_report.json: status missing/changed')
    else: problems = verify_freeze(t, ROOT)
    if problems:
        print('VERIFY FAILED:\n  ' + '\n  '.join(problems), file=sys.stderr); return EXIT['VERIFY']
    print(f'VERIFY OK: {t}'); return 0

# ---------------------------------------------------------------- freeze
def cmd_freeze(a):
    name = validate_name(a.name); cand = pathlib.Path(a.candidate).resolve()
    if ROOT.resolve() not in cand.parents or not cand.is_dir(): raise PipelineError('USAGE', 'candidate must be a directory inside operator_3d_master')
    lock_dir = pathlib.Path(a.lock_dir) if a.lock_dir else ROOT / 'locks' / name
    out = lock_dir / 'FROZEN_CANDIDATE_MANIFEST.json'
    if os.path.lexists(out): raise PipelineError('USAGE', f'refusing to overwrite {out}')
    rels = {str(p.relative_to(ROOT)) for p in cand.rglob('*') if p.is_file()}
    for inc in a.include:
        p = (ROOT / inc).resolve()
        if ROOT.resolve() not in p.parents: raise PipelineError('USAGE', f'--include outside module root: {inc}')
        rels |= {str(q.relative_to(ROOT.resolve())) for q in ([p] if p.is_file() else p.rglob('*')) if q.is_file()}
    prov = json.loads(pathlib.Path(a.provenance_file).read_text()) if a.provenance_file else {}
    rp = cand / 'pipeline_report.json'; params = json.loads(pathlib.Path(a.params_file).read_text()) if a.params_file else (json.loads(rp.read_text()).get('render_contract', {}) if rp.is_file() else {})
    if rp.is_file() and not prov: r = json.loads(rp.read_text()); prov = {'input': r.get('input'), 'container': r.get('container'), 'decoded_sha256': r.get('decoded_sha256')}
    top = subprocess.run(['git', 'rev-parse', '--show-toplevel'], capture_output=True, text=True, cwd=ROOT).stdout.strip(); blobs = {}
    for sp in a.script: blobs[sp] = git_blob(ROOT / sp, ROOT)
    for sr in a.script_rev:
        commit, rel = sr.split(':', 1); r = subprocess.run(['git', 'rev-parse', f'{commit}:{(ROOT / rel).resolve().relative_to(pathlib.Path(top).resolve())}'], capture_output=True, text=True, cwd=ROOT)
        if r.returncode: raise PipelineError('USAGE', f'cannot resolve {sr}: {r.stderr.strip()}')
        blobs[f'{rel}@{commit[:9]}'] = r.stdout.strip()
    tools = {'blender': tool_version(find_tool('CUSTODIAN_BLENDER', 'blender')), 'node': tool_version(find_tool('CUSTODIAN_NODE', 'node')), 'uv': tool_version(shutil.which('uv') or 'uv')}
    m = build_freeze_manifest(ROOT, name, rels, prov, params, tools, blobs, '../operator_2_5d_first_animation/unarmed_posture_idle_relaxed_01_full_body_v1_source.png')
    lock_dir.mkdir(parents=True, exist_ok=True); out.write_text(json.dumps(m, indent=1, sort_keys=True))
    pr = verify_freeze(out, ROOT)
    if pr: out.unlink(); raise PipelineError('VERIFY', 'fresh manifest failed verification: ' + '; '.join(pr))
    print(json.dumps({'manifest': str(out.relative_to(ROOT)), 'files': len(m['files']), 'status': m['status']}, indent=1)); return 0

# ---------------------------------------------------------------- publish-review
def cmd_publish(a):
    cand = pathlib.Path(a.candidate); pack = cand / 'review_pack' if (cand / 'review_pack').is_dir() else cand
    files = sorted(p for p in pack.iterdir() if p.is_file())
    if not files: raise PipelineError('PUBLISH', f'no files in {pack}')
    if len(files) > REVIEW_FILES_MAX or sum(p.stat().st_size for p in files) > REVIEW_MIB_MAX * 1048576: raise PipelineError('PUBLISH', f'review pack must be <= {REVIEW_FILES_MAX} files and <= {REVIEW_MIB_MAX} MiB (got {len(files)} files)')
    imgs = [p for p in files if p.suffix == '.png']
    if len(imgs) < 3: raise PipelineError('PUBLISH', 'refusing to publish without substantive image evidence (need >= 3 PNG views)')
    if not a.reason or not a.question: raise PipelineError('USAGE', '--reason and at least one --question are required (publishing is opt-in and must say what is being asked)')
    for p in files:
        if is_lfs_pointer(p): raise PipelineError('PUBLISH', f'{p.name} is an LFS pointer')
    pub = pathlib.Path(os.environ.get('CUSTODIAN_PUBLISHER') or ROOT.parents[3] / 'tools/iteration/publish_review_artifacts.py'); rclone = os.environ.get('CUSTODIAN_RCLONE') or shutil.which('rclone')
    if not pub.is_file(): raise PipelineError('PUBLISH', 'existing publisher not found')
    if not a.dry_run and not rclone: raise PipelineError('PUBLISH', 'rclone not found; cannot verify remote bytes')
    stage = pathlib.Path(tempfile.mkdtemp(prefix='custodian-review-'))     # neutral path: keeps local home paths out of the shared manifest
    try:
        for p in files: shutil.copyfile(p, stage / p.name)
        rid = a.run_id or f"{cand.name if cand.name != 'review_pack' else cand.parent.name}-{datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')}"
        cmd = [sys.executable, str(pub), '--important', '--run-id', rid, '--reason', a.reason, '--workstream', a.workstream, '--scenario', a.scenario, '--max-files', str(REVIEW_FILES_MAX), '--max-mib', str(REVIEW_MIB_MAX)]
        if a.retain_after_review: cmd.append('--retain-after-review')
        if a.dry_run: cmd.append('--dry-run')
        for q in a.question: cmd += ['--question', q]
        cmd += ['--source', str(stage / imgs[0].name)] + [x for p in files if p.name != imgs[0].name for x in ('--artifact', str(stage / p.name))]
        r = subprocess.run(cmd, capture_output=True, text=True, cwd=(pub.parents[3] if len(pub.parents) > 3 else pub.parent), timeout=1800)
        hl = [l for l in r.stdout.splitlines() if l.startswith('CUSTODIAN_VISUAL_REVIEW_HANDOFF_JSON:')]
        if r.returncode or not hl: raise PipelineError('PUBLISH', f'publisher failed (exit {r.returncode}); nothing marked published: {tail(r)}')
        h = json.loads(hl[0].split(':', 1)[1])
        if a.dry_run:
            sel = len(h.get('manifest', {}).get('artifacts', []))
            if sel != len(files): raise PipelineError('PUBLISH', f'publisher selected {sel} of {len(files)} staged files (silent slicing?)')
            print(json.dumps({'dry_run': True, 'selected': sel, 'staged': len(files), 'run_id': rid}, indent=1)); return 0
        if h.get('status') != 'uploaded' or h.get('file_count') != len(files) + 1: raise PipelineError('PUBLISH', f"publisher status {h.get('status')!r}, file_count {h.get('file_count')}, expected {len(files) + 1}; not marked published")
        remote_arg = f"{h.get('remote', 'git-dropbox-sync:')}{h['dropbox_path'].strip('/')}/artifacts"
        c = subprocess.run([rclone, 'check', str(stage), remote_arg, '--one-way'], capture_output=True, text=True, timeout=900)
        if c.returncode: raise PipelineError('PUBLISH', f'remote verification FAILED (rclone check exit {c.returncode}); not marked published: {tail(c)}')
        receipt = {'status': 'PUBLISHED_VERIFIED', 'approved': False, 'run_id': rid, 'manifest_path': h['manifest_path'], 'dropbox_path': h['dropbox_path'], 'files': {p.name: sha256_file(p) for p in files}, 'retention': h.get('retention_policy')}
        (cand / 'PUBLISHED_REVIEW.json').write_text(json.dumps(receipt, indent=1, sort_keys=True)); print(json.dumps(receipt, indent=1)); return 0
    finally: shutil.rmtree(stage, ignore_errors=True)

# ---------------------------------------------------------------- CLI
EPILOG = """examples:
  uv run scripts/asset_pipeline/run_asset.py asset.glb --name meshy-004 --dry-run
  uv run scripts/asset_pipeline/run_asset.py run asset.glb --name meshy-004
  uv run scripts/asset_pipeline/run_asset.py run old.meshy --name meshy-005 --confirm-authorized     # legacy gated container
  uv run scripts/asset_pipeline/run_asset.py verify meshy_candidates/meshy-004
  uv run scripts/asset_pipeline/run_asset.py freeze meshy_candidates/meshy-004 --name meshy-004
  uv run scripts/asset_pipeline/run_asset.py publish-review meshy_candidates/meshy-004 --reason "visual validation" --question "Is this a better base?" --retain-after-review --dry-run
  re-run after a failure with a NEW --name (nothing is ever overwritten)"""

def build_parser():
    ap = argparse.ArgumentParser(prog='run_asset.py', description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter, epilog=EPILOG)
    sp = ap.add_subparsers(dest='cmd', required=True)
    r = sp.add_parser('run', help='render + compare a GLB (never uploads or locks)'); r.add_argument('input'); r.add_argument('--name', required=True)
    r.add_argument('--confirm-authorized', action='store_true', help='legacy .meshy only: your own assertion that you are entitled to process the file (not automated proof)')
    r.add_argument('--target-height', type=float, default=85.0); r.add_argument('--elev', type=float, default=45.0); r.add_argument('--px-per-m', type=float, default=50.0)
    r.add_argument('--compare-dir', default=str(ROOT / 'review_pack/projection45_exp008')); r.add_argument('--compare-label', default='exp-008 @45deg 50px/m (reference experiment)')
    r.add_argument('--out-root', default=str(ROOT / 'meshy_candidates')); r.add_argument('--no-evidence', dest='evidence', action='store_false', help='skip the extended review_pack/ (textured views, detail crops, material/geometry proof)')
    r.add_argument('--timeout', type=int, default=1200, help='seconds per external stage'); r.add_argument('--dry-run', action='store_true', help='preflight + plan only; creates nothing'); r.set_defaults(fn=cmd_run)
    v = sp.add_parser('verify', help='verify a candidate dir or a frozen lock manifest'); v.add_argument('target'); v.set_defaults(fn=cmd_verify)
    f = sp.add_parser('freeze', help='write a frozen-for-review manifest (no approval)'); f.add_argument('candidate'); f.add_argument('--name', required=True); f.add_argument('--lock-dir')
    f.add_argument('--include', action='append', default=[], help='extra file/dir (relative to operator_3d_master)'); f.add_argument('--provenance-file'); f.add_argument('--params-file')
    f.add_argument('--script', action='append', default=[], help='script path to record current git blob of'); f.add_argument('--script-rev', action='append', default=[], help='COMMIT:path blob at a commit'); f.set_defaults(fn=cmd_freeze)
    p = sp.add_parser('publish-review', help='opt-in: upload review_pack/ through the existing publish_review_artifacts.py'); p.add_argument('candidate'); p.add_argument('--reason'); p.add_argument('--question', action='append', default=[])
    p.add_argument('--workstream', default='operator-3d-master'); p.add_argument('--scenario', default='operator/asset-pipeline'); p.add_argument('--run-id'); p.add_argument('--retain-after-review', action='store_true'); p.add_argument('--dry-run', action='store_true'); p.set_defaults(fn=cmd_publish)
    return ap

def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    if argv and argv[0] not in SUBS and argv[0] not in ('-h', '--help'): argv = ['run'] + argv
    args = build_parser().parse_args(argv)
    try: return args.fn(args)
    except PipelineError as e: print(f'ERROR[{e.stage}]: {e.msg}', file=sys.stderr); return e.code

if __name__ == '__main__': sys.exit(main())
