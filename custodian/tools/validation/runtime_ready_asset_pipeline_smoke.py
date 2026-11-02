#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "pipelines" / "runtime_ready_assets.py"


def run(*args: str, expected: int = 0) -> subprocess.CompletedProcess[str]:
    result = subprocess.run([sys.executable, str(SCRIPT), *args], capture_output=True, text=True, check=False)
    assert result.returncode == expected, result.stdout + result.stderr
    return result


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="custodian-runtime-ready-") as temp:
        root = Path(temp)
        project = root / "custodian"
        drop = project / "asset_drop" / "runtime_ready"
        inbox = drop / "inbox"
        source = inbox / "ui" / "icons" / "test_icon.png"
        source.parent.mkdir(parents=True)
        source.write_bytes(b"v1")

        common = ("--project-dir", str(project), "--drop-dir", str(drop))
        run("--dry-run", *common)
        assert source.exists()
        assert not (project / "content" / "ui" / "icons" / "test_icon.png").exists()

        run("--apply", *common)
        target = project / "content" / "ui" / "icons" / "test_icon.png"
        assert target.read_bytes() == b"v1"
        assert not source.exists()
        assert list((drop / "archive").rglob("test_icon.png"))
        assert list((drop / "logs").glob("*.json"))

        routed = inbox / "bell.ogg"
        routed.parent.mkdir(parents=True, exist_ok=True)
        routed.write_bytes(b"bell")
        routed.with_name(routed.name + ".runtime.json").write_text(
            json.dumps({"targets": ["audio/encounters/test/bell.ogg"]}),
            encoding="utf-8",
        )
        run("--apply", *common)
        assert (project / "content" / "audio" / "encounters" / "test" / "bell.ogg").read_bytes() == b"bell"

        conflict = inbox / "ui" / "icons" / "test_icon.png"
        conflict.parent.mkdir(parents=True, exist_ok=True)
        conflict.write_bytes(b"v2")
        run("--apply", *common, expected=2)
        assert conflict.exists()
        assert target.read_bytes() == b"v1"
        run("--apply", "--replace", *common)
        assert target.read_bytes() == b"v2"

        unknown = inbox / "typo_domain" / "bad.png"
        unknown.parent.mkdir(parents=True, exist_ok=True)
        unknown.write_bytes(b"bad")
        run("--apply", *common, expected=2)
        assert unknown.exists()
        assert not (project / "content" / "typo_domain").exists()

    print("[RuntimeReadyAssetPipelineSmoke] ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
