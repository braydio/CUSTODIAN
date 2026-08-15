# Operator Melee Contact Timing And Cadence

Status: approved design, implementation pending
Owner: gameplay/combat
Runtime target: Godot 4 (`custodian/`)
Last updated: 2026-08-15

## Purpose

Define one durable contract for how CUSTODIAN melee attacks become readable physical actions rather than short visual twitches. This document covers authored animation phases, exact contact-frame ownership, deterministic phase timing, unarmed cadence, attack drive/assist, and validation. It applies to Fists first and serves as the shared rule for armed melee where a weapon does not already have a stronger authored contract.

This document refines `COMBAT_FEEL_SYSTEM.md`; it does not replace the weapon-specific Vigil-Pattern Dagger or Fallen Star Katana contracts.

## Design Summary

The combat-feel split is:

- **Fists / unarmed:** pressure, mobility, interruption, staying on the target.
- **Fast armed melee:** rhythm, reach, authored commitment, choosing whether to continue the next beat.
- **Heavy attacks:** commitment and consequence; they may be slower, but should still complete a readable motion rather than freeze the Operator after contact.

The universal melee presentation rule is:

> One deterministic attack timeline owns the action. Visible animation is synchronized to that timeline. Exact authored contact frames own damage and impact events.

Consequences:

1. A hidden or fallback animation must never be the timing authority that advances a different visible modular animation.
2. Windup, strike, and recovery clips must not be replaced before their intended authored poses have been presented.
3. Damage contact is not inferred from a generic active-time window or from whichever pose happens to be visible. Contact is explicit attack metadata tied to an authored frame/contact ID.
4. Swing/acceleration cues may occur before contact and are separately authored from contact.
5. Multi-contact attacks own separate contact IDs, damage shares, reactions, and deduplication.
6. Presentation may follow deterministic simulation timing, but rendering state must not become an independent simulation authority.

## Existing Runtime And Art

### Fists fast attack

Current runtime source already contains three distinct modular phases for all eight directions:

```text
custodian/content/sprites/operator/runtime/modules/new_operator/
├── lower_body/actions/unarmed/fast_attack/
│   ├── fast_windup_01/
│   ├── fast_strike_01/
│   └── fast_recovery_01/
└── upper_body/actions/unarmed/fast_attack/
    ├── fast_windup_01/
    ├── fast_strike_01/
    └── fast_recovery_01/
```

Current phase art is three frames per phase using 96x96 frame cells. The current registered playback is approximately:

- windup: 3 frames at 12 FPS, about 0.250 s at `speed_scale = 1.0`
- strike: 3 frames at 12 FPS, about 0.250 s at `speed_scale = 1.0`
- recovery: 3 frames at 15 FPS, about 0.200 s at `speed_scale = 1.0`

`operator_modular_fast_attack_smoke.gd` already proves the windup, strike, and recovery modular animations are registered and individually selectable. Therefore the first correction is **not new art**.

### Current Fists profile

`custodian/game/actors/operator/attacks/unarmed_fast_attack.tres` currently owns:

```text
windup_sec      0.06
active_sec      0.10
recovery_sec    0.10
cooldown_sec    0.46
cancel_start    0.22
hit frame       2
```

`custodian/game/actors/operator/unarmed_definition.tres` maps Fists fast aliases to `unarmed_fast_strike` and assigns one fast contact frame. Fists remains a weapon/profile choice and must continue using the shared `attack_fast` / `attack_heavy` state family rather than creating separate unarmed combat states.

## Current Timing Defect To Remove

The live Fists fast path currently mixes several timing authorities:

1. `_try_start_fast_attack_windup()` starts a legacy/fallback `AnimatedSprite2D` windup and the visible modular windup together.
2. The legacy body can be hidden while modular lower/upper layers are visible.
3. The hidden legacy animation uses the melee animation speed scale, while the modular fast phase currently plays at `speed_scale = 1.0`.
4. `_on_animation_finished()` uses completion of `unarmed_attack_fast_windup*` to call `_begin_fast_attack_strike_phase()`.
5. `_begin_fast_attack_strike_phase()` currently assigns `_melee_duration = attack_profile.recovery_sec`, even though it is entering the strike phase.
6. The external fast recovery path uses `melee_fast_recovery_duration`, currently 0.10 s, while the visible three-frame modular recovery needs about 0.20 s at its registered 15 FPS.

