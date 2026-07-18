#!/usr/bin/env python3
"""Print a compact report from a CUSTODIAN Developer Observatory export."""

from __future__ import annotations

import argparse
import json
import os
import sys
from collections import Counter
from pathlib import Path
from typing import Any, Iterable, Mapping, Sequence


EXPECTED_SCHEMA = "custodian.dev_observatory.session.v1"
DEFAULT_TOP = 12
DEFAULT_WARNING_LIMIT = 5


class SessionError(Exception):
    """Raised when an Observatory session cannot be loaded safely."""


def _default_session_candidates() -> list[Path]:
    candidates: list[Path] = []
    xdg_data_home = os.environ.get("XDG_DATA_HOME")
    if xdg_data_home:
        candidates.append(
            Path(xdg_data_home)
            / "godot/app_userdata/CUSTODIAN/dev_observatory/latest_session.json"
        )
    candidates.extend(
        [
            Path.home()
            / ".local/share/godot/app_userdata/CUSTODIAN/dev_observatory/latest_session.json",
            Path.home()
            / "Library/Application Support/Godot/app_userdata/CUSTODIAN/dev_observatory/latest_session.json",
        ]
    )
    appdata = os.environ.get("APPDATA")
    if appdata:
        candidates.append(
            Path(appdata)
            / "Godot/app_userdata/CUSTODIAN/dev_observatory/latest_session.json"
        )
    return candidates


def resolve_session_path(raw_path: str | None) -> Path:
    if raw_path:
        path = Path(raw_path).expanduser()
        if not path.is_file():
            raise SessionError(f"session file does not exist: {path}")
        return path

    for candidate in _default_session_candidates():
        if candidate.is_file():
            return candidate
    raise SessionError(
        "no session path supplied and latest_session.json was not found in the "
        "standard Godot user-data locations"
    )


def load_session(path: Path) -> dict[str, Any]:
    try:
        with path.open("r", encoding="utf-8") as handle:
            payload = json.load(handle)
    except OSError as exc:
        raise SessionError(f"could not read {path}: {exc}") from exc
    except json.JSONDecodeError as exc:
        raise SessionError(
            f"invalid JSON in {path} at line {exc.lineno}, column {exc.colno}: {exc.msg}"
        ) from exc

    if not isinstance(payload, dict):
        raise SessionError("session root must be a JSON object")
    return payload


def _mapping(value: Any) -> Mapping[str, Any]:
    return value if isinstance(value, Mapping) else {}


def _records(value: Any) -> list[Mapping[str, Any]]:
    if not isinstance(value, Sequence) or isinstance(value, (str, bytes)):
        return []
    return [entry for entry in value if isinstance(entry, Mapping)]


def _number(value: Any, default: float = 0.0) -> float:
    if isinstance(value, bool):
        return default
    if isinstance(value, (int, float)):
        return float(value)
    return default


def _count(counters: Mapping[str, Any], name: str, fallback: int = 0) -> int:
    value = counters.get(name)
    if isinstance(value, bool):
        return fallback
    if isinstance(value, (int, float)):
        return int(value)
    return fallback


def _event_kinds(events: Iterable[Mapping[str, Any]]) -> Counter[str]:
    return Counter(str(event.get("kind", "unknown")) for event in events)


def _event_data(event: Mapping[str, Any]) -> Mapping[str, Any]:
    return _mapping(event.get("data"))


def _attack_id(event: Mapping[str, Any]) -> str:
    return str(_event_data(event).get("attack_id", "")).strip()


def _enemy_attack_summary(events: Sequence[Mapping[str, Any]]) -> tuple[Counter[str], Counter[str], Counter[str]]:
    """Derive mutually exclusive terminal outcomes and lifecycle counts by attack_id."""
    started_ids: set[str] = set()
    active_ids: set[str] = set()
    terminal_by_id: dict[str, str] = {}
    interruption_by_id: dict[str, str] = {}
    for event in events:
        kind = str(event.get("kind", ""))
        data = _event_data(event)
        attack_id = _attack_id(event)
        if not attack_id:
            continue
        if kind in {"enemy_attack_windup", "grunt_falcon_punch_windup"}:
            started_ids.add(attack_id)
        if kind in {"enemy_attack_active", "grunt_falcon_punch_active", "grunt_falcon_punch_leap"}:
            active_ids.add(attack_id)
        if kind not in {
            "enemy_attack_resolved",
            "enemy_attack_whiff",
            "enemy_attack_cancelled",
            "grunt_falcon_punch_hit_resolved",
        }:
            continue
        result = str(data.get("result", "")).strip().lower()
        reason = str(data.get("reason", "")).strip().lower()
        if kind == "enemy_attack_whiff" or result in {
            "target_out_of_range", "target_out_of_arc", "blocked_by_collision"
        }:
            result = "whiffed"
        elif result == "interrupted":
            if reason == "death":
                result = "cancelled_by_death"
            elif reason == "parry":
                result = "parried"
        if result:
            terminal_by_id[attack_id] = result
        if reason == "parry" or result == "parried":
            interruption_by_id[attack_id] = "interrupted_by_parry"
        elif reason in {"hit", "damaged", "staggered_by_hit"}:
            interruption_by_id[attack_id] = "interrupted_by_hit"
        elif reason in {"no_target", "target_not_node2d", "target_loss"}:
            interruption_by_id[attack_id] = "interrupted_by_target_loss"

    outcomes = Counter(terminal_by_id.values())
    interruptions = Counter(interruption_by_id.values())
    lifecycle = Counter(
        started=len(started_ids), active=len(active_ids), terminal=len(terminal_by_id)
    )
    return outcomes, interruptions, lifecycle


