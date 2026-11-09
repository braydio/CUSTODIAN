#!/usr/bin/env python3
"""Fast, self-contained paired-review regression checks for ordinary PR CI.

The complete historical source-span archaeology suite remains available via
python3 custodian/tools/agent/test_paired_review_runner.py -v. That suite
depends on pinned historical remote refs and is not a gate for unrelated
dispatcher or browser changes.
"""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import test_paired_review_runner as historical_and_active


def load_tests(loader: unittest.TestLoader, tests: unittest.TestSuite, pattern: str | None):
    del tests, pattern
    suite = unittest.TestSuite()
    for name in (
        "PairedReviewRunnerTests",
        "AdvancedHeadPassRecoveryTests",
        "RedactedFinalCaptureTests",
    ):
        suite.addTests(loader.loadTestsFromTestCase(getattr(historical_and_active, name)))
    return suite


if __name__ == "__main__":
    unittest.main()
