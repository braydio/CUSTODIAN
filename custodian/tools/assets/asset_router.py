"""Schema-driven routing — generates target runtime paths from semantic identity."""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

ASSETS_DIR = Path(__file__).resolve().parent
if str(ASSETS_DIR) not in sys.path:
    sys.path.insert(0, str(ASSETS_DIR))

from asset_contract import AssetFamilyContract, AssetStateContract
from asset_key import AssetKey
from asset_naming import canonical_filename

SCHEMAS_DIR = Path(__file__).resolve().parents[2] / "content" / "metadata" / "assets" / "schemas"


@dataclass(frozen=True)
class AssetKindSchema:
    kind: str
    runtime_template: str
    defaults: dict[str, str]


def load_kind_schemas(directory: Path | None = None) -> dict[str, AssetKindSchema]:
    """Load all kind routing schemas."""
    d = directory or SCHEMAS_DIR
    if not d.exists():
        return {}
    result: dict[str, AssetKindSchema] = {}
    for p in sorted(d.glob("*.json")):
        raw = json.loads(p.read_text(encoding="utf-8"))
        result[raw["kind"]] = AssetKindSchema(
            kind=raw["kind"],
            runtime_template=raw["runtime_template"],
            defaults=raw.get("defaults", {}),
        )
    return result


def resolve_runtime_target(
    *,
    family: AssetFamilyContract,
    state: AssetStateContract,
    key: AssetKey,
    kind_schema: AssetKindSchema | None = None,
) -> Path:
    """Compute the canonical runtime target path for a planned asset."""
    if kind_schema is None:
        raise ValueError(f"unsupported asset kind schema: {family.kind}")
    filename = canonical_filename(key)

    tmpl = kind_schema.runtime_template
    rel = tmpl.format(
            owner=key.owner,
            layer=key.layer,
            action_group=key.action_group,
            variant=key.variant,
            direction=key.direction,
            filename=filename,
    )
    return Path("content") / rel
