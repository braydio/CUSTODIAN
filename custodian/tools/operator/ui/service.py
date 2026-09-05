"""Structured boundary between the TUI and Workbench V2."""
from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path
from typing import Any, Callable

import animation_frame_contract as frame_contract
import animation_workbench as workbench
import animation_workbench_model as model
import animation_preview
import animation_motion_preview

from .state import (
    AnimationRecord, AnimationSelection, ErrorView, ExistingContextView,
    LayerView, MigrationView, PublishView, SessionView,
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

    def _index(self):
        return self.model.source_index(self.source_root, self.weapon_root)

    def browser_records(self) -> list[AnimationRecord]:
        grouped: dict[tuple[str, str, str, str], list[Any]] = {}
        for sid, (_path, key) in self._index().items():
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
            records.append(AnimationRecord(AnimationSelection(profile, group, action, direction), frames, layers, completeness, detail))
        return records

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

    def launch_motion_runtime(self, selection: AnimationSelection, *, fps: float, travel_px: float,
                              curve: str, ground: str, mode: str):
        payload = {
            "schema": "custodian.operator_motion_request.v1",
            "identity": {"profile": selection.profile, "group": selection.group, "action": selection.action, "direction": selection.direction},
            "source": "runtime", "fps": float(fps), "travel_px": float(travel_px),
            "curve": curve, "ground": ground, "mode": mode,
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
    def filter_records(records: list[AnimationRecord], query: str) -> list[AnimationRecord]:
        needle = query.casefold().strip()
        if not needle:
            return records
        return [record for record in records if needle in " ".join((
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
    def migration_view(report: dict[str, Any] | None) -> MigrationView | None:
        if not report:
            return None
        position = report.get("position", {})
        value = position.get("after", position.get("frame", 0)) if isinstance(position, dict) else position
        audit = report.get("dependency_audit", {})
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
            workspace_display,
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

    def publish_preview(self, selection: AnimationSelection, full_validate: bool = False) -> PublishView:
        plan = self._plan(selection)
        manifest_path = self.workspace(selection) / "workbench.json"
        changed = self.workbench.publish(manifest_path, self.aseprite, False, True, full_validate, plan)
        data = self.workbench.load(manifest_path)
        migration = self.migration_view(data.get("pending_migration"))
        old_frames = int(data["timeline"]["source_clock_frames"])
        new_frames = int(data["timeline"]["workspace_clock_frames"])
        retired, new = [], []
        changed_set = {str(Path(path)) for path in changed}
        for binding in data.get("layers", ()):
            old = str(binding.get("source_contract", {}).get("path", ""))
            target = str(binding.get("publish_contract", {}).get("path", old))
            if target in changed_set or old != target:
                retired.append(old); new.append(target)
        return PublishView(selection, old_frames, new_frames, tuple(retired), tuple(new), migration, migration.audit if migration else "GREEN")

    def publish(self, selection: AnimationSelection, full_validate: bool = False):
        plan = self._plan(selection)
        return self.workbench.publish(self.workspace(selection) / "workbench.json", self.aseprite, False, False, full_validate, plan)

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
