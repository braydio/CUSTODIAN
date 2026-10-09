# CORRECTION: LIVING-WORLD ABSTRACT ACTIVITY FOUNDATION REVIEW

- Packet schema: `custodian.task_packet.v2`
- Workstream: `living-world-abstract-activity-foundation-review-corrections-1`
- Kind: `correction`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-living-world-abstract-activity-foundation`
- Locks: `world-simulation-runtime, living-world-abstract-activity`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime`
- Paired review workstream: `review-living-world-abstract-activity-foundation-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Reviewed main: `c447db62d`
- Parent implementation: `living-world-abstract-activity-foundation` — `custodian/docs/ai_context/task_packets/archived/LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION.md`
- Parent review: `review-living-world-abstract-activity-foundation` — `custodian/docs/ai_context/task_packets/archived/REVIEW_LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION.md`
- Findings addressed: `R0-01`
- Affected acceptance: Parent implementation acceptance (3) deterministic event sequence and (4) snapshot continuation/fingerprint; acceptance (6) fail-closed identity handling.
- Current defect/evidence: `AbstractActivitySimulationState` permits periods in domain/group IDs but constructs event IDs by joining both IDs with periods. Valid pairs `a.b`/`c` and `a`/`b.c` both emit `a.b.c.60`; snapshot restore rejects the resulting duplicate event IDs.
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Goal: Ensure every accepted domain/group identity pair produces collision-free causal event IDs and remains snapshot-restorable.
- Completion boundary: Correct the event identity encoding and add a focused regression proving distinct legal identities remain distinct through event generation, snapshot capture, and restore.
- Current measured state: The existing abstract-activity smoke passes, but a fresh probe demonstrated colliding IDs and a failed restore for two legal identity pairs.
- Evidence: Review finding `R0-01`; focused probe output `event_ids=["a.b.c.60", "a.b.c.60"]`, `ids_unique=false`, `snapshot_restore_is_null=true`.
- Task-specific authority: F14 V1 bounded activity lock; parent implementation acceptance and snapshot fingerprint contract.
- Work surface: `custodian/game/state/world/abstract_activity_simulation_state.gd` and `custodian/tools/validation/world_simulation_abstract_activity_smoke.gd`; manifest only if changed-file selection requires it.
- Required correction: Use a deterministic unambiguous event-ID encoding (or stricter identity grammar that preserves the documented accepted identity contract); add a regression with the colliding pair and assert unique event IDs plus successful canonical snapshot restore.
- Preserve: Existing domain-scoped group identity, stable deterministic ordering, causal event contents, schema-v5 serialization, v4 migration, bounded event history and kernel ownership.
- Non-goals: No actor handoff/reification, geography binding, combat, resource mutation, REMAP-3 persistence, or unrelated ID redesign.
- Acceptance:
  1. The valid pairs `a.b`/`c` and `a`/`b.c` generate distinct stable event IDs at the same tick.
  2. A snapshot containing both events restores successfully and preserves the canonical fingerprint/event sequence.
  3. The existing abstract-activity, kernel, macro-state and snapshot-roundtrip smokes remain green.
- Validation: Run the focused abstract-activity smoke, relevant kernel/macro-state/snapshot-roundtrip smokes, changed-file validation once at closeout, and `git diff --check`.
- Task overrides: `none`
- Deferred: F14-C handoff/reification and F14-D REMAP-3 persistence remain gated as before.

## Delta Rules

- Address only `R0-01`; do not reopen the original F14-B scope.
- The paired review retains `R0-01` and reports it as fixed, unresolved, or regressed.
- A new blocking defect may use the next cycle-scoped finding ID, subject to the inherited two-cycle limit.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: Fresh Godot project initialization reimported 9,662 assets and generated nine unrelated reference-art `.import` sidecars; those exact sidecars were removed after validation. An exploratory Python bytecode command was also mistakenly applied to a GDScript file and rejected as invalid syntax; Godot parser validation remained the source of truth.
- Root cause / contributing factors: The ephemeral worktree had no Godot import cache, and the `.gd` file was mistakenly passed to a Python-only syntax tool.
- Prevention / pipeline improvement: Initialize Godot project metadata before focused GDScript validation; use Godot validation for `.gd` files.
- Tooling / docs drift discovered: none
- Follow-up: `review-living-world-abstract-activity-foundation-review-corrections-1`
- What worked: The focused smoke directly covered two formerly colliding legal identities, snapshot restore/fingerprint continuity, and compatibility with existing schema-v5 event IDs.

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Refresh instruction: Keep the correction limited to collision-free event identity and restore proof; do not expand into F14-C or REMAP-3.

## Handoff

- Next action: Start a fresh reviewer context and claim the paired correction review after this correction lands and archives complete.
- Blockers or open questions: none; paired review requires a fresh reviewer context.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: Focused abstract-activity smoke (including collision, snapshot fingerprint, and legacy schema-v5 ID restore); kernel, macro-state, and snapshot-roundtrip smokes; changed-file validation (2 selected, 2 passed); `git diff --check`; packet-pair authoring preflight and managed index check.

## Independent Review

- Status: `passed`
- Review workstream: `review-living-world-abstract-activity-foundation-review-corrections-1`
- Reviewed on main: `a012988f373a61bf076d71bf2113842851dde66e`
- Review modes: `code, runtime`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Blocking defects: `0`
- Material evidence gaps: `0`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Retained finding dispositions: `R0-01 fixed`
- Correction finding IDs: `none`
- Next-slice finding IDs: `none`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_LIVING_WORLD_ABSTRACT_ACTIVITY_FOUNDATION_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md`
- Follow-up workstream: `none`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31`

### Review Notes

- `R0-01` is fixed: new causal IDs length-prefix domain and group identities, eliminating the demonstrated collision without narrowing accepted dotted IDs.
- The focused collision fixture and abstract-activity, kernel, macro-state, and snapshot-roundtrip smokes passed. Legacy schema-v5 dotted event restore also passed.
- No new finding was identified; F14-C handoff/reification and F15 production geography remain outside this correction scope.
