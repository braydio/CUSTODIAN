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

The replacement art is already published. No Asset Pipeline V2 work is expected.
Confirmed against `operator_runtime_manifest.generated.json`:

```
unarmed/attack/fast_01/{e,w}/lower_body   9f
unarmed/attack/fast_01/{e,w}/upper_body   9f
unarmed/attack/fast_01/e/fx               3f      <-- asymmetric, see below
unarmed/attack/fast_01/w/fx               9f
unarmed/attack/fast_02/{e,w}/lower_body   7f
unarmed/attack/fast_02/{e,w}/upper_body   7f
unarmed/attack/fast_02/{e,w}/fx           7f
unarmed/attack/fast_03/{e,w}/lower_body   8f
unarmed/attack/fast_03/{e,w}/upper_body   8f
unarmed/attack/fast_03/{e,w}/fx           8f
```

**Discrepancy found, not yet resolved:** `fast_01/e/fx` has 3 frames while
`fast_01/w/fx` has 9. Every other layer pair in the family is symmetric. This is
recorded rather than papered over; it needs a decision before FX is wired for
Fast 01 (the east FX may be a truncated publication).

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

| link | frames | contact | peak reach | queue open | queue close | commit |
|---|---|---|---|---|---|---|
| fast_01 | 9 | **5** | 80 px | 5 | 8 | 5 |
| fast_02 | 7 | **5** | 75 px | 5 | 6 | 5 |
| fast_03 | 8 | **6** | 82 px | 6 | 7 (terminal) | 6 |

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

## Fast 01 canonical presentation is live

`_sync_unarmed_fast_chain_action()` resolves the link through
`OperatorAnimationSelector`, projects the presentation sector east/west in the
caller, verifies the whole pair before claiming `MODULAR_BODY`, and plays lower
and upper together with `flip_h = false`.

Gameplay direction is never touched. Only the presentation sector is projected,
so a north-facing punch still hits north while drawing the east strip.

Two seams made this possible and are worth recording:

- `MeleeAttackProfile.presentation_action` has existed all along **with no
  reader anywhere in the actor**. That unread field is exactly why Fists kept
  presenting through the retired clips; it is now the authority for which link
  is drawn.
- The chain presentation runs *before* the phase path in
  `_sync_modular_action_domains()`. Without that ordering the consolidated strip
  started correctly and was overwritten by the old phase art one frame later --
  measured, not assumed.

Live probe:

```
chain keys: ["unarmed_fast_01", "unarmed_fast_02", "unarmed_fast_03"]
link 1: active=true windup=false
        lower=unarmed/attack/fast_01/e/lower_body
        upper=unarmed/attack/fast_01/e/upper_body   scale=1.63
```

Scale 1.63 is derived, not hardcoded: authored 9 frames / 12 FPS = 0.75 s over
the profile's 0.46 s target. Retiming a link is now a data edit.

Fast 01 overlay FX is deliberately omitted in **both** directions, per decision.
The east source is a 3-frame 128px sheet and the archived east asset is 3 frames
too, so this is a source-family discrepancy rather than a truncated publish.
Recorded as an Asset Pipeline V2 repair candidate. The existing unarmed contact
VFX still plays, so impact is not silent. Fast 02/03 FX will be enabled.

## Remaining work

- **Chain advance.** Links 2 and 3 do not yet advance in a live probe: a fresh
  `_try_melee_attack` after completion is refused by cooldown rather than
  queued. The buffered-primary path through the queue window needs verifying
  against the measured 5/5/6 commit frames. Fast 01 presentation is correct.
- `operator_modular_fast_attack_smoke.gd` now fails, correctly: it asserts
  `fast_strike_01` where runtime presents `fast_01`. It validates the superseded
  family and must be retired or rewritten, not patched to accept both.
- Remove the unarmed phase choreography once 02/03 advance; keep
  `_melee_fast_windup` (Vigil uses it) and the generic non-integrated recovery.
- Reachability, tooling drift, design docs.
- `operator_unarmed_fast_chain_smoke.gd` with the 23 points and the negative
  controls.
- Moment Forge cadence pass, then finalize the provisional 1.63 / 1.39 / 1.28.
- Part C, gated on the above being green.
