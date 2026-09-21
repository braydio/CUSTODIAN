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

## Remaining work

- Populate the definition and author Fast 02/03 profiles.
- Capture frame metadata from the preview tool.
- `_sync_unarmed_fast_chain_action()` helper resolving through
  `OperatorAnimationSelector`, caller-owned E/W projection, `flip_h = false`.
- Clock cleanup: replace `animated_sprite.frame` reads in fast-chain timing with
  `_presentation_clock_sprite()`.
- Guard blade swing SFX by weapon kind so Fists never emits it.
- Remove unarmed-specific phase choreography (keeping shared flags and the
  generic non-integrated recovery capability).
- Reachability: Fast 01/02/03 genuinely LIVE; windup/strike/recovery SUPERSEDED.
- Tooling drift: `operator_next_actions_report.py` phase expansion,
  `refresh_combo_check_src.sh`, active preview docs.
- Design docs: `OPERATOR_MELEE_CONTACT_TIMING_AND_CADENCE.md`,
  `COMBAT_FEEL_SYSTEM.md`, `CURRENT_STATE.md`, `FILE_INDEX.md`.
- `operator_unarmed_fast_chain_smoke.gd` with the 23 acceptance points, plus
  retiring/rewriting `operator_modular_fast_attack_smoke.gd` and updating
  `operator_attack_phase_cadence_smoke.gd`.
- Negative controls listed in the packet.
- Moment Forge full-capture review of Fast 01→02→03.
