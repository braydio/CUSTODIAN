# AGENT AUTOMATION BACKLOG

Last updated: 2026-09-28

Prioritized automation candidates for CUSTODIAN agent workflow. These are intentionally lightweight checks first; avoid adding a large framework until the simple checks prove insufficient.

## Current Implementation Audit

The prompt-template contract linter is implemented at
`custodian/tools/agent/validate_prompt_contract.py`. It flags repeated
repository-default boilerplate in reusable prompts and active task packets,
supports explicit `TASK OVERRIDE:` lines, and has a focused validation-manifest
entry. Automatic main landing is implemented at
`custodian/tools/agent/land_main.py`; it serializes local landing attempts,
rebases clean landing copies on current `origin/main`, retries bounded races,
and aborts conflicts without force-pushing. `workstream.py` now owns normal
implementation runs in isolated ephemeral worktrees, with push-first checkpoint
and finish paths. Its published-history guard allows only the current branch's
own upstream. `branch_hygiene.py` reports ancestry-based dispositions by default
and archive-tags unique history before optional retirement. Review-only work is
the explicit exception. Broader AI-context and task-packet validators below
remain follow-up proposals.

Moment Forge is now implemented separately under
`custodian/tools/iteration/`. It was prioritized first because deterministic
visual/audio/game-feel comparison provides direct production leverage across
combat, animation, VFX, healing, and vista work.


## Implemented — Repository Task Dispatcher

The dispatcher implementation and acceptance record are in
`custodian/tools/agent/dispatch.py` and the archived packet at
`custodian/docs/ai_context/task_packets/archived/AGENT_TASK_DISPATCH.md`.
The archived packet is historical; the live tool is the current authority.

Goal:

- treat fetched `origin/main` task packets as the durable job board;
- add explicit safe auto-dispatch metadata with manual-by-default behavior;
- let any local Codex terminal claim exactly one eligible workstream;
- delegate branch/worktree creation to existing `workstream.py`;
- use dependencies and narrow locks to prevent invalid concurrent work;
- eliminate packet copy/paste and terminal-to-task bookkeeping by the user.

`custodian/tools/agent/dispatch.py` reads packet truth from fetched
`origin/main`, safely defaults missing dispatch metadata to manual, sorts
eligible tasks by priority and packet path, enforces completed dependencies and
narrow locks, serializes local claims, and delegates worktree lifecycle to
`workstream.py`. V1 stops after one claim and uses a temporary create-only
remote Git ref to serialize initial claims across clones. Continuous workers,
lease expiry, and a generated packet README remain deferred.


### Next bootstrap stage — independent review

The dispatcher is implemented, including its second-pass remote-claim and
coordination-path corrections. The review pipeline is the next queued bootstrap
stage.

Queued behind the dispatcher:

- `task_packets/AGENT_REVIEW_PIPELINE.md` — adds packet-level review contracts,
  independent post-land reviewer workstreams, durable review receipts, bounded
  correction/re-review generation, and human escalation for unresolved judgment.
- `task_packets/REVIEW_AGENT_REVIEW_PIPELINE.md` — uses the new machinery to
  independently review the review pipeline itself.

The review stage reuses dispatcher/workstream primitives rather than adding a
second queue. Pre-land review, continuous workers, distributed leasing, and
automatic subjective baseline acceptance remain deferred.

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

## Priority 3 — Prompt Template Path Validator

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
