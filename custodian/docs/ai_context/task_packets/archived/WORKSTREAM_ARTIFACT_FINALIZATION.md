# WORKSTREAM ARTIFACT FINALIZATION

- Workstream: `workstream-artifact-finalization`
- Status: `complete`
- Goal: Prevent ephemeral worktree teardown from silently losing or stranding task packets, review evidence, Asset V2 source material, summaries, or other run artifacts.
- Current measured state: `workstream.py finish` previously required a clean worktree, committed closing summary, and green validation, but did not associate/validate task packets or classify unresolved untracked run artifacts.
- Task-specific authority: `AGENTS.md`, `custodian/AGENTS.md`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`, and `custodian/docs/ai_context/task_packets/README.md`.
- Change: Add a non-destructive artifact preflight before finish and after latest-main synchronization. Associated task packets must be complete and archived; stale active README entries block; untracked files are classified and block teardown until explicitly committed or removed.
- Preserve: Existing push-first recovery branch, validation gate, main synchronization, ancestry verification, branch deletion, and worktree teardown behavior.
- Non-goals: Do not auto-delete scratch files, auto-commit artifacts, bulk-archive pre-existing historical packet backlog, or change Asset Pipeline V2 ownership.
- Acceptance: Associated active packets block finish; complete archived packets pass; incomplete archived packets block; stale packet-index entries block; untracked report/source files block with useful classification; docs/template/validation recipe match runtime behavior.
- Task overrides: none
- Deferred: Existing pre-policy `Recently Complete (awaiting archive)` packet backlog remains a separate cleanup task.
