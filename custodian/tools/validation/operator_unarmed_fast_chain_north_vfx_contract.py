#!/usr/bin/env python3
"""Verify the North fast-chain FX source, pipeline, and runtime image contract."""
from __future__ import annotations

import hashlib
import re
from pathlib import Path
import subprocess

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
ASSET_ROOT = ROOT / "custodian"
VERIFIED_PUBLICATIONS = {
    "fast_01": "4e845cffaae5d593028ae44acc89cae0241c290c",
    "fast_02": "217f41093802b8c74cf88f986076e4e26acc8e77",
}
FAST_01_SOURCE_PATH = "custodian/content/sprites/operator/source/animations/unarmed/attack/fast_01/operator__fx__unarmed__attack__fast_01__n__6f__96.png"
LFS_POINTER = re.compile(rb"\Aversion https://git-lfs\.github\.com/spec/v1\noid sha256:([0-9a-f]{64})\nsize [0-9]+\n\Z")


def published_lfs_identity(repo_root: Path, commit: str, path: str) -> str:
    """Return a published LFS object's SHA only for a commit in current HEAD ancestry."""
    ancestor = subprocess.run(
        ["git", "merge-base", "--is-ancestor", commit, "HEAD"],
        cwd=repo_root,
        capture_output=True,
        check=False,
    )
    if ancestor.returncode != 0:
        raise AssertionError(f"publication provenance is absent or not in HEAD ancestry: {commit}")
    pointer = subprocess.run(
        ["git", "show", f"{commit}:{path}"],
        cwd=repo_root,
        capture_output=True,
        check=False,
    )
    if pointer.returncode != 0:
        raise AssertionError(f"publication does not contain the declared source path: {path}")
    match = LFS_POINTER.fullmatch(pointer.stdout)
    if match is None:
        raise AssertionError(f"published source is not a canonical Git LFS pointer: {path}")
    return match.group(1).decode("ascii")


def validate_action(
    repo_root: Path,
    action: str,
    frames: int,
    publication_commit: str | None = None,
) -> None:
    name = f"operator__fx__unarmed__attack__{action}__n__{frames}f__96.png"
    paths = {
        "source_work": repo_root / "custodian/asset_drop/source_work/operator/unarmed/attack" / action / "north" / f"operator_unarmed_{action}_n_vfx_generated_master.png",
        "inbox": repo_root / "custodian/content/sprites/_pipeline/inbox" / name,
        "normalized": repo_root / "custodian/content/sprites/_pipeline/normalized" / name,
        "source": repo_root / "custodian/content/sprites/operator/source/animations/unarmed/attack" / action / name,
        "runtime": repo_root / "custodian/content/sprites/operator/runtime/animations/unarmed/attack" / action / name,
    }
    for label, path in paths.items():
        assert path.is_file(), f"{action}: missing {label} asset: {path}"

    assert paths["source"].read_bytes() == paths["runtime"].read_bytes(), f"{action}: source/runtime bytes differ"
    publication_commit = publication_commit or VERIFIED_PUBLICATIONS.get(action)
    published_sha = None
    if publication_commit is not None:
        source_path = paths["source"].relative_to(repo_root).as_posix()
        published_sha = published_lfs_identity(repo_root, publication_commit, source_path)
    reference_pixels = None
    for label in ("inbox", "normalized", "source", "runtime"):
        with Image.open(paths[label]) as source_image:
            image = source_image.convert("RGBA")
        assert image.size == (frames * 96, 96), f"{action}: {label} dimensions {image.size}"
        alpha = image.getchannel("A")
        assert alpha.getextrema() == (0, 255), f"{action}: {label} lacks real transparency"
        for frame in range(frames):
            cell = alpha.crop((frame * 96, 0, (frame + 1) * 96, 96))
            assert cell.getbbox() is not None, f"{action}: {label} frame {frame + 1} is empty"
        pixels = image.tobytes()
        if reference_pixels is None:
            reference_pixels = pixels
        elif published_sha is not None and label in ("source", "runtime"):
            actual_sha = hashlib.sha256(paths[label].read_bytes()).hexdigest()
            assert actual_sha == published_sha, f"{action}: {label} differs from verified canonical art publication"
        else:
            assert pixels == reference_pixels, f"{action}: {label} pixels differ from inbox"


def main() -> int:
    for action, frames in (("fast_01", 6), ("fast_02", 6), ("fast_03", 7), ("fast_04", 8)):
        validate_action(ROOT, action, frames)
    print("PASS operator_unarmed_fast_chain_north_vfx_contract: dimensions, alpha, cells, and pipeline parity")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
