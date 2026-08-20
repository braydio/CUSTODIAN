"""Exact friendly/canonical input classification."""
from __future__ import annotations
from dataclasses import dataclass
from enum import Enum
from asset_contract import AssetFamilyContract
from asset_inspector import AssetInspection,FrameLayout
from asset_naming import parse_canonical_filename
class ResolutionConfidence(str,Enum): EXACT="exact"; INFERRED="inferred"; AMBIGUOUS="ambiguous"
@dataclass(frozen=True)
class AssetResolution:
    family_id:str; state_id:str|None; direction:str|None; confidence:ResolutionConfidence; reason:str; inspection:AssetInspection
def classify_input(family:AssetFamilyContract,filename_stem:str,inspection:AssetInspection)->AssetResolution:
    try: canonical=parse_canonical_filename(filename_stem+".png",family.kind)
    except (ValueError,TypeError): canonical=None
    if canonical is not None:
        matches=[sid for sid,state in family.states.items() if (state.layer,state.action_group,state.variant)==(canonical.layer,canonical.action_group,canonical.variant)]
        valid=len(matches)==1 and canonical.owner==family.runtime_owner and canonical.direction in family.allowed_directions and canonical.frames==inspection.frame_count and (canonical.frame_width,canonical.frame_height)==(inspection.frame_width,inspection.frame_height)
        if valid: return AssetResolution(family.id,matches[0],canonical.direction,ResolutionConfidence.EXACT,"validated canonical filename",inspection)
        return AssetResolution(family.id,None,None,ResolutionConfidence.AMBIGUOUS,"canonical metadata does not match family or physical PNG",inspection)
    base,direction=(filename_stem.rsplit("__",1)+[None])[:2] if "__" in filename_stem else (filename_stem,None)
    sid,reason=family.resolve_state(base)
    if sid is None: return AssetResolution(family.id,None,None,ResolutionConfidence.AMBIGUOUS,reason,inspection)
    if family.direction_policy=="omni":
        if direction not in (None,"omni"): return AssetResolution(family.id,None,None,ResolutionConfidence.AMBIGUOUS,"omni family forbids directional suffix",inspection)
        direction="omni"
    elif direction is None and len(family.allowed_directions) == 1:
        direction = family.allowed_directions[0]
    elif direction not in family.allowed_directions:
        return AssetResolution(family.id,None,None,ResolutionConfidence.AMBIGUOUS,"directional input requires canonical __direction suffix",inspection)
    if inspection.layout==FrameLayout.AMBIGUOUS: return AssetResolution(family.id,sid,direction,ResolutionConfidence.AMBIGUOUS,f"state resolved ({reason}) but image layout is ambiguous",inspection)
    confidence=ResolutionConfidence.INFERRED if reason.startswith("alias ") else ResolutionConfidence.EXACT
    return AssetResolution(family.id,sid,direction,confidence,reason,inspection)
