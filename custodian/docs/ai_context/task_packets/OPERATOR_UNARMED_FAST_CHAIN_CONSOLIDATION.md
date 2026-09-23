# Operator Unarmed Fast Chain Consolidation

## Packet Status

- Status: in progress
- Owner: agent
- Branch: `unarmed-posture-runtime`
- Started from: `398fe7a41` (Part A already landed)
- Last updated: 2026-09-21

## Goal

Three things, in order:

1. Fix the armed-melee body-ownership regression. **Done** — see Part A below.
2. Convert Fists from the three-clip `fast_windup_01 → fast_strike_01 →
   fast_recovery_01` presentation onto the existing canonical
   `fast_01 → fast_02 → fast_03` chain.
3. Remove or supersede the old three-clip unarmed contract so there is one
   fast-chain model, not two overlapping ones.

Heavy attacks are out of scope.

## Part A — armed melee body ownership (complete, `398fe7a41`)

Root cause as diagnosed: `OperatorBodyPresenter.present()` retires every outgoing
renderer and retiring stops playback, so an armed full-body clip started while
the modular rig still owned the body was stopped by its own ownership transfer
one frame later. Gameplay ran, the FX overlay flashed because it is a separate
layer, and the swing was invisible. The presentation clock went with the stopped
clip, which is why later chain links also misbehaved.

Fixed by claiming `LEGACY_FULL_BODY` **before** playback in every armed full-body
branch, plus heavy anticipation and armed recovery. The presenter was not
weakened.

Two further defects surfaced while proving it:

- **Idempotent re-claim was destructive.** `_hide_modular_locomotion_layers()`
  re-presented `LEGACY_FULL_BODY` even when it already owned the body, and
  re-presenting runs retire-then-show. That alone stopped the swing. It now
  transfers only when the owner actually changes.
- **`is_attacking` omitted `_melee_heavy_anticipating`.** Defensive rather than
  independently proven: with the two fixes above the clip keeps playing, so the
  predicate's `is_playing()` term already covers it. Kept because that term is
  self-defeating — once a clip stops it can never become true again.

Gate: `operator_armed_melee_body_visibility_smoke.gd`. Negative-controlled —
dropping the pre-play claim fails it in six places, restoring the unguarded
re-claim in ten.

Two loadout facts that the gate forced into the open:

- The shipped Operator scene equips the **Vigil dagger**, not the Sword-Cleaver.
  The gate installs the Cleaver through the actor's own loadout rebuild.
- The Vigil dagger deliberately routes a fast attack from RELAXED through its
  authored relaxed-to-ready bridge and queues the swing behind it, so
  `_melee_active` is false on the requesting frame. Correct vigil behaviour, so
  the gate uses the Cleaver, which swings directly. Extending coverage to the
  dagger means driving it *through* the bridge, not around it.

## Part B — verified asset facts

The 2026-09-21 generated-art migration replaced the modular E/W body chain and
added a terminal fourth link. Confirmed against
`operator_runtime_manifest.generated.json`:

```
unarmed/attack/fast_01/{e,w}/{lower_body,upper_body}   6f
unarmed/attack/fast_02/{e,w}/{lower_body,upper_body}   6f
unarmed/attack/fast_03/{e,w}/{lower_body,upper_body}   7f
unarmed/attack/fast_04/{e,w}/{lower_body,upper_body}   8f
unarmed/attack/fast_04/{e,w}/fx                       8f
```

Fast 01–04 now use synchronized authored E/W FX strips in the four-link modular
presentation. Older full-body variants remain compatibility/preservation art
and are not selected by this chain.

Fast 01 also carries preserved full-body variants (`e,w` 5f and `n,s` 6f) and
four `fast_01_legacy_*` families. Those are preservation art. The modular E/W
chain is the runtime family; the packet explicitly does **not** mix full-body
cardinals into the modular chain to gain N/S coverage.

## Tooling blocker found, and worked around

`operator_action_preview.py` cannot see any of this art. It resolves
`runtime/modules/new_operator/<layer>/actions/<loadout>/<action>/...`, the
pre-canonical layout. That tree still exists but holds no unarmed actions and no
`fast_0*` at all, so the tool reports `frames: 0, missing_layers:
[lower_body, upper_body]` for every link.

