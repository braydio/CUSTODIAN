# Agent Prompt Templates

These templates inherit repository workflow, authority, validation,
documentation, and Git defaults from `custodian/AGENTS.md` and the root
`AGENTS.md`. Fill the task-specific fields and keep the prompt focused on the
delta. Mark deliberate task-level exceptions `TASK OVERRIDE:` with a reason.
Substantial parallel work uses isolated worktrees. Validated implementation
work lands automatically on `origin/main`; review is by exception. Review-only
templates must explicitly override that default. For automated, dispatcher-
scheduled post-land review of a specific implementation packet (rather than an
ad hoc requested review), see `task_packets/README.md`'s Paired Review And
Correction section and `AGENT_REVIEW_PACKET_TEMPLATE.md` instead.

## Templates

- `implement_runtime_feature.md` — delta-only runtime implementation.
- `review_docs_drift.md` — documentation drift review.
- `update_sprite_pipeline.md` — sprite intake and pipeline work.
- `inspect_procgen_handoff.md` — procgen-to-consumer handoff inspection.
- `flip_spritesheet_frames.md` — mirror a spritesheet by frame grid.
- `tune_combat_feel.md` — combat feel tuning.
- `review_runtime_change.md` — runtime diff review.
- `scan_git_commit.md` — review-only Git audit/planning; explicitly overrides
  automatic landing and does not mutate repository state.

Run this after editing reusable templates:

```bash
python3 custodian/tools/agent/validate_prompt_contract.py --templates-only --strict
```

The default full scan also reports repeated boilerplate in active task packets;
use `--strict` for an explicit audit gate while migrating an existing packet.
