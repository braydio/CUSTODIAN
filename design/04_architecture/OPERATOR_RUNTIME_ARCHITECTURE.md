# Operator Runtime Architecture

**Status:** active migration contract
**Audit gate:** `custodian/tools/validation/operator_architecture_debt_audit.py`
**Task packet:** `custodian/docs/ai_context/task_packets/OPERATOR_RUNTIME_DECOMPOSITION.md`

## The diagnosis

`operator.gd` is not merely large. It holds **too many overlapping authorities**.
Splitting it into ten arbitrary files would make the repository prettier while
preserving the confusion. The goal is a machine where you can point at any
gameplay fact and say exactly one thing owns it — the rule
`design/04_architecture/INTEGRATION_CONTRACT_GLUE_LAYER.md` already sets for
the project as a whole.

Measured at the start of this migration (`--emit-baseline`, 2026-09-10):

| Overlapping authority | Violations | Should be owned by |
|---|---:|---|
| direct `Input.*` sampling | 65 | `OperatorInputRouter` |
| `AnimatedSprite2D.play()` outside presentation | 94 | `OperatorAnimationPlayer` |
| retired `AnimationResolver` | 45 | `OperatorAnimationSelector` |
| absolute `/root/...` scene lookups | 38 | injected dependencies |
| `AnimationState` → actor `has_method()`/`call()` glue | 34 | `OperatorActionController` |
| body-layer visibility writes outside presentation | ~~25~~ **0** | `OperatorBodyPresenter` (Slice B) |
| attack `fallback_animation` indirection | 16 | selector exact-identity contract |
| simulation advanced from the render tick | 12 | the fixed physics tick |
| retired `DirectionalAnimationFallback` | 6 | `OperatorAnimationSelector` |
| actor-local `SpriteFrames` construction | 5 | one generated `operator_runtime_frames.tres` |
| retired `OperatorAnimationCatalog` | 4 | `OperatorAnimationSelector` |
| mutable state in `OperatorWeaponDefinition` | 3 | `OperatorWeaponRuntimeState` |
| **total** | **347** → **322** | |

`operator.gd` is 540,567 bytes / 13,745 lines and acts simultaneously as input
handler, locomotion controller, aim resolver, combat coordinator, animation
selector, renderer, ranged and melee controller, dodge controller,
reload/ammo/heat controller, interaction system, build/repair interface,
field-patch system, target selector, debug harness, presentation coordinator
and compatibility layer.

Line count is not the acceptance test. The acceptance test is that an agent
fixing melee does not need to understand ranged ammo, building, field patches,
procgen unstuck recovery and UI focus handling.

## Core locks

1. Exactly one authoritative owner for every gameplay fact.
2. Gameplay simulation advances on the **fixed physics tick**.
3. `_process()` is presentation-only.
4. `operator.gd` stays the `CharacterBody2D` facade and the sole
   `move_and_slide()` owner.
5. Input is sampled once per tick into an immutable `OperatorInputFrame`.
6. The active input device owns aim. A neutral controller stick never falls
   through to stale mouse aim.
7. Action, locomotion, loadout, posture, aim and presentation are **orthogonal
   axes**, not one combinatorial state machine.
8. `OperatorActionController` replaces `AnimationStateMachine` as the
   behavioural authority.
9. Presentation never authors simulation timing.
10. Exactly one **body** presentation owner may be visible at a time.
11. Only `operator/presentation/` code may mutate body-layer visibility.
12. Full-body animation stays fully supported through a canonical
    `FullBodySprite`. **Full-body is not a synonym for legacy.**
13. All Operator animation lookup goes through `OperatorAnimationSelector` and
    the one generated `operator_runtime_frames.tres`.
14. No gameplay raw PNG loading, private `SpriteFrames` DB,
    `AnimationResolver`, `DirectionalAnimationFallback`,
    `OperatorAnimationCatalog` or `fallback_animation` in the final state.
15. `OperatorWeaponDefinition` is immutable definition data; magazine, heat,
    reload and cooldown live in `OperatorWeaponRuntimeState`.
16. The public Operator API and signals stay intact behind delegating facade
    methods for the whole migration.
17. Deterministic combat and contact behaviour is preserved.

## Orthogonal axes

```text
ACTION       free | attack_fast | attack_heavy | guard | dodge | hit | equip | sheathe | field_patch | dead
LOCOMOTION   idle | walk | run | sprint | sneak
LOADOUT      unarmed | melee | ranged | sidearm
POSTURE      sheathed | relaxed | ready
AIM          direction + active input device
PRESENTATION full_body | modular
```