This is not the chain-keys chicken-and-egg the packet predicted: populating
`fast_chain_keys` changed nothing, because the tool never consults them for the
strip lookup. The tool simply predates R3/R4's canonical layout. Fixing it is
real work and is recorded here as a finding rather than silently skipped.

**Frames were therefore measured directly from the canonical strips**, which
satisfies the packet's actual intent: do not guess contact from filenames. Per
frame, the opaque pixel count and the forward reach of the silhouette both peak
on the contact frame, and they agree.

| link | frames | contact | queue open | queue close | commit |
|---|---|---|---|---|---|
| fast_01 | 6 | **4** | 3 | 4 | 3 |
| fast_02 | 6 | **4** | 3 | 4 | 3 |
| fast_03 | 7 | **4** | 3 | 5 | 3 |
| fast_04 | 8 | **5** | 4 | 7 (terminal) | 4 |

East and west measure identically to within one pixel, confirming separately
authored but symmetric strips — consistent with `flip_h = false` and never
mirroring west.

The previously authored `hit_window_frames = PackedInt32Array(2)` described the
old three-frame strike clip. On the consolidated strips contact is frame 5/5/6,
so leaving it at 2 would have fired the hit during windup. Updated.

## Cadence targets

Authored duration is frames / 12 FPS; playback scale is authored over target, so
the target is data rather than a magic speed constant.

| link | authored | target | scale |
|---|---|---|---|
| fast_01 | 0.750 s | 0.46 s | 1.63 |
| fast_02 | 0.583 s | 0.42 s | 1.39 |
| fast_03 | 0.667 s | 0.52 s | 1.28 |

Fast 02 is deliberately not slower than Fast 01; Fast 03 carries more
commitment. These are proposed from the authored frame counts and the approved
0.46 s Fast 01 target, and want a visual pass in Moment Forge before they are
called final.

## Measured cadence: the reported latency was a unit error

An earlier report described ~0.372s from input to Fast 01 contact and ~0.2s of
dead air between links, and proposed hunting a runtime handoff gremlin. **Those
numbers were wall clock from a headless capture, reported as if they were game
time.** They are not.

Moment Forge renders at ~24 fps while stepping 60 Hz physics, so its
`uptime_sec` runs about 2.5x longer than simulated time. Measured from the run's
own data: 188 ticks is 3.13s of game time against a 7.89s wall span, a **2.52x
dilation**.

Corrected, and confirmed independently by an in-engine probe:

| stage | measured |
|---|---|
| input -> `_try_melee_attack` returns | 0.3 ms |
| -> canonical playback starts | 7.1 ms |
| -> clock reaches contact frame 3 | 158.7 ms |

| interval | wall | game |
|---|---|---|
| input -> contact | 0.372s | **0.148s** |
| contact 1 -> 2 | 0.549s | 0.218s |
| contact 2 -> 3 | 0.676s | 0.269s |
| contact 3 -> 4 | 0.910s | 0.361s |

Fast 01 is 6 frames at 12 fps scaled 1.67x, so contact at frame 3 is expected at
**0.150s**. Measured 0.148s. The chain is hitting its target, and is already
faster than the 0.17-0.22s design window.

Runtime handoff is 7.1 ms, under half a frame at 60 Hz. There is no quarter
second unaccounted for, so there is nothing to hunt: no latency investigation, no
timing-sidecar reshaping, and certainly no new art.

The escalation ratio was scale-invariant and still holds: **1.00 / 1.23 / 1.66**,
snap -> snap -> drive -> BOOM.

Lesson for future captures: Moment Forge `uptime_sec` is wall clock. Divide by
the tick-derived dilation, or read ticks, before treating any interval as a
gameplay timing.

## Landed so far

| commit | what |
|---|---|
| `398fe7a41` | Part A: armed melee body ownership |
| `09cbe98de` | data contract: chain keys, Fast 02/03 profiles, measured contact frames |
| `7f7fb04e0` | preview tool reads the canonical runtime layout |
| (this) | chain timing on the visible clock; blade-SFX guard |

### Clock cleanup (done)

`_fast_chain_presentation_frame()` replaces four direct `animated_sprite.frame`
reads in chain timing: the queue window, the swing-cue frame, the commit
comparison, and the hit-window resolved frame. `animated_sprite` is the correct
clock only while the legacy full body is visible; for a modular chain it is
hidden, so reading it would time a visible attack off an invisible one.
Simulation authority did not move — profiles remain gameplay truth and this only
supplies the authored-frame observation.

