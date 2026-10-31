"""Command-line interface for candidate-only static GLB proofs."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from .glb import ModelToSpriteError, inspect_glb
from .blend_inspection import inspect_blend
from .pipeline import publish_review, render_static, verify_candidate


EXIT_CODES = {
    "USAGE": 2,
    "INPUT": 3,
    "RENDER": 5,
    "VERIFY": 7,
    "PUBLISH": 8,
    "INTERNAL": 4,
}


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="model_to_sprite.py", description="Inspect and render experimental static Operator GLB candidates.")
    commands = parser.add_subparsers(dest="command", required=True)

    inspect = commands.add_parser("inspect", help="inspect geometry, materials, textures and rig identity without changing inputs")
    inspect.add_argument("input", type=Path)

    render = commands.add_parser("render-static", help="render an unrigged GLB to independent eight-direction 128/512 candidates")
    render.add_argument("input", type=Path)
    render.add_argument("--asset-root", type=Path, help="dependency root; defaults to the input file's directory")
    render.add_argument("--output-root", type=Path, required=True)
    render.add_argument("--name", required=True)
    render.add_argument("--blender")
    render.add_argument("--timeout", type=int, default=1800)
    render.add_argument("--target-height-px", type=float, default=85.0)

    verify = commands.add_parser("verify", help="recheck candidate source/dependency/tool/output hashes")
    verify.add_argument("candidate", type=Path)
    verify.add_argument("--asset-root", type=Path, required=True)

    publish = commands.add_parser("publish-review", help="publish a verified static candidate through the existing review publisher")
    publish.add_argument("candidate", type=Path)
    publish.add_argument("--asset-root", type=Path, required=True)
    publish.add_argument("--reason", required=True)
    publish.add_argument("--question", action="append", required=True)
    publish.add_argument("--workstream", default="operator-3d-model-to-sprite-tooling-integration-v1")
    publish.add_argument("--authoring-chat")
    publish.add_argument("--dry-run", action="store_true")
    return parser


def _error_code_exit(code: str) -> int:
    if code.startswith("OUTPUT") or code.startswith("USAGE") or code in {"BLENDER_MISSING", "ASSET_ROOT_REQUIRED", "PUBLISH_ARGUMENTS_REQUIRED"}:
        return EXIT_CODES["USAGE"]
    if code.startswith(("GLB", "INPUT", "DEPENDENCY", "STATIC_RIG", "RASTER", "PILLOW", "BLENDER_VERSION", "BLENDER_LAUNCH")):
        return EXIT_CODES["INPUT"]
    if code.startswith(("RENDER", "BLENDER")):
        return EXIT_CODES["RENDER"]
    if code.startswith(("CANDIDATE", "MANIFEST", "TOOL_SOURCE", "OUTPUT_", "RENDER_PROFILE", "DIRECTION_")):
        return EXIT_CODES["VERIFY"]
    if code.startswith(("PUBLISH", "REVIEW", "RCLONE")):
        return EXIT_CODES["PUBLISH"]
    return EXIT_CODES["INTERNAL"]


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        if args.command == "inspect":
            inspection = inspect_blend(args.input) if args.input.suffix.lower() == ".blend" else inspect_glb(args.input)
            result = {"status": "inspected", "inspection": inspection}
        elif args.command == "render-static":
            result = render_static(args.input, args.output_root, args.name, asset_root=args.asset_root,
                                  blender_executable=args.blender, timeout_seconds=args.timeout,
                                  target_height_px=args.target_height_px)
        elif args.command == "verify":
            result = verify_candidate(args.candidate, args.asset_root)
        else:
            result = publish_review(args.candidate, args.asset_root, reason=args.reason, questions=args.question,
                                    workstream=args.workstream, authoring_chat=args.authoring_chat, dry_run=args.dry_run)
        print(json.dumps({"ok": True, **result}, sort_keys=True, separators=(",", ":")))
        if result.get("status") == "stale":
            return EXIT_CODES["VERIFY"]
        return EXIT_CODES["OK"] if "OK" in EXIT_CODES else 0
    except ModelToSpriteError as exc:
        print(json.dumps({"ok": False, "error": {"code": exc.code, "message": exc.message}}, sort_keys=True, separators=(",", ":")))
        return _error_code_exit(exc.code)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(json.dumps({"ok": False, "error": {"code": "LOCAL_IO_ERROR", "message": type(exc).__name__}}, sort_keys=True, separators=(",", ":")))
        return EXIT_CODES["INTERNAL"]


if __name__ == "__main__":
    raise SystemExit(main())