`READY` is not a gameplay state, and neither is `melee_ready_walk` or
`ranged_walk_east`. They are compositions of independent facts.

## The fixed-step spine

```gdscript
func _physics_process(delta: float) -> void:
	var input := input_router.sample()
	aim_controller.advance(input)
	action_controller.accept_input(input)
	loadout_controller.advance_fixed(delta)
	melee_controller.advance_fixed(delta)
	ranged_controller.advance_fixed(delta)
	guard_controller.advance_fixed(delta)
	dodge_controller.advance_fixed(delta)
	velocity = locomotion_controller.compose_velocity(input, action_controller.snapshot())
	move_and_slide()
	action_controller.accept_motion_result(_build_motion_result())
	_runtime_snapshot = _build_runtime_snapshot()


func _process(delta: float) -> void:
	presentation_controller.present(_runtime_snapshot, delta)
```

**The physics tick decides what is true. The render tick decides what truth
looks like.** Deterministic simulation controllers are `RefCounted` and are
ticked explicitly from the root in this order — they must not own their own
`_physics_process()`, which would make update order implicit again.
Presentation objects that own scene nodes may be Nodes.

This is the same doctrine
`design/02_features/combat_feel/OPERATOR_MELEE_CONTACT_TIMING_AND_CADENCE.md`
already states: one deterministic attack timeline owns the action, visible
animation follows it, and a hidden or fallback animation never becomes timing
authority for a different visible animation.

## The presentation firewall

```text
ONLY operator_body_presenter.gd MAY CHANGE BODY-LAYER VISIBILITY.
```

**Live as of Slice B-final.** `custodian/game/actors/operator/presentation/operator_body_presenter.gd`
is a `RefCounted` that owns the `Owner` enum, the per-owner registry of
body-capable renderers, per-owner overlay registration and retirement,
exclusive-owner classification, body visibility mutation and visible-owner
observability. The Operator creates its renderers and registers them — the
presenter performs no scene-tree discovery and never calls back into the actor.
`operator.gd` keeps thin delegating wrappers (`_set_body_presentation_owner`,
`_claim_modular_body_owner`, `_release_modular_body_layers`, `_show_body_layer`,
`_hide_body_layer`, `_show_presentation_layer`, `_hide_presentation_layer`,
`get_body_presentation_owner`, `get_visible_body_owners`,
`get_visible_body_overlays`) that contain no visibility policy of their own.

Overlays are owner-scoped, not a single global pool. Retiring one owner never
blanks another owner's cosmetics, and preempting an owner takes down both its
body and its overlays — a global pool produced two opposite bugs at once: an
unrelated modular release hid the active rig's sword, while modular preemption
retired a rig's body and left its weapon floating.

An overlay may be worn by more than one owner. The cape rides both the legacy
strips and the modular rig, so `release_modular()` deliberately leaves it for
whoever takes the body next instead of blinking it between presentations.

`OperatorAnimationPlayer` (Slice C1) owns HOW an already-resolved clip plays:
start, restart, stop, speed, frame and progress. It is mechanical and holds no
semantic vocabulary — no attack kind, no weapon identity, no direction policy,
and no action-specific methods. `operator.gd` and the compatibility
`AnimationStateMachine` both drive playback through it rather than touching
`AnimatedSprite2D` directly.

### The active presentation chassis

Modularity is not the goal; the minimum number of independently animated layers
that supports real gameplay variation is. The active Operator chassis is:

```text
lower-body cadence
+ upper action layer where genuinely needed
+ weapon
+ FX
```

with authored full-body actions available where appropriate — not a stack of
every layer that could technically be separated.

**Retired from active composition (C2a authoring decision, 2026-09-12):** the
modular head and the modular cape. `Operator.ACTIVE_MODULAR_HEAD` and
`ACTIVE_MODULAR_CAPE` are `false`, and the composition paths that used to draw
them return early. Their source and runtime art stays published and their
canonical identities stay in the manifest, classified `DORMANT` per layer —
this is a retirement, not a deletion, and they may return in a dedicated
presentation/art pass. That is why these are gates rather than removed code.
Their compatibility SpriteFrames become zero-consumer residue for C2b/G.

### The presentation clock

Anything that follows animation frames — overlay synchronization, the melee
hit-window scan, the frame tick and the completion signal — reads them from
`_presentation_clock_sprite()`, which returns only a **visible** body layer. A
tick or a finish reported by a renderer that is not the current clock is ignored.

