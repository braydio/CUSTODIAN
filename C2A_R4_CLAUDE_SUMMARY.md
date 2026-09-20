# C2a-R4 — `animated_sprite` cutover

Branch `c2a-r4-animated-sprite`. Latest: `05cb7532a`. Actor tier **50/50**.

This file is overwritten each time the slice advances; it is not a changelog.

## Status

**R4 is landed.** `animated_sprite` binds
`content/sprites/operator/runtime/operator_runtime_frames.tres`, the same
generated resource the other canonical renderers share. The compatibility
`ext_resource` is gone from `operator.tscn`.

```
live animated_sprite clips   135 -> 2
unreachable                   83 -> 133
open decisions 0   unresolved 0   cutover_ready true
```

`OperatorAnimationSelector` is now the live selection authority for R1
(`modular_sidearm_sprite`), R2 (`modular_upper_fx_sprite`), R3 (the modular body
pair) and R4 (`animated_sprite`). The melee and weapon overlays are the remaining
compatibility renderers.

## Commits in this slice

| Commit | What |
|---|---|
| `ecd05fb63` | Promote legacy ranged reload row 1 into `ranged_2h/cosmetic/reload_01`, byte-for-byte |
| `befd28a95` | Frozen compatibility timing outranks the catalog on refresh |
| `828369ff8` | Close the 13 remaining authoring decisions |
| `96e720cab` | Full-body projection policy; two live clips the evidence missed |
| `0178c89b1` | Validation resource cost made explicit for agents |
| `7117ad30e` | Retire the full-body ranged fallbacks; proof/disposition split |
| `05cb7532a` | The rebind itself |

## Decisions that shaped it

**Direction lives in the identity.** Canonical sector art is authored per
direction — `walk_01/e` and `walk_01/w` are different files, not one strip
mirrored at runtime — so canonical directional playback sets `flip_h = false`.
Keeping the compatibility `facing_left` mirroring would have pointed the Operator
east while playing the west strip, with every animation name still reading
correctly. `_is_facing_left` survives next to these paths for the renderers this
slice does not own, so the rule is commented where someone would otherwise
"simplify" it back into a bug. OMNI identities are the deliberate exception: one
strip serves every facing, so mirroring it is how west is expressed.

**Sparse full-body coverage is caller-owned policy.** `FULL_BODY_AUTHORED_SECTORS`
decides what a missing diagonal shows: authored sectors always present
themselves, missing diagonals project horizontally, `run_01` keeps the `se`/`sw`
it authors. `unarmed/attack/heavy_01` is also authored `e/n/s/w` only and takes
the same policy. The selector stays exact-only — no nearest-sector search, no
coverage-driven inference.

**The ranged full-body fallbacks were retired, not migrated.** Canonical ranged
presentation is the modular composition; `WEAPON_OWNED_ANIMATION_SYSTEM.md`
forbids substituting a compatibility full-body clip for a missing ranged layer.
`ranged_2h/cosmetic/fire_01/*/full_body` and
`ranged_2h/posture/stance_01/*/full_body` are deliberately not published. A
modular stack that cannot present reports the gap instead of falling back.

**Proof and disposition are orthogonal.** `ranged_2h_stance` provably drew
`unarmed/posture/stance_01/e/full_body` — the unarmed stance wearing a ranged
name. It keeps `historical_mapping_proven: true` while being recorded as a
resolved retirement. Retirements stay `AUTHORING_DECISION` rather than moving to
`RETIRED`, which is the mechanical finding "no live consumer reaches this clip".

## No mutation of the shared resource

`_ensure_runtime_body_animations()` forked the SpriteFrames with
`duplicate(true)` and injected legacy clips into the copy. Against a shared
resource that would rewrite the spine for every renderer at once, so it is now
`_ensure_compatibility_overlay_animations()`, which only initializes the melee
and dodge FX overlays. The name says what it does so nothing reintroduces body
mutation there.

