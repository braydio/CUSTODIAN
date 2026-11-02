# F14-B Review Correction · Collision-Free Causal Event IDs

**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31

## Result

Fixed review finding `R0-01` by making causal event IDs unambiguous with length-prefixed domain and group IDs. The accepted dotted identity grammar remains intact. Restore accepts the former schema-v5 event-ID encoding so snapshots written before this correction can still load; newly emitted events use the collision-free encoding.

Added a focused smoke case for domain/group pairs `a.b`/`c` and `a`/`b.c`. It proves they produce distinct event IDs, snapshot restore succeeds, canonical fingerprints and event sequences remain equal, and the prior schema-v5 ID form remains readable.

## Validation

- `world_simulation_abstract_activity_smoke.gd`: passed.
- `world_simulation_kernel_smoke.gd`: passed.
- `world_simulation_macro_state_smoke.gd`: passed.
- `world_simulation_snapshot_roundtrip_smoke.gd`: passed; its unsupported-schema negative control logged its expected diagnostic.
- `python3 custodian/tools/validation/run_validation.py --changed --json`: passed, 2 selected / 2 passed; included the abstract-activity smoke and an unrelated Operator contract check selected by current owner mapping.
- `git diff --check`: passed.
- Nine generated reference-art `.import` sidecars were removed after validation.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Fresh Godot project initialization reimported 9,662 assets. A Python bytecode check was mistakenly attempted on GDScript and rejected as invalid syntax; Godot validation passed.
- Root cause / contributing factors: The worktree had no editor import cache, and the wrong language-specific parser was invoked once.
- Prevention / pipeline improvement: Initialize project metadata before focused Godot validation; use Godot for GDScript validation.
- Tooling / docs drift discovered: none
- Follow-up: review-living-world-abstract-activity-foundation-review-corrections-1
- What worked: The collision regression directly exercises the failure and snapshot continuation contract.

## Next Handoff

- Next workstream: `review-living-world-abstract-activity-foundation-review-corrections-1`
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Refresh reason: none
- Next action: Start a fresh reviewer context and claim the paired re-review after this correction lands and archives complete.
- Blockers or open questions: the correction's paired review requires fresh reviewer context.