This means the assets can be fully loaded and technically playable while still being visually truncated. The visible result can read as a twitch because the phase changes before the authored pose sequence has completed.

The implementation must remove this split-brain timing behavior.

## Authoritative Phase Contract

### Required action grammar

A normal Fists fast attack is:

```text
INPUT
  -> WINDUP
  -> STRIKE / CONTACT
  -> FOLLOW-THROUGH
  -> RECOVERY / RETRACT
  -> NEUTRAL
```

The existing three modular clips remain the presentation sources:

```text
windup clip   -> anticipation/compression
strike clip   -> acceleration/contact/follow-through
recovery clip -> retract/settle
```

### Deterministic timing authority

The attack profile/timeline is simulation authority. Presentation must be synchronized to it.

For each visible phase:

1. determine the actual authored animation duration from its SpriteFrames frame count, animation FPS, and per-frame duration multipliers;
2. determine the deterministic target phase duration;
3. compute presentation `speed_scale = authored_duration / target_phase_duration`;
4. begin the visible modular phase and the deterministic phase together;
5. advance to the next phase from the deterministic timeline, with validation proving the final intended pose was reached rather than relying on a hidden fallback animation to finish first.

The implementation may use an equivalent helper/structure if it preserves this ownership. Do not introduce render-frame-dependent damage authority.

### Initial Fists fast timing target

Use the following as the first production A/B target:

```text
windup target:   0.15 s
strike target:   0.15 s
recovery target: 0.16 s
visual total:    0.46 s
```

With the current 3/3/3 source clips this yields approximately:

```text
windup modular speed scale:   0.250 / 0.150 = 1.667x
strike modular speed scale:   0.250 / 0.150 = 1.667x
recovery modular speed scale: 0.200 / 0.160 = 1.250x
```

These values are not permission to hard-code direction-specific animation rates. Compute the ratio from the registered SpriteFrames so future frame-count or duration changes remain coherent.

The contact should be readable roughly 0.17-0.22 s after accepted input. With the current three-frame strike, the intended contact pose should be the second strike pose unless visual review proves the source art places contact elsewhere.

If the source art's actual contact pose differs, preserve the art and author the metadata to the correct visible pose rather than redrawing solely to satisfy this provisional frame number.

## Contact-Frame Contract

### General rule

Every melee attack owns one or more explicit contact records.

A contact record may define:

- stable contact ID
- authored frame(s)
- damage multiplier/share
- stagger multiplier
- knockback multiplier
- hit-stop override
- camera-impact class
- optional material/VFX/SFX semantic

Hit deduplication is target + contact ID. Repeated overlap polling must not multiply one contact, while a legitimate later contact from the same attack may hit the same target once.

### Single-contact attacks

Fists fast should have one explicit contact event. Fists heavy should normally have one explicit heavy contact event unless later art is intentionally authored as a multi-hit action.

A generic multi-frame damage window such as `[4, 5]` may remain only when both frames intentionally represent the same contact tolerance. It must not accidentally deal the same intended blow twice.

### Existing Vigil dagger reference

The Vigil-Pattern Dagger demonstrates the desired grammar:

- Fast 01: one contact
- Fast 02: one contact
- Fast 03: two distinct contacts

Fast 03 currently resolves:

```text
runtime frame 3 -> swing / visible acceleration cue
runtime frame 4 -> cut_01 contact
runtime frame 7 -> second swing / acceleration cue
runtime frame 8 -> cut_02 contact
```

`cut_01` owns 36% of profile damage with reduced stagger/knockback; `cut_02` owns the remaining 64% with full finisher stagger/knockback. This is deliberate contact grammar, not an active window spanning frames 4-8.

Existing hit-window data has a legacy indexing convention where stored authored frame values can map to zero-based runtime frame indices through helper code. Do not silently renumber all existing weapon data in this slice. Instead:

