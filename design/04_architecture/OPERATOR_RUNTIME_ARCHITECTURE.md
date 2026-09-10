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
| body-layer visibility writes outside presentation | 25 | `OperatorBodyPresenter` |
| attack `fallback_animation` indirection | 16 | selector exact-identity contract |
| simulation advanced from the render tick | 12 | the fixed physics tick |
| retired `DirectionalAnimationFallback` | 6 | `OperatorAnimationSelector` |
| actor-local `SpriteFrames` construction | 5 | one generated `operator_runtime_frames.tres` |
| retired `OperatorAnimationCatalog` | 4 | `OperatorAnimationSelector` |
| mutable state in `OperatorWeaponDefinition` | 3 | `OperatorWeaponRuntimeState` |
| **total** | **347** | |

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

Combat does not. Dodge does not. Melee does not. `operator.gd` does not.
Everything goes through:

```gdscript
body_presenter.present(plan)
```

where a plan is either

```text
body_mode     = MODULAR
lower_action  = fast_01
upper_action  = fast_01
weapon_action = fast_01
```

or

```text
body_mode   = FULL_BODY
body_action = critical_execution_01
```

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

| Slice | Scope | State |
|---|---|---|
| A | Architecture contract, debt audit, characterization | **done** |
| B | Presentation firewall, body ownership invariant | **invariant landed; presenter extraction pending** |
| C | Canonical animation-selector cutover | pending |
| D | Input/aim router + fixed-step split | pending |
| E | `OperatorActionController` replacing animation-state glue | pending |
| F | Extract melee, dodge, ranged, loadout, interaction, recovery | pending |
| G | Collapse `operator.tscn` and `operator.gd`, delete compatibility infra | pending |

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
