# Agent Task Packets

Last updated: 2026-10-02

Task packets are optional, task-scoped risk-control and handoff files for CUSTODIAN agents.


## Active Archive Resolve Presentation Series

Design authority: `../../../design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md`.

The three implementation packets are intentionally pre-authored and
refresh-gated. They remain `blocked/manual` until their named predecessor has
landed and the packet has been re-derived from live main; each packet contains a
temporary refresh section that must be deleted during that refresh before it may
become `ready`.

- `PROCGEN_ARCHIVE_RESOLVE_PRESENTATION_SPINE.md` — AR1, presentation-only
  request/commit/unload spine and flat diagnostic veil; refresh after reviewed
  M6/MR6.
- `PROCGEN_ARCHIVE_RESOLVE_SHADER.md` — AR2, locked graphite/dither +
  restrained brass/amber Archive Resolve shader; refresh after AR1.
- `PROCGEN_ARCHIVE_RESOLVE_SEMANTIC_ECHO.md` — AR3, bounded semantic pre-echo,
  spawn resolve, and shortened reacquisition; refresh after AR2.

The post-MR6 ProcGenTilemap rewrite packets carry temporary preservation guards
so extraction/contraction work cannot move or absorb the reveal seams before the
AR packet set is refreshed.

## Active Persistent Recovery Series

- `CUSTODIAN_DEATH_HANDOFF_FOUNDATION.md` — R1 of the expected 8-packet persistent recovery/armament-registration implementation series. It removes ordinary Operator death consequence ownership from the actor, resolves the live CampaignSession exactly once, and intentionally retains current Game Over only as the R1 compatibility fallback.
- Program tracker: `../../../design/02_features/operator/PERSISTENT_RECOVERY_IMPLEMENTATION_ROADMAP.md`.
- Design authority: `../../../design/02_features/operator/PERSISTENT_RECOVERY_AND_ARMAMENT_REGISTRATION.md`.
- Only R1 is authored at program start. Per the roadmap, author each later packet against the landed live surface of its predecessor rather than freezing speculative runtime contracts up front.

## Active Non-Player Actor Runtime Refactor Series

- Program tracker / architecture authority: `../../../design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md`.
- Expected program size: 11 implementation packets spanning standard combat-agent decomplexification, then commanded allies, fauna, encounter/social NPCs, static autonomous agents, and final compatibility cleanup.
- Starter packets authored against `main@02ca0025b8`:
  - `ENEMY_MARINE_DASH_ABILITY_EXTRACTION.md` — NPA-1, ready/auto, no dependency.
  - `ENEMY_SAVAGE_POUNCE_ABILITY_EXTRACTION.md` — NPA-2, ready/auto, depends on NPA-1.
  - `ENEMY_SAVAGE_CHAIN_ABILITY_EXTRACTION.md` — NPA-3, ready/auto, depends on NPA-2.
- Author NPA-4+ against the landed live surface of predecessors rather than freezing speculative shared actor APIs. The target is composition over six actor families, not a universal NPC superclass.

## Cross-cutting Stealth Awareness Planning

Design authority: `../../../design/02_features/stealth/STEALTH_PERCEPTION_AND_ALARM_SYSTEM.md`.

- `STEALTH_PERCEPTION_FOUNDATION.md` - P0 draft/manual S0/S1 packet for the typed NoiseEvent repair and shared Enemy + Vaultwing acoustic observation seam.
- `VAULTWING_RUNTIME_HARDENING.md` - P1 draft/manual dependent cleanup for fixed-step bonding, restore reconciliation, allegiance-sensitive damage compatibility, and Vaultwing-local residue after hearing has moved to shared stealth ownership.
- Both remain intentionally non-claimable drafts until the stealth design boundary is accepted for implementation.

## Selection

- Skip packets for narrow, low-risk, single-session work.
- `../AGENT_TASK_PACKET_TEMPLATE.md` is the canonical authoring specification for new packets. New packets use `Packet schema: custodian.task_packet.v2`.
- Use the compact template when scope, constraints, acceptance, evidence, or deferred work needs a durable record.
- Add full-packet sections only for high-risk, multi-session, architecture, ownership, migration, or substantial handoff work.
- Do not create a packet merely because several files change.

## Workflow

1. Decide whether a packet adds enough value to justify maintaining it.
2. If so, copy `../AGENT_TASK_PACKET_TEMPLATE.md` into this folder.
3. Rename it after the task in uppercase snake case, for example `VALIDATION_RECIPES.md`.
4. Review current `origin/main`, fill the V2 contract fields, and delete unused optional expansion sections.
5. Do not set `ready` until the completion boundary, evidence, work surface, acceptance, validation, dependencies/locks, and review intent are implementation-ready.
6. Keep the packet current when scope, blockers, acceptance, validation, or deferred work materially changes.
7. Before `complete`, add the structured `Execution Feedback` receipt and mirror it in the required closing summary.
8. Mark it `complete` only after implementation, required docs updates, feasible validation, feedback, and completion notes are done.

## V2 Packet Contract

