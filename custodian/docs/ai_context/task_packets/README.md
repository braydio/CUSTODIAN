# Agent Task Packets

Last updated: 2026-09-29

Task packets are optional, task-scoped risk-control and handoff files for CUSTODIAN agents.

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
`dispatch.py claim-next --agent codex` to claim the highest-priority eligible
auto packet, or `dispatch.py claim <workstream-id> --agent codex` for explicit
selection (including manual packets). Initial claims and direct starts share
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

### Ready / Auto Dispatch

- `OPERATOR_WORKBENCH_SPARSE_ART_CHECKOUT_REVIEW_CORRECTIONS_1.md` — P1 repair for invalid tracked `block_hold_01` FX import metadata that prevents the required sparse Workbench modular-layer validation from passing; paired review is dependency-gated.
- `REVIEW_OPERATOR_WORKBENCH_SPARSE_ART_CHECKOUT_REVIEW_CORRECTIONS_1.md` — paired P1 code/workflow re-review of the `block_hold_01` FX import repair.
#### Procgen Runtime Optimization V1 Full-Auto Series

- Canonical dependency tracker: `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`. All packets below are already authored as `Status: ready` / `Dispatch: auto`; dependencies and locks gate eligibility. One authorized agent may follow the roadmap's serial auto-run order, while parallel agents may claim independent eligible siblings.
- `PROCGEN_CANDIDATE_SEMANTIC_MODEL.md` — G2 data-only candidate model; depends on G1.
- `PROCGEN_SEMANTIC_CANDIDATE_GENERATION.md` — G3 semantics-first rejected-candidate path; depends on G2.
- `PROCGEN_ACCEPTED_CANDIDATE_MATERIALIZER.md` — G4 accepted semantic candidate runtime materializer; depends on G3.
- `PROCGEN_CANDIDATE_RUNTIME_PATH_DEMOLITION.md` — G5 retire superseded live rejected-candidate path; depends on G4.
- `PROCGEN_DERIVED_REBUILD_SCHEDULER_FOUNDATION.md` — M1 dirty-region/rebuild scheduler foundation; depends on S1.
- `PROCGEN_RUNTIME_MUTATION_SCHEDULER_CUTOVER.md` — M2 route runtime mutation producers through scheduler; depends on M1.
- `PROCGEN_PAUSE_AWARE_STREAMING.md` — M3 background prepare vs gameplay commit pause contract; depends on M2.
- `PROCGEN_CHUNK_LIFECYCLE_STATE_MACHINE.md` — M4 explicit chunk lifecycle authority; depends on M3.
- `PROCGEN_CHUNK_PAYLOAD_CACHE.md` — M5 deterministic reusable chunk payload cache; depends on M4.
- `PROCGEN_DISTANT_CHUNK_UNLOAD.md` — M6 production distant unload/reload after cache proof; depends on M5.
- `CONTRACT_WORLD_PLACEMENT_FOUNDATION.md` — P1 shared world-placement context/service seam; depends on S1.
- `CONTRACT_WORLD_RESOURCE_PLACEMENT_EXTRACTION.md` — P2 resource placement extraction; depends on P1.
- `CONTRACT_WORLD_VEHICLE_PLACEMENT_EXTRACTION.md` — P3 vehicle placement extraction; depends on P1.
- `CONTRACT_WORLD_RELAY_PLACEMENT_EXTRACTION.md` — P4 ARRN relay placement extraction; depends on P1.
- `CONTRACT_WORLD_ENCOUNTER_PLACEMENT_EXTRACTION.md` — P5 encounter/ambient marker placement extraction; depends on P1.
- `CONTRACT_WORLD_INGRESS_PLACEMENT_EXTRACTION.md` — P6 authored ingress placement extraction; depends on P1.
- `CONTRACT_WORLD_LOADER_CONTRACTION.md` — P7 loader cleanup after all placement siblings complete.
- `PROCGEN_ROAD_AUTHORITY_EXTRACTION.md` — D1 road authority extraction; depends on G5 + M6.
- `PROCGEN_AUTHORED_CLAIM_REGISTRY_EXTRACTION.md` — D2 authored claim registry extraction; depends on G5 + M6.
- `PROCGEN_GENERATION_STATE_EXTRACTION.md` — D3 generation-state/level-data extraction; depends on G5 + M6.
- `PROCGEN_TILEMAP_FACADE_CONTRACTION.md` — D4 ProcGenTilemap façade contraction after D1+D2+D3.
- `PROCGEN_RENDER_ATTRIBUTION_V1.md` — V1 presentation cost attribution after D4 + P7.
- `PROCGEN_RENDER_LOAD_CONSOLIDATION.md` — V2 evidence-driven presentation node/draw consolidation; depends on V1.
- `PROCGEN_PERFORMANCE_SOAK_V1.md` — F1 final deterministic V1 soak and regression budgets; depends on V2.
- `REVIEW_PROCGEN_RUNTIME_OPTIMIZATION_SERIES_V1.md` — Q1 whole-series implementation + dependency-chain review; depends on F1.
- `PROCGEN_RUNTIME_OPTIMIZATION_V2_SERIES_AUTHORING.md` — A1 auto-author the next full packet DAG from Q1 findings/evidence.

- `VISUAL_VALIDATION_ECONOMY_TOOLING_V1_REVIEW_CORRECTIONS_1.md` — P0 bounded correction round for review findings R0-01 through R0-06.
- `REVIEW_VISUAL_VALIDATION_ECONOMY_TOOLING_V1_REVIEW_CORRECTIONS_1.md` — paired P0 code/runtime/workflow re-review of the correction round.
- `AWAKENING_04_05_CONNECTOR_TRANSITION_REGRESSION_GUARD.md` — P2 dependency-gated bidirectional regression harness for the Dust Lung ↔ Locker Reliquary connector; captures both travel directions and alpha telemetry after the visual closeout lands.
- `ASSET_WORKBENCH_FAMILY_FOUNDATION.md` — P2 Slice 1 of the living Asset Workbench roadmap: read-only Asset V2 FAMILY navigator, truthful family/state lifecycle projection, pure search, transactional refresh, and Baby Opossum acceptance coverage.
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
- `OPERATOR_RUNTIME_COMPATIBILITY_RESIDUE.md` — P1 C2b.3 cleanup queued behind C2b.2: reconcile stale animation reachability, migrate direct Operator-PNG VFX consumers, disposition orphan/superseded canonical output, and retire compatibility SpriteFrames/resources only after zero-consumer proof.
- `OPERATOR_ACTION_ARBITRATION.md` — P1 Slice E queued behind C2b.3: replace reflection-driven Operator animation states with explicit action arbitration + semantic presentation coordination and remove the 34 state→actor glue sites.
- `OPERATOR_MOBILE_GUARD_COMPOSITION.md` — P1 post-Slice-E mobile guard composition: movement-owned lower locomotion through enter/hold/non-break recoil/exit with aim-owned upper defense, continuity guards, and runtime-scale strafe validation.
- `AI_CONTEXT_TASK_PACKET_VALIDATOR.md` — P2 read-only validator for required AI context, task-packet/index consistency, auto-dispatch metadata, and bounded authority-path drift.
- `TASK_PACKET_INDEX_AUTOMODE_HARDENING.md` — P2 bounded auto-index hardening queued after the AI-context validator: deterministically check/write only the Ready / Auto Dispatch block from packet metadata while preserving manual, in-progress, and historical sections.

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

_None._
