"""Standalone frame/loop review with explicit, non-authoritative playback rate."""
import base64
import argparse
import hashlib
import io
import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path
from PIL import Image, ImageDraw

DONOR_SHA256='20d462e69e172785d91a8f2b450b1127ea33f32ebc92b96a7216c20fc85383ba'
RIG_SHA256='b7002e66df5928a53d4a42e7b74e7bdf82f6ef8006a2bed11a8dcdae815a0ff5'
BACKGROUND=(37,39,44,255)

def _sha_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()

def _sha_file(path: Path) -> str:
    return _sha_bytes(path.read_bytes())

def _rgba(path: Path) -> Image.Image:
    with Image.open(path) as source:
        if source.mode!='RGBA':raise ValueError(f'{path.name} must be RGBA, found {source.mode}')
        return source.copy()

def _verify_strip(path: Path, expected_sha: str, label: str) -> Image.Image:
    if not path.is_file():raise ValueError(f'{label} image missing: {path}')
    actual=_sha_file(path)
    if actual!=expected_sha:raise ValueError(f'{label} SHA-256 mismatch: {actual}')
    image=_rgba(path)
    if image.size!=(1920,128):raise ValueError(f'{label} dimensions must be 1920x128, found {image.size}')
    return image

def _read_html_png(html_path: Path, variable: str) -> bytes:
    if not html_path.is_file():raise ValueError(f'embedded viewer missing: {html_path}')
    html=html_path.read_text()
    match=re.search(rf'\b{variable}\.src\s*=\s*("(?:\\.|[^"\\])*")',html)
    if not match:raise ValueError(f'LOOP_REVIEW.html has no valid {variable}.src assignment')
    try:
        uri=json.loads(match.group(1))
        header,payload=uri.split(',',1)
        if header!='data:image/png;base64':raise ValueError(f'{variable}.src is not a PNG data URI')
        raw=base64.b64decode(payload,validate=True)
    except (ValueError,json.JSONDecodeError) as exc:
        raise ValueError(f'{variable}.src PNG data URI is malformed: {exc}') from exc
    try:
        with Image.open(io.BytesIO(raw)) as image:
            if image.mode!='RGBA' or image.size!=(1920,128):raise ValueError(f'{variable}.src must decode as RGBA 1920x128')
            image.verify()
    except (OSError,ValueError) as exc:
        raise ValueError(f'{variable}.src embedded PNG is invalid: {exc}') from exc
    return raw

