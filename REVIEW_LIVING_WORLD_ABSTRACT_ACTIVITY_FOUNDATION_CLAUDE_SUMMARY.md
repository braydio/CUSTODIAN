# F14-B Independent Review · Living-World Abstract Activity Foundation

**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31

## Verdict

The review found one blocking correctness defect in causal event identity. The abstract-activity slice otherwise passed its focused state, kernel, macro-state, and snapshot checks. The correction is isolated in `living-world-abstract-activity-foundation-review-corrections-1`; reviewed runtime code was not modified.

## Finding

### R0-01 · blocking_defect · implementation

- **Affected acceptance:** F14-B acceptance 3 (deterministic event sequence), 4 (snapshot continuation/fingerprint), and 6 (duplicate identity/consequence handling).
- **Evidence:** `abstract_activity_simulation_state.gd:114-116` constructs event IDs by joining domain ID, group ID, and fixed tick with periods. `_valid_id` accepts periods. The valid pairs domain/group `a.b`/`c` and `a`/`b.c` both emitted `a.b.c.60`. A fresh Godot probe confirmed `ids_unique=false` and `SimulationSnapshot.restore(...) == null`, because restore rejects duplicate event IDs.
- **Disposition:** `correction`.
- **Rationale:** A valid identity pair can make the canonical snapshot un-restorable. The bounded correction requires an unambiguous event-ID encoding and a regression that proves event uniqueness and snapshot continuation.

## Review evidence

- `world_simulation_abstract_activity_smoke.gd`: PASS after project class-cache initialization.
- `world_simulation_kernel_smoke.gd`: PASS.
- `world_simulation_macro_state_smoke.gd`: PASS.
- `world_simulation_snapshot_roundtrip_smoke.gd`: PASS; expected unsupported-schema negative-control diagnostics appeared.
- `world_simulation_live_scene_smoke.gd`: attempted, then interrupted after the fresh-worktree editor import had exited with code 139 and left required `.godot/imported` resources unavailable. It entered repeated generated-world retries and was stopped; it did not produce a valid pass/fail result. This runtime smoke is unaffected by the reviewed owner files and had passed in the implementation run.
- Correction probe: reproduced duplicate IDs and failed snapshot restore for the two accepted identity pairs above.
- Correction/re-review packet pair: targeted authoring preflight PASS; task packet index write and check PASS.
- No broad changed-file sweep was run for this review-only artifact update.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: partial
- Friction severity: medium
- What went wrong: The first editor import in the fresh worktree exited 139 after generating global class metadata, and the live-scene smoke then lacked imported assets and caused expensive generated-world retries before interruption.
- Root cause / contributing factors: First-import Godot initialization attempted a large asset reimport and crashed after class registration; direct smoke execution continued with an incomplete import cache.
- Prevention / pipeline improvement: Use the focused activity/kernel/macro/snapshot smokes for this state-only review. The live-scene smoke can be rerun after a successful editor import if its evidence becomes material to the correction.
- Tooling / docs drift discovered: none.
- Follow-up: `living-world-abstract-activity-foundation-review-corrections-1`
- What worked: The focused state smoke passed and a minimal isolated probe exposed the collision without touching runtime files.

## Next Handoff

- Next workstream: `living-world-abstract-activity-foundation-review-corrections-1`
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Refresh reason: none
- Next action: Claim and implement the bounded event-ID correction; the paired re-review then returns the corrected B state and evidence to the authoring chat for F14-C contract refresh.
- Blockers or open questions: none for correction dispatch after this review lands.
