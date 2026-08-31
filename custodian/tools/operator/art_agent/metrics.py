from __future__ import annotations

import hashlib
from pathlib import Path
from PIL import Image


def frame_metrics(path: Path) -> dict:
    with Image.open(path) as source:
        image=source.convert("RGBA"); alpha=image.getchannel("A"); bbox=alpha.getbbox(); pixels=list(image.getdata())
        occupied=[(i%image.width,i//image.width,p) for i,p in enumerate(pixels) if p[3]]
        opaque=sum(p[3]==255 for _,_,p in occupied); semi=sum(0<p[3]<255 for _,_,p in occupied)
        centroid=[sum(x for x,_,_ in occupied)/len(occupied),sum(y for _,y,_ in occupied)/len(occupied)] if occupied else None
        return {"size":[image.width,image.height],"alpha_bbox":list(bbox) if bbox else None,"opaque_pixels":opaque,"semi_transparent_pixels":semi,"visual_centroid":centroid,"lowest_occupied_y":max((y for _,y,_ in occupied),default=None),"highest_occupied_y":min((y for _,y,_ in occupied),default=None),"width":0 if not bbox else bbox[2]-bbox[0],"height":0 if not bbox else bbox[3]-bbox[1],"palette_size":len({p for _,_,p in occupied}),"pixel_sha":hashlib.sha256(image.tobytes()).hexdigest()}


def animation_metrics(paths: list[Path], landmarks: list[dict] | None = None) -> dict:
    frames=[frame_metrics(path) for path in paths]; hashes=[x["pixel_sha"] for x in frames]
    duplicate=[i+1 for i in range(1,len(hashes)) if hashes[i]==hashes[i-1]]
    trajectories={}
    for point in landmarks or []: trajectories.setdefault(point["name"],[]).append([point["frame"],point["x"],point["y"]])
    return {"schema":"custodian.operator_art_metrics.v1","frames":frames,"duplicate_adjacent_frames":duplicate,"loop_discontinuity":bool(hashes and hashes[0]!=hashes[-1]),"trajectories":trajectories}
