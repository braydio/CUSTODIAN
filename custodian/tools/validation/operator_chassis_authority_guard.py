#!/usr/bin/env python3
"""Fail-closed structural ownership guard for the Operator chassis.

The guard measures the live GDScript source, records exact field and method
ownership evidence, prevents new actor-local state and method growth, and
rejects foreign-body movement.  ``workstream.py`` also invokes it directly
before an Operator-touching finish, independently of changed-file test
selection.
"""

from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import importlib.util
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[3]
CUSTODIAN_ROOT = REPO_ROOT / "custodian"
OPERATOR_ROOT = CUSTODIAN_ROOT / "game/actors/operator"
SOURCE_REL = "custodian/game/actors/operator/operator.gd"
BUDGET_REL = "custodian/tools/validation/operator_chassis_authority_budget.json"
MANIFEST_REL = "custodian/tools/validation/validation_manifest.json"
WORKSTREAM_REL = "custodian/tools/agent/workstream.py"
GUARD_TEST_ID = "operator_chassis_authority_guard"
REUSED_AUDITS = (
    ("custodian/tools/validation/operator_architecture_debt_audit.py", ("--json",)),
    ("custodian/tools/validation/operator_runtime_path_audit.py", ()),
    ("custodian/tools/validation/operator_runtime_animation_authority_smoke.py", ()),
)
PINNED_BUDGET_SHA256 = "58693a15f557909a6f3eed91ca2b63253d79d983597db595ffd37f4e8cf18db9"

# These bootstrap ceilings are the source measurements at the first sealed
# revision. Later revisions must ratchet each ceiling downward; the budget is
# additionally compared with the exact base revision by the normal finish gate.
BOOTSTRAP_LIMITS = {
    "source_lines": 14792,
    "top_level_fields": 577,
    "top_level_functions": 742,
    "max_method_code_lines": 214,
    "max_method_branches": 61,
}

DOMAIN_RULES: tuple[tuple[str, tuple[str, ...]], ...] = (
    ("pre_f2_melee", ("melee", "attack", "swing", "combo", "unarmed", "riposte", "impact", "hit_target", "vigil", "initiative", "block", "parry", "paired_execution", "counter", "fast_chain", "terminal", "hitbox", "combat_target", "engagement", "guard")),
    ("pre_f3_ranged", ("ranged", "ammo", "reload", "muzzle", "projectile", "weapon", "heat", "fire_cooldown", "sidearm", "magazine", "loadout_mode")),
    ("pre_f5_interaction", ("interact", "interaction", "repair", "build", "resource", "pickup", "construction")),
    ("pre_f6_survivability", ("health", "damage", "field_patch", "death", "recovery", "stun", "knockdown", "integrity", "invulner", "armor", "unstuck", "hit_stop", "hitstop", "stabilization")),
    ("chassis_integration", ("velocity", "movement", "motion", "deceleration", "physics", "collision", "position", "facing", "direction", "speed", "stamina", "sprint", "dodge", "aim", "input", "stealth", "sneak", "noise")),
    ("presentation_bridge", ("sprite", "animation", "frame", "pose", "visual", "vfx", "sfx", "sound", "color", "modulate", "recoil", "shake", "flash", "debug_draw", "fake_elevation", "idle_loop", "idle_long_loop", "placeholder", "world_z", "target_ring", "vista", "barrel", "portal_transition")),
)


def mask_non_code(source: str) -> str:
    """Blank comments and string contents while preserving offsets/newlines."""
    chars = list(source)
    i = 0
    quote: str | None = None
    triple = False
    while i < len(source):
        char = source[i]
        if quote is not None:
            end = quote * (3 if triple else 1)
            if char == "\\":
                for j in range(i, min(i + 2, len(source))):
                    if chars[j] != "\n":
                        chars[j] = " "
                i += 2
                continue
            if source.startswith(end, i):
                for j in range(i, i + len(end)):
                    if chars[j] != "\n":
                        chars[j] = " "
                i += len(end)
                quote = None
                triple = False
                continue
            if char != "\n":
                chars[i] = " "
            i += 1
            continue
        if char == "#":
            while i < len(source) and source[i] != "\n":
                chars[i] = " "
                i += 1
            continue
        if char in "\"'":
            triple = source.startswith(char * 3, i)
            quote = char
            length = 3 if triple else 1
            for j in range(i, min(i + length, len(source))):
                if chars[j] != "\n":
                    chars[j] = " "
            i += length
            continue
        i += 1
    return "".join(chars)


def _top_level_kind(line: str) -> tuple[str, str] | None:
    stripped = line.lstrip(" \t")
    if not stripped or stripped != line:
        return None
    func = re.match(r"(?:(?:static|async)\s+)*func\s+([A-Za-z_]\w*)\s*\(", line)
    if func:
        return "function", func.group(1)
    field = re.match(
        r"(?:(?:@[A-Za-z_]\w*(?:\([^\n]*\))?)\s+)*(?:static\s+)?(var|const)\s+([A-Za-z_]\w*)\b",
        line,
    )
    if field:
        return field.group(1), field.group(2)
    return None


