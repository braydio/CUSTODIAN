#!/usr/bin/env python3
"""Human-first production front door for non-Operator asset intake."""
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
from collections import Counter, defaultdict
from pathlib import Path

ASSETS_DIR = Path(__file__).resolve().parent
PROJECT_DIR = ASSETS_DIR.parent.parent
INBOX_ROOT = PROJECT_DIR / "asset_drop/inbox"
FAMILIES_DIR = PROJECT_DIR / "content/metadata/assets/families"
if str(ASSETS_DIR) not in sys.path:
    sys.path.insert(0, str(ASSETS_DIR))

from asset_catalog import CatalogEntry, file_hash, load_catalog, save_catalog, update_catalog_entry
from asset_contract import SCHEMA_VERSION, load_all_families, parse_family
from asset_doctor import run_doctor
from asset_plan import AssetOperation, generate_plan
from asset_router import load_kind_schemas
from asset_status import get_family_status

MARK = {"success": "✓", "pending": "→", "empty": "·", "warning": "⚠", "error": "✗", "partial": "◐"}


def _title(value: str) -> str:
    return value.replace("_", " ").upper()


def _display_path(path: Path | str) -> str:
    try:
        return Path(path).relative_to(PROJECT_DIR).as_posix()
    except ValueError:
        return Path(path).as_posix()


def _directions(values) -> str:
    order = {direction: index for index, direction in enumerate(("n", "ne", "e", "se", "s", "sw", "w", "nw", "omni"))}
    return " ".join(value.upper() for value in sorted(values, key=lambda value: order.get(value, 99)))


def _json_default(value):
    if isinstance(value, Path):
        return value.as_posix()
    if hasattr(value, "value"):
        return value.value
    raise TypeError(f"cannot serialize {type(value).__name__}")


def _print_json(payload) -> None:
    print(json.dumps(payload, indent=2, default=_json_default))


def _plan_payload(plan) -> dict:
    return {
        "family": plan.family_id,
        "can_apply": plan.can_apply,
        "summary": dict(Counter(output.operation.value for output in plan.outputs)),
        "source_count": len(plan.assets),
        "output_count": len(plan.outputs),
        "errors": list(plan.errors),
        "warnings": list(plan.warnings),
        "post_process_hooks": list(plan.post_process),
        "assets": [
            {
                "source": asset.source_path.name,
                "state": asset.state_id,
                "confidence": asset.confidence.value,
                "resolution_reason": asset.resolution.reason,
                "inspection": {"width": asset.inspection.width, "height": asset.inspection.height, "frame_width": asset.inspection.frame_width, "frame_height": asset.inspection.frame_height, "frame_count": asset.inspection.frame_count, "layout": asset.inspection.layout.value},
                "backend": asset.backend,
                "outputs": [{"state": output.state_id, "direction": output.key.direction, "provenance": output.provenance, "operation": output.operation.value, "path": output.target_relative_path.as_posix(), "source_asset": output.source_asset, "superseded_paths": [path.as_posix() for path in output.superseded_targets], "stale_consumers": list(output.stale_consumers)} for output in asset.outputs],
            }
            for asset in plan.assets
        ],
    }


