# Task Packet — Operator Runtime Decomposition

**Status:** Slices A, B, B-final, C1, **D** (through D.3) and **C2b in part**
(through **C2b.1**) complete (2026-09-24). C2a/R4 landed some time ago --
`animated_sprite` is canonical and the modular body is canonical -- so the older
"C2a blocked / R4 next" prose below is history, not present reality.
Architecture debt is **97**, down from **347** at the start of the migration.

**C2b.1 (blocker removal).** C2b discovered that equipping a melee weapon copied
that weapon's `body_frames_resource` into the shared canonical `SpriteFrames`,
making the runtime animation database mutable and keeping legacy clip names
genuinely reachable. That mutation is gone: the canonical database is immutable
across equip/unequip/cycling, armed melee selects canonical semantic identities
derived from weapon data, the per-weapon `SpriteFrames` fields and their six
resources are deleted, and `actor_local_spriteframes` reached 0.
`operator_runtime_spine_immutable` is the executable form of that invariant.
`animation_resolver` (18) and `directional_animation_fallback` (4) remain for
non-armed callers and retire in the C2b demolition pass. The figure previously given
here as the migration's starting point, 201, was an intermediate state, not the
opening balance.

**Slice D (done, after the D.1 and D.2 seal corrections).** `operator/input/` is the sole owner of raw Operator input
sampling: `OperatorInputFrame` (one immutable tick of intent),
`OperatorInputRouter` (the only `Input.*` reader) and `OperatorAimController`
(aim-source policy and the retained controller direction, moved out of
`operator.gd`). One frame is sampled at the top of `_physics_process`; the tick is
`_sample_input_frame` -> `_advance_simulation` -> `_advance_movement`, and
`_process` is presentation only. `ControllableActor.process_input()` stays a no-op
base interface; the **Operator override** is the implemented adapter, and it is
real: an injected frame is adopted by the next fixed tick, so external control
converges with local input before any gameplay decision. Counters:
`input_calls_outside_input_dir` 65 -> 0, `gameplay_mutation_in_process` 12 -> 0,
total architecture debt 119.

**D.1 corrected three things Slice D got wrong.** It had exempted four calls from the render-tick
audit on the strength of their names; three of them advance state gameplay reads and are now on the
fixed tick -- the ranged action timer gates firing through `_is_ranged_aim_ready()`, the animation
state machine's state gates movement locks and weapon selection, and melee draw grace gates the Vigil
ready-up bridge. Only `_update_body_recoil` remains exempt. `adopt()` now derives
`just_pressed`/`just_released` for injected frames, without which external control could drive
held-fire ranged but not melee or the sidearm. And `OperatorAimController` now actually reads
`OperatorInputFrame.mouse_moved`, which Slice D sampled and ignored.

**D.2 closed the two authority seams D.1 left open.** External aim is now an
explicit input-frame fact (`external_control` + `control_aim`) that
`OperatorAimController` ranks above every local source: D.1 filed the supplied
vector as `keyboard_aim`, which is read only in arrow-aim mode, so
`process_input()` accepted a world-space aim direction and could silently discard
it -- external control could press a button but not steer. And `mouse_moved` is now
event-derived, from `InputPromptService.mouse_motion_generation`, a monotonic count
advanced only by a qualifying `InputEventMouseMotion`. D.1 derived it from changes
in `_get_world_mouse_position()`, a camera-relative coordinate that moves under a
motionless mouse because `CameraController` follows the Operator with smoothing,
lookahead, ranged lead, threat framing, bob and shake -- so the stale-mouse handoff
D.1 set out to fix could still reappear. The router no longer sees a mouse position
at all.
Gates `operator_input_frame` and `operator_fixed_tick_spine` own
`operator/input/**`, and `operator_input_aim_source` carries the D.2 negative
controls against the real actor. Still open and deliberately untouched: C2b, Slice E
(`OperatorActionController`) and Slice F (domain extraction).

The C2a renderer cutover record, kept for its evidence (2026-09-15):

