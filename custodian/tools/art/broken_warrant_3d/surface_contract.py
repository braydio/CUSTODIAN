"""Deterministic semantic mapping and constants for Broken Warrant materials."""
from __future__ import annotations

import re

EXPECTED_MESHES = 503
EXPECTED_TRIANGLES = 45_998
EXPECTED_BONES = 15
EXPECTED_BONE_NAMES = (
    "Root", "Hips", "Spine", "Chest", "Neck", "Head", "Backpack",
    "UpperArm.R", "Forearm.R", "UpperArm.L", "Forearm.L",
    "UpperLeg.R", "LowerLeg.R", "UpperLeg.L", "LowerLeg.L",
)
SOURCE_BONE_ALIASES = {
    "Hand.L": "Forearm.L",
    "Foot.R": "LowerLeg.R",
    "Foot.L": "LowerLeg.L",
}
ORTHO_SCALE = 5.0
FRAME_SIZE = 128
ROOT_PIXEL = (64, 106)
GROUND_Y = 107
SUPERSAMPLE = 4


def split_source_name(name: str) -> tuple[str, str]:
    """Return (human part name, intended source bone) from the GLB node name."""
    match = re.match(r"^\d{4}__(?P<part>.+)__BONE_(?P<bone>[A-Za-z0-9_.]+)$", name)
    if not match:
        raise ValueError(f"Unrecognized source mesh name: {name}")
    return match.group("part"), match.group("bone")


def assigned_bone(source_bone: str) -> str:
    return SOURCE_BONE_ALIASES.get(source_bone, source_bone)


def material_for_part(part: str) -> str | None:
    """Fail-closed part-name-to-material policy; ordered from specific to broad."""
    n = part.lower()

    # Canister cores need a separate energy budget from the visor/chest.
    if n.startswith("tank_") and "amber_glass" in n:
        return "emission_canister"

    # Independently glowing geometry, never alpha-cutout glass or face crops.
    if (
        "amber_glass" in n or "amber_emitter" in n or "round_emissive" in n
        or "glowing_nodule" in n or "luminous_core" in n or "muzzle_hot" in n
        or "vertical_amber_eye" in n
    ):
        return "emission_amber"

    # Garments keep their authored panel identity and opaque frayed mesh edges.
    if "apron_center_white" in n or "white_fray" in n or "mantle_back_cream" in n or "mantle_white" in n or "mantle_side_white" in n or n == "hood_tent_shell":
        return "fabric_offwhite"
    if "burgundy" in n or "side_wine" in n or "maroon_inner" in n or "side_lace" in n:
        return "fabric_burgundy"
    if "apron_central_dark" in n or "mantle_black" in n:
        return "fabric_charcoal"
    if n.startswith("apron_outer_") or "apron_center_burgundy" in n:
        return "fabric_burgundy"
    if n.startswith("hood_worn_seam") or n.startswith("hood_rolled_cowl_lip"):
        return "fabric_offwhite"

    # Face hardware remains dark; the visor was handled as emissive above.
    if n.startswith("mask") or n.startswith("neck_black"):
        return "mask_nearblack"

    # Pouches and load-bearing soft straps read as rough leather.
    if n.startswith(("belt_pouch", "pouch_flap", "chest_harness", "pack_shoulder_strap")):
        return "leather_dark"

    # Insignia relief is a two-tone geometric symbol; segmented ring relief is metal.
    if "insignia_roof" in n or "insignia_plinth" in n or "insignia_pillar" in n:
        return "emblem_ivory"
    if "insignia_ring" in n:
        return "metal_bronze"

    if n.startswith("energy_cable"):
        return "cable_ochre"

    # The three tanks use opaque glowing cores, dark caps, and distinct metal cage.
    if n.startswith("tank_"):
        if "dark_cap" in n:
            return "armor_graphite"
        if "brass_ring" in n or "port" in n:
            return "metal_bronze"
        if "frame_rail" in n:
            return "armor_graphite"
        if "amber" in n:
            return "emission_amber"
        return None

    # Cannon shell, bronze cage/hoops and amber core are separate classes.
    if "cannon" in n:
        if "brass_cage" in n or "barrel_girdle" in n or "muzzle_ring" in n or "muzzle_rivet" in n:
            return "metal_bronze"
        return "armor_graphite"

    # Backpack and torso mechanical detail.
    if n.startswith(("backpack_metal", "backpack_carry", "chest_rivet", "waist_brass", "waist_hanging_ring", "collar_ring")):
        if "rivet" in n or "brass" in n or "ring" in n:
            return "metal_bronze"
        return "armor_graphite"
    if n.startswith("collar_glowing"):
        return "emission_amber"
    if n.startswith("core_brass"):
        return "metal_bronze"
    if n.startswith("core_amber"):
        return "emission_amber"
    if n.startswith("core_black"):
        return "armor_graphite"

    # Flexible sleeve, seam, joint and armor underlayers.
    if (
        "softarmor" in n or "underarmor" in n or "underlay" in n
        or "upper_sleeve" in n or "elbow_joint" in n or "hip_joint" in n
        or "thigh_underlay" in n or "knee_underarmor" in n
    ):
        return "soft_underarmor"

    if "knuckle" in n or "elbow_armor" in n:
        return "armor_graphite"

    # Bronze fittings, straps and explicit metal accents.
    if "brass" in n or "buckle" in n or "rivet" in n or "metal_strap" in n or "greave_strap" in n or "sleeve_strap" in n or "rolled_cowl" in n:
        return "metal_bronze"

    # Dark fabric regions and remaining modeled armor pieces.
    if n.startswith(("mantle_black", "apron_central_dark")):
        return "fabric_charcoal"
    if "upper_arm" in n or "armored_forearm" in n or "gauntlet" in n or "elbow_armor" in n or "shoulder_underarmor" in n:
        return "armor_graphite"
    if n.startswith(("body_core", "chest_", "pelvis_", "waist_armored", "r_shoulder", "l_shoulder", "r_pauldron", "l_pauldron", "r_thigh", "l_thigh", "r_knee", "l_knee", "r_shin", "l_shin", "r_greave", "l_greave", "r_boot", "l_boot", "hood_")):
        if "round_reactor" in n or "chest_layered" in n:
            return "armor_graphite"
        return "armor_graphite" if any(k in n for k in ("armor", "plate", "shell", "lamella", "bulwark", "greave", "shin", "boot", "shoulder", "pauldron", "body_core", "chest_black", "waist_armored")) else "fabric_offwhite"

    # Explicit inventory-backed remaining known parts.
    if n in {"body_core", "pelvis_softarmor", "waist_armored_cinch", "chest_black_breastplate", "chest_layered_dorsal"}:
        return "soft_underarmor" if "softarmor" in n else "armor_graphite"
    if n.startswith(("r_upper_sleeve", "l_upper_sleeve")):
        return "soft_underarmor"
    return None