New packets use `Packet schema: custodian.task_packet.v2`. Legacy packets
without a schema remain valid and are not bulk-migrated.

A ready V2 packet must carry enough live evidence and scope control for a fresh
agent to execute it without reconstructing intent from chat history. At minimum
it records the reviewed main SHA, coherent completion boundary, measured current
state, concrete evidence, task-specific authorities, work surface, change,
preservation/non-goals, measurable acceptance, focused validation, and deferred
work. The template's Authoring Quality Gate is the canonical checklist.

A packet should reference technical truth already owned by code/data/schema
rather than copying it. Packet text owns the task closure contract, not duplicate
runtime configuration.

## Execution Feedback

Every V2 packet gets a compact process receipt before completion:

```text
Feedback schema: custodian.task_feedback.v1
Outcome: success | partial | blocked
Friction severity: none | low | medium | high
What went wrong
Root cause / contributing factors
Prevention / pipeline improvement
Tooling / docs drift discovered
Follow-up
What worked (optional)
```

The useful signal is failure/friction and prevention. "What worked" may be one
short line or omitted.

If a repeatable medium/high-severity workflow issue is found, either fix the
small safe correction in the current scope or name/create a follow-up before the
packet becomes complete. The required closing summary mirrors the same fields so
unpacketed tasks also leave process feedback.

## Dispatch

Packets are manual by default. Add `Dispatch: auto` only when the ready packet
is safe for a Codex terminal to claim without additional human selection.
`dispatch.py status` reads packet truth from fetched `origin/main`; use
`dispatch.py claim-next --agent <agent-id>` (for example `--agent claude` or
`--agent codex`) to claim the highest-priority eligible auto packet, or
`dispatch.py claim <workstream-id> --agent <agent-id>` for explicit selection
(including manual packets). Omitting `--agent` falls back to the
`CUSTODIAN_AGENT_ID` environment variable, then a neutral `unspecified` —
never a silently assumed agent brand. Initial claims and direct starts share
unique remote Git claims and per-workstream local mutexes so separate clones
cannot acquire the same task; interrupted
claims require explicit operator recovery. `Priority` is `P0`–`P3` (default `P2`),
`Depends on` lists workstream IDs that must be complete and archived on main,
and `Locks` lists narrow contention IDs. A missing `Dispatch` remains manual.
Claims create/resume exactly one existing `agent/<id>` workstream and do not
edit packet state on main; normal lifecycle progression and archival happen
on the task branch. A successful claim's `CLAIMED` banner and
`CUSTODIAN_DISPATCH_RESULT_JSON:{...}` line are the assignment authority; if
that output is lost, recover it read-only with `dispatch.py last-claim` (or
`--json`) rather than inferring ownership from worktree/branch activity.
Continuous workers and cross-machine leases are deferred.

## Paired Review And Correction

Independent post-land review is opt-in per packet, decided when the
implementation packet is created. It uses ordinary dispatcher primitives
(`Dispatch`, `Depends on`, `Locks`) rather than a second scheduler, and
happens after validated implementation already landed on `main` — it is never
a `workstream.py finish` blocker.

- Declare `Review: auto` on the implementation packet and create a paired
  review packet from `AGENT_REVIEW_PACKET_TEMPLATE.md` on `main` in the same
  change. The review packet declares `Kind: review`, `Review: none`,
  `Depends on: <implementation-id>`, and `Review target workstream:
  <implementation-id>`, `Review target packet:
  custodian/docs/ai_context/task_packets/archived/<implementation-packet-filename>`,
  `Status: ready`, and `Dispatch: auto`.
- `dispatch.py`'s review-pairing consistency guard
  (`custodian/tools/agent/validate_review_pairing.py`) fails closed for any
  active `Review: auto` packet whose pair is missing, wrong `Kind`, wrong
  `Review`, not ready or auto-dispatchable, or whose dependency/target
  workstream/canonical archived target-packet path does not match. The packet
  path must identify the exact implementation packet filename under the
  canonical `archived/` directory; missing and traversal paths are rejected.
  Historical packets that omit review metadata (`Review: none`, the default)
  are never required to pair.
- The review becomes dispatcher-eligible once its implementation dependency
  is `complete` and archived, exactly like any other dependency — no new
  eligibility mechanism.
- A reviewer works from fresh `origin/main` in its own workstream, never
  modifies reviewed implementation/runtime code, and appends a durable `##
  Independent Review` receipt to the archived implementation packet:

  ```md
  ## Independent Review

  - Status: `pending | passed | findings | human_required`
  - Review workstream: `review-...`
  - Reviewed on main: `<short SHA/current target>`
  - Review modes: `...`
  - Blocking defects: `N`
  - Material evidence gaps: `N`
  - Non-blocking issues: `N`
  - Optional improvements: `N`
  - Correction finding IDs: `R0-01, ... | none`
  - Next-slice finding IDs: `... | none`
  - Human-decision finding IDs: `... | none`
  - Detailed review summary: `<reviewer closing-summary path>`
  - Follow-up workstream: `none | <correction-id>`
  ```

