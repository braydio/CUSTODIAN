"""Drive the character 3D-to-2.5D pipeline from a contract.

One entry point for the stages whose tools are repository-owned. Each subcommand reads a
character contract (see contracts/character_contract.v1.schema.json), resolves paths against a
workspace, and runs the matching repo tool. Use --dry-run to print the exact commands without
running anything. Staging is delegated to the character's own stager, because each character's
presentation adapter has its own staged format and is deliberately not merged.

Stages (run in this order):
  verify-inputs  hash source files named in the contract against their recorded SHA-256
  adapt          motion -> derived skinned GLB (adapt_motion_to_master.py)
  verify         derived clip pose checks (verify_derived_pose.py, Blender headless)
  render         object-level root removal render (measure_render.py, Blender headless)
  clean          alpha cleanup of raw renders into a derived tree (alpha_cleanup.py)
  sheets         one review sheet per action (make_review_sheets.py)
  stage          character-specific staging into a gitignored custodian/.ai folder
  validate       validate the contract against the schema

Usage:
  python3 -I custodian/tools/character3d/pipeline.py <stage> --contract <file> --workspace <dir> [--dry-run]
"""
import argparse
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parents[1]
BLENDER = os.environ.get("BLENDER", "blender")
PYTHON = sys.executable
STAGERS = {
    "pursuit_frame": "stage/pursuit_frame_stage.py",
    "operator": "stage/operator_stage.py",
}


def load_contract(path: Path) -> dict:
    contract = json.loads(path.read_text())
    if contract.get("schema") != "custodian.character3d_contract.v1":
        raise SystemExit(f"{path}: not a character3d contract")
    return contract


def included_actions(contract: dict):
    return [a for a, info in contract["actions"].items()]


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def verify_inputs(contract: dict, workspace: Path) -> list[str]:
    """Return one line per source file: OK, MISMATCH, MISSING, or EXTERNAL (not checkable here)."""
    lines = []
    master = contract["source"]["master"]
    entries = [("master", master["path_hint"], master["sha256"])]
    for name, info in contract["source"]["motions"].items():
        if info["included"]:
            entries.append((name, info["path_hint"], info["sha256"]))
    for name, hint, expected in entries:
        rel = hint.split(" ")[0]
        if not rel.startswith("inputs/"):
            lines.append(f"EXTERNAL {name}: {hint} (hash checked by the owning workspace)")
            continue
        path = workspace / rel
        if not path.is_file():
            lines.append(f"MISSING  {name}: {path}")
            continue
        actual = sha256_file(path)
        lines.append(("OK       " if actual == expected else "MISMATCH ") + f"{name}: {path}")
    return lines


