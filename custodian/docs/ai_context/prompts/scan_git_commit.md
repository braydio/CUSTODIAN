# Scan Git State And Prepare Commits

TASK OVERRIDE: This is an audit/planning workflow. Do not stage, commit, stash,
reset, or delete files until the user explicitly approves the proposed action.

Repository defaults otherwise inherit from `custodian/AGENTS.md`.

## Task

Review the current Git state and propose logical commit boundaries for:
{{requested_scope}}

## Process

1. Inspect branch, recent history, and staged/unstaged/untracked paths.
2. Identify likely task ownership and generated, temporary, or unrelated files.
3. Propose commit groups with exact paths and any unresolved ownership.
4. Wait for explicit approval before changing the index or repository state.

Do not group by broad directories when they contain unrelated work. Do not
assume every dirty file belongs to the requested task.

## Output

- Branch and base commit
- Logical commit candidates with exact file lists
- Files that should remain untouched and why
- Validation gaps or ownership questions
