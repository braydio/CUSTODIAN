# DEV OBSERVATORY AUDIT REMEDIATION

- Status: `in_progress`
- Authority: `DEV_OBSERVATORY_AUDITS.md`; `design/02_features/debug_ui/DEVELOPER_OBSERVATORY_SYSTEM.md`
- Goal: Implement the audit's observability contract fixes and harden the debug-only procgen unstuck rescue without changing combat balance or simulation authority.
- Files: Observatory runtime/analyzer, Operator/enemy combat telemetry, procgen walkability diagnostics, world-state/history telemetry, focused validation, and active AI-context docs.
- Constraints: Observatory remains presentation/diagnostics-only; stable reason identifiers; no combat balance changes; no generated-world authority moves into debug code.
- Acceptance: Ranged attempts reconcile; enemy hits share attack IDs; dodge/Field Patch/stamina outcomes are observable; warnings report truncation honestly; legacy/director AI gauges are distinct; rescue destinations pass stronger safety checks and export forensic context; focused smokes pass.
- Completed: Audit mapped to current runtime ownership.
- Deferred: None yet.

## Ownership And Timing

- Owner: gameplay/tools
- Agent/session: Codex
- Created: 2026-07-14
- Last updated: 2026-07-14

## Work Surface

- Read: Audit, Observatory authority, combat/procgen runtime, analyzer, validation recipes, current-state/index docs.
- Change: Instrumentation and debug safety only.
- Out of scope: Weapon/enemy balance, procgen aesthetic tuning, new gameplay mechanics, AI noise behavior.

## Plan

1. Stabilize ranged failure/request and enemy attack-chain telemetry.
2. Harden rescue landing selection and expand stuck forensic snapshots.
3. Add missing dodge, Field Patch, stamina, AI ownership, node/performance, and world-state telemetry.
4. Fix analyzer report consistency and add focused validation.
5. Update active docs and complete the packet after validation.

## Drift Review

- Primary authority: Update Developer Observatory and relevant active feature docs; ignore retired `design/20_features/` paths quoted by the audit.
- `CURRENT_STATE.md`: Update runtime instrumentation state.
- `CONTEXT.md`: Update only if guardrails change.
- `FILE_INDEX.md`: Index new/expanded validation and ownership entrypoints.
- Local routing/readmes: No new routing authority planned.

## Handoff

- Next action: Implement stable telemetry helpers and rescue safety predicates.
- Best starting files: `operator.gd`, `enemy.gd`, `proc_gen_tilemap.gd`, `dev_observatory.gd`, analyzer.
- Validation to run: Dev Observatory, procgen stuck-pocket, ranged/combat, dodge/Field Patch focused smokes plus headless parse.
- Blockers or open questions: None.