def render_plan(plan, *, verbose: bool = False, next_command: str | None = None) -> None:
    counts = Counter(output.operation.value for output in plan.outputs)
    heading = f"{_title(plan.family_id)} · INGEST PLAN"
    print(f"\n{heading}\n{'─' * len(heading)}")
    print(f"{len(plan.assets)} source file{'s' if len(plan.assets) != 1 else ''} → {len(plan.outputs)} runtime asset{'s' if len(plan.outputs) != 1 else ''}\n")
    for operation in ("create", "replace", "duplicate", "conflict", "skip"):
        if counts[operation] or operation in {"create", "replace"}:
            print(f"  {operation.upper():9} {counts[operation]}")
    print(f"\n{MARK['success']} Safe to ingest" if plan.can_apply else f"\n{MARK['error']} CANNOT INGEST")
    if plan.errors:
        print(f"\n{len(plan.errors)} blocking issue{'s' if len(plan.errors) != 1 else ''}:")
        for error in plan.errors:
            print(f"  {MARK['error']} {error}")
    if plan.warnings:
        print(f"\n{MARK['warning']} {len(plan.warnings)} item{'s' if len(plan.warnings) != 1 else ''} to inspect")
        for warning in plan.warnings:
            print(f"  {warning}")
    if plan.assets:
        print("\nFILES")
    for asset in plan.assets:
        print(f"  {asset.source_path.name}")
        if not asset.outputs:
            print(f"    {MARK['error']} unresolved: {asset.resolution.reason}")
        for output in asset.outputs:
            detail = "  mirrored" if output.provenance == "mirrored" else ""
            operation = f"  {output.operation.value.upper()}" if output.operation != AssetOperation.CREATE else ""
            print(f"    {MARK['pending']} {output.state_id} {output.key.direction.upper()}{detail}{operation}")
            for consumer in output.stale_consumers:
                print(f"      {MARK['error']} replacement still referenced by {consumer}")
        if verbose:
            print("    Resolution")
            print(f"      confidence  {asset.confidence.value}\n      reason      {asset.resolution.reason}\n      backend     {asset.backend}\n      layout      {asset.inspection.layout.value}\n      detected    {asset.inspection.frame_count} × {asset.inspection.frame_width}x{asset.inspection.frame_height} frames")
            for output in asset.outputs:
                print(f"      target      {output.target_relative_path}")
                for superseded in output.superseded_targets:
                    print(f"      supersedes  {superseded}")
    if next_command:
        print(f"\nNext: {next_command}")


def cmd_plan(args, families):
    selected = _selected(args.family, families)
    if selected is None:
        return 2
    plans = [generate_plan(family, INBOX_ROOT / family.id, PROJECT_DIR, no_mirror=getattr(args, "no_mirror", False)) for family in selected]
    if getattr(args, "json", False):
        payload = [_plan_payload(plan) for plan in plans]
        _print_json(payload[0] if args.family else payload)
    else:
        for plan in plans:
            render_plan(plan, verbose=getattr(args, "verbose", False), next_command=f"asset ingest {plan.family_id}")
    return 2 if any(not plan.can_apply for plan in plans) else 0


