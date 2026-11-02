#!/usr/bin/env python3
from __future__ import annotations

import json
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[2]
PIPELINE_ROOT = PROJECT_ROOT / "content/sprites/_pipeline"
INBOX = PIPELINE_ROOT / "inbox"
ARCHIVE = PIPELINE_ROOT / "archive"
LOGS = PIPELINE_ROOT / "logs"
NORMALIZED = PIPELINE_ROOT / "normalized"
DESTINATION = PROJECT_ROOT / "content/sprites/_pipeline_cleanup_smoke/runtime"
INGEST = PROJECT_ROOT / "tools/pipelines/ingest.py"

OLD_NAME = "pipeline_cleanup_smoke__body__test__replace_01__e__5f__96.png"
NEW_NAME = "pipeline_cleanup_smoke__body__test__replace_01__e__7f__96.png"


def _write_strip(path: Path, frames: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.new("RGBA", (frames * 96, 96), (255, 255, 255, 255)).save(path)


def _run(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(INGEST), *args],
        cwd=PROJECT_ROOT,
        text=True,
        capture_output=True,
        check=False,
    )


def main() -> int:
    source = INBOX / NEW_NAME
    manifest = source.with_suffix(".json")
    old_output = DESTINATION / OLD_NAME
    new_output = DESTINATION / NEW_NAME
    old_import = old_output.with_suffix(old_output.suffix + ".import")
    cleanup_paths = [
        source,
        manifest,
        ARCHIVE / NEW_NAME,
        ARCHIVE / manifest.name,
        LOGS / f"{manifest.stem}.log.json",
        NORMALIZED / NEW_NAME,
    ]

    try:
        _write_strip(source, 7)
        _write_strip(old_output, 5)
        old_import.write_text("smoke import sidecar\n", encoding="utf-8")
        manifest.write_text(
            json.dumps(
                {
                    "source": NEW_NAME,
                    "mode": "strip",
                    "frame_size": [96, 96],
                    "outputs": [
                        {
                            "path": f"_pipeline_cleanup_smoke/runtime/{NEW_NAME}",
                            "layout": "horizontal_strip",
                            "select": {"type": "range", "start": 0, "count": 7},
                        }
                    ],
                },
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )

        dry_run = _run("--dry-run", "--remove-superseded", "--manifest", str(manifest))
        assert dry_run.returncode == 0, dry_run.stdout + dry_run.stderr
        assert "remove superseded" in dry_run.stdout
        assert old_output.exists() and old_import.exists()
        assert not new_output.exists()

        apply = _run("--remove-superseded", "--skip-post", "--manifest", str(manifest))
        assert apply.returncode == 0, apply.stdout + apply.stderr
        assert not old_output.exists() and not old_import.exists()
        assert new_output.exists()
    finally:
        for path in cleanup_paths:
            path.unlink(missing_ok=True)
        shutil.rmtree(DESTINATION.parent, ignore_errors=True)

    print("sprite superseded cleanup smoke passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