def _header_end(lines: list[str], start: int, kind: str) -> int:
    """Return the last line of a multiline declaration header."""
    depth = 0
    for index in range(start, len(lines)):
        line = lines[index]
        for char in line:
            if char in "([{":
                depth += 1
            elif char in ")]}" and depth:
                depth -= 1
            elif char == ":" and depth == 0:
                return index
        if kind != "function" and depth == 0:
            return index
    return min(start, len(lines) - 1)


def _declaration_end(lines: list[str], start: int) -> int:
    depth = 0
    for index in range(start, len(lines)):
        line = lines[index]
        if index > start and depth == 0 and line and not line[0].isspace():
            return index
        for char in line:
            if char in "([{":
                depth += 1
            elif char in ")]}":
                depth = max(0, depth - 1)
    return len(lines)


def _identifier_set(source: str) -> set[str]:
    return set(re.findall(r"\b[A-Za-z_]\w*\b", source))


def _code_fingerprint(source: str) -> str:
    """Hash normalized code tokens, retaining literals but ignoring comments."""
    token_pattern = re.compile(
        r'(?P<string>"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\')'
        r"|(?P<comment>\#.*)"
        r"|(?P<token>[A-Za-z_]\w*|\d+(?:\.\d+)?|:=|==|!=|<=|>=|\+=|-=|\*=|/=|->|&&|\|\||[^\s])"
    )
    tokens = [match.group("string") or match.group("token")
              for match in token_pattern.finditer(source) if not match.group("comment")]
    return hashlib.sha256(json.dumps(tokens, separators=(",", ":")).encode("utf-8")).hexdigest()


def _domain(name: str, method_names: set[str] | None = None) -> str:
    lowered = name.lower()
    if lowered.endswith(("_controller", "_presenter", "_scanner", "_service", "_config")) or "runtime_dependencies" in lowered:
        return "delegation_reference"
    for domain, tokens in DOMAIN_RULES:
        if any(token in lowered for token in tokens):
            return domain
    return "legacy_other_gameplay_authority"


def _field_write_pattern(name: str) -> re.Pattern[str]:
    escaped = re.escape(name)
    return re.compile(
        rf"(?<![\w])(?:self\s*\.\s*)?{escaped}\b\s*(?:\[[^\]\n]*\])?"
        r"(?:\s*\.\s*[A-Za-z_]\w*)?\s*(?:=(?!=)|\+=|-=|\*=|/=|%=|\|=|&=|\^=)"
        rf"|(?<![.\w]){escaped}\b\s*\.\s*(?:append|append_array|erase|clear|push_back|pop_back|sort|reverse|fill|resize|set)\s*\("
    )


def _field_alias_is_mutated(field: str, body: str) -> bool:
    """Catch a mutable field copied to a local alias before mutation."""
    aliases: set[str] = set()
    assignment = re.compile(
        r"^\s*(?:var\s+)?([A-Za-z_]\w*)\s*(?::[^=]+)?(?::=|=)\s*"
        r"(?:self\s*\.\s*)?([A-Za-z_]\w*)\b", re.M,
    )
    field_aliases = {field}
    for _ in range(4):
        added = set()
        for match in assignment.finditer(body):
            alias, source = match.group(1), match.group(2)
            if source in field_aliases and alias != source:
                added.add(alias)
        if added <= field_aliases:
            break
        field_aliases.update(added)
        aliases.update(added - {field})
    if not aliases:
        return False
    mutator = re.compile(
        r"^\s*(?:var\s+)?([A-Za-z_]\w*)\s*(?:\[[^\]\n]*\])?"
        r"(?:\s*\.\s*[A-Za-z_]\w*)?\s*(?:=(?!=)|\+=|-=|\*=|/=|%=|\|=|&=|\^=)"
        r"|\b([A-Za-z_]\w*)\s*\.\s*(?:append|append_array|erase|clear|push_back|pop_back|sort|reverse|fill|resize|set)\s*\("
    )
    for line in body.splitlines():
        if re.match(r"^\s*(?:var\s+)?(?:" + "|".join(map(re.escape, aliases)) + r")\s*(?::[^=]+)?(?::=|=)\s*(?:self\s*\.\s*)?", line):
            # Alias creation is a read of the field, not a mutation of it.
            continue
        match = mutator.search(line)
        if match and (match.group(1) or match.group(2)) in aliases:
            return True
    return False


