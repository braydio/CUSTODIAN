from __future__ import annotations

import fcntl
import json
import os
import shutil
import uuid
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterator

import animation_workbench as workbench
import animation_workbench_model as model

from .aseprite_bridge import ArtAgentBridge
from .models import ArtIdentity, ArtSession, REQUEST_SCHEMA
from .render import make_before_after, make_contact_sheet, make_diff, split_strip

ART_ROOT = model.REPO_ROOT / ".ai/operator_art_agent"
MUTATION_TYPES = {
    "paint_pixels",
    "erase_pixels",
    "stroke",
    "copy_region",
    "move_region",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n")


def append_jsonl(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as stream:
        stream.write(json.dumps(payload, sort_keys=True) + "\n")


@contextmanager
def mutation_lock(workbench_path: Path) -> Iterator[None]:
    lock_path = workbench_path.with_name(".operator_art_agent.lock")
    with lock_path.open("w", encoding="utf-8") as lock:
        try:
            fcntl.flock(lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as error:
            raise model.WorkbenchError(
                "Operator Art Agent workbench is already being mutated"
            ) from error
        lock.write(str(os.getpid()))
        lock.flush()
        try:
            yield
        finally:
            fcntl.flock(lock.fileno(), fcntl.LOCK_UN)


class ArtAgentService:
    def __init__(
        self,
        *,
        art_root: Path = ART_ROOT,
        workspace_root: Path = workbench.DEFAULT_ROOT,
        aseprite: Path | None = None,
        bridge_factory=ArtAgentBridge,
    ):
        self.art_root = Path(art_root)
        self.workspace_root = Path(workspace_root)
        self.aseprite = aseprite
        self.bridge_factory = bridge_factory

    def start_session(
        self,
        *,
        profile: str,
        action: str,
        direction: str,
        group: str = "",
        weapon: str = "",
        linked_profile: str = "",
    ) -> Path:
        manifest, workbench_root = workbench.ensure(
            profile,
            action,
            direction,
            group,
            weapon,
            linked_profile,
            self.workspace_root,
            self.aseprite,
        )
        self._assert_workbench_usable(manifest, workbench_root / "workbench.aseprite")
        identity_data = manifest["identity"]
        identity = ArtIdentity(
            profile=identity_data["profile"],
            group=identity_data["group"],
            action=identity_data["action"],
            direction=identity_data["direction"],
            weapon=str(manifest.get("context", {}).get("weapon_id", weapon)),
            linked_profile=str(
                manifest.get("context", {}).get("linked_profile", linked_profile)
            ),
        )
        session_id = uuid.uuid4().hex[:12]
        root = (
            self.art_root
            / identity.profile
            / identity.group
            / identity.action
            / identity.direction
            / session_id
        )
        for child in ("requests", "responses", "backups", "previews/frames"):
            (root / child).mkdir(parents=True, exist_ok=True)
        workbench_path = workbench_root / "workbench.aseprite"
        manifest_path = workbench_root / "workbench.json"
        sha = model.file_sha256(workbench_path)
        session = ArtSession.create(
            session_id=session_id,
            created_utc=utc_now(),
            identity=identity,
            workbench_manifest=str(manifest_path.resolve()),
            workbench_path=str(workbench_path.resolve()),
            context_fingerprint=manifest.get("context", {}).get("fingerprint", ""),
            workbench_sha256=sha,
        )
        session_path = root / "session.json"
        write_json(session_path, session.to_json())
        shutil.copy2(workbench_path, root / "backups/000000_baseline.aseprite")
        return session_path

    def load_session(self, session_path: Path) -> ArtSession:
        return ArtSession.from_json(json.loads(Path(session_path).read_text()))

    def save_session(self, session_path: Path, session: ArtSession) -> None:
        write_json(Path(session_path), session.to_json())

    def status(self, session_path: Path) -> dict[str, Any]:
        session = self.load_session(session_path)
        workbench_path = Path(session.workbench_path)
        actual_sha = model.file_sha256(workbench_path) if workbench_path.exists() else ""
        return {
            **session.to_json(),
            "actual_workbench_sha256": actual_sha,
            "external_change": actual_sha != session.expected_workbench_sha256,
        }

    def inspect(self, session_path: Path) -> dict[str, Any]:
        session, manifest, root = self._checked_session(session_path)
        response = self._execute_read_request(
            session,
            root,
            {"type": "inspect"},
        )
        response["identity"] = session.to_json()["identity"]
        response["context_fingerprint"] = session.context_fingerprint
        return response

    def render(self, session_path: Path) -> dict[str, Any]:
        session, manifest, root = self._checked_session(session_path)
        previews = root / "previews"
        current = previews / "current.png"
        self._execute_read_request(
            session,
            root,
            {"type": "render", "output": str(current.resolve())},
        )
        canvas = manifest["canvas"]
        frame_count = int(manifest["timeline"]["document_frames"])
        frames = split_strip(
            current,
            frame_width=int(canvas["width"]),
            frame_height=int(canvas["height"]),
            frame_count=frame_count,
            output_dir=previews / "frames",
        )
        contact_sheet = previews / "contact_sheet.png"
        make_contact_sheet(frames, contact_sheet)
        workbench_root = Path(session.workbench_manifest).parent
        source_baseline = workbench_root / "baseline/reference_composite.png"
        baseline = previews / "baseline.png"
        shutil.copy2(source_baseline, baseline)
        diff = previews / "diff.png"
        before_after = previews / "before_after.png"
        make_diff(baseline, current, diff)
        make_before_after(baseline, current, before_after)
        return {
            "strip": str(current.resolve()),
            "baseline": str(baseline.resolve()),
            "contact_sheet": str(contact_sheet.resolve()),
            "diff": str(diff.resolve()),
            "before_after": str(before_after.resolve()),
            "frames": [str(path.resolve()) for path in frames],
        }

    def apply_operation(
        self,
        session_path: Path,
        operation: dict[str, Any],
    ) -> dict[str, Any]:
        if operation.get("type") not in MUTATION_TYPES:
            raise model.WorkbenchError(f"unsupported Art Agent V1 mutation: {operation.get('type')}")
        session_path = Path(session_path)
        session, manifest, root = self._checked_session(session_path)
        workbench_path = Path(session.workbench_path)
        with mutation_lock(workbench_path):
            actual_sha = model.file_sha256(workbench_path)
            if actual_sha != session.expected_workbench_sha256:
                raise model.WorkbenchError(
                    "WORKBENCH CHANGED OUTSIDE ART AGENT SESSION"
                )
            operation_id = session.operation_count + 1
            request_id = f"{operation_id:06d}"
            backup = root / "backups" / f"{request_id}.aseprite"
            shutil.copy2(workbench_path, backup)
            request_path = root / "requests" / f"{request_id}.json"
            response_path = root / "responses" / f"{request_id}.json"
            request = self._build_request(session, request_id, operation)
            write_json(request_path, request)
            try:
                response = self.bridge_factory(aseprite=self.aseprite).execute(
                    request_path=request_path,
                    response_path=response_path,
                )
            except Exception as error:
                shutil.copy2(backup, workbench_path)
                session.operation_count = operation_id
                session.expected_workbench_sha256 = model.file_sha256(workbench_path)
                self.save_session(session_path, session)
                append_jsonl(
                    root / "operations.jsonl",
                    {
                        "operation_id": operation_id,
                        "timestamp_utc": utc_now(),
                        "type": operation["type"],
                        "arguments": operation,
                        "status": "FAILED_ROLLED_BACK",
                        "workbench_sha256_before": actual_sha,
                        "workbench_sha256_after": session.expected_workbench_sha256,
                        "backup": str(backup.resolve()),
                        "error": str(error),
                    },
                )
                raise
            after_sha = model.file_sha256(workbench_path)
            record = {
                "operation_id": operation_id,
                "timestamp_utc": utc_now(),
                "type": operation["type"],
                "arguments": operation,
                "status": "APPLIED",
                "workbench_sha256_before": actual_sha,
                "workbench_sha256_after": after_sha,
                "backup": str(backup.resolve()),
                "response": response,
            }
            append_jsonl(root / "operations.jsonl", record)
            session.operation_count = operation_id
            session.expected_workbench_sha256 = after_sha
            self.save_session(session_path, session)
            return record

    def undo_last(self, session_path: Path) -> dict[str, Any]:
        session_path = Path(session_path)
        session, _manifest, root = self._checked_session(session_path)
        workbench_path = Path(session.workbench_path)
        with mutation_lock(workbench_path):
            record = self._last_active_mutation(root / "operations.jsonl")
            if record is None:
                raise model.WorkbenchError("nothing to undo")
            actual_sha = model.file_sha256(workbench_path)
            if actual_sha != record["workbench_sha256_after"]:
                raise model.WorkbenchError(
                    "cannot undo: workbench changed since last operation"
                )
            backup = Path(record["backup"])
            shutil.copy2(backup, workbench_path)
            restored_sha = model.file_sha256(workbench_path)
            session.expected_workbench_sha256 = restored_sha
            self.save_session(session_path, session)
            undo_record = {
                "type": "undo",
                "timestamp_utc": utc_now(),
                "target_operation_id": record["operation_id"],
                "workbench_sha256_before": actual_sha,
                "workbench_sha256_after": restored_sha,
            }
            append_jsonl(root / "operations.jsonl", undo_record)
            return {
                "undone_operation": record["operation_id"],
                "workbench_sha256": restored_sha,
            }

    def close(self, session_path: Path) -> dict[str, Any]:
        session = self.load_session(session_path)
        session.state = "CLOSED"
        self.save_session(Path(session_path), session)
        return session.to_json()

    def _checked_session(
        self,
        session_path: Path,
    ) -> tuple[ArtSession, dict[str, Any], Path]:
        session_path = Path(session_path)
        session = self.load_session(session_path)
        if session.state != "ACTIVE":
            raise model.WorkbenchError("Art Agent session is not active")
        manifest_path = Path(session.workbench_manifest)
        workbench_path = Path(session.workbench_path)
        manifest = workbench.load(manifest_path)
        if manifest.get("context", {}).get("fingerprint", "") != session.context_fingerprint:
            raise model.WorkbenchError("WORKBENCH CONTEXT MISMATCH")
        self._assert_workbench_usable(manifest, workbench_path)
        actual_sha = model.file_sha256(workbench_path)
        if actual_sha != session.expected_workbench_sha256:
            raise model.WorkbenchError("WORKBENCH CHANGED OUTSIDE ART AGENT SESSION")
        return session, manifest, session_path.parent

    @staticmethod
    def _assert_workbench_usable(manifest: dict[str, Any], workbench_path: Path) -> None:
        if manifest.get("pending_migration"):
            raise model.WorkbenchError(
                "ART AGENT V1 DOES NOT SUPPORT PENDING FRAME MIGRATIONS"
            )
        if "STALE" in workbench.state(manifest, workbench_path):
            raise model.WorkbenchError("ART AGENT REFUSES STALE WORKBENCH")

    def _execute_read_request(
        self,
        session: ArtSession,
        root: Path,
        operation: dict[str, Any],
    ) -> dict[str, Any]:
        request_id = f"read_{uuid.uuid4().hex[:12]}"
        request_path = root / "requests" / f"{request_id}.json"
        response_path = root / "responses" / f"{request_id}.json"
        write_json(
            request_path,
            self._build_request(session, request_id, operation),
        )
        return self.bridge_factory(aseprite=self.aseprite).execute(
            request_path=request_path,
            response_path=response_path,
        )

    @staticmethod
    def _build_request(
        session: ArtSession,
        request_id: str,
        operation: dict[str, Any],
    ) -> dict[str, Any]:
        return {
            "schema": REQUEST_SCHEMA,
            "request_id": request_id,
            "manifest": session.workbench_manifest,
            "workbench": session.workbench_path,
            "operation": operation,
        }

    @staticmethod
    def _last_active_mutation(path: Path) -> dict[str, Any] | None:
        if not path.exists():
            return None
        records = [json.loads(line) for line in path.read_text().splitlines() if line]
        undone = {
            int(record["target_operation_id"])
            for record in records
            if record.get("type") == "undo"
        }
        for record in reversed(records):
            operation_id = record.get("operation_id")
            if (
                operation_id is not None
                and record.get("status") == "APPLIED"
                and int(operation_id) not in undone
            ):
                return record
        return None
