"""Transaction model — staged ingestion with rollback support."""

from __future__ import annotations

import json
import shutil
import sys
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path

ASSETS_DIR = Path(__file__).resolve().parent
if str(ASSETS_DIR) not in sys.path:
    sys.path.insert(0, str(ASSETS_DIR))

from asset_plan import PlannedAsset


@dataclass
class TransactionRecord:
    job_id: str
    timestamp: str
    staged_files: list[Path] = field(default_factory=list)
    created_targets: list[Path] = field(default_factory=list)
    replaced_targets: list[Path] = field(default_factory=list)
    backups: dict[Path, Path] = field(default_factory=dict)
    catalog_backup: bytes | None = None
    archived_inputs: dict[Path, Path] = field(default_factory=dict)


def new_job_id() -> str:
    ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    short = uuid.uuid4().hex[:8]
    return f"job_{ts}_{short}"


def begin_transaction(
    job_id: str,
    project_dir: Path,
    planned_assets: list[PlannedAsset],
) -> tuple[TransactionRecord, Path]:
    """Create a transaction journal and back up existing targets."""
    staging_dir = project_dir / "asset_drop" / "staging" / job_id
    staging_dir.mkdir(parents=True, exist_ok=True)

    record = TransactionRecord(
        job_id=job_id,
        timestamp=datetime.now(timezone.utc).isoformat(),
    )

    for pa in planned_assets:
        target = project_dir / pa.target_relative_path
        if target.exists() and pa.operation.value == "replace":
            backup = staging_dir / "backups" / pa.target_relative_path
            backup.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(target, backup)
            record.backups[target] = backup
            record.replaced_targets.append(target)

    catalog = project_dir / "content/metadata/assets/generated/asset_catalog.generated.json"
    if catalog.exists():
        record.catalog_backup = catalog.read_bytes()
    return record, staging_dir


def commit_transaction(record: TransactionRecord, project_dir: Path, receipt: dict) -> None:
    """Write a repo-relative unified transaction receipt."""
    log_dir = project_dir / "asset_drop" / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    log_path = log_dir / f"{record.job_id}.json"

    log_path.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    staging_dir = project_dir / "asset_drop" / "staging" / record.job_id
    if staging_dir.exists():
        shutil.rmtree(staging_dir)


def rollback_transaction(record: TransactionRecord, project_dir: Path) -> None:
    """Rollback: remove created targets, restore replaced targets from backups."""
    for target in record.created_targets:
        if target.exists():
            target.unlink()

    for target, backup in record.backups.items():
        if backup.exists():
            shutil.copy2(backup, target)

    catalog = project_dir / "content/metadata/assets/generated/asset_catalog.generated.json"
    if record.catalog_backup is not None:
        catalog.parent.mkdir(parents=True, exist_ok=True)
        catalog.write_bytes(record.catalog_backup)
    elif catalog.exists():
        catalog.unlink()

    for original, archived in record.archived_inputs.items():
        if archived.exists():
            original.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(archived), str(original))

    staging_dir = project_dir / "asset_drop" / "staging" / record.job_id
    if staging_dir.exists():
        shutil.rmtree(staging_dir)
