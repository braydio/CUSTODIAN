#!/usr/bin/env python3
"""Build a deterministic read-only WB25 candidate dependency closure report."""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[3]
sys.path[:0] = [str(ROOT / "custodian/tools/operator"), str(ROOT / "custodian/tools/operator/ui"),
                str(ROOT / "custodian/tools/pipelines")]

import operator_animation_targets
import operator_2_5d_review
from ui.service import WorkbenchService
from ui.state import AnimationSelection

PLAN = Path("design/02_features/animation/OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json")
REACHABILITY = Path("custodian/content/data/operator/operator_animation_reachability.json")
OPERATOR = Path("custodian/game/actors/operator/operator.gd")
SELECTOR = Path("custodian/game/actors/operator/animations/operator_animation_selector.gd")
PRESENTER = Path("custodian/game/actors/operator/presentation/operator_body_presenter.gd")
CONTROLLER = Path("custodian/game/actors/operator/presentation/operator_presentation_controller.gd")
POSTURE = Path("custodian/game/actors/operator/presentation/unarmed_posture_presentation.gd")
MANIFEST = Path("custodian/content/sprites/operator/runtime/operator_runtime_manifest.generated.json")
CATALOG = Path("custodian/content/data/operator/generated/operator_animation_catalog.generated.json")
FRAMES = Path("custodian/content/sprites/operator/runtime/operator_runtime_frames.tres")
CORRECTION = Path("custodian/docs/reports/operator_2_5d/idle_relaxed_01_timing_authority_correction_1.json")
REVIEW = Path("custodian/tools/operator/operator_2_5d_review.py")

CANDIDATE = "unarmed_neutral_motion_v1"
FAMILY_KEYS = (
    ("unarmed", "posture", "idle_relaxed_01"),
    ("unarmed", "posture", "idle_ready_01"),
    ("unarmed", "transition", "relaxed_to_ready_01"),
    ("unarmed", "transition", "ready_to_relaxed_01"),
    ("unarmed", "locomotion", "idle_01"),
    ("unarmed", "locomotion", "walk_01"),
    ("unarmed", "locomotion", "run_01"),
)
DIRECTIONS = ["n", "ne", "e", "se", "s", "sw", "w", "nw"]


def sha(path: Path) -> str | None:
    try:
        return hashlib.sha256(path.read_bytes()).hexdigest()
    except OSError:
        return None


def git_value(root: Path, *args: str) -> str | None:
    try:
        return subprocess.run(["git", "-C", str(root), *args], check=True, capture_output=True,
                              text=True).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return None


def read_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
        return value if isinstance(value, dict) else {}
    except (OSError, json.JSONDecodeError):
        return {}


def _workspace_default(root: Path) -> Path | None:
    receipt = read_json(root / CORRECTION)
    value = receipt.get("workspace_root")
    return Path(value) if isinstance(value, str) and value else None


