# Procgen Alpine Cliff Presentation V1 — Validation Contract Correction

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391

## Latest continuation — SOUTH final-world seam and review handoff

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391

The existing AP2 worktree was synced by merging `origin/main@5b3d1806692c941bf0d300763a33f868d3101dcc`; the merge completed without conflicts. The SOUTH contact PNG and authored socket were retained. `ProcgenAlpineCliffContactComposer` now attaches the sprite before resolving its authored socket with `Sprite2D.to_global()`, applies the resulting world-space translation, and records both target and resolved socket positions. The focused Alpine smoke now creates a translated, rotated, nonuniformly scaled parent and verifies the SOUTH socket against its final world-space frontier. Runtime also flood-fills the socket-connected alpha component in final sprite space and requires at least 8 world pixels of connected geology on both terrace and cliff sides before the contact can emit fascia suppression. A negative control shifts the intact contact 1,024 px outward and confirms rejection. The smoke is registered in `validation_manifest.json` as the owner for the composer and focused contract.

- Focused `procgen_alpine_cliff_presentation_smoke.gd`: PASS.
- Latest changed-file validation: coverage complete; 3 passed, 1 failed, 0 skipped. The focused Alpine, Reciprocal Continuity docs, and Macro Presentation tests passed. `procgen_meridian_hardstand_macro` fails its existing exact `report.valid.size() == 36` assertion on current merged content. It is outside the SOUTH/AP2 code surface and was selected through broad presentation ownership. Do not close AP2 while this required validation result remains unresolved.
- An initial changed-file run also exposed `/tmp/.git`, an empty directory that makes the standalone-project LFS fixture misclassify temporary directories. The final run used `TMPDIR=/dev/shm`; it passed that fixture.
- The human review of `20261014T195049Z` recorded terrace/fascia `FAIL`, attached geology `FAIL`, playable edge `PASS`, with the blocker isolated to SOUTH. Its delete-after-review cleanup completed. Fresh run `20261014T-south-frontier-35ad6afe` passed with four attached contacts, 0 px maximum socket error, and the focused connected-alpha regression. Local manifest and fetched Dropbox manifest both record `35ad6afe6d92ad0e6b9c442139d1f092de0d01fc`; local source manifest has `dirty=false`. Uploaded manifest: `/CUSTODIAN/visual_review/procgen-alpine-cliff-presentation-v1/20261014T-south-frontier-final-35ad6afe/REVIEW_MANIFEST.json`. New human review is pending.

## Outcome

AP2 remains open. Human review of the valid `20261014T195049Z` bundle recorded terrace/fascia `FAIL`, attached geology `FAIL`, playable-edge readability `PASS`; SOUTH was the sole failing direction. That reviewed bundle was deleted under its recorded delete-after-review policy. The latest SOUTH correction is committed and pushed; a fresh clean-SHA evidence run is published for human review. AP3 remains dependency-gated.

The source masters and ten contact PNG payloads were preserved. The correction resolves the socket through the final `Sprite2D` transform and validates that the socket-connected alpha component crosses the final world frontier, with at least 8 world pixels on each side, before the contact can emit fascia suppression. The focused smoke includes a transformed-parent SOUTH case and a 1,024 px outward-displacement negative control.

## Evidence

