# Operator 2.5D Animation Viability Audit

Status: **evidence complete; human visual decision pending**. This is a read-only audit. No art, runtime behavior, catalog, manifest, SpriteFrames, sockets, frame timings, or Asset V2 content was changed.

## Executive result

The current Operator is structurally usable as a 2.5D actor, but the art set is not yet a consistent directional benchmark. The strongest continuous set is unarmed idle, walk, and run, with 8 catalog sectors each. Those counts overstate usable coverage: several NE/NW/diagonal runtime identities contain only one modular body layer, and the production renderer projects selected missing/full-body sectors onto horizontal art. The actual runtime-pixel matrix makes those differences visible.

The active reachability ledger contains **69 live semantic action families** (78 LIVE ledger rows, including layer authorities) and **24 non-live base action families** excluded from the production backlog. The catalog has 446 semantic identities and the runtime manifest has 243 animation identities. Eight live actions have exact identities in all eight sectors; six other actions use OMNI. Most combat and posture families remain E/W, cardinal-only, or otherwise partial. See the machine inventory for every action, layer, frame count/size, FPS, and runtime path.

The Lords of Pain archive was not present in either prescribed local Downloads location. It was not fetched. That reference row is therefore unavailable; the Playable Knight reference remains in-repo. Knight sheet geometry is **1920x1024 RGBA**, with a visible repeated grid consistent with 16 frame columns by 8 direction rows (120x128 cells). Row-to-sector labels in the contact sheet are provisional because no accompanying direction metadata was found.

## Direction and composition findings

- Unarmed idle and walk have all eight catalog directions, but NE is lower-body-only; walk also has NW lower-body-only. In the live full-body route, missing idle/walk diagonal sectors project horizontally (NE/SE to E, NW/SW to W). These are projection cases, not authored diagonal full-body views.
- Unarmed run has eight exact catalog sectors and complete modular body pairs in each. Its full-body route preserves SE/SW and projects NE/NW horizontally.
- Unarmed relaxed/ready postures and block enter/hold/hit are currently E/W, with modular lower/upper body composition. The current dodge presentation family `dodge_fast_attack_01` is E/W; the shared dodge chain has broader sectors, but it is a distinct transition identity and should not be counted as authored dodge body coverage.
- Unarmed fast windup, fast recovery, and fast strike have eight complete modular body pairs. `fast_01` through `fast_04` and heavy are cardinal E/N/S/W. Weapon melee chains and block families are chiefly E/W. Ranged 2H fire/stance are partial; sidearm fire has six diagonal/cardinal sectors but no N/S.
- The E/W projection used for unarmed fast-chain requests when a requested modular pair is missing is explicit in `operator.gd`. Armed melee's semantic sector policy is E/W. The runtime deliberately maps selected sparse full-body locomotion sectors; its table preserves authored sectors and does not ask the selector to guess.

These are structural findings. Ground stability, volumetric continuity, silhouette readability at gameplay scale, acceptable projection, and redraw-versus-patch judgments need the requested human review of the three matrices. The report does not self-approve art direction.

## Provisional backlog and sizing

The numbers below are planning bounds for the next review, not approved production counts. A “sheet” means one authored direction strip for one runtime layer. Do not multiply every absent sector into new art: projection, OMNI, and gameplay readability can make additional art unnecessary.

