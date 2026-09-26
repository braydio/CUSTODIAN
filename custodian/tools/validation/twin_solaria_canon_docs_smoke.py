#!/usr/bin/env python3
"""Tripwire for Twin Solaria / Crown Reciprocal Incident documentation canon."""
from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]

REQUIRED_FILES = (
    "design/05_levels/TWIN_SOLARIA.md",
    "design/03_world/lore/TWIN_SOLARIA_CROWN_INCIDENT.md",
    "design/03_world/lore/CUSTODIAN_NARRATIVE.md",
    "design/03_world/lore/CORE_LORE.md",
    "design/04_architecture/HUB_SPATIAL_LAYOUT.md",
    "design/04_architecture/HUB_DOCTRINE.md",
    "custodian/docs/ai_context/CONTEXT.md",
    "custodian/docs/ai_context/CURRENT_STATE.md",
    "custodian/docs/ai_context/FILE_INDEX.md",
)

REQUIRED_LEVEL_MARKERS = (
    "Solarium I — Acquisition Aperture",
    "Solarium II — Passage Aperture",
    "the Second Crown",
    "the Amputation",
    "Outbound Anchor",
    "Reciprocal Anchor",
    "Resolved Route Vista",
)

REQUIRED_INCIDENT_MARKERS = (
    "Crown Reciprocal Incident",
    "pre-amputation anomalous damage",
    "deliberate emergency-separation damage",
    "Local termination of Solarium II did not terminate the wider crisis.",
    "Twin Solaria caused the Severing | **UNRESOLVED / DO NOT ASSERT**",
    "Solarium II was Ground Zero | **UNRESOLVED / DO NOT ASSERT**",
)

FORBIDDEN_ACTIVE_CLAIMS = (
    "The name **Twin Solaria** refers to two paired continuity-reference towers",
    "The facility's two namesake towers are the **Outbound Solaria**",
    "paired Outbound and Reciprocal Solaria",
    "paired continuity-reference towers, not literal suns",
)


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def main() -> int:
    errors: list[str] = []

    for relative in REQUIRED_FILES:
        if not (ROOT / relative).is_file():
            errors.append(f"missing Twin Solaria canon file: {relative}")

    if errors:
        for error in errors:
            print(f"FAIL: {error}")
        return 1

    level = read("design/05_levels/TWIN_SOLARIA.md")
    incident = read("design/03_world/lore/TWIN_SOLARIA_CROWN_INCIDENT.md")
    narrative = read("design/03_world/lore/CUSTODIAN_NARRATIVE.md")
    core = read("design/03_world/lore/CORE_LORE.md")
    spatial = read("design/04_architecture/HUB_SPATIAL_LAYOUT.md")
    doctrine = read("design/04_architecture/HUB_DOCTRINE.md")
    context = read("custodian/docs/ai_context/CONTEXT.md")
    current = read("custodian/docs/ai_context/CURRENT_STATE.md")
    index = read("custodian/docs/ai_context/FILE_INDEX.md")

    for marker in REQUIRED_LEVEL_MARKERS:
        if marker not in level:
            errors.append(f"level authority missing marker: {marker!r}")

    for marker in REQUIRED_INCIDENT_MARKERS:
        if marker not in incident:
            errors.append(f"incident authority missing marker: {marker!r}")

    if "## The Second Crown" not in narrative:
        errors.append("canonical narrative is missing the Second Crown exposition slice")

    if "SOLARIUM II\nPASSAGE APERTURE" not in narrative:
        errors.append("Second Crown narrative no longer reveals Solarium II as the Passage Aperture")

    if "The Second Crown was enormous." not in narrative:
        errors.append("Second Crown narrative no longer carries the network-scale Severing reveal")

    if "Twin Solaria provides a second kind of evidence." not in core:
        errors.append("CORE_LORE no longer indexes Twin Solaria in the Null Warrant layer")

    for text_name, text in (
        ("level", level),
        ("spatial", spatial),
        ("doctrine", doctrine),
        ("context", context),
        ("current", current),
    ):
        for forbidden in FORBIDDEN_ACTIVE_CLAIMS:
            if forbidden in text:
                errors.append(
                    f"{text_name} resurrects retired Twin Solaria tower-name canon: {forbidden!r}"
                )

    if "design/03_world/lore/TWIN_SOLARIA_CROWN_INCIDENT.md" not in index:
        errors.append("FILE_INDEX does not index the Crown Incident authority")

    if "Ground Zero" not in context or "not established" not in context:
        errors.append("AI context no longer preserves the Twin Solaria Ground Zero uncertainty")

    if "development-only fidelity preview" not in current:
        errors.append("CURRENT_STATE no longer preserves the truthful Twin Solaria runtime status")

    if errors:
        for error in errors:
            print(f"FAIL: {error}")
        return 1

    print("twin_solaria_canon_docs_smoke: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
