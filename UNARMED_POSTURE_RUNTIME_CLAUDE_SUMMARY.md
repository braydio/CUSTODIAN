# Unarmed Posture Runtime

Branch `unarmed-posture-runtime`, worktree `/home/braydenchaffee/Projects/CUSTODIAN-posture`,
merge base `1febeae0a` on `main` (rebased as main advances).

This file is overwritten each time the slice advances; it is not a changelog.

## Status

**Part A complete and committed. Part B designed, not yet implemented.**

```
A. harden the R4.1 acceptance proof + fix summary drift   DONE
B. implement Unarmed Posture Runtime                      NEXT
```

## Part A — R4.1 proof hardening (done)

The R4.1 runtime fixes were correct. The test meant to prove them was not, and
would have passed with or without them.

`_equip_armed_melee()` set `using_unarmed = false` and
`combat_loadout_mode = "melee"` by hand, which is not a loadout.
`_rebuild_armed_weapon_list()` appends the primary ranged weapon before the melee
one, so `armed_weapon_index` stayed on the carbine and the current profile was
ranged. The guard passed only because the profile was not *unarmed*.

Selection now goes through the actor's own path — search `armed_weapons` for
`weapon_kind == "melee"`, then `_apply_armed_selection(index)` — and asserts
`using_unarmed` false, `_is_melee_loadout_active()` true, and a genuinely melee
profile. The index is searched, never hardcoded.

Assertions moved from resolver return values to the lifecycle. Heavy anticipation
drives `_start_heavy_attack()` per cardinal, asserts anticipating with
`_melee_active` still false, checks the clock plays a heavy-windup identity, then
drives the real completion signal with that clock and asserts the active phase
begins. Recovery drives `_play_fast_attack_recovery()` and asserts a canonical
unmirrored body plus surviving weapon/FX overlays.

**Outcome: the strengthened test passes.** The R4.1 projections and semantic
completion predicates hold under a real armed melee loadout. Negative-controlled:
removing the heavy windup projection fails it.

R4 summary drift corrected: R4 integrated at `96e225bec`, R4.1 at `0edcfe827`,
main since advanced, and the R4 branch is a historical marker not tracking main.

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

## Key finding: the machinery already exists

`custodian/game/actors/operator/presentation/melee_posture_state.gd` is already
almost exactly the state machine this slice needs, and it is already driven by
engagement rather than by proximity scanning:

```gdscript
enum Posture { SHEATHED, READY, RELAXED }

func resolve(delta, melee_equipped, engagement_active, presentation_locked) -> Posture
func get_animation_action() -> StringName   # idle_ready_01 / idle_relaxed_01
func attack_action_bypasses_ready_up() -> bool
```

Three things make it a good seam rather than a coincidence:

- `get_animation_action()` returns bare action names, with no profile in them.
  The profile is the caller's business, so unarmed needs no new vocabulary.
- `resolve()` already takes `engagement_active`, wired in `operator.gd` from
  `_engagement_tracker.engagement_started` / `engagement_ended`. No new
  gameplay state, no proximity scan.
- `attack_action_bypasses_ready_up()` already exists as the hook for "attacks
  must not wait for the ready-up animation".

The only reason unarmed is excluded today is the caller's gate:

```gdscript
_melee_posture_state.resolve(
    delta, _is_melee_loadout_active() and not using_unarmed, engagement_active, presentation_locked
)
```

So this is a generalization, not a new system. Plan is to widen that predicate
and let the caller supply the profile, rather than to build a parallel unarmed
posture path.

## Canonical art (published, currently DORMANT)

```
unarmed/posture/idle_relaxed_01/{e,w}/{lower_body,upper_body}        5f @8 loop
unarmed/posture/idle_ready_01/{e,w}/{lower_body,upper_body}          5f @8 loop
unarmed/transition/relaxed_to_ready_01/{e,w}/{lower_body,upper_body} 1f @8
unarmed/transition/ready_to_relaxed_01/{e,w}/{lower_body,upper_body} 1f @8
```

The 1-frame transitions are deliberate placeholders. Wire the semantic
transition now so multi-frame replacement art drops in with no runtime change.

## Runtime policy

```
neutral + unarmed + no engagement -> RELAXED
neutral + unarmed + engagement    -> READY

RELAXED -> READY    play relaxed_to_ready_01, then idle_ready_01
READY -> RELAXED    play ready_to_relaxed_01, then idle_relaxed_01
```

Constraints:

- Posture idles own the body only while stationary and neutral. Ordinary unarmed
  walk/run keeps using canonical locomotion; movement is movement-owned.
- Attacks from RELAXED begin gameplay immediately. Ready-up is presentation-only
  and is preempted by attack, dodge, hit reaction, death, interaction, or any
  higher-priority body owner.
- Direction is E/W authored: `x < 0 -> w`, otherwise `e`, played with
  `flip_h = false`. West is never mirrored east — the R4 lesson.
- Selection goes through `OperatorAnimationSelector` and the canonical body pair.
  No compatibility names constructed, nothing added to SpriteFrames at runtime.

## Open question to resolve during implementation

`_start_vigil_posture_bridge()` is the existing transition player and is
vigil-specific. Either generalize it to take a profile, or give the unarmed path
a sibling that shares its ownership discipline. Generalizing is preferred, but
only if it can be done without a broad rename that makes ownership less
truthful — the surrounding names need to keep saying what they actually own.

## Acceptance smoke (to be written)

```
quiet unarmed neutral            -> idle_relaxed_01
engagement                       -> relaxed_to_ready_01 -> idle_ready_01
quiet after engagement           -> ready_to_relaxed_01 -> idle_relaxed_01
E/W select distinct canonical identities
west never uses flip_h
movement preempts posture with normal locomotion
attack from relaxed is not gameplay-delayed
dodge / hit / death preempt a posture transition cleanly
body ownership never exposes two competing body presentations
selector remains exact-only
```

Reachability for the four actions moves DORMANT -> LIVE only once the consumer
exists.

## Out of scope

- The temporary `operator_ranged_body_core_v1` full-body family. Untouched here.
- Older reachability prose around `ranged_2h/cosmetic/aim_01` and `fire_01` that
  still describes compatibility-era consumers. Its validation is not wrong, and
  C2b is the better broom.

## Validation order

Focused posture smoke, then changed-set, single-test repeats for any suspected
flake, and one actor-tier sweep at the end. Check `free -h` before a broad sweep
and run one at a time.
