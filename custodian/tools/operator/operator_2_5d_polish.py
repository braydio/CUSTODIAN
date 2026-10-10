"""Publication-free analysis and bounded operations for exact 2.5D Workbenches."""
from __future__ import annotations

from pathlib import Path
from typing import Any

from PIL import Image

from art_agent.metrics import connected_components, reference_metrics, temporal_metrics
from art_agent.service import ArtAgentService

MAX_AUTO_ERASE_PIXELS = 4
SUPPORT_LANDMARKS = {"left_foot_contact", "right_foot_contact"}
SUPPORT_MASK_PARTS = {"support_foot", "foot_contact", "foot_near", "foot_far"}
LOCOMOTION_WORDS = {"walk", "run", "dash", "jump", "charge", "locomotion", "crawl"}


class PolishError(RuntimeError):
    pass


def _box_inside(bounds: list[int], dx: int, dy: int, size: tuple[int, int]) -> bool:
    x, y, width, height = bounds
    return x + dx >= 0 and y + dy >= 0 and x + dx + width <= size[0] and y + dy + height <= size[1]


def _locomotion(group: str, action: str) -> bool:
    words = set((group + " " + action).casefold().replace("_", " ").replace("-", " ").split())
    return bool(words & LOCOMOTION_WORDS)


def _mask_pixels(mask: dict[str, Any]) -> set[tuple[int, int]]:
    points = set()
    for span in mask.get("spans", []):
        points.update((x, int(span["y"])) for x in range(int(span["x0"]), int(span["x1"]) + 1))
    return points


def detached_component_proposals(
    frame_paths: list[Path], *, layer: str, masks: list[dict[str, Any]] | None = None,
    landmarks: list[dict[str, Any]] | None = None, max_area: int = MAX_AUTO_ERASE_PIXELS,
) -> list[dict[str, Any]]:
    """Offer exact-pixel erase proposals only for tiny detached non-semantic islands."""
    if not 1 <= max_area <= MAX_AUTO_ERASE_PIXELS:
        raise ValueError(f"automatic detached-component threshold must be 1..{MAX_AUTO_ERASE_PIXELS}")
    result = []
    for frame_number, path in enumerate(frame_paths, 1):
        with Image.open(path) as source:
            image = source.convert("RGBA")
            components = connected_components(image)
            protected = set()
            for mask in masks or []:
                if int(mask.get("frame", -1)) == frame_number and mask.get("layer") == layer:
                    protected.update(_mask_pixels(mask))
            for item in landmarks or []:
                if int(item.get("frame", -1)) == frame_number and item.get("status", "CURRENT") == "CURRENT":
                    protected.add((int(item["x"]), int(item["y"])))
            main_area = max((entry["area"] for entry in components), default=0)
            for component in components:
                pixels = component.get("pixels")
                if component["area"] > max_area or component["area"] >= main_area or not pixels:
                    continue
                exact_pixels = [tuple(point) for point in pixels]
                if any(point in protected for point in exact_pixels):
                    continue
                result.append({"kind": "erase_detached_component", "status": "PROPOSAL",
                               "frame": frame_number, "layer": layer,
                               "bounds": component["bounds"], "area": component["area"],
                               "pixels": [[x, y] for x, y in exact_pixels], "mutates": False})
    return result


