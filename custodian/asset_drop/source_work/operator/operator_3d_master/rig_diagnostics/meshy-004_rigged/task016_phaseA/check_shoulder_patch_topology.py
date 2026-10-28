#!/usr/bin/env python3
"""Read-only topology check for the existing static-study shoulder selector."""

from collections import defaultdict
import json

import bpy


SOURCE = ("custodian/asset_drop/source_work/operator/operator_3d_master/"
          "rig_diagnostics/meshy-004_rigged/shoulder_plate_study_iter001/BASELINE.blend")

bpy.ops.wm.open_mainfile(filepath=SOURCE)
armature = next(obj for obj in bpy.data.objects if obj.type == "ARMATURE")
mesh = next(obj for obj in bpy.data.objects if obj.type == "MESH" and obj.vertex_groups)
groups = {group.name: group.index for group in mesh.vertex_groups}
results = {}

for side in ("Left", "Right"):
    selected = []
    for index, polygon in enumerate(mesh.data.polygons):
        x, _y, z = polygon.center
        anatomical_side = "Left" if x >= 0 else "Right"
        group_id = groups[f"mixamorig:{anatomical_side}Shoulder"]
        mean_weight = sum(
            next((weight.weight for weight in mesh.data.vertices[vertex].groups
                  if weight.group == group_id), 0.0)
            for vertex in polygon.vertices
        ) / len(polygon.vertices)
        if (anatomical_side == side and 0.14 <= abs(x) <= 0.34
                and 1.20 <= z <= 1.48 and mean_weight > 0.20):
            selected.append(index)

    edge_faces = defaultdict(list)
    for face_index in selected:
        vertices = list(mesh.data.polygons[face_index].vertices)
        for first, second in zip(vertices, vertices[1:] + vertices[:1]):
            edge_faces[tuple(sorted((first, second)))].append(face_index)

    adjacency = defaultdict(set)
    for faces in edge_faces.values():
        if len(faces) > 1:
            for face in faces:
                adjacency[face].update(other for other in faces if other != face)

    components = []
    seen = set()
    for face in selected:
        if face in seen:
            continue
        pending, seen, count = [face], seen | {face}, 0
        while pending:
            current = pending.pop()
            count += 1
            for neighbor in adjacency[current]:
                if neighbor not in seen:
                    seen.add(neighbor)
                    pending.append(neighbor)
        components.append(count)

    uv = mesh.data.uv_layers.active.data
    uv_values = [tuple(uv[loop].uv) for face in selected
                 for loop in mesh.data.polygons[face].loop_indices]
    bone_axis = (armature.data.bones[f"mixamorig:{side}Shoulder"].tail_local
                 - armature.data.bones[f"mixamorig:{side}Shoulder"].head_local).normalized()
    normal_angles = [(mesh.matrix_world.to_3x3() @ mesh.data.polygons[index].normal)
                     .angle(bone_axis) * 180.0 / 3.14159265 for index in selected]
    results[side] = {
        "faces": len(selected),
        "largest_components": sorted(components, reverse=True)[:8],
        "boundary_edges": sum(len(faces) == 1 for faces in edge_faces.values()),
        "uv_bounds": [[round(min(value[axis] for value in uv_values), 4),
                       round(max(value[axis] for value in uv_values), 4)]
                      for axis in range(2)],
        "normal_angle_min_mean_max_deg": [
            round(min(normal_angles), 1),
            round(sum(normal_angles) / len(normal_angles), 1),
            round(max(normal_angles), 1),
        ],
    }

print(json.dumps(results, separators=(",", ":")))
