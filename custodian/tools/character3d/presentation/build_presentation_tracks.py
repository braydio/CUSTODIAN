"""Build verified per-direction presentation tracks from a raw attachment export.

Consumes the Blender raw export (export_attachment_tracks.py) and the existing staged frame metadata.
It refuses to write unless every track validates against character_presentation_track.v1 and
every source, frame, pivot and sample relationship matches the staged sprites.

  python3 custodian/tools/character3d/presentation/build_presentation_tracks.py \
    --raw <raw.json> --contract custodian/tools/character3d/contracts/operator.v1.json \
    --mapping custodian/tools/character3d/contracts/operator_attachment_map.v1.json \
    --effects custodian/tools/character3d/contracts/presentation_effect_registry.v1.json \
    --schema custodian/tools/character3d/contracts/character_presentation_track.v1.schema.json \
    --stage-root <stage> --probe-report <REVIEW_VIEWPORT_REPORT.json> --profile unarmed --group locomotion \
    --workbench-action walk_01 [--dry-run]

Track coordinates: canvas pixels (origin top-left, y down). staged = canvas + staging_offset, where
staging_offset = target_pivot - source_pivot, exactly the sprite stager's placement. root_relative =
staged - target_pivot. Contact cues come from foot world height (not from authored event names).
"""
import argparse
import hashlib
import importlib.util
import json
import math
import os
import sys
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
DIRECTIONS = ["S", "SE", "E", "NE", "N", "NW", "W", "SW"]
AZIMUTH = {"S": 0, "SE": 45, "E": 90, "NE": 135, "N": 180, "NW": 225, "W": 270, "SW": 315}
ROOT_TOLERANCE_PX = 0.01
CONTACT_THRESHOLD_M = 0.05
TRACK_SCHEMA = "custodian.character3d_presentation_track.v1"
RECEIPT_SCHEMA = "custodian.character3d_presentation_receipt.v1"


class TrackError(Exception):
    pass


def _load_validator():
    spec = importlib.util.spec_from_file_location("character3d_validate_contract", HERE.parent / "validate_contract.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_validator = _load_validator()


def sha_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _json(path: Path, label: str):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError) as error:
        raise TrackError(f"{label} unreadable: {path}: {error}") from error


def contact_spans(heights, threshold):
    """Circular spans where a foot is within threshold of its cycle minimum. Returns onset indices."""
    low = min(heights)
    inside = [h <= low + threshold for h in heights]
    if all(inside):
        raise TrackError("foot never leaves contact range; contact cannot be derived")
    onsets = []
    n = len(heights)
    for i in range(n):
        if inside[i] and not inside[i - 1]:
            onsets.append(i)
    return onsets


