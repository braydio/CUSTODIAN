# Agent Task Packets

Last updated: 2026-10-03

Task packets are optional, task-scoped risk-control and handoff files for CUSTODIAN agents.


## Active Hub First-Set / First Campaign Loop Series

Design/spatial authority: `../../../design/04_architecture/HUB_FIRST_SET_BLOCKOUT.md`.  
Program tracker: `../../../design/04_architecture/HUB_FIRST_SET_IMPLEMENTATION_ROADMAP.md`.

Seven implementation slices are pre-authored with paired reviews. H1 is in progress. H2-H7 are deliberately `blocked/manual` and must be refreshed **in place** from landed predecessor review evidence before becoming `ready/auto`.

- H1 `HUB_FIRST_SET_BLOCKOUT_V1.md` / review — blockout with true two-connector Sepulcher loop, Operator-clearance path proof, Port return-bay semantics, current-main sync, human topology gate.
- H2 `HUB_AWAKENING_CONTEXT_HANDOFF.md` / review — reviewed Awakening completion → persistent Hub; also waits on reviewed Awakening handoff-readiness.
- H3 `HUB_FORUM_ADJUDICATION_CONTRACT_PREWARM.md` / review — explicit Dais acceptance + persistent accepted CampaignScenario/seed + one bootstrap generation.
- H4 `HUB_CROWN_TRANSFER_TWIN_SOLARIA.md` / review — optional same-Hub Crown Transfer route to production Twin and back; may run parallel with H3 after H2.
- H5 `HUB_MUSTER_CONTINUITY_PORT_DEPLOYMENT.md` / review — READY/GENERATING/FAILED Port gating and same-prewarmed-map deployment.
- H6 `HUB_CAMPAIGN_RETURN.md` / review — exactly-once CampaignOutcome → HubState mutation, Campaign teardown, Port return.
- H7 `HUB_FIRST_SET_INTEGRATION_CLOSEOUT.md` / review — full boot→Awakening→Hub→optional Twin→Campaign→outcome→Hub proof.

Do not create v2 duplicates merely because a predecessor chose different private helpers; refresh the existing downstream packet and its review in the same docs change.

## Active Kenney Presentation Feasibility Series

Program tracker: `../../../design/01_systems/KENNEY_PRESENTATION_FEASIBILITY_ROADMAP.md`.  
Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff

Three implementation slices test CUSTODIAN presentation without changing production art direction up front.

- K3D-1 technical review passed on `dc1110b8`; return the report/comparison to the recorded authoring chat for the user's A/B judgment before refreshing K3D-2.
- K3D-2 orthographic real-3D presentation and K3D-3 Shape/Asset Forge 3D→2D production testing remain planned and must be refreshed from landed predecessor evidence rather than pre-authored speculatively.
- Retro Fantasy and Retro Urban are intentionally outside this series until a separate art-direction discussion assigns them a role.

## Active Reusable Source-Material Intake

- `KENNEY_PATTERN_LINES_SOURCE_LIBRARY.md` — ready/auto reference-only intake for all four user-downloaded Kenney Pattern Pack Lines variants (30 motifs each, 120 PNGs total), with exact-copy provenance, license/hash metadata, and a curated CUSTODIAN usage shortlist. It does not create runtime assets; production use must promote selected motifs through the owning Asset V2 family.

## Active Archive Resolve Presentation Series

Design authority: `../../../design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md`.

The Archive Resolve implementation series is evidence-gated. AR1 is complete/landed on `83d89fd85`; ARR1 is now the active ready/auto gate and has been re-derived against the landed batched veil, disabled oracle, overflow behavior, z-layering, and reacquisition seams. AR2 has now been refreshed in the recorded planning chat against landed AR1 and remains blocked/manual only on clean/non-blocking ARR1; if ARR1 changes the AR1 render/state contract, AR2 returns here again. AR3 remains blocked/manual until the paired AR2 review passes and this planning chat refreshes it. AR2 and AR3 both declare paired automatic technical reviews, while subjective visual/game-feel approval stays in the Dropbox human-review lane.

