#!/usr/bin/env python3
"""Create a markdown bundle of current changed files for change control."""

from __future__ import annotations

import argparse
import datetime as dt
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path


REPO_MARKER = ".git"
BINARY_PREVIEW_BYTES = 8192


def run_git(repo_root: Path, args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=repo_root,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def find_repo_root(start: Path) -> Path:
    current = start.resolve()
    for candidate in [current, *current.parents]:
        if (candidate / REPO_MARKER).exists():
            return candidate
    raise SystemExit("Could not find repository root.")


def normalize_packet_name(raw_name: str) -> str:
    name = raw_name.strip()
    if name.endswith(".md"):
        name = name[:-3]
    name = name.replace("\\", "/").split("/")[-1]
    name = re.sub(r"[^A-Za-z0-9_.-]+", "_", name)
    name = name.strip("._-")
    if not name:
        raise SystemExit("Task packet name cannot be empty after sanitization.")
    return name


def find_task_packet(repo_root: Path, packet_name: str) -> Path | None:
    candidates = [
        repo_root / "custodian/docs/ai_context/task_packets" / f"{packet_name}.md",
        repo_root / "custodian/docs/ai_context/task_packets/archived" / f"{packet_name}.md",
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate
    return None


def parse_status_z(raw: str) -> list[tuple[str, str]]:
    entries = raw.split("\0")
    changed: list[tuple[str, str]] = []
    idx = 0
    while idx < len(entries):
        entry = entries[idx]
        idx += 1
        if not entry:
            continue
        status = entry[:2]
        path = entry[3:]
        if not path:
            continue
        changed.append((status, path))
        if status[0] in {"R", "C"} or status[1] in {"R", "C"}:
            idx += 1
    return changed


def changed_files(repo_root: Path, output_rel: str) -> list[tuple[str, Path]]:
    result = run_git(
        repo_root,
        ["status", "--porcelain=v1", "-z", "--untracked-files=all"],
    )
    files: list[tuple[str, Path]] = []
    seen: set[str] = set()
    for status, rel_path in parse_status_z(result.stdout):
        rel_path = rel_path.replace("\\", "/")
        if rel_path == output_rel or rel_path in seen:
            continue
        seen.add(rel_path)
        files.append((status, repo_root / rel_path))
    return files


def is_binary_file(path: Path) -> bool:
    try:
        data = path.read_bytes()[:BINARY_PREVIEW_BYTES]
    except OSError:
        return False
    return b"\0" in data


def language_for(path: Path) -> str:
    suffix = path.suffix.lower().lstrip(".")
    return {
        "gd": "gdscript",
        "md": "markdown",
        "py": "python",
        "json": "json",
        "ts": "typescript",
        "js": "javascript",
        "sh": "bash",
        "toml": "toml",
        "yaml": "yaml",
        "yml": "yaml",
    }.get(suffix, suffix)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def fence(text: str, info: str) -> str:
    backtick_run = max((len(match.group(0)) for match in re.finditer(r"`+", text)), default=0)
    fence_ticks = "`" * max(3, backtick_run + 1)
    return f"{fence_ticks}{info}\n{text.rstrip()}\n{fence_ticks}\n"


def build_bundle(repo_root: Path, packet_name: str, packet_path: Path | None, output_path: Path) -> str:
    output_rel = output_path.relative_to(repo_root).as_posix()
    files = changed_files(repo_root, output_rel)
    now = dt.datetime.now().astimezone().isoformat(timespec="seconds")
    lines: list[str] = [
        f"# Change Control Bundle: {packet_name}",
        "",
        f"- Generated: {now}",
        f"- Repository: `{repo_root}`",
        f"- Task packet: `{packet_path.relative_to(repo_root).as_posix() if packet_path else 'not found'}`",
        f"- Changed files included: {len(files)}",
        "",
    ]
    if packet_path is None:
        lines.extend([
            "> Warning: no matching task packet was found in active or archived task packet directories.",
            "",
        ])
    lines.extend(["## Files", ""])
    if not files:
        lines.extend(["No changed files were found.", ""])
        return "\n".join(lines)
    for status, path in files:
        rel = path.relative_to(repo_root).as_posix()
        lines.extend([f"## `{rel}`", "", f"- Git status: `{status}`", ""])
        if not path.exists():
            lines.extend(["File is deleted or missing in the working tree.", ""])
            continue
        if is_binary_file(path):
            size = path.stat().st_size
            lines.extend([f"Binary file omitted from inline content. Size: `{size}` bytes.", ""])
            continue
        content = read_text(path)
        lines.append(fence(content, language_for(path)))
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def copy_to_clipboard(text: str) -> str | None:
    commands = [
        ["wl-copy"],
        ["xclip", "-selection", "clipboard"],
        ["xsel", "--clipboard", "--input"],
        ["pbcopy"],
        ["clip.exe"],
    ]
    for command in commands:
        if shutil.which(command[0]) is None:
            continue
        try:
            subprocess.run(command, input=text, text=True, check=True)
            return " ".join(command)
        except (OSError, subprocess.CalledProcessError):
            continue
    return None


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Bundle all current changed files into custodian/docs/change_control/<TASK_PACKET_NAME>.md and copy it to the clipboard.",
    )
    parser.add_argument("task_packet_name", help="Task packet name, with or without .md")
    parser.add_argument("--no-clipboard", action="store_true", help="Write the bundle but skip clipboard copy.")
    args = parser.parse_args(argv)

    repo_root = find_repo_root(Path.cwd())
    packet_name = normalize_packet_name(args.task_packet_name)
    packet_path = find_task_packet(repo_root, packet_name)
    output_dir = repo_root / "custodian/docs/change_control"
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{packet_name}.md"
    bundle = build_bundle(repo_root, packet_name, packet_path, output_path)
    output_path.write_text(bundle, encoding="utf-8")

    clipboard_command = None if args.no_clipboard else copy_to_clipboard(bundle)
    print(f"Wrote {output_path}")
    if args.no_clipboard:
        print("Clipboard copy skipped.")
    elif clipboard_command:
        print(f"Copied bundle to clipboard via `{clipboard_command}`.")
    else:
        print("No clipboard command found; bundle was written but not copied.", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
