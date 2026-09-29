"""Fast coverage for prompt contracts and serialized main landing."""

from pathlib import Path
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[3]


def main() -> int:
    commands = [
        [sys.executable, "custodian/tools/agent/validate_prompt_contract.py", "--templates-only", "--strict", "--self-test"],
        [sys.executable, "custodian/tools/agent/test_land_main.py"],
        [sys.executable, "custodian/tools/agent/test_dispatch.py"],
        [sys.executable, "custodian/tools/agent/test_review_contract.py"],
    ]
    for command in commands:
        result = subprocess.run(command, cwd=ROOT)
        if result.returncode:
            return result.returncode
    print("PASS agent workflow contracts")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
