import bpy, json, math, os
from mathutils import Matrix, Vector

MANIFEST = os.environ["CRECHE_MANIFEST"]
GLB_DIR = os.environ["CRECHE_GLB_DIR"]
BLEND_IN = os.environ["CRECHE_BLEND"]
OUT_DIR = os.environ["CRECHE_OUT"]
PACKET = os.environ["CRECHE_PACKET"]
MAX_TRIS = 60000

# socket id -> GLB stem (by manifest asset_hint); None = reserved, left empty
MAP = {}
for s in ("NORTH_PIER_SKIN_01", "NORTH_PIER_SKIN_02", "NORTH_PIER_SKIN_03", "NORTH_PIER_SKIN_04",
          "SOUTH_PIER_SKIN_01", "SOUTH_PIER_SKIN_02", "SOUTH_PIER_SKIN_03", "SOUTH_PIER_SKIN_04"):
    MAP[s] = "Nameless_Creche_01_Thick_Column_01"
for s in ("WEST_PIER_SKIN_01", "WEST_PIER_SKIN_02", "WEST_PIER_SKIN_03",
          "EAST_PIER_SKIN_01", "EAST_PIER_SKIN_02", "EAST_PIER_SKIN_03"):
    MAP[s] = "Nameless_Creche_03_Column_01"
for s in ("NORTH_SLEEP_ALCOVE_01", "NORTH_SLEEP_ALCOVE_02", "NORTH_SLEEP_ALCOVE_03"):
    MAP[s] = "Nameless_Creche_09_Wall_Creche_01_Simple"
MAP["NORTH_SLEEP_ALCOVE_04"] = "Nameless_Creche_09_Wall_Creche_01_Detailed"
MAP["NORTH_TRIPLE_GOTHIC_WINDOW_KIT"] = "Nameless_Creche_02_Back_Window_Detailed"
MAP["SOUTH_DOOR_ARCH"] = "Nameless_Creche_05_Door_Archway_01"
MAP["SOUTH_DOOR_LEAF"] = "Nameless_Creche_06_Door_Body_01"
MAP["NORTH_CROWN_TRIM"] = "Nameless_Creche_08_Stone_Crown_Moulding"
MAP["SOUTH_CROWN_TRIM"] = "Nameless_Creche_08_Stone_Crown_Moulding"
for s in ("RUBBLE_W_N", "RUBBLE_W_S", "RUBBLE_E_N", "RUBBLE_E_S"):
    MAP[s] = "Nameless_Creche_02_Stone_Rubble_01"


import hashlib, re
import sys as _sys
EXPECTED = {m.group(2): m.group(1) for m in re.finditer(
    r"^- `([0-9a-f]{64})` (\S+\.glb)$", open(PACKET).read(), re.M)}


def check_glb(stem):
    name = stem + ".glb"
    path = os.path.join(GLB_DIR, name)
    if not os.path.isfile(path):
        raise SystemExit(f"MISSING_GLB {name}: fail closed, do not substitute")
    digest = hashlib.sha256(open(path, "rb").read()).hexdigest()
    if digest != EXPECTED.get(name):
        raise SystemExit(f"HASH_MISMATCH {name}: fail closed, do not substitute")
    return digest


# Verify every required GLB before any import so a bad input stops the run early.
for _stem in sorted({v for v in MAP.values() if v}):
    check_glb(_stem)

man = json.load(open(MANIFEST))
bpy.ops.wm.open_mainfile(filepath=BLEND_IN)
coll = bpy.data.collections.new("CRECHE_ASSETS")
bpy.context.scene.collection.children.link(coll)

