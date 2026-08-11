# Agent Headless Test Layer

Design authority for the thin, standardized headless testing layer that makes the game's validation stack directly usable by AI agents. Items 1–4 are implemented V1; the rest is sequenced follow-up.

Status: **implemented V1** — the manifest runner, shared harness, relational Moment Forge assertions, read-only actor snapshots, and dotted snapshot probes are live. Builds on existing foundations; explicitly does **not** introduce GUT/GdUnit or another parallel framework.

## Why

Headless testability is already unusually good, but the tests are powerful yet bespoke. Two weaknesses matter for AI-driven bug testing:

1. **Tests are coupled to implementation internals.** `operator.set("_dodge_iframe_timer", 0.1)` breaks when the dodge representation changes even if gameplay behavior is still correct, and a test can construct state the real game could never reach.
2. **Every smoke reinvents scaffolding.** Each one re-implements scene-root creation, actor spawning, autoload lookup/reset, physics-frame waiting, assert helpers, event search, cleanup, input release, exit-code handling, and failure formatting — code an agent must understand and write for every bug.

The pattern to push gameplay logic toward is the pure resolver test: `operator_melee_soft_targeting_smoke.gd` feeds inputs into `MeleeTargetResolver` and tests invariants without booting half the game.

## Foundations (build on these)

- `custodian/tools/validation/` — large `SceneTree` headless smoke set; canonical command-selection guide `custodian/docs/ai_context/VALIDATION_RECIPES.md`.
- Moment Forge — deterministic seeded, fixed-tick scene execution, role resolution, action injection, telemetry, and stable assertions. Authority: `design/02_features/debug_ui/MOMENT_FORGE_SYSTEM.md`.
- Changed-file routing — `custodian/tools/iteration/changed_file_router.py` already exposes `changed_files()`; reuse it rather than inventing another git-diff parser.

## V1 Pieces

### 1. Shared headless harness

Path: `custodian/tools/validation/support/headless_test_harness.gd`

```gdscript
extends RefCounted
class_name HeadlessTestHarness

var tree: SceneTree
var failures: Array[Dictionary] = []
var fixture_root: Node
var observatory: Node

func configure(p_tree: SceneTree, test_name: String) -> void
func expect(condition: bool, message: String, evidence := {}) -> void
func expect_eq(actual: Variant, expected: Variant, message: String) -> void
func expect_approx(actual: float, expected: float, epsilon: float, message: String) -> void
func recent_event(kind: StringName, predicate: Callable = Callable()) -> Dictionary
func wait_physics_ticks(count: int) -> void   # awaits tree.physics_frame
```

Behavior contract:

- `configure()` creates a `%sFixture` root under the tree, sets `tree.current_scene` to it, resolves `/root/DevObservatory`, and clears observatory state.
- `recent_event()` searches `observatory.get_recent_events(100, kind)` and matches an optional predicate against each event's `data`.
- Failures accumulate as `{ "message", "evidence" }` dictionaries; formatting and exit-code handling live in the runner, not in each smoke.

Every smoke then stops reinventing assertion plumbing; agent-authored tests become materially smaller.

### 2. Machine-readable validation manifest + runner (highest ROI)

Files:

- `custodian/tools/validation/validation_manifest.json`
- `custodian/tools/validation/run_validation.py`

Manifest entry fields: `id`, `type` (`godot_script`), `script` (`res://` path), `tags`, `owners` (globs), `timeout_sec`, `needs_import`, `tier`.

```json
{
  "id": "operator_dodge_overlap",
  "type": "godot_script",
  "script": "res://tools/validation/operator_dodge_overlap_telemetry_smoke.gd",
  "tags": ["combat", "operator", "dodge"],
  "owners": ["custodian/game/actors/operator/operator.gd", "custodian/game/systems/combat/**"],
  "timeout_sec": 30,
  "needs_import": false,
  "tier": "actor"
}
```

CLI:

```bash
python3 custodian/tools/validation/run_validation.py --changed
python3 custodian/tools/validation/run_validation.py --tag combat --json
python3 custodian/tools/validation/run_validation.py --test operator_dodge_overlap
```

Rules:

- Reuse `changed_files()` from `changed_file_router.py`; no new git-diff parser.
- JSON output contract an agent can consume cheaply:

```json
{
  "passed": false,
  "duration_sec": 4.18,
  "tests": [
    { "id": "operator_dodge_overlap", "status": "pass", "duration_ms": 481 },
    {
      "id": "enemy_hit_spatial",
      "status": "fail",
      "duration_ms": 337,
      "failures": [ { "message": "Marine hit exceeded lateral contact lane", "actual": 26.4, "expected_max": 23.7 } ]
    }
  ]
}
```

- Per-test timeout enforced by the Python supervisor: a hung generated smoke becomes `FAIL: timeout after 30 seconds` instead of an agent waiting forever.
- Tier-ordered cheapest-first selection (see Tiers): if Tier 0 fails, do not waste 30 seconds running Moment Forge.

### 3. Moment Forge assertion extensions

Current vocabulary: `role_exists`, `warning_count`, `event_count`, `counter_value`, `probe_compare`, `metric_compare`, `output_exists`, `event_order`.

Add: `event_field_compare`, `event_exactly_once`, `event_absent`, `event_same_field`, `role_distance_compare`, `probe_stable`, `probe_never`, `probe_changed`, `event_between_ticks`.

Examples:

```json
{
  "type": "event_field_compare",
  "event": "marine_dash_hit_resolved",
  "where": { "data.attack_id": "$last" },
  "field": "data.spatial_valid",
  "op": "eq",
  "value": true
}
```

