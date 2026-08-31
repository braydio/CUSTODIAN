from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

import animation_workbench as workbench
import animation_workbench_model as model

from .service import ART_ROOT, ArtAgentService


def _session_command(subparsers: argparse._SubParsersAction, name: str) -> argparse.ArgumentParser:
    parser = subparsers.add_parser(name)
    parser.add_argument("session", type=Path)
    parser.add_argument("--aseprite", type=Path)
    parser.add_argument("--json", action="store_true")
    return parser


def configure_art_parser(parser: argparse.ArgumentParser) -> None:
    commands = parser.add_subparsers(dest="art_cmd", required=True)
    start = commands.add_parser("start")
    start.add_argument("profile")
    start.add_argument("action")
    start.add_argument("direction")
    start.add_argument("--group", default="")
    start.add_argument("--weapon", default="")
    start.add_argument("--linked-profile", default="")
    start.add_argument("--aseprite", type=Path)
    start.add_argument("--json", action="store_true")

    for name in ("status", "inspect", "render", "undo", "close"):
        _session_command(commands, name)

    landmarks = _session_command(commands, "landmarks")
    landmarks.add_argument("--set", dest="landmark_file", type=Path)
    landmarks.add_argument("--remove")
    landmarks.add_argument("--frame", type=int)
    mask = _session_command(commands, "mask")
    mask.add_argument("--frame", type=int, required=True); mask.add_argument("--layer", required=True); mask.add_argument("--part", required=True)
    mask.add_argument("--polygon"); mask.add_argument("--rect")
    plan = _session_command(commands, "plan"); plan.add_argument("--recipe", required=True, choices=("walk","run","idle","fast_attack","heavy_attack"))
    _session_command(commands, "metrics"); _session_command(commands, "qa")
    draft = _session_command(commands, "draft")
    draft.add_argument("--kind", choices=("shift","copy","replace","mirror"), required=True); draft.add_argument("--mask", required=True); draft.add_argument("--destination-frame", type=int); draft.add_argument("--dx", type=int, default=0); draft.add_argument("--dy", type=int, default=0); draft.add_argument("--axis-x", type=int)
    discard = _session_command(commands, "discard-draft"); discard.add_argument("--draft", required=True)
    bake = _session_command(commands, "bake-draft"); bake.add_argument("--draft", required=True); bake.add_argument("--mask", required=True); bake.add_argument("--frame", type=int, required=True); bake.add_argument("--layer", required=True); bake.add_argument("--keep-source", action="store_true")
    critique = _session_command(commands, "critique"); critique.add_argument("--input", type=Path, required=True)
    review = _session_command(commands, "review"); review.add_argument("--task", default="")
    _session_command(commands, "ingest-notes")

    paint = _session_command(commands, "paint")
    paint.add_argument("--frame", type=int, required=True)
    paint.add_argument("--layer", required=True)
    paint.add_argument("--pixels", type=Path, required=True)

    erase = _session_command(commands, "erase")
    erase.add_argument("--frame", type=int, required=True)
    erase.add_argument("--layer", required=True)
    erase.add_argument("--pixels", type=Path, required=True)

    stroke = _session_command(commands, "stroke")
    stroke.add_argument("--frame", type=int, required=True)
    stroke.add_argument("--layer", required=True)
    stroke.add_argument("--color", required=True)
    stroke.add_argument("--points", required=True)
    stroke.add_argument("--brush-size", type=int, choices=(1, 2, 3), default=1)

    copy = _session_command(commands, "copy")
    copy.add_argument("--layer", required=True)
    copy.add_argument("--source-frame", type=int, required=True)
    copy.add_argument("--destination-frame", type=int, required=True)
    copy.add_argument("--rect", required=True)
    copy.add_argument("--to", required=True)

    move = _session_command(commands, "move")
    move.add_argument("--frame", type=int, required=True)
    move.add_argument("--layer", required=True)
    move.add_argument("--rect", required=True)
    move.add_argument("--dx", type=int, required=True)
    move.add_argument("--dy", type=int, required=True)


def _integer_list(value: str, count: int, label: str) -> list[int]:
    try:
        values = [int(part.strip()) for part in value.split(",")]
    except ValueError as error:
        raise model.WorkbenchError(f"{label} must contain integers") from error
    if len(values) != count:
        raise model.WorkbenchError(f"{label} requires {count} comma-separated integers")
    return values


def _color(value: str) -> list[int]:
    match = re.fullmatch(r"#?([0-9a-fA-F]{6}|[0-9a-fA-F]{8})", value)
    if not match:
        raise model.WorkbenchError("color must be #RRGGBB or #RRGGBBAA")
    digits = match.group(1)
    if len(digits) == 6:
        digits += "ff"
    return [int(digits[index:index + 2], 16) for index in range(0, 8, 2)]


def _points(value: str) -> list[list[int]]:
    points = [_integer_list(part, 2, "point") for part in value.split(";") if part.strip()]
    if not points:
        raise model.WorkbenchError("stroke requires at least one point")
    return points


