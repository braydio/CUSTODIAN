from __future__ import annotations

from pathlib import Path

import animation_workbench_model as model


def require_under(root: Path, candidate: Path, *, label: str, must_exist: bool = True) -> Path:
    root = Path(root).resolve()
    try:
        candidate = Path(candidate).resolve(strict=must_exist)
        candidate.relative_to(root)
    except (OSError, ValueError) as error:
        raise model.WorkbenchError(f"{label} escapes authorized root: {candidate}") from error
    return candidate


def require_output_under(root: Path, candidate: Path, *, label: str) -> Path:
    parent = require_under(Path(root), Path(candidate).parent, label=label)
    return parent / Path(candidate).name
