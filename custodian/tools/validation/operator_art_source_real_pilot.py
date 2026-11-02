#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "custodian/tools/operator"))

from art_agent.source_service import ALLOWED_SOURCE_ROOTS, SourceArtService


def tree_hash(root: Path) -> str:
    digest = hashlib.sha256()
    if root.exists():
        for path in sorted(item for item in root.rglob("*") if item.is_file()):
            digest.update(str(path.relative_to(root)).encode())
            digest.update(path.read_bytes())
    return digest.hexdigest()


def fixture(path: Path, frames: int) -> None:
    image = Image.new("RGBA", (256 * frames, 512), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    for index in range(frames):
        x = index * 256
        bob = (index % 4) * 3
        draw.ellipse((x + 70, 42 + bob, x + 186, 158 + bob), fill=(46, 61, 73, 255))
        draw.polygon([(x + 48, 460), (x + 74, 148 + bob), (x + 182, 148 + bob), (x + 210, 460)], fill=(78, 96, 108, 255))
        draw.rectangle((x + 78, 410, x + 112, 480), fill=(190, 154, 82, 255))
        draw.rectangle((x + 144, 410, x + 178, 480), fill=(190, 154, 82, 255))
    image.save(path)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path)
    parser.add_argument("--frames", type=int, default=8)
    parser.add_argument("--target-size", type=int, default=96)
    args = parser.parse_args()
    protected = ROOT / "custodian/content/sprites/operator"
    before = tree_hash(protected)
    with tempfile.TemporaryDirectory(prefix="operator-art-source-pilot-") as temp:
        work = Path(temp)
        if args.source:
            source = args.source.resolve(strict=True)
            service = SourceArtService()
        else:
            allowed = work / "asset_drop/inbox"
            allowed.mkdir(parents=True)
            source = allowed / "operator_highres_walk_8f.png"
            fixture(source, args.frames)
            service = SourceArtService(root=work / ".ai/source_sessions", allowed_source_roots=(allowed,))
        source_before = source.read_bytes()
        session = service.start(source_path=source, frames=args.frames, target_size=args.target_size)
        analysis = service.analyze(session)
        plan = service.plan_normalization(session)
        conversion = service.convert(session)
        review = service.review(session)
        result = {
            "status": review["status"],
            "session": str(session),
            "source": str(source),
            "frame_count": analysis["geometry"]["frame_count"],
            "global_scale": plan["global_scale"],
            "candidates": conversion["candidates"],
            "review": review,
            "source_unchanged": source.read_bytes() == source_before,
            "production_unchanged": tree_hash(protected) == before,
        }
        assert result["status"] == "PASS", result
        assert result["source_unchanged"] and result["production_unchanged"]
        print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
