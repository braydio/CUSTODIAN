# Operator NE walk — master audit and anatomy recovery checkpoint

Workstream: operator-2-5d-ne-walk-retargeting
Authoring chat: not-recorded
Status: **partial: technical rig recovery implemented; human rig acceptance pending;
15-frame cycle still rejected. No merge, source/runtime publication, or timing approval.**

## Decision and authority

The user's master audit is preserved in
`custodian/tools/operator/ne_walk_retarget/MASTER_AUDIT_BRIEF.md`; the original
15-frame contract remains `BRIEF.md`. The explicit subsequent human decision is
recorded in `RECOVERY_DECISION.md`: preserve original SINGLE_FRAME (2191 opaque
pixels), reannotate against rendered far-leg anatomy first, author minimum hidden
completion, validate, and rerun unchanged V6. Newer recovered V6 pixels are comparison
only. The recovered master still needs human visual acceptance.

Selected immutable SHA256:
`0f5b3346044e60581db6e38e41fc292bd2b49ca05c291ada9591495765166149`.
Recovered comparison-only SHA256:
`b883f9d068d29d1d012e873b8902394ce5716faabb2fa756e2936c6cc176a58a`.
Both original files remain byte-identical to these inputs.

The lifecycle resumed the existing branch and merged newer main at `ece5a7920`.
The original `230a0b207` checkpoint and preview remain reachable/preserved.
This checkpoint stays on `agent/operator-2-5d-ne-walk-retargeting`.

## Audit reproduced and guard implemented

Real Aseprite export/save/reopen independently reproduces the supplied static audit:

- Locked sources differ at **11 pixels**: 8 added opaque positions and 3 recolors.
- All 58 recovered foot pixels trace to 29 original far-shin, 25 far-thigh,
  1 near-thigh and 3 previously transparent positions. Recovered far-shin art is 0.
- Original far shin 10.440px; recovered 3.606px; near 11.045px.
- Both old visible partitions are pixel-exact and have 18 unique valid pivots.
  Partition correctness therefore did not catch the semantic/articulation defect.
- Original ankle (49,98)/toe (45,101) are transparent, legitimate inference candidates
  but not proof of actual painted anatomy. Recovered ankle (50,85) samples a thigh-
  owned source location and its historical toe falls outside the recognized boot.

`master_audit.py` and `rig_audit.lua` reproduce these measurements and preserve input
hashes. An intermediate source-preserving, foot-incomplete candidate was created
before the human decision. It remains evidence, not the current proposed master.
`run.py` now rejects missing boot, empty shin art, anomalously short-chain review
triggers, and toe/boot inconsistency before starting V6. Both old candidates were
proven to stop before the solver; their RIG_BLOCKED reports remain local.

## Anatomy recovery candidate

Path:
`/home/braydenchaffee/Downloads/operator_ne_master_audit_implementation_v1/anatomy_recovery_verified/operator_ne_rig_ANATOMY_RECOVERY_CANDIDATE.aseprite`
SHA256: `b7002e66df5928a53d4a42e7b74e7bdf82f6ef8006a2bed11a8dcdae815a0ff5`.

`recover.py` accepts only the human-selected SHA and creates a new disposable
candidate. `recover_far_leg.lua` records a provisional source-space interpretation:
proximal visible far leg y78–83, distal leg y84–88, cuff/sole y89–91. Proposed
hip (53,75) remains an occluded inference; knee (52,83), ankle (50,88), toe (48,91)
follow this interpretation. Opacity alone was not used as the marker criterion.
These coordinates and the shorter projected chain remain **human-unaccepted**.

- 39 distal thigh pixels move to shin; 21 distal original shin pixels move to boot.
- Independent visible parts: **52px far thigh / 47px shin / 21px boot**.
- Two hidden shin joint-cover pixels at (51,83)/(52,83) and two hidden boot pixels
  at (50,88)/(51,88) use exact colors from selected source positions. All four are
  covered by their original visible owners in neutral.
- No new V6 source pixel, near-boot copying/mirroring, scale change or palette
  invention. Unrelated rig layers and all near-leg data remain unchanged.
- Far projected thigh **8.062px**, shin **5.385px**, compared with near **14.142px /
  11.045px**. This is a provisional foreshortened-chain annotation, not an approved
  anatomical-proportion decision. Visual review must decide whether it is defensible.

## Technical rig evidence

