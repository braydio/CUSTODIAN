# TWIN SOLARIA SOLARIUM I ACQUISITION PRESENTATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `twin-solaria-solarium-i-acquisition-presentation`
- Kind: `implementation`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-twin-solaria-route-review-authority, visual-validation-economy-tooling-v1, review-twin-solaria-route-vista-samples-v1`
- Locks: `twin-solaria-runtime, asset-catalog`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual, asset-pipeline`
- Paired review workstream: `review-twin-solaria-solarium-i-acquisition-presentation`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `b1e622dde554bfac88ae73a3b1a578f606027c91`
- Authoring chat: `not-recorded`
- Goal: Implement Twin Solaria Slice E so authorized route-review state drives a readable Solarium I observational-acquisition sequence through the Outbound/Reciprocal Anchors, Echo Drums, Coherence Witnesses, and Acquisition Aperture, while Passage remains physically and mechanically impossible.
- Completion boundary: Done when reviewed Slice D authorization drives one bounded Solarium I presentation state machine, the three planned Asset V2 FX families and route-vista content resolve with exact provenance/registration, warning/shutdown fail closed, presentation never mutates route truth, no traversal/Passage is exposed, and structured runtime/asset evidence plus paired review are green.
- Current measured state: The preserved production composite already contains the golden Resolved Route Vista in the Solarium I crop and canon interprets it as route-candidate observational resolve. The dedicated `twin-solaria-route-vista-samples-v1` slice now owns ingestion/registration of three neutral static destination samples and a reusable `TwinSolariaVistaPresentation`-style content layer. Slice D will own route truth and authorization. This slice owns aperture/instrument presentation and must consume the vista-sample family rather than baking destination imagery into FX.
- Evidence: reviewed Slice D API, reviewed route-vista sample family, Twin Solaria design authority, Asset Pipeline V2 family/catalog truth, current authored layout, visual-validation economy contract, and the paired post-land review packet.
- Task-specific authority: `design/05_levels/TWIN_SOLARIA.md` sections 7–9, 29, 30–32; live Asset Pipeline V2 schemas/tooling; reviewed Slice D route-review API.
- Work surface: Solarium I presentation controller/state mapping, three scoped Asset V2 FX families, Route Vista presentation consumption, focused Twin/asset validation, and directly stale Twin docs.
- Change: Add state-driven Solarium I acquisition presentation; publish the three explicitly planned V2 FX families; stage anchors/witnesses/drums/aperture through candidate, resolve, stable, warning, and shutdown states; add deterministic visual/runtime evidence.
- Preserve: route-review authority decides safety/authorization; existing 2048×1536 layout/plate registration; missing Second Crown; no Passage; no new global route state; no replacement of preserved base plate art; no reference-landmark raster double rendering.
- Non-goals: No cross-map travel; no Passage handoff; no Solarium II reconstruction; no Slice F; no campaign destination UI; no final full-level lighting/audio overhaul; no new Echo Drum raster family unless live review proves procedural presentation insufficient.
- Acceptance: unauthorized/HOLD state cannot fully resolve Solarium I; authorized state performs a bounded industrial acquisition resolve into stable observational vista; reciprocal warning can force fail-closed shutdown; presentation never mutates route truth; no traversal is offered; all new art is Asset Pipeline V2 with exact family/state contracts and true alpha.
- Validation: Run Asset V2 plan/status/doctor and focused presentation-state/interrupt/restore checks first; verify route truth is read-only, run Twin runtime/canon regressions, structured registration/alpha metrics and compact ROI evidence where needed, then changed-file validation and `git diff --check`.

## Asset Pipeline V2 Families

Before creating files, re-read live V2 schema/tool help and use current contracts. The design values below are locked production targets unless the live schema requires a field-format translation.

## Route Vista Content Dependency

Destination imagery is owned separately by:

`twin_solaria_route_vista_samples`

from the reviewed workstream:

`twin-solaria-route-vista-samples-v1`

The aperture FX family must not contain the destination paintings themselves.

The `route_candidate` aperture-FX state is therefore an aperture-field / edge / reveal treatment layered around or over the selected Route Vista sample, not the sample image.

Consume the selected neutral candidate id from the route-review/presentation seam and feed it to the Route Vista presentation independently from the aperture machine state.

### 1. `twin_solaria_acquisition_aperture_fx`

Family metadata:

`custodian/content/metadata/assets/families/twin_solaria_acquisition_aperture_fx.asset.json`

Source-work:

`custodian/asset_drop/source_work/hub/twin_solaria_acquisition_aperture_fx/`

Inbox:

`custodian/asset_drop/inbox/twin_solaria_acquisition_aperture_fx/`

Asset family intent:

- schema: `custodian.asset_family.v2`
- kind: current V2 effect/FX kind
- owner: `twin_solaria_acquisition_aperture_fx`
- runtime domain: `sprites/effects/hub/twin_solaria`
- direction: omni
- mirror: none
- true alpha required
- stable registration on a 1024×1024 canvas

Required states:

| Inbox filename | State | Canvas | Frames | FPS | Loop |
|---|---|---:|---:|---:|---|
| `route_candidate.png` | `route_candidate` | 1024×1024 | 1 | 0/static | no |
| `acquisition_resolve.png` | `acquisition_resolve` | 1024×1024 | 12 | 8 | no |
| `acquisition_stable.png` | `acquisition_stable` | 1024×1024 | 8 | 8 | yes |
| `reciprocity_warning.png` | `reciprocity_warning` | 1024×1024 | 8 | 8 | yes |
| `shutdown.png` | `shutdown` | 1024×1024 | 8 | 10 | no |

### 2. `twin_solaria_anchor_fx`

Family metadata:

`custodian/content/metadata/assets/families/twin_solaria_anchor_fx.asset.json`

Source-work:

`custodian/asset_drop/source_work/hub/twin_solaria_anchor_fx/`

Inbox:

`custodian/asset_drop/inbox/twin_solaria_anchor_fx/`

Family intent:

- schema V2
- effect/FX kind
- runtime domain `sprites/effects/hub/twin_solaria`
- omni
- no mirror
- true alpha
- 256×512 canvas

Required states:

| Inbox filename | State | Frames | FPS | Loop |
|---|---|---:|---:|---|
| `outbound_idle.png` | `outbound_idle` | 6 | 6 | yes |
| `outbound_lock.png` | `outbound_lock` | 8 | 8 | yes |
| `reciprocal_idle.png` | `reciprocal_idle` | 6 | 6 | yes |
| `reciprocal_lock.png` | `reciprocal_lock` | 8 | 8 | yes |
| `reciprocal_warning.png` | `reciprocal_warning` | 8 | 10 | yes |

### 3. `twin_solaria_coherence_witness_fx`

Family metadata:

`custodian/content/metadata/assets/families/twin_solaria_coherence_witness_fx.asset.json`

Source-work:

`custodian/asset_drop/source_work/hub/twin_solaria_coherence_witness_fx/`

Inbox:

`custodian/asset_drop/inbox/twin_solaria_coherence_witness_fx/`

Family intent:

- schema V2
- effect/FX kind
- runtime domain `sprites/effects/hub/twin_solaria`
- omni
- no mirror
- true alpha
- 64×96 canvas

Required states:

| Inbox filename | State | Frames | FPS | Loop |
|---|---|---:|---:|---|
| `consensus.png` | `consensus` | 6 | 4 | yes |
| `disagreement.png` | `disagreement` | 8 | 8 | yes |
| `dropout.png` | `dropout` | 6 | 10 | no |

### Asset creation rule

If new/generated source art is required, preserve editable/generation source under the source-work paths above and place only normalized runtime-intake PNGs under the exact inbox paths above.

Do not hand-place generated runtime art. Run current Asset V2 plan/dry-run/ingest/status/doctor and bind published outputs explicitly.

## Aperture Presentation

The preserved Solarium I plate already visually contains a golden candidate vista.

Therefore baseline/dormant presentation needs a non-authoritative aperture cover/mask or equivalent presentation layer so the level does not permanently appear fully resolved.

State behavior:

- DORMANT / HOME work: aperture masked/dim; no route signal.
- ROUTE CANDIDATE: select a Route Vista sample and show it through the reviewed `candidate_weak` presentation; aperture FX adds field/edge treatment only.
- RECIPROCITY REVIEW: selected vista content remains independent; weak/conflicting Route Vista presentation may persist while reciprocal anchor/witnesses communicate safety state.
- HOLD: freeze at weak candidate, no full resolve.
- ABORT: controlled shutdown to masked/dim.
- AUTHORIZE ACQUISITION: play `acquisition_resolve`.
- ACQUISITION STABLE: show the selected Route Vista sample in resolved presentation plus restrained aperture-edge motion.
- reciprocal warning during stable state: warning presentation, then fail-closed shutdown if route-review authority requests it.

The mask/cover is presentation only. It may not change collision, route state, or candidate truth.

## Instrument Presentation

### Outbound Anchor

Clean narrow lock. Stable outbound is not safety proof.

### Reciprocal Anchor

Can become visibly more alarming than Outbound. Multiple/nonconvergent states must read as unsafe and cannot authorize.

### Coherence Witnesses

- consensus: synchronized dim pulse;
- disagreement: asynchronous pulse;
- dropout: bounded loss then dark;
- shutdown: dark cascade using state timing, no new route mutation.

