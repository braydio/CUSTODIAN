# CUSTODIAN Repository Router

This repository contains multiple eras of the project. For all active Godot work under `custodian/`, the mandatory local authority and workflow primer is:

1. `custodian/AGENTS.md`
2. the matching implementation spec under `design/`
3. `custodian/docs/ai_context/CURRENT_STATE.md`

Active Godot feature specifications live under `design/02_features/`. Do not add new work to the retired `design/20_features/` tree.

## Historical Archive Boundary

`python-sim/` is a historical pre-Godot archive. It is not an active runtime,
design, architecture, implementation, validation, tooling, or source-of-truth
dependency. Do not include it in an active authority chain. Consult it only
when a task explicitly requires historical archaeology; it never overrides
current design or runtime.

The active authority chain is:

1. `design/`
2. `custodian/docs/ai_context/`
3. `custodian/docs/`
4. live runtime and content under `custodian/`

Repository-root path equivalents used by the local primer are:

- active design: `design/`
- current state/context/index: `custodian/docs/ai_context/`
- active runtime: `custodian/game/`, `custodian/content/`, and `custodian/project.godot`
- validation: `custodian/docs/ai_context/VALIDATION_RECIPES.md` and `custodian/tools/validation/`
- validation resource cost: broad sweeps launch one headless Godot process per test
  (`--tier actor` is roughly fifty). Check `free -h` before one and run a single sweep at
  a time; see Resource Budget Before Broad Sweeps in `VALIDATION_RECIPES.md`.
- active project doctrine: `design/00_meta/MASTER_DESIGN_DOCTRINE.md`
- deterministic micro-playtest review: route through `custodian/AGENTS.md`,
  `design/02_features/debug_ui/MOMENT_FORGE_SYSTEM.md`, and the Moment Forge
  section of `custodian/docs/ai_context/VALIDATION_RECIPES.md`

If root guidance conflicts with `custodian/AGENTS.md` for Godot runtime work, follow `custodian/AGENTS.md`.

## Operator Main-Character Pixel-Art Resizing

For any pixel-art conversion or resizing of the Operator main character's
artwork, use the repository alias defined in `tools/custodian_aliases.sh`:

```bash
source tools/custodian_aliases.sh
pixelart <source> --choose 1 ...
```

The `pixelart` alias is the required entrypoint; do not bypass it by invoking
the converter script directly. `--choose 1` is the required resizing method
(crisp nearest-neighbor reduction) for Operator main-character art. Do not use
options 2 or 3 for this artwork unless an active Operator design specification
explicitly overrides this rule. This requirement applies to authoring and
review-preparation conversions; it does not replace the canonical Operator
source-to-runtime ingest pipeline.

For long-horizon wanted-feature tracking, use `design/90_codex/` and its tracker at `design/90_codex/TRACKER.md`; codex cards are idea inventory until graduated into active design authority.

## Commit Policy

Agents commit completed work without waiting for a per-task instruction.

- Commit at task boundaries once the change is implemented and validated (parse checks, smoke tests, or the recipe in `custodian/docs/ai_context/VALIDATION_RECIPES.md`).
- Stage only the files the current task changed. Never `git add -A` blindly: do not sweep in another session's unrelated dirty files, secrets, logs, or generated artifacts.
- Use short, lowercase, comma-joined summaries in the repo's existing style (for example `combat feel authoring, FPS chasing`).
- Push completed work to the remote once committed.
- Do not amend or force-push unless explicitly asked.
- This working tree is shared with other sessions. If unrelated files are dirty alongside yours, commit only your own files so the tree stays reconcilable.

## Closing Summary Files

Every agent writes the summary that normally closes a message to
`<TASK_NAME>_CLAUDE_SUMMARY.md` at the repo root, and pushes it with the work.

- **Name it after the work slice, not the message.** `C2A_R4_CLAUDE_SUMMARY.md`,
  `UNARMED_FAST_CHAIN_PART_C_CLAUDE_SUMMARY.md`, `OPERATOR_SLICE_D_CLAUDE_SUMMARY.md`.
- **One file per task.** Overwrite the previous version as the task advances;
  never append, never create a second file for the same slice.
- **Stage it in the same commit as the work it describes.** If the work has
  already landed, a follow-up commit is the fallback, not the intent.
- **Keep writing the summary in the reply as well.** The file is in addition to
  the reply, not instead of it.
- **It is not a substitute for the authority docs, and they are not a substitute
  for it.** Updating `CURRENT_STATE.md`, a task packet, `FILE_INDEX.md`, an
  architecture contract or an ownership map does not discharge this. Those record
  what the repo now *is*; the summary records what this slice *did* — the
  measurements, the negative controls, what was deferred, and what went wrong on
  the way. This distinction is exactly where it tends to get skipped.

**Why:** the work is followed across sessions and machines. A summary that exists
only in terminal scrollback is gone the moment the session ends or context is
compacted. In the repo it travels with the branch and is reviewable next to the
diff.

Say the awkward parts in it. A summary that only records what worked is not worth
reading next to the diff, which already shows that.

<!-- code-review-graph MCP tools -->
## MCP Tools: code-review-graph

**IMPORTANT: This project has a knowledge graph. ALWAYS use the
code-review-graph MCP tools BEFORE using Grep/Glob/Read to explore
the codebase.** The graph is faster, cheaper (fewer tokens), and gives
you structural context (callers, dependents, test coverage) that file
scanning cannot.

### When to use graph tools FIRST

- **Exploring code**: `semantic_search_nodes_tool` or `query_graph_tool` instead of Grep
- **Understanding impact**: `get_impact_radius_tool` instead of manually tracing imports
- **Code review**: `detect_changes_tool` + `get_review_context_tool` instead of reading entire files
- **Finding relationships**: `query_graph_tool` with callers_of/callees_of/imports_of/tests_for
- **Architecture questions**: `get_architecture_overview_tool` + `list_communities_tool`

Fall back to Grep/Glob/Read **only** when the graph doesn't cover what you need.

### Key Tools

| Tool | Use when |
| ------ | ---------- |
| `detect_changes_tool` | Reviewing code changes — gives risk-scored analysis |
| `get_review_context_tool` | Need source snippets for review — token-efficient |
| `get_impact_radius_tool` | Understanding blast radius of a change |
| `get_affected_flows_tool` | Finding which execution paths are impacted |
| `query_graph_tool` | Tracing callers, callees, imports, tests, dependencies |
| `semantic_search_nodes_tool` | Finding functions/classes by name or keyword |
| `get_architecture_overview_tool` | Understanding high-level codebase structure |
| `refactor_tool` | Planning renames, finding dead code |

### Workflow

1. The graph auto-updates on file changes (via hooks).
2. Use `detect_changes_tool` for code review.
3. Use `get_affected_flows_tool` to understand impact.
4. Use `query_graph_tool` pattern="tests_for" to check coverage.
