"""State resolution and classification — deterministic inbox filename interpretation."""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum

import sys
from pathlib import Path
ASSETS_DIR = Path(__file__).resolve().parent
if str(ASSETS_DIR) not in sys.path:
    sys.path.insert(0, str(ASSETS_DIR))

from asset_contract import AssetFamilyContract
from asset_inspector import AssetInspection, FrameLayout


class ResolutionConfidence(str, Enum):
    EXACT = "exact"
    INFERRED = "inferred"
    AMBIGUOUS = "ambiguous"


@dataclass(frozen=True)
class AssetResolution:
    family_id: str
    state_id: str | None
    confidence: ResolutionConfidence
    reason: str
    inspection: AssetInspection


def classify_input(
    family: AssetFamilyContract,
    filename_stem: str,
    inspection: AssetInspection,
) -> AssetResolution:
    """Classify an inbox input against a known family contract.

    Deterministic. No fuzzy matching.
    """
    state_id, reason = family.resolve_state(filename_stem)

    if state_id is not None:
        if inspection.layout == FrameLayout.AMBIGUOUS:
            return AssetResolution(
                family_id=family.id,
                state_id=state_id,
                confidence=ResolutionConfidence.AMBIGUOUS,
                reason=f"state resolved ({reason}) but image layout is ambiguous",
                inspection=inspection,
            )
        return AssetResolution(
            family_id=family.id,
            state_id=state_id,
            confidence=ResolutionConfidence.EXACT,
            reason=reason,
            inspection=inspection,
        )

    return AssetResolution(
        family_id=family.id,
        state_id=None,
        confidence=ResolutionConfidence.AMBIGUOUS,
        reason=reason,
        inspection=inspection,
    )