### Echo Drums

For V1 use restrained procedural/world presentation at the existing marker positions:

- West: controlled emitted diagnostic pulse;
- East: returned-response pulse, delay, duplicate or warning pattern driven by snapshot.

Do not create an unplanned raster family unless the implementation cannot meet readability with existing/procedural presentation. If a new family becomes necessary, stop and add a V2 family contract to this packet before creating art.

## Architecture

Create a presentation owner that subscribes to/read-polls a read-only route-review snapshot.

It may request no route decisions.

No presentation callback can set:

- reciprocity result;
- finding;
- authorization;
- candidate evidence.

Use explicit state transitions and generation/token cancellation for one-shots so abort/warning cannot leave stale animation completion callbacks applying a later state.

## Failure / Interrupt Behavior

Prove:

- ABORT during resolve cancels pending completion and returns masked;
- HOLD never plays full resolve;
- route-review warning during stable forces warning/shutdown without modifying route truth;
- leaving/reloading level restores presentation from authoritative snapshot rather than replaying resolve incorrectly;
- repeated stable snapshots do not restart loops/one-shots every frame.

## Focused Validation

Add `twin_solaria_acquisition_presentation_smoke.gd`.

Cover:

1. dormant mask;
2. candidate weak state;
3. HOLD no full resolve;
4. AUTHORIZE is required for resolve;
5. resolve → stable;
6. abort during resolve cancels stale completion;
7. warning → fail-closed shutdown;
8. presentation cannot mutate route-review authority;
9. restore maps snapshot to correct visual state without replay side effects;
10. no level exit/Passage node exists;
11. V2 family state/dimension/frame/FPS/alpha contracts;
12. exact marker registration for anchors/witness presentation;
13. existing Twin runtime/forensic/route-review/canon smokes green;
14. reusable presentation probes report aperture/anchor/witness visibility, alpha, bounds/registration, animation/frame/progress, and route-authority snapshot immutability for dormant/candidate/resolve/stable/warning-shutdown;
15. forward/restore/repeated-snapshot paths produce equivalent steady presentation state without relying on screenshot inspection.

## Presentation Evidence Economy

Use the reusable visual-validation/Moment Forge probes as the primary acceptance
surface. The five requested presentation states do not require five routine
full-screen visual inspections.

Run the acquisition scenario first in `capture-mode none` and record:

- route-review authoritative snapshot before and after each presentation state;
- aperture/anchor/witness node identity, visibility, alpha, world/screen bounds,
  z-order, current animation/frame/progress, and expected registration;
- dormant mask present, candidate weak, HOLD non-resolved, AUTHORIZE resolve,
  stable loop, warning/shutdown, and ABORT cancellation;
- repeated stable snapshots do not restart one-shots;
- restore maps directly to the correct steady presentation state;
- no Passage/level-exit node appears and presentation never mutates route truth;
- Asset V2 family/state/dimension/frame/FPS/alpha contracts remain exact.

If actual rendered pixels remain necessary after those checks are green, run one
evidence-mode pass and generate a compact aperture/instrument ROI contact sheet
for:

- dormant;
- route candidate;
- acquisition resolve midpoint;
- stable vista;
- reciprocal warning/shutdown.

Use code-based ROI metrics for clipping, registration, duplicate rendering, alpha
coverage, and unexpected Solarium-II content. Do not ask Codex to inspect five
full-screen captures as a normal acceptance step. Inspect a tight ROI manually
only when a metric is ambiguous/failing or when a subjective FX/art-direction
decision remains.

Human baseline approval is never automatic. Subjective FX intensity, beauty,
composition, and game-feel preference are human-owned; objective alignment,
clipping, duplication, state correspondence, alpha, and Second Crown absence
should be settled from structured evidence first.

## Documentation

Update `TWIN_SOLARIA.md`, CURRENT_STATE, FILE_INDEX, validation recipes, and required-assets registry only as actual implementation/art truth changes.

Any unfinished art state must remain explicitly tracked in the requirement registry rather than hidden behind procedural fallback.

## Completion

Archive packet, keep paired review active, write
`TWIN_SOLARIA_SOLARIUM_I_ACQUISITION_PRESENTATION_CLAUDE_SUMMARY.md`, record Asset V2 jobs/family status and visual evidence, then land normally.

## Handoff

- Next action: after review, stop. Slice F Passage restoration requires a separate narrative/story authorization and is not queued.
- Best starting files: reviewed Slice D authority, Twin Solaria layout/presentation roots, Asset V2 family schemas/tooling, Moment Forge.
- Blockers or open questions: blocked intentionally on reviewed Slice D.