- Selected locked full-body **2191 pixels**, exact RGBA unchanged.
- One owner per visible pixel, no unowned/extra/recolored visible pixels.
- All 18 exact-color pivots parsed once; no unknown markers.
- Neutral composite **0 pixel mismatches**, including hidden completion layers.
- Both boot geometries pass the existing V5.5 requirements.
- Six real IK/raster support probes: near/far at -15°, 0°, +15° all pass; no target
  clamping, sole residual max **0.5px x / 0px y**, segment-length errors below 1e-8.
- Saved candidate reopens through Aseprite; Python independently verifies source,
  neutral, unrelated-layer and palette identity.
- `recovery_report.json`, `original_audit/audit.json`, `candidate_audit/audit.json`
  and `neutral_reconstructed.png` are under the candidate directory.

The initial recovery run and the final reproducible-driver candidate are byte-
identical. Therefore V6's recorded rig SHA matches the verified candidate exactly.
The earlier incomplete candidate was never treated as passing.

## Unchanged V6 comparison

New evidence:
`/home/braydenchaffee/Downloads/operator_ne_master_audit_implementation_v1/v6_recovered_run01/`

Clean animation, separate QA, source/marker tracks, 15 per-frame PNGs, compact
contact sheet and full `report.json` are retained there.
Comparison: `/home/braydenchaffee/Downloads/operator_ne_master_audit_implementation_v1/RECOVERY_V6_COMPARISON.json`.

| Check | Previous | Recovered candidate |
|---|---|---|
| Full passing frames | 3/15 | **5/15** (1, 4, 6, 11, 12) |
| Passing support contacts | 14/15 | **13/15** |
| 15→1 max joint step | 4.556px | **2.737px** |
| Source/timing acceptance | absent | still absent for rig/cycle/timing |

The full-pass count improves by 2; contact coverage regresses by 1. **The cycle
remains rejected** (expected exit 2). Frames 5 and 13 fail support contact/reach;
other failures include branch flips, angular and joint jumps. No tolerance was
relaxed to improve the score.

| Frame | Contact dx / dy | Remaining defects |
|---|---|---|
| 1 | 0.483 / 0.162 | implemented checks pass |
| 2 | -0.897 / -0.128 | far_shin_rotation_jump, far_knee_branch_flip |
| 3 | 0.506 / -0.332 | near_knee_jump, near_ankle_jump, near_toe_jump, near_thigh_rotation_jump, far_ankle_jump, far_toe_jump, far_shin_rotation_jump, far_knee_branch_flip |
| 4 | 0.376 / -0.332 | implemented checks pass |
| 5 | 4.246 / -7.332 | rendered_support_contact, far_unreachable |
| 6 | -0.173 / -0.752 | implemented checks pass |
| 7 | 0.463 / -0.752 | far_ankle_jump, far_toe_jump, far_knee_branch_flip |
| 8 | 0.765 / -0.332 | far_ankle_jump, far_toe_jump |
| 9 | -0.098 / 0.162 | near_toe_jump, far_knee_jump, far_ankle_jump, far_toe_jump |
| 10 | 1.772 / -0.128 | near_ankle_jump, near_toe_jump, far_shin_rotation_jump, far_knee_branch_flip |
| 11 | 0.001 / 0.162 | implemented checks pass |
| 12 | -1.003 / -0.838 | implemented checks pass |
| 13 | -2.875 / -6.128 | rendered_support_contact, near_unreachable, far_knee_jump, far_shin_rotation_jump, far_knee_branch_flip |
| 14 | 0.532 / 0.162 | near_toe_jump |
| 15 | 0.402 / 0.162 | far_knee_jump, far_thigh_rotation_jump, far_shin_rotation_jump, far_knee_branch_flip |

`batch.lua` is byte-identical to the original V6 checkpoint; SHA256
`2e2cf2cb7b939b4238968f9598eb57e31106dd7b00c4434ab9ea31cd809fd49a`. Body registration remains center x=64, root (64,106), ground
107. Both the original and new runs pass exact donor hash/reassembly checks.
No FPS was chosen; editor durations remain placeholders. No gameplay/runtime
selector or canonical source/Workbench approval was modified.

## Reproduction and validation

```bash
python3 custodian/tools/operator/ne_walk_retarget/master_audit.py \
  --original ~/Downloads/SINGLE_FRAME.aseprite \
  --recovered ~/Downloads/custodian_operator_ne_rig_recovery_audit_v1/operator_ne_rig_RECOVERED_FROM_V6_UNVERIFIED.aseprite \
  --output <fresh-audit-directory>
python3 custodian/tools/operator/ne_walk_retarget/recover.py \
  --original ~/Downloads/SINGLE_FRAME.aseprite --output <fresh-recovery-directory>
python3 custodian/tools/operator/ne_walk_retarget/run.py \
  --bundle ~/Downloads/custodian_operator_ne_knight_15f_reference_v1 \
  --rig <recovery-directory>/operator_ne_rig_ANATOMY_RECOVERY_CANDIDATE.aseprite \
  --output <fresh-v6-directory>
python3 custodian/tools/validation/run_validation.py --test operator_ne_rig_master_audit --json
python3 custodian/tools/validation/run_validation.py --changed --base HEAD --json
git diff --check
```

