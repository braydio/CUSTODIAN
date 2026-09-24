# Operator Runtime Decomposition — Slice D

Branch `main`. Deterministic input authority + fixed-step simulation spine.
This file is overwritten as the slice advances; it is not a changelog.
Contract: `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`.
Tracker: `custodian/docs/ai_context/task_packets/OPERATOR_RUNTIME_DECOMPOSITION.md`.

## Status — **SLICE D COMPLETE** (after the D.1 and D.2 seal corrections)

```
part 1  input frame / router / aim authority        7d047f3cc
part 2  simulation onto the fixed-tick spine        38675287f
part 3  architecture + drift documentation          60d38cebb
D.1     render tick, injected edges, mouse latch    b2ed048f7
D.2     external aim + event-derived mouse motion   this pass
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

## D.2 — what D.1 still left open

Review followed the seams D.1 created and found two more, one of them inside the
external-control contract itself. Both are the same species of error as D.1's:
a fact was *stored*, and the thing that would have made it true was not checked.

**1. External aim was accepted and discarded.**
`ControllableActor.process_input(input_vector, aim_vector, is_firing)` documents
`aim_vector` as a world-space aim direction. The router filed it as
`keyboard_aim`; `OperatorAimController` reads `keyboard_aim` only when
`arrow_aim_enabled` is true; the Operator defaults it to **false**. So an injected
`Vector2.UP` did not necessarily aim up, and usually did not.

D.1 therefore proved *external control can press melee* and never proved *external
control can control the Operator* — for exactly the promised users of the seam: AI,
vehicle/possession routing, replay, future remote control. The D.1 test could not
see it, because the melee regression set `aim_direction` and
`visual_idle_direction` to RIGHT and then injected RIGHT. The attack succeeded
whether or not the aim propagated.

External control is now its own source rather than an impersonated device.
`OperatorInputFrame` carries `external_control` and a normalized `control_aim`,
`adopt()` carries both through with the edges, and the aim authority ranks
external above gamepad, arrow-aim and mouse. A driver with no aim opinion holds
the current direction instead of falling through to local devices, which are not
driving. Local frames keep the existing gamepad/keyboard/mouse policy untouched,
and there is still one convergence point, not a second gameplay path.

**2. `mouse_moved` was still not mouse movement.**
D.1 added the `_mouse_is_live` latch and got the *policy* right. The *fact* feeding
it was wrong one level upstream: the router derived `mouse_moved` by comparing
`_get_world_mouse_position()` between ticks — a **camera-relative** coordinate.

`CameraController` follows the Operator and applies smoothing, lookahead, combat
offsets, ranged aim lead, threat framing, bob, shake and zoom. The world
coordinate under a physically motionless mouse therefore moves constantly, and
D.1's own scenario could reappear intact:

```
gamepad owns aim -> player presses W -> InputPromptService flips to keyboard_mouse
-> operator/camera moves -> world mouse coordinate changes
-> router reports mouse_moved -> a stale physical mouse becomes live aim
```

The D.1 test built `mouse_moved` by hand, so it tested the AimController policy
correctly and never tested whether the router produced the fact correctly.

`InputPromptService` already receives real `InputEventMouseMotion` and already owns
device-family detection, so it now also keeps `mouse_motion_generation`, a
monotonic count advanced only by the same qualifying event. The router compares
that against its previous sample; it no longer takes a mouse position at all, and
the Operator adds no second `_input(event)` detector. Camera position, actor
position and world mouse coordinates are structurally out of the path.

**Controls, mutation-tested, all biting.** Refiling external aim as `keyboard_aim`
fails `operator_input_frame` and `operator_input_aim_source` ("externally supplied
aim must own aim with arrow_aim_enabled false, got (1.0, 0.0)"). Restoring the
world-position comparison fails `operator_input_aim_source` at "camera movement was
reported as pointer movement at step 0" and at the positive control.

The camera negative control needed a second pass: the first version moved only the
actor, and headless with no camera the world mouse coordinate does not move, so it
asserted nothing. It now builds a real `Camera2D` at `/root/GameRoot/World/Camera2D`
— the path the Operator actually reads — and asserts the world mouse coordinate
really moved *before* asserting what that must not cause. A negative control that
cannot reproduce the input proves nothing, which is the same mistake in test form
that D.1 made in code.

**One stale gate fixed.** `controller_input_contract` asserted `operator.gd`
contains `Input.is_action_pressed("sprint")` — a call site Slice D deliberately
removed. It has been failing since Slice D and was failing at `b2ed048f7` before
this pass; it is not a D.2 regression. The assertion now names the post-Slice-D
owner (`_input_frame.pressed(&"sprint")`) and additionally forbids a return to raw
`Input` sampling, which is what it was always trying to protect.

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

Re-measured against the live file at the D.2 seal, not carried forward:

```
operator.gd            15,231 lines, 723 functions, 613,598 bytes
                       (Slice D opened at 15,212 / 716)

