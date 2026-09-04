#!/usr/bin/env python3
"""Focused acceptance for Asset Pipeline V2 human and JSON CLI surfaces."""
from __future__ import annotations

import contextlib
import io
import json
import sys
import tempfile
from pathlib import Path
from types import SimpleNamespace

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "tools/assets"
sys.path.insert(0, str(ASSETS))

import asset as cli
from asset_catalog import file_hash
from asset_contract import parse_family


def capture(call, args, families):
    stream = io.StringIO()
    with contextlib.redirect_stdout(stream):
        result = call(args, families)
    return result, stream.getvalue()


def main():
    family = parse_family({
        "schema": "custodian.asset_family.v2",
        "id": "baby_opossum",
        "kind": "ambient_creature",
        "runtime": {"domain": "sprites/ambient_creatures", "owner": "baby_opossum"},
        "canvas": {"width": 64, "height": 64},
        "direction_policy": "4dir",
        "auto_mirror": True,
        "states": {
            "idle": {"required": True, "layer": "body", "action_group": "locomotion", "variant": "idle", "animation": True, "frames": 2, "min_direction_count": 3, "required_directions": ["n", "e", "s"]},
            "startle": {"recommended": True, "layer": "body", "action_group": "reaction", "variant": "startle", "animation": True, "frames": 2, "min_direction_count": 1},
        },
        "aliases": {},
        "consumers": [],
    })
    families = {family.id: family}

    with tempfile.TemporaryDirectory() as temporary:
        project = Path(temporary)
        old_project, old_inbox, old_families = cli.PROJECT_DIR, cli.INBOX_ROOT, cli.FAMILIES_DIR
        cli.PROJECT_DIR = project
        cli.INBOX_ROOT = project / "asset_drop/inbox"
        cli.FAMILIES_DIR = project / "content/metadata/assets/families"
        try:
            inbox = cli.INBOX_ROOT / family.id
            inbox.mkdir(parents=True)
            Image.new("RGBA", (128, 64), (20, 40, 60, 255)).save(inbox / "idle__e.png")

            result, human = capture(cli.cmd_plan, SimpleNamespace(family=family.id, no_mirror=False, verbose=False, json=False), families)
            assert result == 0
            assert "1 source file → 2 runtime assets" in human
            assert "✓ Safe to ingest" in human and "→ idle E" in human and "mirrored" in human
            assert "confidence" not in human and "backend" not in human and "target" not in human

            _, verbose = capture(cli.cmd_plan, SimpleNamespace(family=family.id, no_mirror=False, verbose=True, json=False), families)
            assert "Resolution" in verbose and "confidence" in verbose and "backend" in verbose and "target" in verbose

            _, serialized = capture(cli.cmd_plan, SimpleNamespace(family=family.id, no_mirror=False, verbose=False, json=True), families)
            plan_payload = json.loads(serialized)
            assert plan_payload["family"] == family.id and plan_payload["can_apply"] is True
            assert plan_payload["output_count"] == 2 and plan_payload["assets"][0]["confidence"] == "exact"

            _, request = capture(cli.cmd_request, SimpleNamespace(family=family.id, write=False, json=False), families)
            assert "idle__n.png" in request and "idle__e.png" in request and "idle__s.png" in request
            assert "West is generated automatically from east." in request
            assert "minimum directions" not in request and "auto mirror: True" not in request

            output = project / "content/sprites/ambient_creatures/baby_opossum/runtime/body/locomotion/idle.png"
            output.parent.mkdir(parents=True)
            output.write_bytes(b"runtime")
            catalog = project / "content/metadata/assets/generated/asset_catalog.generated.json"
            catalog.parent.mkdir(parents=True)
            catalog.write_text(json.dumps({"schema": "custodian.asset_catalog.v2", "families": {family.id: {"kind": family.kind, "assets": {"idle::e": {"state_id": "idle", "direction": "e", "path": output.relative_to(project).as_posix(), "sha256": file_hash(output), "provenance": "authored"}}}}}))
            _, status = capture(cli.cmd_status, SimpleNamespace(family=family.id, verbose=False, json=False), families)
            assert "Required art" in status and "NEEDS ART" in status and "WAITING TO INGEST" in status
            assert "ART_PRESENT" not in status and "RUNTIME_VERIFIED" not in status

            _, detailed = capture(cli.cmd_status, SimpleNamespace(family=family.id, verbose=True, json=False), families)
            assert "PIPELINE DETAILS" in detailed and "runtime test    · not verified" in detailed

            _, status_json = capture(cli.cmd_status, SimpleNamespace(family=family.id, verbose=False, json=True), families)
            assert json.loads(status_json)["states"]["idle"]["runtime_verified"] is False

            _, invalid = capture(cli.cmd_new, SimpleNamespace(family="bad", kind="ambient_creature", size="64", direction=None, domain=None, owner=None, auto_mirror=None, force=False), {})
            assert "✗ Invalid size: 64" in invalid and "--size 64x64" in invalid
        finally:
            cli.PROJECT_DIR, cli.INBOX_ROOT, cli.FAMILIES_DIR = old_project, old_inbox, old_families

    print("PASS: answer-first CLI, verbose diagnostics, JSON output, recovery guidance")


if __name__ == "__main__":
    main()
