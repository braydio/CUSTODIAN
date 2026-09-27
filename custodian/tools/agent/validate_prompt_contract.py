#!/usr/bin/env python3
"""Find repository-default boilerplate repeated in prompts and task packets."""
from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
AI_CONTEXT = ROOT / "custodian/docs/ai_context"
PROMPTS = AI_CONTEXT / "prompts"
PACKET_TEMPLATE = AI_CONTEXT / "AGENT_TASK_PACKET_TEMPLATE.md"
TASK_PACKETS = AI_CONTEXT / "task_packets"


@dataclass(frozen=True)
class Rule:
    label: str
    pattern: re.Pattern[str]


RULES = (
    Rule("read-order boilerplate", re.compile(r"^\s*(?:Then )?read `?custodian/AGENTS\.md` first\.?\s*$", re.I)),
    Rule("fixed-step default", re.compile(r"^\s*[-*]?\s*Preserve deterministic fixed-step simulation\.?\s*$", re.I)),
    Rule("simulation/presentation default", re.compile(r"^\s*[-*]?\s*Keep rendering/UI separate from simulation authority\.?\s*$", re.I)),
    Rule("task-packet default", re.compile(r"^\s*[-*]?\s*Create or update a compact task packet when .*\.?\s*$", re.I)),
    Rule("current-state checklist default", re.compile(r"^\s*[-*]?\s*Update `?CURRENT_STATE\.md` if behavior changes\.?\s*$", re.I)),
    Rule("file-index checklist default", re.compile(r"^\s*[-*]?\s*Update `?FILE_INDEX\.md` if ownership or entrypoints change\.?\s*$", re.I)),
    Rule("validation recipe default", re.compile(r"^\s*[-*]?\s*Follow `?custodian/docs/ai_context/VALIDATION_RECIPES\.md`\.?\s*$", re.I)),
    Rule("implicit commit approval override", re.compile(r"^\s*[-*]?\s*Do not stage, commit, stash, reset, or delete .*without explicit user approval\.?\s*$", re.I)),
)


def violations(text: str) -> list[tuple[int, str, str]]:
    found: list[tuple[int, str, str]] = []
    for line_number, line in enumerate(text.splitlines(), start=1):
        if line.lstrip().startswith("TASK OVERRIDE:"):
            continue
        for rule in RULES:
            if rule.pattern.match(line):
                found.append((line_number, rule.label, line.strip()))
    return found


def input_files(templates_only: bool) -> list[Path]:
    paths = [path for path in sorted(PROMPTS.glob("*.md")) if path.name != "README.md"]
    paths.append(PACKET_TEMPLATE)
    if not templates_only:
        paths.extend(
            path for path in sorted(TASK_PACKETS.rglob("*.md"))
            if "archived" not in path.relative_to(TASK_PACKETS).parts
        )
    return paths


def self_test() -> bool:
    cases = [
        ("- Preserve deterministic fixed-step simulation.", True),
        ("TASK OVERRIDE: Preserve deterministic fixed-step simulation for this migration.", False),
        ("Vigil Fast 03 remains 9f at 13 FPS with a 1.5s duration.", False),
        ("Follow `custodian/docs/ai_context/VALIDATION_RECIPES.md`.", True),
    ]
    for source, should_flag in cases:
        actual = bool(violations(source))
        if actual != should_flag:
            print(f"SELF-TEST FAIL: {source!r}: expected flagged={should_flag}, got {actual}")
            return False
    print("PASS prompt contract linter self-test")
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--templates-only", action="store_true", help="scan reusable prompts and the packet template")
    parser.add_argument("--strict", action="store_true", help="return failure when any repeated default is found")
    parser.add_argument("--self-test", action="store_true", help="check rule detection and TASK OVERRIDE handling")
    args = parser.parse_args()

    if args.self_test and not self_test():
        return 1

    total = 0
    for path in input_files(args.templates_only):
        try:
            text = path.read_text(encoding="utf-8")
        except OSError as error:
            print(f"ERROR {path.relative_to(ROOT)}: {error}")
            total += 1
            continue
        for line_number, label, excerpt in violations(text):
            total += 1
            print(f"{path.relative_to(ROOT)}:{line_number}: {label}: {excerpt}")

    scope = "templates" if args.templates_only else "templates and active task packets"
    print(f"Prompt contract: {total} repeated default(s) found in {scope}.")
    if args.strict and total:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
