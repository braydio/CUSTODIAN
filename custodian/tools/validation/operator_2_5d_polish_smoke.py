#!/usr/bin/env python3
from __future__ import annotations

import sys
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "custodian/tools/operator"))

from art_agent.metrics import animation_metrics, reference_metrics, temporal_metrics
from art_agent.models import ArtIdentity, ArtSession
from art_agent.qa import _temporal_pixel_findings
from art_agent.service import ArtAgentService
from operator_2_5d_polish import (
    Operator2DPolish,
    PolishError,
    center_x_proposal,
    detached_component_proposals,
    planted_registration_proposal,
)


def frame(path: Path, *, shift: int = 0, bright: bool = False, island: bool = False) -> None:
    image = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    color = (240, 240, 240, 255) if bright else (80, 80, 80, 255)
    for y in range(4, 9):
        for x in range(4 + shift, 8 + shift):
            image.putpixel((x, y), color)
    if island:
        for point in ((13, 2), (14, 2), (13, 3)):
            image.putpixel(point, color)
    image.save(path)


def main() -> None:
    with tempfile.TemporaryDirectory() as temp:
        root = Path(temp)
        first, jittered, island = root / "f1.png", root / "f2.png", root / "island.png"
        frame(first)
        frame(jittered, shift=1, bright=True)
        frame(island, island=True)

        proposals = detached_component_proposals([island], layer="body")
        assert len(proposals) == 1 and proposals[0]["area"] == 3
        assert proposals[0]["pixels"] == [[13, 2], [14, 2], [13, 3]]
        protected = [{"frame": 1, "layer": "body", "spans": [{"y": 2, "x0": 13, "x1": 13}]}]
        assert not detached_component_proposals([island], layer="body", masks=protected)
        assert not detached_component_proposals([island], layer="body", max_area=2)

        paths = []
        offsets = [0, 1, -1, 2, -2, 1, 0, -1, 2, -2, 1, 0, -1, 2, -2]
        landmarks = []
        for index, shift in enumerate(offsets, 1):
            path = root / f"idle-{index:02d}.png"
            frame(path, shift=shift, bright=index == 6)
            paths.append(path)
            landmarks.append({"frame": index, "name": "left_foot_contact", "x": 6 + shift,
                              "y": 9, "confidence": .9, "approved": True, "status": "CURRENT"})
        pixels_before = [path.read_bytes() for path in paths]
        disabled = planted_registration_proposal(paths, landmarks=landmarks, masks=[],
                                                  group="idle", action="relaxed", enabled=False)
        assert disabled["status"] == "NO_PROPOSAL"
        proposal = planted_registration_proposal(paths, landmarks=landmarks, masks=[],
                                                 group="idle", action="relaxed", enabled=True)
        assert proposal["status"] == "PROPOSAL" and len(proposal["offsets"]) == 15
        assert [row["dx"] for row in proposal["offsets"]] == [0, -1, 1, -2, 2, -1, 0, 1, -2, 2, -1, 0, 1, -2, 2]
        assert [path.read_bytes() for path in paths] == pixels_before, "proposal generation must preserve intentional pixels"
        assert planted_registration_proposal(paths, landmarks=landmarks, masks=[],
                                             group="locomotion", action="walk", enabled=True)["status"] == "NO_PROPOSAL"
        assert planted_registration_proposal(paths, landmarks=[], masks=[],
                                             group="idle", action="relaxed", enabled=True)["status"] == "NO_PROPOSAL"

        temporal = temporal_metrics([first, jittered, first], masks=[{
            "mask_id": "shoulder", "part": "shoulder", "layer": "body",
            "spans": [{"y": 5, "x0": 5, "x1": 6}],
        }])
        assert temporal["adjacent_frames"][0]["silhouette_delta_pixels"] > 0
        assert temporal["loop_seam"]["from_frame"] == 3
        assert temporal["regions"][0]["metrics"][0]["mean_luminance_delta"] > 0
        findings = _temporal_pixel_findings({"temporal_metrics": temporal})
        assert findings, "pixel-level temporal drift should be localized as objective QA findings"
        comparison = reference_metrics([jittered], [first])
        assert comparison[0]["changed_pixels"] > 0 and comparison[0]["changed_bounds"] is not None
        metrics = animation_metrics([first, jittered])
        assert metrics["frames"][0]["opaque_components"]

        old_session = ArtSession.from_json({
            "schema": "custodian.operator_art_agent.session.v2", "session_id": "old",
            "created_utc": "now", "identity": {"profile": "p", "group": "g", "action": "a", "direction": "e"},
            "workbench_manifest": "/m", "workbench_path": "/w", "context_fingerprint": "",
            "initial_workbench_sha256": "x", "expected_workbench_sha256": "x",
        })
        assert old_session.art_generation == "legacy_96"
        assert ArtAgentService._session_profile_id(old_session) is None
        modern = ArtSession.from_json({**old_session.to_json(), "session_id": "new",
                                       "art_generation": "operator_2_5d_128"})
        assert ArtAgentService._session_profile_id(modern) == "operator_2_5d_128"

        class FakeService:
            def __init__(self, frames, *, masks=None, landmarks=None):
                self.scopes = []
                self.operations = []
                self.undos = 0
                self.frames = frames
                self.masks = masks or []
                self.landmarks = landmarks or []
            def _checked_session(self, _path):
                identity = type("Identity", (), {"group": "idle", "action": "relaxed"})()
                return (type("Session", (), {"expected_workbench_sha256": "before", "identity": identity})(),
                        {"layers": [{"aseprite_layer_name": "body", "editable": True}]}, root)
            def inspect_polish_contract(self, _path): return {"valid": True}
            def render(self, _path): return {"frames": [str(path) for path in self.frames]}
            def get_masks(self, _path): return self.masks
            def get_landmarks(self, _path): return self.landmarks
            def set_edit_scope(self, _path, **scope): self.scopes.append(scope)
            def apply_operation(self, _path, operation): self.operations.append(operation); return {"status": "APPLIED", "journal": "j1"}
            def undo_last(self, _path): self.undos += 1; return {"undone_operation": "j1"}
            def clear_edit_scope(self, _path): self.scopes.append("cleared")
        def must_reject(service, value):
            before = len(service.operations)
            try: Operator2DPolish(service).apply(Path("fixture-session"), value)
            except PolishError: pass
            else: raise AssertionError(f"forged/stale proposal was accepted: {value}")
            assert len(service.operations) == before, "rejected proposal reached the mutation service"

        fake = FakeService([island])
        exact_island = detached_component_proposals([island], layer="body")[0]
        applied = Operator2DPolish(fake).apply(Path("fixture-session"), exact_island)
        assert applied["undo_available"] and fake.scopes[0]["allowed"] == [{"layer": "body", "frames": [1]}]
        assert fake.operations[0]["type"] == "erase_pixels"
        assert fake.operations[0]["pixels"] == [{"x": 13, "y": 2}, {"x": 14, "y": 2}, {"x": 13, "y": 3}]
        fake.undo_last(Path("fixture-session"))
        assert fake.undos == 1 and fake.scopes[-1] == "cleared"

        forged_island = {**exact_island, "area": 1, "bounds": [0, 0, 1, 1], "pixels": [[0, 0], [15, 15]]}
        must_reject(FakeService([island]), forged_island)
        must_reject(FakeService([island], masks=protected), exact_island)
        must_reject(FakeService([first]), exact_island)  # stale: the island disappeared
        must_reject(FakeService([island]), {**exact_island, "area": 5})
        must_reject(FakeService([island]), {**exact_island, "pixels": [[16, 16]]})
        must_reject(FakeService([island]), {**exact_island, "frame": 0})

        def frame128(path, shift):
            image = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
            for y in range(48, 53):
                for x in range(60 + shift, 64 + shift): image.putpixel((x, y), (80, 80, 80, 255))
            image.save(path)
        large1, large2 = root / "registration-1.png", root / "registration-2.png"
        frame128(large1, 0); frame128(large2, 4)
        support = [
            {"frame": 1, "name": "left_foot_contact", "x": 64, "y": 60, "confidence": .9, "approved": True, "status": "CURRENT"},
            {"frame": 2, "name": "left_foot_contact", "x": 68, "y": 60, "confidence": .9, "approved": True, "status": "CURRENT"},
        ]
        registration_service = FakeService([large1, large2], landmarks=support)
        planted = planted_registration_proposal([large1, large2], landmarks=support, masks=[],
                                                  group="idle", action="relaxed", enabled=True)
        planted["layer"] = "body"
        frame_two = {**planted, "frame": 2}
        registration_applied = Operator2DPolish(registration_service).apply(Path("fixture-session"), frame_two)
        assert registration_applied["undo_available"]
        assert registration_service.operations[0] == {
            "type": "move_region", "layer": "body", "frame": 2,
            "source_rect": [64, 48, 4, 5], "dx": -4, "dy": 0,
        }
        forged_planted = {**frame_two, "offsets": [{**planted["offsets"][0]}, {**planted["offsets"][1], "dx": 100}]}
        must_reject(FakeService([large1, large2], landmarks=support), forged_planted)
        must_reject(FakeService([large1, large2], landmarks=[]), frame_two)
        stale_support = [{**item, "x": item["x"] + 1} for item in support]
        must_reject(FakeService([large1, large2], landmarks=stale_support), frame_two)

        center = center_x_proposal([large1, large2], group="idle", action="relaxed")
        center["layer"] = "body"
        center["frame"] = 1
        must_reject(FakeService([large1, large2]), {**center, "offsets": [{**center["offsets"][0], "dx": 101}, center["offsets"][1]]})

    print("PASS operator_2_5d_polish_smoke: exact fresh apply validation, forged/stale rejection, diagnostics, profile compatibility")


if __name__ == "__main__":
    main()
