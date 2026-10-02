"""Fast coverage for prompt contracts and serialized main landing."""

from pathlib import Path
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[3]


def validate_procgen_packet_routing_expiry() -> None:
    """Keep removed temporary routing controls absent after their expiry."""
    assert not (ROOT / ".github/workflows/expire-lfs-degraded-mode.yml").exists()
    markers = (
        "TEMP_PROCGEN_PACKET_ROUTING_START",
        "TEMP_PROCGEN_PACKET_ROUTING_END",
        "agents other than Claude must skip all procgen-family task packets",
        "Claude is explicitly allowed to claim and work procgen-family task packets",
    )
    for relative in (
        "custodian/AGENTS.md",
        "custodian/tools/agent/workstream.py",
        "custodian/tools/agent/land_main.py",
        "tools/custodian_aliases.sh",
    ):
        content = (ROOT / relative).read_text()
        for marker in markers:
            assert marker not in content, f"expired routing marker remains in {relative}: {marker}"


def main() -> int:
    validate_procgen_packet_routing_expiry()
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
