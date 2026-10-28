#!/usr/bin/env python3
"""Read-only geometric diagnosis and focused renders for the Task 016 start state."""

import json
import math
import sys
from collections import defaultdict
from pathlib import Path

import bpy
import numpy as np
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from PIL import Image, ImageDraw


def rest_pose():
    arm = next(obj for obj in bpy.data.objects if obj.type == "ARMATURE")
    mesh = next(obj for obj in bpy.data.objects if obj.type == "MESH" and obj.vertex_groups)
    if arm.animation_data:
        arm.animation_data.action = None
    for pose_bone in arm.pose.bones:
        pose_bone.matrix_basis = pose_bone.matrix_basis.__class__()
    bpy.context.scene.frame_set(1)
    bpy.context.view_layer.update()
    return arm, mesh


def selected_faces(mesh):
    groups = {group.name: group.index for group in mesh.vertex_groups}
    sides = {"Left": [], "Right": []}
    for index, poly in enumerate(mesh.data.polygons):
        x, _y, z = poly.center
        side = "Left" if x >= 0 else "Right"
        group = groups[f"mixamorig:{side}Shoulder"]
        weight = sum(next((w.weight for w in mesh.data.vertices[v].groups
                           if w.group == group), 0.0) for v in poly.vertices) / len(poly.vertices)
        if 0.14 <= abs(x) <= 0.34 and 1.20 <= z <= 1.48 and weight > 0.20:
            sides[side].append(index)
    return sides


def frame_for_side(armature, side):
    bone = armature.data.bones[f"mixamorig:{side}Shoulder"]
    head = armature.matrix_world @ bone.head_local
    tail = armature.matrix_world @ bone.tail_local
    outward = (tail - head).normalized()
    up = Vector((0, 0, 1))
    forward = Vector((0, -1, 0))
    return head, outward, forward, up


def bounds_in_frame(points, frame):
    head, outward, forward, up = frame
    rows = np.asarray([[float((point - head).dot(axis)) for axis in (outward, forward, up)]
                       for point in points], dtype=np.float64)
    return {"axes": ["outward_from_joint", "forward", "up"],
            "minimum_m": rows.min(0).round(6).tolist(),
            "maximum_m": rows.max(0).round(6).tolist(),
            "size_mm": ((rows.max(0) - rows.min(0)) * 1000).round(2).tolist(),
            "outwardmost_from_joint_mm": round(float(rows[:, 0].max() * 1000), 2),
            "highest_point_from_joint_mm": round(float(rows[:, 2].max() * 1000), 2)}


def patch_records(mesh, sides):
    vertex_ids = {side: sorted({v for face in faces for v in mesh.data.polygons[face].vertices})
                  for side, faces in sides.items()}
    points = {side: [mesh.matrix_world @ mesh.data.vertices[index].co for index in ids]
              for side, ids in vertex_ids.items()}
    return vertex_ids, points


def symmetric_nn(a, b):
    a = np.asarray(a, dtype=np.float64)
    b = np.asarray(b, dtype=np.float64)
    d = np.sqrt(((a[:, None, :] - b[None, :, :]) ** 2).sum(axis=2))
    x, y = d.min(axis=1), d.min(axis=0)
    both = np.concatenate((x, y)) * 1000
    return {"mean_mm": round(float(both.mean()), 2),
            "median_mm": round(float(np.median(both)), 2),
            "p95_mm": round(float(np.percentile(both, 95)), 2),
            "max_mm": round(float(both.max()), 2)}


def groups_summary(mesh, vertex_ids, side):
    names = {group.index: group.name for group in mesh.vertex_groups}
    groups = defaultdict(list)
    for index in vertex_ids:
        for item in mesh.data.vertices[index].groups:
            groups[names[item.group]].append(item.weight)
    key_bones = [f"mixamorig:{side}Shoulder", f"mixamorig:{side}Arm",
                 f"mixamorig:Spine2", f"mixamorig:Spine1", "mixamorig:Hips"]
    return {name: {"mean": round(float(np.mean(groups.get(name, [0]))), 4),
                   "max": round(float(max(groups.get(name, [0]))), 4),
                   "nonzero_vertex_count": len(groups.get(name, []))}
            for name in key_bones}


def mesh_points(obj):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = obj.evaluated_get(depsgraph)
    data = evaluated.to_mesh()
    points = [obj.matrix_world @ vertex.co for vertex in data.vertices]
    polys = [tuple(poly.vertices) for poly in data.polygons]
    evaluated.to_mesh_clear()
    return points, polys


def mean_normal(mesh, face_ids):
    normals = [mesh.matrix_world.to_3x3() @ mesh.data.polygons[index].normal for index in face_ids]
    avg = sum(normals, Vector())
    if avg.length:
        avg.normalize()
    return avg