def commands_for(stage: str, contract: dict, workspace: Path, canvas_override: int | None, batch: Path | None = None,
                 only: list[str] | None = None):
    """Return a list of (label, argv, cwd) tuples for a stage. Pure: no side effects."""
    cmds = []
    selected = set(only) if only else None
    actions = included_actions(contract) if stage in ("verify", "render", "clean", "sheets") else []
    if selected is not None:
        unknown = selected - set(contract["actions"]) - set(contract["source"]["motions"])
        if unknown:
            raise SystemExit(f"--action not in contract: {sorted(unknown)}")
        actions = [a for a in actions if a in selected]
    if stage == "adapt":
        for a in contract["source"]["motions"]:
            info = contract["source"]["motions"][a]
            if not info["included"] or (selected is not None and a not in selected):
                continue
            # Workspace-relative arguments: the adapter records its input path in the output's
            # provenance, so relative paths keep the output identical across machines.
            cmds.append((a, [PYTHON, "-I", str(HERE / "adapt/adapt_motion_to_master.py"),
                             "inputs/character_master.glb", f"inputs/animations/{a}.glb",
                             f"output/derived/{a}_skinned.glb", a], workspace))
    elif stage == "verify":
        for a in actions:
            cmds.append((a, [BLENDER, "-b", "--factory-startup", "--python", str(HERE / "adapt/verify_derived_pose.py"), "--",
                             str(workspace / f"output/derived/{a}_skinned.glb"),
                             str(workspace / f"inputs/animations/{a}.glb"),
                             str(workspace / f"reports/{a}_derived_verification.json")], workspace))
    elif stage == "render":
        ppm = contract["render"]["px_per_m"]
        for a in actions:
            canvas = canvas_override or contract["actions"][a]["source_canvas"]
            cmds.append((a, [BLENDER, "-b", "--factory-startup", "--python", str(HERE / "render/measure_render.py"), "--",
                             "--action", a, "--clip", str(workspace / f"output/derived/{a}_skinned.glb"),
                             "--out", str(workspace / "output/measure"),
                             "--meta", str(workspace / f"reports/measure_{a}_c{canvas}_{ppm:g}.json"),
                             "--ppm", f"{ppm:g}", "--canvas", str(canvas),
                             "--root-mode", contract["render"]["root_mode"]], workspace))
    elif stage == "clean":
        ppm = contract["render"]["px_per_m"]
        canvases = sorted({contract["actions"][a]["source_canvas"] for a in actions} | ({canvas_override} if canvas_override else set()))
        for c in canvases:
            cmds.append((f"c{c}", [PYTHON, "-I", str(HERE / "render/alpha_cleanup.py"),
                                   "--src", str(workspace / f"output/measure/c{c}_{ppm:g}"),
                                   "--dst", str(workspace / f"output/clean/c{c}_{ppm:g}"),
                                   "--report", str(workspace / f"reports/_alpha_cleanup_c{c}.json")], workspace))
    elif stage == "sheets":
        ppm = contract["render"]["px_per_m"]
        by_canvas: dict[int, list[str]] = {}
        for a in actions:
            by_canvas.setdefault(canvas_override or contract["actions"][a]["source_canvas"], []).append(a)
        for c, names in sorted(by_canvas.items()):
            cmds.append((f"c{c}", [PYTHON, "-I", str(HERE / "review/make_review_sheets.py"),
                                   "--src", str(workspace / f"output/clean/c{c}_{ppm:g}"),
                                   "--action", *names, "--out", str(workspace / "output/review")], workspace))
    elif stage == "stage":
        char = contract["character_id"]
        if char not in STAGERS:
            raise SystemExit(f"no stager registered for character {char!r}; add one, do not reuse another character's")
        script = STAGERS[char]
        if char == "pursuit_frame":
            argv = [PYTHON, "-I", str(HERE / script), "--workspace", str(workspace)]
        else:
            if batch is None:
                raise SystemExit("operator staging needs --batch <operator_sprite_batch_v1 workspace>")
            argv = [PYTHON, "-I", str(HERE / script), "--probe", str(workspace), "--batch", str(batch),
                    "--repo", str(REPO_ROOT.parent)]
        cmds.append((char, argv, REPO_ROOT))
    return cmds


def run(cmds, dry_run: bool) -> int:
    status = 0
    for label, argv, cwd in cmds:
        print(f"[{label}] " + " ".join(argv))
        if dry_run:
            continue
        result = subprocess.run(argv, cwd=cwd)
        if result.returncode != 0:
            print(f"[{label}] FAILED exit {result.returncode}")
            status = result.returncode
            break
    return status


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("stage", choices=["verify-inputs", "adapt", "verify", "render", "clean", "sheets", "stage", "validate"])
    ap.add_argument("--contract", required=True, type=Path)
    ap.add_argument("--workspace", type=Path, help="workspace root (required for every stage except validate)")
    ap.add_argument("--canvas", type=int, default=None, help="override the canvas for render/clean/sheets")
    ap.add_argument("--batch", type=Path, default=None, help="Operator only: operator_sprite_batch_v1 workspace")
    ap.add_argument("--action", nargs="+", default=None, help="limit the stage to these actions")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args(argv)
    contract = load_contract(args.contract)
    if args.stage == "validate":
        return subprocess.run([PYTHON, "-I", str(HERE / "validate_contract.py"), str(args.contract)]).returncode
    if args.workspace is None:
        raise SystemExit(f"--workspace is required for stage {args.stage!r}")
    workspace = args.workspace.expanduser().resolve()
    if args.stage == "verify-inputs":
        lines = verify_inputs(contract, workspace)
        print("\n".join(lines))
        return 1 if any(line.startswith(("MISMATCH", "MISSING")) for line in lines) else 0
    batch = args.batch.expanduser().resolve() if args.batch else None
    return run(commands_for(args.stage, contract, workspace, args.canvas, batch, args.action), args.dry_run)


if __name__ == "__main__":
    raise SystemExit(main())
