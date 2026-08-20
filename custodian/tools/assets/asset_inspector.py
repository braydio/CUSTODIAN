"""Physical PNG layout inspection."""
from __future__ import annotations
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from PIL import Image
class FrameLayout(str,Enum):
    COPY="copy"; HORIZONTAL_STRIP="horizontal_strip"; VERTICAL_STRIP="vertical_strip"; GRID="grid"; AMBIGUOUS="ambiguous"
@dataclass(frozen=True)
class AssetInspection:
    source_path:Path; width:int; height:int; frame_width:int; frame_height:int; frame_count:int; layout:FrameLayout; columns:int|None=None; rows:int|None=None
def inspect_png(path:Path,fw:int,fh:int,layout:str="auto",columns:int|None=None,rows:int|None=None)->AssetInspection:
    with Image.open(path) as image: w,h=image.size
    if layout=="grid":
        if not columns or not rows or (w,h)!=(fw*columns,fh*rows): return AssetInspection(path,w,h,fw,fh,0,FrameLayout.AMBIGUOUS)
        return AssetInspection(path,w,h,fw,fh,columns*rows,FrameLayout.GRID,columns,rows)
    candidates=[]
    if (w,h)==(fw,fh): candidates.append((FrameLayout.COPY,1))
    if h==fh and w>fw and w%fw==0: candidates.append((FrameLayout.HORIZONTAL_STRIP,w//fw))
    if w==fw and h>fh and h%fh==0: candidates.append((FrameLayout.VERTICAL_STRIP,h//fh))
    if layout!="auto": candidates=[item for item in candidates if item[0]==FrameLayout(layout)]
    if len(candidates)!=1: return AssetInspection(path,w,h,fw,fh,0,FrameLayout.AMBIGUOUS)
    kind,count=candidates[0]; return AssetInspection(path,w,h,fw,fh,count,kind)
