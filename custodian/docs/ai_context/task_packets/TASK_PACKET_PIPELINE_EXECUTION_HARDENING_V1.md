# TASK PACKET PIPELINE EXECUTION HARDENING V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `task-packet-pipeline-execution-hardening-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `agent-workflow`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-task-packet-pipeline-execution-hardening-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `ba56a054d7dfc6a969f0cbf4bfa94c134c8246f5`
- Goal: Make CUSTODIAN task packets cheaper to execute, harder to close falsely, and safer to hand across agents by turning the postmortem lessons from the procgen S1/G1-G5 run into shared packet-contract, dispatch, validation, and workstream-finish architecture.
- Completion boundary: Done when packet parsing has one reusable authority; active V2 packets have a durable low-context execution contract; `workstream.py finish` fails closed when a completed implementation packet cannot truthfully prove Goal + Completion boundary + Acceptance; dispatcher traces no longer falsely identify every unspecified worker as Codex; packet/index drift has a read-only validator plus deterministic bounded index repair; current workflow docs encode the LFS/import and subagent lessons; the known procgen G3 false-closure is reconciled into a separate correction packet without changing procgen runtime in this workstream; and focused workflow tests prove the new lifecycle end to end.
- Current measured state: `dispatch.py` owns the live packet parser; `workstream.py finish` proves artifact cleanliness, committed summary, green focused validation, synchronization, landing, and teardown but does not prove that a packet's stated Goal/Completion boundary remain true. `dispatch.py claim/claim-next` defaults `--agent` to `codex`, so Claude-run traces may be mislabeled. The queued `ai-context-task-packet-validator` and `task-packet-index-automode-hardening` packets separately propose overlapping parser/validator/index work but neither has landed. S1's transcript/summary shows expensive research fanout, a read-only fork that wrote hallucinated code, LFS-before-import ordering failure, and broad validation churn; G2/G3/G5 summaries show materially lower friction when predecessor summaries, targeted symbol reads, focused tests, and LFS-first setup were used. The procgen roadmap currently says G3 closes semantics-only rejected-candidate generation, but live `CustodianContractMap.generate_contract()` still instantiates a live `candidate_map` via `_instantiate_map(...)` for every evaluation attempt and builds the semantic snapshot from that generated map, so the stated S3 goal remains materially false despite green acceptance checks.
- Evidence: `custodian/tools/agent/dispatch.py` (`Packet`, `parse_packet`, claim trace identity); `custodian/tools/agent/workstream.py` (`_finish_impl`); `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; root and local `AGENTS.md`; `PROCGEN_PERFORMANCE_BASELINE_V1_CLAUDE_SUMMARY.md`; `PROCGEN_CANDIDATE_EVALUATOR_EXTRACTION_CLAUDE_SUMMARY.md`; `PROCGEN_CANDIDATE_SEMANTIC_MODEL_CLAUDE_SUMMARY.md`; `PROCGEN_SEMANTIC_CANDIDATE_GENERATION_CLAUDE_SUMMARY.md`; `PROCGEN_ACCEPTED_CANDIDATE_MATERIALIZER_CLAUDE_SUMMARY.md`; `PROCGEN_CANDIDATE_RUNTIME_PATH_DEMOLITION_CLAUDE_SUMMARY.md`; `session-transcript/procgen-performance-baseline-v1`; live `custodian/game/world/procgen/custodian_contract_map.gd`; queued validator/index packets named below.
- Task-specific authority: `AGENTS.md`; `custodian/AGENTS.md`; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/task_packets/README.md`; `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`; live `dispatch.py` / `workstream.py` / workflow tests; `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` only for the bounded real-world migration fixture.
- Work surface: Primary code is `custodian/tools/agent/dispatch.py`, `custodian/tools/agent/workstream.py`, a new shared packet-contract module under `custodian/tools/agent/`, the new/read-only AI-context validator and bounded packet-index tool, and their focused tests. Primary docs are the packet template, workstream lifecycle, task-packet README, root/local AGENTS, validation recipes, automation backlog, FILE_INDEX, and validation manifest. Procgen edits are coordination-only: roadmap truth, one new correction packet, and dependency metadata. Do not edit procgen runtime code here.
- Change: Extract packet metadata/contract parsing into one reusable module consumed by dispatcher, finish-time packet checks, AI-context validation, and packet-index maintenance; add a structured completion-truth receipt and enforce it for the current workstream before teardown; strengthen authoring/closeout rules so Acceptance cannot substitute for an unmet Goal/Completion boundary; encode low-context predecessor-summary/exact-symbol execution rules and safe subagent fanout; make agent identity truthful; implement the queued validator/index functionality on the shared parser rather than leaving parallel grammars; and perform the bounded active-packet migration described below.
- Preserve: Existing remote claim atomicity, stable workstream IDs, dependency/lock semantics, paired-review lifecycle, push-first recovery, non-destructive worktree policy, manual/auto dispatch behavior, historical archived packet validity, validation-report gates, task summary/artifact finalization, Ultra low-bandwidth semantics, and unrelated active packets/worktrees.
- Non-goals: Do not change procgen runtime implementation; do not redesign review/correction semantics beyond what is needed for completion truth; do not introduce a daemon or automatic background worker; do not require historical archived packets to be bulk-rewritten; do not make subjective prose scoring a machine gate; do not auto-fetch missing LFS objects from the network; do not permit research subagents to mutate the parent implementation worktree by default.
- Acceptance: One shared parser/contract authority is used by dispatch plus new validator/index/finish checks; `workstream.py finish` refuses a current V2 implementation/correction packet marked complete when its required completion-truth receipt is missing or says Goal, Completion boundary, or Acceptance is unsatisfied; historical already-landed packets remain closable/recoverable without bulk migration; a ready packet can no longer be considered complete merely because tests are green while its stated architecture goal is materially false; dispatcher receipts/traces preserve an explicitly supplied agent ID and never silently label an unspecified non-Codex worker as Codex; validator/index tooling catches/repairs active packet/index drift deterministically without mutating dispatch as a side effect; packet/template/docs encode targeted context economy, predecessor-summary handoff, safe research-fork behavior, focused-validation-first, and LFS-before-Godot-import ordering; focused temporary-repo tests cover all of these; the active procgen roadmap no longer claims S3's semantics-only goal is fully satisfied while production still constructs live evaluation maps, and a separate bounded correction packet owns that runtime gap before M2 resumes.
- Validation: Focused unit tests for shared packet parsing, dispatcher identity, completion-truth gating, AI-context validation, packet-index check/write, already-landed finish compatibility, and active/archived packet handling; `python3 custodian/tools/agent/test_dispatch.py`; `python3 custodian/tools/agent/test_workstream.py`; new packet-contract/validator/index test modules; `python3 custodian/tools/validation/agent_workflow_smoke.py`; paired-review consistency validation; `python3 -m py_compile` on changed agent tooling; `check_ai_context.py --json` and packet-index check on the task branch; one changed-file closeout sweep; `git diff --check`. This is workflow/tooling work, so do not run Godot/procgen benchmark sweeps merely for ceremony.
- Task overrides: `none`
- Deferred: Semantic-only procgen runtime correction itself; broader task-run token accounting; automatic import-completeness baselines; continuous task workers; generalized semantic prose analysis.

