# Unarmed Fast Chain — Part C feel pass

Branch `main`. This file is overwritten as Part C advances; it is not a changelog.
Full derivation lives in
`custodian/docs/ai_context/task_packets/OPERATOR_UNARMED_FAST_CHAIN_CONSOLIDATION.md`.

## Status

```
C1  subtle Fists target assistance      DONE
C3  attack-drive continuity             DONE
C4  early input forgiveness             DONE
C2  per-link impact progression         DONE
C5  chain movement continuity           DONE   <- this pass
C6  Fast 04 posture settle              next
C7  contact-owned feedback              pending
C8  parry alignment                     pending
```

## C5 — chain movement continuity

C3 left a residual: `_begin_attack_drive()` opens with
`_cancel_attack_drive(true)`, so the outgoing link lost its contribution the
instant a successor started, and the successor then sat through its own
`drive_delay_sec`. The chain read as drive, gap, drive.

Measured at each link's real commit frame, counting drive contribution rather
than position so ordinary locomotion is not counted:

| seam | dead frames before | after | drive total before | after | authored budget |
|---|---|---|---|---|---|
| 1 -> 2 | 2 of 3 | **0** | 11.46 px | **12.00 px** | 12.0 px |
| 2 -> 3 | 3 of 3 | **0** | 16.00 px | **16.00 px** | 16.0 px |
| 3 -> 4 | 3 of 4 | **0** | 22.00 px | **22.00 px** | 22.0 px |

The seam is bridged across the incoming delay, decaying from the outgoing link's
authored curve speed to zero, funded first from the outgoing link's unspent
distance and then from the incoming link's own budget — which the incoming drive
then does not get to spend later. **The bound is exact:** each seam drives its
two authored distances and not a pixel more. Seam 1 -> 2 gained 0.54 px because
that much of Fast 01's own distance used to be forfeited at the handoff.

Continuations are recognised structurally — the drive records its chain step, and
only step N+1 may inherit from step N — so a fresh attack, a restart at step 0,
and all non-chain melee inherit nothing.

Two things measurement caught that reasoning had not: a front-loaded falloff
leaves Fast 02 and Fast 03 with **zero** unspent distance at their commit frame,
so an outgoing-only bridge would have been empty exactly where it mattered; and a
drive that exhausted itself used to cancel, wiping the chain step before the
chain advanced. Natural exhaustion now completes instead, preserving the handoff;
interruption still cancels and still clears the carry.

Controlled: restoring the hard cancel fails the gate in eight places with the
exact 2/3/3 dead-frame counts. The collision case is a clear-versus-obstructed
comparison, because asserting only that the drive ended would pass vacuously.

No drive values retuned — Fists remains 5 / 7 / 9 / 13 px.

## C2 — per-link impact progression

Presentation hierarchy, not balance. Damage stays 10.0 and knockback 56.0 across
all four links, and the gate now asserts that flatness so a later feel pass
cannot quietly become a balance pass.

The authored staircase was already in the profiles — **but none of it reached the
game.** Two hardcoded per-step tables sat between `MeleeAttackProfile` and the
feedback path and overrode it:

| link | authored stop | ran as | authored shake | ran as |
|---|---|---|---|---|
| fast_01 | 0.018 | **0.026** | 0.70 | 0.70 |
| fast_02 | 0.024 | **0.030** | 1.00 | **1.08** |
| fast_03 | 0.032 | **0.036** | 1.45 | **1.81** |
| fast_04 | 0.050 | 0.050 | 2.20 | 2.20 |

Both tables keyed on steps 0/1/2 with a fallback, dating them to the retired
three-link model — which is why only link 4 was correct, and only by falling off
the end of the table. The authored curve spans 2.8x from jab to finisher; what
ran spanned 1.9x, with the early links louder than authored and the steps between
them compressed.

**It was not confined to Fists.** `_has_authored_fast_chain()` is true for both
armed weapons, and there it inverted the intent: the Vigil dagger's finisher was
cut from 0.043 to 0.036, and every Sword-Cleaver link was wrong, its opener cut
from 0.032 to 0.026. The heaviest beats were the ones most flattened.

Both helpers and their call sites are deleted — removing a parallel impact system
rather than adding one. `MeleeAttackProfile` is now the only authority, as
`CURRENT_STATE.md` already claimed.

One structural change was needed to make this testable: `_apply_hit_stop()`
resolved and applied in the same function, so the duration could not be read
without stopping time, and a headless frame (~6 ms) is coarser than the gaps
between links (4-8 ms). Resolution is now `_resolve_melee_hit_stop()`, consumed
by `_apply_hit_stop()`, semantics unchanged including the `_active_melee_contact`
override. Fusing resolve and apply is exactly what let the parallel table hide.

