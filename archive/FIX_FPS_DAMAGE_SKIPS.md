Yes. That should go into the repair pass **as a correctness bug, not combat tuning**. I checked the live Operator runtime and the mechanism explains exactly what you're seeing.

## The current bug

Ordinary Operator melee damage is still effectively **sampled from the currently visible animation frame**.

During `_update_melee_attack()` the runtime does:

```gdscript
_update_melee_hitbox_transform()
_sync_melee_hitbox_window_from_animation()

if _melee_hitbox_active:
    _apply_melee_hitbox_tick()
```

And `_sync_melee_hitbox_window_from_animation()` resolves the contact from:

```gdscript
var frame: int = animated_sprite.frame

_active_melee_contact = _get_melee_contact_for_frame(
    frame,
    window
)

if _is_melee_hit_frame_active(frame, window):
    enable_hitbox()
else:
    disable_hitbox()
```

The `AnimatedSprite2D.frame_changed` signal also just calls that same current-frame synchronization.

So at normal FPS:

```text
frame 4
frame 5
frame 6
      ↑
   CONTACT
```

works.

Under a sufficiently long frame:

```text
frame 4
   ↓  80-120 ms hitch
frame 6

frame 5 was never observed by gameplay code
→ hitbox never becomes logically active
→ damage vanishes
```

And your melee definitions make this particularly vulnerable because many contacts are intentionally **one authored frame wide**. For example, Vigil Fast 01 and Fast 02 each have one contact frame; Fast 03 has separate contacts at authored frames 5 and 9. Unarmed fast likewise currently declares a single hit-window frame.

So yes, this is a real architectural hole.

## The funny part: CUSTODIAN already has the correct solution

The critical execution implementation already solved this exact problem.

Its execution timeline doesn't ask:

> “What frame happens to be visible right now?”

It accumulates `delta`, then repeatedly consumes every crossed frame boundary:

```gdscript
var frame_step := minf(
    remaining_delta,
    frame_duration - _paired_execution_frame_elapsed
)

_paired_execution_frame_elapsed += frame_step
remaining_delta -= frame_step

if _paired_execution_frame_elapsed + 0.000001 < frame_duration:
    break

_paired_execution_frame_elapsed = 0.0
_paired_execution_frame_index += 1
_apply_paired_execution_frame(
    _paired_execution_frame_index
)
```

So one horrible frame can cross 3 animation frames and **all three semantic boundaries are still processed in order**.

Ordinary melee needs the same invariant.

# Exact fix

I would **not** widen every damage frame to two or three frames. That merely makes the bug harder to reproduce and damages authored timing.

Instead, add a semantic frame cursor to `operator.gd`.

### Add state

```gdscript
var _melee_last_processed_frame: int = -1
var _melee_processed_animation: StringName = &""
```

Reset these whenever a new attack/link starts:

```gdscript
func _reset_melee_frame_cursor() -> void:
    _melee_processed_animation = (
        animated_sprite.animation
        if animated_sprite != null
        else &""
    )
    _melee_last_processed_frame = -1
```

Call it **after the new melee animation has been selected and played**.

### Add crossed-frame processing

```gdscript
func _process_crossed_melee_frames() -> void:
    if animated_sprite == null or not _melee_active:
        return

    var animation := animated_sprite.animation
    var current_frame := animated_sprite.frame

    if animation != _melee_processed_animation:
        _melee_processed_animation = animation
        _melee_last_processed_frame = -1

    # Non-looping melee should normally never go backwards.
    # A backwards jump means the clip/link was reset.
    if current_frame < _melee_last_processed_frame:
        _melee_last_processed_frame = -1

    var first_frame := _melee_last_processed_frame + 1

    for crossed_frame in range(
        first_frame,
        current_frame + 1
    ):
        _process_melee_semantic_frame(
            crossed_frame
        )

    _melee_last_processed_frame = current_frame
```

Then:

```gdscript
func _process_melee_semantic_frame(
    frame: int
) -> void:
    var weapon_definition := (
        _active_attack_profile
        if _active_attack_profile != null
        else _get_equipped_primary_weapon_definition()
    )

    var window := _get_active_melee_hit_window()

    if weapon_definition != null \
    and weapon_definition.hit_windows is Dictionary:
        var weapon_window := (
            weapon_definition.hit_windows.get(
                _melee_attack_key,
                {}
            ) as Dictionary
        )

        if not weapon_window.is_empty():
            window = weapon_window

    if not _is_melee_hit_frame_active(
        frame,
        window
    ):
        return

    _resolve_melee_contact_frame(
        frame,
        window
    )
```

## Refactor the current damage tick

This is important.

Current `_apply_melee_hitbox_tick()` itself looks back at:

```gdscript
animated_sprite.frame
```

to determine contact data. That means merely detecting crossed frames is insufficient.

Change it from:

```gdscript
func _apply_melee_hitbox_tick() -> void:
```

to something like:

```gdscript
func _apply_melee_hitbox_tick(
    semantic_frame: int = -1,
    window_override: Dictionary = {}
) -> void:
    var resolved_frame := (
        semantic_frame
        if semantic_frame >= 0
        else animated_sprite.frame
    )

    var window := (
        window_override
        if not window_override.is_empty()
        else _get_active_melee_hit_window()
    )

    var active_directions := (
        _get_melee_active_hit_directions(
            resolved_frame,
            window
        )
    )

    var active_contact := (
        _get_melee_contact_for_frame(
            resolved_frame,
            window
        )
    )

    var contact_id := StringName(
        active_contact.get(
            "id",
            "default"
        )
    )

    ...
```

Then the catch-up path calls:

```gdscript
_apply_melee_hitbox_tick(
    crossed_frame,
    window
)
```

rather than letting the function inspect the later visual frame.

That's the key detail.

# Also keep the Area2D warm during the whole swing

There is one more trap.

Damage currently obtains candidates through:

```gdscript
weapon_hitbox.get_overlapping_bodies()
```

but `enable_hitbox()` and `disable_hitbox()` currently toggle `Area2D.monitoring`.

A skipped frame shouldn't require turning monitoring on and immediately querying it, because physics overlap state may not have refreshed yet.

I would change the contract to:

```text
attack begins
    weapon_hitbox.monitoring = true

whole melee animation
    overlap information stays available

semantic contact frame
    _melee_hitbox_active = true
    resolve damage

recovery/non-contact
    _melee_hitbox_active = false

attack ends
    weapon_hitbox.monitoring = false
```

In other words, **monitoring is attack-lifetime authority; `_melee_hitbox_active` is damage-lifetime authority**.

There's only one Operator melee Area2D, so the performance cost is negligible.

## Existing dedupe already helps us

The runtime already deduplicates damage using:

```text
enemy instance ID + contact ID
```

rather than merely “enemy hit this swing.”

That's excellent for this fix.

It means if a hitch crosses:

```text
Fast 03
frame 4 → frame 8
```

the crossed-frame processor can encounter:

```text
cut_01
cut_02
```

in order, and both legitimate contacts may occur, while repeated processing of the same contact cannot double-hit the same target.

So **do not replace the current contact-ID system**.

# Change `_update_melee_attack()`

The important section becomes:

```gdscript
_update_melee_hitbox_transform()

# Presentation/debug state can still follow current frame.
_sync_melee_hitbox_window_from_animation()

# Gameplay authority processes every frame crossed
# since the previous simulation update.
_process_crossed_melee_frames()
```

Remove this as the sole damage authority:

```gdscript
if _melee_hitbox_active:
    _apply_melee_hitbox_tick()
```

Otherwise you're still mixing polling and semantic-event damage.

You can keep ordinary active-window polling as a compatibility path for legacy multi-frame windows, but explicit `contacts` and single-frame `frames` should use crossed-frame semantic dispatch.

## Make the rules explicit

I'd establish:

```text
contacts:
    semantic event
    process every crossed contact frame exactly once

frames: [N]:
    semantic single-contact event
    process if N was crossed

frames: [N, N+1]:
    one tolerant contact window unless explicitly assigned
    separate IDs

start/end:
    legacy continuous active window
    polling remains allowed until migrated
```

