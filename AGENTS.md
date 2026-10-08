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

## Visual Validation Economy

Visual/media inspection is a last-mile proof, not the default validation loop.
Prefer machine-checkable state, geometry, asset-contract, telemetry, and pixel
metrics before asking an agent to inspect rendered frames.

Use this order:

1. Prove code/data invariants first: dimensions, registration, bounds, node/resource
   identity, visibility/modulate alpha, z-order, collision/navigation ownership,
   animation/state/progress, route authority, Asset V2 status, and deterministic
   forward/reverse snapshots.
2. When pixels themselves are part of acceptance, prefer automated image checks
   such as alpha/silhouette bounds, matte/opaque-void detection, overlap/coverage,
   edge/seam discontinuity metrics, targeted image diffs, and exact region hashes.
3. If renderer evidence is still needed, capture the smallest authored region and
   fewest keyframes that can falsify the defect. Prefer tight crops/contact sheets
   over repeated full-resolution screenshots.
4. Use full-frame or full-motion capture only when acceptance genuinely depends on
   global composition, motion, audiovisual synchronization, or game feel that the
   structured checks cannot establish.

During iteration, Moment Forge defaults to `--capture-mode none`; escalate to
`evidence` for the final objective proof and to `full` only with a task-specific
reason. Do not repeatedly feed equivalent full-resolution captures to Codex.
Independent reviewers should reuse durable implementation evidence and structured
metrics unless it is missing, stale, or insufficient for the review contract.

Agents may automatically decide objective technical visual failures such as wrong
registration, clipping, missing/duplicate presentation, invalid alpha, visibility,
or layering when those are established by deterministic evidence. Subjective art
direction, composition preference, aesthetic cohesion, and baseline approval stay
human-owned.

When objective checks are green but an important subjective presentation question
remains, do not spend the coding-agent review loop judging its own screenshots.
Publish one compact external review handoff with
`custodian/tools/iteration/publish_review_artifacts.py` and return the emitted
Dropbox manifest path plus the exact reviewer questions. The publisher is opt-in:
use `--important --reason ...` only when the human/ChatGPT visual decision is
material. When the packet records an `Authoring chat:` URL, pass it through
`--authoring-chat <exact-url>` and report both that URL and the exact
`/CUSTODIAN/visual_review/<workstream>/<run-id>/REVIEW_MANIFEST.json` path. The
authoring ChatGPT/web conversation owns the human visual decision and should use
that Dropbox path directly instead of asking the coding agent to duplicate the
media into chat. Reviewed cloud evidence defaults to `delete-after-review`: after
the ChatGPT/user decision is recorded, resume the same workstream and run the
emitted cleanup command. Use `--retain-after-review` only when the user/packet
explicitly requires retained cloud evidence. Prefer ROI/contact sheets and sparse
authored keyframes; do not commit bulk review media to Git. See
`custodian/docs/ai_context/VISUAL_REVIEW_HANDOFF.md`.

Task packets that require substantial visual evidence must state why non-visual
checks are insufficient and minimize the capture budget. More than two full-frame
stills, any repeated full-frame pass, or full-motion capture needs explicit
task-specific justification.

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

Normal implementation work follows `implement → validate → commit → land on
origin/main`. Completed validated work lands automatically without per-task
approval and without a PR or routine human-review gate. Ad hoc review-only work
must carry the explicit task override `TASK OVERRIDE: review only; do not stage,
commit, or push.` Paired post-land review packets may authorize commits only for their durable review receipt, required closing summary, review-packet lifecycle metadata, and bounded correction/re-review packets. They must never edit the reviewed implementation or unrelated work; the packet must state this bounded override explicitly. A paired review must also start from a fresh reviewer context rather than continuing the implementation session. The same model/agent family may review its own prior work only from a newly started context/workstream that reconstructs the target from durable repository evidence and records `same-agent-fresh-context`; otherwise use `different-agent`.

- Every normal implementation run uses `python3 custodian/tools/agent/workstream.py`
  in an isolated ephemeral worktree. Exceptions are explicitly read-only/review-only
  tasks or a documented reason an ephemeral worktree cannot be used. The persistent
  project-root checkout is for coordination and safe post-landing main sync.
- Commit at task boundaries once the change is implemented and validated (parse checks, smoke tests, or the recipe in `custodian/docs/ai_context/VALIDATION_RECIPES.md`).
- Never `git add -A` blindly, and never commit secrets, logs or generated artifacts.
- Stage only files belonging to the current task. Preserve staged and unstaged
  work from other sessions; do not commit it as routine cleanup. Coordinate
  before including another session's work.
