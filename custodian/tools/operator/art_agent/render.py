from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops


def split_strip(
    strip_path: Path,
    *,
    frame_width: int,
    frame_height: int,
    frame_count: int,
    output_dir: Path,
) -> list[Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    paths: list[Path] = []
    with Image.open(strip_path) as source_image:
        source = source_image.convert("RGBA")
        expected = (frame_width * frame_count, frame_height)
        if source.size != expected:
            raise ValueError(f"rendered strip size {source.size} != {expected}")
        for index in range(frame_count):
            frame = source.crop(
                (
                    index * frame_width,
                    0,
                    (index + 1) * frame_width,
                    frame_height,
                )
            )
            path = output_dir / f"{index + 1:03d}.png"
            frame.save(path)
            paths.append(path)
    return paths


def make_contact_sheet(
    frame_paths: list[Path],
    output: Path,
    *,
    columns: int = 3,
    padding: int = 8,
) -> None:
    if not frame_paths:
        raise ValueError("contact sheet requires at least one frame")
    images = [Image.open(path).convert("RGBA") for path in frame_paths]
    try:
        frame_width, frame_height = images[0].size
        if any(image.size != (frame_width, frame_height) for image in images):
            raise ValueError("contact sheet frames have different dimensions")
        rows = (len(images) + columns - 1) // columns
        canvas = Image.new(
            "RGBA",
            (
                columns * frame_width + (columns + 1) * padding,
                rows * frame_height + (rows + 1) * padding,
            ),
            (0, 0, 0, 0),
        )
        for index, image in enumerate(images):
            column = index % columns
            row = index // columns
            canvas.alpha_composite(
                image,
                (padding + column * (frame_width + padding),
                 padding + row * (frame_height + padding)),
            )
        output.parent.mkdir(parents=True, exist_ok=True)
        canvas.save(output)
    finally:
        for image in images:
            image.close()


def make_diff(before_path: Path, after_path: Path, output_path: Path) -> None:
    with Image.open(before_path) as before_image, Image.open(after_path) as after_image:
        before = before_image.convert("RGBA")
        after = after_image.convert("RGBA")
        if before.size != after.size:
            raise ValueError("diff images have different dimensions")
        output_path.parent.mkdir(parents=True, exist_ok=True)
        ImageChops.difference(before, after).save(output_path)


def make_before_after(before_path: Path, after_path: Path, output_path: Path) -> None:
    with Image.open(before_path) as before_image, Image.open(after_path) as after_image:
        before = before_image.convert("RGBA")
        after = after_image.convert("RGBA")
        if before.size != after.size:
            raise ValueError("before/after images have different dimensions")
        canvas = Image.new("RGBA", (before.width, before.height * 2), (0, 0, 0, 0))
        canvas.alpha_composite(before, (0, 0))
        canvas.alpha_composite(after, (0, before.height))
        output_path.parent.mkdir(parents=True, exist_ok=True)
        canvas.save(output_path)


def make_silhouette_sheet(frame_paths: list[Path], output: Path) -> None:
    temporary=[]
    try:
        for index,path in enumerate(frame_paths):
            with Image.open(path) as source:
                image=source.convert("RGBA"); alpha=image.getchannel("A"); silhouette=Image.new("RGBA",image.size,(255,255,255,0)); silhouette.putalpha(alpha)
                item=output.parent/f".silhouette_{index}.png"; silhouette.save(item); temporary.append(item)
        make_contact_sheet(temporary,output)
    finally:
        for path in temporary: path.unlink(missing_ok=True)


def make_onion_skin(frame_paths: list[Path], output: Path) -> None:
    images=[Image.open(path).convert("RGBA") for path in frame_paths]
    try:
        canvas=Image.new("RGBA",images[0].size,(0,0,0,0))
        for image in images:
            layer=image.copy(); layer.putalpha(layer.getchannel("A").point(lambda value:value//max(1,len(images))))
            canvas=Image.alpha_composite(canvas,layer)
        canvas.save(output)
    finally:
        for image in images: image.close()


def make_animation_gif(frame_paths: list[Path], output: Path, *, fps: float) -> None:
    images=[Image.open(path).convert("RGBA") for path in frame_paths]
    try: images[0].save(output,save_all=True,append_images=images[1:],duration=max(1,round(1000/fps)),loop=0,disposal=2)
    finally:
        for image in images: image.close()


def make_mask_overlay(frame_path: Path, spans: list[dict], output: Path) -> None:
    with Image.open(frame_path) as source:
        image=source.convert("RGBA"); overlay=Image.new("RGBA",image.size,(0,0,0,0)); pixels=overlay.load()
        for span in spans:
            for x in range(span["x0"],span["x1"]+1): pixels[x,span["y"]]=(0,255,255,112)
        Image.alpha_composite(image,overlay).save(output)


def extract_note_components(frame_path: Path, frame: int) -> list[dict]:
    colors={(255,0,0):"remove",(0,255,255):"target",(255,255,0):"preserve"}
    with Image.open(frame_path) as source:
        image=source.convert("RGBA"); pixels=image.load(); visited=set(); result=[]
        for y in range(image.height):
            for x in range(image.width):
                rgb=pixels[x,y][:3]
                if rgb not in colors or pixels[x,y][3]==0 or (x,y) in visited: continue
                stack=[(x,y)]; visited.add((x,y)); points=[]
                while stack:
                    point=stack.pop(); points.append(point)
                    for neighbor in ((point[0]-1,point[1]),(point[0]+1,point[1]),(point[0],point[1]-1),(point[0],point[1]+1)):
                        if 0<=neighbor[0]<image.width and 0<=neighbor[1]<image.height and neighbor not in visited and pixels[neighbor[0],neighbor[1]][:3]==rgb and pixels[neighbor[0],neighbor[1]][3]>0: visited.add(neighbor); stack.append(neighbor)
                x0=min(p[0] for p in points); x1=max(p[0] for p in points); y0=min(p[1] for p in points); y1=max(p[1] for p in points)
                result.append({"frame":frame,"kind":colors[rgb],"bounds":[x0,y0,x1-x0+1,y1-y0+1],"pixel_count":len(points),"source":"__REVIEW_NOTES"})
        return result