| Rank | Family | Current coverage | Proposed minimum target | Preliminary action | Sheet estimate / note |
|---:|---|---|---|---|---|
| 1 | Unarmed idle/walk/run identity | 8 catalog sectors each; partial modular idle NE and walk NE/NW; full-body idle/walk project diagonals | Preserve current projections if visually acceptable; otherwise complete only missing modular sectors | Visual decision first; cleanup or directional completion | Up to 6 body-layer strips for the three incomplete diagonal pairs; run requires none structurally |
| 2 | Unarmed ready/relaxed + dodge/block transitions | Ready/relaxed and block E/W; dodge-fast E/W; several shared dodge transitions are broader | E/W may be sufficient for combat-facing actions; choose whether locomotion-facing dodge needs diagonal views | Decide projection vs directional additions, then patch transitions | Up to 12 sheets for six sectors across 2 body layers for ready; dodge up to 6 full-body strips if 8-way is required; block counts per selected action/layer |
| 3 | Melee 1H locomotion/posture | E/W posture; walk E/S/W; run E/N/S/W | Retain E/W combat posture; decide whether movement must match unarmed directional coverage | Directional completion only where mismatch is visible | Up to 10 body-layer strips for two missing walk sectors and four run sectors, depending on chosen layer authority |
| 4 | Melee 1H fast chain + guard | Fast chain and block are E/W | Keep horizontal combat-facing art if readable; otherwise add oblique combat views | Directional completion or targeted cleanup | 6 sectors x 2 body layers per three attacks = up to 36 strips; guards estimated separately after review |
| 5 | Ranged 2H stance/aim/fire/run | Stance/fire partial; aim E/SE/SW/W; run E/W; reload OMNI | Add only sectors that fail aim/weapon alignment in the review | Patch weapon alignment first; then directional completion | Variable; per action and layer, not one shared sheet count |
| 6 | Sidearm | Fire six sectors; draw four diagonal sectors | Confirm whether missing N/S and transitions are actually visible | Small targeted completion | At most 2 sectors for fire; draw gaps depend on runtime requested sectors |
| 7 | Heavy/reaction/special/death | Mixed E/W, S-only, cardinal, and intentional OMNI | Keep OMNI reactions/death where spatially neutral; repair only obvious orientation breaks | Cleanup or consciously projected | Defer low-frequency actions; no blanket 8-way target |

**Numeric planning buckets (pre-review):** viable unchanged: **8 action families have exact 8-sector identities**, though visual approval remains pending; cleanup-only: **0 proven** (machine checks cannot establish pixel cleanup); new directional sheets: **not approved**, with current upper bounds listed above; substantial redraw: **0 proven** (no action is labeled RED without human-confirmed spatial failure); acceptable projection/OMNI: **6 OMNI live families plus explicit sparse projection routes**, acceptance pending; legacy/catalog-only excluded: **24 action families** (13 SUPERSEDED, 19 DORMANT, 1 DORMANT_PENDING_INTERACTION_SUCCESS_CONTRACT ledger rows, consolidated by action). These buckets are intentionally evidence-bounded; human review is expected to revise the provisional decisions and counts.

Recommended first art slice: **unarmed locomotion + relaxed/ready identity**, preceded by a short human decision on whether the existing diagonals/projections meet the target. Total coherent slices: **7** in the rank order above. Slices 5 and 6 can proceed in parallel after shared registration/viewpoint rules are locked; slices 2–4 depend on the same reference and registration decision. Existing Workbench/Art Agent appears sufficient for reviewing and authoring directional families; no tooling blocker was found. Before mass production, confirm the Knight's exact direction-row mapping and secure/restore the user-selected LoP reference locally if that comparison is required.

## Elevation and grounding compatibility

`Operator.set_fake_elevation()` remains presentation-only: it updates a visual lift offset, raises z-index with elevation, and changes BlobShadow scale/alpha; authoritative XY/root grounding remains separate. Generic `IsometricVisualAnchor2D` owns an isolated visual root and sort anchor without affecting physics/collision/navigation. **Classification: compatible, but needs adapter/convergence in the Forum slice.** Operator's existing method distributes state to its body/recoil and shadow path, while the generic anchor owns a visual-root transform and sorting contract. The slice should choose one authority or a narrow adapter to prevent double lift/sort offsets; this audit changes neither system.

## Evidence and limitations

- Runtime pixels in locomotion/combat matrices are composed from generated runtime strips. Cells show first/middle/last frames; missing cells are marked rather than silently relabeled.
- Playable Knight primary sheets are inspected at 1920x1024 RGBA. Its row-sector metadata is not available in the packet, so N/NE/E markers are provisional.
- LoP local archive unavailable; no substitute was fetched.
- `operator_runtime_consumer_report.py --check` reports the committed consumer disposition file stale on claim-time main. The source-of-truth reachability ledger was used; refreshing that report is outside this read-only packet.
- No broad runtime suite was run. Validation is limited to catalog/status identity evidence, artifact consistency, PNG hashes, and whitespace checks.

## Visual review required

Please review the published matrices and decide:

1. Does current unarmed locomotion already meet the spatial/volumetric target?
2. Which current projections are visually acceptable versus obvious cheats?
3. Is 8-direction Operator art sufficient when LoP 16-angle continuity is used as a quality reference?
4. Which action families should be regenerated rather than patched?
5. Is the proposed ranked art backlog the right production order?

The workstream remains paused until the decision is recorded. Afterward, refresh `isometric-2-5d-forum-vertical-slice` against the approved art verdict and actual projection constraints.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac60342-02a4-83e9-b402-577faeed63ff
