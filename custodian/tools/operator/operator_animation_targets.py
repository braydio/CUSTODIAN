"""Generation-aware Operator animation target and coverage projection."""
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

import operator_asset_schema as schema
import animation_workbench
from ui.state import AnimationRecord, AnimationSelection


GENERATIONS = {"legacy_96", "operator_2_5d_128"}
CANONICAL_DIRECTIONS = ("n", "ne", "e", "se", "s", "sw", "w", "nw")


@dataclass(frozen=True)
class TargetFamily:
    generation: str
    profile: str
    group: str
    action: str
    rank: int
    priority: str
    state: str
    directions: tuple[str, ...]
    required_layers: tuple[str, ...]
    migration_verdict: str
    source_sha256: str | None
    canonical_profile_sha256: str | None
    normalized_reference_sha256: str | None
    frame_contract: dict

    @property
    def key(self) -> tuple[str, str, str, str]:
        return self.generation, self.profile, self.group, self.action


def load_plan(path: Path) -> dict:
    payload = json.loads(Path(path).read_text())
    if payload.get("schema") not in {
        "custodian.operator_animation_implementation_plan.v1",
        "custodian.operator_animation_implementation_plan.v2",
    }:
        raise ValueError("unsupported implementation-plan schema")
    if not isinstance(payload.get("items"), list):
        raise ValueError("implementation plan items must be a list")
    return payload


def target_families(payload: dict) -> tuple[TargetFamily, ...]:
    families = []
    ids: set[str] = set()
    ranks: set[tuple[str, int]] = set()
    for row in payload.get("items", ()):
        generation = row.get("art_generation", "legacy_96")
        if generation not in GENERATIONS:
            raise ValueError(f"invalid art generation: {generation}")
        family_key = (generation, int(row["rank"]))
        if family_key in ranks:
            raise ValueError(f"duplicate plan rank for {generation}: {row['rank']}")
        if row["id"] in ids:
            raise ValueError(f"duplicate plan id: {row['id']}")
        ranks.add(family_key)
        ids.add(row["id"])
        if generation == "legacy_96":
            continue
        directions = tuple(str(value).lower() for value in row.get("requested_directions", row["directions"]))
        if len(set(directions)) != len(directions) or any(value not in CANONICAL_DIRECTIONS for value in directions):
            raise ValueError(f"invalid target directions for {row['id']}")
        if row.get("canonical_profile_id") != "operator_2_5d_128":
            raise ValueError(f"invalid canonical profile id for {row['id']}")
        if row.get("group") not in schema.ACTION_GROUPS:
            raise ValueError(f"invalid action group for {row['id']}: {row.get('group')}")
        families.append(TargetFamily(
            generation, row["profile"], row["group"], row["action"], int(row["rank"]),
            row["priority"], row["state"], directions,
            tuple(row.get("required_layers", ())), row.get("migration_verdict", ""),
            row.get("source_sha256"), row.get("canonical_profile_sha256"),
            row.get("normalized_reference_sha256"), dict(row.get("frame_contract") or {}),
        ))
    return tuple(sorted(families, key=lambda family: family.rank))


def _generation_source_files(repo_root: Path, family: TargetFamily, direction: str) -> dict[str, list[Path]]:
    directory = (
        Path(repo_root) / "custodian/content/sprites/operator/source/generations"
        / family.generation / "animations" / family.profile / family.group / family.action
    )
    found: dict[str, list[Path]] = {layer: [] for layer in family.required_layers}
    if not directory.is_dir():
        return found
    for path in directory.glob(f"operator__*__{family.profile}__{family.group}__{family.action}__{direction}__*f__128.png"):
        try:
            key = schema.parse_filename(path)
        except ValueError:
            continue
        if key.owner == "operator" and key.layer in found:
            found[key.layer].append(path)
    return found


def _profile_hashes(repo_root: Path) -> tuple[str | None, str | None]:
    path = Path(repo_root) / "custodian/content/data/operator/authoring/operator_art_profile.json"
    try:
        payload = json.loads(path.read_text())
        profile_id = payload.get("active_authoring_profile", "operator_2_5d_128")
        profile = payload.get("profiles", {}).get(profile_id, {})
        reference = payload.get("canonical_visual_reference", {})
        return profile.get("profile_sha256"), reference.get("sha256")
    except (OSError, json.JSONDecodeError, AttributeError):
        return None, None


