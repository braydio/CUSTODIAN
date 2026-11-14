# Operator Runtime Decomplexification Summary

Completed C2b.2 in `operator-runtime-decomplexification`.

- Removed Operator-owned `AnimationResolver` and `DirectionalAnimationFallback` dependencies and deleted `animation_resolver.gd`.
- Routed heavy E/W and light S damage reactions through canonical runtime identities; made dodge charge/link use exact eight-sector selection.
- Tightened the authority smoke, registered the canonical reaction smoke, refreshed the debt baseline from 95 to 75, and reconciled current-state/design docs.
- Canonical light hit-react art is 3 frames at 10 FPS per the generated runtime manifest. Heavy authored E/W strips remain 12 frames at 12 FPS. The smoke asserts the canonical rates and the 0.22/1.0 second reaction durations.

## Validation

Passed: architecture debt audit (75 remaining), Operator runtime-animation-authority smoke, canonical knockdown/reaction smoke, modular idle-hitreact, dodge flow, dodge FX canonical, parry presentation, Vigil Dagger, Sword Cleaver, unarmed fast chain, canonical animated sprite, immutable runtime spine, and visual ownership.

`run_validation.py --changed --json` ran but was not green. Its Operator architecture, reachability, and melee checks passed; unrelated Baby Opossum, elevated-world asset, Meridian semantic-manifest, procgen-ocean, and Vaultwing asset checks failed or lacked source assets in this worktree. The reaction smoke passed independently after repairing its test harness.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: The fresh worktree lacked hydrated Git LFS dependencies and had an invalid LimboAI pointer. Godot import rewrote thousands of unrelated `.import` sidecars. The initial reaction smoke incorrectly relied on same-state re-entry and sampled hit-stop at a transient frame. The changed-files sweep surfaced unrelated missing/corrupt assets.
- Root cause / contributing factors: Workstream creation leaves LFS objects as pointers. Importing before hydration records invalid import metadata. The smoke combined state-machine behavior with canonical presentation selection, making the test sensitive to re-entry semantics and timing.
- Prevention / pipeline improvement: Hydrate locally available LFS dependencies before import and restore generated sidecars after import. Isolate canonical presentation smoke cases from repeated state-machine entry and assert stable evidence rather than transient hit-stop state.
- Tooling / docs drift discovered: Canonical light hit-react uses 10 FPS, not the old smoke’s assumed 12 FPS. Broad changed validation in a fresh worktree may hit unrelated absent/corrupt asset inputs.
- Follow-up: C2b.3 compatibility residue remains queued in `OPERATOR_RUNTIME_COMPATIBILITY_RESIDUE.md`.
- What worked: Focused tests and the debt audit became deterministic after local LFS hydration; no network fetch was needed.

C2b.3 remains the next Operator runtime slice. This task did not start action arbitration or domain extraction.
