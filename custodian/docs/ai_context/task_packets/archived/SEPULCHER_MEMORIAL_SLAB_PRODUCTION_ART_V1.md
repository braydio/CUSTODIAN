# SEPULCHER MEMORIAL SLAB PRODUCTION ART V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `sepulcher-memorial-slab-production-art-v1`
- Category: `assets-art`
- Kind: `implementation`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `asset-pipeline, sepulcher-grave-art`
- Review: `none`
- Review rationale: `Bounded, reversible registration of one new approved prop state and replacement of only decorative draw calls. Hash-pinned source evidence, Asset V2 integrity checks, real Hub scene binding, and three focused Godot smokes directly establish correctness; no persistence, collision or authority cutover.`
- Reviewed main: `761ea68008e32305691d15ffd5de546289c6a6b0`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae9a2f9-cf10-83e8-bffe-5f16e079abac
- Visual review: `conditional`
- Goal: Install the user's accepted refined Sepulcher memorial slab as a real Asset Pipeline V2 sprite in production Hub gameplay in place of only the grave's existing procedural slab illustration.
- Completion boundary: Verify the exact approved Dropbox source and human acceptance, preserve immutable original bytes and SHA-256 receipt, normalize/register/ingest one `memorial_slab` state, bind the live SepulcherGraveEvidence consumer, and prove actual HubRuntimeHost rendering with no gameplay/persistence changes; land through the normal workstream lifecycle after focused validation; no paired review required.
- Current measured state: The approved source is now pinned to SHA-256 `349d642e74f246fc277993c5bfd46889795e3f771d7846e98daba9b031b2d028`, normalized to 160x96 RGBA with preserved alpha under a replayable V2 plan, ingested as job `job_20261107T070300Z_3d825703`, and bound by the existing grave controller. Asset V2 reports 1/1 required, imported, bound, and runtime-verified. The human-approved source, registration state and hashes are reconciled in the art manifest. The three existing reading positions and all interaction/persistence logic remain unchanged.
- Evidence: User explicitly accepted the refined Memorial Slab and supplied the November 2 source-approval conversation at https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae9a2f9-cf10-83e8-bffe-5f16e079abac; Dropbox exact file `/CUSTODIAN/implementation_inputs/custodian_sepulcher_memorial_slab_refined_v2_source_20261102.png`, ID `id:8NXqdXuW6GUAAAAAAAAGsw`, revision `65f4aa8f42035915cdd61`, size 2252263 bytes, Dropbox content hash `fa15ca085092805147abfdd73bdfef0053d4f7344c84ac9bea7cd73e0052ad39` (NOT a SHA-256 digest). Existing controller and focused smoke scripts on main inspected. The exact source revision, bytes, SHA-256, dimensions, RGBA alpha, normalized output and runtime rendering were verified during implementation; evidence and details are in the closing summary.
- Task-specific authority: `design/04_architecture/HUB_SEPULCHER_AWAKENING_ART_V1_MANIFEST.md` CAL-03 and active JSON entry; `design/04_architecture/ASSET_PIPELINE_V2.md`; `design/04_architecture/DROPBOX_ASSET_LIFECYCLE_RECONCILIATION_V1.md`; live Asset V2 schema and `source_review_receipts.v1.json`; `SepulcherGraveEvidence` owns grave presentation and interactions, existing Hub/geometry owns movement and collision.
- Work surface: `custodian/game/world/hub/events/sepulcher_grave/sepulcher_grave_evidence.gd`; proposed `custodian/content/metadata/assets/families/hub_sepulcher_grave_evidence_art.asset.json`; `custodian/content/metadata/assets/source_review_receipts.v1.json`; `custodian/asset_drop/source_work/hub/first_set/hub_sepulcher_grave_evidence_art/memorial_slab_source.png`; `custodian/asset_drop/inbox/hub_sepulcher_grave_evidence_art/memorial_slab.png`; required-assets registry only as necessary; focused Hub tests.
- Publication inputs: `design/04_architecture/HUB_SEPULCHER_AWAKENING_ART_V1_MANIFEST.md`; `design/04_architecture/HUB_SEPULCHER_AWAKENING_ART_V1_MANIFEST.json`; `design/04_architecture/ASSET_PIPELINE_V2.md`; `design/04_architecture/DROPBOX_ASSET_LIFECYCLE_RECONCILIATION_V1.md`; `custodian/game/world/hub/events/sepulcher_grave/sepulcher_grave_evidence.gd`; `custodian/content/metadata/assets/source_review_receipts.v1.json`; `custodian/tools/assets/asset.py`; `custodian/tools/art/custodian_pixelart_converter.py`; `custodian/tools/validation/hub_sepulcher_grave_evidence_smoke.gd`; `custodian/tools/validation/hub_sepulcher_grave_resolution_smoke.gd`; `custodian/tools/validation/hub_first_set_blockout_smoke.gd`
- Change:
  1. Fetch fresh `origin/main`, run read-only dispatcher/claim/lock audit, and dedupe the exact grave art owner before claiming. Do not displace an existing writer or review claim.
  2. Retrieve exactly the specified Dropbox PNG through the established remote/transport; verify revision, size, Dropbox content hash, byte-level SHA-256, actual dimensions and real alpha. Compare the user's accepted visual identity and approval link to this exact file. Record a human-approved, SHA-256-pinned source review decision in the existing repository authority using valid schema; do not invent a ZIP or sign a review on behalf of a different source.
  3. Keep original source bytes at `custodian/asset_drop/source_work/hub/first_set/hub_sepulcher_grave_evidence_art/memorial_slab_source.png`. Create one `world_prop` V2 state: family `hub_sepulcher_grave_evidence_art`, state `memorial_slab`, `omni`, `copy`, one 160x96 true-RGBA frame; normalize with the repository converter, preserving aspect/silhouette and transparent background. Check actual live family schema before authoring it.
  4. Use `asset.py plan/ingest/status/doctor/needs --check` per current CLI; do not manually copy images into final runtime and do not claim import equals binding.
  5. Replace only the static rectangular memorial slab strokes inside `SepulcherGraveEvidence::_draw` with the runtime V2 texture at the existing world anchor. Keep the three inspection point drawings, resolution points, gated returning growth, dialogue and all interaction logic untouched. Verify texture dimensions/pivot, correct z-order and no new occlusion of accessible readings.
  6. Prove the sprite is actually visible in production `HubRuntimeHost`/`HubFirstSetMap`, not only an isolated preview. Prefer resource, geometry and render-state assertions before one compact native-scale crop; publish a Dropbox visual review handoff only if a material subjective placement question remains and link https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae9a2f9-cf10-83e8-bffe-5f16e079abac.
  7. Run focused Godot smoke scripts, asset-family/alpha checks, changed-file validation and `git diff --check`. Publish accurate Asset V2 per-state stage, evidence and documentation drift correction; land through the normal workstream finish lifecycle without a paired review.