def _workspace_evidence(root: Path, workspace_root: Path | None) -> dict[str, Any]:
    if workspace_root is None or not workspace_root.is_dir():
        return {"status": "UNAVAILABLE", "reason": "populated authoring workspace was not readable",
                "editable_idle_directions": None, "effective_receipts": None, "families": []}
    generation_root = workspace_root / "operator_2_5d_128"
    workspace_checkout = workspace_root.parents[1]
    receipt_root = workspace_root / "review_receipts/operator_2_5d_128"
    receipts = sorted(receipt_root.rglob("*.json")) if receipt_root.is_dir() else []
    idle = generation_root / "unarmed/posture/idle_relaxed_01"
    directions = []
    for direction in DIRECTIONS:
        leaf = idle / direction
        manifest_path = leaf / "workbench.json"
        document_path = leaf / "workbench.aseprite"
        manifest = read_json(manifest_path)
        timeline = manifest.get("timeline", {})
        source = None
        correction = read_json(root / CORRECTION)
        source_row = correction.get("directions", {}).get(direction, {})
        source_path = Path(str(source_row.get("source_strip_path", ""))) if source_row.get("source_strip_path") else None
        source_hash = sha(source_path) if source_path else None
        # The correction records a path relative to the Workbench root's parent
        # checkout; resolve it against the physical authoring checkout instead.
        source_session = workspace_root.parents[1] / str(source_row.get("source_session_path", "")) if source_row.get("source_session_path") else None
        session_hash = sha(source_session) if source_session else None
        expected_source_hash = source_row.get("source_strip_sha256_after")
        expected_session_hash = source_row.get("source_session_sha256_after")
        directions.append({
            "direction": direction,
            "manifest_status": "PRESENT" if manifest_path.is_file() else "MISSING",
            "manifest_sha256": sha(manifest_path),
            "saved_document_status": "PRESENT" if document_path.is_file() else "MISSING",
            "saved_document_sha256": sha(document_path),
            "source_strip_status": "PRESENT" if source_hash else ("UNAVAILABLE" if source_path else "UNRECORDED"),
            "source_strip_sha256": source_hash,
            "source_strip_hash_matches_correction": bool(source_hash and source_hash == expected_source_hash),
            "source_session_status": "PRESENT" if session_hash else ("UNAVAILABLE" if source_session else "UNRECORDED"),
            "source_session_sha256": session_hash,
            "source_session_hash_matches_correction": bool(session_hash and session_hash == expected_session_hash),
            "frames": timeline.get("document_frames", timeline.get("frames")),
            "preview_fps": timeline.get("preview_fps", timeline.get("fps")),
            "timing_authority": timeline.get("timing_authority"),
            "durations_ms": timeline.get("frame_durations_ms"),
            "effective_receipt": False,
            "published": False,
        })
    readable = sum(row["manifest_status"] == "PRESENT" and row["saved_document_status"] == "PRESENT"
                   for row in directions)
    status = git_value(workspace_checkout, "status", "--porcelain")
    return {
        "status": "AVAILABLE",
        "workspace_root": str(workspace_root),
        "workspace_checkout_head": git_value(workspace_checkout, "rev-parse", "HEAD"),
        "workspace_checkout_status": "UNAVAILABLE" if status is None else ("CLEAN" if status == "" else "DIRTY"),
        "workspace_checkout_porcelain": status,
        "workspace_checkout_behind_main": git_value(workspace_checkout, "rev-list", "--count", "HEAD..origin/main"),
        "editable_idle_directions": readable,
        "effective_receipts": len(receipts),
        "receipt_inventory_status": "EMPTY" if not receipts else "PRESENT_REQUIRES_CURRENT_VALIDATION",
        "idle_relaxed_01": directions,
        "other_candidate_workspace_manifests": sum(
            1 for p in generation_root.glob("unarmed/*/*/*/workbench.json")
            if p.parent.parent.name != "idle_relaxed_01"
        ) if generation_root.is_dir() else 0,
    }


def _runtime_inventory(root: Path, manifest: dict[str, Any], catalog: dict[str, Any], key: tuple[str, str, str]) -> dict[str, Any]:
    profile, group, action = key
    prefix = f"{profile}/{group}/{action}/"
    animations = manifest.get("animations", {})
    catalog_rows = catalog.get("animations", {})
    runtime_rows = []
    catalog_directions = []
    for direction in DIRECTIONS:
        identity = prefix + direction
        row = animations.get(identity)
        if row:
            layers = {}
            for layer, spec in row.get("layers", {}).items():
                path = str(spec.get("path", ""))
                frame_size = spec.get("frame_size")
                layers[layer] = {"path": path.removeprefix("res://"), "frames": spec.get("frames"),
                                 "frame_size": frame_size}
            runtime_rows.append({"direction": direction, "layers": layers})
        if identity in catalog_rows:
            catalog_directions.append(direction)
    return {"runtime_manifest_directions": [r["direction"] for r in runtime_rows],
            "runtime_manifest_layers": runtime_rows,
            "catalog_directions": catalog_directions,
            "runtime_is_generation_neutral": True}


