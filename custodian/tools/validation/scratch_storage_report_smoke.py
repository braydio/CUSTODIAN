#!/usr/bin/env python3
"""Prove RAM-backed worktree reporting is protective and read-only."""

from __future__ import annotations

import importlib.util
import os
import subprocess
import tempfile
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "agent" / "workstream.py"
SPEC = importlib.util.spec_from_file_location("workstream_scratch_report", SCRIPT)
workstream = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(workstream)


def git(repo: Path, *args: str) -> None:
    subprocess.run(["git", *args], cwd=repo, check=True, capture_output=True, text=True)


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="scratch-report-smoke-") as temp:
        root = Path(temp)
        repo = root / "repo"
        repo.mkdir()
        git(repo, "init", "-q")
        git(repo, "config", "user.name", "Smoke")
        git(repo, "config", "user.email", "smoke@example.test")
        (repo / "preserve.txt").write_text("keep this file\n", encoding="utf-8")
        git(repo, "add", "preserve.txt")
        git(repo, "commit", "-m", "fixture")
        git(repo, "switch", "-c", "agent/protected-fixture")
        (repo / "dirty.txt").write_text("must remain\n", encoding="utf-8")
        packet_root = repo / "custodian/docs/ai_context/task_packets"
        packet_root.mkdir(parents=True)
        (packet_root / "PROTECTED_FIXTURE.md").write_text(
            "# Protected fixture\n\n- Workstream: `protected-fixture`\n- Status: `blocked`\n",
            encoding="utf-8",
        )

        scratch = root / "scratch-not-created"
        os.environ["CUSTODIAN_SCRATCH_DIR"] = str(scratch)
        record = {"worktree": str(repo), "branch": "refs/heads/agent/protected-fixture"}
        report = workstream.storage_report(
            repo,
            records=[record],
            mounts=[{"mount": str(root), "fstype": "tmpfs"}],
        )
        entry = report["ram_backed_worktrees"][0]
        assert report["scratch"]["ram_backed"] is True, report["scratch"]
        assert entry["protected"] is True, entry
        assert "claimed workstream" in entry["protected_reasons"], entry
        assert "blocked packet" in entry["protected_reasons"], entry
        assert "dirty" in entry["protected_reasons"], entry
        assert "unpushed or no upstream" in entry["protected_reasons"], entry
        assert report["deletions_performed"] == 0, report
        assert (repo / "preserve.txt").read_text(encoding="utf-8") == "keep this file\n"
        assert (repo / "dirty.txt").read_text(encoding="utf-8") == "must remain\n"
        assert not scratch.exists(), "the read-only report must not create scratch state"
        os.environ.pop("CUSTODIAN_SCRATCH_DIR", None)
    print("scratch_storage_report_smoke: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
