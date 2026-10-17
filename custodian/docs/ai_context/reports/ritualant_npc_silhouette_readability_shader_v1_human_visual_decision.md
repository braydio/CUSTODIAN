# Ritualant NPC silhouette readability shader V1 — human visual decision

- Decision: **approved** (human/user artistic sign-off).
- Decision date: 2026-10-17.
- Workstream: `ritualant-npc-silhouette-readability-shader-v1`.
- Candidate commit: `03678c0af88caf911166040a06fba460bcf4d2e0`.
- Candidate branch: `agent/ritualant-npc-silhouette-readability-shader-v1`.
- Published visual review: `/CUSTODIAN/visual_review/ritualant-npc-silhouette-readability-shader-v1/ritualant-readability-human-gate/REVIEW_MANIFEST.json`.
- Review run: `ritualant-readability-human-gate`.
- Reviewed artifact: `artifacts/before_after_roi.png` (manifest SHA-256 `dffb67e0369b018c4fd5deb2410bf1634207bac62622f4695f20af3ef42931df`).
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20

## Human decision and scope

The user inspected the matched normal-gameplay-scale before/after image in this authoring conversation and stated: **"okay yeah it looks goodtome we may end up remaking the animated guy anywasy but im signed off"**.

Interpretation: **approve the current subtle kneeling-actor visibility treatment and its art direction**. The sprite is easier to separate from the authored stone floor; the pale edge is restrained and does not read as an overt magical outline. This is the required user-owned aesthetic decision for the submitted candidate, **not** approval of an invented future sprite remake.

The single published ROI only shows the kneeling comparison. It does **not** visually demonstrate hostile, dissolve, or violent-death phases. Their alpha, animation and presentation correctness remain objective implementation/independent review obligations under the existing packet. Do not misrepresent the kneeling screenshot as proof of all phases; however, do not reopen or block this already-given subjective visual approval solely because a future full character remake might be considered. If the reviewer finds a concrete phase defect, report and correct it under normal review rules.

## Resume/closeout instructions

1. Resume the **same** claimed/recovery workstream from its exact remote branch and preserve the existing candidate and validation evidence. Do not re-author or claim an unrelated workstream instead.
2. Include this decision and exact manifest/run/commit provenance in the implementation closing summary and archived packet; complete existing objective validation and land normally on `main`.
3. Have the independent `review-ritualant-npc-silhouette-readability-shader-v1` workstream verify the actual landed scene/shader, alpha and phase safety, branch/review provenance and this recorded human acceptance.
4. Follow the published `delete-after-review` policy **after this human decision is durably incorporated into the claimed workstream closeout**, using the manifest's exact `publish_review_artifacts.py --reviewed-manifest ... --reviewed-by chatgpt-user` cleanup command. Record cleanup result; do not delete evidence prematurely or commit Dropbox review binaries.
5. A possible later animation/actor redraw remains a **new optional art workstream**, not a blocker and not permission to change this shader workstream's approved boundary.

No runtime code or workstream status was changed by this decision receipt.