- document the conversion at the helper boundary;
- add regression coverage around it;
- use one explicit internal zero-based runtime-frame contract after conversion;
- if a later migration normalizes stored data, make that a separate repository-wide migration.

### Swing cue versus contact

A swing/acceleration cue is not contact. It should normally precede contact.

For a punch this can be:

```text
windup -> acceleration cue -> CONTACT -> extension/follow-through -> retract
```

Contact owns damage, hit-stop, impact VFX/SFX, and enemy reaction. Acceleration owns only pre-contact movement/audio/visual anticipation.

## Fists Contact And Cadence Pass

After the timing-authority repair is proven independently, apply the Fists feel tuning through the existing `MeleeAttackProfile` machinery.

### Fast attack initial tuning

Use this initial target unless runtime tracing proves a field is double-scaled or measured from a different origin:

```text
windup_sec                  0.15
active_sec                  0.15
recovery_sec                0.16
cooldown_sec                derive/retune so repeat cadence has no invisible dead-air
cancel_start_sec            retune against the new timeline; do not preserve 0.22 blindly

drive_distance_px           6.0
drive_delay_sec              0.025
drive_duration_sec           0.11
drive_input_influence        0.25

target_assist_enabled        true
target_acquire_extra_px      10.0
target_assist_cone_degrees   28.0
target_aim_correction_degrees 8.0
target_drive_bonus_max_px    2.0

hit_stop_duration            0.032
camera_shake_power           1.5
```

Do not change fast damage, range, arc, knockback, or the Fists weapon-level damage/range/stagger multipliers in this pass until their exact effective-runtime consumption has been traced and reported.

The fast attack should physically close a small amount of distance instead of faking reach with a very large hitbox. Assist is a bounded pre-commit correction, not tracking through the punch.

### Heavy attack initial tuning

The heavy action should remain a committed blow but recover without a long frozen tail. After verifying the heavy animation/contact alignment, use this first A/B target:

```text
windup_sec                  0.17
active_sec                  0.14
recovery_sec                0.54
cooldown_sec                0.76
cancel_start_sec            0.47

drive_distance_px           10.0
drive_delay_sec              0.10
drive_duration_sec           0.15
drive_input_influence        0.10

target_assist_enabled        true
target_acquire_extra_px      8.0
target_assist_cone_degrees   24.0
target_aim_correction_degrees 6.0
target_drive_bonus_max_px    2.0

hit_stop_duration            0.058
camera_shake_power           4.5
```

Do not change heavy damage/range/stagger values in this pass. Preserve a single authored heavy contact unless the source animation clearly contains two separate physical impacts.

### Enemy reaction priority

Sell punches primarily through body displacement and enemy reaction, not by escalating camera shake globally. Camera movement is seasoning; contact readability comes from:

1. correct authored contact pose;
2. target reaction beginning on that contact;
3. brief hit-stop;
4. bounded knockback/stagger;
5. impact VFX/SFX at the resolved contact point;
6. attacker follow-through and recovery.

## Asset Policy

Do **not** commission or generate replacement Fists fast art before this timing repair is captured and reviewed.

Current source already provides 9 authored phase frames per direction across windup/strike/recovery. The runtime must first prove it can present those poses coherently.

Only if full-timeline playback still looks under-authored should the strike phase be expanded.

Potential follow-up asset contract, not required by this implementation:

```text
custodian/content/sprites/operator/new_operator/modular/fast_attack/
operator__modular_{lower_body,upper_body}__unarmed__fast_strike_02__{dir}__4f__96.png
operator__modular_{lower_body,upper_body}__unarmed__fast_strike_03__{dir}__5f__96.png
```

If commissioned later:

- 96x96 frame cells
- transparent alpha
- eight directions: n, ne, e, se, s, sw, w, nw
- 4-5 strike frames per directional strip
- lower/upper modular layers stay synchronized
- add frames around acceleration/contact/follow-through, not filler in neutral poses
- authored contact frame must be declared alongside ingestion