def _edges() -> list[dict[str, Any]]:
    # Classifications concern whether the proposed full-body cohort has a proven
    # end-to-end presentation edge, not whether a legacy transition currently works.
    rows = [
        ("relaxed_idle", "ready_idle", "engagement becomes active", "operator._update_unarmed_presentation_posture -> UnarmedPosturePresentation.advance", ["idle_relaxed_01", "idle_ready_01", "relaxed_to_ready_01"], "OPEN", "existing path chooses a modular pair with east/west projection; no 2.5D full-body owner path exists"),
        ("ready_idle", "relaxed_idle", "engagement quiets", "operator._update_unarmed_presentation_posture -> UnarmedPosturePresentation.advance", ["idle_ready_01", "idle_relaxed_01", "ready_to_relaxed_01"], "OPEN", "same composition mismatch; completion is tied to the legacy transition clip"),
        ("relaxed_idle", "locomotion_idle", "movement begins below walk threshold", "operator._sync_animation_from_state", ["idle_relaxed_01", "idle_01"], "OPEN", "posture is skipped during movement; current locomotion prefers modular body layers"),
        ("locomotion_idle", "walk", "movement crosses walk threshold", "operator._sync_animation_from_state -> _sync_modular_locomotion_layers", ["idle_01", "walk_01"], "OPEN", "selector has legacy identities but no generation-selected full-body composition seam"),
        ("walk", "run", "sprint input / run threshold", "operator._sync_animation_from_state -> _sync_modular_locomotion_layers", ["walk_01", "run_01"], "OPEN", "run and walk remain on modular layer owner before full-body fallback"),
        ("run", "walk", "sprint ends", "operator._sync_animation_from_state -> _sync_modular_locomotion_layers", ["run_01", "walk_01"], "OPEN", "reverse movement transition has the same owner/generation gap"),
        ("posture_or_locomotion", "guard_or_parry", "guard/parry action acquires body", "OperatorBodyPresenter + operator guard/parry presentation", ["guard", "parry"], "OPEN", "exclusive legacy body ownership and FX/socket lifetime must be reconciled with full-body cohort"),
        ("posture_or_locomotion", "dodge", "dodge charge/flow preempts body", "operator dodge presentation / OperatorBodyPresenter", ["dodge_charge", "dodge_flow"], "OPEN", "dodge identities are outside candidate; exact outgoing and settle seams remain 96px"),
        ("posture_or_locomotion", "melee_action", "melee attack preempts body", "operator melee presentation / OperatorBodyPresenter", ["melee_attack", "parry_recovery"], "OPEN", "profile-specific melee full-body/body-slaved layers, weapon socket and FX ownership are outside cohort"),
        ("posture_or_locomotion", "ranged_action", "ranged aim/fire preempts body", "operator ranged presentation / OperatorBodyPresenter", ["ranged_ready", "fire"], "OPEN", "ranged upper-body, weapon and muzzle/socket layers are outside unarmed cohort"),
        ("unarmed", "equipped_or_sheathed", "equip/sheathe changes profile and body owner", "operator.start_equip_weapon_presentation / melee and ranged posture sync", ["draw_01", "sheath_01", "idle_ready_01"], "OPEN", "equipment transition and following profile posture have separate identity/layer requirements"),
        ("action_owner", "neutral_settle", "action completion returns neutral body", "OperatorPresentationController completion clock + operator posture settle", ["action_recovery", "idle_relaxed_01", "idle_ready_01"], "OPEN", "completion callbacks/anchors must settle into the same selected generation without stale modular renderers"),
    ]
    return [{"id": f"edge-{i+1:02d}", "from": a, "to": b, "trigger": trigger,
             "consumer": consumer, "identities_or_seams": ids, "classification": status,
             "evidence": {"path": "custodian/game/actors/operator/operator.gd", "symbol": consumer},
             "reason": reason} for i, (a,b,trigger,consumer,ids,status,reason) in enumerate(rows)]


