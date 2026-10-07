# OPERATOR 2.5D ANIMATION VIABILITY AUDIT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-2-5d-animation-viability-audit`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `operator-art-agent, presentation-experiments`
- Kind: `implementation`
- Review: `none`
- Review rationale: `low-risk exemption: read-only evidence/report task; the required human visual review is the acceptance gate`
- Visual review: `required`
- Reviewed main: `df80ee151473724aa524a1d24c36cd7d32389bd2`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Goal: Determine whether the current production-reachable Operator animation art is viable for CUSTODIAN's fixed-isometric 2.5D contract, quantify exactly where directional/viewpoint/registration/composition gaps exist, and produce a ranked art backlog before the Forum 2.5D vertical slice treats the Operator as an approved visual benchmark.
- Completion boundary: Produce a structural coverage inventory, runtime-pixel visual matrices, a reference comparison against the Lords of Pain 16-angle goalpost and the repository Playable Knight, and a final viability report that classifies each production-reachable animation family as keep / cleanup / directional completion / redraw / consciously projected. Do not modify, publish, ingest, regenerate, normalize, or replace any Operator art.
- Current measured state: the Operator runtime architecture is compatible with 2.5D presentation, but the art set is uneven. The generated semantic catalog contains broad 8-sector unarmed locomotion coverage, while many combat/posture/armed actions are E/W, partial, S-only, omni, or caller-projected. `operator.gd` already has presentation-only `set_fake_elevation()` behavior that lifts visual layers while leaving authoritative XY/shadow grounding separate. The Playable Knight reference exists in-repo at `custodian/dev/test_sprites/Knight/`. The user-selected Lords of Pain reference is expected locally in Downloads and must remain reference-only.
- Evidence: `custodian/content/data/operator/generated/operator_animation_catalog.generated.json`; `custodian/game/actors/operator/animations/operator_animation_selector.gd`; `custodian/game/actors/operator/operator.gd`; `custodian/game/actors/operator/presentation/`; `custodian/tools/operator/`; `custodian/content/data/operator/authoring/operator_art_profile.json`; `custodian/dev/test_sprites/Knight/`; `design/01_systems/ISOMETRIC_2_5D_PRESENTATION_CONTRACT.md`.
- Task-specific authority: live runtime/catalog truth on claim-time main; the 2.5D presentation contract; the accepted Operator registration profile; existing Operator Workbench/preview/motion APIs.
- Work surface: read-only analysis of Operator canonical/runtime art plus durable reports under `reports/operator_presentation/`; bounded roadmap/index updates only.
- Change: evidence and planning truth only. No production art/runtime mutation.
- Preserve: all canonical/runtime Operator PNGs, manifests, SpriteFrames, sockets, frame timings, gameplay animation selection, Operator runtime behavior, Asset Pipeline V2 families, source-work/inbox state, and both external visual references.
- Non-goals: no new Operator art; no 16-direction Operator mandate; no frame-count retuning; no combat balance changes; no runtime fallback rewrite; no Workbench feature work; no Asset V2 ingest; no copying LoP/Playable Knight pixels into CUSTODIAN production art; no Forum vertical-slice implementation.
- Acceptance: every production-reachable Operator action is separated from legacy/catalog-only residue; high-frequency animation families receive actual runtime-pixel visual review; directional/layer gaps are counted; current projection/fallback policy is recorded; required art work is ranked and counted; the human review packet contains enough visual evidence to decide what survives unchanged; source/runtime art hashes remain untouched.
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

## 9. Visual review handoff

Because the final classification is partly art-direction judgment, this packet cannot close before human review.

Publish the bounded evidence through the repository visual-review workflow:

`custodian/tools/iteration/publish_review_artifacts.py`

Use exactly this authoring chat:

https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb

Publish only the three matrices plus the concise viability report, not the complete raw Operator art tree.

Reviewer questions:

1. Does current unarmed locomotion already meet the spatial/volumetric target?
2. Which current projections are visually acceptable versus obvious cheats?
3. Is 8-direction Operator art sufficient when LoP 16-angle continuity is used as a quality reference?
4. Which action families should be regenerated rather than patched?
5. Is the proposed ranked art backlog the right production order?

Pause the workstream at that boundary. Record the user's decision before completion.

## Lean validation / no art mutation

Before handoff/closeout:

- capture hashes or `git status/diff` evidence proving no canonical/runtime Operator PNG changed;
- prove `operator_animation_catalog.generated.json` was read, not rewritten;
- verify all committed report JSON/Markdown/PNG paths exist;
- run `git diff --check`;
- do not run broad Godot/runtime suites unless the audit unexpectedly touches runtime code, which it should not.

## Handoff after human decision

- Next workstream: `isometric-2-5d-forum-vertical-slice`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: `Forum slice must incorporate the approved Operator viability verdict, the actual art backlog, and any required short-term projection/registration constraints rather than assuming the current Operator art is production-ready.`
- Next action: return the audit report/matrices to this chat, lock the first Operator art-production tranche, then refresh the Forum packet against current main.
- Blockers or open questions: `human visual decision required before Forum implementation`.