| step | renderer / scope | state |
|---|---|---|
| C2a-R1 | `modular_sidearm_sprite` | canonical |
| C2a-R2 | `modular_upper_fx_sprite` | canonical |
| C2a-T1 | authored timing preserved on the canonical spine | done |
| C2a-R3 art | synchronized 4-frame `block_enter_01` body pair | published |
| C2a-T1.1 | frozen authored-timing oracle | done |
| C2a-R3 | `modular_lower_body_sprite` + `modular_upper_body_sprite` | canonical |
| C2a-R4 | `animated_sprite` | canonical |
| C2a-R4.1 | `animated_sprite` seal correction | done |

`animated_sprite` is canonical as of R4/R4.1; the sentence that used to stand
here calling it a compatibility renderer predated that and was wrong when read.
The melee weapon/FX overlays are still compatibility renderers, and the
compatibility SpriteFrames stay on disk until C2b completes.
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

### Evidence pass complete (2026-09-12)

`operator_selection_cutover_inventory.py` now proves each site's canonical intent
and emits `reports/operator/operator_selection_cutover_evidence.json` plus a
Markdown companion. Every site is classified; **zero remain UNRESOLVED**:

```text
PROVEN              50
DATA_DRIVEN          6
AUTHORING_DECISION   2
RETIRED              1
```

The authoritative join is `legacy_clips` on each reachability row, with
`legacy_clip_proof` recording the proof source per clip. 43 clip mappings are
recorded this way. Prose matching was tried first and rejected: "unarmed_parry"
matches "unarmed_parry_recovery" by substring and silently yields the wrong
action, so the contract records the mapping as data and the tool only reads it.

**DATA_DRIVEN (6 sites)** are not provable from code at all: `base_animation`
arrives from `OperatorWeaponDefinition.animation_map` / `fx_map`, or from the
weapon `melee_stance` entry. The mapping is proven per resource entry — the
`vigil_dagger_fast_*` and `sword_cleaver_fast_*` clips are recorded — but the
*resource* is what has to change, per C2a §7. These block their renderers.

**AUTHORING_DECISION (2 sites)** — `begin_modular_damage_reaction`.
`shared/locomotion/idle_hitreact_01` is authored for `n` and `s` only and the
retired nearest-sector search chose between them. Which variant a
diagonal-facing hit reaction should use is the same shape of question as the
dodge decision, and needs the same kind of answer. This blocks
`modular_lower_body_sprite` and `modular_upper_body_sprite`.

### Renderer readiness

```text
modular_sidearm_sprite      5 sites,  0 blocking   READY
modular_upper_fx_sprite     5 sites,  0 blocking   READY
melee_weapon_overlay_sprite 2 sites,  1 blocking
melee_fx_overlay_sprite     2 sites,  1 blocking
modular_lower_body_sprite  16 sites,  2 blocking
modular_upper_body_sprite  17 sites,  2 blocking
animated_sprite            15 sites,  4 blocking
modular_head_sprite / modular_cape_sprite            RETIRED
```

Two corrections worth keeping. First, `modular_sidearm_sprite` is not the
5-touch-point renderer the earlier estimate suggested — it serves both the
`sidearm` and `ranged_2h` profiles, and its consumer set spans
`_sync_sidearm_action_sprite`, `_sync_modular_ranged_weapon_layer`,
`_retarget_ranged_sprite_preserving_progress` and `_play_modular_action_animation`.
It is still the smallest READY renderer. Second, readiness had to attribute
generic helper sites to the renderers their callers pass, and entry-point sites
to the renderers they actually drive — attributing by mere mention made
`begin_modular_damage_reaction` block the sidearm it only hides, and attributing
by call line alone made `animated_sprite` look READY with four open blockers.

### Coverage note for the sidearm cutover

`sidearm/posture/draw_sidearm_01` and `sidearm/cosmetic/fire_sidearm_01` are
published on the four diagonals only (`ne nw se sw`) — no cardinals. Under the
strict contract a cardinal-facing sidearm draw has no exact identity and no
SOUTH to fall back to, so expect either authored cardinals or a deliberate
decision before the sidearm cutover is visually complete.

### Open authoring question found while proving mappings

