from __future__ import annotations

import hashlib
import json
import shutil
import sys
import uuid
from dataclasses import asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from PIL import Image

import animation_workbench_model as model

from .render import make_animation_gif, make_contact_sheet, make_silhouette_sheet
from .security import require_under
from .source_analysis import analyze_frame, extract_frames, union_bbox
from .source_models import (
    NORMALIZATION_PLAN_SCHEMA,
    SOURCE_ANALYSIS_SCHEMA,
    NormalizationPlan,
    SourceGeometry,
    SourceSession,
)
from .source_normalization import build_plan, shared_transform_from_plan
from .source_review import review_normalization
from . import palette as palette_core
from . import recolor as recolor_store

ART_TOOLS = model.CUSTODIAN_ROOT / "tools/art"
if str(ART_TOOLS) not in sys.path:
    sys.path.insert(0, str(ART_TOOLS))

from custodian_pixelart_converter import SheetConversionRequest, convert_sheet_request  # noqa: E402

SOURCE_ROOT = model.REPO_ROOT / ".ai/operator_art_agent/source_sessions"
ALLOWED_SOURCE_ROOTS = (
    model.CUSTODIAN_ROOT / "asset_drop/inbox",
    model.CUSTODIAN_ROOT / "asset_drop/source_work",
)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


