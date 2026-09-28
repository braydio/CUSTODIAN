# Workstream Artifact Finalization Summary

This slice hardens the ephemeral workstream teardown boundary. `workstream.py finish`
now performs an artifact preflight before its existing clean-worktree/validation
checks and again after synchronizing latest `origin/main`.

The preflight associates task packets by stable `Workstream` metadata or the
workstream-derived filename. Associated packets must be moved out of the active
packet directory, carry a `complete` status, and no longer appear in the packet
README's active or recently-complete sections. Untracked files block teardown
and are reported as task-packet, closing-summary, Asset V2 source, review
evidence, disposable candidate, or unclassified. The tool does not delete,
stash, reset, or auto-commit any artifact.

Asset V2 source/inbox material is explicitly classified as durable-source work,
not disposable run debris. Validation JSON remains an input to finish unless a
task elects to retain it as evidence. The existing root
`<TASK>_CLAUDE_SUMMARY.md` requirement remains unchanged.

Focused coverage lives in
`custodian/tools/agent/test_workstream_artifacts.py`; the validation recipe now
includes it with the existing landing/workstream/hygiene test set. Agent routers,
packet template/readme, lifecycle docs, current-state text, and file index were
updated to match the enforced behavior.

Deferred intentionally: the historical pre-policy packet backlog under
"Recently Complete (awaiting archive)" was not bulk-moved as part of this
runtime-safety slice.