## Required Architecture

### 1. One packet-contract parser

Extract the current packet grammar from `dispatch.py` into a focused reusable module, preferably:

`custodian/tools/agent/task_packet_contract.py`

The exact filename may change if live conventions provide a better seam, but there must be one parser/validation authority rather than dispatcher, validator, indexer, and finish each inventing their own front-matter grammar.

It must support the current V2 fields and legacy-safe defaults used by dispatch/review pairing. Keep dispatcher behavior byte/semantics compatible unless explicitly changed below.

Consumers after this packet:

```text
task_packet_contract.py
  ├─ dispatch.py
  ├─ workstream.py completion truth
  ├─ check_ai_context.py
  └─ task_packet_index.py
```

### 2. Completion truth is separate from validation green

Add a structured receipt to the packet template and required closing summary for current V2 implementation/correction work:

```text
## Completion Truth
- Completion schema: custodian.task_completion.v1
- Goal satisfied: yes | no
- Completion boundary satisfied: yes | no
- Acceptance satisfied: yes | no
- Superseded/legacy production path disposition: removed | intentionally-preserved | n/a
- Evidence: <compact exact evidence>
```

Rules:

- `Status: complete` for a V2 implementation/correction packet requires Goal, Completion boundary, and Acceptance all `yes`.
- `Superseded/legacy production path disposition` is `removed` when the packet promises demolition/replacement, `intentionally-preserved` only when Preserve/Deferred explicitly authorizes it, or `n/a`.
- Green tests are evidence, not permission to answer `yes` when the stated architecture outcome remains false.
- `Outcome: partial` may still describe process/validation friction, but it cannot make an incomplete Goal eligible for teardown.
- If any completion-truth requirement is `no`, use checkpoint/blocked/in-progress state or a scoped correction path; do not archive/finish as complete.
- Historical packets already archived before this migration are not bulk-invalidated. Enforce the new finish gate on the packet associated with the currently finishing workstream and on newly authored/current active V2 packets.

