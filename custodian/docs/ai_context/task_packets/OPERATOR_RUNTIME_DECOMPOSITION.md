# Task Packet — Operator Runtime Decomposition

**Status:** Slices A and B complete (2026-09-10)
**Contract:** `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`
**Gate:** `custodian/tools/validation/operator_architecture_debt_audit.py`

## Goal

Turn `operator.gd` from a 540 KB multi-authority god object into a thin
deterministic actor facade built from explicit domain controllers and a single
presentation authority.

**This is a staged strangler migration, not a rewrite.** Each slice must be
independently reviewable and leave the runtime green.

## Read first

- `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`
- `design/04_architecture/INTEGRATION_CONTRACT_GLUE_LAYER.md`
- `design/02_features/animation/OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md`
- `design/02_features/combat_feel/OPERATOR_MELEE_CONTACT_TIMING_AND_CADENCE.md`
- `design/02_features/combat_feel/OPERATOR_MELEE_ATTACK_DRIVE.md`
- `custodian/game/actors/operator/AGENTS.md`
- `custodian/docs/ai_context/ARCHITECTURE_OWNERSHIP_MAP.md`

The core locks are listed in the contract and are not restated here. Do not
weaken one to make a slice easier; raise it instead.

## Working rule for every slice

Run the debt audit before and after. It ratchets:

```bash
python3 custodian/tools/validation/operator_architecture_debt_audit.py
python3 custodian/tools/validation/operator_architecture_debt_audit.py --final   # end state
```

- a NEW or INCREASED violation fails ordinary validation — debt cannot grow;
- a DECREASED violation makes the baseline stale, which is TODO normally and a
  failure under `--final`, so the ledger must shrink as work lands;
- refresh the ledger with:

```bash
python3 custodian/tools/validation/operator_architecture_debt_audit.py --emit-baseline \
  > /tmp/base.json && mv /tmp/base.json custodian/tools/validation/operator_architecture_debt_baseline.json
```

Do not redirect straight onto the baseline file: the audit reads it at import
time and the shell truncates it first.

## Slice A — contract + audit + characterization — DONE

Delivered:

- `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`
- this packet
- `custodian/tools/validation/operator_architecture_debt_audit.py` with 13
  ownership rules, `--final`, `--json` and `--emit-baseline`
- `custodian/tools/validation/operator_architecture_debt_baseline.json`
  frozen at **347 violations across 12 rules**
- registered as `operator_architecture_debt` in the validation manifest
- documentation drift corrected (see below)

Characterization measured at freeze time is tabulated in the contract.

## Slice B — presentation firewall

**Landed (commit `cb157148b`):** the one-body invariant itself.
`_set_body_presentation_owner()` in `operator.gd` is now the single authority —
it hides and stops every body-capable renderer, then enables only the requested
owner. The Vigil posture bridge and ready→fast_1 startup acquire it atomically
and surrender it on release. `operator_visual_ownership_smoke.gd` asserts
visible **body owners** one frame before and after every handoff, with negative
controls proving it catches the pre-fix duplicate-body behaviour.

**Extracted (Slice B):** the authority now lives in
`presentation/operator_body_presenter.gd` (`RefCounted`) with
`presentation/operator_body_presentation_plan.gd` as the typed request shape.
`operator.gd` holds a presenter instance, registers the static renderers in
`_ready()` and the lazily built Vigil rigs as they are created, and keeps thin
delegating wrappers with no visibility policy.

Presenter vocabulary is deliberately split, so that showing a renderer is a
mechanism and changing ownership is a decision:

- `show_layer(layer)` is **strict** — a body layer must already belong to the
  current owner, otherwise it errors and refuses. An innocent-looking show can
  never overthrow an exclusive presentation.
- `preempt_with_owner(owner, layers)` is the explicit ownership transfer.
- `present_legacy_full_body()` names the one asymmetric case: that owner is a
  single sprite, so acquiring it displays it, which existing callers depend on.
