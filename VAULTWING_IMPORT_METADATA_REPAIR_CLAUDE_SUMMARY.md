# Vaultwing Import Metadata Repair

## Outcome

Restored valid Godot importer remap metadata for the 15 Vaultwing bonding textures whose tracked `.png.import` sidecars had been replaced by `valid=false`. This is the bounded asset-side repair needed for clean-checkout import and `actor_relationship_contract`.

The current `origin/main` state was reproduced in a disposable detached checkout at `fb2f634bc`. Its LFS preflight passed, and `godot --headless --path custodian --import --quit` exited 0. The actor smoke nevertheless failed because Godot could not load the 15 Vaultwing bonding texture resources. The source PNGs were materialized and valid; `7b94bb6f6` had removed each sidecar's generated `path` and `dest_files` remap and left `valid=false`.

Restoring those importer records from the preceding known-good metadata and importing in a fresh workstream cache regenerated the targets. `actor_relationship_contract` then passed with its existing structured assertions intact. No gameplay relationship behavior or resolver logic changed.

## Validation

- `godot_import_preflight.py --project-dir custodian`: PASS; no checked-out LFS pointers.
- `godot --headless --path custodian --import --quit`: PASS; exit 0; repaired bonding textures were reimported.
- `run_validation.py --test actor_relationship_contract --json`: PASS; 1 passed, 0 failed, 0 skipped. The existing navigation warning remains non-fatal.
- `git diff --check`: PASS.

A separate remaining baseline issue is recorded for the next handoff: `world_transition_handoff` has intermittently returned `TARGET_SCENE_UNAVAILABLE` for request `awakening-hub-0002` after the Hub path was switched to the production scene. The unmodified test also passes in direct execution, so the transition failure needs its own deterministic reproduction and correction before NPA-7 resumes. It is not included in this asset-import change.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: invalid tracked importer sidecars made a fresh imported checkout fail a resource-loading validation despite a successful LFS preflight and Godot import exit.
- Root cause / contributing factors: the 15 sidecars had their generated remap target records removed and were committed with `valid=false`; the import command did not regenerate those records from that state.
- Prevention / pipeline improvement: validate representative LFS-backed runtime assets through a fresh-checkout import followed by their registered resource-loading smoke.
- Tooling / docs drift discovered: `world_transition_handoff` exposes an intermittent target-scene load failure in the same clean validation environment; it remains a separate owning-workstream issue.
- Follow-up: world-transition-handoff-baseline-repair
- What worked: sidecar provenance comparison against the known-good parent isolated the failure without changing runtime targeting semantics.

## Next Handoff
- Next workstream: world-transition-handoff-baseline-repair
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: none
- Next action: Reproduce and correct the `world_transition_handoff` target-scene failure in its world-transition owner, then rerun both baseline checks before resuming NPA-7.
- Blockers or open questions: exact cause of the intermittent `TARGET_SCENE_UNAVAILABLE` result remains under investigation.