`workstream.py finish` must perform this targeted packet check before destructive teardown and again after main synchronization if packet bytes changed.

### 3. Authoring truth gate

Update `AGENT_TASK_PACKET_TEMPLATE.md` so its quality gate requires:

- Acceptance collectively proves the stated Goal and Completion boundary, rather than a convenient subset.
- Architecture/migration packets identify the old authority/path whose absence, non-use, or explicit preservation proves closure.
- A task that discovers its authored-time Current measured state is stale must re-derive the current call graph before destructive migration.
- A packet cannot declare its macro goal complete by satisfying a narrower local optimization.

Do not add subjective automated prose scoring.

### 4. Context economy and predecessor handoff

Move the useful parts of the procgen packet-local context-economy experiment into shared execution guidance so future packets do not duplicate the same boilerplate.

Default packet execution:

1. read the current packet;
2. read the immediate predecessor closing summary when the task depends on an architecture-shifting predecessor;
3. use code-review graph first when available;
4. otherwise search exact symbols/paths before reading large files;
5. read direct callers/callees only as needed;
6. do not reread completed packets or broad roadmaps unless a concrete contradiction requires them;
7. reuse landed benchmark/validation evidence instead of rediscovering it;
8. run the highest-risk focused falsification first, then one normal closeout sweep.

For large files, explicitly forbid whole-file reads by default when targeted symbol/range retrieval is available.

Keep task packets task-specific: repository-default economy rules live in AGENTS/lifecycle/template rather than being copied into every packet.

### 5. Subagent/fork safety

Codify a default-single-agent rule for packet implementation:

- Use research forks/subagents only when the work is genuinely independent and parallelism materially reduces wall time.
- A read-only research fork must not share writable authority over the parent implementation worktree. Use tool restrictions or a separate isolated checkout/context; if the platform cannot enforce read-only mutation, do the targeted research in the parent instead.
- Never allow two implementation-capable forks to concurrently edit the same worktree without an explicitly scoped multi-writer task contract.
- If a fork stalls and the parent can obtain the fact with a few targeted reads/searches, stop the fork rather than waiting/polling repeatedly.
- Parent must verify fork claims against live code before implementation when the result names APIs/paths not already known.

This is primarily an instruction/contract hardening, not a requirement to build a general subagent manager.

### 6. Truthful agent identity

Today `dispatch.py claim/claim-next` defaults `--agent` to `codex`.

Change this so traces never silently make a false attribution.

Preferred contract:

- explicit `--agent <id>` wins;
- otherwise use a documented environment identity such as `CUSTODIAN_AGENT_ID` when present;
- otherwise record a neutral value such as `unspecified`, not `codex`.

