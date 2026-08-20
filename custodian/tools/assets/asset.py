#!/usr/bin/env python3
"""Asset Pipeline Extraordinaire — unified asset intake CLI.

Usage:
    asset plan [family]
    asset ingest [family] [--yes] [--dry-run] [--replace]
    asset status [family]
    asset families
    asset new <family> --kind <kind> [--size WxH] [--direction omni]
    asset request <family> [--write]
    asset doctor
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ASSETS_DIR = Path(__file__).resolve().parent
PROJECT_DIR = ASSETS_DIR.parent.parent
INBOX_ROOT = PROJECT_DIR / "asset_drop" / "inbox"
FAMILIES_DIR = PROJECT_DIR / "content" / "metadata" / "assets" / "families"
SCHEMAS_DIR = PROJECT_DIR / "content" / "metadata" / "assets" / "schemas"

# Ensure asset modules are importable
if str(ASSETS_DIR) not in sys.path:
    sys.path.insert(0, str(ASSETS_DIR))

from asset_contract import AssetFamilyContract, load_all_families, SCHEMA_VERSION
from asset_plan import generate_plan, PlannedAsset, AssetPlan
from asset_plan import AssetOperation
from asset_status import get_family_status, FamilyStatus
from asset_doctor import run_doctor
from asset_inspector import inspect_png
from asset_classifier import classify_input, ResolutionConfidence
from asset_key import AssetKey
from asset_naming import canonical_filename


# ── Renderers ─────────────────────────────────────────────────────────────

def render_plan(plan: AssetPlan) -> None:
    print(f"\n{'=' * 60}")
    print(f"  {plan.family_id.upper()}")
    print(f"{'=' * 60}\n")

    if plan.errors:
        for e in plan.errors:
            print(f"  ERROR: {e}")
        print()

    for a in plan.assets:
        conf = a.confidence.value.upper()
        if a.state_id:
            print(f"  {a.source_path.name}")
            print(f"    {conf}")
            print(f"    {a.inspection.width}x{a.inspection.height}")
            layout = a.inspection.layout.value
            if layout == "horizontal_strip":
                print(f"    inferred {a.inspection.frame_count} x {a.inspection.frame_width}x{a.inspection.frame_height} horizontal strip")
            else:
                print(f"    {layout} {a.inspection.frame_width}x{a.inspection.frame_height}")
            print(f"    ->")
            print(f"    {a.target_relative_path}")
            print(f"    {a.canonical_filename}")
            print(f"    backend: {a.backend}")
            print(f"    operation: {a.operation.value}")
            print()
        else:
            print(f"  {a.source_path.name}")
            print(f"    AMBIGUOUS")
            print(f"    {a.inspection.width}x{a.inspection.height}")
            print(f"    reason: unresolvable state")
            print()

    if plan.warnings:
        for w in plan.warnings:
            print(f"  WARNING: {w}")
        print()


def render_status(status: FamilyStatus) -> None:
    print(f"\n{status.family_id.upper()}\n")

    print("  required")
    for sid, present in status.required_states:
        mark = "  ✓" if present else "  ✗"
        print(f"    {mark} {sid}")

    if status.recommended_states:
        print("  recommended")
        for sid, present in status.recommended_states:
            mark = "  ✓" if present else "  ✗"
            print(f"    {mark} {sid}")

    if status.optional_states:
        print("  optional")
        for sid, present in status.optional_states:
            mark = "  ✓" if present else "  ○"
            print(f"    {mark} {sid}")

    if status.consumers:
        print("\n  consumer")
        for c in status.consumers:
            path = c.get("path", "?")
            print(f"    {path}")

    print("\n  state lifecycle")
    for sid, state in status.states.items():
        print(f"    {sid}: SOURCE_PENDING {'yes' if state.source_pending else 'no'} | "
              f"ART_PRESENT {'yes' if state.art_present else 'no'} | "
              f"IMPORTED {'yes' if state.imported else 'no'} | "
              f"BOUND {'yes' if state.bound else 'no'} | "
              f"RUNTIME_VERIFIED {'yes' if state.runtime_verified else 'no'}")

    print(f"\n  production completeness: {status.completeness}")
    print()


def render_status_all(families: dict, project_dir: Path) -> None:
    from asset_status import get_family_status
    for fid, fam in sorted(families.items()):
        status = get_family_status(fam, project_dir)
        render_status(status)


def render_families(families: dict) -> None:
    print("\nRegistered Families\n")
    if not families:
        print("  (none)")
        return
    for fid, fam in sorted(families.items()):
        req = sum(1 for s in fam.states.values() if s.required)
        print(f"  {fid} ({fam.kind}) — {len(fam.states)} states, {req} required")
    print()


def render_doctor(issues: list) -> None:
    print("\nAsset Doctor\n")
    if not issues:
        print("  ✓ No issues found")
        return
    for issue in issues:
        icon = "✗" if issue.severity == "error" else "⚠"
        print(f"  {icon} [{issue.severity}] {issue.message}")
    print()


# ── Commands ──────────────────────────────────────────────────────────────

def cmd_plan(args, families: dict) -> int:
    if args.family:
        if args.family not in families:
            print(f"Unknown family: {args.family}")
            print(f"Known families: {', '.join(sorted(families))}")
            return 2
        fam = families[args.family]
        inbox = INBOX_ROOT / fam.id
        plan = generate_plan(fam, inbox, PROJECT_DIR)
        render_plan(plan)
        return 0 if plan.can_apply else 2

    any_errors = False
    for fid, fam in sorted(families.items()):
        inbox = INBOX_ROOT / fam.id
        plan = generate_plan(fam, inbox, PROJECT_DIR)
        render_plan(plan)
        if not plan.can_apply:
            any_errors = True
    return 2 if any_errors else 0


def cmd_ingest(args, families: dict) -> int:
    if not args.family:
        print("Usage: asset ingest <family>")
        return 2

    if args.family not in families:
        print(f"Unknown family: {args.family}")
        return 2

    fam = families[args.family]
    inbox = INBOX_ROOT / fam.id
    plan = generate_plan(fam, inbox, PROJECT_DIR)
    render_plan(plan)

    if not plan.can_apply:
        print("Plan has errors or ambiguous assets. Aborting.")
        return 2

    if args.dry_run:
        print("\n(dry run — no transaction started and no files written)")
        return 0

    if any(a.operation == AssetOperation.REPLACE for a in plan.assets) and not args.replace:
        print("Replacement requires explicit --replace. Aborting.")
        return 2

    if not plan.assets:
        print(f"No pending intake files for {fam.id}.")
        return 0

    if not args.yes:
        answer = input("Apply this plan? [y/N] ").strip().lower()
        if answer not in ("y", "yes"):
            print("Aborted.")
            return 1

    from asset_transaction import new_job_id, begin_transaction, commit_transaction
    job_id = new_job_id()
    record, staging = begin_transaction(job_id, PROJECT_DIR, list(plan.assets))

    ok = True
    for planned in plan.assets:
        if planned.backend == "runtime_ready":
            from adapters.runtime_ready import stage_asset
            result = stage_asset(planned, PROJECT_DIR, replace=args.replace, work_dir=staging)
        elif planned.backend == "sprite_ingest":
            from adapters.sprite_ingest import stage_asset
            result = stage_asset(planned, PROJECT_DIR, replace=args.replace, work_dir=staging)
        else:
            print(f"  Unknown backend: {planned.backend}")
            ok = False
            continue

        if result.ok:
            if result.operation == AssetOperation.CREATE:
                record.created_targets.extend(result.outputs)
            print(f"  OK: {planned.canonical_filename}")
        else:
            for err in result.errors:
                print(f"  FAIL: {err}")
            ok = False

    if ok:
        import shutil
        from asset_catalog import CatalogEntry, file_hash, load_catalog, save_catalog, update_catalog_entry
        catalog = load_catalog(PROJECT_DIR / "content/metadata/assets/generated/asset_catalog.generated.json")
        assets_receipt = []
        for planned in plan.assets:
            output = PROJECT_DIR / planned.target_relative_path
            if not output.exists():
                ok = False
                print(f"  FAIL: backend output missing: {planned.target_relative_path}")
                break
            update_catalog_entry(catalog, fam.id, planned.state_id, CatalogEntry(
                semantic_identity=list(planned.key.semantic_identity),
                path=planned.target_relative_path.as_posix(), frames=planned.key.frames,
                frame_size=[planned.key.frame_width, planned.key.frame_height], sha256=file_hash(output),
            ))
            assets_receipt.append({
                "state": planned.state_id, "semantic_identity": list(planned.key.semantic_identity),
                "operation": planned.operation.value, "backend": planned.backend,
                "output": planned.target_relative_path.as_posix(), "output_sha256": file_hash(output),
            })
        import_result = None
        if ok and args.godot_import:
            from adapters.godot_import import run_godot_import
            import_result = run_godot_import(PROJECT_DIR)
            ok = import_result.ok
            if not ok:
                print(f"  FAIL: {import_result.detail}")
        if ok:
            save_catalog(catalog, PROJECT_DIR / "content/metadata/assets/generated/asset_catalog.generated.json")
            archive_root = PROJECT_DIR / "asset_drop/archive" / job_id / fam.id
            for planned in plan.assets:
                archive = archive_root / planned.source_path.name
                archive.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(str(planned.source_path), str(archive))
                record.archived_inputs[planned.source_path] = archive
            receipt = {
                "schema": "custodian.asset_ingest_job.v1", "job_id": job_id,
                "timestamp": record.timestamp, "family": fam.id,
                "inputs": [{"path": p.source_path.relative_to(PROJECT_DIR).as_posix(),
                            "sha256": __import__("hashlib").sha256((record.archived_inputs[p.source_path]).read_bytes()).hexdigest()}
                           for p in plan.assets],
                "assets": assets_receipt,
                "godot_import": {"attempted": bool(args.godot_import),
                                 "ok": import_result.ok if import_result else None},
                "validation": [], "result": "success",
            }
            commit_transaction(record, PROJECT_DIR, receipt)
            print(f"\nIngest complete. Job: {job_id}")
            return 0
    if not ok:
        from asset_transaction import rollback_transaction
        rollback_transaction(record, PROJECT_DIR)
        print(f"\nIngest failed. Rolled back job: {job_id}")
        return 2


def cmd_status(args, families: dict) -> int:
    if args.family:
        if args.family not in families:
            print(f"Unknown family: {args.family}")
            return 2
        render_status(get_family_status(families[args.family], PROJECT_DIR))
        return 0

    render_status_all(families, PROJECT_DIR)
    return 0


def cmd_families(args, families: dict) -> int:
    render_families(families)
    return 0


def cmd_new(args, families: dict) -> int:
    fid = args.family
    if fid in families and not args.force:
        print(f"Family '{fid}' already exists. Use --force to overwrite.")
        return 2

    w, h = 128, 96
    if args.size:
        parts = args.size.lower().split("x")
        if len(parts) != 2:
            print(f"Invalid size: {args.size}. Use WxH format.")
            return 2
        w, h = int(parts[0]), int(parts[1])

    from asset_router import load_kind_schemas
    kind_schema = load_kind_schemas().get(args.kind)
    if kind_schema is None:
        print(f"Unsupported asset kind: {args.kind}")
        return 2
    if args.kind != "world_prop":
        print(f"Asset V2 production support is currently limited to world_prop (got {args.kind})")
        return 2
    runtime_domain = "sprites/environment/props"
    contract = {
        "schema": SCHEMA_VERSION,
        "id": fid,
        "kind": args.kind,
        "runtime": {
            "domain": runtime_domain,
            "owner": fid,
        },
        "canvas": {"width": w, "height": h},
        "direction_policy": args.direction or "omni",
        "states": {
            "idle": {
                "required": True,
                "layer": "body",
                "action_group": "interaction",
                "variant": "idle",
            }
        },
        "aliases": {},
        "consumers": [],
    }

    out_path = FAMILIES_DIR / f"{fid}.asset.json"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(contract, indent=2) + "\n", encoding="utf-8")
    print(f"Created: {out_path}")

    inbox_dir = INBOX_ROOT / fid
    inbox_dir.mkdir(parents=True, exist_ok=True)
    print(f"Inbox:   {inbox_dir}")

    return 0


def cmd_request(args, families: dict) -> int:
    if not args.family:
        print("Usage: asset request <family>")
        return 2

    if args.family not in families:
        print(f"Unknown family: {args.family}")
        return 2

    fam = families[args.family]
    print(f"\n{fam.id.upper()}\n")
    print(f"  DROP ART HERE:")
    print(f"  {INBOX_ROOT / fam.id}/\n")

    for sid, state in sorted(fam.states.items()):
        tag = "REQUIRED" if state.required else ("RECOMMENDED" if state.recommended else "OPTIONAL")
        marker = "[ ]"
        print(f"  {tag}")
        print(f"    {marker} {sid}.png")
        print(f"        {fam.frame_width}x{fam.frame_height}")
        if state.animation:
            print(f"        horizontal animation strip")
        else:
            print(f"        transparent, static")
        print()

    if args.write:
        out = INBOX_ROOT / fam.id / "README.txt"
        out.parent.mkdir(parents=True, exist_ok=True)
        lines = [f"{fam.id.upper()}", "", f"Drop art here: {INBOX_ROOT / fam.id}/", ""]
        for sid, state in sorted(fam.states.items()):
            tag = "REQUIRED" if state.required else ("RECOMMENDED" if state.recommended else "OPTIONAL")
            lines.append(f"{tag}: {sid}.png — {fam.frame_width}x{fam.frame_height}")
        out.write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(f"Written: {out}")

    return 0


def cmd_doctor(args, families: dict) -> int:
    issues = run_doctor(PROJECT_DIR)
    render_doctor(issues)
    return 2 if any(i.severity == "error" for i in issues) else 0


# ── Main ──────────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(
        prog="asset",
        description="Asset Pipeline Extraordinaire — unified asset intake.",
    )
    sub = parser.add_subparsers(dest="command")

    p_plan = sub.add_parser("plan", help="Show ingest plan (read-only)")
    p_plan.add_argument("family", nargs="?")

    p_ingest = sub.add_parser("ingest", help="Apply ingest plan")
    p_ingest.add_argument("family")
    p_ingest.add_argument("--yes", "-y", action="store_true")
    p_ingest.add_argument("--dry-run", action="store_true")
    p_ingest.add_argument("--replace", action="store_true")
    p_ingest.add_argument("--godot-import", action="store_true")

    p_status = sub.add_parser("status", help="Show family production status")
    p_status.add_argument("family", nargs="?")

    sub.add_parser("families", help="List registered families")

    p_new = sub.add_parser("new", help="Create a new family contract")
    p_new.add_argument("family")
    p_new.add_argument("--kind", default="world_prop")
    p_new.add_argument("--size", default=None)
    p_new.add_argument("--direction", default=None)
    p_new.add_argument("--force", action="store_true")

    p_req = sub.add_parser("request", help="Show art request for a family")
    p_req.add_argument("family")
    p_req.add_argument("--write", action="store_true")

    sub.add_parser("doctor", help="Run health checks")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return 1

    families = load_all_families()

    commands = {
        "plan": cmd_plan,
        "ingest": cmd_ingest,
        "status": cmd_status,
        "families": cmd_families,
        "new": cmd_new,
        "request": cmd_request,
        "doctor": cmd_doctor,
    }

    return commands[args.command](args, families)


if __name__ == "__main__":
    sys.exit(main())