def project_crop_center(scene, camera, world_point, resolution):
    uv = world_to_camera_view(scene, camera, world_point)
    return int(round(uv.x * resolution)), int(round((1 - uv.y) * resolution))


def render_diagnostics(mesh, arm, selected, overlay, intersection_pairs, outdir):
    scene = bpy.context.scene
    base_faces = sorted(index for faces in selected.values() for index in faces)
    # Temporary diagnostic materials are applied only to this in-memory inspection.
    colors = {"base_patch": (0.05, 0.8, 1.0, 1), "overlay": (1.0, 0.0, 0.72, 1),
              "intersection": (1.0, 0.05, 0.02, 1)}
    mats = {}
    for name, rgba in colors.items():
        mat = bpy.data.materials.new(f"TEMP_DIAG_{name}")
        mat.diffuse_color = rgba
        mat.use_nodes = True
        shader = mat.node_tree.nodes.get("Principled BSDF")
        shader.inputs["Base Color"].default_value = rgba
        shader.inputs["Emission Color"].default_value = rgba
        shader.inputs["Emission Strength"].default_value = 0.35
        mats[name] = mat
    base_mat_index = len(mesh.data.materials)
    mesh.data.materials.append(mats["base_patch"])
    for index in base_faces:
        mesh.data.polygons[index].material_index = base_mat_index

    overlay_mat_index = None
    if overlay:
        overlay_mat_index = len(overlay.data.materials)
        overlay.data.materials.append(mats["overlay"])
        for poly in overlay.data.polygons:
            poly.material_index = overlay_mat_index
        red_index = len(overlay.data.materials)
        overlay.data.materials.append(mats["intersection"])
        for overlay_index in intersection_pairs:
            if 0 <= overlay_index < len(overlay.data.polygons):
                overlay.data.polygons[overlay_index].material_index = red_index

    lo = [min((mesh.matrix_world @ v.co)[i] for v in mesh.data.vertices) for i in range(3)]
    hi = [max((mesh.matrix_world @ v.co)[i] for v in mesh.data.vertices) for i in range(3)]
    scale = 1.23547
    root = bpy.data.objects.new("TEMP_DIAG_ROOT", None)
    scene.collection.objects.link(root)
    for obj in (mesh, arm, overlay):
        if obj:
            obj.parent = root
    root.scale = (scale,) * 3
    root.location = (-(lo[0] + hi[0]) / 2 * scale, -(lo[1] + hi[1]) / 2 * scale,
                     -lo[2] * scale)
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = scene.render.resolution_y = 512
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.render.filter_size = 1.5
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "Medium High Contrast"
    world = bpy.data.worlds.new("TEMP_DIAG_WORLD")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.1, 0.11, 0.13, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.8
    scene.world = world
    light = bpy.data.objects.new("TEMP_DIAG_SUN", bpy.data.lights.new("TEMP_DIAG_SUN", "SUN"))
    light.data.energy = 3.0
    scene.collection.objects.link(light)
    camera = bpy.data.objects.new("TEMP_DIAG_CAMERA", bpy.data.cameras.new("TEMP_DIAG_CAMERA"))
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 128 / 50
    camera.data.shift_y = (106 - 64) / 128
    scene.collection.objects.link(camera)
    scene.camera = camera
    azimuths = {"S": 0, "N": 180, "SE": -45, "SW": 45}
    labels = []
    for direction, degrees in azimuths.items():
        az = math.radians(degrees)
        el = math.radians(45)
        camera.location = (10 * math.sin(az) * math.cos(el),
                           -10 * math.cos(az) * math.cos(el), 10 * math.sin(el))
        camera.rotation_euler = (Vector() - camera.location).to_track_quat("-Z", "Y").to_euler()
        light.rotation_euler = (math.radians(50), 0, az - math.radians(35))
        scene.render.filepath = str(outdir / f"diagnostic_{direction}.png")
        bpy.ops.render.render(write_still=True)
        rendered = Image.open(scene.render.filepath).convert("RGB")
        for side in ("Left", "Right"):
            head, *_ = frame_for_side(arm, side)
            center_x, center_y = project_crop_center(scene, camera, head, 512)
            left = max(0, min(512 - 224, center_x - 112))
            top = max(0, min(512 - 224, center_y - 112))
            crop = rendered.crop((left, top, left + 224, top + 224))
            anatomical_label = f"ANATOMICAL {side.upper()} · camera {direction}"
            if direction == "S":
                anatomical_label += " · image-left" if side == "Right" else " · image-right"
            labels.append((crop, anatomical_label, direction, side))
    tile_w, tile_h = 224, 246
    sheet = Image.new("RGB", (tile_w * 4, tile_h * 2), (20, 22, 26))
    draw = ImageDraw.Draw(sheet)
    for i, (crop, label, direction, side) in enumerate(labels):
        x, y = (i % 4) * tile_w, (i // 4) * tile_h
        sheet.paste(crop, (x, y + 22))
        draw.text((x + 3, y + 4), label, fill="white")
    sheet.save(outdir / "phaseA_shoulder_patch_intersections.png", optimize=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    baseline_path, variant_path, outdir = Path(argv[0]), Path(argv[1]), Path(argv[2])
    outdir.mkdir(parents=True, exist_ok=True)
    report = {"schema": "custodian.operator_shoulder_asymmetry_diagnosis.v1",
              "source_baseline": str(baseline_path), "variant_a": str(variant_path),
              "screen_side_mapping": "camera S projects world x<torso mirror plane to image-left; this is anatomical RightShoulder",
              "torso_mirror_plane_x_m": None, "baseline": {"sides": {}}, "variant_a": {"sides": {}}}

    bpy.ops.wm.open_mainfile(filepath=str(baseline_path.resolve()))
    arm, mesh = rest_pose()
    selected = selected_faces(mesh)
    vertex_ids, points = patch_records(mesh, selected)
    plane = (arm.data.bones["mixamorig:LeftShoulder"].head_local.x +
             arm.data.bones["mixamorig:RightShoulder"].head_local.x) / 2
    report["torso_mirror_plane_x_m"] = float(plane)
    for side in ("Left", "Right"):
        frame = frame_for_side(arm, side)
        normal = mean_normal(mesh, selected[side])
        outward_angle = math.degrees(normal.angle(frame[1])) if normal.length else None
        report["baseline"]["sides"][side] = {
            "selected_face_count": len(selected[side]),
            "selected_vertex_count": len(vertex_ids[side]),
            "shoulder_local_bounds": bounds_in_frame(points[side], frame),
            "mean_surface_normal_vs_outward_axis_deg": round(outward_angle, 2) if outward_angle is not None else None,
            "mean_skin_weights": groups_summary(mesh, vertex_ids[side], side)}
    mirrored_left = [[2 * plane - p.x, p.y, p.z] for p in points["Left"]]
    right_points = [[p.x, p.y, p.z] for p in points["Right"]]
    report["baseline"]["mirrored_surface_deviation"] = symmetric_nn(mirrored_left, right_points)

    bpy.ops.wm.open_mainfile(filepath=str(variant_path.resolve()))
    arm_a, mesh_a = rest_pose()
    selected_a = selected_faces(mesh_a)
    vertex_ids_a, points_a = patch_records(mesh_a, selected_a)
    overlay = next(obj for obj in bpy.data.objects if obj.name.startswith("SHOULDER_PLATE_OVERLAY_VARIANT_A"))
    overlay_points, overlay_polys = mesh_points(overlay)
    overlay_sides = {"Left": [], "Right": []}
    for point in overlay_points:
        overlay_sides["Left" if point.x >= 0 else "Right"].append(point)
    for side in ("Left", "Right"):
        report["variant_a"]["sides"][side] = {
            "underlying_source_faces_retained": len(selected_a[side]),
            "overlay_vertex_count_in_side_bbox": len(overlay_sides[side]),
            "overlay_bounds_in_shoulder_local_frame": bounds_in_frame(overlay_sides[side], frame_for_side(arm_a, side)),
            "base_skin_weight_summary": groups_summary(mesh_a, vertex_ids_a[side], side),
            "overlay_has_armature_modifier": any(mod.type == "ARMATURE" for mod in overlay.modifiers),
            "overlay_vertex_groups": [group.name for group in overlay.vertex_groups]}
    mirrored_overlay_left = [[2 * plane - p.x, p.y, p.z] for p in overlay_sides["Left"]]
    overlay_right = [[p.x, p.y, p.z] for p in overlay_sides["Right"]]
    report["variant_a"]["mirrored_overlay_deviation"] = symmetric_nn(mirrored_overlay_left, overlay_right)

    base_polys = [tuple(poly.vertices) for poly in mesh_a.data.polygons]
    selected_ids = {i for faces in selected_a.values() for i in faces}
    nonplate = [face for i, face in enumerate(base_polys) if i not in selected_ids]
    base_vertices = [mesh_a.matrix_world @ vertex.co for vertex in mesh_a.data.vertices]
    base_bvh = BVHTree.FromPolygons(base_vertices, nonplate, all_triangles=False)
    overlay_bvh = BVHTree.FromPolygons(overlay_points, overlay_polys, all_triangles=False)
    pairs = base_bvh.overlap(overlay_bvh)
    report["variant_a"]["intersections"] = {
        "triangle_pair_count_with_nonplate_base": len(pairs),
        "distinct_overlay_faces": len({p[1] for p in pairs}),
        "intentionality": "undetermined pending construction review",
        "intersection_face_ids": sorted({p[1] for p in pairs})}
    intersection_ids = {p[1] for p in pairs}
    render_diagnostics(mesh_a, arm_a, selected_a, overlay, intersection_ids, outdir)
    (outdir / "phaseA_shoulder_asymmetry.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
