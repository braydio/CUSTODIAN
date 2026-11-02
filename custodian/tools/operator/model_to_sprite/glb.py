"""Strict, bounded inspection for standard self-contained or locally referenced GLB 2.0."""
from __future__ import annotations

import array
import hashlib
import json
import math
import os
import pathlib
import re
import struct
from urllib.parse import unquote, urlsplit


MAX_GLB_BYTES = 256 * 1024 * 1024
SUPPORTED_REQUIRED_EXTENSIONS = {"KHR_texture_transform"}
COMPONENT_TYPES = {5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2), 5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4)}
TYPE_COUNTS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT2": 4, "MAT3": 9, "MAT4": 16}
SHA256_RE = re.compile(r"^[a-f0-9]{64}$")


class ModelToSpriteError(Exception):
    """User-facing deterministic error with a stable machine code."""

    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code
        self.message = message


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _regular_file(path: pathlib.Path) -> pathlib.Path:
    if path.is_symlink():
        raise ModelToSpriteError("INPUT_UNSAFE_PATH", f"symbolic-link input is not allowed: {path.name}")
    try:
        resolved = path.resolve(strict=True)
        stat = resolved.stat()
    except OSError as exc:
        raise ModelToSpriteError("INPUT_MISSING", f"input cannot be read: {path.name}") from exc
    if not resolved.is_file() or not os.access(resolved, os.R_OK):
        raise ModelToSpriteError("INPUT_MISSING", f"input is not a readable regular file: {path.name}")
    if stat.st_size > MAX_GLB_BYTES:
        raise ModelToSpriteError("INPUT_TOO_LARGE", f"GLB exceeds {MAX_GLB_BYTES} bytes")
    try:
        with resolved.open("rb") as stream:
            prefix = stream.read(128)
    except OSError as exc:
        raise ModelToSpriteError("INPUT_MISSING", f"input cannot be read: {path.name}") from exc
    if prefix.startswith(b"version https://git-lfs.github.com/spec/v1"):
        raise ModelToSpriteError("INPUT_LFS_POINTER", "input is a Git LFS pointer, not hydrated model bytes")
    return resolved


def _external_uri(base: pathlib.Path, uri: str) -> pathlib.Path:
    parsed = urlsplit(uri)
    decoded = unquote(parsed.path)
    if parsed.scheme or parsed.netloc or parsed.query or parsed.fragment or not decoded:
        raise ModelToSpriteError("GLB_EXTERNAL_URI_UNSUPPORTED", "GLB external dependency must be a local relative path")
    candidate_path = pathlib.PurePosixPath(decoded)
    if candidate_path.is_absolute() or "\\" in decoded or any(part in ("", ".", "..") for part in candidate_path.parts):
        raise ModelToSpriteError("GLB_UNSAFE_DEPENDENCY", "GLB dependency path is absolute, traversing, or malformed")
    base = base.resolve(strict=True)
    candidate = base.joinpath(*candidate_path.parts)
    if candidate.is_symlink():
        raise ModelToSpriteError("GLB_UNSAFE_DEPENDENCY", "GLB dependency may not be a symbolic link")
    try:
        resolved = candidate.resolve(strict=True)
    except OSError as exc:
        raise ModelToSpriteError("GLB_DEPENDENCY_MISSING", f"GLB dependency is missing: {candidate_path.name}") from exc
    if base not in resolved.parents or not resolved.is_file():
        raise ModelToSpriteError("GLB_UNSAFE_DEPENDENCY", "GLB dependency escapes its input directory")
    return resolved


