# RTK COMMAND ROUTING CORRECTION — TASK PACKET

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-23
- Created: 2026-05-23
- Last updated: 2026-05-23

## Task

Correct CUSTODIAN instructional docs that framed `rtk` as a generic command prefix instead of a CLI with named subcommands.

## Outcome

Agents should use RTK as `rtk <subcommand> ...`, for example `rtk git status`, `rtk grep ...`, and `rtk find ...`. Unsupported commands should use raw shell commands or `rtk proxy <command> ...` only when token tracking is useful.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: none
- Active runtime/docs files: `custodian/docs/ai_context/VALIDATION_RECIPES.md`, `custodian/docs/ai_context/AGENT_AUTOMATION_BACKLOG.md`, `custodian/docs/ai_context/task_packets/COGNITIVE_STATE_PHASE_B.md`
- Historical reference only: archived task packets and change-control bundles

## Work Surface

- Files or folders changed:
  - `AGENTS.md`
  - `custodian/AGENTS.md`
  - `custodian/docs/ai_context/VALIDATION_RECIPES.md`
  - `custodian/docs/ai_context/AGENT_AUTOMATION_BACKLOG.md`
  - `custodian/docs/ai_context/task_packets/COGNITIVE_STATE_PHASE_B.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
- Files or folders read but not changed:
  - `custodian/docs/ai_context/prompts/scan_git_commit.md`
  - `custodian/docs/ai_context/task_packets/README.md`
- Out-of-scope areas:
  - Archived change-control bundle snapshots.
  - Unrelated runtime and asset files.

## Constraints

- Determinism concerns: none; docs-only workflow correction.
- Simulation/UI boundary concerns: none.
- Asset requirements: none.
- Compatibility or migration concerns: preserve valid existing RTK examples such as `rtk git status`.
- Clarifying questions or assumptions: user confirmed `rtk git status` is the intended form and `rtk` alone can show usage.

## Implementation Plan

1. Audit active instruction docs for `rtk` command wording.
2. Replace generic-prefix wording with RTK subcommand/proxy guidance.
3. Validate no active instruction text recommends invalid bare RTK forms.

## Acceptance

- Runtime behavior: unchanged.
- Documentation: command-routing instructions distinguish RTK subcommands, `rtk proxy`, and raw commands.
- Path/reference validation: updated packet and file-index paths resolve.
- Manual validation: `rtk --help` verified the subcommand model.
- Automated/headless validation: targeted `rg` audits run against active instruction docs.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? No; runtime state unchanged.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No; local primers and validation recipes carry the workflow detail.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes; updated for related archived packet path drift.
- Does `custodian/AGENTS.md` need an update? Yes; updated.
- Do any design docs need an update? No.

## Completion Notes

- Implemented:
  - Root and local primers now describe RTK as subcommand-based.
  - Validation recipes now show valid RTK forms and proxy/raw fallbacks.
  - Cognitive task packet no longer says `rtk` is a prefix for all commands.
  - Automation backlog now checks for invalid bare RTK forms without embedding a misleading command.
- Validated:
  - `rtk --help` confirmed command structure.
  - Searched active instruction docs for stale prefix wording and invalid bare forms.
- Deferred:
  - Archived change-control bundles were not rewritten because they are historical snapshots.

## Next Steps

- Next action: use `rtk git status` or raw `git status --short` depending on whether compact summary or exact porcelain output is needed.
- Best starting files: `AGENTS.md`, `custodian/AGENTS.md`, `custodian/docs/ai_context/VALIDATION_RECIPES.md`.
- Required context: `rtk --help`.
- Validation to run: `rg -n 'rtk status|rtk prefix|prefix used|RTK wrappers' AGENTS.md custodian/AGENTS.md custodian/docs/ai_context -g '*.md'`.
- Blockers or open questions: none.