That fits the existing contact grammar rather than inventing another one.

# Add a low-FPS regression smoke

Create:

```text
custodian/tools/validation/
operator_melee_low_fps_contact_smoke.gd
```

This test is important enough that I wouldn't accept the combat repair without it.

Required cases:

```text
Vigil Fast 01:
previous frame 4
current frame 6
contact frame 5 crossed
=> damage exactly once

Vigil Fast 02:
same test
=> damage exactly once

Vigil Fast 03:
jump across first contact
=> cut_01 occurs

jump across second contact
=> cut_02 occurs

one large update crossing both contacts
=> cut_01 and cut_02 each occur once

Unarmed Fast:
jump over its single contact frame
=> damage exactly once

Heavy:
jump over heavy contact
=> damage exactly once

Normal FPS:
contact frame observed normally
=> still exactly once

Repeated callback:
same target + same contact ID
=> still exactly once
```

I'd explicitly simulate some ugly frame times:

```text
16.7 ms   60 FPS
33.3 ms   30 FPS
66.7 ms   15 FPS
100 ms    10 FPS
200 ms     5 FPS
```

and assert that attack outcome is identical for all of them.

That's the actual invariant we want:

> **FPS may change presentation smoothness. It may never change whether an authored melee contact occurs.**

## Add this to the Codex repair brief

Append:

```text
5. LOW-FPS-SAFE MELEE CONTACT TIMING

Files:
- custodian/game/actors/operator/operator.gd
- custodian/game/systems/combat/melee_attack_profile.gd only if contract docs/comments need clarification
- custodian/tools/validation/operator_vigil_dagger_smoke.gd
- add custodian/tools/validation/operator_melee_low_fps_contact_smoke.gd
- design/02_features/combat_feel/OPERATOR_MELEE_CONTACT_TIMING_AND_CADENCE.md

BUG:
Ordinary melee currently derives hitbox activation/contact from the currently
observed AnimatedSprite2D.frame. A long simulation/render frame can advance
past a one-frame contact without gameplay observing that frame, causing the
attack to deal no damage.

The paired-critical execution timeline already solves this class of failure by
processing every crossed authored frame boundary. Preserve that invariant for
ordinary melee.

IMPLEMENT:
- Add an attack-local melee semantic frame cursor.
- Reset it on every newly started melee attack/chain link/animation.
- Each melee update processes every authored frame crossed since the previous
  update, not only animated_sprite.frame at the end of the update.
- Explicit contact records and one-frame hit windows fire when their frame was
  crossed, even if that frame was never rendered.
- Parameterize melee damage resolution with the semantic frame being processed;
  do not have catch-up resolution read animated_sprite.frame again.
- Preserve target + contact-ID deduplication.
- Fast 03 and any future multi-contact attack must preserve distinct contacts.
- Do not widen contact windows to hide the bug.
- Do not make damage dependent on frame_changed signal delivery.
- Keep the melee Area2D monitoring for the attack lifetime, while logical
  damage activation remains contact/window controlled, so crossed-frame
  resolution has current overlap data.
- Disable monitoring when the attack ends/cancels.
- Presentation may skip visual frames at low FPS. Gameplay semantic contacts
  may not be skipped.

VALIDATE:
Add operator_melee_low_fps_contact_smoke.gd.

Run the same authored attacks under simulated update steps equivalent to
60/30/15/10/5 FPS.

Assert identical contact IDs, hit counts and total damage at every step size.

Explicitly cover:
- Vigil Fast 01
- Vigil Fast 02
- both Fast 03 contacts
- unarmed Fast
- configured Heavy
- one large step crossing multiple contacts
- dedupe after repeated callbacks

Do not modify attack damage/tuning as part of this repair.
```

This one is worth fixing **in the same correctness batch**. The repository's critical executions already establish the right doctrine: their frame-step loop guarantees a low-FPS step cannot skip contact. Ordinary melee should obey exactly the same rule.
