# DEV OBSERVATORY AUDIT REMEDIATION

- Status: `complete`
- Authority: `DEV_OBSERVATORY_AUDITS.md`; `design/02_features/debug_ui/DEVELOPER_OBSERVATORY_SYSTEM.md`
- Goal: Implement the audit's observability contract fixes and harden the debug-only procgen unstuck rescue without changing combat balance or simulation authority.
- Files: Observatory runtime/analyzer, Operator/enemy combat telemetry, procgen walkability diagnostics, world-state/history telemetry, focused validation, and active AI-context docs.
- Constraints: Observatory remains presentation/diagnostics-only; stable reason identifiers; no combat balance changes; no generated-world authority moves into debug code.
- Acceptance: Ranged attempts reconcile; enemy hits share attack IDs; dodge/Field Patch/stamina outcomes are observable; warnings report truncation honestly; legacy/director AI gauges are distinct; rescue destinations pass stronger safety checks and export forensic context; focused smokes pass.
- Completed: Stable ranged taxonomy/request metrics; shared attack-chain IDs; dodge/Field Patch/stamina telemetry; director/legacy and node ownership gauges; structured world-state/history metadata; stronger rescue selection and forensic reports; honest warning truncation; focused smokes/docs; Vista Approach gate/key/enemy-marker and blocker removal with unconditional end traversal.
- Deferred: Production combat-balance tuning remains intentionally out of scope. Existing missing `unarmed_run_cape` animation and headless ObjectDB/resource-leak diagnostics remain loud, pre-existing validation noise.

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

- Next action: Run a targeted live playtest and inspect the next F10 export for zero internal ranged failures, zero runtime traps/rescues, and attack-chain reconciliation.
- Best starting files: `operator.gd`, `enemy.gd`, `proc_gen_tilemap.gd`, `dev_observatory.gd`, analyzer.
- Validation to run: Dev Observatory, procgen stuck-pocket, ranged/combat, dodge/Field Patch focused smokes plus headless parse.
- Blockers or open questions: None. All selected focused smokes pass.
