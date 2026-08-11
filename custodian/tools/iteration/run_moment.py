#!/usr/bin/env python3
"""Run deterministic CUSTODIAN Moment Forge micro-scenarios."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, Iterable

from build_moment_report import BaselineCompatibilityError, build_report
from changed_file_router import changed_files, suggest_scenarios


ITERATION_DIR = Path(__file__).resolve().parent
CUSTODIAN_DIR = ITERATION_DIR.parents[1]
REPO_ROOT = ITERATION_DIR.parents[2]
SCENARIO_ROOT = ITERATION_DIR / "scenarios"
DEFAULT_OUTPUT_ROOT = REPO_ROOT / "reports" / "moment_forge"
BASELINE_ROOT = DEFAULT_OUTPUT_ROOT / "_baselines"

EXIT_OK = 0
EXIT_SCHEMA = 2
EXIT_PREFLIGHT = 3
EXIT_RUNTIME = 4
EXIT_ASSERTIONS = 5
EXIT_REPORT = 6
EXIT_BASELINE = 7
EXIT_MEDIA = 8

SUPPORTED_ACTIONS = {
    "input_press",
    "input_release",
    "input_tap",
    "aim_at_role",
    "aim_at_world",
    "set_role_position",
    "set_role_property",
    "set_role_physics_enabled",
    "set_role_process_enabled",
    "capture_marker",
    "fixture_command",
    "finish",
}
SUPPORTED_ASSERTIONS = {
    "event_count",
    "warning_count",
    "counter_value",
    "probe_compare",
    "metric_compare",
    "role_exists",
    "no_unreleased_inputs",
    "output_exists",
    "event_order",
    "event_exactly_once",
    "event_absent",
    "event_field_compare",
    "event_same_field",
    "event_between_ticks",
    "role_distance_compare",
}
ID_PATTERN = re.compile(r"^[a-z0-9][a-z0-9_/-]*[a-z0-9]$")
TAG_PATTERN = re.compile(r"^[a-z0-9_]+$")


class ScenarioError(ValueError):
    """Scenario or CLI contract error."""


class PreflightError(RuntimeError):
    """Environment cannot perform the requested run."""


def _resolve_res_path(path: str) -> Path:
    return CUSTODIAN_DIR / path.removeprefix("res://")


def _scenario_snapshot(scenario: dict[str, Any]) -> dict[str, Any]:
    return {key: value for key, value in scenario.items() if not key.startswith("_")}


def _canonical_json(payload: Any) -> bytes:
    return json.dumps(
        payload,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=True,
    ).encode("utf-8")


def scenario_sha256(scenario: dict[str, Any]) -> str:
    return hashlib.sha256(_canonical_json(_scenario_snapshot(scenario))).hexdigest()


def _require_object(container: dict[str, Any], key: str) -> dict[str, Any]:
    value = container.get(key)
    if not isinstance(value, dict):
        raise ScenarioError(f"{key} must be an object")
    return value


def _require_array(container: dict[str, Any], key: str) -> list[Any]:
    value = container.get(key)
    if not isinstance(value, list):
        raise ScenarioError(f"{key} must be an array")
    return value


def _validate_res_scene(path: Any, label: str, require_scene: bool) -> str:
    if (
        not isinstance(path, str)
        or not path.startswith("res://")
        or ".." in path
        or not path.endswith((".tscn", ".scn"))
    ):
        raise ScenarioError(f"{label} must be a contained res:// scene path")
    if require_scene and not _resolve_res_path(path).is_file():
        raise ScenarioError(f"{label} does not exist: {path}")
    return path


def _validate_setup(setup: dict[str, Any], require_scene: bool) -> set[str]:
    allowed = {"remove_nodes", "roles", "spawns", "properties", "processing", "fixture"}
    unknown = sorted(set(setup).difference(allowed))
    if unknown:
        raise ScenarioError(f"setup contains unsupported fields: {', '.join(unknown)}")
    roles = _require_object(setup, "roles")
    if not roles:
        raise ScenarioError("setup.roles must define at least one role")
    role_ids: set[str] = set()
    for role_id, definition in roles.items():
        if not TAG_PATTERN.fullmatch(str(role_id)) or not isinstance(definition, dict):
            raise ScenarioError("setup role IDs must be lowercase identifiers with object definitions")
        selectors = [name for name in ("node_path", "group", "spawn_id") if definition.get(name)]
        if len(selectors) != 1:
            raise ScenarioError(f"role {role_id} must declare exactly one selector")
        role_ids.add(str(role_id))
    for raw_spawn in _require_array(setup, "spawns"):
        if not isinstance(raw_spawn, dict):
            raise ScenarioError("setup.spawns entries must be objects")
        spawn_id = str(raw_spawn.get("id", ""))
        role_id = str(raw_spawn.get("role", ""))
        if not TAG_PATTERN.fullmatch(spawn_id) or not TAG_PATTERN.fullmatch(role_id):
            raise ScenarioError("spawn id and role must be lowercase identifiers")
        if role_id in role_ids:
            raise ScenarioError(f"duplicate role ID: {role_id}")
        _validate_res_scene(raw_spawn.get("scene"), f"spawn {spawn_id} scene", require_scene)
        if str(raw_spawn.get("parent_role", "")) not in role_ids:
            raise ScenarioError(f"spawn {spawn_id} references an unknown parent role")
        role_ids.add(role_id)
    for key in ("properties", "processing"):
        for record in _require_array(setup, key):
            if not isinstance(record, dict) or str(record.get("role", "")) not in role_ids:
                raise ScenarioError(f"setup.{key} references an unknown role")
    for node_path in _require_array(setup, "remove_nodes"):
        if not isinstance(node_path, str) or node_path.startswith("/") or ".." in node_path:
            raise ScenarioError("setup.remove_nodes must contain scene-relative NodePaths")
    fixture = _require_object(setup, "fixture")
    if not TAG_PATTERN.fullmatch(str(fixture.get("id", ""))):
        raise ScenarioError("setup.fixture.id must be a lowercase identifier")
    if not isinstance(fixture.get("config", {}), dict):
        raise ScenarioError("setup.fixture.config must be an object")
    return role_ids


def _validate_timeline(
    timeline: list[Any],
    duration: int,
    role_ids: set[str],
) -> None:
    previous_tick = -1
    exact_records: set[bytes] = set()
    held: set[str] = set()
    for index, raw_action in enumerate(timeline):
        if not isinstance(raw_action, dict):
            raise ScenarioError("timeline entries must be objects")
        tick = raw_action.get("tick")
        if not isinstance(tick, int) or not 0 <= tick < duration:
            raise ScenarioError(f"timeline[{index}] tick is outside scenario duration")
        if tick < previous_tick:
            raise ScenarioError("timeline ticks must be nondecreasing")
        previous_tick = tick
        encoded = _canonical_json(raw_action)
        if encoded in exact_records:
            raise ScenarioError(f"duplicate exact action at tick {tick}")
        exact_records.add(encoded)
        action = raw_action.get("action")
        if action not in SUPPORTED_ACTIONS:
            raise ScenarioError(f"unsupported action: {action}")
        if action in {"input_press", "input_release", "input_tap"}:
            name = str(raw_action.get("name", ""))
            if not name:
                raise ScenarioError(f"{action} requires name")
            if action == "input_press":
                held.add(name)
            elif action == "input_release":
                held.discard(name)
            else:
                hold_ticks = raw_action.get("hold_ticks")
                release_tick = raw_action.get("release_tick")
                if not (
                    isinstance(hold_ticks, int)
                    and hold_ticks > 0
                    or isinstance(release_tick, int)
                    and tick < release_tick < duration
                ):
                    raise ScenarioError("input_tap requires positive hold_ticks or in-range release_tick")
        if action in {
            "aim_at_role",
            "set_role_position",
            "set_role_property",
            "set_role_physics_enabled",
            "set_role_process_enabled",
        } and str(raw_action.get("role", "")) not in role_ids:
            raise ScenarioError(f"{action} references an unknown role")
        if action == "aim_at_role" and str(raw_action.get("target_role", "")) not in role_ids:
            raise ScenarioError("aim_at_role references an unknown target_role")
        if action == "fixture_command" and not TAG_PATTERN.fullmatch(str(raw_action.get("name", ""))):
            raise ScenarioError("fixture_command requires a registered command name")
    if held:
        raise ScenarioError(
            "timeline leaves InputMap actions pressed: " + ", ".join(sorted(held))
        )


def _validate_probes(probes: list[Any], role_ids: set[str], duration: int) -> set[str]:
    probe_ids: set[str] = set()
    for raw_probe in probes:
        if not isinstance(raw_probe, dict):
            raise ScenarioError("probe entries must be objects")
        probe_id = str(raw_probe.get("id", ""))
        if not TAG_PATTERN.fullmatch(probe_id) or probe_id in probe_ids:
            raise ScenarioError("probe IDs must be unique lowercase identifiers")
        if str(raw_probe.get("role", "")) not in role_ids:
            raise ScenarioError(f"probe {probe_id} references an unknown role")
        if raw_probe.get("snapshot") not in {None, "debug"}:
            raise ScenarioError(f"probe {probe_id} has invalid snapshot mode")
        fields = raw_probe.get("fields")
        if not isinstance(fields, list) or not fields or any(not isinstance(item, str) for item in fields):
            raise ScenarioError(f"probe {probe_id} requires fields")
        ticks = raw_probe.get("ticks", [])
        if ticks and (
            not isinstance(ticks, list)
            or len(ticks) != len(set(ticks))
            or any(not isinstance(tick, int) or not 0 <= tick < duration for tick in ticks)
        ):
            raise ScenarioError(f"probe {probe_id} has invalid ticks")
        every = raw_probe.get("every_ticks")
        if every is not None and (not isinstance(every, int) or every <= 0):
            raise ScenarioError(f"probe {probe_id} every_ticks must be positive")
        probe_ids.add(probe_id)
    return probe_ids


def _validate_assertions(assertions: list[Any], probe_ids: set[str], role_ids: set[str], duration: int) -> None:
    compare_kinds = {"warning_count", "event_count", "counter_value", "probe_compare", "metric_compare",
                     "event_field_compare", "role_distance_compare"}
    compare_ops = {"eq", "ne", "gt", "gte", "lt", "lte"}
    filtered_event_kinds = {"event_exactly_once", "event_absent", "event_field_compare"}
    for index, raw_assertion in enumerate(assertions):
        if not isinstance(raw_assertion, dict):
            raise ScenarioError("assertions must be objects")
        kind = raw_assertion.get("type")
        if kind not in SUPPORTED_ASSERTIONS:
            raise ScenarioError(f"unsupported assertion: {kind}")
        severity = raw_assertion.get("severity", "error")
        if severity not in {"error", "warning", "info"}:
            raise ScenarioError(f"assertion[{index}] has invalid severity")
        if kind in compare_kinds and raw_assertion.get("op", "eq") not in compare_ops:
            raise ScenarioError(f"{kind}.op must be one of {sorted(compare_ops)}")
        if kind == "probe_compare":
            references = [raw_assertion.get("probe")]
            value_from = raw_assertion.get("value_from")
            if isinstance(value_from, dict):
                references.append(value_from.get("probe"))
            if any(str(reference) not in probe_ids for reference in references):
                raise ScenarioError("probe_compare references an undefined probe")
        if kind == "output_exists":
            path = str(raw_assertion.get("path", ""))
            if not path or ".." in Path(path).parts or Path(path).is_absolute():
                raise ScenarioError("output_exists path must be run-relative")
        if kind in {"event_exactly_once", "event_absent", "event_field_compare", "event_between_ticks"} and not raw_assertion.get("event"):
            raise ScenarioError(f"{kind} requires event")
        if kind in filtered_event_kinds:
            where = raw_assertion.get("where", {})
            if not isinstance(where, dict) or any(not isinstance(path, str) or not path for path in where):
                raise ScenarioError(f"{kind}.where must be an object with dotted-path keys")
            if any(isinstance(value, str) and value.startswith("$") for value in where.values()):
                raise ScenarioError(f"{kind}.where does not support correlation variables")
        if kind == "event_field_compare" and (not isinstance(raw_assertion.get("field"), str) or not raw_assertion.get("field")):
            raise ScenarioError("event_field_compare requires field")
        if kind == "event_field_compare" and raw_assertion.get("select", "last") not in {"first", "last"}:
            raise ScenarioError("event_field_compare.select must be first|last")
        if kind == "event_same_field":
            events = raw_assertion.get("events")
            if (not isinstance(events, list) or len(events) < 2
                    or any(not isinstance(event, str) or not event for event in events)
                    or not isinstance(raw_assertion.get("field"), str) or not raw_assertion.get("field")):
                raise ScenarioError("event_same_field requires events and field")
        if kind == "event_between_ticks":
            start_tick = raw_assertion.get("start_tick")
            end_tick = raw_assertion.get("end_tick")
            if (not isinstance(start_tick, int) or not isinstance(end_tick, int)
                    or not 0 <= start_tick <= end_tick < duration):
                raise ScenarioError("event_between_ticks tick range is invalid")
            if raw_assertion.get("count_op", "eq") not in compare_ops:
                raise ScenarioError(f"event_between_ticks.count_op must be one of {sorted(compare_ops)}")
            if not isinstance(raw_assertion.get("count", 1), int) or raw_assertion.get("count", 1) < 0:
                raise ScenarioError("event_between_ticks.count must be a nonnegative integer")
        if kind == "role_distance_compare":
            role_a, role_b = raw_assertion.get("role_a"), raw_assertion.get("role_b")
            if role_a not in role_ids or role_b not in role_ids:
                raise ScenarioError("role_distance_compare references an undefined role")


def validate_scenario(
    scenario: dict[str, Any],
    source_path: Path | None = None,
    require_scene: bool = True,
) -> dict[str, Any]:
    required = {
        "schema_version",
        "id",
        "description",
        "scene",
        "seed",
        "duration_ticks",
        "simulation",
        "capture",
        "setup",
        "timeline",
        "probes",
        "assertions",
        "stable_fingerprint",
        "tags",
    }
    missing = sorted(required.difference(scenario))
    if missing:
        raise ScenarioError(f"missing required fields: {', '.join(missing)}")
    unknown = sorted(set(scenario).difference(required | {"comparison"}))
    if unknown:
        raise ScenarioError(f"unsupported top-level fields: {', '.join(unknown)}")
    if scenario["schema_version"] != 1:
        raise ScenarioError("schema_version must be 1")
    scenario_id = scenario["id"]
    if (
        not isinstance(scenario_id, str)
        or len(scenario_id) > 120
        or not ID_PATTERN.fullmatch(scenario_id)
        or "/" not in scenario_id
        or ".." in scenario_id
        or "//" in scenario_id
        or "\\" in scenario_id
    ):
        raise ScenarioError("id must be a safe lowercase slash-delimited identifier")
    if source_path is not None and source_path.is_relative_to(SCENARIO_ROOT):
        expected_id = source_path.relative_to(SCENARIO_ROOT).with_suffix("").as_posix()
        if scenario_id != expected_id:
            raise ScenarioError(f"id {scenario_id!r} disagrees with path {expected_id!r}")
    description = scenario["description"]
    if not isinstance(description, str) or not description.strip() or len(description) > 300:
        raise ScenarioError("description must contain 1–300 characters")
    _validate_res_scene(scenario["scene"], "scene", require_scene)
    seed_value = scenario["seed"]
    if not isinstance(seed_value, int) or not -(2**62) <= seed_value < 2**62:
        raise ScenarioError("seed must be a signed 63-bit integer")
    duration = scenario["duration_ticks"]
    if not isinstance(duration, int) or not 1 <= duration <= 1800:
        raise ScenarioError("duration_ticks must be between 1 and 1800")

    simulation = _require_object(scenario, "simulation")
    if set(simulation).difference(
        {"physics_hz", "warmup_ticks", "max_wall_seconds", "pause_during_setup"}
    ):
        raise ScenarioError("simulation contains unsupported fields")
    if simulation.get("physics_hz") != 60:
        raise ScenarioError("simulation.physics_hz must be 60 in schema v1")
    if not isinstance(simulation.get("warmup_ticks"), int) or simulation["warmup_ticks"] < 0:
        raise ScenarioError("simulation.warmup_ticks must be a nonnegative integer")
    if not isinstance(simulation.get("max_wall_seconds"), (int, float)) or not 1 <= simulation["max_wall_seconds"] <= 600:
        raise ScenarioError("simulation.max_wall_seconds is outside 1–600")
    if not isinstance(simulation.get("pause_during_setup"), bool):
        raise ScenarioError("simulation.pause_during_setup must be boolean")

    capture = _require_object(scenario, "capture")
    capture_required = {
        "width",
        "height",
        "fps",
        "audio",
        "start_tick",
        "end_tick",
        "contact_sheet_ticks",
        "required_keyframes",
        "background",
    }
    if capture_required.difference(capture):
        raise ScenarioError("capture is missing required fields")
    if set(capture).difference(capture_required | {"audio_onset_threshold_dbfs"}):
        raise ScenarioError("capture contains unsupported fields")
    if capture["width"] != 1280 or capture["height"] != 720 or capture["fps"] != 60:
        raise ScenarioError("schema v1 capture must be 1280x720 at 60 fps")
    if not isinstance(capture["audio"], bool) or not isinstance(capture["required_keyframes"], bool):
        raise ScenarioError("capture audio/required_keyframes must be boolean")
    if capture["background"] not in {"opaque", "transparent"}:
        raise ScenarioError("capture.background is invalid")
    start_tick, end_tick = capture["start_tick"], capture["end_tick"]
    if not isinstance(start_tick, int) or not isinstance(end_tick, int) or not 0 <= start_tick <= end_tick < duration:
        raise ScenarioError("capture tick range is invalid")
    contact_ticks = capture["contact_sheet_ticks"]
    if (
        not isinstance(contact_ticks, list)
        or len(contact_ticks) != 6
        or contact_ticks != sorted(set(contact_ticks))
        or any(not isinstance(tick, int) or not start_tick <= tick <= end_tick for tick in contact_ticks)
    ):
        raise ScenarioError("contact_sheet_ticks must contain six sorted unique in-range ticks")

    role_ids = _validate_setup(_require_object(scenario, "setup"), require_scene)
    _validate_timeline(_require_array(scenario, "timeline"), duration, role_ids)
    probe_ids = _validate_probes(_require_array(scenario, "probes"), role_ids, duration)
    _validate_assertions(_require_array(scenario, "assertions"), probe_ids, role_ids, duration)
    stable = _require_object(scenario, "stable_fingerprint")
    if set(stable).difference(
        {"event_payload_fields", "counters", "probes", "position_quantum_px", "float_quantum"}
    ):
        raise ScenarioError("stable_fingerprint contains unsupported fields")
    if any(str(probe_id) not in probe_ids for probe_id in stable.get("probes", [])):
        raise ScenarioError("stable_fingerprint references an undefined probe")
    tags = _require_array(scenario, "tags")
    if not tags or len(tags) != len(set(tags)) or any(
        not isinstance(tag, str) or not TAG_PATTERN.fullmatch(tag) for tag in tags
    ):
        raise ScenarioError("tags must be nonempty unique lowercase identifiers")
    return scenario


def load_scenarios(root: Path = SCENARIO_ROOT) -> dict[str, dict[str, Any]]:
    scenarios: dict[str, dict[str, Any]] = {}
    for path in sorted(root.rglob("*.json")):
        scenario = json.loads(path.read_text(encoding="utf-8"))
        validate_scenario(scenario, path)
        scenario_id = scenario["id"]
        if scenario_id in scenarios:
            raise ScenarioError(f"duplicate scenario id: {scenario_id}")
        scenario["_source_path"] = str(path.resolve())
        scenarios[scenario_id] = scenario
    return scenarios


def _resolve_output_root(path: Path, allow_external: bool = False) -> Path:
    resolved = path.resolve()
    permitted = DEFAULT_OUTPUT_ROOT.resolve()
    if not allow_external and resolved != permitted and permitted not in resolved.parents:
        raise ScenarioError(f"output root must remain under {permitted}")
    forbidden = [
        (CUSTODIAN_DIR / "content").resolve(),
        (CUSTODIAN_DIR / "game").resolve(),
        (CUSTODIAN_DIR / "scenes").resolve(),
        (REPO_ROOT / "design").resolve(),
    ]
    if any(resolved == item or item in resolved.parents for item in forbidden):
        raise ScenarioError("output root may not be inside source/runtime content")
    return resolved


def _output_dir_for(
    scenario_id: str,
    run_id: str,
    output_root: Path,
    allow_external: bool = False,
) -> Path:
    root = _resolve_output_root(output_root, allow_external)
    result = (root / scenario_id / run_id).resolve()
    if root not in result.parents or ".." in Path(run_id).parts:
        raise ScenarioError("resolved output escaped the selected output root")
    return result


def _godot_binary(explicit: str | None = None) -> str:
    configured = (explicit or os.environ.get("GODOT_BIN", "")).strip()
    if configured:
        resolved = shutil.which(configured) or configured
        if Path(resolved).is_file() or shutil.which(resolved):
            return resolved
        raise PreflightError(f"configured Godot executable does not exist: {configured}")
    discovered = shutil.which("godot")
    if discovered:
        return discovered
    raise PreflightError("Godot executable not found; set GODOT_BIN or --godot")


def _git_metadata() -> dict[str, Any]:
    def run(*args: str) -> str:
        completed = subprocess.run(
            ["git", *args],
            cwd=REPO_ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
        return completed.stdout.strip() if completed.returncode == 0 else ""

    return {
        "commit": run("rev-parse", "HEAD"),
        "branch": run("branch", "--show-current"),
        "dirty": bool(run("status", "--porcelain")),
        "changed_files": run("status", "--short").splitlines(),
    }


def _write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def _build_command(
    godot: str,
    scenario_path: Path,
    output_dir: Path,
    scenario: dict[str, Any],
    capture_mode: str,
) -> list[str]:
    command = [
        godot,
        "--path",
        str(CUSTODIAN_DIR),
        "--fixed-fps",
        "60",
    ]
    if capture_mode == "none":
        command.append("--headless")
    elif capture_mode == "full":
        raw_dir = output_dir / "raw"
        raw_dir.mkdir(parents=True, exist_ok=True)
        command.extend(["--write-movie", str(raw_dir / "capture.png")])
    command.extend(
        [
            "--script",
            "res://tools/iteration/godot/moment_runner.gd",
            "--",
            "--custodian-dev",
            "--observe",
            "--moment-forge",
            "--moment-scenario",
            str(scenario_path),
            "--moment-output",
            str(output_dir),
            "--moment-capture-mode",
            capture_mode,
        ]
    )
    return command


def _run_once(
    scenario: dict[str, Any],
    output_dir: Path,
    capture_mode: str,
    baseline: Path | None,
    godot: str,
    require_mp4: bool,
    require_synchronized_media: bool,
    keep_raw: bool,
    allow_incompatible_baseline: bool,
) -> tuple[int, dict[str, Any] | None]:
    output_dir.mkdir(parents=True, exist_ok=False)
    (output_dir / "logs").mkdir()
    snapshot = _scenario_snapshot(scenario)
    snapshot_path = output_dir / "scenario.snapshot.json"
    _write_json(snapshot_path, snapshot)
    _write_json(
        output_dir / "logs" / "command.json",
        {
            "capture_mode": capture_mode,
            "scenario_sha256": scenario_sha256(scenario),
            "repository": _git_metadata(),
        },
    )
    command = _build_command(godot, snapshot_path, output_dir, scenario, capture_mode)
    command_log = json.loads((output_dir / "logs" / "command.json").read_text(encoding="utf-8"))
    command_log["argv"] = command
    _write_json(output_dir / "logs" / "command.json", command_log)
    timeout = max(float(scenario["simulation"]["max_wall_seconds"]) + 10.0, 30.0)
    if capture_mode == "full":
        # Movie Maker writes one lossless PNG per rendered frame. Encoding can
        # be substantially slower than simulation on otherwise valid machines,
        # so supervise media capture separately from the authored runtime limit.
        timeout = max(timeout, float(scenario["duration_ticks"]) * 1.25)
    try:
        completed = subprocess.run(
            command,
            cwd=REPO_ROOT,
            check=False,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired as exc:
        stdout = exc.stdout or b""
        stderr = exc.stderr or b""
        if isinstance(stdout, bytes):
            stdout = stdout.decode("utf-8", errors="replace")
        if isinstance(stderr, bytes):
            stderr = stderr.decode("utf-8", errors="replace")
        (output_dir / "logs" / "godot.log").write_text(
            stdout + "\n" + stderr,
            encoding="utf-8",
        )
        _write_json(
            output_dir / "run_result.json",
            {"status": "failed_runtime", "reason": "process_timeout", "timeout_seconds": timeout},
        )
        return EXIT_RUNTIME, None
    (output_dir / "logs" / "godot.log").write_text(
        completed.stdout + ("\n" if completed.stdout and completed.stderr else "") + completed.stderr,
        encoding="utf-8",
    )
    runtime_result = {}
    result_path = output_dir / "run_result.json"
    if result_path.exists():
        runtime_result = json.loads(result_path.read_text(encoding="utf-8"))
    if completed.returncode != 0:
        return EXIT_RUNTIME, None
    try:
        manifest = build_report(
            output_dir,
            snapshot,
            REPO_ROOT,
            baseline,
            build_video=capture_mode == "full",
            require_mp4=require_mp4,
            require_synchronized_media=require_synchronized_media,
            allow_incompatible_baseline=allow_incompatible_baseline,
            keep_raw=keep_raw,
        )
    except BaselineCompatibilityError:
        return EXIT_BASELINE, None
    except (FileNotFoundError, OSError, ValueError, json.JSONDecodeError) as exc:
        (output_dir / "logs" / "report.log").write_text(str(exc) + "\n", encoding="utf-8")
        return EXIT_REPORT, None
    if not manifest.get("stable_assertions_passed", False):
        return EXIT_ASSERTIONS, manifest
    if require_mp4 and not manifest.get("artifacts", {}).get("video"):
        return EXIT_MEDIA, manifest
    if require_synchronized_media and manifest.get("capture", {}).get("synchronization") != "verified":
        return EXIT_MEDIA, manifest
    return EXIT_OK, manifest


def _resolve_baseline(path: Path | None) -> Path | None:
    if path is None:
        return None
    resolved = path.resolve()
    if resolved.is_file() and resolved.name == "manifest.json":
        resolved = resolved.parent
    if not (resolved / "manifest.json").is_file():
        raise ScenarioError(f"baseline does not contain manifest.json: {resolved}")
    return resolved


def _accept_baseline(
    scenario_id: str,
    source_run: Path,
    name: str,
    replace: bool,
    assume_yes: bool,
) -> Path:
    if not TAG_PATTERN.fullmatch(name.replace("-", "_")):
        raise ScenarioError("baseline name must be lowercase letters, numbers, underscores, or hyphens")
    manifest_path = source_run / "manifest.json"
    if not manifest_path.is_file():
        raise ScenarioError("cannot accept an incomplete run as a baseline")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if not manifest.get("stable_assertions_passed", False):
        raise ScenarioError("baseline source must pass stable assertions")
    destination = (BASELINE_ROOT / scenario_id / name).resolve()
    if destination.exists():
        if not replace:
            raise ScenarioError(f"baseline already exists: {destination}")
        if not assume_yes:
            response = input(f"Replace baseline {destination}? [y/N] ").strip().lower()
            if response not in {"y", "yes"}:
                raise ScenarioError("baseline replacement cancelled")
        shutil.rmtree(destination)
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(source_run, destination)
    _write_json(
        destination / "baseline_provenance.json",
        {
            "baseline_name": name,
            "accepted_at": datetime.now().astimezone().isoformat(),
            "source_run_id": source_run.name,
            "git": manifest.get("repository", {}),
        },
    )
    return destination


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("scenario", nargs="?", help="slash-delimited scenario ID")
    parser.add_argument("--list", action="store_true", help="list available moments")
    parser.add_argument("--tag", help="filter --list by tag")
    parser.add_argument("--json", action="store_true", help="emit machine-readable list/router output")
    parser.add_argument("--changed", action="store_true", help="suggest moments for changed files")
    parser.add_argument("--base", help="Git base for committed branch changes")
    parser.add_argument("--execute-suggested", action="store_true")
    parser.add_argument("--baseline", type=Path, help="baseline run, directory, or manifest")
    parser.add_argument("--allow-incompatible-baseline", action="store_true")
    parser.add_argument("--accept-baseline", metavar="NAME")
    parser.add_argument("--replace-baseline", action="store_true")
    parser.add_argument("--yes", action="store_true")
    parser.add_argument("--capture-mode", choices=("none", "evidence", "full"), default="full")
    parser.add_argument("--repeat", type=int, default=1)
    parser.add_argument("--require-identical-stable-fingerprint", action="store_true")
    parser.add_argument("--require-mp4", action="store_true")
    parser.add_argument("--require-synchronized-media", action="store_true")
    parser.add_argument("--keep-raw", action="store_true")
    parser.add_argument("--run-id", help="explicit run ID prefix")
    parser.add_argument("--output-root", type=Path, default=DEFAULT_OUTPUT_ROOT)
    parser.add_argument("--allow-external-output", action="store_true")
    parser.add_argument("--godot", help="Godot executable")
    return parser


def _list_payload(scenarios: Iterable[dict[str, Any]], tag: str | None) -> list[dict[str, Any]]:
    payload = []
    for scenario in scenarios:
        if tag and tag not in scenario["tags"]:
            continue
        baseline_parent = BASELINE_ROOT / scenario["id"]
        payload.append(
            {
                "id": scenario["id"],
                "description": scenario["description"],
                "duration_ticks": scenario["duration_ticks"],
                "duration_seconds": scenario["duration_ticks"] / 60.0,
                "scene": scenario["scene"],
                "tags": scenario["tags"],
                "baselines": sorted(
                    path.name for path in baseline_parent.iterdir() if path.is_dir()
                )
                if baseline_parent.is_dir()
                else [],
                "schema_valid": True,
            }
        )
    return payload


def _print_failure(scenario_id: str, stage: str, reason: str, run_dir: Path | None) -> None:
    print(f"Moment Forge failed: {scenario_id}", file=sys.stderr)
    print(f"stage: {stage}", file=sys.stderr)
    print(f"reason: {reason}", file=sys.stderr)
    if run_dir is not None:
        print(f"evidence retained: {run_dir}", file=sys.stderr)
        print(f"log: {run_dir / 'logs' / 'godot.log'}", file=sys.stderr)


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        scenarios = load_scenarios()
        if args.list:
            payload = _list_payload(scenarios.values(), args.tag)
            if args.json:
                print(json.dumps(payload, indent=2, sort_keys=True))
            else:
                for item in payload:
                    print(
                        f"{item['id']}: {item['description']} "
                        f"[{item['duration_ticks']} ticks; {', '.join(item['tags'])}]"
                    )
            return EXIT_OK
        if args.changed:
            files = changed_files(base=args.base)
            suggestions = suggest_scenarios(scenarios.values(), files)
            if args.json:
                print(json.dumps({"changed": files, "suggestions": suggestions}, indent=2))
            else:
                print("Changed:")
                for path in files:
                    print(f"- {path}")
                print("\nSuggested moments:")
                for index, suggestion in enumerate(suggestions, 1):
                    print(
                        f"{index}. {suggestion['id']} (score {suggestion['score']})\n"
                        f"   reason: {'; '.join(suggestion['reasons'])}\n"
                        f"   run: python3 custodian/tools/iteration/run_moment.py {suggestion['id']}"
                    )
                if not suggestions:
                    print("- none")
            if not args.execute_suggested:
                return EXIT_OK
            selected_ids = [item["id"] for item in suggestions]
            if not selected_ids:
                return EXIT_OK
        else:
            if not args.scenario:
                raise ScenarioError("provide a scenario ID, --list, or --changed")
            if args.scenario not in scenarios:
                raise ScenarioError(f"unknown scenario: {args.scenario}")
            selected_ids = [args.scenario]
        if args.repeat < 1 or args.repeat > 20:
            raise ScenarioError("--repeat must be between 1 and 20")
        baseline = _resolve_baseline(args.baseline)
        output_root = _resolve_output_root(args.output_root, args.allow_external_output)
        godot = _godot_binary(args.godot)
        overall = EXIT_OK
        for scenario_id in selected_ids:
            scenario = scenarios[scenario_id]
            fingerprints: list[str] = []
            run_dirs: list[Path] = []
            for repeat_index in range(args.repeat):
                base_run_id = args.run_id or datetime.now().astimezone().strftime("%Y%m%dT%H%M%S%z")
                run_id = (
                    f"{base_run_id}_r{repeat_index + 1}"
                    if args.repeat > 1
                    else base_run_id
                )
                output_dir = _output_dir_for(
                    scenario_id,
                    run_id,
                    output_root,
                    args.allow_external_output,
                )
                code, manifest = _run_once(
                    scenario,
                    output_dir,
                    args.capture_mode,
                    baseline,
                    godot,
                    args.require_mp4,
                    args.require_synchronized_media,
                    args.keep_raw,
                    args.allow_incompatible_baseline,
                )
                run_dirs.append(output_dir)
                if manifest:
                    fingerprint = (
                        manifest.get("stable_fingerprint", {}).get("value", "")
                    )
                    fingerprints.append(str(fingerprint))
                if code != EXIT_OK:
                    _print_failure(scenario_id, "run", f"exit {code}", output_dir)
                    overall = code
                    break
                print(f"Moment Forge output: {output_dir}")
                print(f"Review: {output_dir / 'index.html'}")
            if overall != EXIT_OK:
                break
            if args.require_identical_stable_fingerprint and (
                len(fingerprints) != args.repeat
                or len(set(fingerprints)) != 1
                or not fingerprints[0]
            ):
                _print_failure(
                    scenario_id,
                    "determinism",
                    "stable fingerprints differed",
                    run_dirs[-1] if run_dirs else None,
                )
                overall = EXIT_ASSERTIONS
                break
            if args.accept_baseline:
                accepted = _accept_baseline(
                    scenario_id,
                    run_dirs[-1],
                    args.accept_baseline,
                    args.replace_baseline,
                    args.yes,
                )
                print(f"Baseline accepted: {accepted}")
        return overall
    except ScenarioError as exc:
        print(f"Moment Forge schema/CLI error: {exc}", file=sys.stderr)
        return EXIT_SCHEMA
    except PreflightError as exc:
        print(f"Moment Forge preflight error: {exc}", file=sys.stderr)
        return EXIT_PREFLIGHT
    except KeyboardInterrupt:
        return 130
    except (json.JSONDecodeError, OSError, RuntimeError) as exc:
        print(f"Moment Forge error: {exc}", file=sys.stderr)
        return EXIT_PREFLIGHT


if __name__ == "__main__":
    raise SystemExit(main())
