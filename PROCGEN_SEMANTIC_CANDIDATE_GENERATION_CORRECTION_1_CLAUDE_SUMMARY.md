# Procgen Semantic Candidate Generation Correction 1 — Closing Summary

Workstream: `procgen-semantic-candidate-generation-correction-1`
Packet: `custodian/docs/ai_context/task_packets/archived/PROCGEN_SEMANTIC_CANDIDATE_GENERATION_CORRECTION_1.md`

## What happened

This packet was originally authored (by `task-packet-pipeline-execution-hardening-v1`)
to make rejected-candidate procgen evaluation possible from semantic data
alone, without instantiating a live `ProcGenTilemap` for any rejected
attempt — closing the gap G3 left open. Before writing any implementation,
targeted investigation of `custodian_contract_map.gd` and
`proc_gen_tilemap.gd` found the gap is far larger than assumed: the
generation algorithm itself (`ProcGenTilemap._fill_tilemaps()`, ~40 helper
functions, 147 direct `TileMapLayer` cell-operation call sites across an
11,325-line file) uses the TileMapLayer nodes as its own working data
structure throughout — not a thin presentation layer over a separate
pure-data generator. Only the underlying `ProcGen` room/corridor/cellular-automaton
algorithm (`procgen.gd`) is actually pure-data; everything that turns its
output into the walkable/route/terrain facts `CandidateEvaluator` scores
happens against live TileMapLayer cells.

Closing S3's Exit condition for real therefore requires extracting that
generation pipeline's working representation to a plain data grid
throughout — a rewrite comparable in scope to the entire G1-G5 generation
lane already completed, not a bounded correction.

Per `AGENT_TASK_PACKET_TEMPLATE.md`'s own Authoring Quality Gate rules (added
by the pipeline-hardening packet this correction descends from: re-derive
stale current-measured-state before destructive migration; a packet cannot
declare its macro goal complete via a narrower local optimization), this
finding was surfaced to the user before any implementation. The user chose
to rescope the packet rather than attempt the full rewrite in this
workstream.

## What this workstream actually delivered

Docs/roadmap-authority only, no code changes:

- `PROCGEN_SEMANTIC_CANDIDATE_GENERATION_CORRECTION_1.md` rewritten in place
  with a rescoping note, re-derived Current measured state (with exact file/
  line/call-site evidence), and a Goal/Completion boundary/Acceptance that
  match what was actually delivered.
- `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`: a
  second, deeper correction note superseding the first (still-too-optimistic)
  one; a new "Future Program Entry: Semantics-First Generation Pipeline
  Rewrite" section naming and sizing the real fix as its own future
  initiative with a concrete first task (inventory and slice
  `_fill_tilemaps()`'s ~40 helpers); updated Packet Status table,
  Dependency Graph correction-edge note, and Current Program Position.
- `design/00_meta/MASTER_ROADMAP.md`'s mirrored S3 row corrected to
  `planned` with the same honest scope note.
- `task_packets/README.md`'s active index updated (this packet's entry
  removed on archival; M2's entry updated to reflect it is now eligible).

`procgen-runtime-mutation-scheduler-cutover` (M2) depends on this
workstream's completion (not on the eventual rewrite), so M2 is now
eligible/resumed — the known gap stays durably visible in the roadmap rather
than silently skipped, without indefinitely blocking unrelated M-lane work.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `medium`
- What went wrong: The original packet's authoring (in
  `task-packet-pipeline-execution-hardening-v1`) derived its "Current
  measured state" from the roadmap's own prose summary of G2/G3, not from
  reading `_fill_tilemaps()`'s actual body, and so underestimated how deep
  the TileMap coupling goes.
- Root cause / contributing factors: Trusting a summary (even a previously
  truthful one, at the scope it was written for) over re-deriving the live
  call graph before committing to a Completion boundary for a different,
  larger claim.
- Prevention / pipeline improvement: Caught by following the exact rule this
  same postmortem chain added to `AGENT_TASK_PACKET_TEMPLATE.md` — stopped
  before writing any implementation and re-derived the call graph first. No
  further fix needed; this is the rule working as intended.
- Tooling / docs drift discovered: None beyond the roadmap's own correction
  note needing a second pass.
- Follow-up: `manual-follow-up` — the real semantics-first generation-pipeline
  rewrite is named and sized in the roadmap but unclaimed and unsliced.
- What worked: Stopping to verify the original Goal's feasibility against
  live code before writing any implementation, and asking the user how to
  proceed once the true scope was clear, rather than either silently
  attempting an unbounded rewrite or silently shipping a narrower fix
  mislabeled as closing S3.

## Validation

- `git diff --stat origin/main...HEAD` confirms zero `.gd`/`.tscn` files changed.
- `python3 custodian/tools/agent/check_ai_context.py` — only the 3
  pre-existing, unrelated findings already disclosed by earlier workstreams.
- `git diff --check` — clean.
- No Godot/procgen benchmark sweep run (docs-only; no runtime code changed).
