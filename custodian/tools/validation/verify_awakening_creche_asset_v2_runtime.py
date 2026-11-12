#!/usr/bin/env python3
"""Verify Crèche Asset V2 runtime bytes and optionally record current evidence."""
from __future__ import annotations

import argparse
import hashlib
import json
import struct
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FAMILY_ID = "awakening_creche_environment"
FAMILY_PATH = ROOT / "content/metadata/assets/families/awakening_creche_environment.asset.json"
CATALOG_PATH = ROOT / "content/metadata/assets/generated/asset_catalog.generated.json"
SCENE_PATH = ROOT / "scenes/awakening_first_return.tscn"
TRAVERSAL_PATH = ROOT.parent / "reports/awakening_creche_gameplay_review/live_traversal_result.json"
CAPTURE_DIR = TRAVERSAL_PATH.parent
INGEST_JOB_PATH = ROOT / "asset_drop/logs/job_20261110T003455Z_2cfe3ce7.json"
CONSOLE_BODY_PATH = ROOT / "content/sprites/environment/props/awakening/awakening_creche_console/runtime/body/awakening_creche_console__body__interaction__idle__omni__1f__128.png"
CONSOLE_FX_PATH = ROOT / "content/sprites/effects/awakening/runtime/awakening_creche_console_activation_fx/awakening_creche_console_activation_fx__fx__effect__activate__omni__8f__128.png"
RECEIPT_PATH = ROOT / "docs/ai_context/asset_audits/AWAKENING_CRECHE_RUNTIME_VERIFICATION_20261110.json"
ORCHESTRATION_URL = "https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af12561-89a4-83ea-bc7f-c896ec89bed0"
EXPECTED = {
    "underlay": {
        "source": "asset_drop/source_work/awakening/awakening_creche_environment/underlay_source.png",
        "sha256": "9ce70dff57e7678234ff423643d255840ca66cf855067948763f73b2b426d77a",
        "runtime": "content/levels/awakening/01_creche/awakening_creche_underlay_1464x1074.png",
    },
    "foreground": {
        "source": "asset_drop/source_work/awakening/awakening_creche_environment/foreground_source.png",
        "sha256": "515b287f877cf4cd940c11aeab6bfa05370ff651f06927ba46e13c212a252bfc",
        "runtime": "content/levels/awakening/01_creche/awakening_creche_foreground_1464x1074.png",
    },
}
EXPECTED_CAPTURE_NAMES = [
    "10_actual_operator_wake.png",
    "11_actual_console_fx_frame_0.png",
    "12_actual_console_fx_frame_3.png",
    "13_actual_console_fx_frame_7.png",
    "14_north_destination.png",
    "15_return_destination.png",
    "16_actual_operator_returned.png",
]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def image_info(path: Path) -> tuple[int, int, int, int]:
    with path.open("rb") as stream:
        header = stream.read(29)
    if len(header) != 29 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise ValueError(f"not a valid PNG with an IHDR header: {path}")
    width, height = struct.unpack(">II", header[16:24])
    bit_depth, color_type = header[24], header[25]
    return width, height, bit_depth, color_type