def cmd_ingest(args, families):
    family = families.get(args.family)
    if not family:
        return _unknown_family(args.family)
    plan = generate_plan(family, INBOX_ROOT / family.id, PROJECT_DIR, no_mirror=getattr(args, "no_mirror", False))
    render_plan(plan, verbose=getattr(args, "verbose", False))
    if not plan.can_apply:
        print(f"\nFix the blocking issues, then run:\n  asset plan {family.id}")
        return 2
    if args.dry_run:
        print(f"\n{MARK['success']} Dry run complete · no files changed")
        return 0
    if not plan.assets:
        print(f"\n{MARK['empty']} No files are waiting to ingest")
        return 0
    if any(output.operation == AssetOperation.REPLACE for output in plan.outputs) and not args.replace:
        print(f"\n{MARK['error']} Replacement approval required\n\nRun:\n  asset ingest {family.id} --replace")
        return 2
    if plan.post_process:
        print(f"\n{MARK['warning']} Delegated post-processing may update bounded runtime resources outside this PNG plan.")
        if getattr(args, "verbose", False):
            print("  Godot cache changes are not transactional: " + ", ".join(plan.post_process))
    if not args.yes and input("\nApply this plan? [y/N] ").strip().lower() not in {"y", "yes"}:
        return 1
    from asset_transaction import begin_transaction, commit_transaction, new_job_id, rollback_transaction
    job_id = new_job_id()
    record, staging = begin_transaction(job_id, PROJECT_DIR, list(plan.assets))
    try:
        for asset in plan.assets:
            module = __import__(f"adapters.{asset.backend}", fromlist=["stage_asset"])
            result = module.stage_asset(asset, PROJECT_DIR, replace=args.replace, work_dir=staging)
            if not result.ok:
                raise RuntimeError("; ".join(result.errors))
        for output in plan.outputs:
            for superseded in output.superseded_targets:
                old_target = PROJECT_DIR / superseded
                if old_target.is_file():
                    old_target.unlink()
        catalog = load_catalog()
        receipt_assets = []
        for asset in plan.assets:
            for output in asset.outputs:
                target = PROJECT_DIR / output.target_relative_path
                if not target.is_file():
                    raise RuntimeError(f"missing declared output: {output.target_relative_path}")
                update_catalog_entry(catalog, family.id, output.state_id, CatalogEntry(list(output.key.semantic_identity), output.target_relative_path.as_posix(), output.key.frames, [output.key.frame_width, output.key.frame_height], file_hash(target), output.state_id, output.key.direction, output.provenance, output.source_asset), family.kind)
                receipt_assets.append({"state_id": output.state_id, "direction": output.key.direction, "semantic_identity": list(output.key.semantic_identity), "path": output.target_relative_path.as_posix(), "provenance": output.provenance, "source_asset": output.source_asset, "sha256": file_hash(target), "operation": output.operation.value, "superseded_paths": [path.as_posix() for path in output.superseded_targets], "backend": asset.backend})
        import_result = None
        if args.godot_import:
            from adapters.godot_import import run_godot_import
            import_result = run_godot_import(PROJECT_DIR)
            if not import_result.ok:
                raise RuntimeError(import_result.detail)
        save_catalog(catalog)
        archive_root = PROJECT_DIR / "asset_drop/archive" / job_id / family.id
        input_receipts = []
        for asset in plan.assets:
            archive = archive_root / asset.source_path.name
            archive.parent.mkdir(parents=True, exist_ok=True)
            digest = hashlib.sha256(asset.source_path.read_bytes()).hexdigest()
            shutil.move(str(asset.source_path), str(archive))
            record.archived_inputs[asset.source_path] = archive
            input_receipts.append({"path": asset.source_path.relative_to(PROJECT_DIR).as_posix(), "sha256": digest})
        receipt = {"schema": "custodian.asset_ingest_job.v2", "job_id": job_id, "timestamp": record.timestamp, "family": family.id, "kind": family.kind, "inputs": input_receipts, "outputs": receipt_assets, "backends": sorted({asset.backend for asset in plan.assets}), "post_process_hooks": list(plan.post_process), "godot_import": {"attempted": args.godot_import, "ok": import_result.ok if import_result else None}, "validation_evidence": [], "result": "success"}
        commit_transaction(record, PROJECT_DIR, receipt)
        mirrored = sum(output.provenance == "mirrored" for output in plan.outputs)
        replaced = sum(output.operation == AssetOperation.REPLACE for output in plan.outputs)
        print(f"\n{MARK['success']} INGEST COMPLETE\n\n{_title(family.id).title()}\n  {len(plan.assets)} sources processed\n  {len(plan.outputs)} runtime assets written\n  {mirrored} directions auto-mirrored\n  {replaced} replaced")
        print(f"  Godot import: {MARK['success'] + ' complete' if args.godot_import else MARK['empty'] + ' not requested'}")
        print(f"\nArchive\n  {_display_path(archive_root)}/\n\nJob\n  {job_id}\n\nNext:\n  asset status {family.id}")
        return 0
    except Exception as exc:
        rollback_transaction(record, PROJECT_DIR)
        print(f"\n{MARK['error']} Ingest failed; all managed changes were rolled back\n\n{exc}\n\nRun:\n  asset plan {family.id} --verbose")
        return 2


def _status_payload(family, status) -> dict:
    return {"family": family.id, "kind": family.kind, "completeness": status.completeness, "inbox_files": status.inbox_files, "runtime_outputs": status.runtime_outputs, "consumers": status.consumers, "states": {state_id: {"tier": "required" if family.states[state_id].required else "recommended" if family.states[state_id].recommended else "optional", "source_pending": item.source_pending, "art_present": item.art_present, "imported": item.imported, "bound": item.bound, "runtime_verified": item.runtime_verified, "runtime_path": item.runtime_path, "authored_directions": list(item.authored_directions), "mirrored_directions": list(item.mirrored_directions), "required_directions": list(item.required_directions), "min_direction_count": item.min_direction_count} for state_id, item in status.states.items()}}


