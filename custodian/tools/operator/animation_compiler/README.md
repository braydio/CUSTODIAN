# Operator 3D animation compiler foundation

Task 001 defines a read-only contract and planner for a future Blender skeletal pipeline. It does not import FBX files into Blender, retarget actions, render images, execute jobs, or publish assets. A generated plan is descriptive only; `candidate_unapproved` can never mean art approval.

## Architecture

```text
approved or explicitly experimental content-addressed master
  + Mixamo FBX and Blender inspection proof
  + pinned retarget and rendering contracts
    -> deterministic plan -> future retarget/motion processing
    -> independent full-body N/NE/E/SE/S/SW/W/NW renders
    -> technical QA -> review package -> existing 2.5D ingress
```

The new compiler owns source-batch identity, declared dependencies, compatibility evidence bindings, sampling estimates, staleness checks, and the future candidate receipt shape. Blender owns import/retarget/render in a later task. The existing Operator 2.5D ingress owns any future reviewed candidate intake. No body upper/lower composition or runtime selector policy is changed by this target design.

## Contracts

- `schemas/master.v1.schema.json` describes a replaceable content-addressed `.blend` master, including Blender file hash, armature identity/rest-pose/skeleton hashes, mesh/material identity hashes, texture dependency hashes, retarget config and camera/registration profile.
- `schemas/batch.v1.schema.json` describes FBX availability, filename/import metadata/hash, semantics, source action and skeleton proof, source-authored timing, loop/one-shot and character-local impact direction, root-motion policy, foot contacts, sampling and runtime timing authority.
- `schemas/runtime_timing_authority.v1.schema.json` specifies an explicit, hash-bound record associating approved runtime FPS/loop with one semantic, FBX hash, and master contract hash.
- `schemas/inspection_proof.v1.schema.json` specifies the Blender inspector evidence that a future worker must bind to the exact FBX, master contract, action, skeleton and retarget policy. The CLI refuses `synthetic_test` proof; that evidence kind exists only for unit tests.
- `schemas/plan.v1.schema.json` defines deterministic planner output.
- `schemas/candidate_receipt.v1.schema.json` specifies future output hashes, the eight independent 128×128 RGBA full-body direction streams, optional 512×512 diagnostics, source timing, separate root trajectory and candidate-only approval state. It is a contract, not a renderer implementation.
- `contracts/full_body_8dir_128_v1.json` is pinned by its actual file SHA-256 in manifests. It fixes 45° elevation, 50 px/m, root `(64,106)`, fixed master-derived scale, consistent registration, no mirroring, and candidate-only output.
- `contracts/retarget_policy_v1.json` is a versioned policy contract only. It requires compatibility proof and timing preservation but intentionally does not invent Mixamo bone mappings or execute a retarget.

All external master, FBX, proof, texture and master-retarget paths are relative to the explicitly authorized `--asset-root` (or, by default, the manifest directory). Absolute paths, traversal and symlink escapes are rejected. Rendering and batch-retarget contract paths are repository-relative and hash-checked. File hashes stream bytes in bounded blocks; no image decoding is performed for estimates.

A plan job ID is the first 24 hex characters of a SHA-256 over canonical JSON containing animation/source identity, expected master and policy identities, rendering profile and sampling. The plan ID binds canonical input-manifest bytes to the current sorted dependency states and observed hashes. Replanning identical unchanged inputs produces byte-identical JSON. A missing source or source timing leaves estimates explicitly unknown rather than inventing counts.

## CLI

Run from the repository root:

```bash
python3 -m custodian.tools.operator.animation_compiler.cli plan \
  custodian/tools/operator/animation_compiler/examples/operator_mixamo_batch_v1.json
python3 -m custodian.tools.operator.animation_compiler.cli validate \
  custodian/tools/operator/animation_compiler/examples/operator_mixamo_batch_v1.json
python3 -m custodian.tools.operator.animation_compiler.cli check \
  /path/to/saved-plan-or-candidate-receipt.json \
  custodian/tools/operator/animation_compiler/examples/operator_mixamo_batch_v1.json
```

