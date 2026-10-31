# Meridian Civic Wall 3D Source Intake V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `meridian-civic-wall-3d-source-intake-v1`
- Category: `assets-art`
- Authoring handoff: `auto`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `none`
- Locks: `meridian-civic-wall-source-intake`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `asset-pipeline, workflow`
- Paired review workstream: `review-meridian-civic-wall-3d-source-intake-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Preserve exact source provenance and publish a decoder-derived archival GLB without implying runtime or visual approval.`
- Reviewed main: `ec12bbe2365122042096087f7367eb346f1fd46e`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad3b05a-6b30-83e9-ae0a-97f0a88a751f`
- Visual review: `none`
- Goal: Preserve the user's Meridian Civic Wall source and a reproducible archival GLB on `origin/main`.
- Completion boundary: Verify the authorized local Meshy source, decode it with the existing decoder into the canonical source-work directory, publish a byte-identical root archival copy and versioned provenance record, and land these files on `origin/main`. Do not register, normalize, render, approve, or integrate the asset.
- Current measured state: Both expected Downloads files are locally available at 1,628,604 bytes and SHA-256 `9ca53b5bd034380e9afe46dbed3138ce17aed1628830f2d035fe8fdb62188fc2`; equality must be reverified at execution. Existing decoder entrypoints are `meshy_decode.py` and `meshy_container.py`.
- Evidence: User-authorized source names and expected decoder command; existing `meshy_decode.py`, `meshy_container.py`, and `.gitattributes` GLB LFS rule.
- Task-specific authority: Root `AGENTS.md`; `custodian/AGENTS.md`; `custodian/docs/ASSET_LAYOUT_CONVENTION.md`; `design/04_architecture/ASSET_PIPELINE_V2.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Work surface: `custodian/asset_drop/source_work/meridian_civic/meridian_wall_3d_v1/`; `MERIDIAN_CIVIC_WALL_3D_V1.glb`; `MERIDIAN_CIVIC_WALL_3D_V1.md`; existing `meshy_decode.py`, `meshy_container.py`, `.gitattributes`, `custodian/tools/validation/validation_manifest.json`, `custodian/tools/validation/run_validation.py`.
- Publication inputs: `meshy_decode.py`, `meshy_container.py`, `.gitattributes`, `custodian/docs/ASSET_LAYOUT_CONVENTION.md`, `custodian/tools/validation/validation_manifest.json`, `custodian/tools/validation/run_validation.py` (all tracked on reviewed main).
- Change: Rehash both local files and require exact equality; preserve the original `.meshy` bytes in source_work; invoke the existing decoder with `--confirm-authorized` and fail on output collision; inspect GLB magic/length and parse glTF JSON/GLB chunks; record meshes, materials, images and extensions; publish canonical and root GLBs with identical SHA-256; add a root Markdown record with source/output hashes, decoder commit, command, inventory, canonical path, unverified legacy-container authentication limitation, and explicit archival-only approval state. Use existing `*.glb` LFS rule and narrowly scoped LFS tracking for the `.meshy` source. Add a focused archival identity/GLB/LFS smoke test and its validation owner mapping so changed-file validation covers the required root GLB and `.gitattributes` update.
- Preserve: Decoder implementation and cryptographic reconstruction routine; all existing assets, source bytes, source-work content, runtime, Asset V2 records, scenes and unrelated work.
- Non-goals: No decoder rewrite, alternate reconstruction, runtime or Godot integration, asset-family registration, texture generation, 2.5D quality claim, or production approval.
- Acceptance: (1) Source SHA-256 values and byte equality are recorded and verified. (2) The original is preserved byte-for-byte. (3) The output has valid GLB magic, declared length, parseable chunks and glTF inventory. (4) Canonical and root GLBs are byte-identical. (5) Decoder revision/command and its lack of original-container cryptographic authentication are recorded. (6) All published binary paths are LFS-backed and reachable from `origin/main`. (7) Status remains archival source validation only.
- Validation: Verify both source hashes and `cmp`; run existing decoder only when output path does not exist; parse GLB header, binary length, chunk structure and glTF JSON; compare canonical/root output hashes; inspect `git lfs ls-files` and `git check-attr filter -- <binary paths>`; run `python3 custodian/tools/validation/meridian_civic_wall_source_smoke.py`, canonical changed-file validation including the manifest self-check, and `git diff --check`; independently review provenance and LFS publication.
- Task overrides: `none`
- Deferred: Any downstream rendering, source approval, Asset V2 intake, Godot use, and visual assessment.

## Handoff

- Next workstream: `review-meridian-civic-wall-3d-source-intake-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad3b05a-6b30-83e9-ae0a-97f0a88a751f`
- Next action: Independently verify source/output identity, LFS publication and archival-only status after the implementation lands.
- Blockers or open questions: None; local source availability and exact hashes must be reconfirmed before decoding.
