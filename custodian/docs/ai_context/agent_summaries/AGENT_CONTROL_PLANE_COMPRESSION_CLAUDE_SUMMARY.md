# Agent Control-Plane Compression — Summary

## Changes

- Added an instruction-inheritance and delta-only prompt contract to
  `custodian/AGENTS.md`, including explicit `TASK OVERRIDE:` semantics,
  consequence-driven documentation edits, and validation compression.
- Changed root and custodian worktree guidance to prefer isolated worktrees for
  substantial parallel implementation. Shared-worktree tolerance is now
  incidental; staging other sessions' work is not routine.
- Removed duplicated repository defaults and unrelated Shrumb/CognitiveState
  guidance from reusable prompts. Preserved domain-specific acceptance such as
  combat-moment review, spritesheet input contracts, and procgen handoff checks.
- Replaced the scan/commit prompt's implicit approval conflict with an explicit
  audit/planning `TASK OVERRIDE:`.
- Changed the task packet template to delta fields: goal, measured state,
  authority, change, preserve, non-goals, acceptance, overrides, and deferred.
- Added `custodian/tools/agent/validate_prompt_contract.py`; documented its
  template gate and full active-packet scan in the prompt README and automation
  backlog; added it to FILE_INDEX.

## Validation

- `python3 custodian/tools/agent/validate_prompt_contract.py --templates-only --strict --self-test` — passed; zero template violations.
- `python3 custodian/tools/agent/validate_prompt_contract.py` — passed; zero repeated defaults found in reusable prompts, packet template, or active task packets.
- `python3 -m py_compile custodian/tools/agent/validate_prompt_contract.py` — passed.
- `git diff --check` — passed.

Historical/archived task packets were left unchanged. Runtime behavior and
validation manifest were not changed.
