# OPERATOR MOTION FOUNDRY CORE V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-motion-foundry-core-v1`
- Kind: `implementation`
- Status: `complete`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `operator-motion-foundry`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Paired review workstream: `review-operator-motion-foundry-core-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `new offline candidate authoring data contract, deterministic raster output and safety boundary`
- Reviewed main: `9bbe905a1ffcca2afca273ccc48a7ed2f794d0c8`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Visual review: `none`
- Goal: Produce content-hashed offline pose-to-pixel animation candidates with exact frame/root/alpha contract, without changing canonical Operator art or runtime authorities.
- Completion boundary: Pure Python rig/motion parsers, deterministic integer translation/compositing, confined candidate render/plan/check CLI, QA receipt, and synthetic 15-frame 128px proof all work with explicit negative controls.
- Current measured state: Workbench can author/render/QA existing frames and Art Agent can edit bounded pixels, but neither is a general pose-synthesis engine. The existing 96px enemy cutout rig is runtime presentation, not an offline Operator generation authority. No `motion_foundry` package exists at reviewed main.
- Evidence: `design/02_features/animation/CUSTODIAN_MOTION_FOUNDRY_V1.md`; `OPERATOR_2_5D_VISUAL_CONTRACT.md`; `OPERATOR_ART_AGENT_SYSTEM.md`; `custodian/tools/operator/art_agent/qa.py`; `custodian/tools/operator/animation_transition.py`; `custodian/tools/operator/animation_workbench_model.py`; `design/02_features/enemy_visuals/HUMANOID_CUTOUT_RIG_SYSTEM.md`.
- Task-specific authority: The Motion Foundry V1 design and existing Operator 2.5D visual/root/direction/profile contract own acceptance. Existing Workbench/Asset Pipeline V2 retain all production authorization.
- Work surface: New `custodian/tools/operator/motion_foundry/{__init__,schema,rig,motion,render,qa,cli}.py`; new `custodian/tools/validation/operator_motion_foundry_core_smoke.py`. Existing tool files read-only unless a demonstrated adapter requires a narrow change.
- Publication inputs: `design/02_features/animation/CUSTODIAN_MOTION_FOUNDRY_V1.md`
- Change: Implement the exact `custodian.motion_foundry.rig.v1`, `.motion.v1`, candidate and report contracts; guarded path/hash/semantic validation; piecewise rational integer interpolation with signed-half-away rounding; stable compositing of whole-canvas binary-alpha RGBA parts via integer offsets, no scaling/rotation/mirroring; content-addressed ignored `.ai/operator_motion_foundry/runs` output; `plan` read-only, `render` explicit, `check` reproducibility and QA. Synthesize test-only colored part images in temp directories, then render the south-facing 15f x 128x128 fixture and emit exact 1920x128 strip. Reuse existing metrics when their interface applies; hard-fail mutated root/contacts, clipping, color expansion, stale source SHA and rejected paths.
- Preserve: Accepted 2.5D design/reference/profile hashes, independent eight directions, canonical Operator PNGs/timing/sidecars, existing Workbench and Art Agent services, 96px enemy cutout rig, gameplay and resource outputs. All synthetic art remains ignored, not approved.
- Non-goals: No automatic segmentation of flattened Operator idle, no AI model, IK/rotating limbs, export to source_work, Aseprite document write, human art approval, MCP network, Asset V2 ingest, Godot runtime integration or publication.
- Acceptance: (A) Same rig/motion/input SHAs produce byte-identical 1920x128 RGBA candidate PNG and stable receipt twice. (B) Exact per-part translations, alpha, z-order, roots, foot contacts and no clipping. (C) Wrong size, forged hash, invalid direction, parent cycle, moved locked root, source path escape/symlink, duplicate part, invalid timeline, clipping and tampered repeated output fail closed. (D) Test reads no external creative service and modifies zero canonical paths. (E) Review report states `candidate` and `publication_authorized:false`; preview FPS never becomes an authored clock.
- Validation: New `operator_motion_foundry_core_smoke.py` (planned creation), relevant `operator_2_5d_canonical_visual_contract_smoke.py`, targeted `operator_art_agent_v2_pilot.py` if touched, `python3 custodian/tools/validation/run_validation.py --changed --json` and `git diff --check`.
- Task overrides: `none`
- Deferred: MF2 source-work bridge; MF3 real human-authored parts; AI, bone deformation, GPU and 3D.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `operator_motion_foundry_core_smoke.py` passed; separate temporary output roots produced identical candidate and receipt hashes; synthetic 15-frame strip is 1920x128 RGBA; source hash and symlink escapes and modified repeated output are refused; canonical Operator content and design reference hashes remained unchanged.
- Validation: `python3 custodian/tools/validation/operator_motion_foundry_core_smoke.py`; `python3 custodian/tools/validation/operator_2_5d_canonical_visual_contract_smoke.py`; `python3 custodian/tools/validation/run_validation.py --changed --json` (39/39 passed); `python3 -m compileall -q custodian/tools/operator/motion_foundry custodian/tools/validation/operator_motion_foundry_core_smoke.py`; `git diff --check`.
- Candidate status: reports and receipts say `candidate`; `publication_authorized` is false. No authored art, timing approval, runtime integration, or production publication is claimed.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: Initial changed-file validation lacked a manifest owner for the new smoke and correctly reported uncovered files; the focused test was added to the manifest and the full changed sweep then passed. One validation retry waited behind an active Godot project lock and continued after it cleared.
- Root cause / contributing factors: New validation scripts require explicit manifest ownership; host Godot import/validation activity shares a serialized project lock.
- Prevention / pipeline improvement: New implementation smokes are now registered in `validation_manifest.json` with the owned package glob. Keep the existing lock wait behavior and do not launch overlapping validation sweeps.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: Candidate outputs are content-addressed, confined, and collision refusing; the synthetic proof protects canonical source/reference hashes.

## Next Handoff

- Next workstream: `review-operator-motion-foundry-core-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Refresh reason: `none`
- Next action: `Run independent falsifying paired review; do not route candidates to runtime.`
- Blockers or open questions: `none after automatic authoring promotion, live dependency and lock audit`