- `present(plan)` rejects a plan whose body layers span owners.

Draw/equip legitimately preempting a posture bridge is real behaviour, so the
transfer has to be possible — it just has to be *said*. The ~14 incremental
modular sync call sites still speak per layer, so `operator.gd::_show_body_layer()`
carries a documented MIGRATION SEAM that performs the explicit
`preempt_with_owner()` on their behalf. Slice F should convert those call sites
to `_present_body()` and delete the branch.

`claim_modular()` still hides the legacy body without stopping it, now marked
in-code as MIGRATION DEBT: some weapon/presentation layers slave frame timing
to the hidden legacy sprite, and Slice C must remove that hidden
animation-clock authority before LegacyFullBody can always be stopped on
retire.

Do not convert `operator_presentation_rig_2d.gd` into this controller.

## Slice B-final — close the presentation firewall — DONE

Slice B's `body_visibility_outside_presentation = 0` was a **false zero**. The
audit regex only recognised direct writes through the literal body-node names,
so binding a body renderer to a loop variable or a parameter and writing
`sprite.visible` hid the same write from the same rule. Seventeen such aliased
writes were live in `operator.gd`.

Closed in B-final:

1. **Owner-scoped overlays.** The presenter's single global `_overlays` array
   became `_overlays_by_owner` + `_owners_of_overlay`, alongside
   `_layers_by_owner`. It had two opposite bugs at once: `release_modular()`
   retired *every* owner's overlays, so an unrelated modular release hid the
   active Vigil bridge's sword, while `claim_modular()` retired none, so modular
   preemption took a rig's body and left its weapon floating. Counting bodies
   could not see either. An overlay may be worn by several owners — the cape
   rides both the legacy strips and the modular rig — so `release_modular()`
   leaves shared overlays to whoever takes the body next.
2. **Transactional `present()`.** Owner, every body layer and every overlay are
   validated *before* anything retires and before `_owner` moves; the function
   returns `bool`. An unregistered layer used to default to looking valid
   (`_owner_of_layer.get(layer, plan.owner)`), so the presenter tore down the old
   owner and changed `_owner` before `show_layer()` finally refused the bad
   renderer. `register_body_layers()` now also refuses to reassign a body layer
   that already belongs to a different owner.
3. **Caller-side lifecycle cancellation.** Transferring pixels does not
   invalidate a coroutine. `_invalidate_preempted_rig_lifecycles()` in
   `operator.gd` bumps the abandoned rig's token and clears its pending action
   when gameplay deliberately preempts it. The presenter stays ignorant of melee
   and posture gameplay — cancelling a lifecycle is action/presentation
   coordination, not renderer policy.
4. **Real body-visibility zero.** Every aliased write now funnels through
   `_show_presentation_layer()` / `_hide_presentation_layer()`, which route
   anything the presenter owns to the presenter and only ever set unregistered
   cosmetic layers directly. The audit gained
   `aliased_body_visibility_writes`, which strips those two declared funnel
   functions by name and flags aliasing everywhere else: **17 at the previous
   commit, 0 now**.
5. **The Vigil guard rig was never registered at all.** `_vigil_guard_lower` /
   `_vigil_guard_upper` are a complete authored body that was built, shown and
   hidden entirely outside the presenter, invisible to the one-body invariant. It
   is now `Owner.VIGIL_GUARD`, an exclusive owner with its own weapon overlay,
   and it takes the body explicitly instead of claiming `MODULAR_BODY` and hiding
   the modular composition behind itself.

`operator_visual_ownership_smoke.gd` gained three scenarios, each verified to
fail when its bug is reintroduced: an unrelated modular release leaving an active
bridge's weapon alone; explicit preemption retiring a rig's body *and* weapon and
cancelling its lifecycle so the expired coroutine cannot reclaim the
presentation; and a rejected plan changing nothing.