- Preserve: World anchor `(-1984,-3200)`, three separate evidence readings and unchanged `CYCLE 184 · NINTH WATCH` text, physical inspection positions/range, choice IDs, HubState persistence/snapshot restoration, later-return growth gating, Hub routes/connectors, Operator clearances and navigation/collision authorities.
- Non-goals: Do not generate/revise memorial art, alter CAL-01 paving or CAL-02 geometry, install blackwater, change grave lore/quest outcomes, create new interactive access, author collision from decorative pixels, or claim the other artwork approved/installed.
- Acceptance: Exact Dropbox image/approval provenance is recorded and hash-pinned; valid normalized one-frame 160x96 RGBA Asset V2 state is ingested and bound; real Hub-runtime grave displays the approved slab exactly once; no duplicate procedural slab; all original interaction, route, persistence and growth smokes pass; objective alpha/pivot/z-order and native-scale rendering evidence exists; required source receipt and runtime status are accurate; focused tests and runtime evidence pass and the implementation lands on main; no paired review is required.
- Validation: `python3 custodian/tools/assets/asset.py plan hub_sepulcher_grave_evidence_art`; `python3 custodian/tools/assets/asset.py status hub_sepulcher_grave_evidence_art`; `python3 custodian/tools/assets/asset.py doctor`; `python3 custodian/tools/assets/asset.py needs --check`; `godot --headless --path custodian --script res://tools/validation/hub_sepulcher_grave_evidence_smoke.gd`; `godot --headless --path custodian --script res://tools/validation/hub_sepulcher_grave_resolution_smoke.gd`; `godot --headless --path custodian --script res://tools/validation/hub_first_set_blockout_smoke.gd`; `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`; `git diff --check`; native Hub presentation evidence at the grave ROI.
- Task overrides: `none`
- Deferred: CAL-01 floor, blackwater and all other art intake remain outside this one-at-a-time slice. A Dropbox PNG is not itself a review receipt or runtime resource.

## Next Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae9a2f9-cf10-83e8-bffe-5f16e079abac
- Next action: This implementation is complete and landed; do not begin another art asset in this workstream.
- Blockers or open questions: none for this installation. Global Asset V2 doctor still reports four unrelated Awakening Designation Locker catalog hash mismatches; see the closing summary.


## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: See `SEPULCHER_MEMORIAL_SLAB_PRODUCTION_ART_V1_CLAUDE_SUMMARY.md` for exact Dropbox identity and SHA-pinned human approval, Asset V2 normalization/ingest/resource path, production consumer binding, focused tests, runtime image evidence, landed commit and remaining unrelated doctor findings. The implementation was validated from the workstream commit against the current main baseline and has no paired-review requirement.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: `The first full-project Godot import crashed during unrelated font reimport; the first concurrent smoke pass also produced route-test failures. A serial import and serial rerun completed cleanly.`
- Root cause / contributing factors: `The fresh ephemeral checkout had no Godot import cache, and three Godot processes initially contended during import and scene loading.`
- Prevention / pipeline improvement: `Initialize a fresh Godot project cache once before running scene-dependent smokes, then run Godot checks serially. Use the replayable sprite-import plan for soft-alpha art rather than the legacy binary-alpha converter.`
- Tooling / docs drift discovered: `The manifest marked this approved slab pending/proposed even though the user had explicitly approved it. The manifest entry and Markdown mirror now carry exact source/normalized hashes, Dropbox identity, ingest job and runtime-verified status. Asset doctor also reports four unrelated Awakening Designation Locker catalog hash mismatches.`
- Follow-up: `Finish-first execution-rules hardening, as separately authorized after this workstream closes.`
- What worked: `The existing V2 sprite-import plan preserved RGBA and aspect ratio, Asset V2 produced the canonical runtime resource, and the actual active HubRuntimeHost render plus focused tests verified the installation.`