The goal is smoother motion at comparable total duration, not simply raising FPS and shortening the action.

## Armed Melee Relationship

Do not flatten all melee into the Fists timing.

### Vigil-Pattern Dagger

Preserve its existing three-beat identity:

- independent Fast 01/02/03 profiles
- 7/9/11 px authored drive
- bounded commit-time assist
- Fast 03 two-contact finisher
- escalating hit-stop
- animation-finished continuation behavior for its finisher

Do not globally increase melee hit-stop/shake while fixing Fists.

### Other weapons

Use the same contact-frame/timeline contract, but preserve weapon identity:

- Fists: fast pressure + brutal heavy
- Dagger: rapid three-beat chain, mobility, precision
- Sword/Cleaver: deliberate links and a proper committed heavy when authored
- Katana: its own authored rhythm/commit contract

## Melee Posture Relationship

Non-attack melee posture remains governed by:

`design/02_features/combat_feel/OPERATOR_MELEE_PRESENTATION_POSTURE.md`

That design defines sheathed/drawing/ready/relaxed/sheathing presentation, with READY/RELAXED driven by the existing engagement tracker and no new gameplay state explosion. Attack input from RELAXED must still begin the attack immediately; ready-up is presentation-only.

This contact/cadence implementation must not create a second posture system. It may touch posture only where necessary to ensure attack entry/exit returns to the existing intended melee neutral.

## Runtime Implementation Requirements

Primary files to inspect/change:

```text
custodian/game/actors/operator/operator.gd
custodian/game/systems/combat/melee_attack_profile.gd
custodian/game/actors/operator/operator_weapon_definition.gd
custodian/game/actors/operator/unarmed_definition.tres
custodian/game/actors/operator/attacks/unarmed_fast_attack.tres
custodian/game/actors/operator/attacks/unarmed_heavy_attack.tres
custodian/game/actors/operator/operator_modular_lower_body_frames.tres
custodian/game/actors/operator/operator_modular_upper_body_frames.tres
custodian/tools/validation/operator_modular_fast_attack_smoke.gd
custodian/tools/validation/operator_vigil_dagger_smoke.gd
```

Related authorities/read-only references:

```text
design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md
design/02_features/combat_feel/OPERATOR_MELEE_FAST_CHAIN.md
design/02_features/combat_feel/OPERATOR_MELEE_PRESENTATION_POSTURE.md
design/02_features/weapons/VIGIL_PATTERN_DAGGER.md
custodian/docs/ai_context/CURRENT_STATE.md
custodian/docs/ai_context/FILE_INDEX.md
custodian/docs/ai_context/VALIDATION_RECIPES.md
custodian/docs/ai_context/prompts/tune_combat_feel.md
```

Implementation constraints:

1. Preserve deterministic fixed-step gameplay authority.
2. Do not add separate Fists combat states.
3. Reuse `MeleeAttackProfile` drive/assist fields and existing target resolver rather than creating a Fists-only targeting system.
4. Remove or bypass hidden legacy-animation timing authority for modular Fists fast phase transitions.
5. Do not allow `recovery_sec` to stand in for strike duration.
6. Do not let the fixed global `melee_fast_recovery_duration` truncate a profile-owned modular recovery.
7. Synchronize modular lower body, upper body, optional FX, and fallback presentation to one phase timeline.
8. Preserve dodge-fast-attack special presentation and charged-dodge commitment rules.
9. Preserve parry, critical, ranged, dagger, cleaver, and Katana behavior unless an existing bug is directly exposed by the shared helper change.
10. Do not change damage/range/stagger balance in this slice.

## Validation Contract

### Focused automated coverage

Extend `operator_modular_fast_attack_smoke.gd` so it proves more than animation-name selection.

It must verify:

- windup -> strike -> recovery ordering;
- the visible modular phase cannot be replaced before the intended final phase pose is reachable;
- phase speed scale is derived from authored duration and target phase duration;
- the hidden legacy sprite does not control visible modular phase completion;
- the Fists fast contact occurs exactly once on the intended strike contact frame;
- recovery completes before neutral presentation takes ownership;
- all eight directions preserve the contract;
- dodge-exit fast attack still follows its explicit exception path;
- no duplicate contact is produced by adjacent polling frames.