Still deliberately open: `_show_body_layer()`'s MIGRATION SEAM, and
`claim_modular()` keeping the legacy body hidden-but-playing as an animation
clock. Both belong to C1.

## Slice C1 — presentation playback funnel — DONE

`presentation/operator_animation_player.gd` owns HOW an already-resolved clip
plays.

The count, stated precisely. The recorded ledger was **94** (`operator.gd` 87 +
7 across the animation states) and it moved 94 -> 0 as recorded. But the
hardened detector found one more site the old pattern could not see —
`sprites[index].play()`, direct playback wearing an index — so the *actual*
number of direct playback sites was **95**: 88 in `operator.gd` plus 7 in the
states. C1 eliminated all 95. The ledger and reality now agree.

The states reach playback through narrow `AnimationStateMachine.play_animation()`
/ `can_play_animation()` delegates that share the same authority instance.
`animated_sprite_play_outside_presentation` is retired from the baseline. The rule also gained an optional subscript, because
`sprites[index].play()` was the same direct playback wearing an index and the old
pattern missed it, exactly the way the body-visibility rule missed aliases.

**The hidden legacy clock is gone.** It turned out to be three things at once,
which is why it had survived: the frame *value* read by overlay synchronization
AND by the melee hit-window scan, the frame *tick* (`frame_changed` was only
connected to the legacy body), and the *completion signal* for attacks that
commit on animation finish. Removing only the first breaks the dagger, which is
how the regression surfaced. All four now follow `_presentation_clock_sprite()`,
which returns only a VISIBLE body layer; `frame_changed` and `animation_finished`
are bound per-source and ignored when the source is not the current clock. Under
modular presentation `LegacyFullBody` is hidden **and** stopped.

Note `MeleeOverlayClockOwner.MODULAR_LOWER_BODY` was assigned in four places and
consumed in none — under modular presentation the overlays were not being
synchronized at all. They are now.

**The body-show seam is gone.** `_show_body_layer()` is a strict delegate.
Composition paths declare their presentation before configuring any layer, via
`_declare_modular_body_composition()` at the point where they have resolved and
checked their clips. Nine paths were acquiring the body one layer at a time and
are converted: melee locomotion, melee posture, unarmed parry, unarmed block,
lower/upper body locomotion, ranged ready/relaxed upper layers, ranged aim, and
the damage reaction (which claimed the body *after* playing every layer).

**A stranded windup was found and fixed.** Preempting the ready_to_fast startup
left `_melee_fast_windup` true forever, because only the startup's own completion
clears it — silently blocking every subsequent attack.
`_invalidate_preempted_rig_lifecycles()` now clears it with the token.

Deliberately untouched, for C2: `AnimationResolver` 45, `fallback_animation` 16,
`DirectionalAnimationFallback` 6, actor-local `SpriteFrames` 5,
`OperatorAnimationCatalog` 4.

## Slice C2a — canonical animation consumer cutover — BLOCKED, evidence landed

Characterization landed; the code cutover did not, because characterization
showed it cannot be done safely as specified yet. Three findings, in order of
how much they block.

### 1. Every renderer is on a compatibility SpriteFrames

`operator.tscn` binds all eleven presentation renderers to the compatibility
resources in `game/actors/operator/`, not to the generated
`content/sprites/operator/runtime/operator_runtime_frames.tres`. Legacy clip
names (`unarmed_walk_e`) and canonical identities
(`unarmed/locomotion/walk_01/e/lower_body`) are disjoint namespaces, so a
selector result is unplayable until its renderer is rebound — and per this
packet's own rule, rebinding one renderer means migrating ALL of its consumers
in the same atomic step. Touch points per renderer:

```text
animated_sprite              124      melee_weapon_overlay_sprite   22
modular_upper_body_sprite     52      primary_weapon_sprite         19
modular_lower_body_sprite     39      modular_upper_fx_sprite       17
melee_fx_overlay_sprite       16      ranged_fx_overlay_sprite      12
modular_head_sprite            6      modular_sidearm_sprite         5
modular_cape_sprite            3
```

