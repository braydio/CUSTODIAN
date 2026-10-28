#!/usr/bin/env python3
"""Create one symmetric, separately rigged pauldron pair for Task 017."""

import argparse
import hashlib
import json
import math
import struct
from pathlib import Path

import bpy
import bmesh
from mathutils import Vector


def cli():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--outdir", type=Path, required=True)
    return parser.parse_args(sys_argv())


def sys_argv():
    import sys
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def mesh_digest(obj):
    digest = hashlib.sha256()
    mesh = obj.data
    for vertex in mesh.vertices:
        digest.update(struct.pack("<3f", *vertex.co))
    for polygon in mesh.polygons:
        digest.update(struct.pack("<I", len(polygon.vertices)))
        digest.update(struct.pack(f"<{len(polygon.vertices)}I", *polygon.vertices))
    for vertex in mesh.vertices:
        memberships = sorted((item.group, item.weight) for item in vertex.groups)
        digest.update(struct.pack("<I", len(memberships)))
        for group, weight in memberships:
            digest.update(struct.pack("<If", group, weight))
    return digest.hexdigest()


def action_digest(armature):
    action = armature.animation_data.action
    digest = hashlib.sha256()
    digest.update(action.name.encode())
    if hasattr(action, "fcurves"):
        curves = list(action.fcurves)
    else:
        curves = []
        for layer in action.layers:
            for strip in layer.strips:
                for bag in strip.channelbags:
                    curves.extend(bag.fcurves)
    for curve in sorted(curves, key=lambda c: (c.data_path, c.array_index)):
        digest.update(curve.data_path.encode())
        digest.update(struct.pack("<I", curve.array_index))
        for point in curve.keyframe_points:
            digest.update(struct.pack("<6f", point.co.x, point.co.y,
                                      point.handle_left.x, point.handle_left.y,
                                      point.handle_right.x, point.handle_right.y))
            digest.update(point.interpolation.encode())
    return digest.hexdigest()


def nearest_uv(mesh, bvh, local_point, loop_triangles_by_poly):
    nearest = bvh.find_nearest(local_point)
    if nearest is None:
        return (0.5, 0.5)
    nearest_point, _normal, polygon_index, _distance = nearest
    uv_layer = mesh.data.uv_layers.active.data
    best = None
    for triangle in loop_triangles_by_poly.get(polygon_index, ()):
        coords = [mesh.data.vertices[index].co for index in triangle.vertices]
        point = Vector(nearest_point)
        a, b, c = coords
        v0, v1, v2 = b - a, c - a, point - a
        d00, d01, d11 = v0.dot(v0), v0.dot(v1), v1.dot(v1)
        d20, d21 = v2.dot(v0), v2.dot(v1)
        denom = d00 * d11 - d01 * d01
        if abs(denom) < 1e-12:
            continue
        v = (d11 * d20 - d01 * d21) / denom
        w = (d00 * d21 - d01 * d20) / denom
        bary = (1.0 - v - w, v, w)
        uvs = [Vector(uv_layer[index].uv) for index in triangle.loops]
        uv = sum((uvs[i] * bary[i] for i in range(3)), Vector((0.0, 0.0)))
        dist = (sum((coords[i] * bary[i] for i in range(3)), Vector()) - point).length_squared
        if best is None or dist < best[0]:
            best = dist, uv
    return tuple(best[1]) if best else (0.5, 0.5)