- Each finding has a stable cycle-scoped ID (`R<cycle>-<NN>`), class
  (`blocking_defect`, `evidence_gap`, `non_blocking_issue`,
  `optional_improvement`), domain (`implementation`, `pipeline`), affected
  acceptance, evidence, disposition (`correction`, `next_slice`, `deferred`,
  `human_required`, `no_action`), and rationale. Re-review retains an existing
  ID when reporting `fixed`, `unresolved`, or `regressed`; new findings use the
  current cycle's next ID.
- Correction threshold: confirmed acceptance/correctness defects and evidence
  gaps that prevent confidence in required acceptance become correction work.
  Other evidence gaps, non-blocking issues, and optional improvements are
  recorded for next-slice/deferred unless separately justified. Subjective
  design, canon, art-direction, or game-feel decisions use `human_required`.
  Do not turn taste, speculative optimization, or cleanup into a correction.
- Implementation findings stay separate from pipeline/process findings.
  Record the latter through `custodian.task_feedback.v1`; fix a small safe
  repeatable workflow problem in-scope or name a follow-up for medium/high
  severity.
- Use `AGENT_CORRECTION_PACKET_TEMPLATE.md` for correction work. It records a
  narrow delta against exact finding IDs and affected acceptance; it does not
  repeat the original feature design. Its paired review uses the ordinary
  finite review-cycle mechanism.
- A paired post-land review packet must include the bounded `TASK OVERRIDE:`
  that authorizes staging, committing, and pushing only its durable review
  receipt, required closing summary, review-packet lifecycle/archive metadata,
  and bounded correction/re-review packets. It must explicitly forbid editing
  the reviewed implementation and unrelated work. Dispatcher validation
  rejects a missing or malformed override before claim. A clean or
  non-blocking-only review autonomously commits, pushes, and finishes these
  authorized artifacts; it does not stop for routine user landing approval.
  Only `human_required` pauses for a human decision. Truly ad hoc/read-only
  reviews outside a paired review workstream retain the ordinary review-only
  no-stage/no-commit/no-push rule unless their task explicitly says otherwise.
- Before an auto packet is claimable, every explicit validation script path in
  its `Validation` field must resolve to a live repository entrypoint. A stale
  path blocks claim and reports the exact path plus the nearest replacement
  when one can be identified. This is structural path checking, not command or
  semantic validation.
- Validation paths may be written as `custodian/tools/...`, `res://tools/...`,
  or `tools/...`. The last form prefers a matching root `tools/` entrypoint and
  falls back to `custodian/tools/`. Describe implementation-created future
  smoke scripts generically until they exist, then add their exact live path
  to the packet before closeout.

- Blocking findings scaffold `<implementation-id>-review-corrections-<n>.md`
  (`Kind: correction`, `Review: auto`) plus its own paired
  `REVIEW_..._REVIEW_CORRECTIONS_<n>.md` before the review workstream lands —
  an ordinary `Review: auto` pair like any other, so the same consistency
  guard covers it. `Review cycle` increments each correction round; cycle 0 is
  the original review. At `Max automatic review cycles` (default `2`) with
  findings still blocking, the reviewer sets the receipt to `human_required`
  instead of generating another automatic correction, and may add a
  `Dispatch: manual` decision packet.
- Subjective calls (visual baselines, art direction, unresolved design
  interpretation) are never auto-approved; the reviewer finishes technical
  review, sets `human_required`, and states the exact decision needed.

Manual conversational second-pass requests use the same finding classes,
evidence, dispositions, and correction threshold. Outside a paired independent
review workstream, repository patch-first rules still apply: a small, safe,
obvious correction may be patched directly. Inside a paired review, preserve
independence and create the narrow correction workstream instead. Prefer
rolling non-blocking improvements into the next real feature slice or deferred
work over extending the correction loop.

## Ownership

- Reuse a packet only when it is scoped to the current task.
- Create a new packet for a different task, even if related files overlap.
- Do not update another agent's in-progress packet unless the user asks or that packet is explicitly the active task surface.
- Set `Agent/session` in new packets with a stable handle, such as `Codex 2026-05-03T11:xx`.
- Update `Last updated` whenever a packet changes.

## Archive

Completed packets are moved to `archived/`. They are preserved for historical reference but are no longer active task surfaces.

For implementation workstreams, set the packet's `Workstream` field to the
stable kebab-case ID used by `agent/<workstream-id>`. Before
`workstream.py finish`, an associated packet must be marked `complete`, moved
under `archived/`, and removed from the `In Progress` or `Recently Complete
(awaiting archive)` index sections. V2 packets must also contain a completed
`Execution Feedback` receipt. Finish enforces packet cleanup so it cannot be
lost when the ephemeral worktree is removed.

## Active Packets

### Procgen Runtime Optimization V1

