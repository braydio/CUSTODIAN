"""Build compact V004 shoulder-review sheets from verified proof renders."""
from __future__ import annotations
import hashlib
import json
import shutil
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

DIRECTIONS = ("N", "NE", "E", "SE", "S", "SW", "W", "NW")
DETAIL_DIRECTIONS = ("S", "SE", "SW", "E")
IDLE_FRAMES = (1, 6, 13, 16, 22, 132, 263)
RUN_FRAMES = (6, 16)


def sha(path: Path) -> str:
    h=hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda:f.read(1024*1024),b""): h.update(block)
    return h.hexdigest()

def image(path: Path, size):
    im=Image.open(path).convert("RGBA")
    if im.size != size: raise RuntimeError(f"IMAGE_SIZE:{path}:{im.size}:{size}")
    return im

def paste_bg(dst, src, xy):
    bg=Image.new("RGBA",src.size,(22,24,29,255));bg.alpha_composite(src);dst.alpha_composite(bg,xy)

def run(proof: Path, repo: Path, source_v3: Path, candidate_v4: Path, source_v3_sha: str, candidate_v4_sha: str):
    out=proof/"review_bundle";out.mkdir(parents=True,exist_ok=True)
    helper=proof/"reference_comparisons"
    copies={
        "operator_v004_approved_idle_comparison.png":"operator_v003_8dir_reference_comparison.png",
        "operator_v004_runtime_idle_comparison.png":"runtime_idle_actual_contact_sheet.png",
        "operator_v004_native128_vs_reduced512.png":"operator_v003_native128_vs_reduced512.png",
        "operator_v004_approved_reference_sheet.png":"approved_128_idle_8dir_15f_contact_sheet.png",
    }
    for dest,src in copies.items():shutil.copyfile(helper/src,out/dest)

    v3=proof/"v003_native512";v4=proof/"native512"
    # Full eight-direction 128px A/B at source frame 132.
    cw,ch=270,300; margin=20; title_h=42
    sheet=Image.new("RGBA",(margin*2+cw*2,title_h+margin+len(DIRECTIONS)*ch),(14,16,20,255));d=ImageDraw.Draw(sheet)
    d.text((margin,12),"V003 vs V004 · fixed camera · neutral idle frame 132",fill=(238,238,238,255))
    d.text((margin+72,title_h),"V003",fill=(208,208,208,255));d.text((margin+cw+72,title_h),"V004",fill=(208,208,208,255))
    for row,di in enumerate(DIRECTIONS):
        y=title_h+margin+row*ch;d.text((4,y+126),di,fill=(240,210,140,255))
        for col,root in enumerate((proof/"v003_native128",proof/"native128")):
            im=image(root/di/"0132.png",(128,128)).resize((256,256),Image.Resampling.NEAREST)
            paste_bg(sheet,im,(margin+col*cw,y))
    sheet.save(out/"operator_v004_v003_before_after.png")

    # Contact-critical shoulder ROIs, keeping the original 512px source samples.
    crop=(128,72,384,264); crop_w=crop[2]-crop[0];crop_h=crop[3]-crop[1]
    cell_w=2*crop_w+34; cell_h=crop_h+34
    detail=Image.new("RGBA",(78+len(DETAIL_DIRECTIONS)*cell_w,50+len(IDLE_FRAMES)*cell_h),(14,16,20,255));d=ImageDraw.Draw(detail)
    d.text((12,12),"Right pauldron region · V003/V004 · unchanged camera and 512px render",fill=(238,238,238,255))
    for ci,di in enumerate(DETAIL_DIRECTIONS):d.text((78+ci*cell_w+crop_w,36),di,fill=(240,210,140,255))
    for ri,frame in enumerate(IDLE_FRAMES):
        y=50+ri*cell_h;d.text((6,y+crop_h//2),f"idle {frame}",fill=(230,230,230,255))
        for ci,di in enumerate(DETAIL_DIRECTIONS):
            x=78+ci*cell_w
            for vi,root in enumerate((proof/"v003_native512",proof/"native512")):
                im=image(root/di/f"{frame:04d}.png",(512,512)).crop(crop)
                paste_bg(detail,im,(x+vi*(crop_w+10),y+20))
                d.text((x+vi*(crop_w+10)+3,y+3),"V003" if vi==0 else "V004",fill=(230,230,230,255))
    detail.save(out/"operator_v004_shoulder_detail.png")

    # Motion contact frames use the same unchanged 22-frame Running action.
    run=Image.new("RGBA",(76+2*(2*crop_w+34),54+len(RUN_FRAMES)*cell_h),(14,16,20,255));d=ImageDraw.Draw(run)
    d.text((12,12),"Running action shoulder clearance · V003/V004",fill=(238,238,238,255))
    for ci,di in enumerate(("S","SE")):d.text((76+ci*(2*crop_w+34)+crop_w,38),di,fill=(240,210,140,255))
    for ri,frame in enumerate(RUN_FRAMES):
        y=54+ri*cell_h;d.text((5,y+crop_h//2),f"run {frame}",fill=(230,230,230,255))
        for ci,di in enumerate(("S","SE")):
            x=76+ci*(2*crop_w+34)
            for vi,root in enumerate((proof/"v003_running512",proof/"v004_running512")):
                im=image(root/di/f"{frame:04d}.png",(512,512)).crop(crop)
                paste_bg(run,im,(x+vi*(crop_w+10),y+20));d.text((x+vi*(crop_w+10)+3,y+3),"V003" if vi==0 else "V004",fill=(230,230,230,255))
    run.save(out/"operator_v004_shoulder_motion_contact_sheet.png")

    # Objective framing and exact decoded-pixel comparisons.
    bounds={};diffs=[]
    for root,label,size in ((proof/"native128","V004 native128",128),(proof/"native512","V004 native512",512)):
        for p in sorted(root.rglob("*.png")):
            im=image(p,(size,size));box=im.getchannel("A").getbbox()
            margins=[box[0],box[1],size-box[2],size-box[3]] if box else [size]*4
            bounds[str(p.relative_to(proof))]={"size":[size,size],"alpha_bbox":list(box) if box else None,"transparent_margin_min_px":min(margins)}
    for di in DIRECTIONS:
        for frame in (1,132,263):
            a=image(proof/"v003_native128"/di/f"{frame:04d}.png",(128,128))
            b=image(proof/"native128"/di/f"{frame:04d}.png",(128,128))
            import numpy as np
            aa=np.asarray(a);bb=np.asarray(b);mask=np.any(aa!=bb,axis=2)
            yy,xx=np.where(mask)
            diffs.append({"direction":di,"frame":frame,"different_pixels":int(mask.sum()),"compared_pixels":128*128,"bounds":[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)] if len(xx) else None})
    outputs={p.name:{"sha256":sha(p),"bytes":p.stat().st_size,"dimensions":list(Image.open(p).size)} for p in sorted(out.glob("*.png"))}
    manifest={
        "schema":"custodian.operator_v004_comparison_manifest.v1",
        "candidate_state":"candidate_unapproved",
        "source":{"branch":"manual/operator-3d-visual-fidelity-candidate-v3-mesh-separation","commit":"c10a3415a9a788cf56619505ceebe780331b0eb6","sha256":"17c3cc57ce58aff1e400636d8b5f1db5bc97058d7028d6de587803514a131589"},
        "candidate":{"path":"custodian/asset_drop/source_work/operator/operator_3d_master/masters/operator_3d_iter005_visual_fidelity_candidate_v004/operator_3d_iter005_visual_fidelity_candidate_v004.blend","sha256":candidate_v4_sha,"source_v3_sha256":source_v3_sha},
        "review_inputs":{"approved_art_path":"custodian/asset_drop/source_work/operator/operator_2_5d_first_animation/unarmed_posture_idle_relaxed_01_full_body_v1_source.png","approved_art_sha256":"d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3","runtime_manifest":"custodian/content/sprites/operator/runtime/operator_runtime_manifest.generated.json","runtime_resolution":"live legacy_96 selector/presenter, as composed by iteration_reference_contact_sheet.py","v3_blend_sha256":source_v3_sha},
        "rendering":{"blender":"5.2.3 LTS","render_only_mesh_join":"V004 body and two pauldron mesh objects joined in a temporary render-only copy; combined vertex/face counts match split candidate totals; shipped V004 remains three identifiable mesh objects","camera":{"elevation_degrees":45,"pixels_per_meter":50,"scale":1.2287417600294088,"root_pixel_128":[64,106],"directions":list(DIRECTIONS),"mirroring":False},"native128_frames":[1,132,263],"native512_contact_frames":list(IDLE_FRAMES),"native512_directions":list(DETAIL_DIRECTIONS),"running_frames":[6,16],"running_directions":["S","SE"],"reduction":"tools/custodian_aliases.sh pixelart --pixel-source --size 128 --choose 1; invoked independently for each V4 512px sample"},
        "pixel_bounds":bounds,
        "v3_vs_v4_native128_pixel_diff":diffs,
        "outputs":outputs,
    }
    (out/"comparison_manifest.v1.json").write_text(json.dumps(manifest,indent=2,sort_keys=True)+"\n")
    print(json.dumps({"result":"built","output_dir":str(out),"outputs":list(outputs),"manifest":str(out/"comparison_manifest.v1.json"),"minimum_alpha_margin_128":min(v['transparent_margin_min_px'] for k,v in bounds.items() if k.startswith('native128/'))},sort_keys=True))

if __name__=="__main__":
    # proof, repo, source blend, candidate blend, source hash, candidate hash
    run(Path(sys.argv[1]),Path(sys.argv[2]),Path(sys.argv[3]),Path(sys.argv[4]),sys.argv[5],sys.argv[6])
