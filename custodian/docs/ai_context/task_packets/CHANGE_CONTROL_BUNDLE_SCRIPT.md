# Change Control Bundle Script

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-19
- Created: 2026-05-19
- Last updated: 2026-05-19

## Task

Add a script that accepts a task packet name, concatenates current changed files into one markdown bundle, writes it to `custodian/docs/change_control/<TASK_PACKET_NAME>.md`, and copies the bundle to the system clipboard when a clipboard command is available.

## Outcome

Agents and the user can run one command after a task to produce a clearly labeled review/change-control artifact from the current git worktree.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: none required for this utility
- Active runtime/docs files: `custodian/tools/agent/`, `custodian/docs/change_control/`, `custodian/docs/ai_context/FILE_INDEX.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change: `custodian/tools/agent/change_control_bundle.py`, `custodian/docs/change_control/`, AI context docs.
- Files or folders expected to be read but not changed: task packet directories and git worktree state.
- Out-of-scope areas: committing, staging, diff generation, destructive cleanup.

## Constraints

- Determinism concerns: none.
- Simulation/UI boundary concerns: none.
- Asset requirements: binary changed files should be listed but not inlined.
- Compatibility or migration concerns: support active and archived task packet names with or without `.md`.
- Clarifying questions or assumptions: "changed files" means current git status including staged, unstaged, and untracked files.

## Implementation Plan

1. Add the script with git-status parsing, binary detection, markdown bundling, and clipboard fallback handling.
2. Ensure output directory exists and output filename is sanitized from the task packet name.
3. Update AI context index/docs and validate by running the script plus lint/compile checks.

## Acceptance

- Runtime behavior: script writes `custodian/docs/change_control/<TASK_PACKET_NAME>.md`.
- Documentation: AI context index mentions the utility.
- Path/reference validation: script resolves repo root and task packet paths from any working directory.
- Manual validation: run the script against this packet.
- Automated/headless validation: `python -m py_compile` and `git diff --check`.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? No runtime state change.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No.

## Completion Notes

- Implemented: added `custodian/tools/agent/change_control_bundle.py`, which resolves the repo root, accepts a task packet name with or without `.md`, finds active/archived packets, snapshots current git-changed files, writes `custodian/docs/change_control/<TASK_PACKET_NAME>.md`, labels each file section clearly, omits binary inline content, and attempts clipboard copy through common desktop clipboard tools.
- Validated: `python -m py_compile custodian/tools/agent/change_control_bundle.py`; smoke-tested with `python custodian/tools/agent/change_control_bundle.py CHANGE_CONTROL_BUNDLE_SCRIPT`; `git diff --check` on touched files.
- Deferred: clipboard copy could not be proven inside this session because the sandbox cannot access the Wayland/X display sockets; the script will copy when run from a desktop shell with `wl-copy`, `xclip`, `xsel`, `pbcopy`, or `clip.exe`.

## Next Steps

- Next action: run `python custodian/tools/agent/change_control_bundle.py <TASK_PACKET_NAME>` after a task when a change-control bundle is needed.
- Best starting files: `custodian/tools/agent/`
- Required context: current git worktree status.
- Validation to run: optional desktop-shell run to confirm clipboard access in the user's normal environment.
- Blockers or open questions: none.