def verify() -> dict:
    family = json.loads(FAMILY_PATH.read_text(encoding="utf-8"))
    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    scene = SCENE_PATH.read_text(encoding="utf-8")
    traversal = json.loads(TRAVERSAL_PATH.read_text(encoding="utf-8"))
    ingest_job = json.loads(INGEST_JOB_PATH.read_text(encoding="utf-8"))
    if family.get("id") != FAMILY_ID or family.get("canvas") != {"width": 1464, "height": 1074}:
        raise ValueError("Crèche family identity or canvas size does not match the approved contract")
    if traversal.get("schema") != "custodian.awakening_creche_live_traversal.v1" or not traversal.get("passed") or traversal.get("failures"):
        raise ValueError("latest live traversal result is missing or not passing")
    transition_zones = [item.get("zone") for item in traversal.get("transitions", [])]
    if transition_zones != ["zone02_ambulatory", "zone01_creche"]:
        raise ValueError(f"live traversal has unexpected zone transitions: {transition_zones}")
    if traversal.get("console_fx_frames") != [0, 3, 7] or traversal.get("screenshots") != EXPECTED_CAPTURE_NAMES:
        raise ValueError("live gameplay capture does not include the expected console frames and traversal screenshots")
    previous_capture_evidence = {}
    if RECEIPT_PATH.is_file():
        previous = json.loads(RECEIPT_PATH.read_text(encoding="utf-8"))
        previous_capture_evidence = {
            Path(item.get("path", "")).name: item
            for item in previous.get("gameplay_presentation", {}).get("gameplay_screenshots", [])
            if isinstance(item, dict)
        }
    capture_evidence = []
    for name in EXPECTED_CAPTURE_NAMES:
        capture_path = CAPTURE_DIR / name
        if capture_path.is_file():
            capture_evidence.append({
                "path": f"reports/awakening_creche_gameplay_review/{name}",
                "sha256": sha256(capture_path),
                "retained_after_review": True,
            })
            continue
        prior = previous_capture_evidence.get(name)
        if not prior or not prior.get("sha256"):
            raise ValueError(f"gameplay capture is missing and has no previously recorded hash: {name}")
        capture_evidence.append({
            "path": f"reports/awakening_creche_gameplay_review/{name}",
            "sha256": prior["sha256"],
            "retained_after_review": False,
        })
    if (ingest_job.get("job_id") != "job_20261110T003455Z_2cfe3ce7"
            or ingest_job.get("result") != "success"
            or ingest_job.get("godot_import", {}).get("ok") is not True):
        raise ValueError("Asset V2 ingest receipt does not record successful import")
    if sha256(CONSOLE_BODY_PATH) != "01716bcdf4a3d7169e52149f495f91830106df93f94736e3c2aee8d910a30acb":
        raise ValueError("approved console body texture hash changed")
    if sha256(CONSOLE_FX_PATH) != "5ce24cd54338cdf4f757c4be0b83514295239cbb578617cceb8234f44eb579b5":
        raise ValueError("console activation FX source hash changed")
    console_source = (ROOT / "game/world/awakening/awakening_first_return.gd").read_text(encoding="utf-8")
    if ("frames.set_animation_speed(&\"activate\", 8.0)" not in console_source
            or "for frame_index in 8:" not in console_source
            or "CRECHE_ZONE_TRIGGER_INSET := 32.0" not in console_source):
        raise ValueError("console FX or Crèche trigger runtime contract changed")
    if scene.count("position = Vector2(0, -96)") < 2:
        raise ValueError("Crèche underlay and foreground no longer share the verified (0,-96) registration")
    states = []
    for state_id, item in EXPECTED.items():
        source = ROOT / item["source"]
        output = ROOT / item["runtime"]
        source_hash, output_hash = sha256(source), sha256(output)
        if source_hash != item["sha256"] or output_hash != item["sha256"]:
            raise ValueError(f"{state_id}: source/runtime bytes do not match approved hash")
        source_info, output_info = image_info(source), image_info(output)
        if source_info != (1464, 1074, 8, 6) or output_info != source_info:
            raise ValueError(f"{state_id}: expected matching 1464x1074 RGBA PNGs, got {source_info} -> {output_info}")
        sidecar = output.with_name(output.name + ".import")
        if not sidecar.is_file():
            raise ValueError(f"{state_id}: missing Godot import sidecar")
        entry = catalog.get("families", {}).get(FAMILY_ID, {}).get("assets", {}).get(f"{state_id}::omni")
        if not entry or entry.get("path") != item["runtime"].removeprefix("custodian/"):
            raise ValueError(f"{state_id}: generated catalog binding missing or mismatched")
        if entry.get("sha256") != item["sha256"] or entry.get("frame_size") != [1464, 1074] or entry.get("frames") != 1:
            raise ValueError(f"{state_id}: generated catalog contract does not match runtime bytes")
        resource_path = "res://" + item["runtime"].removeprefix("custodian/")
        if resource_path not in scene:
            raise ValueError(f"{state_id}: production scene does not bind {resource_path}")
        states.append({
            "state_id": state_id,
            "source_path": item["source"],
            "source_sha256": source_hash,
            "source_size_bytes": source.stat().st_size,
            "runtime_path": item["runtime"].removeprefix("custodian/"),
            "runtime_sha256": output_hash,
            "runtime_size_bytes": output.stat().st_size,
            "dimensions": [1464, 1074],
            "mode": "RGBA",
            "frames": 1,
            "imported": True,
            "bound_to": "res://scenes/awakening_first_return.tscn",
            "traversal_result_sha256": sha256(TRAVERSAL_PATH),
        })
    return {
        "schema": "custodian.awakening_creche_asset_v2_runtime_verification.v1",
        "verified_at_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "family": FAMILY_ID,
        "family_schema": "custodian.asset_family.v2",
        "family_contract_sha256": sha256(FAMILY_PATH),
        "catalog_sha256_before_record": sha256(CATALOG_PATH),
        "consumer_scene": {"path": "custodian/scenes/awakening_first_return.tscn", "sha256": sha256(SCENE_PATH)},
        "asset_v2_ingest": {
            "job_id": ingest_job["job_id"],
            "receipt_path": "custodian/asset_drop/logs/job_20261110T003455Z_2cfe3ce7.json",
            "receipt_sha256": sha256(INGEST_JOB_PATH),
            "godot_import_ok": ingest_job["godot_import"]["ok"],
        },
        "gameplay_presentation": {
            "scene_registration": {"underlay": [0, -96], "foreground": [0, -96]},
            "console_body_path": CONSOLE_BODY_PATH.relative_to(ROOT).as_posix(),
            "console_body_sha256": sha256(CONSOLE_BODY_PATH),
            "console_activation_fx_path": CONSOLE_FX_PATH.relative_to(ROOT).as_posix(),
            "console_activation_fx_sha256": sha256(CONSOLE_FX_PATH),
            "console_activation_frames_observed": traversal["console_fx_frames"],
            "console_activation_fps": 8,
            "source_validation": "awakening_first_return.gd frame count and speed checked",
            "gameplay_screenshots": capture_evidence,
        },
        "states": states,
        "live_traversal": {
            "path": "reports/awakening_creche_gameplay_review/live_traversal_result.json",
            "sha256": sha256(TRAVERSAL_PATH),
            "passed": True,
            "failures": [],
            "transitions": traversal["transitions"],
            "north_position": traversal["north_position"],
            "return_position": traversal["return_position"],
            "return_zone_index": traversal["return_zone_index"],
        },
    }


