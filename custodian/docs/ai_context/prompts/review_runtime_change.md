# Review Runtime Change

Read `custodian/AGENTS.md` first.
Then read `CURRENT_STATE.md`, `FILE_INDEX.md`, any relevant existing task packet, and the linked design doc.

## Task

Review this runtime change: **[change_or_diff_scope]**

## Review Priority

Findings first. Prioritize:

- behavior regressions
- determinism risks
- simulation/UI authority leaks
- stale docs or paths
- missing validation
- unsafe asset or git workflow side effects

## Context Files

- `custodian/AGENTS.md` - local routing and working rules
- `custodian/docs/ai_context/CURRENT_STATE.md` - live runtime state
- `custodian/docs/ai_context/FILE_INDEX.md` - file ownership map
- `custodian/docs/ai_context/VALIDATION_RECIPES.md` - validation command guide
- Task packet, when one exists: `custodian/docs/ai_context/task_packets/[TASK_PACKET].md`
- Design doc: `design/[feature_path].md`

## Output

- Findings with file and line references
- Open questions or assumptions
- Validation performed or still needed
- Brief change summary only after findings
