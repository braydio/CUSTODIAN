#!/usr/bin/env python3
"""Map body face regions intersected by Task 017 shells without editing them."""

import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path

import bpy


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--blend", type=Path, required=True)
    parser.add_argument("--validation", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    opts = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    bpy.ops.wm.open_mainfile(filepath=str(opts.blend.resolve()))
    body = bpy.data.objects["output_unwrapped"]
    mesh = body.data
    validation = json.loads(opts.validation.read_text())
    edge_faces = defaultdict(list)
    for poly in mesh.polygons:
        vertices = list(poly.vertices)
        for a, b in zip(vertices, vertices[1:] + vertices[:1]):
            edge_faces[tuple(sorted((a, b)))].append(poly.index)

    result = {}
    for side in ("Left", "Right"):
        selected = set(validation["body_overlap_union_across_cycle"][side]["body_face_indices"])
        adjacency = defaultdict(set)
        for uses in edge_faces.values():
            selected_uses = [face for face in uses if face in selected]
            if len(selected_uses) > 1:
                for face in selected_uses:
                    adjacency[face].update(other for other in selected_uses if other != face)
        components, seen = [], set()
        for face in sorted(selected):
            if face in seen:
                continue
            pending, seen, component = [face], seen | {face}, []
            while pending:
                current = pending.pop()
                component.append(current)
                for neighbor in adjacency[current]:
                    if neighbor not in seen:
                        seen.add(neighbor)
                        pending.append(neighbor)
            components.append(component)
        boundary_edges = [edge for edge, uses in edge_faces.items()
                          if len([face for face in uses if face in selected]) == 1]
        vertices = sorted({vertex for face in selected for vertex in mesh.polygons[face].vertices})
        coords = [body.matrix_world @ mesh.vertices[index].co for index in vertices]
        result[side] = {
            "face_count": len(selected),
            "face_indices": sorted(selected),
            "vertex_count": len(vertices),
            "component_count": len(components),
            "largest_component_face_counts": sorted((len(c) for c in components), reverse=True)[:12],
            "boundary_edge_count": len(boundary_edges),
            "material_indices": sorted({mesh.polygons[index].material_index for index in selected}),
            "world_bounds_m": [[min(point[axis] for point in coords),
                                max(point[axis] for point in coords)] for axis in range(3)],
        }
    result = {"schema": "custodian.operator_task017_overlap_region_analysis.v1",
              "method": "union of exact body faces reported intersecting a pauldron across frames 1-22; adjacency by shared mesh edge",
              "regions": result,
              "interpretation": "The face sets identify affected source surfaces, not permission to delete them. Boundary edges do not define a safe replacement surface by themselves."}
    opts.out.parent.mkdir(parents=True, exist_ok=True)
    opts.out.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({side: {key: value for key, value in row.items()
                             if key not in ("face_indices", "world_bounds_m")}
                      for side, row in result["regions"].items()}, indent=2))


if __name__ == "__main__":
    main()