def parse_gdscript(source: str) -> dict[str, Any]:
    """Parse top-level declarations and source-backed mutation evidence."""
    masked = mask_non_code(source)
    lines = masked.splitlines()
    original_lines = source.splitlines()
    declarations: list[tuple[int, str, str]] = []
    for index, line in enumerate(lines):
        item = _top_level_kind(line)
        if item:
            declarations.append((index, item[0], item[1]))

    fields: dict[str, dict[str, Any]] = {}
    methods: dict[str, dict[str, Any]] = {}
    for declaration_index, (line_no, kind, name) in enumerate(declarations):
        if kind in {"var", "const"}:
            end = _declaration_end(lines, line_no)
            raw_block = "\n".join(lines[line_no:end])
            signature_start = line_no
            while signature_start > 0 and re.match(r"^@[A-Za-z_]\w*(?:\([^\n]*\))?\s*$", lines[signature_start - 1]):
                signature_start -= 1
            source_signature = "\n".join(original_lines[signature_start:end])
            first = lines[line_no].strip()
            fields[name] = {
                "kind": kind,
                "line": line_no + 1,
                "signature": re.sub(r"\s+", " ", source_signature).strip(),
                "declared": first,
                "domain": "immutable_configuration" if kind == "const" else _domain(name),
                "_accessor_source": raw_block,
            }
            continue
        if kind != "function":
            continue
        header_last = _header_end(lines, line_no, "function")
        end = _declaration_end(lines, header_last)
        body = "\n".join(lines[header_last + 1:end])
        original_body = "\n".join(original_lines[header_last + 1:end])
        body_lines = [line for line in body.splitlines() if line.strip()]
        branches = sum(
            1 for line in body.splitlines()
            if re.match(r"^\s*(?:if|elif|match|for|while)\b", line)
        )
        params = _function_parameters("\n".join(lines[line_no:header_last + 1]))
        local_names = set(params)
        local_names.update(re.findall(r"^\s*(?:var|const)\s+([A-Za-z_]\w*)", body, re.M))
        methods[name] = {
            "line": line_no + 1,
            "code_lines": len(body_lines),
            "branches": branches,
            "params": sorted(params),
            "locals": sorted(local_names - set(params)),
            "body": body,
            "calls": sorted(set(re.findall(r"\b([A-Za-z_]\w*)\s*\(", body))),
            "clock_behavior": bool(re.search(r"\b(?:delta|Timer|create_timer|_timer|_cooldown|_duration)\b", body)),
            "fingerprint": _code_fingerprint(original_body),
        }

    mutable_fields = {name for name, item in fields.items() if item["kind"] == "var"}
    all_method_names = set(methods)
    writers_by_field: dict[str, list[str]] = {name: [] for name in fields}
    readers_by_field: dict[str, list[str]] = {name: [] for name in fields}
    field_names = set(fields)
    write_patterns = {name: _field_write_pattern(name) for name in mutable_fields}
    for method_name, method in methods.items():
        body = method["body"]
        identifiers = _identifier_set(body)
        shadowed = set(method["locals"]) | set(method["params"])
        for name in field_names & identifiers:
            explicit_self = bool(re.search(rf"\bself\s*\.\s*{re.escape(name)}\b", body))
            if name not in shadowed or explicit_self:
                readers_by_field[name].append(method_name)
                if name in mutable_fields and (
                    write_patterns[name].search(body) or _field_alias_is_mutated(name, body)
                ):
                    writers_by_field[name].append(method_name)

    for property_name, property_field in fields.items():
        accessor_source = property_field.pop("_accessor_source")
        accessor_lines = accessor_source.splitlines()
        accessor_matches = list(re.finditer(
            r"^\s+(get|set)\s*(?:\(([^)]*)\))?\s*:\s*$",
            accessor_source, re.M,
        ))
        for index, accessor in enumerate(accessor_matches):
            start_line = accessor_source.count("\n", 0, accessor.end()) + 1
            end_line = (accessor_source.count("\n", 0, accessor_matches[index + 1].start()) + 1
                        if index + 1 < len(accessor_matches) else len(accessor_lines))
            body = "\n".join(accessor_lines[start_line:end_line])
            params = _identifier_set(accessor.group(2) or "")
            label = f"{property_name}.{accessor.group(1)}"
            for target in field_names & _identifier_set(body):
                explicit_self = bool(re.search(rf"\bself\s*\.\s*{re.escape(target)}\b", body))
                if target not in params or explicit_self:
                    readers_by_field[target].append(label)
                    if target in mutable_fields and write_patterns[target].search(body):
                        writers_by_field[target].append(label)

    for name, field in fields.items():
        readers = readers_by_field[name]
        writers = writers_by_field[name]
        field["readers"] = sorted(readers)
        field["writers"] = sorted(writers)
        field["mutable"] = name in mutable_fields
        domains = {_domain(method, all_method_names) for method in writers}
        if field["domain"] == "legacy_other_gameplay_authority" and len(domains) == 1 and "legacy_other_gameplay_authority" not in domains:
            field["domain"] = next(iter(domains))
        field["behavior"] = {
            "writer_count": len(writers),
            "reader_count": len(readers),
            "clock_mutated": "timer" in name.lower() or "cooldown" in name.lower() or "duration" in name.lower(),
            "multiple_domain_writers": len(domains) > 1,
        }

    for name, method in methods.items():
        writes = [field for field in sorted(mutable_fields)
                  if name in fields[field]["writers"]]
        reads = [field for field in sorted(fields)
                 if name in fields[field]["readers"]]
        delegates_to = [field for field in reads if fields[field]["domain"] == "delegation_reference"]
        clock_fields = [field for field in set(reads) | set(writes)
                        if fields[field]["behavior"]["clock_mutated"]]
        method["writes"] = writes
        method["reads"] = reads
        method["delegates_to"] = sorted(delegates_to)
        method["clock_fields"] = sorted(clock_fields)
        method["owner"] = _domain(name)
        if writes:
            domains = sorted({fields[field]["domain"] for field in writes})
            method["owner"] = domains[0] if len(domains) == 1 else "mixed_legacy_domains"
        elif delegates_to:
            method["owner"] = "post_extraction_compatibility"
        method["behavior"] = {
            "writes_state": bool(writes),
            "branches": method["branches"],
            "advances_or_checks_clock": method["clock_behavior"],
            "delegates": bool(delegates_to),
            "decision_writes": bool(writes and method["branches"]),
        }
        del method["body"]

    return {
        "source_lines": len(original_lines),
        "top_level_fields": len(fields),
        "mutable_fields": len(mutable_fields),
        "top_level_functions": len(methods),
        "max_method_code_lines": max((item["code_lines"] for item in methods.values()), default=0),
        "max_method_branches": max((item["branches"] for item in methods.values()), default=0),
        "fields": fields,
        "methods": methods,
    }


