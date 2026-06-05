#!/usr/bin/env python3
"""Run deterministic fabrication/resource balance simulations.

The pipeline is proposal-only: it reads live recipe/resource JSON plus a
scenario file, writes a Markdown report, and writes JSON suggestions that a
human or agent can review before applying.
"""

from __future__ import annotations

import argparse
import json
import random
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_RECIPES = REPO_ROOT / "custodian" / "content" / "fabrication" / "fab_recipes.json"
DEFAULT_RESOURCES = REPO_ROOT / "custodian" / "content" / "resources" / "resource_defs.json"
DEFAULT_SCENARIO = (
    REPO_ROOT
    / "custodian"
    / "content"
    / "balance"
    / "scenarios"
    / "default_fabrication_run.json"
)
DEFAULT_OUT = REPO_ROOT / "reports" / "fabrication_balance"


ResourceMap = dict[str, int]


@dataclass(frozen=True)
class Recipe:
    recipe_id: str
    label: str
    category: str
    cost: ResourceMap
    build_seconds: float
    output_type: str
    output_id: str


@dataclass
class RunResult:
    build_id: str
    drop_profile_id: str
    seed: int
    crafted: Counter[str] = field(default_factory=Counter)
    affordability_seen: set[str] = field(default_factory=set)
    unaffordable_attempts: Counter[str] = field(default_factory=Counter)
    bottlenecks: Counter[str] = field(default_factory=Counter)
    final_resources: Counter[str] = field(default_factory=Counter)
    resource_gains: Counter[str] = field(default_factory=Counter)


@dataclass
class AggregateResult:
    build_id: str
    drop_profile_id: str
    runs: int = 0
    crafted_runs: Counter[str] = field(default_factory=Counter)
    crafted_counts: Counter[str] = field(default_factory=Counter)
    affordable_runs: Counter[str] = field(default_factory=Counter)
    unaffordable_attempts: Counter[str] = field(default_factory=Counter)
    bottlenecks: Counter[str] = field(default_factory=Counter)
    final_resources: Counter[str] = field(default_factory=Counter)
    resource_gains: Counter[str] = field(default_factory=Counter)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Simulate fabrication/resource balance and emit proposal-only changes."
    )
    parser.add_argument("--recipes", type=Path, default=DEFAULT_RECIPES)
    parser.add_argument("--resources", type=Path, default=DEFAULT_RESOURCES)
    parser.add_argument("--scenario", type=Path, default=DEFAULT_SCENARIO)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    parser.add_argument("--duration-minutes", type=int, default=None)
    parser.add_argument("--seeds", type=int, default=100)
    parser.add_argument("--seed-base", type=int, default=1701)
    parser.add_argument(
        "--drop-profile",
        action="append",
        default=None,
        help="Limit to a drop profile id. May be supplied more than once.",
    )
    parser.add_argument(
        "--build",
        action="append",
        default=None,
        help="Limit to a build id. May be supplied more than once.",
    )
    parser.add_argument(
        "--strict-lore",
        action="store_true",
        help="Exit non-zero if lore drop-table violations are found.",
    )
    return parser.parse_args()


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, sort_keys=True)
        handle.write("\n")


def rel(path: Path) -> str:
    try:
        return path.relative_to(REPO_ROOT).as_posix()
    except ValueError:
        return path.as_posix()


def parse_recipes(raw: dict[str, Any]) -> dict[str, Recipe]:
    recipes: dict[str, Recipe] = {}
    for recipe_id, data in raw.items():
        cost = {
            str(resource_id): int(amount)
            for resource_id, amount in dict(data.get("cost", {})).items()
            if int(amount) > 0
        }
        recipes[recipe_id] = Recipe(
            recipe_id=recipe_id,
            label=str(data.get("label", recipe_id)),
            category=str(data.get("category", "uncategorized")),
            cost=cost,
            build_seconds=float(data.get("build_seconds", 0.0)),
            output_type=str(data.get("output_type", "build_token")),
            output_id=str(data.get("output_id", recipe_id)),
        )
    return recipes


def can_pay(resources: ResourceMap | Counter[str], cost: ResourceMap) -> bool:
    return all(int(resources.get(resource_id, 0)) >= amount for resource_id, amount in cost.items())


