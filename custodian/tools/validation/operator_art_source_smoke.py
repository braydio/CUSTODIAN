#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
import tempfile
from dataclasses import asdict
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "custodian/tools/operator"))

import animation_workbench_model as model
from art_agent.source_models import NormalizationPlan
from art_agent.source_service import SourceArtService


def make_source(path: Path) -> None:
    sheet = Image.new("RGBA", (512, 256), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)
    # Frame one is intentionally tall; frame two crouches. Shared normalization
    # must preserve that authored height difference.
    draw.rounded_rectangle((50, 24, 205, 235), radius=24, fill=(82, 112, 132, 255))
    draw.rectangle((76, 174, 115, 235), fill=(198, 166, 92, 255))
    draw.rectangle((142, 174, 181, 235), fill=(198, 166, 92, 255))
    draw.rounded_rectangle((306, 78, 461, 235), radius=24, fill=(82, 112, 132, 255))
    draw.rectangle((331, 190, 370, 235), fill=(198, 166, 92, 255))
    draw.rectangle((398, 190, 437, 235), fill=(198, 166, 92, 255))
    sheet.save(path)


def make_grid_source(path: Path, *, frames: int = 3, columns: int = 2, rows: int = 2) -> None:
    sheet = Image.new("RGBA", (columns * 256, rows * 256), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)
    colors = tuple((255 if index % 3 == 0 else 0, 255 if index % 3 == 1 else 0, 255 if index % 3 == 2 else 0, 255) for index in range(frames))
    for index, color in enumerate(colors):
        column = index % 2
        row = index // 2
        left = column * 256 + 64
        top = row * 256 + 64
        draw.rectangle((left, top, left + 127, top + 127), fill=color)
    sheet.save(path)


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="operator-art-source-smoke-") as temp:
        root = Path(temp)
        allowed = root / "asset_drop/inbox"
        allowed.mkdir(parents=True)
        source = allowed / "highres_walk_2f.png"
        make_source(source)
        original = source.read_bytes()
        service = SourceArtService(
            root=root / ".ai/source_sessions",
            allowed_source_roots=(allowed,),
            handoff_root=allowed / "operator",
        )
        session = service.start(source_path=source, frames=2, target_size=96)
        assert service.status(session)["state"] == "STAGED"
        analysis = service.analyze(session)
        assert analysis["geometry"]["frame_count"] == 2
        assert analysis["shared_union_bbox"] == [50, 24, 206, 236]
        plan_payload = service.plan_normalization(session, anchor="feet", method="balanced")
        plan = NormalizationPlan.from_json(plan_payload)
        assert isinstance(plan.global_scale, float) and len(plan.registrations) == 2
        for registration in plan.registrations:
            payload = asdict(registration)
            assert "scale" not in payload and "width" not in payload and "height" not in payload

        reviewed_scale = plan.global_scale * 0.9
        reviewed_payload = service.plan_normalization(
            session,
            anchor="feet",
            method="balanced",
            global_scale=reviewed_scale,
        )
        reviewed_plan = NormalizationPlan.from_json(reviewed_payload)
        assert reviewed_plan.global_scale == reviewed_scale
        assert reviewed_plan.destination_x > plan.destination_x
        assert reviewed_plan.destination_y > plan.destination_y
        try:
            service.plan_normalization(
                session,
                anchor="feet",
                method="balanced",
                global_scale=plan.global_scale * 1.01,
            )
            raise AssertionError("clipping-unsafe reviewed scale was accepted")
        except model.WorkbenchError as error:
            assert "clipping-safe contain scale" in str(error)
        service.plan_normalization(
            session,
            anchor="feet",
            method="balanced",
            global_scale=reviewed_scale,
        )
        converted = service.convert(session)
        assert set(converted["candidates"]) == {"crisp", "balanced", "clustered"}
        for candidate in converted["candidates"].values():
            with Image.open(candidate) as image:
                assert image.size == (192, 96) and image.mode == "RGBA"
                assert image.getchannel("A").getextrema() == (0, 255)
        review = service.review(session)
        assert review["status"] == "PASS", review
        assert review["metrics"][1]["height"] < review["metrics"][0]["height"]
        assert Path(review["contact_sheet"]).exists()
        assert Path(review["silhouette"]).exists()
        assert Path(review["animation"]).exists()
        destination_name = "operator__upper_body__unarmed__locomotion__walk_01__e__2f__96.png"
        handoff = service.handoff(session, destination_name=destination_name)
        assert handoff["status"] == "READY_FOR_INGEST" and Path(handoff["candidate"]).exists()
        assert source.read_bytes() == original

        replacement = service.start(source_path=source, frames=2, target_size=96)
        service.analyze(replacement); service.plan_normalization(replacement); service.convert(replacement); service.review(replacement)
        try:
            service.handoff(replacement, destination_name=destination_name)
            raise AssertionError("implicit replacement was accepted")
        except model.WorkbenchError as error:
            assert "explicit replacement" in str(error)
        dry = service.handoff(replacement, destination_name=destination_name, replace=True, dry_run=True)
        assert dry["status"] == "DRY_RUN" and dry["operation"] == "REPLACE" and dry["old"]["sha256"]
        replaced = service.handoff(replacement, destination_name=destination_name, replace=True)
        assert replaced["operation"] == "REPLACE"

        unreviewed = service.start(source_path=source, frames=2, target_size=96)
        try:
            service.handoff(unreviewed, destination_name="operator__upper_body__unarmed__locomotion__run_01__e__2f__96.png", replace=True)
            raise AssertionError("unreviewed handoff was accepted")
        except model.WorkbenchError as error:
            assert "pass review" in str(error)

        grid_source = allowed / "highres_grid_3f.png"
        make_grid_source(grid_source, frames=3, columns=2, rows=2)
        grid_session = service.start(
            source_path=grid_source,
            frames=3,
            columns=2,
            rows=2,
            target_size=96,
        )
        service.analyze(grid_session)
        service.plan_normalization(grid_session)
        grid_result = service.convert(grid_session)
        with Image.open(grid_result["registered"]).convert("RGBA") as grid_candidate:
            assert grid_candidate.size == (288, 96)
            sampled = [grid_candidate.getpixel((index * 96 + 48, 48))[:3] for index in range(3)]
            assert sampled == [(255, 0, 0), (0, 255, 0), (0, 0, 255)], sampled

        for frames, columns, rows in ((6, 3, 2), (7, 4, 2), (8, 4, 2)):
            source_grid = allowed / f"highres_grid_{frames}f.png"
            make_grid_source(source_grid, frames=frames, columns=columns, rows=rows)
            session_grid = service.start(source_path=source_grid, frames=frames, columns=columns, rows=rows, target_size=96)
            service.analyze(session_grid)
            service.plan_normalization(session_grid)
            converted_grid = service.convert(session_grid)
            assert Image.open(converted_grid["registered"]).size == (frames * 96, 96)
            reviewed_grid = service.review(session_grid)
            assert reviewed_grid["status"] == "PASS", reviewed_grid

        outside = root / "outside.png"
        make_source(outside)
        try:
            service.start(source_path=outside, frames=2)
            raise AssertionError("outside source path was accepted")
        except model.WorkbenchError as error:
            assert "outside authorized" in str(error)

        # A bounded integer registration that would discard visible pixels is
        # rejected during conversion rather than silently clipping equipment.
        clipping_session = service.start(source_path=source, frames=2, target_size=96)
        service.analyze(clipping_session)
        service.plan_normalization(clipping_session)
        service.set_frame_registration(clipping_session, frame=1, dx=0, dy=12)
        try:
            service.convert(clipping_session)
            raise AssertionError("clipping registration was accepted")
        except model.WorkbenchError as error:
            assert "would clip" in str(error)

    print("PASS operator_art_source_smoke: shared-scale source sessions, candidates, review, confinement, clipping refusal")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
