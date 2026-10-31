"""Blender-side read-only source master inventory."""
from __future__ import annotations

import hashlib
import json
import pathlib
import sys

import bpy


def canonical(value) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def sha_json(value) -> str:
    return hashlib.sha256(canonical(value)).hexdigest()


def sha_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def scalar(value):
    if hasattr(value, "to_list"):
        value = value.to_list()
    if isinstance(value, (tuple, list)):
        return [scalar(item) for item in value]
    if isinstance(value, (int, float, bool, str)) or value is None:
        return value
    try:
        return [scalar(item) for item in value]
    except TypeError:
        return str(value)


def image_identity(image, blend_dir: pathlib.Path):
    if image.packed_file:
        payload = bytes(image.packed_file.data)
        return {"name": image.name, "packed": True, "sha256": sha_bytes(payload),
                "bytes": len(payload), "size": list(image.size), "format": image.file_format}
    absolute = pathlib.Path(bpy.path.abspath(image.filepath))
    if not absolute.is_file():
        raise RuntimeError("TEXTURE_DEPENDENCY_MISSING:" + image.name)
    digest = hashlib.sha256()
    size = 0
    with absolute.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            size += len(block)
            digest.update(block)
    try:
        relative = absolute.resolve().relative_to(blend_dir.resolve()).as_posix()
    except ValueError:
        relative = None
    return {"name": image.name, "packed": False, "relative_path": relative,
            "filename": absolute.name, "sha256": digest.hexdigest(), "bytes": size,
            "size": list(image.size), "format": image.file_format}


def material_identity(material, blend_dir):
    nodes = []
    compiler_nodes = []
    images = {}
    if material.use_nodes and material.node_tree:
        for node in material.node_tree.nodes:
            item = {"name": node.name, "type": node.bl_idname, "inputs": []}
            for socket in node.inputs:
                if not socket.is_linked and hasattr(socket, "default_value"):
                    try:
                        item["inputs"].append({"name": socket.name, "value": scalar(socket.default_value)})
                    except (TypeError, ValueError):
                        continue
            if node.type == "TEX_IMAGE" and node.image:
                identity = image_identity(node.image, blend_dir)
                images[node.image.name] = identity
                item["image_sha256"] = identity["sha256"]
            compiler_node = {"type": node.bl_idname, "name": node.name}
            if node.type == "TEX_IMAGE" and node.image:
                compiler_node["image_sha256"] = images[node.image.name]["sha256"]
            compiler_nodes.append(compiler_node)
            nodes.append(item)
        links = sorted({
            (link.from_node.name, link.from_socket.name, link.to_node.name, link.to_socket.name)
            for link in material.node_tree.links
        })
        graph = {"nodes": sorted(nodes, key=lambda item: (item["name"], item["type"])),
                 "links": [list(link) for link in links]}
    else:
        graph = {"nodes": [], "links": []}
    compiler_compatible = {"name": material.name, "node_graph": compiler_nodes}
    item = {"name": material.name, "diffuse_color": scalar(material.diffuse_color),
            "metallic": float(material.metallic), "roughness": float(material.roughness),
            "use_nodes": bool(material.use_nodes), "graph": graph,
            "compiler_compatible_node_graph": compiler_nodes,
            "sha256": sha_json(compiler_compatible),
            "compiler_compatible_identity_sha256": sha_json(compiler_compatible)}
    item["graph_sha256"] = sha_json(item)
    return item, images


