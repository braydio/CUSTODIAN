# Operator 2.5D Canonical Visual Contract — Implementation Summary

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb

## Result

Preserved the exact Dropbox design master (2048x256 RGBA, SHA-256 `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`) and relaxed-idle master (1920x1024 RGBA, SHA-256 `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`) in Operator source-work. Generated eight exact 256px source cells and proved byte-pixel reconstruction of the design sheet. The animation PNG contains no authoritative FPS/timing metadata; no timing was inferred.

Used the required `pixelart --choose 1` alias path to produce one shared-scale 1024x128 rotation reference (SHA-256 `e529df0e0ceaeb941f67ed18ce93799755053b7c516a9f02a5b6929248e25fb9`). Added deterministic measurements, a compact palette summary, an eight-direction F01 calibration overlay, a turnaround, and a visual-contract report. The v3 profile registry keeps `legacy_96` hash-stable (`3197bb8880acd1ded1ea09985905cf6a5c57568f8e899284ceb48759bc1ceeb5`) and exposes `operator_2_5d_128` as provisional (profile hash `c2fa7472a8d97079da65a7635757449850e87b2d1dd0818f37237ab79d1220fd`).

Added explicit Art Agent profile selection and new semantic landmarks for projected root, shadow origin, and left/right foot contact. Aseprite guide layers now support profile-sized grids and direction-matched canonical reference ghosts; clean-render exclusion is covered by the existing Aseprite smoke.

## Gates Still Open

The 128px profile is not accepted. Human semantic root/floor approval, universal action-envelope proof, and review of any normalized-reference pixel cleanup remain required. The supplied idle is preserved in source-work but is not yet registered as a canonical production family with timing metadata. WB25-1 stays dependency-gated until this workstream and its paired review close.

The compact Dropbox review handoff is `/CUSTODIAN/visual_review/operator-2-5d-canonical-visual-contract/20261008T182220Z/REVIEW_MANIFEST.json` (default `delete-after-review`). Questions: approve/revise the candidate x=64, root y=106, ground y=107 registration across all eight directions, and identify only specific palette pixels requiring cleanup.

## Validation

- `operator_2_5d_canonical_visual_contract_smoke.py` — passed, including deterministic evidence generation, exact source hashes, profile backward-read, stable legacy hash, and explicit 128 profile selection.
- `operator_art_registration_profile_smoke.py` — passed; v1 compatibility and trusted legacy normalization-plan replay remain valid.
- `operator_art_agent_aseprite_smoke.py` — passed; visible guide layers do not leak into clean renders.
- `operator_art_agent_mcp_smoke.py` — passed after adding optional profile selection.
- `git diff --check` — passed.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: low
- What went wrong: the first registry migration caused the legacy normalization-plan replay guard to compare against the v3 file hash; updated it to accept registered profile hashes and reran the focused replay successfully. Dropbox review manifests are immutable, so the final profile-hash refresh required a fresh run ID after a same-run update was rejected.
- Root cause / contributing factors: legacy validation assumed one profile hash equaled the entire profile file hash; published review runs cannot be overwritten.
- Prevention / pipeline improvement: v3 plans validate against explicit profile hashes while v1/v2 profile file-hash compatibility remains; publish corrected evidence in a new review run.
- Tooling / docs drift discovered: the active packet omits the required `Change` field; this is recorded in its Execution Feedback for repair before archive. The supplied animation PNG has no authoritative FPS/timing metadata.
- Follow-up: operator-2-5d-canonical-visual-contract
- What worked: byte-exact source hashes and source-cell reconstruction made provenance verifiable without visual guesswork.

## Next Handoff

- Next workstream: review-operator-2-5d-canonical-visual-contract
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: semantic root/floor decision, universal action-envelope proof, and normalized-reference cleanup review are required before profile acceptance.
- Next action: review the Dropbox handoff in the authoring chat, record the exact semantic decision, then resume this implementation workstream before paired review.
- Blockers or open questions: action-envelope evidence and palette-cleanup decision; animation FPS/timing metadata is unavailable.