That is ~315 presentation touch points, and the largest single atomic unit is
124. The three debt counters C2a targets (61 sites) are the visible part of a
much larger change.

### 2. The recorded evidence does not prove most mappings

`operator_selection_cutover_inventory.py` (migration-only; gameplay must never
consume it) joins every legacy selection site against the reachability contract
and the runtime manifest. Of 59 sites:

- 16 pass a clip literal; the contract records only **6** of those clips.
- 24 pass a variable and need caller tracing to identify at all.
- 9 resolve to recorded consumer evidence overall.

`ranged_2h_aim_modular`, `ranged_2h_stance_modular`, `unarmed_parry`,
`unarmed_attack_fast_windup`, `unarmed_attack_fast_recovery` and
`unarmed_attack_fast_recovery_fx` appear at call sites and are **not** recorded
in the reachability contract. This packet says not to infer identity from clip
names when the repo records them; where the repo does *not* record them, the
mapping has to be established deliberately, not guessed. Extending the
reachability contract to cover these is the cheapest way to unblock.

### 3. The dodge fallback is case C, and its replacement is a design decision

`_resolve_dodge_presentation_animation()` searches for the nearest sector that
has art. Dodge chain-link and charge-windup are authored in only three facings
(`down`, `left`, `right`) covering eight input directions, so the search is
doing real work. Its current outcomes are an artifact of tie-ordering rather
than a coherent rule, and no deterministic mapping reproduces them:

```text
sector   current      |x|>=|y| rule
n     -> right        down          <- differs
ne    -> right        right
e     -> right        right
se    -> down         right         <- differs
s     -> down         down
sw    -> down         left          <- differs
w     -> left         left
nw    -> left         left
```

Under the strict contract a missing exact identity goes to SOUTH, so a
north-east dodge would render the *down* strip where it renders *right* today.
Choosing the replacement means answering what a north, south-east and
south-west dodge should look like — an authoring decision. Options: author the
missing directions, or declare an explicit three-facing intent rule and accept
the change in those three sectors.

### Authoring decisions received (2026-09-12) and applied

**Modular head and cape are retired from active composition, not deleted.**
`Operator.ACTIVE_MODULAR_HEAD` / `ACTIVE_MODULAR_CAPE` gate the composition
paths that drew them; source and runtime art stays published; the ten affected
canonical layers are classified `DORMANT` per layer in the reachability
contract. They are NOT rebinding targets for C2. The first small renderer proof
is therefore `modular_sidearm_sprite` (5 touch points), not
`modular_head_sprite`. `operator_modular_head_frames.tres` and
`operator_modular_cape_frames.tres` become zero-consumer residue for C2b/G.

**Dodge directional coverage is materialized, not fallen back to.** The visible
mapping the characterization found is preserved deliberately —
N/NE -> E art, SE/S/SW -> S art, W/NW -> W art — and expanded into exact
canonical identities for all eight sectors of `dodge_charge_windup_01` and
`dodge_chain_link_01`. Every expanded strip is a byte-identical copy of the
authored strip it reuses, verified by SHA-256, and carries an `.expansion.json`
sidecar recording that it is deliberate reuse rather than unique art, so no
future agent mistakes it for authored coverage. The map and rationale live in
`tools/pipelines/migrations/operator_directional_expansion_map.json`; the
reachability entries point at it.

The selector is deliberately NOT taught this mapping: it keeps seeing an exact
identity, and its contract stays exact -> temporary same-identity SOUTH ->
error. This is presentation only and must never affect dodge movement
direction, Flow, timing or iframes.

Note the dodge entries stay `DORMANT`: the coverage now exists, but the
consumer still resolves legacy production body frames until `animated_sprite`
is rebound. Retiring `DirectionalAnimationFallback` at that call site is
therefore part of the `animated_sprite` cutover, not separable from it.

