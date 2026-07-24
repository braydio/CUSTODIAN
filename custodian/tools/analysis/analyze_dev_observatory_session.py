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
            data = _event_data(event)
            damage_this_life += _number(data.get("damage_applied", data.get("amount")))
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


def _ranged_failure_category(
    counters: Mapping[str, Any], category: str, reasons: Sequence[str]
) -> str:
    total = _count(counters, f"player_ranged_fire_failure_{category}")
    parts = [f"total={total}"]
    for reason in reasons:
        count = _count(counters, f"player_ranged_fire_failure_{reason}")
        if count:
            parts.append(f"{reason}={count}")
    return ", ".join(parts)


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


def _format_counter(values: Any) -> str:
    counter = _mapping(values)
    rows = [
        (str(key), _number(value))
        for key, value in counter.items()
        if _number(value) != 0.0
    ]
    rows.sort(key=lambda row: (-row[1], row[0]))
    if not rows:
        return "none"
    return ", ".join(f"{key}={_format_value(value)}" for key, value in rows)


def _heatmap_cell_location(
    key: str, entry: Mapping[str, Any], cell_size_px: float
) -> str:
    world = _mapping(entry.get("world"))
    try:
        cell_x_text, cell_y_text = key.split(",", maxsplit=1)
        cell_x = int(cell_x_text)
        cell_y = int(cell_y_text)
    except (TypeError, ValueError):
        cell_x = 0
        cell_y = 0
    origin_x = _number(world.get("x"), cell_x * cell_size_px)
    origin_y = _number(world.get("y"), cell_y * cell_size_px)
    end_x = origin_x + cell_size_px
    end_y = origin_y + cell_size_px
    return (
        f"world=({_format_value(origin_x)},{_format_value(origin_y)}) "
        f"bounds=({_format_value(origin_x)},{_format_value(origin_y)})"
        f"-({_format_value(end_x)},{_format_value(end_y)})"
    )


def _append_heatmap_section(
    lines: list[str], payload: Mapping[str, Any], top: int
) -> None:
    heatmap = _mapping(payload.get("heatmap"))
    lines.extend(["", "HEATMAP", "-" * 48])
    if not heatmap:
        lines.append("  none")
        return

    lines.append(f"  {'cells':<28} {int(_number(heatmap.get('cell_count')))}")
    lines.append(f"  {'samples':<28} {int(_number(heatmap.get('total_samples')))}")
    lines.append(
        f"  {'event types':<28} "
        f"{_format_counter(heatmap.get('event_type_counts'))}"
    )
    cell_size_px = max(1.0, _number(heatmap.get("cell_size_px"), 64.0))

    cells = _mapping(heatmap.get("cells"))
    ranked: list[tuple[float, str, Mapping[str, Any]]] = []
    danger: list[tuple[float, str, Mapping[str, Any]]] = []
    combat: list[tuple[float, str, Mapping[str, Any]]] = []
    for key, raw_entry in cells.items():
        entry = _mapping(raw_entry)
        if not entry:
            continue
        by_type = _mapping(entry.get("by_type"))
        total = _number(entry.get("total"))
        ranked.append((total, str(key), entry))

        danger_score = (
            _number(by_type.get("player_death")) * 10.0
            + _number(by_type.get("damage_taken"))
        )
        if danger_score > 0.0:
            danger.append((danger_score, str(key), entry))

        combat_score = sum(
            _number(by_type.get(name))
            for name in ("shot_fired", "enemy_killed", "enemy_attack_hit")
        )
        if combat_score > 0.0:
            combat.append((combat_score, str(key), entry))

    ranked.sort(key=lambda row: (-row[0], row[1]))
    danger.sort(key=lambda row: (-row[0], row[1]))
    combat.sort(key=lambda row: (-row[0], row[1]))

    lines.extend(["", "  Top heat cells"])
    if not ranked:
        lines.append("    none")
    for total, key, entry in ranked[:top]:
        lines.append(
            f"    {key:<12} {_heatmap_cell_location(key, entry, cell_size_px)} "
            f"total={total:<8.2f} "
            f"by_type={_format_counter(entry.get('by_type'))}"
        )

    lines.extend(["", "  Danger cells"])
    if not danger:
        lines.append("    none")
    for score, key, entry in danger[:top]:
        lines.append(
            f"    {key:<12} {_heatmap_cell_location(key, entry, cell_size_px)} "
            f"danger={score:<8.2f} "
            f"by_type={_format_counter(entry.get('by_type'))}"
        )

    lines.extend(["", "  Combat cells"])
    if not combat:
        lines.append("    none")
    for score, key, entry in combat[:top]:
        lines.append(
            f"    {key:<12} {_heatmap_cell_location(key, entry, cell_size_px)} "
            f"combat={score:<8.2f} "
            f"by_type={_format_counter(entry.get('by_type'))}"
        )


