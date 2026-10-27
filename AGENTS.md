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

## Render Automatic Deploy Isolation

The Render service named `CUSTODIAN` is linked to this repository. Without a
service-side Build Filter, **every push to the linked branch can trigger a
deploy**, including Godot implementation work, packet metadata, and reviews that
have nothing to do with the legacy hosted terminal.

- For a commit that changes **only files outside `python-sim/`** and does not
  change Render configuration or dependencies used by the hosted terminal, put
  `[skip render]` in the commit message. Do this for routine task-packet
  authoring, review receipts, Godot code/art, documentation, and automation.
  Render recognizes the marker; GitHub still receives and processes the commit.
- Do **not** use the marker for commits that change the hosted terminal or its
  runtime/deployment dependencies. Do not rewrite published commits to add it.
- Commit-message markers are a defense in depth, **not a replacement** for a
  service-side filter. The existing `python-sim/render.yaml` targets the legacy
  `custodian-terminal` Blueprint service and already declares an include filter,
  but that does not prove the live `CUSTODIAN` service is configured with it.
- For the permanent fix, set **Build Filters > Included Paths** on the existing
  live Render `CUSTODIAN` service to `python-sim/**` (no ignored paths), after
  verifying this is the Python-terminal service. This setting controls existing
  standalone services; merely adding or editing YAML does not apply it.
  See `RENDER_DEPLOY_POLICY.md` for the safe validation procedure.

## Atomic Task Packet Publication (required)

When a new implementation/correction packet and its paired review are published,
publish every existing task-required supporting tool, script, test fixture, schema,
configuration, manifest, and authoring note in the **same atomic main publication**
as those packets. The packet must enumerate these concrete paths under
`Publication inputs:` (or `none` if no auxiliary inputs are needed). Confirm
that every declared input is tracked at the landed `origin/main` SHA before
claiming. A sandbox download, pasted script, private chat attachment, stale
branch, or unmerged worktree is **not** a published dependency. Do not instruct
Codex to retrieve required implementation inputs exclusively from ChatGPT.

Distinguish already-required inputs from source files the workstream is expressly
tasked with creating. If a prerequisite is host-private or cannot safely be
committed, describe the original owner and local verification procedure; do not
pretend the data was published or silently bypass its gate. Such a packet cannot
claim readiness if that prerequisite is indispensable and unavailable. This rule
does **not** authorize altering third-party claims, review verdicts, locks, or
worktree preservation requirements. Preserve the ordinary workflow and review
contracts.

## Existing-workstream continuity: ownership is not a session veto

**Project-owner directive (2026-10-27):** A Codex session is an expendable worker;
the canonical workstream ID, existing branch, checkout, Git history, evidence,
and reviews are the durable work. An absent OR1 supervisor journal or the
`UNMANAGED_UNKNOWN` diagnosis **alone** does not forbid a new, explicitly
user-authorized session from continuing the same claim. Do not demand OR2
parking, a new claim, or a new recovery packet before attempting the supported
`python3 custodian/tools/agent/workstream.py resume <existing-id>` command.

Before continuation, check the exact branch and attached checkout, latest
origin state, live processes/writers on the current host, and both tracked and
untracked changes. Respect any known live competing worker or unresolved
foreign-host ownership; do not infer process death from age. A clean checkout
with no conflicting writer may be resumed using the existing lifecycle and its
mutex under the project owner's authorization. If resume refuses, report its
**actual failed invariant** rather than citing missing supervisor history.
Dirty/unique work must be preserved and reconciled, not silently cleaned,
reset, overwritten, or abandoned. Do not delete or release claims/locks by
this rule. Pinned independent reviews and evidence/validation gates still apply.

