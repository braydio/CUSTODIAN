# Agent Task Packets

Last updated: 2026-10-04

Task packets are optional, task-scoped risk-control and handoff files for CUSTODIAN agents.


## Active Hub First-Set / First Campaign Loop Series

Design/spatial authority: `../../../design/04_architecture/HUB_FIRST_SET_BLOCKOUT.md`.
Program tracker: `../../../design/04_architecture/HUB_FIRST_SET_IMPLEMENTATION_ROADMAP.md`.

Seven implementation slices are pre-authored with paired reviews. H1 is queue-recovered as `hub-first-set-blockout-v1-recovery-1` and is `ready/auto`; the original remote branch is donor evidence only. H2-H7 are deliberately `blocked/manual` and must be refreshed **in place** from landed predecessor review evidence before becoming `ready/auto`.

- H1 `HUB_FIRST_SET_BLOCKOUT_V1.md` / review — recovery workstream `hub-first-set-blockout-v1-recovery-1`; blockout with true two-connector Sepulcher loop, Operator-clearance path proof, Port return-bay semantics, current-main sync, human topology gate.
- H2 `HUB_AWAKENING_CONTEXT_HANDOFF.md` / review — reviewed Awakening completion → persistent Hub; also waits on reviewed Awakening handoff-readiness.
- H3 `HUB_FORUM_ADJUDICATION_CONTRACT_PREWARM.md` / review — explicit Dais acceptance + persistent accepted CampaignScenario/seed + one bootstrap generation.
- H4 `HUB_CROWN_TRANSFER_TWIN_SOLARIA.md` / review — optional same-Hub Crown Transfer route to production Twin and back; may run parallel with H3 after H2.
- H5 `HUB_MUSTER_CONTINUITY_PORT_DEPLOYMENT.md` / review — READY/GENERATING/FAILED Port gating and same-prewarmed-map deployment.
- H6 `HUB_CAMPAIGN_RETURN.md` / review — exactly-once CampaignOutcome → HubState mutation, Campaign teardown, Port return.
- H7 `HUB_FIRST_SET_INTEGRATION_CLOSEOUT.md` / review — full boot→Awakening→Hub→optional Twin→Campaign→outcome→Hub proof.

Do not create v2 duplicates merely because a predecessor chose different private helpers; refresh the existing downstream packet and its review in the same docs change.

## Active Isometric 2.5D Presentation Realization Series

Design authority: `../../../design/01_systems/ISOMETRIC_2_5D_PRESENTATION_CONTRACT.md`.
Program tracker: `../../../design/01_systems/ISOMETRIC_2_5D_REALIZATION_ROADMAP.md`.
Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff

The project has pivoted away from planned live-3D presentation experiments. The fixed-isometric 2.5D doctrine will be realized inside the existing 2D runtime.

- K3D-1 remains complete/reviewed precursor evidence.
- K3D-1P `kenney-isometric-blockout-playtest` is **complete/landed** as the final walkable Kenney reference.
- `isometric-2-5d-presentation-foundation` is **ready/auto**; its K3D-1P dependency is satisfied by this landed precursor.
- `isometric-2-5d-forum-vertical-slice` is authored and dependency-gated on the foundation.
- The old planned `kenney-orthographic-3d-feasibility` and `kenney-3d-to-2d-production-feasibility` workstreams are canceled and must not be authored.
- Human approval after the Forum vertical slice gates any production rollout or asset-authoring standard.

## Active Reusable Source-Material Intake

- `KENNEY_PATTERN_LINES_SOURCE_LIBRARY.md` — ready/auto reference-only intake for all four user-downloaded Kenney Pattern Pack Lines variants (30 motifs each, 120 PNGs total), with exact-copy provenance, license/hash metadata, and a curated CUSTODIAN usage shortlist. It does not create runtime assets; production use must promote selected motifs through the owning Asset V2 family.

## Active Awakening 04→05 Production Art Refresh

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9

- `AWAKENING_ROOM_CONNECTORS_POLISH.md` — P1 ready/manual implementation packet. It consumes the user's local `~/Downloads/dust.png`, `connector.png`, and `locker.png` into the existing Dust Lung, 04→05 connector, and Locker Reliquary Asset V2 families; replaces the visible room-crossfade/room-strip seam machinery with direct registered art; reconciles the new Locker archive obstacles/P-9 bay; and keeps any still-missing Locker foreground honest rather than fabricating art.
- `REVIEW_AWAKENING_ROOM_CONNECTORS_POLISH.md` — paired P1 post-land code/runtime/visual/asset-pipeline review.
- `AWAKENING_HANDOFF_READINESS_ART_CONVERGENCE_V1.md` is now blocked/manual on the room-connectors polish and must be refreshed in place from the landed implementation + paired-review evidence before its old Zone04/05 feather/fade preservation clauses are executable again.
- `AWAKENING_04_05_CONNECTOR_TRANSITION_REGRESSION_GUARD.md` is also blocked/manual on the polish; after landing, first check whether the new packet's committed bidirectional regression fully supersedes it rather than duplicating the harness.

## Active Archive Resolve Presentation Series

Design authority: `../../../design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md`.

The Archive Resolve implementation series is evidence-gated. AR1/ARR1 are complete/passed. AR2 implementation landed on `085a38a5`, but its archived closeout explicitly lacked the mandatory real-renderer compile/runtime proof and human visual decision. The ingress-spawn hotfix/review are now complete/passed, so `PROCGEN_ARCHIVE_RESOLVE_SHADER_RECOVERY_1.md` is the active `ready/auto` renderer-closeout slice; the existing AR2 paired review now depends on that recovery. AR3 remains blocked/manual until the recovered AR2 review passes and this exact planning chat refreshes it. Subjective visual/game-feel approval stays in the Dropbox + user/ChatGPT review lane.