def pay(resources: Counter[str], cost: ResourceMap) -> None:
    for resource_id, amount in cost.items():
        resources[resource_id] -= amount


def add_resources(resources: Counter[str], gains: ResourceMap) -> None:
    for resource_id, amount in gains.items():
        if amount > 0:
            resources[resource_id] += amount


def roll_amount(rng: random.Random, amount_spec: Any) -> int:
    if isinstance(amount_spec, list) and len(amount_spec) >= 2:
        return rng.randint(int(amount_spec[0]), int(amount_spec[1]))
    return int(amount_spec)


def roll_resource_node(source: dict[str, Any], rng: random.Random, multiplier: float) -> Counter[str]:
    count = rng.randint(int(source.get("per_run_min", 1)), int(source.get("per_run_max", 1)))
    gains: Counter[str] = Counter()
    for _ in range(max(0, count)):
        for resource_id, amount_spec in dict(source.get("yields", {})).items():
            amount = roll_amount(rng, amount_spec)
            amount = int(round(amount * multiplier))
            if amount > 0:
                gains[str(resource_id)] += amount
    return gains


def roll_enemy_drops(source: dict[str, Any], rng: random.Random, multiplier: float) -> Counter[str]:
    if rng.random() > float(source.get("encounter_chance", 1.0)):
        return Counter()
    enemy_count = rng.randint(
        int(source.get("per_encounter_min", 1)),
        int(source.get("per_encounter_max", 1)),
    )
    gains: Counter[str] = Counter()
    for _ in range(max(0, enemy_count)):
        for drop in list(source.get("drops", [])):
            chance = max(0.0, min(1.0, float(drop.get("chance", 1.0))))
            if rng.random() > chance:
                continue
            min_amount = int(drop.get("min", drop.get("amount", 1)))
            max_amount = int(drop.get("max", min_amount))
            amount = rng.randint(min_amount, max(min_amount, max_amount))
            amount = int(round(amount * multiplier))
            if amount > 0:
                gains[str(drop.get("resource_id", drop.get("id", "")))] += amount
    return gains


def score_recipe(recipe: Recipe, build: dict[str, Any], priority_index: dict[str, int]) -> tuple[float, int, str]:
    weights = dict(build.get("category_weights", {}))
    category_weight = float(weights.get(recipe.category, 1.0))
    total_cost = sum(recipe.cost.values()) or 1
    speed_bias = 1.0 / max(recipe.build_seconds, 1.0)
    score = category_weight + speed_bias - (total_cost * 0.01)
    return (-score, priority_index.get(recipe.recipe_id, 999), recipe.recipe_id)


def choose_recipe(
    resources: Counter[str],
    recipes: dict[str, Recipe],
    build: dict[str, Any],
) -> Recipe | None:
    priority = [str(item) for item in build.get("recipe_priority", [])]
    priority_index = {recipe_id: index for index, recipe_id in enumerate(priority)}
    affordable = [recipe for recipe in recipes.values() if can_pay(resources, recipe.cost)]
    if not affordable:
        return None
    return sorted(affordable, key=lambda recipe: score_recipe(recipe, build, priority_index))[0]


def record_unaffordable_pressure(
    result: RunResult,
    resources: Counter[str],
    recipes: dict[str, Recipe],
) -> None:
    for recipe in recipes.values():
        if can_pay(resources, recipe.cost):
            result.affordability_seen.add(recipe.recipe_id)
            continue
        result.unaffordable_attempts[recipe.recipe_id] += 1
        missing = {
            resource_id: amount - int(resources.get(resource_id, 0))
            for resource_id, amount in recipe.cost.items()
            if int(resources.get(resource_id, 0)) < amount
        }
        if missing:
            dominant = max(missing.items(), key=lambda item: (item[1], item[0]))[0]
            result.bottlenecks[dominant] += 1


