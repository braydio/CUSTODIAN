"""Fast coverage for prompt contracts and serialized main landing."""

from pathlib import Path
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[3]


def validate_procgen_packet_routing_expiry() -> None:
    instructions = (ROOT / "custodian/AGENTS.md").read_text()
    workflow = (ROOT / ".github/workflows/expire-lfs-degraded-mode.yml").read_text()
    start = "<!-- TEMP_PROCGEN_PACKET_ROUTING_START expires=2026-10-01T04:00:00Z -->"
    end = "<!-- TEMP_PROCGEN_PACKET_ROUTING_END -->"
    assert start in instructions and end in instructions
    note = instructions[instructions.index(start):instructions.index(end)]
    assert "Until 2026-10-01 00:00 America/New_York" in note
    assert "agents other than Claude must skip all procgen-family task packets" in note
    assert "Claude is explicitly allowed to claim and work procgen-family task packets" in note
    assert 'cron: "0 4 * * *"' in workflow
    assert "datetime(2026, 10, 1, 4, 0, tzinfo=timezone.utc)" in workflow
    assert "TEMP_PROCGEN_PACKET_ROUTING_START" in workflow
    assert end in workflow


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