def _function_parameters(header: str) -> set[str]:
    match = re.search(r"\bfunc\s+[A-Za-z_]\w*\s*\((.*)\)", header, re.S)
    if not match:
        return set()
    params = match.group(1)
    # Split only at commas outside generic/call/container delimiters.
    parts: list[str] = []
    start = depth = 0
    for index, char in enumerate(params):
        if char in "([{": depth += 1
        elif char in ")]}" and depth: depth -= 1
        elif char == "," and depth == 0:
            parts.append(params[start:index]); start = index + 1
    parts.append(params[start:])
    names = set()
    for part in parts:
        token = re.match(r"\s*([A-Za-z_]\w*)", part)
        if token:
            names.add(token.group(1))
    return names


def make_budget(inventory: dict[str, Any], migration_debt: dict[str, list[Any]] | None = None) -> dict[str, Any]:
    """Create the initial reviewed inventory from actual source evidence."""
    fields = {
        name: {key: value for key, value in item.items() if key != "line"}
        for name, item in sorted(inventory["fields"].items())
    }
    methods = {
        name: {
            "owner": item["owner"],
            "max_code_lines": item["code_lines"],
            "max_branches": item["branches"],
            "writes": item["writes"],
            "reads": item["reads"],
            "delegates_to": item["delegates_to"],
            "clock_fields": item["clock_fields"],
            "behavior": item["behavior"],
            "code_fingerprint": item["fingerprint"],
        }
        for name, item in sorted(inventory["methods"].items())
    }
    return {
        "schema": "custodian.operator_chassis_authority_budget.v1",
        "version": 1,
        "source": SOURCE_REL,
        "limits": {key: inventory[key] for key in BOOTSTRAP_LIMITS},
        "field_inventory": fields,
        "method_inventory": methods,
        "legacy_exceptions": [
            {
                "path": SOURCE_REL,
                "function": "_apply_melee_hitbox_tick",
                "receiver": "enemy",
                "call": "enemy.move_and_slide()",
                "owner": "operator-melee-domain-extraction",
                "expires_after": "F2 completes and the enemy impact fallback is removed",
                "reason": "Measured legacy melee impact fallback; never a chassis permission.",
            }
        ],
        "existing_migration_debt": migration_debt or {
            "legacy_path_lines": [],
            "legacy_runtime_paths": [],
        },
        "approval_records": {},
    }


