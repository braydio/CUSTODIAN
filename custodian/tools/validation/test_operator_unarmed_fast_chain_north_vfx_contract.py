#!/usr/bin/env python3
"""Regression tests for immutable intake and verified canonical publication."""
from __future__ import annotations

import hashlib
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[3]
SCRIPT = ROOT / "custodian/tools/validation/operator_unarmed_fast_chain_north_vfx_contract.py"
SPEC = importlib.util.spec_from_file_location("north_vfx_contract", SCRIPT)
CONTRACT = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(CONTRACT)


def make_strip(color: tuple[int, int, int, int]) -> bytes:
    image = Image.new("RGBA", (576, 96), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    for frame in range(6):
        left = frame * 96
        draw.rectangle((left + 20, 20, left + 40, 40), fill=color)
    from io import BytesIO
    buffer = BytesIO()
    image.save(buffer, format="PNG")
    return buffer.getvalue()


def run_git(repo: Path, *args: str) -> str:
    return subprocess.run(["git", *args], cwd=repo, check=True, capture_output=True, text=True).stdout.strip()


class NorthFast01PublicationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.repo = Path(self.temp.name)
        run_git(self.repo, "init", "-q")
        run_git(self.repo, "config", "user.email", "test@example.invalid")
        run_git(self.repo, "config", "user.name", "VFX contract test")
        self.inbox = make_strip((255, 30, 20, 255))
        self.published = make_strip((20, 210, 80, 255))
        digest = hashlib.sha256(self.published).hexdigest()
        pointer = (
            "version https://git-lfs.github.com/spec/v1\n"
            f"oid sha256:{digest}\nsize {len(self.published)}\n"
        )
        published_path = self.repo / CONTRACT.FAST_01_SOURCE_PATH
        published_path.parent.mkdir(parents=True)
        published_path.write_text(pointer)
        run_git(self.repo, "add", CONTRACT.FAST_01_SOURCE_PATH)
        run_git(self.repo, "commit", "-qm", "publish canonical source")
        self.publication = run_git(self.repo, "rev-parse", "HEAD")

        name = "operator__fx__unarmed__attack__fast_01__n__6f__96.png"
        relpaths = {
            "source_work": "custodian/asset_drop/source_work/operator/unarmed/attack/fast_01/north/operator_unarmed_fast_01_n_vfx_generated_master.png",
            "inbox": f"custodian/content/sprites/_pipeline/inbox/{name}",
            "normalized": f"custodian/content/sprites/_pipeline/normalized/{name}",
            "source": f"custodian/content/sprites/operator/source/animations/unarmed/attack/fast_01/{name}",
            "runtime": f"custodian/content/sprites/operator/runtime/animations/unarmed/attack/fast_01/{name}",
        }
        self.paths = {key: self.repo / rel for key, rel in relpaths.items()}
        for path in self.paths.values():
            path.parent.mkdir(parents=True, exist_ok=True)
        self.paths["source_work"].write_bytes(self.inbox)
        self.paths["inbox"].write_bytes(self.inbox)
        self.paths["normalized"].write_bytes(self.inbox)
        self.paths["source"].write_bytes(self.published)
        self.paths["runtime"].write_bytes(self.published)

    def tearDown(self) -> None:
        self.temp.cleanup()

    def validate(self, publication: str | None = None) -> None:
        CONTRACT.validate_action(self.repo, "fast_01", 6, publication or self.publication)

    def test_verified_publication_can_differ_from_immutable_intake(self) -> None:
        self.validate()

    def test_unauthorized_source_and_runtime_change_fails(self) -> None:
        changed = make_strip((15, 40, 230, 255))
        self.paths["source"].write_bytes(changed)
        self.paths["runtime"].write_bytes(changed)
        with self.assertRaisesRegex(AssertionError, "verified canonical art publication"):
            self.validate()

    def test_runtime_change_without_source_parity_fails(self) -> None:
        self.paths["runtime"].write_bytes(make_strip((15, 40, 230, 255)))
        with self.assertRaisesRegex(AssertionError, "source/runtime bytes differ"):
            self.validate()

    def test_missing_publication_provenance_fails(self) -> None:
        with self.assertRaisesRegex(AssertionError, "publication provenance"):
            self.validate("f" * 40)

    def test_reversed_publication_ancestry_fails(self) -> None:
        run_git(self.repo, "checkout", "--orphan", "unrelated")
        run_git(self.repo, "rm", "-rfq", ".")
        marker = self.repo / "unrelated.txt"
        marker.write_text("unrelated head\n")
        run_git(self.repo, "add", "unrelated.txt")
        run_git(self.repo, "commit", "-qm", "unrelated history")
        with self.assertRaisesRegex(AssertionError, "not in HEAD ancestry"):
            CONTRACT.published_lfs_identity(self.repo, self.publication, CONTRACT.FAST_01_SOURCE_PATH)


if __name__ == "__main__":
    unittest.main()
