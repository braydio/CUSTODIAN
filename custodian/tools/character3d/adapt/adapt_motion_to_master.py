"""Import adapter: combine a motion-only GLB's animation with the accepted master's skin and skeleton.

The motion GLB has the same glTF node names, order, and rest TRS as the master (verified before this
runs). Its animation channels target the same joint node indices. This adapter writes a derived GLB:
  - master JSON, master mesh/skin/nodes/materials untouched
  - the motion animation's accessor bytes copied verbatim into the master BIN chunk (buffer views rebased)
  - one animation whose channels/samplers point at the copied accessors
Animation values are never modified or re-encoded.

Usage:
  python3 -I adapt_motion_to_master.py MASTER.glb MOTION.glb OUT.glb ACTION_NAME
"""
import hashlib
import json
import struct
import sys
from pathlib import Path

MAGIC_JSON = 0x4E4F534A
MAGIC_BIN = 0x004E4942
COMP_SIZE = {5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4}
TYPE_N = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT2": 4, "MAT3": 9, "MAT4": 16}


def read_glb(path: Path):
    data = path.read_bytes()
    magic, version, length = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF" or version != 2 or length != len(data):
        raise SystemExit(f"{path}: not a valid GLB 2.0 container")
    off = 12
    j, binc = None, b""
    while off < len(data):
        clen, ctype = struct.unpack_from("<II", data, off)
        body = data[off + 8: off + 8 + clen]
        if ctype == MAGIC_JSON:
            j = json.loads(body.decode("utf-8"))
        elif ctype == MAGIC_BIN:
            binc = body
        off += 8 + clen
    if j is None:
        raise SystemExit(f"{path}: missing JSON chunk")
    return j, binc


def write_glb(path: Path, j: dict, binc: bytes):
    jb = json.dumps(j, separators=(",", ":")).encode("utf-8")
    jb += b" " * ((4 - len(jb) % 4) % 4)
    binc += b"\x00" * ((4 - len(binc) % 4) % 4)
    total = 12 + 8 + len(jb) + 8 + len(binc)
    out = struct.pack("<4sII", b"glTF", 2, total)
    out += struct.pack("<II", len(jb), MAGIC_JSON) + jb
    out += struct.pack("<II", len(binc), MAGIC_BIN) + binc
    path.write_bytes(out)


def bytes_of_accessor(j, binc, acc_idx):
    """Raw bytes of an accessor's data, strided if needed (used only for verification)."""
    acc = j["accessors"][acc_idx]
    bv = j["bufferViews"][acc["bufferView"]]
    comp = COMP_SIZE[acc["componentType"]]
    ncomp = TYPE_N[acc["type"]]
    elem = comp * ncomp
    stride = bv.get("byteStride", elem)
    base = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
    return b"".join(binc[base + i * stride: base + i * stride + elem] for i in range(acc["count"]))


def check_identical_skeleton(master, motion):
    m_nodes, s_nodes = master["nodes"], motion["nodes"]
    if len(m_nodes) != len(s_nodes):
        raise SystemExit("node count differs")
    for i, (a, b) in enumerate(zip(m_nodes, s_nodes)):
        for key in ("name", "children", "translation", "rotation", "scale", "matrix"):
            if a.get(key) != b.get(key):
                raise SystemExit(f"node {i} '{a.get('name')}' differs in '{key}'")
    joints = master["skins"][0]["joints"]
    return joints


def main():
    master_path, motion_path, out_path, action = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]), sys.argv[4]
    mj, mbin = read_glb(master_path)
    sj, sbin = read_glb(motion_path)
    joints = check_identical_skeleton(mj, sj)
    master_meshes_before = json.dumps(mj["meshes"], sort_keys=True)
    master_skins_before = json.dumps(mj["skins"], sort_keys=True)
    master_nodes_before = json.dumps(mj["nodes"], sort_keys=True)
    if not sj.get("animations"):
        raise SystemExit("motion has no animation")
    src_anim = sj["animations"][0]
    targets = {c["target"]["node"] for c in src_anim["channels"]}
    if not targets <= set(joints):
        raise SystemExit(f"channel targets {sorted(targets - set(joints))} are not skin joints")

    # Append motion accessor data verbatim to master BIN. Each referenced accessor gets its own
    # bufferView (copied slice + original stride), aligned to 4 bytes.
    new_bin = bytearray(mbin)
    new_bv_index = {}
    new_acc_index = {}
    new_accessors = mj["accessors"]
    new_views = mj["bufferViews"]
    copied = []

    def copy_accessor(src_idx):
        if src_idx in new_acc_index:
            return new_acc_index[src_idx]
        acc = dict(sj["accessors"][src_idx])
        src_bv = sj["bufferViews"][acc["bufferView"]]
        blob = sbin[src_bv.get("byteOffset", 0): src_bv.get("byteOffset", 0) + src_bv["byteLength"]]
        pad = (4 - len(new_bin) % 4) % 4
        new_bin.extend(b"\x00" * pad)
        offset = len(new_bin)
        new_bin.extend(blob)
        view = {"buffer": 0, "byteOffset": offset, "byteLength": src_bv["byteLength"]}
        if "byteStride" in src_bv:
            view["byteStride"] = src_bv["byteStride"]
        new_views.append(view)
        acc["bufferView"] = len(new_views) - 1
        new_accessors.append(acc)
        new_acc_index[src_idx] = len(new_accessors) - 1
        copied.append({"src_accessor": src_idx, "dst_accessor": new_acc_index[src_idx], "bytes": len(blob)})
        return new_acc_index[src_idx]

    new_samplers = []
    for s in src_anim["samplers"]:
        new_samplers.append({"input": copy_accessor(s["input"]), "output": copy_accessor(s["output"]),
                             "interpolation": s.get("interpolation", "LINEAR")})
    channels = [{"sampler": c["sampler"], "target": {"node": c["target"]["node"], "path": c["target"]["path"]}}
                for c in src_anim["channels"]]
    anim = {"name": action, "channels": channels, "samplers": new_samplers,
            "extras": {"derived_from_motion": {"path": str(motion_path), "sha256": hashlib.sha256(motion_path.read_bytes()).hexdigest(),
                                               "original_animation_name": src_anim.get("name")},
                       "adapter": "adapt_motion_to_master.py", "master_sha256": hashlib.sha256(master_path.read_bytes()).hexdigest()}}
    mj["animations"] = [anim]
    mj["buffers"][0]["byteLength"] = len(new_bin)
    write_glb(out_path, mj, bytes(new_bin))

    # Verification: every copied accessor reads back byte-identical to its source.
    dj, dbin = read_glb(out_path)
    for c in copied:
        if bytes_of_accessor(dj, dbin, c["dst_accessor"]) != bytes_of_accessor(sj, sbin, c["src_accessor"]):
            raise SystemExit(f"value mismatch for accessor {c['src_accessor']}")
    report = {"action": action, "master": str(master_path), "motion": str(motion_path), "output": str(out_path),
              "channels": len(channels), "targets": sorted(targets), "copied_accessors": copied,
              "meshes_skins_nodes_unchanged": (json.dumps(mj["meshes"], sort_keys=True) == master_meshes_before and json.dumps(mj["skins"], sort_keys=True) == master_skins_before and json.dumps(mj["nodes"], sort_keys=True) == master_nodes_before),
              "output_sha256": hashlib.sha256(out_path.read_bytes()).hexdigest(), "verified_values_identical": True}
    print(json.dumps(report, indent=1))


if __name__ == "__main__":
    main()
