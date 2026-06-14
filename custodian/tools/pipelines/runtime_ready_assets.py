#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_PROJECT_DIR = SCRIPT_DIR.parent.parent
DEFAULT_DROP_DIR = DEFAULT_PROJECT_DIR / "asset_drop" / "runtime_ready"
ROUTE_SUFFIX = ".runtime.json"
IGNORED_SUFFIXES = {".import", ".uid"}
ALLOWED_CONTENT_DOMAINS = {
    "ammo_types",
    "animations",
    "audio",
    "balance",
    "dialogue",
    "doors",
    "fabrication",
    "items",
    "levels",
    "metadata",
    "mods",
    "placeholder_art",
    "procgen",
    "props",
    "resources",
    "runtime",
    "sprites",
    "structures",
    "tiles",
    "ui",
    "vehicles",
    "walls",
    "weapons",
}


@dataclass
class RouteResult:
    source: str
    targets: list[str]
    status: str
    detail: str
    sha256: str


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Route persistent runtime-ready asset drops into organized Godot content paths."
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--apply", action="store_true", help="Write accepted assets and archive processed inputs.")
    mode.add_argument("--dry-run", action="store_true", help="Report routes without writing files.")
    parser.add_argument("--replace", action="store_true", help="Allow replacement of different existing targets.")
    parser.add_argument("--godot-import", action="store_true", help="Run a Godot headless import after a successful apply.")
    parser.add_argument("--project-dir", type=Path, default=DEFAULT_PROJECT_DIR, help=argparse.SUPPRESS)
    parser.add_argument("--drop-dir", type=Path, default=DEFAULT_DROP_DIR, help=argparse.SUPPRESS)
    args = parser.parse_args()

    apply = args.apply
    project_dir = args.project_dir.resolve()
    drop_dir = args.drop_dir.resolve()
    content_dir = project_dir / "content"
    inbox_dir = drop_dir / "inbox"
    archive_dir = drop_dir / "archive"
    logs_dir = drop_dir / "logs"
    for directory in (content_dir, inbox_dir, archive_dir, logs_dir):
        directory.mkdir(parents=True, exist_ok=True)

    job_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    results = process_inbox(
        inbox_dir=inbox_dir,
        content_dir=content_dir,
        archive_dir=archive_dir / job_id,
        apply=apply,
        replace=args.replace,
    )
    summary = _summarize(results)
    _print_results(results, summary, apply)

    if apply:
        receipt = {
            "job_id": job_id,
            "project_dir": str(project_dir),
            "drop_dir": str(drop_dir),
            "replace": args.replace,
            "summary": summary,
            "results": [asdict(result) for result in results],
        }
        receipt_path = logs_dir / f"{job_id}.json"
        receipt_path.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
        print(f"receipt: {receipt_path}")

    if summary["rejected"] > 0:
        return 2
    if apply and args.godot_import and summary["accepted"] > 0:
        return _run_godot_import(project_dir)
    return 0


def process_inbox(
    *,
    inbox_dir: Path,
    content_dir: Path,
    archive_dir: Path,
    apply: bool,
    replace: bool,
) -> list[RouteResult]:
    results: list[RouteResult] = []
    for source in _iter_sources(inbox_dir):
        relative = source.relative_to(inbox_dir)
        digest = _sha256(source)
        try:
            targets, sidecar = _resolve_targets(source, relative, inbox_dir, content_dir)
            status, detail = _route_source(source, targets, apply=apply, replace=replace)
            if apply and status in {"copied", "replaced", "duplicate"}:
                _archive_input(source, relative, archive_dir)
                if sidecar is not None:
                    _archive_input(sidecar, sidecar.relative_to(inbox_dir), archive_dir)
            results.append(
                RouteResult(
                    source=relative.as_posix(),
                    targets=[target.relative_to(content_dir).as_posix() for target in targets],
                    status=status,
                    detail=detail,
                    sha256=digest,
                )
            )
        except (ValueError, OSError, json.JSONDecodeError) as error:
            results.append(
                RouteResult(
                    source=relative.as_posix(),
                    targets=[],
                    status="rejected",
                    detail=str(error),
                    sha256=digest,
                )
            )
    return results