def _load_audit_module(root: Path, relative: str, name: str) -> Any:
    path = root / relative
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load existing Operator audit predicate: {relative}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def measure_existing_migration_debt(root: Path) -> dict[str, list[Any]]:
    """Snapshot existing audit findings with the canonical audit predicates."""
    custodian = root / "custodian"
    path_audit = _load_audit_module(
        root, "custodian/tools/validation/operator_runtime_path_audit.py", "operator_runtime_path_audit_for_guard"
    )
    legacy_path_lines: list[dict[str, str]] = []
    for source_root in (custodian / "game", custodian / "tools"):
        for path in sorted(source_root.rglob("*")):
            if path.name in path_audit.MIGRATION_ONLY:
                continue
            if path.suffix not in {".gd", ".tscn", ".tres", ".py", ".json"} or not path.is_file():
                continue
            relative = path.relative_to(custodian).as_posix()
            operator_owned = relative.startswith(path_audit.OPERATOR_OWNED_DIRS)
            for line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
                match = path_audit.LEGACY_ACTION.search(line)
                if match and (operator_owned or path_audit.OPERATOR_SCOPE.search(line)):
                    legacy_path_lines.append({
                        "path": relative,
                        "line_sha256": hashlib.sha256(line.strip().encode("utf-8")).hexdigest(),
                    })

    animation_audit = _load_audit_module(
        root, "custodian/tools/validation/operator_runtime_animation_authority_smoke.py",
        "operator_runtime_animation_authority_for_guard",
    )
    runtime_roots = [animation_audit.OPERATOR_RUNTIME_ANIMATIONS,
                     *animation_audit.WEAPONS_ROOT.glob("*/runtime")]
    legacy_runtime_paths: list[str] = []
    for runtime_root in runtime_roots:
        if not runtime_root.exists():
            continue
        for png in runtime_root.rglob("*.png"):
            try:
                action = animation_audit.parse_filename(png, allow_legacy_action=True).action
            except ValueError:
                continue
            if animation_audit.is_legacy_action(action):
                relative = png.relative_to(custodian).as_posix()
                legacy_runtime_paths.append(hashlib.sha256(relative.encode("utf-8")).hexdigest())
    return {
        "legacy_path_lines": sorted(legacy_path_lines, key=lambda item: (item["path"], item["line_sha256"])),
        "legacy_runtime_paths": sorted(legacy_runtime_paths),
    }


def _policy_violations(current: dict[str, Any], base: dict[str, Any] | None) -> list[str]:
    failures: list[str] = []
    if current.get("schema") != "custodian.operator_chassis_authority_budget.v1":
        failures.append("unsupported budget schema")
    limits = current.get("limits")
    if not isinstance(limits, dict):
        return failures + ["budget limits must be an object"]
    approvals = current.get("approval_records", {})
    if not isinstance(approvals, dict):
        failures.append("approval_records must be an object")
        approvals = {}
    if not isinstance(current.get("legacy_exceptions"), list):
        failures.append("legacy_exceptions must be an array")
    debt = current.get("existing_migration_debt")
    if not isinstance(debt, dict) or any(not isinstance(debt.get(key), list) for key in
                                         ("legacy_path_lines", "legacy_runtime_paths")):
        failures.append("existing_migration_debt must contain path-line and runtime-path arrays")
    for key, ceiling in BOOTSTRAP_LIMITS.items():
        value = limits.get(key)
        if not isinstance(value, int) or isinstance(value, bool) or value < 0:
            failures.append(f"invalid limit {key}")
        elif value > ceiling:
            failures.append(f"budget limit increased above sealed bootstrap ceiling: {key}={value}>{ceiling}")
    if base is None:
        return failures
    old_limits = base.get("limits", {})
    for key, old in old_limits.items():
        new = limits.get(key)
        if isinstance(old, int) and isinstance(new, int) and new > old:
            failures.append(f"budget limit increased relative to base: {key}={old}->{new}")
    for inventory_key in ("field_inventory", "method_inventory"):
        old_items = base.get(inventory_key, {})
        new_items = current.get(inventory_key, {})
        if not isinstance(old_items, dict) or not isinstance(new_items, dict):
            failures.append(f"{inventory_key} must be an object")
            continue
        added = sorted(set(new_items) - set(old_items))
        removed = sorted(set(old_items) - set(new_items))
        for name in added:
            approval = approvals.get(name)
            if not _valid_approval(approval):
                failures.append(f"unapproved {inventory_key} addition: {name}")
        for name in set(old_items) & set(new_items):
            before, after = old_items[name], new_items[name]
            if not isinstance(before, dict) or not isinstance(after, dict):
                failures.append(f"malformed {inventory_key} record: {name}")
                continue
            if before.get("owner") != after.get("owner"):
                approval = approvals.get(name)
                if not _valid_approval(approval):
                    failures.append(f"unapproved ownership rebaseline: {name}")
            if inventory_key == "field_inventory":
                if before.get("signature") != after.get("signature"):
                    approval = approvals.get(name)
                    if not _valid_approval(approval):
                        failures.append(f"unapproved field declaration rebaseline: {name}")
                for evidence_key in ("writers", "readers"):
                    if not set(after.get(evidence_key, [])) <= set(before.get(evidence_key, [])):
                        failures.append(f"field mutation evidence expanded in budget: {name}.{evidence_key}")
            if inventory_key == "method_inventory" and before.get("code_fingerprint") != after.get("code_fingerprint"):
                if not _valid_approval(approvals.get(name)):
                    failures.append(f"method fingerprint rebaseline lacks bounded approval: {name}")
            for metric in ("max_code_lines", "max_branches"):
                if metric in before and metric in after and after[metric] > before[metric]:
                    failures.append(f"method ceiling increased relative to base: {name}.{metric}")
            old_writes = set(before.get("writes", []))
            new_writes = set(after.get("writes", []))
            if not new_writes <= old_writes:
                failures.append(f"method write-set expanded in budget: {name}")
            for evidence_key in ("reads", "delegates_to", "clock_fields"):
                if not set(after.get(evidence_key, [])) <= set(before.get(evidence_key, [])):
                    failures.append(f"method evidence expanded in budget: {name}.{evidence_key}")
            old_behavior = before.get("behavior", {})
            new_behavior = after.get("behavior", {})
            for key, value in new_behavior.items():
                old_value = old_behavior.get(key)
                if isinstance(value, int) and not isinstance(value, bool) and isinstance(old_value, int):
                    if value > old_value:
                        failures.append(f"method behavior budget increased: {name}.{key}")
                elif value is True and old_value is not True:
                    failures.append(f"method behavior budget expanded: {name}.{key}")
        # Removed baseline symbols are the expected monotonic ratchet.
        _ = removed
    old_exceptions = {json.dumps(item, sort_keys=True) for item in base.get("legacy_exceptions", [])
                      if isinstance(item, dict)}
    new_exceptions = {json.dumps(item, sort_keys=True) for item in current.get("legacy_exceptions", [])
                      if isinstance(item, dict)}
    if not new_exceptions <= old_exceptions:
        failures.append("legacy movement exception added or broadened relative to base")
    old_debt = base.get("existing_migration_debt", {})
    if isinstance(debt, dict) and isinstance(old_debt, dict):
        for key in ("legacy_path_lines", "legacy_runtime_paths"):
            before = old_debt.get(key, [])
            after = debt.get(key, [])
            before_counts = Counter(json.dumps(item, sort_keys=True) for item in before)
            after_counts = Counter(json.dumps(item, sort_keys=True) for item in after)
            if after_counts - before_counts:
                failures.append(f"existing migration debt baseline increased: {key}")
    return failures


