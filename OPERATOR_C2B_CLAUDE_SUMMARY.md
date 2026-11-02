# Operator C2b — canonical animation authority

Two slices, recorded in order. **C2b** (first pass) and **C2b.1** (blocker
removal). C2b is still not closed; what remains is smaller and better understood
than when it started.

Read `OPERATOR_SLICE_D_CLAUDE_SUMMARY.md` for D.3, which opened this work as its
regression gate and passed.

## Measured result, both slices

```
architecture debt      119 -> 98 -> 95
operator.gd         15,231 -> 14,841 -> 14,849 lines
operator.gd            723 ->    709 ->     709 functions
```

Per category:

```
                                 start   C2b   C2b.1   target
operator_animation_catalog           4     0       0        0   done
attack_fallback_animation           13     0       0        0   done
actor_local_spriteframes             5     1       0        0   done
animation_resolver                  18    18      16        0   deferred
directional_animation_fallback       4     4       4        0   deferred (out of scope)
```

The baseline was refreshed to measured truth after each slice, through the
approved `/tmp` flow.
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
`directional_animation_fallback` did not move in C2b. They are not call-site
debt. They are held up by a runtime mutation of the shared canonical resource,
and removing them requires per-weapon body art published as canonical identities
first.

**Worth flagging on its own:** `_install_weapon_body_frames()` mutating the shared
canonical `SpriteFrames` at runtime is arguably a worse violation than the ones
this audit tracks, and no current rule catches it. It deserves its own rule.

> **C2b.1 resolved this.** The mutation is gone and the invariant is now
> executable rather than a note in a summary — see below. One correction to the
> paragraph above, from measurement rather than argument: "per-weapon body art
> published as canonical identities" was too broad. Almost all of it already
> existed.

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

### DirectionalAnimationFallback is not a rename away either

Three of its four sites are the nearest-available-sector search, blocked by the
same runtime mutation as above. The fourth, `vector_to_sector()`, looks like a
pure function the selector already duplicates -- and swapping it would be a
behaviour change, not a cleanup. Sampling 20,000 directions around the circle:

```
DirectionalAnimationFallback.vector_to_sector   OperatorAnimationSelector.vector_to_sector
  wrapf(angle, 0, TAU), round(), % 8              raw angle(), floor(x + 0.5), posmod()
  zero test: length_squared() <= 0.0001           zero test: is_zero_approx()

disagreements at exactly -157.5 deg  -> w  vs nw
disagreements at exactly -112.5 deg  -> nw vs n
a 0.0001-magnitude vector            -> s  vs e   (different zero thresholds)
```

Two boundary angles and the near-zero threshold. Small, but this is dodge
direction selection, and I had just been burned by one equivalence that held on
disk and failed at runtime. Left alone deliberately; whoever finishes this should
pick the intended boundary behaviour on purpose rather than inherit whichever
function survived.

# C2b.1 — armed melee canonicalization and the immutable spine

The blocker C2b found, removed. Equipping a weapon no longer edits the animation
database; it changes which identity a renderer selects.

## What measurement corrected

C2b ended saying per-weapon body and FX art was broadly missing. That was an
argument, not a measurement, and it was wrong in both directions. C2b.1 started
by characterizing every live Vigil/Cleaver fast-chain animation against its
candidate canonical identities using decoded pixels, frame count, FPS, loop and
per-frame durations
(`reports/operator/operator_armed_melee_canonicalization.json`).

Two measurement traps had to be cleared first, and each would have produced a
confident wrong answer:

- Comparing `(texture, region)` pairs calls the source and published strips
  different art. The compatibility resources cite
  `weapons/<id>/source/.../legacy_*`; the canonical database cites
  `weapons/<id>/runtime/.../attack/<action>`. Same pixels, different files.
- Hashing raw RGBA then calls them different anyway. Vigil fast_01 differs in the
  RGB channels of **450 fully transparent pixels** and in **zero** visible ones —
  PNG encoder choice, not art. The hash now zeroes RGB under alpha 0.
  (`ImageChops.difference().getbbox()` happens to agree, because `getbbox()`
  keys on alpha for RGBA. Right answer, wrong reason, so the tool is explicit.)