Controlled from both directions: flattening the links to one generic value fails
the gate in fourteen places; restoring the two hardcoded tables fails it in five.

## C4 — early input forgiveness

`_try_melee_attack()` **discarded** any fast press made outside the rhythm
window — it never reached `_buffer_attack()`. On Fast 01 the window opens at
frame 2 of 6, so roughly the first third of the link silently ate the player's
input and they had to press again. Fast 04 opens at frame 4 of 8, a 0.26s dead
region on the finisher.

Early and late are now different answers. `_fast_chain_queue_window_state()`
reports `open` / `early` / `late` / `unavailable`, and
`_is_fast_chain_queue_window_open()` delegates to it so the window has one
definition. Early presses are buffered and spent at the commit frame; late
presses are still refused, because a rhythm gate that forgives both directions
is not a gate. No new timer was needed — `_update_attack_buffer()` already
freezes the buffer for the duration of an authored chain, so a latched early
press survives to commit instead of decaying.

Forgiveness is bounded by the link's own geometry rather than a second tunable:
the pre-window region is at most four frames and is exactly the interval the
author already marked as not-yet-queueable.

Fixed in passing: the rejection log read `animated_sprite.frame`, the wrong clock
for a modular chain — the same defect `_fast_chain_presentation_frame()` exists
to fix.

Controlled from both sides: reverting to reject-unless-open fails the gate in
four places, and forgiving late presses too fails it in one.

## C3 — attack-drive continuity

Fists had **no attack drive at all**: every unarmed link sat at the 0.0 default
while the Vigil dagger (7/9/11) and Sword-Cleaver (9/11/14) both escalate. The
runtime system was already complete and already per-link, so the feature was
inert for Fists rather than missing.

| link | drive px | delay s | duration s | input influence | falloff | assist bonus px |
|---|---|---|---|---|---|---|
| fast_01 | 5 | 0.08 | 0.16 | 0.30 | 1.8 | 4 |
| fast_02 | 7 | 0.04 | 0.16 | 0.26 | 1.8 | 5 |
| fast_03 | 9 | 0.05 | 0.18 | 0.20 | 1.7 | 6 |
| fast_04 | 13 | 0.06 | 0.20 | 0.12 | 1.5 | 8 |

Distances follow the commitment curve the move multipliers already set. Delay and
duration start from the Cleaver's shipped `windup + 0.02` / `active + 0.04`
relation; links 2-4 cut the delay below it on purpose, because a continuation
link starts while the previous drive is still carrying.

## C3 also closed a hole C1 left open

`MeleeTargetResolver` derives its whole reach model from the drive. With drive at
zero, `reliable_drive` was zero and `assist_drive` was always zero — so C1's 8px
acquire ring acquired and aimed at targets between 64 and 72px and then punched
at them from out of range. The drive bonus therefore belongs here, not in C1.

## Two things recorded rather than hidden

- **A ~0.04s drive gap at the 1→2 chain seam.** `_begin_attack_drive()` cancels
  the outgoing drive's velocity contribution, so there is a short window with no
  drive while the next link's delay runs. Player locomotion still carries them
  through it. Closing it properly means carrying residual velocity across links,
  which is a runtime change, not a data pass. Wants a feel review first.
- **The acquire ring is not fully guaranteed to connect.** Under the conservative
  `target_reliable_drive_fraction = 0.75` model, closing the last pixel would need
  a 10.7px bonus, which on a 5px base link would read as a magnet snap. Link 1 can
  still honestly whiff at the outer edge; the finisher reaches furthest.

## `operator_sword_cleaver_smoke.gd` had never run

It exists, it passes, and it owns the Cleaver drive numbers C3 calibrated
against — but it was absent from `validation_manifest.json`. Same defect found
earlier with `operator_unarmed_fast_chain_smoke.gd`. Registered at actor tier.
`validation_runner_smoke.py` pins an exact selection list for
`melee_target_resolver.gd` and correctly caught the new entry; the expected list
was updated rather than the owners glob narrowed.

## Validation

```
actor tier    54/55  (lootable_corpse_beacon only; resampled F/P/F, unrelated)
changed set   36/36
focused       operator_melee_soft_targeting, operator_sword_cleaver,
              operator_vigil_dagger, operator_unarmed_fast_chain,
              operator_attack_phase_cadence, operator_armed_melee_body_visibility,
              operator_melee_switch_chain, operator_melee_point_blank,
              operator_melee_posture                          all green
```

`operator_unarmed_fast_chain` gained a drive section that is executed, not merely
declarative: each link is driven through the real `_physics_process` and its
travelled distance measured, settling is checked for snap-back, opposing input is
checked not to reverse a committed step, and a target at the edge of each link's
own acquire ring is asserted to resolve extra drive. Negative control: zeroing
link 1's distance and bonus fails it in six places.