def _write_pair_sheet(donor_path: Path, candidate_path: Path, donor_frames: list[Path],
                      candidate_frames: list[Path], report: dict, review_dir: Path,
                      expected_donor_sha: str, donor_frame_sha256: list[str]) -> dict:
    donor_sha=_sha_file(donor_path) if donor_path.is_file() else ''
    if donor_sha!=expected_donor_sha:raise ValueError(f'Knight donor SHA-256 mismatch: {donor_sha or "missing"}')
    donor=_rgba(donor_path);candidate=_rgba(candidate_path)
    if donor.size!=(1920,128):raise ValueError(f'Knight donor dimensions must be 1920x128, found {donor.size}')
    if candidate.size!=(1920,128):raise ValueError(f'Operator candidate dimensions must be 1920x128, found {candidate.size}')
    candidate_sha=_sha_file(candidate_path)
    if donor_sha==candidate_sha or donor.tobytes()==candidate.tobytes():
        raise ValueError('Knight donor and Operator candidate resolve to the same image')
    if len(donor_frames)!=15 or len(candidate_frames)!=15 or len(donor_frame_sha256)!=15:
        raise ValueError('exactly 15 donor and Operator frame files are required')
    rows=report.get('frames')
    if not isinstance(rows,list) or len(rows)!=15 or [row.get('frame') for row in rows]!=list(range(1,16)):
        raise ValueError('report.json must contain ordered frame/support records 1 through 15')
    donor_rebuild=Image.new('RGBA',(1920,128));candidate_rebuild=Image.new('RGBA',(1920,128))
    donor_images=[];candidate_images=[];frame_records=[]
    for i,(donor_frame_path,candidate_frame_path,row,expected_frame_sha) in enumerate(zip(donor_frames,candidate_frames,rows,donor_frame_sha256)):
        donor_frame=_rgba(donor_frame_path);candidate_frame=_rgba(candidate_frame_path)
        if donor_frame.size!=(128,128) or candidate_frame.size!=(128,128):raise ValueError(f'frame {i+1} crop must be 128x128')
        if _sha_file(donor_frame_path)!=expected_frame_sha:raise ValueError(f'Knight donor frame {i+1} file SHA-256 mismatch')
        if donor_frame.tobytes()!=donor.crop((i*128,0,(i+1)*128,128)).tobytes():raise ValueError(f'Knight donor frame {i+1} extraction mismatch')
        if candidate_frame.tobytes()!=candidate.crop((i*128,0,(i+1)*128,128)).tobytes():raise ValueError(f'Operator candidate frame {i+1} extraction mismatch')
        donor_rebuild.paste(donor_frame,(i*128,0));candidate_rebuild.paste(candidate_frame,(i*128,0))
        donor_images.append(donor_frame);candidate_images.append(candidate_frame)
        frame_records.append({'frame':i+1,'support':row.get('support'),'donor_frame_file_sha256':expected_frame_sha,
            'donor_rgba_pixels_sha256':_sha_bytes(donor_frame.tobytes()),
            'candidate_rgba_pixels_sha256':_sha_bytes(candidate_frame.tobytes())})
    if donor_rebuild.tobytes()!=donor.tobytes():raise ValueError('Knight donor 15-frame extraction does not reassemble exactly')
    if candidate_rebuild.tobytes()!=candidate.tobytes():raise ValueError('Operator candidate 15-frame extraction does not reassemble exactly')
    if not review_dir.is_dir():raise ValueError(f'review directory must exist and be empty: {review_dir}')
    sheet_path=review_dir/'REFERENCE_OPERATOR_15_POSES.png'
    provenance_path=review_dir/'REFERENCE_OPERATOR_PROVENANCE.json'
    if sheet_path.exists() or provenance_path.exists():raise ValueError('refusing to overwrite existing review provenance output')
    sheet=Image.new('RGB',(1280,480),BACKGROUND[:3]);draw=ImageDraw.Draw(sheet)
    for i,(donor_frame,candidate_frame,row,record) in enumerate(zip(donor_images,candidate_images,rows,frame_records)):
        col=i%5;line=i//5;cell_x=col*256;cell_y=line*160
        draw.text((cell_x+3,cell_y+3),f"F{i+1:02} · support {row['support']}",fill=(255,255,255))
        donor_panel=Image.new('RGBA',(128,128),BACKGROUND);donor_panel.alpha_composite(donor_frame)
        candidate_panel=Image.new('RGBA',(128,128),BACKGROUND);candidate_panel.alpha_composite(candidate_frame)
        donor_rect=(cell_x,cell_y+20,128,128);candidate_rect=(cell_x+128,cell_y+20,128,128)
        sheet.paste(donor_panel.convert('RGB'),donor_rect[:2]);sheet.paste(candidate_panel.convert('RGB'),candidate_rect[:2])
        draw.text((cell_x+2,cell_y+149),'Knight NE donor',fill=(190,218,255))
        draw.text((cell_x+130,cell_y+149),'Operator candidate',fill=(255,215,174))
        donor_match=sheet.crop((donor_rect[0],donor_rect[1],donor_rect[0]+128,donor_rect[1]+128)).tobytes()==donor_panel.convert('RGB').tobytes()
        candidate_match=sheet.crop((candidate_rect[0],candidate_rect[1],candidate_rect[0]+128,candidate_rect[1]+128)).tobytes()==candidate_panel.convert('RGB').tobytes()
        if not donor_match or not candidate_match:raise ValueError(f'frame {i+1} rendered panel differs from declared source after compositing')
        record.update(support=row['support'],donor_source_crop_xywh=[i*128,0,128,128],
            candidate_source_crop_xywh=[i*128,0,128,128],donor_sheet_panel_xywh=list(donor_rect),
            candidate_sheet_panel_xywh=list(candidate_rect),donor_background_composited_match=donor_match,
            candidate_background_composited_match=candidate_match)
    sheet.save(sheet_path)
    sheet_sha=_sha_file(sheet_path)
    provenance={'schema':'custodian.operator_ne_reference_pair_provenance.v1',
        'donor':{'identity':'Knight NE reference','direction':'NE','sha256':donor_sha,
            'rgba_pixels_sha256':_sha_bytes(donor.tobytes()),'declared_sha256':expected_donor_sha},
        'source_strip_sha256':donor_sha,'candidate_strip_sha256':candidate_sha,
        'report_sha256':_sha_file(candidate_path.parent/'report.json'),
        'background_rgba':list(BACKGROUND),'source_reassembly_exact':True,
        'candidate_reassembly_exact':True,'all_panels_match_declared_sources_after_compositing':True,
        'contact_sheet':{'filename':sheet_path.name,'sha256':sheet_sha,'dimensions':[1280,480],
            'layout':'five columns by three rows; each 256x160 frame pair; donor left, candidate right'},
        'frames':frame_records}
    provenance_path.write_text(json.dumps(provenance,indent=2,allow_nan=False)+'\n')
    return provenance

