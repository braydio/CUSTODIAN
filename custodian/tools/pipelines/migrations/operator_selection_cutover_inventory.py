#!/usr/bin/env python3
"""Prove, per call site, which canonical identity each legacy Operator selection means.

Migration tooling. Gameplay must never consume this, and it emits no runtime
alias table: the deliverable is evidence a human can review, not a translation
layer that would keep the legacy names alive.

The authoritative join is `legacy_clips` on each row of
`operator_animation_reachability.json`. Prose matching was tried first and is
unsafe — "unarmed_parry" matches "unarmed_parry_recovery" by substring and
silently produces the wrong action — so the contract now records the mapping as
data, and this tool only reads it.

Proof sources, strongest first:

    A  canonical runtime / reachability metadata
    B  weapon or profile resource semantic fields
    C  explicit runtime call context
    D  design authority describing that exact action

Filename resemblance alone is never proof.

Classification per mapping:

    PROVEN               safe for renderer cutover
    AUTHORING_DECISION   no uniquely correct mapping; design input required
    MISSING_PUBLICATION  intent proven, canonical identity or art absent
    RETIRED              caller belongs to retired presentation (head/cape)
    UNRESOLVED           the legacy value could not be traced to a literal

A renderer is READY only when every active consumer is PROVEN and the target
canonical identities are published and playable.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

CUSTODIAN_ROOT = Path(__file__).resolve().parents[3]
REPO_ROOT = CUSTODIAN_ROOT.parent
OPERATOR_DIR = CUSTODIAN_ROOT / "game/actors/operator"
MANIFEST = CUSTODIAN_ROOT / "content/sprites/operator/runtime/operator_runtime_manifest.generated.json"
REACHABILITY = CUSTODIAN_ROOT / "content/data/operator/operator_animation_reachability.json"
DEFAULT_REPORT = REPO_ROOT / "reports/operator/operator_selection_cutover_evidence.json"

SELECTION_PATTERNS = {
    "animation_resolver": re.compile(r"AnimationResolver\.resolve\s*\(([^;]+)"),
    "directional_animation_fallback": re.compile(r"DirectionalAnimationFallback\.(\w+)\s*\("),
    "attack_fallback_animation": re.compile(r"\bfallback_animation\b"),
}

#: The actual Operator presentation renderers. An explicit whitelist, because
#: pattern-matching identifiers containing "sprite" also matches helper names
#: like `_has_playable_sprite_animation` and parameters like `layer_sprite`.
RENDERERS = (
    "animated_sprite",
    "modular_lower_body_sprite",
    "modular_upper_body_sprite",
    "modular_head_sprite",
    "modular_cape_sprite",
    "modular_sidearm_sprite",
    "modular_upper_fx_sprite",
    "melee_weapon_overlay_sprite",
    "melee_fx_overlay_sprite",
    "primary_weapon_sprite",
    "ranged_fx_overlay_sprite",
    "dodge_fx_back_sprite",
    "_vigil_startup_lower", "_vigil_startup_upper", "_vigil_startup_weapon",
    "_vigil_posture_bridge_lower", "_vigil_posture_bridge_upper", "_vigil_posture_bridge_weapon",
    "_vigil_guard_lower", "_vigil_guard_upper", "_vigil_guard_weapon",
)

#: Renderers retired from active composition; their consumers are not C2 work.
RETIRED_RENDERERS = {"modular_head_sprite", "modular_cape_sprite"}

#: Selection sites whose replacement needs design input rather than evidence,
#: keyed by enclosing function.
AUTHORING_DECISIONS: dict[str, str] = {
    "begin_modular_damage_reaction": (
        "shared/locomotion/idle_hitreact_01 is authored for n and s only, and the "
        "retired nearest-sector search chose between them. Which variant a "
        "diagonal-facing hit reaction should use is an authoring decision, the "
        "same shape as the dodge decision resolved on 2026-09-12."
    ),
}

#: Sites whose legacy value originates in weapon/profile RESOURCE data rather
#: than any code literal. Their mapping is proven per resource entry (proof
#: source B), and the resource is what has to change, not the call site.
DATA_DRIVEN_SITES: dict[str, str] = {
    "_play_melee_anim_resolved": (
        "base_animation arrives from _get_weapon_animation_name(), i.e. "
        "OperatorWeaponDefinition.animation_map. Proven per resource entry via "
        "the recorded legacy_clips for vigil_dagger_fast_* / sword_cleaver_fast_*; "
        "the fix is the resource losing its concrete clip names, per C2a §7."
    ),
    "_play_melee_overlay_from_key": (
        "weapon_anim / fx_anim arrive from OperatorWeaponDefinition.fx_map. Same "
        "resolution as above: the resource carries the concrete clip name."
    ),
    "_update_animation": (
        "melee_body_stance_anim arrives from "
        "_get_authored_melee_body_stance_animation(), which reads the weapon "
        "animation_map 'melee_stance' entry."
    ),
}

#: Sites that are already resolved by an authoring decision plus published art.
RESOLVED_BY_DECISION: dict[str, str] = {
    "_resolve_dodge_presentation_animation": (
        "Resolved by the 2026-09-12 dodge authoring decision: exact canonical "
        "coverage now exists for all eight sectors of dodge_charge_windup_01 and "
        "dodge_chain_link_01. Blocked only on the animated_sprite rebinding."
    ),
}


def enclosing(funcs, index: int) -> str:
    name = "<file scope>"
    for i, n in funcs:
        if i <= index:
            name = n
        else:
            break
    return name


def load_contract() -> tuple[dict, dict]:
    """The canonical identities that exist, and the recorded legacy->canonical join."""
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    coverage: dict[tuple[str, str, str], dict[str, list[str]]] = defaultdict(lambda: defaultdict(list))
    for entry in manifest["animations"].values():
        key = (entry["profile"], entry["group"], entry["action"])
        for layer in entry["layers"]:
            coverage[key][layer].append(entry["direction"])
    for layers in coverage.values():
        for layer in layers:
            layers[layer] = sorted(layers[layer])

    join: dict[str, dict] = {}
    reach = json.loads(REACHABILITY.read_text(encoding="utf-8"))
    for entry in reach["entries"]:
        for clip in entry.get("legacy_clips", []):
            join[clip] = {
                "profile": entry["profile"], "group": entry["group"], "action": entry["action"],
                "status": entry.get("status"),
                "proof_source": entry.get("legacy_clip_proof", {}).get(clip, ""),
                "layers": coverage.get(
                    (entry["profile"], entry["group"], entry["action"]), {}),
            }
    return coverage, join


def sources() -> list[tuple[Path, list[str], list[tuple[int, str]]]]:
    out = []
    for path in sorted(OPERATOR_DIR.rglob("*.gd")):
        lines = path.read_text(encoding="utf-8", errors="ignore").split("\n")
        out.append((path, lines, [(i, l.split("(")[0][5:])
                                  for i, l in enumerate(lines) if l.startswith("func ")]))
    return out


#: Literals that appear in these call sites but are not clip names — dictionary
#: keys, phase names and result fields. Filtering by shape alone is not enough.
NON_CLIP_LITERALS = {
    "played", "duration", "animation", "aiming", "lowering", "windup", "strike",
    "recovery", "hidden", "up", "down", "left", "right", "default",
}


def literals_in(text: str, known: set[str] | None = None) -> list[str]:
    """Clip-shaped literals. A clip name has a profile/action shape; a bare word
    like "aiming" is a phase key and would otherwise be reported as an unproven
    clip forever."""
    found = []
    for literal in re.findall(r'"([a-z][a-z0-9_]*)"', text):
        if known and literal in known:
            found.append(literal)
            continue
        if literal in NON_CLIP_LITERALS:
            continue
        if "_" in literal and len(literal) >= 8:
            found.append(literal)
    return found


def renderer_in(text: str) -> str:
    """The renderer a call site drives, or "" when it is a generic helper.

    A generic helper receives its renderer as a parameter, so the honest answer
    for those is "unattributed" rather than a guess at the parameter name.
    """
    for name in RENDERERS:
        if re.search(r"\b" + re.escape(name) + r"\b", text):
            return name
    return ""


def local_literals(names: list[str], lines: list[str], funcs, site_index: int, known: set[str] | None = None) -> list[str]:
    """Clip literals assigned to `names` inside the function containing the site."""
    start = 0
    for i, _n in funcs:
        if i <= site_index:
            start = i
        else:
            break
    end = site_index
    found: list[str] = []
    for line in lines[start:end]:
        for name in names:
            if re.search(r"\b" + re.escape(name) + r"\b\s*:?=", line):
                found.extend(literals_in(line, known))
    return sorted(set(found))


#: Verbs that mean "this line selects or plays art for that renderer". Merely
#: naming a renderer is not enough: `begin_modular_damage_reaction` mentions the
#: sidearm only to hide it, and attributing its animation decisions to the
#: sidearm made that renderer look blocked by an unrelated authoring question.
DRIVING_VERBS = (
    "AnimationResolver.resolve(",
    "_animation_player.play(",
    "_show_body_layer(",
    "_show_presentation_layer(",
    ".animation =",
    "_sync_modular",
    "_play_modular",
    "_play_synchronized",
    "_sync_sidearm_action_sprite(",
    "_retarget_ranged_sprite_preserving_progress(",
)


def function_renderers(lines: list[str], funcs, site_index: int) -> list[str]:
    """Renderers the enclosing function actually selects or plays art for."""
    start = 0
    end = len(lines)
    for position, (i, _n) in enumerate(funcs):
        if i <= site_index:
            start = i
            end = funcs[position + 1][0] if position + 1 < len(funcs) else len(lines)
        else:
            break
    found: set[str] = set()
    body = lines[start:end]
    for position, line in enumerate(body):
        if not any(verb in line for verb in DRIVING_VERBS):
            continue
        # Calls are often wrapped, so the verb and its renderer argument sit on
        # different lines; match over a small window rather than one line.
        window = " ".join(body[position:position + 4])
        for renderer in RENDERERS:
            if re.search(r"\b" + re.escape(renderer) + r"\b", window):
                found.add(renderer)
    return sorted(found)


def default_literals(names: list[str], lines: list[str], funcs, site_index: int) -> list[str]:
    """Clip literals supplied as default values of the enclosing function's params."""
    signature_index = 0
    for i, _n in funcs:
        if i <= site_index:
            signature_index = i
        else:
            break
    signature = " ".join(lines[signature_index:signature_index + 3])
    found: list[str] = []
    for name in names:
        match = re.search(re.escape(name) + r'\s*:[^=]*=\s*"([a-z][a-z0-9_]*)"', signature)
        if match:
            found.append(match.group(1))
    return sorted(set(found))