def _missing_directions(family, item) -> list[str]:
    present = set(item.authored_directions + item.mirrored_directions)
    required_missing = [direction for direction in item.required_directions if direction not in present]
    needed = max(0, item.min_direction_count - len(present) - len(required_missing))
    candidates = [direction for direction in family.allowed_directions if direction not in present and direction not in required_missing]
    return required_missing + candidates[:needed]


def cmd_status(args, families):
    selected = _selected(args.family, families)
    if selected is None:
        return 2
    reports = [(family, get_family_status(family, PROJECT_DIR)) for family in selected]
    if getattr(args, "json", False):
        payload = [_status_payload(family, status) for family, status in reports]
        _print_json(payload[0] if args.family else payload)
        return 0
    for family, status in reports:
        required_ready = sum(ready for _, ready in status.required_states)
        recommended_ready = sum(ready for _, ready in status.recommended_states)
        optional_ready = sum(ready for _, ready in status.optional_states)
        heading = _title(family.id)
        print(f"\n{heading}\n{'─' * len(heading)}\nRequired art      {required_ready} / {len(status.required_states)} ready\nRecommended       {recommended_ready} / {len(status.recommended_states)} ready\nOptional          {optional_ready} / {len(status.optional_states)} ready\nInbox             {len(status.inbox_files)} file{'s' if len(status.inbox_files) != 1 else ''} waiting")
        needs = [(state_id, item) for state_id, item in status.states.items() if (family.states[state_id].required or family.states[state_id].recommended) and not item.art_present]
        ready = [(state_id, item) for state_id, item in status.states.items() if item.art_present]
        if needs:
            print("\nNEEDS ART")
            for state_id, item in needs:
                present = _directions(item.authored_directions + item.mirrored_directions)
                missing = _directions(_missing_directions(family, item))
                marker = MARK["partial"] if present else MARK["error"]
                detail = f"has {present} · needs {missing}" if present else f"missing: {missing or 'art'}"
                print(f"  {marker} {state_id:18} {detail}")
        if ready:
            print("\nREADY")
            for state_id, item in ready:
                print(f"  {MARK['success']} {state_id:18} {_directions(item.authored_directions + item.mirrored_directions)}")
        if status.inbox_files:
            print("\nWAITING TO INGEST")
            for filename in status.inbox_files:
                print(f"  {MARK['pending']} {filename}")
        if getattr(args, "verbose", False):
            print("\nPIPELINE DETAILS")
            for state_id, item in status.states.items():
                print(f"  {state_id}\n    art             {MARK['success'] if item.art_present else MARK['error']}\n    authored        {_directions(item.authored_directions) or 'none'}\n    generated       {_directions(item.mirrored_directions) or 'none'}\n    Godot import    {MARK['success'] if item.imported else MARK['empty'] + ' not imported'}\n    runtime binding {MARK['success'] if item.bound else MARK['empty'] + ' not bound'}\n    runtime test    {MARK['success'] + ' verified' if item.runtime_verified else MARK['empty'] + ' not verified'}")
                if item.runtime_path:
                    print(f"    runtime path    {item.runtime_path}")
        print(f"\nNext: asset plan {family.id}" if status.inbox_files else f"\nNext: asset request {family.id}")
    return 0


def cmd_families(args, families):
    payload = [{"id": family.id, "kind": family.kind} for family in families.values()]
    if getattr(args, "json", False):
        _print_json(payload)
        return 0
    print(f"ASSET FAMILIES · {len(payload)} registered")
    grouped = defaultdict(list)
    for family in families.values():
        grouped[family.kind].append(family.id)
    for kind in sorted(grouped):
        print(f"\n{_title(kind)} · {len(grouped[kind])}")
        for family_id in sorted(grouped[kind]):
            print(f"  {family_id}")
    print("\nOperator assets use the specialized Operator pipeline.")
    return 0


