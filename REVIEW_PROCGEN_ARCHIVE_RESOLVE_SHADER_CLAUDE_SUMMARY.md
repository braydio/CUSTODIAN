# REVIEW_PROCGEN_ARCHIVE_RESOLVE_SHADER summary

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7

AR2 cycle-0 independent review on `e60e097f2` (implementation `085a38a5e`, renderer recovery landed). Result: **passed, 0 blocking defects, 0 material evidence gaps.** The receipt is on the archived AR2 packet. Reviewer context `fresh`, provenance `same-agent-fresh-context`; the recovery summary was treated as a claim and re-verified.

## Findings (none create correction work)

- `R0-01` non_blocking, pipeline, `next_slice`: the archived recovery packet's Completion Truth evidence still says the visual approval was given "in the recorded authoring chat after reviewing the published Dropbox contact sheet". The recovery closing summary and the user say it was given in-session on 2026-10-05, not in that chat. The human decision exists, so the gate is satisfied, but the durable packet text is contradicted by the summary. I did not edit the recovery packet (outside this review's override). Correct that wording, or have the user restate the approval in the authoring chat, during the AR3 refresh. I could not verify the Dropbox manifest from this machine (no local Dropbox mirror); it rests on the recovery summary.
- `R0-02` non_blocking, implementation, `next_slice`: ARR1 R0-02 proof in `procgen_archive_resolve_shader_smoke.gd` is a text-offset check on `game.tscn` (ContractMap before Enemies/Projectiles/Allies/Items/Operator). It does not assert effective draw order or that z3/z4 foreground stays above actors. I checked the scene directly: ContractMap precedes all five containers, and the veil is a later sibling than the z2 `PropLayer`/`Walls` inside the map, with `TerrainPresentationFront` at absolute z4. The ordering is correct; only the test is weak.
- `R0-03` non_blocking, implementation, `no_action`: `procgen_distant_chunk_unload_smoke.gd` still has the original `if had_road_decal:` blocks (lines 289, 327). The new F2 block asserts road-decal unload, queued reacquisition and immediate reacquisition unconditionally through the production `_reveal_road_piece_decal`, so the claimed parity no longer depends on them. They are vestigial.
- `R0-04` optional_improvement, implementation, `deferred`: `ProcGenTilemap.archive_resolve_enabled` is a plain exported var. Direct writes after init do not reach the veil; only `set_archive_resolve_enabled()` does. The packet only required the API.

## ARR1 follow-ups, verified directly
- R0-01 live disable: `effect_enabled` is now a setter that calls `_settle_all_immediately()`, and `set_effect_enabled()` and the map API share it. The smoke covers the direct write, a late commit while disabled, and re-enable.
- R0-02 ordering: see `R0-02` above.
- R0-03 production map: the smoke runs live disable/re-enable and a 64-slot pool on the real map, with lifecycle fingerprint parity against the 8192-slot baseline, peak ≤ 64, overflow counted, settled == requested.
- R0-04 road decal: closed as above.

## Shader and material review
- One `ShaderMaterial`, bound to the existing `ArchiveResolveVeil`; no per-cell nodes or materials (`shared_material_count=1` in every probe).
- `COLOR.a` stays the progress channel. `INSTANCE_CUSTOM` is written once per slot assignment (`identity_write_count` unchanged across `advance()`), not rescanned per frame.
- No `TIME` in the shader. Motion uses `presentation_time`, which only `advance()` and `reset()` write. Fresh probes: it froze at 2.05 while the tree was paused (ticks 121-149) and resumed at 2.083.
- REQUESTED/READY cover is opaque (`veil >= 0.995` yields alpha 1; threshold is clamped to 0.97 so early RESOLVING stays opaque). The shader discards at `veil <= 0.001`, and released slots are hidden, so settled terrain has no veil object.
- Misregistration offset is at most 1 px and only shifts the trace sampling lattice. There is no screen-texture read.
- Reduced effects zeroes misregistration and scales registration to 0.25. The scheduling trace is identical to normal mode in the smoke.

## Evidence run by this review (all on the review worktree)
- Fresh real-renderer Moment Forge run `procgen/archive_resolve_shader_review` (Vulkan, GTX 1650 SUPER, capture-mode evidence): no shader parse/link/runtime errors in `godot.log`; the only errors are the usual exit-time ObjectDB/resource leak lines. Probes: 1020 active instances at start, 0 after settlement, reduced-effects reveal of 517 tiles, 44 reacquisitions after a forced unload, `actor_above_veil` true throughout. The contact sheet shows irregular dithered fronts, no 32 px grid or chunk rectangles, the actor above the veil, and ordinary settled terrain.
- Passed: `procgen_archive_resolve_shader`, `procgen_reveal_presentation`, `procgen_pause_aware_streaming`, `procgen_chunk_lifecycle`, `procgen_chunk_payload_cache`, `procgen_distant_chunk_unload`, `procgen_runtime_health`, `procgen_candidate_materializer_parity`, `procgen_region_frame`. S1 quick `determinism_ok=true`, fingerprint `1773840677`.
- Not done: no mutation probes; the aesthetic baseline was not judged (human-owned). The throwaway capture under `reports/moment_forge/` was removed, not committed.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: `run_moment.py` rejected an out-of-tree `--output-root` even with `--allow-external-output`; a fresh worktree needs `godot --import` first.
- Root cause / contributing factors: the output guard requires a child of the worktree's `reports/moment_forge`; the import cache is per worktree.
- Prevention / pipeline improvement: have the runner's error name the accepted root; have `dispatch.py claim` print the import hint for review packets that need Godot.
- Tooling / docs drift discovered: the archived recovery packet's approval provenance contradicts its closing summary (`R0-01`).
- Follow-up: manual-follow-up
- What worked: the recovery's Moment Forge scenario reran unchanged and reproduced every claimed probe.

## Next Handoff
- Next workstream: `procgen-archive-resolve-semantic-echo`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7
- Refresh reason: AR3 must be re-derived against the reviewed AR2 shader/material/custom-data contract (`INSTANCE_CUSTOM.g` reacquisition flag is written but unstyled; `.b` reserved) and the current semantic-owner surface.
- Next action: Bring the AR2 implementation evidence, the recovery summary, this receipt, and the Dropbox manifest to the authoring chat and refresh AR3 in place; also settle the `R0-01` approval-provenance wording there before any AR3 claim.
- Blockers or open questions: AR3 stays blocked/manual until that refresh completes.

## Reminder

Ran on `agent/review-procgen-archive-resolve-shader` in a separate worktree. Your root checkout should stay on `main`; switch back if you left it.
