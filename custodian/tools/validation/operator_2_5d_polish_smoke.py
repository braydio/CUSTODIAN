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
            def __init__(self):
                self.scopes = []
                self.operations = []
                self.undos = 0
            def _checked_session(self, _path):
                return (type("Session", (), {"expected_workbench_sha256": "before"})(),
                        {"layers": [{"aseprite_layer_name": "body", "editable": True}]}, root)
            def inspect_polish_contract(self, _path): return {"valid": True}
            def set_edit_scope(self, _path, **scope): self.scopes.append(scope)
            def apply_operation(self, _path, operation): self.operations.append(operation); return {"status": "APPLIED", "journal": "j1"}
            def undo_last(self, _path): self.undos += 1; return {"undone_operation": "j1"}
            def clear_edit_scope(self, _path): self.scopes.append("cleared")
        fake = FakeService()
        applied = Operator2DPolish(fake).apply(Path("fixture-session"), {
            "status": "PROPOSAL", "mutates": False, "kind": "manual_center_x", "frame": 2,
            "layer": "body", "offsets": [{"frame": 2, "dx": 1, "dy": 0, "bounds": [4, 4, 4, 5]}],
        })
        assert applied["undo_available"] and fake.scopes[0]["allowed"] == [{"layer": "body", "frames": [2]}]
        assert fake.operations[0]["type"] == "move_region" and fake.operations[0]["dx"] == 1
        fake.undo_last(Path("fixture-session"))
        assert fake.undos == 1 and fake.scopes[-1] == "cleared"

    print("PASS operator_2_5d_polish_smoke: deterministic proposals, temporal/reference metrics, profile compatibility")


if __name__ == "__main__":
    main()
