# Operator 2.5D Canonical Visual Contract — Implementation Summary

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb

## Result

Preserved both exact Dropbox masters in Operator source-work: the 2048x256 design lock (SHA-256 `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`) and the 1920x1024 relaxed-idle source (SHA-256 `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`). The generated design cells reconstruct the source pixels exactly. The normalized 1024x128 reference uses the required `pixelart --choose 1` path and is accepted unchanged (SHA-256 `e529df0e0ceaeb941f67ed18ce93799755053b7c516a9f02a5b6929248e25fb9`); no cleanup pixels were applied or authorized.

The v3 profile keeps the `legacy_96` hash stable (`3197bb8880acd1ded1ea09985905cf6a5c57568f8e899284ceb48759bc1ceeb5`) and now accepts `operator_2_5d_128` as the canonical body/reference registration profile (SHA-256 `05e92192af68b2f4e7516f59a0938e536926f3525a31b42dd7695f61d77ca761`). Registration is fixed across all eight directions: center x=64, projected root `[64,106]`, shadow origin/ground `[64,107]`. It does not change runtime selectors.

The first animation source manifest now identifies the accepted specialized Operator family `unarmed/posture/idle_relaxed_01/full_body`, 8 directions x 15 frames, and links its profile/reference hashes. FPS/timing remains `null` / unknown and is explicitly non-blocking; it is not inferred from pixels.

## Action-envelope evidence and scope

The deterministic pre-migration proxy scan records 446 category-assigned frame observations (categories may overlap). Mapping legacy anchor `[48,84]` to accepted root `[64,106]` without alpha normalization found 46/180 fast-chain frames and 16/47 one-handed-reach frames outside the 128px canvas. The largest is legacy east `fast_02` frame 4: source alpha bbox `[35,11,136,85]`, translated bbox `[51,33,152,107]`. Human review decided this is not a valid maximum-body proxy and does not redefine the 128px profile, root, or scale. Universal action-envelope fit is explicitly **not asserted**; future extreme poses receive per-action validation and may use root-preserving expanded envelopes or modular presentation. Ranged aim and wide block-hit are deferred per-action evidence.

## Validation

- `operator_2_5d_canonical_visual_contract_smoke.py` — passed; exact source hashes, deterministic generation, accepted profile/root/reference, no-cleanup disposition, canonical family/timing metadata, proxy overflow evidence, profile backward-read, and stable legacy profile hash.
- `operator_animation_workbench_smoke.py` — passed; creation/migration, schema, ownership, and compatibility coverage.
- `operator_art_registration_profile_smoke.py` — passed; v1 compatibility and trusted legacy plan replay remain valid.
- `operator_art_agent_mcp_smoke.py` — passed.
- `operator_art_agent_aseprite_smoke.py` — passed; internal guide layers do not leak into clean renders.
- `python3 -m py_compile` on changed Python files — passed.
- `git diff --check` — passed.
- Dropbox reviewed evidence cleanup — completed; publisher returned `status: deleted` for `/CUSTODIAN/visual_review/operator-2-5d-canonical-visual-contract/20261008T183010Z/REVIEW_MANIFEST.json` under `delete-after-review`.

## Deferred

No production runtime selector cutover is included. Universal action-envelope fit, future extreme per-action samples, and authoritative animation timing are not required to accept the canonical body/reference frame. The paired post-land review remains the next lifecycle step.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: the first profile-registry migration made legacy plan replay compare against the v3 registry hash; later, the neutral idle could not prove a universal action envelope, and the proxy scan found legacy overflow candidates after initial review handoffs. Immutable Dropbox runs required fresh IDs when evidence changed.
- Root cause / contributing factors: the legacy validator assumed one selected profile hash equaled the entire profile-file hash; neutral-idle poses do not cover extreme actions; published Dropbox manifests cannot be overwritten.
- Prevention / pipeline improvement: validate explicit profile hashes while preserving v1/v2 compatibility; distinguish canonical body registration from per-action envelopes; update the handoff under a fresh run ID when evidence changes.
- Tooling / docs drift discovered: the planning refresh repaired the packet's missing `Change` field. Repo-wide `check_ai_context.py` still reports 13 unrelated pre-existing findings in vehicle/Sundered Keep/ProcGen packet metadata and one archived review index entry; none touches this workstream's files. Missing FPS is preserved as unknown/null and non-blocking.
- Follow-up: review-operator-2-5d-canonical-visual-contract
- What worked: byte-exact masters, stable legacy hash, deterministic geometry/proxy checks, and a durable human decision block kept acceptance evidence explicit.

## Next Handoff

- Next workstream: review-operator-2-5d-canonical-visual-contract
- Next packet state: ready after this implementation lands
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: none; accepted implementation is ready for paired post-land review.
- Next action: land this implementation, then claim the paired review in a fresh reviewer context; after that review passes, refresh WB25-1 using its packet and the accepted profile/family provenance.
- Blockers or open questions: none for this workstream; per-action extreme-envelope validation and animation timing are deferred/non-blocking as recorded above.
