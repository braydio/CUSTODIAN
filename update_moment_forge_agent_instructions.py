#!/usr/bin/env python3
"""Activate Moment Forge guidance across CUSTODIAN agent instructions.

Run from the repository root after Moment Forge V1 exists. The script is
idempotent and refuses to activate guidance while the CLI/spec are missing.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import sys

ROOT = Path.cwd()
SENTINEL = "<!-- MOMENT_FORGE_AGENT_GUIDANCE_V1 -->"


class PatchError(RuntimeError):
    pass


def read(path: Path) -> str:
    if not path.is_file():
        raise PatchError(f"Missing required file: {path}")
    return path.read_text(encoding="utf-8")


def write(path: Path, text: str, dry_run: bool) -> None:
    if dry_run:
        print(f"WOULD UPDATE {path}")
        return
    path.write_text(text, encoding="utf-8")
    print(f"UPDATED {path}")


def insert_before(path: Path, marker: str, block: str, dry_run: bool) -> None:
    text = read(path)
    if SENTINEL in text:
        print(f"SKIP {path} (already updated)")
        return
    if marker not in text:
        raise PatchError(f"Marker not found in {path}: {marker!r}")
    updated = text.replace(marker, block.rstrip() + "\n\n" + marker, 1)
    write(path, updated, dry_run)


def insert_after(path: Path, marker: str, block: str, dry_run: bool) -> None:
    text = read(path)
    if SENTINEL in text:
        print(f"SKIP {path} (already updated)")
        return
    if marker not in text:
        raise PatchError(f"Marker not found in {path}: {marker!r}")
    updated = text.replace(marker, marker + "\n" + block.rstrip(), 1)
    write(path, updated, dry_run)


def update_tooling_router(path: Path, dry_run: bool) -> None:
    text = read(path)
    if SENTINEL in text:
        print(f"SKIP {path} (already updated)")
        return
    text = text.replace("Last updated: 2026-06-19", "Last updated: 2026-07-29", 1)
    marker = "## Related Runtime Validation"
    if marker not in text:
        raise PatchError(f"Marker not found in {path}: {marker!r}")
    block = f"""{SENTINEL}
## Deterministic Gameplay Moment Review

Use Moment Forge when the ask depends on reproducing and comparing a short player-perceived moment: combat weight, contact timing, animation/FX alignment, SFX synchronization, displacement, healing commit, camera behavior, or curated vista presentation.

Start with scenario selection:

```bash
python3 custodian/tools/iteration/run_moment.py --changed
```

The selector is cheap and advisory. Review its reasons, then run the smallest relevant scenario explicitly; do not use `--execute-suggested` blindly.

```bash
python3 custodian/tools/iteration/run_moment.py combat/light_hit_grunt --capture-mode none
python3 custodian/tools/iteration/run_moment.py combat/light_hit_grunt --capture-mode evidence
python3 custodian/tools/iteration/run_moment.py combat/light_hit_grunt --capture-mode full
```

Use:

- `none` for deterministic assertions and stable fingerprints;
- `evidence` for telemetry plus authored-tick keyframes;
- `full` when acceptance depends on audiovisual timing, readability, feel, or baseline comparison.

Focused smoke tests remain the authority for narrow stable logic. Moment Forge supplements them with repeatable experiential evidence. Skip Moment Forge for docs-only work, tooling-only changes, or refactors with no plausible runtime/presentation effect; state the reason in the completion report.

Never accept or replace a baseline automatically. Generated evidence belongs under `reports/moment_forge/`.
"""
    updated = text.replace(marker, block.rstrip() + "\n\n" + marker, 1)
    write(path, updated, dry_run)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument(
        "--allow-preimplementation",
        action="store_true",
        help="Allow editing before the Moment Forge CLI exists (not recommended).",
    )
    args = parser.parse_args()

    cli = ROOT / "custodian/tools/iteration/run_moment.py"
    spec = ROOT / "design/02_features/debug_ui/MOMENT_FORGE_SYSTEM.md"
    if not args.allow_preimplementation:
        missing = [str(p) for p in (cli, spec) if not p.is_file()]
        if missing:
            raise PatchError(
                "Refusing to activate Moment Forge agent guidance before implementation. "
                f"Missing: {', '.join(missing)}"
            )

    root_agents = ROOT / "AGENTS.md"
    root_block = f"""{SENTINEL}
- deterministic micro-playtest review: route through `custodian/AGENTS.md`, `design/02_features/debug_ui/MOMENT_FORGE_SYSTEM.md`, and the Moment Forge section of `custodian/docs/ai_context/VALIDATION_RECIPES.md`.
"""
    insert_after(
        root_agents,
        "- validation: `custodian/docs/ai_context/VALIDATION_RECIPES.md` and `custodian/tools/validation/`",
        root_block,
        args.dry_run,
    )

    local_agents = ROOT / "custodian/AGENTS.md"
    local_block = f"""\n{SENTINEL}

## Moment Forge Selection

Use Moment Forge for repeatable 2–8 second gameplay moments whose acceptance depends on timing, audiovisual synchronization, movement/displacement, readability, camera composition, or game feel.

1. After changing combat timing, animation playback or assets, VFX, SFX, healing presentation, attack movement, camera behavior, or curated vista presentation, run:

   ```bash
   python3 custodian/tools/iteration/run_moment.py --changed
   ```

