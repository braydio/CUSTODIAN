# Operator Workbench Publish Readiness Recovery — Cycle 2 Independent Review

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac8f303-1b34-83ea-a74b-3e3973c9667d

## Findings

- **R0-01 — fixed.** Cycle 2 binds every Workbench publication binding to the selected animation plan before preparation, derives publication/allowlist paths from that validated plan, then reloads and revalidates the manifest path set in the pre-mutation callback before readiness inspection and backend publication. The initial-rebind control and the post-preparation path-swap control both fail before `animation_workbench.publish()` and preserve source/runtime hashes, HEAD, and Git status. The selected-path positive control stages exactly the selected source and lands only that path through the fixture remote. No additional cycle-2 finding was identified.

## Review evidence

- Reviewed live main at `8756927453ee8fc0eee2ab194e8c7098f2a6271a` in a fresh worktree. Reviewer context: `fresh`; reviewer provenance: `different-agent`.
- Confirmed the selected identity, source/publish path validation, mirror target derivation, readiness/allowlist boundary, final manifest reload, and scoped staging/landing path in the live implementation.
- Confirmed correction commit `2b5d645c7e6d1fa9f07559109f90b7c0c974480d` contains no art or gameplay changes. Reviewed implementation files (`ui/service.py`, CLI boundary smoke, Workbench backend, and art-worktree publisher) are unchanged after that correction commit.
- `operator_cli_publish_boundary_smoke.py` — PASS. Rebound manifest with internally consistent alternate-source hashes and post-preparation path substitution were rejected before backend mutation; selected-path publication staged and landed only `[SOURCE]` on the fixture remote.
- `operator_art_worktree_smoke.py` — PASS, including fixture-only landing race/retry coverage.
- `operator_workbench_mirror_publish_smoke.py` — PASS.
- `operator_workbench_ui_smoke.py` — PASS; optional Textual pilot skipped because its dependency is not installed.
- `operator_animation_workbench_smoke.py` — PASS.
- `git diff --check` — PASS.
- All publication remotes exercised by these validations were local fixtures; no test data was sent to the project remote.

## Awkward parts

- The code-review graph returned `graph is empty: nothing is indexed` for the relevant symbols in this worktree. I used exact symbol/path source reads after recording that limitation.
- The art-worktree smoke printed its expected fixture-only remote-advancement/retry diagnostics before completing with PASS.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The local graph index was empty; one fixture smoke exercised a deliberate landing race and emitted retry diagnostics.
- Root cause / contributing factors: The review worktree had no indexed graph data; the smoke intentionally simulates remote advancement.
- Prevention / pipeline improvement: Fall back to exact source reads when graph discovery is empty; retain the smoke's race/retry control.
- Tooling / docs drift discovered: The graph index was empty. `task_packet_index.py` reports its managed block stale; the writer proposed unrelated 2.5D packet removals and a Procgen description rewrite, so those out-of-scope changes were preserved rather than committed.
- Follow-up: none
- What worked: CLI-level single-fault tamper controls plus fixture remotes proved the blocking publication boundary before mutation and on the successful scoped path.

## Next Handoff

- Next workstream: operator-workbench-browser-preview-disconnect-ownership-correction
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac8f303-1b34-83ea-a74b-3e3973c9667d
- Refresh reason: none
- Next action: Claim the already human-authorized browser Preview disconnect-ownership correction; FX-layer adoption remains gated on its paired review.
- Blockers or open questions: none.
