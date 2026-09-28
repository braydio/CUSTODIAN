"""Machine-backed production asset requirements and Markdown projection."""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from asset_contract import AssetFamilyContract
from asset_status import get_family_status

SCHEMA = "custodian.asset_requirements.v1"
REGISTRY_RELATIVE_PATH = "content/metadata/assets/required_assets.registry.json"
REGISTRY_DISPLAY_PATH = "custodian/content/metadata/assets/required_assets.registry.json"
FULFILLMENT_TYPES = {"audio", "tiled", "operator", "review", "manual", "asset_v2"}
DECLARED_STATUSES = {"needed", "partial", "bound", "deferred"}
MIGRATABLE_STATUSES = {"needed", "partial", "bound", "deferred", "fulfilled"}


def registry_path(project_dir: Path) -> Path:
    return project_dir / REGISTRY_RELATIVE_PATH


def markdown_path(project_dir: Path) -> Path:
    return project_dir.parent / "REQUIRED_ASSETS.md"


def load_registry(project_dir: Path) -> dict[str, Any]:
    return json.loads(registry_path(project_dir).read_text(encoding="utf-8"))


def _requirements(registry: dict[str, Any]) -> list[dict[str, Any]]:
    requirements = registry.get("requirements", [])
    return requirements if isinstance(requirements, list) else []


def validate_registry(registry: Any, families: dict[str, AssetFamilyContract]) -> list[str]:
    errors: list[str] = []
    if not isinstance(registry, dict) or registry.get("schema") != SCHEMA:
        return [f"unknown requirement schema: {registry.get('schema') if isinstance(registry, dict) else None}"]
    requirements = registry.get("requirements")
    if not isinstance(requirements, list):
        return ["requirements must be an array"]
    seen: set[str] = set()
    for index, requirement in enumerate(requirements):
        prefix = f"requirements[{index}]"
        if not isinstance(requirement, dict):
            errors.append(f"{prefix} must be an object")
            continue
        requirement_id = requirement.get("id")
        if not isinstance(requirement_id, str) or not requirement_id:
            errors.append(f"{prefix} has missing requirement ID")
        elif requirement_id in seen:
            errors.append(f"duplicate requirement ID: {requirement_id}")
        else:
            seen.add(requirement_id)
        fulfillment = requirement.get("fulfillment")
        if not isinstance(fulfillment, dict):
            errors.append(f"{prefix} has invalid fulfillment route")
            continue
        route_type = fulfillment.get("type")
        if route_type not in FULFILLMENT_TYPES:
            errors.append(f"{requirement_id or prefix}: unknown fulfillment type {route_type!r}")
            continue
        if route_type != "asset_v2":
            if fulfillment.get("status") not in DECLARED_STATUSES:
                errors.append(f"{requirement_id or prefix}: invalid declared status {fulfillment.get('status')!r}")
            continue
        targets = fulfillment.get("targets")
        if not isinstance(targets, list) or not targets:
            errors.append(f"{requirement_id or prefix}: empty Asset V2 target set")
            continue
        for target_index, target in enumerate(targets):
            target_prefix = f"{requirement_id or prefix} target {target_index + 1}"
            if not isinstance(target, dict):
                errors.append(f"{target_prefix}: target must be an object")
                continue
            family_id, state_id = target.get("family"), target.get("state")
            family = families.get(family_id) if isinstance(family_id, str) else None
            if family is None:
                errors.append(f"{target_prefix}: missing Asset V2 family {family_id!r}")
                continue
            state = family.states.get(state_id) if isinstance(state_id, str) else None
            if state is None:
                errors.append(f"{target_prefix}: missing state {state_id!r} in {family_id}")
                continue
            if "directions" in target:
                directions = target["directions"]
                if not isinstance(directions, list) or not directions or any(not isinstance(direction, str) for direction in directions):
                    errors.append(f"{target_prefix}: directions must be a non-empty string array")
                    continue
                if len(set(directions)) != len(directions):
                    errors.append(f"{target_prefix}: duplicate direction")
                for direction in directions:
                    if direction not in family.allowed_directions:
                        errors.append(f"{target_prefix}: direction {direction!r} outside {family.direction_policy} policy")
    return errors


def _target_evidence(target: dict[str, Any], families: dict[str, AssetFamilyContract], project_dir: Path) -> dict[str, Any]:
    family_id, state_id = target["family"], target["state"]
    family = families[family_id]
    family_status = get_family_status(family, project_dir)
    state_status = family_status.states[state_id]
    present = set(state_status.authored_directions) | set(state_status.mirrored_directions)
    if "directions" in target:
        missing_directions = [direction for direction in target["directions"] if direction not in present]
        satisfied = not missing_directions
    else:
        missing_directions = []
        satisfied = state_status.art_present
    return {
        "family": family_id,
        "state": state_id,
        **({"directions": list(target["directions"])} if "directions" in target else {}),
        "satisfied": satisfied,
        "missing_directions": missing_directions,
        "art_present": state_status.art_present,
        "authored_directions": list(state_status.authored_directions),
        "mirrored_directions": list(state_status.mirrored_directions),
    }