`unarmed_block_exit` is played as `block_enter_01` by an existing in-code
substitution, and there is no unarmed `block_exit_01` art, though
`melee_1h_heavy` has one. Whether unarmed block exit deserves its own authored
action is recorded on the reachability row as `open_authoring_question`. Not a
cutover blocker.

### C2a-R1 — modular_sidearm_sprite is canonical (DONE)

The first live compatibility renderer is on the canonical spine.
`operator.tscn` binds `ModularSidearmSprite` to
`content/sprites/operator/runtime/operator_runtime_frames.tres`, the scene no
longer loads `operator_modular_sidearm_frames.tres` at all, and the evidence
report marks the renderer `CANONICAL` with `canonical_frames_bound: true` and
zero legacy selection sites. The compatibility `.tres` stays on disk as C2b
residue. No other renderer moved.

Selection now runs semantic intent -> `OperatorAnimationSelector.resolve_sector()`
-> `OperatorAnimationPlayer` -> renderer. `resolve_sector()` is a new entry point
that takes an already-decided sector and performs the same exact -> temporary
SOUTH -> error lookup, because projecting a requested direction onto an authored
facing is presentation policy that belongs to the caller. The selector learns
nothing about the projection.

**The evidence artifact under-reported this renderer, and that matters for the
renderers still to come.** It said 5 sites / 4 active / 0 blockers, scoped to the
three debt patterns. Two further legacy selection mechanisms drive this renderer
and are invisible to those patterns:

* `_resolve_sidearm_directional_animation()` built `<base>_<up|down>_<left|right>`
  names directly — the whole P-9 draw/fire path, and the reason the sidearm's own
  presentation never appeared in the inventory at all. Now deleted.
* `_play_first_available_modular_fire_animation()` walks a *candidate name list*,
  so the ranged fire weapon layer selected legacy clips without ever touching
  `AnimationResolver`. Its `&"weapon"` candidate list is now empty and the layer
  resolves one canonical identity.

Expect the same for later renderers: the debt counters are a floor on the
consumer surface, not a description of it. Read the renderer, not only the report.

**Direction policy.** The P-9 is authored for four diagonals. The 2026-09-12
authoring decision is encoded as a literal table, and it is exactly what the
deleted `_resolve_sidearm_directional_animation()` produced, so nothing the
player sees changed:

```text
n, ne -> ne      e, se, s -> se      sw, w -> sw      nw -> nw
```

The sector is resolved ONCE per action and drives the whole authored stack. The
three layers beside the pistol are still compatibility renderers, so they receive
legacy names built from the SAME sector via
`_sidearm_legacy_sector_suffix()` — they cannot drift from the pistol, which is
what independent per-layer resolution allowed before.

**ranged_2h on this renderer.** Despite the node's name it also carries the
ranged_2h weapon layer. Those actions are published in partial sets, and their
projection tables were characterized rather than invented: the compatibility
resource already sourced canonical PNGs, its unsuffixed clips are the `e` art,
and `AnimationResolver` fell through to `_left` when x < 0 and otherwise to
`_right`. `RANGED_2H_AUTHORED_SECTORS` reproduces that per action. `fire_01`
leaves ne/nw/s mapped to themselves because those sectors played nothing before;
`has_sector_identity()` asks before resolving so ordinary aiming does not emit
missing-animation errors for an optional layer.

All of this is presentation only. Aim direction, projectile direction, the weapon
socket, movement, target selection, gameplay state and combat timing are
untouched.

**Tests.** `operator_sidearm_canonical_smoke.gd` asserts the actual canonical
animation selected for all eight sectors, that the stack shares one authored
sector, that legacy clips are no longer playable on the renderer, and that
ranged_2h requests never resolve P-9 art. Two negative controls verified: inverting
one cardinal fails it, and desynchronising the legacy suffix table fails it.

Two existing tests encoded the compatibility naming and were updated rather than
worked around: `operator_weapon_socket_smoke` now asserts the renderer carries
canonical identities and does **not** carry the legacy clips, and drives it with
canonical names; its socket-track checks stay keyed to the still-legacy upper body.

### C2a-R2 — modular_upper_fx_sprite is canonical (DONE)

