"""Hash-bound review receipts for exact 2.5D Workbench leaves.

This module projects existing Workbench, Art Agent QA, and target authority. It
does not publish assets or create a second source of family progress truth.
"""
from __future__ import annotations

import hashlib
import json
import math
import re
import shutil
import subprocess
from pathlib import Path
from typing import Any

from PIL import Image

SCHEMA = "custodian.operator_2_5d_review_receipt.v1"
GENERATION = "operator_2_5d_128"


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(Path(path).read_bytes())


def canonical_json(value: Any) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()


def human_review_evidence_sha(*, identity: str, manifest_sha256: str, document_sha256: str,
                              frame_sha256: list[str], profile_sha256: str,
                              reference_sha256: str, frames: int, frame_size: list[int],
                              durations: list[float], findings_sha256: str) -> str:
    return sha256_bytes(canonical_json({"identity": identity, "manifest": manifest_sha256,
        "document": document_sha256, "frames": frame_sha256, "profile": profile_sha256,
        "reference": reference_sha256, "physical": [frames, *frame_size, durations],
        "qa": findings_sha256}))


def qa_state(qa: dict[str, Any]) -> str:
    """Map the live v2 QA result without treating advisory findings as blockers."""
    status = str(qa.get("status", "")).upper()
    findings = qa.get("findings", ())
    if status not in {"GREEN", "YELLOW", "NEEDS_HUMAN_REVIEW", "RED"}:
        return "RED"
    if any(not isinstance(item, dict) or str(item.get("severity", "")).lower() not in {"critical", "major", "advisory"}
           for item in findings):
        return "RED"
    if any(str(item.get("severity", "")).lower() == "critical" for item in findings if isinstance(item, dict)):
        return "RED"
    if status in {"RED", "FAIL", "BLOCKED"}:
        return "RED"
    if any(str(item.get("severity", "")).lower() == "major" for item in findings if isinstance(item, dict)):
        return "NEEDS_HUMAN_REVIEW"
    if status == "NEEDS_HUMAN_REVIEW":
        return status
    if status == "YELLOW" or findings:
        return "YELLOW"
    return "GREEN"


def human_review_is_valid(qa_status: str, human: dict[str, Any], evidence_sha: str) -> bool:
    """Validate the backend-derived human gate for the exact current QA state."""
    if qa_status in {"GREEN", "YELLOW"}:
        return human == {"status": "NOT_REQUIRED"}
    if qa_status == "NEEDS_HUMAN_REVIEW":
        return human in ({"status": "REQUIRED"}, {
            "status": "APPROVED",
            "provenance": {
                "kind": "workbench_explicit_user",
                "reviewer": "human-user",
                "control": "polish-human-approved",
            },
            "evidence_sha256": evidence_sha,
        })
    return qa_status == "RED" and human == {"status": "REQUIRED"}


def human_review_passes(qa_status: str, human: dict[str, Any], evidence_sha: str) -> bool:
    """Return whether human review permits verification for the live QA state."""
    return ((qa_status in {"GREEN", "YELLOW"} and human == {"status": "NOT_REQUIRED"})
            or (qa_status == "NEEDS_HUMAN_REVIEW" and human == {
                "status": "APPROVED",
                "provenance": {
                    "kind": "workbench_explicit_user",
                    "reviewer": "human-user",
                    "control": "polish-human-approved",
                },
                "evidence_sha256": evidence_sha,
            }))


