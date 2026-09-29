# AI CONTEXT AND TASK PACKET VALIDATOR

- Workstream: `ai-context-task-packet-validator`
- Kind: `implementation`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `review-agent-review-pipeline`
- Locks: `agent-workflow`
- Review: `none`
- Goal: Implement the lightweight AI-context/task-packet validator already prioritized in the automation backlog so stale paths, packet/index drift, malformed V2 task contracts, and broken workflow references fail visibly before agent handoff.
- Current measured state: dispatcher/workstream/review tooling now relies heavily on docs and packet metadata as executable coordination truth. The repo still accumulates manual packet-index drift and the automation backlog explicitly lists `custodian/tools/agent/check_ai_context.py` as the next lightweight validator.
- Task-specific authority: `AGENT_AUTOMATION_BACKLOG.md`, `FILE_INDEX.md`, `task_packets/README.md`, `AGENT_TASK_PACKET_TEMPLATE.md`, live dispatcher packet parser, and validation manifest conventions.
- Change: Add a read-only `check_ai_context.py` plus focused tests/manifest ownership that verifies required context files, active/archived packet consistency, indexed packet existence, auto-dispatch metadata sanity, the versioned `custodian.task_packet.v2` authoring contract, completed V2 execution-feedback receipts, and a bounded set of workflow-authority references.
- Preserve: dispatcher remains task-selection authority; review pipeline remains review authority; no automatic doc rewriting; historical archived packets are not churned just for old wording.
- Non-goals: No general Markdown link checker; no full repository documentation linter; no prose-quality scoring; no automatic packet archiving; no continuous watcher; no mutation of main.
- Acceptance: the validator exits green on consistent current main and fails with precise path/packet diagnostics for missing required AI context, active packet indexed as archived or vice versa, nonexistent indexed packet, malformed auto-dispatch metadata, malformed V2 packet contracts, complete V2 packets missing actionable execution feedback, or current-authority docs pointing at a removed required workflow file. Legacy packets without a packet schema remain valid.

## Checks

At minimum:

### Required context existence

Validate the current required AI context set, including:

- `custodian/AGENTS.md`
- `custodian/docs/ai_context/CONTEXT.md`
- `CURRENT_STATE.md`
- `FILE_INDEX.md`
- `VALIDATION_RECIPES.md`
- `AGENT_WORKSTREAM_LIFECYCLE.md`
- task-packet README/template
- current agent tooling paths referenced by those authorities.

Keep the list centralized and intentionally small.

### Packet/index consistency

For active top-level packet files:

- file exists;
- status is not `complete`;
- if README indexes it under Ready/Auto, packet must be `Status: ready` and `Dispatch: auto`;
- if README indexes it under In Progress, status must be compatible;
- archived packets must not appear in active sections;
- active packet names in README must resolve to files;
- duplicate active index entries fail.

Do not require every historical packet to be indexed.

### Auto-dispatch metadata

Reuse dispatcher parser/validation where practical rather than duplicating grammar.

Check:

- valid workstream ID;
- valid priority;
- valid dispatch value;
- dependency/lock parseability;
- review pair fields when live review-pipeline contract requires them.

### V2 task-packet contract

Treat packets without `Packet schema` as legacy and do not force a bulk
migration.

For `Packet schema: custodian.task_packet.v2`, reuse the live packet parser
where practical and require non-empty:

- `Reviewed main`
- `Goal`
- `Completion boundary`
- `Current measured state`
- `Evidence`
- `Task-specific authority`
- `Work surface`
- `Change`
- `Preserve`
- `Non-goals`
- `Acceptance`
- `Validation`
- `Deferred`

Validate that `Reviewed main` is SHA-like and that a ready V2 packet does not
contain untouched template placeholders.

Do not attempt subjective prose scoring. Structural presence and obvious
placeholder detection are enough; semantic quality remains an author/reviewer
responsibility.

For a V2 packet with `Status: complete`, require a structured
`## Execution Feedback` receipt with:

- `Feedback schema: custodian.task_feedback.v1`
- `Outcome: success | partial | blocked`
- `Friction severity: none | low | medium | high`
- non-empty `What went wrong`
- non-empty `Root cause / contributing factors`
- non-empty `Prevention / pipeline improvement`
- non-empty `Tooling / docs drift discovered`
- non-empty `Follow-up`

Literal `none` is valid where nothing occurred. `What worked` is optional.

### Authority-path drift

Validate only explicit current-authority paths in a small manifest/list.

Do not grep every archived document and generate noise.

## CLI

```bash
python3 custodian/tools/agent/check_ai_context.py
python3 custodian/tools/agent/check_ai_context.py --json
```

JSON should be deterministic and useful to CI/agent closeout.

## Focused Tests

Use temp fixtures to prove:

1. current consistent fixture passes;
2. missing required context fails;
3. nonexistent active packet index entry fails;
4. archived packet listed active fails;
5. ready/auto index with manual packet fails;
6. duplicate active index entry fails;
7. malformed workstream/priority fails;
8. historical unindexed archived packet is allowed;
9. bounded authority-path missing target fails;
10. JSON output is deterministic;
11. legacy packet without schema remains valid;
12. ready V2 packet missing a required contract field fails;
13. V2 packet with untouched placeholders fails;
14. complete V2 packet missing execution feedback fails;
15. complete V2 packet with a valid `custodian.task_feedback.v1` receipt passes.

Register in `validation_manifest.json` and document in VALIDATION_RECIPES.

## Documentation Drift

After implementation:

- mark this item implemented in `AGENT_AUTOMATION_BACKLOG.md`;
- index tool/test in FILE_INDEX;
- document that this catches coordination-document drift but does not replace semantic human review.

## Completion

Archive complete, write
`AI_CONTEXT_TASK_PACKET_VALIDATOR_CLAUDE_SUMMARY.md`, run focused + changed-unit validation, and land normally.