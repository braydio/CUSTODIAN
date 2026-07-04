#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
REPO = ROOT.parent

REQUIRED_DOCS = [
    ROOT / "docs" / "ARCHITECTURE.md",
    ROOT / "docs" / "ai_context" / "ARCHITECTURE_OWNERSHIP_MAP.md",
    ROOT / "docs" / "ai_context" / "task_packets" / "ARCHITECTURE_ORGANIZATION_PASS.md",
]

SCAFFOLD_READMES = [
    ROOT / "game" / "app" / "README.md",
    ROOT / "game" / "state" / "persistent" / "README.md",
    ROOT / "game" / "state" / "run" / "README.md",
    ROOT / "game" / "world" / "lifecycle" / "README.md",
    ROOT / "game" / "world" / "placement" / "README.md",
    ROOT / "game" / "world" / "procgen" / "generation" / "README.md",
    ROOT / "game" / "world" / "procgen" / "foliage" / "README.md",
    ROOT / "game" / "world" / "procgen" / "roads" / "README.md",
    ROOT / "game" / "world" / "procgen" / "authored_claims" / "README.md",
    ROOT / "game" / "actors" / "enemies" / "abilities" / "README.md",
    ROOT / "game" / "actors" / "enemies" / "archetypes" / "README.md",
    ROOT / "game" / "systems" / "combat" / "README.md",
    ROOT / "game" / "systems" / "arrn" / "README.md",
    ROOT / "game" / "systems" / "observability" / "README.md",
]

COORDINATORS = [
    ROOT / "game" / "world" / "procgen" / "proc_gen_tilemap.gd",
    ROOT / "game" / "world" / "procgen" / "custodian_contract_map.gd",
    ROOT / "game" / "systems" / "core" / "systems" / "contract_world_loader.gd",
    ROOT / "game" / "actors" / "enemies" / "enemy.gd",
    ROOT / "game" / "systems" / "core" / "state" / "game_state.gd",
]


def main() -> int:
    failed = False
    for path in REQUIRED_DOCS + SCAFFOLD_READMES:
        if not path.exists():
            print(f"FAIL missing: {path.relative_to(REPO)}")
            failed = True

    architecture_dir = REPO / "design" / "04_architecture"
    stale_hits = []
    for path in architecture_dir.glob("*.md"):
        text = path.read_text(encoding="utf-8", errors="replace")
        if "design/03_architecture" in text:
            stale_hits.append(path.relative_to(REPO))
    if stale_hits:
        for hit in stale_hits:
            print(f"FAIL stale design/03_architecture reference: {hit}")
        failed = True

    print("Coordinator line counts:")
    for path in COORDINATORS:
        if not path.exists():
            print(f"WARN missing coordinator path: {path.relative_to(REPO)}")
            continue
        line_count = len(path.read_text(encoding="utf-8", errors="replace").splitlines())
        label = "WARN" if line_count > 1000 else "INFO"
        print(f"{label} {path.relative_to(REPO)} lines={line_count}")

    if failed:
        return 1
    print("architecture_ownership_smoke passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