This is what allowed the hidden legacy clock to go. The legacy body used to be
left hidden-but-playing because it was three things at once: the frame value,
the frame tick, and the completion signal for attacks that commit on animation
finish. Under modular presentation it is now hidden **and stopped**, and the
visible modular lower body is the clock.

Gameplay timing is still not the renderer's: deterministic combat timelines own
it, and visual layers merely follow the visible clock.

Showing a renderer is a mechanism; changing presentation ownership is a
decision. The presenter keeps those separate: `show_layer()` is strict and
requires the renderer to belong to the current owner, while
`preempt_with_owner()` is the explicit transfer. One asymmetry is deliberate
and named — `present_legacy_full_body()` displays its sprite on acquisition,
because that owner is a single renderer and callers depend on it.

Transferring pixels is not the same as cancelling a lifecycle, and the presenter
owns only the first. An authored rig has an outstanding token and timer; when
gameplay deliberately preempts it, the **caller** invalidates that lifecycle
(`_invalidate_preempted_rig_lifecycles()`), or the abandoned coroutine wakes with
a still-valid token and runs completion behaviour — queued attacks, animation
updates, rig releases — for a presentation that no longer exists. Deciding that a
posture transition has been abandoned is action/presentation coordination;
`OperatorBodyPresenter` must stay ignorant of melee and posture gameplay.

Combat does not. Dodge does not. Melee does not. `operator.gd` does not.
Everything goes through:

```gdscript
body_presenter.present(plan) -> bool
```

`OperatorBodyPresentationPlan` is deliberately mechanical. It carries exactly
three fields and no semantic animation vocabulary:

```text
owner        = OperatorBodyPresenter.Owner
body_layers  = [renderers this owner wants visible]
overlays     = [owner-scoped cosmetics riding along]
```

Semantic requests — "modular body playing `fast_01` on lower, upper and weapon"
— are **not** the plan's job. Translating a semantic presentation request into
this mechanical plan belongs to the future `OperatorPresentationController`
(Slice E). Putting actions into the plan would hand the renderer the animation
selection authority this architecture spent Slice C taking away from it.

An empty `body_layers` list is meaningful and common: an authored rig acquires
the body first and shows its own layers as it starts playing them, which keeps
art selection with the caller while ownership stays in the presenter.

`present()` is transactional. The whole plan is validated — known owner, every
body layer registered and owned by that owner, every overlay registered and worn
by it — **before** anything is retired and before `_owner` moves. A rejected
plan changes nothing and returns `false`, so a bad renderer can never leave the
body owned by a presentation that never drew. `register_body_layers()` likewise
refuses to reassign a body layer that already belongs to a different owner.

Composition paths declare their whole presentation before configuring any layer:
resolve and check the clips, build the plan or claim the owner, then play the
layers they already own. `_show_body_layer()` is a strict delegate — it no longer
carries the seam that quietly took ownership on a caller's behalf, so acquiring
the body one layer at a time now reports an error instead of silently working.

`can_present(plan)` is the non-mutating, non-reporting probe, sharing one
validator with `present()` so the two can never disagree. `present()` takes
`report_rejection := true`; only negative-control tests pass `false`, because
validation treats a deliberate engine error as a failure and a rejected
presentation in production is a real bug that must be loud.

The presenter retires the previous body ownership and enables the new one
**atomically**, so no rendered frame contains two bodies. Weapon and FX
overlays are allowed alongside the body owner; a second body is not. The
invariant is one **body**, not one `CanvasItem` — the cape, for instance, is
worn by both the legacy dodge strips and the modular rig and is therefore an
owner-scoped overlay, not a body layer.

`operator_presentation_rig_2d.gd` is **not** this controller and must not be
converted into it. It is a cinematic puppet that clones currently visible
Operator parts for Ash-Bell lift and arrival sequences — a valid but unrelated
purpose.

## Target tree