### Recommended sequencing for the next attempt

1. Extend `operator_animation_reachability.json` to record the ten unrecorded
   clips, and trace the 24 variable-argument sites to their callers. The
   inventory reports both sets.
2. Answer the dodge authoring question in item 3.
3. Then cut over renderer by renderer, starting with `modular_sidearm_sprite`
   (5 touch points) to prove the rebinding pattern before touching
   `animated_sprite`. Head and cape are retired, not migrated.
4. Expect SOUTH-fallback telemetry to spike where canonical directional
   coverage is partial — `melee_1h/posture/*` is e/w only,
   `unarmed/locomotion/walk_01` upper is 6 of 8. Collect the counts as §9 asks.

Nothing in `game/` was changed by this slice: a partial cutover would silently
change what the player sees, and the smokes cannot see art correctness.

## Slice C2a — original scope

Route every presentation request through `OperatorAnimationSelector` and the one
generated `operator_runtime_frames.tres`. Retire `AnimationResolver` (45),
`DirectionalAnimationFallback` (6), `OperatorAnimationCatalog` (4),
`fallback_animation` (16) and actor-local `SpriteFrames.new()` (5) **only as
their consumers reach zero**. The selector's exact-identity → temporary SOUTH →
error contract is already correct; the existing final audits define the finish
line.

## Slice D — input + fixed-step spine

Introduce `OperatorInputFrame`, `OperatorInputRouter` and
`OperatorAimController`. Move the 12 simulation advances out of `_process()`
onto the explicitly ordered fixed tick; leave `_process()` presentation-only.
Make gamepad/mouse ownership deterministic: a neutral stick retains the last
gamepad aim and only real mouse movement hands the device back. Make
`ControllableActor.process_input()` a real adapter instead of the current
no-op `pass`, so replay/AI/vehicle drivers have a seam.

## Slice E — action arbitration