What that showed:

```
Vigil weapon layer      already canonical, all three links, nothing to do
Vigil fast_01/02 body   already canonical pixels, wrong published rate
Vigil all three FX      already canonical pixels, wrong published rate
Vigil fast_03 body      the ONLY genuine gap
Sword Cleaver           not rendering melee_1h_heavy art at all
```

The Vigil weapon layer was already published at 9 frames / 13 fps with the 1.5x
final hold for Fast 03. Three of its nine frames differ from the legacy source by
2, 2 and 5 pixels out of 14,976 — a re-encode artifact.

## Timing, fixed in the pipeline rather than the actor

The shared `melee_1h/attack/fast_0N` body and FX layers carried **no timing
sidecar**, so they published at the 12 fps default while the dagger played them
at 18/14/13. Canonicalizing without closing that gap would have retuned the
dagger by accident.

The evidence that 18/14/13 is the *semantic* timing of those identities, not a
dagger-local preference, is that the database already said so: the weapon layer
of the same actions carried exactly those rates. Only body and FX were missing
sidecars. Checked for a competing clock before retiming shared art — no runtime
consumer selects `melee_1h/attack/*` semantically at all; the only `melee_1h`
identities the actor asks for are `transition` and `defense`.

18 sidecars authored in `source/`, republished with
`sync_operator_runtime_assets.py`, rebuilt with
`build_operator_runtime_frames.gd`. No generated file was hand-edited. Diffed
against HEAD: **582 animations before and after, none added, none removed, and
exactly the 18 intended changes.**

## The one preservation asset

Vigil Fast 03's body plays the **first nine** atlas regions of the generic
ten-frame strip at 13 fps with a 1.5x hold. A subrange, not a retime, so it
became weapon-owned art rather than something imposed on `melee_1h`.

Those exact nine frames were copied region-for-region — no resample, no redraw,
no new art — into an Operator V2 source master under the weapon's override tree
and published through `OperatorAssetKey`, which produced the canonical path and
filename itself. The new PNG needed a Godot import pass before the frames build
could load it.

```
source master vs compatibility resource : 9/9 frames pixel-identical, both sectors
published identity vs compatibility     : EXACT (identical pixels AND timing)

weapon/vigil_pattern_dagger/melee_1h_dagger/attack/fast_03/{e,w}/full_body
9 frames @ 13 fps, loop false, durations [1 x8, 1.5]
```

Database 582 -> 584 animations; only these two added.

## Final semantic mapping

```
Vigil
  fast_01/02 body   melee_1h/attack/fast_0N/{e,w}/full_body
  fast_03 body      weapon/vigil_pattern_dagger/melee_1h_dagger/attack/fast_03/{e,w}/full_body
  weapon            weapon/vigil_pattern_dagger/melee_1h_dagger/attack/fast_0N/{e,w}/weapon
  fx                melee_1h/attack/fast_0N/{e,w}/fx

Sword Cleaver
  body              melee_1h_heavy/attack/fast_0N/{e,w}/full_body
  weapon            weapon/sword_cleaver/melee_1h_heavy/attack/fast_0N/{e,w}/weapon
  fx                melee_1h_heavy/attack/fast_0N/{e,w}/fx
```

Identity is derived from data the weapon definition already carries —
`weapon_type` for the shared body/FX family, `get_animation_profile()` plus
`weapon_id` for the weapon layer, and the active
`MeleeAttackProfile.presentation_action` for the action. A weapon-owned body
override wins when published. Body, weapon and FX are selected and started
together, because the overlays are frame-synchronized to the body clock and a
half-canonical composition would sync a canonical body against a compatibility
overlay.

## The immutable spine

Deleted: `_install_weapon_body_frames()`,
`_install_melee_posture_weapon_frames()`, `_copy_runtime_animation()`,
`_apply_melee_weapon_animation_resources()` and the `_default_melee_*_frames`
caches that existed only to restore a swapped resource. `AnimatedSprite2D`,
`MeleeWeaponOverlaySprite` and `MeleeFxOverlaySprite` bind the canonical database
in the scene.

