from __future__ import annotations

import hashlib
import json
import re
from dataclasses import asdict
from typing import Any

from .models import SpriteImportContract, SpriteImportError, canonical_json

_SHA256 = re.compile(r"^[0-9a-f]{64}$")


def _digest(value: Any) -> str:
    return hashlib.sha256(canonical_json(value).encode("utf-8")).hexdigest()


def contract_from_asset_family(
    family: Any,
    *,
    state_id: str,
    direction: str,
    frame_count: int | None = None,
    source_cell: tuple[int, int],
    layout: str | None = None,
    grid: tuple[int, int] | None = None,
    alpha_policy: str,
    resampler: str,
    anchor: str,
) -> SpriteImportContract:
    """Adapt one resolved V1/V2 family state without filename inference."""
    canonical_state, resolution = family.resolve_state(state_id)
    if canonical_state is None:
        raise SpriteImportError(f"unknown family state {state_id!r}: {resolution}")
    state = family.states[canonical_state]
    if direction not in family.allowed_directions:
        raise SpriteImportError(f"direction {direction!r} is not allowed for family {family.id!r}")
    frames = frame_count if frame_count is not None else state.expected_frames
    if frames is None:
        raise SpriteImportError("family state has no exact frame count; supply frame_count explicitly")
    selected_layout = layout or state.layout
    if selected_layout == "auto":
        raise SpriteImportError("family layout is ambiguous; declare exact layout and grid geometry")
    if selected_layout == "copy":
        if frames != 1:
            raise SpriteImportError("copy state must have one frame")
        selected_layout, columns, rows = "single_image", 1, 1
    elif selected_layout == "horizontal_strip":
        columns, rows = frames, 1
    elif selected_layout == "vertical_strip":
        columns, rows = 1, frames
    elif selected_layout == "grid":
        columns, rows = grid if grid is not None else (state.columns, state.rows)
        if columns is None or rows is None:
            raise SpriteImportError("grid family state requires explicit columns and rows")
    else:
        raise SpriteImportError(f"unsupported family layout: {selected_layout!r}")
    family_contract = {
        "schema": family.schema, "id": family.id, "kind": family.kind,
        "runtime_domain": family.runtime_domain, "runtime_owner": family.runtime_owner,
        "canvas": [family.frame_width, family.frame_height], "direction_policy": family.direction_policy,
        "state": asdict(state), "direction": direction,
    }
    return SpriteImportContract(
        semantic_identity={"kind": "asset_family", "family": family.id,
                          "state": canonical_state, "direction": direction},
        contract_sha256=_digest(family_contract), frame_count=frames, columns=columns, rows=rows,
        source_cell_width=source_cell[0], source_cell_height=source_cell[1],
        target_width=state.frame_width or family.frame_width,
        target_height=state.frame_height or family.frame_height,
        layout=selected_layout, alpha_policy=alpha_policy, resampler=resampler, anchor=anchor,
    )


def contract_from_operator_profile(
    profile_document: dict[str, Any],
    *,
    profile_id: str,
    frame_count: int,
    columns: int,
    rows: int,
    source_cell: tuple[int, int],
    layout: str,
    target_size: tuple[int, int],
) -> SpriteImportContract:
    """Adapt one explicit accepted Operator profile; production stays on pixelart."""
    profiles = profile_document.get("profiles")
    profile = profiles.get(profile_id) if isinstance(profiles, dict) else None
    if not isinstance(profile, dict) or profile.get("id", profile_id) != profile_id:
        raise SpriteImportError(f"unknown Operator profile {profile_id!r}")
    if profile.get("status") != "accepted":
        raise SpriteImportError(f"Operator profile {profile_id!r} is not accepted")
    digest = profile.get("profile_sha256")
    if not isinstance(digest, str) or not _SHA256.fullmatch(digest):
        raise SpriteImportError("Operator profile has no valid content digest")
    registration = profile.get("registration")
    if not isinstance(registration, dict) or registration.get("status") != "accepted":
        raise SpriteImportError("Operator profile has no accepted registration geometry")
    if registration.get("frame_size") != list(target_size):
        raise SpriteImportError("target dimensions do not match the accepted Operator profile")
    anchor_xy = registration.get("anchor")
    if not isinstance(anchor_xy, list) or len(anchor_xy) != 2:
        raise SpriteImportError("accepted Operator profile has no explicit anchor")
    return SpriteImportContract(
        semantic_identity={"kind": "operator_profile", "profile": profile_id},
        contract_sha256=digest, frame_count=frame_count, columns=columns, rows=rows,
        source_cell_width=source_cell[0], source_cell_height=source_cell[1],
        target_width=target_size[0], target_height=target_size[1],
        layout=layout, alpha_policy="pixel_crisp", resampler="nearest", anchor="feet",
    )
