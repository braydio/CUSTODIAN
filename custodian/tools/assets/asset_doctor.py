"""Doctor — health checks for family contracts, catalog, and inbox integrity."""

from __future__ import annotations

import sys
from dataclasses import dataclass
from pathlib import Path

ASSETS_DIR = Path(__file__).resolve().parent
if str(ASSETS_DIR) not in sys.path:
    sys.path.insert(0, str(ASSETS_DIR))

from asset_contract import AssetFamilyContract, load_all_families
from asset_inspector import inspect_png
from asset_classifier import classify_input
from asset_catalog import file_hash, load_catalog
from asset_plan import generate_plan
from asset_router import load_kind_schemas


@dataclass
class DoctorIssue:
    severity: str  # error, warning
    message: str


def run_doctor(project_dir: Path) -> list[DoctorIssue]:
    """Run health checks across all registered families."""
    issues: list[DoctorIssue] = []
    try:
        schemas = load_kind_schemas(project_dir / "content/metadata/assets/schemas")
        families = load_all_families(project_dir / "content/metadata/assets/families")
    except (ValueError, OSError) as exc:
        return [DoctorIssue("error", f"contract/schema load failed: {exc}")]

    for fid, fam in families.items():
        if fam.kind not in schemas:
            issues.append(DoctorIssue("error", f"{fid}: unknown kind schema '{fam.kind}'"))
            continue
        _check_inbox(fam, project_dir, issues)
        _check_consumers(fam, project_dir, issues)
        plan = generate_plan(fam, project_dir / "asset_drop/inbox" / fid, project_dir, kind_schemas=schemas)
        for error in plan.errors:
            if "duplicate semantic output" in error:
                issues.append(DoctorIssue("error", f"{fid}: {error}"))

    _check_unprocessed_inbox(project_dir, families, issues)
    _check_catalog(project_dir, families, issues)

    return issues


def _check_catalog(project_dir: Path, families: dict[str, AssetFamilyContract], issues: list[DoctorIssue]) -> None:
    catalog = load_catalog(project_dir / "content/metadata/assets/generated/asset_catalog.generated.json")
    for family_id, family_data in catalog.get("families", {}).items():
        if family_id not in families:
            issues.append(DoctorIssue("error", f"catalog references unregistered family: {family_id}"))
            continue
        seen: set[str] = set()
        for asset_id, entry in family_data.get("assets", {}).items():
            state_id = str(entry.get("state_id", ""))
            if asset_id in seen:
                issues.append(DoctorIssue("error", f"duplicate catalog asset key: {family_id}/{asset_id}"))
            seen.add(asset_id)
            if state_id not in families[family_id].states:
                issues.append(DoctorIssue("error", f"catalog references unknown state: {family_id}/{asset_id}"))
                continue
            path = project_dir / str(entry.get("path", ""))
            if not path.is_file():
                issues.append(DoctorIssue("error", f"catalog output missing: {family_id}/{asset_id}: {entry.get('path')}"))
            elif entry.get("sha256") != file_hash(path):
                issues.append(DoctorIssue("error", f"catalog hash mismatch: {family_id}/{asset_id}: {entry.get('path')}"))
            elif str(entry.get("path", "")).endswith(".png") and not path.with_name(path.name + ".import").exists():
                issues.append(DoctorIssue("warning", f"catalog PNG lacks Godot import sidecar: {family_id}/{asset_id}"))


def _check_inbox(fam: AssetFamilyContract, project_dir: Path, issues: list[DoctorIssue]) -> None:
    inbox = project_dir / "asset_drop" / "inbox" / fam.id
    if not inbox.exists():
        return

    for png in inbox.glob("*.png"):
        from asset_inspector import inspect_png
        insp = inspect_png(png, fam.frame_width, fam.frame_height)
        from asset_classifier import classify_input
        res = classify_input(fam, png.stem, insp)
        if res.confidence.value == "ambiguous":
            issues.append(DoctorIssue(
                severity="warning",
                message=f"{fam.id}/{png.name}: ambiguous classification — {res.reason}",
            ))


def _check_consumers(fam: AssetFamilyContract, project_dir: Path, issues: list[DoctorIssue]) -> None:
    for consumer in fam.consumers:
        rel = consumer.get("path", "")
        if rel.startswith("res://"):
            fs_path = project_dir / rel.removeprefix("res://")
            if not fs_path.exists():
                issues.append(DoctorIssue(
                    severity="warning",
                    message=f"{fam.id}: consumer not found: {rel}",
                ))


def _check_unprocessed_inbox(
    project_dir: Path,
    families: dict[str, AssetFamilyContract],
    issues: list[DoctorIssue],
) -> None:
    inbox_root = project_dir / "asset_drop" / "inbox"
    if not inbox_root.exists():
        return

    for child in sorted(inbox_root.iterdir()):
        if child.is_dir() and child.name not in families:
            pngs = list(child.glob("*.png"))
            if pngs:
                issues.append(DoctorIssue(
                    severity="warning",
                    message=f"unregistered inbox family: {child.name} ({len(pngs)} PNGs)",
                ))
