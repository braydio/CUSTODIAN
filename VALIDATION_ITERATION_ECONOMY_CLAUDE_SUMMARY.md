# Validation Iteration Economy — Closeout

## Delivered

- Added a dedicated validation-iteration economy section to `custodian/AGENTS.md`.
- Made focused validation the default edit/test loop and moved broad `--changed`
  validation to the task closeout boundary.
- Made Moment Forge capture escalation explicit:
  `none` while debugging, `evidence` for the first reviewable green run, and
  `full` only for final audiovisual review when actually required.
- Explicitly forbade overlapping focused and broad validation against the same
  Godot project.
- Added guidance against tight process polling, giant fallback source dumps when
  code-review-graph is unavailable, and interleaving two substantial tasks'
  implementation/validation loops.
- Added concrete command sequencing to
  `custodian/docs/ai_context/VALIDATION_RECIPES.md`.

## Documentation Drift Check

The existing guidance was not factually stale: it already warned about broad
sweep resource cost, single-sweep execution, and Moment Forge capture modes.
The missing piece was explicit iteration sequencing and task-switch discipline.
This pass strengthens that workflow without changing runtime, design authority,
or validation ownership.

## Validation

Doc-only workflow change. Verified the edited files remain the existing
canonical routing/validation authorities and introduce no new runtime paths,
assets, or task-packet authority.
