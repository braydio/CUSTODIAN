#!/usr/bin/env python3
"""Audit Operator runtime architecture debt against a shrinking baseline.

`operator.gd` is not merely large: it holds too many overlapping authorities.
This audit encodes the ownership rules the decomposition is migrating toward,
so the runtime cannot silently grow back into a monolith once it is split.

Each rule names one authority and the directory that owns it. Every current
violation is recorded as an exact per-file baseline:

* a NEW or INCREASED violation fails ordinary validation - debt cannot grow;
* a REMOVED or DECREASED violation is TODO normally and a failure under
  ``--final``, which forces the ledger to shrink as work lands;
* any remaining baseline entry fails under ``--final``, which is the objective
  end state - zero debt.

Raw Operator animation art references stay under the authority of
`operator_runtime_path_audit.py`; this audit does not duplicate that ledger.

Authority: design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
OPERATOR_DIR = PROJECT_ROOT / "game/actors/operator"

BODY_LAYER_NODES = (
    "animated_sprite",
    "modular_lower_body_sprite",
    "modular_upper_body_sprite",
    "modular_head_sprite",
    "full_body_sprite",
    "_vigil_startup_lower",
    "_vigil_startup_upper",
    "_vigil_posture_bridge_lower",
    "_vigil_posture_bridge_upper",
    "_vigil_guard_lower",
    "_vigil_guard_upper",
)

# A direct write names a body renderer, so a regex over those names finds it.
# Binding one to a loop variable or a parameter and writing `sprite.visible`
# instead hides the same write from the same regex, which is how the body
# firewall reported a false zero. These are the alias names the Operator's
# generic presentation helpers use; every one of them must route through
# OperatorBodyPresenter rather than writing visibility itself.
BODY_LAYER_ALIASES = ("sprite", "layer_sprite", "layer", "body", "rig")

# The two functions that are allowed to write an unregistered renderer's
# visibility, because they ARE the funnel: both refuse to touch anything the
# presenter is authoritative for. Nothing else may write through an alias.
VISIBILITY_FUNNEL_FUNCTIONS = ("_show_presentation_layer", "_hide_presentation_layer")


class Rule:
    """One ownership rule: a pattern, the dirs allowed to violate it, and why."""

    def __init__(self, key, title, pattern, owner, allowed_prefixes=(), files=("*.gd",),
                 exempt_functions=()):
        self.key = key
        self.title = title
        self.pattern = re.compile(pattern, re.MULTILINE)
        self.owner = owner
        self.allowed_prefixes = allowed_prefixes
        self.files = files
        # Named functions whose bodies are removed before matching. Used only
        # where a single declared funnel is the correct place for a write; it is
        # a narrow, auditable exemption rather than a laxer pattern.
        self.exempt_functions = exempt_functions

    def allows(self, relative: str) -> bool:
        return any(relative.startswith(prefix) for prefix in self.allowed_prefixes)

    def prepare(self, source: str) -> str:
        for name in self.exempt_functions:
            source = _strip_function(source, name)
        return source


def _strip_function(source: str, name: str) -> str:
    """Remove one top-level function body so a rule can exempt it by name."""
    lines = source.split("\n")
    kept: list[str] = []
    inside = False
    for line in lines:
        if line.startswith("func %s(" % name):
            inside = True
            continue
        if inside:
            if line.startswith("func ") or (line and not line[0].isspace()):
                inside = False
            else:
                continue
        kept.append(line)
    return "\n".join(kept)


RULES = [
    Rule(
        "input_calls_outside_input_dir",
        "direct Input.* sampling outside operator/input/",
        r"\bInput\.(?:is_action|get_action|get_vector|get_axis|get_joy|get_last_mouse|get_mouse)",
        "OperatorInputRouter (operator/input/)",
        allowed_prefixes=("input/",),
    ),
    Rule(
        "body_visibility_outside_presentation",
        "body-layer visibility writes outside operator/presentation/",
        r"(?:%s)\s*\.\s*visible\s*=" % "|".join(re.escape(n) for n in BODY_LAYER_NODES),
        "OperatorBodyPresenter (operator/presentation/)",
        allowed_prefixes=("presentation/",),
    ),
    Rule(
        "aliased_body_visibility_writes",
        "body-layer visibility written through a loop variable or parameter",
        r"(?:%s)\s*\.\s*visible\s*=" % "|".join(
            r"\b" + re.escape(n) for n in BODY_LAYER_ALIASES
        ),
        "OperatorBodyPresenter (operator/presentation/)",
        allowed_prefixes=("presentation/",),
        exempt_functions=VISIBILITY_FUNNEL_FUNCTIONS,
    ),
    Rule(
        "animated_sprite_play_outside_presentation",
        "AnimatedSprite2D.play() outside operator/presentation/",
        r"(?:sprite|_lower|_upper|_head|_weapon|_body)\w*\s*\.\s*play\s*\(",
        "OperatorAnimationPlayer (operator/presentation/)",
        allowed_prefixes=("presentation/",),
    ),
    Rule(
        "actor_local_spriteframes",
        "actor-local SpriteFrames construction",
        r"\bSpriteFrames\.new\s*\(",
        "the one generated operator_runtime_frames.tres",
    ),
    Rule(
        "animation_resolver",
        "retired AnimationResolver usage",
        r"\bAnimationResolver\b",
        "OperatorAnimationSelector",
    ),
    Rule(
        "directional_animation_fallback",
        "retired DirectionalAnimationFallback usage",
        r"\bDirectionalAnimationFallback\b",
        "OperatorAnimationSelector",
    ),
    Rule(
        "operator_animation_catalog",
        "retired OperatorAnimationCatalog usage",
        r"\bOperatorAnimationCatalog\b|operator_animation_catalog_frames",
        "OperatorAnimationSelector",
    ),
    Rule(
        "attack_fallback_animation",
        "attack fallback_animation indirection",
        r"\bfallback_animation\b",
        "OperatorAnimationSelector exact-identity contract",
    ),
    Rule(
        "animation_state_actor_glue",
        "AnimationState reaching back into the actor via has_method()/call()",
        r"actor\s*\.\s*(?:has_method|call|callv|get|set)\s*\(",
        "OperatorActionController",
        allowed_prefixes=(),
        files=("animations/states/*.gd",),
    ),
    Rule(
        "weapon_definition_runtime_state",
        "mutable per-instance state inside OperatorWeaponDefinition",
        r"@export\s+var\s+(?:current_magazine|is_reloading|reload_timer|current_heat|heat_locked)\b",
        "OperatorWeaponRuntimeState",
        files=("operator_weapon_definition.gd",),
    ),
    Rule(
        "absolute_scene_lookups",
        "absolute /root/... scene-tree lookups inside Operator code",
        r"get_node(?:_or_null)?\s*\(\s*[\"']/root/",
        "injected dependencies / the integration glue layer",
    ),
    Rule(
        "gameplay_mutation_in_process",
        "simulation advanced from the render tick",
        r"^\t(?:_update_|_tick_|_try_|_sync_)\w+\(delta\)",
        "the fixed physics tick",
        files=("_process_body",),
    ),
    Rule(
        "move_and_slide_authority",
        "move_and_slide() outside the operator.gd chassis",
        r"\bmove_and_slide\s*\(",
        "operator.gd root",
        allowed_prefixes=("operator.gd",),
    ),
]

# Exact migration debt, keyed by rule then repo-relative Operator path. Shrink
# this as slices land; never grow it.
BASELINE: dict[str, dict[str, int]] = {}
BASELINE_PATH = Path(__file__).with_name("operator_architecture_debt_baseline.json")
if BASELINE_PATH.is_file():
    BASELINE = json.loads(BASELINE_PATH.read_text(encoding="utf-8"))


def _process_body(source: str) -> str:
    """The `_process()` body only, so render-tick debt is measured in isolation."""
    lines = source.split("\n")
    try:
        start = next(i for i, line in enumerate(lines) if line.startswith("func _process("))
    except StopIteration:
        return ""
    end = start + 1
    while end < len(lines) and not lines[end].startswith("func "):
        end += 1
    return "\n".join(lines[start:end])


def _iter_sources(rule: Rule):
    for spec in rule.files:
        if spec == "_process_body":
            path = OPERATOR_DIR / "operator.gd"
            if path.is_file():
                yield path, _process_body(path.read_text(encoding="utf-8"))
            continue
        for path in sorted(OPERATOR_DIR.glob("**/" + spec if "/" not in spec else spec)):
            if path.is_file():
                yield path, path.read_text(encoding="utf-8")


def measure() -> dict[str, dict[str, int]]:
    found: dict[str, dict[str, int]] = {}
    for rule in RULES:
        for path, source in _iter_sources(rule):
            relative = path.relative_to(OPERATOR_DIR).as_posix()
            if rule.allows(relative):
                continue
            hits = len(rule.pattern.findall(rule.prepare(source)))
            if hits:
                found.setdefault(rule.key, {})[relative] = hits
    return found


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--final", action="store_true",
                        help="require zero debt; the objective end-state gate")
    parser.add_argument("--emit-baseline", action="store_true",
                        help="print the measured state as a baseline ledger")
    parser.add_argument("--json", action="store_true", help="machine-readable report")
    args = parser.parse_args()

    found = measure()
    if args.emit_baseline:
        print(json.dumps(found, indent=2, sort_keys=True))
        return 0

    grown: list[str] = []
    shrunk: list[str] = []
    remaining = 0
    rules_by_key = {rule.key: rule for rule in RULES}

    for key in sorted(set(found) | set(BASELINE)):
        rule = rules_by_key.get(key)
        title = rule.title if rule else key
        current = found.get(key, {})
        baseline = BASELINE.get(key, {})
        for relative in sorted(set(current) | set(baseline)):
            now = current.get(relative, 0)
            was = baseline.get(relative, 0)
            remaining += now
            if now > was:
                grown.append("%s: %s %d -> %d (owner: %s)" % (
                    title, relative, was, now, rule.owner if rule else "?"))
            elif now < was:
                shrunk.append("%s: %s %d -> %d" % (title, relative, was, now))

    if args.json:
        print(json.dumps({
            "schema": "custodian.operator_architecture_debt.v1",
            "remaining_violations": remaining,
            "grown": grown,
            "shrunk": shrunk,
            "final": args.final,
            "found": found,
        }, indent=2, sort_keys=True))

    ok = True
    if grown:
        ok = False
        print("\nFAIL: Operator architecture debt grew")
        for line in grown:
            print("  ✗ %s" % line)
        print("\nEach line names the authority that should own the fact instead.")

    if shrunk:
        label = "FAIL" if args.final else "TODO"
        if args.final:
            ok = False
        print("\n%s: baseline is stale - debt shrank, update the ledger" % label)
        for line in shrunk:
            print("  · %s" % line)
        print("\nRefresh with: operator_architecture_debt_audit.py --emit-baseline"
              " > operator_architecture_debt_baseline.json")

    if remaining and args.final:
        ok = False
        print("\nFAIL --final: %d architecture debt violations remain" % remaining)
        for key in sorted(found):
            rule = rules_by_key.get(key)
            print("  ✗ %s" % (rule.title if rule else key))
            for relative, count in sorted(found[key].items()):
                print("      %s (%d)" % (relative, count))
    elif remaining:
        print("\nTODO: %d architecture debt violations remain (baseline held)" % remaining)
        for key in sorted(found):
            rule = rules_by_key.get(key)
            print("  · %-46s %d in %d file(s)" % (
                key, sum(found[key].values()), len(found[key])))

    if ok:
        print("\nPASS: operator architecture debt%s" % (" (final)" if args.final else ""))
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
