#!/usr/bin/env python3
from __future__ import annotations

import argparse
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Tuple


def run_script(
    script_path: Path, script_args: List[str], label: str
) -> Tuple[int, str, List[str]]:
    cmd = [sys.executable, str(script_path)] + script_args
    print(f"--- {label} ---")
    print(f"Running: {' '.join(cmd)}")
    print()
    result = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if result.stdout:
        print(result.stdout)
    if result.stderr:
        print(result.stderr)
    combined = result.stdout + ("\n" + result.stderr if result.stderr else "")
    warnings: List[str] = []
    for line in combined.splitlines():
        lower = line.lower()
        if "warn" in lower or " error" in lower or "failure" in lower:
            warnings.append(line.strip())
    return result.returncode, combined, warnings


def count_ok_lines(output: str) -> int:
    return sum(1 for line in output.splitlines() if line.startswith("[ok]"))


PACK_DEFS: List[Dict] = [
    {
        "name": "connector",
        "script": "normalize_connector_pack_tiles.py",
        "extra_args": [],
        "source": "content/tiles/terrain/source/generated/connector/indexed_tiles",
        "runtime_rel": "content/tiles/terrain/runtime/connector",
        "alpha_preserved": "yes (checker cleanup → transparent background)",
    },
    {
        "name": "ascent",
        "script": "normalize_ascent_pack_sheet.py",
        "extra_args": [
            "--merge-radius",
            "4",
            "--min-area",
            "3000",
        ],
        "source": "content/tiles/terrain/source/generated/ascent/ascent_pack_ai_source.png",
        "runtime_rel": "content/tiles/terrain/runtime/ascent",
        "alpha_preserved": "yes (alpha component detection preserves alpha, black void pixels kept)",
    },
    {
        "name": "chasm_bridge",
        "script": "normalize_chasm_bridge_pack_sheet.py",
        "extra_args": [
            "--min-area",
            "3000",
        ],
        "source": "content/tiles/terrain/source/generated/chasm_bridge/chasm_bridge_pack_ai_source.png",
        "runtime_rel": "content/tiles/terrain/runtime/chasm_bridge",
        "alpha_preserved": "yes (alpha component detection preserves alpha, black void pixels kept)",
    },
]


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Run all three terrain pack normalize scripts and generate a combined ingest report."
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path.cwd(),
        help="CUSTODIAN repo root (parent of custodian/). Default: current directory.",
    )
    args = parser.parse_args()

    repo_root = args.repo_root.resolve()
    script_dir = repo_root / "custodian" / "tools" / "tiles"
    report_dir = repo_root / "reports" / "terrain_pack_ingest"
    report_dir.mkdir(parents=True, exist_ok=True)

    results: List[Dict] = []
    all_pass = True

    for pack in PACK_DEFS:
        script_path = script_dir / pack["script"]
        script_args = ["--repo-root", str(repo_root)] + pack["extra_args"]
        returncode, output, warnings = run_script(
            script_path, script_args, pack["name"]
        )
        tile_count = count_ok_lines(output) if returncode == 0 else 0
        passed = returncode == 0
        if not passed:
            all_pass = False
        results.append({
            **pack,
            "returncode": returncode,
            "output": output,
            "warnings": warnings,
            "tile_count": tile_count,
            "passed": passed,
            "source_path": str(repo_root / pack["source"]),
            "runtime_path": str(repo_root / pack["runtime_rel"]),
        })
        print()

    report_path = report_dir / "terrain_pack_ingest_report.md"
    lines = [
        "# Terrain Pack Ingest Report",
        "",
        f"- **Generated**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"- **Repo Root**: `{repo_root}`",
        "",
        "## Summary",
        "",
        "| Pack | Source | Runtime Dir | Tiles | Alpha Preserved | Status |",
        "|---|---|---|---|---|---|",
    ]
    for r in results:
        status = "PASS" if r["passed"] else "FAIL"
        lines.append(
            f"| {r['name']} | `{r['source_path']}` | `{r['runtime_path']}` | "
            f"{r['tile_count']} | {r['alpha_preserved']} | **{status}** |"
        )

    lines.extend(["", "## Per-Pack Details", ""])
    for r in results:
        lines.append(f"### {r['name'].title()} Pack")
        lines.append("")
        lines.append(f"- **Script**: `{r['script']}`")
        lines.append(f"- **Exit Code**: {r['returncode']}")
        lines.append(f"- **Source**: `{r['source_path']}`")
        lines.append(f"- **Runtime Dir**: `{r['runtime_path']}`")
        lines.append(f"- **Tiles Generated**: {r['tile_count']}")
        lines.append(f"- **Alpha Preserved**: {r['alpha_preserved']}")
        if r["warnings"]:
            lines.append("- **Warnings/Errors**:")
            for w in r["warnings"]:
                lines.append(f"  - `{w}`")
        else:
            lines.append("- **Warnings/Errors**: (none)")
        status_str = "**PASS**" if r["passed"] else "**FAIL**"
        lines.append(f"- **Result**: {status_str}")
        lines.append("")

    lines.extend(["---", "", f"## Combined Result: {'**PASS**' if all_pass else '**FAIL**'}", ""])
    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote combined report: {report_path}")
    return 0 if all_pass else 1


if __name__ == "__main__":
    raise SystemExit(main())