def build_tracks(raw, meta, contract, mapping, effects, *, action, pivot, meta_sha, manifest_sha, mapping_sha, glb_sha, frame_hashes, semantic):
    contract_action = contract["actions"][action]
    if raw.get("schema") != "custodian.character3d_attachment_raw.v1" or raw.get("action") != action:
        raise TrackError("raw export schema or action does not match")
    if raw["master"]["sha256"] != contract["source"]["master"]["sha256"]:
        raise TrackError("raw export was rendered on a different master than the contract")
    if raw["glb"]["sha256"] != glb_sha:
        raise TrackError("raw export was produced from a different GLB")
    motion_sha = contract["source"]["motions"][action]["sha256"]
    if glb_sha != motion_sha:
        raise TrackError(f"source GLB {glb_sha[:12]} does not match the contract motion {motion_sha[:12]}")
    if meta["source_sha256"] != motion_sha:
        raise TrackError("stage metadata source hash does not match the contract motion")
    count = int(contract_action["frame_count"])
    if raw["sample_count"] != count or int(meta["frame_count"]) != count:
        raise TrackError(f"sample count mismatch: raw {raw['sample_count']}, metadata {meta['frame_count']}, contract {count}")
    if raw["canvas"] != meta["source_canvas"] or raw["ppm"] != contract["render"]["px_per_m"]:
        raise TrackError("render canvas or density differs from the staged render")
    if [round(v, 6) for v in raw["root_pixel"]] != [round(v, 6) for v in pivot["source"]]:
        raise TrackError("raw root pixel differs from the source pivot")
    offset = (pivot["target"][0] - pivot["source"][0], pivot["target"][1] - pivot["source"][1])
    canvas_out = meta["frame_size"]
    tracks = {}
    # Registration proof: the root socket must land on the source pivot for every sample and direction.
    for direction in DIRECTIONS:
        block = raw["directions"][direction]
        root_error = 0.0
        for sample in block["samples"]:
            root = sample["points"]["root"]
            root_error = max(root_error, abs(root["x"] - pivot["source"][0]), abs(root["y"] - pivot["source"][1]))
        if root_error > ROOT_TOLERANCE_PX:
            raise TrackError(f"{direction}: root socket is {root_error:.4f}px from the source pivot")
    feet = {s: [w["world_m"][s][2] for w in raw["world"]] for s in ("foot_l", "foot_r")}
    cues_common = []
    for socket in ("foot_l", "foot_r"):
        for onset in contact_spans(feet[socket], CONTACT_THRESHOLD_M):
            cues_common.append({
                "id": f"{action}.footstep.{socket}.{onset:02d}",
                "class": "presentation",
                "trigger": {"type": "contact_onset", "sample": onset},
                "socket": socket,
                "effect_ref": "footstep_dust",
                "presentation_duration_samples": 0,
                "ordering": "by_depth",
                "interruption": "cancel_pending_on_interrupt",
                "repetition": "per_loop_cycle",
                "provenance": f"foot world height within {CONTACT_THRESHOLD_M} m of the cycle minimum; motion {motion_sha[:12]}",
            })
    for cue in cues_common:
        if cue["effect_ref"] not in effects["effects"]:
            raise TrackError(f"cue {cue['id']} references unregistered effect {cue['effect_ref']}")
    for direction in DIRECTIONS:
        block = raw["directions"][direction]
        root_depth = None
        sockets = {}
        for socket, spec in raw["sockets"].items():
            if spec["status"] != "resolved":
                sockets[socket] = {"status": "unavailable", "reason": spec.get("reason", "no resolved rig node")}
                continue
            if socket == "root":
                continue
            samples = []
            for index, sample in enumerate(block["samples"]):
                point = sample["points"][socket]
                depth = point["depth_m"]
                staged_x, staged_y = point["x"] + offset[0], point["y"] + offset[1]
                samples.append({
                    "index": index,
                    "canvas": {"x": point["x"], "y": point["y"]},
                    "staged": {"x": round(staged_x, 6), "y": round(staged_y, 6)},
                    "root_relative": {"x": round(staged_x - pivot["target"][0], 6), "y": round(staged_y - pivot["target"][1], 6)},
                    "valid": bool(point["in_canvas"]),
                    "depth_m": depth,
                    "relative_depth_m": None,
                    "order": None,
                })
            sockets[socket] = {"status": "resolved", "bone": spec["bone"], "samples": samples}
        root_depths = [s["points"]["root"]["depth_m"] for s in block["samples"]]
        for socket, body in sockets.items():
            if body["status"] != "resolved":
                continue
            for sample, depth_root in zip(body["samples"], root_depths):
                sample["relative_depth_m"] = round(sample["depth_m"] - depth_root, 6)
                sample["order"] = "front" if sample["relative_depth_m"] < 0 else "behind"
        track = {
            "schema": TRACK_SCHEMA,
            "character_id": contract["character_id"],
            "action": action,
            "direction": direction,
            "semantic": semantic,
            "render": {
                "generation": "operator_3d_80",
                "canvas": list(canvas_out),
                "px_per_m": contract["render"]["px_per_m"],
                "source_canvas": raw["canvas"],
                "source_pivot": list(pivot["source"]),
                "target_pivot": list(pivot["target"]),
                "staging_offset": [offset[0], offset[1]],
                "projection": "orthographic",
                "elevation_deg": contract["render"]["elevation_deg"],
                "azimuth_deg": AZIMUTH[direction],
                "registration_policy": "per_action_pivot",
            },
            "source": {"motion_sha256": motion_sha, "master_sha256": contract["source"]["master"]["sha256"],
                       "glb_sha256": glb_sha, "mapping_sha256": mapping_sha, "meta_sha256": meta_sha,
                       "stage_manifest_sha256": manifest_sha},
            "frames": {"count": count, "indices": list(range(count)),
                       "sample_times_s": [w["time_s"] for w in raw["world"]],
                       "sampling_fps": raw["sampling_fps"],
                       "frame_sha256": [frame_hashes[f"{direction}/{k:04d}"] for k in range(count)]},
            "sockets": sockets,
            "cues": [dict(cue) for cue in cues_common],
            "loop": bool(contract_action["loop"]),
            "approval_status": "candidate_unapproved",
            "gameplay_timing_approved": False,
        }
        tracks[direction] = track
    return tracks


