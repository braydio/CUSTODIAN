#!/usr/bin/env python3
"""Supported entrypoint for the candidate-only static Operator model renderer."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3]))

from custodian.tools.operator.model_to_sprite.cli import main


if __name__ == "__main__":
    raise SystemExit(main())