def simulate_run(
    recipes: dict[str, Recipe],
    scenario: dict[str, Any],
    build: dict[str, Any],
    drop_profile: dict[str, Any],
    seed: int,
    duration_minutes: int,
) -> RunResult:
    rng = random.Random(seed)
    resources: Counter[str] = Counter(
        {str(k): int(v) for k, v in dict(scenario.get("starting_resources", {})).items()}
    )
    result = RunResult(
        build_id=str(build["id"]),
        drop_profile_id=str(drop_profile["id"]),
        seed=seed,
    )
    multiplier = float(drop_profile.get("multiplier", 1.0)) * float(build.get("drop_rate_multiplier", 1.0))
    encounter_interval = max(1, int(scenario.get("encounter_interval_seconds", 90)))
    steps = max(1, int(duration_minutes * 60 / encounter_interval))

    for source in list(scenario.get("resource_inflows", [])):
        if str(source.get("source_type")) == "resource_node":
            gains = roll_resource_node(source, rng, multiplier)
            add_resources(resources, gains)
            result.resource_gains.update(gains)

    for _step in range(steps):
        for source in list(scenario.get("resource_inflows", [])):
            if str(source.get("source_type")) != "enemy_drop":
                continue
            gains = roll_enemy_drops(source, rng, multiplier)
            add_resources(resources, gains)
            result.resource_gains.update(gains)

        record_unaffordable_pressure(result, resources, recipes)
        recipe = choose_recipe(resources, recipes, build)
        if recipe is None:
            continue
        pay(resources, recipe.cost)
        result.crafted[recipe.recipe_id] += 1

    record_unaffordable_pressure(result, resources, recipes)
    result.final_resources.update(resources)
    return result


def aggregate(results: list[RunResult]) -> dict[tuple[str, str], AggregateResult]:
    aggregates: dict[tuple[str, str], AggregateResult] = {}
    for result in results:
        key = (result.build_id, result.drop_profile_id)
        if key not in aggregates:
            aggregates[key] = AggregateResult(*key)
        aggregate_result = aggregates[key]
        aggregate_result.runs += 1
        aggregate_result.crafted_counts.update(result.crafted)
        aggregate_result.unaffordable_attempts.update(result.unaffordable_attempts)
        aggregate_result.bottlenecks.update(result.bottlenecks)
        aggregate_result.final_resources.update(result.final_resources)
        aggregate_result.resource_gains.update(result.resource_gains)
        for recipe_id in result.crafted:
            aggregate_result.crafted_runs[recipe_id] += 1
        for recipe_id in result.affordability_seen:
            aggregate_result.affordable_runs[recipe_id] += 1
    return aggregates


def validate_lore(scenario: dict[str, Any], resources: dict[str, Any]) -> list[dict[str, Any]]:
    rules = dict(scenario.get("lore_rules", {})).get("enemy_role_rules", {})
    violations: list[dict[str, Any]] = []
    for source in list(scenario.get("resource_inflows", [])):
        if str(source.get("source_type")) != "enemy_drop":
            continue
        role = str(source.get("enemy_role", ""))
        rule = dict(rules.get(role, {}))
        if not rule:
            continue
        source_id = str(source.get("source_id", "unknown"))
        source_tags = set(str(tag) for tag in list(source.get("story_tags", [])))
        required_tags = set(str(tag) for tag in list(rule.get("required_story_tags_any", [])))
        if required_tags and not source_tags.intersection(required_tags):
            violations.append(
                {
                    "source_id": source_id,
                    "enemy_role": role,
                    "issue": "missing_required_story_tag",
                    "required_any": sorted(required_tags),
                    "actual": sorted(source_tags),
                }
            )
        allowed_resources = set(str(item) for item in list(rule.get("allowed_resources", [])))
        actual_resources = [
            str(drop.get("resource_id", drop.get("id", "")))
            for drop in list(source.get("drops", []))
        ]
        if allowed_resources:
            for resource_id in actual_resources:
                if resource_id not in allowed_resources:
                    violations.append(
                        {
                            "source_id": source_id,
                            "enemy_role": role,
                            "issue": "drop_resource_outside_role_theme",
                            "resource_id": resource_id,
                            "allowed": sorted(allowed_resources),
                        }
                    )
        required_drops = set(str(item) for item in list(rule.get("required_drop_resources_any", [])))
        if required_drops and not required_drops.intersection(actual_resources):
            violations.append(
                {
                    "source_id": source_id,
                    "enemy_role": role,
                    "issue": "missing_required_story_drop",
                    "required_any": sorted(required_drops),
                    "actual": actual_resources,
                }
            )
        for resource_id in actual_resources:
            if resource_id and resource_id not in resources:
                violations.append(
                    {
                        "source_id": source_id,
                        "enemy_role": role,
                        "issue": "drop_resource_missing_definition",
                        "resource_id": resource_id,
                    }
                )
    return violations