def _ordered_counts(values: Mapping[str, int], names: Sequence[str]) -> str:
    parts = [f"{name}={int(values.get(name, 0))}" for name in names]
    extras = sorted(name for name in values if name not in names and values[name])
    parts.extend(f"{name}={int(values[name])}" for name in extras)
    return ", ".join(parts)


def _damage_before_deaths(events: Sequence[Mapping[str, Any]]) -> list[float]:
    damage_this_life = 0.0
    totals: list[float] = []
    for event in events:
        kind = str(event.get("kind", ""))
        if kind == "player_damage":
            damage_this_life += _number(_event_data(event).get("amount"))
        elif kind == "player_death":
            totals.append(damage_this_life)
            damage_this_life = 0.0
    return totals


def _prefixed_counts(counters: Mapping[str, Any], prefix: str) -> str:
    values: list[str] = []
    for key, value in sorted(counters.items(), key=lambda item: str(item[0])):
        name = str(key)
        if not name.startswith(prefix):
            continue
        count = _count(counters, name)
        if count:
            values.append(f"{name.removeprefix(prefix)}={count}")
    return ", ".join(values) if values else "none"


def _format_duration(seconds: float) -> str:
    seconds = max(0.0, seconds)
    minutes, remainder = divmod(int(seconds), 60)
    hours, minutes = divmod(minutes, 60)
    if hours:
        return f"{hours:d}h {minutes:02d}m {remainder:02d}s"
    return f"{minutes:d}m {remainder:02d}s"


def _format_value(value: Any, max_length: int = 88) -> str:
    if isinstance(value, float):
        text = f"{value:.3f}".rstrip("0").rstrip(".")
    elif isinstance(value, (dict, list)):
        text = json.dumps(value, sort_keys=True, separators=(",", ":"))
    else:
        text = str(value)
    if len(text) > max_length:
        return text[: max_length - 3] + "..."
    return text


def _append_key_values(
    lines: list[str], values: Mapping[str, Any], limit: int, *, nonzero_only: bool
) -> None:
    entries = []
    for key, value in values.items():
        if nonzero_only and isinstance(value, (int, float)) and not isinstance(value, bool):
            if value == 0:
                continue
        entries.append((str(key), value))
    entries.sort(key=lambda item: item[0])
    for key, value in entries[:limit]:
        lines.append(f"  {key:<36} {_format_value(value)}")
    remaining = len(entries) - limit
    if remaining > 0:
        lines.append(f"  ... {remaining} more")


