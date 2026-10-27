#!/usr/bin/env python3
# /// script
# dependencies = ["cryptography", "pillow", "numpy"]
# ///
"""Thin stable entrypoint for the Operator 3D asset workflow (run -> verify -> freeze -> publish-review).
The implementation lives in custodian/asset_drop/source_work/operator/operator_3d_master/scripts/asset_pipeline/; see its README.
    uv run custodian/tools/iteration/asset_pipeline.py --help"""
import pathlib, sys
PIPE = pathlib.Path(__file__).resolve().parents[2] / 'asset_drop/source_work/operator/operator_3d_master/scripts/asset_pipeline'
sys.path.insert(0, str(PIPE))
import run_asset  # noqa: E402
if __name__ == '__main__': sys.exit(run_asset.main())
