# AGENT AUTOMATION BACKLOG

Last updated: 2026-05-03

Prioritized automation candidates for CUSTODIAN agent workflow. These are intentionally lightweight checks first; avoid adding a large framework until the simple checks prove insufficient.

## Priority 1 — AI Context Validator

Suggested path: `custodian/tools/agent/check_ai_context.py`

Purpose:

- catch stale doc paths before handoff
- confirm required AI context files exist
- confirm task packets include the compact required fields or valid legacy/full sections
- confirm prompt templates reference `custodian/AGENTS.md`, not stale paths

Checks:

- `custodian/docs/ai_context/VALIDATION_RECIPES.md` exists
- `custodian/docs/ai_context/prompts/README.md` exists
- every new `custodian/docs/ai_context/task_packets/*.md` contains the compact required fields; legacy/full packets remain valid
- no prompt references `custodian/docs/ai_context/AGENTS.md`, `PAIPELINE.md`, `operator_weapon_definition.tres`, or invalid bare RTK forms that omit the needed RTK subcommand
- `FILE_INDEX.md` references new workflow docs

Why first:

- high signal
- fast to run
- docs-only
- catches the exact drift already found

## Priority 2 — Task Packet Linter

Suggested path: `custodian/tools/agent/check_task_packets.py`

Purpose:

- enforce packet status and handoff quality without requiring packets for every task
- detect completed packets with empty completion or next-step notes
- detect full packets with incomplete ownership fields

Checks:

- valid status value
- compact required fields are present
- full packets with ownership metadata have parseable `Last updated` values
- `complete` packets have non-empty completion and deferred-work notes
- `blocked` packets have a blocker or open question

Why second:

- useful once multiple agents are active
- protects against ambiguous handoffs

## Priority 3 — Prompt Template Validator

Suggested path: `custodian/tools/agent/check_prompts.py`

Purpose:

- keep reusable prompts from drifting as files move
- make prompts safe before agents copy them into tasks

Checks:

- every prompt includes `custodian/AGENTS.md`
- every prompt includes `custodian/docs/ai_context/VALIDATION_RECIPES.md`
- implementation prompts describe risk-based packet selection
- Git prompt requires explicit approval before staging or committing
- all referenced static paths exist unless they contain placeholders like `[TASK_PACKET]`

Why third:

- prevents recurring stale-path bugs
- makes prompt templates trustworthy enough for repeated use

## Priority 4 — Validation Recipe Runner

Suggested path: `custodian/tools/agent/validate_docs.py`

Purpose:

- bundle common doc-only validation into one command
- provide a clean target for agents after documentation changes

Checks:

- run AI context validator
- run prompt validator
- run task packet linter
- report missing paths and stale references

Why fourth:

- useful after the smaller validators exist
- keeps the command surface simple

## Priority 5 — Git Safety Scanner

Suggested path: `custodian/tools/agent/check_git_safety.py`

Purpose:

- help agents propose commits without staging unrelated user work

Checks:

- summarize modified/untracked files by domain
- flag broad directory staging risks
- flag deleted files separately
- identify generated/import files separately
- output commit candidate groups without running `git add` or `git commit`

Why fifth:

- valuable, but more judgment-heavy than docs validation
- should assist humans/agents, not automate commits

## Recommended Implementation Order

1. `check_ai_context.py`
2. `check_task_packets.py`
3. `check_prompts.py`
4. `validate_docs.py`
5. `check_git_safety.py`

## Command Shape

Prefer simple repository-root commands:

```bash
python3 custodian/tools/agent/check_ai_context.py
python3 custodian/tools/agent/check_task_packets.py
python3 custodian/tools/agent/check_prompts.py
python3 custodian/tools/agent/validate_docs.py
python3 custodian/tools/agent/check_git_safety.py
```

Once stable, add these commands to `custodian/docs/ai_context/VALIDATION_RECIPES.md`.
