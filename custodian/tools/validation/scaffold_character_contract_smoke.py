#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
from pathlib import Path
from tempfile import TemporaryDirectory


PROJECT_ROOT = Path(__file__).resolve().parents[2]
SCAFFOLD_TOOL = PROJECT_ROOT / "tools/pipelines/scaffold_character_contract.py"


def main() -> int:
    with TemporaryDirectory(prefix="character-scaffold-smoke-") as temp:
        root = Path(temp)
        result = subprocess.run(
            [
                sys.executable,
                str(SCAFFOLD_TOOL),
                "--owner",
                "enemy_smoke",
                "--template",
                "humanoid_combat",
                "--frame-size",
                "96",
                "--directions",
                "s,e",
                "--output-root",
                str(root),
            ],
            check=False,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            print(result.stdout)
            print(result.stderr, file=sys.stderr)
            return result.returncode
        request_dir = root / "enemy_smoke"
        checklist = request_dir / "enemy_smoke_animation_checklist.md"
        contract = request_dir / "enemy_smoke_suggested_contract.json"
        filenames = request_dir / "enemy_smoke_expected_filenames.txt"
        assert checklist.exists()
        assert contract.exists()
        assert filenames.exists()
        filename_text = filenames.read_text(encoding="utf-8")
        assert "enemy_smoke__body__unarmed__idle_01__s__5f__96.png" in filename_text
        assert "enemy_smoke__body__unarmed__attack_01__e__6f__96.png" in filename_text
        assert "Runtime playback still requires deliberate code/state registration" in checklist.read_text(encoding="utf-8")
    print("scaffold_character_contract_smoke passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
