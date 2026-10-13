# Ash-Bell Surface Lift V2 Asset Intake

Workstream: `ash-bell-surface-lift-v2-asset-intake`

The authenticated source archive at `/CUSTODIAN/asset_batches/ash-bell-ritualant/CUSTODIAN_Ash_Bell_Surface_Lift_V2_Full_Resolution_Source_20261013.zip` matches SHA-256 `fb283369cf3546c7615d1ea51a28c6f6fd95591d36d8c1ccafd5e4c2338bcdbc` and size 7,801,299 bytes. Every PNG member matches the package manifest’s SHA-256, byte size, RGBA mode and source dimensions. The current human review chat approved `lift_deck` (448×320, 1f), `field_projector` (64×128, 1f), `field_idle` (6f, 512×192/cell, 6 FPS loop) and `field_engaged` (6f, 512×192/cell, 8 FPS loop). It approved `field_arming` as source work only; the runtime target remains 8f, 512×192/cell, 12 FPS one-shot.

The approval receipt is in `custodian/content/metadata/assets/source_review_receipts.v1.json`. Its `authoring_chat` points to the current decision chat `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c`; `original_authoring_chat` preserves the packet’s originating conversation `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20`.

Two V2 families were registered. Five immutable source PNG masters were preserved under canonical `custodian/asset_drop/source_work/ash_bell/<family>/` paths. The existing pixel-art converter produced the four eligible normalized assets under the registered family dimensions; both six-frame effects retain six distinct cells and RGBA alpha. Asset Pipeline V2 ingested and Godot-imported the two props and two field animations. Their catalog status is imported, unbound, and not runtime-verified because scene integration is explicitly out of scope. `field_arming` remains registered at the 8-frame target, has a hash-matching approved source master, and reports `source_pending`; it was not normalized or ingested. No frames were invented or changed.

Structured source/runtime hashes, dimensions, per-frame alpha counts, status, job IDs and Dropbox path drift are recorded in `custodian/docs/ai_context/asset_audits/ASH_BELL_SURFACE_LIFT_V2_INTAKE_20261013.json`. The ingest receipts are `custodian/asset_drop/logs/job_20261013T151138Z_83e73ea6.json` and `custodian/asset_drop/logs/job_20261013T151356Z_92e933f5.json`. Asset V2 `needs --check` passes. `asset.py doctor` reports the four previously documented designation-locker catalog hash mismatches; no new family errors were reported. Focused Asset V2 plan, ingest, status, requirements, source-stage, source-only pending-status and Dropbox audit tests passed. Godot import succeeded for both families.

A path-root bug in `dropbox_asset_stage.py` initially placed source files under an unintended nested directory. The staging tool root and metadata/inbox paths were corrected, the five source masters were staged at canonical locations, and only the five erroneous copies created by that first apply were removed. The same pass found Asset V2 status did not treat an approved source-work-only receipt as pending; the status projector now verifies that receipt’s member hash and reports `field_arming` as `source_pending`. Two unrelated `.uid` files created by Godot’s broad import and fixture artifacts from validation were excluded from the task.

No lift scene, traversal, timing, collision/navigation, shared platform assembly, or presentation integration was modified. The ZIP was not moved or rewritten. Dropbox lifecycle audit still reports the package as unregistered at its direct-under-folder path; reconciliation of that path/registry is deferred to bounded follow-up after this intake. Do not begin visual integration in this slice.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: Stage path-root mismatch caused an initial misplaced copy; the tool was fixed, canonical sources restaged, and only the duplicate copies created by that run were removed.
- Root cause / contributing factors: The stage tool mixed repo-root-relative archive entries with a `custodian/`-relative default project root and metadata paths.
- Prevention / pipeline improvement: Root handling was corrected and an exact-hash source-only pending-status test was added.
- Tooling / docs drift discovered: `asset_status.py` previously ignored source-work-only approved receipt states; the Dropbox package remains unregistered and directly under its parent folder.
- Follow-up: fixed-in-scope
- What worked: The explicit per-state human receipt allowed four valid runtime states to ship while keeping the six-frame arming source pending against its eight-frame target.

## Next Handoff
- Next workstream: review-ash-bell-surface-lift-v2-asset-intake
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Refresh reason: none
- Next action: Land and archive the implementation, then run its fresh-context paired review. Keep all scene wiring and traversal changes for the subsequent integration packet; obtain genuine reviewed 8-frame `field_arming` art before that state is runtime-ready. Reconcile the Dropbox path/registry in a bounded lifecycle follow-up.
- Blockers or open questions: None for this intake. Genuine 8-frame arming artwork and the deferred Dropbox registry/path reconciliation remain subsequent work.