### Blade SFX guard (done)

The swing cue fires from the generic authored-chain branch, which keys off
`fast_chain_keys`. Fists now declares a chain, so without a guard punching would
play sword audio. `_weapon_emits_blade_swing_sfx()` tests the weapon's semantic
kind rather than a clip name. This was urgent rather than optional: the chain
keys had already landed in `09cbe98de`, so the trap was armed.

## Current runtime integration

- `_sync_unarmed_fast_chain_action()` resolves through
  `OperatorAnimationSelector`, caller-owned E/W projection, `flip_h = false`,
  claiming `MODULAR_BODY`, starting lower/upper together.
- Fists links use data-authored presentation targets of 0.42 / 0.42 / 0.42 /
  0.50 seconds; Fast 04 reaches its visible terminal recovery.
- Remove unarmed-specific phase choreography once the chain presents; keep
  `_melee_fast_windup` (Vigil still uses it) and the generic non-integrated
  recovery capability.
- Fast 01–04 each use a synchronized authored E/W FX strip in the replacement
  family, sharing the exact visible frame clock with their body layers.
- Reachability: Fast 01/02/03 genuinely LIVE, windup/strike/recovery SUPERSEDED.
- Tooling drift: `operator_next_actions_report.py` phase expansion,
  `refresh_combo_check_src.sh`, active preview docs.
- Design docs: `OPERATOR_MELEE_CONTACT_TIMING_AND_CADENCE.md`,
  `COMBAT_FEEL_SYSTEM.md`, `COMBAT_FEEL_UPGRADE.md`, `CURRENT_STATE.md`,
  `FILE_INDEX.md`.
- `operator_unarmed_fast_chain_smoke.gd` proves four-link ordering, terminal
  behavior, E/W authored identities, no runtime flip, synchronized clocks, and
  the 6/6/7/8 frame contract.
- Part C feel work, which is explicitly gated on B being mechanically green.

Nothing in Part C has been started, by design: the packet gates it on the
migration being green, and tuning feel against a chain that does not yet present
would be tuning noise.

## Part C — feel pass (sequential)

Tuned one parameter group at a time, with evidence between steps, so a bad
setting cannot be hidden by compensating with another.

### C1 — subtle Fists target assistance (done)

The machinery already existed and was already correct: `melee_target_resolver.gd`
gates on `target_assist_enabled`, rejects anything beyond `assist_reach` or
outside `target_assist_cone_degrees`, and clamps the nudge to
`target_aim_correction_degrees`. The Fists profiles simply never opted in, while
the Vigil dagger did.

    target_assist_enabled          true
    target_acquire_extra_px        8
    target_assist_cone_degrees     24
    target_aim_correction_degrees  6
    target_drive_bonus_max_px      0   (raised in C3, once drive existed)

Applied to all four links. The drive bonus is deliberately left at zero so this
step changes aim only -- the assist path can also extend attack drive, and mixing
that in here would make C3 impossible to read.

Measured in `combat/melee_soft_target_spacing`:

| case | input error | correction applied |
|---|---|---|
| target off-axis at 63px | ~4.7 deg | **4.15 deg** (under the 6 deg clamp) |
| target already aligned at 61px | 0 | **0.00 deg** |

So it corrects a real aiming error and does nothing when none exists. Baseline
control: with `target_assist_enabled = false` both corrections read `0.0`, which
confirms the effect comes from this change rather than from pre-existing
targeting.

Gates: operator_melee_soft_targeting, operator_unarmed_fast_chain and
operator_vigil_dagger green. Dagger values untouched.

### C3 — attack-drive continuity (done)

Fists had **no attack drive at all**. Every unarmed link left `drive_distance_px`
at its 0.0 default while both shipped melee weapons escalate across their chains
(Vigil dagger 7/9/11, Sword-Cleaver 9/11/14). The runtime system is complete and
already per-link -- `_begin_attack_drive()` is called from the chain-advance path
with the assist-resolved distance -- so the whole feature was simply inert for
Fists.