The authoring blockers were resolved on 2026-09-13 and the renderer is cut over.
`ModularUpperFxSprite` binds to `operator_runtime_frames.tres`, the scene no
longer loads `operator_modular_upper_fx_frames.tres`, and the evidence report
marks it `CANONICAL` with zero legacy selection sites. `animation_resolver` fell
43 -> 42 by this renderer's site. No other renderer moved.

**The runtime SpriteFrames mutation is gone.** This was the structural blocker:
`_ensure_operator_critical_hitspark_animation()` and the FX half of
`_ensure_paired_execution_animation()` built animations into the renderer's
SpriteFrames from raw PNG sheets, which a *shared* canonical resource cannot
accept. Both now resolve published identities — `critical_hitspark_01`,
`critical_execution_01`, `falcon_reversal_01` — whose frame counts and canvas
sizes match the actor's constants exactly, so they are drop-in. The legacy sheet
constants and the hitspark builder are deleted. `_play_modular_parry_fx()` was
dead with no callers and is deleted rather than preserved as a seam.

**Parry FX authoring decision.** Successful parry presents
`unarmed/defense/parry_success_01/fx`. The legacy clip
`unarmed_parry_success_01_fx` is NOT preservation authority: it was mis-published,
its west sourcing `parry_recovery_01` art and its east sourcing
`interaction/success_01`, which is `DORMANT_PENDING_INTERACTION_SUCCESS_CONTRACT`
and must never stand in for parry-success. The action is authored e/w, and the
caller preserves the historical left/right selection (`x < 0 -> w`, otherwise
`e`) as presentation policy.

Failed-parry recovery presents **no** FX beat. The guard contract keeps the
original `parry_01` attempt through recovery, so nothing requests a recovery
animation; `parry_recovery_01/fx` stays published but dormant for a future
explicit contract. The FX decision is extracted as `_present_parry_fx()` and
returns the identity it presented, because asserting it through the whole parry
function proved vacuous — the modular path never reaches recovery today, as no
modular body art exists for that base.

**A correction found while migrating.** The initial plan assumed ranged fire FX
should preserve "no FX" on unauthored sectors. That was wrong: the compatibility
resource has an *unsuffixed* clip, so `AnimationResolver` always resolved
something and FX never rendered nothing. Its unsuffixed clip is the `e` art. The
FX layer therefore needs its own projection table, separate from the weapon
layer's, because their authored sets differ — `fire_01` publishes a weapon strip
for `n` but no fx strip. Blanking those sectors would have been a visible
regression.

Sidearm FX reuses the single authored sector R1 established rather than resolving
its own, so the whole Sidearm stack still cannot disagree with itself.

**Three negative controls verified**: mapping parry-success back to the
mis-published interaction art, reintroducing the runtime SpriteFrames mutation,
and unbinding the renderer each fail the new smoke.

Two existing tests encoded compatibility naming on this renderer and were
corrected: `operator_primary_ranged_modular_fire`'s FX fixture now installs
canonical identities.

#### Historical: the Step-0 stop that preceded this

The renderer was **not** rebound. The mandated Step 0 pass found live consumers
that cannot be canonicalized without an authoring decision, and the packet's own
rule is to stop rather than partially rebind.

**The R1 lesson repeated, larger.** The inventory reported this renderer as
5 sites / 4 active / 0 blockers / READY. Its real surface is **14 sites, 10
blocking** — undercounted roughly threefold. Three mechanisms were invisible to
the three debt patterns, and the inventory now detects all three:

* `runtime_spriteframes_mutation` — `_ensure_operator_critical_hitspark_animation()`
  and `_ensure_paired_execution_animation()` BUILD animations into the renderer's
  `SpriteFrames` at runtime from raw PNG sheets. A shared canonical resource
  cannot accept that: the mutation would leak into every other renderer bound to
  it. Canonical equivalents exist (`critical_hitspark_01` e/w,
  `critical_execution_01` e/s/w, `falcon_reversal_01` e/w), so this is migratable
  work — but it must be done *before* the rebind, not after.
* `candidate_animation_list` — the ranged fire FX layer walks
  `_primary_ranged_fire_candidates(&"fx", …)`, the same mechanism R1 found on the
  weapon layer.