def analyze(
    aggregates: dict[tuple[str, str], AggregateResult],
    recipes: dict[str, Recipe],
    scenario: dict[str, Any],
    lore_violations: list[dict[str, Any]],
) -> dict[str, Any]:
    thresholds = dict(scenario.get("analysis", {}))
    never_affordable_threshold = float(thresholds.get("never_affordable_threshold", 0.05))
    always_optimal_threshold = float(thresholds.get("always_optimal_threshold", 0.82))
    never_chosen_threshold = float(thresholds.get("never_chosen_threshold", 0.03))

    recipe_affordable_runs: Counter[str] = Counter()
    recipe_crafted_runs: Counter[str] = Counter()
    recipe_crafted_counts: Counter[str] = Counter()
    total_runs = 0
    bottlenecks: Counter[str] = Counter()
    resource_gains: Counter[str] = Counter()
    final_resources: Counter[str] = Counter()

    for aggregate_result in aggregates.values():
        total_runs += aggregate_result.runs
        recipe_affordable_runs.update(aggregate_result.affordable_runs)
        recipe_crafted_runs.update(aggregate_result.crafted_runs)
        recipe_crafted_counts.update(aggregate_result.crafted_counts)
        bottlenecks.update(aggregate_result.bottlenecks)
        resource_gains.update(aggregate_result.resource_gains)
        final_resources.update(aggregate_result.final_resources)

    never_affordable = []
    always_optimal = []
    never_chosen = []
    recipe_stats = {}
    for recipe_id, recipe in recipes.items():
        affordable_rate = recipe_affordable_runs[recipe_id] / max(1, total_runs)
        chosen_rate = recipe_crafted_runs[recipe_id] / max(1, total_runs)
        avg_crafted = recipe_crafted_counts[recipe_id] / max(1, total_runs)
        recipe_stats[recipe_id] = {
            "label": recipe.label,
            "category": recipe.category,
            "affordable_rate": round(affordable_rate, 4),
            "chosen_rate": round(chosen_rate, 4),
            "average_crafted_per_run": round(avg_crafted, 4),
        }
        if affordable_rate < never_affordable_threshold:
            never_affordable.append(recipe_id)
        if chosen_rate >= always_optimal_threshold:
            always_optimal.append(recipe_id)
        if chosen_rate <= never_chosen_threshold:
            never_chosen.append(recipe_id)

    return {
        "total_runs": total_runs,
        "recipe_stats": recipe_stats,
        "never_affordable": never_affordable,
        "always_optimal": always_optimal,
        "never_chosen": never_chosen,
        "bottlenecks": dict(bottlenecks.most_common()),
        "resource_gains": dict(resource_gains.most_common()),
        "final_resources": dict(final_resources.most_common()),
        "lore_violations": lore_violations,
    }