def trace_renderers(name: str, files, depth: int = 0, seen: set | None = None) -> list[str]:
    """Renderers that callers pass into `name`.

    A generic layer helper receives its renderer as a parameter, so its call site
    cannot name one. Readiness is per renderer, so a helper site has to be
    attributed to every renderer its callers actually hand it — otherwise a
    renderer looks READY while a helper still selects legacy clips for it.
    """
    seen = seen or set()
    if name in seen or depth > 3:
        return []
    seen.add(name)
    found: list[str] = []
    for path, lines, funcs in files:
        for index, line in enumerate(lines):
            if line.startswith("func ") or not re.search(r"\b" + re.escape(name) + r"\s*\(", line):
                continue
            caller = enclosing(funcs, index)
            if caller == name:
                continue
            chunk = " ".join(lines[index:index + 4])
            here = [r for r in RENDERERS if re.search(r"\b" + re.escape(r) + r"\b", chunk)]
            if here:
                found.extend(here)
            else:
                found.extend(trace_renderers(caller, files, depth + 1, seen))
    return sorted(set(found))


def trace_literals(name: str, files, known: set[str], depth: int = 0, seen: set | None = None) -> tuple[list[str], list[str]]:
    """Literal clip bases reaching `name`'s animation parameter, and the trace path.

    Multi-hop because the Operator's generic layer helpers take the base clip as a
    parameter, so the literal lives one or more callers up.
    """
    seen = seen or set()
    if name in seen or depth > 3:
        return [], []
    seen.add(name)
    literals: list[str] = []
    trace: list[str] = []
    for path, lines, funcs in files:
        for index, line in enumerate(lines):
            if line.startswith("func ") or not re.search(r"\b" + re.escape(name) + r"\s*\(", line):
                continue
            caller = enclosing(funcs, index)
            if caller == name:
                continue
            chunk = " ".join(lines[index:index + 4])
            found = literals_in(chunk, known)
            if not found:
                # The caller passes a variable it built locally; resolve it there
                # before assuming the value comes from further up the chain.
                passed = re.findall(r"[A-Za-z_]\w*", chunk)
                found = local_literals(passed, lines, funcs, index, known)
            if found:
                literals.extend(found)
                trace.append(f"{caller} -> {name}: {sorted(set(found))}")
            else:
                deeper, deeper_trace = trace_literals(caller, files, known, depth + 1, seen)
                if deeper:
                    literals.extend(deeper)
                    trace.append(f"{caller} -> {name} (via caller)")
                    trace.extend(deeper_trace)
    return literals, trace


