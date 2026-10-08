# OPERATOR 2.5D ANIMATION VIABILITY AUDIT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-2-5d-animation-viability-audit`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `operator-art-agent, presentation-experiments`
- Kind: `implementation`
- Review: `none`
- Review rationale: `low-risk exemption: read-only current-main closeout; the human visual decision is already recorded in the authoring chat and must not be reopened`
- Visual review: `none`
- Human visual decision: `recorded in the authoring chat on 2026-10-07; Codex must consume it as authority rather than reopening the legacy-art viability question`
- Reviewed main: `90e2ac01e3b91809bd5e1b52fe6ada13e388c808`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Goal: Determine whether the current production-reachable Operator animation art is viable for CUSTODIAN's fixed-isometric 2.5D contract, quantify exactly where directional/viewpoint/registration/composition gaps exist, and produce a ranked art backlog before the Forum 2.5D vertical slice treats the Operator as an approved visual benchmark.
- Completion boundary: Recover and close the existing audit against current main using the user's recorded art-direction decision and the two exact locked inputs below. Preserve the structural/runtime evidence, but rewrite the final classification so pre-migration live art is legacy/misaligned unless it independently satisfies the new lock; treat the supplied relaxed idle as the first canonical `operator_2_5d_128` production family; update the ranked backlog around that truth. Do not modify, publish, ingest, regenerate, normalize, or replace Operator art in this audit.
- Current measured state: The user has resolved the audit's central art-direction ambiguity. Existing production-reachable Operator art predating the migration is not the planned volumetric realistic top-down 2.5D target and must not be counted as canonical completion merely because it is live or directionally broad. The locked design authority is the user-supplied 2048x256 RGBA 8-direction sheet at `/CUSTODIAN/implementation_inputs/operator_2_5d_design_lock_v1_8dir_1f_256.png` (8x1 256px cells, order N/NE/E/SE/S/SW/W/NW, SHA-256 `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`). The first and currently only fully authored target-aligned production animation is `unarmed/posture/idle_relaxed_01/full_body`, supplied at `/CUSTODIAN/implementation_inputs/operator_2_5d_unarmed_posture_idle_relaxed_01_full_body_v1_8dir_15f_128.png` (1920x1024 RGBA, 15 columns x 8 direction rows, 128x128 cells, SHA-256 `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`). All future 2.5D Operator animation authoring is based on the locked design sheet. Legacy/projection art may remain runtime fallback during migration, but it does not satisfy canonical 2.5D coverage.
- Evidence: exact locked Dropbox inputs `/CUSTODIAN/implementation_inputs/operator_2_5d_design_lock_v1_8dir_1f_256.png` and `/CUSTODIAN/implementation_inputs/operator_2_5d_unarmed_posture_idle_relaxed_01_full_body_v1_8dir_15f_128.png` with hashes above; the user's decision in this authoring chat; `custodian/content/data/operator/generated/operator_animation_catalog.generated.json`; `custodian/game/actors/operator/animations/operator_animation_selector.gd`; `custodian/game/actors/operator/operator.gd`; `custodian/game/actors/operator/presentation/`; `custodian/tools/operator/`; `custodian/content/data/operator/authoring/operator_art_profile.json`; `custodian/dev/test_sprites/Knight/`; `design/01_systems/ISOMETRIC_2_5D_PRESENTATION_CONTRACT.md`.
- Task-specific authority: the user's 2026-10-07 decision; exact locked design-reference bytes/hash; exact authored relaxed-idle bytes/hash; live runtime/catalog truth on claim-time main for legacy/fallback reachability only; the 2.5D presentation contract; current Operator Workbench/preview/motion APIs.
- Work surface: read-only analysis of Operator canonical/runtime art plus durable reports under `reports/operator_presentation/`; bounded roadmap/index updates only.
- Change: evidence and planning truth only. No production art/runtime mutation.
- Preserve: all canonical/runtime Operator PNGs, manifests, SpriteFrames, sockets, frame timings, gameplay animation selection, Operator runtime behavior, Asset Pipeline V2 families, source-work/inbox state, and both external visual references.
- Non-goals: no new Operator art; no 16-direction Operator mandate; no frame-count retuning; no combat balance changes; no runtime fallback rewrite; no Workbench feature work; no Asset V2 ingest; no copying LoP/Playable Knight pixels into CUSTODIAN production art; no Forum vertical-slice implementation.
- Acceptance: the final durable report records the locked design reference and authored relaxed idle with exact hashes/geometry; `unarmed/posture/idle_relaxed_01/full_body` is classified as the first canonical `operator_2_5d_128` family rather than a legacy viability candidate; pre-migration live/projection art is explicitly separated from canonical completion; 8-direction is the production directional contract unless a later gameplay-specific packet proves a need for more; the remaining required art work is ranked around the already-complete idle family; no Operator art bytes or runtime selectors change in this audit.
- Validation: no broad gameplay suite. Verify report artifacts exist and are internally consistent, run the existing Operator catalog/status command(s) needed to prove identities, run `git diff --check`, and prove no Operator source/runtime PNG or asset-family content changed.
- Task overrides: `none`
- Deferred: any actual art repair/regeneration and the exact production packet series are authored only after user/ChatGPT review of this audit.

