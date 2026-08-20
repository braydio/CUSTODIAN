"""Asset family contract model — typed representation of .asset.json files."""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

SCHEMA_VERSION = "custodian.asset_family.v1"
FAMILIES_DIR = Path(__file__).resolve().parents[2] / "content" / "metadata" / "assets" / "families"


@dataclass(frozen=True)
class AssetStateContract:
    id: str
    layer: str
    action_group: str
    variant: str
    required: bool = False
    recommended: bool = False
    animation: bool = False
    fps: float | None = None


@dataclass(frozen=True)
class AssetFamilyContract:
    id: str
    kind: str
    runtime_domain: str
    runtime_owner: str
    frame_width: int
    frame_height: int
    direction_policy: str
    states: dict[str, AssetStateContract]
    aliases: dict[str, str] = field(default_factory=dict)
    consumers: tuple[dict[str, Any], ...] = ()

    def resolve_state(self, name: str) -> tuple[str | None, str]:
        """Resolve a filename stem to a state id.

        Returns (state_id, reason). state_id is None if unresolvable.
        """
        if name in self.states:
            return name, f"exact state id '{name}'"

        if name in self.aliases:
            resolved = self.aliases[name]
            if resolved in self.states:
                return resolved, f"alias '{name}' -> '{resolved}'"

        return None, f"no state or alias for '{name}'"


def load_family(path: Path) -> AssetFamilyContract:
    """Load and validate a family contract JSON file."""
    raw = json.loads(path.read_text(encoding="utf-8"))
    return _parse_family(raw)


def load_all_families(directory: Path | None = None) -> dict[str, AssetFamilyContract]:
    """Load all family contracts from the families directory."""
    d = directory or FAMILIES_DIR
    if not d.exists():
        return {}
    result = {}
    for p in sorted(d.glob("*.asset.json")):
        fam = load_family(p)
        result[fam.id] = fam
    return result


def _parse_family(raw: dict[str, Any]) -> AssetFamilyContract:
    schema = raw.get("schema")
    if schema != SCHEMA_VERSION:
        raise ValueError(f"Unknown schema '{schema}', expected '{SCHEMA_VERSION}'")

    states_raw = raw.get("states", {})
    states: dict[str, AssetStateContract] = {}
    for sid, sdata in states_raw.items():
        states[sid] = AssetStateContract(
            id=sid,
            layer=sdata.get("layer", "body"),
            action_group=sdata.get("action_group", "interaction"),
            variant=sdata.get("variant", sid),
            required=sdata.get("required", False),
            recommended=sdata.get("recommended", False),
            animation=sdata.get("animation", False),
            fps=sdata.get("fps"),
        )

    runtime = raw.get("runtime", {})
    canvas = raw.get("canvas", {})

    return AssetFamilyContract(
        id=raw["id"],
        kind=raw.get("kind", "world_prop"),
        runtime_domain=runtime.get("domain", "sprites/props"),
        runtime_owner=runtime.get("owner", raw["id"]),
        frame_width=canvas.get("width", 128),
        frame_height=canvas.get("height", 96),
        direction_policy=raw.get("direction_policy", "omni"),
        states=states,
        aliases=raw.get("aliases", {}),
        consumers=tuple(raw.get("consumers", [])),
    )