#: Worst-first, because a site is only as migratable as its least proven mapping.
SEVERITY = ("UNRESOLVED", "AUTHORING_DECISION", "MISSING_PUBLICATION", "DATA_DRIVEN",
            "RETIRED", "PROVEN")


def worst(verdicts: set[str]) -> str:
    for verdict in SEVERITY:
        if verdict in verdicts:
            return verdict
    return "UNRESOLVED"


def classify_site(site: dict) -> tuple[str, str] | None:
    """Whole-site verdicts that do not depend on a legacy clip name."""
    if site["function"] in AUTHORING_DECISIONS:
        return "AUTHORING_DECISION", AUTHORING_DECISIONS[site["function"]]
    if site["function"] in RESOLVED_BY_DECISION:
        return "PROVEN", RESOLVED_BY_DECISION[site["function"]]
    if site["function"] in DATA_DRIVEN_SITES:
        return "DATA_DRIVEN", DATA_DRIVEN_SITES[site["function"]]
    if site["debt"] == "attack_fallback_animation":
        return "PROVEN", (
            "MeleeAttackProfile.presentation_action already carries the semantic "
            "action on every attack resource (proof source B), so this field is "
            "removed rather than mapped."
        )
    return None


def classify(clip: str, evidence: dict | None) -> tuple[str, str]:
    if clip.endswith("_cape") or "_head" in clip:
        return "RETIRED", (
            "targets the modular cape/head, retired from active composition by the "
            "2026-09-12 authoring decision; art preserved, layer no longer drawn"
        )
    if clip in AUTHORING_DECISIONS:
        return "AUTHORING_DECISION", AUTHORING_DECISIONS[clip]
    if evidence is None:
        return "UNRESOLVED", "no legacy_clips row in the reachability contract"
    if not evidence["layers"]:
        return "MISSING_PUBLICATION", "canonical action has no published layers"
    return "PROVEN", "reachability legacy_clips, proof source %s" % (evidence["proof_source"] or "?")


