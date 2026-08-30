# Controller Input System

Status: implemented hardening authority

## Purpose

CUSTODIAN uses Godot's InputMap as the sole production gameplay input authority. Controller support extends the existing twin-stick implementation; it does not introduce an intermediary gameplay input manager. Keyboard and mouse remain immediately interchangeable with an Xbox-layout controller.

## Production Controller Contract

| Control | Action |
|---|---|
| Left Stick | Analog movement |
| Right Stick | Aim |
| L3 / R3 | Sprint / sneak |
| RT / LT | Primary-fire or fast attack / secondary-ready, aim, or guard |
| RB / LB | Heavy attack / repair or field-work hold |
| A / B | Interact or accept / dodge or back |
| X / Y | Reload / inventory |
| D-pad Up / Down | Field Patch or active utility / build, deploy, or pickup |
| D-pad Left / Right | Previous / next weapon |
| View / Menu | Map / pause |

Weapon cycling must retain access to unarmed where required; `toggle_unarmed` receives no dedicated controller button. Item-cycle compatibility actions are keyboard-only until a live item-selection design exists. Drone extras remain terminal-accessible or await a dedicated command-mode design. Debug, time-shift, replay, and developer actions remain keyboard-oriented.

## Analog Contract

- Movement InputMap deadzone: `0.20`; analog magnitude is preserved above it.
- Aim InputMap deadzone: `0.22`; Operator code does not add a second meaningful stick threshold.
- LT/RT action deadzone: `0.15`, avoiding the prior half-pull activation requirement.
- Presentation device detection ignores joypad motion below `0.35` and mouse motion below two pixels so drift/noise does not churn prompts.

## Ownership

- `project.godot` owns action definitions, compatibility aliases, physical bindings, and deadzones.
- Gameplay consumes semantic InputMap actions directly. Raw production `KEY_CTRL`/`KEY_SHIFT` checks are forbidden.
- `InputPromptService` is presentation-only. It records the last meaningfully used keyboard/mouse or gamepad family, emits changes, and resolves action labels from InputMap.
- UI owns focus and accept/back behavior. Progression-critical overlays must expose required operations through focus plus `ui_accept`, and use `ui_cancel` wherever backing out is valid.
- Action-driven prompts are preferred. Literal labels remain a compatibility path for non-action status badges.

## Validation

Run:

```bash
env HOME=/tmp/custodian-godot-home godot --headless --path custodian --script res://tools/validation/controller_input_contract_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path custodian --script res://tools/validation/operator_ranged_ready_input_smoke.gd
python3 custodian/tools/validation/run_validation.py --changed --json
env HOME=/tmp/custodian-godot-home godot --headless --path custodian --quit
```

Moment Forge is not required for binding/prompt reachability changes that do not alter dodge or combat timing.

## Deferred

- Controller glyph artwork; textual Xbox labels are sufficient.
- A dedicated drone command mode if terminal navigation cannot satisfy future production commands.
- A live item-cycle design before restoring item cycling to controller buttons.
