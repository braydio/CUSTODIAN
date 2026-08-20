"""Truthful source, runtime-art, import, consumer-binding, and verification status."""
from __future__ import annotations
import json
import sys
from dataclasses import dataclass
from pathlib import Path

ASSETS_DIR = Path(__file__).resolve().parent
if str(ASSETS_DIR) not in sys.path:
    sys.path.insert(0, str(ASSETS_DIR))

from asset_catalog import file_hash, load_catalog
from asset_contract import AssetFamilyContract


@dataclass(frozen=True)
class StateStatus:
    state_id: str
    source_pending: bool
    art_present: bool
    imported: bool
    bound: bool
    runtime_verified: bool
    runtime_path: str | None


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
    states: dict[str, StateStatus]


def get_family_status(family: AssetFamilyContract, project_dir: Path) -> FamilyStatus:
    inbox = project_dir / "asset_drop/inbox" / family.id
    inbox_files = sorted(p.name for p in inbox.glob("*.png")) if inbox.exists() else []
    pending_states = {resolved for name in inbox_files
                      if (resolved := family.resolve_state(Path(name).stem)[0]) is not None}
    catalog = load_catalog(project_dir / "content/metadata/assets/generated/asset_catalog.generated.json")
    entries = catalog.get("families", {}).get(family.id, {}).get("states", {})
    statuses: dict[str, StateStatus] = {}
    runtime_outputs: list[str] = []
    for sid in family.states:
        entry = entries.get(sid, {})
        rel = entry.get("path") if isinstance(entry, dict) else None
        output = project_dir / rel if rel else None
        art = bool(output and output.is_file() and entry.get("sha256") == file_hash(output))
        if art:
            runtime_outputs.append(rel)
        imported = bool(art and output.with_name(output.name + ".import").exists())
        expected_res = "res://" + rel if rel else None
        bound = art and _is_bound(family.consumers, project_dir, expected_res)
        # Runtime verification needs explicit validation evidence; V1 records none.
        statuses[sid] = StateStatus(sid, sid in pending_states, art, imported, bound, False, rel)

    def group(predicate):
        return [(sid, statuses[sid].art_present) for sid, state in family.states.items() if predicate(state)]
    required = group(lambda state: state.required)
    recommended = group(lambda state: not state.required and state.recommended)
    optional = group(lambda state: not state.required and not state.recommended)
    done = sum(present for _, present in required)
    return FamilyStatus(family.id, required, recommended, optional, inbox.exists(), inbox_files,
                        sorted(runtime_outputs), list(family.consumers), f"{done}/{len(required)} required", statuses)


def _is_bound(consumers: tuple[dict, ...], project_dir: Path, expected_res: str | None) -> bool:
    if not expected_res:
        return False
    for consumer in consumers:
        if consumer.get("type") != "scene":
            continue
        path = str(consumer.get("path", ""))
        if not path.startswith("res://"):
            continue
        scene = project_dir / path.removeprefix("res://")
        if scene.is_file() and expected_res in scene.read_text(encoding="utf-8"):
            return True
    return False
