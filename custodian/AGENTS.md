# CUSTODIAN AGENTS PRIMER

Mandatory entrypoint for any agent or developer working inside `custodian/`.

If you entered from the repository root, stop here first before changing runtime code, docs, assets, pipelines, or design references.

## Mission

This primer exists to route all work through one consistent authority chain, one current-state summary, and one repeatable process for:

- finding the right active docs quickly
- checking adjacent files before editing
- detecting documentation drift
- remediating drift before it compounds
- executing migrations without leaving stale references behind

## First-Read Order

Read these in order before making changes:

1. `../design/` for active Godot-native implementation specs
2. `docs/ai_context/CURRENT_STATE.md` for the latest runtime and documentation state
3. `docs/ai_context/CONTEXT.md` for project rules and handoff context
4. `docs/ai_context/FILE_INDEX.md` for high-signal file ownership and entrypoints
5. `docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md` and any relevant packet in `docs/ai_context/task_packets/` for non-trivial work
6. `docs/ai_context/VALIDATION_RECIPES.md` and relevant prompt templates in `docs/ai_context/prompts/`
7. Relevant runtime/docs files for the feature or asset area you are touching

If a conflict appears, prefer this authority order:

1. `../design/`
2. `../python-sim/design/MASTER_DESIGN_DOCTRINE.md`
3. `docs/*`
4. legacy Python-era design or AI docs only as historical reference

## Current Design And Development State

- Active runtime authority is the Godot 4.x project in `custodian/`
- Active implementation specs live in `../design/`
- Active AI-facing context pack lives in `docs/ai_context/`
- Legacy Python runtime and Python AI context are historical reference only
- Deterministic fixed-step simulation remains a hard constraint
- Rendering/UI logic should not silently absorb simulation authority

## Routing Map

Use this map to land on the right material fast:

| Need | Read First | Then Check |
|---|---|---|
| Runtime feature behavior | `../design/` matching feature/system doc | `game/` scripts and `docs/ai_context/*` |
| Architecture or ownership | `docs/ai_context/FILE_INDEX.md` | `docs/ARCHITECTURE.md`, `../design/03_architecture/` |
| Current implementation status | `docs/ai_context/CURRENT_STATE.md` | `../design/TRACKING.md`, active feature docs |
| Asset layout or content placement | `docs/ASSET_LAYOUT_CONVENTION.md` | nearby `README.md` files in `content/` |
| Scene/runtime structure | `docs/SCENE_HIERARCHY.md` | `scenes/`, `game/`, `project.godot` |
| Migration or drift cleanup | `docs/AGENT_MIGRATION_PLAYBOOK.md` | this primer, `docs/ai_context/*` |
| Validation command selection | `docs/ai_context/VALIDATION_RECIPES.md` | relevant task packet acceptance checks |
| Reusable agent prompts | `docs/ai_context/prompts/README.md` | task-specific prompt template |
| Agent workflow automation | `docs/ai_context/AGENT_AUTOMATION_BACKLOG.md` | `tools/agent/` when scripts exist |

## Reusable Context Fetch Pipeline

Before editing, run this retrieval pipeline:

1. Define the work surface.
   Identify the exact runtime area, doc area, or asset area being changed.
2. Pull the active authority.
   Read the matching file in `../design/` first.
3. Pull current state.
   Read `docs/ai_context/CURRENT_STATE.md` and `docs/ai_context/FILE_INDEX.md`.
4. Check task packet requirements.
   For non-trivial implementation, review, migration, validation, asset workflow, or multi-file docs work, create or update a packet from `docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md` under `docs/ai_context/task_packets/`.
5. Pull validation and prompt guidance.
   Read `docs/ai_context/VALIDATION_RECIPES.md` and any matching prompt template in `docs/ai_context/prompts/`.
6. Pull adjacent context.
   Read neighboring docs, scene files, READMEs, and directly related scripts/assets.
7. Pull historical context only if still unresolved.
   Use `../python-sim/` or archived docs only to explain intent, not to override active authority.
8. Record any mismatch immediately.
   If names, paths, behavior, or ownership disagree, treat that as drift and remediate before or alongside the main change.

Minimum adjacency check:

- the file you will edit
- one upstream authority doc
- one downstream runtime or content consumer
- one neighboring doc or index that would become stale if ignored
- the relevant task packet when the work requires one
- the validation recipe and prompt template when the work matches one

## Agent Task Packets

Task packets are task-scoped planning and handoff records for work that is large enough to risk ambiguity or documentation drift.

Use a packet for:

- runtime behavior changes
- architecture or ownership changes
- validation workflow changes
- asset pipeline or production asset workflow changes
- migrations and docs-drift cleanup
- multi-file documentation changes
- reviews that produce follow-up implementation work

Task packet workflow:

1. Copy `docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md` into `docs/ai_context/task_packets/`.
2. Name the copy after the task, for example `VALIDATION_RECIPES.md`.
3. Fill task, outcome, authority, work surface, constraints, plan, acceptance, and drift review before implementation.
4. Keep packet status and assumptions current as scope changes.
5. Mark the packet `complete` only after implementation, documentation updates, feasible validation, and completion notes are done.

Task packets do not replace design docs. Use `../design/` as implementation authority, and use task packets to make the current agent slice explicit.

## Prompt Templates And Validation

Reusable prompts live in `docs/ai_context/prompts/`.

Use these agent work modes:

- Design Audit: compare active design docs, AI context, and runtime files for drift before implementation.
- Implementation: make the scoped change, update active docs, and run feasible validation.
- Review: inspect diffs for behavior regressions, determinism risks, stale paths, missing validation, and unsafe workflow assumptions.

Use these prompts to standardize recurring agent work:

- runtime feature implementation
- runtime change review
- docs-drift review
- sprite pipeline updates
- procgen handoff inspection
- combat feel tuning
- git state and commit preparation

Validation recipes live in `docs/ai_context/VALIDATION_RECIPES.md`.

Use the recipes to choose the narrowest command that proves the change. Prefer RTK wrappers for compact output when they support the command shape, and use raw commands when RTK argument rewriting would hide or alter needed output.

When editing a design doc that will drive follow-up implementation, add or refresh a `Next Agent Slice` section with goal, files, constraints, and acceptance checks. This keeps design docs usable as executable work queues without replacing task packets.

Planned automation for these workflows is tracked in `docs/ai_context/AGENT_AUTOMATION_BACKLOG.md`. Add scripts only when they support a listed check or update the backlog with the new rationale.

## Docs Drift Review

Treat any of the following as documentation drift:

- a path moved but indexes still point to the old location
- implementation status changed but `docs/ai_context/` was not updated
- runtime behavior changed but design/docs still describe the old behavior
- a migration created duplicate instructions with no clear primary source
- asset layout changed but submission/layout conventions were left behind

Drift review checklist:

1. Does the active design doc still describe the current implementation target?
2. Does `docs/ai_context/CURRENT_STATE.md` still describe the live state?
3. Does `docs/ai_context/FILE_INDEX.md` still point to the right entry files?
4. Does any README or local guide still route newcomers to deprecated paths?
5. Did this change create a new local authority that needs to be indexed?

## Drift Remediation Procedure

When you detect drift, do this automatically unless the user explicitly says not to:

1. Update the primary authority doc first.
2. Update `docs/ai_context/CURRENT_STATE.md` if runtime state, ownership, or workflow changed.
3. Update `docs/ai_context/CONTEXT.md` if the working model or guardrails changed.
4. Update `docs/ai_context/FILE_INDEX.md` if entry files, locations, or ownership changed.
5. Update the relevant task packet if scope, acceptance, status, or deferred work changed.
6. Update local routing docs such as `README.md` or folder `README.md` files if discoverability changed.
7. Note any intentionally deferred cleanup explicitly so the drift is tracked, not hidden.

## Migration Execution Instructions

Use this whenever you are restructuring docs, moving asset guidance, consolidating primers, or changing canonical paths.

1. Define the new canonical destination.
   Example: `custodian/AGENTS.md` becomes the local entrypoint for all work under `custodian/`.
2. Add the destination before deleting or de-emphasizing old routes.
3. Add prominent routing from every high-probability entrypoint.
   Typical entrypoints: repository `AGENTS.md`, local `README.md`, AI context indexes, and directory `README.md` files.
4. Migrate current state into the new destination.
   Do not create an empty shell that only links elsewhere.
5. Update the indexes and context pack.
6. Validate that old entrypoints now forward clearly to the new canonical location.
7. Leave historical docs in place unless removal is explicitly requested.

## Expected Behavior For Agents

- Ask concise clarification questions when ambiguity would risk wrong work.
- State temporary assumptions when you proceed under uncertainty.
- Keep deterministic gameplay logic separate from presentation logic.
- Do not silently promote legacy Python docs back into active authority.
- When changing behavior or architecture, update docs as part of the same task.

## Migration Shortcut

If the task is “where do I start?” or “what do I read first?”, the answer for `custodian/` work is:

1. `custodian/AGENTS.md`
2. `custodian/docs/ai_context/CURRENT_STATE.md`
3. the relevant file in `design/`