def validate_track(track, schema):
    errors = _validator.validate(track, schema)
    for socket, body in track["sockets"].items():
        if body["status"] == "resolved":
            for sample in body["samples"]:
                for key in ("x", "y"):
                    for group in ("canvas", "staged", "root_relative"):
                        if not math.isfinite(sample[group][key]):
                            errors.append(f"{socket}: nonfinite {group}.{key}")
                for key in ("depth_m", "relative_depth_m"):
                    if not math.isfinite(sample[key]):
                        errors.append(f"{socket}: nonfinite {key}")
    indices = [s["index"] for body in track["sockets"].values() if body["status"] == "resolved" for s in body["samples"]]
    if indices and sorted(set(indices)) != list(range(track["frames"]["count"])):
        errors.append("socket sample indices do not cover the frame indices")
    return errors


def write_all(stage_root: Path, action: str, tracks: dict, receipt: dict):
    """Promote the complete track set for one action, or leave the previous set untouched."""
    target = stage_root / "presentation" / action
    work = stage_root / "presentation" / f".{action}.staging"
    import shutil
    shutil.rmtree(work, ignore_errors=True)
    work.mkdir(parents=True)
    try:
        for direction, track in tracks.items():
            (work / f"{direction}.json").write_text(json.dumps(track, indent=1, sort_keys=True) + "\n")
        (work / "receipt.json").write_text(json.dumps(receipt, indent=1, sort_keys=True) + "\n")
        previous = target.with_name(target.name + ".previous")
        shutil.rmtree(previous, ignore_errors=True)
        if target.exists():
            os.replace(target, previous)
        try:
            os.replace(work, target)
        except BaseException:
            if previous.exists():
                os.replace(previous, target)
            raise
        shutil.rmtree(previous, ignore_errors=True)
    finally:
        shutil.rmtree(work, ignore_errors=True)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--raw", required=True, type=Path)
    ap.add_argument("--contract", required=True, type=Path)
    ap.add_argument("--mapping", required=True, type=Path)
    ap.add_argument("--effects", required=True, type=Path)
    ap.add_argument("--schema", required=True, type=Path)
    ap.add_argument("--stage-root", required=True, type=Path)
    ap.add_argument("--probe-report", required=True, type=Path)
    ap.add_argument("--profile", required=True)
    ap.add_argument("--group", required=True)
    ap.add_argument("--workbench-action", required=True)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args(argv)
    try:
        raw = _json(args.raw, "raw export")
        action = raw["action"]
        contract = _json(args.contract, "contract")
        mapping = _json(args.mapping, "attachment map")
        effects = _json(args.effects, "effect registry")
        schema = _json(args.schema, "track schema")
        meta = _json(args.stage_root / "meta" / f"{action}.json", "stage metadata")
        frame_hashes = meta["cell_sha256"]
        report = _json(args.probe_report, "viewport report")["actions"][action]
        pivot = {"source": report["source_pivot"], "target": report["target_pivot"]}
        if list(pivot["target"]) != list(meta["pivot"]):
            raise TrackError("stage metadata pivot differs from the viewport report target pivot")
        semantic = f"{args.profile}/{args.group}/{args.workbench_action}"
        tracks = build_tracks(
            raw, meta, contract, mapping, effects, action=action, pivot=pivot, meta_sha=sha_file(args.stage_root / "meta" / f"{action}.json"),
            manifest_sha=sha_file(args.stage_root / "MANIFEST.json"), mapping_sha=sha_file(args.mapping),
            glb_sha=raw["glb"]["sha256"], frame_hashes=frame_hashes, semantic=semantic,
        )
        for direction, track in tracks.items():
            errors = validate_track(track, schema)
            if errors:
                raise TrackError(f"{direction} invalid:\n  " + "\n  ".join(errors[:10]))
        receipt = {
            "schema": RECEIPT_SCHEMA, "action": action, "semantic": semantic, "directions": DIRECTIONS,
            "samples_per_direction": contract["actions"][action]["frame_count"],
            "track_sha256": {d: hashlib.sha256((json.dumps(tracks[d], indent=1, sort_keys=True) + "\n").encode()).hexdigest() for d in DIRECTIONS},
            "cue_count": len(tracks["S"]["cues"]), "raw_sha256": sha_file(args.raw),
            "unavailable_sockets": sorted(s for s, b in tracks["S"]["sockets"].items() if b["status"] != "resolved"),
        }
    except (TrackError, KeyError) as error:
        print(f"REFUSED: {error}", file=sys.stderr)
        return 1
    if args.dry_run:
        print(json.dumps({"dry_run": True, "action": action, "cue_count": receipt["cue_count"],
                          "unavailable_sockets": receipt["unavailable_sockets"]}, indent=1))
        return 0
    write_all(args.stage_root, action, tracks, receipt)
    print(f"WROTE {action}: {len(DIRECTIONS)} directions, {receipt['samples_per_direction']} samples each, {receipt['cue_count']} cues")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