def build_report(
    payload: Mapping[str, Any],
    source: Path,
    top: int,
    warning_limit: int,
    show_all: bool = False,
) -> str:
    session = _mapping(payload.get("session"))
    scene = _mapping(payload.get("scene"))
    metadata = _mapping(payload.get("metadata"))
    counters = _mapping(payload.get("counters"))
    gauges = _mapping(payload.get("gauges"))
    events = _records(payload.get("events"))
    warnings = _records(payload.get("warnings"))
    kinds = _event_kinds(events)
    attack_outcomes, attack_interruptions, attack_lifecycle = _enemy_attack_summary(events)
    if show_all:
        top = max(top, len(kinds), len(counters), len(gauges), len(events))

    event_count = int(_number(session.get("event_count"), len(events)))
    has_buffer_accounting = "event_capacity" in session or "dropped_event_count" in session
    event_capacity = int(_number(session.get("event_capacity"), 300))
    total_events_logged = int(_number(session.get("total_events_logged"), event_count))
    dropped_event_count = int(_number(session.get("dropped_event_count"), 0))
    event_buffer_saturated = bool(session.get("event_buffer_saturated", dropped_event_count > 0))
    legacy_buffer_may_be_saturated = (
        not has_buffer_accounting and event_capacity > 0 and event_count >= event_capacity
    )
    warning_count = int(_number(session.get("warning_count"), len(warnings)))
    uptime = _number(session.get("uptime_sec"))
    schema = str(payload.get("schema", "missing"))
    scene_name = str(scene.get("name", "unknown") or "unknown")
    scene_path = str(scene.get("path", "") or "")
    project_name = str(metadata.get("project_name", "CUSTODIAN") or "CUSTODIAN")

    deaths = _count(counters, "player_deaths", kinds["player_death"])
    damage_events = kinds["player_damage"]
    total_damage = sum(
        _number(_event_data(event).get("amount"))
        for event in events
        if str(event.get("kind", "")) == "player_damage"
    )
    damage_before_deaths = _damage_before_deaths(events)

    terminal_event_kinds = {
        "enemy_attack_resolved",
        "enemy_attack_whiff",
        "enemy_attack_cancelled",
        "grunt_falcon_punch_hit_resolved",
    }
    terminal_events_total = sum(
        1 for event in events if str(event.get("kind", "")) in terminal_event_kinds
    )
    terminal_unique_ids = int(attack_lifecycle.get("terminal", 0))
    incoming_result_counts = {
        name: _count(counters, f"incoming_hit_{name}")
        for name in ["damaged", "blocked", "parried", "dodged"]
    }
    incoming_results_total = _count(
        counters, "incoming_hits_total", sum(incoming_result_counts.values())
    )
    whiff_terminal_total = _count(
        counters, "enemy_attack_result_whiffed", int(attack_outcomes.get("whiffed", 0))
    )

    signals = [
        ("player deaths", deaths),
        ("damage events", damage_events),
        ("damage observed", _format_value(total_damage)),
        ("ranged shots fired", _count(counters, "player_ranged_shots_fired", kinds["player_ranged_shot"])),
        ("blocked muzzle shots", _count(counters, "player_ranged_shots_blocked", kinds["player_ranged_shot_blocked"])),
        ("ranged fire failures", _count(counters, "player_ranged_fire_failures", kinds["player_ranged_fire_failed"])),
        ("ranged empty failures", _prefixed_counts(counters, "player_ranged_fire_failure_empty_")),
        ("ranged state failures", _prefixed_counts(counters, "player_ranged_fire_failure_state_locked_")),
        ("ranged internal failures", _prefixed_counts(counters, "player_ranged_fire_failure_internal_")),
        ("dodges started", _count(counters, "player_dodges_started", kinds["player_dodge_started"])),
        ("iframe avoids", _count(counters, "player_iframe_avoids", kinds["player_damage_avoided_by_iframe"])),
        ("field patches committed", _count(counters, "field_patch_committed", kinds["field_patch_committed"])),
        ("field patches cancelled", _count(counters, "field_patch_cancelled", kinds["field_patch_cancelled"])),
        ("enemy attacks resolved", _count(counters, "enemy_attacks_resolved", kinds["enemy_attack_resolved"])),
        ("terminal events retained", terminal_events_total),
        ("terminal unique IDs retained", terminal_unique_ids),
        ("incoming hit results total", incoming_results_total),
        ("whiff terminals total", whiff_terminal_total),
        ("enemy attack whiffs", _count(counters, "enemy_attack_whiffs", kinds["enemy_attack_whiff"])),
        ("incoming hit results", _ordered_counts(incoming_result_counts, ["damaged", "blocked", "parried", "dodged"])),
        ("falcon punch attempts", _count(counters, "falcon_punch_attempts", kinds["grunt_falcon_punch_windup"])),
        ("falcon punch hits", _count(counters, "falcon_punch_hits")),
        ("falcon punch parried", _count(counters, "falcon_punch_parried")),
        ("falcon punch whiffed", _count(counters, "falcon_punch_whiffed")),
        ("falcon punch cancelled", _count(counters, "falcon_punch_cancelled")),
        ("falcon punch results", _prefixed_counts(counters, "falcon_punch_result_")),
        ("enemies destroyed", _count(counters, "enemies_destroyed", kinds["enemy_killed"])),
    ]

    lines = [
        f"{project_name} DEV OBSERVATORY PLAYTEST REPORT",
        "=" * 44,
        f"Source:   {source}",
        f"Schema:   {schema}",
        f"Exported: {payload.get('exported_at', 'unknown')}",
        f"Scene:    {scene_name}{f' ({scene_path})' if scene_path else ''}",
        f"Uptime:   {_format_duration(uptime)}",
        f"Captured: {event_count} events | {warning_count} warnings | "
        f"{len(counters)} counters | {len(gauges)} gauges",
    ]
    if event_buffer_saturated:
        lines.append(
            f"NOTE: event buffer wrapped; showing the final {event_count}/{event_capacity} events "
            f"({total_events_logged} logged, {dropped_event_count} dropped). Counters remain cumulative."
        )
    elif legacy_buffer_may_be_saturated:
        lines.append(
            f"NOTE: legacy export filled the {event_capacity}-event buffer; this is only the final "
            "retained window if wrapping occurred. Total/dropped counts are unavailable; counters remain cumulative."
        )
    if schema != EXPECTED_SCHEMA:
        lines.append(f"NOTE: expected schema {EXPECTED_SCHEMA}; reporting known fields only.")

    lines.extend(["", "PLAYTEST SIGNALS"])
    for label, value in signals:
        lines.append(f"  {label:<28} {value}")
    if damage_before_deaths:
        formatted = ", ".join(_format_value(value) for value in damage_before_deaths)
        lines.append(f"  {'damage observed before deaths':<28} {formatted}")
    lines.append("  NOTE: incoming hit results exclude whiffs; terminal outcomes include them.")
    lines.append("  NOTE: retained event/unique-ID totals are tail-window values; cumulative counters may be larger.")

    lines.extend([
        "",
        "ENEMY ATTACK TERMINAL OUTCOMES (UNIQUE ATTACK IDs IN RETAINED EVENTS)",
        "  " + _ordered_counts(
            attack_outcomes,
            ["damaged", "blocked", "parried", "whiffed", "cancelled_by_death"],
        ),
        "",
        "ENEMY ATTACK INTERRUPTION CAUSES (UNIQUE ATTACK IDs IN RETAINED EVENTS)",
        "  " + _ordered_counts(
            attack_interruptions,
            ["interrupted_by_parry", "interrupted_by_hit", "interrupted_by_target_loss"],
        ),
        "",
        "ENEMY ATTACK LIFECYCLE (UNIQUE ATTACK IDs IN RETAINED EVENTS)",
        "  " + _ordered_counts(attack_lifecycle, ["started", "active", "terminal"]),
    ])

    lines.extend(["", f"TOP EVENT TYPES ({min(top, len(kinds))})"])
    if kinds:
        for kind, count in kinds.most_common(top):
            lines.append(f"  {kind:<36} {count}")
    else:
        lines.append("  none")

    displayed_warning_count = min(len(warnings), warning_limit)
    lines.extend(["", f"WARNINGS ({warning_count} total, {displayed_warning_count} displayed)"])
    if warnings:
        for warning in warnings[-warning_limit:]:
            uptime_text = _format_value(warning.get("uptime_sec", "?"))
            message = _format_value(warning.get("message", "warning"), 110)
            lines.append(f"  [{uptime_text}s] {message}")
        hidden_warning_count = max(0, len(warnings) - displayed_warning_count)
        if hidden_warning_count:
            lines.append(f"  ... {hidden_warning_count} earlier warning(s) omitted; use --warnings to show more")
        unavailable_warning_count = max(0, warning_count - len(warnings))
        if unavailable_warning_count:
            lines.append(f"  ... {unavailable_warning_count} warning(s) counted by the session but absent from the export list")
    else:
        lines.append("  none")

    lines.extend(["", "NONZERO COUNTERS"])
    if counters:
        _append_key_values(lines, counters, top, nonzero_only=True)
    else:
        lines.append("  none")

    lines.extend(["", "GAUGES"])
    if gauges:
        _append_key_values(lines, gauges, top, nonzero_only=False)
    else:
        lines.append("  none")

    return "\n".join(lines)


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Print a compact report from a Developer Observatory JSON export."
    )
    parser.add_argument(
        "session",
        nargs="?",
        help="exported session JSON; defaults to latest_session.json in Godot user data",
    )
    parser.add_argument(
        "--top",
        type=int,
        default=DEFAULT_TOP,
        help=f"maximum event, counter, and gauge rows (default: {DEFAULT_TOP})",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="show all events, counters, and gauges without truncation",
    )
    parser.add_argument(
        "--warnings",
        type=int,
        default=DEFAULT_WARNING_LIMIT,
        help=f"maximum recent warnings (default: {DEFAULT_WARNING_LIMIT})",
    )
    parser.add_argument(
        "-o", "--output",
        type=str,
        default=None,
        help="save report to this file instead of printing to stdout",
    )
    args = parser.parse_args(argv)
    if args.top < 1:
        parser.error("--top must be at least 1")
    if args.warnings < 1:
        parser.error("--warnings must be at least 1")
    return args


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        path = resolve_session_path(args.session)
        payload = load_session(path)
    except SessionError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    report = build_report(payload, path, args.top, args.warnings, show_all=args.all)

    if args.output:
        out = Path(args.output)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(report + "\n", encoding="utf-8")
        print(f"report saved to {out}")
    else:
        print(report)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