- `archived/PROCGEN_ARCHIVE_RESOLVE_PRESENTATION_SPINE.md` — AR1, complete/landed presentation-only request/commit/unload spine and one batched flat diagnostic veil.
- `archived/REVIEW_PROCGEN_ARCHIVE_RESOLVE_PRESENTATION_SPINE.md` — ARR1, complete: passed with 0 blocking defects; RFR1 R0-04 closed; next-slice items R0-01..R0-04 recorded on the archived AR1 packet.
- `archived/PROCGEN_ARCHIVE_RESOLVE_SHADER.md` — AR2 implementation landed on `085a38a5`; archived receipt records renderer/visual proof missing, so do not treat it as fully accepted.
- `PROCGEN_ARCHIVE_RESOLVE_SHADER_RECOVERY_1.md` — active renderer/visual closeout recovery; `ready/auto` after `review-contract-world-ingress-spawn-clearance-fix`; paired `REVIEW_PROCGEN_ARCHIVE_RESOLVE_SHADER.md` follows.
- `PROCGEN_ARCHIVE_RESOLVE_SEMANTIC_ECHO.md` — AR3, bounded semantic pre-echo, spawn resolve, and shortened reacquisition; blocked/manual until reviewed AR2 + ChatGPT/user refresh; paired `REVIEW_PROCGEN_ARCHIVE_RESOLVE_SEMANTIC_ECHO.md` is pre-authored.

The post-MR6 ProcGenTilemap rewrite packets carry temporary preservation guards
so extraction/contraction work cannot move or absorb the reveal seams before the
AR packet set is refreshed.

## Persistent Recovery Series

- Planning / refresh chat: https://chatgpt.com/c/6abca2bb-1b3c-83ea-a3ae-e3d368c88461?src=history_search
- `archived/CUSTODIAN_DEATH_HANDOFF_FOUNDATION.md` — R1 is complete: Operator death now resolves an active CampaignSession once before the temporary Game Over fallback; no-session worlds keep the safe fallback without inventing a campaign.
- `REVIEW_CUSTODIAN_DEATH_HANDOFF_FOUNDATION_RECOVERY_1.md` — formal R1 paired review remains ready/auto.
- `CUSTODIAN_POST_RECOVERY_REINTEGRATION.md` — R2 is materially refreshed but correctly `blocked/manual`; it depends on the formal R1 review and reviewed H6 `hub-campaign-return`. R2 owns exact death-outcome correlation, fallback suppression only after accepted generic return, Operator reintegration, and life-scoped death-latch re-arm. It must not duplicate H6 HubState mutation or Campaign->Hub return.
- `REVIEW_CUSTODIAN_POST_RECOVERY_REINTEGRATION.md` — paired post-land R2 review, dependency-gated on R2.
- Program tracker: `../../../design/02_features/operator/PERSISTENT_RECOVERY_IMPLEMENTATION_ROADMAP.md`.
- Design authority: `../../../design/02_features/operator/PERSISTENT_RECOVERY_AND_ARMAMENT_REGISTRATION.md`.
- Whenever a recovery implementation/review says its successor needs architecture/design refresh, the closing summary and user-facing reply must surface the exact planning / refresh chat URL above. Do not silently re-author the recovery sequence from chatless live state.

## Active Non-Player Actor Runtime Refactor Series

Non-player actor planning / refresh chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6abb151e-693c-83ea-8563-b7cd74c2960b?src=history_search

- Program tracker / architecture authority: `../../../design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md`.
- Expected program size: 11 implementation packets spanning standard combat-agent decomplexification, then commanded allies, fauna, encounter/social NPCs, static autonomous agents, and final compatibility cleanup.
- Current first-wave packet state:
  - `archived/ENEMY_MARINE_DASH_ABILITY_EXTRACTION.md` — NPA-1 implementation landed after all 23 changed-file checks passed; `MarineDash` owns the complete lifecycle and typed tuning with exact 26-field parity.
  - `REVIEW_ENEMY_MARINE_DASH_ABILITY_EXTRACTION_RECOVERY_1.md` — paired NPA-1 review is ready after implementation landing; verifies the 26-value parity, public request seam, host-service boundary, and full selected closeout.
  - `ENEMY_SAVAGE_POUNCE_ABILITY_EXTRACTION.md` — NPA-2 blocked/manual; must be refreshed in this planning chat after the passed NPA-1 review before promotion to ready/auto.
  - `REVIEW_ENEMY_SAVAGE_POUNCE_ABILITY_EXTRACTION.md` — paired NPA-2 review, blocked with NPA-2.
  - `ENEMY_SAVAGE_CHAIN_ABILITY_EXTRACTION.md` — NPA-3 blocked/manual; must be refreshed in this planning chat after the passed NPA-2 review.
  - `REVIEW_ENEMY_SAVAGE_CHAIN_ABILITY_EXTRACTION.md` — paired NPA-3 review, blocked with NPA-3.
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

For interactive Codex, the repository provides the repo-local
`$custodian-next` skill. It is also selectable from `/skills` and may appear
directly in the slash picker. It does not change dispatcher eligibility: it
continues an already-active workstream, otherwise prefers the durable immediate
`Next Handoff` in the same series, respects refresh/manual/dependency gates,
and uses global `claim-next` only when no same-series successor exists.

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
