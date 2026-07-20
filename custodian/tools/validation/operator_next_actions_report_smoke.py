#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
import tempfile
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
HELPER = REPO_ROOT / "tools/operator_next_actions_report.py"
COMBO_CHECKER = REPO_ROOT / "tools/modular_combo_check.py"


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="custodian_next_actions_") as temp:
        reports = Path(temp) / "reports"
        reports.mkdir(parents=True)
        manifest = {
            "schema": "custodian.operator_modular_combo_check.test.v1",
            "records": [
                {
                    "id": "fast_strike_e_on_idle",
                    "pair_mode": "action_fanout",
                    "lower_anim": "idle_01",
                    "upper_anim": "fast_strike_01",
                    "direction": "e",
                    "fit_debug": [
                        {
                            "frame": 0,
                            "vertical_gap_px": 7,
                            "horizontal_center_delta_px": 6,
                        }
                    ],
                }
            ],
        }
        manifest_path = reports / "manifest.json"
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
        completed = subprocess.run(
            [
                sys.executable,
                str(HELPER),
                "--combo-manifest",
                str(manifest_path),
                "--repo-root",
                str(REPO_ROOT),
                "--max-actions",
                "20",
            ],
            check=False,
            capture_output=True,
            text=True,
        )
        assert completed.returncode == 0, completed.stderr or completed.stdout
        report = json.loads((reports / "next_actions.json").read_text(encoding="utf-8"))
        assert report["schema"] == "custodian.operator_modular_next_actions.v1"
        assert report["notice"] == "Generated artifact—not project authority."
        fast_actions = [action for action in report["actions"] if action["group"] == "fast_attack"]
        assert fast_actions, "fast-attack fit evidence did not produce a grouped recommendation"
        action = fast_actions[0]
        assert {"fast_windup_01", "fast_strike_01", "fast_recovery_01"}.issubset(action["affected_actions"])
        assert action["source_files"] and all(source["absolute_path"] for source in action["source_files"])
        assert action["expected_runtime_paths"]
        assert action["implementation_commands"] and action["validation_commands"]
        assert (reports / "NEXT_ACTIONS.md").exists()

        spec = importlib.util.spec_from_file_location("combo_checker_smoke", COMBO_CHECKER)
        assert spec is not None and spec.loader is not None
        module = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = module
        spec.loader.exec_module(module)
        html = module.next_actions_html(Path(temp))
        assert "Recommended Next Actions" in html
        assert "reports/NEXT_ACTIONS.md" in html

    print("operator_next_actions_report_smoke ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
