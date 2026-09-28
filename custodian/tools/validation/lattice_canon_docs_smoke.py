#!/usr/bin/env python3
"""Reject retired Lattice cosmology in active canon documents."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]

CHECKS = {
    "design/03_world/LATTICE_DOCTRINE.md": [
        "temporary continuity pocket",
        "the Pale wins",
        "Every success accelerates",
        "Campaign end = inevitable Lattice collapse",
        "Campaign lifecycle as Lattice establishment-to-collapse",
        "Field extension with inevitable collapse",
        "Campaigns are failing Lattice pockets",
        "Because each campaign is a failed preservation attempt",
    ],
    "design/03_world/lore/CUSTODIAN_NARRATIVE.md": [
        "knowing the Lattice cannot hold forever",
        "worlds that no longer exist",
    ],
}

REQUIRED = {
    "design/03_world/LATTICE_DOCTRINE.md": [
        "Lattice Domains are",
        "CampaignRegion",
        "It does not fictionally destroy the place.",
        "Failure should be consequential precisely because it is **not automatic**.",
        "provenance as forensic evidence",
    ],
}

def main() -> int:
    failures: list[str] = []

    for rel, banned in CHECKS.items():
        path = ROOT / rel
        if not path.is_file():
            failures.append(f"missing active canon file: {rel}")
            continue
        text = path.read_text(encoding="utf-8")
        for phrase in banned:
            if phrase.lower() in text.lower():
                failures.append(f"{rel}: retired phrase present: {phrase!r}")

    for rel, required in REQUIRED.items():
        path = ROOT / rel
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        for phrase in required:
            if phrase.lower() not in text.lower():
                failures.append(f"{rel}: required current-canon lock missing: {phrase!r}")

    if failures:
        print("lattice_canon_docs_smoke: FAIL")
        for failure in failures:
            print(f"  - {failure}")
        return 1

    print("lattice_canon_docs_smoke: PASS")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
