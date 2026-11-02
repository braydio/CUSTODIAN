#!/usr/bin/env python3
"""Rank Moment Forge scenarios for changed repository files."""

from __future__ import annotations

import fnmatch
import json
import subprocess
from pathlib import Path
from typing import Iterable


ITERATION_DIR = Path(__file__).resolve().parent
REPO_ROOT = ITERATION_DIR.parents[2]
ROUTES_PATH = ITERATION_DIR / "changed_file_routes.json"
DEFAULT_EXCLUDES = ("reports/**", "custodian/.godot/**", "**/*.import", ".ai/**", "tmp/**")


def _git_lines(arguments: list[str], repo_root: Path) -> list[str]:
    completed = subprocess.run(
        ["git", *arguments],
        cwd=repo_root,
        check=False,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        raise RuntimeError(completed.stderr.strip() or "git changed-file query failed")
    return [line.strip().replace("\\", "/") for line in completed.stdout.splitlines() if line.strip()]


def changed_files(base: str | None = None, repo_root: Path = REPO_ROOT) -> list[str]:
    found: set[str] = set()
    if base:
        found.update(_git_lines(["diff", "--name-only", f"{base}...HEAD"], repo_root))
    found.update(_git_lines(["diff", "--name-only"], repo_root))
    found.update(_git_lines(["diff", "--cached", "--name-only"], repo_root))
    found.update(_git_lines(["ls-files", "--others", "--exclude-standard"], repo_root))
    return sorted(found)


def load_rules(path: Path = ROUTES_PATH) -> list[dict]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if payload.get("schema_version") != 1 or not isinstance(payload.get("rules"), list):
        raise ValueError(f"unsupported changed-file route document: {path}")
    return payload["rules"]


def _matches(path: str, patterns: Iterable[str]) -> bool:
    return any(fnmatch.fnmatchcase(path, pattern) for pattern in patterns)


def _specificity(patterns: Iterable[str]) -> int:
    return max((len(pattern.replace("*", "").replace("?", "")) for pattern in patterns), default=0)


def route_files(
    files: Iterable[str],
    rules: list[dict] | None = None,
) -> list[dict]:
    resolved_rules = rules if rules is not None else load_rules()
    matches: list[dict] = []
    for rule in resolved_rules:
        include = [str(value) for value in rule.get("include", [])]
        exclude = [str(value) for value in rule.get("exclude", DEFAULT_EXCLUDES)]
        matched_files = []
        for raw_path in files:
            path = raw_path.replace("\\", "/")
            if _matches(path, DEFAULT_EXCLUDES) and not _matches(path, include):
                continue
            if include and _matches(path, include) and not _matches(path, exclude):
                matched_files.append(path)
        if matched_files:
            matches.append(
                {
                    "id": str(rule.get("id", "")),
                    "tags": [str(tag) for tag in rule.get("tags", [])],
                    "scenario_ids": [str(item) for item in rule.get("scenario_ids", [])],
                    "priority": int(rule.get("priority", 0)),
                    "reason": str(rule.get("reason", rule.get("id", "matched route"))),
                    "specificity": _specificity(include),
                    "files": sorted(set(matched_files)),
                }
            )
    return matches


def suggest_scenarios(
    scenarios: Iterable[dict],
    files: Iterable[str],
    rules: list[dict] | None = None,
) -> list[dict]:
    scenario_list = list(scenarios)
    score_by_id: dict[str, int] = {}
    reasons_by_id: dict[str, set[str]] = {}
    files_by_id: dict[str, set[str]] = {}
    for route in route_files(files, rules):
        explicit = set(route["scenario_ids"])
        tags = set(route["tags"])
        for scenario in scenario_list:
            scenario_id = str(scenario.get("id", ""))
            tag_match = tags.intersection(str(tag) for tag in scenario.get("tags", []))
            if scenario_id not in explicit and not tag_match:
                continue
            score = route["priority"] + min(route["specificity"], 50)
            if scenario_id in explicit:
                score += 100
            score_by_id[scenario_id] = score_by_id.get(scenario_id, 0) + score
            reasons_by_id.setdefault(scenario_id, set()).add(route["reason"])
            files_by_id.setdefault(scenario_id, set()).update(route["files"])
    return sorted(
        (
            {
                "id": scenario_id,
                "score": score,
                "reasons": sorted(reasons_by_id.get(scenario_id, set())),
                "matched_files": sorted(files_by_id.get(scenario_id, set())),
            }
            for scenario_id, score in score_by_id.items()
        ),
        key=lambda item: (-item["score"], item["id"]),
    )


if __name__ == "__main__":
    from run_moment import load_scenarios

    files = changed_files()
    print(json.dumps({"changed": files, "suggestions": suggest_scenarios(load_scenarios().values(), files)}, indent=2))