That also left a hole in C1 that only drive can close. `MeleeTargetResolver`
builds its reach model from the drive:

    reliable_drive = drive_distance_px * target_reliable_drive_fraction
    reliable_reach = range_px + reliable_drive
    assist_reach   = reliable_reach + target_acquire_extra_px
    assist_drive   = min(distance - reliable_reach, target_drive_bonus_max_px)

With drive at zero, `reliable_drive` was zero and `assist_drive` was always zero.
So C1's 8px acquire ring acquired and aimed at targets between 64 and 72px and
then punched at them from out of range. C1 was aim-only by design; this is the
step that pays for it, which is why the drive bonus lands here rather than there.

| link | drive px | delay s | duration s | input influence | falloff | assist bonus px |
|---|---|---|---|---|---|---|
| fast_01 | 5 | 0.08 | 0.16 | 0.30 | 1.8 | 4 |
| fast_02 | 7 | 0.04 | 0.16 | 0.26 | 1.8 | 5 |
| fast_03 | 9 | 0.05 | 0.18 | 0.20 | 1.7 | 6 |
| fast_04 | 13 | 0.06 | 0.20 | 0.12 | 1.5 | 8 |

Derivation, so these are data rather than taste:

- **Distance** follows the commitment curve the move multipliers already
  establish (1.00/0.95/1.00 down to 0.88/0.68/0.90). Link 1 is the poke thrown
  while repositioning and barely steps; link 4 is the finisher and takes the
  large jump, mirroring the 0.82 -> 0.68 break in active movement.
- **Delay and duration** start from the Cleaver's shipped relation, delay ~
  `windup_sec + 0.02` and duration ~ `active_sec + 0.04`. Link 1 keeps that.
  Links 2-4 cut the delay below it deliberately: a continuation link starts while
  the previous link's drive is still carrying, and honouring the full windup
  there is exactly what makes a chain stutter.
