# Vigil-Pattern Dagger

- **Status:** implemented-v1
- **Owner:** gameplay/weapons
- **Runtime target:** Godot 4 (`custodian/`)

## Role

The Vigil-Pattern Dagger is the default starting melee weapon and reference
implementation for profile-owned attack drive. It is independent from the
Sword-Cleaver and Fallen Star Katana.

Its silhouette may read at short-sword proportions, but that does not alter its
canonical identity: `vigil_pattern_dagger`, displayed as **Vigil-Pattern Dagger**.

## Current Fast Chain

| Link | Presentation | Drive | Stamina |
|---|---|---:|---:|
| Fast 01 | Shared 10-frame Chain 01 + dagger overlay | 7 px | 5 |
| Fast 02 | Dedicated 8-frame Chain 02 connective body, dagger, and FX | 9 px | 6 |
| Fast 03 | Dedicated 9-frame Chain 03 two-contact finisher body, dagger, and FX | 11 px | 8 |

Soft targeting preserves those authored drives and adds only a pre-commit
assist: Fast 01 permits 12 degrees and up to 3 px, Fast 02 permits 13 degrees
and up to 4 px, and Fast 03 permits 14 degrees and up to 5 px. The escalating
assist is a subtle increase in commitment, not a larger hitbox or mid-swing
tracking. Each link freezes its corrected facing and resolved drive at commit.

All links have distinct semantic animation names and attack profiles. Body,
dagger, and FX use separate synchronized 156×96 `SpriteFrames` resources.
Runtime semantics follow the authored numbering: Chain 02 is Fast 02 and the
nine-frame Chain 03 strip is Fast 03. All play at 18 FPS. Fast 03 owns contacts
at zero-based runtime frames 4 and 8; its final frame has a `1.5x` duration
hold before animation completion.

Gameplay timing follows that contact grammar: `0.278 s` startup, `0.056 s`
active contact, and link-specific recovery (`0.222/0.111/0.420 s`). Movement,
turn lock, drive, cancellation, damage, and presentation therefore agree on
the same beat. Swing audio begins at visible acceleration rather than frame
zero, and hit-stop escalates across the three links.

The chain uses one-command rhythm windows. Queue-open frames are `3/2/6`,
queue-close frames are `8/7/8`, and commit frames are `6/6/8`. Input outside
the window is rejected; one accepted input is latched through commit. For Fast
03, frame 8 resolves the second hit but cannot transition the presentation.
The Fast 03 damaging contacts and final-frame hold complete before the action
returns to neutral. The chain does not loop: a queued fast is retained as a
fresh Fast 01 request and cannot take over until terminal recovery and ordinary
cooldown eligibility have completed.

Fast 03 owns two per-contact records. `cut_01` deals 36% of the profile damage
(about 5), 35% of its posture damage, and 12% knockback without cancelling a
committed grunt attack. `cut_02` deals the remaining 64% damage, 65% posture,
and owns the finisher interruption and displacement. Target deduplication is
keyed by target plus contact ID, so
overlap polling cannot repeat either cut while both cuts can hit one target.
Swing cues occur on runtime frames 3 and 7 rather than attack start.

Posture contribution is `14/16/30` for Fast 01/02/03. Baseline grunt posture is
`100`, recovers after `1.25 s` at `26/s`, and gates neutral light flinch for
`0.70 s`. Fast 01/02 resolve about `2.5/3 px` displacement; Fast 03's catch is
about `1.7 px` and its payoff about `14 px`, subject to collision.

The held weapon remains the native 24×24 dagger texture. Heavy remains disabled
through an empty `secondary_intent`: the repository has no semantically
appropriate authored Vigil heavy presentation, and unrelated two-hand/legacy
weapon art is not a valid substitute.

## Runtime Files

```text
custodian/game/actors/operator/
├── vigil_pattern_dagger_definition.tres
├── vigil_pattern_dagger_frames.tres
├── vigil_pattern_dagger_body_frames.tres
├── vigil_pattern_dagger_melee_overlay_frames.tres
├── vigil_pattern_dagger_fx_frames.tres
└── attacks/vigil_pattern_dagger_fast_{01,02,03}.tres
```

Pipeline outputs are under:

```text
content/sprites/operator/runtime/body/melee_1h/shared/
content/sprites/operator/runtime/fx/melee_1h/shared/
content/sprites/operator/runtime/weapon/melee_1h/vigil_pattern_dagger/
```

## Acceptance

- `operator.tscn` assigns the dagger to its melee slot.
- Three fast links select independent profiles.
- Body, weapon, and FX remain frame-synchronized.
- Drive respects collision and interruption without target tracking or
  snapback.
- Heavy input cannot invoke missing content.
- Cleaver and Katana definitions remain independently loadable.

## Enemy cadence integration

The shared `EnemyEngagementCoordinator` grants one nearby enemy committed
melee token within 260 px. Other enemies may approach and telegraph, but wait
at the active boundary until the token reaches recovery, expires, or is
released by interruption. Grunt quick strikes retain their 0.42 s tell, lock
tracking for the final 0.12 s, and reserve 0.40 s recovery permission. Falcon
Punch may telegraph concurrently but must claim permission before its leap.

Dagger Fast 01/02 deal damage and posture but do not interrupt a committed
ordinary grunt attack. Against a neutral eligible grunt the first light may
flinch; immediate follow-ups are feedback-only until the deterministic gate
expires. Fast 03's first cut creates slight space without cancelling; its
second cut strongly staggers grunts,
interrupts marines, and interrupts savages only outside their armored special
commitments.