def write_reference_operator_sheet(bundle: Path, output: Path, report: dict, review_dir: Path) -> dict:
    bundle=bundle.resolve();output=output.resolve();review_dir=review_dir.resolve()
    authority=json.loads((Path(__file__).resolve().parent/'donor_authority.json').read_text())
    rig_acceptance=json.loads((Path(__file__).resolve().parent/'rig_acceptance.json').read_text())
    crossover_acceptance=json.loads((Path(__file__).resolve().parent/'crossover_acceptance.json').read_text())
    if authority.get('source_sha256')!=DONOR_SHA256 or rig_acceptance.get('rig_sha256')!=RIG_SHA256 or crossover_acceptance.get('rig_sha256')!=RIG_SHA256:
        raise ValueError('repository donor/rig acceptance receipt does not match pinned Iteration 002 identity')
    source_path=bundle/'reference/knight_ne_walk_reference_15f_128.png'
    source=_verify_strip(source_path,DONOR_SHA256,'Knight NE donor')
    manifest=json.loads((bundle/'MANIFEST.json').read_text())
    if manifest.get('source_sha256')!=DONOR_SHA256 or len(manifest.get('frames_metadata',[]))!=15:
        raise ValueError('NE donor bundle manifest identity or frame count mismatch')
    candidate_path=output/'operator_ne_walk_v6_15f.png'
    candidate=_verify_strip(candidate_path,_sha_file(candidate_path),'Operator candidate')
    if source.tobytes()==candidate.tobytes():raise ValueError('Knight donor and Operator candidate pixels are identical')
    if report.get('schema')!='custodian.ne_walk_preview.v1' or report.get('rig_sha256')!=RIG_SHA256:
        raise ValueError('Iteration 001 report schema/rig acceptance mismatch')
    if report.get('input_validation',{}).get('source_hash')!=DONOR_SHA256:
        raise ValueError('Iteration 001 report source hash does not identify the locked Knight donor')
    if report.get('calibration_acceptance',{}).get('rig_sha256')!=RIG_SHA256:
        raise ValueError('Iteration 001 report calibration rig receipt mismatch')
    html_path=output/'LOOP_REVIEW.html'
    embedded_donor=_read_html_png(html_path,'ref');embedded_candidate=_read_html_png(html_path,'op')
    if _sha_bytes(embedded_donor)!=DONOR_SHA256:raise ValueError('LOOP_REVIEW.html ref.src does not embed the pinned Knight donor')
    if _sha_bytes(embedded_candidate)!=_sha_file(candidate_path):raise ValueError('LOOP_REVIEW.html op.src does not embed the Iteration 001 Operator candidate')
    donor_frames=[]
    for meta in manifest['frames_metadata']:
        path=bundle/'reference/frames'/meta['name']
        if _sha_file(path)!=meta['sha256']:raise ValueError(f"NE donor bundle frame manifest mismatch: {meta['name']}")
        donor_frames.append(path)
    candidate_frames=[output/f"frame_{i:02}.png" for i in range(1,16)]
    provenance=_write_pair_sheet(source_path,candidate_path,donor_frames,candidate_frames,report,
        review_dir,DONOR_SHA256,[meta['sha256'] for meta in manifest['frames_metadata']])
    provenance['html_reference']={'verified':True,'donor_png_sha256':_sha_bytes(embedded_donor),
        'operator_png_sha256':_sha_bytes(embedded_candidate),'viewer_file_sha256':_sha_file(html_path)}
    (review_dir/'REFERENCE_OPERATOR_PROVENANCE.json').write_text(json.dumps(provenance,indent=2,allow_nan=False)+'\n')
    return provenance

