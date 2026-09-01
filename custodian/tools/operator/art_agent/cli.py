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
from .source_service import SourceArtService
from .pilot import print_result as print_pilot_result, run_v2_pilot


def _session_command(subparsers: argparse._SubParsersAction, name: str) -> argparse.ArgumentParser:
    parser = subparsers.add_parser(name)
    parser.add_argument("session", type=Path)
    parser.add_argument("--aseprite", type=Path)
    parser.add_argument("--json", action="store_true")
    return parser


def configure_art_parser(parser: argparse.ArgumentParser) -> None:
    commands = parser.add_subparsers(dest="art_cmd", required=True)
    pilot = commands.add_parser("pilot", help="run the real V2 semantic-art acceptance pilot")
    pilot.add_argument("--json", action="store_true")
    pilot.add_argument("--keep-artifacts", action="store_true")
    pilot.add_argument("--allow-skip-aseprite", action="store_true")
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
    _session_command(commands, "validate-landmarks")
    mask = _session_command(commands, "mask")
    mask.add_argument("--frame", type=int, required=True); mask.add_argument("--layer", required=True); mask.add_argument("--part", required=True)
    mask.add_argument("--polygon"); mask.add_argument("--rect")
    _session_command(commands, "validate-masks")
    plan = _session_command(commands, "plan"); plan.add_argument("--recipe", required=True, choices=("walk","run","idle","fast_attack","heavy_attack"))
    _session_command(commands, "metrics"); _session_command(commands, "qa")
    draft = _session_command(commands, "draft")
    draft.add_argument("--kind", choices=("shift","copy","replace","mirror"), required=True); draft.add_argument("--mask", required=True); draft.add_argument("--destination-mask"); draft.add_argument("--destination-frame", type=int); draft.add_argument("--dx", type=int, default=0); draft.add_argument("--dy", type=int, default=0); draft.add_argument("--axis-x", type=int)
    _session_command(commands, "drafts")
    _session_command(commands, "validate-drafts")
    discard = _session_command(commands, "discard-draft"); discard.add_argument("--draft", required=True)
    bake = _session_command(commands, "bake-draft"); bake.add_argument("--draft", required=True)
    gap_repair = _session_command(commands, "resolve-gap-repair"); gap_repair.add_argument("--draft", required=True); gap_repair.add_argument("--note", default="")
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

    source_start = commands.add_parser("source-start")
    source_start.add_argument("source", type=Path)
    source_start.add_argument("--frames", type=int, required=True)
    source_start.add_argument("--columns", type=int)
    source_start.add_argument("--rows", type=int, default=1)
    source_start.add_argument("--target-size", type=int, default=96)
    source_start.add_argument("--json", action="store_true")
    for name in ("source-status", "source-analyze", "source-convert", "source-review"):
        command = commands.add_parser(name)
        command.add_argument("session", type=Path)
        command.add_argument("--json", action="store_true")
    source_plan = commands.add_parser("source-plan")
    source_plan.add_argument("session", type=Path)
    source_plan.add_argument("--anchor", choices=("feet", "center", "top-center", "bottom-center"), default="feet")
    source_plan.add_argument("--method", choices=("crisp", "balanced", "clustered"), default="balanced")
    source_plan.add_argument("--json", action="store_true")
    source_register = commands.add_parser("source-register")
    source_register.add_argument("session", type=Path)
    source_register.add_argument("--frame", type=int, required=True)
    source_register.add_argument("--dx", type=int, required=True)
    source_register.add_argument("--dy", type=int, required=True)
    source_register.add_argument("--json", action="store_true")
    source_select = commands.add_parser("source-select")
    source_select.add_argument("session", type=Path)
    source_select.add_argument("method", choices=("crisp", "balanced", "clustered"))
    source_select.add_argument("--json", action="store_true")
    source_handoff = commands.add_parser("source-handoff")
    source_handoff.add_argument("session", type=Path)
    source_handoff.add_argument("destination_name")
    source_handoff.add_argument("--json", action="store_true")


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
        command = args.art_cmd
        if command == "pilot":
            result = run_v2_pilot(
                keep_artifacts=args.keep_artifacts,
                allow_skip_aseprite=args.allow_skip_aseprite,
            )
            print_pilot_result(result, json_output=args.json)
            return 0 if result.get("engineering") in {"PASS", "SKIP"} else 1
        if command.startswith("source-"):
            source = SourceArtService()
            if command == "source-start":
                result = {"session": str(source.start(source_path=args.source, frames=args.frames, columns=args.columns, rows=args.rows, target_size=args.target_size))}
            elif command == "source-status": result = source.status(args.session)
            elif command == "source-analyze": result = source.analyze(args.session)
            elif command == "source-plan": result = source.plan_normalization(args.session, anchor=args.anchor, method=args.method)
            elif command == "source-register": result = source.set_frame_registration(args.session, frame=args.frame, dx=args.dx, dy=args.dy)
            elif command == "source-convert": result = source.convert(args.session)
            elif command == "source-review": result = source.review(args.session)
            elif command == "source-select": result = source.select_candidate(args.session, args.method)
            else: result = source.handoff(args.session, destination_name=args.destination_name)
            print(json.dumps(result, indent=2))
            return 0
        service = _service(args)
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
        elif command == "validate-landmarks": result = service.validate_landmarks(args.session)
        elif command == "mask":
            polygon = [_integer_list(point,2,"polygon point") for point in args.polygon.split(";")] if args.polygon else None
            result = service.define_mask(args.session,frame=args.frame,layer=args.layer,part=args.part,polygon=polygon,rect=_integer_list(args.rect,4,"rect") if args.rect else None)
        elif command == "validate-masks": result = service.validate_masks(args.session)
        elif command == "plan": result = service.plan(args.session,args.recipe)
        elif command == "metrics": result = service.get_metrics(args.session)
        elif command == "qa": result = service.run_qa(args.session)
        elif command == "draft": result = service.create_draft(args.session,kind=args.kind,mask_id=args.mask,destination_mask_id=args.destination_mask,destination_frame=args.destination_frame,dx=args.dx,dy=args.dy,axis_x=args.axis_x)
        elif command == "drafts": result = service.get_drafts(args.session)
        elif command == "validate-drafts": result = service.validate_drafts(args.session)
        elif command == "discard-draft": result = service.discard_draft(args.session,args.draft)
        elif command == "bake-draft": result = service.bake_draft(args.session,draft_id=args.draft)
        elif command == "resolve-gap-repair": result = service.resolve_gap_repair(args.session,args.draft,args.note)
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