```json
{
  "type": "event_same_field",
  "events": ["marine_dash_hit_resolved", "incoming_hit_result"],
  "field": "data.attack_id"
}
```

```json
{ "type": "event_exactly_once", "event": "marine_dash_hit_resolved" }
```

Effect: a cheapshot bug test becomes a ~20-line JSON scenario instead of a ~200-line GDScript smoke.

### 4. Standardized read-only actor snapshots

Formalize the existing convention — `get_behavior_snapshot()` (enemy.gd), `get_weapon_status()` (operator.gd) — into `get_debug_snapshot() -> Dictionary` on major gameplay owners.

Operator shape:

```json
{
  "health": "...", "stamina": "...",
  "combat": { "attack_phase": "...", "melee_forward": "...", "committed_target_id": "..." },
  "dodge": { "phase": "<get_dodge_telemetry_phase()>", "iframe_remaining": "...", "recovery_active": "..." },
  "weapon": "<get_weapon_status()>",
  "targeting": "<get_melee_targeting_status()>"
}
```

Enemy shape:

```json
{
  "health": "...",
  "behavior": "<get_behavior_snapshot()>",
  "attack": { "id": "...", "type": "...", "phase": "...", "target_id": "..." },
  "position": "<global_position>"
}
```

These APIs are read-only diagnostics — never simulation influence. Moment Forge probes then support dotted-path snapshot fields:

```json
{
  "id": "operator_combat",
  "role": "operator",
  "snapshot": "debug",
  "fields": ["dodge.phase", "combat.attack_phase", "weapon.loaded_ammo"]
}
```

That is dramatically more resilient than `operator.get("_dodge_recovery_active")` and gives an agent a stable vocabulary for runtime state.

### 5. Pure gameplay mathematics extraction

Extract functional cores into `RefCounted` helpers wherever meaningful logic exists: hit geometry, attack eligibility, target scoring, damage scaling, spread calculation, dodge classification, weapon heat transitions, ammo reconciliation, attack phase transition decisions.

Actor lifecycle and actual physics stay on actors. Example:

```gdscript
OperatorDodgeResolver.classify(charge_active, dodge_active, iframe_remaining, recovery_active)
```

An integration smoke then only proves `real Operator state → resolver inputs → correct gameplay result` instead of exercising every truth table through a full actor scene.

## Tiers

| Tier | Kind | Contents | Target |
|------|------|----------|--------|
| 0 | PURE | No scene tree / no physics. Resolvers, geometry, state transitions. | <100 ms |
| 1 | ACTOR | Minimal fixture + actual actor scene. Operator, enemy, projectile interactions. | <1–3 s |
| 2 | INTEGRATION | Real subsystem/debug scene. Procgen, route traversal, HUD wiring. | <5–15 s |
| 3 | MOMENT | Deterministic gameplay sequence. Telemetry/assertions, optionally capture. | seconds |
| 4 | FULL BOOT | Main scene / import / resource regression. Run only when ownership or routing demands it. | — |

`run_validation.py --changed` selects the cheapest proof first; a Tier 0 failure short-circuits higher tiers.

## Observatory → Repro Capsule (later phase)

Turning an F10 Observatory session diagnosis into an executable reproduction is currently manual. Add:

- `custodian/tools/analysis/build_combat_repro.py` — converts an Observatory session export into `reports/repros/<timestamp>/repro.json` holding whatever minimal combat state the Observatory knows: `kind`, `attack_id`, `attacker_scene`, attacker/target positions, target health, dodge phase, attack type, and contact geometry (forward/lateral px vs allowed).
- `custodian/tools/validation/run_repro.py` — reproduces the minimal combat state.

Not arbitrary save-state replay, and it should not pretend to be — Moment Forge's design explicitly keeps human-session replay out of scope. Effective targets: impossible melee contact, bad dodge classification, projectile spawn mismatch, range boundary failures, target-selection errors.

## Headless Warning Noise Policy

`VALIDATION_RECIPES.md` currently notes headless runs may exit with existing object/resource leak warnings. Humans learn to ignore the same four benign warnings; agents cannot reliably tell whether warning #5 is the same benign issue or a new regression.

Invariant (eventual): **zero unexplained headless warnings**. Until the existing leaks are fixed, `run_validation.py` classifies stderr as `KNOWN BASELINE WARNING` / `NEW WARNING` / `FATAL`. Never silently suppress stderr — preserve signal while removing noise.

## Priority Order

1. `validation_manifest.json` + `run_validation.py --changed --json`
2. shared `headless_test_harness.gd`
3. Moment Forge `event_field_compare` / `event_exactly_once` / `event_same_field`
4. standardized actor debug snapshots + dotted-path probes
5. migrate the worst private-state-poking smokes
6. Observatory → combat repro capsule
7. later: systematic extraction of additional pure gameplay resolvers

Items 1–4 are live. The remaining items are follow-up and must preserve the same ownership split.

## AI Usage Contract

One command replaces "run these 11 commands and read the output":

```bash
python3 custodian/tools/validation/run_validation.py --changed --json
```

Expected result: `3 relevant tests / 2 passed / 1 failed`, with per-failure attack id, expected vs actual values, and tick — an interface an agent can iterate against cheaply. Fits existing project rules: fixed-step determinism and rendering/UI separation are already explicit requirements.

## Next Agent Slice

- Expand manifest coverage opportunistically when feature work touches an unregistered high-value smoke.
- Migrate bespoke smoke scaffolding only when those tests are already being changed.
- Consider the Observatory repro capsule after the V1 runner has accumulated practical use.
- Complete warning-baseline cleanup rather than broadening suppression patterns.