- **Input influence** descends as commitment rises, as on both armed chains, but
  sits higher overall (0.30 vs the Cleaver's 0.20) because Fists is the mobile,
  uncommitted option.
- **Falloff power** is front-loaded for the jabs (1.8) and lower on the finisher
  (1.5) so it carries rather than snaps. Distance is exact at any power -- the
  sampler normalises by `(power + 1) / duration` -- so this changes the shape of
  the step, not its length.

**Residual, recorded rather than hidden.** `_begin_attack_drive()` calls
`_cancel_attack_drive(true)`, which subtracts the outgoing drive's velocity
contribution. Between a chain advance and the next link's delay expiring there is
therefore a window with no drive contribution: about 0.04s at the 1->2 seam,
shorter later. The player's own locomotion still moves them through it
(`movement_profile = "mobile"`), so it is not a dead stop. Closing it properly
means carrying residual drive velocity across links in `_begin_attack_drive()`,
which is a runtime change and not a no-new-assets data pass. Left for a feel
review to decide whether it is perceptible.

The full acquire ring is also not guaranteed to connect. Under the conservative
`target_reliable_drive_fraction = 0.75` model, closing the last pixel of the ring
would need a bonus of `target_acquire_extra_px / 0.75` = 10.7px, which on a 5px
base link would read as a magnet snap. The bonuses above close most of the ring
and scale with the link, so the finisher reaches furthest and link 1 can still
honestly whiff at the outer edge.

Coverage: `operator_unarmed_fast_chain` gained a drive section that asserts the
declared contract, drives each link through the real `_physics_process` and
measures the travelled distance, checks the drive settles without snap-back,
checks opposing input cannot reverse a committed step, and asserts a target at
the edge of each link's own acquire ring now resolves extra drive. Negative
control: zeroing link 1's distance and bonus fails it in six places.

**`operator_sword_cleaver_smoke.gd` had never run.** It exists, it passes, and it
is the gate that owns the Cleaver drive numbers this step calibrated against --
but it was absent from `validation_manifest.json`, the same defect found earlier
with `operator_unarmed_fast_chain_smoke.gd`. Registered at actor tier.
`validation_runner_smoke.py` pins an exact selection list for
`melee_target_resolver.gd` and correctly caught the new entry; the expected list
was updated rather than the owners glob narrowed, because the Cleaver gate should
run when the resolver changes.

Validation: actor tier 55/55, changed set 7/7, and the focused melee set
(operator_melee_soft_targeting, operator_sword_cleaver, operator_vigil_dagger,
operator_unarmed_fast_chain, operator_attack_phase_cadence,
operator_armed_melee_body_visibility, operator_melee_switch_chain,
operator_melee_point_blank, operator_melee_posture) all green.

### C4 — early input forgiveness (done)

`_try_melee_attack()` discarded any fast press made outside the rhythm window. It
did not buffer it, did not shorten it, did not queue it: the press reached
`_obs_log(..., "outside_rhythm_window")` and returned, never touching
`_buffer_attack()`.

On Fast 01 the window opens at frame 2 of 6, so roughly the first third of the
link silently ate the player's input and they had to press again. The pre-window
region per link:

| link | frames | window opens | pre-window region | at the link's own cadence |
|---|---|---|---|---|
| fast_01 | 6 | 2 | frames 0-1 | 0.10 s |
| fast_02 | 6 | 2 | frames 0-1 | 0.11 s |
| fast_03 | 7 | 2 | frames 0-1 | 0.11 s |
| fast_04 | 8 | 4 | frames 0-3 | 0.26 s |

An early press and a late press are different mistakes and now get different
answers. `_fast_chain_queue_window_state()` replaces the bare boolean and reports
`open`, `early`, `late` or `unavailable`; `_is_fast_chain_queue_window_open()`
delegates to it so there is one definition of the window, not two.

- **early** is forgiven. The press is buffered and spent at the commit frame.
  This costs no new timer: `_update_attack_buffer()` already freezes the buffer
  for the duration of an authored chain, so a latched early press survives to
  commit instead of decaying.
- **late** is still refused. The rhythm gate only means something if a missed
  beat can cost you the link, and forgiving both directions would delete it.
- **unavailable** (no chain weapon, no readable clock) is refused, which is what
  the predicate already did.

The forgiveness is bounded by the link's own geometry rather than by a second
tunable. The pre-window region is at most four frames, and it is exactly the
region the author already marked as "not yet queueable", so a separate
forgiveness window would be a knob describing the same interval twice.

Fixed in passing: the rejection log reported `animated_sprite.frame`, which is
the wrong clock for a modular chain — the same defect `_fast_chain_presentation_frame()`
was introduced to fix. It now reports the visible frame.

Coverage in `operator_unarmed_fast_chain`, driven through a real
`_try_melee_attack` on a real running link, with the clock asserted to be the
link actually being drawn: early buffers, inside-window still buffers, late is
still refused, an early press does not decay while the link runs, and an early
press advances the chain at the commit frame. Controlled from **both** sides —
reverting to the old reject-unless-open fails it in four places, and forgiving
late presses too fails it in one.

Validation: actor tier 54/55 (`lootable_corpse_beacon` only, nondeterministic
and unrelated), changed set 36/36, focused chain gates green including the Vigil
dagger and Sword-Cleaver, which share this code path.

### C2 — per-link impact progression (done)

Scoped as presentation hierarchy, not balance: damage stays 10.0 and knockback
56.0 across all four links, and the gate now asserts that flatness so a later
feel pass cannot quietly become a balance pass.

The authored staircase was already in the profiles from the four-link
integration:

| link | hit stop | shake | scale |
|---|---|---|---|
| fast_01 | 0.018 | 0.70 | 0.88 |
| fast_02 | 0.024 | 1.00 | 0.88 |
| fast_03 | 0.032 | 1.45 | 0.86 |
| fast_04 | 0.050 | 2.20 | 0.86 |

**But none of it reached the game.** Two hardcoded per-step tables sat between
`MeleeAttackProfile` and the feedback path and silently overrode it:

```gdscript
func _get_fast_chain_hit_stop_duration(fallback: float) -> float:
    match _melee_fast_combo_step:
        0: return 0.026
        1: return 0.030
        2: return 0.036
        _: return fallback

func _get_fast_chain_camera_shake_multiplier() -> float:
    match _melee_fast_combo_step:
        1: return 1.08
        2: return 1.25
        _: return 1.0
```

Both keyed on steps 0/1/2 with a fallback, which dates them to the retired
three-link model. Nothing else referenced them and no validation asserted their
numbers. What the player actually got:

| link | authored stop | ran as | authored shake | ran as |
|---|---|---|---|---|
| fast_01 | 0.018 | **0.026** | 0.70 | 0.70 |
| fast_02 | 0.024 | **0.030** | 1.00 | **1.08** |
| fast_03 | 0.032 | **0.036** | 1.45 | **1.81** |
| fast_04 | 0.050 | 0.050 | 2.20 | 2.20 |

The authored curve spans 2.8x from first jab to finisher; the one that ran spanned
1.9x, with the early links louder than authored and the steps between them
compressed. Only link 4 was correct, and only because step 3 fell off the end of
a table written for three links.

**This was not confined to Fists.** `_has_authored_fast_chain()` is true for both
armed melee weapons, so the same table overrode them, and there it inverted the
intent outright:

| weapon | authored stop | ran as |
|---|---|---|
| Vigil dagger | 0.022 / 0.027 / 0.043 | 0.026 / 0.030 / **0.036** |
| Sword-Cleaver | 0.032 / 0.034 / 0.048 | **0.026** / **0.030** / **0.036** |

The dagger's finisher was cut from 0.043 to 0.036 and the Cleaver's opener was
cut from 0.032 to 0.026 — the heaviest beats were the ones most flattened.

Both helpers and their call sites are deleted. That removes a parallel impact
system rather than adding one; `MeleeAttackProfile` is now the only authority, as
`CURRENT_STATE.md` already claimed it was.

**One structural change was needed to make this testable.** `_apply_hit_stop()`
resolved the values and applied them in the same function, so the resolved
duration could not be read without also stopping time — and a headless process
frame is ~6 ms while the links differ by 4-8 ms, so a wall-clock measurement
cannot tell the authored staircase from a flattened one. Resolution is now
`_resolve_melee_hit_stop()`, which `_apply_hit_stop()` consumes. Semantics are
unchanged, including the `_active_melee_contact` override for paired executions.
Fusing resolve and apply is precisely what let a parallel table hide in the
middle for as long as nothing could see it.

Coverage in `operator_unarmed_fast_chain`: the authored values and their
monotonicity, damage and knockback asserted flat, the resolved hit stop read from
the seam the apply path uses, and the confirmed-hit path driven against a stub
camera with the power it asks for measured.

**Superseded in part by C7.** This section originally drove
`_trigger_camera_shake()`, which read the profile correctly and which no game code
called. The camera half of C2 was therefore proven against an orphan and was false
on screen until C7 put the authored power on the live confirmed-hit path. The
hitstop half was and remains correct.

Controlled from both directions, as the packet asked: flattening the four links
to one generic impact value fails it in fourteen places, and restoring the two
hardcoded tables fails it in five — so the gate would have caught the defect that
prompted this.

Validation: actor tier, changed set, and the Vigil dagger and Sword-Cleaver gates
green.

### C5 — chain movement continuity (done)

C3 recorded a residual: `_begin_attack_drive()` opens with
`_cancel_attack_drive(true)`, so the outgoing link lost its contribution the
instant a successor started, and the successor then sat through its own
`drive_delay_sec` before moving. The chain read as drive, gap, drive.

Measured at each seam, taking the seam at the link's real commit frame on its own
presentation clock, and measuring drive contribution rather than position so that
ordinary locomotion is not counted:

| seam | seam at | dead frames before | after | drive total before | after | authored budget |
|---|---|---|---|---|---|---|
| 1 -> 2 | 0.150 s | 2 of 3 | **0** | 11.46 px | **12.00 px** | 12.0 px |
| 2 -> 3 | 0.160 s | 3 of 3 | **0** | 16.00 px | **16.00 px** | 16.0 px |
| 3 -> 4 | 0.159 s | 3 of 4 | **0** | 22.00 px | **22.00 px** | 22.0 px |

The seam is bridged across the incoming delay at a speed decaying linearly from
the outgoing link's own authored curve speed to zero. It is funded **first** from
whatever the outgoing link had authored but not yet spent, and **then** from the
incoming link's `_attack_drive_distance_remaining`, which the incoming drive
consequently does not get to spend later. The bound is exact, not approximate:
each seam now drives its two authored distances and not a pixel more. Seam 1 -> 2
rose by 0.54 px because that much of Fast 01's *own* authored distance used to be
forfeited at the handoff; the other two seams are unchanged in total, because
their outgoing link was already fully spent and the bridge borrowed from the
incoming budget instead.

A continuation is recognised structurally rather than by animation name: the live
drive records which chain step it belongs to, and only step N+1 of the same chain
may inherit from step N. A fresh attack, a chain restart at step 0, and all
non-chain melee inherit nothing.

**Two things had to change for the middle seams to work at all**, and both were
found by measurement rather than reasoning:

- A front-loaded falloff spends the authored distance well before the curve ends.
  At the real commit frame, Fast 02 and Fast 03 have **zero** unspent distance, so
  a bridge funded only by outgoing residue would have been empty exactly where it
  was most needed. Hence the fall-through to the incoming budget.
- A drive that exhausts itself used to call `_cancel_attack_drive()`, which wiped
  the chain step and the direction. By the time the chain advanced there was no
  record that a chain had been running. Natural exhaustion now *completes*
  instead, preserving the chain step, handoff speed and handoff direction;
  interruption still cancels, and cancelling still clears the carry.

Coverage in `operator_unarmed_fast_chain`: dead frames at all three seams,
displacement bounded above *and* below at each seam, a chain restart inheriting
nothing, dodge / damage reaction / block each clearing carried momentum through
their real entry points, blocking geometry truncating it, and opposing input
unable to reverse it mid-handoff.

Controlled: restoring the hard cancel fails it in eight places, naming the exact
2 / 3 / 3 dead-frame counts above. The collision case is a two-run comparison,
clear versus obstructed, because asserting only that the drive ended would pass
vacuously -- it ends on its own after its authored duration either way. Removing
the wall from the obstructed run fails it.

No drive profile values were retuned. Fists remains 5 / 7 / 9 / 13 px.

Validation: actor tier 54/55, changed set 36/36, focused melee and dodge/guard
gates green.

### C6 — terminal Fast 04 posture settle (done)

No new art. Fast 04 already ends on a guarded frame; the seam was that posture
threw that away.

`UnarmedPosturePresentation.advance()` resets its model to RELAXED whenever
posture is unavailable, and posture is unavailable for the whole of an attack.
RELAXED is the right *resting assumption* for a body posture did not see land,
but it is not a claim about where the body actually is, and the finisher had put
it somewhere specific. Confirmed by negative control, which reproduces both
pre-fix symptoms exactly:

| engagement | before | after |
|---|---|---|
| active | `fast_04` -> **`relaxed_to_ready_01`** -> `idle_ready_01` | `fast_04` -> `idle_ready_01` |
| quiet | `fast_04` -> **`idle_relaxed_01`** (pop) | `fast_04` -> `ready_to_relaxed_01` -> `idle_relaxed_01` |

`settle_from_terminal_attack()` sets the posture anchor to READY and cancels any
stale transition. It plays nothing and owns no gameplay state; the ordinary
resolver decides everything after it, which is why an engaged settle simply holds
READY and a quiet one exhales through the transition that already existed.

**The latch is consumed on the first frame posture can actually present**, not
when the attack ends. Fast 04 drives 13 px, so the actor is still coasting for a
few frames afterwards and `_can_present_unarmed_posture()` is false for a reason
that has nothing to do with posture; arming the anchor into that window would
have let `advance()` wipe it immediately. `_is_unarmed_posture_preempted()` was
split out of the availability predicate for exactly this: the same question
without the "is the actor standing still" half.

Terminality is structural, not a name match: the last key of a non-looping
authored chain that owns its own recovery, on an unarmed profile. The completion
branch it hangs off is already unreachable while anything is buffered, so a
queued dodge, heavy or restart never arms it, and a real interruption clears it
through the preempt check.

Coverage in `operator_unarmed_posture`, driven through a real `_start_fast_attack`
and a real completion: Fast 04 keeps its 8 authored frames playing for its
authored 0.52 s, posture is never presentable while the finisher is active, the
engaged settle inserts no `relaxed_to_ready_01`, the quiet settle reaches
`idle_relaxed_01` only after `ready_to_relaxed_01`, dodge and damage reaction each
leave the settle uninstalled, and a buffered press at the terminal link neither
arms the settle nor adds latency to the restart. Control: returning posture from
the attack semantically RELAXED fails it in three places, naming the bridge and
the pop.

**Two corrections to the packet's assumptions, both found by measurement.**

- `_melee_duration` for the unarmed chain is derived from `animated_sprite`, which
  during a modular chain is showing an unrelated leftover clip -- in one observed
  state `melee_1h/attack/critical_execution_01/e/weapon`. It measured 0.667 s in
  one setup and 0.360 s in another against a 0.520 s finisher. This is the same
  wrong-clock defect class as `_fast_chain_presentation_frame()` and the C2 tables,
  it is a **cadence** concern this slice was told not to touch, and an assertion
  written against it would have been asserting an accident. Recorded, not fixed.
- Fists never sets `_terminal_fast_restart_buffered`. That flag is set only on the
  `_fast_chain_commits_on_animation_finished()` path, which is a Vigil behaviour;
  a buffered press at the Fists terminal link is spent at the commit frame
  instead. The restart case asserts the real consumption rather than a flag this
  chain does not use.

### C7 — contact-owned melee feedback (done)

Two notions of "the active contact" existed. `_apply_melee_hitbox_tick()` resolved
the right one locally and already used it for damage, posture, knockback, dedupe
and enemy reaction identity. But `_sync_melee_hitbox_window_from_animation()`
separately left `_active_melee_contact` holding whichever contact its scan saw
**last**, and the confirmed-hit path read that global. One update crossing two
contacts therefore shipped `cut_01`'s damage with `cut_02`'s hitstop and heavy
camera.

`_on_melee_hit_confirmed()` now takes the contact that landed and resolves
everything from it once, through a single hierarchy in
`_resolve_melee_contact_feedback()`:

    authored contact override -> active MeleeAttackProfile -> legacy actor fallback

`_active_melee_contact` survives only as the window scan's bookkeeping record; it
is no longer read by any feedback path.

**The second hole was larger than the first.** `_trigger_camera_shake()` read the
profile's `camera_shake_power` correctly -- and **no game code called it**. The
live confirmed hit went to `Camera2D.on_attack_impact(direction, is_heavy)`, which
flattened every melee impact to `3.2 if is_heavy else 1.8`. So the C2 staircase
was true in the profiles, true in its test, and false on screen; C2's own
coverage was proving an orphan. The helper is deleted, `on_attack_impact` takes an
optional authored amplitude, and the Fists coverage now drives the live path.

Measured on the live path, per link:

| link | camera asked for | hit stop |
|---|---|---|
| fast_01 | 0.70 | 0.018 |
| fast_02 | 1.00 | 0.024 |
| fast_03 | 1.45 | 0.032 |
| fast_04 | 2.20 | 0.050 |

**Vigil was preserved, not retuned.** Making the profile authoritative would have
dropped `cut_02` from the 3.2 it ships at to the profile's 1.5. Both cuts now
carry an explicit `camera_shake_power` derived from current shipped output --
`cut_01` 1.8, `cut_02` 3.2 -- so the finisher looks exactly as it does today while
the generic path becomes profile-driven. Every other authored value is untouched.

Controls, all three of them biting:

- Re-reading feedback from the global fails the skipped-frame case: `cut_01`
  fires at 3.2 with the heavy push.
- Passing -1.0 to the camera instead of the authored power fails the Fists case in
  eight places, each naming the generic fallback.
- Calling `_on_melee_hit_confirmed()` per target instead of per contact fails the
  multi-target case: 3 camera requests for one contact, and 2 then 4 across the
  finisher.

Coverage: the Vigil gate gained a skipped-frame case that crosses runtime frames 4
and 8 in one update -- the existing finisher case polls them separately, which is
precisely why it never caught this -- plus multi-target and miss controls. The
Fists gate drives real confirmed contacts against a camera probe.

Two things worth recording about building it. The Fists fixture could not open its
own hitbox: `enable_hitbox()` early-returns on a stale `_melee_hitbox_active`, and
`frame_changed` reruns the window scan, which closes the box on any frame that
authors no contact. Rather than fight that, the multi-target and miss controls use
the Vigil harness, which lands hits through the real scan. And an early version of
the Fists case died on a missing method and **still reported "passed"**, because
the harness prints its own result -- the case was rewritten so its assertions
actually run.

`_melee_duration`'s wrong-clock cadence defect from C6 was left untouched, as
instructed.

### Remaining Part C steps
### Remaining Part C steps

C8 parry alignment. Then a Part C closeout for the `_melee_duration`
wrong-clock defect C6 uncovered.