- `archived/PROCGEN_ARCHIVE_RESOLVE_PRESENTATION_SPINE.md` — AR1, complete/landed presentation-only request/commit/unload spine and one batched flat diagnostic veil.
- `REVIEW_PROCGEN_ARCHIVE_RESOLVE_PRESENTATION_SPINE.md` — active ready/auto ARR1 gate, refreshed against landed AR1 and carrying RFR1 R0-04 road reacquisition proof.
- `PROCGEN_ARCHIVE_RESOLVE_SHADER.md` — AR2, refreshed against landed AR1; blocked/manual on ARR1 only, with automatic paired `REVIEW_PROCGEN_ARCHIVE_RESOLVE_SHADER.md`. Clean ARR1 promotion is mechanical unless ARR1 changes the AR1 contract.
- `PROCGEN_ARCHIVE_RESOLVE_SEMANTIC_ECHO.md` — AR3, bounded semantic pre-echo, spawn resolve, and shortened reacquisition; blocked/manual until reviewed AR2 + ChatGPT/user refresh; paired `REVIEW_PROCGEN_ARCHIVE_RESOLVE_SEMANTIC_ECHO.md` is pre-authored.

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

For presentation-heavy packets, author objective visual validation first. If
material subjective judgment will still remain after those checks, route one
compact external handoff through
`custodian/tools/iteration/publish_review_artifacts.py` and
`custodian/docs/ai_context/VISUAL_REVIEW_HANDOFF.md`. The execution agent should
return the Dropbox manifest path and reviewer questions, not perform a redundant
aesthetic critique of its own captures.

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

## Packet Handoff And Authoring-Chat Provenance

Newly authored or materially refreshed V2 packets record
`Authoring chat: <ChatGPT conversation URL | not-recorded | n/a>`. When the
user provides the originating conversation URL, preserve it exactly. Agents
must never derive or invent ChatGPT conversation URLs.

Every completed packet/review reports the immediate successor in its own
program/DAG through the required `Next Handoff` fields: next workstream,
packet state, refresh owner, whether ChatGPT/user planning refresh is required,
authoring-chat URL, refresh reason, next action, and blockers.

Architecture/design-sensitive refreshes default to `Refresh owner: chatgpt-user`.
The execution/review agent supplies the live-state evidence and drift, but the
user brings the recorded authoring chat back to ChatGPT so the packet can be
re-derived against both original intent and current main. Mechanical refreshes
that do not change scope, ownership, sequencing, acceptance, visual direction,
or design interpretation may use `execution-agent`.

Historical packets without an authoring URL remain valid; surface
`Authoring chat: not-recorded` and ask the user to provide the originating
chat URL if they have it.

## Paired Review Default And Independence

For newly authored or materially refreshed V2 implementation packets, use `Review: auto` by default when independent review can materially improve confidence. This includes runtime/state-machine/persistence/streaming changes, architecture extraction or migration, production asset-pipeline/tooling mutations, performance changes that must preserve semantics, validation/workflow infrastructure, substantial bug fixes, and objective technical presentation work. `Review: none` is a low-risk exemption for documentation-only truth repair, tiny mechanical patches with obvious local effects and direct regression coverage, disposable probes, or similarly inspectable changes; record a concrete `Review rationale: low-risk exemption: ...`. Do not disable review merely to reduce queue length.

Paired review requires a **fresh reviewer context**. A different agent/context is preferred when available, but a different model family is not mandatory. The same model/agent family may review prior work only from a newly started context/workstream with no transient implementation reasoning carried forward, reconstructing the target from the archived packet, closing summary, live code, design authority, tests, and fresh traces/mutations. Record `Reviewer context: fresh` and `Reviewer provenance: different-agent | same-agent-fresh-context` in the durable review artifacts. Continuing the implementation conversation/session is self-review and does not satisfy the paired-review contract.

Legacy packets are not bulk-retrofitted. When new work materially depends on an older unreviewed/legacy seam, re-check the surviving live authority and focused behavior during authoring; use paired review for the new slice when that seam is high-risk, unclear, or central to acceptance.

## Paired Review And Correction

Post-land review intent is decided when the implementation packet is created. For newly authored or materially refreshed V2 engineering packets, `Review: auto` is the risk-based default described above; `Review: none` is the explicit low-risk exemption. It uses ordinary dispatcher primitives
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
  - Reviewer context: `fresh`
  - Reviewer provenance: `different-agent | same-agent-fresh-context`
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

