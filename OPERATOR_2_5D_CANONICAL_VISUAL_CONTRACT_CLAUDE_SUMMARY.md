# Operator 2.5D Canonical Visual Contract — Implementation Summary

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb

## Result

Preserved the exact Dropbox design master (2048x256 RGBA, SHA-256 `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`) and relaxed-idle master (1920x1024 RGBA, SHA-256 `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`) in Operator source-work. Generated eight exact 256px source cells and proved byte-pixel reconstruction of the design sheet. The animation PNG contains no authoritative FPS/timing metadata; no timing was inferred.

Used the required `pixelart --choose 1` alias path to produce one shared-scale 1024x128 rotation reference (SHA-256 `e529df0e0ceaeb941f67ed18ce93799755053b7c516a9f02a5b6929248e25fb9`). Added deterministic measurements, a compact palette summary, an eight-direction F01 calibration overlay, a turnaround, and a visual-contract report. The v3 profile registry keeps `legacy_96` hash-stable (`3197bb8880acd1ded1ea09985905cf6a5c57568f8e899284ceb48759bc1ceeb5`) and exposes `operator_2_5d_128` as provisional (profile hash `c2fa7472a8d97079da65a7635757449850e87b2d1dd0818f37237ab79d1220fd`).

New Workbench animation-creation plans now default to the active 128px profile. Added explicit Art Agent profile selection and new semantic landmarks for projected root, shadow origin, and left/right foot contact. Aseprite guide layers now support profile-sized grids and direction-matched canonical reference ghosts; clean-render exclusion is covered by the existing Aseprite smoke.

## Gates Still Open

The 128px profile is not accepted. Human semantic root/floor approval, universal action-envelope proof, and review of any normalized-reference pixel cleanup remain required. The supplied idle is preserved in source-work but is not yet registered as a canonical production family with timing metadata. WB25-1 stays dependency-gated until this workstream and its paired review close.

The initial Dropbox review handoff at `/CUSTODIAN/visual_review/operator-2-5d-canonical-visual-contract/20261008T182511Z/REVIEW_MANIFEST.json` is superseded by a fresh action-envelope handoff to be published from this evidence update (default `delete-after-review`). Questions now include whether the pre-migration east `fast_02` frame 4 is a valid maximum-body proxy and whether the 128px canvas or pose-root policy needs revision, while preserving the locked projection and design.

## Action-envelope proxy update

Added a deterministic scan of 446 category-assigned observations from existing pre-migration full-body sheets; action categories can overlap. The scan translates legacy anchor `[48,84]` to provisional root `[64,106]` by +16,+22 without alpha normalization. It finds 46/180 fast-chain and 16/47 one-handed-reach frames outside the 128px canvas; 71 and 24 respectively also exceed the deliberate 8px safety margin. The largest fast-chain proxy is east `fast_02` frame 4: source alpha bbox `[35,11,136,85]`, translated candidate bbox `[51,33,152,107]`. This is proxy evidence, not a canonical 2.5D failure verdict. Ranged modular aim, wide block-hit, and complete locked-projection coverage remain unproven. The profile stays provisional pending human review.

## Validation

- `operator_2_5d_canonical_visual_contract_smoke.py` — passed, including deterministic evidence generation, exact source hashes, profile backward-read, stable legacy hash, explicit 128 profile selection, and proxy-overflow assertions.
- `operator_animation_workbench_smoke.py` — passed, including new full-body/modular creation and existing 96px migration contracts.
- `operator_art_registration_profile_smoke.py` — passed; v1 compatibility and trusted legacy normalization-plan replay remain valid.
- `operator_art_agent_aseprite_smoke.py` — passed; visible guide layers do not leak into clean renders.
- `operator_art_agent_mcp_smoke.py` — passed after adding optional profile selection.
- `git diff --check` — passed.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: the first registry migration caused the legacy normalization-plan replay guard to compare against the v3 file hash; later, the neutral idle's inability to prove universal action fit required a proxy scan, which found fast-chain and long-reach overflow candidates after the first visual handoffs. Dropbox review manifests are immutable, so each evidence change needs a new run ID.
- Root cause / contributing factors: legacy validation assumed one profile hash equaled the entire profile file hash; the neutral idle does not exercise extreme actions; published review runs cannot be overwritten.
- Prevention / pipeline improvement: v3 plans validate against explicit profile hashes while v1/v2 profile file-hash compatibility remains; scan representative action classes before treating neutral animation as canvas proof; publish changed evidence under a fresh run ID and identify the latest handoff.
- Tooling / docs drift discovered: the active packet omits the required `Change` field; this is recorded in its Execution Feedback for repair before archive. The supplied animation PNG has no authoritative FPS/timing metadata.
- Follow-up: operator-2-5d-canonical-visual-contract
- What worked: byte-exact source hashes, source-cell reconstruction, and deterministic proxy extents made provenance and overflow candidates verifiable without visual guesswork.

## Next Handoff

- Next workstream: review-operator-2-5d-canonical-visual-contract
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: semantic root/floor decision, action-envelope proxy validity/canvas decision, and normalized-reference cleanup review are required before profile acceptance.
- Next action: review the latest Dropbox handoff in the authoring chat, record exact root/floor and action-envelope decisions, then resume this implementation workstream before paired review.
- Blockers or open questions: human review of registration, fast02 proxy/canvas implication, and palette cleanup; ranged aim/block-hit/all-direction envelope proof and animation FPS/timing metadata remain unavailable.
