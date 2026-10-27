#!/usr/bin/env python3
# /// script
# dependencies = ["cryptography", "pillow", "numpy"]
# ///
"""ONE command: run an asset through the CUSTODIAN Operator 3D review pipeline.

    uv run scripts/asset_pipeline/run_asset.py INPUT --name meshy-003 [--compare-dir review_pack/projection45_exp008 --compare-label exp-008]

INPUT may be a Meshy `.meshy` v1 file, a meshopt-compressed GLB, or a plain GLB/glTF-binary. Steps (each recorded in pipeline_report.json):
  1 container   .meshy -> GLB (static-key AES-CTR prefix; REQUIRES --confirm-authorized, auth tag not verified) | GLB passes through
  2 decode      EXT_meshopt_compression -> plain buffers (node + three.js decoder), other extensions (WebP, texture transform) kept
  3 render      Blender headless: ground (Z=0, xy centred), ONE common scale so S height = --target-height px, 8 unmirrored directions at
                45 deg above horizon, 50 px/m ortho, root (64,106), native 128 + look-dev 512, asset's own materials
  4 compare     canonical idle f0 (SHA256-verified locked bytes) | asset | overlay (+ optional reference experiment row), per-direction metrics
Output: meshy_candidates/<name>/ (never overwrites). Does NOT commit, select-best, approve art, touch manifests/SpriteFrames/runtime, or change FPS."""
import argparse, hashlib, json, pathlib, shutil, struct, subprocess, sys
import numpy as np
from PIL import Image, ImageDraw
HERE = pathlib.Path(__file__).resolve().parent; ROOT = HERE.parents[1]; sys.path.insert(0, str(ROOT / 'scripts'))
KEY = b'JSON{"accessors":[{"bufferView":'; ENC_BEGIN, ENC_END, TAG_END = 32, 8224, 8240
sha = lambda b: hashlib.sha256(b).hexdigest()

def meshy_to_glb(blob):
    from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
    if len(blob) < TAG_END or struct.unpack_from('<H', blob, 8)[0] != 1: raise SystemExit('not a Meshy v1 container')
    dec = Cipher(algorithms.AES(KEY), modes.CTR(blob[10:22] + b'\x00\x00\x00\x02')).decryptor()
    pre = dec.update(blob[ENC_BEGIN:ENC_END]) + dec.finalize()
    if pre[:4] != b'glTF': raise SystemExit('reconstruction did not yield GLB magic')
    out = bytearray(pre + blob[TAG_END:]); struct.pack_into('<I', out, 8, len(out)); return bytes(out)