def cmd_new(args, families):
    schemas = load_kind_schemas()
    schema = schemas.get(args.kind)
    if not schema:
        print(f"{MARK['error']} Unknown asset kind: {args.kind}\n\nAvailable kinds:")
        for kind in sorted(schemas):
            print(f"  {kind}")
        print(f"\nKinds are registered in:\n  content/metadata/assets/schemas/\n\nTo add this kind, create:\n  content/metadata/assets/schemas/{args.kind}.json")
        return 2
    path = FAMILIES_DIR / f"{args.family}.asset.json"
    if path.exists() and not args.force:
        print(f"{MARK['error']} Family already exists: {args.family}\n\nContract:\n  {_display_path(path)}\n\nUse --force only if you intend to replace this contract:\n  asset new {args.family} --kind {args.kind} --force")
        return 2
    size = args.size or "32x32"
    try:
        parts = size.lower().split("x")
        if len(parts) != 2:
            raise ValueError
        width, height = map(int, parts)
        if width <= 0 or height <= 0:
            raise ValueError
    except ValueError:
        print(f"{MARK['error']} Invalid size: {size}\n\nExpected WIDTHxHEIGHT, for example:\n  --size 64x64")
        return 2
    defaults = schema.defaults
    direction = args.direction or defaults.get("direction", "omni")
    auto = defaults.get("auto_mirror", False) if args.auto_mirror is None else args.auto_mirror
    raw = {"schema": SCHEMA_VERSION, "id": args.family, "kind": args.kind, "runtime": {"domain": args.domain or defaults.get("domain"), "owner": args.owner or args.family}, "canvas": {"width": width, "height": height}, "direction_policy": direction, "auto_mirror": auto, "states": {"idle": {"required": True, "layer": defaults.get("layer", "body"), "action_group": defaults.get("action_group", "display"), "variant": "idle"}}, "aliases": {}, "consumers": []}
    try:
        parse_family(raw)
    except ValueError as exc:
        print(f"{MARK['error']} Invalid family request: {exc}")
        return 2
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(raw, indent=2) + "\n", encoding="utf-8")
    inbox = INBOX_ROOT / args.family
    inbox.mkdir(parents=True, exist_ok=True)
    mirror = "off"
    if auto:
        mirror = "east ↔ west" if direction in {"4dir", "8dir"} else "enabled"
    print(f"{MARK['success']} Created asset family: {args.family}\n\nKind          {args.kind}\nCanvas        {width}×{height}\nDirections    {direction}\nAuto mirror   {mirror}\nDomain        {raw['runtime']['domain']}\nOwner         {raw['runtime']['owner']}\n\nContract\n  {_display_path(path)}\n\nDrop art here\n  {_display_path(inbox)}/\n\nNext\n  Edit the animation states, then run:\n  asset request {args.family}")
    return 0


def _request_directions(family, state) -> tuple[str, ...]:
    if family.direction_policy == "omni":
        return ()
    if state.required_directions:
        return state.required_directions
    return family.allowed_directions[:state.min_direction_count]


def _request_filenames(family, state_id, state) -> list[str]:
    directions = _request_directions(family, state)
    return [f"{state_id}__{direction}.png" for direction in directions] if directions else [f"{state_id}.png"]


def _request_payload(family) -> dict:
    return {"family": family.id, "kind": family.kind, "states": [{"id": state_id, "tier": "required" if state.required else "recommended" if state.recommended else "optional", "filenames": _request_filenames(family, state_id, state), "frame_size": list(family.state_frame_size(state)), "frames": state.expected_frames, "animation": state.animation, "layout": state.layout, "auto_mirror": family.auto_mirror} for state_id, state in family.states.items()]}


def _render_request(family) -> str:
    heading = f"{_title(family.id)} · ART REQUEST"
    lines = [heading, "─" * len(heading)]
    tiers = (("REQUIRED", lambda state: state.required), ("RECOMMENDED", lambda state: not state.required and state.recommended), ("OPTIONAL", lambda state: not state.required and not state.recommended))
    for label, predicate in tiers:
        states = [(state_id, state) for state_id, state in family.states.items() if predicate(state)]
        if not states:
            continue
        lines += ["", label]
        for state_id, state in states:
            width, height = family.state_frame_size(state)
            lines += ["", state_id, "  Make:"] + [f"    {filename}" for filename in _request_filenames(family, state_id, state)]
            frame_detail = f" · {state.expected_frames} frames" if state.expected_frames else ""
            lines.append(f"  {width}×{height} frames{frame_detail}" if state.animation else f"  {width}×{height} image")
            directions = _request_directions(family, state)
            if family.auto_mirror and "e" in directions and "w" in family.allowed_directions and "w" not in directions:
                lines.append("  West is generated automatically from east.")
    return "\n".join(lines) + "\n"