- `verify_alpine_cliff_presentation_assets.py --record`: PASS, all 26 AP2 states verified; receipt `850f3261b800bdb255c71aa61553e13bc1b9313a7d6b27ac193e484f0cc268ef`. The three AP2 Asset V2 family statuses remain complete: fascia 12/12, contact 10/10, depth chunks 11/11 registered optional states. Contact inbox files remain waiting for ingest because their payload hashes match the current runtime PNGs.
- Focused `procgen_alpine_cliff_presentation_smoke.gd`: PASS, including a negative control restoring the old east silhouette-edge socket; it fails closed and emits no fascia mask.
- Generic cliff smoke: PASS (`1001` cells, five representative seeds). Wall integration: PASS (eight seeds; `3531` fascia cells, `3601` wall cells, `1163` wall lips). Region Frame smoke: PASS. Macro Presentation smoke: PASS (`d2d2e420…`). Elevated-world asset contract: PASS (`37` sources, `944` face cells).
- Moment Forge `procgen/alpine_plateau_edge_review`, evidence run `20261014T164000Z-socket-embed-contract`: PASS, no run/probe/capture failures. North/east/south/west each have four successfully attached cardinal contacts; maximum socket error is `0 px`; minimum measured opaque support and configured minimum are both `24 px`; core/shoulder suppression remains `279` cells and `16` shoulder cells. Scenario assertions explicitly guard these attachment values. Review manifest: `/CUSTODIAN/visual_review/procgen-alpine-cliff-presentation-v1/20261014T164000Z-socket-embed-contract/REVIEW_MANIFEST.json`.
- The first attempt to add the new Moment Forge probe failed because its threshold variable was scoped inside the placement loop. The retained `20261014T163000Z-socket-embed-contract` run is diagnostic-only; the scope error was fixed, the focused smoke passed, and the successful `164000Z` run supersedes it.
- Accepted-world parity smoke: PASS on AP2 at semantic hash `562871128`, runtime fingerprint `2896026968`, and 69 keys. The same smoke in baseline mode passed on clean `origin/main@8decfc1`, producing `562871128 / 2896026968 / 69`. `macro_presentation` remains exported and is structurally checked for schema `custodian.procgen_macro_presentation.v1` and `fingerprint`, while excluded from the semantic value hash.
- `procgen_performance_baseline_quick` now has a registered 300 s timeout and passed changed-file validation in `152386 ms`. Prior direct AP2/main comparison also passed `determinism_ok=true` with matching generation fingerprint `1773840677`, contract fingerprint `1223064559`, and streaming counts (`19` revealed, `1466` queue peak, `389` nodes); generation was about `2.8/2.8 s`, contract loop `55.9/54.2 s`, promotion/materialization `82.0/78.8 s`, and sampled average frame time `6.894/6.887 ms`.
- Changed-file validation selected 69 tests: 38 passed, 0 failed, 1 timed out (`procgen_region_frame` at 120 s), and 30 were skipped after the actor-tier timeout. The timed-out test passed alone in `112431 ms`; other Godot/reviewer work was competing during the batch. Focused Alpine and Macro Presentation smokes passed after the changes. Asset Doctor’s four Awakening Designation Locker mismatches are unrelated and were not included in AP2 scope.
- The Procgen Runtime Optimization Roadmap planning-chat link now points to the current AP2 authoring chat.

## Checkpoint identity and current visual handoff

Latest main `1326220d8172cee9322363b7a5c020acaf41f64c` was merged cleanly. The AP2 branch checkpoint used for capture is `35ad6afe6d92ad0e6b9c442139d1f092de0d01fc`. Moment Forge run `20261014T-south-frontier-35ad6afe` used scenario `procgen/alpine_plateau_edge_review` in evidence mode, passed, and its local manifest records `35ad6afe6d92ad0e6b9c442139d1f092de0d01fc` with `dirty=false`. The uploaded review manifest was fetched from Dropbox; its `git.commit` also equals `35ad6afe6d92ad0e6b9c442139d1f092de0d01fc`.

- Uploaded manifest: `/CUSTODIAN/visual_review/procgen-alpine-cliff-presentation-v1/20261014T-south-frontier-final-35ad6afe/REVIEW_MANIFEST.json`
- Retention: `delete-after-review`; after recording the human decision, run `python3 custodian/tools/iteration/publish_review_artifacts.py --reviewed-manifest /CUSTODIAN/visual_review/procgen-alpine-cliff-presentation-v1/20261014T-south-frontier-final-35ad6afe/REVIEW_MANIFEST.json --reviewed-by chatgpt-user`.
- Questions: (1) Does SOUTH visibly join the playable terrace and fascia without a backdrop/fog gap? (2) Does SOUTH read as attached geology without a crop wall or detached mass? (3) Are north/east/west acceptable and is the playable floor edge clear and truthful?
- The earlier `20261014T195049Z` bundle was deleted after its disposition was recorded. Do not use it for the current gate.
- Current changed-file validation has complete coverage, 3 passed, 1 failed, 0 skipped. The unrelated `procgen_meridian_hardstand_macro` exact catalog-size assertion remains the technical blocker; AP2 closeout and AP3 eligibility remain gated.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: the original attachment smoke treated an opaque boundary point with zero positional error as proof of physical attachment; the first probe-enhancement run exposed a GDScript scope mistake. Fresh detached worktrees also require a full Godot import before Moment Forge can parse global classes, and the runner marks its own in-repository reports as dirty unless that generated output is excluded from the status snapshot.
- Root cause / contributing factors: the contract did not measure solid alpha support inward from the socket; the probe variable was declared inside a narrower block than its summary use. The Moment Forge runner writes its report before collecting repository status and requires output below `reports/moment_forge`, so capturing a clean provenance SHA requires an imported checkout and a scoped Git status override for that generated report directory.
- Prevention / pipeline improvement: require at least 24 opaque pixels of inward support in both preparation and runtime; keep the negative control that restores a boundary-touch socket; import fresh worktrees before evidence capture; run the evidence command with a one-command `status.showUntrackedFiles=no` override so the generated report does not invalidate its own clean-checkout provenance.
- Tooling / docs drift discovered: the quick performance profile needed a 300 s registered timeout and passed in 152386 ms. The changed-file batch also timed out Region Frame at 120 s while other Godot work was active; its isolated run passed in 112431 ms. The Moment Forge output-root guard rejects external paths even with `--allow-external-output`; the successful capture used the required in-repo report directory with a one-command untracked-status override.
- Follow-up: fixed-in-scope
- What worked: comparing current AP2 and clean-main outputs with `PARITY_KEYS=1` isolated the golden mismatch to `macro_presentation`.

