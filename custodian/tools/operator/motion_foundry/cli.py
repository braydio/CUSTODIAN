"""Plan, render and verify content-addressed Motion Foundry candidates."""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any

from .motion import load_motion
from .qa import run_qa
from .render import canonical_document_sha, content_job_id, create_once, encode_strip, render_frames
from .rig import load_rig
from .schema import RECEIPT_SCHEMA, REPORT_SCHEMA, canonical_json, read_json, sha256_bytes, sha256_file


def _paths(args: argparse.Namespace) -> tuple[Path, Path, Path, Path]:
    rig_path, motion_path = Path(args.rig).resolve(strict=True), Path(args.motion).resolve(strict=True)
    source_root = Path(args.source_root).resolve(strict=True)
    output_root = Path(args.output_root).resolve()
    if output_root.parts[-2:] != (".ai", "operator_motion_foundry"):
        raise ValueError("output root must be beneath an ignored .ai/operator_motion_foundry directory")
    return rig_path, motion_path, source_root, output_root


def execute(args: argparse.Namespace) -> dict[str, Any]:
    rig_path, motion_path, source_root, output_root = _paths(args)
    rig, images, paths = load_rig(rig_path, source_root)
    motion = load_motion(motion_path, rig)
    sources = {part_id: sha256_file(path) for part_id, path in sorted(paths.items())}
    rig_sha, motion_sha = sha256_file(rig_path), sha256_file(motion_path)
    job_id = content_job_id(rig_sha, motion_sha, sources)
    if args.preview_fps is not None and not 1 <= args.preview_fps <= 120:
        raise ValueError("preview fps must be in 1..120")
    if args.command == "plan":
        return {"status": "planned", "job_id": job_id, "rig_id": rig["rig_id"], "motion_id": motion["motion_id"],
                "source_sha256": sources, "rig_sha256": rig_sha, "motion_sha256": motion_sha,
                "profile_sha256": rig["reference_profile_sha256"], "frame_count": motion["frame_count"],
                "geometry": [rig["frame_size"][0] * motion["frame_count"], rig["frame_size"][1]],
                "writes": False, "authored_fps": motion["fps"]}
    frames, transforms = render_frames(rig, motion, images)
    qa = run_qa(frames, rig, motion, transforms, images)
    if qa["hard_failures"]:
        raise ValueError("QA failed: " + "; ".join(qa["hard_failures"]))
    strip = encode_strip(frames)
    candidate_sha = sha256_bytes(strip)
    if rig["owner"] == "operator":
        custodian_root = Path(__file__).resolve().parents[3]
        if str(custodian_root / "tools") not in sys.path:
            sys.path.insert(0, str(custodian_root / "tools"))
        from pipelines.operator_asset_schema import OperatorAssetKey, canonical_filename
        filename = canonical_filename(OperatorAssetKey("operator", "full_body", motion["profile"], motion["group"],
            motion["action"], motion["direction"], motion["frame_count"], *rig["frame_size"]))
    else:
        filename = f"{rig['owner']}__full_body__{motion['profile']}__{motion['group']}__{motion['action']}__{motion['direction']}__{motion['frame_count']}f__{rig['frame_size'][0]}.png"
    job_dir = output_root / "runs" / job_id
    candidate_rel = Path("candidate") / filename
    report = {"schema": REPORT_SCHEMA, "status": "candidate", "owner": rig["owner"], "rig_id": rig["rig_id"],
              "motion_id": motion["motion_id"], "source_sha256": sources, "rig_sha256": rig_sha,
              "motion_sha256": motion_sha, "profile_sha256": rig["reference_profile_sha256"],
              "geometry": [rig["frame_size"][0] * motion["frame_count"], rig["frame_size"][1]],
              "root": list(rig["root"]), "ground": list(rig["ground"]),
              "frame_count": motion["frame_count"], "loop": motion["loop"], "authored_fps": motion["fps"],
              "preview_fps": args.preview_fps, "candidate_sha256": candidate_sha,
              "frame_transforms": transforms, **qa}
    receipt = {"schema": RECEIPT_SCHEMA, "status": "candidate", "job_id": job_id,
               "rig_canonical_sha256": canonical_document_sha(rig), "motion_canonical_sha256": canonical_document_sha(motion),
               "source_sha256": sources, "candidate_path": candidate_rel.as_posix(),
               "candidate_sha256": candidate_sha, "report_sha256": sha256_bytes(canonical_json(report)),
               "publication_authorized": False}
    if args.command == "check":
        return {"status": "reproducible", "job_id": job_id, "candidate_sha256": candidate_sha,
                "receipt_sha256": sha256_bytes(canonical_json(receipt)), "report_sha256": receipt["report_sha256"],
                "writes": False}
    if not args.write:
        raise ValueError("render requires --write to create its ignored candidate")
    create_once(job_dir / candidate_rel, strip)
    preview = encode_strip(frames)
    create_once(job_dir / "preview/contact_sheet.png", preview)
    create_once(job_dir / "report.json", json.dumps(report, sort_keys=True, indent=2).encode() + b"\n")
    create_once(job_dir / "receipt.json", json.dumps(receipt, sort_keys=True, indent=2).encode() + b"\n")
    return {"status": "candidate", "job_id": job_id, "candidate": str(job_dir / candidate_rel),
            "report": str(job_dir / "report.json"), "receipt": str(job_dir / "receipt.json"),
            "candidate_sha256": candidate_sha, "publication_authorized": False}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    for name in ("plan", "render", "check"):
        child = sub.add_parser(name)
        child.add_argument("--rig", required=True)
        child.add_argument("--motion", required=True)
        child.add_argument("--source-root", required=True)
        child.add_argument("--output-root", default=".ai/operator_motion_foundry")
        child.add_argument("--preview-fps", type=int, default=None)
        if name == "render":
            child.add_argument("--write", action="store_true")
    args = parser.parse_args(argv)
    try:
        value = execute(args)
        print(json.dumps(value, sort_keys=True, indent=2))
        return 0
    except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError) as exc:
        print(f"motion_foundry: ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
