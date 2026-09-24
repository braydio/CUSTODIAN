# Operator C2b — canonical animation authority

**Status: partially complete. C2b is not closed.** Three of the five target debt
categories reached zero. Two did not, for one shared reason that is written out
below rather than deferred to "future work", because the reason is the useful
part of this summary.

Read `OPERATOR_SLICE_D_CLAUDE_SUMMARY.md` for D.3, which opened this task as its
regression gate and did pass.

## Measured result

```
architecture debt      119 -> 98        (target was ~75)
operator.gd         15,231 -> 14,841 lines
operator.gd            723 -> 709 functions
```

Per category:

```
                                 before   after   target
operator_animation_catalog            4       0        0   done
attack_fallback_animation            13       0        0   done
actor_local_spriteframes              5       1        0   1 remains
animation_resolver                   18      18        0   BLOCKED
directional_animation_fallback        4       4        0   BLOCKED
```

The baseline was refreshed to the measured 98 through the approved `/tmp` flow.
No regex was weakened, no exemption was added, no symbol was renamed to escape
detection, and no audit coverage was removed.

One honest caveat about the count. The `attack_fallback_animation` rule matches
the bare token `fallback_animation`, including in comments. After removing the
mechanism, my own explanatory comment still named the removed parameter and kept
the count at 1. I rewrote that sentence to describe the removal without spelling
the token. That is a prose change, not a code change, and it is the one place
where the number moved for a reason other than deleted machinery.

## What was actually removed

### OperatorAnimationCatalog (4 -> 0)

The catalog was a second animation database read at runtime. Before touching it I
compared its contents against the generated `operator_runtime_frames.tres`:

```
catalog identities                                675
canonical runtime identities                      582
in catalog, not in runtime                        179   all named legacy_*
in catalog, not in runtime, WITHOUT "legacy"        0
in runtime, not in catalog                         86   newer authored work
```

Zero non-legacy identities were unique to it, and the canonical frames carry 86
it never had. It was migration residue, not an authority. The posture/locomotion
weapon-overlay install now copies from the canonical frames instead — same
identities, same pixels — and `_copy_catalog_animation` is renamed
`_copy_runtime_animation` because its source is no longer a catalog.

`OperatorAnimationCatalog` itself had exactly one consumer: a `load_catalog()`
validity check in `_ready` whose result was never read again. The class is
deleted. The generated JSON manifest stays — it is pipeline metadata, and only
its runtime consumer disappeared.

`operator_melee_posture_smoke` asserted against the catalog resource. Repointing
it at the canonical frames left every assertion passing unchanged, which is the
same superset finding arriving from the test's side.

### attack_fallback_animation (13 -> 0)

`MeleeAttackProfile.fallback_animation` named a second compatibility base for
`_play_melee_anim_from_key()` to retry when the first produced nothing. Both
spellings resolve through the same `FULL_BODY_IDENTITIES` table to the same
canonical identity, so the retry either repeated the first attempt or asked for
an identity the weapon did not claim.

Removed at the source: the `@export`, its value in ten attack profiles, the
parameter, and the write-only locals that fed it. Not renamed, not defaulted —
gone.

### Knight test skin, and why it mattered structurally

Documented `KNOWN STALE` since C2a-R4: it swapped `animated_sprite.sprite_frames`
for compatibility names that canonical playback no longer requests, so the body
simply did not present while it was on. It still had a live DevConsole command,
which is how something can be both reachable and dead.

It was also **the last writer of `animated_sprite.sprite_frames`**, which is why
it is in this slice rather than a cleanup pass. Retired with its command.

### Runtime PNG loading and actor-local SpriteFrames (5 -> 1)

`_ensure_melee_fast_chain_fx_animations()` loaded six PNGs at runtime into names
(`melee_2h_fast_N_fx_left/right`) that **no weapon `fx_map` references** — checked
across every `*_definition.tres`. It also ran before
`_apply_melee_weapon_animation_resources()` replaced the overlay's resource
wholesale. Deleted; no authored visual changed.

`_ensure_dodge_fx_animation()` loaded exactly the PNGs behind the canonical
identities `shared/transition/dodge_01/{n,s}/fx`. Verified identical before
swapping rather than after:

```
frames  9      (both)
loop    0      (both)
speed   25.0   (canonical .tres) == DODGE_FULL_SEQUENCE_FPS (the builder's value)
```

`DodgeFXBackSprite` now binds the canonical runtime frames in the scene and
resolves through the selector. The step-FX fallback went with it — its sheet path
was the empty string, so that animation never existed to fall back to.

`operator.gd` now loads no PNG at runtime.

## What did NOT work, and why

This is the part worth reading.

I removed the compatibility tail of `_play_melee_anim_resolved()` — the
`AnimationResolver` pass, the `<base>_right` probe, the bare-base probe and the
`attack_right_old` probe — on what looked like a proof:

- `animated_sprite` binds `operator_runtime_frames.tres` in the scene;
- after the Knight skin was retired, **nothing assigns that property**;
- every identity in that resource is slash-delimited
  (`profile/group/action/sector/layer`) — I checked, zero exceptions;
- every name those probes construct contains no slash;
- therefore they could only ever miss.

Every one of those statements is true. The conclusion is still wrong, because
`_install_weapon_body_frames()` copies a weapon's `body_frames_resource`
animations **into that same `SpriteFrames` object**. Equipping the Vigil dagger
adds `vigil_dagger_fast_03_right` to the canonical database in place. The
resource on disk is canonical-only; the resource in memory is not.

`operator_vigil_dagger` caught it — the finisher lost its authored body. I
restored the tail with that reasoning written directly above it, because the next
person to read that function will reach for the same argument I did.