Add/extend a focused profile test if necessary to prove drive and target-assist values are resolved from `MeleeAttackProfile` rather than Fists-only constants.

Keep `operator_vigil_dagger_smoke.gd` green and retain explicit validation for Fast 03 runtime contacts at frames 4 and 8 with frame 7 inactive.

### Repository validation

Run from repository root:

```bash
python3 custodian/tools/validation/run_validation.py --changed --json
```

### Moment Forge

Because acceptance depends on timing, displacement, animation, VFX/SFX, and impact feel:

```bash
python3 custodian/tools/iteration/run_moment.py --changed
```

Review the suggestions, then explicitly run the smallest relevant combat scenario using:

```text
--capture-mode full
```

Do not use `--execute-suggested` blindly and do not auto-approve/replace any baseline.

Capture at minimum:

1. Fists fast whiff in open space.
2. Fists fast confirmed hit on an ordinary grunt.
3. Repeated distinct fast inputs to judge cadence/dead-air.
4. Fists heavy confirmed hit and recovery.
5. Dagger three-link chain regression, including Fast 03 two contacts.

### Visual acceptance

Fists fast passes when:

- input reads immediately but not as a one-frame twitch;
- anticipation is visible without feeling sluggish;
- the fist visibly arrives on the same beat as damage, hit-stop, sound, VFX, and enemy reaction;
- follow-through is visible after contact;
- the hand/body retracts rather than snapping directly to idle;
- repeated attacks have pressure cadence without an unexplained dead interval;
- whiffs still look like complete physical punches;
- small drive closes distance without magnetizing the Operator through targets or walls;
- no new art is required to understand the motion.

If it still reads incomplete after all current frames are demonstrably visible, then and only then authorize the 4-5-frame strike-art follow-up.

## Documentation Drift Review

Known drift/risks to clean while implementing:

1. Older generic combat-feel notes describing broad frame windows or generic attack timing may no longer reflect profile-owned weapon timing. Treat `design/02_features/combat_feel/notes.md` as stale unless reconciled.
2. The current Fists modular smoke proves phase selection, not full phase-duration coherence; its acceptance contract is insufficient for the observed twitch defect.
3. Legacy hit-window frame numbering versus zero-based runtime frame numbering is easy to misread. Document conversion in code/tests rather than silently changing existing weapon data.
4. If implementation changes runtime timing/ownership, update `custodian/docs/ai_context/CURRENT_STATE.md`.
5. Add this document to `custodian/docs/ai_context/FILE_INDEX.md` as the focused authority for melee contact timing and Fists cadence.
6. Update `COMBAT_FEEL_SYSTEM.md` with a short pointer to this document if the implementation changes its generic timing description.

## Next Agent Slice

### Goal

Implement the complete Fists contact/timing/cadence repair while preserving existing armed-melee contracts.

### Required order

1. Read repository/local authority and this document.
2. Trace current effective multiplier/timing/cooldown consumption before edits.
3. Capture the current Fists fast behavior if a repeatable moment exists.
4. Repair phase/timeline ownership first, without feel-value tuning.
5. Validate and capture the timing-only repair.
6. Apply the Fists drive/assist/hit-stop/cadence values in this document.
7. Validate and capture again.
8. Audit Fists heavy against the same contact contract and apply its approved A/B values if the authored contact remains aligned.
9. Keep dagger/Katana regressions green.
10. Update current-state/index/design docs for any behavior or ownership changes.

### Completion report must include

- changed files;
- before/after timing ownership;
- actual effective Fists attack timing after any weapon/profile multipliers;
- actual cooldown/repeat-gate semantics;
- exact Fists contact runtime frame and indexing conversion;
- drive/assist effective values;
- focused smoke results;
- changed-file validation result;
- Moment Forge scenario IDs, capture mode, report paths, and observed before/after feel;
- documentation drift found and remediated;
- whether new strike art is still needed after complete current-frame playback.