## Next Handoff

- Next workstream: procgen-alpine-cliff-presentation-v1
- Next packet state: human-required
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391
- Refresh reason: none
- Next action: review `/CUSTODIAN/visual_review/procgen-alpine-cliff-presentation-v1/20261014T195049Z/REVIEW_MANIFEST.json` and answer the three contact-integration questions.
- Blockers or open questions: human visual disposition is pending. Latest changed-file validation has complete coverage with 3 passes and 1 failure: `procgen_meridian_hardstand_macro` fails its unrelated exact catalog count assertion (`report.valid.size() == 36`). Keep AP2 open and do not claim AP3 until the validation issue is resolved and visual review passes.

## Human visual disposition — 20261014T195049Z

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391

The fresh clean-SHA bundle is valid evidence but does not close AP2. Human/ChatGPT review recorded `FAIL / FAIL / PASS`: terrace/fascia attachment failed, attached-geology silhouette failed, and playable-floor edge truthfulness passed. The blocker is south only; north/east/west are acceptable for this gate.

The remaining correction is narrower than the earlier socket problem. The source socket can satisfy 24 px opaque support while final transformed/suppressed composition still leaves a visible world-space gap. Preserve that source-space check and add a post-placement connected-alpha frontier-crossing assertion. Prefer south placement/socket/suppression correction over new art. AP3 remains blocked.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391

## Human review — SOUTH recapture evidence mismatch

The `20261014T-south-frontier-final-35ad6afe` manifest is provenance-clean at `35ad6afe6d92ad0e6b9c442139d1f092de0d01fc`, but its visual artifacts are byte-for-byte identical to the prior failed human-review media. The contact sheet SHA remains `4045a23440949a81e72170155ab3b203267725ee0c8b2c9bb46b4316115c82ba`, with the same retained keyframe hashes. Therefore this recapture does not demonstrate a visual change. The human disposition remains `FAIL / FAIL / PASS`: SOUTH visible join fail, SOUTH attached-geology fail, north/east/west and playable-edge truthfulness pass.

The focused final-world seam regression is still useful and should be retained. Next work is to determine why the Moment Forge fixture/capture does not reflect the corrected path, rather than redesigning the art again.

The changed-file `procgen_meridian_hardstand_macro` failure is AP2-adjacent, not unrelated: AP2 adds four depth-chunk profiles to the shared terrain-stamp catalog (36 -> 40), while that Meridian-specific smoke hard-codes the global catalog size as 36. Its meaningful assertions are no rejected profiles and exactly 10 Meridian profiles. Remove or replace the stale global total coupling, rerun changed validation, then recapture after the visual path is demonstrably different.

## Continuation — capture-path diagnosis and Meridian catalog contract

The latest `origin/agent/procgen-alpine-cliff-presentation-v1` handoff commit `63d1b3a8e528604fb00b2cad955f043df08a0342` was fast-forwarded into this worktree. The repeated visual hashes were not caused by report-file reuse: they match the deterministic renderer’s north (`tick 10`) and west (`tick 125`) viewport frames. The old scenario sampled SOUTH at tick 85 only; the human-referenced keyframes did not show SOUTH. Its SOUTH contact screen bounds extended below the viewport, so displacing it farther did not alter full-frame pixels.

The Moment Forge scenario now includes a tick-75 SOUTH keyframe, explicit viewport and contact-alpha hashes, and a displacement negative control. The fixture moves the SOUTH contact out of view and records attachment ownership dropping from 4 to 3; the action driver awaits async fixture commands and propagates returned `{ok:false}` values. A successful local diagnostic capture at `south-diagnostic-63d1b3a8-r2` produced SOUTH tick hash `4061704a578aa5b92b0948f2ce2af71f1966f8c57af72b76c05952b033998eaa`; the negative control confirms displacement. Later diagnostic attempts exposed a stale assertion configuration and one incomplete run; no new review bundle was published.

The Meridian smoke no longer asserts a global catalog size of 36. It retains rejection-free catalog validation and its exact Meridian family count of 10. The AP2 catalog extension can therefore add presentation profiles without breaking a family-specific contract.

- Focused Alpine smoke: PASS.
- Focused Meridian smoke: PASS.
- Final changed-file validation: PASS, complete coverage, 38/38 tests, 0 failed, 0 skipped, 0 timed out.
- `git diff --check`: PASS.
- No final visual review bundle was published; the capture-path changes need a clean committed-SHA evidence run. AP2 remains open; AP3 remains gated.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391
