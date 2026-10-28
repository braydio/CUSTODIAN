"""Build grounded heel/toe overlays and before/after contact review media.

Usage: python build_contact_review_iter004.py <iter002_128> <iter003_128> <iter002_512> <iter003_512> <diag_iter002.json> <diag_iter003.json> <outdir>

The input renders must use the Task 015 fixed camera/pivot/scale contract.
512px renders are resized only for loop playback; the focused 512 sheet stays native.
"""
from pathlib import Path
import sys, json, math
import numpy as np
from PIL import Image, ImageDraw

base128, new128, base512, new512, diag_base, diag_new, out = map(Path,sys.argv[1:])
out.mkdir(parents=True,exist_ok=True)
before=json.load(open(diag_base)); after=json.load(open(diag_new))
CAM=after['render_camera_contract']; scale=CAM['uniform_scale']; cx,cy=CAM['pivot_center_xy_m']; z0=CAM['ground_pivot_z_m']
AZ={'N':180,'NE':-135,'E':-90,'SE':-45,'S':0,'SW':45,'W':90,'NW':135}
FRAMES=[11,12,13,14]
FOCUSED=['N','E','S','SE']
LABELS={'left_heel':'LH','left_toe':'LT','right_heel':'RH','right_toe':'RT'}
COLORS={'left_heel':(55,220,255),'left_toe':(255,115,220),'right_heel':(90,155,255),'right_toe':(255,190,70)}

def get_frame(diag,frame): return diag['frames'][frame-1]

def project(pos, direction, res):
    r=math.radians(AZ[direction]); elev=math.radians(45)
    cam=np.array([math.sin(r)*math.cos(elev),-math.cos(r)*math.cos(elev),math.sin(elev)])
    view=-cam/np.linalg.norm(cam); up0=np.array([0.,0.,1.])
    right=np.cross(view,up0); right/=np.linalg.norm(right)
    up=np.cross(right,view); up/=np.linalg.norm(up)
    pivot=np.array([cx,cy,z0]); q=(np.asarray(pos,dtype=float)-pivot)*scale
    pixels_per_meter=50.0*res/128.0
    root=np.array([64.0*res/128.0,106.0*res/128.0])
    return root+np.array([np.dot(q,right),-np.dot(q,up)])*pixels_per_meter

def paint(img,diag,frame,direction,res,label):
    draw=ImageDraw.Draw(img,'RGBA')
    g=np.array([cx,cy,0.0]); gy=project(g,direction,res)[1]
    draw.line((0,int(round(gy)),res,int(round(gy))),fill=(115,235,145,225),width=max(1,res//256))
    row=get_frame(diag,frame)
    for name,short in LABELS.items():
        p=row['fixed_landmarks'][name]['xyz_m']; z=row['fixed_landmarks'][name]['z_mm']
        x,y=project(p,direction,res); x=int(round(x)); y=int(round(y)); color=COLORS[name]
        rr=max(3,res//64)
        draw.ellipse((x-rr,y-rr,x+rr,y+rr),fill=(*color,235),outline=(0,0,0,255),width=max(1,res//256))
        draw.text((x+rr+1,y-rr-2),f'{short} {z:+.0f}mm',fill=(*color,255),stroke_width=1,stroke_fill=(0,0,0,220))
    draw.text((3,3),f'{label}  f{frame:02d} {direction}',fill=(255,255,255,255),stroke_width=1,stroke_fill=(0,0,0,230))
    return img

def tile(root,res,d,frame,diag,label):
    im=Image.open(root/f'{res}_{d}_{frame:02d}.png').convert('RGBA')
    return paint(im,diag,frame,d,res,label).convert('RGB')

def compare_sheet(res,dirs,path):
    roots=(base128,new128) if res==128 else (base512,new512)
    diags=(before,after)
    tile_h=res+22; sheet=Image.new('RGB',(len(dirs)*2*res,len(FRAMES)*tile_h),(20,20,25))
    for ri,fr in enumerate(FRAMES):
        for ci,d in enumerate(dirs):
            for vi,(root,diag,label) in enumerate(zip(roots,diags,('ITER002','ITER003'))):
                im=tile(root,res,d,fr,diag,label); sheet.paste(im,(ci*2*res+vi*res,ri*tile_h+22))
                ImageDraw.Draw(sheet).text((ci*2*res+vi*res+3,ri*tile_h+4),f'{d} f{fr:02d} {label}',fill='white')
    sheet.save(path,optimize=True)

compare_sheet(128,list(AZ),out/'contact_128_all8_iter002_vs_iter003.png')
compare_sheet(512,FOCUSED,out/'contact_512_native_focused_iter002_vs_iter003.png')

def make_loop(res,oldroot,newroot,filename):
    if res==128: roots=(oldroot,newroot); dirs=list(AZ)
    else: roots=(oldroot,newroot); dirs=list(AZ)
    loop=[]
    for frame in range(1,22):
        before_strip=Image.new('RGB',(128*8,128),(0,0,0)); after_strip=Image.new('RGB',(128*8,128),(0,0,0))
        for ci,d in enumerate(dirs):
            for root,diag,strip in ((roots[0],before,before_strip),(roots[1],after,after_strip)):
                im=tile(root,res,d,frame,diag,'')
                if res!=128: im=im.resize((128,128),Image.Resampling.LANCZOS)
                strip.paste(im,(ci*128,0))
        frame_img=Image.new('RGB',(1024,282),(24,24,28)); frame_img.paste(before_strip,(0,20)); frame_img.paste(after_strip,(0,154))
        ImageDraw.Draw(frame_img).text((5,3),f'{res}px source ITER002 (upper) / ITER003 (lower), all 8 directions | frame {frame}/21 | green line = ground',fill='white')
        loop.append(frame_img.convert('P',palette=Image.Palette.ADAPTIVE,colors=128))
    loop[0].save(out/filename,save_all=True,append_images=loop[1:],duration=70,loop=0,optimize=True,disposal=2)

make_loop(128,base128,new128,'contact_loop_128_all8.gif')
make_loop(512,base512,new512,'contact_loop_512_all8.gif')

summary={'schema':'custodian.operator_run_contact_review.v1','renders_reused_from':'Task 015 ITER002/ITER003 full native render sets; no camera or frame resampling changes',
         'overlay':'green line is z=0 ground plane; LH/LT/RH/RT labels mark the same fixed 12-vertex centroids used by contact measurements; labels show centroid z in mm',
         'native_128_sheet':str(out/'contact_128_all8_iter002_vs_iter003.png'),'native_512_sheet':str(out/'contact_512_native_focused_iter002_vs_iter003.png'),
         'loop_128':str(out/'contact_loop_128_all8.gif'),'loop_512':str(out/'contact_loop_512_all8.gif'),
         '512_loop_note':'independently rendered 512px frames are reduced to 128px per direction only for the loop; native 512px stills are in the focused contact sheet.'}
json.dump(summary,open(out/'contact_review_metadata.json','w'),indent=2)
print(json.dumps(summary,indent=2))