Retired with it: `MELEE_FAST_CHAIN_BODY_SHEETS`,
`_register_melee_fast_chain_body_animations()`,
`_register_melee_stance_placeholder()`, and the dodge step/backstep injections
whose sheet constants were empty strings. Fast-chain capability now reads the
weapon's `animation_map` instead of asking whether the actor's own injection had
run — a presentation resource was deciding a combat capability.

## Recurring lesson: static name analysis undercounts consumers

Six consumer families across four slices were found only by breaking something.
R4's additions:

- **Interpolated names.** The roll-exit body (`unarmed_dodge_fast_attack_<suffix>`)
  and the dodge chain-link and charge-windup bases are built by string
  interpolation, so no literal ever appeared at an `animated_sprite` call site.
- **Weapon-mapped bases.** The melee attack path reaches `animated_sprite`
  through weapon `animation_map` values, hiding `unarmed_attack_heavy` and
  `unarmed_fast_strike`.
- **Hardcoded weapon-map defaults.** `_get_weapon_animation_name()` looks
  data-driven, but the carbine has no `animation_map` at all, so the literal
  default is what ships. The evidence generator now reads the weapon definitions
  and raises if such a name matches a compatibility clip with no recorded
  consumer.

A stale test expectation surfaced the same way: the fast-attack smoke asserted
compatibility suffix names in an `else` branch that never ran, because the
roll-exit body always won before the cutover.

## The two rows still counted live

`ranged_2h_fire` and `ranged_2h_stance` are a **name collision, not surviving
body clips**. The names persist as hardcoded weapon-map defaults whose remaining
consumers read `primary_weapon_sprite`, and `operator_weapon_frames.tres` has its
own clips of those names. The count is left conservative on purpose:
under-reporting is the failure mode that hid consumers four times. Explained in
the row rather than filtered away.

## Pipeline defect fixed at source

`update_operator_compatibility_resources.py` derived a clip's FPS/loop/durations
from the catalog entry for whatever texture the clip referenced. For the
historical cross-action clips that is wrong — the strip behind
`unarmed_walk_up_right` is authored as `unarmed/locomotion/idle_01/ne`, so the
refresh retimed a 10 FPS walk to the 8 FPS idle clock. It fired on four
consecutive ingests and was repaired by hand each time.

```
catalog                     -> texture path, frame count, frame geometry
frozen compatibility oracle -> historical FPS, loop, durations
```

The writer is also style-preserving now (float32 comparison), so an unchanged
value keeps its spelling and a refresh on a clean tree writes nothing. That
matters because the constant cosmetic churn is what let the real drift hide.

## Gates

`tools/validation/operator_animated_sprite_canonical_smoke.gd` (tier `actor`)
asserts: canonical binding; no per-instance fork; retired legacy names absent
from the spine; required identities published; the ranged full-body composition
deliberately absent; promotions pixel-identical with frame count, FPS, loop and
per-frame durations; the projection policy; and west playback using the west
texture with `flip_h` false.

Negative-controlled rather than assumed: discarding run's authored `se`,
projecting onto unpublished art, overriding an authored sector, repointing the
reload promotion at another identity, and disabling the weapon-default detector
each fail.

## Open items

- `custodian/docs/ai_context/task_packets/OPERATOR_RANGED_READY_INPUT.md` still
  says to fall back to ranged stance/fire body frames, which is exactly what R4
  removed. Needs a superseded banner pointing at the current ranged
  composition/socket authority, or archiving.
- `lootable_corpse_beacon` is nondeterministic independently of this work
  (sampled 1/3 in this worktree, 2/3 on an unmodified checkout at `aa025bf26`).
  Unrelated to Operator animation, and distinct from the controller-input flake.
- `idle_long_loop_threshold` and `_idle_loop_counter` are retained with no
  current reader, as the seam a future authored long-idle action would use.
  `idle_long` playback itself is retired.

## Next, in order

1. Wire the parked unarmed relaxed/ready posture flow (art already published,
   classified DORMANT).
2. Wire the new ranged equip/relaxed/reload semantics using the temporary
   full-body assets.
3. C2b compatibility-store demolition.
