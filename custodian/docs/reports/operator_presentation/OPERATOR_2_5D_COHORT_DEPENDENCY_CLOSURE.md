# Operator 2.5D Cohort Dependency Closure

- Report schema: `custodian.operator_2_5d_cohort_dependency_closure.v1`
- Investigated main: `7e8049e96baa70630f9d66ed5520fbed83f998a3`
- Source evidence digest set: `6861558dcaaedf44458a75e0c4df205244e7c1eeb49b92d2ca71e0cf4ae469b0`
- Candidate: `unarmed_neutral_motion_v1` — 7 families / 56 direction slots
- Authoring workspace: `AVAILABLE`; editable idle directions: `8`; effective receipts: `0`
- Authoring checkout: `DIRTY`; behind origin/main: `76`; working tree evidence is preserved and read-only
- Release: **NOT_RELEASE_ELIGIBLE**

## Candidate Families

| Family | Priority | Layers | Directions | Frames / loop / FPS | Editable | Runtime directions | Closure |
|---|---:|---|---:|---|---:|---:|---|
| `unarmed/posture/idle_relaxed_01` | P0 | full_body | 8 | 15 / True / None | 8 | 2 | OPEN |
| `unarmed/posture/idle_ready_01` | P1 | full_body | 8 | None / None / None | 0 | 2 | OPEN |
| `unarmed/transition/relaxed_to_ready_01` | P1 | full_body | 8 | None / None / None | 0 | 2 | OPEN |
| `unarmed/transition/ready_to_relaxed_01` | P1 | full_body | 8 | None / None / None | 0 | 2 | OPEN |
| `unarmed/locomotion/idle_01` | P1 | full_body | 8 | None / None / None | 0 | 8 | OPEN |
| `unarmed/locomotion/walk_01` | P1 | full_body | 8 | None / None / None | 0 | 8 | OPEN |
| `unarmed/locomotion/run_01` | P1 | full_body | 8 | None / None / None | 0 | 8 | OPEN |

## Current Authoring Evidence

The eight relaxed-idle Aseprite documents, source strips, and Source Sessions match the correction receipt hashes. Their manifests retain a physical 15 × 125 ms document clock and 8 FPS preview, with `timing_authority=false`; none has a current effective receipt or publication. The other six families have null frame, loop, and FPS contracts.

## Runtime Composition and Edges

The proposed art is eight-direction `full_body`. Current unarmed posture instead requires `lower_body + upper_body` and projects requested headings to east/west. Locomotion normally prefers modular layers. The selector and runtime manifest are generation-neutral, so current semantic rows prove legacy availability only.