## Workstream identity

```text
workstream: operator-2-5d-animation-viability-audit
branch: agent/operator-2-5d-animation-viability-audit
closing summary: OPERATOR_2_5D_ANIMATION_VIABILITY_AUDIT_CLAUDE_SUMMARY.md
```

## Required durable outputs

Create:

```text
reports/operator_presentation/
├── OPERATOR_2_5D_ANIMATION_VIABILITY.md
├── operator_2_5d_coverage.json
├── operator_2_5d_locomotion_matrix.png
├── operator_2_5d_combat_matrix.png
└── operator_2_5d_reference_matrix.png
```

The PNGs are evidence/report artifacts, not runtime assets. Do not route them through Asset Pipeline V2.

Temporary generation scripts belong under `.ai/operator_2_5d_audit/` or `/tmp` and are not committed unless a genuinely reusable missing capability is discovered. Prefer existing Workbench APIs over new tooling.

## Reference goalposts

### A. Lords of Pain directional reference

Use the user's local reference if present, in this preference order:

```text
~/Downloads/lop_knight_N-NNE-NE-ENE-E_reference.zip
~/Downloads/LordsOfPain.zip
```

This is a **visual reference only**. Never commit or ingest its contents.

Primary value:

- 16-angle rotational continuity;
- consistent apparent camera pitch;
- N → NNE → NE → ENE → E body-volume progression;
- near/far limb and equipment occlusion;
- stable ground contact while the body rotates.

For Operator comparison, map authored Operator sectors to the compatible goalposts:

```text
Operator N  -> LoP N
Operator NE -> LoP NE, with NNE/ENE used as continuity intermediates
Operator E  -> LoP E
```

If neither local archive exists, do not fetch/guess a substitute. Finish the structural/Playable-Knight audit, mark LoP visual evidence unavailable, and make that missing local reference the only visual-review blocker.

### B. CUSTODIAN Playable Knight

Use the in-repo reference:

```text
custodian/dev/test_sprites/Knight/
```

Primary sheets:

```text
Idle.png
Walk.png
Melee.png
```

Inspect other Knight sheets only when they provide a directly relevant action analogue such as block, damage, draw/sheathe, slide/dodge, or death.

Verify its actual sheet geometry on claim-time main rather than trusting this packet's descriptive shorthand.

Primary value:

- convincing 8-direction production coverage;
- stable per-direction camera/viewpoint;
- ground/foot registration;
- readable silhouettes at gameplay scale;
- large combat arcs that retain directional volume.

The Knight is a goalpost, not a source asset to copy.

## 1. Build the structural inventory first

Parse:

`custodian/content/data/operator/generated/operator_animation_catalog.generated.json`

Do **not** count every catalog row as future art.

Classify semantic actions into:

1. **production-reachable**: referenced by the live Operator/presentation/weapon path;
2. **projection-supported**: runtime deliberately maps requested sectors onto fewer authored sectors;
3. **legacy/catalog-only**: compatibility/archive residue not reachable from current production presentation;
4. **dev/reference-only**.

The report must clearly separate those groups so legacy residue does not inflate the art estimate.

For every production-reachable action record:

- profile;
- group;
- action;
- required runtime role;
- authored directions;
- requested gameplay directions;
- layers present per direction;
- frame counts per layer;
- frame size;
- FPS/timing source where available;
- whether runtime projects sectors;
- whether projection is explicitly intentional or documented debt;
- whether a full-body or modular composition is used;
- current source/runtime paths.

Write machine-readable truth to `operator_2_5d_coverage.json`.

## 2. Priority tiers for visual review

### Tier A: constant/high-frequency body identity

Audit every direction and relevant layer for:

- unarmed idle;
- unarmed walk;
- unarmed run;
- unarmed combat-ready/engaged posture;
- primary dodge/roll/evade presentation.

These determine whether the Operator feels like one volumetric body moving through the world.

