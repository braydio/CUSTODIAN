"""Guided, resumable intake orchestration for projected Operator 2.5D targets."""
from __future__ import annotations

import hashlib
import json
import os
import shlex
import subprocess
from pathlib import Path
from typing import Any

import operator_animation_targets
import operator_asset_schema as schema
import animation_workbench
import animation_workbench_model as workbench_model
from art_agent.source_service import SourceArtService, sha256, write_json
from ui.state import AnimationSelection


WORKBENCH_ROOT_NAME = ".ai/operator_animation_workbench"
PROFILE_PATH = "custodian/content/data/operator/authoring/operator_art_profile.json"


class IngressError(RuntimeError):
    pass


class Operator2DIngress:
    """Coordinates target identity, Source Sessions, and resumable direction packages."""

    def __init__(self, repo_root: Path, *, source: SourceArtService | None = None,
                 workspace_root: Path | None = None):
        self.repo_root = Path(repo_root)
        self.workspace_root = Path(workspace_root or (self.repo_root / WORKBENCH_ROOT_NAME))
        self.package_root = self.workspace_root / "import_packages"
        self.source = source or SourceArtService()
        self.plan_path = self.repo_root / "design/02_features/animation/OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json"

    def _family(self, selection: AnimationSelection):
        if selection.art_generation != "operator_2_5d_128":
            raise IngressError("guided intake requires an exact operator_2_5d_128 selection")
        families = operator_animation_targets.target_families(operator_animation_targets.load_plan(self.plan_path))
        family = next((item for item in families if
                       (item.generation, item.profile, item.group, item.action) ==
                       (selection.art_generation, selection.profile, selection.group, selection.action)), None)
        if family is None or selection.direction not in family.directions:
            raise IngressError("selection is not a target in the current 2.5D projection")
        return family

    def target_binding(self, selection: AnimationSelection, layer: str = "full_body") -> dict[str, Any]:
        family = self._family(selection)
        if layer not in family.required_layers:
            raise IngressError(f"layer {layer!r} is not required by this target")
        profile_sha, reference_sha = operator_animation_targets._profile_hashes(self.repo_root)
        if profile_sha != family.canonical_profile_sha256 or reference_sha != family.normalized_reference_sha256:
            raise IngressError("2.5D profile or normalized reference changed; refresh target authority")
        contract = family.frame_contract
        frames = int(contract.get("frames", 0))
        size = contract.get("frame_size", [128, 128])
        if frames < 1 or list(size) != [128, 128]:
            raise IngressError("projected target frame contract is unsupported")
        return {"art_generation": family.generation, "profile": family.profile,
                "group": family.group, "action": family.action,
                "direction": selection.direction, "layer": layer,
                "authoring_identity": selection.authoring_identity,
                "canonical_profile_sha256": profile_sha,
                "normalized_reference_sha256": reference_sha,
                "frames": frames, "frame_size": list(size)}

    @staticmethod
    def _package_id(targets: list[dict[str, Any]], source_hashes: list[str]) -> str:
        stable = json.dumps({"targets": targets, "sources": source_hashes}, sort_keys=True, separators=(",", ":"))
        return hashlib.sha256(stable.encode()).hexdigest()[:20]

    def create_package(self, targets: list[AnimationSelection], *, source_paths: dict[str, Path | str],
                       direction_map: dict[str, str] | None = None) -> Path:
        """Create one explicit direction package; direction keys are never inferred from pixels."""
        if len(targets) not in {1, 8}:
            raise IngressError("an intake package must contain one direction or all eight directions")
        bindings = [self.target_binding(selection) for selection in targets]
        family_ids = {(item["profile"], item["group"], item["action"]) for item in bindings}
        if len(family_ids) != 1 or len({item["direction"] for item in bindings}) != len(bindings):
            raise IngressError("package targets must be unique directions from one semantic family")
        if len(targets) == 8 and {item["direction"] for item in bindings} != set(operator_animation_targets.CANONICAL_DIRECTIONS):
            raise IngressError("eight-direction package must name all eight canonical directions")
        if set(source_paths) != {item["direction"] for item in bindings}:
            raise IngressError("each target direction needs exactly one explicitly mapped source PNG")
        for selection, binding in zip(targets, bindings):
            family = self._family(selection)
            present = operator_animation_targets._generation_source_files(self.repo_root, family, selection.direction)
            if present.get(binding["layer"]):
                raise IngressError(f"{selection.direction} already has a same-generation canonical source")
        if direction_map is not None and direction_map != {key: key for key in source_paths}:
            raise IngressError("combined-sheet direction maps must explicitly map each source cell to its target direction")
        sources = {}
        for direction, source_path in source_paths.items():
            authorized = self.source.authorize_source_path(Path(source_path))
            if authorized.suffix.lower() != ".png":
                raise IngressError("intake accepts PNG sources only")
            sources[direction] = {"path": str(authorized), "sha256": sha256(authorized)}
        if len(targets) == 8 and len({item["path"] for item in sources.values()}) != 8:
            raise IngressError("eight-direction intake requires eight explicitly selected PNG files")
        package_id = self._package_id(bindings, [sources[key]["sha256"] for key in sorted(sources)])
        path = self.package_root / package_id / "package.json"
        if path.exists():
            existing = json.loads(path.read_text(encoding="utf-8"))
            if existing.get("targets") != bindings or existing.get("sources") != sources:
                raise IngressError("package id collision with different target or source proof")
            return path
        payload = {"schema": "custodian.operator_2_5d_import_package.v1", "package_id": package_id,
                   "targets": bindings, "sources": sources,
                   "authority": {"plan_sha256": sha256(self.plan_path),
                                 "profile_sha256": bindings[0]["canonical_profile_sha256"],
                                 "reference_sha256": bindings[0]["normalized_reference_sha256"]},
                   "cells": {item["direction"]: {"source_session": "", "terminal_state": "PENDING", "error": ""}
                             for item in bindings}}
        write_json(path, payload)
        return path

    def start_cell(self, package_path: Path | str, direction: str, *, columns: int | None = None,
                   rows: int = 1) -> Path:
        path = Path(package_path)
        package = json.loads(path.read_text(encoding="utf-8"))
        if sha256(self.plan_path) != package.get("authority", {}).get("plan_sha256"):
            raise IngressError("target projection changed after package creation; refresh intake authority")
        cell = package["cells"].get(direction)
        if cell is None:
            raise IngressError("direction is not part of this package")
        binding = next(item for item in package["targets"] if item["direction"] == direction)
        source = package["sources"][direction]
        if sha256(Path(source["path"])) != source["sha256"]:
            raise IngressError("source PNG changed after package creation")
        current_binding = self.target_binding(AnimationSelection(
            binding["profile"], binding["group"], binding["action"], direction,
            art_generation=binding["art_generation"]), binding["layer"])
        if current_binding != binding:
            raise IngressError("target authority changed after package creation")
        if cell.get("source_session"):
            session_path = Path(cell["source_session"])
            session = self.source.status(session_path)
            if session.get("source_sha256") != source["sha256"] or session.get("target_binding") != binding:
                raise IngressError("saved Source Session proof is stale; refusing to restart conversion")
            return session_path
        session_path = self.source.start(source_path=source["path"], frames=binding["frames"],
                                         target_size=128, columns=columns, rows=rows)
        self.source.bind_target(session_path, binding, donor_provenance={"source_path": source["path"],
                                                                         "source_sha256": source["sha256"]})
        cell["source_session"] = str(session_path.resolve())
        cell["terminal_state"] = "SOURCE_STAGED"
        write_json(path, package)
        return session_path

    def record_blocked(self, package_path: Path | str, direction: str, reason: str) -> None:
        if not reason.strip():
            raise IngressError("blocked package cells require a durable reason")
        path = Path(package_path)
        package = json.loads(path.read_text(encoding="utf-8"))
        if direction not in package["cells"]:
            raise IngressError("direction is not part of this package")
        package["cells"][direction].update({"terminal_state": "BLOCKED", "error": reason.strip()})
        write_json(path, package)

    def process_cell(self, package_path: Path | str, direction: str, *,
                     execution_env: dict[str, str] | None = None) -> dict[str, Any]:
        try:
            return self._process_cell(package_path, direction, execution_env=execution_env)
        except Exception as error:
            self.record_blocked(package_path, direction, f"{type(error).__name__}: {error}")
            raise

    def process_package(self, package_path: Path | str, *,
                        execution_env: dict[str, str] | None = None) -> dict[str, Any]:
        """Advance every direction independently and persist each failure locally."""
        path = Path(package_path)
        package = json.loads(path.read_text(encoding="utf-8"))
        outcomes: dict[str, dict[str, Any]] = {}
        for binding in package.get("targets", []):
            direction = binding["direction"]
            try:
                outcomes[direction] = self.process_cell(path, direction, execution_env=execution_env)
            except Exception:
                latest = json.loads(path.read_text(encoding="utf-8"))
                outcomes[direction] = dict(latest["cells"][direction])
        states = [cell.get("terminal_state", "PENDING") for cell in outcomes.values()]
        counts = {state: states.count(state) for state in ("EDITABLE_WORKBENCH", "BLOCKED", "PENDING")}
        complete = not counts["PENDING"] and not counts["BLOCKED"]
        return {"complete": complete, "cells": outcomes, "counts": counts}

    def _workbench_root(self, binding: dict[str, Any]) -> Path:
        return self.workspace_root / binding["art_generation"] / binding["profile"] / binding["group"] / binding["action"] / binding["direction"]

    def _validate_workbench(self, binding: dict[str, Any], candidate: Path,
                            workbench_value: str | None = None) -> Path:
        workspace = self._workbench_root(binding)
        if workbench_value and Path(workbench_value).resolve() != workspace.resolve():
            raise IngressError("saved Workbench path does not match the exact target workspace")
        manifest_path = workspace / "workbench.json"
        document_path = workspace / "workbench.aseprite"
        if not manifest_path.is_file() or not document_path.is_file() or document_path.stat().st_size == 0:
            raise IngressError("target Workbench document or manifest is missing")
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            raise IngressError(f"target Workbench manifest is unreadable: {error}") from error
        identity = {key: manifest.get("identity", {}).get(key)
                    for key in ("profile", "group", "action", "direction")}
        expected_identity = {key: binding[key] for key in identity}
        creation = manifest.get("creation", {})
        timeline = manifest.get("timeline", {})
        canvas = manifest.get("canvas", {})
        size = list(binding["frame_size"])
        if (identity != expected_identity
                or creation.get("art_generation") != binding["art_generation"]
                or creation.get("authoring_identity") != binding["authoring_identity"]
                or creation.get("template") != "full_body"
                or creation.get("import_sources", {}).get(binding["layer"]) != str(candidate.resolve())
                or int(timeline.get("workspace_clock_frames", 0)) != int(binding["frames"])
                or int(timeline.get("document_frames", 0)) != int(binding["frames"])
                or [int(canvas.get("width", 0)), int(canvas.get("height", 0))] != size
                or Path(manifest.get("aseprite", {}).get("path", "")).resolve() != document_path.resolve()):
            raise IngressError("target Workbench identity or frame contract does not match the package")
        try:
            physical = animation_workbench.inspect_saved_document_contract(manifest_path)
            physical_frames = int(physical["frames"])
            physical_canvas = [int(physical["width"]), int(physical["height"])]
            durations = [float(value) for value in physical["durations"]]
            expected_duration = 1.0 / float(timeline.get("preview_fps", timeline.get("fps", 0)) or 1)
            timing_matches = (len(durations) == physical_frames
                              and all(abs(value - expected_duration) <= 0.001 for value in durations))
        except (workbench_model.WorkbenchError, OSError, ValueError, TypeError, KeyError) as error:
            raise IngressError(f"saved Workbench Aseprite contract is unreadable: {error}") from error
        if (physical_frames != int(binding["frames"])
                or physical_frames != int(timeline["document_frames"])
                or physical_canvas != size or not timing_matches):
            raise IngressError(
                "saved Workbench Aseprite contract does not match the target: "
                f"document={physical_frames}f/{physical_canvas}, target={binding['frames']}f/{size}, "
                f"uniform timing={'yes' if timing_matches else 'no'}; document bytes preserved"
            )
        layers = manifest.get("layers", [])
        matching = [row for row in layers if row.get("layer") == binding["layer"]]
        if len(matching) != 1:
            raise IngressError("target Workbench is missing its unique imported layer")
        layer = matching[0]
        contract = layer.get("workspace_contract", {})
        if (int(contract.get("frames", 0)) != int(binding["frames"])
                or list(contract.get("frame_size", ())) != size
                or layer.get("input_path") != str(candidate.resolve())):
            raise IngressError("target Workbench layer contract does not match the reviewed candidate")
        return workspace

    def _validate_ready_proof(self, package_path: Path, direction: str,
                              cell: dict[str, Any], *, require_receipt: bool) -> dict[str, Any]:
        package = json.loads(package_path.read_text(encoding="utf-8"))
        binding = next(item for item in package["targets"] if item["direction"] == direction)
        session_path = self.start_cell(package_path, direction)
        session, session_root, _session_file = self.source.load(session_path)
        if session.state != "READY" or session.target_binding != binding:
            raise IngressError("completed intake requires the current READY Source Session target proof")
        candidate = Path(session.selected_candidate).resolve(strict=True)
        candidate_sha = sha256(candidate)
        if not session.reviewed_candidate_sha256 or candidate_sha != session.reviewed_candidate_sha256:
            raise IngressError("reviewed candidate proof changed after Source Session review")
        if require_receipt and cell.get("reviewed_candidate_sha256") != candidate_sha:
            raise IngressError("completed package candidate receipt does not match the current Source Session")
        key = schema.OperatorAssetKey("operator", binding["layer"], binding["profile"], binding["group"],
                                      binding["action"], direction, binding["frames"], 128, 128)
        destination_name = schema.canonical_filename(key)
        handoff = self.source.handoff(session_path, destination_name=destination_name,
                                      art_generation=binding["art_generation"], dry_run=True)
        if handoff.get("status") != "DRY_RUN" or handoff.get("operation") != "REUSE":
            raise IngressError("READY Source Session does not prove the existing reviewed handoff")
        candidate_path = str(Path(handoff["candidate"]).resolve())
        if require_receipt and cell.get("handoff") != candidate_path:
            raise IngressError("completed package handoff receipt does not match current source proof")
        workspace = self._validate_workbench(binding, candidate, cell.get("workbench"))
        if require_receipt and cell.get("workbench") != str(workspace):
            raise IngressError("completed package has no exact target Workbench receipt")
        return {"terminal_state": "EDITABLE_WORKBENCH", "source_session": str(session_root / "session.json"),
                "workbench": str(workspace), "reviewed_candidate_sha256": candidate_sha,
                "handoff": candidate_path, "error": ""}

    def _process_cell(self, package_path: Path | str, direction: str, *,
                      execution_env: dict[str, str] | None = None) -> dict[str, Any]:
        """Run the approved source proof, construct its editable Workbench, then stage handoff."""
        path = Path(package_path)
        package = json.loads(path.read_text(encoding="utf-8"))
        cell = package["cells"].get(direction)
        if cell is None:
            raise IngressError("direction is not part of this package")
        if cell.get("terminal_state") == "EDITABLE_WORKBENCH":
            self._validate_ready_proof(path, direction, cell, require_receipt=True)
            return dict(cell)
        session_path = self.start_cell(path, direction)
        session = self.source.status(session_path)
        state = session.get("state")
        if state == "READY":
            recovered = self._validate_ready_proof(path, direction, cell, require_receipt=False)
            package = json.loads(path.read_text(encoding="utf-8"))
            package["cells"][direction].update(recovered)
            write_json(path, package)
            return dict(package["cells"][direction])
        if state == "STAGED":
            self.source.analyze(session_path)
            state = "ANALYZED"
        if state == "ANALYZED":
            self.source.plan_normalization(session_path, mode="operator_profile")
            state = "PLANNED"
        if state == "PLANNED":
            production_output = Path(session["root"]) / "production/crisp.png"
            if production_output.is_file():
                # A crash after conversion but before receipt persistence can be
                # resumed through deterministic replay verification without
                # repeating the conversion write.
                self.source.verify_production(session_path)
            else:
                command = self.source.production_command(session_path)["command"]
                shell = "source tools/custodian_aliases.sh && " + " ".join(shlex.quote(str(part)) for part in command)
                env = os.environ.copy()
                env.update(execution_env or {})
                subprocess.run(["bash", "-lc", shell], cwd=self.repo_root, check=True, env=env)
                self.source.verify_production(session_path)
            state = "CONVERTED"
        elif state == "CONVERTED":
            self.source.verify_production(session_path)
        if state == "CONVERTED":
            review = self.source.review(session_path)
            if review.get("status") != "PASS":
                reason = (f"SourceArtService normalization review returned {review.get('status', 'unknown')}: "
                          f"{review.get('findings', [])}")
                self.record_blocked(path, direction, reason)
                raise IngressError(reason)
        elif state != "REVIEWED":
            raise IngressError(f"Source Session is in unsupported resumable state {state!r}")
        binding = next(item for item in package["targets"] if item["direction"] == direction)
        session, session_root, _ = self.source.load(session_path)
        candidate = Path(session.selected_candidate)
        if session.target_binding != binding or session.reviewed_candidate_sha256 != sha256(candidate):
            raise IngressError("Source Session target or reviewed candidate proof changed")
        target = AnimationSelection(binding["profile"], binding["group"], binding["action"], direction,
                                    art_generation=binding["art_generation"])
        options = {"profile": binding["profile"], "group": binding["group"], "action": binding["action"],
                   "direction": direction, "frames": binding["frames"], "frame_size": tuple(binding["frame_size"]),
                   "fps": 8.0, "loop": True, "template": "full_body",
                   "art_generation": binding["art_generation"], "initial_sources": {binding["layer"]: str(candidate)}}
        workbench_root = self._workbench_root(binding)
        manifest_path = workbench_root / "workbench.json"
        document_path = workbench_root / "workbench.aseprite"
        manifest_exists, document_exists = manifest_path.is_file(), document_path.is_file()
        if manifest_exists != document_exists:
            raise IngressError("target Workbench is incomplete; refusing to rebuild or overwrite it")
        if manifest_exists:
            self._validate_workbench(binding, candidate, str(workbench_root))
        else:
            if state == "READY":
                raise IngressError("READY Source Session has no existing target Workbench to resume")
            _manifest, workbench_root = animation_workbench.create_animation(
                options["profile"], options["action"], options["direction"], group=options["group"],
                frames=options["frames"], frame_size=options["frame_size"], fps=options["fps"],
                loop=options["loop"], template=options["template"],
                root=self.workspace_root, repo_root=self.repo_root,
                source_root=self.repo_root / "custodian/content/sprites/operator/source",
                weapon_root=self.repo_root / "custodian/content/sprites/weapons",
                art_generation=target.art_generation, initial_sources=options["initial_sources"],
            )
            self._validate_workbench(binding, candidate, str(workbench_root))
        key = schema.OperatorAssetKey("operator", binding["layer"], binding["profile"], binding["group"],
                                      binding["action"], direction, binding["frames"], 128, 128)
        destination_name = schema.canonical_filename(key)
        handoff = self.source.handoff(session_path, destination_name=destination_name,
                                      art_generation=target.art_generation)
        if handoff.get("status") != "READY_FOR_INGEST":
            raise IngressError("reviewed candidate did not reach the specialized Operator handoff")
        package = json.loads(path.read_text(encoding="utf-8"))
        cell = package["cells"][direction]
        cell.update({"terminal_state": "EDITABLE_WORKBENCH", "source_session": str(session_root / "session.json"),
                     "workbench": str(workbench_root), "reviewed_candidate_sha256": sha256(candidate),
                     "handoff": handoff.get("candidate", ""), "error": ""})
        write_json(path, package)
        return dict(cell)

    def validate_package(self, package_path: Path | str) -> dict[str, Any]:
        path = Path(package_path)
        package = json.loads(path.read_text(encoding="utf-8"))
        for direction, cell in package["cells"].items():
            if cell["terminal_state"] not in {"EDITABLE_WORKBENCH", "BLOCKED"}:
                raise IngressError(f"package direction {direction} is not terminal")
            if cell["terminal_state"] == "BLOCKED" and not cell.get("error"):
                raise IngressError(f"package direction {direction} is blocked without a reason")
            if cell["terminal_state"] == "EDITABLE_WORKBENCH":
                self._validate_ready_proof(path, direction, cell, require_receipt=True)
        return {"complete": True, "cells": package["cells"]}