def planted_registration_proposal(
    frame_paths: list[Path], *, landmarks: list[dict[str, Any]], masks: list[dict[str, Any]],
    group: str, action: str, enabled: bool,
) -> dict[str, Any]:
    """Propose integer per-frame translations only with explicit approved support authority."""
    if not enabled:
        return {"kind": "planted_registration", "status": "NO_PROPOSAL",
                "reason": "explicit planted/stationary opt-in is disabled", "offsets": [], "mutates": False}
    if _locomotion(group, action):
        return {"kind": "planted_registration", "status": "NO_PROPOSAL",
                "reason": "locomotion/root-motion target is not eligible for planted registration",
                "offsets": [], "mutates": False}
    root_points = {}
    supports: dict[int, list[tuple[float, float]]] = {}
    for item in landmarks:
        if item.get("status", "CURRENT") != "CURRENT" or not item.get("approved"):
            continue
        if item.get("name") in SUPPORT_LANDMARKS and float(item.get("confidence", 0)) >= 0.75:
            supports.setdefault(int(item["frame"]), []).append((float(item["x"]), float(item["y"])))
        if item.get("name") in {"projected_world_root", "shadow_origin"}:
            root_points.setdefault(item["name"], []).append((int(item["x"]), int(item["y"])))
    for mask in masks:
        if (mask.get("status", "CURRENT") == "CURRENT" and mask.get("provenance") == "human"
                and float(mask.get("confidence", 0)) >= 0.75 and mask.get("part") in SUPPORT_MASK_PARTS):
            points = _mask_pixels(mask)
            if points:
                supports.setdefault(int(mask["frame"]), []).append(
                    (sum(point[0] for point in points) / len(points), sum(point[1] for point in points) / len(points)))
    if any(len(set(points)) > 1 for points in root_points.values()):
        return {"kind": "planted_registration", "status": "NO_PROPOSAL",
                "reason": "approved root/shadow landmarks show contrary motion evidence",
                "offsets": [], "mutates": False}
    if len(supports) != len(frame_paths) or any(frame not in supports for frame in range(1, len(frame_paths) + 1)):
        return {"kind": "planted_registration", "status": "NO_PROPOSAL",
                "reason": "approved current support-foot landmarks or masks are required for every frame",
                "offsets": [], "mutates": False}
    centers = {frame: (sum(x for x, _ in values) / len(values), sum(y for _, y in values) / len(values))
               for frame, values in supports.items()}
    anchor = centers[1]
    offsets = []
    for frame_number, path in enumerate(frame_paths, 1):
        dx = round(anchor[0] - centers[frame_number][0])
        dy = round(anchor[1] - centers[frame_number][1])
        with Image.open(path) as source:
            bounds = list(source.convert("RGBA").getchannel("A").getbbox() or (0, 0, 0, 0))
            bounds[2] -= bounds[0]
            bounds[3] -= bounds[1]
            if not _box_inside(bounds, dx, dy, source.size):
                return {"kind": "planted_registration", "status": "NO_PROPOSAL",
                        "reason": f"frame {frame_number} translation would clip occupied pixels",
                        "offsets": [], "mutates": False}
        offsets.append({"frame": frame_number, "dx": int(dx), "dy": int(dy), "bounds": bounds})
    return {"kind": "planted_registration", "status": "PROPOSAL", "authority_frame": 1,
            "motion_policy": "explicit_planted", "evidence": "approved_support_landmark_or_mask",
            "anchor": [round(anchor[0]), round(anchor[1])], "offsets": offsets, "mutates": False}


def center_x_proposal(frame_paths: list[Path], *, group: str, action: str,
                      center_x: int = 64) -> dict[str, Any]:
    if _locomotion(group, action):
        return {"kind": "manual_center_x", "status": "NO_PROPOSAL",
                "reason": "visual-bounds centering is unsafe for an obvious locomotion/root-motion target",
                "offsets": [], "mutates": False}
    offsets = []
    for index, path in enumerate(frame_paths, 1):
        with Image.open(path) as source:
            image = source.convert("RGBA")
            bbox = image.getchannel("A").getbbox()
            if bbox is None:
                return {"kind": "manual_center_x", "status": "NO_PROPOSAL",
                        "reason": f"frame {index} has no visible bounds", "offsets": [], "mutates": False}
            dx = round(center_x - ((bbox[0] + bbox[2] - 1) / 2))
            bounds = [bbox[0], bbox[1], bbox[2] - bbox[0], bbox[3] - bbox[1]]
            if not _box_inside(bounds, dx, 0, image.size):
                return {"kind": "manual_center_x", "status": "NO_PROPOSAL",
                        "reason": f"frame {index} centering would clip visible pixels", "offsets": [], "mutates": False}
            offsets.append({"frame": index, "dx": int(dx), "dy": 0, "bounds": bounds})
    return {"kind": "manual_center_x", "status": "PROPOSAL", "basis": "current visual bounds",
            "warning": "manual preview only; does not redefine semantic root", "offsets": offsets, "mutates": False}


