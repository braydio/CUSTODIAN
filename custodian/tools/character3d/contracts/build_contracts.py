"""Build the character contracts from the staging inputs they describe.

Each contract is derived from the same reports its stager reads, so the numbers cannot drift
from the frames that were actually produced:

  pursuit_frame: pursuit workspace reports/INPUT_MANIFEST.json + staged .ai manifest.json
  operator:      operator_running_scale_probe_v1 reports/REVIEW_VIEWPORT_REPORT.json +
                 reports/PREVIEW_FRAME_MANIFEST.json, and operator_sprite_batch_v1 INPUT_MANIFEST

Usage:
  python3 -I custodian/tools/character3d/contracts/build_contracts.py \
      --pursuit-workspace ~/Projects/.operator-3d-animation-proof/pursuit_frame_3d_v1 \
      --pursuit-staged custodian/.ai/pursuit_frame_3d_preview/manifest.json \
      --operator-probe ~/Projects/.operator-3d-animation-proof/operator_running_scale_probe_v1 \
      --operator-batch ~/Projects/.operator-3d-animation-proof/operator_sprite_batch_v1 \
      --out custodian/tools/character3d/contracts
Each generated contract is then checked with validate_contract.py.
"""
import argparse
import json
from pathlib import Path

PURSUIT_ORDER = ["S", "SE", "E", "NE", "N", "NW", "W", "SW"]
PURSUIT_ACTIONS = [
    "running", "walking", "alert", "agree_gesture", "casual_walk", "arise",
    "attack", "behit_flyup", "skill_01", "skill_03", "triple_combo_attack",
]
PURSUIT_MAPPED = {"running": "locomotion.run / locomotion.relaxed_run (chase)",
                  "walking": "locomotion.walk / locomotion.relaxed_walk (idle fallback: frame 0)",
                  "alert": "posture.alert (plays once)"}
OPERATOR_ACTIONS = ["running", "walking", "alert", "casual_walk", "dead", "run_03", "runfast",
                    "skill_01", "skill_03", "triple_combo_attack", "unsteady_walk"]
OPERATOR_MAPPED = {"running": "locomotion run (preview)", "walking": "locomotion walk (preview)"}


def build_pursuit(workspace: Path, staged_manifest: Path) -> dict:
    inputs = json.loads((workspace / "reports/INPUT_MANIFEST.json").read_text())["inputs"]
    staged = json.loads(staged_manifest.read_text())
    motions = {}
    for action in PURSUIT_ACTIONS:
        rec = inputs[f"inputs/animations/{action}.glb"]
        motions[action] = {"included": True, "path_hint": f"inputs/animations/{action}.glb (source: {rec['source']})",
                           "sha256": rec["sha256"], "exclusion_reason": None}
    motions["minstrel_static_mesh"] = {"included": False, "path_hint": "PF_MAYBE_minstrel.3qd87sruqknyz.glb",
                                       "sha256": None, "exclusion_reason": "single static mesh, no rig; unrelated to the rig"}
    motions["casual_walk_duplicate"] = {"included": False, "path_hint": "PF_CasualWalk.glb",
                                        "sha256": None, "exclusion_reason": "byte-identical duplicate of PF_Casual_Walk.glb"}
    actions = {}
    for action in PURSUIT_ACTIONS:
        info = staged["actions"][action]
        actions[action] = {
            "status": "mapped_debug" if action in PURSUIT_MAPPED else "inspect_only",
            "semantic": PURSUIT_MAPPED.get(action, "inspect only until its combat or reaction timing is validated"),
            "viewport": info["viewport"],
            "viewport_px": [256, 320 if info["viewport"].startswith("extended") else 256],
            "source_canvas": int(info["source_canvas"].split("_")[0][1:]),
            "frame_count": info["frame_count"],
            "sample_count": info["sample_count"],
            "sampling_target_fps": info["sampling_target_fps"],
            "authored_frame_range": info["authored_frame_range"],
            "loop": info["loop"],
            "clip_fit": "fits_class",
            "root_px": info["root_px"],
            "flags": [],
        }
    return {
        "schema": "custodian.character3d_contract.v1",
        "character_id": "pursuit_frame",
        "display_name": "Pursuit Frame",
        "status": "experimental_debug_preview",
        "source": {
            "master": {"path_hint": "inputs/character_master.glb (P-F-Character_output-1.glb)",
                       "sha256": inputs["inputs/character_master.glb"]["sha256"], "skin_joints": 24},
            "motions": motions,
        },
        "directions": {"order": PURSUIT_ORDER, "azimuth_deg": [0, 45, 90, 135, 180, 225, 270, 315],
                       "mirroring": False, "screen_convention": "S faces the camera; E is screen-right; W is screen-left"},
        "render": {"projection": "orthographic", "elevation_deg": 45, "px_per_m": 80, "root_bone": "Hips",
                   "root_mode": "object", "engine": "BLENDER_EEVEE"},
        "game": {"px_per_m": 50, "display_scale": 0.625,
                 "display_scale_rule": "display_scale = game_px_per_m / render_px_per_m = 50 / 80; matches the Operator 50 px/m contract"},
        "registration": {"policy": "fixed_per_class",
                         "rule": "one root pixel per canvas class, shared by every action, direction and frame; never recentred"},
        "canvas_classes": [
            {"id": "standard_256x256", "width": 256, "height": 256, "root_px": [128, 180], "clearance_px": 4},
            {"id": "extended_256x320", "width": 256, "height": 320, "root_px": [128, 216], "clearance_px": 4},
        ],
        "actions": actions,
        "staging": {"output_root": "custodian/.ai/pursuit_frame_3d_preview", "gitignored": True, "manifest_name": "manifest.json"},
        "dependencies_external": [
            "~/Downloads/PursuitFrame3D (source GLBs; hashes in reports/INPUT_MANIFEST.json)",
            "Blender 5.2.3 LTS headless for derive, verify and render",
            "pursuit_frame_3d_v1 proof workspace: derived clips, measure reports, cleaned frames (output/clean)",
        ],
    }


