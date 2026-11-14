#!/usr/bin/env python3
"""Check the immutable Meridian Civic Wall archival source record."""

from __future__ import annotations

import hashlib
import json
import struct
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
SOURCE = Path("custodian/asset_drop/source_work/meridian_civic/meridian_wall_3d_v1/Meridian_Wall_3D_Textured_model.meshy")
CANONICAL = Path("custodian/asset_drop/source_work/meridian_civic/meridian_wall_3d_v1/meridian_civic_wall_v1.glb")
ARCHIVAL = Path("MERIDIAN_CIVIC_WALL_3D_V1.glb")
RECORD = Path("MERIDIAN_CIVIC_WALL_3D_V1.md")
SOURCE_SHA256 = "9ca53b5bd034380e9afe46dbed3138ce17aed1628830f2d035fe8fdb62188fc2"
GLB_SHA256 = "342056035401bfa626233072c629ceaf0ff7517a5a6687ad564dc2d5cb49c666"


def lfs_oid(path: Path) -> tuple[str, int] | None:
    raw = path.read_bytes()
    if not raw.startswith(b"version https://git-lfs.github.com/spec/v1\n"):
        return None
    values = dict(line.split(" ", 1) for line in raw.decode("ascii").splitlines()[1:] if " " in line)
    return values["oid"].removeprefix("sha256:"), int(values["size"])


def content_sha(path: Path) -> str:
    raw = path.read_bytes()
    pointer = lfs_oid(path)
    return pointer[0] if pointer else hashlib.sha256(raw).hexdigest()


def indexed_lfs_oid(path: Path) -> tuple[str, int]:
    raw = subprocess.run(
        ["git", "show", f":{path.as_posix()}"], cwd=ROOT,
        check=True, capture_output=True,
    ).stdout
    pointer = lfs_oid_from_bytes(raw)
    assert pointer is not None, f"Git index does not contain an LFS pointer: {path}"
    return pointer


def lfs_oid_from_bytes(raw: bytes) -> tuple[str, int] | None:
    if not raw.startswith(b"version https://git-lfs.github.com/spec/v1\n"):
        return None
    values = dict(line.split(" ", 1) for line in raw.decode("ascii").splitlines()[1:] if " " in line)
    return values["oid"].removeprefix("sha256:"), int(values["size"])


def check_glb(path: Path) -> None:
    raw = path.read_bytes()
    if lfs_oid(path):
        # GitHub CI may keep LFS smudging disabled. The immutable pointer SHA is
        # still checked above; structural parsing is done when content is local.
        return
    magic, version, length = struct.unpack_from("<4sII", raw)
    assert (magic, version, length) == (b"glTF", 2, len(raw)), path
    offset = 12
    document = None
    while offset < len(raw):
        size, kind = struct.unpack_from("<I4s", raw, offset)
        offset += 8
        chunk = raw[offset:offset + size]
        assert len(chunk) == size, path
        if kind == b"JSON":
            document = json.loads(chunk.rstrip(b" \t\r\n\0"))
        offset += size
    assert offset == len(raw) and document is not None, path
    assert len(document.get("meshes", [])) == 1, path
    assert len(document.get("materials", [])) == 1, path
    assert len(document.get("images", [])) == 3, path
    assert len(document.get("textures", [])) == 3, path


def main() -> None:
    for path, digest in ((SOURCE, SOURCE_SHA256), (CANONICAL, GLB_SHA256), (ARCHIVAL, GLB_SHA256)):
        assert content_sha(ROOT / path) == digest, f"unexpected content identity: {path}"
    assert indexed_lfs_oid(SOURCE) == (SOURCE_SHA256, 1_628_604)
    assert indexed_lfs_oid(CANONICAL) == (GLB_SHA256, 1_628_556)
    assert indexed_lfs_oid(ARCHIVAL) == (GLB_SHA256, 1_628_556)
    for path in (CANONICAL, ARCHIVAL):
        check_glb(ROOT / path)
    attributes = subprocess.run(
        ["git", "check-attr", "filter", "--", str(SOURCE), str(CANONICAL), str(ARCHIVAL)],
        cwd=ROOT, text=True, check=True, capture_output=True,
    ).stdout.splitlines()
    assert len(attributes) == 3 and all(line.endswith(": filter: lfs") for line in attributes), attributes
    record = (ROOT / RECORD).read_text()
    for text in (SOURCE_SHA256, GLB_SHA256, "skips verification", "archived source validation only"):
        assert text.lower() in record.lower(), f"provenance record is missing {text!r}"
    print("PASS: Meridian source, GLB LFS identities, parseable content, and provenance record")


if __name__ == "__main__":
    main()