- Canonical dependency tracker: `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`. Workstream identities are stable, but execution readiness is evidence-gated. A packet is `ready/auto` only when its current measured state and implementation surface exist on live main; architecture-dependent downstream packets stay `blocked/manual` and are refreshed in place after the named predecessor/review lands.
- **Runtime/streaming:** M4/MR4 and M5/MR5 are complete; M6 is landed. Cycle-0 MR6 completed with one blocking defect (`R0-01`: eviction-triggered presentation flush bypasses reveal coalescing) and four material proof gaps (`R0-02`..`R0-05`). `PROCGEN_DISTANT_CHUNK_UNLOAD_REVIEW_CORRECTIONS_1.md` is the active bounded correction packet (`ready/manual`) and `REVIEW_PROCGEN_DISTANT_CHUNK_UNLOAD_REVIEW_CORRECTIONS_1.md` is its cycle-1 paired re-review (`ready/auto`). S7 stays open and no downstream packet may treat cycle-0 MR6 as approval.
- **Post-M6 world presentation:** `PROCGEN_REGION_FRAME_PRESENTATION_FOUNDATION.md` (RF1) is fully re-derived and `ready/auto`, dependency-gated on the clean cycle-1 M6 re-review. Its paired `REVIEW_PROCGEN_REGION_FRAME_PRESENTATION_FOUNDATION.md` is pre-authored. `PROCGEN_ALPINE_PLATEAU_UNDERLAY_ASSETS.md` remains blocked behind RF1 review + six approved 1536×1024 source images. Archive Resolve AR1 remains blocked/manual behind the same cycle-1 re-review and still needs its final seam refresh before dispatch; AR2/AR3 remain refresh-gated behind AR1/AR2.
- **Placement:** P1 `CONTRACT_WORLD_PLACEMENT_FOUNDATION.md` has landed `WorldPlacementContext` as the accepted-world read seam while leaving placement policies in `ContractWorldLoader`. `REVIEW_CONTRACT_WORLD_PLACEMENT_FOUNDATION.md` (PR1) is now the next review gate and must pass before resource, vehicle, relay, encounter, or ingress extraction; those packets remain serialized by the `contract-world-loader` lock. `CONTRACT_WORLD_LOADER_CONTRACTION.md` (P7) remains blocked/manual until P2-P6 land, then must be re-derived from the surviving loader.
- **ProcGen decomplexification:** D1 `PROCGEN_ROAD_AUTHORITY_EXTRACTION.md`, D2 `PROCGEN_AUTHORED_CLAIM_REGISTRY_EXTRACTION.md`, and D3 `PROCGEN_GENERATION_STATE_EXTRACTION.md` now depend on G5 + `review-procgen-distant-chunk-unload-review-corrections-1`. They remain blocked/manual because each still requires its own post-review live inventory refresh before it may become executable.
- **GenerationGrid:** `PROCGEN_GENERATION_DATA_MODEL_AUDIT.md` / XR1 remain the first executable post-D audit. `PROCGEN_GENERATION_GRID_FOUNDATION.md` is blocked/manual until XR1 defines the real minimum grid seam. `PROCGEN_GENERATION_GRID_MIGRATION_SERIES_AUTHORING.md` is blocked/manual until XR2. Their paired reviews remain dependency-gated. `PROCGEN_TILEMAP_FACADE_CONTRACTION.md` stays hard-blocked until X3 authors and the generated migration DAG reaches a concrete final reviewed convergence workstream.
- **Render/soak:** `PROCGEN_RENDER_ATTRIBUTION_V1.md` remains the post-D4/P7 measurement slice and must re-inventory live presentation owners at execution. `PROCGEN_RENDER_LOAD_CONSOLIDATION.md` is blocked/manual until attribution identifies the actual safe target. `PROCGEN_PERFORMANCE_SOAK_V1.md`, `REVIEW_PROCGEN_RUNTIME_OPTIMIZATION_SERIES_V1.md`, and `PROCGEN_RUNTIME_OPTIMIZATION_V2_SERIES_AUTHORING.md` remain dependency-gated end-of-series work; A1 now carries the same refresh-gate discipline rather than requiring speculative future packets to be ready up front.

### Ready / Auto Dispatch

