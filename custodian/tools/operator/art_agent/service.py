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
from .models import ArtIdentity, ArtSession, CAPABILITY_SCHEMA, REQUEST_SCHEMA
from .render import extract_note_components, make_animation_gif, make_before_after, make_contact_sheet, make_diff, make_mask_overlay, make_onion_skin, make_silhouette_sheet, split_strip
from .security import require_under
from . import landmarks as landmark_store
from . import masks as mask_store
from .metrics import animation_metrics
from .planner import build as build_animation_plan
from .qa import run_qa as evaluate_qa
from .references import assemble as assemble_references
from .review import append_critique, critiques, packet as review_packet
from .semantic_ops import draft_operation

ART_ROOT = model.REPO_ROOT / ".ai/operator_art_agent"
MUTATION_TYPES = {
    "paint_pixels",
    "erase_pixels",
    "stroke",
    "copy_region",
    "move_region",
    "draft_shift_part",
    "draft_copy_part",
    "draft_replace_part",
    "draft_mirror_part",
    "discard_draft",
    "bake_draft",
    "clear_masked_region",
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
            capability_path=str((root / "capability.json").resolve()),
        )
        session_path = root / "session.json"
        write_json(session_path, session.to_json())
        write_json(
            root / "capability.json",
            {
                "schema": CAPABILITY_SCHEMA,
                "session_id": session_id,
                "nonce": uuid.uuid4().hex,
                "context_fingerprint": session.context_fingerprint,
                "workbench_manifest": session.workbench_manifest,
                "workbench": session.workbench_path,
                "preview_root": str((root / "previews").resolve()),
            },
        )
        shutil.copy2(workbench_path, root / "backups/000000_baseline.aseprite")
        return session_path

    def load_session(self, session_path: Path) -> ArtSession:
        path = self._authorized_session_path(session_path)
        session = ArtSession.from_json(json.loads(path.read_text()))
        self._authorized_workbench_paths(session)
        require_under(self.art_root, Path(session.capability_path), label="Art Agent capability")
        return session

    def save_session(self, session_path: Path, session: ArtSession) -> None:
        write_json(self._authorized_session_path(session_path), session.to_json())

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

    def render(self, session_path: Path, *, mode: str = "clean", layer: str = "", include_drafts: bool = True) -> dict[str, Any]:
        session, manifest, root = self._checked_session(session_path)
        previews = root / "previews"
        current = previews / "current.png"
        self._execute_read_request(
            session,
            root,
            {"type": f"render_{mode}", "output": str(current.resolve()), "layer": layer, "include_drafts": include_drafts},
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
        silhouette = previews / "silhouette_contact_sheet.png"
        onion = previews / "onion_skin.png"
        animation = previews / "animation.gif"
        make_silhouette_sheet(frames, silhouette)
        make_onion_skin(frames, onion)
        fps=float(manifest.get("timeline",{}).get("preview_fps",12.0))
        make_animation_gif(frames,animation,fps=fps)
        return {
            "strip": str(current.resolve()),
            "baseline": str(baseline.resolve()),
            "contact_sheet": str(contact_sheet.resolve()),
            "diff": str(diff.resolve()),
            "before_after": str(before_after.resolve()),
            "silhouette": str(silhouette.resolve()),
            "onion_skin": str(onion.resolve()),
            "animation": str(animation.resolve()),
            "frames": [str(path.resolve()) for path in frames],
        }

    def get_landmarks(self, session_path: Path) -> list[dict[str, Any]]:
        _session, _manifest, root = self._checked_session(session_path)
        return [landmark_store.asdict(item) for item in landmark_store.load(root / "landmarks.json")]

    def infer_frame_anchors(self, session_path: Path, frame: int) -> list[dict[str, Any]]:
        session,manifest,_root=self._checked_session(session_path); artifacts=self.render(session_path); metric=animation_metrics([Path(artifacts["frames"][frame-1])])["frames"][0]; bbox=metric["alpha_bbox"]
        if not bbox: return []
        x0,y0,x1,y1=bbox; values=[{"frame":frame,"name":"head_center","x":round((x0+x1-1)/2),"y":y0+max(0,(y1-y0)//5),"semantic_side":"center","confidence":0.25,"provenance":"heuristic"},{"frame":frame,"name":"hip_center","x":round((x0+x1-1)/2),"y":y0+round((y1-y0)*0.58),"semantic_side":"center","confidence":0.2,"provenance":"heuristic"}]
        return self.set_landmarks(session_path,values)

    def validate_landmarks(self, session_path: Path) -> list[dict[str, Any]]:
        session,_manifest,root=self._checked_session(session_path); items=landmark_store.reconcile_hashes(landmark_store.load(root/"landmarks.json"),{frame:session.expected_workbench_sha256 for frame in range(1,1000)}); landmark_store.save(root/"landmarks.json",items); return [landmark_store.asdict(x) for x in items]

    def set_landmarks(self, session_path: Path, values: list[dict[str, Any]]) -> list[dict[str, Any]]:
        session, manifest, root = self._checked_session(session_path)
        canvas=manifest["canvas"]; current=landmark_store.load(root / "landmarks.json"); indexed={(x.frame,x.name):x for x in current}
        for value in values:
            value=dict(value); value.setdefault("source_hash",session.expected_workbench_sha256); value.setdefault("approved",False); value.setdefault("status","CURRENT")
            item=landmark_store.Landmark(**value); landmark_store.validate(item,frame_count=int(manifest["timeline"]["document_frames"]),width=int(canvas["width"]),height=int(canvas["height"])); indexed[(item.frame,item.name)]=item
        result=sorted(indexed.values(),key=lambda x:(x.frame,x.name)); landmark_store.save(root / "landmarks.json",result)
        return [landmark_store.asdict(x) for x in result]

    def remove_landmark(self, session_path: Path, *, frame: int, name: str) -> list[dict[str, Any]]:
        _session,_manifest,root=self._checked_session(session_path); result=[x for x in landmark_store.load(root/"landmarks.json") if (x.frame,x.name)!=(frame,name)]; landmark_store.save(root/"landmarks.json",result); return [landmark_store.asdict(x) for x in result]

    def define_mask(self, session_path: Path, *, frame: int, layer: str, part: str, polygon: list[list[int]] | None = None, rect: list[int] | None = None, provenance: str = "agent", confidence: float = 1.0) -> dict[str, Any]:
        session,manifest,root=self._checked_session(session_path); canvas=manifest["canvas"]
        if (polygon is None)==(rect is None): raise model.WorkbenchError("mask requires exactly one polygon or rectangle")
        if not 1<=frame<=int(manifest["timeline"]["document_frames"]): raise model.WorkbenchError("mask frame outside animation contract")
        editable={item["aseprite_layer_name"] for item in manifest.get("layers",[]) if item.get("editable") is True}
        if layer not in editable: raise model.WorkbenchError("mask layer is not an editable Workbench binding")
        if not 0.0<=confidence<=1.0: raise model.WorkbenchError("mask confidence must be in 0..1")
        size=(int(canvas["width"]),int(canvas["height"])); spans=mask_store.polygon(size,polygon) if polygon is not None else mask_store.rectangle(size,rect or [])
        cel_fingerprint=self._layer_frame_hash(session_path,layer,frame)
        mask_id=f"{part}_f{frame}_{mask_store.fingerprint(spans)[:10]}"; item=mask_store.PartMask(mask_id,frame,layer,part,spans,mask_store.bounds(spans),session.expected_workbench_sha256,cel_fingerprint,provenance,confidence)
        path=root/"masks.json"; payload=json.loads(path.read_text()) if path.exists() else {"schema":"custodian.operator_part_masks.v1","masks":[]}; payload["masks"]=[x for x in payload["masks"] if x["mask_id"]!=mask_id]+[item.to_json()]; write_json(path,payload); return item.to_json()

    def get_masks(self, session_path: Path) -> list[dict[str, Any]]:
        _session,_manifest,root=self._checked_session(session_path); path=root/"masks.json"; return json.loads(path.read_text()).get("masks",[]) if path.exists() else []

    def _mask(self, session_path: Path, mask_id: str) -> mask_store.PartMask:
        for value in self.get_masks(session_path):
            if value["mask_id"]==mask_id:
                item=mask_store.PartMask.from_json(value)
                if self._layer_frame_hash(session_path,item.layer,item.frame)!=item.source_cel_fingerprint: raise model.WorkbenchError(f"stale semantic mask: {mask_id}")
                return item
        raise model.WorkbenchError(f"unknown semantic mask: {mask_id}")

    def _layer_frame_hash(self, session_path: Path, layer: str, frame: int) -> str:
        artifacts=self.render(session_path,mode="layer",layer=layer)
        return animation_metrics([Path(artifacts["frames"][frame-1])])["frames"][0]["pixel_sha"]

    def preview_mask(self, session_path: Path, mask_id: str) -> dict[str, Any]:
        _session,_manifest,root=self._checked_session(session_path); mask=self._mask(session_path,mask_id); artifacts=self.render(session_path); output=root/"previews/masks"/f"frame_{mask.frame:03d}_{mask.part}.png"; output.parent.mkdir(parents=True,exist_ok=True); make_mask_overlay(Path(artifacts["frames"][mask.frame-1]),mask.to_json()["spans"],output); return {"mask_id":mask_id,"preview":str(output.resolve())}

    def create_draft(self, session_path: Path, *, kind: str, mask_id: str, destination_frame: int | None = None, dx: int = 0, dy: int = 0, axis_x: int | None = None, operation_key: str | None = None) -> dict[str, Any]:
        mask=self._mask(session_path,mask_id); operation=draft_operation(kind,mask,destination_frame=destination_frame,dx=dx,dy=dy,axis_x=axis_x); return self.apply_operation(session_path,operation,operation_key=operation_key)

    def discard_draft(self, session_path: Path, draft_id: str, *, operation_key: str | None = None) -> dict[str, Any]:
        return self.apply_operation(session_path,{"type":"discard_draft","draft_id":draft_id},operation_key=operation_key)

    def bake_draft(self, session_path: Path, *, draft_id: str, mask_id: str, target_frame: int, target_layer: str, clear_source_mask: bool = True, operation_key: str | None = None) -> dict[str, Any]:
        mask=self._mask(session_path,mask_id); return self.apply_operation(session_path,{"type":"bake_draft","draft_id":draft_id,"frame":target_frame,"layer":target_layer,"clear_source_mask":clear_source_mask,"spans":[{"y":x.y,"x0":x.x0,"x1":x.x1} for x in mask.spans]},operation_key=operation_key)

    def get_metrics(self, session_path: Path) -> dict[str, Any]:
        _session,_manifest,root=self._checked_session(session_path); artifacts=self.render(session_path); values=animation_metrics([Path(x) for x in artifacts["frames"]],self.get_landmarks(session_path)); write_json(root/"metrics.json",values); return values

    def plan(self, session_path: Path, recipe: str) -> dict[str, Any]:
        session,manifest,root=self._checked_session(session_path); recipes=model.CUSTODIAN_ROOT/"tools/operator/art_recipes"; projection=json.loads((model.CUSTODIAN_ROOT/"content/data/operator/authoring/operator_direction_projection.json").read_text()); refs=assemble_references(manifest,source_root=model.SOURCE_ROOT); value=build_animation_plan(session.identity,manifest,recipes/f"{recipe}.json",projection,refs).to_json(); write_json(root/"plan.json",value); return value

    def run_qa(self, session_path: Path, *, required_landmarks: list[str] | None = None) -> dict[str, Any]:
        _session,_manifest,root=self._checked_session(session_path); metrics=self.get_metrics(session_path); value=evaluate_qa(metrics,required_landmarks=required_landmarks,landmarks=self.get_landmarks(session_path),critiques=critiques(root/"critiques.jsonl")); write_json(root/"qa.json",value); return value

    def record_critique(self, session_path: Path, critique: dict[str, Any]) -> dict[str, Any]:
        _session,_manifest,root=self._checked_session(session_path); return append_critique(root/"critiques.jsonl",critique)

    def build_review_packet(self, session_path: Path, *, task: str = "") -> dict[str, Any]:
        session,manifest,root=self._checked_session(session_path); artifacts=self.render(session_path); metrics=self.get_metrics(session_path); qa=self.run_qa(session_path); refs=assemble_references(manifest,source_root=model.SOURCE_ROOT); plan_path=root/"plan.json"; constraints=json.loads(plan_path.read_text()).get("constraints",[]) if plan_path.exists() else []
        return review_packet(root/"review_packet.json",task=task or f"Review {session.identity.action} {session.identity.direction}",constraints=constraints,artifacts=artifacts,metrics=str((root/"metrics.json").resolve()),qa=str((root/"qa.json").resolve()),references=refs,findings=qa["findings"])

    def ingest_notes(self, session_path: Path) -> list[dict[str, Any]]:
        _session,manifest,root=self._checked_session(session_path); artifacts=self.render(session_path,mode="layer",layer="__REVIEW_NOTES"); observations=[]
        for index,path in enumerate(artifacts["frames"],1): observations.extend(extract_note_components(Path(path),index))
        for item in observations: append_jsonl(root/"observations.jsonl",item)
        return observations

    def apply_operation(
        self,
        session_path: Path,
        operation: dict[str, Any],
        *,
        operation_key: str | None = None,
    ) -> dict[str, Any]:
        if operation.get("type") not in MUTATION_TYPES:
            raise model.WorkbenchError(f"unsupported Art Agent V1 mutation: {operation.get('type')}")
        operation_key = operation_key or uuid.uuid4().hex
        session_path = self._authorized_session_path(session_path)
        session, manifest, root = self._checked_session(session_path)
        prior = self._journal_by_operation_key(root / "operations.jsonl", operation_key)
        if prior:
            if prior.get("status") in {"APPLIED", "NOOP"}:
                return prior
            raise model.WorkbenchError("operation_key previously failed")
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
            request = self._build_request(session, request_id, operation, operation_key)
            write_json(request_path, request)
            try:
                response = self.bridge_factory(aseprite=self.aseprite).execute(
                    request_path=request_path,
                    response_path=response_path,
                    expected_request_id=request_id,
                    expected_operation_key=operation_key,
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
                        "operation_key": operation_key,
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
            changed = bool(response.get("changed", response.get("changed_pixels", 0) > 0))
            if not changed and after_sha != actual_sha:
                shutil.copy2(backup, workbench_path)
                after_sha = actual_sha
                raise model.WorkbenchError("NOOP operation unexpectedly changed workbench")
            record = {
                "operation_id": operation_id,
                "timestamp_utc": utc_now(),
                "type": operation["type"],
                "operation_key": operation_key,
                "arguments": operation,
                "status": "APPLIED" if changed else "NOOP",
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
        session_path = self._authorized_session_path(session_path)
        session = self.load_session(session_path)
        if session.state != "ACTIVE":
            raise model.WorkbenchError("Art Agent session is not active")
        manifest_path, workbench_path = self._authorized_workbench_paths(session)
        manifest = workbench.load(manifest_path)
        if manifest.get("context", {}).get("fingerprint", "") != session.context_fingerprint:
            raise model.WorkbenchError("WORKBENCH CONTEXT MISMATCH")
        self._assert_workbench_usable(manifest, workbench_path)
        actual_sha = model.file_sha256(workbench_path)
        if actual_sha != session.expected_workbench_sha256:
            raise model.WorkbenchError("WORKBENCH CHANGED OUTSIDE ART AGENT SESSION")
        return session, manifest, session_path.parent

    def _authorized_session_path(self, session_path: Path) -> Path:
        path = require_under(self.art_root, Path(session_path), label="Art Agent session")
        if path.name != "session.json":
            raise model.WorkbenchError("Art Agent session must be session.json")
        return path

    def _authorized_workbench_paths(self, session: ArtSession) -> tuple[Path, Path]:
        manifest = require_under(self.workspace_root, Path(session.workbench_manifest), label="Workbench manifest")
        document = require_under(self.workspace_root, Path(session.workbench_path), label="Workbench document")
        if manifest.name != "workbench.json" or document.name != "workbench.aseprite":
            raise model.WorkbenchError("Art Agent requires workbench.json and workbench.aseprite")
        if manifest.parent != document.parent:
            raise model.WorkbenchError("Workbench manifest and document must share a directory")
        return manifest, document

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
        operation_key = uuid.uuid4().hex
        request_path = root / "requests" / f"{request_id}.json"
        response_path = root / "responses" / f"{request_id}.json"
        write_json(
            request_path,
            self._build_request(session, request_id, operation, operation_key),
        )
        return self.bridge_factory(aseprite=self.aseprite).execute(
            request_path=request_path,
            response_path=response_path,
            expected_request_id=request_id,
            expected_operation_key=operation_key,
        )

    def _build_request(
        self,
        session: ArtSession,
        request_id: str,
        operation: dict[str, Any],
        operation_key: str,
    ) -> dict[str, Any]:
        return {
            "schema": REQUEST_SCHEMA,
            "request_id": request_id,
            "operation_key": operation_key,
            "session_id": session.session_id,
            "capability": session.capability_path,
            "nonce": json.loads(Path(session.capability_path).read_text())["nonce"],
            "manifest": session.workbench_manifest,
            "workbench": session.workbench_path,
            "operation": operation,
        }

    @staticmethod
    def _journal_by_operation_key(path: Path, operation_key: str) -> dict[str, Any] | None:
        if not path.exists():
            return None
        for line in path.read_text().splitlines():
            if line:
                record = json.loads(line)
                if record.get("operation_key") == operation_key:
                    return record
        return None

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