def requirement_status(requirement: dict[str, Any], families: dict[str, AssetFamilyContract], project_dir: Path) -> tuple[str, list[dict[str, Any]]]:
    fulfillment = requirement["fulfillment"]
    if fulfillment["type"] != "asset_v2":
        return fulfillment["status"], []
    targets = [_target_evidence(target, families, project_dir) for target in fulfillment["targets"]]
    satisfied_count = sum(bool(target["satisfied"]) for target in targets)
    if satisfied_count == 0:
        status = "needed"
    elif satisfied_count == len(targets):
        status = "fulfilled"
    else:
        status = "partial"
    return status, targets


def evaluate_registry(registry: dict[str, Any], families: dict[str, AssetFamilyContract], project_dir: Path) -> list[dict[str, Any]]:
    output = []
    for requirement in _requirements(registry):
        status, targets = requirement_status(requirement, families, project_dir)
        output.append({**requirement, "status": status, "targets_status": targets})
    return output


def _md_cell(value: Any) -> str:
    return str(value if value is not None else "").replace("|", "&#124;").replace("\n", "<br>")


def render_markdown(registry: dict[str, Any], families: dict[str, AssetFamilyContract], project_dir: Path) -> str:
    evaluated = evaluate_registry(registry, families, project_dir)
    lines = [
        "# REQUIRED ASSETS",
        "",
        "Generated production demand queue. Edit the registry and regenerate this file; do not edit requirement rows here.",
        "",
        f"> Source authority: `{REGISTRY_DISPLAY_PATH}`",
        "> Regenerate with: `python3 custodian/tools/assets/asset.py needs --write`",
        "",
    ]
    current_section: str | None = None
    for item in evaluated:
        if item["status"] == "fulfilled":
            continue
        section = str(item["section"])
        if section != current_section:
            if current_section is not None:
                lines.append("")
            lines.extend([f"## {section}", "", "| Status | Asset | Target Path | Purpose | Notes |", "|---|---|---|---|---|"])
            current_section = section
        lines.append("| " + " | ".join(_md_cell(value) for value in (
            item["status"], item["title"], item["target"], item["purpose"], item["notes"]
        )) + " |")
    return "\n".join(lines).rstrip() + "\n"


def check_markdown(registry: dict[str, Any], families: dict[str, AssetFamilyContract], project_dir: Path) -> bool:
    path = markdown_path(project_dir)
    return path.is_file() and path.read_text(encoding="utf-8") == render_markdown(registry, families, project_dir)


def write_markdown(registry: dict[str, Any], families: dict[str, AssetFamilyContract], project_dir: Path) -> Path:
    path = markdown_path(project_dir)
    path.write_text(render_markdown(registry, families, project_dir), encoding="utf-8", newline="\n")
    return path


def semantic_id(title: str) -> str:
    value = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")
    if not value:
        raise ValueError(f"cannot make semantic ID from title {title!r}")
    return value


def _split_markdown_row(line: str) -> list[str]:
    """Split a pipe table row while retaining literal pipes inside code spans."""
    content = line.strip().strip("|")
    cells: list[str] = []
    current: list[str] = []
    in_code = False
    for char in content:
        if char == "`":
            in_code = not in_code
        if char == "|" and not in_code:
            cells.append("".join(current).strip())
            current.clear()
        else:
            current.append(char)
    cells.append("".join(current).strip())
    return cells


def migrate_markdown(source: str) -> dict[str, Any]:
    """One-time row-preserving parser for the legacy tracker Markdown."""
    section = ""
    requirements: list[dict[str, Any]] = []
    seen: set[str] = set()
    for line_number, line in enumerate(source.splitlines(), 1):
        if line.startswith("## "):
            section = line[3:].strip()
        if not line.startswith("|"):
            continue
        cells = _split_markdown_row(line)
        if not cells or cells[0] not in MIGRATABLE_STATUSES:
            continue
        if len(cells) == 5:
            status, title, target, purpose, notes = cells
        elif len(cells) == 3:
            status, title, notes = cells
            target, purpose = title, ""
        else:
            raise ValueError(f"line {line_number}: unsupported requirement table with {len(cells)} columns")
        requirement_id = semantic_id(title)
        if requirement_id in seen:
            raise ValueError(f"line {line_number}: requirement ID collision: {requirement_id}")
        seen.add(requirement_id)
        requirements.append({
            "id": requirement_id,
            "section": section,
            "title": title,
            "target": target,
            "purpose": purpose,
            "notes": notes,
            "fulfillment": {"type": "manual", "status": status},
        })
    return {"schema": SCHEMA, "requirements": requirements}