- `HUB_FIRST_SET_BLOCKOUT_V1.md` — P1 runtime-ready Hub first-set blockout from South Reach through Ashen Forum, Sepulcher loop, Archive/Crown Transfer branch, and Muster Court/Continuity Port deployment wing; spatial only, no world transitions.
- `REVIEW_HUB_FIRST_SET_BLOCKOUT_V1.md` — paired independent review of first-set geometry, navigation, Road presentation reuse, inert handoff markers, and human blockout overview approval.
- `TWIN_SOLARIA_ROUTE_VISTA_SAMPLES_V1.md` — P1 first-pass Solarium I Route Vista sample ingest/presentation: three neutral V2 candidate contents from the new archway-view drop, exact 465×280 registration, playtest sampler, and human capture review.
- `REVIEW_TWIN_SOLARIA_ROUTE_VISTA_SAMPLES_V1.md` — paired independent review of vista provenance, normalization, registration, presentation ownership, and recorded human approval.
- `AGENT_VALIDATION_GATE_DRIFT_REPAIR.md` — P0 repository gate repair: remove the expired LFS/procgen workflow assumption, normalize valid `res://tools` / project-root validation paths through the shared packet contract, preserve fail-closed missing-script checks, and clear the current eight false-positive packet failures.
- `REVIEW_AGENT_VALIDATION_GATE_DRIFT_REPAIR.md` — paired P0 code/architecture/workflow review of expiry-state truth, validation-path resolution, and fail-closed gate preservation.
- `OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY.md` — P0 publication hardening: classify/preflight the dedicated art checkout, safely prepare clean-behind/local-cache state, reject stale baselines before mutation, and restore only proven transaction-generated Godot metadata churn; depends on the sparse-checkout correction re-review.
- `REVIEW_OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY.md` — paired P0 code/architecture/asset-pipeline/workflow review of the publish-readiness and clean-or-RECOVERY_REQUIRED contract.
- `OPERATOR_WORKBENCH_BROWSER_SNAPSHOT_HARDENING.md` — P0 browser/PREVIEW concurrency hardening: accepted browser snapshot, latest-request-wins refresh, page-3 atomic F5 replacement, stale async rejection, and deterministic race coverage; depends on the publish-readiness review.
- `REVIEW_OPERATOR_WORKBENCH_BROWSER_SNAPSHOT_HARDENING.md` — paired P0 code/architecture/runtime/workflow review of browser/PREVIEW refresh hardening and the page-3 crash-class regressions.
- `OPERATOR_WORKBENCH_SPARSE_ART_CHECKOUT_REVIEW_CORRECTIONS_1.md` — P1 repair for invalid tracked `block_hold_01` FX import metadata that prevents the required sparse Workbench modular-layer validation from passing; paired review is dependency-gated.
- `REVIEW_OPERATOR_WORKBENCH_SPARSE_ART_CHECKOUT_REVIEW_CORRECTIONS_1.md` — paired P1 code/workflow re-review of the `block_hold_01` FX import repair.
- `OPERATOR_WORKBENCH_FX_LAYER_ADOPTION.md` — P1 post-hardening Operator Workbench slice: explicitly adopt a saved `vfx`/`fx` Aseprite layer as canonical `fx`, transactionally CREATE/REPLACE source+runtime, preserve preview/rollback/concurrency safety, and make counterpart mirroring explicit/default-off; dependency-gated behind the browser/PREVIEW hardening review.
- `OPERATOR_ART_REGISTRATION_PROFILE.md` — P1 Operator Art Agent/Source Session calibration slice: one accepted 96x96 registration profile drives Aseprite guides, landmark-aware shared-scale planning, registration reports/overlays, and exact `pixelart --choose 1` plan replay without per-frame scaling.
- `REVIEW_OPERATOR_ART_REGISTRATION_PROFILE.md` — paired P1 code/architecture/asset-pipeline/workflow review of registration-profile authority, clipping/pose-preservation guards, MCP confinement, and crisp production-plan replay.
- `REVIEW_OPERATOR_WORKBENCH_FX_LAYER_ADOPTION.md` — paired P1 independent code/architecture/asset-pipeline review of FX layer adoption and new-source publication safety.
#### Procgen Runtime Optimization V1 Full-Auto Series

