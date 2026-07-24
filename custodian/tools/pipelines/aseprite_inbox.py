#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parents[2]
PIPELINE_DIR = PROJECT_DIR / "content" / "sprites" / "_pipeline"
ASEPRITE_DIR = PIPELINE_DIR / "aseprite"
INBOX_DIR = PIPELINE_DIR / "inbox"
GENERATE_MANIFESTS = Path(__file__).resolve().parent / "generate_inbox_manifests.py"

CANONICAL_FIELDS = ("owner", "layer", "action_group", "variant", "direction", "frames", "size")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Move aseprite PNG exports into the sprite inbox with pipeline-safe names."
    )
    parser.add_argument("--source", default=str(ASEPRITE_DIR), help="Source folder to scan for PNG exports.")
    parser.add_argument("--prompt", action="store_true", help="Force interactive prompts even for parsed names.")
    parser.add_argument("--yes", action="store_true", help="Never prompt; use parsed or inferred defaults only.")
    parser.add_argument("--dry-run", action="store_true", help="Show planned moves without changing files.")
    parser.add_argument("--run-ingest", action="store_true", help="Run manifest generation and ingest after moves.")
    parser.add_argument("--skip-post", action="store_true", help="Forward --skip-post to manifest generation and ingest.")
    parser.add_argument(
        "--no-mirror",
        action="store_true",
        help="Suppress automatic horizontal direction counterparts during ingest.",
    )
    parser.add_argument("--regen", action="store_true", help="Regenerate manifests even when they already exist.")
    parser.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Only process the first N PNGs after sorting. Useful for testing a small batch.",
    )
    args = parser.parse_args()

    source_dir = Path(args.source).expanduser().resolve()
    if not source_dir.exists():
        print(f"source directory does not exist: {source_dir}", file=sys.stderr)
        return 1

    INBOX_DIR.mkdir(parents=True, exist_ok=True)
    ASEPRITE_DIR.mkdir(parents=True, exist_ok=True)

    png_paths = sorted(source_dir.glob("*.png"))
    if args.limit > 0:
        png_paths = png_paths[: args.limit]
    if not png_paths:
        print(f"no PNG exports found in {source_dir}")
        return 0

    moved = 0
    for png_path in png_paths:
        normalized_base = _normalize_png_name(png_path.stem, prompt=args.prompt and not args.yes, quiet=args.yes)
        target_png = INBOX_DIR / f"{normalized_base}.png"
        target_json = png_path.with_suffix(".json")
        inbox_json = INBOX_DIR / f"{normalized_base}.json"

        if args.dry_run:
            print(f"[dry-run] {png_path.name} -> {target_png.relative_to(PROJECT_DIR)}")
            if target_json.exists() or target_json.is_file():
                print(f"[dry-run] would move manifest alongside as {inbox_json.relative_to(PROJECT_DIR)}")
            continue

        if target_png.exists():
            raise RuntimeError(f"target already exists: {target_png}")

        shutil.move(str(png_path), str(target_png))
        if target_json.exists():
            if inbox_json.exists():
                raise RuntimeError(f"target manifest already exists: {inbox_json}")
            shutil.move(str(target_json), str(inbox_json))
        moved += 1
        print(f"moved {png_path.name} -> {target_png.relative_to(PROJECT_DIR)}")

    if args.dry_run:
        return 0

    if args.run_ingest:
        return _run_manifest_and_ingest(
            args.skip_post,
            args.regen,
            args.no_mirror,
        )

    return 0


def _normalize_png_name(stem: str, prompt: bool, quiet: bool) -> str:
    parsed = _parse_canonical_name(stem)
    if parsed is not None and not prompt:
        return parsed
    if parsed is not None and prompt:
        defaults = parsed
    else:
        defaults = _infer_basename_from_stem(stem)
    if quiet:
        return defaults
    return _prompt_for_name(stem, defaults)


def _infer_basename_from_stem(stem: str) -> str:
    cleaned = stem.replace(" ", "_").replace("-", "_")
    parts = [part for part in cleaned.split("__") if part]
    if len(parts) >= 6:
        return "__".join(parts[:6])
    if len(parts) >= 4:
        return "__".join(parts)
    return cleaned


def _parse_canonical_name(stem: str) -> str | None:
    parts = stem.split("__")
    if len(parts) < 6:
        return None
    owner = parts[0]
    layer = parts[1]
    action_group = parts[2]
    direction = parts[-3]
    frames = parts[-2]
    size = parts[-1]
    variant = "__".join(parts[3:-3])
    if not all([owner, layer, action_group, variant, direction, frames, size]):
        return None
    if not frames.endswith("f") or not size.isdigit():
        return None
    return "__".join([owner, layer, action_group, variant, direction, frames, size])


def _prompt_for_name(stem: str, defaults: str) -> str:
    inferred = _split_canonical(defaults)
    print(f"filename needs normalization: {stem}")
    values = {}
    for field in CANONICAL_FIELDS:
        current = inferred.get(field, "")
        prompt = f"{field} [{current}]: " if current else f"{field}: "
        value = input(prompt).strip()
        values[field] = value or current

    if not values["frames"].endswith("f"):
        values["frames"] = f"{values['frames']}f"

    if not values["owner"] or not values["layer"] or not values["action_group"] or not values["variant"]:
        raise RuntimeError("filename blocks are incomplete; aborting")
    if not values["direction"] or not values["frames"] or not values["size"]:
        raise RuntimeError("filename blocks are incomplete; aborting")
    return "__".join([values[field] for field in CANONICAL_FIELDS])


def _split_canonical(name: str) -> dict[str, str]:
    parts = name.split("__")
    if len(parts) >= 7:
        return {
            "owner": parts[0],
            "layer": parts[1],
            "action_group": parts[2],
            "variant": "__".join(parts[3:-3]),
            "direction": parts[-3],
            "frames": parts[-2],
            "size": parts[-1],
        }
    return {
        "owner": "",
        "layer": "",
        "action_group": "",
        "variant": "",
        "direction": "",
        "frames": "",
        "size": "",
    }


def _run_manifest_and_ingest(
    skip_post: bool,
    regen: bool,
    no_mirror: bool,
) -> int:
    manifest_args = [sys.executable, str(GENERATE_MANIFESTS)]
    if regen:
        manifest_args.append("--regen")
    if skip_post:
        manifest_args.append("--skip-post")
    if no_mirror:
        manifest_args.append("--no-mirror")
    result = subprocess.run(manifest_args, cwd=PROJECT_DIR, check=False)
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
