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
    if not isinstance(raw, dict):
        raise ValueError("family contract root must be an object")
    schema = raw.get("schema")
    if schema != SCHEMA_VERSION:
        raise ValueError(f"Unknown schema '{schema}', expected '{SCHEMA_VERSION}'")

    def required_text(container: dict, key: str, context: str) -> str:
        value = container.get(key)
        if not isinstance(value, str) or not value.strip():
            raise ValueError(f"{context}.{key} must be a non-empty string")
        return value

    family_id = required_text(raw, "id", "family")
    kind = required_text(raw, "kind", "family")
    runtime = raw.get("runtime")
    canvas = raw.get("canvas")
    if not isinstance(runtime, dict) or not isinstance(canvas, dict):
        raise ValueError("runtime and canvas must be objects")
    runtime_domain = required_text(runtime, "domain", "runtime")
    runtime_owner = required_text(runtime, "owner", "runtime")
    width, height = canvas.get("width"), canvas.get("height")
    if not isinstance(width, int) or isinstance(width, bool) or width <= 0:
        raise ValueError("canvas.width must be a positive integer")
    if not isinstance(height, int) or isinstance(height, bool) or height <= 0:
        raise ValueError("canvas.height must be a positive integer")
    direction = required_text(raw, "direction_policy", "family")
    if direction not in {"omni", "n", "ne", "e", "se", "s", "sw", "w", "nw", "4dir", "8dir"}:
        raise ValueError(f"unsupported direction_policy '{direction}'")
    states_raw = raw.get("states")
    if not isinstance(states_raw, dict) or not states_raw:
        raise ValueError("states must be a non-empty object")
    states: dict[str, AssetStateContract] = {}
    for sid, sdata in states_raw.items():
        if not isinstance(sid, str) or not sid or not isinstance(sdata, dict):
            raise ValueError("state ids must be non-empty strings and state values must be objects")
        states[sid] = AssetStateContract(
            id=sid,
            layer=required_text(sdata, "layer", f"states.{sid}"),
            action_group=required_text(sdata, "action_group", f"states.{sid}"),
            variant=required_text(sdata, "variant", f"states.{sid}"),
            required=sdata.get("required", False),
            recommended=sdata.get("recommended", False),
            animation=sdata.get("animation", False),
            fps=sdata.get("fps"),
        )

    aliases = raw.get("aliases", {})
    if not isinstance(aliases, dict):
        raise ValueError("aliases must be an object")
    for alias, target in aliases.items():
        if not isinstance(alias, str) or not alias or target not in states:
            raise ValueError(f"alias '{alias}' targets unknown state '{target}'")
    consumers = raw.get("consumers", [])
    if not isinstance(consumers, list):
        raise ValueError("consumers must be an array")
    for index, consumer in enumerate(consumers):
        if not isinstance(consumer, dict):
            raise ValueError(f"consumer {index} must be an object")
        required_text(consumer, "type", f"consumers[{index}]")
        required_text(consumer, "path", f"consumers[{index}]")

    return AssetFamilyContract(
        id=family_id, kind=kind, runtime_domain=runtime_domain, runtime_owner=runtime_owner,
        frame_width=width, frame_height=height, direction_policy=direction,
        states=states,
        aliases=aliases, consumers=tuple(consumers),
    )
