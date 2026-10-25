# Broken Warrant 3D Surface Rebuild

- Packet schema: `custodian.task_packet.v2`
- Workstream: `broken-warrant-3d-surface-rebuild`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: none
- Locks: `broken-warrant-3d-source`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-broken-warrant-3d-surface-rebuild`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `material authoring and deterministic Blender proof tooling need independent technical review; subjective art acceptance remains with the user`
- Reviewed main: `052ccc20901f953348b1b5e5f27d7dc1e5b30d0e`
- Authoring handoff: `auto`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad67690-d998-83ea-a107-ff3417ee482a`
- Visual review: `required`
- Visual review retention: `delete-after-review`
- Goal: Rebuild the existing Broken Warrant 3D character's materials from semantic surface classes, then create deterministic fixed-camera 128px pixel-art proofs without changing source geometry or promoting runtime art.
- Completion boundary: Deliver a packed editable Blender material master, reusable deterministic renderer, front/three-quarter/rear RGBA 128px proofs, one comparison sheet, and machine-readable material/mesh/registration validation. Explicit human art acceptance remains pending until the user reviews the comparison sheet.
- Current measured state: The supplied original GLB is reported as 503 meshes and 45,998 triangles. A previous source-fragment atlas pass is rejected and is included only as a negative control. The repository has no authoritative implementation for this 3D material rebuild yet.
- Evidence: Completed outputs are local at `custodian/asset_drop/source_work/actors/broken_warrant_playable_knight_3d/`; `proof/material_master_validation.json` and `proof/pixel_proof_validation.json` pass, with source census in `proof/source_surface_audit.json`. The three-angle sheet is externally staged at `/CUSTODIAN/visual_review/broken-warrant-3d-surface-rebuild/20261020T023328Z/REVIEW_MANIFEST.json`. The complete immutable handoff is tracked at `custodian/docs/ai_context/task_packets/implementation_inputs/CUSTODIAN_BROKEN_WARRANT_3D_SURFACE_REBUILD_CODEX_HANDOFF_V1.zip` (SHA-256 `14fc45c5168286605099a57e5404084e84cdba46d5233949562a9577c3cfadf7`). Its `SOURCE_MANIFEST.json`, `MATERIAL_SURFACE_PLAN.json`, source GLB/reference, surface inventory/audit, rejected controls and bounded scripts define the inputs and baseline.
- Task-specific authority: This packet and its tracked input handoff; `design/01_systems/ISOMETRIC_2_5D_PRESENTATION_CONTRACT.md`; `custodian/content/data/operator/authoring/operator_art_profile.json`; `design/04_architecture/ASSET_PIPELINE_V2.md`; and `custodian/AGENTS.md`.
- Work surface: `custodian/tools/art/broken_warrant_3d/`; ignored source-only outputs under `custodian/asset_drop/source_work/actors/broken_warrant_playable_knight_3d/`; `custodian/docs/ai_context/task_packets/` only for the scoped implementation/review lifecycle and final handoff; focused tests/reports beside the new tool.
- Change: Use the packaged installer to stage immutable source inputs. Implement deterministic opaque semantic PBR materials in Blender, classify every exact mesh intentionally, preserve the 503 source meshes, 45,998 triangles and one intended 15-bone rig, and pack all dependencies in the saved master. Build a reversible render-only detail LOD and deterministic transparent front/three-quarter/rear renderer at native 128px and 4x supersampling with explicitly controlled nearest-neighbor downsampling. Enforce root `(64,106)`, ground line `Y107`, fixed orthographic framing, source immutability, no rejected atlas/projection, complete assignments, alpha and clipping checks. Emit one three-angle comparison sheet and JSON/CSV evidence. Record documentation drift and keep human artistic acceptance pending.
- Preserve: Original GLB and reference image bytes/hashes; character identity and silhouette-defining geometry; the single 15-bone hierarchy, source mesh names/transforms and animation potential; the accepted Operator 128px registration contract; separation from NPA 96px E/W runtime art; all runtime/Asset V2 authority.
- Non-goals: No source geometry edits, new rig or animation reconstruction, FPS choice, Godot runtime wiring, 96px production art, Asset V2 promotion, full-character photo-fragment projection, or production-art approval.
- Acceptance: Source hashes are unchanged; census remains exactly 503 meshes/45,998 triangles; one valid 15-bone rig has complete rigid assignments; all meshes have intentional semantic materials and no unresolved references; no rejected atlas/fragment mapping survives; materials are opaque with no accidental holes; packed `.blend` reopens with dependencies resolved; renderer settings are deterministic and fixed; direct and supersampled outputs have correct RGBA 128×128 dimensions, registration, alpha, no clipping, and no unreported render-only hiding; exactly three transparent proof views and one concise native-plus-4x comparison sheet are emitted; machine-readable validation is green; doc drift is reported. Artistic similarity remains explicitly pending human acceptance.
- Validation: Run packaged surface census and verify source manifest; headless Blender build and reopen; focused `test_surface_contract.py`; native and 4x proof renders; pixel-level dimension/alpha/registration/clipping and silhouette/color checks; packed dependency check; `git diff --check`; targeted changed-file repository validation. Keep rendered evidence to three angles and one sheet.
- Deferred: Additional render directions, animation export, any production/runtime integration, Asset V2 intake, and all art revisions after user review.
- Task overrides: `none`