`operator_runtime_spine_immutable` snapshots the whole database — name set, frame
counts, fps, loop, every frame duration, and each frame's atlas source and region
— cycles Vigil / unarmed / Cleaver / Vigil, and asserts it is unchanged. It
carries its own negative control, because a fingerprint that cannot see a
mutation proves nothing by staying quiet.

**Verified by reintroducing the mutation:** 584 -> 591 -> 597 animations, caught
on every step.

## Behaviour that changed, and why

Both are restrictions removed, not features added. Frame counts and rates are
unchanged in both, so hit windows, commits and contacts are untouched.

1. **East Vigil walk now presents its weapon strip.** The authored
   `melee_1h_dagger/locomotion/walk_01/e/weapon` art was published all along, but
   the equip-time copy list named `walk_01` as `[s]` only, so east had nothing to
   play and fell back. The test that asserted that gap now asserts the art.
2. **The Sword Cleaver gets its own art.** Its body and FX resources pointed at
   the generic `melee_1h` fast_01 strip — all three links at the *same* one — so
   the chain played one borrowed swing three times. Canonical
   `melee_1h_heavy/attack/fast_01..03` is distinct per link at the same 10 frames
   and 18 fps.

## Retired

Zero consumers proven first, then deleted: the three `SpriteFrames` fields on
`OperatorWeaponDefinition`, their assignments and orphaned `ext_resource`
headers, and

```
vigil_pattern_dagger_{body,melee_overlay,fx}_frames.tres
sword_cleaver_{body,weapon_overlay,fx}_frames.tres
```

`frames_resource` stays — the held-weapon sprite is not part of the animation
spine. `fx_map` is gone from both armed definitions, verified by removing it and
re-running both weapon smokes rather than by reading the call graph.

`operator_melee_sheathe_smoke` inspected those deleted resources; its assertions
were really about the art the chain presents, so they read the canonical database
directly now. No test requires resurrecting a dead resource.

Two pre-existing `FAIL` lines in the authority smoke — "gameplay reads weapon
source art" for the dagger and cleaver overlay resources — are gone as a side
effect, since the resources that read source art no longer exist.

## Deferred to the C2b demolition pass

`animation_resolver` (18) and `directional_animation_fallback` (4). Armed melee
is no longer among the resolver's consumers, which was this packet's requirement;
the remainder is non-armed call-site debt and is now ordinary cleanup rather than
a live runtime dependency. `directional_animation_fallback` was explicitly out of
scope here, and the boundary-behaviour difference C2b measured between its
quantizer and the selector's still needs a deliberate decision.

## Phases not started

Phase 7 (deleting `operator_melee_overlay_frames.tres`,
`operator_weapon_frames.tres`, `operator_ranged_fx_frames.tres`,
`AnimationResolver`, `DirectionalAnimationFallback`) is untouched: each still has
live runtime or tooling consumers, and deleting them now would mean resurrecting
dead resources to keep tests running — exactly what the packet forbids.
`operator_animation_catalog_frames.tres` also stays; its runtime consumer is gone
but six validation and tooling scripts still read it.

`operator_timing_preservation` is therefore **not** retired and still passes.

## C2b.1 follow-up: the overlay-binding regression

Binding `MeleeWeaponOverlaySprite` and `MeleeFxOverlaySprite` to the canonical
database (above) took three non-armed presentation paths with it, each reaching
for a clip name that only ever lived in the deleted compatibility resource, so
the lookup became a permanent, silent miss:

```
unarmed heavy attack FX            fx_map "unarmed_attack_heavy_fx_right"
unarmed dodge-fast-attack FX        "unarmed_dodge_fast_attack_fx_<suffix>"
unarmed fast-attack recovery FX     AnimationResolver("unarmed_attack_fast_recovery_fx")
```

`operator_modular_defense_ranged` caught the first as a real regression, not a
stale assertion -- it asserted the FX overlay stays visible across a weapon
visual update, and the clip it named could never be found again.

