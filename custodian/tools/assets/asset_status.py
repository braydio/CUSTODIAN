"""Status reporting — production completeness and consumer awareness."""

from __future__ import annotations

import sys
from dataclasses import dataclass
from pathlib import Path

ASSETS_DIR = Path(__file__).resolve().parent
if str(ASSETS_DIR) not in sys.path:
    sys.path.insert(0, str(ASSETS_DIR))

from asset_contract import AssetFamilyContract, load_all_families


@dataclass
class FamilyStatus:
    family_id: str
    required_states: list[tuple[str, bool]]
    recommended_states: list[tuple[str, bool]]
    optional_states: list[tuple[str, bool]]
    inbox_exists: bool
    inbox_files: list[str]
    runtime_outputs: list[str]
    consumers: list[dict]
    completeness: str


def get_family_status(
    family: AssetFamilyContract,
    project_dir: Path,
) -> FamilyStatus:
    """Get status for a single family."""
    inbox = project_dir / "asset_drop" / "inbox" / family.id
    inbox_exists = inbox.exists()
    inbox_files = sorted(p.name for p in inbox.glob("*.png")) if inbox_exists else []

    runtime_dir = (
        project_dir / "content" / family.runtime_domain / family.runtime_owner / "runtime"
    )
    runtime_outputs = sorted(
        str(p.relative_to(project_dir / "content"))
        for p in runtime_dir.rglob("*.png")
    ) if runtime_dir.exists() else []

    required = []
    recommended = []
    optional = []
    for sid, state in family.states.items():
        present = sid in [f.stem for f in (inbox.glob("*.png") if inbox_exists else [])]
        entry = (sid, present)
        if state.required:
            required.append(entry)
        elif state.recommended:
            recommended.append(entry)
        else:
            optional.append(entry)

    req_done = sum(1 for _, p in required if p)
    req_total = len(required)
    completeness = f"{req_done}/{req_total} required"

    return FamilyStatus(
        family_id=family.id,
        required_states=required,
        recommended_states=recommended,
        optional_states=optional,
        inbox_exists=inbox_exists,
        inbox_files=inbox_files,
        runtime_outputs=runtime_outputs,
        consumers=list(family.consumers),
        completeness=completeness,
    )