def _workspace_state(path: Path) -> str:
    manifest = path / "workbench.json"
    if not manifest.is_file():
        return "NONE"
    try:
        data = json.loads(manifest.read_text())
    except (OSError, json.JSONDecodeError):
        return "BLOCKED"
    if data.get("pending_land") or data.get("last_publish", {}).get("state") == "LAND_PENDING":
        return "LAND_PENDING"
    if data.get("pending_migration"):
        return "BLOCKED"
    document = path / "workbench.aseprite"
    try:
        state = animation_workbench.state(data, document)
    except (KeyError, OSError, TypeError, ValueError):
        return "BLOCKED"
    if data.get("creation"):
        if state == "NEW / READY TO PUBLISH":
            return "READY_TO_PUBLISH"
        if state == "NEW / COLLISION":
            return "BLOCKED"
        return "EDITING"
    if state in {"EDITED", "EDITED+STALE"}:
        return "EDITING"
    if state == "STALE":
        return "STALE_REFERENCE"
    if data.get("last_publish", {}).get("validation_status") == "passed":
        return "RUNTIME_VERIFIED"
    return "REVIEW" if data.get("review_status") else "EDITING"


def project_targets(
    payload: dict, *, repo_root: Path, workspace_root: Path,
    legacy_records: Iterable[AnimationRecord] = (),
) -> tuple[AnimationRecord, ...]:
    """Project authored target leaves before local 2.5D files exist."""
    families = target_families(payload)
    legacy = {
        (record.selection.profile, record.selection.group, record.selection.action, record.selection.direction): record
        for record in legacy_records
    }
    audit_path = Path(repo_root) / "reports/operator_presentation/operator_2_5d_coverage.json"
    try:
        audit_rows = json.loads(audit_path.read_text()).get("production_reachable_actions", ())
    except (OSError, json.JSONDecodeError):
        audit_rows = ()
    audit = {(row.get("profile"), row.get("group"), row.get("action")): row for row in audit_rows}
    active_profile_hash, active_reference_hash = _profile_hashes(repo_root)
    records = []
    for family in families:
        audit_row = audit.get((family.profile, family.group, family.action), {})
        authored_directions = {str(value).lower() for value in audit_row.get("authored_directions", ())}
        projection_policy = str(audit_row.get("projection_policy", "")).strip().lower()
        frame_count = family.frame_contract.get("frames")
        family_ws = Path(workspace_root) / family.generation / family.profile / family.group / family.action
        stale = bool(
            (family.canonical_profile_sha256 and active_profile_hash != family.canonical_profile_sha256)
            or (family.normalized_reference_sha256 and active_reference_hash != family.normalized_reference_sha256)
        )
        for direction in family.directions:
            selection = AnimationSelection(
                family.profile, family.group, family.action, direction,
                art_generation=family.generation,
            )
            present = _generation_source_files(repo_root, family, direction)
            present_layers = tuple(layer for layer, paths in present.items() if paths)
            accepted_source = bool(family.source_sha256 and family.migration_verdict == "canonical_2_5d")
            workflow = _workspace_state(family_ws / direction)
            if len(present_layers) == len(family.required_layers) and family.required_layers:
                coverage = "CANONICAL_2_5D"
            elif present_layers:
                coverage = "PARTIAL"
            elif accepted_source:
                # The exact accepted source is an eight-direction sheet awaiting the
                # later intake slice; it is authored canonical input, not local output.
                coverage = "CANONICAL_2_5D"
            elif (family.profile, family.group, family.action, direction) in legacy:
                coverage = "LEGACY_FALLBACK"
            elif authored_directions and direction not in authored_directions and projection_policy not in {"", "none", "no projection"}:
                coverage = "PROJECTED"
            else:
                coverage = "MISSING"
            if coverage == "CANONICAL_2_5D":
                if workflow == "NONE" and accepted_source:
                    workflow = "INTAKE"
                canonical_complete = True
            else:
                canonical_complete = False
            if stale:
                workflow = "STALE_REFERENCE"
            layers = present_layers or (family.required_layers if accepted_source else ())
            records.append(AnimationRecord(
                selection, int(frame_count or 0), tuple(layers),
                "COMPLETE" if canonical_complete else ("PARTIAL" if coverage == "PARTIAL" else "REFERENCE/LEGACY"),
                "canonical source accepted" if accepted_source else coverage.lower().replace("_", " "),
                "LIVE" if coverage == "CANONICAL_2_5D" else "DORMANT",
                coverage, workflow, canonical_complete, stale, family.rank,
            ))
    return tuple(records)
