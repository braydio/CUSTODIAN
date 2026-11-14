"""Rig input validation and immutable part loading."""
from __future__ import annotations

from pathlib import Path
from typing import Any

from PIL import Image

from .schema import DIRECTIONS, HEX, RIG_SCHEMA, confined_path, inside, integer_pair, read_json, sha256_file

PROFILE_SHA256 = "05e92192af68b2f4e7516f59a0938e536926f3525a31b42dd7695f61d77ca761"


def load_rig(path: Path, source_root: Path) -> tuple[dict[str, Any], dict[str, Image.Image], dict[str, Path]]:
    rig = read_json(path)
    if rig.get("schema") != RIG_SCHEMA:
        raise ValueError("unsupported rig schema")
    if rig.get("owner") != "operator" or rig.get("art_generation") != "operator_2_5d_128":
        raise ValueError("unsupported rig owner or art generation")
    if rig.get("direction") not in DIRECTIONS:
        raise ValueError("invalid rig direction")
    size = integer_pair(rig.get("frame_size"), "frame_size")
    if size not in {(128, 128), (96, 96)}:
        raise ValueError("unsupported rig frame size")
    if rig["art_generation"] == "operator_2_5d_128" and size != (128, 128):
        raise ValueError("operator_2_5d_128 rigs must use 128x128 cells")
    root, ground = integer_pair(rig.get("root"), "root"), integer_pair(rig.get("ground"), "ground")
    if not inside(root, size) or not inside(ground, size):
        raise ValueError("root and ground must be within the frame")
    if rig["art_generation"] == "operator_2_5d_128" and (root != (64, 106) or ground != (64, 107)):
        raise ValueError("Operator 2.5D root and ground must match the accepted registration")
    profile_sha = rig.get("reference_profile_sha256")
    if not isinstance(profile_sha, str) or not HEX.fullmatch(profile_sha):
        raise ValueError("invalid reference profile SHA-256")
    if rig["art_generation"] == "operator_2_5d_128" and profile_sha != PROFILE_SHA256:
        raise ValueError("changed Operator 2.5D profile SHA-256")
    parts = rig.get("parts")
    if not isinstance(parts, list) or not parts:
        raise ValueError("rig parts must be a non-empty list")
    ids: set[str] = set()
    orders: set[int] = set()
    normalized: dict[str, dict[str, Any]] = {}
    images: dict[str, Image.Image] = {}
    paths: dict[str, Path] = {}
    for part in parts:
        if not isinstance(part, dict):
            raise ValueError("part entry must be an object")
        part_id = part.get("id")
        if not isinstance(part_id, str) or not part_id or part_id in ids:
            raise ValueError("missing or duplicate part ID")
        ids.add(part_id)
        order = part.get("draw_order")
        if isinstance(order, bool) or not isinstance(order, int) or order in orders:
            raise ValueError("draw_order must be a unique integer")
        orders.add(order)
        pivot = integer_pair(part.get("pivot"), f"{part_id}.pivot")
        if not inside(pivot, size):
            raise ValueError(f"pivot outside canvas: {part_id}")
        if not isinstance(part.get("movable"), bool):
            raise ValueError(f"movable must be boolean: {part_id}")
        parent = part.get("parent")
        if parent is not None and (not isinstance(parent, str) or not parent):
            raise ValueError(f"invalid parent: {part_id}")
        digest = part.get("sha256")
        if not isinstance(digest, str) or not HEX.fullmatch(digest):
            raise ValueError(f"invalid source SHA-256: {part_id}")
        src = confined_path(part.get("source"), source_root)
        if sha256_file(src) != digest:
            raise ValueError(f"source hash mismatch: {part_id}")
        image = Image.open(src)
        image.load()
        if image.mode != "RGBA" or image.size != size:
            raise ValueError(f"part must be exact-size RGBA: {part_id}")
        if len(set(image.getchannel("A").getdata())) > 2 or not set(image.getchannel("A").getdata()) <= {0, 255}:
            raise ValueError(f"part alpha must be binary: {part_id}")
        normalized[part_id] = {**part, "pivot": pivot, "parent": parent}
        images[part_id], paths[part_id] = image, src
    for part_id, part in normalized.items():
        if part["parent"] is not None and part["parent"] not in ids:
            raise ValueError(f"missing parent for {part_id}")
        visited: set[str] = set()
        cursor: str | None = part_id
        while cursor is not None:
            if cursor in visited:
                raise ValueError("part hierarchy contains a cycle")
            visited.add(cursor)
            cursor = normalized[cursor]["parent"]
    rig["parts"] = sorted(normalized.values(), key=lambda p: p["draw_order"])
    rig["frame_size"] = size
    rig["root"], rig["ground"] = root, ground
    return rig, images, paths
