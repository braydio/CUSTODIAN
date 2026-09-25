#!/usr/bin/env python3
"""Tripwire for split-brain seven-polity canon documentation."""
from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]

REQUIRED_CANON = (
    "design/03_world/factions/FIELDWORKS_COMPACT.md",
    "design/03_world/factions/DRAWDOWN_COUNCILS.md",
    "design/03_world/factions/CORDON_SERVICE.md",
    "design/03_world/factions/CHARTER_AUTHORITIES.md",
    "design/03_world/factions/ORRAIC_ORDERS.md",
    "design/03_world/factions/RECOVERY_COMPANIES.md",
    "design/03_world/factions/WITNESS_ASSEMBLIES.md",
    "design/03_world/factions/LEGACY_INTERDICTION_MESH.md",
    "design/03_world/factions/FACTION_GAMEPLAY_OPPORTUNITIES.md",
    "design/02_features/factions/FACTION_IMPLEMENTATION_TRACKER.md",
)

COMPLETE_MARKERS = (
    "Faction canon migration is complete at the canonical design-document level",
    "Faction canon migration is complete at the design-document level",
)


def _expand_braced_path(path_text: str) -> list[str]:
    match = re.fullmatch(r"([^{}]*)\{([^{}]+)\}([^{}]*)", path_text)
    if match is None:
        return [path_text]
    prefix, choices, suffix = match.groups()
    return [prefix + choice.strip() + suffix for choice in choices.split(",")]


def _indexed_faction_paths(index: str) -> set[str]:
    paths: set[str] = set()
    for token in re.findall(r"`([^`]+)`", index):
        if "/factions/" not in token:
            continue
        for expanded in _expand_braced_path(token):
            if expanded.startswith(("design/", "custodian/")):
                paths.add(expanded)
    return paths


def main() -> int:
    errors: list[str] = []

    core = (ROOT / "design/03_world/lore/CORE_LORE.md").read_text(encoding="utf-8")
    overview = (ROOT / "design/03_world/factions/_FACTION_OVERVIEW.md").read_text(encoding="utf-8")
    narrative = (ROOT / "design/03_world/lore/CUSTODIAN_NARRATIVE.md").read_text(encoding="utf-8")
    lattice_migration = (ROOT / "design/03_world/LATTICE_DOMAIN_COSMOLOGY_MIGRATION.md").read_text(encoding="utf-8")
    index = (ROOT / "custodian/docs/ai_context/FILE_INDEX.md").read_text(encoding="utf-8")
    current = (ROOT / "custodian/docs/ai_context/CURRENT_STATE.md").read_text(encoding="utf-8")

    ai_claims_complete = any(marker in current for marker in COMPLETE_MARKERS)
    hold_present = (
        "MIGRATION HOLD — FACTION REAUTHOR PENDING" in core
        or "MIGRATION HOLD — FACTION REAUTHOR PENDING" in overview
    )
    if ai_claims_complete and hold_present:
        errors.append(
            "AI context claims faction migration complete while core lore/overview still carries the migration hold"
        )
    elif hold_present:
        errors.append("core lore/overview still carries the faction migration hold")

    for relative in REQUIRED_CANON:
        if not (ROOT / relative).is_file():
            errors.append(f"missing required canonical faction document: {relative}")
        if relative not in index and Path(relative).name not in index:
            errors.append(f"required canonical faction document is not indexed: {relative}")

    for relative in sorted(_indexed_faction_paths(index)):
        if not (ROOT / relative).is_file():
            errors.append(f"FILE_INDEX lists missing canonical faction path: {relative}")

    if "The Six Answers" in narrative or "Temporary Worlds" in narrative:
        errors.append(
            "post-migration narrative still exposes retired 'The Six Answers' or 'Temporary Worlds' language"
        )

    if "## Faction migration hold" in lattice_migration:
        errors.append(
            "persistent-Domain migration document still claims the faction migration is on hold"
        )

    if "Legacy Interdiction Mesh is a separately typed `HAZARD_LAYER`, never a" not in core:
        errors.append(
            "core lore no longer contains the Legacy Interdiction Mesh HAZARD_LAYER lock"
        )

    if errors:
        for error in errors:
            print(f"FAIL: {error}")
        return 1

    print(
        "faction_canon_docs_smoke: PASS "
        f"required={len(REQUIRED_CANON)} indexed={len(_indexed_faction_paths(index))}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
