# Design Codex Tracker

Purpose: keep `design/90_codex/` governable without making it active implementation authority.

The Design Codex is an idea inventory and design memory layer. It preserves promising systems, mechanics, world-design doctrines, and tooling concepts until they are ready to graduate.

## Authority Status

`design/90_codex/` is **not** active runtime authority.

Active Godot implementation authority remains:

1. `design/02_features/`
2. `custodian/docs/ai_context/CURRENT_STATE.md`
3. `custodian/docs/ai_context/FILE_INDEX.md`
4. live runtime files under `custodian/game/`, `custodian/content/`, and `custodian/project.godot`

## Required Index Discipline

Every canonical codex card must appear in:

- `design/90_codex/00_index.md`

Every row in `00_index.md` must point to an existing file.

Cards in package/import folders are not canonical unless deliberately indexed.

## Required Card Fields

Every canonical idea card should include:

- `Status:`
- `Category:`
- `Priority:`
- `Maturity:`
- `Cost:`

Recommended optional fields:

- `Owner:`
- `Last reviewed:`
- `Runtime status:`
- `Graduated to:`
- `Runtime path:`

## Status Values

Allowed statuses:

- `seed` — captured but not judged
- `triaged` — reviewed and categorized
- `candidate` — worth designing soon
- `deferred` — good idea, wrong time
- `cut` — intentionally rejected
- `graduated` — moved into active design/runtime authority
- `runtime-seed` — a minimal runtime version exists, but the codex idea is not fully built
- `implemented` — runtime behavior broadly exists and is tracked elsewhere

## Graduation Rule

A codex card graduates only when there is an active target under:

- `design/02_features/`
- `design/04_architecture/`
- `custodian/docs/ai_context/task_packets/`
- or an existing runtime file under `custodian/game/`

Graduated cards must name the active destination.

Example:

```md
Status: graduated
Runtime status: runtime-seed
Graduated to: `design/02_features/debug_ui/DEVELOPER_OBSERVATORY_SYSTEM.md`
Runtime path: `custodian/game/systems/debug/dev_observatory.gd`
```

## Hook / Validation

Run:

```bash
python tools/validate_design_codex.py
```

Optional local hook install:

```bash
bash tools/install_git_hooks.sh
```

The pre-commit hook validates codex structure when `design/90_codex/` files are staged.

## Agent Rule

Agents may use codex cards for ideation, prioritization, and design continuity.

Agents must not implement directly from a codex card unless the user explicitly asks to promote/build that idea. Before implementation, create or update the active design authority under `design/02_features/` or another appropriate active design location.