Added `_resolve_melee_fx_identity()`: one canonical FX lookup (weapon type,
active `presentation_action`, sector) usable by both loadouts. Used at all
three regressed sites plus the general armed/unarmed `fx_map` overlay path
(`_play_melee_overlay_from_key`), which now tries the canonical identity before
falling back to `AnimationResolver` for any `fx_map` entry this slice did not
touch. Repointed the ranged smoke's two assertions at the canonical identity
(`unarmed/attack/heavy_01/e/fx`) rather than the retired clip name.

Two calls exposed as permanent no-ops by the same binding change are removed
rather than left dead: the heavy-attack windup's
`_play_named_melee_weapon_overlay(&"melee_2h_heavy_anticipation_weapon")`, and
`_play_block_weapon_overlay()`'s `<phase>_weapon` probe (Vigil's block weapon
art presents separately, through `_try_play_vigil_semantic_block()`, and hides
this overlay itself). `_play_named_melee_weapon_overlay()` itself is now
unused and deleted.

No dedicated smoke covers block-phase or heavy-attack-windup weapon-overlay
presentation; both removed calls were confirmed dead (the names they probed are
absent from the canonical database) rather than verified against a passing
test. Flagging this as a coverage gap rather than closing it silently.

`animation_resolver` fell 18 -> 16 (`operator.gd` 17 -> 15, per the audit's own
delta) as a side effect of consolidating FX resolution behind one helper, not
as a goal of this pass. Architecture debt baseline refreshed 98 -> 95.
`operator.gd` is 14,849 lines / 709 functions, against 14,841 / 709 at the
start of this blocker-removal slice -- a net +8 lines, entirely the new shared
helper, against a net -6 for the binding change alone.

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
operator_architecture_debt         PASS   95, baseline refreshed (98 after C2b.1's binding change, 95 after the overlay-regression follow-up)
operator_runtime_path_audit        PASS   ledger shrunk by the 8 removed PNG paths
operator_ranged_ready_input        PASS   (after repointing its dodge-FX assertions)
operator_dodge_fx_canonical        PASS   (new)
actor tier                         all operator tests pass; one pre-existing
                                          flaky non-operator test (see below)
changed set                        4/4
```

Actor tier: **57 selected** (56 before this slice added one), **all operator
tests passing**. Two runs, two different results, and both need reporting.

Run 1 was 55/56. `operator_ranged_ready_input` failed on two dodge-FX assertions
still written against the retired compatibility name
`operator_dodge_full_fx_south`. That was a real regression from this slice, not a
stale test: the assertions were correct about the behaviour and wrong about the
identity. Repointed at `shared/transition/dodge_01/s/fx` and given a frame-count
check.

Run 2 was 56/57, failing `lootable_corpse_beacon` -- which had passed in run 1,
with no change to anything it touches in between. It asserts
`toast_entries.size() == 2` after a **randomly rolled** corpse loot payload.
Re-run three times against identical code: FAIL, PASS, PASS. It is a pre-existing
nondeterministic test, not a regression from this work, and nothing in this slice
touches loot, toasts, `ResourceLedger` or `VaultManager`. Flagging it rather than
re-running until green and calling the tier clean -- it should get a seeded roll
or an assertion that tolerates the empty-type case.

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

**Overlay-regression follow-up, re-run focused:** `operator_vigil_dagger`,
`operator_sword_cleaver`, `operator_melee_posture`, `operator_attack_phase_cadence`,
`operator_body_pair_canonical`, `operator_animated_sprite_canonical`,
`operator_timing_preservation`, `operator_runtime_spine_immutable`,
`operator_dodge_flow`, `operator_dodge_fx_canonical`, `operator_unarmed_fast_chain`,
`operator_melee_sheathe` and `operator_modular_defense_ranged` (the one this
follow-up's diff touches directly) all **PASS**. `--changed` was attempted but
this worktree is shared with other concurrent sessions and carries unrelated
dirty state (procgen, vaultwing, road-semantics work); the unscoped sweep it
triggered was killed after 300s rather than left to churn through unrelated
tests, per the instruction not to run a giant sweep for an animation-file
touch. The full actor tier was not re-run for this follow-up specifically —
only the tests above, chosen to cover every path the diff changes.

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
