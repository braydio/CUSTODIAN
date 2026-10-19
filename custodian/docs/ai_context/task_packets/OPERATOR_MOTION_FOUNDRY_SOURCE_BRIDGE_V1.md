# OPERATOR MOTION FOUNDRY SOURCE BRIDGE V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-motion-foundry-source-bridge-v1`
- Kind: `implementation`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `review-operator-motion-foundry-core-v1`
- Locks: `operator-motion-foundry, operator-assets`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Paired review workstream: `review-operator-motion-foundry-source-bridge-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `explicit candidate source-work export and existing Operator Source Session ingress need independent safety review`
- Reviewed main: `9bbe905a1ffcca2afca273ccc48a7ed2f794d0c8`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Visual review: `none`
- Goal: Safely export an exact current Operator 2.5D motion candidate as untrusted source-work for existing Source Session and Workbench, without inventing a second art approval or publish route.
- Completion boundary: Read-only target-binding/preview/plan, hash-locked explicit single-source-work export with provenance receipt, collision refusal, and passing negative controls; never modify existing runtime/canonical assets.
- Current measured state: `Operator2DIngress.target_binding()` already verifies actual 2.5D target/profile/reference and `SourceArtService.authorize_source_path()` accepts files under `asset_drop/source_work`. It does not accept arbitrary `.ai` candidate paths directly; MF1 is candidate-only and no MF-specific guarded export adapter exists.
- Evidence: `design/02_features/animation/CUSTODIAN_MOTION_FOUNDRY_V1.md`; `custodian/tools/operator/operator_2_5d_ingress.py`; `custodian/tools/operator/art_agent/source_service.py`; `custodian/tools/operator/operator_generation_brief.py`; `custodian/tools/pipelines/operator_asset_schema.py`; MF1 archived implementation and accepted independent review.
- Task-specific authority: `Operator2DIngress` is semantic target/identity gate; `SourceArtService` owns normalization/review source intake; Workbench owns publication; V2 design locks own visual/root/timing decisions.
- Work surface: New `custodian/tools/operator/motion_foundry/source_bridge.py` and `custodian/tools/validation/operator_motion_foundry_source_bridge_smoke.py`; modify existing ingress/CLI only if proof requires and without copying its authority; no Art Agent MCP mutating tools.
- Publication inputs: `design/02_features/animation/CUSTODIAN_MOTION_FOUNDRY_V1.md`
- Change: Add inspect/plan for exact current selected art generation/profile/group/action/direction/layer; reuse public Operator2DIngress binding validation; verify rig/pose/candidate/output/report/SHA and selected target and reject occupied/stale canonical generation. On explicit export only, atomically write an immutable unchanged PNG plus provenance under `custodian/asset_drop/source_work/operator/motion_foundry/<job-id>/`; name using existing Operator V2 8-token grammar. Hash-compare existing target before no-op, reject any different-byte collision and source/path symlink escape. Expose the path for optional **separate** existing Source Session start and handoff; do NOT invoke normalization/publish automatically, set approval/timing flags or write Asset V2 inbox/runtime files.
- Preserve: Same MF1 deterministic rendering, saved 2.5D profile SHA, exact target binding, art-generation status, canonical PNG and sidecar hashes, Source Session authorization, existing Workbench sole publish and no independent 3D/AI renderer.
- Non-goals: No human-reviewed parts or accepted real Operator animation, no automatic replacement/Asset V2 ingest, no Workbench publish, no FPS inference, no Godot cutover, no additional source ownership registry.
- Acceptance: (A) Correct explicit 2.5D target exports a byte-identical PNG into source_work with a content-addressed receipt. (B) Repeated same candidate is idempotent; changed pixels/hash/target/path collisions fail closed. (C) Invalid/missing target, forged receipt, wrong generation/direction/reference/profile or already occupied canonical generation refuse safely. (D) Stub/mock that records all canonical, Workbench, git and runtime writes remains empty throughout bridge calls. (E) Existing SourceArtService independently accepts correctly placed source_work path in isolated tests without automatic normalize/handoff; output remains candidate/unapproved, `fps:null`.
- Validation: New `operator_motion_foundry_source_bridge_smoke.py` (planned), existing `operator_2_5d_ingress_smoke.py`, `operator_2_5d_canonical_visual_contract_smoke.py`, applicable `operator_art_agent_v2_pilot.py`, `run_validation.py --changed --json`, `git diff --check`.
- Task overrides: `none`
- Deferred: Real layered Operator pilot as a separate human-art-gated workstream, any automation of Source Session/Workbench or PixelLab-like generative pixel model.

## Next Handoff

- Next workstream: `review-operator-motion-foundry-source-bridge-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Refresh reason: `none`
- Next action: `Independently verify that explicit exports cannot reach canonical assets or fake human approvals.`
- Blockers or open questions: `none after MF1 accepted review and live lock audit`
