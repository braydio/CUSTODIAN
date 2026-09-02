from __future__ import annotations

from collections import Counter, defaultdict
from dataclasses import asdict, dataclass
import hashlib, json
from PIL import Image

SCHEMA="custodian.operator_art_palette_report.v1"

def srgb_channel(value:int)->float:
    x=value/255.0
    return x/12.92 if x<=0.04045 else ((x+0.055)/1.055)**2.4

def relative_luminance(rgb:tuple[int,int,int])->float:
    r,g,b=(srgb_channel(x) for x in rgb); return .2126*r+.7152*g+.0722*b

@dataclass(frozen=True)
class PaletteColor:
    rgb: tuple[int,int,int]; count:int; frame_count:int; frames:list[int]; relative_luminance:float; first_seen_frame:int
    def to_json(self):
        value=asdict(self); value["rgb"]=list(self.rgb); return value

def inspect(frames:list[Image.Image],layer:str="") -> dict:
    counts=Counter(); seen=defaultdict(set); semi=0; opaque=0
    for number,source in enumerate(frames,1):
        for r,g,b,a in source.convert("RGBA").getdata():
            if a==0: continue
            opaque+=1; semi+=a<255; rgb=(r,g,b); counts[rgb]+=1; seen[rgb].add(number)
    colors=[]
    for rgb in sorted(counts,key=lambda x:(relative_luminance(x),x)):
        fs=sorted(seen[rgb]); colors.append(PaletteColor(rgb,counts[rgb],len(fs),fs,relative_luminance(rgb),fs[0]).to_json())
    canonical=json.dumps([(x["rgb"],x["count"],x["frames"]) for x in colors],separators=(",",":"))
    return {"schema":SCHEMA,"frame_count":len(frames),"layer":layer,"colors":colors,"opaque_pixel_count":opaque,
            "semitransparent_pixel_count":semi,"palette_sha256":hashlib.sha256(canonical.encode()).hexdigest()}

def alpha_sha(frames:list[Image.Image])->str:
    h=hashlib.sha256()
    for x in frames:h.update(x.convert("RGBA").getchannel("A").tobytes())
    return h.hexdigest()

def silhouette_sha(frames:list[Image.Image])->str:
    h=hashlib.sha256()
    for x in frames:h.update(x.convert("RGBA").getchannel("A").point(lambda a:255 if a else 0).tobytes())
    return h.hexdigest()