* `constructed_animation_name` — names assembled as `<base>_%s` suffixes.

`_play_modular_parry_fx()` turned out to be dead code: no callers. Its
`AnimationResolver` site is not an active consumer.

**Two mappings I recorded in the evidence pass were wrong, and are corrected.**
Texture provenance in `operator_modular_upper_fx_frames.tres` settles both, the
same method that settled the sidearm question:

* `unarmed_parry_fx` was recorded against `parry_success_01` on name similarity.
  All four variants source `unarmed/defense/parry_01` art, and the directional
  sets match exactly (legacy up/left/right == canonical n/w/e). Moved.
* `unarmed_parry_success_01_fx` was recorded as one mapping. It is not one: its
  `_left` sources `unarmed/attack/parry_recovery_01` fx art and its `_right`
  sources `unarmed/interaction/success_01` fx art — **two semantically different
  actions under one clip name**. The entry is withdrawn.

The tool had faithfully reported both as PROVEN, because the evidence they rested
on was mine and it was wrong. Evidence recorded by hand needs the same
verification as code.

**The blocker.** `unarmed_parry_success_01_fx` is live:
`guard_enter_post_parry_neutral()` calls
`_play_parry_animation(&"unarmed_parry_success_01")`, and the modular body art for
that base exists in the lower/upper compatibility resources, so the FX branch is
reached. Canonicalizing it requires choosing one of:

```text
(a) unarmed/defense/parry_success_01/fx   — exists for e/w, the semantically
                                            obvious action, but NOT what plays today
(b) preserve today's pixels               — parry_recovery_01 for west,
                                            interaction/success_01 for east;
                                            semantically incoherent
(c) no FX for this action                 — a visible regression
```

**A second, smaller question.** `_play_modular_unarmed_parry()` requests
`unarmed_parry_recovery_fx`, which is absent from the compatibility resource, so
parry-recovery FX has **never rendered**. Canonical `parry_recovery_01` fx exists
for e/w. Preserving current behaviour means deliberately leaving authored art
unused; enabling it is a visible change. Both questions are recorded as
`open_authoring_question` on their reachability rows.

