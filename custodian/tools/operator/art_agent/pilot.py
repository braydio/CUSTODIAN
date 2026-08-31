from __future__ import annotations

import hashlib
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from PIL import Image

import animation_workbench as workbench
import animation_workbench_model as model

from . import masks as mask_store
from .metrics import animation_metrics
from .render import make_before_after, make_diff
from .service import ArtAgentService, write_json


RESULT_SCHEMA = "custodian.operator_art_agent.v2_pilot_result.v1"
IDENTITY = {
    "profile": "melee_1h",
    "group": "locomotion",
    "action": "walk_01",
    "direction": "e",
}
WEAPON = "vigil_pattern_dagger"
REQUIRED_LANDMARKS = (
    "head_center", "hip_center", "knee_near", "knee_far",
    "ankle_near", "ankle_far", "toe_near", "toe_far",
    "weapon_grip", "weapon_tip",
)
PROTECTED_ROOTS = (
    "custodian/content/sprites/operator/source/animations",
    "custodian/content/sprites/operator/runtime/animations",
    "custodian/content/data/operator/generated",
    "custodian/game/actors/operator",
)


class PilotFailure(RuntimeError):
    def __init__(self, gate: str, reason: str):
        super().__init__(reason)
        self.gate = gate
        self.reason = reason


def _require(condition: bool, gate: str, reason: str) -> None:
    if not condition:
        raise PilotFailure(gate, reason)


def _timestamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")