def _load_pixels(path: Path, *, require_rgba: bool) -> list[dict[str, Any]]:
    payload = json.loads(path.read_text())
    if isinstance(payload, dict):
        payload = payload.get("pixels")
    if not isinstance(payload, list):
        raise model.WorkbenchError("pixel file must contain a JSON array or {\"pixels\": [...]} object")
    result = []
    for item in payload:
        if not isinstance(item, dict) or not isinstance(item.get("x"), int) or not isinstance(item.get("y"), int):
            raise model.WorkbenchError("every pixel requires integer x and y")
        pixel = {"x": item["x"], "y": item["y"]}
        if require_rgba:
            rgba = item.get("rgba")
            if not isinstance(rgba, list) or len(rgba) != 4 or any(not isinstance(channel, int) or not 0 <= channel <= 255 for channel in rgba):
                raise model.WorkbenchError("paint pixels require four RGBA channels in 0..255")
            pixel["rgba"] = rgba
        result.append(pixel)
    return result


def _service(args: argparse.Namespace) -> ArtAgentService:
    return ArtAgentService(aseprite=args.aseprite)


def dispatch_art_command(args: argparse.Namespace) -> int:
    try:
        service = _service(args)
        command = args.art_cmd
        if command == "start":
            session = service.start_session(
                profile=args.profile,
                action=args.action,
                direction=args.direction,
                group=args.group,
                weapon=args.weapon,
                linked_profile=args.linked_profile,
            )
            result: Any = {"session": str(session.resolve())}
        elif command == "status":
            result = service.status(args.session)
        elif command == "inspect":
            result = service.inspect(args.session)
        elif command == "render":
            result = service.render(args.session)
        elif command == "undo":
            result = service.undo_last(args.session)
        elif command == "close":
            result = service.close(args.session)
        elif command == "landmarks":
            if args.landmark_file: result = service.set_landmarks(args.session, json.loads(args.landmark_file.read_text()).get("landmarks", json.loads(args.landmark_file.read_text())))
            elif args.remove: result = service.remove_landmark(args.session, frame=args.frame, name=args.remove)
            else: result = service.get_landmarks(args.session)
        elif command == "mask":
            polygon = [_integer_list(point,2,"polygon point") for point in args.polygon.split(";")] if args.polygon else None
            result = service.define_mask(args.session,frame=args.frame,layer=args.layer,part=args.part,polygon=polygon,rect=_integer_list(args.rect,4,"rect") if args.rect else None)
        elif command == "plan": result = service.plan(args.session,args.recipe)
        elif command == "metrics": result = service.get_metrics(args.session)
        elif command == "qa": result = service.run_qa(args.session)
        elif command == "draft": result = service.create_draft(args.session,kind=args.kind,mask_id=args.mask,destination_frame=args.destination_frame,dx=args.dx,dy=args.dy,axis_x=args.axis_x)
        elif command == "discard-draft": result = service.discard_draft(args.session,args.draft)
        elif command == "bake-draft": result = service.bake_draft(args.session,draft_id=args.draft,mask_id=args.mask,target_frame=args.frame,target_layer=args.layer,clear_source_mask=not args.keep_source)
        elif command == "critique": result = service.record_critique(args.session,json.loads(args.input.read_text()))
        elif command == "review": result = service.build_review_packet(args.session,task=args.task)
        elif command == "ingest-notes": result = service.ingest_notes(args.session)
        else:
            operation: dict[str, Any]
            if command in ("paint", "erase"):
                operation = {
                    "type": f"{command}_pixels",
                    "frame": args.frame,
                    "layer": args.layer,
                    "pixels": _load_pixels(args.pixels, require_rgba=command == "paint"),
                }
            elif command == "stroke":
                operation = {
                    "type": "stroke",
                    "frame": args.frame,
                    "layer": args.layer,
                    "rgba": _color(args.color),
                    "brush": {"shape": "square", "size": args.brush_size},
                    "points": _points(args.points),
                }
            elif command == "copy":
                operation = {
                    "type": "copy_region",
                    "layer": args.layer,
                    "source_frame": args.source_frame,
                    "destination_frame": args.destination_frame,
                    "source_rect": _integer_list(args.rect, 4, "rect"),
                    "destination": _integer_list(args.to, 2, "destination"),
                }
            else:
                operation = {
                    "type": "move_region",
                    "frame": args.frame,
                    "layer": args.layer,
                    "rect": _integer_list(args.rect, 4, "rect"),
                    "dx": args.dx,
                    "dy": args.dy,
                }
            result = service.apply_operation(args.session, operation)
        print(json.dumps(result, indent=2))
        return 0
    except (model.WorkbenchError, ValueError, OSError, subprocess.CalledProcessError, json.JSONDecodeError) as error:
        print(f"operator: {error}", file=sys.stderr)
        return 2
