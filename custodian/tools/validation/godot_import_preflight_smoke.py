#!/usr/bin/env python3
"""Prove LFS pointer detection protects project-wide Godot imports."""

from __future__ import annotations

import sys
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "custodian/tools/pipelines"))

from godot_import_preflight import POINTER_HEADER, preflight_detail, unmaterialized_lfs_paths


def _git(root: Path, *args: str) -> None:
    subprocess.run(["git", "-C", str(root), *args], check=True, capture_output=True, text=True)


def _sidecar(source: str | None, uid: str | None, *, invalid: bool = False, destination: bool = True,
             remap_path: bool = True) -> str:
    valid_line = "valid=false\n" if invalid else ""
    dest = 'dest_files=["res://.godot/imported/asset.ctex"]' if destination else "dest_files=[]"
    remap = 'path="res://.godot/imported/asset.ctex"\n' if remap_path else ""
    uid_line = f'uid="{uid}"\n' if uid else ""
    source_line = f'source_file="res://{source}"\n' if source else ""
    return (
        "[remap]\nimporter=\"texture\"\ntype=\"CompressedTexture2D\"\n"
        f"{uid_line}{valid_line}{remap}\n"
        f"[deps]\n{source_line}{dest}\n"
    )


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="godot-import-preflight-") as temp:
        root = Path(temp)
        project = root / "project"
        project.mkdir()
        pointer = project / "pointer.png"
        image = project / "materialized.png"
        outside_project = root / "outside-pointer.png"
        pointer.write_bytes(POINTER_HEADER + b"\noid sha256:deadbeef\n")
        image.write_bytes(b"\x89PNG\r\n\x1a\nimage bytes")
        outside_project.write_bytes(POINTER_HEADER + b"\noid sha256:deadbeef\n")

        found = unmaterialized_lfs_paths(
            root,
            project,
            [
                "project/pointer.png",
                "project/materialized.png",
                "project/sparse-omitted.png",
                f"{outside_project.name}",
            ],
        )
        if found != [pointer]:
            print(f"FAIL: expected only the LFS pointer, found {found}")
            return 1
        if preflight_detail(project) is not None:
            print("FAIL: standalone project should not require a Git LFS check")
            return 1
        outside_project.unlink()

    with tempfile.TemporaryDirectory(prefix="godot-import-sidecars-") as temp:
        root = Path(temp)
        project = root / "custodian"
        assets = project / "content" / "vaultwing"
        scenes = project / "scenes"
        assets.mkdir(parents=True)
        scenes.mkdir()
        _git(root, "init", "-q")
        references: list[str] = []
        for index in range(15):
            name = f"vaultwing_bond_{index:02d}.png"
            relative = f"content/vaultwing/{name}"
            (assets / name).write_bytes(b"fixture source")
            (assets / f"{name}.import").write_text(
                _sidecar(relative, f"uid://fixture{index:02d}", invalid=True), encoding="utf-8"
            )
            if index == 14:
                references.append(f'[ext_resource type="Texture2D" uid="uid://fixture{index:02d}" id="{index}"]')
            else:
                references.append(f'[ext_resource type="Texture2D" path="res://{relative}" id="{index}"]')
        (scenes / "vaultwing.tscn").write_text("[gd_scene]\n" + "\n".join(references), encoding="utf-8")
        _git(root, "add", "custodian")
        detail = preflight_detail(project)
        if not detail or detail.count("valid=false") != 15 or detail.count(".png.import") != 15:
            print(f"FAIL: expected all 15 referenced invalid sidecars to block import, got: {detail}")
            return 1

        # A valid referenced record passes, but an unreferenced corrupt tracked
        # archive and an untracked corrupt file are not project dependencies.
        for index in range(15):
            name = f"vaultwing_bond_{index:02d}.png"
            (assets / f"{name}.import").write_text(
                _sidecar(f"content/vaultwing/{name}", f"uid://fixture{index:02d}"), encoding="utf-8"
            )
        unused = "content/vaultwing/unused_archive.png"
        (assets / "unused_archive.png").write_bytes(b"archive")
        (assets / "unused_archive.png.import").write_text(
            _sidecar(unused, "uid://unused", invalid=True), encoding="utf-8"
        )
        _git(root, "add", "custodian/content/vaultwing")
        if preflight_detail(project) is not None:
            print("FAIL: valid dependencies or unreferenced broken sidecars blocked import")
            return 1

        untracked = "content/vaultwing/untracked.png"
        (assets / "untracked.png").write_bytes(b"fixture source")
        (assets / "untracked.png.import").write_text(
            _sidecar(untracked, "uid://untracked", invalid=True), encoding="utf-8"
        )
        with (scenes / "vaultwing.tscn").open("a", encoding="utf-8") as stream:
            stream.write(f'\n[ext_resource type="Texture2D" path="res://{untracked}" id="untracked"]\n')
        if preflight_detail(project) is not None:
            print("FAIL: untracked sidecar should not be treated as tracked import metadata")
            return 1

        # R0-01: the sidecar filename still identifies its source when both
        # optional-looking metadata fields were removed from the malformed file.
        missing_source = "content/vaultwing/bad.png"
        (assets / "bad.png").write_bytes(b"fixture source")
        (assets / "bad.png.import").write_text(
            _sidecar(None, None, invalid=True, destination=False), encoding="utf-8"
        )
        with (scenes / "vaultwing.tscn").open("a", encoding="utf-8") as stream:
            stream.write(f'\n[ext_resource type="Texture2D" path="res://{missing_source}" id="bad"]\n')
        _git(root, "add", "custodian")
        detail = preflight_detail(project)
        if not detail or "bad.png.import" not in detail or "missing source file metadata" not in detail:
            print(f"FAIL: sidecar without source_file/UID escaped preflight: {detail}")
            return 1

        # Missing remap destinations are also rejected when that tracked source
        # is referenced by a scene.
        missing = "content/vaultwing/missing_destination.png"
        (assets / "missing_destination.png").write_bytes(b"fixture source")
        (assets / "missing_destination.png.import").write_text(
            _sidecar(missing, "uid://missingdest", destination=False), encoding="utf-8"
        )
        with (scenes / "vaultwing.tscn").open("a", encoding="utf-8") as stream:
            stream.write(f'\n[ext_resource type="Texture2D" path="res://{missing}" id="missing"]\n')
        _git(root, "add", "custodian")
        detail = preflight_detail(project)
        if not detail or "missing remap destination" not in detail:
            print(f"FAIL: missing remap destination was not rejected: {detail}")
            return 1

        missing_path = "content/vaultwing/missing_path.png"
        (assets / "missing_path.png").write_bytes(b"fixture source")
        (assets / "missing_path.png.import").write_text(
            _sidecar(missing_path, "uid://missingpath", remap_path=False), encoding="utf-8"
        )
        with (scenes / "vaultwing.tscn").open("a", encoding="utf-8") as stream:
            stream.write(f'\n[ext_resource type="Texture2D" path="res://{missing_path}" id="missing_path"]\n')
        _git(root, "add", "custodian")
        detail = preflight_detail(project)
        if not detail or "missing remap path" not in detail:
            print(f"FAIL: missing remap path was not rejected: {detail}")
            return 1

    print("godot_import_preflight_smoke: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