class SourceArtService:
    def __init__(
        self,
        *,
        root: Path = SOURCE_ROOT,
        allowed_source_roots: tuple[Path, ...] = ALLOWED_SOURCE_ROOTS,
        handoff_root: Path | None = None,
    ):
        self.root = Path(root)
        self.allowed_source_roots = tuple(Path(path) for path in allowed_source_roots)
        self.handoff_root = Path(handoff_root or (model.CUSTODIAN_ROOT / "asset_drop/inbox/operator"))

    def authorize_source_path(self, path: Path) -> Path:
        resolved = Path(path).resolve(strict=True)
        for root in self.allowed_source_roots:
            try:
                resolved.relative_to(root.resolve(strict=True))
                return resolved
            except (OSError, ValueError):
                continue
        raise model.WorkbenchError("source image is outside authorized source roots")

    def start(
        self,
        *,
        source_path: Path | str,
        frames: int,
        target_size: int = 96,
        columns: int | None = None,
        rows: int = 1,
    ) -> Path:
        source_path = self.authorize_source_path(Path(source_path))
        if source_path.suffix.lower() != ".png":
            raise model.WorkbenchError("source image must be a PNG")
        if not 1 <= frames <= 64 or not 16 <= target_size <= 256 or rows < 1:
            raise model.WorkbenchError("source session geometry is outside supported bounds")
        columns = columns or frames
        with Image.open(source_path) as source:
            width, height = source.size
        if columns < 1 or columns * rows < frames:
            raise model.WorkbenchError("grid cannot contain requested frame count")
        if width % columns:
            raise model.WorkbenchError("source width is not divisible by grid columns")
        if height % rows:
            raise model.WorkbenchError("source height is not divisible by grid rows")
        geometry = SourceGeometry(columns, rows, frames, width // columns, height // rows)
        session_id = uuid.uuid4().hex[:12]
        session_root = self.root / session_id
        for child in ("source", "candidates", "registered", "review/frames"):
            (session_root / child).mkdir(parents=True, exist_ok=False)
        staged = session_root / "source/original.png"
        shutil.copy2(source_path, staged)
        session = SourceSession.create(
            session_id=session_id,
            created_utc=utc_now(),
            source_original=str(staged.resolve()),
            source_sha256=sha256(staged),
            geometry=geometry,
            target_width=target_size,
            target_height=target_size,
        )
        session_path = session_root / "session.json"
        write_json(session_path, session.to_json())
        return session_path

    def load(self, session_path: Path | str) -> tuple[SourceSession, Path, Path]:
        path = require_under(self.root, Path(session_path), label="Operator source session").resolve(strict=True)
        if path.name != "session.json":
            raise model.WorkbenchError("source session path must name session.json")
        session = SourceSession.from_json(json.loads(path.read_text(encoding="utf-8")))
        session_root = path.parent
        staged = require_under(session_root, Path(session.source_original), label="staged source").resolve(strict=True)
        if sha256(staged) != session.source_sha256:
            raise model.WorkbenchError("staged source changed after session creation")
        return session, session_root, path

    def save(self, path: Path, session: SourceSession) -> None:
        write_json(path, session.to_json())

    def status(self, session_path: Path | str) -> dict[str, Any]:
        session, root, path = self.load(session_path)
        return {**session.to_json(), "session": str(path), "root": str(root)}

    def analyze(self, session_path: Path | str) -> dict[str, Any]:
        session, root, path = self.load(session_path)
        with Image.open(session.source_original) as source:
            frames = extract_frames(
                source,
                columns=session.geometry.columns,
                rows=session.geometry.rows,
                frame_count=session.geometry.frame_count,
            )
        analyses = [analyze_frame(frame, frame_number=index + 1) for index, frame in enumerate(frames)]
        result = {
            "schema": SOURCE_ANALYSIS_SCHEMA,
            "source_sha256": session.source_sha256,
            "geometry": asdict(session.geometry),
            "frames": [asdict(item) for item in analyses],
            "shared_union_bbox": union_bbox(analyses),
            "clipping_risk_frames": [
                item.frame for item in analyses
                if item.touches_left or item.touches_right or item.touches_top or item.touches_bottom
            ],
        }
        write_json(root / "analysis.json", result)
        session.state = "ANALYZED"
        self.save(path, session)
        return result

    def plan_normalization(
        self, session_path: Path | str, *, anchor: str = "feet", method: str = "balanced"
    ) -> dict[str, Any]:
        session, root, path = self.load(session_path)
        analysis_path = root / "analysis.json"
        if not analysis_path.exists():
            raise model.WorkbenchError("source must be analyzed before normalization planning")
        analysis = json.loads(analysis_path.read_text(encoding="utf-8"))
        if analysis.get("source_sha256") != session.source_sha256:
            raise model.WorkbenchError("analysis belongs to a different source")
        plan = build_plan(session=session, analysis=analysis, method=method, anchor=anchor)
        write_json(root / "normalization_plan.json", plan.to_json())
        session.state = "PLANNED"
        self.save(path, session)
        return plan.to_json()

    def _load_plan(self, root: Path) -> NormalizationPlan:
        plan_path = root / "normalization_plan.json"
        if not plan_path.exists():
            raise model.WorkbenchError("normalization plan does not exist")
        value = json.loads(plan_path.read_text(encoding="utf-8"))
        if value.get("schema") != NORMALIZATION_PLAN_SCHEMA:
            raise model.WorkbenchError("normalization plan has unsupported schema")
        return NormalizationPlan.from_json(value)

    def set_frame_registration(
        self, session_path: Path | str, *, frame: int, dx: int, dy: int
    ) -> dict[str, Any]:
        session, root, path = self.load(session_path)
        plan = self._load_plan(root)
        if not 1 <= frame <= plan.frame_count:
            raise model.WorkbenchError("registration frame outside plan")
        if not isinstance(dx, int) or not isinstance(dy, int) or abs(dx) > 12 or abs(dy) > 12:
            raise model.WorkbenchError("registration offset exceeds safe integer normalization range")
        for registration in plan.registrations:
            if registration.frame == frame:
                registration.dx, registration.dy = dx, dy
                break
        write_json(root / "normalization_plan.json", plan.to_json())
        session.state = "PLANNED"
        self.save(path, session)
        return plan.to_json()

    def convert(self, session_path: Path | str) -> dict[str, Any]:
        session, root, path = self.load(session_path)
        plan = self._load_plan(root)
        if plan.source_sha256 != session.source_sha256:
            raise model.WorkbenchError("normalization plan belongs to a different source")
        transform = shared_transform_from_plan(plan)
        registrations = tuple((item.dx, item.dy) for item in plan.registrations)
        outputs: dict[str, str] = {}
        try:
            for method in ("crisp", "balanced", "clustered"):
                request = SheetConversionRequest(
                    source=Path(session.source_original),
                    columns=session.geometry.columns,
                    rows=session.geometry.rows,
                    frame_count=session.geometry.frame_count,
                    source_cell=(session.geometry.source_cell_width, session.geometry.source_cell_height),
                    target_size=(session.target_width, session.target_height),
                    method=method,
                    transform=transform,
                    registrations=registrations,
                )
                output = root / "candidates" / f"{method}.png"
                convert_sheet_request(request).save(output)
                outputs[method] = str(output.resolve())
        except ValueError as error:
            raise model.WorkbenchError(str(error)) from error
        registered = root / "registered/candidate.png"
        shutil.copy2(Path(outputs[plan.method]), registered)
        session.selected_candidate = str(registered.resolve())
        session.state = "REGISTERED"
        self.save(path, session)
        return {
            "candidates": outputs,
            "selected": plan.method,
            "registered": session.selected_candidate,
            "frame_count": plan.frame_count,
            "frame_size": [plan.target_width, plan.target_height],
            "global_scale": plan.global_scale,
            "registrations": [asdict(item) for item in plan.registrations],
        }

    def select_candidate(self, session_path: Path | str, method: str) -> dict[str, Any]:
        session, root, path = self.load(session_path)
        if method not in {"crisp", "balanced", "clustered"}:
            raise model.WorkbenchError("candidate must be crisp, balanced, or clustered")
        candidate = root / "candidates" / f"{method}.png"
        if not candidate.exists():
            raise model.WorkbenchError("candidate has not been generated")
        registered = root / "registered/candidate.png"
        shutil.copy2(candidate, registered)
        session.selected_candidate = str(registered.resolve())
        session.state = "REGISTERED"
        self.save(path, session)
        return {"selected": method, "candidate": session.selected_candidate}

    def review(self, session_path: Path | str) -> dict[str, Any]:
        session, root, path = self.load(session_path)
        if not session.selected_candidate:
            raise model.WorkbenchError("select or convert a candidate before review")
        candidate = require_under(root / "registered", Path(session.selected_candidate), label="source candidate").resolve(strict=True)
        with Image.open(candidate) as sheet:
            frames = extract_frames(
                sheet,
                columns=session.geometry.columns,
                rows=session.geometry.rows,
                frame_count=session.geometry.frame_count,
            )
        frame_paths: list[Path] = []
        for index, frame in enumerate(frames):
            frame_path = root / "review/frames" / f"frame_{index + 1:02d}.png"
            frame.save(frame_path)
            frame_paths.append(frame_path)
        contact_sheet = root / "review/contact_sheet.png"
        silhouette = root / "review/silhouette.png"
        animation = root / "review/animation.gif"
        make_contact_sheet(frame_paths, contact_sheet)
        make_silhouette_sheet(frame_paths, silhouette)
        make_animation_gif(frame_paths, animation, fps=12.0)
        result = review_normalization(frames=frames)
        result.update({
            "source_sha256": session.source_sha256,
            "candidate": str(candidate),
            "contact_sheet": str(contact_sheet.resolve()),
            "silhouette": str(silhouette.resolve()),
            "animation": str(animation.resolve()),
        })
        write_json(root / "review/frame_metrics.json", {"frames": result["metrics"]})
        write_json(root / "review/normalization_review.json", result)
        if result["status"] == "PASS":
            session.state = "REVIEWED"
            self.save(path, session)
        return result

    def handoff(self, session_path: Path | str, *, destination_name: str) -> dict[str, Any]:
        session, _root, path = self.load(session_path)
        if session.state != "REVIEWED":
            raise model.WorkbenchError("source must pass review before ingest handoff")
        if Path(destination_name).name != destination_name or not destination_name.lower().endswith(".png"):
            raise model.WorkbenchError("handoff destination must be a plain PNG filename")
        candidate = Path(session.selected_candidate).resolve(strict=True)
        destination = self.handoff_root / destination_name
        destination.parent.mkdir(parents=True, exist_ok=True)
        if destination.exists():
            raise model.WorkbenchError("handoff destination already exists")
        shutil.copy2(candidate, destination)
        session.state = "READY"
        self.save(path, session)
        return {
            "status": "READY_FOR_INGEST",
            "candidate": str(destination.resolve()),
            "frame_count": session.geometry.frame_count,
            "frame_size": [session.target_width, session.target_height],
            "source_session": str(path.resolve()),
        }

    def palette_inspect(self,session_path:Path|str)->dict[str,Any]:
        session,root,_path=self.load(session_path)
        if not session.selected_candidate: raise model.WorkbenchError("select a candidate before palette inspection")
        with Image.open(session.selected_candidate) as sheet: frames=extract_frames(sheet,columns=session.geometry.columns,rows=session.geometry.rows,frame_count=session.geometry.frame_count)
        return palette_core.inspect(frames,"candidate")

    def recolor_plan(self,session_path:Path|str,*,profile:str,group:str,action:str,direction:str,layer:str)->dict[str,Any]:
        session,root,_path=self.load(session_path)
        if not session.selected_candidate: raise model.WorkbenchError("select a candidate before recolor planning")
        index=model.source_index(model.SOURCE_ROOT,model.WEAPON_ROOT); hit=index.get(("operator",layer,profile,group,action,direction))
        if not hit: raise model.WorkbenchError("semantic canonical recolor reference did not resolve")
        reference_path=Path(hit[0]); key=hit[1]
        with Image.open(reference_path) as strip:
            strip=strip.convert("RGBA"); reference_frames=[strip.crop((i*key.frame_width,0,(i+1)*key.frame_width,key.frame_height)) for i in range(key.frames)]
        with Image.open(session.selected_candidate) as sheet: target_frames=extract_frames(sheet,columns=session.geometry.columns,rows=session.geometry.rows,frame_count=session.geometry.frame_count)
        reference={"reference_id":uuid.uuid4().hex[:12],"source_hashes":{"candidate":sha256(reference_path)}}
        plan=recolor_store.build(session_id=session.session_id,workbench_sha=sha256(Path(session.selected_candidate)),reference=reference,scopes=[{"target_layer":"candidate","reference_layer":layer}],frames=list(range(1,len(target_frames)+1)),target_reports={"candidate":palette_core.inspect(target_frames,"candidate")},reference_reports={"candidate":palette_core.inspect(reference_frames,layer)},regions=[],fingerprints={})
        payload=plan.to_json();payload["source_reference"]={"path":str(reference_path.resolve()),"layer":layer,"sha256":sha256(reference_path)};recolor_store.save(recolor_store.plan_id_path(root,plan.plan_id),plan);write_json(root/"recolor_plans"/f"{plan.plan_id}.reference.json",payload["source_reference"]);return payload

    def recolor_set_mapping(self,session_path:Path|str,*,plan_id:str,mapping_id:str,action:str,destination_rgb:list[int]|None=None)->dict:
        _session,root,_path=self.load(session_path);plan=recolor_store.load(recolor_store.plan_id_path(root,plan_id));mapping=next((x for x in plan.mappings if x.mapping_id==mapping_id),None)
        if not mapping:raise model.WorkbenchError("unknown recolor mapping")
        ref=json.loads((root/"recolor_plans"/f"{plan_id}.reference.json").read_text()); key=next(hit[1] for hit in model.source_index(model.SOURCE_ROOT,model.WEAPON_ROOT).values() if str(Path(hit[0]).resolve())==ref["path"])
        with Image.open(ref["path"]) as image: image=image.convert("RGBA"); frames=[image.crop((i*key.frame_width,0,(i+1)*key.frame_width,key.frame_height)) for i in range(key.frames)]
        allowed={tuple(x["rgb"]) for x in palette_core.inspect(frames,ref["layer"])["colors"]}
        if action=="map" and tuple(destination_rgb or []) not in allowed:raise model.WorkbenchError("destination RGB is not present in reference palette")
        mapping.action=action;mapping.destination_rgb=mapping.source_rgb if action=="preserve" else destination_rgb;mapping.locked=True;mapping.method="agent_selected";plan.status="READY" if not recolor_store.readiness_issues(plan) else "NEEDS_REVIEW";plan.preview_sha256=None;recolor_store.save(recolor_store.plan_id_path(root,plan_id),plan);return plan.to_json()

    def recolor_preview(self,session_path:Path|str,*,plan_id:str)->dict:
        session,root,_path=self.load(session_path);plan=recolor_store.load(recolor_store.plan_id_path(root,plan_id))
        if plan.status!="READY" or sha256(Path(session.selected_candidate))!=plan.target_workbench_sha256:raise model.WorkbenchError("source recolor plan is not READY or candidate is stale")
        with Image.open(session.selected_candidate) as sheet:frames=extract_frames(sheet,columns=session.geometry.columns,rows=session.geometry.rows,frame_count=session.geometry.frame_count)
        payload=recolor_store.preview(root,plan,{"candidate":frames});plan.status="PREVIEWED";plan.preview_sha256=payload["preview_sha256"];recolor_store.save(recolor_store.plan_id_path(root,plan_id),plan);return payload

    def recolor_apply(self,session_path:Path|str,*,plan_id:str)->dict:
        session,root,path=self.load(session_path);plan=recolor_store.load(recolor_store.plan_id_path(root,plan_id))
        if plan.status!="PREVIEWED" or sha256(Path(session.selected_candidate))!=plan.target_workbench_sha256:raise model.WorkbenchError("previewed source recolor plan is stale")
        preview=json.loads((root/"previews/recolor"/plan_id/"recolor_preview.json").read_text())
        if preview.get("plan_fingerprint")!=recolor_store.fingerprint(plan):raise model.WorkbenchError("source recolor mapping changed after preview")
        ref=json.loads((root/"recolor_plans"/f"{plan_id}.reference.json").read_text())
        if sha256(Path(ref["path"]))!=ref["sha256"]:raise model.WorkbenchError("reference authority changed")
        with Image.open(session.selected_candidate) as sheet:frames=extract_frames(sheet,columns=session.geometry.columns,rows=session.geometry.rows,frame_count=session.geometry.frame_count)
        after,_stats=recolor_store.apply_mapping({"candidate":frames},plan);out=Image.new("RGBA",(session.geometry.columns*session.target_width,session.geometry.rows*session.target_height))
        for i,frame in enumerate(after["candidate"]):out.alpha_composite(frame,((i%session.geometry.columns)*session.target_width,(i//session.geometry.columns)*session.target_height))
        destination=root/"registered/recolored_candidate.png";out.save(destination);plan.status="APPLIED";recolor_store.save(recolor_store.plan_id_path(root,plan_id),plan);return {"candidate":str(destination.resolve()),"plan_id":plan_id}

    def recolor_review(self,session_path:Path|str,*,plan_id:str)->dict:
        session,root,_path=self.load(session_path);plan=recolor_store.load(recolor_store.plan_id_path(root,plan_id));candidate=root/"registered/recolored_candidate.png"
        if plan.status!="APPLIED" or not candidate.exists():raise model.WorkbenchError("source recolor plan has not been applied")
        with Image.open(session.selected_candidate) as a,Image.open(candidate) as b:
            before=extract_frames(a,columns=session.geometry.columns,rows=session.geometry.rows,frame_count=session.geometry.frame_count);after=extract_frames(b,columns=session.geometry.columns,rows=session.geometry.rows,frame_count=session.geometry.frame_count)
        findings=[]
        if palette_core.alpha_sha(before)!=palette_core.alpha_sha(after):findings.append({"severity":"RED","issue":"alpha changed"})
        if palette_core.silhouette_sha(before)!=palette_core.silhouette_sha(after):findings.append({"severity":"RED","issue":"silhouette changed"})
        value={"status":"RED" if findings else "GREEN","findings":findings,"candidate":str(candidate.resolve())};write_json(root/"review/source_recolor_review.json",value);return value
