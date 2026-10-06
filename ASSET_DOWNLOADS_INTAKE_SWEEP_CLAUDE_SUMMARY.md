# Asset Downloads Intake Sweep

- Workstream: `asset-downloads-intake-sweep`
- Branch: `agent/asset-downloads-intake-sweep`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9

## Result

Published Awakening Recovery Ambulatory `service_basin_b` through Asset Pipeline V2. Job `job_20261006T164434Z_7ba36e74` created runtime file `custodian/content/sprites/environment/props/awakening/awakening_ambulatory_fixtures/runtime/body/awakening_ambulatory_fixtures__body__fixture__service_basin_b__omni__1f__128.png` with SHA-256 `b8e068ced61b6a7416b8b5be6ed2da881e5d7861e48faf7e4ea46a2e7cba6924`. The family reports 6/6 required states ready, `asset doctor` is healthy, and Basin B remains BAKED_ONLY with no scene binding. The prior source was preserved in `pre_handoff_history` before replacing the canonical source; source and normalized handoff hashes matched the packet.

The receipt at `custodian/docs/ai_context/reports/assets/asset_downloads_intake_sweep.json` records 25 CUSTODIAN-relevant items discovered among 68 immediate Downloads entries and aggregates 35 other entries without naming them. It classifies existing K3D/Kenney packs, active Awakening/Vaultwing/Knight/ProcGen owners, two East-direction reference sets needing design ownership, the superseded Basin B bundle, and byte-identical duplicate archives. No unrelated download was copied or removed.

The active Kenney Pattern Lines packet owns the four-variant archive. The archive contains 30 files per variant, but names are `pattern_0000.png` through `pattern_0029.png`; its packet requires `pattern_000.png` through `pattern_029.png` and explicitly prohibits inventing a mapping. No files were copied. The owning packet remains ready for a bounded correction/retry.

Updated the generated requirements projection from its authoritative registry so it reports Ambulatory 6/6. Added the Awakening fixture runtime path to the `asset_pipeline_v2` validation owner set after the first changed-file run exposed that coverage gap.

## Validation

- Asset V2 plan, dry run, ingest, status, and doctor: passed; family `6/6`, doctor healthy.
- `python3 custodian/tools/validation/asset_pipeline_v2_smoke.py`: passed.
- `python3 custodian/tools/assets/asset.py needs --check`: passed.
- `python3 custodian/tools/validation/run_validation.py --changed --json`: passed, 6 selected tests, 6 passed, no uncovered files.
- `git diff --check`: passed before closeout.

The first changed-file run exited 6 because the newly published runtime PNG was not covered by a validation owner. The focused smoke and requirements tests passed. The validation-manifest owner pattern was added for this exact Awakening fixture runtime directory, after which changed-file validation passed.

During initial setup, one copy command omitted its explicit worktree and briefly modified the persistent root source/inbox. I restored the root source, removed only files created by that command, copied the verified data/history into the claimed worktree, and confirmed the root checkout was clean. No root ingest occurred.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: Initial validation coverage lacked the new family runtime path; one setup command omitted its worktree.
- Root cause / contributing factors: Coverage manifest had no owner pattern for this generated runtime directory; command was run without an explicit workdir.
- Prevention / pipeline improvement: Added a family-scoped asset pipeline coverage pattern and verified root restoration before continuing.
- Tooling / docs drift discovered: Kenney Pattern Lines delivered filenames violate its active packet's canonical name contract.
- Follow-up: kenney-pattern-lines-source-library
- What worked: Asset V2 and `needs --write` kept runtime, catalog, history, and requirements projections in agreement.

## Next Handoff
- Next workstream: awakening-room-connectors-polish
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9
- Refresh reason: none
- Next action: Return to the active Awakening presentation sequence after the connector transition regression work releases its lock.
- Blockers or open questions: `awakening-room-connectors-polish` is lock-blocked by `awakening-04-05-connector-transition-regression`; Kenney Pattern Lines needs its owner to correct or clarify the filename mapping contract.
