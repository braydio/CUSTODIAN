# Sepulcher V2 Host-Validation Recovery Summary

- Workstream: `agent-sepulcher-v2-host-validation-recovery-v1`
- Authoring chat: `not-recorded`
- Implementation base: `f070b4ee7f46c16890469889886bc13126705387`
- Scope: corrected the V2 smoke ordering and narrowly authenticated genuine failed validation reports from an exact archive-only source span. No V2 runtime scene, art, production gameplay, original review claim, worktree, lock, or run evidence was changed.

## Changes

- The smoke now checks the authored spawn marker and bootstrapped Operator at the immediate ready boundary, before yielding frames. It keeps the full profile, real Operator/controller, movement, presentation, camera, collision, and navigation assertions.
- Before restoring the fixed comparison position, the smoke releases input and disables controller processing and Operator physics. It checks the restored position with a small tolerance and verifies it stays fixed across physics frames.
- The report verifier now validates a failed report against the exact trusted lifecycle source span when the validation manifest change is covered by an archive-only canonical packet archive. It checks the reviewed-main manifest, changed-test selection, coverage, code paths, exact report hashes, and consistent failure exit code. This path returns only failed evidence; a passing report is rejected.
- Added regression coverage for the archive-only path, fake PASS, wrong exit, source-span workstream mismatch, and selection drift. Existing post-hoc-attestation failed-report coverage remains green.

## Evidence

- Original held V2 run: `20261101T135711Z-571d69329b77`, reviewed main `58f52ac2b8f7e5ea60b48a00a3af57f55ee32c79`.
- Original report hashes were read-only verified before implementation: `metadata.json` `8b7045f5d0bd9b954fb4d6147557526f7ca628b6611025f6d79f2299e442a370`; `validation.json` `0687acf7be15f17e91c8bfb511a43dd5b666646c09942815dc9081144f2fe790`; `coordinator-validation.json` `ef3e205782ad7afbc4855b2a8ed40e2b5253412b04e52aa6805861b3a5716254`.
- Focused paired-review tests: 3 passed, including the old attestation path and new archive-only failed-evidence path.
- `python3 -m py_compile` on the runner and its test module: passed.
- `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`: passed all selected checks (`agent_workflow_contract`, `paired_review_runner_unit`, `sepulcher_material_operator_v2`), including 275 runner unit tests and complete changed-file coverage.
- V2 focused gameplay smoke: three consecutive cached gameplay runs passed after import. The initial cold import failed as infrastructure with Godot TLS handshake error `-27648`; no gameplay test was counted for that import failure.
- Neighboring V1 Sepulcher smoke: passed.
- `git diff --check`: passed.
- `## Process Feedback`: medium-friction TLS import failures were retained as infrastructure evidence; retry was serial and three independent cold runs ultimately passed.

## Process Feedback

- Outcome: success; friction severity: medium.
- What went wrong: clean-cache Godot imports intermittently failed with TLS handshake error `-27648` before gameplay.
- Root cause / contributing factors: editor import intermittently reached an unavailable TLS endpoint; later clean imports succeeded without source changes.
- Prevention / pipeline improvement: distinguish import infrastructure failures from gameplay, retry serially, and require three cold passing runs.
- Tooling / docs drift: failed-report authentication incorrectly required post-hoc attestation for an exact archive-only manifest span.
- Follow-up: fixed in scope; exact archive-trace validation and regressions were added.

## Review and held-run boundary

The original V2 run remains a genuine failed pre-review host-validation result, with no verdict and unchanged report bytes. This correction cannot retroactively validate the old pinned source. After this recovery lands and receives its own independent review, use the supported read-only plan for the original run:

`python3 custodian/tools/agent/paired_review_runner.py review-sepulcher-canonical-operator-floor-v2-preview-v1 --continue-run 20261101T135711Z-571d69329b77 --recover-host-validation --plan`

Review that emitted plan and its hashes before any separately authorized apply. Do not treat the failed report as a PASS. To review corrected V2 source, claim a fresh review workstream targeting the corrected landed commit; do not relaunch the preserved old run. Human visual approval remains separate.

## Handoff

- Paired recovery review: `review-agent-sepulcher-v2-host-validation-recovery-v1` (dependency-gated until this implementation lands).
- Original V2 review claim/worktree/run: preserved; no verdict.
- Human visual decision: outstanding.


## Closeout Status

- Correction implementation commit: `de43568f51125fe49bc5ca3915b3f348ad3d35a3` (source); final smoke fault and packet updates are in later branch commits.
- Latest branch checkpoint: `287be4a8356fe487915537e17a19d3b658b997b3`, verified at `origin/agent/agent-sepulcher-v2-host-validation-recovery-v1`.
- Main landing: blocked. `workstream.py finish` rejected the synchronized merge because it lacks a unique exact pre-sync checkpoint witness. No branch rewriting, fabricated trace event, or manual landing was attempted.
- Independent recovery review: dependency-gated and not claimed.
- Next supported action: resolve the missing lifecycle witness through a separately authorized repository workflow correction or recovery; then finish this same workstream, claim `review-agent-sepulcher-v2-host-validation-recovery-v1` in its fresh context, and only afterward plan the preserved original V2 run disposition.
