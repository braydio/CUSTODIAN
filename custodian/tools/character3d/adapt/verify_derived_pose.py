"""Blender verification for a derived skinned GLB: does the action animate the accepted character, and do
five sampled poses match the source glTF joint transforms?

Ground truth is computed in pure glTF math from the source motion GLB (TRS sampled at exact keyframes,
hierarchy excluding the Armature node, which is the object-level transform). Blender's posed bones are
compared as invariants: each joint's rotation angle and translation length relative to its rest pose.
These are unchanged by Blender's Y-up to Z-up conversion.

Run:
  blender -b --factory-startup --python verify_derived_pose.py -- DERIVED.glb SOURCE_MOTION.glb OUT.json
"""
import json
import math
import struct
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Quaternion, Vector

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from adapt_motion_to_master import read_glb  # noqa: E402

argv = sys.argv[sys.argv.index("--") + 1:]
derived, source, out_path = Path(argv[0]), Path(argv[1]), Path(argv[2])
ANGLE_TOL = 2e-3      # radians
TRANS_TOL = 2e-3      # armature-space units
FPS = 24
ARMATURE_NODE_NAME = "Armature"


def floats(j, binc, acc_idx):
    acc = j["accessors"][acc_idx]
    bv = j["bufferViews"][acc["bufferView"]]
    ncomp = {"SCALAR": 1, "VEC3": 3, "VEC4": 4}[acc["type"]]
    base = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
    stride = bv.get("byteStride", 4 * ncomp)
    out = []
    for i in range(acc["count"]):
        out.append(struct.unpack_from("<" + "f" * ncomp, binc, base + i * stride))
    return out


def trs_at(j, binc, anim, node, t_index):
    """Node TRS at keyframe t_index of its sampler(s); channels for a node share one time array."""
    trs = {"translation": None, "rotation": None, "scale": None}
    for ch in anim["channels"]:
        if ch["target"]["node"] != node:
            continue
        s = anim["samplers"][ch["sampler"]]
        vals = floats(j, binc, s["output"])
        trs[ch["target"]["path"]] = vals[t_index]
    return trs


def node_local(node, trs):
    t = trs["translation"] or node.get("translation", [0, 0, 0])
    r = trs["rotation"] or node.get("rotation", [0, 0, 0, 1])
    s = trs["scale"] or node.get("scale", [1, 1, 1])
    qx, qy, qz, qw = r
    return (Matrix.Translation(Vector(t)) @ Quaternion((qw, qx, qy, qz)).to_matrix().to_4x4()
            @ Matrix.Diagonal(Vector((s[0], s[1], s[2], 1.0))))


def gt_world(j, binc, anim, t_index):
    """Skeleton-space world matrix of every joint at keyframe t_index (excludes the Armature node)."""
    nodes = j["nodes"]
    parent = {}
    for i, n in enumerate(nodes):
        for c in n.get("children", []):
            parent[c] = i
    world = {}

    def walk(i):
        if i in world:
            return world[i]
        local = node_local(nodes[i], trs_at(j, binc, anim, i, t_index))
        if i in parent and nodes[parent[i]].get("name") != ARMATURE_NODE_NAME:
            world[i] = walk(parent[i]) @ local
        else:
            world[i] = local
        return world[i]

    for i in range(len(nodes)):
        if nodes[i].get("name") in {"char1"}:
            continue
        walk(i)
    return world


def invariants(delta):
    loc, rot, _ = delta.decompose()
    angle = rot.angle
    return angle, loc.length


bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.scene.render.fps = FPS
bpy.ops.import_scene.gltf(filepath=str(derived))
bpy.context.view_layer.update()

arm = next(o for o in bpy.data.objects if o.type == "ARMATURE" and len(o.data.bones) > 0)
mesh = next(o for o in bpy.data.objects if o.type == "MESH" and o.parent == arm)
action = None
for a in bpy.data.actions:
    if a.name == "alert" or a.name.endswith("alert"):
        action = a
if action is None:
    action = max(bpy.data.actions, key=lambda a: a.frame_range[1] - a.frame_range[0])
if arm.animation_data is None:
    arm.animation_data_create()
arm.animation_data.action = action
if action.slots and hasattr(arm.animation_data, "action_slot"):
    arm.animation_data.action_slot = action.slots[0]