Update root/lifecycle/README examples to use `--agent <agent-id>` and show `claude` / `codex` as examples where useful. Preserve explicit Codex callers by passing `codex`.

Add tests proving the receipt/trace receives the actual explicit/environment identity and that omission is neutral.

### 7. AI-context validator and bounded index authority

Absorb the still-unimplemented scope of:

- `ai-context-task-packet-validator`
- `task-packet-index-automode-hardening`

Do not leave them as competing future implementations.

Implement on top of the shared parser:

- read-only `custodian/tools/agent/check_ai_context.py` with deterministic text/JSON diagnostics for required context, active/archive consistency, V2 structural contract, current completion-truth requirements, auto-dispatch metadata, bounded authority paths, and active index drift;
- focused `custodian/tools/agent/task_packet_index.py` (or equivalent) whose default/check mode is read-only and whose explicit write mode rewrites only the managed Ready/Auto block deterministically;
- tests in temporary repositories;
- manifest/docs/index ownership.

Do not make `dispatch.py status` or `claim-next` mutate documentation.

### 8. LFS/import order

S1 already added useful LFS guidance. Preserve and consolidate it rather than duplicating prose.

For fresh Godot-capable worktrees, the documented/default sequence must remain:

```text
verify cached LFS state
→ materialize locally cached LFS payloads when required
→ Godot import
→ focused validation
```

Do not run Godot import first and then discover pointer stubs. Do not introduce an automatic network LFS fetch. If you add a tooling preflight, it must distinguish local-cache materialization from network fetch and preserve the Ultra worker's low-bandwidth rules.

This packet need not force LFS materialization for docs/tooling-only worktrees.

## Real-World Migration Fixture: Procgen G3 False Closure

Use the already-landed procgen generation lane as a concrete proof that the new pipeline prevents a green-but-incomplete architecture task from disappearing.

Current live evidence:

```text
CustodianContractMap.generate_contract()
  -> _instantiate_map(...)
  -> live ProcGenTilemap evaluation generation
  -> CandidateSemanticAdapter.build_snapshot(...)
  -> CandidateEvaluator.evaluate_snapshot(...)
```

Therefore the roadmap statement that G3 fully achieved “rejected candidates die as data without live near-runtime world construction” is not truthful.

Within this workflow packet, do **coordination/docs only**:

1. Re-open `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` against live main and change the S3/G3 macro completion wording/status to the truthful state: the evaluation path skips some final collision/presentation realization, but true semantic-first candidate construction remains open.
2. Author a bounded correction packet:
   - filename: `custodian/docs/ai_context/task_packets/PROCGEN_SEMANTIC_CANDIDATE_GENERATION_CORRECTION_1.md`
   - workstream: `procgen-semantic-candidate-generation-correction-1`
   - Kind: `correction`
   - Status: `ready`
   - Dispatch: `auto`
   - Priority: `P0`
   - Depends on: `review-task-packet-pipeline-execution-hardening-v1`
   - Locks: `procgen-generation`
   - exact runtime target: production candidate evaluation must be possible from semantic data without instantiating `proc_gen_map.tscn`, `ProcGenTilemap`, TileMap/presentation/collision/nav nodes for rejected attempts; the live-adapter path may remain only as a parity oracle/test seam until proven removable.
3. Make `procgen-runtime-mutation-scheduler-cutover` depend on that correction packet in addition to M1 so the user's authorized serial procgen run cannot silently skip the known architecture gap.
4. Do not edit procgen runtime code in this workstream.
5. Add the correction to the procgen roadmap dependency graph/status table and active packet index.

This is a one-time migration fixture and a real defect correction, not a requirement that future pipeline tasks mutate feature roadmaps.

## Superseded Queued Workflow Packets

The implementation must absorb, then retire/archive or clearly supersede, these currently queued packets so no duplicate worker later implements a second parser/index architecture:

```text
custodian/docs/ai_context/task_packets/AI_CONTEXT_TASK_PACKET_VALIDATOR.md
custodian/docs/ai_context/task_packets/TASK_PACKET_INDEX_AUTOMODE_HARDENING.md
```