- Use short, lowercase, comma-joined summaries in the repo's existing style (for example `combat feel authoring, FPS chasing`).
- Push completed work to the remote once committed.
- Use stable `agent/<workstream-id>` branches and the `workstream.py` lifecycle;
  push recovery work before landing and delete completed task branches only after
  verifying reachability from `origin/main`. See
  `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- The normal completion entrypoint is `python3 custodian/tools/agent/workstream.py finish ...`.
  Do not invoke `land_main.py` directly for destructive landing; it is an internal
  race-safe landing primitive used by `workstream.py finish`. Direct dry-run
  inspection remains allowed.
- After landing a scoped task branch on `origin/main`, keep the user's persistent
  project-root checkout synchronized as a required post-push step; updating only
  the scoped worktree is not sufficient. This safe synchronization is routine
  repository maintenance and requires no user approval. Fetch/check the latest
  `origin/main`, then run `git -C <project-root> pull --ff-only origin main` when
  the root checkout is on `main`, clean, and only behind. Never reset, clean,
  stash, rebase, switch branches, or overwrite local files to force the sync. If
  local changes, local commits, divergence, or another unsafe state prevents a
  fast-forward, leave every byte and commit intact, report the exact blocker and
  that synchronization is pending, and continue the task closeout without
  asking for routine approval. Resume the safe sync automatically after the
  blocker is independently resolved.
  Rebase conflicts and failed required validation are blockers; never force-push.
- Do not amend or force-push unless explicitly asked.

## Name the Brief

When the user names a CUSTODIAN task, slice, workstream, packet, or recognizable brief, resolve that name to the active task packet before implementing. Claim the packeted workstream through the dispatcher/lifecycle rather than treating the user's short name as a free-form prompt.

The user's explicit current-turn instructions may narrow, pause, or override execution details, but they do not silently discard the packet's authority, acceptance, review, completion, or handoff requirements unless the user explicitly changes those requirements.

If a recognizable name is ambiguous, prefer the packet/workstream whose durable metadata and current DAG position match the conversation. Do not invent a new packet merely because the user used a nickname or shorthand. Close out through the packet and ordinary workstream lifecycle.

## Summary Backlink

When a CUSTODIAN task packet or review packet contains an `Authoring chat:` or `Refresh planning chat:` URL, every durable implementation summary, review summary, correction summary, recovery summary, and closeout handoff authored for that packet must include that exact URL as an explicit `Authoring chat` line. Do not omit, shorten, redirect, or replace it with a generic project link.

This applies whether the summary is written at repository root, beside archived packet evidence, or generated during workstream finish. `workstream.py finish` fails closed when a packet with a recorded authoring/refresh URL has a committed root closing summary that omits the exact `Authoring chat: <url>` line. The backlink is part of the durable handoff so the user can return to the exact planning/review conversation before a required refresh or human decision.

## CUSTODIAN Task Dispatch

Executable packet dispatch is automatic by default. Use `Status: ready` + `Dispatch: auto` even when declared dependencies are incomplete; the dispatcher keeps the packet blocked until those dependencies archive `complete`, then makes it claimable without a manual status flip. `Dispatch: manual` is reserved only for an explicit user instruction to hold an otherwise ready packet until the user chooses claim timing. Missing inputs, predecessor API drift, review ordering, and ordinary dependency waits are not manual-dispatch reasons; represent them with status/dependencies and fail-closed execution checks instead.

For “Take the next CUSTODIAN task,” run
`python3 custodian/tools/agent/dispatch.py claim-next --agent <agent-id>`
(for example `--agent claude` or `--agent codex`).
For “Take CUSTODIAN workstream `<id>`,” run
`python3 custodian/tools/agent/dispatch.py claim <id> --agent <agent-id>`.
Omitting `--agent` falls back to the `CUSTODIAN_AGENT_ID` environment variable,
then a neutral `unspecified` — never a silently assumed brand.
Enter the returned worktree, read `AGENTS.md`, `custodian/AGENTS.md`, and the
returned packet. The claim receipt also exposes `authoring_chat`, `visual_review`,
`visual_review_root`, and the default review retention policy so autonomous agents
carry the human-review route without reconstructing it from prose. Then execute
only that workstream through the lifecycle in
`custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.