def _tree_hashes(repo_root: Path) -> dict[str, dict[str, Any]]:
    result: dict[str, dict[str, Any]] = {}
    for relative_root in PROTECTED_ROOTS:
        root = repo_root / relative_root
        if not root.exists():
            continue
        for path in sorted(item for item in root.rglob("*") if item.is_file()):
            relative = str(path.relative_to(repo_root))
            data = path.read_bytes()
            result[relative] = {"sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data)}
    return result


def _copy_artifacts(artifacts: dict[str, Any], report: Path, prefix: str) -> list[Path]:
    mapping = {
        "strip": f"{prefix}_strip.png",
        "contact_sheet": f"{prefix}_contact_sheet.png",
        "animation": f"{prefix}_animation.gif",
        "silhouette": f"{prefix}_silhouette.png",
        "onion_skin": f"{prefix}_onion_skin.png",
    }
    copied: list[Path] = []
    for key, name in mapping.items():
        if key not in artifacts:
            continue
        destination = report / name
        shutil.copy2(Path(artifacts[key]), destination)
        copied.append(destination)
    return copied


def _write(path: Path, value: Any) -> None:
    write_json(path, value if isinstance(value, dict) else {"items": value})


def _frame_images(service: ArtAgentService, session: Path, *, mode: str = "clean", layer: str = "", include_drafts: bool = True) -> list[Image.Image]:
    artifacts = service.render(session, mode=mode, layer=layer, include_drafts=include_drafts)
    return [Image.open(path).convert("RGBA") for path in artifacts["frames"]]


def _close_images(images: list[Image.Image]) -> None:
    for image in images:
        image.close()


def _alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise PilotFailure("semantic_resolution", "resolved animation contains an empty frame")
    return bbox


def _landmark_fixtures(clean: list[Image.Image], lower: list[Image.Image], weapon: list[Image.Image]) -> list[dict[str, Any]]:
    values: list[dict[str, Any]] = []
    for index, (composite, legs, blade) in enumerate(zip(clean, lower, weapon), 1):
        x0, y0, x1, y1 = _alpha_bbox(composite)
        lx0, ly0, lx1, ly1 = _alpha_bbox(legs)
        weapon_box = blade.getchannel("A").getbbox()
        center_x = round((x0 + x1 - 1) / 2)
        leg_center = round((lx0 + lx1 - 1) / 2)
        leg_width = max(2, lx1 - lx0)
        near_x = min(95, leg_center + max(1, leg_width // 5))
        far_x = max(0, leg_center - max(1, leg_width // 5))
        hip_y = min(95, ly0 + round((ly1 - ly0) * 0.34))
        knee_y = min(95, ly0 + round((ly1 - ly0) * 0.62))
        ankle_y = min(95, ly0 + round((ly1 - ly0) * 0.84))
        toe_y = min(95, ly1 - 1)
        if weapon_box:
            wx0, wy0, wx1, wy1 = weapon_box
            grip = (wx0, round((wy0 + wy1 - 1) / 2))
            tip = (wx1 - 1, wy0)
        else:
            grip = (min(95, x1 - 1), min(95, y0 + (y1 - y0) // 2))
            tip = (min(95, x1 - 1), y0)
        points = {
            "head_center": (center_x, y0 + max(1, (y1 - y0) // 7), "center"),
            "hip_center": (leg_center, hip_y, "center"),
            "knee_near": (near_x, knee_y + 1, "near"),
            "knee_far": (far_x, max(0, knee_y - 1), "far"),
            "ankle_near": (near_x, ankle_y + 1, "near"),
            "ankle_far": (far_x, max(0, ankle_y - 1), "far"),
            "toe_near": (min(95, near_x + 2), toe_y, "near"),
            "toe_far": (max(0, far_x - 2), max(0, toe_y - 1), "far"),
            "weapon_grip": (*grip, "none"),
            "weapon_tip": (*tip, "none"),
        }
        for name, (x, y, side) in points.items():
            values.append({
                "frame": index, "name": name, "x": int(x), "y": int(y),
                "semantic_side": side, "confidence": 0.45,
                "provenance": "pilot_fixture", "approved": False,
            })
    return values


def _select_crossover_frame(lower: list[Image.Image]) -> int:
    candidates = []
    for frame, image in enumerate(lower, 1):
        x0, y0, x1, y1 = _alpha_bbox(image)
        candidates.append((x1 - x0, abs(frame - (len(lower) + 1) / 2), frame))
    return min(candidates)[2]


def _leg_rects(image: Image.Image) -> tuple[list[int], list[int]]:
    x0, y0, x1, y1 = _alpha_bbox(image)
    hip = y0 + max(1, round((y1 - y0) * 0.28))
    width = x1 - x0
    split = x0 + max(1, width // 2)
    far = [x0, hip, max(1, split - x0 + 1), y1 - hip]
    near = [split, hip, max(1, x1 - split), y1 - hip]
    return near, far


def _mask_has_pixels(image: Image.Image, mask: dict[str, Any]) -> bool:
    alpha = image.getchannel("A")
    return any(alpha.getpixel((x, span["y"])) for span in mask["spans"] for x in range(span["x0"], span["x1"] + 1))


def _cleanup_pixel(image: Image.Image, mask: dict[str, Any]) -> dict[str, Any]:
    pixels = image.load()
    for span in mask["spans"]:
        for x in range(span["x0"], span["x1"] + 1):
            rgba = pixels[x, span["y"]]
            if rgba[3] > 0:
                return {"x": x, "y": span["y"], "rgba": list(rgba)}
    raise PilotFailure("part_masks", "far-leg mask contains no paintable source pixel")


def _two_mask_overlay(frame: Image.Image, near: dict[str, Any], far: dict[str, Any], output: Path) -> None:
    overlay = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    pixels = overlay.load()
    for mask, color in ((near, (0, 255, 255, 120)), (far, (255, 80, 180, 120))):
        for span in mask["spans"]:
            for x in range(span["x0"], span["x1"] + 1):
                pixels[x, span["y"]] = color
    Image.alpha_composite(frame, overlay).save(output)


def _pixel_diff_count(before: Path, after: Path) -> int:
    with Image.open(before) as a_source, Image.open(after) as b_source:
        a, b = a_source.convert("RGBA"), b_source.convert("RGBA")
        _require(a.size == b.size, "semantic_draft", "baseline and draft render dimensions differ")
        return sum(left != right for left, right in zip(a.getdata(), b.getdata()))


def _layer_hashes(service: ArtAgentService, session: Path, layer: str) -> list[str]:
    frames = _frame_images(service, session, mode="layer", layer=layer)
    try:
        temporary = session.parent / "previews" / "pilot_layer_frames"
        temporary.mkdir(parents=True, exist_ok=True)
        paths = []
        for index, image in enumerate(frames, 1):
            path = temporary / f"{layer}_{index:03d}.png"
            image.save(path)
            paths.append(path)
        return [item["pixel_sha"] for item in animation_metrics(paths)["frames"]]
    finally:
        _close_images(frames)


def _finding_key(finding: dict[str, Any]) -> str:
    return json.dumps(finding, sort_keys=True)


def _status_from_qa(qa: dict[str, Any]) -> str:
    status = qa.get("status")
    if status in {"RED", "NEEDS_HUMAN_REVIEW"}:
        return status
    return "YELLOW"


def _format_text(result: dict[str, Any]) -> str:
    if result.get("engineering") == "PASS":
        return "\n".join((
            "PASS operator_art_agent_v2_pilot", "",
            "identity: melee_1h/locomotion/walk_01/e", f"weapon: {WEAPON}",
            "frames: 8", "frame_size: 96x96", "",
            "landmarks: PASS", "part_masks: PASS", "semantic_draft: PASS",
            "draft_non_destructive: PASS", "temporary_bake: PASS", "metrics: PASS",
            "qa: PASS", "review_packet: PASS", "exact_restore: PASS",
            "production_immutability: PASS", "",
            "engineering: PASS", f"art_capability: {result['art_capability']}", "",
            f"report: {result['report_path']}",
        ))
    if result.get("engineering") == "SKIP":
        return f"SKIP operator_art_agent_v2_pilot\nreason: {result.get('reason')}"
    return "\n".join((
        "FAIL operator_art_agent_v2_pilot", "",
        f"failed_gate: {result.get('failed_gate', 'unknown')}",
        f"reason: {result.get('reason', 'unknown failure')}",
        f"report: {result.get('report_path', '')}",
    ))


def print_result(result: dict[str, Any], *, json_output: bool = False) -> None:
    print(json.dumps(result, indent=2) if json_output else _format_text(result))


def run_v2_pilot(*, keep_artifacts: bool = False, allow_skip_aseprite: bool = False, repo_root: Path | None = None) -> dict[str, Any]:
    repo_root = (repo_root or model.REPO_ROOT).resolve()
    timestamp = _timestamp()
    report = repo_root / "reports/operator_art_agent/v2_pilot" / timestamp
    report.mkdir(parents=True, exist_ok=False)
    result: dict[str, Any] = {
        "schema": RESULT_SCHEMA, "timestamp": timestamp, "identity": IDENTITY,
        "weapon": WEAPON, "engineering": "FAIL", "art_capability": "RED",
        "report_path": str(report.relative_to(repo_root)), "artifact_paths": {},
    }
    aseprite = workbench.resolve_aseprite()
    if aseprite is None:
        result.update({"engineering": "SKIP" if allow_skip_aseprite else "FAIL", "failed_gate": "aseprite", "reason": "Aseprite executable unavailable"})
        _write(report / "pilot_result.json", result)
        return result

    service = ArtAgentService(aseprite=aseprite)
    session: Path | None = None
    baseline_bytes: bytes | None = None
    workbench_path: Path | None = None
    production_before = _tree_hashes(repo_root)
    _write(report / "production_before.json", production_before)
    applied_operations = 0
    try:
        session = service.start_session(**IDENTITY, weapon=WEAPON)
        loaded = service.load_session(session)
        workbench_path = Path(loaded.workbench_path)
        manifest = json.loads(Path(loaded.workbench_manifest).read_text())
        inspection = service.inspect(session)
        _require(inspection.get("canvas") == {"width": 96, "height": 96}, "semantic_resolution", f"unexpected canvas: {inspection.get('canvas')}")
        _require(inspection.get("frames") == 8, "semantic_resolution", f"unexpected frame count: {inspection.get('frames')}")
        layer_names = {item["name"] for item in inspection.get("layers", []) if item.get("editable")}
        _require({"lower_body", "upper_body"}.issubset(layer_names), "semantic_resolution", "lower_body/upper_body bindings unavailable")
        weapon_layers = sorted(name for name in layer_names if name.startswith("weapon"))
        _require(bool(weapon_layers), "semantic_resolution", "authoritative Vigil weapon presentation unavailable")
        _require(manifest.get("context", {}).get("fingerprint") == loaded.context_fingerprint, "session_safety", "context fingerprint mismatch")
        _require(not manifest.get("pending_migration"), "session_safety", "pending frame migration")
        identity_record = {"identity": inspection["identity"], "canvas": inspection["canvas"], "frames": inspection["frames"], "layers": inspection["layers"], "context_fingerprint": inspection["context_fingerprint"], "workbench": loaded.workbench_path}
        _write(report / "pilot_identity.json", identity_record)

        baseline_bytes = workbench_path.read_bytes()
        baseline_sha = hashlib.sha256(baseline_bytes).hexdigest()
        baseline_artifacts = service.render(session, mode="clean", include_drafts=False)
        _copy_artifacts(baseline_artifacts, report, "baseline")
        baseline_metrics = service.get_metrics(session)
        baseline_qa = service.run_qa(session)
        _write(report / "baseline_metrics.json", baseline_metrics)
        _write(report / "baseline_qa.json", baseline_qa)

        clean_frames = _frame_images(service, session, mode="clean", include_drafts=False)
        lower_frames = _frame_images(service, session, mode="layer", layer="lower_body")
        weapon_frames = _frame_images(service, session, mode="layer", layer=weapon_layers[0])
        try:
            fixtures = _landmark_fixtures(clean_frames, lower_frames, weapon_frames)
            saved_landmarks = service.set_landmarks(session, fixtures)
            reloaded_landmarks = service.get_landmarks(session)
            _require(saved_landmarks == reloaded_landmarks, "landmarks", "landmark service roundtrip changed data")
            _require(all(item.get("source_hash") and item.get("provenance") == "pilot_fixture" for item in reloaded_landmarks), "landmarks", "landmark provenance/source hashes missing")
            write_json(report / "landmarks.json", {"schema": "custodian.operator_landmarks.v1", "landmarks": reloaded_landmarks})

            selected_frame = _select_crossover_frame(lower_frames)
            near_rect, far_rect = _leg_rects(lower_frames[selected_frame - 1])
            near = service.define_mask(session, frame=selected_frame, layer="lower_body", part="near_leg", rect=near_rect, provenance="pilot_fixture", confidence=0.5)
            far = service.define_mask(session, frame=selected_frame, layer="lower_body", part="far_leg", rect=far_rect, provenance="pilot_fixture", confidence=0.5)
            _require(near["mask_id"] != far["mask_id"] and near["spans"] != far["spans"], "part_masks", "near/far masks are not distinguishable")
            _require(_mask_has_pixels(lower_frames[selected_frame - 1], near) and _mask_has_pixels(lower_frames[selected_frame - 1], far), "part_masks", "leg mask contains no source pixels")
            cleanup_pixel = _cleanup_pixel(lower_frames[selected_frame - 1], far)
            for mask in (near, far):
                restored = mask_store.PartMask.from_json(mask)
                spans = mask_store.image_to_spans(mask_store.spans_to_image(restored.spans, (96, 96)))
                _require(spans == restored.spans, "part_masks", f"RLE roundtrip failed for {mask['mask_id']}")
            _two_mask_overlay(clean_frames[selected_frame - 1], near, far, report / "selected_frame_mask_overlay.png")
        finally:
            _close_images(clean_frames); _close_images(lower_frames); _close_images(weapon_frames)

        dx, dy = 2, -1
        fx, fy, fw, fh = far["bounds"]
        if fx + fw - 1 + dx >= 96: dx = -2
        if fy + dy < 0: dy = 1
        edit_plan = {"selected_frame": selected_frame, "part": "far_leg", "mask_id": far["mask_id"], "dx": dx, "dy": dy, "reason": "tightest mid-cycle lower-body silhouette selected as deterministic crossover proxy; bounded integer shift makes the far-leg lead visibly without transform filtering"}
        _write(report / "semantic_edit_plan.json", edit_plan)

        lower_before = _layer_hashes(service, session, "lower_body")
        upper_before = _layer_hashes(service, session, "upper_body")
        weapon_before = _layer_hashes(service, session, weapon_layers[0])
        draft_record = service.create_draft(session, kind="shift", mask_id=far["mask_id"], dx=dx, dy=dy, operation_key=f"pilot-{timestamp}-draft")
        applied_operations += 1
        draft_id = draft_record["response"].get("draft_id")
        _require(bool(draft_id and draft_id.startswith("__ART_DRAFT__")), "semantic_draft", "semantic draft layer was not created")
        _require(_layer_hashes(service, session, "lower_body") == lower_before, "draft_non_destructive", "draft changed underlying lower_body pixels")
        draft_artifacts = service.render(session, mode="clean", include_drafts=True)
        _copy_artifacts(draft_artifacts, report, "draft")
        diff_count = _pixel_diff_count(report / "baseline_strip.png", report / "draft_strip.png")
        _require(diff_count > 0, "semantic_draft", "draft render is pixel-identical to baseline")
        draft_metrics = service.get_metrics(session)
        draft_qa = service.run_qa(session, required_landmarks=list(REQUIRED_LANDMARKS))
        _write(report / "draft_metrics.json", draft_metrics); _write(report / "draft_qa.json", draft_qa)

        bake_record = service.bake_draft(session, draft_id=draft_id, operation_key=f"pilot-{timestamp}-bake")
        applied_operations += 1
        bake_response = bake_record["response"]
        _require(bool(bake_response.get("changed_bbox")), "temporary_bake", "bake did not report a changed bbox")
        cleanup_operations: list[dict[str, Any]] = []
        if bake_response.get("needs_gap_repair"):
            cleanup_record = service.apply_operation(
                session,
                {"type": "paint_pixels", "frame": selected_frame, "layer": "lower_body", "pixels": [cleanup_pixel]},
                operation_key=f"pilot-{timestamp}-gap-repair",
            )
            applied_operations += 1
            _require(cleanup_record.get("status") == "APPLIED", "gap_repair", "bounded primitive cleanup was a no-op")
            cleanup_operations.append({"type": "paint_pixels", "frame": selected_frame, "layer": "lower_body", "pixels": [cleanup_pixel]})
            resolved = service.resolve_gap_repair(session, draft_id, "pilot bounded far-leg cleanup applied and reviewed")
            _require(resolved.get("needs_gap_repair") is False, "gap_repair", "resolve_gap_repair did not clear the outstanding flag")
        lower_after = _layer_hashes(service, session, "lower_body")
        _require(lower_after[selected_frame - 1] != lower_before[selected_frame - 1], "temporary_bake", "selected lower_body frame did not change")
        _require(all(after == before for index, (after, before) in enumerate(zip(lower_after, lower_before), 1) if index != selected_frame), "temporary_bake", "unrelated lower_body frame changed")
        _require(_layer_hashes(service, session, "upper_body") == upper_before, "temporary_bake", "upper_body changed during bake")
        _require(_layer_hashes(service, session, weapon_layers[0]) == weapon_before, "temporary_bake", "weapon presentation changed during bake")
        after_inspection = service.inspect(session)
        _require(after_inspection["frames"] == 8 and after_inspection["canvas"] == {"width": 96, "height": 96}, "temporary_bake", "document contract changed during bake")

        edited_artifacts = service.render(session, mode="clean", include_drafts=False)
        _copy_artifacts(edited_artifacts, report, "edited")
        make_before_after(report / "baseline_strip.png", report / "edited_strip.png", report / "before_after.png")
        make_diff(report / "baseline_strip.png", report / "edited_strip.png", report / "diff.png")
        shutil.copy2(report / "selected_frame_mask_overlay.png", report / "mask_overlay.png")
        shutil.copy2(report / "draft_onion_skin.png", report / "edited_onion_skin.png") if not (report / "edited_onion_skin.png").exists() else None
        edited_metrics = service.get_metrics(session)
        edited_qa = service.run_qa(session, required_landmarks=list(REQUIRED_LANDMARKS))
        _write(report / "edited_metrics.json", edited_metrics); _write(report / "edited_qa.json", edited_qa)
        baseline_keys = {_finding_key(item) for item in baseline_qa.get("findings", [])}
        pre_existing = baseline_qa.get("findings", [])
        new_findings = [item for item in edited_qa.get("findings", []) if _finding_key(item) not in baseline_keys]

        operations_path = session.parent / "operations.jsonl"
        operations = [json.loads(line) for line in operations_path.read_text().splitlines() if line]
        _write(report / "operations.json", {"operations": operations})
        review = service.build_review_packet(session, task="Operator Art Agent V2 semantic far-leg pilot")
        edited_report_artifacts = {"strip": "edited_strip.png", "contact_sheet": "edited_contact_sheet.png", "animation": "edited_animation.gif", "silhouette": "edited_silhouette.png", "onion_skin": "edited_onion_skin.png", "before_after": "before_after.png", "diff": "diff.png", "mask_overlay": "mask_overlay.png"}
        review.update({"identity": IDENTITY, "weapon": WEAPON, "selected_frame": selected_frame, "semantic_part": "far_leg", "landmarks": "landmarks.json", "masks": [near, far], "edit_plan": edit_plan, "cleanup_operations": cleanup_operations, "artifacts": edited_report_artifacts, "metrics": "edited_metrics.json", "qa": "edited_qa.json", "baseline_artifacts": {"strip": "baseline_strip.png", "contact_sheet": "baseline_contact_sheet.png", "animation": "baseline_animation.gif", "silhouette": "baseline_silhouette.png"}, "draft_artifacts": {"strip": "draft_strip.png", "contact_sheet": "draft_contact_sheet.png", "animation": "draft_animation.gif", "silhouette": "draft_silhouette.png", "onion_skin": "draft_onion_skin.png"}, "edited_artifacts": edited_report_artifacts, "pre_existing_findings": pre_existing, "new_findings": new_findings, "operation_journal_summary": {"count": len(operations), "types": [item.get("type") for item in operations]}})
        _write(report / "review_packet.json", review)

        while applied_operations:
            service.undo_last(session)
            applied_operations -= 1
        final_bytes = workbench_path.read_bytes()
        final_sha = hashlib.sha256(final_bytes).hexdigest()
        exact_restore = final_bytes == baseline_bytes
        _require(exact_restore, "exact_restore", "Workbench bytes differ after undoing pilot mutations")
        production_after = _tree_hashes(repo_root)
        _write(report / "production_after.json", production_after)
        _require(production_after == production_before, "production_immutability", "protected Operator production files changed")

        result.update({
            "frame_count": 8, "frame_size": [96, 96], "selected_frame": selected_frame,
            "selected_part": "far_leg", "mask_ids": [near["mask_id"], far["mask_id"]],
            "baseline_workbench_sha256": baseline_sha, "final_workbench_sha256": final_sha,
            "exact_restore": exact_restore, "landmark_status": "PASS", "mask_status": "PASS",
            "draft_status": "PASS", "bake_status": "PASS", "metrics_status": "PASS",
            "qa_status": "PASS", "engineering": "PASS", "art_capability": _status_from_qa(edited_qa),
            "pre_existing_findings": pre_existing, "new_findings": new_findings,
            "production_immutability": True,
            "artifact_paths": {path.name: str(path.relative_to(repo_root)) for path in sorted(report.iterdir()) if path.is_file()},
        })
    except Exception as error:
        result.update({"engineering": "FAIL", "art_capability": "RED", "failed_gate": error.gate if isinstance(error, PilotFailure) else "runtime", "reason": str(error)})
    finally:
        if session is not None and workbench_path is not None and baseline_bytes is not None:
            try:
                while applied_operations:
                    service.undo_last(session); applied_operations -= 1
                if workbench_path.read_bytes() != baseline_bytes:
                    workbench_path.write_bytes(baseline_bytes)
                    restored = service.load_session(session)
                    restored.expected_workbench_sha256 = hashlib.sha256(baseline_bytes).hexdigest()
                    service.save_session(session, restored)
            except Exception as restore_error:
                result.update({"engineering": "FAIL", "art_capability": "RED", "failed_gate": "exact_restore", "reason": f"pilot cleanup failed: {restore_error}"})
        production_after = _tree_hashes(repo_root)
        if not (report / "production_after.json").exists():
            _write(report / "production_after.json", production_after)
        if production_after != production_before:
            result.update({"engineering": "FAIL", "art_capability": "RED", "failed_gate": "production_immutability", "reason": "protected Operator production files changed"})
        _write(report / "pilot_result.json", result)
        if session is not None and not keep_artifacts:
            shutil.rmtree(session.parent, ignore_errors=True)
    return result
