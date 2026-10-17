"""Standalone frame/loop review with explicit, non-authoritative playback rate."""
import base64
import json
from pathlib import Path

def write_viewer(out: Path,bundle: Path,report: dict):
    def data(path):return 'data:image/png;base64,'+base64.b64encode(path.read_bytes()).decode('ascii')
    html='''<!doctype html><meta charset="utf-8"><title>Operator NE V6 — animation review</title>
<style>body{font:16px system-ui;background:#202126;color:#eee;max-width:1100px;margin:24px auto}canvas{width:384px;height:384px;image-rendering:pixelated;background:repeating-conic-gradient(#292c33 0% 25%,#353840 0% 50%) 0/16px 16px}button,select{font:inherit;padding:6px;margin:4px}section{display:flex;gap:24px}pre{white-space:pre-wrap}.warn{color:#ffd68d}</style>
<h1>Operator NE V6 — human loop review</h1>
<p class="warn">Rig and crossover calibration accepted; full animation and timing unapproved. Select a review playback rate explicitly. This viewer records no timing or approval.</p>
<button id="prev">← Previous</button><button id="next">Next →</button>
<select id="rate"><option value="">Review playback rate…</option><option>2</option><option>4</option><option>6</option><option>8</option><option>10</option><option>12</option></select><button id="play">Play</button>
<label><input type="checkbox" id="voids">Mark enclosed transparent regions</label>
<section><div><h3>Operator clean output</h3><canvas id="op" width="128" height="128"></canvas></div><div><h3>Knight pose reference only</h3><canvas id="ref" width="128" height="128"></canvas></div></section>
<pre id="state"></pre><p>Use ←/→ to inspect the complete 15-frame loop, including 15→1. Enclosed transparency may include intentional limb gaps or part seams; review its marked locations. Mapping-to-fit deviation reaches MAXDEV px; assess gait fidelity and secondary motion before acceptance.</p>
<script>
const rows=REPORT;const op=new Image(),ref=new Image();let frame=0,playing=false,last=0,ready=0;
const oc=document.querySelector('#op').getContext('2d'),rc=document.querySelector('#ref').getContext('2d');
function draw(){if(ready<2)return;oc.clearRect(0,0,128,128);rc.clearRect(0,0,128,128);oc.drawImage(op,frame*128,0,128,128,0,0,128,128);rc.drawImage(ref,frame*128,0,128,128,0,0,128,128);const r=rows[frame];
if(document.querySelector('#voids').checked){oc.strokeStyle='#ff70df';oc.lineWidth=.5;for(const v of r.enclosed_alpha_voids){const b=v.bbox;oc.strokeRect(b[0],b[1],b[2]-b[0],b[3]-b[1]);}}
document.querySelector('#state').textContent=`Frame ${frame+1}/15 · working support ${r.support} · current checks ${r.pass?'PASS':'FAIL'}\nSole error: ${r.contact.dx.toFixed(3)}, ${r.contact.dy.toFixed(3)} px\nMapping-to-fit deviation near/far: ${r.legs.near.reference_filter_deviation_px.toFixed(3)} / ${r.legs.far.reference_filter_deviation_px.toFixed(3)} px\nEnclosed transparent pixels: ${r.enclosed_alpha_voids.reduce((n,v)=>n+v.pixels,0)}\nSecondary motion: ${JSON.stringify(r.secondary)}`;}
function step(d){frame=(frame+d+15)%15;draw();}function tick(t){const fps=+document.querySelector('#rate').value;if(playing&&fps&&t-last>=1000/fps){step(1);last=t;}requestAnimationFrame(tick);}requestAnimationFrame(tick);
document.querySelector('#prev').onclick=()=>step(-1);document.querySelector('#next').onclick=()=>step(1);document.querySelector('#voids').onchange=draw;
document.querySelector('#play').onclick=()=>{if(!document.querySelector('#rate').value){document.querySelector('#rate').focus();return;}playing=!playing;document.querySelector('#play').textContent=playing?'Pause':'Play';last=performance.now();};
document.onkeydown=e=>{if(e.key==='ArrowLeft')step(-1);if(e.key==='ArrowRight')step(1);};op.onload=ref.onload=()=>{ready++;draw();};op.src=OPDATA;ref.src=REFDATA;
</script>'''
    html=html.replace('MAXDEV',f"{report['maximum_reference_filter_deviation_px']:.3f}")
    html=html.replace('const rows=REPORT','const rows='+json.dumps(report['frames'],separators=(',',':')))
    html=html.replace('op.src=OPDATA','op.src='+json.dumps(data(out/'operator_ne_walk_v6_15f.png')))
    html=html.replace('ref.src=REFDATA','ref.src='+json.dumps(data(bundle/'reference/knight_ne_walk_reference_15f_128.png')))
    (out/'LOOP_REVIEW.html').write_text(html)
