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

Preserved Fast 01–03 FX and full-body variants remain compatibility/preservation
art and are not selected by the four-link modular presentation. Only Fast 04's
synchronized extracted flare is live in this chain.

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
- Fast 01–03 preservation FX are deliberately not wired. Fast 04 owns the only
  synchronized FX strip in the replacement family.
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