def make_shell(side, sign, mirror_x, center_offset, rx, ry, base_z, height,
               y_center, armature, source_mesh, bvh):
    # One radial profile is reflected across the torso plane. The lower lip
    # and inner skin are part of the same closed, independently removable mesh.
    segments = 24
    profile = ((0.000, 0.992), (0.055, 1.000), (0.120, 0.985),
               (0.260, 0.949), (0.430, 0.885), (0.600, 0.787),
               (0.760, 0.650), (0.890, 0.463), (0.970, 0.243))
    thickness = 0.004
    center_x = mirror_x + sign * center_offset
    vertices = []
    for inner in (False, True):
        inset = thickness if inner else 0.0
        for t, factor in profile:
            height_t = t * (height - inset)
            rad_factor = max(0.0, factor - inset / min(rx, ry))
            for i in range(segments):
                theta = 2.0 * math.pi * i / segments
                dx = rx * rad_factor * math.cos(theta)
                dy = ry * rad_factor * math.sin(theta)
                vertices.append((center_x + sign * dx, y_center + dy,
                                 base_z + height_t))
        vertices.append((center_x, y_center, base_z + height - inset))

    profile_count = len(profile)
    points_per_layer = profile_count * segments + 1
    faces = []
    face_uv = []

    def connect_ring(layer, row, nxt, inner=False):
        row_start = layer * points_per_layer + row * segments
        next_start = layer * points_per_layer + nxt * segments
        for i in range(segments):
            j = (i + 1) % segments
            if inner:
                faces.append((row_start + i, next_start + i,
                              next_start + j, row_start + j))
            else:
                faces.append((row_start + i, row_start + j,
                              next_start + j, next_start + i))
            face_uv.append(((i / segments, profile[row][0]),
                            ((i + 1) / segments, profile[row][0]),
                            ((i + 1) / segments, profile[nxt][0]),
                            (i / segments, profile[nxt][0])))

    for row in range(profile_count - 1):
        connect_ring(0, row, row + 1, False)
        connect_ring(1, row, row + 1, True)

    outer_apex = points_per_layer - 1
    inner_apex = 2 * points_per_layer - 1
    outer_last = (profile_count - 1) * segments
    inner_last = points_per_layer + (profile_count - 1) * segments
    for i in range(segments):
        j = (i + 1) % segments
        faces.append((outer_last + i, outer_last + j, outer_apex))
        face_uv.append(((i / segments, profile[-1][0]),
                        ((i + 1) / segments, profile[-1][0]),
                        ((i + 0.5) / segments, 1.0)))
        faces.append((inner_last + i, inner_apex, inner_last + j))
        face_uv.append(((i / segments, profile[-1][0]), (0.5, 1.0),
                        ((i + 1) / segments, profile[-1][0])))

    # Connect the outer and inner sole rings, closing the shell thickness.
    for i in range(segments):
        j = (i + 1) % segments
        faces.append((i, j, points_per_layer + j, points_per_layer + i))
        face_uv.append(((i / segments, 0.0), ((i + 1) / segments, 0.0),
                        ((i + 1) / segments, 0.02), (i / segments, 0.02)))

    # Reverse reflected faces so outward normals remain consistent.
    if sign < 0:
        faces = [tuple(reversed(face)) for face in faces]
        face_uv = [tuple(reversed(uvs)) for uvs in face_uv]

    mesh_data = bpy.data.meshes.new(f"PAULDRON_{side}_Geometry")
    mesh_data.from_pydata(vertices, [], faces)
    mesh_data.update(calc_edges=True)
    mesh_data.materials.append(source_mesh.data.materials[0])
    uv_layer = mesh_data.uv_layers.new(name="UVMap")

    # Project each new vertex to the nearest source-surface triangle, then
    # interpolate the existing baked UV. This retains local material detail.
    loop_triangles_by_poly = {}
    source_mesh.data.calc_loop_triangles()
    for triangle in source_mesh.data.loop_triangles:
        loop_triangles_by_poly.setdefault(triangle.polygon_index, []).append(triangle)
    projected_uv = [nearest_uv(source_mesh, bvh, Vector(co), loop_triangles_by_poly)
                    for co in vertices]
    for polygon, uvs in zip(mesh_data.polygons, face_uv):
        for loop_index, vertex_index, local_uv in zip(polygon.loop_indices,
                                                     polygon.vertices, uvs):
            # Keep the source atlas projection, adding the procedural UV only
            # as a deterministic fallback when source mapping is degenerate.
            uv = projected_uv[vertex_index]
            if not all(math.isfinite(value) for value in uv):
                uv = local_uv
            uv_layer.data[loop_index].uv = uv
        polygon.use_smooth = True
    bm = bmesh.new()
    bm.from_mesh(mesh_data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    if bm.calc_volume(signed=True) < 0:
        bmesh.ops.reverse_faces(bm, faces=list(bm.faces))
    bm.to_mesh(mesh_data)
    bm.free()
    mesh_data.update()

    obj = bpy.data.objects.new(f"PAULDRON_{side}_TASK017", mesh_data)
    bpy.context.scene.collection.objects.link(obj)
    obj.parent = armature
    obj.matrix_parent_inverse.identity()
    obj.matrix_basis.identity()
    group = obj.vertex_groups.new(name=f"mixamorig:{side}Shoulder")
    group.add(list(range(len(vertices))), 1.0, "REPLACE")
    modifier = obj.modifiers.new("shoulder armor rigid attachment", "ARMATURE")
    modifier.object = armature
    modifier.use_vertex_groups = True
    modifier.use_bone_envelopes = False

    return obj, {"side": side, "object": obj.name, "vertices": len(vertices),
                 "faces": len(faces), "triangles": sum(len(face) - 2 for face in faces),
                 "bone_group": group.name, "influences_per_vertex": 1,
                 "rigid_armature_modifier": modifier.name,
                 "dimensions_m": [round(2 * rx, 6), round(2 * ry, 6), round(height, 6)],
                 "thickness_m": thickness, "world_center_m": [center_x, y_center,
                                                                  base_z + height / 2]}


def main():
    opts = cli()
    opts.outdir.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.open_mainfile(filepath=str(opts.source.resolve()))
    armature = next(obj for obj in bpy.data.objects if obj.type == "ARMATURE")
    body = next(obj for obj in bpy.data.objects
                if obj.type == "MESH" and obj.vertex_groups and obj.name == "output_unwrapped")
    if armature.animation_data is None or armature.animation_data.action is None:
        raise RuntimeError("ITER005 source action is missing")
    source_action = armature.animation_data.action
    before_mesh_hash = mesh_digest(body)
    before_action_hash = action_digest(armature)
    original_armature_modifiers = [(modifier.name, modifier.object.name if modifier.object else None)
                                   for modifier in body.modifiers if modifier.type == "ARMATURE"]
    source_vertex_count = len(body.data.vertices)
    source_face_count = len(body.data.polygons)
    frame_range = (bpy.context.scene.frame_start, bpy.context.scene.frame_end,
                   bpy.context.scene.render.fps)

    shoulder_points = [(armature.matrix_world @ armature.data.bones[f"mixamorig:{side}Shoulder"].head_local,
                        side) for side in ("Left", "Right")]
    mirror_x = sum(point.x for point, _side in shoulder_points) / len(shoulder_points)
    y_center = sum(point.y for point, _side in shoulder_points) / len(shoulder_points)
    mean_head_z = sum(point.z for point, _side in shoulder_points) / 2.0
    # Geometry bounds derive from the Task 016 shoulder envelope, with 40 mm
    # added along the mean shoulder axis and 15 mm above the measured ridge.
    outward_projection = 0.295
    outer_ridge = mean_head_z + 0.166
    height = 0.145
    base_z = outer_ridge - height
    mean_head_offset = sum(abs(point.x - mirror_x) for point, _side in shoulder_points) / 2.0
    center_offset = mean_head_offset + outward_projection - 0.117
    rx, ry = 0.117, 0.145

    from mathutils.bvhtree import BVHTree
    depsgraph = bpy.context.evaluated_depsgraph_get()
    source_bvh = BVHTree.FromObject(body, depsgraph)
    shell_reports = []
    for side, sign in (("Left", 1.0), ("Right", -1.0)):
        _obj, report = make_shell(side, sign, mirror_x, center_offset,
                                  rx, ry, base_z, height, y_center,
                                  armature, body, source_bvh)
        shell_reports.append(report)

    # Evaluate source action endpoints without changing any F-curves.
    bpy.context.scene.frame_set(frame_range[0])
    bpy.context.view_layer.update()
    if mesh_digest(body) != before_mesh_hash or action_digest(armature) != before_action_hash:
        raise RuntimeError("source mesh or action changed during candidate construction")

    candidate = opts.outdir / "operator_iter005_clean_pauldrons_task017.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(candidate), check_existing=False)
    report = {
        "schema": "custodian.operator_clean_pauldrons_task017.v1",
        "source_blend": str(opts.source),
        "candidate_blend": str(candidate),
        "motion_action": source_action.name,
        "frame_start_end_fps": list(frame_range),
        "loop_unique_frames_and_endpoint": list(range(frame_range[0], frame_range[1] + 1)),
        "mirror_plane_x_m": mirror_x,
        "common_y_center_m": y_center,
        "source_mesh_sha256_before_after": [before_mesh_hash, mesh_digest(body)],
        "source_action_sha256_before_after": [before_action_hash, action_digest(armature)],
        "source_body_vertex_face_counts": [source_vertex_count, source_face_count],
        "original_body_armature_modifiers": original_armature_modifiers,
        "design_parameters": {
            "outer_projection_from_shoulder_head_m": outward_projection,
            "outer_ridge_relative_to_mean_shoulder_head_m": 0.166,
            "shell_height_m": height,
            "shell_thickness_m": 0.004,
            "half_width_outward_m": rx,
            "half_depth_fore_aft_m": ry,
            "material": body.data.materials[0].name,
            "uv_mapping": "nearest source mesh loop-triangle UV interpolation",
        },
        "shells": shell_reports,
        "original_body_geometry_preserved": True,
        "original_body_weights_preserved": True,
        "original_action_preserved": True,
    }
    (opts.outdir / "task017_geometry_build.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({"candidate": str(candidate), "shells": shell_reports,
                      "body_hash": before_mesh_hash, "action_hash": before_action_hash}, indent=2))


if __name__ == "__main__":
    main()