def _append_material_intelligence_section(
    lines: list[str],
    payload: Mapping[str, Any],
    events: Sequence[Mapping[str, Any]],
    gauges: Mapping[str, Any],
) -> None:
    snapshot = _mapping(payload.get("material_intelligence"))
    material_events = [
        event
        for event in events
        if str(event.get("kind", "")) == "material_contact"
    ]
    contacts_by_material: Counter[str] = Counter()
    contacts_by_kind: Counter[str] = Counter()
    for event in material_events:
        data = _event_data(event)
        contacts_by_material[str(data.get("material_id", "unknown"))] += 1
        contacts_by_kind[str(data.get("contact_kind", "unknown"))] += 1

    lines.extend(["", "MATERIAL INTELLIGENCE", "-" * 48])
    if not snapshot and not material_events and "player_material" not in gauges:
        lines.append("  none")
        return
    lines.append(
        f"  {'override cells':<28} "
        f"{int(_number(snapshot.get('override_cell_count')))}"
    )
    lines.append(
        f"  {'total contacts':<28} "
        f"{int(_number(snapshot.get('total_contacts'), len(material_events)))}"
    )
    lines.append(
        f"  {'material cells':<28} "
        f"{_format_counter(snapshot.get('material_counts'))}"
    )
    lines.append(
        f"  {'current player material':<28} "
        f"{_format_value(gauges.get('player_material', 'unknown'))}"
    )
    lines.append(
        f"  {'retained contact events':<28} {len(material_events)}"
    )
    lines.append(
        f"  {'retained contacts/material':<28} "
        f"{_format_counter(contacts_by_material)}"
    )
    lines.append(
        f"  {'retained contacts/kind':<28} "
        f"{_format_counter(contacts_by_kind)}"
    )


def _overheat_failure_summary(
    events: Sequence[Mapping[str, Any]],
) -> dict[str, Any]:
    failures = [
        event
        for event in events
        if str(event.get("kind", "")) == "player_ranged_fire_failed"
        and str(_event_data(event).get("reason", "")) == "overheated"
    ]
    heat_values = [
        _number(_event_data(event).get("heat"))
        for event in failures
        if isinstance(_event_data(event).get("heat"), (int, float))
    ]
    longest_streak = 0
    current_streak = 0
    for event in events:
        if str(event.get("kind", "")) != "player_ranged_fire_failed":
            continue
        if str(_event_data(event).get("reason", "")) == "overheated":
            current_streak += 1
            longest_streak = max(longest_streak, current_streak)
        else:
            current_streak = 0
    first_time = (
        _number(failures[0].get("uptime_sec"))
        if failures
        else None
    )
    return {
        "retained_count": len(failures),
        "average_heat": sum(heat_values) / len(heat_values) if heat_values else None,
        "max_heat": max(heat_values) if heat_values else None,
        "first_time_sec": first_time,
        "longest_streak": longest_streak,
    }


