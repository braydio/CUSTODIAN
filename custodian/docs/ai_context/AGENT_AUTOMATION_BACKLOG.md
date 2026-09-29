# AGENT AUTOMATION BACKLOG

Last updated: 2026-09-29

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
and archive-tags unique history before optional retirement. Truly read-only
reviews remain the explicit exception; paired post-land reviews use bounded
durable artifact commits. Broader AI-context and task-packet validators below
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
remote Git ref to serialize initial claims across clones. Continuous workers and lease expiry remain deferred. Full README generation remains deferred; bounded Ready / Auto Dispatch index synchronization is queued in `task_packets/TASK_PACKET_INDEX_AUTOMODE_HARDENING.md`.


## Implemented — Paired Post-Land Review

The dispatcher is implemented, including its second-pass remote-claim and
coordination-path corrections. Independent post-land review is now implemented
on top of it at `custodian/docs/ai_context/task_packets/archived/AGENT_REVIEW_PIPELINE.md`
(archived, historical; the live authority is `dispatch.py`, `task_packets/README.md`'s
Paired Review And Correction section, and `AGENT_REVIEW_PACKET_TEMPLATE.md`).

`dispatch.py` extends its packet parser with the review metadata contract
(`Kind`, `Review`, `Review stage`, `Review modes`, `Paired review workstream`,
`Review cycle`, `Max automatic review cycles`, `Review target workstream/packet`)
and a `validate_review_pairing` consistency guard. It now also validates the
bounded review-artifact override on auto review packets and resolves explicit
validation script references in ready packets against tracked live tool paths,
with closest-path diagnostics. These checks are wired into eligibility
(`_decision`) and a standalone smoke
(`custodian/tools/agent/validate_review_pairing.py`, registered in
`validation_manifest.json` as `review_pairing_contract`). Review packets reuse
ordinary `Dispatch`/`Depends on`/`Locks` — a review becomes eligible exactly
when its implementation dependency completes and archives, with no second
scheduler. `review-agent-review-pipeline` is this feature's own first paired
review, per its self-bootstrap requirement.

The V2 review authoring contract now gives findings stable cycle-scoped IDs,
class/domain/disposition fields and acceptance/evidence links. Correction
thresholds route only confirmed defects and material proof gaps into delta
correction packets; process findings use task feedback. Paired reviews may
autonomously commit only their bounded durable review artifacts. Pre-land
review, continuous workers, distributed leasing, a historical review log
beyond the single durable receipt per implementation packet, and automatic
subjective baseline acceptance remain deferred.

## Priority 1 — AI Context Validator

Queued implementation packet: `custodian/docs/ai_context/task_packets/AI_CONTEXT_TASK_PACKET_VALIDATOR.md`.

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

## Priority 1.5 — Task Packet Index Auto-Maintenance

Queued implementation packet: `custodian/docs/ai_context/task_packets/TASK_PACKET_INDEX_AUTOMODE_HARDENING.md`.

Purpose:

- keep the visible Ready / Auto Dispatch board synchronized with packet metadata;
- avoid a second queue grammar by reusing dispatcher/AI-context packet parsing;
- provide deterministic read-only drift detection plus an explicit bounded write mode;
- preserve manual-ready, in-progress, recently-complete, and prose sections outside the managed block.

The scope is deliberately smaller than full README generation. Automatic lifecycle-state derivation and historical residue cleanup remain separate concerns.

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