Preserve any acceptance/test cases from them that remain stronger than this packet.

## Likely Exact Paths

Start here before broad search:

```text
AGENTS.md
custodian/AGENTS.md
custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md
custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md
custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md
custodian/docs/ai_context/task_packets/README.md
custodian/docs/ai_context/task_packets/AI_CONTEXT_TASK_PACKET_VALIDATOR.md
custodian/docs/ai_context/task_packets/TASK_PACKET_INDEX_AUTOMODE_HARDENING.md
custodian/docs/ai_context/AGENT_AUTOMATION_BACKLOG.md
custodian/docs/ai_context/VALIDATION_RECIPES.md
custodian/docs/ai_context/FILE_INDEX.md
custodian/tools/agent/dispatch.py
custodian/tools/agent/workstream.py
custodian/tools/agent/test_dispatch.py
custodian/tools/agent/test_workstream.py
custodian/tools/validation/validation_manifest.json
design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md
custodian/docs/ai_context/task_packets/PROCGEN_RUNTIME_MUTATION_SCHEDULER_CUTOVER.md
```

Preferred new paths unless a cleaner live seam exists:

```text
custodian/tools/agent/task_packet_contract.py
custodian/tools/agent/test_task_packet_contract.py
custodian/tools/agent/check_ai_context.py
custodian/tools/agent/test_check_ai_context.py
custodian/tools/agent/task_packet_index.py
custodian/tools/agent/test_task_packet_index.py
```

Do not read `proc_gen_tilemap.gd` for this pipeline task. The procgen runtime correction is deliberately separate.

## Required Tests

At minimum add/prove fixtures for:

1. shared parser produces the same dispatch metadata decisions as the current parser for representative implementation/review/correction/legacy packets;
2. duplicate/invalid metadata still fails closed;
3. `finish` rejects a current V2 implementation packet that is `Status: complete` but lacks `custodian.task_completion.v1`;
4. `finish` rejects Goal=no, Completion boundary=no, or Acceptance=no even with a green validation JSON;
5. `finish` accepts a truthful all-yes completion receipt with green validation;
6. an old already-landed workstream can still complete teardown/recovery without forcing historical packet migration;
7. explicit `--agent claude` and `--agent codex` are preserved in receipts/traces;
8. omitted identity is neutral, not falsely `codex`;
9. AI-context validator catches active/archive/index drift and malformed current V2 completion truth;
10. indexer check/write is deterministic, bounded, idempotent, and leaves unmanaged README bytes unchanged;
11. no dispatcher status/claim command mutates packet/index docs;
12. review/correction pairing still works after parser extraction;
13. the two absorbed queued workflow packets cannot remain independently auto-eligible after this task lands;
14. the procgen correction packet is dependency-correct and M2 is blocked behind it until completion.

## Documentation Drift To Reconcile

At authoring time, known drift includes:

- lifecycle/root examples hardcode `--agent codex` even for non-Codex agents;
- packet template has no machine-enforced semantic completion receipt;
- `workstream.py finish` can tear down a green task whose packet-level Goal remains false;
- AI-context validator/indexer are queued as separate future packets despite now being required parts of one shared-parser architecture;
- procgen S3/G3 roadmap closure overstates the live production architecture.

Update only current authority/index/docs whose truth changes. Historical summaries/transcripts remain evidence, not living instructions.

## Handoff

- Next action: Explicitly claim `task-packet-pipeline-execution-hardening-v1` with the actual executing agent identity. After it lands, run its paired independent review. Only after that review passes should the newly authored `procgen-semantic-candidate-generation-correction-1` become eligible; M2 must remain blocked behind that correction.
- Best starting files: `custodian/tools/agent/dispatch.py`, `custodian/tools/agent/workstream.py`, `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`, the two superseded queued workflow packets, and the root/local AGENTS/lifecycle docs.
- Blockers or open questions: None. Do not wait for a new procgen implementation decision; the known false-closure is sufficiently evidenced to author its correction packet, but runtime implementation belongs to that later correction workstream.
