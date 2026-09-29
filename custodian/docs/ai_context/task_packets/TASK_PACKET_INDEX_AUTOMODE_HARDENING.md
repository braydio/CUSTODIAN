# TASK PACKET INDEX AUTOMODE HARDENING

- Workstream: `task-packet-index-automode-hardening`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `ai-context-task-packet-validator`
- Locks: `agent-workflow`
- Goal: Add a deterministic, bounded auto-maintenance path for the task-packet README index so new auto-dispatch packets cannot silently fall out of the visible job board while preserving manual packets, in-progress lifecycle state, and historical residue handling.
- Current measured state: `task_packets/README.md` is hand-maintained. `dispatch.py` already treats packet metadata on fetched `origin/main` as queue truth, while the queued AI-context validator is read-only and intentionally does not rewrite docs. The README's `Ready / Auto Dispatch` section can therefore drift from packet metadata; manual-ready packets are intentionally not required there. Existing `In Progress` and `Recently Complete (awaiting archive)` sections also contain lifecycle/history information that cannot be safely regenerated from packet front matter alone.
- Task-specific authority: `custodian/docs/ai_context/task_packets/README.md`, `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`, `custodian/tools/agent/dispatch.py`, and the completed `ai-context-task-packet-validator` parser/consistency contract.
- Change: Add one focused task-packet index authority, preferably `custodian/tools/agent/task_packet_index.py`, that reuses dispatcher/validator packet parsing and owns deterministic rendering/checking of only the `Ready / Auto Dispatch` section. Provide read-only check output plus an explicit write mode. Wire focused validation and documentation so packet authors can repair the generated block with one command.
- Preserve: `dispatch.py` remains task-selection authority; packet metadata on `origin/main` remains durable queue truth; manual-ready packets remain claimable only by explicit workstream selection and are not auto-indexed; `In Progress` and `Recently Complete` remain lifecycle/history-owned until a later explicit migration; README prose outside the managed block remains byte-stable; no background daemon or implicit commits.
- Non-goals: Do not auto-archive packets; do not infer subjective packet descriptions; do not mutate packet status; do not rewrite manual packet entries; do not regenerate the entire README; do not change dispatch priority/dependency/lock semantics; do not repair the existing historical Recently Complete backlog.
- Acceptance: The tool deterministically derives every top-level `Status: ready` + `Dispatch: auto` packet from current packet metadata, renders each once using filename plus normalized Goal text, preserves stable priority/path ordering compatible with dispatcher ordering, reports drift in check mode, rewrites only the managed Ready/Auto block in write mode, is idempotent, leaves manual-ready/in-progress/recent sections untouched, fails closed on malformed packet metadata, and has focused fixture tests for missing/stale/duplicate entries, manual packets, ordering, idempotence, malformed metadata, and preservation of unmanaged README content.
- Task overrides: none
- Deferred: Full README generation; automatic In Progress derivation from remote workstream refs; Recently Complete migration/cleanup; continuous watcher/CI autofix; auto-commit or auto-push behavior.

## Work Surface

- Files/systems to change:
  - `custodian/tools/agent/task_packet_index.py` or an equivalently focused existing agent-workflow module
  - focused tests under `custodian/tools/agent/`
  - `custodian/docs/ai_context/task_packets/README.md`
  - `custodian/docs/ai_context/VALIDATION_RECIPES.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
  - `custodian/docs/ai_context/AGENT_AUTOMATION_BACKLOG.md`
  - `custodian/tools/validation/validation_manifest.json` when needed for selection
- Related consumers or tests:
  - `custodian/tools/agent/dispatch.py`
  - `custodian/tools/agent/check_ai_context.py`
  - `custodian/tools/agent/workstream.py`

## Plan

1. Reuse the live packet parser/metadata validation. Do not create a second grammar for Workstream, Status, Dispatch, Priority, Depends on, or Locks.
2. Define a bounded managed block for `### Ready / Auto Dispatch`. Derive only top-level packets with `Status: ready` and `Dispatch: auto`; sort by the same effective priority/path ordering used by dispatch. Render the packet filename and a compact normalized form of its `Goal` field so descriptions do not require duplicate manual maintenance.
3. Add a read-only default/check mode and an explicit mutation mode such as `--write`. Check mode must return nonzero on drift with a deterministic diff/diagnostic. Write mode must modify only the managed Ready/Auto block and be idempotent.
4. Add focused temp-repo tests proving missing entry repair, stale entry removal, no duplicate entry, manual-ready exclusion, deterministic ordering, malformed packet refusal, idempotence, and byte preservation outside the managed block.
5. Integrate the command into packet-authoring/validation guidance. Do not make `dispatch.py status` or `claim-next` mutate the repository as a side effect.
6. Run focused tests first, then the AI-context validator and task-packet index check, then one changed-unit closeout sweep. Update only documentation whose workflow truth changed.

## Handoff

- Next action: Implement after `ai-context-task-packet-validator` is complete so the indexer can reuse one parser/consistency contract rather than duplicating validation logic.
- Best starting files: `custodian/tools/agent/dispatch.py`, the completed `custodian/tools/agent/check_ai_context.py`, `custodian/docs/ai_context/task_packets/README.md`, and `custodian/tools/agent/test_dispatch.py`.
- Blockers or open questions: None beyond the declared dependency. If the validator lands with a reusable parser module, use it; otherwise extract the smallest shared parser seam rather than copying front-matter logic.