input_calls_outside_input_dir   65 -> 0
gameplay_mutation_in_process    12 -> 0   (honestly, after D.1; not before)
total architecture debt        196 -> 119
migration opened at            347         (201 was a midpoint, not the start)
```

The D.1 summary reported `15212 -> 15201`, which was already stale when it was
written. D.2 adds the external-aim fact, the motion-generation read and the
documentation the seams need; the absolute `/root/InputPromptService` lookup it
required is resolved once in `_get_input_prompt_service()` and shared, so
`absolute_scene_lookups` stays at 38 and the total stays at **119**.

## Edge semantics

Edges combine Godot's physics-relative `just_pressed`/`just_released` with a
comparison against the previously sampled tick. The engine answer alone loses an
edge when a tick is skipped; the comparison alone loses a press that begins and
ends between two ticks. Both mean "since the last physics frame", so combining
them cannot report one edge twice. No consumed flags anywhere in gameplay code.

## Aim

External control, then gamepad, then keyboard in arrow-aim mode, then mouse. An
external frame's `control_aim` outranks every local source and depends on none of
them. A stick returning to
neutral is the player holding still: it does not zero aim and does not hand aim
to the mouse. A mouse position exists whether or not anyone is touching the
mouse, so pointer *movement* is what hands ownership back — and that movement is an
event fact from `InputPromptService.mouse_motion_generation`, never a world-space
coordinate the camera can move by itself. `_last_controller_aim_direction`
is gone from `operator.gd`; the aim controller owns it and the actor reads it,
because two places remembering one stick is how they disagree.
`InputPromptService` remains the single device-family authority.

## Four things worth flagging

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
- **Both D.2 defects are one mistake.** D.1 stored a fact and did not verify the
  thing that produces it: `aim_vector` was stored where nothing would read it by
  default, and `mouse_moved` was computed from a signal that does not mean what its
  name says. A seam that accepts a value it may ignore is worse than one that
  refuses it, because the caller cannot tell. Both facts are now explicit and
  owned, and both have negative controls that fail when reverted.
- **operator.gd grew by 19 lines across Slice D** (15,212 -> 15,231). Raw
  sampling and aim policy genuinely left; I had replaced them with long comments,
  which now live in the architecture doc. The honest lever for a bigger number is
  Slice E/F, not more prose relocation.

## Gates

New: `operator_input_frame` (edges, movement normalisation, full aim policy
including the external-aim ranking, injected control, and `mouse_moved` advancing
only on a qualifying motion event) and `operator_fixed_tick_spine` (render ticks
move no clock; fixed ticks advance by exactly their delta, step-size independent;
an injected attack swings where the driver pointed). Both own `operator/input/**`,
so an input edit selects a focused gate rather than the whole Operator suite.

Control: putting four clocks back in `_process` fails the spine gate in four
places. Refiling external aim as `keyboard_aim`, or deriving `mouse_moved` from the
world mouse position again, each fail by name — verified by mutation, separately
and together.

Migrated, behaviour unchanged: `operator_input_aim_source` (reads the retained
aim from its new owner), `operator_ranged_ready_input`, `operator_dodge_flow`,
`operator_charged_long_roll`, `operator_dodge_charge_feedback`,
`operator_unarmed_fast_chain`, `operator_unarmed_posture`,
`operator_vigil_dagger`, `operator_sword_cleaver`.

D.2 gates, all green:

```
operator_input_frame          PASS
operator_input_aim_source     PASS
operator_fixed_tick_spine     PASS
operator_ranged_ready_input   PASS
operator_unarmed_fast_chain   PASS
operator_vigil_dagger         PASS
operator_sword_cleaver        PASS
controller_input_contract     PASS   (was failing at b2ed048f7; stale assertion)
architecture debt audit       119    baseline held
changed set                   40/40
```

## Deferred deliberately

C2b animation compatibility demolition, Slice E (`OperatorActionController`),
Slice F (melee/dodge/ranged/loadout/interaction/recovery extraction). No combat,
input or timing values were retuned, and no assets were touched.

Slice D is sealed.
