# Operator 2.5D Cohort Dependency Closure

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38

## Result

Completed the read-only cohort dependency closure audit at investigated main
`7d14aa7d697ad39696d873c1547092e6f2acb3f4`. The deterministic probe derives the
proposed `unarmed_neutral_motion_v1` from the current plan and emits:

- `custodian/docs/reports/operator_presentation/operator_2_5d_cohort_dependency_closure.json`
- `custodian/docs/reports/operator_presentation/OPERATOR_2_5D_COHORT_DEPENDENCY_CLOSURE.md`

The seven families total 56 eight-direction full-body targets. Only relaxed idle
has a resolved 15×128×128 frame contract and eight editable saved Workbenches;
the other six have null frame/loop/FPS contracts. I directly checked all eight
source-strip, Source Session, saved-document and corrected-manifest hashes
against the landed R0-01 evidence. Each current idle manifest remains at an
8 FPS / 125 ms preview with `timing_authority=false`.

The current `Operator2DReview.current_receipt()` projection returned zero
effective receipts and zero verified directions in all seven families. No
candidate direction is published. Current runtime identities are generation
neutral: relaxed posture currently has only east/west 96×96 modular
lower/upper-body rows, and locomotion uses legacy 96px runtime rows. The live
posture caller requires both lower and upper layers and projects directions to
east/west, while the candidate specifies eight-direction `full_body`. The
selector and body presenter do not establish a generation-aware full-body path
that prevents modular legacy art from reappearing.

The JSON records twelve open seams for posture entry/exit, idle/walk/run in both
directions, guard/parry, dodge, melee, ranged, equip/sheathe and action completion.
It calls the cohort **NOT_RELEASE_ELIGIBLE** and lists required composition,
art/clock, current QA/sandbox and human decision work. The audit creates no
runtime policy, artwork, or production change.

The physical `CUSTODIAN-operator-art` checkout was readable at
`19d466e7817cc15c5a07ffef67054e5c45215b02`, 67 commits behind `origin/main`,
with untracked source inbox files. I left its files untouched and report the
checkout as dirty. If another machine cannot read the workspace, the probe
emits `UNAVAILABLE` and null counts rather than claiming zero.

## Verification

- New deterministic/fail-closed closure smoke — PASS.
- `operator_animation_targets_smoke.py` — PASS.
- `operator_workbench_production_queue_smoke.py` — PASS.
- `operator_runtime_animation_authority_smoke.py` — PASS (existing 188-file legacy residue notice).
- `operator_2_5d_review_smoke.py` — direct cold-worktree attempt timed out at 90 seconds; serialized import preflight then passed on retry.
- `run_validation.py --changed --json` — PASS, final run 32/32 selected checks with complete changed-file coverage; JSON is at `/tmp/operator_2_5d_cohort_dependency_closure_validation.json` for lifecycle finish.
- Report consistency assertions — PASS (7 families, 56 slots, 8 editable, 0 verified, 12 open seams, 13 source input hashes).
- `task_packet_index.py --write`, subsequent index check, `check_ai_context.py --json` (0 findings), and `git diff --check` — PASS.

The cold Godot timeout matched the known fresh-worktree import-cache issue in the
predecessor correction run. The import cache preflight resolved it. During final
validation, `--changed` selected 32 checks due to the validation manifest and
documentation changes; all passed. No validation debris was added to the repo.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: direct sandbox smoke timed out on a cold cache; the external artist checkout has preserved untracked files and is behind current main.
- Root cause / contributing factors: a fresh worktree needs Godot's serialized editor import first; the populated artist workspace intentionally contains ignored/untracked art inputs and is independently versioned.
- Prevention / pipeline improvement: use the repository import preflight before the sandbox smoke; keep external workspace inspection read-only and describe its actual git state.
- Tooling / docs drift discovered: none
- Follow-up: review-operator-2-5d-cohort-dependency-closure
- What worked: hash binding to correction evidence and direct current-receipt evaluation prevented plan/source presence from being mistaken for review or runtime eligibility.

## Next Handoff
- Next workstream: review-operator-2-5d-cohort-dependency-closure
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Refresh reason: none
- Next action: Complete the fresh-context paired review, then take its exact WB25-6 planning-refresh handoff to the authoring chat.
- Blockers or open questions: No approved FPS/cohort or verified candidate directions; WB25-6 remains held.