```text
custodian/game/actors/operator/
├── operator.gd                          # thin actor facade/chassis
├── operator.tscn
├── AGENTS.md
├── core/
│   ├── operator_input_frame.gd
│   ├── operator_runtime_snapshot.gd
│   └── operator_action_controller.gd
├── input/
│   ├── operator_input_router.gd
│   └── operator_aim_controller.gd
├── movement/
│   └── operator_locomotion_controller.gd
├── combat/
│   ├── operator_melee_controller.gd
│   ├── operator_ranged_controller.gd
│   ├── operator_guard_controller.gd     # existing
│   ├── operator_integrity_reclaim.gd    # existing
│   └── operator_damage_controller.gd
├── traversal/
│   └── operator_dodge_controller.gd
├── loadout/
│   ├── operator_loadout_controller.gd
│   └── operator_weapon_runtime_state.gd
├── interaction/
│   ├── operator_interaction_controller.gd
│   └── operator_recovery_controller.gd
├── animations/
│   ├── operator_animation_selector.gd   # existing, survives
│   ├── operator_weapon_socket_library.gd
│   └── ...data helpers only
└── presentation/
    ├── operator_presentation_controller.gd
    ├── operator_body_presenter.gd
    ├── operator_animation_player.gd
    ├── operator_melee_presenter.gd
    ├── operator_ranged_presenter.gd
    ├── operator_reaction_presenter.gd
    ├── melee_posture_state.gd
    └── operator_presentation_rig_2d.gd  # cinematic puppet, separate purpose
```

## Migration slices

This is a staged strangler migration, **not** a rewrite. Large coordinators stay
compatibility facades while stable responsibilities are extracted behind them —
the pattern the procgen foliage organisation pass already used.

Every measured debt family has exactly one slice that owns retiring it, so no
counter is left without a home.

| Slice | Scope | Debt family it retires | State |
|---|---|---|---|
| A | Architecture contract, debt audit, characterization | — (establishes the ledger) | **done** |
| B | Presentation firewall, body ownership invariant | `body_visibility_outside_presentation` 25 → 0 | **done** |
| B-final | Owner-scoped overlays, transactional `present()`, caller-side lifecycle cancellation, alias-proof audit | `aliased_body_visibility_writes` 17 → 0 | **done** |
| C1 | Presentation playback funnel; remove hidden legacy-body-as-animation-clock authority | `animated_sprite_play_outside_presentation` 94 → 0 | **done** |
| C2 | Canonical semantic selection | `animation_resolver` 45, `attack_fallback_animation` 16, `directional_animation_fallback` 6, `actor_local_spriteframes` 5, `operator_animation_catalog` 4 → 0 | pending |
| D | `InputFrame` + `InputRouter` + `AimController`; deterministic device ownership; fixed-step migration; `_process()` becomes presentation-only | `input_calls_outside_input_dir` 65 → 0, `gameplay_mutation_in_process` 12 → 0 | pending |
| E | `OperatorActionController` replacing animation-state glue; `OperatorPresentationController` translating semantic requests into body plans | `animation_state_actor_glue` 34 → 0 | pending |
| F | Extract melee, dodge, ranged, loadout, interaction, recovery behind injected dependencies; remove the temporary presenter compatibility seams | `absolute_scene_lookups` 38 → 0, `weapon_definition_runtime_state` 3 → 0 | pending |
| G | Collapse `operator.tscn` and `operator.gd`, delete compatibility infra, final audits | `--final` on every audit | pending |

Slice C was split because the repo gave better information than the original
plan: the playback funnel and the selector cutover have different blast radii and
different failure modes, and bundling them would have made one monster slice whose
regression surface could not be reasoned about.

### Migration floor

The three-sweep validation baseline established by Slice B.5 is the floor:
`run_validation.py --tier actor` selects **41** checks and all 41 pass, three
sweeps in a row. No slice may land below it.

**Current status: 40/41 or 41/41 — `lootable_corpse_beacon` is INTERMITTENT.**
It fails on "enemy corpse collection must show typed and recovered-resource
toasts", and across six recorded C1/B-final sweeps it failed four and passed two.
It is unrelated to Operator body presentation and reproduces with the Operator
changes stashed, so it comes from neither slice. Treat it as a flaky test to be
diagnosed on its own terms — not as a deterministic red, and not as noise to be
ignored, since a test that passes sometimes is hiding a real nondeterminism.

Slice detail lives in the task packet.

## Final acceptance

- no double-body frame at any presentation handoff;
- input-device aim ownership works;
- no gameplay mutation in `_process()`;
- one `move_and_slide()` authority;
- no direct Operator animation-art references from gameplay;
- no retired animation-selector machinery;
- no actor-local compatibility `SpriteFrames`;
- no mutable per-instance state in weapon definition resources;
- existing combat, locomotion, dodge, ranged and interaction behaviour green;
- `operator_runtime_animation_authority --final` passes;
- `operator_runtime_path_audit --final` passes;
- `operator_architecture_debt_audit --final` passes.

No new art assets are required for this migration.
