"""Generated asset catalog — tooling metadata, not gameplay authority."""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from pathlib import Path

CATALOG_PATH = Path(__file__).resolve().parents[2] / "content" / "metadata" / "assets" / "generated" / "asset_catalog.generated.json"


@dataclass
class CatalogEntry:
    semantic_identity: list[str]
    path: str
    frames: int
    frame_size: list[int]
    sha256: str


def load_catalog(path: Path | None = None) -> dict:
    p = path or CATALOG_PATH
    if not p.exists():
        return {"schema": "custodian.asset_catalog.v1", "families": {}}
    return json.loads(p.read_text(encoding="utf-8"))


def save_catalog(catalog: dict, path: Path | None = None) -> None:
    p = path or CATALOG_PATH
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")


def update_catalog_entry(
    catalog: dict,
    family_id: str,
    state_id: str,
    entry: CatalogEntry,
) -> None:
    families = catalog.setdefault("families", {})
    fam = families.setdefault(family_id, {"states": {}})
    fam["states"][state_id] = {
        "semantic_identity": entry.semantic_identity,
        "path": entry.path,
        "frames": entry.frames,
        "frame_size": entry.frame_size,
        "sha256": entry.sha256,
    }


def file_hash(path: Path) -> str:
    h = hashlib.sha256()
    h.update(path.read_bytes())
    return h.hexdigest()