def main():
    args = sys.argv[sys.argv.index("--") + 1:]
    if len(args) != 2:
        raise RuntimeError("USAGE_EXPECTED_BLEND_AND_OUTPUT")
    source_path = pathlib.Path(args[0]).resolve(strict=True)
    output_path = pathlib.Path(args[1])
    bpy.ops.wm.open_mainfile(filepath=str(source_path))
    sys.path.insert(0, str(source_path.parents[0]))
    repo_root = pathlib.Path(__file__).resolve().parents[4]
    compiler = repo_root / "custodian/tools/operator/animation_compiler"
    sys.path.insert(0, str(compiler))
    from blender_neutral_idle_proof import armature_signature

    armatures = []
    for armature in sorted((obj for obj in bpy.data.objects if obj.type == "ARMATURE"), key=lambda obj: obj.name):
        signature = armature_signature(armature)
        rest = [{"name": bone.name,
                 "matrix": [[round(float(value), 8) for value in row] for row in bone.matrix_local]}
                for bone in armature.data.bones]
        identity = {"object_name": armature.name, "data_name": armature.data.name,
                    "library": armature.library.filepath if armature.library else None}
        armatures.append({"object_name": armature.name, "data_name": armature.data.name,
                          "bone_count": len(armature.data.bones), "identity": identity,
                          "identity_sha256": sha_json(identity), "rest_pose": rest,
                          "rest_pose_sha256": sha_json(rest), "skeleton": signature,
                          "skeleton_signature_sha256": signature["signature_sha256"]})

    meshes = []
    materials = {}
    textures = {}
    blend_dir = source_path.parent
    for obj in sorted((item for item in bpy.data.objects if item.type == "MESH"), key=lambda item: item.name):
        mesh = obj.data
        vertices = [[round(float(value), 8) for value in vertex.co] for vertex in mesh.vertices]
        polygons = [list(poly.vertices) for poly in mesh.polygons]
        groups = [group.name for group in obj.vertex_groups]
        weights = [
            {"vertex": vertex.index,
             "groups": sorted([[assignment.group, round(float(assignment.weight), 8)]
                               for assignment in vertex.groups])}
            for vertex in mesh.vertices
        ]
        mesh_identity = {"object_name": obj.name, "mesh_data_name": mesh.name,
                         "vertices": vertices, "polygons": polygons, "groups": groups}
        compiler_mesh_identity = {"name": mesh.name, "vertices": vertices,
                                  "polygons": polygons, "groups": groups}
        weights_identity = {"vertex_count": len(mesh.vertices), "groups": groups, "weights": weights}
        material_ids = []
        for material in mesh.materials:
            if material is None:
                continue
            if material.name not in materials:
                identity, image_records = material_identity(material, blend_dir)
                materials[material.name] = identity
                textures.update(image_records)
            material_ids.append({"name": material.name, "sha256": materials[material.name]["sha256"]})
        meshes.append({"object_name": obj.name, "mesh_data_name": mesh.name,
                       "vertex_count": len(vertices), "triangle_count": sum(max(0, len(poly) - 2) for poly in polygons),
                       "vertex_group_names": groups, "parent_armature": obj.parent.name if obj.parent and obj.parent.type == "ARMATURE" else None,
                       "mesh_identity_sha256": sha_json(mesh_identity),
                       "compiler_compatible_mesh_sha256": sha_json(compiler_mesh_identity),
                       "weights_sha256": sha_json(weights_identity),
                       "materials": material_ids})
    report = {
        "schema": "custodian.operator_3d_blend_inspection.v1",
        "source": {"filename": source_path.name, "bytes": source_path.stat().st_size},
        "blender_version": bpy.app.version_string,
        "armatures": armatures,
        "meshes": meshes,
        "materials": sorted(materials.values(), key=lambda item: item["name"]),
        "compiler_compatible_materials_sha256": sha_json([
            {"name": item["name"], "node_graph": item["compiler_compatible_node_graph"]}
            for item in sorted(materials.values(), key=lambda value: value["name"])
        ]),
        "textures": sorted(textures.values(), key=lambda item: item["name"]),
        "scene": {"fps": bpy.context.scene.render.fps,
                  "objects": len(bpy.data.objects), "actions": sorted(action.name for action in bpy.data.actions)},
    }
    output_path.write_bytes(canonical(report) + b"\n")
    print("MODEL_TO_SPRITE_BLEND_INSPECTION_JSON:" + canonical(report).decode("utf-8"), flush=True)


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print("MODEL_TO_SPRITE_BLEND_ERROR:" + (str(exc) or type(exc).__name__), flush=True)
        raise