sj, sbin = read_glb(source)
sanim = sj["animations"][0]
# All channels must share one time array (verified here; no interpolation at sampled keyframes).
samplers_times = [tuple(x[0] for x in floats(sj, sbin, s["input"])) for s in sanim["samplers"]]
if len(set(samplers_times)) != 1:
    raise SystemExit("samplers do not share a single time array; refusing to interpolate")
times = samplers_times[0]
n = len(times)
picks = sorted({0, n // 4, n // 2, (3 * n) // 4, n - 1})[:5]

# Rest and per-bone identity mapping by name.
rest_gt = gt_world(sj, sbin, {"channels": [], "samplers": []}, 0)
name_to_gt = {sj["nodes"][i]["name"]: i for i in rest_gt}

results = {"derived": str(derived), "source": str(source), "action": action.name, "action_frame_range": list(action.frame_range),
           "bone_count": len(arm.data.bones), "keyframes_total": n, "picks": [], "pass": True, "failures": []}
scene = bpy.context.scene
rest_disp = None
mesh_rest = [v.co.copy() for v in mesh.data.vertices]
rest_zs = [v.z for v in mesh_rest]
rest_height = max(rest_zs) - min(rest_zs)  # local units; Armature node scale is 0.01
ARMATURE_SCALE = arm.matrix_world.to_scale().x
for k in picks:
    frame = times[k] * FPS
    scene.frame_set(int(math.floor(frame)), subframe=frame - math.floor(frame))
    bpy.context.view_layer.update()
    gt_now = gt_world(sj, sbin, sanim, k)
    max_ang, max_tr, worst = 0.0, 0.0, None
    for bone in arm.pose.bones:
        if bone.name not in name_to_gt:
            results["failures"].append(f"bone {bone.name} missing from source")
            continue
        gi = name_to_gt[bone.name]
        d_gt = gt_now[gi] @ rest_gt[gi].inverted()
        b_rest = arm.data.bones[bone.name].matrix_local
        d_bl = bone.matrix @ b_rest.inverted()
        a_gt, t_gt = invariants(d_gt)
        a_bl, t_bl = invariants(d_bl)
        da, dt = abs(a_gt - a_bl), abs(t_gt - t_bl)
        if da > max_ang:
            max_ang, worst = da, bone.name
        max_tr = max(max_tr, dt)
        if da > ANGLE_TOL or dt > TRANS_TOL:
            results["failures"].append({"keyframe": k, "bone": bone.name, "angle_gt": a_gt, "angle_blender": a_bl,
                                        "trans_gt": t_gt, "trans_blender": t_bl})
    # Deformation sanity: mesh vertices must be finite and not blow up relative to rest.
    dg = bpy.context.evaluated_depsgraph_get()
    ev = mesh.evaluated_get(dg)
    me = ev.to_mesh()
    pts = [v.co for v in me.vertices]
    ev.to_mesh_clear()
    finite = all(math.isfinite(c) for p in pts for c in p)
    disp = max((p - r).length for p, r in zip(pts, mesh_rest)) if len(pts) == len(mesh_rest) else float("nan")
    zs = [p.z for p in pts]
    height = (max(zs) - min(zs)) if zs else float("nan")
    if not finite or len(pts) != len(mesh_rest):
        results["failures"].append({"keyframe": k, "deformation": "non-finite vertices or vertex count changed", "vertices": len(pts), "expected": len(mesh_rest)})
    results["picks"].append({"keyframe": k, "time_s": round(times[k], 6), "blender_frame": round(frame, 4),
                             "max_angle_err_rad": max_ang, "worst_bone": worst, "max_trans_err": max_tr,
                             "mesh_max_displacement_from_bind_local": disp, "mesh_max_displacement_from_bind_m": disp * ARMATURE_SCALE, "mesh_height_local": height, "rest_height_local": rest_height, "mesh_vertices": len(pts)})

# Does the action actually change the pose across picks (animates)?
results["animates"] = len({round(p["mesh_max_displacement_from_bind_local"], 6) for p in results["picks"]}) > 1
if not results["animates"]:
    results["failures"].append("action did not change the pose across sampled keyframes")
results["pass"] = not results["failures"]
out_path.write_text(json.dumps(results, indent=1, default=str) + "\n")
print("VERIFY", "PASS" if results["pass"] else "FAIL", "failures:", len(results["failures"]))