`plan` writes JSON to stdout and makes no filesystem changes. Redirect stdout if a plan snapshot is wanted. `validate` reports missing/unavailable inputs as stable errors; the representative batch is expected to be incomplete until real authorized sources and a master are supplied. `check` re-evaluates a saved plan or candidate receipt, including declared frame and dependency hashes, and returns exit 3 when stale. Exit codes are 0 (plan created, valid report, or current plan), 2 (invalid document/dependencies), 3 (stale plan), and 4 (unexpected local I/O/processing failure). JSON keys/errors are sorted and timestamps are omitted.

Validation never equates authored FBX FPS with runtime FPS. Every item must explicitly carry either a content-addressed runtime timing authority or `status: unavailable`; unavailable authority is reported as `RUNTIME_TIMING_AUTHORITY_MISSING`. Source frame ranges are not clamped to Motion Foundry's unrelated 120-frame 2D limit. Loop endpoint treatment is declared per animation; `omit_declared_duplicate_terminal` only changes the sample estimate and never rewrites the source range or authored duration.

Root motion distinguishes source world displacement from local sprite poses. The declared `extract_to_metadata` route removes root translation from sprite poses, retains the original trajectory separately, and assigns Godot trajectory application exactly once. `in_place` retains the trajectory as provenance while emitting poses without root displacement and declaring `pose_only`. Inconsistent pose/application combinations fail closed.

## Representative batch and current availability

`examples/operator_mixamo_batch_v1.json` names the eight requested candidates. Source filenames, paths, hashes, importer settings, skeleton identities/actions/ranges, timing and master identity remain null with `availability: unavailable` because none were supplied as authorized inputs here. The example does not claim real animation validation. Its dry run still reports eight jobs, eight target directions and fixed output dimensions while setting frame/pixel workload to unknown.

## Existing-tool reuse map

| Existing interface | Safe reuse | Task 001 decision |
| --- | --- | --- |
| `operator_3d_master/scripts/rig_diag/inspect_fbx.py`, `retarget_run.py`, `render_rigged.py`, ITER003–005 diagnostics | These exact files were absent from the fetched repository and resumed implementation tree. No conclusions about their internals are asserted. | Do not copy or rewrite. The future inspector-proof schema makes source/action/skeleton/retarget bindings explicit. Locate the authorized original source before Task 002 and record which routines are generic vs `Running.fbx`/ITER005-specific. |
| `custodian/tools/art/broken_warrant_3d/render_pixel_proof.py`, `assemble_pixel_proof.py`, README | Reusable technical precedent: bounded-block SHA-256, background Blender scripting, deterministic removal of volatile PNG metadata, pixel metrics and review-only proof outputs. | Not imported as a dependency: its Broken Warrant GLB, rig, cameras and three-view proof are model-specific. |
| `custodian/tools/operator/operator_2_5d_ingress.py` | Its explicit source path/hash, semantic binding and source-work → Workbench separation inform the future handoff boundary. | Keep as downstream owner; do not call or change it in compiler planning. |
| `custodian/tools/operator/operator_2_5d_timing_authority.py` and `custodian/tools/operator/operator_2_5d_review.py` | Explicit timing evidence bound to saved inputs and human approval separate from technical QA. | No FPS inferred; runtime authority is a separate optional hash-bound record. A compiler candidate cannot satisfy the review/approval gate. |
| `custodian/tools/pipelines/operator_asset_schema.py` | Existing semantic dimensions (`profile`, `group`, `action`, direction/layer separation) inform names. | New 3D candidate manifest is not forced into the current 2.5D runtime asset key or modular-layer policy. |
| `custodian/tools/operator/motion_foundry/motion.py` | None for skeletal animation processing. Its current frame-count limit is exactly 1..120. | Left unchanged; this compiler has no 120-frame cap. |

## Task 002 proposal

See [TASK_002_NEUTRAL_IDLE_PROPOSAL.md](TASK_002_NEUTRAL_IDLE_PROPOSAL.md). It is a one-clip Blender proof plan only and requires a human-approved source/master contract before execution.