def cmd_request(args, families):
    family = families.get(args.family)
    if not family:
        return _unknown_family(args.family)
    if getattr(args, "json", False):
        _print_json(_request_payload(family))
        return 0
    text = _render_request(family)
    print(text, end="")
    if args.write:
        path = INBOX_ROOT / family.id / "README.txt"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        print(f"\n{MARK['success']} Wrote {_display_path(path)}")
    return 0


def cmd_doctor(args, families):
    issues = run_doctor(PROJECT_DIR)
    payload = [{"severity": issue.severity, "message": issue.message} for issue in issues]
    if getattr(args, "json", False):
        _print_json({"healthy": not issues, "issues": payload})
    elif not issues:
        print(f"{MARK['success']} ASSET PIPELINE HEALTHY\n\nNo contract, inbox, catalog, or consumer issues found.")
    else:
        grouped = defaultdict(list)
        for issue in issues:
            grouped[issue.severity].append(issue.message)
        print(f"ASSET DOCTOR · {len(issues)} issue{'s' if len(issues) != 1 else ''}")
        for severity, marker in (("error", MARK["error"]), ("warning", MARK["warning"])):
            if grouped[severity]:
                print(f"\n{severity.upper()} · {len(grouped[severity])}")
                for message in grouped[severity]:
                    print(f"  {marker} {message}")
        print("\nNext: resolve errors first, then run asset doctor again.")
    return 2 if any(issue.severity == "error" for issue in issues) else 0


def _unknown_family(name: str) -> int:
    print(f"{MARK['error']} Unknown asset family: {name}\n\nRun:\n  asset families")
    return 2


def _selected(name, families):
    if name and name not in families:
        _unknown_family(name)
        return None
    return [families[name]] if name else [families[key] for key in sorted(families)]


def _output_flags(parser, *, verbose: bool = False) -> None:
    if verbose:
        parser.add_argument("--verbose", action="store_true", help="Show pipeline evidence and implementation details.")
    parser.add_argument("--json", action="store_true", help="Print stable machine-readable output.")


def main():
    parser = argparse.ArgumentParser(prog="asset")
    subs = parser.add_subparsers(dest="command", required=True)
    command = subs.add_parser("plan")
    command.add_argument("family", nargs="?")
    command.add_argument("--no-mirror", action="store_true")
    _output_flags(command, verbose=True)
    command = subs.add_parser("ingest")
    command.add_argument("family")
    command.add_argument("--yes", action="store_true")
    command.add_argument("--dry-run", action="store_true")
    command.add_argument("--replace", action="store_true")
    command.add_argument("--godot-import", action="store_true")
    command.add_argument("--no-mirror", action="store_true")
    command.add_argument("--verbose", action="store_true")
    command = subs.add_parser("status")
    command.add_argument("family", nargs="?")
    _output_flags(command, verbose=True)
    command = subs.add_parser("families")
    _output_flags(command)
    command = subs.add_parser("new")
    command.add_argument("family")
    command.add_argument("--kind", required=True)
    command.add_argument("--size")
    command.add_argument("--direction")
    command.add_argument("--domain")
    command.add_argument("--owner")
    group = command.add_mutually_exclusive_group()
    group.add_argument("--auto-mirror", dest="auto_mirror", action="store_true")
    group.add_argument("--no-auto-mirror", dest="auto_mirror", action="store_false")
    command.set_defaults(auto_mirror=None)
    command.add_argument("--force", action="store_true")
    command = subs.add_parser("request")
    command.add_argument("family")
    command.add_argument("--write", action="store_true")
    _output_flags(command)
    command = subs.add_parser("doctor")
    _output_flags(command)
    args = parser.parse_args()
    families = load_all_families()
    return globals()[f"cmd_{args.command}"](args, families)


if __name__ == "__main__":
    raise SystemExit(main())