This is also the reason `animation_resolver` and
`directional_animation_fallback` did not move. They are not call-site debt. They
are held up by a runtime mutation of the shared canonical resource, and removing
them requires per-weapon body art published as canonical identities first.

**Worth flagging on its own:** `_install_weapon_body_frames()` mutating the shared
canonical `SpriteFrames` at runtime is arguably a worse violation than the ones
this audit tracks, and no current rule catches it. It deserves its own rule.

## Missing canonical identities (reported, not invented)

No new PNGs were authored and Asset Pipeline V2 was not bypassed. The weapon
layer is published weapon-scoped:

```
weapon/vigil_pattern_dagger/melee_1h_dagger/attack/fast_0{1,2,3}/{e,w}/weapon
weapon/vigil_pattern_dagger/melee_1h_dagger/defense/block_{enter,hit,loop}_01/{e,w}/weapon
weapon/sword_cleaver/melee_1h_heavy/attack/fast_0{1,2,3}/{e,w}/weapon
```

The matching **`fx` layer does not exist at all** — there are no
`weapon/<id>/.../fx` identities. The armed-melee FX overlay therefore still runs
from per-weapon compatibility resources (`vigil_dagger_fast_01_fx_right` and
friends). Full-body per-weapon art (`vigil_dagger_fast_0N_right`) is likewise
unpublished canonically.

Until those exist, the melee weapon/FX overlays cannot bind the canonical
database, which is also what keeps the last actor-local `SpriteFrames`
construction alive.

One authored delta to note if that work happens: the canonical
`weapon/vigil_pattern_dagger/.../fast_02/e/weapon` points at the per-weapon
*override* art, while the compatibility resource pointed at the generic
`operator__weapon__melee_1h_dagger__attack__fast_02` strip. Same geometry
(`156x96`), different pixels. The canonical one is the authored-correct choice,
but it is a change and should land with a regression rather than silently.

## Phases not started

Phase 7 (deleting `operator_melee_overlay_frames.tres`,
`operator_weapon_frames.tres`, `operator_ranged_fx_frames.tres`,
`AnimationResolver`, `DirectionalAnimationFallback`) is untouched: each still has
live runtime or tooling consumers, and deleting them now would mean resurrecting
dead resources to keep tests running — exactly what the packet forbids.
`operator_animation_catalog_frames.tres` also stays; its runtime consumer is gone
but six validation and tooling scripts still read it.

`operator_timing_preservation` is therefore **not** retired and still passes.

## Validation

```
operator_input_aim_source          PASS   (D.3, both mutations checked)
operator_input_frame               PASS
operator_vigil_dagger              PASS   (caught the bad removal first)
operator_sword_cleaver             PASS
operator_unarmed_fast_chain        PASS
operator_melee_posture             PASS   (repointed at canonical frames)
operator_attack_phase_cadence      PASS
operator_timing_preservation       PASS
operator_dodge_flow                PASS
operator_animated_sprite_canonical PASS
operator_body_pair_canonical       PASS
operator_visual_ownership          PASS
operator_architecture_debt         PASS   98, baseline refreshed
operator_runtime_path_audit        PASS   ledger shrunk by the 8 removed PNG paths
operator_ranged_ready_input        PASS   (after repointing its dodge-FX assertions)
operator_dodge_fx_canonical        PASS   (new)
actor tier                         56/56
changed set                        4/4
```

Actor tier: **56 selected, 56 passed** after one fix. The first run was 55/56 --
`operator_ranged_ready_input` failed on two dodge-FX assertions still written
against the retired compatibility name `operator_dodge_full_fx_south`. That was a
real regression from this slice, not a stale test: the assertions were correct
about the behaviour and wrong about the identity. Repointed at
`shared/transition/dodge_01/s/fx` and given a frame-count check.

Worth naming: `operator_dodge_flow` passed throughout and proved nothing about
this, because `_play_dodge_fx()` fails soft -- a missing animation returns
silently, so the FX can stop rendering without any test noticing. The coverage
that existed was in the *ranged ready input* smoke. I added
`operator_dodge_fx_canonical` for this directly: it asserts the renderer binds
the canonical resource object (not a duplicate), that both authored facings keep
9 frames / 25 fps / no-loop, and that a live north and south dodge each present
the matching identity visibly.

New C2b **hard invariants** (not migration gates) in
`operator_runtime_animation_authority_smoke.py`: the catalog script must not
return, `operator.gd` must load no runtime PNG, at most one actor-local
`SpriteFrames` may be constructed, and `DodgeFXBackSprite` must keep its
scene-bound resource.

Two pre-existing `FAIL` lines in that smoke ("gameplay reads weapon source art"
for the dagger and cleaver overlay resources) are **not** from this work —
confirmed by running it against a clean `HEAD` before any C2b commit.

Moment Forge was not run. No authored timing, cadence, window or economy value
changed; the only art-path change (dodge FX) was proven frame-, loop- and
FPS-identical beforehand.

## Non-goals respected

Slice E and Slice F not started. No combat balance, attack cadence, dodge
economy, parry window or ranged-threshold change. No artwork changed, no
production PNGs added, `OperatorBodyPresenter` untouched, and no domain state
moved merely because `operator.gd` is large.

## Recommended next step

Not Slice E. The honest ordering is a small pipeline slice that publishes the
per-weapon full-body and `fx` identities named above, plus an audit rule for
runtime mutation of the canonical `SpriteFrames`. With those, the rest of C2b is
the mechanical cleanup it was originally scoped as. Starting Slice E now would
build action arbitration on top of a live `AnimationResolver`, which is the exact
thing C2b existed to prevent.