- Canonical dependency tracker: `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`. Workstream identities are pre-authored, but execution readiness is evidence-gated: packets whose exact contract depends on not-yet-landed architecture may remain `blocked` / `manual` until refreshed in place. Dependencies, paired reviews, refresh gates, and locks control eligibility.
- `archived/REVIEW_PROCGEN_CHUNK_LIFECYCLE_STATE_MACHINE.md` — paired post-land review of M4; complete/passed.
- `archived/PROCGEN_CHUNK_PAYLOAD_CACHE.md` — M5 invalidatable per-chunk reveal-payload cache; complete, landed.
- `archived/REVIEW_PROCGEN_CHUNK_PAYLOAD_CACHE.md` — paired post-land review of M5; complete/passed with one optional M6-owned cache-memory improvement.
- `archived/PROCGEN_DISTANT_CHUNK_UNLOAD.md` — M6 bounded production chunk-residency unload; complete/landed.
- `archived/REVIEW_PROCGEN_DISTANT_CHUNK_UNLOAD.md` — cycle-0 MR6 independent review; complete with findings `R0-01`..`R0-05`, not a pass.
- `PROCGEN_DISTANT_CHUNK_UNLOAD_REVIEW_CORRECTIONS_1.md` — bounded M6 correction cycle 1; ready/manual.
- `REVIEW_PROCGEN_DISTANT_CHUNK_UNLOAD_REVIEW_CORRECTIONS_1.md` — cycle-1 paired re-review; ready/auto behind the correction.
- `REVIEW_PROCGEN_DISTANT_CHUNK_UNLOAD.md` — MR6 paired post-land code/architecture/runtime review; active gate before S7 closes or D1-D3 refresh.
- `PROCGEN_REGION_FRAME_PRESENTATION_FOUNDATION.md` — RF1 data-driven region-frame + true exterior-void presentation foundation; blocked until MR6.
- `REVIEW_PROCGEN_REGION_FRAME_PRESENTATION_FOUNDATION.md` — paired RF1 review.
- `PROCGEN_ALPINE_PLATEAU_UNDERLAY_ASSETS.md` — six-state Asset V2 Alpine FAR/MIDDLE/NEAR underlay family; blocked on RF1 review + source art.
- `PROCGEN_ARCHIVE_RESOLVE_PRESENTATION_SPINE.md` — AR1 presentation-only streaming frontier spine; refreshed to landed M6, blocked until MR6.
- `PROCGEN_ARCHIVE_RESOLVE_SHADER.md` — AR2 shader/material layer; blocked on AR1.
- `PROCGEN_ARCHIVE_RESOLVE_SEMANTIC_ECHO.md` — AR3 semantic echo + spawn/reacquisition polish; blocked on AR2.
- `archived/CONTRACT_WORLD_PLACEMENT_FOUNDATION.md` — P1 accepted-world context foundation; complete/landed, paired review PR1 remains the gate for P2-P6.
- `REVIEW_CONTRACT_WORLD_PLACEMENT_FOUNDATION.md` — PR1 paired foundation review; gates P2-P6.
- `CONTRACT_WORLD_RESOURCE_PLACEMENT_EXTRACTION.md` — P2 resource placement extraction; depends on PR1.
- `CONTRACT_WORLD_VEHICLE_PLACEMENT_EXTRACTION.md` — P3 vehicle placement extraction; depends on PR1.
- `CONTRACT_WORLD_RELAY_PLACEMENT_EXTRACTION.md` — P4 ARRN relay placement extraction; depends on PR1.
- `CONTRACT_WORLD_ENCOUNTER_PLACEMENT_EXTRACTION.md` — P5 encounter/ambient marker placement extraction; depends on PR1.
- `CONTRACT_WORLD_INGRESS_PLACEMENT_EXTRACTION.md` — P6 authored ingress placement extraction; depends on PR1.
- `CONTRACT_WORLD_LOADER_CONTRACTION.md` — P7 loader cleanup after all placement siblings complete.
- `PROCGEN_ROAD_AUTHORITY_EXTRACTION.md` — D1 road authority extraction; depends on G5 + MR6.
- `PROCGEN_AUTHORED_CLAIM_REGISTRY_EXTRACTION.md` — D2 authored claim registry extraction; depends on G5 + MR6.
- `PROCGEN_GENERATION_STATE_EXTRACTION.md` — D3 generation-state/level-data extraction; depends on G5 + MR6.
- `PROCGEN_GENERATION_DATA_MODEL_AUDIT.md` — X1 post-D1/D2/D3 audit: re-measure remaining generation helpers/TileMapLayer operations, classify semantic vs presentation state, and lock the minimum GenerationGrid contract.
- `REVIEW_PROCGEN_GENERATION_DATA_MODEL_AUDIT.md` — XR1 independent architecture/code review of the complete post-D extraction inventory.
- `PROCGEN_GENERATION_GRID_FOUNDATION.md` — X2 implement the reviewed semantic GenerationGrid contract plus behavior-preserving TileMap-backed compatibility backend; broad migration remains deferred.
- `REVIEW_PROCGEN_GENERATION_GRID_FOUNDATION.md` — XR2 verify the grid seam is minimal, Node-free at the contract layer, deterministic, and parity-safe.
- `PROCGEN_GENERATION_GRID_MIGRATION_SERIES_AUTHORING.md` — X3 use reviewed audit+grid evidence to author the actual helper-cluster migration DAG, pure-data backend/cutover/demolition/convergence packets, and D4's final dependency.
- `REVIEW_PROCGEN_GENERATION_GRID_MIGRATION_SERIES_AUTHORING.md` — XR3 verify complete one-owner cluster coverage and keep D4 blocked until reviewed convergence.
- `PROCGEN_RENDER_ATTRIBUTION_V1.md` — V1 presentation cost attribution after D4 + P7.
- `PROCGEN_RENDER_LOAD_CONSOLIDATION.md` — V2 evidence-driven presentation node/draw consolidation; depends on V1.
- `PROCGEN_PERFORMANCE_SOAK_V1.md` — F1 final deterministic V1 soak and regression budgets; depends on V2.
- `REVIEW_PROCGEN_RUNTIME_OPTIMIZATION_SERIES_V1.md` — Q1 whole-series implementation + dependency-chain review; depends on F1.
- `PROCGEN_RUNTIME_OPTIMIZATION_V2_SERIES_AUTHORING.md` — A1 auto-author the next full packet DAG from Q1 findings/evidence.

