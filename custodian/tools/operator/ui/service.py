"""Structured boundary between the TUI and Workbench V2."""
from __future__ import annotations

import json
import re
import io
import os
import shutil
import subprocess
from pathlib import Path
from typing import Any, Callable
from PIL import Image

import animation_frame_contract as frame_contract
import animation_workbench as workbench
import animation_workbench_model as model
import animation_preview
import animation_motion_preview
import operator_art_worktree

from .state import (
    AnimationRecord, AnimationSelection, CanvasMigrationView, ErrorView, ExistingContextView,
    LayerView, MigrationView, PublishRow, PublishView, SessionView,
)


class WorkbenchService:
    """The only UI object allowed to call Workbench V2 APIs."""

    def __init__(
        self, *, repo_root: Path = model.REPO_ROOT,
        source_root: Path = model.SOURCE_ROOT, weapon_root: Path = model.WEAPON_ROOT,
        catalog_path: Path = model.CATALOG, workspace_root: Path = workbench.DEFAULT_ROOT,
        aseprite: Path | None = None, model_api: Any = model,
        workbench_api: Any = workbench, popen: Callable[..., Any] = subprocess.Popen,
    ) -> None:
        self.repo_root = Path(repo_root)
        self.coordination_root_configured = bool(os.environ.get("CUSTODIAN_COORDINATION_ROOT"))
        self.coordination_root = Path(os.environ.get("CUSTODIAN_COORDINATION_ROOT", self.repo_root)).resolve()
        self.source_root = Path(source_root)
        self.weapon_root = Path(weapon_root)
        self.catalog_path = Path(catalog_path)
        self.workspace_root = Path(workspace_root)
        self.aseprite = aseprite
        self.model = model_api
        self.workbench = workbench_api
        self._popen = popen
        self.plan_path = self.repo_root / "design/02_features/animation/OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json"
        self.preview_provider = animation_preview.AnimationPreviewProvider(
            repo_root=self.repo_root, catalog_path=self.catalog_path,
            source_index=self._index, workspace_root=self.workspace_root,
        )
        self.sequence_root = self.workspace_root / "sequences"
        self.motion_request_path = self.repo_root / ".ai/operator_animation_workbench/motion_lab_request.json"
        self.clipboard_root = self.repo_root / ".ai/operator_animation_workbench/clipboard"
    def _reachability_statuses(self) -> dict[tuple[str, str, str], str]:
        path = self.repo_root / "custodian/content/data/operator/operator_animation_reachability.json"
        try:
            rows = json.loads(path.read_text()).get("entries", [])
        except (OSError, json.JSONDecodeError):
            return {}
        action_status: dict[tuple[str, str, str], str] = {}
        layer_statuses: dict[tuple[str, str, str], list[str]] = {}
        for row in rows:
            if not isinstance(row, dict):
                continue
            key = (str(row.get("profile", "")), str(row.get("group", "")), str(row.get("action", "")))
            status = str(row.get("status", ""))
            if row.get("layer"):
                layer_statuses.setdefault(key, []).append(status)
            elif status:
                action_status[key] = status
        for key, statuses in layer_statuses.items():
            if key not in action_status and statuses:
                action_status[key] = "SUPERSEDED" if "SUPERSEDED" in statuses else statuses[0]
        return action_status

    def _index(self):
        return self.model.source_index(self.source_root, self.weapon_root)

    def checkout_identity(self):
        return operator_art_worktree.checkout_identity(self.repo_root, self.coordination_root)

    def readiness(self, selection: AnimationSelection | None = None):
        manifest_path = self.workspace(selection) / "workbench.json" if selection else None
        freshness = {}
        selected_paths = set()
        if manifest_path and manifest_path.is_file():
            try:
                data = self.workbench.load(manifest_path)
                freshness = self.workbench.source_contract_freshness(data, self.repo_root)
                for binding in data.get("layers", ()):
                    for contract in (binding.get("source_contract", {}), binding.get("publish_contract", {})):
                        if contract.get("path"): selected_paths.add(str(contract["path"]))
            except Exception as error:
                freshness = {"selected Workbench": str(error)}
        return operator_art_worktree.inspect_publish_readiness(
            self.repo_root, self.coordination_root, self.workspace_root,
            selected_paths=selected_paths, source_freshness=freshness,
        )

    def checkout_status_label(self, selection: AnimationSelection | None = None) -> str:
        identity = self.checkout_identity()
        readiness = self.readiness(selection)
        suffix = f" · {identity.worktree_state}" if identity.worktree_state != "clean" else ""
        if readiness.pending_land and "LAND PENDING" not in suffix:
            suffix += " · LAND PENDING"
        if identity.kind == "COORDINATION MAIN" and operator_art_worktree.coordination_operator_changes(self.coordination_root):
            suffix += " · coordination Operator edits preserved"
        return f"{identity.kind} · {identity.sparse_profile} · {identity.branch} · origin/main {identity.main_relation} · readiness {readiness.status.upper()}{suffix}"

    def require_saved_live_document_for_migration(self, active_path: str | None, expected_path: Path, modified: bool | None) -> None:
        if not active_path or modified is not True:
            return
        try: matches = Path(active_path).resolve() == Path(expected_path).resolve()
        except OSError: matches = False
        if matches:
            raise self.model.WorkbenchError("SAVE WORKBENCH BEFORE CONTRACT MIGRATION\n\nCanvas migration rebuilds the Aseprite document from saved pixels. Save the current document, then retry.")

    def discover_browser_records(self) -> tuple[AnimationRecord, ...]:
        source_index = self._index()
        reachability = self._reachability_statuses()
        grouped: dict[tuple[str, str, str, str], list[Any]] = {}
        for sid, (_path, key) in source_index.items():
            if sid[0] != "operator":
                continue
            grouped.setdefault((sid[2], sid[3], sid[4], sid[5]), []).append(key)
        records = []
        for (profile, group, action, direction), keys in sorted(grouped.items()):
            keys.sort(key=lambda key: key.layer)
            layer_names = {key.layer for key in keys}
            modular = {"lower_body", "upper_body"} <= layer_names
            visible_keys = [key for key in keys if not (modular and key.layer == "full_body")]
            layers = tuple(key.layer for key in visible_keys)
            clocks = [key.frames for key in visible_keys if key.layer in ("lower_body", "full_body")]
            frames = clocks[0] if clocks else max(key.frames for key in visible_keys)
            completeness, detail = self.classify_layers(layers)
            selection = AnimationSelection(profile, group, action, direction)
            if modular:
                lower = next(key.frames for key in visible_keys if key.layer == "lower_body")
                upper = next(key.frames for key in visible_keys if key.layer == "upper_body")
                if lower != upper:
                    completeness, detail = "PARTIAL", f"contract mismatch · lower {lower}f / upper {upper}f"
            status = reachability.get((profile, group, action))
            if status == "SUPERSEDED":
                detail = f"SUPERSEDED · {detail}"
            records.append(AnimationRecord(selection, frames, layers, completeness, detail, status))
        return tuple(records)

    def browser_records(self, *, show_superseded: bool = False) -> tuple[AnimationRecord, ...]:
        records = self.discover_browser_records()
        if show_superseded:
            return records
        return tuple(record for record in records if record.reachability_status != "SUPERSEDED")

    @staticmethod
    def _png_bytes(frames: tuple[Image.Image, ...]) -> bytes:
        if not frames:
            raise ValueError("selected animation has no frames")
        width, height = frames[0].size
        sheet = Image.new("RGBA", (width * len(frames), height), (0, 0, 0, 0))
        for index, frame in enumerate(frames):
            sheet.alpha_composite(frame.convert("RGBA"), (index * width, 0))
        stream = io.BytesIO(); sheet.save(stream, format="PNG"); return stream.getvalue()

    def copy_spritesheet(self, selection: AnimationSelection, *, mode: str = "body", source: str | None = None, live_path: Path | None = None, live_frames: int | None = None, live_frame_size: tuple[int, int] | None = None) -> dict[str, Any]:
        """Compose and copy the selected semantic animation without publishing it."""
        if mode not in ("body", "fx", "body_fx"):
            raise ValueError(f"unsupported copy mode: {mode}")
        if source is None:
            try:
                requested = "workbench" if (self.workspace(selection) / "workbench.json").exists() else "runtime"
            except Exception:
                requested = "runtime"
        else:
            requested = source
        sources = ("workbench", "runtime") if source is None and requested == "workbench" else ((requested,) if requested in ("workbench", "canonical", "runtime") else ("runtime",))
        error = None
        preview = None
        if live_path is not None:
            if not live_frames or not live_frame_size:
                raise ValueError("live copy requires a frame contract")
            preview = self.preview_provider.load_live(animation_preview.SemanticIdentity(
                selection.profile, selection.group, selection.action, selection.direction,
            ), live_path, frames=live_frames, frame_size=live_frame_size)
            requested = "live"
        for candidate in (() if preview is not None else sources):
            try:
                preview = self.preview_provider.load(animation_preview.SemanticIdentity(
                    selection.profile, selection.group, selection.action, selection.direction,
                ), candidate, mode)
                requested = candidate
                break
            except (OSError, ValueError, KeyError) as exc:
                error = exc
        if preview is None:
            raise ValueError(f"unable to compose {selection.identity}: {error}")
        png = self._png_bytes(preview.frames)
        filename = "__".join((selection.profile, selection.group, selection.action, selection.direction, mode)) + ".png"
        path = self.clipboard_root / filename
        path.parent.mkdir(parents=True, exist_ok=True); path.write_bytes(png)
        provider = shutil.which("wl-copy") or shutil.which("xclip")
        if provider is None:
            raise RuntimeError(f"Clipboard image provider unavailable. Generated sheet: {path}")
        command = [provider, "--type", "image/png"] if Path(provider).name == "wl-copy" else [provider, "-selection", "clipboard", "-t", "image/png", "-i"]
        try:
            subprocess.run(command, input=png, check=True, cwd=self.repo_root, capture_output=True)
        except subprocess.CalledProcessError as exc:
            detail = (exc.stderr or b"").decode(errors="replace").strip()
            raise RuntimeError(f"clipboard provider failed: {detail or exc}") from exc
        return {"mode": mode, "source": requested, "identity": selection.identity, "frames": len(preview.frames), "size": (preview.frame_size[0] * len(preview.frames), preview.frame_size[1]), "path": path}

    def available_directions(self, selection: AnimationSelection) -> tuple[str, ...]:
        available = {
            record.selection.direction
            for record in self.browser_records()
            if (
                record.selection.profile == selection.profile
                and record.selection.group == selection.group
                and record.selection.action == selection.action
            )
        }
        preferred = ("n", "e", "s", "w", "ne", "se", "sw", "nw", "omni")
        return tuple(direction for direction in preferred if direction in available)

    def animation_plan(self) -> list[dict[str, Any]]:
        payload = json.loads(self.plan_path.read_text())
        catalog = json.loads(self.catalog_path.read_text())
        return animation_preview.validate_plan(payload, catalog)

    def preview(self, selection: AnimationSelection, source: str = "runtime"):
        if source == "workbench":
            self.workbench.export_preview(self.workspace(selection) / "workbench.json", self.aseprite)
        identity = animation_preview.SemanticIdentity(
            selection.profile, selection.group, selection.action, selection.direction,
        )
        return self.preview_provider.load(identity, source)

    def live_preview(
        self, selection: AnimationSelection, strip_path: Path, *,
        frames: int, frame_size: tuple[int, int],
    ):
        identity = animation_preview.SemanticIdentity(
            selection.profile, selection.group, selection.action, selection.direction,
        )
        return self.preview_provider.load_live(
            identity, Path(strip_path), frames=frames, frame_size=frame_size,
        )

    def transition_candidates(
        self, selection: AnimationSelection,
    ) -> tuple[AnimationSelection, ...]:
        candidates = []
        for record in self.browser_records():
            candidate = record.selection
            if candidate.profile != selection.profile or candidate.direction != selection.direction:
                continue
            if candidate.group == selection.group and candidate.action == selection.action:
                continue
            layers = set(record.layers)
            if "full_body" not in layers and not {"lower_body", "upper_body"} <= layers:
                continue
            candidates.append(AnimationSelection(
                candidate.profile, candidate.group, candidate.action, candidate.direction,
                selection.weapon_id, selection.linked_profile,
            ))
        candidates.sort(key=lambda item: (item.group != selection.group, item.group, item.action))
        return tuple(candidates)

    def transition_preview(self, selection: AnimationSelection, primary_source: str):
        sources = ("workbench", "canonical", "runtime") if primary_source in ("live", "workbench") else (("canonical", "runtime") if primary_source == "canonical" else ("runtime", "canonical"))
        errors = []
        workbench_error = getattr(self.model, "WorkbenchError", model.WorkbenchError)
        availability_errors = (workbench_error, ValueError, OSError, subprocess.CalledProcessError)
        for source in sources:
            try:
                return self.preview(selection, source)
            except availability_errors as error:
                errors.append(f"{source}: {error}")
        raise ValueError("transition target unavailable: " + "; ".join(errors))

    def timeline_clip_frame_count(self, clip: animation_preview.TimelineClip) -> int:
        for record in self.browser_records():
            selection = record.selection
            if (
                selection.profile == clip.profile
                and selection.group == clip.group
                and selection.action == clip.action
                and selection.direction == clip.direction
            ):
                return record.frames
        raise ValueError(f"timeline clip identity is no longer present: {clip.identity.key}")

    def motion_event_markers(self, selection: AnimationSelection) -> tuple[animation_motion_preview.MotionEventMarker, ...]:
        """Read optional structured catalog events without scraping runtime source."""
        try:
            entry = json.loads(self.catalog_path.read_text()).get("animations", {}).get(selection.identity, {})
        except (OSError, json.JSONDecodeError):
            return ()
        rows = entry.get("motion_events", entry.get("events", ()))
        if not isinstance(rows, list):
            rows = []
        markers = []
        for index, row in enumerate(rows):
            if not isinstance(row, dict) or "frame" not in row:
                continue
            kind = str(row.get("kind", "CONTACT")).upper()
            if kind not in ("WINDUP_END", "ACTIVE", "CONTACT", "RECOVERY_START"):
                continue
            markers.append(animation_motion_preview.MotionEventMarker(
                str(row.get("id", f"event_{index}")), str(row.get("label", kind)), int(row["frame"]), kind,
            ))
        if markers or not selection.weapon_id:
            return tuple(markers)
        definition_path = self.repo_root / "custodian/game/actors/operator" / f"{selection.weapon_id}_definition.tres"
        try: definition = definition_path.read_text()
        except OSError: return ()
        attack_key = ""
        fast_match = re.fullmatch(r"fast_(\d+)", selection.action)
        if fast_match:
            chain = re.search(r"fast_chain_keys\s*=\s*PackedStringArray\(([^)]*)\)", definition)
            keys = re.findall(r'"([^"]+)"', chain.group(1)) if chain else []
            index = int(fast_match.group(1)) - 1
            attack_key = keys[index] if 0 <= index < len(keys) else ""
        if not attack_key:
            mapped = re.search(rf'"{re.escape(selection.action)}"\s*:\s*"([^"]+)"', definition)
            attack_key = mapped.group(1) if mapped else ""
        start = definition.find(f'"{attack_key}": {{') if attack_key else -1
        if start < 0: return ()
        brace_start = definition.find("{", start); depth = 0; end = brace_start
        for end in range(brace_start, len(definition)):
            if definition[end] == "{": depth += 1
            elif definition[end] == "}":
                depth -= 1
                if depth == 0: break
        block = definition[brace_start:end + 1]
        frames = []
        for raw in re.findall(r'(?<![A-Za-z_])"frames"\s*:\s*\[([^]]*)\]', block):
            frames.extend(int(value) for value in re.findall(r"\d+", raw))
        return tuple(animation_motion_preview.MotionEventMarker(
            f"contact_{index + 1}", f"CONTACT {index + 1}", max(0, frame - 1), "CONTACT",
        ) for index, frame in enumerate(dict.fromkeys(frames)))

    def launch_motion_runtime(
        self, selection: AnimationSelection, *, fps: float, travel_px: float,
        curve: str, ground: str, mode: str, loop: bool, loop_cycles: int,
    ):
        payload = {
            "schema": "custodian.operator_motion_request.v2",
            "identity": {"profile": selection.profile, "group": selection.group, "action": selection.action, "direction": selection.direction},
            "source": "runtime", "fps": float(fps), "travel_px": float(travel_px),
            "curve": curve, "ground": ground, "mode": mode,
            "loop": bool(loop), "loop_cycles": max(1, int(loop_cycles)),
        }
        self.motion_request_path.parent.mkdir(parents=True, exist_ok=True)
        self.motion_request_path.write_text(json.dumps(payload, indent=2) + "\n")
        return self._popen([
            "godot", "--path", str(self.repo_root / "custodian"),
            "res://scenes/debug/operator_motion_calibration.tscn",
            "--motion-request", str(self.motion_request_path.resolve()),
        ])

    def save_sequence(self, sequence: animation_preview.ReviewSequence) -> Path:
        return animation_preview.save_sequence(sequence, self.sequence_root)

    def load_sequence(self, name: str) -> animation_preview.ReviewSequence:
        return animation_preview.load_sequence(self.sequence_root / f"{name}.json")

    def flatten_sequence(self, sequence: animation_preview.ReviewSequence, source: str = "runtime"):
        return animation_preview.flatten_sequence(sequence, self.preview_provider, source)

    @staticmethod
    def classify_layers(layers: tuple[str, ...] | list[str]) -> tuple[str, str]:
        names = set(layers)
        if "full_body_reference" in names or any(name.startswith("__REFERENCE") for name in names):
            return "REFERENCE/LEGACY", "reference source"
        if {"lower_body", "upper_body"} <= names:
            return "COMPLETE", "lower+upper"
        if "full_body" in names:
            return "COMPLETE", "full body"
        visible = "+".join(name.replace("_body", "") for name in layers) or "no layers"
        return "PARTIAL", f"{visible} only; no body presentation layer"

    @staticmethod
    def filter_records(
        records: tuple[AnimationRecord, ...] | list[AnimationRecord], query: str,
        *, show_superseded: bool = False,
    ) -> list[AnimationRecord]:
        needle = query.casefold().strip()
        visible = [record for record in records if show_superseded or record.reachability_status != "SUPERSEDED"]
        if not needle:
            return visible
        return [record for record in visible if needle in " ".join((
            record.selection.profile, record.selection.group,
            record.selection.action, record.selection.direction,
        )).casefold()]

    def _plan(self, selection: AnimationSelection) -> dict[str, Any]:
        return self.model.build_plan(
            selection.profile, selection.action, selection.direction, selection.group,
            selection.weapon_id, selection.linked_profile, repo_root=self.repo_root,
            source_root=self.source_root, weapon_root=self.weapon_root,
            catalog_path=self.catalog_path,
        )

    def workspace(self, selection: AnimationSelection) -> Path:
        return self.workbench.workspace(self.workspace_root, {
            "profile": selection.profile, "group": selection.group,
            "action": selection.action, "direction": selection.direction,
        })

    @staticmethod
    def _context_view(context: dict[str, Any]) -> ExistingContextView:
        return ExistingContextView(
            str(context.get("weapon_id", "")),
            str(context.get("linked_profile", "")),
            str(context.get("presentation_mode", "")),
            str(context.get("fingerprint", "")),
        )

    def existing_context(self, selection: AnimationSelection) -> ExistingContextView | None:
        """Inspect manifest context without accepting or asserting it."""
        manifest_path = self.workspace(selection) / "workbench.json"
        if not manifest_path.exists():
            return None
        data = self.workbench.load(manifest_path)
        return self._context_view(data.get("context", {}))

    def requested_context(self, selection: AnimationSelection) -> ExistingContextView:
        return self._context_view(self._plan(selection).get("context", {}))

    @staticmethod
    def migration_view(report: dict[str, Any] | None) -> MigrationView | CanvasMigrationView | None:
        if not report:
            return None
        position = report.get("position", {})
        value = position.get("after", position.get("frame", 0)) if isinstance(position, dict) else position
        audit = report.get("dependency_audit", {})
        if report.get("kind") == "frame_canvas":
            return CanvasMigrationView(tuple(report.get("old_document_size", (0, 0))), tuple(report.get("new_document_size", (0, 0))), tuple(report.get("target_size", (0, 0))), str(report.get("scope", "animation")), tuple(report.get("affected_bindings", ())), tuple((item.get("binding_id", ""), item.get("reason", "")) for item in report.get("excluded_bindings", ())), str(audit.get("level", "GREEN")), report)
        return MigrationView(
            str(report.get("operation", "")), int(value), str(report.get("fill", "")),
            int(report.get("old_clock_frames", 0)), int(report.get("new_clock_frames", 0)),
            tuple(report.get("affected_bindings", ())),
            tuple((item.get("binding_id", ""), item.get("reason", "")) for item in report.get("excluded_bindings", ())),
            str(audit.get("level", "GREEN")), report,
        )

    def session(self, selection: AnimationSelection) -> SessionView:
        plan = self._plan(selection)
        ws = self.workspace(selection)
        manifest_path, document_path = ws / "workbench.json", ws / "workbench.aseprite"
        data, state = plan, "ABSENT"
        if manifest_path.exists():
            data = self.workbench.load(manifest_path)
            self.model.assert_context(data, plan)
            state = self.workbench.state(data, document_path)
        timeline = data["timeline"]
        migration = self.migration_view(data.get("pending_migration"))
        layers = []
        for binding in (*data.get("layers", ()), *data.get("references", ())):
            source = binding.get("source_contract", {})
            workspace_contract = binding.get("workspace_contract", {})
            publish = binding.get("publish_contract", {})
            frame_size = binding.get("frame_size", (0, 0))
            layers.append(LayerView(
                binding.get("aseprite_layer_name", binding.get("binding_id", "")),
                binding.get("role", ""), binding.get("owner", ""), binding.get("profile", ""),
                int(source.get("frames", binding.get("frames", 0))),
                int(workspace_contract.get("frames", binding.get("frames", 0))),
                int(publish.get("frames", binding.get("frames", 0))),
                f"{frame_size[0]}×{frame_size[1]}", bool(binding.get("editable", False)),
            ))
        dependency = migration.audit if migration else "GREEN"
        publishing_layers = tuple(layer.layer for layer in layers if layer.publishing)
        completeness, completeness_detail = self.classify_layers(publishing_layers)
        try: workspace_display = str(ws.relative_to(self.repo_root))
        except ValueError: workspace_display = str(ws)
        return SessionView(
            selection, int(timeline["source_clock_frames"]),
            int(timeline["workspace_clock_frames"]), int(timeline["document_frames"]),
            state, "MIGRATION_PENDING" if migration else "NONE", dependency, ws,
            str(self.workbench.resolve_aseprite(self.aseprite) or "unavailable"), tuple(layers),
            migration, data.get("context", {}), completeness, completeness_detail,
            workspace_display, (int(data.get("canvas", {}).get("width", 96)), int(data.get("canvas", {}).get("height", 96))),
        )

    def watch_signature(self, selection: AnimationSelection) -> tuple[int | None, int | None]:
        ws = self.workspace(selection)
        def stamp(path: Path) -> int | None:
            try: return path.stat().st_mtime_ns
            except FileNotFoundError: return None
        return stamp(ws / "workbench.json"), stamp(ws / "workbench.aseprite")

    def edit(self, selection: AnimationSelection):
        _manifest, ws = self.workbench.ensure(
            selection.profile, selection.action, selection.direction, selection.group,
            selection.weapon_id, selection.linked_profile, self.workspace_root, self.aseprite,
        )
        binary = self.workbench.resolve_aseprite(self.aseprite, True)
        return self._popen([str(binary), str(ws / "workbench.aseprite")])

    def frame_preview(self, selection: AnimationSelection, operation: str, position: int, fill: str = "duplicate-prev") -> MigrationView:
        report = self.workbench.frame_migrate(
            selection.profile, selection.action, selection.direction, operation, position,
            fill, "auto", selection.group, selection.weapon_id, selection.linked_profile,
            self.workspace_root, self.aseprite, True,
        )
        return self.migration_view(report)  # type: ignore[return-value]

    def frame_apply(self, selection: AnimationSelection, operation: str, position: int, fill: str = "duplicate-prev") -> MigrationView:
        report = self.workbench.frame_migrate(
            selection.profile, selection.action, selection.direction, operation, position,
            fill, "auto", selection.group, selection.weapon_id, selection.linked_profile,
            self.workspace_root, self.aseprite, False,
        )
        return self.migration_view(report)  # type: ignore[return-value]

    def canvas_preview(self, selection: AnimationSelection, width: int, height: int, scope: str = "animation") -> CanvasMigrationView:
        report = self.workbench.canvas_migrate(selection.profile, selection.action, selection.direction, width, height, scope, selection.group, selection.weapon_id, selection.linked_profile, self.workspace_root, self.aseprite, True)
        return self.migration_view(report)  # type: ignore[return-value]

    def canvas_apply(self, selection: AnimationSelection, width: int, height: int, scope: str = "animation") -> CanvasMigrationView:
        report = self.workbench.canvas_migrate(selection.profile, selection.action, selection.direction, width, height, scope, selection.group, selection.weapon_id, selection.linked_profile, self.workspace_root, self.aseprite, False)
        return self.migration_view(report)  # type: ignore[return-value]

    def publish_preview(self, selection: AnimationSelection, full_validate: bool = False) -> PublishView:
        pending_path = operator_art_worktree._pending_path(self.repo_root, self.workspace_root)
        if pending_path.exists() and self.model is model and self.workbench is workbench:
            try:
                pending = json.loads(pending_path.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError) as error:
                raise operator_art_worktree.ArtWorktreeError(f"LAND PENDING receipt cannot be read: {error}") from error
            saved_identity = pending.get("identity", {})
            matches = all(saved_identity.get(key) == getattr(selection, key) for key in ("profile", "group", "action", "direction"))
            identity_label = "/".join(str(saved_identity.get(key, "")) for key in ("profile", "group", "action", "direction"))
            try:
                checkout = self.checkout_identity()
                allowed = checkout.publish_allowed
                checkout_reason = "" if allowed else (
                    "Launch OPUI with 'opui' to retry from the isolated art checkout."
                    if checkout.kind == "COORDINATION MAIN"
                    else f"Retry requires {operator_art_worktree.ART_BRANCH}."
                )
            except (operator_art_worktree.ArtWorktreeError, OSError):
                allowed, checkout_reason = False, "Checkout identity could not be verified."
            reason = "" if matches and allowed else (
                f"LAND PENDING for {identity_label}; select that animation to retry landing."
                if not matches else checkout_reason
            )
            return PublishView(
                selection, 0, 0, (), (), None, "GREEN", compatibility_preflight=True,
                publish_enabled=matches and allowed, publish_block_reason=reason,
                land_pending=True, pending_identity=identity_label,
            )
        plan = self._plan(selection)
        manifest_path = self.workspace(selection) / "workbench.json"
        readiness = None
        if self.model is model and self.workbench is workbench:
            selected_paths=set(); freshness={}
            if manifest_path.is_file():
                selected_data=self.workbench.load(manifest_path)
                freshness=self.workbench.source_contract_freshness(selected_data,self.repo_root)
                for binding in selected_data.get("layers",()):
                    for contract in (binding.get("source_contract",{}),binding.get("publish_contract",{})):
                        if contract.get("path"): selected_paths.add(str(contract["path"]))
            readiness=operator_art_worktree.prepare_publish_checkout(
                self.repo_root,self.coordination_root,self.workspace_root,
                selected_paths=selected_paths,source_freshness=freshness,
            )
            if readiness.status=="ready" and manifest_path.is_file():
                selected_data=self.workbench.load(manifest_path)
                freshness=self.workbench.source_contract_freshness(selected_data,self.repo_root)
                if freshness:
                    readiness=operator_art_worktree.inspect_publish_readiness(
                        self.repo_root,self.coordination_root,self.workspace_root,
                        selected_paths=selected_paths,source_freshness=freshness,
                    )
            if readiness.status!="ready":
                reasons=tuple(readiness.blockers) or tuple(readiness.preparations)
                return PublishView(
                    selection,0,0,(),(),None,"GREEN",
                    publish_enabled=False,
                    publish_block_reason="\n".join(reasons),
                    readiness_status=readiness.status,
                    readiness_summary=f"Publication readiness: {readiness.status.upper()}",
                    readiness_blockers=readiness.blockers,
                    readiness_preparations=readiness.preparations,
                )
        counterpart = self.workbench.horizontal_counterpart(selection.direction)
        changed = self.workbench.publish(manifest_path, self.aseprite, False, True, full_validate, plan, bool(counterpart))
        data = self.workbench.load(manifest_path)
        migration = self.migration_view(data.get("pending_migration"))
        old_frames = int(data["timeline"]["source_clock_frames"])
        new_frames = int(data["timeline"]["workspace_clock_frames"])
        retired, new = [], []
        direct_changed = changed[::2] if counterpart else changed
        mirror_changed = changed[1::2] if counterpart else []
        for binding in data.get("layers", ()):
            old = str(binding.get("source_contract", {}).get("path", ""))
            target = str(binding.get("publish_contract", {}).get("path", old))
            if old != target: retired.append(old)
            new.append(target)
        def display(path: str) -> str:
            value = Path(path)
            try: return str(value.relative_to(self.repo_root))
            except ValueError: return str(value)
        mirror_paths = tuple(display(path) for path in mirror_changed)
        counterpart_index = self.model.source_index(self.source_root, self.weapon_root) if counterpart else {}
        normalized = manifest_path.parent / "exports" / data.get("export_stamp", "preview") / "normalized"
        def operation(candidate: Path, existing: Path | None) -> str:
            if existing is None or not existing.exists(): return "CREATE"
            try: return "UNCHANGED" if self.model.pixel_sha256(candidate) == self.model.pixel_sha256(existing) else "REPLACE"
            except (AttributeError, OSError): return "REPLACE"
        bindings = tuple(data.get("layers", ()))
        direct_operations = tuple(operation(normalized / f"{binding['binding_id']}.png", Path(path)) for binding,path in zip(bindings,direct_changed))
        mirror_operations = []
        for binding in bindings:
            sid=(binding.get("owner"),binding.get("layer"),binding.get("profile"),binding.get("group"),binding.get("action"),counterpart)
            existing=counterpart_index.get(sid)
            mirror_operations.append(operation(normalized/f"mirror__{binding['binding_id']}.png",Path(existing[0]) if existing else None))
        direct_rows = tuple(PublishRow(
            str(binding.get("binding_id", binding.get("layer", ""))), selection.direction,
            operation_name, str(binding.get("source_contract", {}).get("path", "")),
            str(binding.get("publish_contract", {}).get("path", "")),
        ) for binding,operation_name in zip(bindings,direct_operations))
        mirror_rows = []
        for binding,path,operation_name in zip(bindings,mirror_paths,mirror_operations):
            sid=(binding.get("owner"),binding.get("layer"),binding.get("profile"),binding.get("group"),binding.get("action"),counterpart)
            existing=counterpart_index.get(sid)
            mirror_rows.append(PublishRow(str(binding.get("binding_id",binding.get("layer",""))),f"{selection.direction} -> {counterpart}",operation_name,display(str(existing[0])) if existing else "",path))
        timeline=data["timeline"]; durations=tuple(float(value) for value in timeline.get("durations", ()))
        variable_durations=bool(durations) and any(abs(value-durations[0])>1e-9 for value in durations[1:])
        try:
            identity = self.checkout_identity()
            publish_enabled = identity.publish_allowed
            block_reason = "" if publish_enabled else (
                "Use the isolated Operator art checkout to publish to main."
                if identity.kind == "COORDINATION MAIN"
                else f"Publishing requires {operator_art_worktree.ART_BRANCH}."
            )
        except (operator_art_worktree.ArtWorktreeError, OSError):
            # Injected model/backend pairs are used by fixture-only service smokes.
            publish_enabled = self.model is not model and self.workbench is not workbench
            block_reason = "Checkout identity could not be verified."
        return PublishView(
            selection,old_frames,new_frames,tuple(retired),tuple(new),migration,
            migration.audit if migration else "GREEN",counterpart,mirror_paths,
            tuple(mirror_operations),direct_operations,
            float(timeline.get("fps",timeline.get("preview_fps",12.0))),bool(timeline.get("loop",True)),
            variable_durations,durations,tuple(row.layer for row in direct_rows),direct_rows,
            tuple(mirror_rows),old_frames!=new_frames or bool(retired),True,
            publish_enabled, block_reason,
            readiness_status=readiness.status if readiness else ("ready" if publish_enabled else "blocked"),
            readiness_summary=(f"Publication readiness: {readiness.status.upper()}" if readiness else ""),
            readiness_blockers=readiness.blockers if readiness else (),
            readiness_preparations=readiness.preparations if readiness else (),
        )

    def publish(self, selection: AnimationSelection, full_validate: bool = False, mirror_counterpart: bool = False):
        pending_path = operator_art_worktree._pending_path(self.repo_root, self.workspace_root)
        if pending_path.exists() and self.model is model and self.workbench is workbench:
            checkout = self.checkout_identity()
            if not checkout.publish_allowed:
                raise operator_art_worktree.ArtWorktreeError(
                    "LAND PENDING retry is available only from the dedicated Operator art checkout."
                )
            pending = json.loads(pending_path.read_text(encoding="utf-8"))
            saved_identity = pending.get("identity", {})
            if not all(saved_identity.get(key) == getattr(selection, key) for key in ("profile", "group", "action", "direction")):
                raise operator_art_worktree.ArtWorktreeError("LAND PENDING belongs to another animation; select that animation before retrying.")
            result = operator_art_worktree.retry_pending_land(self.repo_root, pending_path)
            if result is None:
                raise operator_art_worktree.ArtWorktreeError("LAND PENDING receipt disappeared before retry.")
            result["coordination_sync"] = operator_art_worktree.best_effort_coordination_sync(
                self.coordination_root if self.coordination_root_configured else None
            )
            return result
        plan = self._plan(selection)
        manifest = self.workspace(selection) / "workbench.json"
        if self.model is not model and self.workbench is not workbench:
            return self.workbench.publish(manifest, self.aseprite, False, False, full_validate, plan, mirror_counterpart)
        data = self.workbench.load(manifest)
        canonical_paths: set[str] = set()
        for binding in data.get("layers", ()):
            for contract in (binding.get("source_contract", {}), binding.get("publish_contract", {})):
                path = str(contract.get("path", ""))
                if path:
                    canonical_paths.add(path)
        counterpart = self.workbench.horizontal_counterpart(selection.direction) if mirror_counterpart else None
        if counterpart:
            index = self._index()
            for binding in data.get("layers", ()):
                target = self.workbench._counterpart_target(binding, counterpart)
                canonical_paths.add(self.model.rel(target))
                identity = (binding.get("owner"), binding.get("layer"), binding.get("profile"), binding.get("group"), binding.get("action"), counterpart)
                existing = index.get(identity)
                if existing:
                    canonical_paths.add(self.model.rel(Path(existing[0])))
        allowlist = operator_art_worktree.publication_allowlist(self.repo_root, canonical_paths)
        def revalidate_before_mutation():
            current=self.workbench.load(manifest)
            stale=self.workbench.source_contract_freshness(current,self.repo_root)
            check=operator_art_worktree.inspect_publish_readiness(
                self.repo_root,self.coordination_root,self.workspace_root,
                selected_paths=canonical_paths,source_freshness=stale,
            )
            if check.status!="ready":
                raise operator_art_worktree.ArtWorktreeError(
                    "PUBLISH READINESS CHANGED BEFORE SOURCE MUTATION\n"+
                    "\n".join(check.blockers or check.preparations)
                )
        result = operator_art_worktree.publish_to_main(
            repo_root=self.repo_root, coordination_root=self.coordination_root,
            workspace_root=self.workspace_root, canonical_paths=canonical_paths,
            allowlist=allowlist,
            publish_once=lambda: self.workbench.publish(
                manifest, self.aseprite, False, False, full_validate, plan, mirror_counterpart,
            ),
            identity={
                "profile": selection.profile, "group": selection.group,
                "action": selection.action, "direction": selection.direction,
            }, mirror=mirror_counterpart,
            pre_publish_check=revalidate_before_mutation,
        )
        if result.get("status") == "landed":
            result["coordination_sync"] = operator_art_worktree.best_effort_coordination_sync(
                self.coordination_root if self.coordination_root_configured else None
            )
        return result

    def refresh(self, selection: AnimationSelection, discard: bool = False):
        return self.workbench.refresh(
            selection.profile, selection.action, selection.direction, selection.group,
            selection.weapon_id, selection.linked_profile, self.workspace_root,
            self.aseprite, discard,
        )

    def known_weapons(self) -> list[dict[str, str]]:
        try: payload = json.loads(self.catalog_path.read_text())
        except (FileNotFoundError, json.JSONDecodeError): return []
        rows = []
        for weapon_id, item in sorted(payload.get("weapons", {}).items()):
            rows.append({"weapon_id": weapon_id, "animation_profile": str(item.get("animation_profile", "")), "presentation_mode": str(item.get("presentation_mode", ""))})
        return rows

    def validation_commands(self, selection: AnimationSelection, full: bool = False) -> list[list[str]]:
        data = self._plan(selection)
        return [[str(part) for part in command] for command in self.workbench._validation_commands(data, full)]

    def validate(self, selection: AnimationSelection, full: bool = False) -> list[str]:
        output = []
        for command in self.validation_commands(selection, full):
            result = subprocess.run(command, cwd=self.repo_root, text=True, capture_output=True)
            combined = (result.stdout + result.stderr).strip()
            output.extend(combined.splitlines()[-40:])
            if result.returncode:
                raise self.model.WorkbenchError(f"validation failed ({result.returncode}): {' '.join(command)}\n{combined}")
        return output[-120:]

    def transaction_state(self, selection: AnimationSelection) -> tuple[str, str] | None:
        tx_root = self.workspace(selection) / "transactions"
        journals = sorted(tx_root.glob("*/transaction.json")) if tx_root.exists() else []
        if not journals: return None
        path = journals[-1]
        try: state = str(json.loads(path.read_text()).get("state", ""))
        except (OSError, json.JSONDecodeError): return None
        return state, str(path.parent)

    @staticmethod
    def project_error(error: Exception) -> ErrorView:
        return ErrorView.from_exception(error)
