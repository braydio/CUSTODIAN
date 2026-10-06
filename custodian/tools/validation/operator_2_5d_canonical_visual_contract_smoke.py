#!/usr/bin/env python3
"""Focused proof for the Operator 2.5D canonical visual contract."""
from __future__ import annotations

import copy
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "custodian/tools/operator"))
sys.path.insert(0, str(ROOT / "custodian/tools/art"))

from art_agent import canonical_contract as cc
from art_agent import landmarks as landmark_store
from art_agent import canonical_calibration as calibration
from art_agent.registration_profile import CANONICAL_PROFILE_ID, LEGACY_PROFILE_ID, ProfileNotAccepted, load_profile, require_accepted

EXPECTED_ORDER = ["n", "ne", "e", "se", "s", "sw", "w", "nw"]


def codes(findings, severity=None):
    return {f["code"] for f in findings if severity is None or f["severity"] == severity}


def scaled_about_floor(image: Image.Image, factor: float) -> Image.Image:
    size = int(round(cc.FRAME * factor))
    big = image.resize((size, size), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", image.size, (0, 0, 0, 0))
    canvas.alpha_composite(big, (cc.CENTER_X - size // 2, cc.SUPPORT_ROW + 1 - int(round((cc.SUPPORT_ROW + 1) * factor))))
    return canvas


def recolor(image: Image.Image, fn) -> Image.Image:
    data = np.array(image)
    mask = data[..., 3] > 0
    data[..., :3][mask] = fn(data[..., :3][mask].astype(np.int32)).clip(0, 255).astype(np.uint8)
    return Image.fromarray(data, "RGBA")


def aseprite_checks(temp: Path) -> str:
    aseprite = shutil.which("aseprite")
    if aseprite is None:
        return "SKIP aseprite guide-leak check: executable unavailable"
    script = ROOT / "custodian/tools/aseprite/operator_anchor_guides.lua"
    inspect = temp / "inspect.lua"
    inspect.write_text(
        'local names = {}\n'
        'local function walk(layers) for _, l in ipairs(layers) do table.insert(names, l.name .. ":" .. tostring(l.isEditable)); '
        'if l.isGroup then walk(l.layers) end end end\n'
        'walk(app.activeSprite.layers)\n'
        'local f = io.open(app.params["out"], "w"); f:write(table.concat(names, "\\n")); f:close()\n'
        'local function hide(layers) for _, l in ipairs(layers) do if string.sub(l.name, 1, 12) == "__ART_GUIDE_" then l.isVisible = false '
        'elseif l.isGroup then hide(l.layers) end end end\n'
        'hide(app.activeSprite.layers)\n'
        'app.activeSprite:saveCopyAs(app.params["clean"])\n', encoding="utf-8")
    for size, params in ((128, ["direction=e"]), (128, ["direction=grid"]), (96, [])):
        width = size * (8 if params == ["direction=grid"] else 1)
        base = temp / f"base_{size}_{len(params)}_{width}.png"
        image = Image.new("RGBA", (width, size), (0, 0, 0, 0))
        image.putpixel((3, 3), (200, 10, 10, 255))
        image.save(base)
        argv = [aseprite, "-b", str(base), "--script-param", f"repo={ROOT}"]
        for item in params:
            argv += ["--script-param", item]
        guided, again = temp / f"g_{size}_{width}.aseprite", temp / f"g2_{size}_{width}.aseprite"
        subprocess.run(argv + ["--script", str(script), "--save-as", str(guided)], check=True, capture_output=True, text=True, timeout=90)
        subprocess.run([aseprite, "-b", str(guided), "--script-param", f"repo={ROOT}"] + [x for p in params for x in ("--script-param", p)] +
                       ["--script", str(script), "--save-as", str(again)], check=True, capture_output=True, text=True, timeout=90)
        out, clean = temp / f"layers_{size}_{width}.txt", temp / f"clean_{size}_{width}.png"
        subprocess.run([aseprite, "-b", str(again), "--script-param", f"out={out}", "--script-param", f"clean={clean}",
                        "--script", str(inspect)], check=True, capture_output=True, text=True, timeout=90)
        layers = out.read_text().splitlines()
        guides = [name for name in layers if "__ART_GUIDE_OPERATOR" in name]
        assert all(name.endswith(":false") for name in guides), ("guide layers must be locked", guides)
        assert sum(1 for n in layers if n.startswith("__ART_GUIDE_OPERATOR_REGISTRATION:")) == 1, ("guide replacement is not idempotent", layers)
        if size == 128:
            for expected in ("FLOOR", "CENTER", "BODY", "CANONICAL_REFERENCE"):
                assert sum(1 for n in layers if n.startswith(f"__ART_GUIDE_OPERATOR_{expected}:")) == 1, (expected, layers)
        else:
            assert not any("CANONICAL_REFERENCE" in n for n in layers), "legacy mode must not draw the 128 ghost"
        with Image.open(clean) as rendered, Image.open(base) as original:
            assert rendered.convert("RGBA").tobytes() == original.convert("RGBA").tobytes(), "guides leaked into the clean render"
        flat = temp / f"flat_{size}_{width}.png"
        subprocess.run([aseprite, "-b", str(again), "--save-as", str(flat)], check=True, capture_output=True, timeout=90)
        with Image.open(flat) as visible, Image.open(base) as original:
            assert visible.convert("RGBA").tobytes() != original.convert("RGBA").tobytes(), "guides are not visible in the editor composite"
    return "aseprite: 4 locked layers (128) / ruler (96), idempotent, excluded from clean render"


def main() -> int:
    # 1-2 source identity and cell reconstruction
    manifest = json.loads(cc.MANIFEST_PATH.read_text())
    master = cc.SOURCE_DIR / cc.MASTER_NAME
    identity = cc.verify_master(master)
    assert identity["sha256"] == manifest["sha256"] == "37e080b8dda825dcfe048439e12f0ad4a66c70b33393d3296cd550761e1b0621"
    assert identity["dimensions"] == [3840, 480] and manifest["order"] == EXPECTED_ORDER and manifest["cell_size"] == [480, 480]
    assert manifest["provenance"] == "user_approved_visual_lock"
    root_copy = ROOT / cc.MASTER_NAME
    assert not root_copy.exists() or root_copy.read_bytes() == master.read_bytes(), "preserved master differs from the committed root file"
    cells = [Image.open(cc.SOURCE_DIR / "source_cells" / f"{d}_source.png").convert("RGBA") for d in EXPECTED_ORDER]
    assert all(c.size == (480, 480) for c in cells)
    assert cc.reconstruct(cells).tobytes() == Image.open(master).convert("RGBA").tobytes()
    for d in EXPECTED_ORDER:
        assert manifest["cells"][d]["sha256"] == cc.sha256_file(cc.SOURCE_DIR / "source_cells" / f"{d}_source.png")

    # 3-5 profile registry: v1/v2 readable, legacy selectable, canonical default
    with tempfile.TemporaryDirectory(prefix="operator-canonical-contract-") as td:
        temp = Path(td)
        v3 = json.loads(cc.PROFILE_PATH.read_text())
        legacy_registration = v3["profiles"][LEGACY_PROFILE_ID]["registration"]
        v2 = {"schema": "custodian.operator_art_profile.v2", "status": "provisional", "enforcement": {"structural": True},
              "registration": legacy_registration, "measurements": {}}
        (temp / "v2.json").write_text(json.dumps(v2))
        loaded_v2 = load_profile(temp / "v2.json")
        assert loaded_v2["profile_id"] == LEGACY_PROFILE_ID and loaded_v2["registration"]["anchor"] == [48, 84]
        assert loaded_v2["sha256"] == loaded_v2["file_sha256"], "v2 identity must stay the file hash"
        (temp / "v1.json").write_text(json.dumps({"schema": "custodian.operator_art_profile.v1"}))
        assert load_profile(temp / "v1.json")["registration"] is None
        legacy = load_profile(profile_id=LEGACY_PROFILE_ID)
        assert legacy["registration"]["frame_size"] == [96, 96] and legacy["registration"]["anchor"] == [48, 84]
        assert legacy["registration"] == legacy_registration
        assert legacy["accepted"] is True and legacy["registration_status"] == "accepted"
        canonical = load_profile()
        assert canonical["profile_id"] == CANONICAL_PROFILE_ID == v3["active_authoring_profile"]
        reg = canonical["registration"]
        assert reg["frame_size"] == [128, 128] and reg["anchor"] == [64, 111] and reg["ground_y"] == 112
        # a) provisional 128 loads for calibration; b) legacy stays accepted; c) acceptance-only operations reject provisional
        assert reg["status"] == "provisional" and canonical["registration_status"] == "provisional" and canonical["accepted"] is False
        assert reg["authority"]["root_floor"] == "pending_human_calibration" and reg["authority"]["shared_body_scale"] == "pending_ab_approval"
        assert require_accepted(legacy, operation="legacy production")["profile_id"] == LEGACY_PROFILE_ID
        try:
            require_accepted(canonical, operation="production handoff")
        except ProfileNotAccepted as error:
            assert "PROFILE_NOT_ACCEPTED" in str(error)
        else:
            raise AssertionError("acceptance-only operation accepted a provisional profile")
        bad_legacy = copy.deepcopy(v2); bad_legacy["registration"]["status"] = "provisional"
        (temp / "bad_legacy.json").write_text(json.dumps(bad_legacy))
        try:
            load_profile(temp / "bad_legacy.json")
        except ValueError:
            pass
        else:
            raise AssertionError("legacy 96 profile must not be loadable as provisional")
        assert load_profile(frame_size=[96, 96])["profile_id"] == LEGACY_PROFILE_ID
        assert load_profile(frame_size=[128, 128])["profile_id"] == CANONICAL_PROFILE_ID
        assert legacy["sha256"] != canonical["sha256"]
        assert canonical["canonical_visual_reference"]["sha256"] == manifest["sha256"]
        assert canonical["sha256"] == cc.effective_profile_hash(v3), "effective profile hash must be reproducible"
        try:
            load_profile(profile_id="nope")
        except ValueError:
            pass
        else:
            raise AssertionError("unknown profile id accepted")

        # 6-8 directions, order and landmark vocabulary
        reference = cc.load_reference()
        assert list(reference["directions"]) == EXPECTED_ORDER == list(reference["source"]["order"])
        assert v3["profiles"][CANONICAL_PROFILE_ID]["direction_order"] == EXPECTED_ORDER
        schema_names = set(json.loads((ROOT / "custodian/content/data/operator/authoring/operator_landmark_schema.json").read_text())["names"])
        assert set(cc.LANDMARK_ORDER) <= landmark_store.LANDMARK_NAMES and set(cc.LANDMARK_ORDER) <= schema_names
        for d in EXPECTED_ORDER:
            png = ROOT / reference["directions"][d]["reference_png"]
            image = Image.open(png).convert("RGBA")
            assert image.size == (128, 128) and cc.sha256_file(png) == reference["directions"][d]["reference_sha256"]
            alpha = np.array(image)[..., 3]
            assert set(np.unique(alpha)) <= {0, 255}, "reference must keep crisp binary alpha"
            for space in ("source", "normalized_128"):
                points = reference["directions"][d]["landmarks"][space]
                assert list(points) == list(cc.LANDMARK_ORDER)
                for p in points.values():
                    assert 0.0 <= p["confidence"] <= 1.0 and p["provenance"]
            assert reference["directions"][d]["registration"]["support_contact_y"] == cc.SUPPORT_ROW
        assert (ROOT / reference["rotation_lock"]["path"]).is_file()
        # one shared scale, integer-only translation: normalized pixels are the shared reduction shifted by an integer
        for d, cell in zip(EXPECTED_ORDER, cells):
            reduced = cc.normalize_cell(cell)
            ox, oy = reference["directions"][d]["registration"]["offset_xy"]
            assert isinstance(ox, int) and isinstance(oy, int)
            shifted = Image.new("RGBA", (128, 128), (0, 0, 0, 0)); shifted.alpha_composite(reduced, (ox, oy))
            assert shifted.tobytes() == Image.open(ROOT / reference["directions"][d]["reference_png"]).convert("RGBA").tobytes()

        # 9 determinism: recompute from preserved bytes and annotations, compare to committed measurements
        annotations = cc.load_annotations()
        for d, cell in zip(EXPECTED_ORDER, cells):
            runs = []
            for _ in range(2):
                pts = cc.refine_source_landmarks(cell, annotations["directions"][d])
                norm = cc.normalize_direction(cell, pts)
                geometry = cc.silhouette_metrics(norm["image"])
                runs.append((norm["image"].tobytes(), json.dumps([geometry, cc.color_metrics(norm["image"], cc.head_band(norm["points"])),
                                                                  cc.outline_metrics(norm["image"])], sort_keys=True)))
            assert runs[0] == runs[1], f"non-deterministic measurement: {d}"
            committed = reference["directions"][d]
            assert cc.silhouette_metrics(norm["image"])["alpha_bbox"] == committed["geometry"]["alpha_bbox"]
            assert cc.color_metrics(norm["image"], cc.head_band(norm["points"])) == committed["color"]
            assert cc.outline_metrics(norm["image"]) == committed["outline"]
        assert len(reference["rotational_continuity"]) == 8 and reference["rotational_continuity"][-1]["to"] == "n"

        # canonical references pass their own QA cleanly
        for d in EXPECTED_ORDER:
            result = cc.evaluate_animation([cc.load_direction_image(d)], d, reference=reference)
            assert result["status"] == "PASS", (d, result["findings"])

        # 10 intentional scale / anchor drift is caught
        south = cc.load_direction_image("s")
        grown = scaled_about_floor(south, 1.15)
        assert "BODY_SCALE_DRIFT" in codes(cc.evaluate_frame(grown, "s", reference=reference), "STRUCTURAL_WARN")
        shifted = Image.new("RGBA", south.size, (0, 0, 0, 0)); shifted.alpha_composite(south, (0, -5))
        assert "SUPPORT_ROOT_DRIFT" in codes(cc.evaluate_frame(shifted, "s", reference=reference), "STRUCTURAL_WARN")
        animation = cc.evaluate_animation([south, grown], "s", reference=reference)
        assert animation["status"] == "HARD_FAIL" and "PER_FRAME_SCALE" in codes(animation["findings"], "HARD_FAIL")
        assert "FRAME_SIZE" in codes(cc.evaluate_frame(south.resize((96, 96), Image.Resampling.NEAREST), "s", reference=reference), "HARD_FAIL")
        fringe = np.array(south); idx = np.argwhere(fringe[..., 3] == 255)[0]; fringe[idx[0], idx[1], 3] = 100
        assert "ALPHA_CONTRACT" in codes(cc.evaluate_frame(Image.fromarray(fringe, "RGBA"), "s", reference=reference), "HARD_FAIL")
        clipped = Image.new("RGBA", south.size, (0, 0, 0, 0)); clipped.alpha_composite(south, (0, 40))
        assert "CLIPPING" in codes(cc.evaluate_frame(clipped, "s", reference=reference), "HARD_FAIL")
        stale = cc.evaluate_animation([south], "s", reference=reference, profile_sha256="0" * 64, expected_profile_sha256=canonical["sha256"])
        assert "PROFILE_IDENTITY" in codes(stale["findings"], "HARD_FAIL")
        landmarks = {n: {"x": p["x"], "y": p["y"]} for n, p in reference["directions"]["s"]["landmarks"]["normalized_128"].items()}
        assert not codes(cc.evaluate_frame(south, "s", reference=reference, landmarks=landmarks), "STRUCTURAL_WARN")
        stretched = copy.deepcopy(landmarks); stretched["hand_near"]["y"] += 12; stretched["knee_near"]["y"] += 9
        assert "LIMB_RATIO_DRIFT" in codes(cc.evaluate_frame(south, "s", reference=reference, landmarks=stretched), "STRUCTURAL_WARN")
        off_center = copy.deepcopy(landmarks); off_center["hip_center"]["x"] += 6
        assert "HIP_CENTER_DRIFT" in codes(cc.evaluate_frame(south, "s", reference=reference, landmarks=off_center), "STRUCTURAL_WARN")
        # intentional pose motion stays INFO, not a structural failure
        crouch = Image.new("RGBA", south.size, (0, 0, 0, 0)); crouch.alpha_composite(south, (0, 3))
        pose = cc.evaluate_frame(crouch, "s", reference=reference, baseline=False)
        assert "POSE_MOTION" in codes(pose, "INFO") and not codes(pose, "HARD_FAIL") and not codes(pose, "STRUCTURAL_WARN")

        # 11 palette / brightness drift is reported (art direction), not structural
        darker = recolor(south, lambda rgb: rgb * 0.6)
        palette = cc.evaluate_frame(darker, "s", reference=reference)
        assert "PALETTE_DRIFT" in codes(palette, "ART_DIRECTION_WARN") and not codes(palette, "HARD_FAIL") and not codes(palette, "STRUCTURAL_WARN")
        bluegold = recolor(south, lambda rgb: rgb[:, [2, 1, 0]])
        hue_swapped = cc.evaluate_frame(bluegold, "s", reference=reference)
        assert {"PALETTE_DRIFT", "GOLD_TRIM_PRESENCE"} & codes(hue_swapped, "ART_DIRECTION_WARN") and not codes(hue_swapped, "STRUCTURAL_WARN")

        # provisional authority flows through Source Sessions: planning (calibration) works, production/handoff are refused
        from art_agent.source_service import SourceArtService
        import animation_workbench_model as workbench_model
        source_root = temp / "inbox"; source_root.mkdir()
        source = source_root / "synthetic.png"
        fixture = Image.new("RGBA", (768, 768), (0, 0, 0, 0))
        from PIL import ImageDraw
        draw = ImageDraw.Draw(fixture)
        draw.ellipse((300, 40, 468, 210), fill=(20, 20, 25, 255)); draw.rectangle((250, 210, 518, 470), fill=(40, 40, 45, 255))
        draw.rectangle((270, 450, 350, 650), fill=(60, 50, 45, 255)); draw.rectangle((420, 450, 500, 650), fill=(60, 50, 45, 255)); fixture.save(source)
        service = SourceArtService(root=temp / "sessions", allowed_source_roots=(source_root,), handoff_root=temp / "handoff", canonical_root=temp / "canonical")
        session_path = service.start(source_path=source, frames=1)       # default target size is the canonical 128
        assert service.load(session_path)[0].target_width == 128
        service.analyze(session_path)
        service.set_source_landmarks(session_path, [
            {"frame": 1, "name": "head_center", "x": 384, "y": 125, "semantic_side": "center", "confidence": 1.0, "provenance": "human", "approved": True},
            {"frame": 1, "name": "hip_center", "x": 384, "y": 397, "semantic_side": "center", "confidence": 1.0, "provenance": "human", "approved": True},
            {"frame": 1, "name": "toe_near", "x": 310, "y": 650, "semantic_side": "near", "confidence": 1.0, "provenance": "human", "approved": True},
            {"frame": 1, "name": "toe_far", "x": 460, "y": 650, "semantic_side": "far", "confidence": 1.0, "provenance": "human", "approved": True}])
        service.render_source(session_path)
        plan = service.plan_normalization(session_path, mode="operator_profile")
        assert plan["profile_id"] == CANONICAL_PROFILE_ID and plan["profile_sha256"] == canonical["sha256"]
        try:
            service.production_command(session_path)
        except workbench_model.WorkbenchError as error:
            assert "PROFILE_NOT_ACCEPTED" in str(error)
        else:
            raise AssertionError("production command accepted a provisional profile")

        # root/floor: five separate concepts per direction; 111 is a support baseline, not a proven world root
        for d in EXPECTED_ORDER:
            model = reference["directions"][d]["root_model"]
            for concept in ("hip_center", "left_foot_contact", "right_foot_contact", "projected_world_root", "shadow_origin"):
                assert concept in model, (d, concept)
            assert model["left_foot_contact"]["x"] <= model["right_foot_contact"]["x"]
            assert model["projected_world_root"]["proven"] is False and "pending_human_calibration" in model["projected_world_root"]["status"]
            assert model["shadow_origin"]["proven"] is False
            assert model["support_baseline_row"] == cc.SUPPORT_ROW
        global_root = reference["root_model"]
        assert global_root["status"] == "pending_human_calibration" and abs(global_root["median_foot_contact_midpoint_y"] - 107.45) <= 0.05
        assert global_root["median_foot_contact_midpoint_y"] != cc.SUPPORT_ROW and global_root["comparison_candidate_root_rows"] == [106, 107, 108]
        assert reference["authority"] == cc.AUTHORITY and cc.AUTHORITY["profile_128"] == "provisional"

        # scale A/B: one shared scale per candidate, same canvas and root model, no per-direction scaling
        assert cc.SCALE_CANDIDATES == {"A": (1, 5), "B": (9, 40)}
        for key, pair in cc.SCALE_CANDIDATES.items():
            folder = calibration.SCALE_DIR / calibration.SCALE_DIRNAMES[key]
            for d, cell in zip(EXPECTED_ORDER, cells):
                png = Image.open(folder / f"{d}.png").convert("RGBA")
                assert png.size == (128, 128)
                reduced = cc.normalize_cell(cell, pair)
                pts = cc.refine_source_landmarks(cell, annotations["directions"][d])
                norm = cc.normalize_direction(cell, pts, pair)
                ox, oy = norm["offset"]
                shifted = Image.new("RGBA", (128, 128), (0, 0, 0, 0)); shifted.alpha_composite(reduced, (ox, oy))
                assert shifted.tobytes() == png.tobytes(), (key, d)
                assert cc.silhouette_metrics(png)["alpha_bbox"][3] == cc.SUPPORT_ROW + 1
        ab = json.loads((cc.REPORT_DIR / "operator_2_5d_scale_ab_summary.json").read_text())
        assert ab["status"] == "pending_human_scale_choice"
        assert ab["candidates"]["A"]["height_px"]["median"] < 84 <= ab["candidates"]["B"]["height_px"]["median"] <= 88
        assert ab["candidates"]["B"]["within_previous_runtime_candidate_range"] is True
        assert (cc.REPORT_DIR / "operator_2_5d_scale_ab_comparison.png").is_file() and (cc.REPORT_DIR / "operator_2_5d_registration_overlay.png").is_file()

        # pixel cleanup certification: zero-change receipt; a contaminated fixture is proposed (not applied) and flagged
        receipt = json.loads((cc.REPORT_DIR / "operator_2_5d_cleanup_certification.json").read_text())
        assert receipt["status"] == "zero_change" and receipt["applied"] is False
        for key in ("A", "B"):
            for d, entry in receipt["candidates"][key]["directions"].items():
                assert entry["changed_pixels"] == [] and entry["alpha_mask_equal"] and entry["component_topology_equal"]
                assert entry["before_rgba_sha256"] == entry["after_rgba_sha256"]
        assert "pending" in receipt["final_normalized_hash"]
        dirty = np.array(south); ys, xs = np.where(dirty[..., 3] == 255)
        dirty[ys[40], xs[40], :3] = (20, 40, 255)                              # blue contaminant inside the body
        dirty[2, 2] = (255, 255, 255, 255)                                      # detached 1px island
        proposal = calibration.propose_cleanup(Image.fromarray(dirty, "RGBA"))
        kinds = {c["kind"] for c in proposal["changed"]}
        assert kinds == {"contaminant_recolor", "island_removed"}
        assert proposal["counts"]["contaminant_pixels"] == 1 and proposal["counts"]["detached_islands_1_2px"] == 1
        assert not np.array_equal(np.array(proposal["cleaned"].getchannel("A")), dirty[..., 3]), "island removal must be visible as an alpha change"

        # action envelope: evidence only; body never shrunk; weapon/fx separate
        envelope = json.loads((cc.REPORT_DIR / "operator_2_5d_action_envelope.json").read_text())
        assert "NOT proven" in envelope["status"] and set(envelope["classes"]) == set(calibration.ENVELOPE_CLASSES)
        for name, info in envelope["classes"].items():
            assert info["sheets_measured"] > 0 and set(info["body_worst"]) == {"up", "down", "left", "right"}, name
            assert "presentation_worst" in info
        assert "never shrunk" in envelope["method"]

        # report states the freeze status
        report_text = (cc.REPORT_DIR / "OPERATOR_2_5D_CANONICAL_VISUAL_CONTRACT_REPORT.md").read_text()
        for phrase in ("visual design | locked", "camera projection | locked", "profile 128 | provisional", "root floor | pending human calibration",
                       "shared body scale | pending ab approval", "universal 128 envelope | pending proof", "final normalized hash | pending cleanup certification"):
            assert phrase in report_text, phrase

        # 12 guide layers cannot leak into the clean render / publish
        guide = (ROOT / "custodian/tools/aseprite/operator_anchor_guides.lua").read_text()
        bridge = (ROOT / "custodian/tools/aseprite/operator_live_bridge/art_agent_ops.lua").read_text()
        for name in ("FLOOR", "CENTER", "BODY", "CANONICAL_REFERENCE"):
            assert f"__ART_GUIDE_OPERATOR_{name}" in guide
        assert "isEditable = false" in guide and "sprite:deleteLayer(layer)" in guide and "profile_id" in guide
        assert '"__ART_GUIDE_"' in bridge and "local function internal(layer)" in bridge
        for forbidden in ("[64, 111]", "ground_y = 112", "hips = 77"):
            assert forbidden not in guide, "guide script must not retype geometry constants"
        note = aseprite_checks(temp)

    print(f"PASS operator_2_5d_canonical_visual_contract_smoke: source lock, cells, provisional-vs-accepted profile registry, root model, scale A/B, cleanup receipt, envelope, 8 directions, deterministic metrics, drift QA, guides ({note})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