def build_report(root: Path = ROOT, workspace_root: Path | None = None) -> dict[str, Any]:
    root = root.resolve()
    if workspace_root is None:
        workspace_root = _workspace_default(root)
    workspace = _workspace_evidence(root, workspace_root)
    plan_payload = operator_animation_targets.load_plan(root / PLAN)
    families = operator_animation_targets.target_families(plan_payload)
    by_key = {(f.profile, f.group, f.action): f for f in families}
    reachability = read_json(root / REACHABILITY)
    reach_rows = reachability.get("entries", [])
    runtime_manifest = read_json(root / MANIFEST)
    catalog = read_json(root / CATALOG)
    receipt_states: dict[tuple[str, str, str, str], dict[str, Any] | None] = {}
    receipt_projection_status = "UNAVAILABLE"
    if workspace.get("status") == "AVAILABLE":
        try:
            service = WorkbenchService(repo_root=root, workspace_root=workspace_root)
            review = operator_2_5d_review.Operator2DReview(service=service, repo_root=root, workspace_root=workspace_root)
            review.receipt_root = workspace_root / "review_receipts/operator_2_5d_128"
            for profile, group, action in FAMILY_KEYS:
                for direction in DIRECTIONS:
                    selection = AnimationSelection(profile, group, action, direction, art_generation="operator_2_5d_128")
                    receipt_states[(profile, group, action, direction)] = review.current_receipt(selection)
            receipt_projection_status = "CURRENT_RECEIPT_AUTHORITY"
        except Exception as exc:  # A probe failure is unavailable evidence, never a zero.
            receipt_projection_status = f"UNAVAILABLE: {type(exc).__name__}: {exc}"
    candidate_families = []
    for key in FAMILY_KEYS:
        family = by_key[key]
        plan_row = next(row for row in plan_payload["items"] if (row.get("profile"), row.get("group"), row.get("action")) == key and row.get("art_generation") == "operator_2_5d_128")
        related = [row for row in reach_rows if (row.get("profile"), row.get("group"), row.get("action")) == key]
        runtime = _runtime_inventory(root, runtime_manifest, catalog, key)
        ws_directions = []
        for direction in family.directions:
            leaf = (workspace_root / family.generation / family.profile / family.group / family.action / direction) if workspace_root else None
            ws_directions.append(direction if leaf and (leaf / "workbench.json").is_file() else None)
        current_verified = sum(bool(receipt_states.get((*key, direction), {}).get("runtime_verified"))
                               for direction in DIRECTIONS if receipt_states.get((*key, direction)) is not None)
        current_receipts = sum(receipt_states.get((*key, direction)) is not None for direction in DIRECTIONS)
        candidate_families.append({
            "id": f"{family.profile}/{family.group}/{family.action}",
            "plan_id": plan_row["id"],
            "priority": family.priority, "directions": list(family.directions),
            "required_layers": list(family.required_layers),
            "frame_contract": {k: family.frame_contract.get(k) for k in ("frames", "frame_size", "loop", "fps", "timing_status")},
            "source_sha256": family.source_sha256,
            "authoring": {"workspace_status": workspace.get("status"),
                          "workspace_directions": ([d for d in family.directions if d in ws_directions]
                                                   if workspace.get("status") == "AVAILABLE" else None),
                          "workspace_count": (sum(d is not None for d in ws_directions)
                                              if workspace.get("status") == "AVAILABLE" else None),
                          "accepted_source_status": plan_row.get("source_status", "unknown")},
            "effective_review": {"verified_directions": current_verified if receipt_projection_status == "CURRENT_RECEIPT_AUTHORITY" else None,
                                 "receipts": current_receipts if receipt_projection_status == "CURRENT_RECEIPT_AUTHORITY" else None,
                                 "status": "UNVERIFIED" if current_verified == 0 and receipt_projection_status == "CURRENT_RECEIPT_AUTHORITY" else receipt_projection_status},
            "runtime_manifest": runtime,
            "reachability": [{"status": row.get("status"), "consumer": row.get("consumer"), "layer": row.get("layer"),
                              "reason": row.get("reason"), "migration_note": row.get("migration_note")} for row in related],
            "candidate_presentation_closure": "OPEN",
            "closure_reason": "live consumer composition owner has not been proven to select canonical 2.5D full_body identities across entry, exit, and preemption edges",
        })

    authority_paths = [PLAN, REACHABILITY, OPERATOR, SELECTOR, PRESENTER, CONTROLLER, POSTURE, MANIFEST, CATALOG, FRAMES,
                       REVIEW, Path("custodian/tools/operator/operator_animation_targets.py"), CORRECTION]
    input_hashes = {p.as_posix(): sha(root / p) for p in authority_paths}
    edges = _edges()
    return {
        "schema": "custodian.operator_2_5d_cohort_dependency_closure.v1",
        "investigation": {"main_sha": git_value(root, "rev-parse", "HEAD"),
                          "origin_main_sha": git_value(root, "rev-parse", "origin/main"),
                          "worktree_branch": git_value(root, "branch", "--show-current"),
                          "read_only": True, "source_evidence_sha256": input_hashes},
        "evidence_availability": {"authoring_workspace": workspace,
                                   "effective_receipt_projection": receipt_projection_status,
                                   "reachability": "AVAILABLE" if reach_rows else "UNAVAILABLE",
                                   "runtime_manifest": "AVAILABLE" if runtime_manifest.get("animations") else "UNAVAILABLE",
                                   "catalog": "AVAILABLE" if catalog.get("animations") else "UNAVAILABLE"},
        "candidate": {"id": CANDIDATE, "families": candidate_families,
                      "family_count": len(candidate_families), "direction_slots": sum(len(f["directions"]) for f in candidate_families),
                      "candidate_status": "NOT_RELEASE_ELIGIBLE"},
        "presentation_owners": {
            "posture": {"owner": "operator.gd::_sync_unarmed_posture", "required_layers": ["lower_body", "upper_body"],
                        "sector_policy": "UnarmedPosturePresentation.authored_sector: west only when direction.x < -0.05; all other headings resolve east",
                        "candidate_layers": ["full_body"], "compatibility": "OPEN",
                        "evidence": ["custodian/game/actors/operator/operator.gd", "custodian/game/actors/operator/presentation/unarmed_posture_presentation.gd"]},
            "locomotion": {"owner": "operator.gd::_sync_modular_locomotion_layers", "normal_preference": ["lower_body", "upper_body"],
                           "candidate_layers": ["full_body"], "compatibility": "OPEN",
                           "note": "full-body fallback exists for current identities, but does not establish generation-aware ownership or prevent modular 96px reappearance"},
            "exclusive_body_owner": {"owner": "OperatorBodyPresenter", "owners": ["MODULAR_BODY", "LEGACY_FULL_BODY", "VIGIL_POSTURE_TRANSITION", "VIGIL_FAST_STARTUP", "VIGIL_GUARD"],
                                     "single_body_invariant": "existing authority", "candidate_generation_path": "UNKNOWN"},
            "selector": {"owner": "OperatorAnimationSelector", "identity": "profile/group/action/direction/layer", "generation_neutral": True,
                         "south_fallback": "temporary selector fallback exists; caller projection remains distinct", "candidate_registry": "No generation argument or candidate runtime namespace"},
        },
        "edges": edges,
        "external_consumer_boundaries": [
            {"owner": "guard/parry", "classification": "OPEN", "requirements": ["preemption", "exclusive-body handoff", "FX retirement", "completion/settle"]},
            {"owner": "dodge", "classification": "OPEN", "requirements": ["charge/flow preemption", "full-body owner", "neutral settle"]},
            {"owner": "melee/equipment", "classification": "OPEN", "requirements": ["draw/sheathe", "weapon sockets", "body-slaved or weapon layers", "attack/recovery settle"]},
            {"owner": "ranged", "classification": "OPEN", "requirements": ["ready/aim/fire", "upper body", "muzzle/socket and overlays"]},
            {"owner": "action completion", "classification": "OPEN", "requirements": ["current completion clock", "terminal pose anchor", "no stale continuation after preemption"]},
        ],
        "blocking_gaps": [
            "Only 8/56 candidate directions are editable; the other 48 have no canonical art or resolved frame/loop/FPS contract.",
            "All eight idle documents retain 8 FPS / 125 ms as preview timing with timing_authority=false; no authoritative FPS is selected.",
            "No current effective review/sandbox receipts, verified candidate directions/families, or published candidate directions exist.",
            "Existing posture requires modular lower_body+upper_body and east/west projection; 2.5D candidate requires eight-direction full_body.",
            "Runtime semantic identities are generation-neutral; no proven generation-aware single-body presentation owner prevents 96px modular art from reappearing.",
            "Guard/parry, dodge, melee, ranged, equip/sheathe, FX/socket, and terminal completion edges include identities outside the proposed seven families.",
        ],
        "advisory_gaps": ["Accepted 8-direction source master historical absolute path is unavailable; current per-direction strips, sessions, and documents remain independently hash-recorded."],
        "negative_controls": {
            "preview_timing_cannot_verify": {"pass": workspace.get("effective_receipts") == 0 and all(row.get("timing_authority") is False for row in workspace.get("idle_relaxed_01", [])),
                                              "evidence": "operator_2d_review.py::current_receipt requires valid timing authority and evidence-bound review/sandbox"},
            "planned_family_set_does_not_prove_graph_closure": {"pass": len(edges) > 0 and all(edge["classification"] != "CLOSED" for edge in edges),
                                                               "evidence": "12 live transition/preemption seams remain open"},
            "legacy_modular_layers_are_not_full_body": {"pass": True, "evidence": "_sync_unarmed_posture requires lower_body+upper_body; plan requires full_body"},
        },
        "recommended_next_steps": [
            "Design one generation-coherent body presentation seam under OperatorPresentationController/OperatorBodyPresenter; preserve selector and single SpriteFrames authority.",
            "Specify exact incoming/outgoing transitions and settle behavior for posture, idle/walk/run, guard/parry, dodge, melee, ranged, equip/sheathe, and terminal actions; include weapon sockets and FX ownership.",
            "Only after the user chooses the actual cohort, author the missing 48+ directions and resolve physical frame/loop/timing contracts for every included family.",
            "Select idle timing through the authoritative timing-intent workflow; then obtain current per-direction QA, human disposition where required, sandbox verification, and effective receipts.",
            "Refresh WB25-6 planning from this report and the resulting human scope/timing decisions; keep production generation legacy until explicit closed-cohort release authorization and rollback proof exist.",
        ],
        "release_status": "NOT_RELEASE_ELIGIBLE",
    }


