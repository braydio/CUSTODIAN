from __future__ import annotations

import hashlib
from dataclasses import asdict, dataclass
from PIL import Image, ImageDraw, ImageFilter


@dataclass(frozen=True)
class MaskSpan:
    y: int
    x0: int
    x1: int


@dataclass
class PartMask:
    mask_id: str
    frame: int
    layer: str
    part: str
    spans: list[MaskSpan]
    bounds: list[int]
    source_workbench_sha256: str
    source_cel_fingerprint: str
    provenance: str
    confidence: float

    def to_json(self) -> dict:
        value = asdict(self)
        value["spans"] = [asdict(span) for span in self.spans]
        return value

    @classmethod
    def from_json(cls, value: dict) -> "PartMask":
        value = dict(value); value["spans"] = [MaskSpan(**x) for x in value["spans"]]
        return cls(**value)


def image_to_spans(image: Image.Image) -> list[MaskSpan]:
    image = image.convert("1")
    spans = []
    for y in range(image.height):
        x = 0
        while x < image.width:
            while x < image.width and not image.getpixel((x, y)): x += 1
            if x == image.width: break
            x0 = x
            while x + 1 < image.width and image.getpixel((x + 1, y)): x += 1
            spans.append(MaskSpan(y, x0, x)); x += 1
    return spans


def spans_to_image(spans: list[MaskSpan], size: tuple[int, int]) -> Image.Image:
    image = Image.new("1", size)
    draw = ImageDraw.Draw(image)
    for span in spans: draw.line((span.x0, span.y, span.x1, span.y), fill=1)
    return image


def bounds(spans: list[MaskSpan]) -> list[int]:
    if not spans: return [0, 0, 0, 0]
    x0=min(s.x0 for s in spans); x1=max(s.x1 for s in spans); y0=min(s.y for s in spans); y1=max(s.y for s in spans)
    return [x0, y0, x1-x0+1, y1-y0+1]


def polygon(size: tuple[int, int], points: list[list[int]]) -> list[MaskSpan]:
    image=Image.new("1",size); ImageDraw.Draw(image).polygon([tuple(x) for x in points],fill=1)
    return image_to_spans(image)


def rectangle(size: tuple[int, int], rect: list[int]) -> list[MaskSpan]:
    x,y,w,h=rect; image=Image.new("1",size); ImageDraw.Draw(image).rectangle((x,y,x+w-1,y+h-1),fill=1)
    return image_to_spans(image)


def alpha_region(image: Image.Image, *, seed: tuple[int, int] | None = None) -> list[MaskSpan]:
    alpha=image.convert("RGBA").getchannel("A"); binary=alpha.point(lambda value:1 if value else 0,mode="1")
    if seed is None: return image_to_spans(binary)
    if not binary.getpixel(seed): return []
    pending=[seed]; visited={seed}; output=Image.new("1",binary.size); pixels=output.load()
    while pending:
        x,y=pending.pop(); pixels[x,y]=1
        for point in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
            if 0<=point[0]<binary.width and 0<=point[1]<binary.height and point not in visited and binary.getpixel(point): visited.add(point); pending.append(point)
    return image_to_spans(output)


def combine(a: list[MaskSpan], b: list[MaskSpan], size: tuple[int,int], operation: str) -> list[MaskSpan]:
    ai=spans_to_image(a,size); bi=spans_to_image(b,size)
    ap=set((x,y) for y in range(size[1]) for x in range(size[0]) if ai.getpixel((x,y)))
    bp=set((x,y) for y in range(size[1]) for x in range(size[0]) if bi.getpixel((x,y)))
    result={"union":ap|bp,"subtract":ap-bp,"intersect":ap&bp}[operation]
    out=Image.new("1",size); pix=out.load()
    for point in result: pix[point]=1
    return image_to_spans(out)


def morphology(spans: list[MaskSpan], size: tuple[int,int], mode: str) -> list[MaskSpan]:
    image=spans_to_image(spans,size).convert("L")
    image=image.filter(ImageFilter.MaxFilter(3) if mode=="dilate" else ImageFilter.MinFilter(3))
    return image_to_spans(image.point(lambda value: 1 if value else 0, mode="1"))


def fingerprint(spans: list[MaskSpan]) -> str:
    return hashlib.sha256(repr([(x.y,x.x0,x.x1) for x in spans]).encode()).hexdigest()