### CUSTODIAN Next Shortcut

The repository owns a context-aware next-task workflow at
`.agents/skills/custodian-next/SKILL.md`. In Codex, invoke it directly as
`$custodian-next`.

It is also available through Codex's slash UI: type `/skills` and choose
**CUSTODIAN Next**. Enabled skills may also appear directly in the slash picker
when you type `/`. Do not create a project-local custom prompt for this workflow;
Codex custom prompts are deprecated in favor of skills.

Semantics:

1. If the current session is already in an active `agent/<workstream>`
   checkout, continue that workstream rather than claiming another packet.
2. Otherwise prefer the exact immediate successor recorded by the most recently
   completed packet/review's durable `Next Handoff`, including its paired review.
3. If the requested successor is dependency-blocked, automatically work the
   same dependency chain toward that requested packet: dispatch-claim and
   complete each immediate predecessor that is `ready`/`auto`, including its
   required paired review, then re-check the dispatcher and continue until the
   requested packet is claimable or a real blocker is reached. Do not jump to
   unrelated lanes or edit packet metadata to manufacture eligibility. A
   blocked packet's `ready` status alone does not override its dependency gate.
4. When the successor requires **no ChatGPT/user planning refresh or human
   decision** and the dispatcher says it is eligible, claim it and continue
   autonomously. `Refresh owner: execution-agent` is likewise an autonomous
   bounded refresh unless live evidence exposes a new human-owned choice.
5. Paired review still requires a fresh reviewer context. Transition to a fresh
   reviewer context and claim the review itself; do not ask the user to carry the
   implementation recap into a new session.
6. Stop only on a real human/ChatGPT refresh gate, human visual/design gate,
   explicit manual-dispatch hold, unresolved safety/validation blocker, failed
   prerequisite, or successor that remains ineligible after its eligible
   dependency chain completes. Surface the exact recorded Authoring/Refresh chat
   URL when the stop is human-owned. Do not silently jump lanes.
7. Only when there is no same-series successor and the invocation was for general
   next-task execution, fall back to `dispatch.py claim-next --agent codex`.

The dispatcher receipt remains assignment authority; the shortcut never edits
packet status to manufacture eligibility.

### Naming Work: The Task Packet Is the Brief

When the user names CUSTODIAN work in any form — "claim X", "start X", "take X",
"do X", a short code (`AR2`, `ARR1`, `C2A-R4`), a workstream id, a task, feature,
requirement, or ask — treat the **task packet as the complete brief**. Do not
ask the user to re-explain it, and do not work from the chat message alone.

1. **Resolve the name to a packet.** Search
   `custodian/docs/ai_context/task_packets/` (and `archived/`) for the name:
   `rtk grep -i "<name>" custodian/docs/ai_context/task_packets`. Short codes
   appear in packet text, roadmaps (e.g.
   `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`), and
   `*_CLAUDE_SUMMARY.md` files; the packet's `Workstream:` line is the canonical
   id. `python3 custodian/tools/agent/dispatch.py status` lists claimable work.
   Paired review packets are `REVIEW_<NAME>.md` (workstream `review-<id>`).
2. **If the user says a packet is "ready" but your tree shows `blocked`,** the
   claim reads fetched `origin/main`; run `dispatch.py claim` and let it verify
   rather than editing status by hand. Re-read the packet in the claimed worktree.
   If the explicitly requested packet is dependency-blocked, recursively work
   its incomplete dependency chain in DAG order: dispatch-claim each immediate
   `ready`/`auto` predecessor, complete it through its required review and normal
   lifecycle, then re-check and continue until the requested packet is claimable
   or a real blocker is reached. Do not jump lanes or change packet metadata to
   manufacture eligibility. Stop at manual-dispatch, refresh, human-decision,
   planning-return, failed-prerequisite, or other unresolved execution gates.
