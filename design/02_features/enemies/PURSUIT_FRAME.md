# Pursuit Frame

Status: animation intake contract staged; runtime actor and gameplay implementation deferred.

## Authority Boundary

`pursuit_frame` is a registered Asset Pipeline V2 enemy family. This slice prepares deterministic animation intake only. It does not create placeholder art, a runtime enemy scene, combat behavior, an intercept ability, or a presentation resource.

Missing animations are intentionally non-blocking. All ten initial body states are recommended rather than required, so the family remains healthy at `0/0 required` until artwork is supplied. Once a file is present, its dimensions, direction, layout, and exact frame count are enforced.

## Intake

Place horizontal RGBA strips in:

```text
custodian/asset_drop/inbox/pursuit_frame/
```

Use `<state>__<direction>.png` names:

| State | Group | Direction | Frames | Source dimensions |
| --- | --- | --- | ---: | ---: |
| `idle_ready_01` | posture | S | 4 | 384×96 |
| `patrol_walk_01` | locomotion | S | 8 | 768×96 |
| `patrol_scan_01` | activity | S | 6 | 576×96 |
| `checkpoint_halt_01` | activity | S | 4 | 384×96 |
| `notice_01` | combat | S | 4 | 384×96 |
| `pursuit_run_01` | locomotion | S | 8 | 768×96 |
| `intercept_windup_01` | combat | E | 4 | 384×96 |
| `intercept_burst_01` | combat | E | 4 | 384×96 |
| `intercept_recover_01` | combat | E | 5 | 480×96 |
| `melee_brace_01` | combat | E | 6 | 576×96 |

Each frame is 96×96 with true alpha, stable world-contact registration, no inter-frame padding, and no background pixels. Asset Pipeline V2 deterministically mirrors the four east-authored combat states to west unless an authored west strip is later present.

Canonical runtime output follows the current enemy-kind layout:

```text
custodian/content/sprites/enemies/pursuit_frame/runtime/body/<action-group>/
```

Editable `.aseprite` sources, when introduced, belong below `custodian/content/_aseprite/`; they are not colocated with runtime PNGs.

## Workflow

```bash
python3 custodian/tools/assets/asset.py request pursuit_frame
python3 custodian/tools/assets/asset.py plan pursuit_frame
python3 custodian/tools/assets/asset.py ingest pursuit_frame --dry-run
```

Apply only after reviewing the plan. Runtime actor wiring is a separate feature slice after enough presentation coverage exists.

## Deferred Families and Runtime Work

- rigid-humanoid source/atlas authoring;
- registered optic overlay effects;
- `pursuit_frame.tscn` and its animation set;
- behavior profile and intercept ability;
- gameplay and Moment Forge validation.

These are not represented by fake or fallback assets in this intake contract.