def build_operator(probe: Path, batch: Path) -> dict:
    review = json.loads((probe / "reports/REVIEW_VIEWPORT_REPORT.json").read_text())
    batch_inputs = json.loads((batch / "reports/INPUT_MANIFEST.json").read_text())["inputs"]
    actions = {}
    for action in OPERATOR_ACTIONS:
        v = review["actions"][action]
        vw, vh = v["viewport"]
        measure = json.loads(sorted((probe / "reports").glob(f"measure_{action}_objectfix_c*_80.json"))[0].read_text())
        actions[action] = {
            "status": "mapped_debug" if action in OPERATOR_MAPPED else "inspect_only",
            "semantic": OPERATOR_MAPPED.get(action, "inspect only; semantic review pending or not mapped"),
            "viewport": f"{v['viewport_class'].lower()}_{vw}x{vh}",
            "viewport_px": [vw, vh],
            "source_canvas": v["source_canvas"],
            "frame_count": measure["sample_count"],
            "sample_count": measure["sample_count"],
            "sampling_target_fps": measure["sampling_target_fps"],
            "authored_frame_range": measure["authored_frame_range"],
            "loop": measure["loop"],
            "clip_fit": "fits_with_clearance_check_pending",
            "root_px": v["target_pivot"],
            "flags": v["flags"],
        }
    return {
        "schema": "custodian.character3d_contract.v1",
        "character_id": "operator",
        "display_name": "Operator (Meshy)",
        "status": "candidate_unapproved",
        "source": {
            "master": {"path_hint": "OPERATOR_CHARACTER_MASTER_MESHY_DARK_V1.glb (Git LFS, operator-character-master-v1)",
                       "sha256": "3004e9b5014450708bab80897a83ae676d27704321d2bc4cacdaf9ef1881c127", "skin_joints": 24},
            "motions": {a: {"included": True, "path_hint": f"batch input {a}",
                            "sha256": batch_inputs[a]["sha256"], "exclusion_reason": None}
                        for a in OPERATOR_ACTIONS},
        },
        "directions": {"order": PURSUIT_ORDER, "azimuth_deg": [0, 45, 90, 135, 180, 225, 270, 315],
                       "mirroring": False, "screen_convention": "S faces the camera; E is screen-right; W is screen-left"},
        "render": {"projection": "orthographic", "elevation_deg": 45, "px_per_m": 80, "root_bone": "Hips",
                   "root_mode": "object", "engine": "BLENDER_EEVEE"},
        "game": {"px_per_m": 50, "display_scale": 1.0,
                 "display_scale_rule": ("preview default displays 80 px/m frames at 1.0; the physical-match toggle displays "
                                        "50 px/m frames at 80/50 = 1.6. The runtime 2.5D reference is 50 px/m. "
                                        "The reference is an OPEN DECISION, see the pipeline guide")},
        "registration": {"policy": "per_action_pivot",
                         "rule": "destination = source + target_pivot - source_pivot, per action; pivots come from REVIEW_VIEWPORT_REPORT"},
        "canvas_classes": [
            {"id": "standard_160x160", "width": 160, "height": 160, "root_px": None, "clearance_px": 4},
            {"id": "extended_192x192", "width": 192, "height": 192, "root_px": None, "clearance_px": 4},
        ],
        "actions": actions,
        "staging": {"output_root": "custodian/.ai/operator_3d_animation_preview", "gitignored": True, "manifest_name": "MANIFEST.json"},
        "dependencies_external": [
            "operator_running_scale_probe_v1 reports (PREVIEW_FRAME_MANIFEST.json, REVIEW_VIEWPORT_REPORT.json) and clean frames",
            "operator_sprite_batch_v1 reports/INPUT_MANIFEST.json (source hashes)",
            "Blender 5.2.3 LTS headless for the render chain that produced the clean frames",
        ],
    }


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--pursuit-workspace", required=True, type=Path)
    ap.add_argument("--pursuit-staged", required=True, type=Path)
    ap.add_argument("--operator-probe", required=True, type=Path)
    ap.add_argument("--operator-batch", required=True, type=Path)
    ap.add_argument("--out", required=True, type=Path)
    args = ap.parse_args(argv)
    args.out.mkdir(parents=True, exist_ok=True)
    for name, data in (
        ("pursuit_frame.v1.json", build_pursuit(args.pursuit_workspace.expanduser(), args.pursuit_staged)),
        ("operator.v1.json", build_operator(args.operator_probe.expanduser(), args.operator_batch.expanduser())),
    ):
        (args.out / name).write_text(json.dumps(data, indent=2) + "\n")
        print("wrote", args.out / name)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