- Procgen planning-refresh chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`. Any architecture/design-sensitive procgen packet marked `Refresh owner: chatgpt-user` should send the user back to this conversation with the landed predecessor summary/review evidence before the packet is refreshed in place.

- Canonical dependency tracker: `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`. Workstream identities are stable, but execution readiness is evidence-gated. A packet is `ready/auto` only when its current measured state and implementation surface exist on live main; architecture-dependent downstream packets stay `blocked/manual` and are refreshed in place after the named predecessor/review lands.
- **Runtime/streaming:** M4/MR4, M5/MR5, M6/MR6, M6C1 and MR6R1 are complete. Cycle-1 MR6R1 passed with 0 blocking defects and 0 material evidence gaps, closing S7. Its five optional next-slice proof-hardening items N1-01..N1-05 are now owned by RF1 rather than another correction cycle.
- **Post-M6 world presentation:** RF1/RFR1 are complete/passed; Region Frame is stable presentation authority. RFR1 next-slice findings R0-01/R0-02 are folded into `PROCGEN_ALPINE_PLATEAU_UNDERLAY_ASSETS.md`, while R0-04 is carried into ARR1's reacquisition review. The Alpine packet is now `ready/manual` for a local agent with `~/Downloads/alpine_plateau_underlay_assets.zip`; objective Asset V2 checks precede Dropbox human visual approval. AR1 is complete/landed; ARR1 is ready/auto and is the next Archive Resolve gate. AR2 remains refresh-gated on ARR1 and AR3 on reviewed AR2; both now have paired technical review packets and route required planning refreshes back to the recorded procgen chat.
- **Placement:** P1 `CONTRACT_WORLD_PLACEMENT_FOUNDATION.md` has landed `WorldPlacementContext` as the accepted-world read seam while leaving placement policies in `ContractWorldLoader`. `REVIEW_CONTRACT_WORLD_PLACEMENT_FOUNDATION.md` (PR1) is now the next review gate and must pass before resource, vehicle, relay, encounter, or ingress extraction; those packets remain serialized by the `contract-world-loader` lock. `CONTRACT_WORLD_LOADER_CONTRACTION.md` (P7) remains blocked/manual until P2-P6 land, then must be re-derived from the surviving loader.
- **ProcGen decomplexification:** D1 `PROCGEN_ROAD_AUTHORITY_EXTRACTION.md` is implemented and validated; its paired `REVIEW_PROCGEN_ROAD_AUTHORITY_EXTRACTION.md` is the post-land review gate. D2 `PROCGEN_AUTHORED_CLAIM_REGISTRY_EXTRACTION.md` and D3 `PROCGEN_GENERATION_STATE_EXTRACTION.md` remain blocked/manual pending their own live inventory refreshes.
- **GenerationGrid:** `PROCGEN_GENERATION_DATA_MODEL_AUDIT.md` / XR1 remain the first executable post-D audit. `PROCGEN_GENERATION_GRID_FOUNDATION.md` is blocked/manual until XR1 defines the real minimum grid seam. `PROCGEN_GENERATION_GRID_MIGRATION_SERIES_AUTHORING.md` is blocked/manual until XR2. Their paired reviews remain dependency-gated. `PROCGEN_TILEMAP_FACADE_CONTRACTION.md` stays hard-blocked until X3 authors and the generated migration DAG reaches a concrete final reviewed convergence workstream.
- **Render/soak:** `PROCGEN_RENDER_ATTRIBUTION_V1.md` remains the post-D4/P7 measurement slice and must re-inventory live presentation owners at execution. `PROCGEN_RENDER_LOAD_CONSOLIDATION.md` is blocked/manual until attribution identifies the actual safe target. `PROCGEN_PERFORMANCE_SOAK_V1.md`, `REVIEW_PROCGEN_RUNTIME_OPTIMIZATION_SERIES_V1.md`, and `PROCGEN_RUNTIME_OPTIMIZATION_V2_SERIES_AUTHORING.md` remain dependency-gated end-of-series work; A1 now carries the same refresh-gate discipline rather than requiring speculative future packets to be ready up front.

### Ready / Auto Dispatch


<!-- task_packet_index:managed:start -->
- `OPERATOR_WORKBENCH_BROWSER_SNAPSHOT_HARDENING.md` — Make Operator Workbench browser refresh and page-3 PREVIEW reload transactional from the user's perspective: repeated F5, source scans, live Workbench update...
- `OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY.md` — Make Operator Workbench publication behave as one self-preparing, fail-closed transaction from the artist's perspective: before canonical mutation begins, OP...
- `REVIEW_OPERATOR_WORKBENCH_BROWSER_SNAPSHOT_HARDENING.md` — Independently verify that the landed browser/PREVIEW hardening makes F5 and asynchronous refresh latest-request-wins without creating a second state authorit...
- `REVIEW_OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY.md` — Independently verify that the landed Workbench publication hardening converts the recent serial Git/LFS/manifest/import failure chain into one bounded readin...
- `REVIEW_VISUAL_VALIDATION_ECONOMY_TOOLING_V1_REVIEW_CORRECTIONS_1.md` — Independently verify corrections for findings R0-01 through R0-05 without reopening parent implementation scope.
- `AWAKENING_HANDOFF_READINESS_ART_CONVERGENCE_V1.md` — Make the complete Awakening / The First Return scene a trustworthy production handoff source for the later Hub runtime by locking its current art registratio...
- `CUSTODIAN_DEATH_HANDOFF_FOUNDATION.md` — Make Custodian lethal damage a campaign-level exactly-once event instead of an actor-owned life decrement, establishing the recovery-capable death handoff wi...
- `ENEMY_MARINE_DASH_ABILITY_EXTRACTION.md` — Move Marine Dash from `enemy.gd` into one complete actor-local ability authority while preserving the current tactical-dash behavior, tuning, combat results,...
- `ENEMY_SAVAGE_CHAIN_ABILITY_EXTRACTION.md` — Move the Savage two-hit chain lifecycle out of `enemy.gd` into one actor-local ability authority while preserving the existing rushdown cadence and guard-pre...
- `ENEMY_SAVAGE_POUNCE_ABILITY_EXTRACTION.md` — Move the Savage pounce phase machine out of `enemy.gd` into one actor-local ability authority, reusing the landed Marine/Falcon host-service pattern without...
- `OPERATOR_DEPENDENCY_INJECTION_SPINE.md` — Retire the remaining absolute scene-tree lookup debt before domain extraction so every later Operator controller receives explicit dependencies instead of re...
- `OPERATOR_DODGE_DOMAIN_EXTRACTION.md` — Extract dodge/charge/Flow/chain lifecycle into a focused traversal authority while preserving the deliberate full-body presentation model for displacement-ow...
- `OPERATOR_GUARD_PARRY_COMPOSITION_POLISH.md` — Extend the proven movement-permissive guard composition to the remaining defensive presentations that already allow movement, without weakening contact weigh...
- `OPERATOR_INTERACTION_DOMAIN_EXTRACTION.md` — Extract interaction target/build/repair/terminal field-work coordination into one focused authority and give interactables an opt-in semantic Operator succes...
- `OPERATOR_LOADOUT_DOMAIN_EXTRACTION.md` — Make loadout/weapon-selection runtime state a focused authority, remove mutable instance state from `OperatorWeaponDefinition`, and use the established modul...
- `OPERATOR_MELEE_DOMAIN_EXTRACTION.md` — Extract melee timeline/drive/target/contact state into one focused authority and cash in the existing modular art where it genuinely improves moving combat p...
- `OPERATOR_MOBILE_GUARD_COMPOSITION.md` — Make the unarmed guard lifecycle visibly movement-permissive wherever gameplay already allows movement, so strafing is expressed as movement-owned lower-body...
- `OPERATOR_RANGED_DOMAIN_EXTRACTION.md` — Extract primary-ranged/sidearm combat state into one ranged authority and make all movement-permissive ranged presentation use the same lower-locomotion + up...
- `OPERATOR_RANGED_STATIC_WEAPON_SOCKET_CLOSEOUT.md` — Finish the already-live Carbine hybrid socket architecture by making the static directional `WeaponSprite` the sole primary-ranged weapon renderer for author...
- `OPERATOR_RECOVERY_DOMAIN_EXTRACTION.md` — Extract Operator damage/recovery/Field Patch survivability behavior into explicit authorities and make the movement-permissive Field Patch animation reflect...
- `OPERATOR_RUNTIME_SHELL_COLLAPSE.md` — Finish the Operator strangler migration by collapsing `operator.gd` and `operator.tscn` into a thin deterministic actor chassis over the extracted authoritie...
- `OPERATOR_WORKBENCH_FX_LAYER_ADOPTION.md` — Let an artist add or replace an FX layer directly inside an existing Operator Aseprite Workbench, explicitly adopt that saved layer as the animation's canoni...
- `PROCGEN_GENERATION_DATA_MODEL_AUDIT.md` — Re-derive the post-D1/D2/D3 generation core from live code and produce the authoritative migration contract for replacing TileMapLayer-as-working-memory with...
- `PROCGEN_PERFORMANCE_SOAK_V1.md` — Run the complete optimized procgen stack through a deterministic production-size soak, compare it to the S1 baseline, and establish stable regression budgets...
- `PROCGEN_RENDER_ATTRIBUTION_V1.md` — Attribute procgen presentation node, rendered-object, and draw-call cost to concrete presentation owners before changing renderer structure.
- `PROCGEN_RUNTIME_OPTIMIZATION_V2_SERIES_AUTHORING.md` — Convert the completed V1 whole-series review and final soak evidence into the next evidence-backed procgen optimization/correction DAG, preserving stable wor...
- `REVIEW_AWAKENING_HANDOFF_READINESS_ART_CONVERGENCE_V1.md` — Independently verify the landed Awakening convergence slice against its registration, seam, progression, asset-consumption, and South Reach handoff-readiness...
- `REVIEW_HUB_AWAKENING_CONTEXT_HANDOFF.md` — Independently verify the landed implementation against its archived packet and live runtime.
- `REVIEW_HUB_CAMPAIGN_RETURN.md` — Independently verify the landed implementation against its archived packet and live runtime behavior.
- `REVIEW_HUB_CROWN_TRANSFER_TWIN_SOLARIA.md` — Independently verify the landed implementation against its archived packet and live runtime behavior.
- `REVIEW_HUB_FIRST_SET_BLOCKOUT_V1.md` — Independently verify that the landed Hub first-set blockout is one coherent, navigable spatial authority from South Reach through Forum/branches to Crown Tra...
- `REVIEW_HUB_FIRST_SET_INTEGRATION_CLOSEOUT.md` — Independently verify the landed implementation against its archived packet and live runtime behavior.
- `REVIEW_HUB_FORUM_ADJUDICATION_CONTRACT_PREWARM.md` — Independently verify the landed implementation against its archived packet and live runtime.
- `REVIEW_HUB_MUSTER_CONTINUITY_PORT_DEPLOYMENT.md` — Independently verify the landed implementation against its archived packet and live runtime behavior.
- `REVIEW_OPERATOR_ART_REGISTRATION_PROFILE_REVIEW_CORRECTIONS_1.md` — Independently verify that correction 1 binds production to the approved normalization plan and closes the Workbench registration-report evidence gap without...
- `REVIEW_OPERATOR_WORKBENCH_FX_LAYER_ADOPTION.md` — Independently verify that the landed Workbench FX-adoption slice safely turns an explicit saved Aseprite `vfx`/`fx` layer into canonical Operator `fx` source...
- `REVIEW_OPERATOR_WORKBENCH_SPARSE_ART_CHECKOUT_REVIEW_CORRECTIONS_1.md` — Independently verify closure of parent finding `R0-01` against current main and the landed correction evidence. The review must not assume the resumed correc...
- `REVIEW_PROCGEN_GENERATION_DATA_MODEL_AUDIT.md` — Independently verify that the post-D1/D2/D3 generation-data audit completely and truthfully maps the remaining TileMap-backed generation core before any abst...
- `REVIEW_PROCGEN_GENERATION_GRID_FOUNDATION.md` — Independently verify that the GenerationGrid foundation is a minimal semantic storage seam with exact TileMap-backed parity, not an accidental second generat...
- `REVIEW_PROCGEN_GENERATION_GRID_MIGRATION_SERIES_AUTHORING.md` — Independently verify that the authored generation-grid migration DAG covers the entire audited semantic-generation surface exactly once, has truthful depende...
- `REVIEW_PROCGEN_ROAD_AUTHORITY_EXTRACTION.md` — Independently verify that D1 created one road/path/parking authority owner, removed duplicate canonical road state from `ProcGenTilemap`, preserved Road Sema...
- `REVIEW_PROCGEN_RUNTIME_OPTIMIZATION_SERIES_V1.md` — Independently review the entire landed Procgen Runtime Optimization V1 implementation and its dependency DAG after the final soak, then produce one findings-...
- `REVIEW_STARTUP_WORLD_ENTRY_SPINE_V1.md` — Independently verify that the App/Boot spine makes Twin Solaria and the Contract sandbox directly bootable without changing production story order or duplica...
- `REVIEW_TWIN_SOLARIA_CROWN_INCIDENT_FORENSICS.md` — Independently verify that the landed Twin Solaria Crown Incident forensic progression satisfies the staged evidence contract without creating route/Persisten...
- `REVIEW_TWIN_SOLARIA_ROUTE_REVIEW_AUTHORITY.md` — Independently verify fail-closed Twin Solaria route adjudication without travel or presentation authority leakage.
- `REVIEW_TWIN_SOLARIA_ROUTE_VISTA_SAMPLES_V1.md` — Independently verify the Route Vista sample ingest/presentation without replacing human visual approval or allowing presentation to become route authority.
- `REVIEW_TWIN_SOLARIA_SOLARIUM_I_ACQUISITION_PRESENTATION.md` — Independently verify that Solarium I acquisition is presentation-only, Asset V2-compliant, fail-closed, and never becomes Crown passage.
- `TWIN_SOLARIA_CROWN_INCIDENT_FORENSICS.md` — Implement Twin Solaria Slice C as a deterministic, local Crown Incident forensic progression layered onto the already-live V1 authored level, without introdu...
- `TWIN_SOLARIA_ROUTE_REVIEW_AUTHORITY.md` — Implement Twin Solaria Slice D as one focused, fail-closed route-review authority that models a candidate route, classifies evidence, enforces Home Index and...
- `TWIN_SOLARIA_ROUTE_VISTA_SAMPLES_V1.md` — Ingest the three newly pushed Twin Solaria archway-view images as neutral Route Vista sample content for Solarium I, wire a presentation-only first-pass samp...
- `TWIN_SOLARIA_SOLARIUM_I_ACQUISITION_PRESENTATION.md` — Implement Twin Solaria Slice E so authorized route-review state drives a readable Solarium I observational-acquisition sequence through the Outbound/Reciproc...
- `ASSET_WORKBENCH_REVIEW_STUDIO.md` — Add a non-mutating REVIEW studio to Asset Workbench so selected Asset V2 states can be inspected at native pixel fidelity across staged source and runtime re...
- `AWAKENING_04_05_CONNECTOR_TRANSITION_REGRESSION_GUARD.md` — Make the repaired Dust Lung ↔ Locker Reliquary handoff durable by adding one repeatable bidirectional runtime/presentation regression path that can expose se...
- `BABY_OPOSSUM_RUNTIME_HARDENING.md` — Correct the Baby Opossum runtime state-transition and approach/retrieval semantics, tighten determinism and contract validation, and reconcile the active imp...
- `CONTRACT_WORLD_ENCOUNTER_PLACEMENT_EXTRACTION.md` — Move ambient enemy/encounter marker placement policy from ContractWorldLoader into one focused placement service without moving enemy spawning or AI authority.
- `CONTRACT_WORLD_INGRESS_PLACEMENT_EXTRACTION.md` — Move authored world-ingress/destination placement from ContractWorldLoader into the canonical world-placement layer while preserving transition ownership els...
- `CONTRACT_WORLD_RELAY_PLACEMENT_EXTRACTION.md` — Move ARRN relay tile selection and placement from ContractWorldLoader into the world-placement layer.
- `CONTRACT_WORLD_RESOURCE_PLACEMENT_EXTRACTION.md` — Move tutorial and expedition resource-node placement policy out of ContractWorldLoader into one deterministic placement service.
- `CONTRACT_WORLD_VEHICLE_PLACEMENT_EXTRACTION.md` — Move generated-world vehicle placement policy from ContractWorldLoader into a focused deterministic placement service.
- `REVIEW_CONTRACT_WORLD_PLACEMENT_FOUNDATION.md` — Independently verify that P1 created one minimal read-only world-placement context seam, preserved ContractWorldLoader lifecycle/orchestration authority and...
- `REVIEW_LORDS_OF_PAIN_TEST_GALLERY.md` — Independently verify the landed DEMO-scoped Lords of Pain test gallery against its archived implementation packet, with special attention to the seven availa...
- `REVIEW_PROCGEN_ARCHIVE_RESOLVE_PRESENTATION_SPINE.md` — Independently verify that AR1 hides streaming cadence through a bounded presentation-only frontier while preserving M3-M6, Region Frame, and gameplay authori...
- `TWIN_SOLARIA_DEVELOPMENT_PREVIEW_CONSISTENCY.md` — Resolve the long-standing development-only Twin Solaria preview mismatch where the preview controller/smoke expects 3500×3000 while the loaded development te...
<!-- task_packet_index:managed:end -->
- `REVIEW_PROCGEN_ROAD_AUTHORITY_EXTRACTION.md` — paired D1 code/architecture/runtime review with reviewer-context provenance.

- `archived/PROCGEN_ARCHIVE_RESOLVE_PRESENTATION_SPINE.md` — P2 coding-first Archive Resolve presentation spine; auto-eligible after RF1 releases shared procgen locks.
- `REVIEW_PROCGEN_ARCHIVE_RESOLVE_PRESENTATION_SPINE.md` — paired AR1 technical review; gates AR2.

- `HUB_FIRST_SET_BLOCKOUT_V1.md` — P1 runtime-ready Hub first-set blockout from South Reach through Ashen Forum, Sepulcher loop, Archive/Crown Transfer branch, and Muster Court/Continuity Port deployment wing; spatial only, no world transitions.
- `REVIEW_HUB_FIRST_SET_BLOCKOUT_V1.md` — paired independent review of first-set geometry, navigation, Road presentation reuse, inert handoff markers, and human blockout overview approval.
- `TWIN_SOLARIA_ROUTE_VISTA_SAMPLES_V1.md` — P1 first-pass Solarium I Route Vista sample ingest/presentation: three neutral V2 candidate contents from the new archway-view drop, exact 465×280 registration, playtest sampler, and human capture review.
- `REVIEW_TWIN_SOLARIA_ROUTE_VISTA_SAMPLES_V1.md` — paired independent review of vista provenance, normalization, registration, presentation ownership, and recorded human approval.
- `OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY.md` — P0 publication hardening: classify/preflight the dedicated art checkout, safely prepare clean-behind/local-only LFS state (shared cache first, exact verified hydrated donor second), reject stale baselines before mutation, and restore only proven transaction-generated Godot metadata churn; depends on the sparse-checkout correction re-review.
- `REVIEW_OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY.md` — paired P0 code/architecture/asset-pipeline/workflow review of the publish-readiness and clean-or-RECOVERY_REQUIRED contract.
- `OPERATOR_WORKBENCH_BROWSER_SNAPSHOT_HARDENING.md` — P0 browser/PREVIEW concurrency hardening: accepted browser snapshot, latest-request-wins refresh, page-3 atomic F5 replacement, stale async rejection, and deterministic race coverage; depends on the publish-readiness review.
- `REVIEW_OPERATOR_WORKBENCH_BROWSER_SNAPSHOT_HARDENING.md` — paired P0 code/architecture/runtime/workflow review of browser/PREVIEW refresh hardening and the page-3 crash-class regressions.
- `REVIEW_OPERATOR_WORKBENCH_SPARSE_ART_CHECKOUT_REVIEW_CORRECTIONS_1.md` — paired P1 findings-first review that classifies parent R0-01 as fixed/unresolved/regressed from current main plus sparse-proof evidence; it must reuse exact local-LFS donor evidence instead of rerunning broad imports unnecessarily.
- `OPERATOR_WORKBENCH_FX_LAYER_ADOPTION.md` — P1 post-hardening Operator Workbench slice: explicitly adopt a saved `vfx`/`fx` Aseprite layer as canonical `fx`, transactionally CREATE/REPLACE source+runtime, preserve preview/rollback/concurrency safety, and make counterpart mirroring explicit/default-off; dependency-gated behind the browser/PREVIEW hardening review.
- `REVIEW_OPERATOR_WORKBENCH_FX_LAYER_ADOPTION.md` — paired P1 independent code/architecture/asset-pipeline review of FX layer adoption and new-source publication safety.
- `OPERATOR_WORKBENCH_ANIMATION_CREATION.md` — P1 post-FX Workbench V3 creation slice: author a genuinely new semantic Operator animation from OPUI, preview it before publication, then CREATE canonical source and run the specialized Operator runtime/import/validation/landing transaction; dependency-gated behind the FX-adoption review.
- `REVIEW_OPERATOR_WORKBENCH_ANIMATION_CREATION.md` — paired P1 independent code/architecture/asset-pipeline/workflow review of absent-identity creation, collision safety, exact rollback, pipeline integration, and truthful dormant/unwired state.
#### Procgen Runtime Optimization V1 Full-Auto Series

- Canonical dependency tracker: `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`. Workstream identities are pre-authored, but execution readiness is evidence-gated: packets whose exact contract depends on not-yet-landed architecture may remain `blocked` / `manual` until refreshed in place. Dependencies, paired reviews, refresh gates, and locks control eligibility.
- `archived/REVIEW_PROCGEN_CHUNK_LIFECYCLE_STATE_MACHINE.md` — paired post-land review of M4; complete/passed.
- `archived/PROCGEN_CHUNK_PAYLOAD_CACHE.md` — M5 invalidatable per-chunk reveal-payload cache; complete, landed.
- `archived/REVIEW_PROCGEN_CHUNK_PAYLOAD_CACHE.md` — paired post-land review of M5; complete/passed with one optional M6-owned cache-memory improvement.
- `archived/PROCGEN_DISTANT_CHUNK_UNLOAD.md` — M6 bounded production chunk-residency unload; complete/landed.
- `archived/REVIEW_PROCGEN_DISTANT_CHUNK_UNLOAD.md` — cycle-0 MR6 independent review; complete with findings `R0-01`..`R0-05`, not a pass.
- `archived/PROCGEN_DISTANT_CHUNK_UNLOAD_REVIEW_CORRECTIONS_1.md` — bounded M6 correction cycle 1 closing R0-01..R0-05; complete.
- `archived/REVIEW_PROCGEN_DISTANT_CHUNK_UNLOAD_REVIEW_CORRECTIONS_1.md` — cycle-1 MR6 re-review; complete, clean with next-slice items N1-01..N1-05.
- `archived/PROCGEN_REGION_FRAME_PRESENTATION_FOUNDATION.md` — RF1 region-frame foundation plus M6 proof hardening N1-01..N1-05; complete/landed; paired RFR1 review is ready.
- `archived/REVIEW_PROCGEN_REGION_FRAME_PRESENTATION_FOUNDATION.md` — paired RF1 review; complete, passed with next-slice items R0-01, R0-02, R0-04.
- `PROCGEN_ALPINE_PLATEAU_UNDERLAY_ASSETS.md` — six-state Asset V2 Alpine FAR/MIDDLE/NEAR underlay family; blocked on RF1 review + source art.
- `archived/PROCGEN_ARCHIVE_RESOLVE_PRESENTATION_SPINE.md` — AR1 fully re-derived post-M6 presentation spine; complete/landed; paired ARR1 review is ready.
- `REVIEW_PROCGEN_ARCHIVE_RESOLVE_PRESENTATION_SPINE.md` — paired AR1 technical review; gates AR2.
- `PROCGEN_ARCHIVE_RESOLVE_SHADER.md` — AR2 shader/material layer; blocked on reviewed AR1.
- `PROCGEN_ARCHIVE_RESOLVE_SEMANTIC_ECHO.md` — AR3 semantic echo + spawn/reacquisition polish; blocked on AR2.
- `archived/CONTRACT_WORLD_PLACEMENT_FOUNDATION.md` — P1 accepted-world context foundation; complete/landed, paired review PR1 remains the gate for P2-P6.
- `REVIEW_CONTRACT_WORLD_PLACEMENT_FOUNDATION.md` — PR1 paired foundation review; gates P2-P6.
- `CONTRACT_WORLD_RESOURCE_PLACEMENT_EXTRACTION.md` — P2 resource placement extraction; depends on PR1.
- `CONTRACT_WORLD_VEHICLE_PLACEMENT_EXTRACTION.md` — P3 vehicle placement extraction; depends on PR1.
- `CONTRACT_WORLD_RELAY_PLACEMENT_EXTRACTION.md` — P4 ARRN relay placement extraction; depends on PR1.
- `CONTRACT_WORLD_ENCOUNTER_PLACEMENT_EXTRACTION.md` — P5 encounter/ambient marker placement extraction; depends on PR1.
- `CONTRACT_WORLD_INGRESS_PLACEMENT_EXTRACTION.md` — P6 authored ingress placement extraction; depends on PR1.
- `CONTRACT_WORLD_LOADER_CONTRACTION.md` — P7 loader cleanup after all placement siblings complete.
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

- `OPERATOR_UNARMED_DEFENSE_SOURCE_PROMOTION.md` — P2 blocked/manual Asset V2 source-work promotion for the new ten-file east-facing unarmed-defense generator set; raw 2172×724 outputs must pass Source Session registration/normalization and human art approval before any live canonical family is replaced.
- `OPERATOR_GUARD_BREAK_PRESENTATION.md` — P2 blocked/manual: raw 3f `block_break_01` + 6f `block_break_recovery_01` body source-work now exists but is not production-normalized; packet waits on `operator-unarmed-defense-source-promotion` plus a dedicated reviewed 3f break FX. Guard break intentionally stays movement-locked/full-body.
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