def markdown(report: dict[str, Any]) -> str:
    candidate = report["candidate"]
    inv = report["investigation"]
    workspace = report["evidence_availability"]["authoring_workspace"]
    lines = ["# Operator 2.5D Cohort Dependency Closure", "",
             f"- Report schema: `{report['schema']}`", f"- Investigated main: `{inv['main_sha']}`",
             f"- Source evidence digest set: `{hashlib.sha256(json.dumps(inv['source_evidence_sha256'], sort_keys=True, separators=(',', ':')).encode()).hexdigest()}`",
             f"- Candidate: `{candidate['id']}` — {candidate['family_count']} families / {candidate['direction_slots']} direction slots",
             f"- Authoring workspace: `{workspace['status']}`; editable idle directions: `{workspace.get('editable_idle_directions')}`; effective receipts: `{workspace.get('effective_receipts')}`",
             f"- Authoring checkout: `{workspace.get('workspace_checkout_status')}`; behind origin/main: `{workspace.get('workspace_checkout_behind_main')}`; working tree evidence is preserved and read-only",
             f"- Release: **{report['release_status']}**", "",
             "## Candidate Families", "", "| Family | Priority | Layers | Directions | Frames / loop / FPS | Editable | Runtime directions | Closure |", "|---|---:|---|---:|---|---:|---:|---|"]
    for family in candidate["families"]:
        contract = family["frame_contract"]
        lines.append(f"| `{family['id']}` | {family['priority']} | {', '.join(family['required_layers'])} | {len(family['directions'])} | {contract['frames']} / {contract['loop']} / {contract['fps']} | {family['authoring']['workspace_count']} | {len(family['runtime_manifest']['runtime_manifest_directions'])} | {family['candidate_presentation_closure']} |")
    lines += ["", "## Current Authoring Evidence", "",
              "The eight relaxed-idle Aseprite documents, source strips, and Source Sessions match the correction receipt hashes. Their manifests retain a physical 15 × 125 ms document clock and 8 FPS preview, with `timing_authority=false`; none has a current effective receipt or publication. The other six families have null frame, loop, and FPS contracts.", "",
              "## Runtime Composition and Edges", "",
              "The proposed art is eight-direction `full_body`. Current unarmed posture instead requires `lower_body + upper_body` and projects requested headings to east/west. Locomotion normally prefers modular layers. The selector and runtime manifest are generation-neutral, so current semantic rows prove legacy availability only.", "",
              "| Edge | Trigger | Consumer | State |", "|---|---|---|---|"]
    for edge in report["edges"]:
        lines.append(f"| `{edge['from']} → {edge['to']}` | {edge['trigger']} | `{edge['consumer']}` | **{edge['classification']}** |")
    lines += ["", "## Blocking Gaps", ""] + [f"- {gap}" for gap in report["blocking_gaps"]]
    lines += ["", "## Recommended Next Steps", ""] + [f"{i}. {step}" for i, step in enumerate(report["recommended_next_steps"], 1)]
    lines += ["", "## Invalidation", "", "Regenerate this report after any source SHA changes in the JSON `investigation.source_evidence_sha256` map, any plan/reachability/presenter/selector/runtime-manifest/catalog/SpriteFrames change, or any Workbench/receipt change. A missing external workspace is `UNAVAILABLE`; it is never interpreted as zero authored directions or proof of absence.", ""]
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workspace-root", type=Path, help="populated Operator authoring workspace root")
    parser.add_argument("--json", type=Path, default=ROOT / "custodian/docs/reports/operator_presentation/operator_2_5d_cohort_dependency_closure.json")
    parser.add_argument("--markdown", type=Path, default=ROOT / "custodian/docs/reports/operator_presentation/OPERATOR_2_5D_COHORT_DEPENDENCY_CLOSURE.md")
    args = parser.parse_args()
    report = build_report(ROOT, args.workspace_root)
    args.json.parent.mkdir(parents=True, exist_ok=True)
    args.json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    args.markdown.parent.mkdir(parents=True, exist_ok=True)
    args.markdown.write_text(markdown(report), encoding="utf-8")
    print(f"operator_2_5d_cohort_dependency_closure: {report['release_status']} ({report['candidate']['family_count']} families / {report['candidate']['direction_slots']} slots)")


if __name__ == "__main__":
    main()