3. **Claim, then read the packet in the worktree.** Its fields are the
   instructions: `Goal`, `Completion boundary`, `Work surface`, `Change`,
   `Preserve`, `Non-goals`, `Acceptance`, `Validation`, `Visual review`,
   `Task overrides`, `Deferred`, plus `Depends on` / `Locks` / dependency gates and
   `Recommended Implementation Order`. Also read the packet's `Task-specific
   authority` and `Evidence` files (design docs, prior summaries) before editing.
4. **Explicit user instructions win** over the packet only where the user states
   them; otherwise do not invent scope, and do not expand past `Non-goals`.
   Stop and report if a packet gate says to return to planning.
5. **Close out in the packet's own terms:** fill `Completion Truth` and
   `Execution Feedback`, follow `Validation` and `Visual review` (the agent never
   self-approves aesthetics), and write the closing summary file below.

If a packet is missing information an agent needed, that is packet drift: note
it in `Execution Feedback` → `Tooling / docs drift discovered`.

## Closing Summary Files

Every agent writes the summary that normally closes a message to
`<TASK_NAME>_CLAUDE_SUMMARY.md` at the repo root, and pushes it with the work.

- **Name it after the work slice, not the message.** `C2A_R4_CLAUDE_SUMMARY.md`,
  `UNARMED_FAST_CHAIN_PART_C_CLAUDE_SUMMARY.md`, `OPERATOR_SLICE_D_CLAUDE_SUMMARY.md`.
- **One file per task.** Overwrite the previous version as the task advances;
  never append, never create a second file for the same slice.
- **Stage it in the same commit as the work it describes.** If the work has
  already landed, a follow-up commit is the fallback, not the intent.
- **The durable file is the canonical handoff record.** Keep the substantive
  completion/handoff summary in the file. During autonomous successor execution,
  do not stop merely to paste that full summary into terminal/chat; claim the
  eligible named successor and continue. When a human/ChatGPT gate is reached,
  the user-facing message may be the compact lifecycle unblock card instead of
  duplicating the entire summary. At final chain completion, a concise ordinary
  completion reply is still appropriate.
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

Every normal implementation closing summary also includes this compact process
receipt:

```text
## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success | partial | blocked
- Friction severity: none | low | medium | high
- What went wrong: none | ...
- Root cause / contributing factors: none | ...
- Prevention / pipeline improvement: none | ...
- Tooling / docs drift discovered: none | ...
- Follow-up: none | fixed-in-scope | <workstream-id> | manual-follow-up
- What worked: optional
```

Every packeted closing summary ends with:

```text
## Next Handoff
- Next workstream: <workstream-id | none>
- Next packet state: ready | dependency-gated | refresh-required | human-required | none
- Refresh owner: none | chatgpt-user | execution-agent
- ChatGPT/user planning refresh required: yes | no
- Authoring chat: <ChatGPT conversation URL | not-recorded | n/a>
- Refresh reason: none | ...
- Next action: ...
- Blockers or open questions: none | ...
```

This durable `Next Handoff` drives autonomous continuation. When
`ChatGPT/user planning refresh required: no` and the exact successor is
eligible, the execution agent claims it itself and continues rather than
handing the packet name to the user. When that field is `yes`, the user-facing
terminal/chat handoff should normally collapse to:

```text
PLANNING REFRESH REQUIRED
Authoring Chat: <exact recorded URL>
Workstream: <workstream-id>
Persistent Summary: <repo-relative *_CLAUDE_SUMMARY.md path>
```

The user should only need to open the linked conversation and paste the
workstream ID; the durable summary/packet carries the recap.

This is the immediate successor in the current packet's own program/DAG, not a
random globally eligible task. Architecture/design-sensitive refreshes belong to
`chatgpt-user`: the execution/review agent reports exact live drift and evidence,
then tells the user to bring the originating ChatGPT conversation back to ChatGPT
when its URL is available. Conversation URLs must be copied only from durable
packet/history metadata or user-provided input; never infer or invent one.
A purely mechanical live-main refresh may be assigned to `execution-agent`.

The purpose is to improve the agent pipeline, not praise the run. Keep
`What worked` terse. For packeted V2 work, mirror the same receipt into the
packet's `## Execution Feedback` section before archive. If a repeatable
medium/high-severity process problem is found, fix the small safe issue in-scope
or name/create the follow-up rather than burying it in prose.

## Run Artifact Finalization

Before `workstream.py finish` may tear down an implementation worktree, run
artifacts must be resolved explicitly. Associated task packets must be marked
complete, moved to `custodian/docs/ai_context/task_packets/archived/`, and
removed from active/recently-complete packet-index sections. Untracked files are
classified and block finish until the agent deliberately commits durable
artifacts or removes disposable scratch output. Asset V2 source/inbox material
is never treated as disposable run debris. Validation JSON may remain ephemeral
unless the task requires durable evidence; the required `<TASK>_CLAUDE_SUMMARY.md`
remains committed at repository root. The finish path never silently deletes an
ambiguous artifact.

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