| Edge | Trigger | Consumer | State | Evidence |
|---|---|---|---|---|
| `relaxed_idle → ready_idle` | engagement becomes active | `operator._update_unarmed_presentation_posture -> UnarmedPosturePresentation.advance` | **OPEN** | `custodian/game/actors/operator/operator.gd::operator._update_unarmed_presentation_posture`; `custodian/game/actors/operator/presentation/unarmed_posture_presentation.gd::UnarmedPosturePresentation.advance` |
| `ready_idle → relaxed_idle` | engagement quiets | `operator._update_unarmed_presentation_posture -> UnarmedPosturePresentation.advance` | **OPEN** | `custodian/game/actors/operator/operator.gd::operator._update_unarmed_presentation_posture`; `custodian/game/actors/operator/presentation/unarmed_posture_presentation.gd::UnarmedPosturePresentation.advance` |
| `relaxed_idle → locomotion_idle` | movement begins below walk threshold | `operator._update_animation` | **OPEN** | `custodian/game/actors/operator/operator.gd::operator._update_animation` |
| `locomotion_idle → walk` | movement crosses walk threshold | `operator._update_animation -> operator._sync_modular_locomotion_layers` | **OPEN** | `custodian/game/actors/operator/operator.gd::operator._update_animation`; `custodian/game/actors/operator/operator.gd::operator._sync_modular_locomotion_layers` |
| `walk → run` | sprint input / run threshold | `operator._update_animation -> operator._sync_modular_locomotion_layers` | **OPEN** | `custodian/game/actors/operator/operator.gd::operator._update_animation`; `custodian/game/actors/operator/operator.gd::operator._sync_modular_locomotion_layers` |
| `run → walk` | sprint ends | `operator._update_animation -> operator._sync_modular_locomotion_layers` | **OPEN** | `custodian/game/actors/operator/operator.gd::operator._update_animation`; `custodian/game/actors/operator/operator.gd::operator._sync_modular_locomotion_layers` |
| `posture_or_locomotion → guard_or_parry` | guard/parry action acquires body | `OperatorBodyPresenter + operator guard/parry presentation` | **OPEN** | UNKNOWN: guard/parry acquisition and return owners are not resolved to edge-specific source evidence in this audit |
| `posture_or_locomotion → dodge` | dodge charge/flow preempts body | `operator dodge presentation / OperatorBodyPresenter` | **OPEN** | UNKNOWN: dodge acquisition and return owners are not resolved to edge-specific source evidence in this audit |
| `posture_or_locomotion → melee_action` | melee attack preempts body | `operator melee presentation / OperatorBodyPresenter` | **OPEN** | UNKNOWN: melee acquisition and return owners are not resolved to edge-specific source evidence in this audit |
| `posture_or_locomotion → ranged_action` | ranged aim/fire preempts body | `operator ranged presentation / OperatorBodyPresenter` | **OPEN** | UNKNOWN: ranged acquisition and return owners are not resolved to edge-specific source evidence in this audit |
| `unarmed → equipped_or_sheathed` | equip/sheathe changes profile and body owner | `operator.start_equip_weapon_presentation / melee and ranged posture sync` | **OPEN** | UNKNOWN: equip/sheathe edge ownership is not resolved to edge-specific source evidence in this audit |
| `action_owner → neutral_settle` | action completion returns neutral body | `OperatorPresentationController completion clock + operator posture settle` | **OPEN** | UNKNOWN: action completion's complete presentation edge is not resolved to edge-specific source evidence in this audit |

## Blocking Gaps

- Only 8/56 candidate directions are editable; the other 48 have no canonical art or resolved frame/loop/FPS contract.
- All eight idle documents retain 8 FPS / 125 ms as preview timing with timing_authority=false; no authoritative FPS is selected.
- No current effective review/sandbox receipts, verified candidate directions/families, or published candidate directions exist.
- Existing posture requires modular lower_body+upper_body and east/west projection; 2.5D candidate requires eight-direction full_body.
- Runtime semantic identities are generation-neutral; no proven generation-aware single-body presentation owner prevents 96px modular art from reappearing.
- Guard/parry, dodge, melee, ranged, equip/sheathe, FX/socket, and terminal completion edges include identities outside the proposed seven families.

## Recommended Next Steps

1. Design one generation-coherent body presentation seam under OperatorPresentationController/OperatorBodyPresenter; preserve selector and single SpriteFrames authority.
2. Specify exact incoming/outgoing transitions and settle behavior for posture, idle/walk/run, guard/parry, dodge, melee, ranged, equip/sheathe, and terminal actions; include weapon sockets and FX ownership.
3. Only after the user chooses the actual cohort, author the missing 48+ directions and resolve physical frame/loop/timing contracts for every included family.
4. Select idle timing through the authoritative timing-intent workflow; then obtain current per-direction QA, human disposition where required, sandbox verification, and effective receipts.
5. Refresh WB25-6 planning from this report and the resulting human scope/timing decisions; keep production generation legacy until explicit closed-cohort release authorization and rollback proof exist.

## Invalidation

Regenerate this report after any source SHA changes in the JSON `investigation.source_evidence_sha256` map, any plan/reachability/presenter/selector/runtime-manifest/catalog/SpriteFrames change, or any Workbench/receipt change. A missing external workspace is `UNAVAILABLE`; it is never interpreted as zero authored directions or proof of absence.
