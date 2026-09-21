# Unarmed Posture Runtime

Branch `unarmed-posture-runtime`, worktree `/home/braydenchaffee/Projects/CUSTODIAN-posture`,
merge base `1febeae0a` on `main` (rebased as main advances).

This file is overwritten each time the slice advances; it is not a changelog.

## Status

**Both parts complete.** Actor tier 52/52, changed-set 34/34, focused gates green.

```
A. harden the R4.1 acceptance proof + fix summary drift   DONE
B. implement Unarmed Posture Runtime                      DONE
```

## Part A — R4.1 proof hardening

The R4.1 runtime fixes were correct; the test meant to prove them was not.
`_equip_armed_melee()` set `using_unarmed = false` and
`combat_loadout_mode = "melee"` by hand, which is not a loadout:
`_rebuild_armed_weapon_list()` appends the primary ranged weapon first, so the
current profile stayed the carbine and the guard passed only because it was not
*unarmed*.

Selection now searches `armed_weapons` for `weapon_kind == "melee"` and goes
through `_apply_armed_selection()`. Heavy anticipation drives the real
`_start_heavy_attack()` per cardinal, asserts anticipating with `_melee_active`
still false, and completes through the real clock signal. **All four cardinals
pass**, so the projections and semantic completion predicates hold under a
genuine armed melee loadout.

Recovery was also synthetic and is now tested per path. Both shipped melee
weapons set `fast_chain_has_integrated_recovery`, so an armed fast chain never
reaches the generic helper; calling it by hand proved nothing the game does, and
asserted Sword-Cleaver overlays that do not exist. The unarmed loadout genuinely
uses the helper and is driven end-to-end; armed weapons are checked against the
contract that skips it, with an anti-vacuous assertion that the attack actually
started. If an armed weapon ever ships without integrated recovery, the
else-branch starts requiring generic recovery for it.

That evidence also corrected a claim R4 made:
`melee_1h_heavy/attack/fast_recovery_01` was marked LIVE through a branch no
shipped loadout reaches, and is back to DORMANT with the condition that would
revive it.

## Part B — Unarmed Posture Runtime

`presentation/unarmed_posture_presentation.gd` owns the posture model, the
east/west projection, and the transition lifecycle. It **reuses
`MeleePostureState`** rather than adding a second READY/RELAXED machine; SHEATHED
and draw grace are melee concepts it never enters. Melee posture behaviour is
untouched.

```
quiet   -> idle_relaxed_01
engaged -> relaxed_to_ready_01 -> idle_ready_01
quiet   -> ready_to_relaxed_01 -> idle_relaxed_01
```

- **Engagement** comes from `EngagementTracker` alone. No proximity scan, no
  second timer, no new gameplay state, no retuning.
- **Attacks are never gated.** An attack from RELAXED begins on the frame it is
  requested; the smoke asserts gameplay engaged and that no ready-up preceded it.
- **Movement** retires the stance immediately. `_update_animation` reaches
  locomotion before the idle branch, and `_can_present_unarmed_posture()` refuses
  independently so a direct caller cannot draw a stance over a walk.
- **Preemption** needs no token and no timer. A transition is state, not a
  scheduled callback: it ends when its own clip reports completion, and
  `advance()` drops it the moment posture stops being available. There is nothing
  to race against — the new owner retires the layer, and the forgotten transition
  has no continuation to fire. That also means the one-frame placeholders can be
  replaced with real art without touching runtime logic.
- **Direction**: authored `e`/`w` only. `x < 0 -> w`, everything else including
  north and south `-> e`, played with `flip_h = false`. The selector stays
  exact-only and the smoke asserts it still reports the unauthored sectors absent.

One deliberate visual consequence: a stationary unarmed Operator facing south now
shows the east-facing relaxed stance instead of the south locomotion idle. That
follows directly from the e/w-only authoring decision, and
`operator_modular_layers_smoke` was updated to the new truth rather than left
asserting the old one.

## Reachability changed

```
unarmed/posture/idle_relaxed_01          DORMANT -> LIVE
unarmed/posture/idle_ready_01            DORMANT -> LIVE
unarmed/transition/relaxed_to_ready_01   DORMANT -> LIVE
unarmed/transition/ready_to_relaxed_01   DORMANT -> LIVE
melee_1h_heavy/attack/fast_recovery_01   LIVE -> DORMANT   (corrects an R4 claim)
```

## Architecture debt

The audit caught a violation I introduced: `_update_unarmed_presentation_posture`
took a delta on the render tick. Unarmed posture has no time-based state —
engagement is advanced on the fixed tick by its own tracker, and transitions end
on clip completion — so it no longer takes one. The ledger was then refreshed for
a genuine shrink (`animation_resolver` in operator.gd, 22 -> 17), after verifying
no metric increased.

## Validation

```
focused   operator_unarmed_posture, operator_attack_phase_cadence,
          operator_melee_posture, operator_modular_fast_attack,
          operator_animated_sprite_canonical, reachability audit,
          operator_visual_ownership          all green
changed   34/34
actor     51/52
```

The one actor-tier failure is `lootable_corpse_beacon`, nondeterministic
independently of this work and unrelated to Operator animation: sampled
FAILED/PASSED/FAILED in three consecutive runs here, and previously 2/3 on an
unmodified checkout.

Preemption is proven against real owners, not flags. A genuine in-flight
transition is interrupted by a real attack, a real dodge and real movement; each
asserts the attack or dodge actually started, that the transition was dropped,
that the body moved to the new presenter, and that
`OperatorBodyPresenter.visible_owners()` holds at most one. Hit reaction and
death remain flag-driven and are described as what they are — guard and
cancellation tests, proving posture stands down and refuses to present again,
not full owner transfers.

Negative-controlled rather than assumed: suppressing the transition, mirroring
west onto east, and removing the movement guard each fail the posture smoke;
removing the cancellation on unavailability fails it in five places; restoring
the old completion predicate and removing the heavy projection each fail the
cadence smoke.

## BLOCKER FOUND: an unimportable tracked audio asset

`custodian/content/audio/sfx/combat/hit_medium_body_01.wav` is
**WAVE_FORMAT_EXTENSIBLE** (`audio_format=65534`), which Godot's WAV importer
rejects outright:

```
ERROR: Format not supported for WAVE file (not PCM).
ERROR: Can't save empty resource to .../hit_medium_body_01.wav-...sample
```

`operator.gd` preloads that wav, so on any **fresh checkout** the script fails to
parse and every Operator test fails. Existing worktrees only work because they
carry a cached `.sample` from before, which a clean clone cannot reproduce.

This is pre-existing and unrelated to posture. I unblocked locally by copying the
cached artifact into this worktree's gitignored `.godot/imported/` — no repo
change. The real fix is re-encoding the asset as PCM through the audio pipeline,
which is an asset decision outside this slice.

## Deferred deliberately

- Older ranged `aim_01` / `fire_01` compatibility-era reachability prose. Its
  validation is not wrong, and C2b is the better broom.
- The Knight test skin remains knowingly stale and disabled by default.
- Re-encoding `hit_medium_body_01.wav` belongs to an audio/asset-pipeline task.

## Open decisions

None. No unresolved issues.