def world_bounds(objs):
    pts = []
    for o in objs:
        if o.type == "MESH":
            pts += [o.matrix_world @ Vector(c) for c in o.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return lo, hi

records = []
for sock in man["sockets"]:
    sid = sock["id"]
    stem = MAP.get(sid)
    rec = {"socket": sid, "type": sock["type"], "center_m": sock["center_m"],
           "size_m": sock["size_m"], "source_glb": None}
    if not stem:
        rec["status"] = "EMPTY_RESERVED"
        records.append(rec)
        continue
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(GLB_DIR, stem + ".glb"))
    imported = [o for o in bpy.data.objects if o not in before]
    anchor = bpy.data.objects.new("SOCKET_" + sid, None)
    anchor.empty_display_size = 0.3
    coll.objects.link(anchor)
    for o in imported:
        if o.parent is None:
            o.parent = anchor
        if o.type == "MESH":
            tris = len(o.data.polygons)
            if tris > MAX_TRIS:
                mod = o.modifiers.new("WorkingDecimate", "DECIMATE")
                mod.ratio = MAX_TRIS / tris
                bpy.context.view_layer.objects.active = o
                bpy.ops.object.modifier_apply(modifier=mod.name)
            o.name = f"{sid}__{stem}"
    for o in imported:
        if o.name not in coll.objects:
            coll.objects.link(o)
        if o.name in bpy.context.scene.collection.objects:
            bpy.context.scene.collection.objects.unlink(o)
    bpy.context.view_layer.update()
    lo, hi = world_bounds(imported)
    native = hi - lo
    size = Vector(sock["size_m"])
    ratios = [size[i] / native[i] if native[i] > 1e-6 else 1.0 for i in range(3)]
    k = min(ratios)  # uniform: nothing exceeds the reserved box
    anchor.scale = (k, k, k)
    anchor.location = Vector(sock["center_m"])
    bpy.context.view_layer.update()
    lo, hi = world_bounds(imported)
    # center XY on socket, bottom of the piece sits on the socket's bottom face
    cx, cy = (lo.x + hi.x) / 2, (lo.y + hi.y) / 2
    anchor.location.x += sock["center_m"][0] - cx
    anchor.location.y += sock["center_m"][1] - cy
    anchor.location.z += (sock["center_m"][2] - size.z / 2) - lo.z
    bpy.context.view_layer.update()
    flo, fhi = world_bounds(imported)
    fitted = fhi - flo
    # Repeat un-stretched segments along the long axis: piers stack vertically,
    # crown trim runs along X. Copies share mesh data; spacing overlaps rather
    # than scaling the segment.
    repeat_axis = "z" if "PIER" in sid else ("x" if sock["type"] == "trim" else None)
    repeat_count = 1
    if repeat_axis:
        ai = "xyz".index(repeat_axis)
        span = size[ai]
        h = fitted[ai]
        n = math.ceil(span / h - 1e-9)
        step = (span - h) / (n - 1) if n > 1 else 0.0
        socket_min = sock["center_m"][ai] - span / 2
        base = [o for o in imported if o.type == "MESH"]
        for i in range(n):
            shift = Vector((0, 0, 0))
            shift[ai] = socket_min + i * step - flo[ai]
            for o in base:
                if i == 0:
                    o.matrix_world = Matrix.Translation(shift) @ o.matrix_world
                else:
                    c = o.copy()
                    coll.objects.link(c)
                    c.parent = anchor
                    c.matrix_parent_inverse = anchor.matrix_world.inverted()
                    c.matrix_world = Matrix.Translation(shift) @ o.matrix_world
                    c.name = f"{sid}__{stem}__seg{i}"
        repeat_count = n
        # Bounds above cover only the source objects; the copies span exactly `span`.
        fitted = Vector(fitted)
        fitted[ai] = span
    rec.update({
        "repeat_axis": repeat_axis,
        "repeat_count": repeat_count,
        "status": "PLACED_UNIFORM_FIT",
        "source_glb": stem + ".glb",
        "source_sha256": check_glb(stem),
        "translation_m": [round(v, 4) for v in anchor.location],
        "rotation_euler_deg": [0.0, 0.0, 0.0],
        "uniform_scale": round(k, 5),
        "fitted_size_m": [round(v, 3) for v in fitted],
        "reserved_size_m": sock["size_m"],
        "undersized_axes": [ax for ax, i in zip("xyz", range(3)) if fitted[i] < 0.9 * size[i]],
    })
    records.append(rec)

os.makedirs(OUT_DIR, exist_ok=True)
json.dump(records, open(os.path.join(OUT_DIR, "placement_manifest.json"), "w"), indent=2)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "creche_assembled.blend"))
print("ASSEMBLY_OK", len(records), "sockets")
