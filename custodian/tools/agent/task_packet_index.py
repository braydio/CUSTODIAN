#!/usr/bin/env python3
"""Bounded, deterministic Ready/Auto Dispatch README-index authority.

Absorbs the scope of the superseded `TASK_PACKET_INDEX_AUTOMODE_HARDENING.md`
packet. Owns rendering/checking of only the managed block inside
`task_packets/README.md`'s `### Ready / Auto Dispatch` section, bounded by
explicit HTML-comment markers. Reuses `task_packet_contract.py` for all
packet grammar. `Dispatch.py` remains task-selection authority; this tool
never mutates packet metadata, never auto-archives, and never rewrites
manual-ready/In Progress/Recently Complete content outside the managed
block.

CLI:
    python3 task_packet_index.py           # check mode (default); nonzero on drift
    python3 task_packet_index.py --write   # rewrite only the managed block
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from task_packet_contract import PACKET_ROOT, PRIORITY, header_field, parse_packet, validate_queue_contract

MANAGED_BLOCK_START = "<!-- task_packet_index:managed:start -->"
MANAGED_BLOCK_END = "<!-- task_packet_index:managed:end -->"
_BLOCK_RE = re.compile(
    re.escape(MANAGED_BLOCK_START) + r"\n(.*?)\n" + re.escape(MANAGED_BLOCK_END),
    re.DOTALL,
)


class TaskPacketIndexError(RuntimeError):
    pass


def git(repo: Path, *args: str, check: bool = True) -> str:
    result = subprocess.run(["git", *args], cwd=repo, text=True, capture_output=True)
    if check and result.returncode:
        raise TaskPacketIndexError(f"git {' '.join(args)} failed: {(result.stderr or result.stdout).strip()}")
    return result.stdout.strip()


def _normalize_goal(text: str) -> str:
    normalized = header_field(text, "Goal")
    if normalized is None:
        return "(no Goal recorded)"
    if len(normalized) > 160:
        normalized = normalized[:157].rstrip() + "..."
    return normalized or "(no Goal recorded)"


def discover_ready_auto_packets(repo: Path) -> list[tuple[Path, str]]:
    """Return (path, rendered-line) pairs for every top-level Status: ready,
    Dispatch: auto packet, ordered by the same priority/path ordering
    dispatch.py uses (PRIORITY, then path)."""
    active_root = repo / PACKET_ROOT
    entries: list[tuple[Path, str]] = []
    if not active_root.is_dir():
        return entries
    active_files = [md for md in sorted(active_root.glob("*.md")) if md.name != "README.md"]
    archived_root = active_root / "archived"
    archived_files = sorted(archived_root.glob("*.md")) if archived_root.is_dir() else []
    active_texts = {md.relative_to(repo).as_posix(): md.read_text() for md in active_files}
    active_packets = [parse_packet(rel, text) for rel, text in active_texts.items()]
    archived_packets = [
        parse_packet(md.relative_to(repo).as_posix(), md.read_text()) for md in archived_files
    ]
    queue_errors = validate_queue_contract(active_packets, archived_packets, active_texts)
    for md in active_files:
        text = active_texts[md.relative_to(repo).as_posix()]
        rel = md.relative_to(repo).as_posix()
        packet = parse_packet(rel, text)
        if packet.error or packet.workstream in queue_errors or packet.status != "ready" or packet.dispatch != "auto":
            continue
        entries.append((md, packet.priority))
    entries.sort(key=lambda item: (PRIORITY.get(item[1], 9), item[0].name))
    rendered = []
    for md, _priority in entries:
        goal = _normalize_goal(md.read_text())
        rendered.append((md, f"- `{md.name}` — {goal}"))
    return rendered


def render_managed_block(repo: Path) -> str:
    lines = [line for _path, line in discover_ready_auto_packets(repo)]
    body = "\n".join(lines) if lines else "_None._"
    return f"{MANAGED_BLOCK_START}\n{body}\n{MANAGED_BLOCK_END}"


def check(repo: Path) -> tuple[bool, str]:
    """Return (up_to_date, diagnostic). Diagnostic is empty when up to date."""
    readme_path = repo / PACKET_ROOT / "README.md"
    if not readme_path.is_file():
        return False, f"{PACKET_ROOT}/README.md does not exist"
    text = readme_path.read_text()
    expected = render_managed_block(repo)
    match = _BLOCK_RE.search(text)
    if not match:
        return False, (
            "managed Ready/Auto Dispatch block not found; run with --write to "
            f"initialize it (expects markers {MANAGED_BLOCK_START} / {MANAGED_BLOCK_END})"
        )
    current_block = f"{MANAGED_BLOCK_START}\n{match.group(1)}\n{MANAGED_BLOCK_END}"
    if current_block != expected:
        return False, "managed Ready/Auto Dispatch block is stale; run with --write to repair it"
    return True, ""


def write(repo: Path) -> bool:
    """Rewrite only the managed block. Returns True if content changed."""
    readme_path = repo / PACKET_ROOT / "README.md"
    if not readme_path.is_file():
        raise TaskPacketIndexError(f"{PACKET_ROOT}/README.md does not exist")
    text = readme_path.read_text()
    expected = render_managed_block(repo)
    if _BLOCK_RE.search(text):
        new_text = _BLOCK_RE.sub(lambda _m: expected, text, count=1)
    else:
        anchor = re.search(r"(?m)^### Ready / Auto Dispatch\s*\n", text)
        if not anchor:
            raise TaskPacketIndexError("README.md has no '### Ready / Auto Dispatch' heading to attach the managed block to")
        insert_at = anchor.end()
        new_text = f"{text[:insert_at]}\n{expected}\n{text[insert_at:]}"
    if new_text == text:
        return False
    readme_path.write_text(new_text)
    return True


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--repo", type=Path, default=None)
    args = parser.parse_args(argv)
    try:
        repo = (args.repo or Path(git(Path.cwd(), "rev-parse", "--show-toplevel"))).resolve()
    except TaskPacketIndexError as error:
        print(f"task_packet_index: BLOCKED: {error}", file=sys.stderr)
        return 2
    if args.write:
        try:
            changed = write(repo)
        except TaskPacketIndexError as error:
            print(f"task_packet_index: BLOCKED: {error}", file=sys.stderr)
            return 2
        print(f"task_packet_index: {'updated' if changed else 'already up to date'}")
        return 0
    up_to_date, diagnostic = check(repo)
    if up_to_date:
        print("task_packet_index: PASS")
        return 0
    print(f"task_packet_index: FAIL: {diagnostic}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
