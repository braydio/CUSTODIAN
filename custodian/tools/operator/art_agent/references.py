from __future__ import annotations

from pathlib import Path
from typing import Any

import animation_workbench_model as model

LOCOMOTION_SIBLINGS = {"walk": "run", "run": "walk"}


def _sibling_actions(action: str) -> list[str]:
    for base, other in LOCOMOTION_SIBLINGS.items():
        if action.startswith(base):
            return [other + action[len(base):]]
    return []


def assemble(manifest: dict[str, Any], *, source_root: Path, weapon_root: Path | None = None) -> list[dict[str, Any]]:
    references: list[dict[str, Any]] = []
    seen_paths: set[str] = set()

    for binding in manifest.get("layers", []):
        source = Path(binding.get("source_contract", {}).get("path", binding.get("source_path", "")))
        if source and source.exists() and source.resolve().is_relative_to(source_root.resolve()):
            resolved = str(source.resolve())
            seen_paths.add(resolved)
            references.append({
                "identity": binding.get("semantic_identity", {}),
                "path": resolved,
                "role": "target_layer",
                "authority": "canonical_source",
                "reason": "Workbench semantic binding",
            })

    try:
        index = model.source_index(source_root, weapon_root or model.WEAPON_ROOT)
    except model.WorkbenchError:
        index = {}

    def add(hit: tuple[Path, Any], role: str, reason: str, identity: dict[str, Any]) -> None:
        path, _key = hit
        resolved = str(Path(path).resolve())
        if resolved in seen_paths:
            return
        seen_paths.add(resolved)
        references.append({"identity": identity, "path": resolved, "role": role, "authority": "canonical_source", "reason": reason})

    for binding in manifest.get("layers", []):
        identity = binding.get("semantic_identity", {})
        owner, layer, profile, group, action, direction = (
            identity.get("owner"), identity.get("layer"), identity.get("profile"),
            identity.get("group"), identity.get("action"), identity.get("direction"),
        )
        if not all((owner, layer, profile, group, action, direction)):
            continue

        if group != "posture":
            posture_hit = index.get((owner, layer, profile, "posture", "idle_ready_01", direction))
            if posture_hit:
                add(posture_hit, "posture_reference", f"same-direction idle-ready posture for {layer}", identity)

        for sibling_action in _sibling_actions(action):
            sibling_hit = index.get((owner, layer, profile, group, sibling_action, direction))
            if sibling_hit:
                add(sibling_hit, "locomotion_sibling", f"{sibling_action} sibling of {action} for {layer}", identity)

        runtime_relative = binding.get("runtime_path")
        if runtime_relative:
            runtime_path = (model.REPO_ROOT / runtime_relative).resolve()
            if runtime_path.exists():
                key = str(runtime_path)
                if key not in seen_paths:
                    seen_paths.add(key)
                    references.append({
                        "identity": identity,
                        "path": key,
                        "role": "runtime_composite",
                        "authority": "runtime_reference",
                        "reason": f"current runtime composite for {layer}",
                    })

    return references
