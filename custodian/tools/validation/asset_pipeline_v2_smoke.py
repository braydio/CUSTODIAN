#!/usr/bin/env python3
from asset_pipeline_hardening_testlib import run
from asset_pipeline_v21_production_smoke import main as run_v21_production
if __name__ == "__main__":
    run("contract","animation","ingest","transaction","backend","status",
        "godot_import_timeout","sidecar","superseded_sidecar")
    run_v21_production()