## Publication inputs

- `custodian/docs/ai_context/task_packets/implementation_inputs/CUSTODIAN_BROKEN_WARRANT_3D_SURFACE_REBUILD_CODEX_HANDOFF_V1.zip` — complete source/implementation handoff, including the install tool, exact source assets, material plan, surface census, negative controls and review brief. SHA-256 is pinned above.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `proof/material_master_validation.json` and `proof/pixel_proof_validation.json` pass; source audit and manifest hashes are unchanged; 503 meshes, 45,998 triangles and one 15-bone rig are verified; all material/rig assignments and packed reference resolve; three transparent views pass dimensions/alpha/registration/ground/frame checks; repeated native and 4× renders are byte-identical after stripping volatile Blender PNG metadata; focused tests pass. The output master and reports remain source-work only.
- Artistic acceptance: pending user review of `/CUSTODIAN/visual_review/broken-warrant-3d-surface-rebuild/20261020T023328Z/REVIEW_MANIFEST.json` (delete-after-review).
- Documentation drift: Blender imports source Z-up geometry into world -Y height frame. The source inventory includes 17 bone suffix tags; `Hand.L`, `Foot.R`, `Foot.L` map to `Forearm.L`, `LowerLeg.R`, `LowerLeg.L` for the intended 15-bone hierarchy.


The implementation is complete only when all acceptance checks and source-only artifacts are present and the machine-readable report records their hashes and results. The technical implementation may close with `human_art_acceptance: pending`; no statement may call the character's production artwork approved or complete before the user explicitly accepts it.

## Human visual review route

After objective checks pass, publish only the required three-angle comparison sheet and concise JSON summary with `custodian/tools/iteration/publish_review_artifacts.py --important --reason "User-owned Broken Warrant material-similarity decision after objective validation" --authoring-chat https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad67690-d998-83ea-a107-ff3417ee482a`. Use the canonical `/CUSTODIAN/visual_review/broken-warrant-3d-surface-rebuild/` root and default `delete-after-review` cleanup. Ask the user whether the three views preserve Broken Warrant's identity and material separation at native 128px; do not ask for a frame-by-frame or iterative critique.

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: Initial renderer setup assumed the imported GLB remained Z-up after removing importer nodes; the first pixel proof exposed a sideways character and invalid three-quarter framing. Blender also embedded timestamps and render-time metadata in PNGs, which made file hashes differ despite identical pixels.
- Root cause / contributing factors: Blender's glTF import axis conversion placed the source Z-up geometry in world -Y; mesh transforms were correctly fingerprinted but the rig/camera setup initially used the wrong frame. The source suffix inventory also has 17 bone tags despite the intended 15-bone hierarchy.
- Prevention / pipeline improvement: Builder documents and tests the measured import frame, explicitly maps all source bone coordinates, strips volatile PNG metadata after render, and validates byte-identical repeated output plus registration/bounds before preparing the one-sheet human review.
- Tooling / docs drift discovered: Handoff/legacy rig description says 15 bones but source suffix inventory includes `Hand.L`, `Foot.R`, and `Foot.L` in addition to the core 15; those three now alias to forearm/lower-leg. Blender's import axis adapter also needed to be recorded for correct camera and rig authoring. Current-state and file-index links added.
- Follow-up: User to review the three-angle comparison sheet for identity and material separation at native 128px; independent post-land technical review follows implementation archive.
- What worked: The source audit and alpha/registration/bounds reports gave a fast, objective signal and constrained visual review to one compact sheet.

## Handoff

- Next workstream: `review-broken-warrant-3d-surface-rebuild`
- Next packet state: dependency-gated until implementation is archived
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad67690-d998-83ea-a107-ff3417ee482a`
- Next action: After implementation landing, run the independent technical review against actual Blender reopen/render evidence and exact source hashes; keep subjective visual acceptance with the user.
- Blockers or open questions: none after the supplied handoff ZIP and authoring chat are published with this pair.