def _iter_sources(inbox_dir: Path) -> list[Path]:
    sources: list[Path] = []
    for path in sorted(inbox_dir.rglob("*")):
        if not path.is_file():
            continue
        if path.name.startswith(".") or path.name.endswith(ROUTE_SUFFIX):
            continue
        if path.suffix.lower() in IGNORED_SUFFIXES:
            continue
        sources.append(path)
    return sources


def _resolve_targets(source: Path, relative: Path, inbox_dir: Path, content_dir: Path) -> tuple[list[Path], Path | None]:
    sidecar = source.with_name(source.name + ROUTE_SUFFIX)
    if sidecar.exists():
        payload = json.loads(sidecar.read_text(encoding="utf-8"))
        raw_targets = payload.get("targets")
        if not isinstance(raw_targets, list) or not raw_targets:
            raise ValueError(f"{sidecar.name}: targets must be a non-empty list")
        targets = list(dict.fromkeys(_safe_content_target(content_dir, str(target)) for target in raw_targets))
        return targets, sidecar

    if len(relative.parts) < 2:
        raise ValueError(
            f"{relative.as_posix()}: ambiguous root-level drop; place it under a content domain "
            f"or add {source.name}{ROUTE_SUFFIX}"
        )
    return [_safe_content_target(content_dir, relative.as_posix())], None


def _safe_content_target(content_dir: Path, relative: str) -> Path:
    candidate = Path(relative)
    if candidate.is_absolute():
        raise ValueError(f"absolute target is not allowed: {relative}")
    if not candidate.parts or candidate.parts[0] not in ALLOWED_CONTENT_DOMAINS:
        raise ValueError(
            f"unknown or non-runtime content domain {candidate.parts[0] if candidate.parts else relative!r}; "
            f"use one of: {', '.join(sorted(ALLOWED_CONTENT_DOMAINS))}"
        )
    target = (content_dir / candidate).resolve()
    try:
        target.relative_to(content_dir.resolve())
    except ValueError as error:
        raise ValueError(f"target escapes content directory: {relative}") from error
    return target


def _route_source(source: Path, targets: list[Path], *, apply: bool, replace: bool) -> tuple[str, str]:
    conflicts = [target for target in targets if target.exists() and _sha256(target) != _sha256(source)]
    if conflicts and not replace:
        names = ", ".join(str(target) for target in conflicts)
        return "rejected", f"different target already exists; use --replace intentionally: {names}"

    identical = all(target.exists() and _sha256(target) == _sha256(source) for target in targets)
    if identical:
        return "duplicate", "all targets already contain identical bytes"
    if not apply:
        action = "would replace" if conflicts else "would copy"
        return "planned", action

    for target in targets:
        target.parent.mkdir(parents=True, exist_ok=True)
        temporary = target.with_name(target.name + ".runtime-ready.tmp")
        shutil.copy2(source, temporary)
        os.replace(temporary, target)
    return ("replaced", "replaced existing target files") if conflicts else ("copied", "copied to runtime content")


def _archive_input(source: Path, relative: Path, archive_dir: Path) -> None:
    target = archive_dir / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(str(source), str(target))


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _summarize(results: list[RouteResult]) -> dict[str, int]:
    return {
        "total": len(results),
        "accepted": sum(result.status in {"copied", "replaced", "duplicate", "planned"} for result in results),
        "copied": sum(result.status == "copied" for result in results),
        "replaced": sum(result.status == "replaced" for result in results),
        "duplicates": sum(result.status == "duplicate" for result in results),
        "planned": sum(result.status == "planned" for result in results),
        "rejected": sum(result.status == "rejected" for result in results),
    }


def _print_results(results: list[RouteResult], summary: dict[str, int], apply: bool) -> None:
    mode = "apply" if apply else "dry-run"
    for result in results:
        targets = ", ".join(result.targets) if result.targets else "-"
        print(f"[{result.status}] {result.source} -> {targets}: {result.detail}")
    print(f"{mode} summary: {json.dumps(summary, sort_keys=True)}")


def _run_godot_import(project_dir: Path) -> int:
    command = ["godot", "--headless", "--path", str(project_dir), "--import", "--quit"]
    print("running:", " ".join(command))
    return subprocess.run(command, check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main())
