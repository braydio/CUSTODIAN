#!/usr/bin/env python3
"""Tripwire for split-brain faction canon documentation."""
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
REQUIRED = (
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


def main() -> int:
    errors: list[str] = []
    for relative in REQUIRED:
        if not (ROOT / relative).is_file():
            errors.append(f"missing canonical faction document: {relative}")

    core = (ROOT / "design/03_world/lore/CORE_LORE.md").read_text(encoding="utf-8")
    overview = (ROOT / "design/03_world/factions/_FACTION_OVERVIEW.md").read_text(encoding="utf-8")
    narrative = (ROOT / "design/03_world/lore/CUSTODIAN_NARRATIVE.md").read_text(encoding="utf-8")
    index = (ROOT / "custodian/docs/ai_context/FILE_INDEX.md").read_text(encoding="utf-8")
    current = (ROOT / "custodian/docs/ai_context/CURRENT_STATE.md").read_text(encoding="utf-8")

    if "MIGRATION HOLD — FACTION REAUTHOR PENDING" in core or "MIGRATION HOLD — FACTION REAUTHOR PENDING" in overview:
        errors.append("faction canon still contains migration hold")
    if "The Six Answers" in narrative or "Temporary Worlds" in narrative:
        errors.append("narrative still exposes retired faction/domain headings")
    if "FIELDWORKS_COMPACT" not in index or "FACTION_IMPLEMENTATION_TRACKER.md" not in index:
        errors.append("context pack does not identify the active seven-polity authority")

    if errors:
        for error in errors:
            print(f"FAIL: {error}")
        return 1
    print(f"faction_canon_docs_smoke: PASS documents={len(REQUIRED)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
