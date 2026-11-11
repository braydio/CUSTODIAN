# Operator 3D Workbench Intake V1 — Claude summary

Workstream: `operator-3d-workbench-intake-v1` · Branch: `agent/operator-3d-workbench-intake-v1`
Base: `origin/main@a16fb3ece74f`. Implementation commit `2efb97a82`; this round's corrections are a new commit on top of it. Not landed.

## Status

Candidate-only Walking (`unarmed/locomotion/walk_01`, 25f, pivot 50,107) and Running (`unarmed/locomotion/run_01`, 15f, pivot 62,108) are registered as 16 read-only `operator_3d_80` directional sessions (320 frames, 160×160 RGBA). Not landed. Independent review pending.

## Review corrections (this round)

1. **Additive registration.** A session's validity now depends on a `binding` (its own action's spec hash, motion hash, meta hash, identity, and frame hashes). Whole-contract and whole-manifest hashes move to an audit-only `provenance` block. Verify and apply compare bindings. Tests: an unrelated new contract action, an unrelated new manifest action, a changed motion hash, and a changed pivot. Only the last two fail closed.
2. **Examiner and transition controls.** Split, diff and transition keys are refused for 3D candidates, and stale split state is reset on session load. Transition candidates and transition previews reject 3D on either side. Pilot tests drive the real keys (`D`, `t`, `T`, `S`, `s`). A mutation check, with the guard removed, fails the pilot.
3. **Readiness labels and malformed manifests.** Browser coverage is now `CANDIDATE_VERIFIED` (a verification receipt records each session's binding hash and per-frame size and mtime; any change downgrades it), `CANDIDATE_REGISTERED`, `INVALID` (malformed or broken sources; never crashes discovery), or `MISSING`. Full per-frame hashing still runs on preview load and on `--verify`/`--apply`.
4. **Staging atomicity.** The stager renders into a sibling staging directory. Only after every selected action succeeds are outputs promoted, and any promotion failure restores the previous paths. Tests: a mid-run invalid frame leaves the live stage byte-identical, a promotion failure restores everything, and a bounded run replaces only its own actions.

## Evidence

Package folder (scratchpad): `/tmp/claude-1000/-home-braydenchaffee-Projects-CUSTODIAN/f5b5ce06-685d-44b1-8e95-846e306c5dcb/scratchpad/review/`
- `1_plan.json`, `2_apply.json`, `3_reapply.json`, `4_verify.json`: intake receipts.
- `hashes.json`: contract, master, motion, stage manifest, meta and receipt hashes, and 16 candidate hashes.
- `contact_sheet.png`, `preview_3d_walk_s.svg`, `pilot_run.log`, `stage_run.log`, `regression_results.txt`.

Restaged output hashes match the pre-correction stage for all 200 walk and 120 run frames.

## Scope limits

- Not landed. Fresh-context review not yet performed.
- `operator ui` from the art checkout not run; it requires landing and an art-checkout sync first.
- Idle (`unarmed/posture/idle_relaxed_01`) not started.
- The SVG screenshot was not visually inspected in this session; the contact sheet was.
- Session stats are used to downgrade verification. A change that keeps size and mtime would not downgrade discovery until re-verified.