def propose_changes(
    analysis: dict[str, Any],
    recipes: dict[str, Recipe],
    scenario: dict[str, Any],
) -> dict[str, Any]:
    bottlenecks = Counter(analysis.get("bottlenecks", {}))
    proposals: list[dict[str, Any]] = []
    for recipe_id in analysis.get("never_affordable", []):
        recipe = recipes[recipe_id]
        if not recipe.cost:
            continue
        limiting = [
            resource_id
            for resource_id in recipe.cost
            if bottlenecks.get(resource_id, 0) > 0
        ]
        if not limiting:
            limiting = [max(recipe.cost.items(), key=lambda item: (item[1], item[0]))[0]]
        new_cost = dict(recipe.cost)
        for resource_id in limiting:
            new_cost[resource_id] = max(1, int(round(new_cost[resource_id] * 0.8)))
        proposals.append(
            {
                "target": "recipe",
                "id": recipe_id,
                "reason": "recipe_below_affordability_threshold_in_30_minute_runs",
                "current": {"cost": recipe.cost},
                "proposed": {"cost": new_cost},
            }
        )

    for recipe_id in analysis.get("always_optimal", []):
        recipe = recipes[recipe_id]
        new_cost = {
            resource_id: max(amount + 1, int(round(amount * 1.15)))
            for resource_id, amount in recipe.cost.items()
        }
        proposals.append(
            {
                "target": "recipe",
                "id": recipe_id,
                "reason": "recipe_chosen_across_too_many_runs_and_builds",
                "current": {"cost": recipe.cost},
                "proposed": {"cost": new_cost},
            }
        )

    for violation in analysis.get("lore_violations", []):
        proposals.append(
            {
                "target": "drop_table",
                "id": violation.get("source_id", "unknown"),
                "reason": "drop_table_theme_violation",
                "current": violation,
                "proposed": {
                    "action": "restrict_drop_resources_to_role_theme",
                    "note": "Drop tables should tell what the enemy was doing, not act as generic currency.",
                },
            }
        )

    saboteur_sources = [
        source
        for source in list(scenario.get("resource_inflows", []))
        if str(source.get("enemy_role", "")) == "grunt_saboteur"
    ]
    for source in saboteur_sources:
        proposals.append(
            {
                "target": "drop_table",
                "id": str(source.get("source_id")),
                "reason": "drop_tells_story_rule",
                "current": {
                    "enemy_role": source.get("enemy_role"),
                    "sabotage_target": source.get("sabotage_target"),
                    "drops": source.get("drops", []),
                },
                "proposed": {
                    "enemy_role": "grunt_saboteur",
                    "drop_identity": "sabotage_target_salvage",
                    "allowed_resources": [
                        "signal_filament",
                        "ruin_scrap",
                        "memory_glass_fragment",
                    ],
                    "rule": "Saboteur drops should reveal the target they were sabotaging.",
                },
            }
        )

    return {
        "schema": "custodian.fabrication_balance.proposals.v1",
        "proposal_only": True,
        "scenario_id": scenario.get("scenario_id", "unknown"),
        "changes": proposals,
    }


def render_report(
    recipes: dict[str, Recipe],
    scenario: dict[str, Any],
    aggregates: dict[tuple[str, str], AggregateResult],
    analysis: dict[str, Any],
    proposal_path: Path,
) -> str:
    lines = [
        "# Fabrication Balance Report",
        "",
        f"Scenario: `{scenario.get('scenario_id', 'unknown')}`",
        f"Duration: `{scenario.get('duration_minutes', 30)}` minutes",
        f"Total runs: `{analysis['total_runs']}`",
        f"Proposal JSON: `{rel(proposal_path)}`",
        "",
        "## Flags",
        "",
        f"- Never affordable: {', '.join(analysis['never_affordable']) or 'none'}",
        f"- Always optimal: {', '.join(analysis['always_optimal']) or 'none'}",
        f"- Never chosen: {', '.join(analysis['never_chosen']) or 'none'}",
        f"- Lore violations: {len(analysis['lore_violations'])}",
        "",
        "## Recipe Outcomes",
        "",
        "| Recipe | Category | Affordable rate | Chosen rate | Avg crafted/run |",
        "|---|---:|---:|---:|---:|",
    ]
    for recipe_id in sorted(recipes):
        stats = analysis["recipe_stats"][recipe_id]
        lines.append(
            "| {recipe} | {category} | {affordable:.2%} | {chosen:.2%} | {avg:.2f} |".format(
                recipe=recipe_id,
                category=stats["category"],
                affordable=float(stats["affordable_rate"]),
                chosen=float(stats["chosen_rate"]),
                avg=float(stats["average_crafted_per_run"]),
            )
        )

    lines.extend(["", "## Build And Drop Profile Matrix", ""])
    lines.append("| Build | Drop profile | Runs | Top crafted | Top bottlenecks |")
    lines.append("|---|---|---:|---|---|")
    for key in sorted(aggregates):
        aggregate_result = aggregates[key]
        top_crafted = ", ".join(
            f"{recipe_id}:{count}"
            for recipe_id, count in aggregate_result.crafted_counts.most_common(4)
        ) or "none"
        top_bottlenecks = ", ".join(
            f"{resource_id}:{count}"
            for resource_id, count in aggregate_result.bottlenecks.most_common(4)
        ) or "none"
        lines.append(
            f"| {aggregate_result.build_id} | {aggregate_result.drop_profile_id} | "
            f"{aggregate_result.runs} | {top_crafted} | {top_bottlenecks} |"
        )

    lines.extend(["", "## Resource Pressure", ""])
    lines.append("Top bottlenecks:")
    for resource_id, count in Counter(analysis["bottlenecks"]).most_common(10):
        lines.append(f"- `{resource_id}`: {count}")
    lines.append("")
    lines.append("Top gained resources:")
    for resource_id, count in Counter(analysis["resource_gains"]).most_common(10):
        lines.append(f"- `{resource_id}`: {count}")

    lines.extend(["", "## Lore Drop Table Review", ""])
    if analysis["lore_violations"]:
        for violation in analysis["lore_violations"]:
            lines.append(f"- `{violation.get('source_id')}`: {violation.get('issue')}")
    else:
        lines.append("- No lore rule violations detected.")
    lines.append(
        "- Rule enforced: drops should reveal faction role, objective, and target context instead of generic currency."
    )

    lines.extend(["", "## Proposal Contract", ""])
    lines.append("- Proposals are JSON-only and written separately from runtime data.")
    lines.append("- The pipeline does not apply balance changes automatically.")
    lines.append("- Review `changes[]` in the proposal JSON before editing live recipe/drop data.")
    lines.append("")
    return "\n".join(lines)