def glb_json(d):
    n = struct.unpack_from('<I', d, 12)[0]; return json.loads(d[20:20 + n])

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('input', type=pathlib.Path); ap.add_argument('--name', required=True)
    ap.add_argument('--confirm-authorized', action='store_true', help='required for .meshy input: you confirm you are entitled to process this file')
    ap.add_argument('--target-height', type=float, default=85.0, help='S-view silhouette height in px at the common projection (canonical 84-88)')
    ap.add_argument('--elev', type=float, default=45.0); ap.add_argument('--px-per-m', type=float, default=50.0)
    ap.add_argument('--compare-dir', type=pathlib.Path, default=ROOT / 'review_pack/projection45_exp008', help='dir with el45_<DIR>.png frames of a reference experiment (optional row)')
    ap.add_argument('--compare-label', default='exp-008 @45deg 50px/m'); ap.add_argument('--out-root', type=pathlib.Path, default=ROOT / 'meshy_candidates')
    a = ap.parse_args()
    out = a.out_root / a.name
    if out.exists(): raise SystemExit(f'refusing to overwrite {out}; choose a new --name')
    blob = a.input.read_bytes(); rep = {'input': a.input.name, 'input_sha256': sha(blob), 'name': a.name, 'status': 'IMPORTED_REFERENCE_CANDIDATE_NOT_APPROVED',
                                         'params': {'elev_deg': a.elev, 'px_per_m': a.px_per_m, 'target_S_height_px': a.target_height}}
    (out / 'source').mkdir(parents=True); (out / 'renders').mkdir()
    # 1 container
    if blob[:8] == b'MESHY.AI':
        if not a.confirm_authorized: raise SystemExit('.meshy input is an encrypted container: pass --confirm-authorized to confirm you are entitled to process it')
        glb = meshy_to_glb(blob); rep['container'] = 'meshy_v1 -> glb (tag NOT verified)'
    elif blob[:4] == b'glTF': glb = blob; rep['container'] = 'glb'
    else: raise SystemExit('unrecognised input (expected .meshy v1 or GLB)')
    j = glb_json(glb); (out / 'source/container.glb').write_bytes(glb); rep['container_sha256'] = sha(glb); rep['extensions_required'] = j.get('extensionsRequired', [])
    # 2 decode
    dec = out / 'asset_decoded.glb'
    if 'EXT_meshopt_compression' in j.get('extensionsUsed', []):
        node = shutil.which('node') or sys.exit('node not found (needed for meshopt decode)')
        subprocess.run([node, str(HERE / 'meshopt_decode.mjs'), str(out / 'source/container.glb'), str(dec)], check=True, capture_output=True); rep['meshopt'] = 'decoded locally'
    else: shutil.copyfile(out / 'source/container.glb', dec); rep['meshopt'] = 'not used'
    rep['decoded_sha256'] = sha(dec.read_bytes())
    # 3 render
    exe = shutil.which('blender') or sys.exit('blender not on PATH')
    r = subprocess.run([exe, '-b', '--python', str(HERE / 'blender_render.py'), '--', str(dec), str(out / 'renders'), str(a.elev), str(a.px_per_m), str(a.target_height)], capture_output=True, text=True)
    line = [l for l in r.stdout.splitlines() if l.startswith('PIPELINE_JSON')]
    if r.returncode or not line: sys.exit('blender step failed:\n' + (r.stdout + r.stderr)[-1500:])
    rep['asset'] = json.loads(line[0][len('PIPELINE_JSON'):])
    # 4 compare
    from build_review import src_cell, SRC, DIRS, BG
    assert sha(SRC.read_bytes()) == 'd4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3', 'canonical idle is not the locked bytes (LFS pointer?)'
    mask = lambda im: np.array(im.convert('RGBA'))[..., 3] > 32
    def box(m):
        ys, xs = np.where(m); return {'bbox_xyxy': [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())], 'height_px': int(ys.max() - ys.min() + 1), 'width_px': int(xs.max() - xs.min() + 1)}
    ref = a.compare_dir.is_dir() and all((a.compare_dir / f'el45_{d}.png').exists() for d in DIRS)
    Z, W = 2, 256; H = W + 14; nrows = 4 if ref else 3
    sheet = Image.new('RGBA', (W * 8, H * nrows), BG); dr = ImageDraw.Draw(sheet); met = {}
    labels = ['SOURCE idle f0 (locked)', f'{a.name} @{a.elev:g}deg {a.px_per_m:g}px/m, one common scale (S={a.target_height:g}px)', 'overlay: red=source only, blue=asset only, white=both'] + ([a.compare_label] if ref else [])
    for c, d in enumerate(DIRS):
        s = src_cell(DIRS.index(d)).convert('RGBA'); m = Image.open(out / f'renders/128_{d}.png').convert('RGBA'); ms, mm = mask(s), mask(m)
        ov = np.zeros((128, 128, 4), np.uint8); ov[..., 3] = 255; ov[ms & ~mm] = (230, 40, 40, 255); ov[mm & ~ms] = (60, 90, 255, 255); ov[ms & mm] = (235, 235, 235, 255)
        ims = [s, m, Image.fromarray(ov)] + ([Image.open(a.compare_dir / f'el45_{d}.png')] if ref else [])
        for rI, im in enumerate(ims):
            cell = Image.new('RGBA', (128, 128), BG); cell.alpha_composite(im.convert('RGBA')); sheet.paste(cell.resize((W, W), Image.NEAREST), (W * c, H * rI + 14))
            if c == 0: dr.text((4, H * rI + 1), labels[rI], fill=(255, 255, 0, 255))
            dr.text((W * c + 4, H * rI + 16), d, fill=(255, 255, 0, 255))
        met[d] = {'asset': box(mm), 'source': box(ms), 'silhouette_iou': round(float((mm & ms).sum() / (mm | ms).sum()), 3)}
    sheet.convert('RGB').save(out / 'compare_8dir.png')
    rep['compare'] = {'note': 'IoU is triage only; no approval, no best selection', 'per_direction': met, 'mean_iou': round(sum(v['silhouette_iou'] for v in met.values()) / 8, 3),
                      'asset_height_px_range': [min(v['asset']['height_px'] for v in met.values()), max(v['asset']['height_px'] for v in met.values())]}
    (out / 'pipeline_report.json').write_text(json.dumps(rep, indent=1))
    (out / 'README.md').write_text(f"# {a.name}\n\nStatus: IMPORTED_REFERENCE_CANDIDATE - not approved, not canonical, no runtime change.\n\nProduced by `scripts/asset_pipeline/run_asset.py`. See `pipeline_report.json` (hashes, scale, metrics) and `compare_8dir.png`. Container: {rep['container']}.\n")
    print(json.dumps({'out': str(out), 'S_scale': rep['asset']['applied_scale'], 'height_range_px': rep['compare']['asset_height_px_range'], 'mean_iou': rep['compare']['mean_iou'], 'tris': rep['asset']['tris']}, indent=1))

if __name__ == '__main__': main()
