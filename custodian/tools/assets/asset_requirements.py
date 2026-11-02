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
DECLARED_STATUSES = {"needed", "partial", "bound", "deferred", "fulfilled"}
REQUIREMENT_ID = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


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
    sections: set[str] = set()
    for index, requirement in enumerate(requirements):
        prefix = f"requirements[{index}]"
        if not isinstance(requirement, dict):
            errors.append(f"{prefix} must be an object")
            continue
        requirement_id = requirement.get("id")
        if not isinstance(requirement_id, str) or not requirement_id.strip():
            errors.append(f"{prefix}.id must be a non-empty kebab-case string")
            requirement_id = None
        elif not REQUIREMENT_ID.fullmatch(requirement_id):
            errors.append(f"{prefix}.id must be a non-empty kebab-case string")
        elif requirement_id in seen:
            errors.append(f"duplicate requirement ID: {requirement_id}")
        else:
            seen.add(requirement_id)
        section = requirement.get("section")
        if not isinstance(section, str) or not section.strip():
            errors.append(f"{requirement_id or prefix}.section must be a non-empty string")
        else:
            sections.add(section)
        title = requirement.get("title")
        if not isinstance(title, str) or not title.strip():
            errors.append(f"{requirement_id or prefix}.title must be a non-empty string")
        for field in ("target", "purpose", "notes"):
            if not isinstance(requirement.get(field), str):
                errors.append(f"{requirement_id or prefix}.{field} must be a string")
        fulfillment = requirement.get("fulfillment")
        if not isinstance(fulfillment, dict):
            errors.append(f"{prefix} has invalid fulfillment route")
            continue
        route_type = fulfillment.get("type")
        if not isinstance(route_type, str) or route_type not in FULFILLMENT_TYPES:
            errors.append(f"{requirement_id or prefix}: unknown fulfillment type {route_type!r}")
            continue
        if route_type != "asset_v2":
            declared_status = fulfillment.get("status")
            if not isinstance(declared_status, str) or declared_status not in DECLARED_STATUSES:
                errors.append(f"{requirement_id or prefix}: invalid declared status {declared_status!r}")
            continue
        targets = fulfillment.get("targets")
        if not isinstance(targets, list) or not targets:
            errors.append(f"{requirement_id or prefix}: empty Asset V2 target set")
            continue
        normalized_targets: set[tuple[Any, ...]] = set()
        for target_index, target in enumerate(targets):
            target_prefix = f"{requirement_id or prefix} target {target_index + 1}"
            if not isinstance(target, dict):
                errors.append(f"{target_prefix}: target must be an object")
                continue
            family_id, state_id, scope = target.get("family"), target.get("state"), target.get("scope")
            if not isinstance(family_id, str) or not family_id:
                errors.append(f"{target_prefix}: family must be a non-empty string")
                continue
            state_selected = "state" in target
            scope_selected = "scope" in target
            if state_selected == scope_selected:
                errors.append(f"{target_prefix}: specify exactly one of state or scope")
                continue
            allowed_keys = {"family", "state", "scope", "directions"}
            unknown_keys = set(target) - allowed_keys
            if unknown_keys:
                errors.append(f"{target_prefix}: unknown target fields {sorted(unknown_keys, key=str)}")
                continue
            if scope is not None and "directions" in target:
                errors.append(f"{target_prefix}: directions are only valid with an explicit state")
                continue
            if state_selected and (not isinstance(state_id, str) or not state_id):
                errors.append(f"{target_prefix}: state must be a non-empty string")
                continue
            if scope_selected and (not isinstance(scope, str) or not scope):
                errors.append(f"{target_prefix}: scope must be a non-empty string")
                continue
            selector = ("state", state_id) if state_id is not None else ("scope", scope)
            raw_directions = target.get("directions", [])
            directions_key = tuple(sorted(value for value in raw_directions if isinstance(value, str))) if isinstance(raw_directions, list) else ("<invalid>",)
            normalized = (family_id, *selector, directions_key)
            if normalized in normalized_targets:
                errors.append(f"{target_prefix}: duplicate normalized Asset V2 target")
            normalized_targets.add(normalized)
            family = families.get(family_id) if isinstance(family_id, str) else None
            if family is None:
                errors.append(f"{target_prefix}: missing Asset V2 family {family_id!r}")
                continue
            if scope is not None:
                if scope != "required_states":
                    errors.append(f"{target_prefix}: unsupported scope {scope!r}")
                elif not any(state.required for state in family.states.values()):
                    errors.append(f"{target_prefix}: family {family_id} has no required states for scope required_states")
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
    section_notes = registry.get("section_notes", {})
    if not isinstance(section_notes, dict):
        errors.append("section_notes must be an object mapping sections to strings")
    else:
        for section, note in section_notes.items():
            if not isinstance(section, str) or section not in sections:
                errors.append(f"section_notes names unknown registry section: {section!r}")
            if not isinstance(note, str):
                errors.append(f"section_notes[{section!r}] must be a string")
    return errors


def _target_evidence(target: dict[str, Any], families: dict[str, AssetFamilyContract], project_dir: Path, status_cache: dict[str, Any]) -> dict[str, Any]:
    family_id = target["family"]
    family = families[family_id]
    if family_id not in status_cache:
        status_cache[family_id] = get_family_status(family, project_dir)
    family_status = status_cache[family_id]
    if target.get("scope") == "required_states":
        required_states = [state_id for state_id, state in family.states.items() if state.required]
        satisfied_states = [state_id for state_id in required_states if family_status.states[state_id].art_present]
        missing_states = [state_id for state_id in required_states if not family_status.states[state_id].art_present]
        source_pending_states = [state_id for state_id in missing_states if family_status.states[state_id].source_pending]
        return {
            "family": family_id,
            "scope": "required_states",
            "required_states": required_states,
            "satisfied_states": satisfied_states,
            "missing_states": missing_states,
            "source_pending_states": source_pending_states,
            "source_pending": bool(source_pending_states),
            "satisfied": not missing_states,
            "missing_directions": [],
        }
    state_id = target["state"]
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
        "source_pending": state_status.source_pending,
        "missing_directions": missing_directions,
        "art_present": state_status.art_present,
        "authored_directions": list(state_status.authored_directions),
        "mirrored_directions": list(state_status.mirrored_directions),
    }


def requirement_status(requirement: dict[str, Any], families: dict[str, AssetFamilyContract], project_dir: Path, status_cache: dict[str, Any] | None = None) -> tuple[str, list[dict[str, Any]]]:
    fulfillment = requirement["fulfillment"]
    if fulfillment["type"] != "asset_v2":
        return fulfillment["status"], []
    cache = status_cache if status_cache is not None else {}
    targets = [_target_evidence(target, families, project_dir, cache) for target in fulfillment["targets"]]
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
    status_cache: dict[str, Any] = {}
    for requirement in _requirements(registry):
        status, targets = requirement_status(requirement, families, project_dir, status_cache)
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
    section_notes = registry.get("section_notes", {})
    for item in evaluated:
        if item["status"] == "fulfilled":
            continue
        section = str(item["section"])
        if section != current_section:
            if current_section is not None:
                lines.append("")
            lines.append(f"## {section}")
            note = section_notes.get(section) if isinstance(section_notes, dict) else None
            if note:
                lines.extend(["", note])
            lines.extend(["", "| Status | Asset | Target Path | Purpose | Notes |", "|---|---|---|---|---|"])
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