def filter_by_ids(items: list[dict[str, Any]], ids: list[str] | None) -> list[dict[str, Any]]:
    if not ids:
        return items
    allowed = set(ids)
    return [item for item in items if str(item.get("id")) in allowed]


def main() -> int:
    args = parse_args()
    raw_recipes = load_json(args.recipes)
    resources = load_json(args.resources)
    scenario = load_json(args.scenario)
    if args.duration_minutes is not None:
        scenario["duration_minutes"] = args.duration_minutes

    recipes = parse_recipes(raw_recipes)
    builds = filter_by_ids(list(scenario.get("builds", [])), args.build)
    drop_profiles = filter_by_ids(list(scenario.get("drop_profiles", [])), args.drop_profile)
    if not builds:
        raise SystemExit("No builds selected.")
    if not drop_profiles:
        raise SystemExit("No drop profiles selected.")

    duration_minutes = int(scenario.get("duration_minutes", 30))
    results: list[RunResult] = []
    for build_index, build in enumerate(builds):
        for profile_index, drop_profile in enumerate(drop_profiles):
            for seed_offset in range(args.seeds):
                seed = args.seed_base + build_index * 100000 + profile_index * 10000 + seed_offset
                results.append(
                    simulate_run(
                        recipes=recipes,
                        scenario=scenario,
                        build=build,
                        drop_profile=drop_profile,
                        seed=seed,
                        duration_minutes=duration_minutes,
                    )
                )

    lore_violations = validate_lore(scenario, resources)
    aggregates = aggregate(results)
    analysis = analyze(aggregates, recipes, scenario, lore_violations)
    proposals = propose_changes(analysis, recipes, scenario)

    args.out.mkdir(parents=True, exist_ok=True)
    report_path = args.out / "fabrication_balance_report.md"
    proposal_path = args.out / "proposed_changes.json"
    summary_path = args.out / "summary.json"

    write_json(proposal_path, proposals)
    write_json(summary_path, {"analysis": analysis, "scenario": scenario.get("scenario_id")})
    report_path.write_text(
        render_report(recipes, scenario, aggregates, analysis, proposal_path),
        encoding="utf-8",
    )

    print(f"report: {rel(report_path)}")
    print(f"proposal: {rel(proposal_path)}")
    print(f"summary: {rel(summary_path)}")
    print(f"runs: {analysis['total_runs']}")
    print(f"lore_violations: {len(lore_violations)}")

    if args.strict_lore and lore_violations:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