def _valid_approval(record: Any) -> bool:
    required = ("owner", "consumer", "reason", "scope", "expires_after", "approval_reference")
    return isinstance(record, dict) and all(isinstance(record.get(key), str) and record[key].strip()
                                             for key in required)


def compare_inventory(inventory: dict[str, Any], budget: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    limits = budget.get("limits", {})
    for key, ceiling in limits.items():
        if key in inventory and inventory[key] > ceiling:
            failures.append(f"source exceeds {key}: {inventory[key]}>{ceiling}")
    expected_fields = budget.get("field_inventory", {})
    expected_methods = budget.get("method_inventory", {})
    actual_fields = inventory["fields"]
    actual_methods = inventory["methods"]
    for name in sorted(set(actual_fields) - set(expected_fields)):
        approval_records = budget.get("approval_records", {})
        approval = approval_records.get(name) if isinstance(approval_records, dict) else None
        if not _valid_approval(approval):
            failures.append(f"unregistered top-level field: {name}")
    for name in sorted(set(expected_fields) - set(actual_fields)):
        failures.append(f"stale field baseline must be ratcheted out: {name}")
    for name in sorted(set(actual_fields) & set(expected_fields)):
        actual = actual_fields[name]
        expected = expected_fields[name]
        if actual["signature"] != expected.get("signature"):
            failures.append(f"top-level field declaration changed without an approval record: {name}")
        for key in ("kind", "domain", "writers", "readers", "mutable", "behavior"):
            if key in expected and actual.get(key) != expected.get(key):
                failures.append(f"field ownership evidence changed: {name}.{key}")
    for name in sorted(set(actual_methods) - set(expected_methods)):
        approval_records = budget.get("approval_records", {})
        approval = approval_records.get(name) if isinstance(approval_records, dict) else None
        if not _valid_approval(approval):
            failures.append(f"unregistered top-level method/facade: {name}")
    for name in sorted(set(expected_methods) - set(actual_methods)):
        failures.append(f"stale method baseline must be ratcheted out: {name}")
    for name in sorted(set(actual_methods) & set(expected_methods)):
        actual = actual_methods[name]
        expected = expected_methods[name]
        if actual["code_lines"] > expected.get("max_code_lines", -1):
            failures.append(f"method body grew beyond its source ceiling: {name}")
        if actual["branches"] > expected.get("max_branches", -1):
            failures.append(f"method decision branches grew beyond its source ceiling: {name}")
        if actual["fingerprint"] != expected.get("code_fingerprint"):
            failures.append(f"method body fingerprint differs from the sealed budget: {name}")
        for evidence_key in ("writes", "reads", "delegates_to", "clock_fields"):
            if not set(actual.get(evidence_key, [])) <= set(expected.get(evidence_key, [])):
                failures.append(f"method acquired new actor-state evidence: {name}.{evidence_key}")
        if actual["owner"] != expected.get("owner"):
            failures.append(f"method mutation ownership changed: {name}")
        if actual["behavior"] != expected.get("behavior"):
            failures.append(f"method decision/clock behavior changed: {name}")
    return failures


def detect_foreign_motors(files: dict[str, str], exceptions: list[dict[str, Any]]) -> list[str]:
    allowed = {(e.get("path"), e.get("function"), e.get("receiver"), e.get("call"))
               for e in exceptions if isinstance(e, dict)}
    findings: list[str] = []
    observed: dict[tuple[str, str, str, str], int] = {}
    call_pattern = re.compile(
        r"(?:(?P<receiver>(?:self|[A-Za-z_]\w*)(?:\s*(?:\.\s*[A-Za-z_]\w*|\[[^\]\n]+\]))*)\s*\.\s*)?move_and_slide\s*\("
    )
    for path, source in sorted(files.items()):
        parsed = parse_gdscript(source)
        masked = mask_non_code(source)
        line_starts = [0]
        for match in re.finditer("\n", masked):
            line_starts.append(match.end())
        method_at_line = []
        methods = sorted(((item["line"], name) for name, item in parsed["methods"].items()))
        for match in call_pattern.finditer(masked):
            line = masked.count("\n", 0, match.start()) + 1
            function = next((name for method_line, name in reversed(methods) if method_line <= line), "<top-level>")
            receiver = (match.group("receiver") or "").replace(" ", "")
            call = (receiver + "." if receiver else "") + "move_and_slide()"
            if Path(path).name == "operator.gd" and receiver in {"", "self"} and function == "_advance_movement":
                continue
            key = (path, function, receiver, call)
            observed[key] = observed.get(key, 0) + 1
            if receiver not in {"", "self"} and key in allowed:
                continue
            findings.append(f"{path}:{line}:{function}: foreign or misplaced {call}")
    for key in sorted(allowed):
        count = observed.get(key, 0)
        if count != 1:
            findings.append(
                f"{key[0]}:{key[1]}: measured legacy movement exception must occur exactly once, found {count}"
            )
    return findings


def _read_base_budget(root: Path, ref: str | None) -> dict[str, Any] | None:
    if not ref:
        return None
    result = subprocess.run(
        ["git", "show", f"{ref}:{BUDGET_REL}"], cwd=root,
        text=True, capture_output=True,
    )
    if result.returncode:
        return None
    try:
        value = json.loads(result.stdout)
    except json.JSONDecodeError:
        return {"schema": "invalid"}
    return value if isinstance(value, dict) else {"schema": "invalid"}


def _verify_integration(root: Path) -> list[str]:
    path = root / WORKSTREAM_REL
    if not path.is_file():
        return [f"missing mandatory finish integration: {WORKSTREAM_REL}"]
    source = path.read_text(encoding="utf-8")
    helper = "def _run_operator_chassis_authority_guard("
    caller = "_run_operator_chassis_authority_guard(repo, path)"
    if helper not in source or source.count(caller) < 2:
        return ["workstream.py finish/preflight guard integration missing or disabled"]
    return []


def _verify_manifest(root: Path) -> list[str]:
    path = root / MANIFEST_REL
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"validation manifest is unreadable: {error}"]
    tests = payload.get("tests", []) if isinstance(payload, dict) else []
    matches = [test for test in tests if isinstance(test, dict) and test.get("id") == GUARD_TEST_ID]
    if len(matches) != 1:
        return [f"mandatory guard test registration missing or duplicated: {GUARD_TEST_ID}"]
    test = matches[0]
    expected_script = "custodian/tools/validation/test_operator_chassis_authority_guard.py"
    owners = set(test.get("owners", []))
    if test.get("type") != "python" or test.get("script") != expected_script:
        return ["mandatory guard test registration points to the wrong runner"]
    required_owners = {
        SOURCE_REL, BUDGET_REL, expected_script, MANIFEST_REL, WORKSTREAM_REL,
        "custodian/game/actors/operator/**", "custodian/tools/agent/test_workstream.py",
        "custodian/tools/validation/operator_chassis_authority_guard.py",
        *(relative for relative, _ in REUSED_AUDITS),
    }
    if not required_owners <= owners:
        return ["mandatory guard test registration omits a source, policy, or reused-audit owner"]
    return []


