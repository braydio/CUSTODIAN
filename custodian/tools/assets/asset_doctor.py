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


@dataclass
class DoctorIssue:
    severity: str  # error, warning
    message: str


def run_doctor(project_dir: Path) -> list[DoctorIssue]:
    """Run health checks across all registered families."""
    issues: list[DoctorIssue] = []
    families = load_all_families()

    for fid, fam in families.items():
        _check_inbox(fam, project_dir, issues)
        _check_consumers(fam, project_dir, issues)

    _check_unprocessed_inbox(project_dir, families, issues)
    _check_catalog(project_dir, families, issues)

    return issues


def _check_catalog(project_dir: Path, families: dict[str, AssetFamilyContract], issues: list[DoctorIssue]) -> None:
    catalog = load_catalog(project_dir / "content/metadata/assets/generated/asset_catalog.generated.json")
    for family_id, family_data in catalog.get("families", {}).items():
        if family_id not in families:
            issues.append(DoctorIssue("error", f"catalog references unregistered family: {family_id}"))
            continue
        for state_id, entry in family_data.get("states", {}).items():
            if state_id not in families[family_id].states:
                issues.append(DoctorIssue("error", f"catalog references unknown state: {family_id}/{state_id}"))
                continue
            path = project_dir / str(entry.get("path", ""))
            if not path.is_file():
                issues.append(DoctorIssue("error", f"catalog output missing: {family_id}/{state_id}: {entry.get('path')}"))
            elif entry.get("sha256") != file_hash(path):
                issues.append(DoctorIssue("error", f"catalog hash mismatch: {family_id}/{state_id}: {entry.get('path')}"))


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
        if consumer.get("type") == "scene":
            rel = consumer.get("path", "")
            if rel.startswith("res://"):
                fs_path = project_dir / rel.removeprefix("res://")
                if not fs_path.exists():
                    issues.append(DoctorIssue(
                        severity="warning",
                        message=f"{fam.id}: consumer scene not found: {rel}",
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