def record(evidence: dict, reviewer: str, review_limitation: str) -> str:
    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    evidence["gameplay_visual_review"] = {
        "decision": "approved for gameplay presentation",
        "reviewed_by": reviewer,
        "conversation_url": ORCHESTRATION_URL,
        "limitation": review_limitation,
        "evidence_cleanup": "delete-after-review cleanup completed",
        "review_run_id": "creche-runtime-final-review-20261110",
    }
    temporary = RECEIPT_PATH.with_suffix(RECEIPT_PATH.suffix + ".tmp")
    RECEIPT_PATH.parent.mkdir(parents=True, exist_ok=True)
    temporary.write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
    temporary.replace(RECEIPT_PATH)
    pointer = {"path": RECEIPT_PATH.relative_to(ROOT.parent).as_posix(), "sha256": sha256(RECEIPT_PATH)}
    for state_id in EXPECTED:
        entry = catalog["families"][FAMILY_ID]["assets"][f"{state_id}::omni"]
        entry["validation_evidence"] = [pointer]
    CATALOG_PATH.write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")
    return pointer["sha256"]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--record", action="store_true", help="persist the receipt and link it to both Asset V2 catalog states")
    parser.add_argument("--reviewed-by", default="", help="review attribution supplied by the authoring chat")
    parser.add_argument("--review-limitation", default="", help="exact subjective-inspection limitation to retain")
    args = parser.parse_args()
    try:
        evidence = verify()
        if args.record:
            if not args.reviewed_by.strip() or not args.review_limitation.strip():
                raise ValueError("--record requires --reviewed-by and --review-limitation")
            evidence_sha = record(evidence, args.reviewed_by.strip(), args.review_limitation.strip())
            evidence["recorded_evidence_sha256"] = evidence_sha
        print(json.dumps(evidence, indent=2))
        return 0
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as error:
        print(f"Crèche Asset V2 runtime verification failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