- `REVIEW_OPERATOR_ART_REGISTRATION_PROFILE_REVIEW_CORRECTIONS_1.md` — paired P1 code/architecture/asset-pipeline/workflow re-review of plan-digest binding and Workbench report semantics.
- `REVIEW_VISUAL_VALIDATION_ECONOMY_TOOLING_V1_REVIEW_CORRECTIONS_1.md` — paired P0 code/runtime/workflow re-review of the correction round.
- `AWAKENING_04_05_CONNECTOR_TRANSITION_REGRESSION_GUARD.md` — P2 dependency-gated bidirectional regression harness for the Dust Lung ↔ Locker Reliquary connector; captures both travel directions and alpha telemetry after the visual closeout lands.
- `ASSET_WORKBENCH_REVIEW_STUDIO.md` — P2 Slice 2: native static/animated Asset V2 review, all source layouts, runtime catalog trust, filmstrip/playback, staged/runtime compare, LFS diagnostics, and bounded generic Operator preview reuse; eligible after Slice 1 lands.
- `AWAKENING_HANDOFF_READINESS_ART_CONVERGENCE_V1.md` — P1 full-scene Awakening convergence gate: lock Layout-to-art registration, prove late joins code-first with seam metrics/targeted ROIs, formalize South Reach completion for the later Hub handoff, and reconcile live art debt/docs.
- `REVIEW_AWAKENING_HANDOFF_READINESS_ART_CONVERGENCE_V1.md` — paired independent code/runtime/visual/asset review of the Awakening convergence and handoff-readiness slice.
- `REVIEW_STARTUP_WORLD_ENTRY_SPINE_V1.md` — paired independent review of startup routing, bootstrap reuse, and story-default preservation.
- `BABY_OPOSSUM_RUNTIME_HARDENING.md` — P2 Baby Opossum correctness pass: explicit reaction priority, arrival/contact-authoritative treat/retrieval, deterministic search ties, full contract timing parity, and focused regression coverage.
- `TWIN_SOLARIA_CROWN_INCIDENT_FORENSICS.md` — P1 Twin Solaria forensic progression with code-first overlay/state evidence; now also waits on `visual-validation-economy-tooling-v1` so baseline/Stage-B/Stage-F proof uses structured probes and one compact ROI sheet instead of repeated full-frame inspection.
- `REVIEW_TWIN_SOLARIA_CROWN_INCIDENT_FORENSICS.md` — paired independent review of the forensic slice, blocked on `twin-solaria-crown-incident-forensics`.
- `TWIN_SOLARIA_ROUTE_REVIEW_AUTHORITY.md` — P1 Slice D: fail-closed route candidate/evidence/reciprocity authority and HOLD / ABORT / AUTHORIZE ACQUISITION decisions; blocked on reviewed Slice C.
- `REVIEW_TWIN_SOLARIA_ROUTE_REVIEW_AUTHORITY.md` — paired independent review of Slice D, blocked on `twin-solaria-route-review-authority`.
- `TWIN_SOLARIA_SOLARIUM_I_ACQUISITION_PRESENTATION.md` — P1 Slice E: Asset V2 aperture/anchor/witness FX and state-driven Solarium I observational acquisition; blocked on reviewed Slice D plus `visual-validation-economy-tooling-v1` for structured state/registration/ROI proof.
- `REVIEW_TWIN_SOLARIA_SOLARIUM_I_ACQUISITION_PRESENTATION.md` — paired independent review of Slice E; no automatic Passage slice follows.
- `TWIN_SOLARIA_DEVELOPMENT_PREVIEW_CONSISTENCY.md` — P2 audit/fix for the development-only 3500×3000 expectation versus 4000×3000 texture; production 2048×1536 runtime is explicitly out of scope.
- `OPERATOR_FAST_CHAIN_INBOX_RECONCILIATION.md` — P2 reconcile the 12 already-named Fast 01–04 Operator inbox strips against canonical processed source/runtime and clear the persistent doctor warning without reprocessing valid art.
- `OPERATOR_MOBILE_GUARD_COMPOSITION.md` — P1 immediate post-Slice-E proving slice: establishes the bounded semantic movement-owned-lower + action-owned-upper composition seam, then applies it to moving unarmed guard enter/hold/non-break recoil/exit with lower cadence continuity.
- `OPERATOR_GUARD_PARRY_COMPOSITION_POLISH.md` — P1 follow-up after mobile guard: applies the proven seam to Vigil armed guard plus movement-permissive unarmed parry attempt/recovery without weakening real contact/guard-break commitment.
- `OPERATOR_DEPENDENCY_INJECTION_SPINE.md` — P1 Slice F0: retires all 38 remaining absolute Operator scene-tree lookups before the domain controllers are extracted.
- `OPERATOR_LOADOUT_DOMAIN_EXTRACTION.md` — P1 Slice F1: loadout/selection authority + `OperatorWeaponRuntimeState`, eliminates the three mutable weapon-definition fields, and makes moving draw/sheathe preserve lower cadence.
- `OPERATOR_MELEE_DOMAIN_EXTRACTION.md` — P1 Slice F2: melee timeline/drive/target/contact authority, moving-fast asset wiring, quality-gated armed strafe/READY posture composition, and preservation of authored committed full-body attacks.
- `OPERATOR_RANGED_DOMAIN_EXTRACTION.md` — P1 Slice F3 after F1: ranged/ammo/heat/reload/sidearm authority plus movement-permissive primary raise/lower and sidearm held/fire/recover; reload remains committed.
- `OPERATOR_DODGE_DOMAIN_EXTRACTION.md` — P1 Slice F4: extracts dodge/charge/Flow/chain state while explicitly retaining full-body displacement-owning dodge presentation.
- `OPERATOR_INTERACTION_DOMAIN_EXTRACTION.md` — P1 Slice F5: extracts Operator target/build/repair/terminal coordination and introduces opt-in `interaction/success_01` acknowledgement presentation without gating simulation.
- `OPERATOR_RECOVERY_DOMAIN_EXTRACTION.md` — P1 Slice F6 after the campaign death-handoff foundation: separates damage/recovery ownership and makes the existing moving Field Patch contract use locomotion lower + upper/FX while stationary use retains the authored pair.
- `OPERATOR_RANGED_STATIC_WEAPON_SOCKET_CLOSEOUT.md` — P1 post-F3 ranged presentation closeout: static Carbine `WeaponSprite` becomes the sole primary-ranged weapon renderer for supported socketed phases, animated weapon-strip residue is retired, and relaxed/source socket calibration is closed.
- `OPERATOR_RUNTIME_SHELL_COLLAPSE.md` — P1 Slice G after F0/F1-F6 plus defensive/ranged presentation closure: collapses `operator.gd`/`operator.tscn` to the thin chassis and turns architecture/path/animation audits into hard-zero final gates.

