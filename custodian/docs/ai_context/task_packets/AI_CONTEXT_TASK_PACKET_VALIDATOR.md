# AI CONTEXT AND TASK PACKET VALIDATOR

- Workstream: `ai-context-task-packet-validator`
- Kind: `implementation`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `review-agent-review-pipeline`
- Locks: `agent-workflow`
- Review: `none`
- Goal: Implement the lightweight AI-context validator already prioritized in the automation backlog so stale paths, packet/index state drift, and broken workflow references fail visibly before agent handoff.
- Current measured state: dispatcher/workstream/review tooling now relies heavily on docs and packet metadata as executable coordination truth. The repo still accumulates manual packet-index drift and the automation backlog explicitly lists `custodian/tools/agent/check_ai_context.py` as the next lightweight validator.
- Task-specific authority: `AGENT_AUTOMATION_BACKLOG.md`, `FILE_INDEX.md`, `task_packets/README.md`, `AGENT_TASK_PACKET_TEMPLATE.md`, live dispatcher packet parser, and validation manifest conventions.
- Change: Add a read-only `check_ai_context.py` plus focused tests/manifest ownership that verifies required context files, active/archived packet consistency, indexed packet existence, auto-dispatch metadata sanity, and a bounded set of workflow-authority references.
- Preserve: dispatcher remains task-selection authority; review pipeline remains review authority; no automatic doc rewriting; historical archived packets are not churned just for old wording.
- Non-goals: No general Markdown link checker; no full repository documentation linter; no prose-quality scoring; no automatic packet archiving; no continuous watcher; no mutation of main.
- Acceptance: the validator exits green on consistent current main and fails with precise path/packet diagnostics for missing required AI context, active packet indexed as archived or vice versa, nonexistent indexed packet, malformed auto-dispatch metadata, or current-authority docs pointing at a removed required workflow file.

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
10. JSON output is deterministic.

Register in `validation_manifest.json` and document in VALIDATION_RECIPES.

## Documentation Drift

After implementation:

- mark this item implemented in `AGENT_AUTOMATION_BACKLOG.md`;
- index tool/test in FILE_INDEX;
- document that this catches coordination-document drift but does not replace semantic human review.

## Completion

Archive complete, write
`AI_CONTEXT_TASK_PACKET_VALIDATOR_CLAUDE_SUMMARY.md`, run focused + changed-unit validation, and land normally.