def check_viewer_script(html_text: str) -> dict:
    """Parse the exact JavaScript emitted in the self-contained review HTML."""
    scripts=re.findall(r'<script\b[^>]*>(.*?)</script\s*>',html_text,re.IGNORECASE|re.DOTALL)
    if len(scripts)!=1:raise ValueError(f'generated viewer must contain exactly one script block; found {len(scripts)}')
    node=shutil.which('node')
    if not node:raise RuntimeError('Node.js is required to validate generated review viewer JavaScript')
    with tempfile.TemporaryDirectory(prefix='operator-ne-viewer-js-') as temp:
        script=Path(temp)/'viewer.js';script.write_text(scripts[0])
        result=subprocess.run([node,'--check',str(script)],capture_output=True,text=True,check=False)
    if result.returncode:
        raise ValueError(f'generated viewer JavaScript failed node --check:\n{result.stderr.strip()}')
    return {'validator':'node --check','status':'PASS','script_sha256':_sha_bytes(scripts[0].encode('utf-8'))}

def write_viewer(out: Path,bundle: Path,report: dict,destination: Path|None=None):
    def data(path):return 'data:image/png;base64,'+base64.b64encode(path.read_bytes()).decode('ascii')
    html=r'''<!doctype html><meta charset="utf-8"><title>Operator NE walk — review preview</title>
<style>body{font:16px system-ui;background:#202126;color:#eee;max-width:1250px;margin:24px auto}canvas{width:384px;height:384px;image-rendering:pixelated;background:repeating-conic-gradient(#292c33 0% 25%,#353840 0% 50%) 0/16px 16px}#zoom{width:480px;height:480px}button,select{font:inherit;padding:6px;margin:4px}section{display:flex;gap:24px;align-items:flex-start;flex-wrap:wrap}pre{white-space:pre-wrap}.warn{color:#ffd68d;font-weight:bold}</style>
<h1>Operator NE walk — review preview</h1>
<p class="warn">PREVIEW ONLY / TIMING UNKNOWN / ART NOT ACCEPTED. Select a review playback rate explicitly. This viewer records no timing or approval.</p>
<button id="prev">← Previous</button><button id="next">Next →</button>
<select id="rate"><option value="">Review playback rate…</option><option>2</option><option>4</option><option>6</option><option>8</option><option>10</option><option>12</option></select><button id="play">Play</button>
<label><input type="checkbox" id="voids">Mark enclosed transparent regions</label>
<label><input type="checkbox" id="pitch" checked>Show pitch errors</label>
<section><div><h3>Operator clean output</h3><canvas id="op" width="128" height="128"></canvas></div><div><h3>Knight pose reference only</h3><canvas id="ref" width="128" height="128"></canvas></div><div><h3>Operator edge / seam detail · source x60–99 y65–104 · 6× nearest</h3><canvas id="zoom" width="240" height="240"></canvas></div></section>
<pre id="state"></pre><p>Use ←/→ to inspect the complete 15-frame loop, including 15→1. Enclosed transparency may include intentional limb gaps or part seams; review its marked locations. Mapping-to-fit deviation reaches MAXDEV px; assess gait fidelity and secondary motion before acceptance.</p>
<script>
const rows=REPORT;const op=new Image(),ref=new Image();let frame=0,playing=false,last=0,ready=0;
const oc=document.querySelector('#op').getContext('2d'),rc=document.querySelector('#ref').getContext('2d'),zc=document.querySelector('#zoom').getContext('2d');
function draw(){if(ready<2)return;oc.clearRect(0,0,128,128);rc.clearRect(0,0,128,128);zc.clearRect(0,0,240,240);oc.drawImage(op,frame*128,0,128,128,0,0,128,128);rc.drawImage(ref,frame*128,0,128,128,0,0,128,128);zc.imageSmoothingEnabled=false;zc.drawImage(op,frame*128+60,65,40,40,0,0,240,240);const r=rows[frame];
if(document.querySelector('#voids').checked){oc.strokeStyle='#ff70df';oc.lineWidth=.5;zc.strokeStyle='#ff70df';zc.lineWidth=2;for(const v of r.enclosed_alpha_voids){const b=v.bbox;oc.strokeRect(b[0],b[1],b[2]-b[0],b[3]-b[1]);const x0=Math.max(60,b[0]),y0=Math.max(65,b[1]),x1=Math.min(100,b[2]),y1=Math.min(105,b[3]);if(x1>x0&&y1>y0)zc.strokeRect((x0-60)*6,(y0-65)*6,(x1-x0)*6,(y1-y0)*6);}}
const pitch=document.querySelector('#pitch').checked?`\nPitch target error near/far: ${r.legs.near.reference_pitch_filter_signed_deviation_deg.toFixed(3)}° / ${r.legs.far.reference_pitch_filter_signed_deviation_deg.toFixed(3)}°`:'\nPitch error overlay hidden';
document.querySelector('#state').textContent=`Frame ${frame+1}/15 · support ${r.support} · PREVIEW ONLY · current checks ${r.pass?'PASS':'FAIL'}\nSole error: ${r.contact.dx.toFixed(3)}, ${r.contact.dy.toFixed(3)} px${pitch}\nEnclosed transparent pixels: ${r.enclosed_alpha_voids.reduce((n,v)=>n+v.pixels,0)}\nSecondary motion: ${JSON.stringify(r.secondary)}`;}
function step(d){frame=(frame+d+15)%15;draw();}function tick(t){const fps=+document.querySelector('#rate').value;if(playing&&fps&&t-last>=1000/fps){step(1);last=t;}requestAnimationFrame(tick);}requestAnimationFrame(tick);
document.querySelector('#prev').onclick=()=>step(-1);document.querySelector('#next').onclick=()=>step(1);document.querySelector('#voids').onchange=draw;document.querySelector('#pitch').onchange=draw;
document.querySelector('#play').onclick=()=>{if(!document.querySelector('#rate').value){document.querySelector('#rate').focus();return;}playing=!playing;document.querySelector('#play').textContent=playing?'Pause':'Play';last=performance.now();};
document.onkeydown=e=>{if(e.key==='ArrowLeft')step(-1);if(e.key==='ArrowRight')step(1);};op.onload=ref.onload=()=>{ready++;draw();};op.src=OPDATA;ref.src=REFDATA;
</script>'''
    html=html.replace('MAXDEV',f"{report['maximum_reference_filter_deviation_px']:.3f}")
    html=html.replace('const rows=REPORT','const rows='+json.dumps(report['frames'],separators=(',',':')))
    html=html.replace('op.src=OPDATA','op.src='+json.dumps(data(out/'operator_ne_walk_v6_15f.png')))
    html=html.replace('ref.src=REFDATA','ref.src='+json.dumps(data(bundle/'reference/knight_ne_walk_reference_15f_128.png')))
    target=(destination or (out/'LOOP_REVIEW.html')).resolve()
    check_viewer_script(html)
    target.write_text(html)
    return target