### Blocked / Manual Refresh

- `OPERATOR_GUARD_BREAK_PRESENTATION.md` — P2 blocked/manual until reviewed Asset V2 `block_break_01` body+FX pixels exist; guard break intentionally stays movement-locked/full-body.
- `OPERATOR_MODULAR_DIRECTIONAL_COVERAGE_CLOSEOUT.md` — P2 draft/manual after the runtime composition slices; human review chooses only visibly harmful directional/layer gaps for Asset V2 fulfillment rather than forcing eight-way completeness.

#### Operator Workbench UX Hierarchy V1

- Series tracker: `design/02_features/animation/OPERATOR_WORKBENCH_UX_HIERARCHY_ROADMAP.md`.
- All five packets are intentionally `blocked/manual` planning drafts with a mandatory **REFRESH REQUIRED BEFORE IMPLEMENTATION** banner. Do not claim them until the relevant predecessor/prerequisite has landed, a fresh OPUI review has reconciled the packet to current main, the banner is removed, and the packet is explicitly signed off.
- `OPERATOR_WORKBENCH_UX_STATE_HIERARCHY.md` - UX1 artist-facing publication/live/main state hierarchy, global shell and compact Activity; gated behind the reviewed FX-adoption chain.
- `OPERATOR_WORKBENCH_UX_WORKBENCH_HOME.md` - UX2 preview-first Page 2 WORKBENCH with compact inspector/layers and browser workflow badges; depends on UX1.
- `OPERATOR_WORKBENCH_UX_PUBLISH_DECISION.md` - UX3 changes-first Publish modal with no-op clarity, simplified mirror consequence and readiness projection; depends on UX2.
- `OPERATOR_WORKBENCH_UX_WORK_QUEUE.md` - UX4 actionable QUEUE over the human-authored animation implementation plan, including directional/layer coverage and unpublished-work filters; depends on UX3.
- `OPERATOR_WORKBENCH_UX_CONSISTENCY_CLOSEOUT.md` - UX5 cross-mode terminology/focus/responsive/accessibility regression closeout and human visual sign-off; depends on UX4.


### In Progress

- `ASH_BELL_FORLORN_RITUALANT.md` — INCOMPLETE_CLOSEOUT: route migration is complete and the encounter V2 is implemented; visual polish remains open.
- `BLACK_RELIQUARY_LIVE_MINIMAP.md` — INCOMPLETE_CLOSEOUT: no complete status is recorded; the packet still calls for a visual playtest.

- `PROCGEN_MACRO_PRESENTATION_V1.md` — Validated migration ledger for the live region-first Rocky Upland macro presentation layer; ten SURFACE states are bound and hardened.
- `GAME_OVER_FLOW.md` — Implement the game-over UX slice from `design/02_features/game_over/GAME_OVER_FLOW.md`: fail-state modal, stats snapshot, restart/menu actions, and validation.
- `PLAYABLE_SIEGE_LOOP_GATEHOUSE_SLICE.md` — Extend the Sundered Keep gatehouse into a playable siege loop with gate progression, enemy pressure, objective damage, repair, defense participation, debug feedback, and validation/docs updates.
- `COGNITIVE_STATE_PHASE_B.md` — Wire cognitive state modifiers into game systems and fix debug panel bugs. Implementation done; awaiting Godot runtime validation of move speed, attack recovery, accuracy bonus, and crit bonus modifiers. Manual test: F12 toggles debug panel, cognitive items change player stats visually.
- `UI_GD_FIXES.md` — Fix 11 hard compile blockers, runtime bugs, and performance issues in `ui.gd`. 10 of 11 fixes verified in code; Fix #11 (minimap rebuild performance) deferred. Boot sequence and stub cleanup still need Godot runtime confirmation.
- `OBSERVATORY_WORLD_TELEMETRY_FOUNDATION.md` — Add the first shared observability and world-memory foundation: F9 observatory overlay, world state graph, world history, interest management, sector heatmap accumulation, and the first live player/sector telemetry hooks.

### Recently Complete (awaiting archive)
