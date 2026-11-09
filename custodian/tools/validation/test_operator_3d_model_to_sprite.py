"""Focused tests for the experimental static Operator model-to-sprite tool.

The generated GLB fixtures are synthetic test geometry, never animation proof.
"""
from __future__ import annotations

import hashlib
import json
import shutil
import struct
import subprocess
import tempfile
import unittest
from pathlib import Path

from custodian.tools.operator.model_to_sprite.glb import (
    ModelToSpriteError,
    inspect_glb,
    validate_static_glb,
)
from custodian.tools.operator.model_to_sprite.blend_inspection import inspect_blend
from custodian.tools.operator.model_to_sprite.pipeline import (
    _tool_sources,
    render_static,
    verify_candidate,
)


def make_glb(path: Path, *, rigged: bool = False) -> None:
    """Write a valid, self-contained cube GLB with optional synthetic skin metadata."""
    positions = [
        (-0.5, -0.5, 0.0), (0.5, -0.5, 0.0), (0.5, 0.5, 0.0), (-0.5, 0.5, 0.0),
        (-0.5, -0.5, 1.0), (0.5, -0.5, 1.0), (0.5, 0.5, 1.0), (-0.5, 0.5, 1.0),
    ]
    triangles = [
        0, 2, 1, 0, 3, 2, 4, 5, 6, 4, 6, 7,
        0, 1, 5, 0, 5, 4, 1, 2, 6, 1, 6, 5,
        2, 3, 7, 2, 7, 6, 3, 0, 4, 3, 4, 7,
    ]
    position_bytes = b"".join(struct.pack("<3f", *p) for p in positions)
    index_offset = len(position_bytes)
    index_bytes = b"".join(struct.pack("<H", i) for i in triangles)
    binary = position_bytes + index_bytes
    while len(binary) % 4:
        binary += b"\0"
    nodes = [{"name": "Cube", "mesh": 0}]
    primitive_attributes = {"POSITION": 0}
    if rigged:
        nodes[0]["skin"] = 0
        nodes.append({"name": "RootBone"})
        primitive_attributes["JOINTS_0"] = 2
        primitive_attributes["WEIGHTS_0"] = 3
        joints = bytes(8 * 4)
        weights = b"".join(struct.pack("<4f", 1.0, 0.0, 0.0, 0.0) for _ in positions)
        joint_offset = len(binary)
        binary += joints
        weight_offset = len(binary)
        binary += weights
        binary_byte_length = len(binary)
        while len(binary) % 4:
            binary += b"\0"
    document = {
        "asset": {"version": "2.0", "generator": "synthetic-test-fixture"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": nodes,
        "meshes": [{"name": "TestCube", "primitives": [{"attributes": primitive_attributes,
            "indices": 1, "material": 0}]}],
        "materials": [{"name": "TestGraphite", "pbrMetallicRoughness": {
            "baseColorFactor": [0.2, 0.2, 0.2, 1.0]}}],
        "buffers": [{"byteLength": len(position_bytes) + len(index_bytes)}],
        "bufferViews": [
            {"buffer": 0, "byteOffset": 0, "byteLength": len(position_bytes), "target": 34962},
            {"buffer": 0, "byteOffset": index_offset, "byteLength": len(index_bytes), "target": 34963},
        ],
        "accessors": [
            {"bufferView": 0, "componentType": 5126, "count": len(positions), "type": "VEC3",
             "min": [-0.5, -0.5, 0.0], "max": [0.5, 0.5, 1.0]},
            {"bufferView": 1, "componentType": 5123, "count": len(triangles), "type": "SCALAR"},
        ],
    }
    if rigged:
        document["skins"] = [{"joints": [1], "skeleton": 1}]
        document["nodes"][1]["children"] = []
        document["buffers"][0]["byteLength"] = binary_byte_length
        document["bufferViews"] += [
            {"buffer": 0, "byteOffset": joint_offset, "byteLength": len(joints)},
            {"buffer": 0, "byteOffset": weight_offset, "byteLength": len(weights)},
        ]
        document["accessors"] += [
            {"bufferView": 2, "componentType": 5121, "count": len(positions), "type": "VEC4"},
            {"bufferView": 3, "componentType": 5126, "count": len(positions), "type": "VEC4"},
        ]
    json_bytes = json.dumps(document, separators=(",", ":")).encode()
    json_bytes += b" " * ((-len(json_bytes)) % 4)
    binary += b"\0" * ((-len(binary)) % 4)
    total_length = 12 + 8 + len(json_bytes) + 8 + len(binary)
    glb = b"glTF" + struct.pack("<II", 2, total_length)
    glb += struct.pack("<II", len(json_bytes), 0x4E4F534A) + json_bytes
    glb += struct.pack("<II", len(binary), 0x004E4942) + binary
    path.write_bytes(glb)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class OperatorModelToSpriteTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="op3d-model-to-sprite-test-")
        self.root = Path(self.temp.name)
        self.static_glb = self.root / "static-cube.glb"
        self.rigged_glb = self.root / "rigged-cube.glb"
        make_glb(self.static_glb)
        make_glb(self.rigged_glb, rigged=True)

    def tearDown(self) -> None:
        self.temp.cleanup()

    def test_inspect_reports_geometry_material_and_skin_without_rejecting_inspection(self) -> None:
        result = inspect_glb(self.rigged_glb)
        self.assertEqual(result["geometry"][0]["name"], "TestCube")
        self.assertEqual(result["geometry"][0]["triangles"], 12)
        self.assertEqual(result["materials"][0]["name"], "TestGraphite")
        self.assertTrue(result["rig"]["skinned"])
        self.assertEqual(result["rig"]["joint_count"], 1)

    def test_static_validation_routes_rigged_models_to_animation_compiler(self) -> None:
        with self.assertRaises(ModelToSpriteError) as raised:
            validate_static_glb(self.rigged_glb)
        self.assertEqual(raised.exception.code, "STATIC_RIG_UNSUPPORTED")
        self.assertIn("animation compiler", str(raised.exception).lower())

    def test_lfs_pointer_is_not_treated_as_a_model(self) -> None:
        pointer = self.root / "pointer.glb"
        pointer.write_text("version https://git-lfs.github.com/spec/v1\n")
        with self.assertRaises(ModelToSpriteError) as raised:
            inspect_glb(pointer)
        self.assertEqual(raised.exception.code, "INPUT_LFS_POINTER")

    def test_tool_receipt_paths_are_repository_relative_not_worktree_relative(self) -> None:
        paths = [item["path"] for item in _tool_sources()]
        self.assertTrue(paths)
        self.assertTrue(all(path.startswith("custodian/tools/operator/model_to_sprite/") for path in paths))
        self.assertTrue(all(".custodian-worktrees" not in path for path in paths))

    def test_blend_inspection_reports_rig_mesh_material_and_input_identity(self) -> None:
        blender = shutil.which("blender")
        if not blender:
            self.skipTest("Blender is required for the .blend inspection integration test")
        fixture = self.root / "inspection-fixture.blend"
        script = self.root / "make_blend_fixture.py"
        script.write_text(
            "import bpy\n"
            "bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)\n"
            "bpy.ops.mesh.primitive_cube_add(size=1)\n"
            "mesh=bpy.context.object; mesh.name='FixtureMesh'\n"
            "arm_data=bpy.data.armatures.new('FixtureRigData')\n"
            "arm=bpy.data.objects.new('FixtureRig', arm_data); bpy.context.collection.objects.link(arm)\n"
            "bpy.context.view_layer.objects.active=arm; arm.select_set(True)\n"
            "bpy.ops.object.mode_set(mode='EDIT'); bone=arm.data.edit_bones.new('Root')\n"
            "bone.head=(0,0,0); bone.tail=(0,0,1); bpy.ops.object.mode_set(mode='OBJECT')\n"
            "mesh.parent=arm; group=mesh.vertex_groups.new(name='Root')\n"
            "group.add(list(range(len(mesh.data.vertices))), 1.0, 'REPLACE')\n"
            "mat=bpy.data.materials.new('FixtureGraphite'); mat.use_nodes=True; mesh.data.materials.append(mat)\n"
            f"bpy.ops.wm.save_as_mainfile(filepath={str(fixture)!r})\n",
            encoding="utf-8",
        )
        result = subprocess.run([blender, "-b", "--factory-startup", "--python", str(script)],
                                capture_output=True, text=True, timeout=120, check=False)
        self.assertEqual(result.returncode, 0, result.stderr[-500:])
        before = sha256(fixture)
        report = inspect_blend(fixture)
        self.assertEqual(report["armatures"][0]["bone_count"], 1)
        self.assertEqual(report["meshes"][0]["object_name"], "FixtureMesh")
        self.assertTrue(report["meshes"][0]["weights_sha256"])
        self.assertEqual(report["materials"][0]["name"], "FixtureGraphite")
        self.assertEqual(report["source"]["sha256"], before)
        self.assertEqual(sha256(fixture), before)

    def test_render_static_generates_eight_native_128_and_512_views_and_verifies_hashes(self) -> None:
        if not shutil.which("blender"):
            self.skipTest("Blender is required for the render integration test")
        before = sha256(self.static_glb)
        result = render_static(self.static_glb, self.root / "out", "fixture-cube")
        candidate = Path(result["candidate_path"])
        manifest = json.loads((candidate / "candidate_manifest.v1.json").read_text())
        self.assertEqual(manifest["status"], "candidate_unapproved")
        self.assertEqual(set(manifest["outputs"]), {
            f"renders/{size}_{direction}.png"
            for size in (128, 512)
            for direction in ("N", "NE", "E", "SE", "S", "SW", "W", "NW")
        })
        self.assertEqual(verify_candidate(candidate, self.static_glb.parent)["status"], "current")
        for rel in manifest["outputs"]:
            path = candidate / rel
            data = path.read_bytes()
            self.assertEqual(data[:8], b"\x89PNG\r\n\x1a\n")
            self.assertEqual(struct.unpack(">II", data[16:24]), (int(rel.split("/")[1].split("_")[0]),) * 2)
        self.assertEqual(sha256(self.static_glb), before)

        # The content address covers the rendered pixels, not only render inputs.
        manifest["outputs"]["renders/128_N.png"]["sha256"] = "0" * 64
        (candidate / "candidate_manifest.v1.json").write_text(json.dumps(manifest))
        stale = verify_candidate(candidate, self.static_glb.parent)
        self.assertEqual(stale["status"], "stale")
        self.assertIn("CANDIDATE_IDENTITY_MISMATCH", stale["errors"])

    def test_candidate_verification_rejects_output_path_traversal(self) -> None:
        if not shutil.which("blender"):
            self.skipTest("Blender is required for the render integration test")
        result = render_static(self.static_glb, self.root / "out", "fixture-cube")
        candidate = Path(result["candidate_path"])
        manifest_path = candidate / "candidate_manifest.v1.json"
        manifest = json.loads(manifest_path.read_text())
        record = manifest["review_files"].pop("review_pack/8dir_128.png")
        manifest["review_files"]["../escape.png"] = record
        from custodian.tools.operator.model_to_sprite.pipeline import _candidate_identity
        manifest["candidate_identity_sha256"] = hashlib.sha256(
            json.dumps(_candidate_identity(manifest), sort_keys=True, separators=(",", ":")).encode()
        ).hexdigest()
        manifest_path.write_text(json.dumps(manifest))
        stale = verify_candidate(candidate, self.static_glb.parent)
        self.assertEqual(stale["status"], "stale")
        self.assertIn("REVIEW_OUTPUT_MISMATCH:../escape.png", stale["errors"])

    def test_render_static_refuses_existing_output_without_overwriting(self) -> None:
        if not shutil.which("blender"):
            self.skipTest("Blender is required for the render integration test")
        output_root = self.root / "out"
        output_root.mkdir()
        existing = output_root / "fixture-cube"
        existing.mkdir()
        sentinel = existing / "keep.txt"
        sentinel.write_text("preserve")
        with self.assertRaises(ModelToSpriteError) as raised:
            render_static(self.static_glb, output_root, "fixture-cube")
        self.assertEqual(raised.exception.code, "OUTPUT_COLLISION")
        self.assertEqual(sentinel.read_text(), "preserve")


if __name__ == "__main__":
    unittest.main()