### Tier B: high-frequency combat

Audit the live production-reachable representatives for:

- primary unarmed fast chain;
- unarmed block/guard if reachable;
- melee 1H relaxed/ready stance;
- melee 1H walk/run;
- melee 1H fast chain;
- melee 1H block enter/loop/hit;
- draw/sheathe/ready transitions;
- ranged 2H stance/aim/fire/run/walk where production-reachable;
- sidearm equivalents where production-reachable.

Do not force an obsolete/legacy action into this tier just because it exists in the catalog.

### Tier C: lower-frequency/special

Inventory all production-reachable:

- heavy attacks;
- damage reactions;
- knockdowns/recoveries;
- death;
- critical/special attacks;
- field-use/cosmetic actions.

Perform detailed visual grading only where the action is spatially misleading or likely to become a visible 2.5D break. An intentional OMNI death may be acceptable.

## 3. Objective visual criteria

Grade actual runtime pixels, not filenames.

For each reviewed action/direction evaluate:

### Ground anchor stability
Feet/contact point remain coherent across frames and directions. Intentional root-driving action motion is not registration drift.

### Viewpoint/camera consistency
N/NE/E/etc. read as the same character under one fixed-isometric camera pitch.

### Body volume
Torso, shoulders, head, near/far limbs, cape and equipment show plausible foreshortening/overlap for that direction.

### Directional continuity
N → NE → E and equivalent arcs read as one body rotating, without scale/head-height/silhouette snapping.

### Modular seam integrity
Where lower/upper body are composed, waist registration does not split, float, or visibly change body scale.

### Action readability
Attacks/blocks/aiming retain a clear gameplay silhouette while preserving spatial orientation.

### Gameplay-scale readability
Judge at actual Operator preview/gameplay scale, not only zoomed pixel inspection.

### Ground/shadow relationship
Current sprite registration remains compatible with the Operator ground-root and BlobShadow/fake-elevation presentation model.

## 4. Classification

Each production-reachable action gets exactly one primary verdict:

```text
GREEN  viable unchanged
YELLOW viable after registration / seam / cleanup only
ORANGE needs missing directional art or substantial directional redraw
RED    current concept/viewpoint is incompatible enough to reauthor
GRAY   consciously projected/OMNI; no new art recommended for this action
```

Also record reason tags:

```text
missing_direction
missing_layer
projection_visible
pitch_mismatch
volume_flat
registration_drift
modular_seam
scale_drift
silhouette_break
weapon_alignment
fx_alignment
acceptable_omni
legacy_excluded
```

Do not use RED merely because an animation is old or stylistically imperfect. RED means it fails the new spatial contract.

## 5. Evidence matrices

### operator_2_5d_locomotion_matrix.png

Columns:

```text
N | NE | E | SE | S | SW | W | NW
```

Rows must at least include current production-reachable idle, walk, run, ready posture and dodge.

For an animated cell, show 3 representative frames (early / middle / late) or another compact contact-strip representation that makes grounding and body volume inspectable.

Mark absent/projected directions visibly. Do not silently render a projected E strip and label it NE without a projection badge.

### operator_2_5d_combat_matrix.png

Same 8-sector column convention.

Include representative live actions from unarmed, melee 1H and ranged/sidearm production surfaces. Prioritize actions that are frequently visible or currently sparse.

### operator_2_5d_reference_matrix.png

Show a bounded comparison sufficient to judge the target:

- LoP N/NNE/NE/ENE/E reference sequence if local files are available;
- Playable Knight N/NE/E examples from Idle/Walk/Melee;
- Operator N/NE/E equivalents for idle/walk/run plus one combat representative.

Labels must make clear that references are **goalposts only** and not CUSTODIAN source art.

Do not commit third-party LoP source pixels if repository policy/licensing forbids durable inclusion. If that prevents committing the LoP row, publish the reference matrix only through the visual-review handoff and keep the durable Git report textual/hash-based.

## 6. Quantify the art backlog

The final report must answer the user's core planning question numerically.

Provide totals for production-reachable work in these buckets:

```text
existing sheets viable unchanged
existing sheets needing cleanup only
new directional sheets required
existing directional sheets needing substantial redraw
actions where current projection/OMNI is acceptable
legacy/catalog-only identities excluded
```

Then provide a ranked backlog table with one row per semantic action family:

```text
rank
profile/group/action
gameplay frequency
current authored sectors
target sectors
missing/new sectors
layers affected
verdict
estimated new/redo sheet count
reason
recommended implementation slice
```