Real Aseprite recovery/round-trip/contact probes PASS. Final focused smoke PASS
(`/tmp/ne_recovery_final_focused_validation.json`), including positive ownership,
missing shin/boot, duplicate ownership, recoloring, toe/boot mismatch, short chain,
locked-source mutation and unrelated near-leg mutation controls. No synthetic
fixture grants human art acceptance. Validation ownership is registered for the
experiment, addressing the previous checkpoint's coverage gap.

The changed-file run at the audit stage passed **35/35 checks with complete
coverage** (`/tmp/ne_master_audit_changed_validation.json`). After the user's
additional recovery authorization/code, final focused regression, actual Aseprite
recovery and unchanged-V6 execution were rerun; the unrelated 35-test set was not
repeated. Python compilation and whitespace checks pass. Moment Forge: not run —
local authoring tooling, no runtime change. Operator inspection resizing used the
required `pixelart ... --choose 1` alias and is review-only.

An initial changed-file base selected upstream changes merged during resume (78
checks). It was interrupted during import before test execution, the owned importer
stopped, and the selection corrected to current HEAD. The owned import's three
untracked generated UID files were classified/removed. Other game processes were
preserved. No old failed preview was silently reused for the new candidate.

## Visual review and next boundary

The source/anatomy-route decision review was recorded and its old cloud evidence
was deleted using the publisher's delete-after-review command.

Current review manifest:
`/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/anatomy-recovery-20261016/REVIEW_MANIFEST.json`
Authoring chat: not-recorded

Exact questions:

1. Is the proposed far-leg chain hip (53,75), knee (52,83), ankle (50,88), toe (48,91)
   defensible for the selected rendered NE anatomy, including its shorter projected
   segments?
2. Are the 52px thigh / 47px shin / 21px boot ownership and four hidden joint-cover
   pixels acceptable as the recovered rig, with exact neutral/source identity?
   This approves neither the still-failing 15-frame cycle nor timing.

Only one compact chain-comparison image plus the editable rig and two structured
reports were uploaded. No repeated full-frame or full-motion capture is needed for
this rig decision. Retention is delete-after-review. After recording the decision,
resume this same workstream and run:

```bash
python3 custodian/tools/iteration/publish_review_artifacts.py \
  --reviewed-manifest /CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/anatomy-recovery-20261016/REVIEW_MANIFEST.json \
  --reviewed-by chatgpt-user
```

Keep the branch and checkpoints. Do not call finish/merge: the audit explicitly
requires a visually accepted 15-frame cycle and validation ownership before merging;
ownership is fixed, but the cycle and human master acceptance are not.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: neutral partition checks allowed shin pixels to be counted as a foot; historical pivots lacked anatomical artwork evidence; initial validation base included upstream resume merges; reannotation improves full passes but does not solve the cycle and contact coverage regresses.
- Root cause / contributing factors: pixel ownership and pivot color uniqueness do not establish articulated anatomy; single-view depth/foreshortening and limb branch continuity remain uncertain.
- Prevention / pipeline improvement: exact source decision, pre-solver semantic/foot gates, source-preserving recovery driver, real contact probes and focused regression owner; validate current-turn scope against current HEAD after resume.
- Tooling / docs drift discovered: previously uncovered experiment has registered regression ownership; README and FILE_INDEX now route master audit, recovery and preflight.
- Follow-up: fixed-in-scope
- What worked: immutable inputs, real Aseprite round-trip, four occluded joint-cover pixels, unchanged solver and explicit negative cycle result.

## Next Handoff
- Next workstream: operator-2-5d-ne-walk-retargeting
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: not-recorded
- Refresh reason: human visual acceptance of reannotated far-leg anatomy/projection and recovered master remains required.
- Next action: review the exact anatomy-recovery Dropbox manifest; record the rig decision and clean reviewed cloud evidence; then address remaining V6 branch/contact discontinuities in the same retained workstream.
- Blockers or open questions: projected far-leg proportions/ownership acceptance; 10 failed V6 frames including contact failures 5/13; coherent-loop and timing approval. No source/runtime publication or main merge.
