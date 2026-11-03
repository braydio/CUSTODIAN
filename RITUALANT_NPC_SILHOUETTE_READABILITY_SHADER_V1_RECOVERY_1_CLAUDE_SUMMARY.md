# Ritualant NPC silhouette readability shader v1 recovery 1

Workstream: `ritualant-npc-silhouette-readability-shader-v1-recovery-1`

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae7eb07-c554-83e9-911a-1335e640e4d0

## Result

Ported the approved actor-local shader treatment from the verified donor archive onto current main. The production `NPCs/ForlornRitualant/AnimatedSprite2D` now uses a scene-local material with a bounded midtone lift and internal ash-silver rim cue. The shader samples only the current texture fragment, uses alpha derivatives for its edge, and passes incoming alpha through. Existing art, animation, transform, scene placement, collision and gameplay authority remain intact.

The exact October 17 human approval was reused: candidate `03678c0af88caf911166040a06fba460bcf4d2e0`, approved ROI SHA-256 `dffb67e0369b018c4fd5deb2410bf1634207bac62622f4695f20af3ef42931df`. Original evidence remains archived under `/home/braydenchaffee/.local/share/custodian/evidence/ritualant-npc-silhouette-readability-shader-v1-closeout-2026-11-02/`; manifest SHA-256 `1953c386dbffbd10e4138b257034ed7b2e3e1a2484ca404f755716e12191aa12`, tar SHA-256 `26602a9e1122e8676b5d00311fb1f4952a89ff0f9ea59f03edce0114b01bcfd1`. Donor tag `archive/agent-ritualant-npc-silhouette-readability-shader-v1-20261102` dereferences to `52e396976cb3a1444fac9377c58c2ae36cc48b41`. No new visual capture or sign-off was requested.

## Validation

- `forlorn_ritualant_presentation` canonical focused validation: PASS.
- `forlorn_ritualant_completion_smoke.gd`: PASS.
- `forlorn_ritualant_underground_smoke.gd`: PASS.
- `python3 custodian/tools/validation/run_validation.py --changed --json`: PASS, 6/6, complete coverage, 0 failures, timeouts, skips, or infrastructure errors. Report: `/home/braydenchaffee/.cache/custodian/validation/ritualant-npc-silhouette-readability-shader-v1-recovery-1/changed.json`.
- `git diff --check` and `python3 -m json.tool custodian/tools/validation/validation_manifest.json`: PASS.

The first fresh-worktree Godot import lacked generated class/font caches; one import attempt segfaulted in a worker while rebuilding an unchanged font. The exact matching generated font cache from the persistent checkout was reused; the canonical runner then passed. The focused scene validation reports 17 pre-existing stale UID fallback warnings from unchanged scene resource references. The underground smoke had an outdated expected spawn Y of 1670; corrected it to the unchanged production scene's authored Y of 1696.

Moment Forge: not run; the packet requires reuse of the existing human-approved ROI and does not require recapturing equivalent frames.

## Closeout

Implementation worktree started at `518ff1c51dd863277a05db95bf99fe3563abcb83`; validation source HEAD is that same base with the scoped changes above. The task packet is marked complete and moved to `custodian/docs/ai_context/task_packets/archived/` as part of canonical finish. The paired review remains a separate fresh-context workstream, dependency-gated until this implementation is landed and closed. Root checkout synchronization is pending because the persistent root is dirty; it was left untouched.

Next Handoff: `review-ritualant-npc-silhouette-readability-shader-v1-recovery-1` — after implementation landing, verify live dispatcher eligibility and launch only through the canonical paired-review runner. The review is not performed or accepted by this implementation workstream.
