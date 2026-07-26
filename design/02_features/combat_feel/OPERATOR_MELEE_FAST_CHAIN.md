# Operator Melee Fast Chain

Status: implemented-v1
Owner: gameplay/combat
Runtime target: Godot 4 (`custodian/`)

## Purpose

The Fallen Star Katana fast attack is a deliberate three-command chain. A
primary press queues intent, while the visible authored contact frame grants
permission to move to the next clip.

The chain is:

```text
Fast 01 -> Fast 02 -> Fast 03 -> Fast 01 ...
```

Holding primary never repeats the chain. Each link requires a distinct
`just_pressed` input and the first valid queued command owns the single command
slot.

## Source and runtime assets

The verified source master is:

```text
custodian/content/sprites/operator/new_operator/modular/chain_attack/
operator__full_body_source__melee_1h__chain_attack_01__e__22f__156x96.png
```

It is `3432x96`: 22 frames at `156x96`. The two standalone seven-frame
full-body candidates present during implementation were pixel-identical and are
not runtime authority. `split_operator_melee_fast_chain.py` validates the master
dimensions, rejects identical first and second source ranges, and writes:

```text
Fast 01: frames 0-6   -> 1092x96
Fast 02: frames 7-13  -> 1092x96
Fast 03: frames 14-21 -> 1248x96
```

The runtime strips live under:

```text
custodian/content/sprites/operator/runtime/body/melee_1h/
```

The verified master is a baked body/weapon/effect presentation. The Katana
chain therefore leaves `weapon_anim` and `fx_anim` empty; it does not combine
the baked strip with independently timed overlays.

## Timing

All three animations are non-looping and registered at 18 FPS with body
`speed_scale = 1.0`.

| Link | Frames | Damage frame | Commit frame | Stamina |
|---|---:|---:|---:|---:|
| Fast 01 | 7 | 5 | 5 | 7 |
| Fast 02 | 7 | 5 | 5 | 8 |
| Fast 03 | 8 | 6 | 6 | 10 |

Indices are zero-based. Every link produces one light damage event. Fast 03
keeps equal damage and light-hit taxonomy while receiving modestly stronger
hit-stop, shake, and knockback.

When a fast or heavy command is buffered, the current link applies its contact
frame before transitioning. Its final stance frame is skipped and the next
clip begins on its opening stance frame. Without a queued command, the final
stance frame plays and the attack ends without the legacy external fast
recovery clip.

A post-contact dodge press may occupy the same command slot. It waits for the
current clip's final stance frame, then starts the ordinary tap dodge. Early
dodge input cannot erase anticipation or contact.

## Direction

Each link samples a new aim direction once and locks it for that link.
Link-to-link retargeting is capped at 75 degrees. Until additional directional
art exists, the east strip is mirrored for west and gameplay direction is
clamped inside a 75-degree horizontal presentation sector, preventing a
horizontal-looking attack from damaging a target directly north or south.

## Reset rules

The chain resets to Fast 01 when:

- a link finishes without a queued fast command;
- heavy or dodge commits;
- the Operator takes a damage reaction;
- block, parry, critical execution, or death takes authority;
- weapon selection changes;
- a runtime/portal action lock clears combat input.

Whiffs do not reset an otherwise valid queued link. Hit confirmation controls
impact presentation and reactions, not chain permission.

## Runtime ownership

- `operator_weapon_definition.gd` owns per-weapon chain keys, commit frames,
  stamina costs, looping, and integrated-recovery flags.
- `fallen_star_katana_definition.tres` configures the three Katana links.
- `operator.gd` owns the single command slot, authored-frame transition,
  stamina spending, retarget clamp, hit dedupe, reset behavior, and dynamic
  runtime registration.
- `operator_melee_fast_chain_smoke.gd` validates assets, data, animation
  registration, command order, branches, dedupe, reset behavior, and feel
  hierarchy.

## Validation

```bash
cd custodian
godot --headless --path . \
  --script res://tools/validation/operator_melee_fast_chain_smoke.gd
godot --headless --path . \
  --script res://tools/validation/operator_modular_fast_attack_smoke.gd
godot --headless --path . \
  --script res://tools/validation/grunt_parry_crit_reaction_smoke.gd
```