Everything else on this renderer is migratable once those are answered: fast-strike
FX (canonical coverage is all eight sectors), field-patch FX, sidearm draw/fire FX
(reusing R1's authored sector), ranged fire FX, and the two runtime-built cosmetic
families.

**R1 re-verified.** Under the new stricter detectors `modular_sidearm_sprite`
still reports `CANONICAL` with zero sites, so R1's cutover holds against
mechanisms it was not originally measured by.

### C2a-R3 — canonical body pair — STOPPED at the exhaustiveness pass

`modular_lower_body_sprite` and `modular_upper_body_sprite` were **not** rebound.
Section 0 required proving the complete consumer surface first, and it found two
live mappings that cannot be canonicalized without an authoring decision, plus
three places where the packet's stated premises are contradicted by the authored
art. Nothing in `game/` changed.

#### The reported site count was a floor again

The evidence reported 13 active sites for the lower body and 15 for the upper.
The real surface is **273 lines across 54 functions**. Two mechanism classes were
invisible to the detector and are now detected:

* `runtime_spriteframes_fork` — `_install_melee_posture_catalog_frames()` replaces
  BOTH body `SpriteFrames` with `duplicate(true)` deep copies. This is how a
  renderer opts out of sharing *before* mutating, so it hides a mutation that
  `runtime_spriteframes_mutation` alone never flags. Against the shared canonical
  resource it would fork 557 animations twice per Operator instance.
* `secondary_animation_database` — that same function then copies clips in from
  `operator_animation_catalog_frames.tres`, a second animation database, rather
  than reading the one generated runtime SpriteFrames.

With both detectors the body pair reads 16 sites / 4 blocking (lower) and
16 / 3 (upper). `melee_weapon_overlay_sprite` also rose 2 -> 4; it uses the same
catalog machinery and inherits this finding when its own slice runs.

The catalog copy is **provably redundant**: all 24 identities it installs
(`melee_1h/posture/{draw,sheathe,idle_ready,idle_relaxed}_01/{e,w}/{lower,upper}_body`
and `melee_1h/locomotion/{run_01/{e,s,w},walk_01/s}/{lower,upper}_body`) are already
published in `operator_runtime_frames.tres`, and were verified frame-by-frame as
identical in atlas source, region, frame count, per-frame duration, FPS and loop.
The fork, the copy and the second database all retire with the rebind.

#### Proven by evidence, no decision needed

| family | canonical identity | historical projection |
|---|---|---|
| parry windup / parry success (body) | `unarmed/defense/parry_01` | `n->n`, `ne,e,se,s->e`, `sw,w,nw->w` |
| block hold | `unarmed/defense/block_hold_01` | `n,ne,e,se,s->e`, `sw,w,nw->w` |
| block hitreact | `unarmed/defense/block_hit_01` | same e/w split |
| ranged fire, upper | `ranged_2h/cosmetic/fire_01` | authored `n,e,se,sw,w`; `ne,s,nw` played **nothing** |
| field patch | `unarmed/interaction/field_patch_use_01` | `n..s->e`, `sw,w,nw->w` |

The ranged-fire candidate list collapses to a single identity family whose
authored set is exactly R1's `fire_01` weapon table, so the upper body reuses
`_ranged_2h_authored_sector()` rather than growing a third table.

Locomotion projections are proven but **not** layer-symmetric, and two of them
substitute a different *action*, not just a different direction:

* lower `walk_01`: `ne -> idle_01/ne`, `nw -> run_01/nw`
* lower `run_01`: `ne -> idle_01/ne`
* upper `walk_01`: `ne,nw -> walk_01/n`
* upper `idle_01`: `ne -> idle_01/n`

#### Three packet premises the authored art contradicts

1. **Section 2B — parry-success body art does not exist.** `parry_success_01` is
   authored as `fx` only, in `source/` and `runtime/` alike. Every live
   parry-success body clip sources `unarmed/defense/parry_01`. The section's
   E/W-only policy would also drop the authored **north** parry pose, which
   `unarmed_parry_success_up` renders today.
2. **Section 2A — the profile is `unarmed`,** not `shared`: the identity is
   `unarmed/locomotion/idle_hitreact_01`, authored `n,s` on both layers. The
   prescribed policy matches today's behavior except for `e`/`w`, which are an
   exact tie between `n` and `s` and currently stick to the previous sector.
   Retiring the memory makes them always `s`; that is the one visible delta.
3. **Sections 1 and 8 — "resolve the sector once" does not hold for every action.**
   Lower and upper have different authored coverage for `idle_01` (upper has no
   `ne`), `walk_01` (upper has no `ne`/`nw`), `ranged_2h/posture/stance_01` and
   `field_patch_use_01`. A single shared sector would either request a missing
   upper identity or discard an authored lower one. It holds for the sidearm and
   parry beats and is applied there.

#### The two blockers

**B1 — upper-body block-enter art was never published canonically.**
Of 217 playable clips across both compatibility resources, 215 map to a published
canonical identity. The two that do not are the upper body's block-enter:

    unarmed/defense/block_enter_01_legacy_cc318778/e/upper_body   (5 frames)
    unarmed/defense/block_enter_01_legacy_68a274b0/w/upper_body   (5 frames)

They exist only as legacy-named runtime residue. `source/` holds `block_enter_01`
for the **lower** body only (4 frames e/w), so the sync never publishes an upper
strip and `unarmed/defense/block_enter_01/*/upper_body` does not exist. This also
governs guard **exit**, which is block-enter played backwards on the upper body.
Rebinding without resolving it silently removes the upper half of guard enter and
guard exit. Note the layers are already frame-asymmetric here: lower 4f, upper 5f.

**B2 — post-parry-neutral lower west is mis-published.**
`guard_enter_post_parry_neutral()` plays `unarmed_parry_success_01`, which resolves:

| | east side (`n,ne,e,se,s`) | west side (`sw,w,nw`) |
|---|---|---|
| upper | `unarmed/attack/parry_recovery_01/e` | `unarmed/attack/parry_recovery_01/w` |
| lower | `unarmed/attack/parry_recovery_01/e` | `unarmed/interaction/success_01/w` |

One clip name, two different semantic actions, and the layers disagree — the same
shape as the R2 FX defect. Both actions are fully published e/w for both body
layers, so either reading is implementable.


### C2a-T1 — canonical timing preservation (DONE)

R3's exhaustiveness pass found that the canonical spine knew which pixels to play
but not how fast. Operator source art carries `.animation.json` timing sidecars
only sparsely, and `build_operator_runtime_frames.gd` falls back to 12 FPS plus a
loop heuristic without one — while the compatibility resources carry hand-authored
per-clip FPS. Rebinding a renderer therefore preserved pixels and frame counts
while silently retiming the animation, which the preservation contract forbids.

That had already happened twice, in work that was reviewed and accepted:

* **C2a-R1** — `ranged_2h/posture/stance_01/*/weapon` went 8 -> 12 FPS. The
  sidearm ranged-ready stance loop ran 50% fast.
* **C2a-R2** — `unarmed/interaction/field_patch_use_01/*/fx` went 11.2 -> 12 FPS
  and desynchronized from its own body layer, which is still driven at 11.2.

Neither smoke could see it: the paths under test renormalize speed
(`_play_first_available_modular_fire_animation()` sets
`speed_scale = target_fps / source_speed`, and the ranged aim path derives FPS from
frame count over a tuned duration), and these two paths do not. The selection
architecture from R1 and R2 stands; only their timing preservation was defective.

Of 191 canonical identities reachable from the four migrated or pending renderers,
103 already matched, 31 are explicitly renormalized at runtime, and 88 would have
retimed. Publishing **43** sidecars covers all 88, because the pipeline projects a
clock layer's timing onto every sibling with the same frame count; the other 45 are
covered by that projection rather than duplicated. Zero conflicts and zero
inexpressible sibling clocks remain.

Three cross-action mis-publications produced the only timing conflicts, and the R3
decision to stop preserving them dissolved all three. Timing follows the *consumer*,
not the mis-published pixels: `unarmed_walk_up_right` keeps the walk clock even
though it drew idle art. A fourth was found the same way —
`unarmed_fast_windup_lower_up` drew `fast_recovery_01/n`.

`operator_timing_preservation_smoke.gd` is the gate that should have caught R1 and
R2. It compares every compatibility clip against the canonical identity its consumer
resolves to and fails on FPS, loop or per-frame duration drift, and it is verified
against three negative controls: an authored clock regressed to 12 FPS, a flipped
loop, and a changed duration multiplier.

Two structural findings worth carrying forward:

* `operator_animation_catalog.generated.json` accumulates. An identity the manifest
  has no timing for keeps whatever the catalog already held, so deleting a sidecar
  does not revert its clock.
* The clock reaches only siblings with a matching frame count. Seven `full_body`
  and `fx` layers are outside every clock published here and keep the generated
  default; `animated_sprite` owns `full_body`, so its slice must publish them.

No renderer binding changed in T1.


### Recommended sequencing for the next attempt

1. Extend `operator_animation_reachability.json` to record the ten unrecorded
   clips, and trace the 24 variable-argument sites to their callers. The
   inventory reports both sets.
2. Answer the dodge authoring question in item 3.
3. R1 `modular_sidearm_sprite`, R2 `modular_upper_fx_sprite` and R3 the body pair
   are done. Next is C2a-R4, `animated_sprite`, the last of the large renderers —
   the melee and weapon overlays are still compatibility-bound and belong to
   their own later slices. Head and cape are retired, not migrated.
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
gamepad aim and only real mouse movement hands the device back -- *real* meaning a
pointer-motion event, never a change in the world-space mouse coordinate, which
the camera moves on its own. Give `ControllableActor.process_input()` a real
adapter in the **Operator override**, so replay/AI/vehicle drivers have a seam;
the base method stays a no-op `pass`, because it is the interface, not the
implementation. The adapter is not done when an injected frame arrives: it must
carry edges *and* aim, on its own explicit facts rather than by impersonating a
keyboard or a gamepad.

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