def _display(path: Path) -> str:
    resolved = path.resolve()
    try:
        return resolved.relative_to(REPO_ROOT).as_posix()
    except ValueError:
        return resolved.as_posix()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    parser.add_argument("--markdown", type=Path)
    args = parser.parse_args(argv)

    coverage, join = load_contract()
    files = sources()

    sites: list[dict] = []
    for path, lines, funcs in files:
        relative = path.relative_to(REPO_ROOT).as_posix()
        for index, line in enumerate(lines):
            for debt, pattern in SELECTION_PATTERNS.items():
                match = pattern.search(line)
                if not match:
                    continue
                function = enclosing(funcs, index)
                argument = match.group(1).strip() if match.groups() else ""
                renderer = renderer_in(line) or renderer_in(" ".join(lines[max(0, index - 6):index + 2]))
                # Attribution order: the call line, then the enclosing function's
                # own body (an entry point composes renderers it never receives as
                # a parameter), then the callers of a generic helper. Without the
                # middle step an entry point looks renderer-less and its blockers
                # never count against the renderers it actually drives.
                renderers = [renderer] if renderer else (
                    function_renderers(lines, funcs, index) or trace_renderers(function, files))
                clips = literals_in(argument, set(join))
                trace: list[str] = []
                if not clips and debt == "animation_resolver":
                    # The value is often built locally before the call, so look in
                    # the enclosing function before walking up to callers.
                    names = re.findall(r"[A-Za-z_]\w*", argument)
                    local = local_literals(names, lines, funcs, index, set(join))
                    if not local:
                        # The literal is sometimes the parameter's own default.
                        local = default_literals(names, lines, funcs, index)
                    if local:
                        clips, trace = local, ["local assignment in %s" % function]
                    else:
                        clips, trace = trace_literals(function, files, set(join))
                clips = sorted(set(clips))
                site_verdict = classify_site({"function": function, "debt": debt})
                mappings = []
                for clip in clips:
                    evidence = join.get(clip)
                    verdict, why = classify(clip, evidence)
                    mappings.append({
                        "legacy_clip": clip, "classification": verdict, "why": why,
                        "canonical": evidence and {
                            "profile": evidence["profile"], "group": evidence["group"],
                            "action": evidence["action"], "layers": evidence["layers"],
                            "reachability_status": evidence["status"],
                        },
                    })
                # A site is retired only if EVERY renderer it drives is retired.
                retired = bool(renderers) and all(r in RETIRED_RENDERERS for r in renderers)
                sites.append({
                    "debt": debt, "file": relative, "line": index + 1, "function": function,
                    "renderer": renderer, "renderers": renderers,
                    "argument": argument, "source": line.strip(),
                    "legacy_clips": clips, "trace": trace, "mappings": mappings,
                    "classification": "RETIRED" if retired else (
                        site_verdict[0] if site_verdict else (
                            "UNRESOLVED" if not clips else worst(
                                {m["classification"] for m in mappings}))),
                    "site_reason": site_verdict[1] if site_verdict else "",
                })

    by_renderer: dict[str, list[dict]] = defaultdict(list)
    for site in sites:
        for renderer in (site["renderers"] or ["<unattributed>"]):
            by_renderer[renderer].append(site)

    readiness = {}
    for renderer, renderer_sites in by_renderer.items():
        if renderer == "<unattributed>":
            readiness[renderer] = {
                "sites": len(renderer_sites), "active": len(renderer_sites),
                "blocking": sum(1 for s in renderer_sites if s["classification"] != "PROVEN"),
                "ready": False, "unattributed": True, "blocking_detail": [],
            }
            continue
        if renderer in RETIRED_RENDERERS:
            readiness[renderer] = {
                "sites": len(renderer_sites), "active": 0, "blocking": 0,
                "ready": False, "retired": True, "blocking_detail": [],
            }
            continue
        active = [s for s in renderer_sites if s["classification"] != "RETIRED"]
        # DATA_DRIVEN blocks readiness. The mapping is proven, but the consumer
        # still receives a legacy clip name from a resource, so the renderer
        # cannot be rebound until that resource is migrated (C2a §7).
        blocking = [s for s in active if s["classification"] != "PROVEN"]
        readiness[renderer] = {
            "sites": len(renderer_sites), "active": len(active),
            "blocking": len(blocking),
            "ready": not blocking and bool(active),
            "blocking_detail": [
                {"line": s["line"], "function": s["function"],
                 "classification": s["classification"], "clips": s["legacy_clips"]}
                for s in blocking
            ],
        }

    counts: dict[str, int] = defaultdict(int)
    for site in sites:
        counts[site["classification"]] += 1

    print("Operator selection cutover evidence")
    print("=" * 74)
    for verdict, count in sorted(counts.items()):
        print(f"  {verdict:<22} {count}")
    print()
    print(f"{'renderer':<32} {'sites':>5} {'active':>6} {'blocking':>8}  ready")
    for renderer, info in sorted(readiness.items(), key=lambda kv: kv[1]["active"]):
        print("  %-30s %5d %6d %8d  %s" % (
            renderer, info["sites"], info["active"], info["blocking"],
            "RETIRED" if info.get("retired") else (
                "n/a" if info.get("unattributed") else ("READY" if info["ready"] else ""))))

    payload = {
        "schema": "custodian.operator_selection_cutover_evidence.v1",
        "counts": dict(counts), "renderer_readiness": readiness, "sites": sites,
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"\nwrote {args.report.relative_to(REPO_ROOT)}")

    if args.markdown:
        rows = ["| renderer | line | function | legacy clip | canonical | class | proof |",
                "|---|---|---|---|---|---|---|"]
        for site in sites:
            for mapping in site["mappings"] or [{"legacy_clip": "", "classification": site["classification"],
                                                 "why": "", "canonical": None}]:
                canonical = mapping["canonical"]
                rows.append("| %s | %d | %s | %s | %s | %s | %s |" % (
                    site["renderer"], site["line"], site["function"], mapping["legacy_clip"],
                    "%s/%s/%s" % (canonical["profile"], canonical["group"], canonical["action"])
                    if canonical else "", mapping["classification"], mapping["why"]))
        args.markdown.parent.mkdir(parents=True, exist_ok=True)
        args.markdown.write_text("\n".join(rows) + "\n", encoding="utf-8")
        print("wrote %s" % _display(args.markdown))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