def _read_container(path: pathlib.Path) -> tuple[dict, bytes, dict[str, pathlib.Path]]:
    path = _regular_file(path)
    data = path.read_bytes()
    if len(data) < 20 or data[:4] != b"glTF":
        raise ModelToSpriteError("GLB_INVALID", "input is not a binary glTF (GLB)")
    version, declared_size = struct.unpack_from("<II", data, 4)
    if version != 2:
        raise ModelToSpriteError("GLB_INVALID", f"unsupported GLB version {version}; expected 2")
    if declared_size != len(data):
        raise ModelToSpriteError("GLB_INVALID", "GLB header length does not match file size")
    offset = 12
    chunks: list[tuple[int, bytes]] = []
    while offset < len(data):
        if offset + 8 > len(data):
            raise ModelToSpriteError("GLB_INVALID", "truncated GLB chunk header")
        length, kind = struct.unpack_from("<II", data, offset)
        offset += 8
        if length % 4 or offset + length > len(data):
            raise ModelToSpriteError("GLB_INVALID", "invalid GLB chunk length or alignment")
        chunks.append((kind, data[offset:offset + length]))
        offset += length
    if not chunks or chunks[0][0] != 0x4E4F534A or len(chunks) > 2:
        raise ModelToSpriteError("GLB_INVALID", "expected JSON and optional BIN chunks only")
    if len(chunks) == 2 and chunks[1][0] != 0x004E4942:
        raise ModelToSpriteError("GLB_INVALID", "second GLB chunk must be BIN")
    try:
        document = json.loads(chunks[0][1].decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise ModelToSpriteError("GLB_INVALID", "GLB JSON chunk is invalid") from exc
    if not isinstance(document, dict) or (document.get("asset") or {}).get("version") != "2.0":
        raise ModelToSpriteError("GLB_INVALID", "glTF asset.version must be 2.0")
    binary = chunks[1][1] if len(chunks) == 2 else b""
    dependencies: dict[str, pathlib.Path] = {}
    parent = path.parent
    for entry in document.get("buffers", []):
        uri = entry.get("uri")
        if not uri:
            if len(document.get("buffers", [])) > 1:
                raise ModelToSpriteError("GLB_INVALID", "multiple GLB buffers are unsupported")
            continue
        if uri.startswith("data:"):
            # Embedded data URIs need a separate decoder and are unnecessary in GLB 2.0.
            raise ModelToSpriteError("GLB_EXTERNAL_URI_UNSUPPORTED", "data-URI buffers are not accepted in the GLB binary path")
        dep = _external_uri(parent, uri)
        dependencies[str(dep.relative_to(parent))] = dep
    for image in document.get("images", []):
        uri = image.get("uri")
        if not uri or uri.startswith("data:"):
            continue
        dep = _external_uri(parent, uri)
        dependencies[str(dep.relative_to(parent))] = dep
    return document, binary, dependencies


def _buffer_data(document: dict, binary: bytes, dependencies: dict[str, pathlib.Path], source: pathlib.Path) -> bytes:
    buffers = document.get("buffers") or []
    if not buffers:
        return binary
    buffer = buffers[0]
    if buffer.get("uri"):
        uri_path = _external_uri(source.parent, buffer["uri"])
        data = uri_path.read_bytes()
    else:
        data = binary
    if buffer.get("byteLength", 0) > len(data) + 3:
        raise ModelToSpriteError("GLB_INVALID", "buffer byteLength exceeds available data")
    return data


def _accessor_values(document: dict, binary: bytes, index: int) -> array.array:
    try:
        accessor = document["accessors"][index]
        view = document["bufferViews"][accessor["bufferView"]]
        code, component_size = COMPONENT_TYPES[accessor["componentType"]]
        components = TYPE_COUNTS[accessor["type"]]
        count = accessor["count"]
    except (KeyError, IndexError, TypeError) as exc:
        raise ModelToSpriteError("GLB_INVALID", "accessor or bufferView metadata is invalid") from exc
    if count < 0:
        raise ModelToSpriteError("GLB_INVALID", "accessor count may not be negative")
    item_size = component_size * components
    stride = view.get("byteStride", item_size)
    start = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
    end = start + (count - 1) * stride + item_size if count else start
    view_end = view.get("byteOffset", 0) + view.get("byteLength", 0)
    if stride < item_size or end > view_end or view_end > len(binary):
        raise ModelToSpriteError("GLB_INVALID", "accessor exceeds its bufferView or BIN data")
    values = array.array(code)
    if stride == item_size:
        values.frombytes(binary[start:end])
    else:
        for position in range(count):
            values.extend(struct.unpack_from("<" + code * components, binary, start + position * stride))
    return values


def _finite(values) -> bool:
    return isinstance(values, list) and all(isinstance(v, (float, int)) and not isinstance(v, bool) and math.isfinite(v) for v in values)


def _primitive_metrics(document: dict, binary: bytes) -> list[dict]:
    meshes = document.get("meshes") or []
    if not meshes:
        raise ModelToSpriteError("GLB_INVALID", "GLB has no meshes")
    result = []
    for mesh_index, mesh in enumerate(meshes):
        vertices = triangles = 0
        material_ids: set[int] = set()
        has_weights = False
        for primitive in mesh.get("primitives", []):
            if primitive.get("mode", 4) != 4:
                raise ModelToSpriteError("GLB_INVALID", "only triangle-list primitives are supported for static proof renders")
            attributes = primitive.get("attributes") or {}
            position_index = attributes.get("POSITION")
            indices_index = primitive.get("indices")
            if position_index is None or indices_index is None:
                raise ModelToSpriteError("GLB_INVALID", "each primitive requires POSITION and index accessors")
            positions = _accessor_values(document, binary, position_index)
            indices = _accessor_values(document, binary, indices_index)
            position_accessor = document["accessors"][position_index]
            index_accessor = document["accessors"][indices_index]
            if position_accessor["type"] != "VEC3" or index_accessor["type"] != "SCALAR":
                raise ModelToSpriteError("GLB_INVALID", "POSITION must be VEC3 and indices must be SCALAR")
            if position_accessor["componentType"] != 5126:
                raise ModelToSpriteError("GLB_INVALID", "static GLB intake requires float POSITION data")
            if len(indices) % 3 or (indices and (min(indices) < 0 or max(indices) >= position_accessor["count"])):
                raise ModelToSpriteError("GLB_INVALID", "triangle indices are incomplete or out of range")
            if any(not math.isfinite(float(value)) for value in positions):
                raise ModelToSpriteError("GLB_INVALID", "POSITION contains non-finite coordinates")
            vertices += position_accessor["count"]
            triangles += len(indices) // 3
            if "material" in primitive:
                material_ids.add(primitive["material"])
            has_weights |= "JOINTS_0" in attributes or "WEIGHTS_0" in attributes
        result.append({"index": mesh_index, "name": mesh.get("name", f"mesh_{mesh_index}"), "vertices": vertices,
                       "triangles": triangles, "material_indices": sorted(material_ids), "skinned_attributes": has_weights})
    return result


def inspect_glb(input_path: str | pathlib.Path) -> dict:
    """Report exact content identity and geometry/material/rig metadata without importing or mutating it."""
    path = _regular_file(pathlib.Path(input_path))
    document, binary, dependencies = _read_container(path)
    required = set(document.get("extensionsRequired") or [])
    unsupported = sorted(required - SUPPORTED_REQUIRED_EXTENSIONS)
    if unsupported:
        raise ModelToSpriteError("GLB_EXTENSION_UNSUPPORTED", "unsupported required GLB extensions: " + ", ".join(unsupported))
    buffer = _buffer_data(document, binary, dependencies, path)
    geometry = _primitive_metrics(document, buffer)
    nodes = document.get("nodes") or []
    skins = document.get("skins") or []
    skin_node = any("skin" in node for node in nodes)
    weighted = any(mesh["skinned_attributes"] for mesh in geometry)
    rigged = bool(skins or skin_node or weighted)
    materials = []
    for index, material in enumerate(document.get("materials") or []):
        canonical = json.dumps(material, sort_keys=True, separators=(",", ":")).encode()
        materials.append({"index": index, "name": material.get("name", f"material_{index}"),
                          "sha256": hashlib.sha256(canonical).hexdigest(), "pbr_metallic_roughness": material.get("pbrMetallicRoughness", {})})
    joint_names: set[str] = set()
    for skin in skins:
        for joint in skin.get("joints", []):
            if isinstance(joint, int) and 0 <= joint < len(nodes):
                joint_names.add(nodes[joint].get("name", f"node_{joint}"))
    images = []
    for index, image in enumerate(document.get("images") or []):
        entry = {"index": index, "name": image.get("name", f"image_{index}"), "mime_type": image.get("mimeType")}
        if "uri" in image:
            if image["uri"].startswith("data:"):
                entry["embedded_data_uri"] = True
                entry["sha256"] = hashlib.sha256(image["uri"].encode()).hexdigest()
            else:
                dep = _external_uri(path.parent, image["uri"])
                entry["path"] = str(dep.relative_to(path.parent))
                entry["sha256"] = sha256_file(dep)
        elif "bufferView" in image:
            view = document.get("bufferViews", [])[image["bufferView"]]
            start, size = view.get("byteOffset", 0), view.get("byteLength", 0)
            payload = buffer[start:start + size]
            if len(payload) != size:
                raise ModelToSpriteError("GLB_INVALID", "image bufferView exceeds binary payload")
            entry["sha256"] = hashlib.sha256(payload).hexdigest()
        images.append(entry)
    dependency_entries = [{"path": rel, "sha256": sha256_file(dep), "bytes": dep.stat().st_size}
                          for rel, dep in sorted(dependencies.items())]
    return {
        "schema": "custodian.operator_3d_glb_inspection.v1",
        "source": {"filename": path.name, "sha256": sha256_file(path), "bytes": path.stat().st_size},
        "asset": {"version": "2.0", "generator": (document.get("asset") or {}).get("generator")},
        "geometry": geometry,
        "materials": materials,
        "images": images,
        "dependencies": dependency_entries,
        "rig": {"skinned": rigged, "skin_count": len(skins), "joint_count": len(joint_names), "joint_names": sorted(joint_names)},
        "extensions": {"used": sorted(document.get("extensionsUsed") or []), "required": sorted(required)},
    }


def validate_static_glb(input_path: str | pathlib.Path) -> dict:
    inspection = inspect_glb(input_path)
    if inspection["rig"]["skinned"]:
        raise ModelToSpriteError("STATIC_RIG_UNSUPPORTED", "static renderer refuses skinned/rigged GLB; route this input to the animation compiler at custodian.tools.operator.animation_compiler")
    return inspection