class Operator2DPolish:
    """Exact-target orchestration over the existing Workbench and Art Agent owners."""

    def __init__(self, service: ArtAgentService):
        self.service = service

    def attach(self, manifest_path: Path, selection: Any) -> Path:
        return self.service.attach_existing_workbench(manifest_path, selection)

    def analyze(self, session_path: Path) -> dict[str, Any]:
        self.service.inspect_polish_contract(session_path)
        session, _manifest, root = self.service._checked_session(session_path)
        rendered = self.service.render(session_path)
        frames = [Path(path) for path in rendered["frames"]]
        masks = self.service.get_masks(session_path)
        landmarks = self.service.get_landmarks(session_path)
        metrics = self.service.get_metrics(session_path)
        metrics["polish_temporal"] = temporal_metrics(frames, masks=masks)
        baseline_strip = Path(rendered["baseline"])
        from art_agent.render import split_strip
        baseline_frames = split_strip(baseline_strip, frame_width=128 if session.art_generation == "operator_2_5d_128" else int(_manifest["canvas"]["width"]),
                                      frame_height=128 if session.art_generation == "operator_2_5d_128" else int(_manifest["canvas"]["height"]),
                                      frame_count=len(frames), output_dir=root / "previews/polish_baseline")
        metrics["polish_baseline_comparison"] = reference_metrics(frames, baseline_frames)
        metrics["polish_components"] = [frame.get("opaque_components", []) for frame in metrics.get("frames", [])]
        qa = self.service.run_qa(session_path)
        metrics["qa"] = qa
        editable_layers = [row["aseprite_layer_name"] for row in _manifest.get("layers", []) if row.get("editable")]
        if not editable_layers:
            raise PolishError("Workbench has no editable layer for polish proposals")
        target_layer = editable_layers[0]
        planted = planted_registration_proposal(
            frames, landmarks=landmarks, masks=masks, group=session.identity.group,
            action=session.identity.action, enabled=False)
        planted["layer"] = target_layer
        center = center_x_proposal(frames, group=session.identity.group,
                                   action=session.identity.action)
        center["layer"] = target_layer
        metrics["proposals"] = {
            "detached_components": detached_component_proposals(frames, layer=target_layer,
                                                                  masks=masks, landmarks=landmarks),
            "planted_registration": planted,
            "center_x": center,
        }
        metrics["schema"] = "custodian.operator_art_metrics.v2"
        (root / "polish_analysis.json").write_text(__import__("json").dumps(metrics, indent=2) + "\n")
        return metrics

    def propose_center_x(self, session_path: Path) -> dict[str, Any]:
        self.service.inspect_polish_contract(session_path)
        session, manifest, _root = self.service._checked_session(session_path)
        artifacts = self.service.render(session_path)
        result = center_x_proposal([Path(path) for path in artifacts["frames"]],
                                  group=session.identity.group, action=session.identity.action)
        _session, manifest, _root = self.service._checked_session(session_path)
        result["layer"] = next(row["aseprite_layer_name"] for row in manifest.get("layers", []) if row.get("editable"))
        return result

    def propose_planted_registration(self, session_path: Path, *, enabled: bool) -> dict[str, Any]:
        self.service.inspect_polish_contract(session_path)
        session, _manifest, _root = self.service._checked_session(session_path)
        artifacts = self.service.render(session_path)
        result = planted_registration_proposal(
            [Path(path) for path in artifacts["frames"]],
            landmarks=self.service.get_landmarks(session_path), masks=self.service.get_masks(session_path),
            group=session.identity.group, action=session.identity.action, enabled=enabled,
        )
        _session, manifest, _root = self.service._checked_session(session_path)
        result["layer"] = next(row["aseprite_layer_name"] for row in manifest.get("layers", []) if row.get("editable"))
        return result

    @staticmethod
    def _integer_list(value: Any, length: int) -> bool:
        return (isinstance(value, list) and len(value) == length
                and all(type(item) is int for item in value))

    def _fresh_apply_operation(
        self, session_path: Path, proposal: dict[str, Any], session: Any,
        manifest: dict[str, Any],
    ) -> dict[str, Any]:
        """Authenticate caller data against a fresh proposal before mutation."""
        if not isinstance(proposal, dict):
            raise PolishError("proposal must be an object")
        if (proposal.get("status") != "PROPOSAL" or proposal.get("mutates") is not False
                or type(proposal.get("frame")) is not int):
            raise PolishError("only a well-formed non-mutating proposal can be applied")
        editable_layers = [row["aseprite_layer_name"] for row in manifest.get("layers", [])
                           if row.get("editable")]
        if not editable_layers:
            raise PolishError("Workbench has no editable polish layer")
        # WB25-3 proposal generation binds to this exact primary editable body cel.
        layer = editable_layers[0]
        if proposal.get("layer") != layer:
            raise PolishError("proposal target layer does not match the current polish binding")

        self.service.inspect_polish_contract(session_path)
        rendered = self.service.render(session_path)
        frames = [Path(path) for path in rendered["frames"]]
        frame = proposal["frame"]
        if not 1 <= frame <= len(frames):
            raise PolishError("proposal frame is outside the current Workbench")
        masks = self.service.get_masks(session_path)
        landmarks = self.service.get_landmarks(session_path)
        kind = proposal.get("kind")

        if kind == "erase_detached_component":
            if (type(proposal.get("area")) is not int
                    or not self._integer_list(proposal.get("bounds"), 4)
                    or not isinstance(proposal.get("pixels"), list)
                    or not proposal["pixels"]
                    or any(not self._integer_list(point, 2) for point in proposal["pixels"])):
                raise PolishError("detached-component proposal geometry is malformed")
            fresh = detached_component_proposals(frames, layer=layer, masks=masks, landmarks=landmarks)
            candidate = next((item for item in fresh if item["frame"] == frame
                              and proposal["area"] == item["area"]
                              and proposal["bounds"] == item["bounds"]
                              and proposal["pixels"] == item["pixels"]), None)
            if candidate is None:
                raise PolishError("detached-component proposal is stale, forged, protected, or not an exact current island")
            return {"type": "erase_pixels", "layer": layer, "frame": frame,
                    "pixels": [{"x": x, "y": y} for x, y in candidate["pixels"]]}

        if kind not in {"planted_registration", "manual_center_x"}:
            raise PolishError(f"unsupported polish proposal: {kind}")
        if not isinstance(proposal.get("offsets"), list):
            raise PolishError("registration proposal offsets are malformed")
        if kind == "manual_center_x":
            fresh_registration = center_x_proposal(
                frames, group=session.identity.group, action=session.identity.action)
            if proposal.get("basis") != "current visual bounds":
                raise PolishError("manual Center X proposal basis is invalid")
        else:
            if (proposal.get("motion_policy") != "explicit_planted"
                    or proposal.get("evidence") != "approved_support_landmark_or_mask"
                    or type(proposal.get("authority_frame")) is not int
                    or proposal.get("authority_frame") != 1):
                raise PolishError("planted registration requires its explicit supported proposal receipt")
            fresh_registration = planted_registration_proposal(
                frames, landmarks=landmarks, masks=masks,
                group=session.identity.group, action=session.identity.action, enabled=True,
            )
        if fresh_registration.get("status") != "PROPOSAL":
            raise PolishError("registration proposal is no longer eligible from current evidence")
        fresh_offsets = fresh_registration["offsets"]
        supplied_offsets = proposal["offsets"]
        if len(supplied_offsets) != len(fresh_offsets):
            raise PolishError("registration proposal frame set differs from the fresh proposal")
        for supplied, expected in zip(supplied_offsets, fresh_offsets):
            if not isinstance(supplied, dict) or any(type(supplied.get(key)) is not int
                    for key in ("frame", "dx", "dy")) or not self._integer_list(supplied.get("bounds"), 4):
                raise PolishError("registration proposal contains malformed offset data")
            if supplied != expected:
                raise PolishError("registration offsets or bounds differ from the fresh proposal")
        if kind == "planted_registration":
            if (not self._integer_list(proposal.get("anchor"), 2)
                    or proposal["anchor"] != fresh_registration.get("anchor")):
                raise PolishError("planted registration anchor differs from current support evidence")
        elif proposal.get("warning") != fresh_registration.get("warning"):
            raise PolishError("manual Center X warning/basis differs from the fresh proposal")
        offset = next(item for item in fresh_offsets if item["frame"] == frame)
        if offset["dx"] == 0 and offset["dy"] == 0:
            return {"type": "noop", "layer": layer, "frame": frame}
        return {"type": "move_region", "layer": layer, "frame": frame,
                "source_rect": list(offset["bounds"]), "dx": offset["dx"], "dy": offset["dy"]}

    def apply(self, session_path: Path, proposal: dict[str, Any]) -> dict[str, Any]:
        session, manifest, _root = self.service._checked_session(session_path)
        operation = self._fresh_apply_operation(session_path, proposal, session, manifest)
        frame, layer = operation.get("frame"), operation.get("layer")
        if operation["type"] == "noop":
            return {"status": "NOOP", "frame": frame, "workbench_sha256": session.expected_workbench_sha256}
        self.service.set_edit_scope(session_path, allowed=[{"layer": layer, "frames": [frame]}],
                                    operations=[operation["type"]])
        try:
            result = self.service.apply_operation(session_path, operation)
            try:
                contract = self.service.inspect_polish_contract(session_path)
            except Exception:
                self.service.undo_last(session_path)
                self.service.inspect_polish_contract(session_path)
                raise
            return {"status": result.get("status", "APPLIED"), "operation": result,
                    "contract": contract, "undo_available": True}
        finally:
            try:
                self.service.clear_edit_scope(session_path)
            except Exception:
                pass