def _run_reused_authority_audits(root: Path) -> list[str]:
    """Re-run the repository's canonical input, animation and runtime-path predicates."""
    failures: list[str] = []
    for relative, arguments in REUSED_AUDITS:
        script = root / relative
        if not script.is_file():
            failures.append(f"required existing Operator authority audit is missing: {relative}")
            continue
        try:
            result = subprocess.run(
                [sys.executable, str(script), *arguments], cwd=root,
                text=True, capture_output=True, timeout=120,
            )
        except subprocess.TimeoutExpired:
            failures.append(f"existing Operator authority audit exceeded its 120-second bound: {relative}")
            continue
        if result.returncode:
            detail = (result.stderr or result.stdout).strip().splitlines()
            failures.append(f"existing Operator authority audit failed ({relative}): "
                            f"{detail[0] if detail else f'exit {result.returncode}'}")
    return failures


def audit(root: Path, against_ref: str | None = "origin/main") -> dict[str, Any]:
    root = root.resolve()
    source_path = root / SOURCE_REL
    budget_path = root / BUDGET_REL
    failures: list[str] = []
    if not source_path.is_file() or not budget_path.is_file():
        failures.append("missing Operator source or authority budget")
        return {"schema": "custodian.operator_chassis_authority_guard.v1", "passed": False,
                "failures": failures}
    source = source_path.read_text(encoding="utf-8")
    budget_raw = budget_path.read_bytes()
    try:
        budget = json.loads(budget_raw)
    except json.JSONDecodeError as error:
        return {"schema": "custodian.operator_chassis_authority_guard.v1", "passed": False,
                "failures": [f"invalid authority budget JSON: {error}"]}
    if hashlib.sha256(budget_raw).hexdigest() != PINNED_BUDGET_SHA256:
        failures.append("authority budget differs from the reviewed pinned digest")
    base = _read_base_budget(root, against_ref)
    failures.extend(_policy_violations(budget, base))
    inventory = parse_gdscript(source)
    failures.extend(compare_inventory(inventory, budget))
    failures.extend(_verify_integration(root))
    failures.extend(_verify_manifest(root))
    failures.extend(_run_reused_authority_audits(root))
    try:
        observed_debt = measure_existing_migration_debt(root)
    except Exception as error:
        observed_debt = {"legacy_path_lines": [], "legacy_runtime_paths": []}
        failures.append(f"existing migration debt could not be measured: {error}")
    budget_debt = budget.get("existing_migration_debt", {})
    for key in ("legacy_path_lines", "legacy_runtime_paths"):
        expected = budget_debt.get(key, []) if isinstance(budget_debt, dict) else []
        expected_counts = Counter(json.dumps(item, sort_keys=True) for item in expected)
        observed_counts = Counter(json.dumps(item, sort_keys=True) for item in observed_debt[key])
        if observed_counts - expected_counts:
            failures.append(f"new or increased pre-existing Operator migration debt: {key}")
        if expected_counts - observed_counts:
            failures.append(f"removed Operator migration debt must be ratcheted out of the budget: {key}")
    operator_root = root / "custodian/game/actors/operator"
    exception_files = [
        path.relative_to(root).as_posix() for path in sorted(operator_root.glob("**/*.gd"))
        if path.is_file() and path.resolve() != source_path.resolve()
    ]
    files = {SOURCE_REL: source}
    files.update({rel: (root / rel).read_text(encoding="utf-8") for rel in exception_files})
    failures.extend(detect_foreign_motors(files, budget.get("legacy_exceptions", [])))
    domain_counts: dict[str, int] = {}
    for item in inventory["fields"].values():
        domain_counts[item["domain"]] = domain_counts.get(item["domain"], 0) + 1
    return {
        "schema": "custodian.operator_chassis_authority_guard.v1",
        "passed": not failures,
        "failures": failures,
        "source_sha256": hashlib.sha256(source.encode("utf-8")).hexdigest(),
        "budget_sha256": hashlib.sha256(budget_raw).hexdigest(),
        "measurements": {key: inventory[key] for key in BOOTSTRAP_LIMITS},
        "mutable_fields": inventory["mutable_fields"],
        "domain_field_counts": dict(sorted(domain_counts.items())),
        "legacy_exception_count": len(budget.get("legacy_exceptions", [])),
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=REPO_ROOT)
    parser.add_argument("--against-ref", default="origin/main")
    parser.add_argument("--emit-budget", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)
    if args.emit_budget:
        source = (args.root / SOURCE_REL).read_text(encoding="utf-8")
        debt = measure_existing_migration_debt(args.root)
        print(json.dumps(make_budget(parse_gdscript(source), debt), indent=2, sort_keys=True))
        return 0
    report = audit(args.root, args.against_ref)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print("PASS" if report["passed"] else "FAIL")
        for failure in report.get("failures", []):
            print(f"- {failure}")
        if report.get("passed"):
            print(json.dumps(report.get("measurements", {}), sort_keys=True))
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
