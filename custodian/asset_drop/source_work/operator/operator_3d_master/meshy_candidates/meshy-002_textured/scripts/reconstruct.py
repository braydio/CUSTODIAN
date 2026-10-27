#!/usr/bin/env python3
"""Reconstruct the meshopt-compressed GLB container of a local Meshy v1 file.

For forensic/compatibility study on files you are authorized to process.
Does NOT decode EXT_meshopt_compression or verify the discarded auth tag.

Dependency: pip install cryptography
Usage: python reconstruct_meshy_v1_container.py input.meshy output.glb
"""
import argparse
import hashlib
import json
import struct
from pathlib import Path

from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes

MAGIC = b"MESHY.AI"
KEY = b'JSON{"accessors":[{"bufferView":'  # 32 bytes, documented upstream
ENCRYPTED_BEGIN = 32
ENCRYPTED_END = 8224       # 8192 encrypted bytes
TAG_END = 8240             # skip 16-byte tag (NOT verified)
MAX_INPUT = 256 * 1024 * 1024


def audit_glb(data: bytes) -> dict:
    if len(data) < 20 or data[:4] != b"glTF":
        raise ValueError("Recovered content does not begin with GLB magic")
    version, declared_size = struct.unpack_from("<II", data, 4)
    if version != 2 or declared_size != len(data):
        raise ValueError(f"Invalid GLB header: version={version}, declared={declared_size}, actual={len(data)}")

    offset, chunks = 12, []
    while offset < len(data):
        if offset + 8 > len(data):
            raise ValueError("Truncated GLB chunk header")
        length, kind = struct.unpack_from("<I4s", data, offset)
        start, end = offset + 8, offset + 8 + length
        if end > len(data) or length % 4:
            raise ValueError("Invalid GLB chunk length/alignment")
        chunks.append({"type": kind.decode("ascii", errors="replace"), "length": length, "offset": offset})
        offset = end
    if len(chunks) != 2 or chunks[0]["type"] != "JSON" or chunks[1]["type"] != "BIN\x00":
        raise ValueError("Expected one JSON chunk followed by one BIN chunk")

    jlen = chunks[0]["length"]
    gltf = json.loads(data[20:20 + jlen])
    if gltf.get("asset", {}).get("version") != "2.0":
        raise ValueError("Invalid glTF asset version")
    accessors = gltf.get("accessors", [])
    index_count = 0
    if gltf.get("meshes"):
        for prim in gltf["meshes"][0].get("primitives", []):
            ix = prim.get("indices")
            if ix is not None:
                index_count += accessors[ix]["count"]
    return {
        "byte_length": len(data),
        "sha256": hashlib.sha256(data).hexdigest(),
        "chunks": chunks,
        "meshes": len(gltf.get("meshes", [])),
        "materials": len(gltf.get("materials", [])),
        "extensions_required": gltf.get("extensionsRequired", []),
        "accessor_counts": [a["count"] for a in accessors],
        "triangle_count_if_all_indices_are_triangles": index_count // 3,
        "meshopt_buffer_view_count": sum(
            "EXT_meshopt_compression" in bv.get("extensions", {})
            for bv in gltf.get("bufferViews", [])
        ),
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("input", type=Path)
    ap.add_argument("output", type=Path)
    args = ap.parse_args()
    if args.input.resolve() == args.output.resolve():
        raise SystemExit("Refusing in-place overwrite")
    if args.output.exists():
        raise SystemExit(f"Refusing to overwrite existing output: {args.output}")
    blob = args.input.read_bytes()
    if len(blob) < TAG_END or len(blob) > MAX_INPUT:
        raise SystemExit("Invalid or oversized input length")
    if blob[:8] != MAGIC or struct.unpack_from("<H", blob, 8)[0] != 1:
        raise SystemExit("Expected .meshy magic and version 1")

    nonce = blob[10:22]
    counter = nonce + b"\x00\x00\x00\x02"
    decryptor = Cipher(algorithms.AES(KEY), modes.CTR(counter)).decryptor()
    prefix = decryptor.update(blob[ENCRYPTED_BEGIN:ENCRYPTED_END]) + decryptor.finalize()
    if prefix[:4] != b"glTF":
        raise SystemExit("AES-CTR reconstruction did not produce GLB magic")

    recovered = bytearray(prefix + blob[TAG_END:])
    struct.pack_into("<I", recovered, 8, len(recovered))
    report = audit_glb(bytes(recovered))
    args.output.write_bytes(recovered)
    print(json.dumps({
        "input_sha256": hashlib.sha256(blob).hexdigest(),
        "nonce_hex": nonce.hex(),
        "tag_verified": False,
        "meshopt_decompressed": False,
        **report
    }, indent=2))


if __name__ == "__main__":
    main()