class Operator2DReview:
    """Creates and validates a receipt around one attached exact Workbench leaf."""

    def __init__(self, *, service: Any, repo_root: Path, workspace_root: Path):
        self.service = service
        self.repo_root = Path(repo_root).resolve()
        self.workspace_root = Path(workspace_root).resolve()
        self.receipt_root = self.repo_root / ".ai/operator_animation_workbench/review_receipts/operator_2_5d_128"
        self.preview_root = self.repo_root / ".ai/operator_animation_workbench/runtime_preview"

    def _paths(self, selection: Any) -> tuple[Path, Path]:
        if getattr(selection, "art_generation", "") != GENERATION:
            raise ValueError("2.5D review requires an exact operator_2_5d_128 selection")
        workspace = Path(self.service.workspace(selection)).resolve()
        manifest = workspace / "workbench.json"
        document = workspace / "workbench.aseprite"
        if not manifest.is_file() or not document.is_file():
            raise ValueError("exact current Workbench manifest and saved document are required")
        return manifest, document

    def _receipt_path(self, selection: Any) -> Path:
        parts = [selection.profile, selection.group, selection.action, selection.direction]
        if any(not re.fullmatch(r"[A-Za-z0-9_-]+", str(part)) for part in parts):
            raise ValueError("review target identity contains an unsafe path component")
        return self.receipt_root / str(selection.profile) / str(selection.group) / str(selection.action) / f"{selection.direction}.json"

    @staticmethod
    def _under(root: Path, value: str | Path) -> Path:
        candidate = Path(value)
        if not candidate.is_absolute():
            candidate = root / candidate
        path = candidate.resolve()
        if not path.is_relative_to(root.resolve()):
            raise ValueError("review evidence path escapes its authorized root")
        return path

    @staticmethod
    def _approval_record(evidence_sha: str) -> dict[str, Any]:
        return {
            "status": "APPROVED",
            "provenance": {
                "kind": "workbench_explicit_user",
                "reviewer": "human-user",
                "control": "polish-human-approved",
            },
            "evidence_sha256": evidence_sha,
        }

    def inspect(self, selection: Any, *, sandbox_result: dict[str, Any] | None = None) -> dict[str, Any]:
        """Reinspect current QA and derive human state from current evidence."""
        return self._inspect(selection, sandbox_result=sandbox_result, approve_human=False)

    def _approve_human_review(self, selection: Any) -> dict[str, Any]:
        """Author approval only after the Workbench service observes explicit UI intent."""
        return self._inspect(selection, sandbox_result=None, approve_human=True)

    def _inspect(self, selection: Any, *, sandbox_result: dict[str, Any] | None,
                 approve_human: bool) -> dict[str, Any]:
        """Reinspect current QA and produce an honest, initially unverified receipt."""
        manifest_path, document_path = self._paths(selection)
        session_path = self.service.polish_attach(selection)
        art = self.service._polish(selection).service
        contract = art.inspect_polish_contract(session_path)
        if not contract.get("valid") or contract.get("art_generation") != GENERATION:
            raise ValueError("Art Agent refused the exact-current 2.5D Workbench contract")
        import animation_workbench
        physical = animation_workbench.inspect_saved_document_contract(manifest_path, art.aseprite)
        if ((int(physical["width"]), int(physical["height"])) != (128, 128)
                or int(physical["frames"]) < 1
                or len(physical["durations"]) != int(physical["frames"])
                or any(not math.isfinite(float(value)) or float(value) <= 0 for value in physical["durations"])):
            raise ValueError("saved document is outside the exact 128px 2.5D physical contract")
        rendered = art.render(session_path)
        analysis = self.service.polish_analyze(session_path)
        qa = analysis.get("qa", {})
        if qa.get("schema") != "custodian.operator_art_qa.v2":
            raise ValueError("review requires the authoritative operator_art_qa.v2 result")
        findings_digest = sha256_bytes(canonical_json(qa.get("findings", ())))
        profile_path = self.repo_root / "custodian/content/data/operator/authoring/operator_art_profile.json"
        profile_payload = json.loads(profile_path.read_text(encoding="utf-8"))
        profile_id = profile_payload.get("active_authoring_profile", GENERATION)
        profile_sha = str(profile_payload.get("profiles", {}).get(profile_id, {}).get("profile_sha256", ""))
        reference_sha = str(profile_payload.get("canonical_visual_reference", {}).get("sha256", ""))
        reference_path = self.repo_root / str(profile_payload.get("canonical_visual_reference", {}).get("path", ""))
        if not profile_sha or not reference_sha or not reference_path.is_file() or sha256_file(reference_path) != reference_sha:
            raise ValueError("accepted canonical profile/reference evidence is missing or changed")
        frame_paths = [Path(path) for path in rendered["frames"]]
        frame_digests = [sha256_file(path) for path in frame_paths]
        sandbox = sandbox_result or {"status": "NOT_RUN", "request_sha256": "", "result_sha256": ""}
        state = qa_state(qa)
        evidence_sha = human_review_evidence_sha(identity=selection.authoring_identity,
            manifest_sha256=sha256_file(manifest_path), document_sha256=sha256_file(document_path),
            frame_sha256=frame_digests, profile_sha256=profile_sha, reference_sha256=reference_sha,
            frames=int(physical["frames"]), frame_size=[int(physical["width"]), int(physical["height"])],
            durations=[float(value) for value in physical["durations"]], findings_sha256=findings_digest)
        if state in {"GREEN", "YELLOW"}:
            human = {"status": "NOT_REQUIRED"}
        else:
            human = {"status": "REQUIRED"}
            if state == "NEEDS_HUMAN_REVIEW":
                if approve_human:
                    human = self._approval_record(evidence_sha)
                else:
                    try:
                        previous = json.loads(self._receipt_path(selection).read_text(encoding="utf-8"))
                        previous_human = previous.get("human_review", {})
                        previous_receipt_digest = previous.get("receipt_sha256", "")
                        previous_receipt_payload = {key: value for key, value in previous.items()
                                                    if key != "receipt_sha256"}
                        previous_evidence = sha256_bytes(canonical_json({
                            "identity": previous.get("authoring_identity"),
                            "authority": previous.get("authority"),
                            "qa": previous.get("qa"),
                            "human_review": previous_human,
                        }))
                        if (previous.get("schema") == SCHEMA
                                and previous.get("authoring_identity") == selection.authoring_identity
                                and previous_receipt_digest == sha256_bytes(canonical_json(previous_receipt_payload))
                                and previous.get("evidence_sha256") == previous_evidence
                                and previous.get("qa", {}).get("status") == "NEEDS_HUMAN_REVIEW"
                                and previous_human == self._approval_record(evidence_sha)):
                            human = previous_human
                    except (OSError, ValueError, TypeError, json.JSONDecodeError):
                        pass
        sandbox_ok = sandbox.get("status") == "PASSED" and bool(sandbox.get("request_sha256")) and bool(sandbox.get("result_sha256"))
        receipt = {
            "schema": SCHEMA,
            "authoring_identity": selection.authoring_identity,
            "session_path": str(Path(session_path).resolve()),
            "authority": {
                "workbench_manifest_sha256": sha256_file(manifest_path),
                "workbench_document_sha256": sha256_file(document_path),
                "render_sha256": sha256_bytes("".join(frame_digests).encode()),
                "frame_sha256": frame_digests,
                "frame_paths": [str(path.resolve()) for path in frame_paths],
                "canonical_profile_sha256": profile_sha,
                "normalized_reference_sha256": reference_sha,
                "frames": int(physical["frames"]),
                "frame_size": [int(physical["width"]), int(physical["height"])],
                "durations": [float(value) for value in physical["durations"]],
            },
            "qa": {"status": state, "findings_sha256": findings_digest, "findings": qa.get("findings", [])},
            "human_review": human,
            "sandbox": sandbox,
            "runtime_verified": False,
        }
        receipt["evidence_sha256"] = sha256_bytes(canonical_json({"identity": receipt["authoring_identity"],
            "authority": receipt["authority"], "qa": receipt["qa"], "human_review": receipt["human_review"]}))
        receipt["receipt_sha256"] = sha256_bytes(canonical_json(receipt))
        path = self._receipt_path(selection)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
        if sandbox_ok:
            effective = self.current_receipt(selection)
            if effective and effective.get("runtime_verified"):
                receipt["runtime_verified"] = True
                receipt.pop("receipt_sha256")
                receipt["receipt_sha256"] = sha256_bytes(canonical_json(receipt))
                path.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
        return receipt

    def current_receipt(self, selection: Any) -> dict[str, Any] | None:
        """Return only a receipt whose exact current inputs and review proof match."""
        path = self._receipt_path(selection)
        try:
            receipt = json.loads(path.read_text(encoding="utf-8"))
            receipt_digest = receipt.pop("receipt_sha256", "")
            if not receipt_digest or receipt_digest != sha256_bytes(canonical_json(receipt)): return None
            receipt["receipt_sha256"] = receipt_digest
            manifest, document = self._paths(selection)
            authority = receipt["authority"]
            if receipt.get("schema") != SCHEMA or receipt.get("authoring_identity") != selection.authoring_identity:
                return None
            if authority["workbench_manifest_sha256"] != sha256_file(manifest): return None
            if authority["workbench_document_sha256"] != sha256_file(document): return None
            profile_path = self.repo_root / "custodian/content/data/operator/authoring/operator_art_profile.json"
            profile_payload = json.loads(profile_path.read_text(encoding="utf-8"))
            profile_id = profile_payload.get("active_authoring_profile", GENERATION)
            current_profile_sha = str(profile_payload.get("profiles", {}).get(profile_id, {}).get("profile_sha256", ""))
            if authority["canonical_profile_sha256"] != current_profile_sha: return None
            if authority["normalized_reference_sha256"] != str(profile_payload.get("canonical_visual_reference", {}).get("sha256", "")): return None
            reference_path = self.repo_root / str(profile_payload.get("canonical_visual_reference", {}).get("path", ""))
            if not reference_path.is_file() or sha256_file(reference_path) != authority["normalized_reference_sha256"]: return None
            session_path = self.service.polish_attach(selection)
            art = self.service._polish(selection).service
            contract = art.inspect_polish_contract(session_path)
            if not contract.get("valid") or contract.get("art_generation") != GENERATION: return None
            import animation_workbench
            physical = animation_workbench.inspect_saved_document_contract(manifest, art.aseprite)
            if ((int(physical["width"]), int(physical["height"])) != (128, 128)
                    or int(physical["frames"]) < 1
                    or (int(physical["width"]), int(physical["height"])) != tuple(authority["frame_size"])
                    or int(physical["frames"]) != int(authority["frames"])
                    or len(physical["durations"]) != int(physical["frames"])
                    or [float(value) for value in physical["durations"]] != [float(value) for value in authority["durations"]]):
                return None
            if (len(authority["durations"]) != authority["frames"]
                    or any(not math.isfinite(float(value)) or float(value) <= 0 for value in authority["durations"])): return None
            frame_paths = authority.get("frame_paths", [])
            art_root = (self.repo_root / ".ai/operator_art_agent").resolve()
            if len(frame_paths) != authority["frames"] or [sha256_file(self._under(art_root, p)) for p in frame_paths] != authority.get("frame_sha256"):
                return None
            analysis = self.service.polish_analyze(Path(receipt["session_path"]))
            current_qa = analysis.get("qa", {})
            if qa_state(current_qa) != receipt.get("qa", {}).get("status") or sha256_bytes(canonical_json(current_qa.get("findings", ()))) != receipt.get("qa", {}).get("findings_sha256"):
                return None
            if canonical_json(current_qa.get("findings", ())) != canonical_json(receipt.get("qa", {}).get("findings", ())): return None
            if [sha256_file(self._under(art_root, p)) for p in frame_paths] != authority.get("frame_sha256"):
                return None
            qa_digest = receipt.get("qa", {}).get("findings_sha256", "")
            expected_evidence = human_review_evidence_sha(identity=selection.authoring_identity,
                manifest_sha256=authority["workbench_manifest_sha256"],
                document_sha256=authority["workbench_document_sha256"], frame_sha256=authority["frame_sha256"],
                profile_sha256=authority["canonical_profile_sha256"],
                reference_sha256=authority["normalized_reference_sha256"], frames=authority["frames"],
                frame_size=authority["frame_size"], durations=authority["durations"], findings_sha256=qa_digest)
            human = receipt.get("human_review", {})
            qa_status = receipt.get("qa", {}).get("status")
            if not human_review_is_valid(qa_status, human, expected_evidence):
                return None
            expected_receipt_evidence = sha256_bytes(canonical_json({
                "identity": receipt["authoring_identity"],
                "authority": authority,
                "qa": receipt["qa"],
                "human_review": human,
            }))
            if receipt.get("evidence_sha256") != expected_receipt_evidence: return None
            sandbox = receipt.get("sandbox", {})
            if sandbox.get("status") == "PASSED":
                if not sandbox.get("request_sha256") or not sandbox.get("result_sha256"): return None
                result_path = self._under(self.preview_root, str(sandbox.get("result_path", "")))
                if not result_path.is_file() or sha256_file(result_path) != sandbox.get("result_sha256"): return None
                sandbox_result = json.loads(result_path.read_text(encoding="utf-8"))
                if sandbox_result.get("request_sha256") != sandbox.get("request_sha256") or sandbox_result.get("presentation") != "PASSED": return None
                if not sandbox.get("production_unchanged") or sandbox.get("production_before") != sandbox.get("production_after"): return None
                for raw_path, expected_hash in sandbox.get("production_before", {}).items():
                    safe_path = self._under(self.repo_root, raw_path)
                    if not safe_path.is_file() or sha256_file(safe_path) != expected_hash: return None
                request_path = self._under(self.preview_root, str(sandbox.get("request_path", "")))
                request = json.loads(request_path.read_text(encoding="utf-8"))
                request_digest = str(request.get("request_sha256", ""))
                payload_json = str(request.get("payload_json", ""))
                payload = json.loads(payload_json)
                outer_payload = {key: value for key, value in request.items() if key not in {"payload_json", "request_sha256"}}
                if (request_digest != sha256_bytes(payload_json.encode())
                        or payload != outer_payload
                        or request.get("evidence_sha256") != receipt.get("evidence_sha256")
                        or request_digest != sandbox.get("request_sha256")
                        or request.get("authoring_identity") != selection.authoring_identity
                        or request.get("durations") != authority.get("durations")
                        or [row.get("sha256") for row in request.get("frames", [])] != authority.get("frame_sha256")):
                    return None
                for row in request.get("frames", []):
                    frame_path = self._under(request_path.parent, str(row.get("path", "")))
                    if not frame_path.is_file() or sha256_file(frame_path) != row.get("sha256"): return None
                    if sha256_bytes(Image.open(frame_path).convert("RGBA").tobytes()) != row.get("pixel_sha256"): return None
            elif sandbox.get("status") not in {"NOT_RUN", "FAILED"}:
                return None
            receipt["runtime_verified"] = bool(
                human_review_passes(receipt["qa"]["status"], human, expected_evidence)
                and sandbox.get("status") == "PASSED")
            return receipt
        except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError):
            return None

    def family(self, records: list[Any] | tuple[Any, ...], *, profile: str, group: str, action: str) -> dict[str, Any]:
        """Derive all family cells from project_targets records plus current receipts."""
        cells = []
        for record in records:
            selection = record.selection
            if (selection.art_generation, selection.profile, selection.group, selection.action) != (GENERATION, profile, group, action):
                continue
            receipt = self.current_receipt(selection) if record.coverage == "CANONICAL_2_5D" and not record.stale else None
            cells.append({"direction": selection.direction, "coverage": record.coverage,
                          "workflow": record.workflow_status, "stale": bool(record.stale),
                          "runtime_verified": bool(receipt and receipt.get("runtime_verified")),
                          "qa": receipt.get("qa", {}).get("status", "UNREVIEWED") if receipt else "UNREVIEWED",
                          "human_review": receipt.get("human_review", {}).get("status", "NONE") if receipt else "NONE",
                          "sandbox": receipt.get("sandbox", {}).get("status", "NONE") if receipt else "NONE",
                          "receipt_sha256": receipt.get("receipt_sha256", "") if receipt else ""})
        cells.sort(key=lambda row: row["direction"])
        return {"profile": profile, "group": group, "action": action, "cells": cells,
                "complete": bool(cells) and all(cell["coverage"] == "CANONICAL_2_5D" and not cell["stale"] and cell["runtime_verified"] for cell in cells)}

    def make_sandbox_request(self, selection: Any, receipt: dict[str, Any], frame_paths: list[Path]) -> dict[str, Any]:
        """Copy exact frames to an immutable request bundle; no production assets are read."""
        if receipt.get("authoring_identity") != selection.authoring_identity:
            raise ValueError("sandbox request does not match the exact 2.5D selection")
        durations = receipt.get("authority", {}).get("durations", [])
        if (not durations or len(frame_paths) != len(durations)
                or len(receipt.get("authority", {}).get("frame_sha256", [])) != len(durations)
                or any(not math.isfinite(float(value)) or float(value) <= 0 for value in durations)):
            raise ValueError("sandbox request requires a complete positive physical duration contract")
        request_id = sha256_bytes(canonical_json([receipt["receipt_sha256"], receipt["authority"]["frame_sha256"]]))[:24]
        root = self.preview_root / request_id
        root.mkdir(parents=True, exist_ok=True)
        copied = []
        for index, source in enumerate(frame_paths):
            image = Image.open(source).convert("RGBA")
            if image.size != (128, 128): raise ValueError("2.5D sandbox accepts exact 128x128 full-body frames")
            destination = root / f"frame_{index:03d}.png"
            if destination.exists():
                if sha256_file(destination) != sha256_file(source):
                    raise ValueError("immutable sandbox frame already exists with different bytes")
            else:
                shutil.copyfile(source, destination)
            copied.append({"path": destination.name, "sha256": sha256_file(destination),
                           "pixel_sha256": sha256_bytes(image.tobytes())})
        if [item["sha256"] for item in copied] != receipt["authority"]["frame_sha256"]:
            raise ValueError("rendered Workbench frames changed before sandbox bundle creation")
        request = {"schema": "custodian.operator_2_5d_sandbox_request.v1", "request_id": request_id,
                   "authoring_identity": selection.authoring_identity,
                   "evidence_sha256": receipt.get("evidence_sha256", ""),
                   "frame_size": [128, 128], "durations": durations, "frames": copied}
        payload_json = json.dumps(request, separators=(",", ":"), ensure_ascii=False)
        request["payload_json"] = payload_json
        request["request_sha256"] = sha256_bytes(payload_json.encode())
        request_path = root / "request.json"
        if request_path.exists():
            existing = json.loads(request_path.read_text(encoding="utf-8"))
            if existing != request:
                raise ValueError("immutable sandbox request id already contains different evidence")
        else:
            request_path.write_text(json.dumps(request, indent=2) + "\n", encoding="utf-8")
        return request

    def run_sandbox(self, selection: Any, receipt: dict[str, Any], *, godot: str = "godot") -> dict[str, Any]:
        frame_paths = [Path(path) for path in receipt["authority"]["frame_paths"]]
        request = self.make_sandbox_request(selection, receipt, frame_paths)
        request_path = self.preview_root / request["request_id"] / "request.json"
        runtime_manifest = self.repo_root / "custodian/content/sprites/operator/runtime/operator_runtime_manifest.generated.json"
        runtime_frames = self.repo_root / "custodian/content/sprites/operator/runtime/operator_runtime_frames.tres"
        production_files = [runtime_manifest, runtime_frames]
        selector_policy = self.repo_root / "custodian/game/actors/operator/animations/operator_animation_selector.gd"
        if selector_policy.is_file(): production_files.append(selector_policy)
        if not runtime_manifest.is_file() or not runtime_frames.is_file() or not selector_policy.is_file():
            raise ValueError("production Operator runtime fence inputs are incomplete")
        try:
            manifest = json.loads(runtime_manifest.read_text(encoding="utf-8"))
            prefix = f"{selection.profile}/{selection.group}/{selection.action}/"
            runtime_rows = [row for key, row in manifest.get("animations", {}).items() if key.startswith(prefix)]
            for runtime_row in runtime_rows:
                for layer in runtime_row.get("layers", {}).values():
                    value = str(layer.get("path", ""))
                    if value.startswith("res://"):
                        candidate = self.repo_root / "custodian" / value.removeprefix("res://")
                        if candidate.is_file(): production_files.append(candidate)
        except (OSError, json.JSONDecodeError):
            pass
        before = {str(path): sha256_file(path) for path in production_files if path.is_file()}
        command = [godot, "--headless", "--path", str(self.repo_root / "custodian"),
                   "--scene", "res://scenes/debug/operator_2_5d_review_sandbox.tscn", "--", "--request", str(request_path)]
        completed = subprocess.run(command, capture_output=True, text=True, timeout=90, check=False)
        after = {str(path): sha256_file(path) for path in production_files if path.is_file()}
        result_path = request_path.parent / "result.json"
        try:
            result = json.loads(result_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            result = {"error": (completed.stderr or completed.stdout)[-4000:] or "sandbox emitted no result"}
        valid = completed.returncode == 0 and result.get("presentation") == "PASSED" and before == after \
            and result.get("request_sha256") == request["request_sha256"]
        return {"status": "PASSED" if valid else "FAILED", "request_sha256": request["request_sha256"],
                "result_sha256": sha256_file(result_path) if result_path.is_file() else "",
                "result_path": str(result_path.resolve()),
                "request_path": str(request_path.resolve()),
                "production_before": before, "production_after": after,
                "production_unchanged": before == after, "godot_exit_code": completed.returncode,
                "result": result, "stdout": completed.stdout[-3000:], "stderr": completed.stderr[-3000:]}
