#!/usr/bin/env python3
"""Claude Bash pre-tool guard: protect the shared CUSTODIAN coordination checkout.

This is a command guard, not a replacement for V2 worktree/landing validation.
It never changes files or Git state. Exit 2 from PreToolUse denies the command.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
# Branch changes and direct source mutations are prohibited in the shared root.
ROOT_MUTATION = re.compile(
    r"(?<![\w./-])(?:rtk\s+)?git\s+"
    r"(?:(?:-C\s+(?:\"[^\"]+\"|'[^']+'|\S+)|-c\s+\S+)\s+){0,5}"
    r"(?:switch|checkout|rebase|reset|stash|cherry-pick|merge|restore|clean|"
    r"add|commit|am|apply|mv|rm|update-ref|symbolic-ref)\b",
    re.IGNORECASE | re.MULTILINE,
)


def is_restricted(command: str, cwd: Path, root: Path = ROOT) -> bool:
    """Fail closed for root-affecting Git mutation, not for isolated worktrees."""
    text = command or ""
    if not ROOT_MUTATION.search(text):
        return False
    # Commands executed in a turn checkout are permitted by their own lifecycle.
    # Explicitly naming the coordination root remains forbidden from anywhere.
    root_text = str(root.resolve())
    root_cwd = cwd.resolve() == root.resolve()
    explicit_root = (
        bool(re.search(r"\b(?:cd|git\s+-C)\s+['\"]?" + re.escape(root_text) +
                       r"(?=['\"\s;&|]|$)", text))
    )
    if not root_cwd and not explicit_root:
        return False
    # A root-origin git -C invocation targeting an isolated checkout is allowed.
    if root_cwd and not explicit_root:
        matches = list(re.finditer(r"\bgit\s+-C\s+(['\"]?)(\S+?)\1(?=\s|$)", text))
        if len(matches) == 1:
            target = Path(matches[0].group(2)).expanduser()
            target = target if target.is_absolute() else cwd / target
            if target.resolve() != root.resolve():
                return False
    return True


def hook() -> int:
    try:
        payload = json.load(sys.stdin)
    except (ValueError, OSError):
        print("CUSTODIAN: refusing unparsable Bash pre-tool input", file=sys.stderr)
        return 2
    if payload.get("tool_name") not in ("Bash", None):
        return 0
    command = payload.get("tool_input", {}).get("command", "")
    cwd = Path(payload.get("cwd") or ROOT)
    if is_restricted(command, cwd):
        print(
            "CUSTODIAN: coordination root is main-only and not an implementation "
            "checkout. Use dispatch.py claim/start and run Git mutation inside "
            "the returned temporary worktree. No branch switch or commit here.",
            file=sys.stderr,
        )
        return 2
    return 0


def check_root() -> int:
    check = subprocess.run(
        ["git", "-C", str(ROOT), "symbolic-ref", "--quiet", "--short", "HEAD"],
        text=True, capture_output=True, check=False,
    )
    if check.returncode or check.stdout.strip() != "main":
        print(
            f"CUSTODIAN: shared coordination root must remain on main "
            f"(observed: {check.stdout.strip() or 'detached/unknown'}). "
            "Stop; preserve the current checkout, do not force-switch.",
            file=sys.stderr,
        )
        return 2
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument("--hook", action="store_true")
    mode.add_argument("--check-root", action="store_true")
    args = ap.parse_args()
    return hook() if args.hook else check_root()


if __name__ == "__main__":
    sys.exit(main())