Introduce `OperatorActionController` and `OperatorPresentationController`. The
latter is what translates a semantic presentation request ("modular body playing
`fast_01` on lower, upper and weapon") into the mechanical
`OperatorBodyPresentationPlan`. Semantic action fields must **not** be added to
that plan: the plan stays `owner` + `body_layers` + `overlays`, or the renderer
reacquires the animation-selection authority C2 takes away from it.

Delete the empty `idle_state.gd`,
`walk_state.gd` and `sprint_state.gd` shells — locomotion is a separate axis and
must not compete with attack state. Action arbitration owns interruption and
priority only; melee, guard, dodge, ranged, equip/sheathe, damage and death own
their own behaviour. Eliminate the 34 `actor.has_method()`/`call()` glue sites.
The action controller must not hold a sprite reference at all.

## Slice F — extract domains

One domain at a time: melee timeline/drive, dodge, ranged/ammo/heat/reload,
loadout, interactions/build/repair, recovery. Keep `operator.gd` facade methods
so existing callers and tests keep working. Split
`OperatorWeaponDefinition` into immutable definition data plus
`OperatorWeaponRuntimeState` (the 3 mutable `@export` fields are old-architecture
residue with no meaningful current consumers).

Retire the **38** absolute `/root/...` scene-tree lookups
(`absolute_scene_lookups`) by injecting those dependencies, and remove the
temporary presenter compatibility seams once the domains declare presentations up
front.

## Slice G — collapse the shell

Reorganise `operator.tscn` into `Controllers`, `Presentation`, `Sockets`,
`Hitboxes` and `Feedback` groups. Remove compatibility nodes and resources.
Move Knight Test Skin and debug frame construction out of production Operator
code. Update `FILE_INDEX.md`, `CURRENT_STATE.md` and
`ARCHITECTURE_OWNERSHIP_MAP.md`. Turn the debt audit into a hard `--final` gate
in the default validation set.

## Tooling backlog

**Generated Operator runtime spine has a writer lock.** DONE.
`custodian/tools/godot_project_lock.py` is a machine-wide exclusive `flock` over
one Godot project, keyed by resolved project path. `run_validation.py` holds it
across the import step and the tests that load its output; the Operator pipeline
holds it while it rewrites the runtime spine. Both take `--no-godot-lock` for
debugging a stuck lock.

`flock` was chosen because the kernel releases it when the holder dies: agent
sessions get killed mid-run, and a PID-file lock would strand the project behind
a lock nobody holds. The lock file lives in the system temp directory — never in
the repository (it would show up in `git status`) and never in `.godot/`, because
a full reimport deletes that directory and would silently unlink the inode every
waiter is queued on. Acquisition is reentrant across process boundaries via
`CUSTODIAN_GODOT_PROJECT_LOCK`, so a locked run can shell out to another locked
tool without deadlocking.

`godot_project_lock_smoke.py` asserts the behaviour rather than the presence of
the code: a second acquirer blocks, times out with a message naming the holder,
and succeeds once the holder releases — including when the holder is SIGKILLed.

Evidence, stated precisely. The original incident was one observation: two
overlapping full `run_validation.py` sweeps produced
`infrastructure_failure: import` with the import step timing out at 120s.
Afterwards that timeout **could not be reproduced on demand** with the lock
disabled, on either single-test or 26-check overlapping runs — the project was
already fully imported, so the contention window was small. So the lock is
justified by proven serialization plus one real incident, not by a repeatable
red. Treat a recurrence as new information rather than assuming this is closed.

A Godot **editor** open on the project is a writer the lock cannot capture: it
holds the project and reimports on filesystem change. It is harmless for ordinary
validation — every B-final sweep passed with one open — so the pipeline only warns
about it (`detect_external_editor()`) before rewriting the generated spine rather
than refusing to run.

Deliberate engine errors are a related hazard. `classify_warnings()` treats any
unregistered `ERROR:` line as fatal, and `known_headless_warnings.json` holds only
engine-shutdown noise. Negative-control tests must therefore not emit errors:
registering a real rejection message there would mask that same rejection
everywhere else. `OperatorBodyPresenter.present()` takes `report_rejection` and
`can_present()` probes validity silently precisely so the rejection paths can be
tested without weakening the registry.

## Non-goals

- No ECS rewrite, no constellation of tiny manager classes.
- No arbitrary LOC limits during extraction.
- No new art assets.
- No behavioural change to combat, locomotion, dodge, ranged or interaction.
- No conversion of `operator_presentation_rig_2d.gd`.

## Documentation drift corrected in Slice A

| Drift | Correction |
|---|---|
| `OPERATOR_MELEE_PRESENTATION_POSTURE.md` said attacks from RELAXED bypass `ready_up` | Live `MeleePostureState.attack_action_bypasses_ready_up()` returns **false**; the doc was stale, not the code. Doc now states the bridge chain. |
| `OPERATOR_MELEE_FAST_CHAIN.md` referenced by 3 live docs but absent | References redirected to the live cadence/posture authorities |
| `operator_modular_core.json` referenced by 4 live docs | Live contract is `custodian/tools/validation/contracts/operator_animation_core.json` |
| `WEAPON_OWNED_ANIMATION_SYSTEM.md` carried the old `AnimationResolver` target architecture | Marked superseded by `OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md` |

The locked relaxed-attack flow is:

```text
relaxed
→ relaxed_to_ready
→ READY ANCHOR
→ ready_to_fast_1
→ fast_1
```

with no `idle_ready` playback between the bridges.

## Validation

```bash
python3 custodian/tools/validation/operator_architecture_debt_audit.py
python3 custodian/tools/validation/operator_runtime_path_audit.py
python3 custodian/tools/validation/run_validation.py --test operator_visual_ownership
python3 custodian/tools/validation/run_validation.py --changed --json
```