2. Treat selection output as advice. Run the smallest relevant scenario explicitly; do not invoke every suggestion or use `--execute-suggested` without reviewing the matched paths and reasons.
3. Use `--capture-mode none` for deterministic assertions/fingerprints, `evidence` for telemetry and keyframes, and `full` when acceptance depends on audiovisual timing, readability, feel, or baseline comparison.
4. Focused smoke tests remain required for stable logic contracts. Moment Forge is additional experiential/regression evidence, not a replacement for narrow validation.
5. Moment Forge may be skipped for docs-only changes, tooling-only work, generated review artifacts, or refactors with no plausible runtime/presentation effect. State `Moment Forge: not run — <reason>` in the completion report.
6. When a repeatable high-value regression lacks a scenario, propose or add the narrowest stable scenario when it belongs to the task. Do not block unrelated work solely because scenario coverage is absent.
7. Never approve or replace a baseline automatically. Baseline acceptance requires explicit developer judgment.
8. Record scenario IDs, capture mode, pass/fail status, and report path under task completion or handoff. Reports belong under `reports/moment_forge/`, never runtime content.
"""
    insert_before(local_agents, "## Reusable Context Fetch Pipeline", local_block, args.dry_run)

    validation = ROOT / "custodian/docs/ai_context/VALIDATION_RECIPES.md"
    validation_block = f"""{SENTINEL}
## Moment Forge Selection And Evidence

Use Moment Forge after stable focused validation when a change can affect a short reproducible gameplay/presentation moment.

Cheap selection for the current worktree:

```bash
python3 custodian/tools/iteration/run_moment.py --changed
```

Selection for committed branch changes:

```bash
python3 custodian/tools/iteration/run_moment.py --changed --base origin/main
```

Run the smallest relevant scenario:

```bash
# Logic and deterministic fingerprint only
python3 custodian/tools/iteration/run_moment.py <scenario-id> --capture-mode none

# Telemetry plus authored-tick keyframes
python3 custodian/tools/iteration/run_moment.py <scenario-id> --capture-mode evidence

# Full audiovisual/game-feel review
python3 custodian/tools/iteration/run_moment.py <scenario-id> --capture-mode full
```

Use `full` for combat feel, animation/FX/SFX synchronization, camera/vista composition, and baseline comparison. Use `none` or `evidence` for routine deterministic regression checks. Full captures are not a default CI requirement.

Repeatability proof:

```bash
python3 custodian/tools/iteration/run_moment.py \\
  <scenario-id> \\
  --capture-mode none \\
  --repeat 2 \\
  --require-identical-stable-fingerprint
```

Core suite:

```bash
bash custodian/tools/validation/run_moment_forge_suite.sh
```

Completion reports must include one of:

```text
Moment Forge: <scenario-id> (<mode>) — PASS — reports/moment_forge/...
Moment Forge: not run — <specific reason>
```

Do not accept a baseline automatically, and do not fail CI on advisory pixel/audio deltas.
"""
    insert_before(validation, "## Common Commands", validation_block, args.dry_run)

    tooling = ROOT / "custodian/docs/ai_context/AGENT_TOOLING_BY_ASK.md"
    update_tooling_router(tooling, args.dry_run)

    implement_prompt = ROOT / "custodian/docs/ai_context/prompts/implement_runtime_feature.md"
    implement_block = f"""{SENTINEL}
- When the diff can affect a repeatable gameplay/presentation moment and Moment Forge is available, run `python3 custodian/tools/iteration/run_moment.py --changed`, review its reasons, and execute the smallest relevant scenario. Record the scenario/mode/report path or a specific not-run reason.
"""
    insert_after(
        implement_prompt,
        "- Follow `custodian/docs/ai_context/VALIDATION_RECIPES.md`.",
        implement_block,
        args.dry_run,
    )

    review_prompt = ROOT / "custodian/docs/ai_context/prompts/review_runtime_change.md"
    review_block = f"""{SENTINEL}
- missing Moment Forge evidence when the change affects a repeatable audiovisual/game-feel moment
"""
    insert_after(review_prompt, "- missing validation", review_block, args.dry_run)

    tune_prompt = ROOT / "custodian/docs/ai_context/prompts/tune_combat_feel.md"
    tune_block = f"""{SENTINEL}
- Run `python3 custodian/tools/iteration/run_moment.py --changed`, select the smallest relevant combat scenario, and use `--capture-mode full` when judging weight, contact timing, animation/FX/SFX synchronization, hitstop, recoil, or displacement. Keep focused combat smokes for stable logic and never accept a baseline automatically.
"""
    insert_after(
        tune_prompt,
        "- Follow `custodian/docs/ai_context/VALIDATION_RECIPES.md`.",
        tune_block,
        args.dry_run,
    )

    file_index = ROOT / "custodian/docs/ai_context/FILE_INDEX.md"
    index_block = f"""{SENTINEL}
- `design/02_features/debug_ui/MOMENT_FORGE_SYSTEM.md` — active deterministic micro-playtest, capture, baseline, and comparison contract
- `custodian/tools/iteration/run_moment.py` — Moment Forge CLI for scenario listing, changed-file selection, execution, and report orchestration
- `custodian/tools/iteration/scenarios/` — versioned curated Moment Forge scenario registry
- `reports/moment_forge/` — generated review evidence; never runtime content or automatic baseline authority
"""
    insert_after(
        file_index,
        "- `custodian/docs/ai_context/AGENT_TOOLING_BY_ASK.md` — ask-specific tooling router for agent work, currently covering modular Operator asset audit/review scripts and their caveats",
        index_block,
        args.dry_run,
    )

    print("\nManual follow-up:")
    print("- Update CURRENT_STATE.md with the actually implemented Moment Forge phase/scenarios.")
    print("- Update CONTEXT.md only if the selection rule is adopted as a project-wide workflow contract.")
    print("- Run doc-path validation plus the Moment Forge suite.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except PatchError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(2)
