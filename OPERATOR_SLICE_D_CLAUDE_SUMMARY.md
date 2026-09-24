# Operator Runtime Decomposition — Slice D

Branch `main`. Deterministic input authority + fixed-step simulation spine.
This file is overwritten as the slice advances; it is not a changelog.
Contract: `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`.
Tracker: `custodian/docs/ai_context/task_packets/OPERATOR_RUNTIME_DECOMPOSITION.md`.

## Status — **SLICE D COMPLETE** (after the D.1 seal correction)

```
part 1  input frame / router / aim authority        7d047f3cc
part 2  simulation onto the fixed-tick spine        38675287f
part 3  architecture + drift documentation          60d38cebb
D.1     seal correction (see below)                 this pass
```

## D.1 — what Slice D got wrong

Review caught three holes. All three were places where the implementation did not
satisfy its own contract, and one of them I had flagged as a risk and then not
checked.

**1. The audit exemption was false.** Slice D exempted four `_process` calls from
the render-tick rule on the strength of their names, and claimed each was
"verified to read simulation state and write none". Three were not:

| call | what it actually moves | who reads it |
|---|---|---|
| `_tick_primary_ranged_action_presentation` | `_primary_ranged_action_timer` / phase | `_is_ranged_aim_ready()` → `can_fire_ranged_now()` and the fire branch of `_handle_attack_input()` |
| `_update_animation_state_machine` | `AnimationState.elapsed`, transitions | `_is_movement_locked()`, weapon selection, `update_block_state()` |
| `_update_melee_presentation_posture` | melee draw grace, READY/RELAXED | the Vigil ready-up bridge before attack startup |

So **whether you may fire was advancing on render delta**, and the reported zero
was not true. All three are on the fixed tick now; only `_update_body_recoil`
remains exempt, verified against its readers rather than its name.

**2. Injected control had no edges.** `from_control_intent()` states what is
held; `adopt()` returned it unchanged. `pressed` worked and `just_pressed` never
fired, so a replay or AI could drive held-fire ranged but **could not start melee
or the sidearm** — one seam delivering two behaviours, which is precisely what
the seam exists to prevent. `adopt()` now derives edges against the previous
tick. The old Slice D test only asserted `pressed_any()`, which is why it passed.

**3. `mouse_moved` was dead data.** The router computed it, the docs promised
pointer movement owned the handoff, and `OperatorAimController` never read it.
`InputPromptService` flips to keyboard_mouse on *any* keyboard press, so tapping
a movement key after using a controller handed aim to wherever the cursor was
sitting. Now latched on real pointer movement, cleared when the gamepad takes
aim back.

Controls, all biting: putting the three advancers back fails the spine gate in
three places naming each reader; reverting `adopt()` fails in four including
"external control could not start a melee attack"; ignoring `mouse_moved` fails
with the stale cursor acquiring aim.

## What moved

```
OperatorInputFrame     one fixed tick's intent, immutable
OperatorInputRouter    the only place Operator code reads Input.*
OperatorAimController  aim-source policy + the retained controller direction
```

The split is by question, not convenience: the router answers *what did the
player do*, the aim controller *what direction does that mean*, and the existing
gameplay authorities keep *is that legal right now*. That is what lets a replay,
an AI or a vehicle supply intent without pretending to be a keyboard.

## The tick

```
_physics_process(delta)
    _sample_input_frame()        one immutable frame
    _advance_simulation(delta)   clocks, input handling, state changes
    _advance_movement(delta)     movement intent, attack drive, move_and_slide()

_process(delta)
    presentation only
```

`_advance_simulation` is the old `_process` body moved verbatim in order, early
returns included — they encode real dependencies, and the movement ladder
re-checks the same conditions itself. `_advance_movement` is split out so
movement can be driven alone; it is also the seam the attack-drive tests wanted.

## Measured

```
operator.gd            15212 -> 15201 lines, 716 -> 721 functions

input_calls_outside_input_dir   65 -> 0
gameplay_mutation_in_process    12 -> 0   (honestly, after D.1; not before)
total architecture debt        196 -> 119
migration opened at            347         (201 was a midpoint, not the start)
```

## Edge semantics

Edges combine Godot's physics-relative `just_pressed`/`just_released` with a
comparison against the previously sampled tick. The engine answer alone loses an
edge when a tick is skipped; the comparison alone loses a press that begins and
ends between two ticks. Both mean "since the last physics frame", so combining
them cannot report one edge twice. No consumed flags anywhere in gameplay code.

## Aim

Gamepad, then keyboard in arrow-aim mode, then mouse. A stick returning to
neutral is the player holding still: it does not zero aim and does not hand aim
to the mouse. A mouse position exists whether or not anyone is touching the
mouse, so pointer *movement* is what hands ownership back. `_last_controller_aim_direction`
is gone from `operator.gd`; the aim controller owns it and the actor reads it,
because two places remembering one stick is how they disagree.
`InputPromptService` remains the single device-family authority.

## Three things worth flagging

- **The audit exemption was the failure, not the risk I thought it was.** I said
  each of the four was "verified to read simulation state and write none". I had
  checked one. Three moved state that gates firing, movement locks and the Vigil
  ready-up route. Corrected in D.1; an exemption is a claim about a function's
  readers, and has to be checked against them.
- **A flake I caused, found and fixed.** `operator_unarmed_posture` failed 2-in-5
  after part 2 because the fixture stepped attacks by hand while the actor's own
  ticks still ran — a physics tick landing inside an `await` completed the attack
  early. Deterministic now, 0-in-6. The fast-chain presentation-clock case had
  the same shape.
- **operator.gd only shrank by 11 lines**, and grew by 24 before I trimmed. Raw
  sampling and aim policy genuinely left; I had replaced them with long comments,
  which now live in the architecture doc. The honest lever for a bigger number is
  Slice E/F, not more prose relocation.

## Gates

New: `operator_input_frame` (edges, movement normalisation, full aim policy,
injected control) and `operator_fixed_tick_spine` (render ticks move no clock;
fixed ticks advance by exactly their delta, step-size independent). Both own
`operator/input/**`, so an input edit selects a focused gate rather than the
whole Operator suite.

Control: putting four clocks back in `_process` fails the spine gate in four
places.

Migrated, behaviour unchanged: `operator_input_aim_source` (reads the retained
aim from its new owner), `operator_ranged_ready_input`, `operator_dodge_flow`,
`operator_charged_long_roll`, `operator_dodge_charge_feedback`,
`operator_unarmed_fast_chain`, `operator_unarmed_posture`,
`operator_vigil_dagger`, `operator_sword_cleaver`.

```
changed set   39/39
actor tier    55/56   (lootable_corpse_beacon only, unrelated)
```

## Deferred deliberately

C2b animation compatibility demolition, Slice E (`OperatorActionController`),
Slice F (melee/dodge/ranged/loadout/interaction/recovery extraction). No combat,
input or timing values were retuned, and no assets were touched.