def build_report(
    payload: Mapping[str, Any],
    source: Path,
    top: int,
    warning_limit: int,
    show_all: bool = False,
    heatmap_top: int | None = None,
) -> str:
    session = _mapping(payload.get("session"))
    scene = _mapping(payload.get("scene"))
    metadata = _mapping(payload.get("metadata"))
    counters = _mapping(payload.get("counters"))
    gauges = _mapping(payload.get("gauges"))
    events = _records(payload.get("events"))
    warnings = _records(payload.get("warnings"))
    kinds = _event_kinds(events)
    overheat_summary = _overheat_failure_summary(events)
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
        _number(_event_data(event).get("damage_applied", _event_data(event).get("amount")))
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
        ("cumulative damage amount", _format_value(_number(counters.get("player_damage_amount_total")))),
        ("retained-event damage", _format_value(total_damage)),
        ("cumulative chip damage", _format_value(_number(counters.get("player_chip_damage_amount_total")))),
        ("cumulative healing amount", _format_value(_number(counters.get("player_healing_amount_total")))),
        ("ranged shots fired", _count(counters, "player_ranged_shots_fired", kinds["player_ranged_shot"])),
        ("blocked muzzle shots", _count(counters, "player_ranged_shots_blocked", kinds["player_ranged_shot_blocked"])),
        ("ranged fire failures", _count(counters, "player_ranged_fire_failures", kinds["player_ranged_fire_failed"])),
        ("ranged empty failures", _ranged_failure_category(counters, "empty", ["empty_magazine", "no_reserve_ammo", "no_ammo"])),
        ("ranged state failures", _ranged_failure_category(counters, "state_locked", ["reloading", "overheated", "action_locked", "sidearm_not_held"])),
        ("ranged internal failures", _ranged_failure_category(counters, "internal", ["invalid_profile", "projectile_spawn_failed"])),
        ("ranged cancellations", _prefixed_counts(counters, "player_ranged_request_cancelled_")),
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
        lines.append(f"  {'retained damage before deaths':<28} {formatted}")
        if event_buffer_saturated or legacy_buffer_may_be_saturated:
            lines.append("  NOTE: retained damage-before-death values exclude damage dropped from the event ring.")
    lines.append("  NOTE: incoming hit results exclude whiffs; terminal outcomes include them.")
    lines.append("  NOTE: retained event/unique-ID totals are tail-window values; cumulative counters may be larger.")

    ranged_requests = _count(counters, "player_ranged_fire_requests")
    ranged_fired = _count(counters, "player_ranged_request_fired", _count(counters, "player_ranged_shots_fired"))
    ranged_blocked = _count(counters, "player_ranged_request_muzzle_blocked", _count(counters, "player_ranged_shots_blocked"))
    ranged_failed = _count(counters, "player_ranged_request_failed", _count(counters, "player_ranged_fire_failures"))
    ranged_cancelled = _count(counters, "player_ranged_request_cancelled")
    ranged_pending = int(_number(gauges.get("player_ranged_requests_pending")))
    ranged_terminal = ranged_fired + ranged_blocked + ranged_failed + ranged_cancelled
    ranged_unaccounted = ranged_requests - ranged_terminal - ranged_pending
    lines.extend([
        "",
        "RANGED REQUEST RECONCILIATION",
        f"  {'requests':<28} {ranged_requests}",
        f"  {'fired':<28} {ranged_fired}",
        f"  {'muzzle blocked':<28} {ranged_blocked}",
        f"  {'failed':<28} {ranged_failed}",
        f"  {'cancelled':<28} {ranged_cancelled}",
        f"  {'pending':<28} {ranged_pending}",
        f"  {'unaccounted':<28} {ranged_unaccounted}{'  <-- defect' if ranged_unaccounted else ''}",
    ])
    overheat_failures = _count(
        counters,
        "player_ranged_fire_failure_overheated",
        int(overheat_summary["retained_count"]),
    )
    average_heat_text = (
        _format_value(overheat_summary["average_heat"])
        if overheat_summary["average_heat"] is not None
        else "unavailable (not retained)"
    )
    maximum_heat_text = (
        _format_value(overheat_summary["max_heat"])
        if overheat_summary["max_heat"] is not None
        else "unavailable (not retained)"
    )
    first_overheat_text = (
        f"{_format_value(overheat_summary['first_time_sec'])}s"
        if overheat_summary["first_time_sec"] is not None
        else "unavailable (not retained)"
    )
    lines.extend([
        "",
        "RANGED OVERHEAT DIAGNOSTICS",
        f"  {'cumulative failures':<28} {overheat_failures}",
        f"  {'retained detailed failures':<28} {overheat_summary['retained_count']}",
        f"  {'average heat at failure':<28} {average_heat_text}",
        f"  {'maximum heat at failure':<28} {maximum_heat_text}",
        f"  {'first retained overheat':<28} {first_overheat_text}",
        f"  {'longest retained streak':<28} {overheat_summary['longest_streak']}",
    ])
    if bool(gauges.get("player_dead", False)):
        lines.append("")
        lines.append("NOTE: player was dead at export; current resource gauges reflect post-death state.")
        lines.append(
            "  last live resources: weapon=%s, loaded=%s, reserve=%s, stamina=%s"
            % (
                _format_value(gauges.get("player_last_live_weapon_id", "")),
                _format_value(gauges.get("player_last_live_loaded_ammo", 0)),
                _format_value(gauges.get("player_last_live_reserve_ammo", 0)),
                _format_value(gauges.get("player_last_live_stamina", 0)),
            )
        )

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

    _append_material_intelligence_section(lines, payload, events, gauges)
    _append_heatmap_section(
        lines,
        payload,
        heatmap_top if heatmap_top is not None else top,
    )

    signal_flags: list[str] = []
    if event_buffer_saturated:
        signal_flags.append(
            f"Event buffer wrapped: {dropped_event_count} events dropped "
            f"after {total_events_logged} logged."
        )
    if kinds and event_count > 0:
        top_kind, top_count = kinds.most_common(1)[0]
        top_share = top_count / event_count
        if top_share >= 0.5:
            signal_flags.append(
                f"Retained events are dominated by {top_kind}: "
                f"{top_count}/{event_count} ({top_share:.1%})."
            )
    cumulative_damage = _number(counters.get("player_damage_amount_total"))
    if (cumulative_damage > 0.0 or deaths > 0) and incoming_results_total == 0:
        signal_flags.append(
            "Player damage/death exists, but incoming hit telemetry is zero."
        )
    enemy_attacks_resolved = _count(counters, "enemy_attacks_resolved")
    enemy_attack_whiffs = _count(counters, "enemy_attack_whiffs")
    if deaths > 0 and enemy_attacks_resolved + enemy_attack_whiffs == 0:
        signal_flags.append(
            "Player death exists, but enemy terminal attack telemetry is zero."
        )
    if ranged_failed > 0 and overheat_failures / ranged_failed >= 0.5:
        signal_flags.append(
            f"Overheat dominates ranged failures: "
            f"{overheat_failures}/{ranged_failed} "
            f"({overheat_failures / ranged_failed:.1%})."
        )
    dodges_started = _count(
        counters, "player_dodges_started", kinds["player_dodge_started"]
    )
    iframe_avoids = _count(
        counters,
        "player_iframe_avoids",
        kinds["player_damage_avoided_by_iframe"],
    )
    if dodges_started > 0 and iframe_avoids == 0:
        signal_flags.append(
            "Dodges were recorded, but no iframe avoids were observed."
        )

    lines.extend(["", "SIGNAL QUALITY FLAGS", "-" * 48])
    if signal_flags:
        lines.extend(f"  - {flag}" for flag in signal_flags)
    else:
        lines.append("  none")

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
        "--heatmap-top",
        type=int,
        default=DEFAULT_TOP,
        help=f"maximum rows in each heatmap ranking (default: {DEFAULT_TOP})",
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
    if args.heatmap_top < 1:
        parser.error("--heatmap-top must be at least 1")
    return args


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        path = resolve_session_path(args.session)
        payload = load_session(path)
    except SessionError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    report = build_report(
        payload,
        path,
        args.top,
        args.warnings,
        show_all=args.all,
        heatmap_top=args.heatmap_top,
    )

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
