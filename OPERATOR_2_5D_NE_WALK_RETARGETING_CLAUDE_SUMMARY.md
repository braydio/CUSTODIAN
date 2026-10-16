# Operator NE walk V6 retargeting — partial checkpoint

Workstream: operator-2-5d-ne-walk-retargeting
Authoring chat: not-recorded
Status: **partial; no art acceptance, source intake, runtime publication, or main landing**.
Brief: `custodian/tools/operator/ne_walk_retarget/BRIEF.md` (the user's ZIP instructions).

## Delivered

- Unpacked `~/Downloads/custodian_operator_ne_knight_15f_reference_v1.zip` into
  `~/Downloads/custodian_operator_ne_knight_15f_reference_v1/`.
- Added a preview-only Python/Lua V6 adapter, pinned to the local V5.5 script hash,
  plus 135 individually identified, editable provisional reference landmarks.
  Removed the obsolete embedded Knight F1 pixels and markers from the generated
  execution core; never called the single-frame retarget entrypoint.
- Preserved the immutable saved rig and exact source-part palette. Used editable
  rig pivots, fixed segment lengths, moving phase contacts, bounded pelvis reach,
  and ±3px raster correction with IK re-solving. Reported failed frames rather
  than converting contact-only success into gait acceptance.
- Added independent upper-body and robe controls, disabled in this baseline.
- Saved a separate 15-cel clean RGBA preview, QA and marker tracks, original rig
  copies hidden/locked, per-frame PNGs, clean/QA 1920×128 strips, compact contact
  sheet and machine-readable per-frame/loop reports. No scaling or invented pixels.
- Linked the experiment from the Operator tools README and FILE_INDEX.

## Exact local evidence

Final output directory: `/home/braydenchaffee/Downloads/custodian_operator_ne_knight_15f_reference_v1/preview_v6_run04`

- `operator_ne_walk_v6_PREVIEW_ONLY.aseprite`
- `operator_ne_walk_v6_15f.png` (1920×128 RGBA, 15×1)
- `operator_ne_walk_v6_qa_15f.png`, `contact_sheet.png`
- `frame_01.png` through `frame_15.png` (128×128 RGBA)
- `annotations.json`, `input_validation.json`, `aseprite_report.json`, `report.json`
- `source_palette.png`, `aseprite.log`, `run_receipt.json`, `batch_generated.lua`

Reference source SHA256: `707efe8a3d0438473d87fdf112c9127c2b034454d3d383bc1829dda3a632b1d1`.
Saved rig SHA256: `8445bd69ae03e2798ba8eac28eefc6116ff0750aadf24dc24eb99d40cdd4375e`.
Pinned V5.5 SHA256: `767125d82caa03de90da0216bdb5f8277d691771264cf8ab44a57b2bd54a5521`.
All 15 file hashes and exact cropped/reassembled pixel identity pass. All 135 marker
records have provenance and unique identities; final boot marker samples avoid
empty/shadow pixels under the conservative input check. These are **agent estimates,
not accepted gait annotations**. Occluded pelvis/hip centers are explicitly marked
inferences; confidence is null. That check cannot prove anatomical ownership.
The near 1–2 → far 3–8 → near 9–15 support schedule remains provisional.

## Observed frame results

**15 rendered; 14/15 contact checks pass; 3/15 all implemented per-frame checks pass.**
Overall preview is rejected (`accepted=false`, process exit 2).

| Frame | Support | Contact dx / dy px | Result / deficiencies |
|---|---|---|---|
| 1 | near | 0.10 / -0.07 | far_unreachable |
| 2 | near | 0.29 / -0.47 | far_unreachable, far_knee_jump, far_ankle_jump, far_toe_jump, far_thigh_rotation_jump, far_knee_branch_flip |
| 3 | far | -0.37 / 0.23 | near_knee_jump, near_ankle_jump, near_toe_jump, far_knee_jump, far_ankle_jump, far_toe_jump, far_shin_rotation_jump, far_knee_branch_flip |
| 4 | far | -0.18 / 0.23 | checks pass; human acceptance pending |
| 5 | far | 0.01 / 0.23 | checks pass; human acceptance pending |
| 6 | far | -0.19 / 0.02 | checks pass; human acceptance pending |
| 7 | far | -0.30 / 0.02 | near_unreachable, far_ankle_jump, far_shin_rotation_jump, far_knee_branch_flip |
| 8 | far | -0.08 / 0.23 | far_knee_jump, far_ankle_jump, far_toe_jump |
| 9 | near | -0.69 / -0.07 | far_unreachable, near_toe_jump, far_ankle_jump, far_toe_jump, far_shin_rotation_jump |
| 10 | near | 1.03 / 0.53 | far_unreachable, near_ankle_jump, near_toe_jump, far_knee_branch_flip |
| 11 | near | -1.66 / -0.07 | far_unreachable |
| 12 | near | -4.41 / -5.07 | rendered_support_contact, near_unreachable, far_unreachable, far_knee_branch_flip |
| 13 | near | 0.07 / -0.47 | far_unreachable, far_knee_branch_flip |
| 14 | near | 0.62 / -0.07 | far_unreachable, far_knee_jump |
| 15 | near | 0.06 / -0.07 | far_unreachable |

The 15→1 seam has max joint displacement **4.556px**,
**2283 changed pixels**, and **0 knee branch flips**.
The seam measurement does not establish acceptable visual interpolation. Other
within-cycle branch/joint discontinuities still fail. No in-between frames were
invented. Root stays (64,106), center x=64, semantic ground y=107; existing neutral
near/far depth planes are not collapsed to a single sole row. Output colors are
an exact subset of the source-part palette; binary alpha and cell bounds pass.
Pixel-hole coverage, a true ground-plane model/swing clearance, coherent authored
upper-body/robe motion, visual-loop approval and timing remain unproven.

## Rig blocker and smallest next correction

The only saved candidate with both boot layers is
`/home/braydenchaffee/Temp/RigPivotBuildingTemp.aseprite`.
It passes V5.5's layer/pivot-color/unclassified/foot checks, but its far pivots are
hip (53,75), knee (52,88), ankle (50,85), toe (45,101). That produces a **3.606px
far shin**, versus **11.045px near shin**. Far boot contact is (50.5,91), versus
near (65.5,105). Structural validity is not proof this is the intended final rig.
`~/Temp/Sprite-0003.aseprite` instead has a 10.440px far shin but no far-foot pixels;
it fails the support-foot gate. No master was rebuilt or silently corrected.

The user was asked to identify/save the intended finalized rig master. Resume this
same workstream with that exact file, recheck immutable hashes, then rerun to a new
output directory. Do not edit canonical pivots, invent timing, force a common foot
plane or damp away failures to manufacture a pass. If this master is intentional,
the constrained source geometry and contact model need an explicit authoring decision
before this experiment can satisfy the coherent-loop contract.

## Validation commands and outcomes

From the retained worktree:

```bash
python3 custodian/tools/operator/ne_walk_retarget/run.py \
  --bundle ~/Downloads/custodian_operator_ne_knight_15f_reference_v1 \
  --rig ~/Temp/RigPivotBuildingTemp.aseprite \
  --output ~/Downloads/custodian_operator_ne_knight_15f_reference_v1/preview_v6_run04
python3 -m py_compile custodian/tools/operator/ne_walk_retarget/run.py
python3 custodian/tools/validation/run_validation.py --changed --base HEAD --json
 git diff --check
```

- Real Aseprite run: all outputs written, source rig hash unchanged, rejected preview
  with above defects (exit 2). Full exact executable command/config in `run_receipt.json`.
- Focused input negative controls: wrong source/frame hashes, root drift, invented 8 FPS
  and duplicate markers all refused. Correct source passes exact 15-frame reassembly.
- Python compilation and whitespace check pass.
- Changed-file repository run: all **9 selected checks pass**, but overall result is
  **false** because the new experiment's four non-doc files have no registered owner.
  Report retained locally at `/tmp/ne_v6_changed_validation.json`. Register a durable
  focused input-contract/Aseprite fixture validation owner before any main landing.
- Moment Forge: not run — isolated authoring tooling; no Godot/runtime change.
- No source or runtime tests were falsely claimed as animation acceptance. Aseprite
  editor durations remain 100ms placeholders; authoritative FPS remains null.

## Documentation drift

The accepted canonical profile/visual contract agrees with this handoff's 128px cells,
root (64,106), center x=64 and ground y=107. Existing specialized Operator identity,
source→Workbench→QA/human/timing/sandbox→publication separation is preserved. No generic
Asset V2 family or animation selector was created.

The current production-queue packet is archived WB25-5
`OPERATOR_2_5D_WORKBENCH_PRODUCTION_QUEUE.md`, not a Knight-retarget production packet.
No matching retarget packet exists; the supplied ZIP brief is retained as the native
contract for this local experiment. WB25-6/runtime cutover remains a separate gate.
The high-level `ISOMETRIC_2_5D_REALIZATION_ROADMAP.md` Operator-canon paragraph still
uses prospective wording for the canonical-contract step, while its dedicated visual
contract already records acceptance. This historical roadmap wording is reported;
it does not authorize changes to live source intake or runtime state. No profile or
publication reality changed, so those authorities were not rewritten.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: first batch used unsupported json.null access in Aseprite; early marker traces hit shadow/empty pixels; saved rig's structurally valid geometry cannot sustain the requested gait under the current mapping; changed-file validation has no owner for new tooling.
- Root cause / contributing factors: supplied ZIP omits the rig and V5.5 dependency; saved candidate cannot be assumed to match the user's current edited master; pixel-sampling and real Aseprite execution exposed gaps that layer validation misses.
- Prevention / pipeline improvement: bind the intended master by immutable hash in future handoffs; validate per-frame boot anatomy before solving; record far/near segment and sole diagnostics; register focused fixture ownership before landing.
- Tooling / docs drift discovered: V5.5 checks establish structure rather than accepted rig anatomy; new experiment files are not covered by the repository validation manifest; prospective canon roadmap wording described above.
- Follow-up: manual-follow-up
- What worked: isolated worktree, exact hash/pixel checks, real batch execution, explicit failed frames and preserved source art.

## Next Handoff
- Next workstream: operator-2-5d-ne-walk-retargeting
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: not-recorded
- Refresh reason: identify the intended saved finalized rig master; no accepted gait or timing decision exists.
- Next action: provide/save the correct rig path, then resume this retained workstream; add validation ownership and rerun geometry/contact QA before finish.
- Blockers or open questions: intended rig master identity; far-leg geometry/contact-plane fit; failed frame 12 contact and within-cycle knee discontinuities; coverage registration; visual-loop and timing acceptance.