For work already in progress when this policy lands: on the **next safe
decision boundary**, fetch the current main instructions and re-evaluate
owner-blocked work against this rule without resetting the active worktree.
A GitHub commit does not hot-replace prompts already loaded into running agent
sessions; no claim of instant process-wide delivery is permitted. See
`custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.

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

## Automatic Task Packet Handoff

### Automatic task packet authoring handoff

For a newly authorized V2 implementation/correction packet and its paired
post-land review, set `- Authoring handoff: auto` on **both** and publish them
together to `origin/main` as `draft/manual`. The push-triggered
`.github/workflows/packet-authoring-handoff.yml` runs the targeted
`packet_authoring_handoff.py` tool. It validates the pair, promotes both
to `ready/auto`, checks their queue and referenced validation scripts,
updates the bounded Ready/Auto index, then commits and fast-forward pushes
only the two packets and the generated README.

This is opt-in: no marker means no automatic promotion. Do **not** opt in
planning/human-decision holds, blocked reviews, or unreconciled refreshes.
Failures stop without publication, force pushing, claiming or overriding
locks. An hourly retry checks only remaining explicit opt-ins, so a main-branch
race does not require another user/Codex preflight. The GitHub action runs authoring, **not local Codex execution**;
`dispatch.py` remains the sole execution/dependency/lock authority.
A normal Codex dispatcher worker can claim later if the live audit says
eligible. CI write permission and allowed non-force main push are required.

## Name the Brief

When the user names a CUSTODIAN task, slice, workstream, packet, or recognizable brief, resolve that name to the active task packet before implementing. Claim the packeted workstream through the dispatcher/lifecycle rather than treating the user's short name as a free-form prompt.

The user's explicit current-turn instructions may narrow, pause, or override execution details, but they do not silently discard the packet's authority, acceptance, review, completion, or handoff requirements unless the user explicitly changes those requirements.

If a recognizable name is ambiguous, prefer the packet/workstream whose durable metadata and current DAG position match the conversation. Do not invent a new packet merely because the user used a nickname or shorthand. Close out through the packet and ordinary workstream lifecycle.

## Codex Activity Attribution (low overhead)

Keep Codex usage attribution aligned with the existing canonical CUSTODIAN
workstream lifecycle. Once a dispatcher claim/resume or the active worktree has
**verified** the assignment, begin the first substantive user-visible progress
or completion reply **in each Codex turn** with this plain-text line:

```text
Workstream: <canonical-workstream-id>
```

Use the exact `Workstream:` value in the task packet or verified claim receipt,
including the `review-...` prefix for independent reviews and the full
`...-review-corrections-N` name for corrections. Do not substitute a feature
nickname, packet filename, agent name, or previously completed workstream.
When autonomous continuation claims a successor, announce the new exact ID in
the first reply for that successor. If no assignment is verified, omit the line
rather than guessing. Where possible, keep one workstream per Codex turn; a
turn spanning multiple assignments must not be reported as single-workstream
usage.

This line is a lightweight attribution hint, **not** a dispatch claim, an
approval, or a required extra status message. Do not create extra Codex calls,
commit telemetry files, or extend task summaries solely for usage tracking.
Model, reasoning effort, wall time, input/cached/output/reasoning tokens, and
quota snapshots must be measured by the local Codex session-log tracker, not
estimated by the agent or inferred from this label. Existing packet metadata,
branches, independent reviews, validation requirements, and durable handoffs
remain authoritative. Prefer compact tool output and non-duplicative context,
without skipping required checks to optimize tokens.

## Summary Backlink

When a CUSTODIAN task packet or review packet contains an `Authoring chat:` or `Refresh planning chat:` URL, every durable implementation summary, review summary, correction summary, recovery summary, and closeout handoff authored for that packet must include that exact URL as an explicit `Authoring chat` line. Do not omit, shorten, redirect, or replace it with a generic project link.

This applies whether the summary is written at repository root, beside archived packet evidence, or generated during workstream finish. `workstream.py finish` fails closed when a packet with a recorded authoring/refresh URL has a committed root closing summary that omits the exact `Authoring chat: <url>` line. The backlink is part of the durable handoff so the user can return to the exact planning/review conversation before a required refresh or human decision.

## Task-Packet Promotion Before Dispatch (mandatory for newly authored or unparked packets)

**A local authoring PASS does not publish a packet or authorize a dispatcher claim.**
When an implementation/review pair has been authored as `draft/manual` (or materially
refreshed), the agent assigned to promote it should complete this lifecycle
*without requiring the user to supply the command*:

1. Confirm the design/refresh lock and check that the target workstream is not
   already claimed, archived, or superseded on fetched `origin/main`. Do not
   silently convert a real human-held `ready/manual` packet into auto dispatch.
2. Run the **targeted** authoring check against the implementation **and paired
   review** while still unpromoted:
   ```bash
   python3 custodian/tools/agent/validate_task_packet_authoring.py \
     custodian/docs/ai_context/task_packets/<IMPLEMENTATION>.md \
     custodian/docs/ai_context/task_packets/REVIEW_<IMPLEMENTATION>.md
   ```
3. Only if the design lock explicitly permits execution, set both metadata headers
   to `Status: ready`, `Dispatch: auto` (unless the user explicitly requested
   manual claim timing). Re-run the same targeted preflight **after** editing
   those headers, then regenerate and verify the managed queue index:
   ```bash
   python3 custodian/tools/agent/task_packet_index.py --write
   python3 custodian/tools/agent/task_packet_index.py
   ```
4. Stage only the authorized implementation/review files and
   `custodian/docs/ai_context/task_packets/README.md` (plus explicitly
   required scoped authority changes). Commit and **land on `origin/main`**
   using the safe repository landing process. Do not treat an unmerged branch,
   local `main`, or locally generated README as dispatcher visibility. Never
   overwrite another worker's changes or bypass claim/lock authority.
5. `git fetch origin`; verify both packet headers **on `origin/main`**
   and the managed index entry, then run
   `python3 custodian/tools/agent/dispatch.py claim <implementation-workstream-id> --agent <agent-id>`
   **only if eligible**. The paired post-land review waits for the implementation
   to land and archive complete.

If the requested packet does not exist on `origin/main`, stop trying to claim
it and finish this publication sequence first. `validate_task_packet_authoring.py`
prints these publication/claim instructions after PASS; its output never performs
a promotion, commit, push, or claim. See
`custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md` for the full
authoring contract. For standalone read-only audit packets, do not promote
without actual user authorization.

## CUSTODIAN Task Dispatch

Executable packet dispatch is automatic by default. Use `Status: ready` + `Dispatch: auto` even when declared dependencies are incomplete; the dispatcher keeps the packet blocked until those dependencies archive `complete`, then makes it claimable without a manual status flip. `Dispatch: manual` is reserved only for an explicit user instruction to hold an otherwise ready packet until the user chooses claim timing. Missing inputs, predecessor API drift, review ordering, and ordinary dependency waits are not manual-dispatch reasons; represent them with status/dependencies and fail-closed execution checks instead.

For a full live queue and branch/worktree reconciliation, use
`python3 custodian/tools/agent/dispatch.py audit` (or `--json` for stable
machine-readable output). It shares the dispatcher's exact eligibility gate;
the README Ready/Auto block is only a generated view. Use
`dispatch.py repair --plan` to inspect the bounded metadata repair and add
`--archive-completed` to preview only legacy records with explicit completion
evidence. Repair apply never cleans branches or worktrees; preserve ambiguous
ownership for explicit recovery.

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

1. An unqualified invocation is `single-pair`: complete or resume at most one
   implementation packet and its required fresh-context paired review, including
   bounded correction/re-review cycles, then stop. An active claimed workstream
   counts as that pair; do not claim another while it is unresolved.
2. Use `continuous-chain` only when the user explicitly requests multiple
   packets. Require a positive finite `max_pairs` and honor any explicit scope.
   Continue only through the durable `Next Handoff` DAG and dispatcher-confirmed
   eligible predecessors; a pair is one implementation plus its paired review.
3. Reconcile active branch, worktree, dispatch receipt, and remote state. A stale
   `last-claim` is not ownership proof. Ambiguous/stale claims require audit and
   must never cause a duplicate claim.
4. The pure invocation policy is
   `custodian/tools/agent/next_execution_boundary.py`. Use its `evaluate`,
   `progress`, and `record-receipt` commands at invocation/pair boundaries. It
   does not select or claim packets. `dispatch.py` remains the assignment
   authority. Record compact receipts with pair progress, landed SHA, review,
   validation, elapsed time, and next eligibility.
5. Paired post-land review remains a fresh-context operation. Once eligible,
   invoke `python3 custodian/tools/agent/paired_review_runner.py <review-workstream-id>`
   from the coordination checkout. Corrections and
   re-reviews remain inside the same pair.
6. Stop at planning refresh, human visual/design/canon decision,
   manual-dispatch, failed validation, or unresolved safety/ownership gates.
   `Refresh owner: execution-agent` allows a bounded refresh unless it exposes a
   new human-owned decision. Never edit packet status to manufacture eligibility.
7. After one pair, default mode stops even if the handoff names another ready
   packet. Global `dispatch.py claim-next --agent codex` is allowed only when the
   user explicitly requested general-next execution and no current pair remains
   unresolved; it selects one eligible implementation within the stated budget.

The dispatcher receipt remains assignment authority; the shortcut never edits
packet status to manufacture a claim.

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

Use code-review-graph as an **opportunistic structural accelerator**, not as a
cold-start prerequisite for every ephemeral worktree.

### CUSTODIAN worktree policy

- The persistent coordination checkout is the maintained/shared CRG baseline.
  In a linked agent worktree, derive it with:
  `COORD_ROOT="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"`.
- A linked/ephemeral worktree does **not** need its own graph by default. Do not
  run `build_or_update_graph` or a full `code-review-graph update` merely
  because the first graph call reports `missing_graph`, `not_ready`, an empty
  graph, stale coverage, or no mapped symbols.
- From a linked worktree, CRG may point at `$COORD_ROOT` for baseline
  architecture, callers/dependents, and likely-test orientation. Treat that as
  a hint only. Confirm every symbol/path used for implementation or review
  against the **current worktree** and use the worktree diff as change truth.
- Never use the coordination-root graph as proof of branch-local changes that
  are not present in that checkout.
- Build/maintain a worktree-local graph only when the task explicitly benefits
  from it; opt in with `CRG_HOOK_WORKTREES=1`.
- If one cheap graph attempt is unusable, fall back immediately to targeted
  symbol/path reads. Do not spend task time repairing CRG ceremony.

### CRG install contract

- Claude (`.mcp.json`), the refresh hook (`tools/crg-refresh.sh`), and the
  user-level `~/.codex/config.toml` all run the same pinned, lightweight
  `code-review-graph==<CRG_VERSION>` from `tools/crg-pin.env`. Do not add the
  `[embeddings]` extra: it pulls torch + CUDA (~5.9 GB in the uv cache) and the
  root graph has no embeddings. Without them `semantic_search_nodes_tool` is
  keyword/FTS search, not vector search.
- MCP servers run with a read-only `--tools` allowlist, so build/postprocess/
  embed/refactor-apply tools are not exposed. Graph updates go through
  `tools/crg-refresh.sh` (the post-commit and session-start hooks). This does
  not intercept a direct `code-review-graph build|update` CLI call; the
  worktree skip above covers only `crg-refresh.sh`.
- Verify drift with `python3 tools/check_crg_config.py` after touching any CRG
  config. Each MCP server is one process per session over one shared database;
  that is expected.

### Task-scoped Repomix context

For broad multi-file tasks, a packet may provide a bounded `## Context Pack`
with repo-relative Repomix include globs. Generate it **from the claimed
worktree**, not the persistent coordination checkout:

```bash
scripts/ai/pack-context.sh task "<comma-separated include globs>" "<workstream-id>"
```

The output is ignored under `.ai/task-context/`. Generate it once at task
start (and again only after a material scope change). It is a navigation/context
snapshot, never repository authority; exact live files and `git diff` remain
truth.

### When the graph is usable

- **Exploring code**: `semantic_search_nodes_tool` or `query_graph_tool`
- **Understanding impact**: `get_impact_radius_tool`
- **Code review**: `detect_changes_tool` + `get_review_context_tool`
- **Finding relationships**: `query_graph_tool` with callers_of/callees_of/imports_of/tests_for
- **Architecture questions**: `get_architecture_overview_tool` + `list_communities_tool`

Keep graph calls narrow and token-efficient. Prefer `detail_level="minimal"`
and escalate only when needed.
