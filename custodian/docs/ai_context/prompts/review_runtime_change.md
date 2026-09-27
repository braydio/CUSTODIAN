# Review Runtime Change

Repository workflow and review defaults are inherited from
`custodian/AGENTS.md`.

## Task

Review this runtime change: {{change_or_diff_scope}}

**Active design authority:** {{design_doc}}

**Relevant task acceptance:** {{acceptance_or_none}}

## Output

Report findings first, with file and line references. Prioritize behavior or
determinism regressions, ownership leaks, stale documentation, missing proof
for the changed behavior, and unsafe side effects. Distinguish confirmed
failures from questions or assumptions. Summarize the change only after
findings.
