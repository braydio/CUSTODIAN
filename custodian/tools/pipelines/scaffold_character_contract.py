#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_REQUEST_ROOT = PROJECT_ROOT / "content/sprites/_pipeline/requests"
DEFAULT_DIRECTIONS = ("s", "se", "e", "ne", "n", "nw", "w", "sw")


@dataclass(frozen=True)
class ChecklistEntry:
    layer: str
    loadout: str
    action: str
    frames: int | str
    required: bool
    notes: str


TEMPLATES: dict[str, list[ChecklistEntry]] = {
    "humanoid_combat": [
        ChecklistEntry("body", "unarmed", "idle_01", 5, True, "baseline readability"),
        ChecklistEntry("body", "unarmed", "walk_01", 5, True, "navigation readability"),
        ChecklistEntry("body", "unarmed", "run_01", 5, True, "combat movement readability"),
        ChecklistEntry("body", "unarmed", "attack_01", "4-6", True, "one readable melee attack"),
        ChecklistEntry("body", "unarmed", "hitreact_01", 4, True, "damage response"),
        ChecklistEntry("body", "unarmed", "death_01", "6-10", True, "combat resolution"),
        ChecklistEntry("body", "unarmed", "block_loop_01", 5, False, "only if this character defends"),
        ChecklistEntry("body", "unarmed", "parry_01", 5, False, "only if this character can parry"),
        ChecklistEntry("fx", "unarmed", "attack_01", "4-6", False, "optional slash, flash, or impact overlay"),
        ChecklistEntry("weapon", "ranged_2h", "stance_01", 5, False, "only if this character uses ranged two-hand weapons"),
        ChecklistEntry("weapon", "ranged_2h", "fire_01", "4-8", False, "only if ranged playback is registered"),
    ],
}


def main() -> int:
    parser = argparse.ArgumentParser(description="Scaffold a production checklist and suggested animation contract.")
    parser.add_argument("--owner", required=True)
    parser.add_argument("--template", default="humanoid_combat", choices=sorted(TEMPLATES))
    parser.add_argument("--frame-size", type=int, default=96)
    parser.add_argument("--directions", default=",".join(DEFAULT_DIRECTIONS))
    parser.add_argument("--output-root", type=Path, default=DEFAULT_REQUEST_ROOT)
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    directions = [part.strip() for part in args.directions.split(",") if part.strip()]
    if not directions:
        raise SystemExit("At least one direction is required.")

    request_dir = args.output_root / args.owner
    request_dir.mkdir(parents=True, exist_ok=True)
    checklist_path = request_dir / f"{args.owner}_animation_checklist.md"
    contract_path = request_dir / f"{args.owner}_suggested_contract.json"
    filenames_path = request_dir / f"{args.owner}_expected_filenames.txt"

    for path in (checklist_path, contract_path, filenames_path):
        if path.exists() and not args.force:
            raise SystemExit(f"{path} already exists. Pass --force to overwrite.")

    entries = TEMPLATES[args.template]
    filenames = expected_filenames(args.owner, entries, directions, args.frame_size)
    checklist_path.write_text(render_checklist(args.owner, args.template, entries, directions, args.frame_size, filenames), encoding="utf-8")
    contract_path.write_text(json.dumps(render_contract(args.owner, args.template, entries, directions, args.frame_size), indent=2), encoding="utf-8")
    filenames_path.write_text("\n".join(filenames) + "\n", encoding="utf-8")

    print(f"Wrote checklist: {checklist_path}")
    print(f"Wrote suggested contract: {contract_path}")
    print(f"Wrote expected filenames: {filenames_path}")
    return 0


def expected_filenames(owner: str, entries: list[ChecklistEntry], directions: list[str], frame_size: int) -> list[str]:
    filenames: list[str] = []
    for entry in entries:
        for direction in directions:
            filenames.append(
                f"{owner}__{entry.layer}__{entry.loadout}__{entry.action}__{direction}__{filename_frame_count(entry.frames)}f__{frame_size}.png"
            )
    return filenames


def filename_frame_count(frames: int | str) -> int:
    if isinstance(frames, int):
        return frames
    if "-" in frames:
        return int(frames.split("-", 1)[1])
    return int(frames)


def render_checklist(
    owner: str,
    template: str,
    entries: list[ChecklistEntry],
    directions: list[str],
    frame_size: int,
    filenames: list[str],
) -> str:
    source_path = f"custodian/content/sprites/_pipeline/inbox/{owner}/"
    runtime_path = f"custodian/content/sprites/{owner}/runtime/"
    lines = [
        f"# {owner} Animation Production Checklist",
        "",
        f"- Template: `{template}`",
        f"- Frame size: `{frame_size}`",
        f"- Directions: `{','.join(directions)}`",
        f"- Intended source/inbox path: `{source_path}`",
        f"- Intended runtime destination pattern: `{runtime_path}` after a deliberate import/build step",
        "- Runtime playback still requires deliberate code/state registration; these files only plan art coverage.",
        "- Do not place gameplay scenes against `_pipeline/` paths.",
        "",
        "## Authoring Order",
        "",
        "1. idle",
        "2. walk/run",
        "3. one readable attack",
        "4. hit reaction",
        "5. death",
        "6. block/parry/defense if the character uses it",
        "7. ranged/sidearm if needed",
        "",
        "## Coverage",
        "",
        "| Required | Layer | Loadout | Action | Frames | Notes |",
        "|---|---|---|---|---|---|",
    ]
    for entry in entries:
        lines.append(
            f"| {'yes' if entry.required else 'optional'} | `{entry.layer}` | `{entry.loadout}` | `{entry.action}` | `{entry.frames}` | {entry.notes} |"
        )
    lines.extend(["", "## Recommended Canonical Filenames", ""])
    for filename in filenames:
        lines.append(f"- `{filename}`")
    return "\n".join(lines) + "\n"


def render_contract(owner: str, template: str, entries: list[ChecklistEntry], directions: list[str], frame_size: int) -> dict[str, object]:
    return {
        "schema": "custodian.character_animation_contract.v1",
        "owner": owner,
        "template": template,
        "frame_size": frame_size,
        "directions": directions,
        "notes": [
            "Generated by scaffold_character_contract.py as a production planning aid.",
            "Runtime playback still requires deliberate code/state registration.",
        ],
        "groups": [
            {
                "id": "starter_humanoid_combat",
                "label": "Starter humanoid combat coverage",
                "required": False,
                "entries": [
                    {
                        "layer": entry.layer,
                        "loadout": entry.loadout,
                        "action": entry.action,
                        "directions": directions,
                        "required": entry.required,
                        "frame_size": frame_size,
                        "frames": entry.frames,
                        "notes": entry.notes,
                    }
                    for entry in entries
                ],
            }
        ],
    }


if __name__ == "__main__":
    raise SystemExit(main())
