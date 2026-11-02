# Scan Git State And Prepare Commits

TASK OVERRIDE: review only; do not stage, commit, or push. This audit/planning
workflow may inspect and propose exact actions, but does not mutate repository
state. Do not stash, reset, or delete files.

Repository defaults otherwise inherit from `custodian/AGENTS.md`.

## Task

Review the current Git state and propose logical commit boundaries for:
{{requested_scope}}

## Process

1. Inspect branch, recent history, and staged/unstaged/untracked paths.
2. Identify likely task ownership and generated, temporary, or unrelated files.
3. Propose commit groups with exact paths and any unresolved ownership.
4. Leave the index and repository state unchanged for the entire review.

Do not group by broad directories when they contain unrelated work. Do not
assume every dirty file belongs to the requested task.

## Output

- Branch and base commit
- Logical commit candidates with exact file lists
- Files that should remain untouched and why
- Validation gaps or ownership questions