Count **sheets**, not only semantic actions. If lower/upper/weapon/fx require separate authored strips, count those separately and explain the composition.

Do not manufacture target directions merely to hit 8-direction symmetry. The target is the minimum coverage that preserves convincing 2.5D presentation and gameplay readability.

## 7. Recommend the art-production roadmap, but do not author it yet

End `OPERATOR_2_5D_ANIMATION_VIABILITY.md` with:

- recommended first art slice;
- estimated total number of coherent art-production slices;
- which slices can be parallel;
- which depend on a shared reference/registration decision;
- expected asset families/sheet counts per slice;
- whether existing Workbench/Art Agent is sufficient;
- any tooling gap that should be solved before mass production.

Strong default ordering unless evidence contradicts it:

```text
A. unarmed locomotion + relaxed/ready identity
B. dodge / block / movement transitions
C. melee 1H locomotion + posture
D. melee 1H attack chain + guard
E. ranged 2H stance / aim / fire / locomotion
F. sidearm
G. heavy / reaction / special / death cleanup
```

Do not create those implementation packets in this task. The user/ChatGPT will approve or reorder them after reviewing the evidence.

## 8. Existing Operator elevation drift note

The final report must explicitly record that the Operator already owns a local presentation-only elevation behavior through `set_fake_elevation()` and BlobShadow separation.

Compare its semantics with the landed generic `IsometricVisualAnchor2D` foundation and identify one of:

```text
compatible as-is
compatible but needs adapter/convergence in Forum slice
semantic conflict requiring a separate correction packet
```

Do not modify either system in this audit.

## 9. Human decision already recorded

The bounded visual-review evidence was produced previously. Do not republish it merely to ask the same questions again. The authoring-chat decision is now:

1. The pre-migration live Operator art is not the planned migration target.
2. The supplied 8-direction, 15-frame relaxed idle is the first real production animation that matches the volumetric realistic top-down 2.5D target.
3. The supplied 8-direction single-frame design sheet is the locked design reference for all future Operator animation authoring.
4. Legacy/projected art may remain transitional runtime fallback, but cannot close canonical 2.5D coverage.
5. The production plan should begin from the already-authored relaxed idle and build the remaining coherent families from the locked reference.

The audit closeout may preserve the old matrices as legacy evidence, but must not let them override this decision.
## Lean validation / no art mutation

Before handoff/closeout:

- capture hashes or `git status/diff` evidence proving no canonical/runtime Operator PNG changed;
- prove `operator_animation_catalog.generated.json` was read, not rewritten;
- verify all committed report JSON/Markdown/PNG paths exist;
- run `git diff --check`;
- do not run broad Godot/runtime suites unless the audit unexpectedly touches runtime code, which it should not.

## Handoff after recorded decision

- Next workstream: `operator-2-5d-canonical-visual-contract`
- Next packet state: `dependency-gated / ready-auto after this audit closes`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: `the human art-direction decision is now recorded; the canonical-contract packet owns hardening the exact design lock and first authored animation`
- Next action: `close this read-only audit on current main with the revised canonical-vs-legacy classification, release operator-art-agent, then allow the canonical visual-contract workstream to claim`
- Blockers or open questions: `none beyond deterministic audit closeout; do not reopen the already-recorded visual decision`


## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: yes
- Completion boundary satisfied: yes
- Acceptance satisfied: yes
- Superseded/legacy production path disposition: intentionally-preserved
- Evidence: `reports/operator_presentation/OPERATOR_2_5D_ANIMATION_VIABILITY.md`; `reports/operator_presentation/operator_2_5d_coverage.json`; three existing evidence matrices; `operator anim list unarmed --json`; report consistency check; `git diff --check`; `task_packet_index.py`; only report/packet/index/roadmap files changed, with no Operator art/runtime asset mutation.

## Execution Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: dispatch found an existing clean audit worktree from the prior run; the claim was resumed after inspecting its remote branch and current-main merge.
- Root cause / contributing factors: the packet was refreshed on main while a clean prior audit claim and branch remained active.
- Prevention / pipeline improvement: inspect dispatcher and workstream recovery state, then resume the existing clean branch and reread the packet before editing.
- Tooling / docs drift discovered: none
- Follow-up: operator-2-5d-canonical-visual-contract
- What worked: existing coverage JSON and pixel matrices preserved useful legacy evidence while exact user-locked generation metadata made canonical scope explicit.

## Next Handoff
- Next workstream: operator-2-5d-canonical-visual-contract
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: none
- Next action: claim the canonical visual-contract packet after this audit archives and releases `operator-art-agent`.
- Blockers or open questions: none