def main(argv=None):
    parser=argparse.ArgumentParser(description='Verify Iteration 001 image provenance and create a Knight/Operator pair sheet without rerendering.')
    parser.add_argument('--bundle',required=True,type=Path)
    parser.add_argument('--output',required=True,type=Path,help='existing animation output directory; read-only')
    parser.add_argument('--review-dir',required=True,type=Path,help='new or empty directory for review evidence')
    parser.add_argument('--repair-viewer-only',action='store_true',help='regenerate only a repaired viewer from locked Iteration 004 files')
    args=parser.parse_args(argv);output=args.output.resolve();review_dir=args.review_dir.resolve()
    if not output.is_dir():parser.error(f'Iteration 001 output directory does not exist: {output}')
    if args.repair_viewer_only:
        expected_report='88aa6469a76b986d0d3ccd2592dfed62903b5461ebe3e6e25c0fdb7f9519e83a'
        expected_candidate='e06daea3f55b6bb8c2787b5874978a72644a7607f0eb37519c03828b3b61bb6a'
        report_path=output/'report.json';candidate_path=output/'operator_ne_walk_v6_15f.png'
        donor_path=args.bundle.resolve()/'reference/knight_ne_walk_reference_15f_128.png'
        if not report_path.is_file() or _sha_file(report_path)!=expected_report:parser.error('Iteration 004 report SHA-256 does not match the locked baseline')
        if not candidate_path.is_file() or _sha_file(candidate_path)!=expected_candidate:parser.error('Iteration 004 Operator strip SHA-256 does not match the locked baseline')
        if not donor_path.is_file() or _sha_file(donor_path)!=DONOR_SHA256:parser.error('Knight NE donor SHA-256 does not match the locked baseline')
        if review_dir.exists() and (not review_dir.is_dir() or any(review_dir.iterdir())):
            parser.error(f'repair staging directory must be new or empty: {review_dir}')
        review_dir.mkdir(parents=True,exist_ok=True)
        try:
            report=json.loads(report_path.read_text())
            target=write_viewer(output,args.bundle.resolve(),report,review_dir/'LOOP_REVIEW.html')
            embedded_donor=_read_html_png(target,'ref');embedded_candidate=_read_html_png(target,'op')
            if _sha_bytes(embedded_donor)!=DONOR_SHA256:raise ValueError('regenerated ref.src does not match the pinned Knight NE donor')
            if _sha_bytes(embedded_candidate)!=expected_candidate:raise ValueError('regenerated op.src does not match the pinned Iteration 004 Operator strip')
            parser_receipt=check_viewer_script(target.read_text())
        except (OSError,ValueError,KeyError,json.JSONDecodeError,RuntimeError) as exc:
            parser.error(str(exc))
        print(json.dumps({'status':'PASS','mode':'repair-viewer-only','viewer':str(target),
            'html_sha256':_sha_file(target),'report_sha256':_sha_file(report_path),
            'candidate_strip_sha256':_sha_file(candidate_path),'donor_sha256':_sha_file(donor_path),
            'embedded_donor_sha256':_sha_bytes(embedded_donor),'embedded_candidate_sha256':_sha_bytes(embedded_candidate),
            'script':parser_receipt}))
        return 0
    report_path=output/'report.json'
    if not report_path.is_file():parser.error(f'Iteration 001 report missing: {report_path}')
    if review_dir.exists():
        if not review_dir.is_dir() or any(review_dir.iterdir()):parser.error(f'review directory must be new or empty: {review_dir}')
    else:review_dir.mkdir(parents=True)
    try:
        report=json.loads(report_path.read_text())
        provenance=write_reference_operator_sheet(args.bundle,output,report,review_dir)
    except (OSError,ValueError,KeyError,json.JSONDecodeError) as exc:
        parser.error(str(exc))
    print(json.dumps({'status':'PASS','review_dir':str(review_dir),
        'contact_sheet_sha256':provenance['contact_sheet']['sha256'],
        'donor_sha256':provenance['donor']['sha256'],
        'candidate_strip_sha256':provenance['candidate_strip_sha256'],
        'html_donor_verified':provenance['html_reference']['verified']}))
    return 0

if __name__=='__main__':
    raise SystemExit(main())
