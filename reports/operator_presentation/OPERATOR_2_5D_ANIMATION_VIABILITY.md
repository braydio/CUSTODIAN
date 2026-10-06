# OPERATOR 2.5D ANIMATION VIABILITY AUDIT

Workstream: `operator-2-5d-animation-viability-audit` · Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff

Generated 2026-10-06 against claim-time main. Read-only audit: no Operator art, catalog, manifest or runtime resource was changed (hash proof in section 9). Companion files: `operator_2_5d_coverage.json`, `operator_2_5d_locomotion_matrix.png`, `operator_2_5d_combat_matrix.png`, `operator_2_5d_reference_matrix.png`.

**Status: paused for human visual review.** Verdicts below are an evidence-backed proposal. Subjective art-direction calls (which look is canonical, which projections are acceptable) are the reviewer's to make, and the one reference that cannot be shown (Lords of Pain) is called out in section 2.

## 1. Answer

The Operator **runtime architecture** can carry the 2.5D contract; the Operator **art set cannot yet be treated as the visual benchmark**.

- Of 72 production-reachable action families: **4 GREEN, 1 YELLOW, 45 ORANGE, 5 RED, 17 GRAY.** Only the unarmed fast windup/recovery pair and the two dodge-wind clips are clean today.
- The biggest gap is **directional**, not polish: 48 of the 50 ORANGE/RED families show an authored strip under a different requested facing (mostly E/W art reused for N, NE, SE, S, SW and NW). All melee 1H posture, walk, attacks and guard, the unarmed ready/relaxed posture, and the unarmed block family are E/W-only.
- The second gap is **identity**: the live art mixes at least three character renders (section 4.1). A fixed-isometric 2.5D benchmark needs one.
- Proposed minimum target (section 7) is **332 new directional sheets to author plus 194 derivable by the existing mirror promotion, and 21 sheets to redraw** (against 460 sheets composed live today). Restricting to high-frequency ORANGE/RED families, the first-priority subset is **244 new authored sheets and 10 redraws**.
- The Operator's existing `set_fake_elevation()` is **compatible but needs adapter/convergence in the Forum slice** (section 8).

## 2. Evidence base and limits

| Item | State |
| --- | --- |
| Generated catalog | Read, never rewritten. sha256 `9d3305594bd182aa…` |
| Reachability truth | `custodian/content/data/operator/operator_animation_reachability.json` (human-audited LIVE/DORMANT/SUPERSEDED table) plus the projection tables in `operator.gd` |
| Pixels graded | Every production-reachable family was rendered from runtime sheets at the sector the runtime resolves (3 frames each) into the locomotion and combat matrices and visually reviewed |
| Objective measures | Per sector: median body height, foot baseline vs the accepted registration `ground_y=85` on 96 px frames, within-sheet baseline range. Stored under `measures` in the JSON |
| **Lords of Pain reference** | **Unavailable.** Neither `~/Downloads/lop_knight_N-NNE-NE-ENE-E_reference.zip` nor `~/Downloads/LordsOfPain.zip` exists on this machine. Nothing was fetched or substituted. The LoP row of the reference matrix is a labelled placeholder. This is the only visual-review blocker. |
| Playable Knight | Real, in-repo, verified geometry: 1920×1024 sheets = 15 columns × 8 rows of 128 px frames. Row-to-direction order for rows 0-5 (NW, N, NE, E, SE, S) comes from the retired Knight test-skin code (removed in git `1ea8513d4`); rows 6-7 (SW, W) are inferred. The N→NE→E rotation visible in the matrix is consistent with it, but it is not pixel-proven |
| Composition order | cape, full-body or lower+upper, weapon, fx, centred on a shared canvas. Approximate: it was reconstructed from the catalog, not captured from the running game. Layer z-order inside the live actor may differ |
| Palette signature | Heuristic classifier (cyan ratio, gold-trim ratio), used only to point at identity differences, which were then confirmed by eye |

## 3. Structural inventory

Source: the generated catalog has 279 semantic action families (446 direction rows).

| Group | Families | Notes |
| --- | ---: | --- |
| Production-reachable | 72 | Reachability LIVE and at least one live body/overlay layer. This is the only group counted as art work |
| Projection-supported (subset of the above) | 58 | Runtime maps requested sectors onto fewer authored sectors |
| Legacy / catalog-only | 178 | `legacy_*` identities, all omni, none reachable. 179 sheets excluded |
| Superseded | 13 | No runtime consumer |
| Dormant | 12 | Materialised preservation art or pending contract (for example heavy guard, `fire_walk_01`, `block_*_02`) |
| LIVE action with head layer only | 4 | `shared/locomotion/{idle,idle_hitreact,run,walk}_01`: reachability marks the action LIVE but the only sheets are the retired head layer. See 4.5 |
| Dev/reference-only | 1 | `custodian/dev/test_sprites/Knight/` |

The 178 legacy families were not allowed to inflate the estimate. A further 75 sheets sit in superseded/dormant/head-only families.

Full per-family detail (authored directions, layers per direction, frame counts, frame size, fps/loop, source and runtime paths, projection per sector, projection policy) is in `operator_2_5d_coverage.json`.

## 4. Findings

### 4.1 The live art is three different characters
By palette signature and visual review, three renders are in production:

- **L1 gray-armored hood** (newest modular sets): unarmed fast windup/strike/recovery, ranged stance/aim/fire, sidearm, dodge chain/windup, `idle_relaxed`, and the diagonals of locomotion.
- **L2 black-gold hooded robe**: unarmed ready posture, fast_01-04 chain, block/parry, the whole melee 1H family, and the E/S/W sectors of unarmed idle/walk/run.
- **L3 cyan-visor armor**: unarmed `heavy_01`, `light_hitreact_01`, ranged_2h `run_01` and `reload_01`, melee heavy windup, and the retired full-body fallback sheets.

Inside a single action the axis sectors (E/S/W) and the diagonals can come from different renders (unarmed idle, walk and run), which is visible in the locomotion matrix. Which look is canonical is a **human decision** (Q1 below); this audit does not assume it. The verdicts treat the spatial contract only (direction, pitch, volume, registration), and treat L3 as RED because it is a different character, not because it is old. If the reviewer additionally demands one look everywhere, add the sheets of the 36 families that contain an L2 sector (234 composed sheets, an upper bound because some are mixed) to the redraw column: that moves the redraw count from 21 unique sheets to roughly 230.

### 4.2 Projection is the dominant policy, and most of it is a cheat
Runtime policy lives in `operator.gd` tables (`MODULAR_BODY_AUTHORED_SECTORS`, `FULL_BODY_AUTHORED_SECTORS`, `RANGED_2H_*`, `SIDEARM_AUTHORED_SECTORS`) plus the E/W reduction `_reduced_horizontal_sector` (x<0 → W else E) and `unarmed_posture_presentation.authored_sector`. The selector itself is exact-only and falls back to the temporary SOUTH identity with a warning. Of 58 projected families, 21 have an explicit documented table and 38 rely on the implicit E/W reduction or the SOUTH fallback with no table entry. Code comments themselves record several of these as debt (for example the heavy windup/fast-recovery tables say "if these are conceptually directionless … republish as OMNI").

### 4.3 Objective registration and scale measures
Against the accepted guide (`ground_y` 85, anchor y 84 on 96 px frames):

- Most families sit at baseline 84±1 in every sector (GREEN evidence).
- Outliers: unarmed `run_01` sector baselines 82-89 (SE/SW at 89), S bounce range 9 px, and heights 63-73 px; unarmed `fast_strike_01` baselines 84-90; unarmed `heavy_01` heights 56 vs 66 px; melee `run_01` N 70 px vs 63 px elsewhere.
- Scale drift inside one action: unarmed `walk_01` SE/SW 55 px vs E/W 75 px; unarmed `idle_01` S 54 px vs 70-71 px.

### 4.4 Specific runtime-visible defects worth verifying in game
1. **Unarmed idle S and walk SE/SW compose to a headless torso** (lower+upper only; the head art exists only as dormant `shared/locomotion/*` head sheets and `ACTIVE_MODULAR_HEAD = false`). Confirm in the running game whether a head is drawn from another source.
2. **Ranged `fire_01` at NE, S and NW plays no upper/weapon fire layer at all.** The runtime asks first and plays nothing, so firing toward those sectors has no fire presentation.
3. **`shared/transition/dodge_01` has only N and S**; every other direction falls back to the south-facing clip.
4. **Unarmed ready and melee posture show E/W art unchanged for N and S**, so a character facing away from the camera still shows a front/side guard pose.

### 4.5 Reachability drift
`shared/locomotion/*_01` is marked LIVE at action level while only the dormant head layer exists in the catalog. 54 retired `full_body` fallback sheets are still shipped alongside modular compositions that supersede them (for unarmed idle/walk/run they are the cyan L3 render). They are not counted as art work, but they are a latent identity break if a modular layer ever fails to resolve (the runtime then falls back to them).

### 4.6 Reference comparison (Playable Knight)
The Knight shows the target qualities: one pitch across N→NE→E, stable foot contact and a cast ground shadow that rotates with the body, and large melee arcs that keep directional volume. The Operator's L1 sets (unarmed windup/strike/recovery, ranged stance/aim/fire) are closest to that standard, with clear near/far limb and cloak overlap on N/NE/NW. The E/W-only sets are where the Operator falls furthest below it: the same flat side view is reused for every direction. LoP 16-angle continuity could not be compared (section 2); the 8-sector question (Q3) therefore remains open.

## 5. Current projection and fallback policy (recorded)
1. Selector: exact → temporary SOUTH (warns, counts) → error. It does not project.
2. Callers own projection through the per-action tables above. Unlisted horizontal sparsity defaults to E/W reduction; unarmed posture always projects to E/W; heavy windup and fast recovery project every sector onto the single authored S.
3. Optional layers (fx, cape) are asked before resolving; absent sectors simply draw nothing (this is why ranged `fire_01` has no fire layer at NE/S/NW).
4. `OMNI` identities (death, dodge charge feedback, reload) are single-presentation by design.

## 6. Verdict classification

| Verdict | Families | Meaning here |
| --- | ---: | --- |
| GREEN | 4 | Viable unchanged |
| YELLOW | 1 | Registration/cleanup only (`unarmed/attack/fast_strike_01`) |
| ORANGE | 45 | Missing directional art or substantial directional redraw |
| RED | 5 | Different character/concept and pitch; reauthor |
| GRAY | 17 | Consciously projected or OMNI; no new art recommended for the action itself |

Reason tags used: `missing_direction`, `missing_layer`, `projection_visible`, `pitch_mismatch`, `volume_flat`, `registration_drift`, `scale_drift`, `weapon_alignment`, `acceptable_omni` (and `legacy_excluded` for the excluded groups). `modular_seam`, `silhouette_break` and `fx_alignment` were not asserted from this evidence; the matrices are the place a reviewer would judge them.

## 7. Backlog numbers

Target conventions (a proposal, minimum coverage that keeps the 2.5D read; the reviewer may reduce): **P5** = N, NE, E, SE, S authored with SW/W/NW produced by the existing mirror promotion; **P8** = all eight (mirror for the W side); **P4** = N, E, S authored, W by mirror; **as authored** = no new art. Sheets are counted per sector per composed layer (lower, upper, weapon, fx or full-body separately).

| Bucket | Count |
| --- | ---: |
| Sheets composed live today (production-reachable) | 460 |
| Existing sheets viable unchanged (GREEN families) | 48 |
| Existing sheets needing cleanup only (YELLOW) | 24 |
| Existing sheets in GRAY families (projection/OMNI acceptable) | 80 |
| Existing sheets inside ORANGE/RED families (kept unless listed under redo) | 308 |
| **New directional sheets required** | **526** (332 drawn + 194 mirror-derived) |
| **Existing sheets needing substantial redraw** | **29** (21 unique; the rest are mirror pairs) |
| Actions where current projection/OMNI is acceptable (GRAY) | 17 |
| Legacy/catalog-only identities excluded | 178 families (179 sheets) |

Redraw counts are deliberately conservative: only sheets with a measured or visible spatial defect (unarmed idle S, walk SE/SW, run E/S/W) plus the RED families' existing sheets. They do not include harmonising the L2 families to a single look (4.1).

Mirror-derived sheets assume the existing Workbench mirror promotion (E↔W, NE↔NW, SE↔SW) is acceptable for handedness and prop asymmetry; the runtime already treats E/W that way. N and S cannot be mirrored.

### Ranked backlog (one row per production-reachable action family)

Ranking: verdict severity, then gameplay frequency, then size of the gap. "Nm new" means N sheets drawn plus M mirror-derived.

| rank | profile/group/action | frequency | authored sectors | target sectors | missing/new sectors | layers affected | verdict | estimated sheets | reason | slice |
| ---: | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | ranged_2h/locomotion/run_01 | high | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | full_body,weapon | RED | 8+4m new / 4 redo | E/W-only cyan-visor full-body run, a different character render from the ranged stance/aim/fire set. | E |
| 2 | unarmed/attack/heavy_01 | medium | N,E,S,W | N,NE,E,SE,S | NE,SE,SW,NW | full_body,fx | RED | 4+4m new / 8 redo | N/E/W show a cyan-visor armored figure; this is not the hooded Operator and reads at a different pitch/height (56 px vs 66 px N); diagonals reuse E. | G |
| 3 | unarmed/reaction/light_hitreact_01 | medium | S | N,E,S | N,E,W | full_body,fx | RED | 4+2m new / 2 redo | South-only cyan-visor art, a different character render from the hooded Operator. | G |
| 4 | ranged_2h/cosmetic/reload_01 | medium | OMNI | as authored | - | full_body | RED | 0+0m new / 1 redo | Omni cyan-visor body, a different render from the ranged modular set. | E |
| 5 | melee_1h_heavy/attack/heavy_windup_01 | low | S | N,E,S | N,E,W | full_body,weapon | RED | 4+2m new / 2 redo | South-only cyan-visor art projected onto every sector via a documented table. | G |
| 6 | melee_1h/attack/fast_01 | high | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | fx,lower_body,upper_body | ORANGE | 12+6m new / 0 redo | E/W only; N, NE, SE, S, SW, NW all play an E/W strip. | D |
| 7 | melee_1h/attack/fast_02 | high | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | fx,lower_body,upper_body | ORANGE | 12+6m new / 0 redo | E/W only; N, NE, SE, S, SW, NW all play an E/W strip. | D |
| 8 | melee_1h/attack/fast_03 | high | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | fx,lower_body,upper_body | ORANGE | 12+6m new / 0 redo | E/W only; N, NE, SE, S, SW, NW all play an E/W strip. | D |
| 9 | ranged_2h/posture/relaxed_01 | high | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | lower_body,upper_body,weapon | ORANGE | 12+6m new / 0 redo | E/W only; every other facing reuses it. | E |
| 10 | unarmed/defense/block_hold_01 | high | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | fx,lower_body,upper_body | ORANGE | 12+6m new / 0 redo | Guard is held while the player faces any direction; E/W art is shown for N, NE, SE, S, SW, NW. | B |
| 11 | ranged_2h/cosmetic/fire_01 | high | N,E,SE,SW,W | N,NE,E,SE,S,SW,W,NW | N,NE,S,NW | fx,lower_body,upper_body,weapon | ORANGE | 9+8m new / 0 redo | N/E/SE/SW/W authored; NE, S and NW play no upper/weapon fire layer at all (runtime asks first and plays nothing). | E |
| 12 | ranged_2h/cosmetic/aim_01 | high | E,SE,SW,W | N,NE,E,SE,S,SW,W,NW | N,NE,S,NW | lower_body,upper_body,weapon | ORANGE | 9+6m new / 0 redo | E/SE/SW/W authored; N, NE, S and NW reuse E/W. | E |
| 13 | melee_1h/defense/block_enter_01 | high | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | lower_body,upper_body | ORANGE | 8+4m new / 0 redo | Guard is held while the player faces any direction; E/W art is shown for N, NE, SE, S, SW, NW. | D |
| 14 | melee_1h/defense/block_hit_01 | high | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | lower_body,upper_body | ORANGE | 8+4m new / 0 redo | Guard is held while the player faces any direction; E/W art is shown for N, NE, SE, S, SW, NW. | D |
| 15 | melee_1h/defense/block_loop_01 | high | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | lower_body,upper_body | ORANGE | 8+4m new / 0 redo | Guard is held while the player faces any direction; E/W art is shown for N, NE, SE, S, SW, NW. | D |
| 16 | melee_1h/posture/draw_01 | high | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | lower_body,upper_body | ORANGE | 8+4m new / 0 redo | E/W-only posture and transition art shown for every other facing. | C |
| 17 | melee_1h/posture/idle_ready_01 | high | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | lower_body,upper_body | ORANGE | 8+4m new / 0 redo | E/W-only posture and transition art shown for every other facing. | C |
| 18 | melee_1h/posture/idle_relaxed_01 | high | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | lower_body,upper_body | ORANGE | 8+4m new / 0 redo | E/W-only posture and transition art shown for every other facing. | C |
| 19 | melee_1h/posture/sheathe_01 | high | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | lower_body,upper_body | ORANGE | 8+4m new / 0 redo | E/W-only posture and transition art shown for every other facing. | C |
| 20 | melee_1h/transition/idle_fast_transition_01 | high | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | lower_body,upper_body | ORANGE | 8+4m new / 0 redo | E/W-only posture and transition art shown for every other facing. | C |
| 21 | melee_1h/transition/ready_to_relaxed_01 | high | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | lower_body,upper_body | ORANGE | 8+4m new / 0 redo | E/W-only posture and transition art shown for every other facing. | C |
| 22 | melee_1h/transition/relaxed_to_ready_01 | high | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | lower_body,upper_body | ORANGE | 8+4m new / 0 redo | E/W-only posture and transition art shown for every other facing. | C |
| 23 | shared/transition/dodge_01 | high | N,S | N,NE,E,SE,S | NE,E,SE,SW,W,NW | full_body,fx | ORANGE | 6+6m new / 0 redo | Only N and S are authored; every other request falls back to the temporary SOUTH identity (selector fallback), so a dodge toward E plays the south-facing clip. | B |
| 24 | unarmed/attack/fast_01 | high | N,E,S,W | N,NE,E,SE,S | NE,SE,SW,NW | fx,lower_body,upper_body | ORANGE | 6+6m new / 0 redo | N/S/E/W authored; diagonals reuse E/W strips; N/S figures are visibly larger than E/W. Likely consolidation candidate with the 8-sector windup/strike/recovery trio. | B |
| 25 | unarmed/attack/fast_02 | high | N,E,S,W | N,NE,E,SE,S | NE,SE,SW,NW | fx,lower_body,upper_body | ORANGE | 6+6m new / 0 redo | N/S/E/W authored; diagonals reuse E/W strips; N/S figures are visibly larger than E/W. Likely consolidation candidate with the 8-sector windup/strike/recovery trio. | B |
| 26 | unarmed/attack/fast_03 | high | N,E,S,W | N,NE,E,SE,S | NE,SE,SW,NW | fx,lower_body,upper_body | ORANGE | 6+6m new / 0 redo | N/S/E/W authored; diagonals reuse E/W strips; N/S figures are visibly larger than E/W. Likely consolidation candidate with the 8-sector windup/strike/recovery trio. | B |
| 27 | unarmed/attack/fast_04 | high | N,E,S,W | N,NE,E,SE,S | NE,SE,SW,NW | fx,lower_body,upper_body | ORANGE | 6+6m new / 0 redo | N/S/E/W authored; diagonals reuse E/W strips; N/S figures are visibly larger than E/W. Likely consolidation candidate with the 8-sector windup/strike/recovery trio. | B |
| 28 | unarmed/defense/block_enter_01 | high | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | lower_body,upper_body | ORANGE | 8+4m new / 0 redo | Guard is held while the player faces any direction; E/W art is shown for N, NE, SE, S, SW, NW. | B |
| 29 | unarmed/defense/block_hit_01 | high | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | lower_body,upper_body | ORANGE | 8+4m new / 0 redo | Guard is held while the player faces any direction; E/W art is shown for N, NE, SE, S, SW, NW. | B |
| 30 | unarmed/posture/idle_ready_01 | high | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | lower_body,upper_body | ORANGE | 8+4m new / 0 redo | E/W-only art is shown unchanged for N, NE, SE, S, SW and NW; no volume change with facing (runtime code states none was authored). | A |
| 31 | unarmed/posture/idle_relaxed_01 | high | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | lower_body,upper_body | ORANGE | 8+4m new / 0 redo | E/W-only art is shown unchanged for N, NE, SE, S, SW and NW; no volume change with facing (runtime code states none was authored). | A |
| 32 | melee_1h/locomotion/walk_01 | high | E,S,W | N,NE,E,SE,S | N,NE,SE,SW,NW | lower_body,upper_body | ORANGE | 6+4m new / 0 redo | E/S/W authored; N and all diagonals are missing and show E/W. | C |
| 33 | melee_1h/locomotion/run_01 | high | N,E,S,W | N,NE,E,SE,S | NE,SE,SW,NW | lower_body,upper_body | ORANGE | 4+4m new / 0 redo | N/E/S/W authored; diagonals reuse E/W; N baseline/height differ from the rest (N 70 px, others 63). | C |
| 34 | unarmed/locomotion/walk_01 | high | N,NE,E,SE,S,SW,W,NW | N,NE,E,SE,S,SW,W,NW | NE,NW | upper_body | ORANGE | 1+2m new / 4 redo | SE/SW compose 55 px tall against 68-75 px elsewhere and read as a different, headless torso; NE/NW have lower only and borrow N upper. | A |
| 35 | ranged_2h/posture/stance_01 | high | N,NE,E,SE,SW,W,NW | N,NE,E,SE,S,SW,W,NW | NE,S,NW | lower_body,upper_body,weapon | ORANGE | 4+2m new / 0 redo | Best coverage in the set (N/E/SE/SW/W full; NE/NW upper+weapon only); S is missing and NE/NW lower borrow E/W. | E |
| 36 | unarmed/locomotion/run_01 | high | N,NE,E,SE,S,SW,W,NW | as authored | - | lower_body,upper_body | ORANGE | 0+0m new / 6 redo | All 8 sectors authored, but E/S/W and the diagonals read as two different renders; median height 63-73 px and foot baseline 82-89 vs accepted ground_y 85; S bounce range 9 px. | A |
| 37 | unarmed/locomotion/idle_01 | high | N,NE,E,SE,S,SW,W,NW | N,NE,E,SE,S,SW,W,NW | NE | upper_body | ORANGE | 1+0m new / 2 redo | S composes to a headless torso (32 px shorter than E; head layers exist only as dormant shared/locomotion head sheets); NE has lower only and borrows N upper. Other sectors read as one body. | A |
| 38 | unarmed/defense/parry_01 | medium | N,E,W | N,NE,E,SE,S | NE,SE,S,SW,NW | fx,lower_body,upper_body | ORANGE | 9+6m new / 0 redo | N/E/W authored; SE/S/SW/NE/NW reuse E/W. | B |
| 39 | melee_1h_heavy/attack/fast_01 | medium | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | full_body,fx | ORANGE | 8+4m new / 0 redo | E/W-only full-body heavy-weapon chain. | D |
| 40 | melee_1h_heavy/attack/fast_02 | medium | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | full_body,fx | ORANGE | 8+4m new / 0 redo | E/W-only full-body heavy-weapon chain. | D |
| 41 | melee_1h_heavy/attack/fast_03 | medium | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | full_body,fx | ORANGE | 8+4m new / 0 redo | E/W-only full-body heavy-weapon chain. | D |
| 42 | unarmed/transition/ready_to_relaxed_01 | medium | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | lower_body,upper_body | ORANGE | 8+4m new / 0 redo | Brief bridge clips, E/W only; they must follow the posture decision or they will pop against re-authored posture. | A |
| 43 | unarmed/transition/relaxed_to_ready_01 | medium | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | lower_body,upper_body | ORANGE | 8+4m new / 0 redo | Brief bridge clips, E/W only; they must follow the posture decision or they will pop against re-authored posture. | A |
| 44 | melee_1h_dagger/attack/fast_02 | medium | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | weapon | ORANGE | 4+2m new / 0 redo | Weapon-only overlay that must follow the melee_1h body; one weapon sheet per new body sector. | D |
| 45 | melee_1h_dagger/posture/draw_01 | medium | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | weapon | ORANGE | 4+2m new / 0 redo | Weapon-only overlay that must follow the melee_1h body; one weapon sheet per new body sector. | D |
| 46 | melee_1h_dagger/posture/idle_ready_01 | medium | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | weapon | ORANGE | 4+2m new / 0 redo | Weapon-only overlay that must follow the melee_1h body; one weapon sheet per new body sector. | D |
| 47 | melee_1h_dagger/posture/idle_relaxed_01 | medium | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | weapon | ORANGE | 4+2m new / 0 redo | Weapon-only overlay that must follow the melee_1h body; one weapon sheet per new body sector. | D |
| 48 | melee_1h_dagger/posture/sheathe_01 | medium | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | weapon | ORANGE | 4+2m new / 0 redo | Weapon-only overlay that must follow the melee_1h body; one weapon sheet per new body sector. | D |
| 49 | melee_1h_dagger/transition/idle_fast_transition_01 | medium | E,W | N,NE,E,SE,S | N,NE,SE,S,SW,NW | weapon | ORANGE | 4+2m new / 0 redo | Weapon-only overlay that must follow the melee_1h body; one weapon sheet per new body sector. | D |
| 50 | melee_1h_dagger/locomotion/run_01 | medium | E,S,W | N,NE,E,SE,S | N,NE,SE,SW,NW | weapon | ORANGE | 3+2m new / 0 redo | Weapon-only overlay that must follow the melee_1h body; one weapon sheet per new body sector. | D |
| 51 | unarmed/attack/fast_strike_01 | high | N,NE,E,SE,S,SW,W,NW | as authored | - | lower_body,upper_body,fx | YELLOW | 0+0m new / 0 redo | 8 sectors authored, one look; sector baselines span 84-90 px and heights 68-79 px. Part may be intentional lunge motion; needs a registration pass, not new art. | B |
| 52 | shared/attack/dodge_charge_windup_01 | high | N,NE,E,SE,S,SW,W,NW | as authored | - | full_body | GREEN | 0+0m new / 0 redo | 8 sectors authored, one look, uniform height (57 px) and baseline 84. | B |
| 53 | shared/transition/dodge_chain_link_01 | high | N,NE,E,SE,S,SW,W,NW | as authored | - | full_body | GREEN | 0+0m new / 0 redo | 8 sectors authored, one look, uniform height (57 px) and baseline 84. | B |
| 54 | unarmed/attack/fast_recovery_01 | high | N,NE,E,SE,S,SW,W,NW | as authored | - | lower_body,upper_body | GREEN | 0+0m new / 0 redo | 8 sectors authored in one look; height 68-74 px; baseline 86 (within 1 px of ground_y 85) in every sector. | B |
| 55 | unarmed/attack/fast_windup_01 | high | N,NE,E,SE,S,SW,W,NW | as authored | - | lower_body,upper_body | GREEN | 0+0m new / 0 redo | 8 sectors authored in one look; height 68-74 px; baseline 86 (within 1 px of ground_y 85) in every sector. | B |
| 56 | sidearm/cosmetic/fire_sidearm_01 | medium | NE,E,SE,SW,W,NW | as authored | - | lower_body,upper_body,weapon,fx | GRAY | 0+0m new / 0 redo | Four diagonal sectors; N/E/S/W map to the nearest diagonal by a documented table. Quality of the 45-degree error is a reviewer decision. | F |
| 57 | sidearm/posture/draw_sidearm_01 | medium | NE,SE,SW,NW | as authored | - | lower_body,upper_body,weapon,fx | GRAY | 0+0m new / 0 redo | Four diagonal sectors; N/E/S/W map to the nearest diagonal by a documented table. Quality of the 45-degree error is a reviewer decision. | F |
| 58 | unarmed/locomotion/idle_hitreact_01 | medium | N,S | as authored | - | lower_body,upper_body | GRAY | 0+0m new / 0 redo | N/S authored with a documented table (C2a-R3 decision); brief clip. | G |
| 59 | unarmed/attack/dodge_fast_attack_01 | low | E,W | as authored | - | full_body,fx | GRAY | 0+0m new / 0 redo | Special/low-frequency actions with E/W(+S) coverage; projection is conscious. Reviewer should confirm. | G |
| 60 | unarmed/attack/parry_recovery_01 | low | E,W | as authored | - | lower_body,upper_body,fx | GRAY | 0+0m new / 0 redo | Brief E/W recovery after a parry; documented table; no new art recommended for this action alone. | B |
| 61 | unarmed/cosmetic/critical_execution_01 | low | E,S,W | as authored | - | full_body,fx | GRAY | 0+0m new / 0 redo | Special/low-frequency actions with E/W(+S) coverage; projection is conscious. Reviewer should confirm. | G |
| 62 | unarmed/cosmetic/critical_hitspark_01 | low | E,W | as authored | - | fx | GRAY | 0+0m new / 0 redo | Short overlay/effect clips; E/W is sufficient. | G |
| 63 | unarmed/cosmetic/falcon_reversal_01 | low | E,W | as authored | - | full_body,fx | GRAY | 0+0m new / 0 redo | Special/low-frequency actions with E/W(+S) coverage; projection is conscious. Reviewer should confirm. | G |
| 64 | unarmed/defense/parry_miss_01 | low | E,W | as authored | - | full_body | GRAY | 0+0m new / 0 redo | Short overlay/effect clips; E/W is sufficient. | G |
| 65 | unarmed/defense/parry_success_01 | low | E,W | as authored | - | fx | GRAY | 0+0m new / 0 redo | Short overlay/effect clips; E/W is sufficient. | G |
| 66 | unarmed/interaction/field_patch_use_01 | low | N,E,W | as authored | - | lower_body,upper_body,fx | GRAY | 0+0m new / 0 redo | Special/low-frequency actions with E/W(+S) coverage; projection is conscious. Reviewer should confirm. | G |
| 67 | unarmed/posture/dodge_charge_ready_01 | low | OMNI | as authored | - | fx | GRAY | 0+0m new / 0 redo | Single omni presentation by design. | G |
| 68 | unarmed/reaction/bodyslam_knockdown_01 | low | E,W | as authored | - | full_body,fx | GRAY | 0+0m new / 0 redo | Special/low-frequency actions with E/W(+S) coverage; projection is conscious. Reviewer should confirm. | G |
| 69 | unarmed/reaction/death_01 | low | OMNI | as authored | - | full_body | GRAY | 0+0m new / 0 redo | Single omni presentation by design. | G |
| 70 | unarmed/transition/dodge_chain_release_01 | low | OMNI | as authored | - | fx | GRAY | 0+0m new / 0 redo | Single omni presentation by design. | G |
| 71 | unarmed/transition/dodge_charge_meter_01 | low | OMNI | as authored | - | fx | GRAY | 0+0m new / 0 redo | Single omni presentation by design. | G |
| 72 | unarmed/transition/dodge_charge_release_01 | low | OMNI | as authored | - | fx | GRAY | 0+0m new / 0 redo | Single omni presentation by design. | G |

## 8. Existing Operator elevation versus `IsometricVisualAnchor2D`

`operator.gd` already owns presentation-only elevation: `set_fake_elevation(value)` sets `fake_elevation` (clamped ≥ 0), derives `_fake_elevation_visual_offset = (0, -fake_elevation × 0.5)` (`fake_elevation_visual_lift_factor`), applies it to every body, weapon and FX sprite position individually, bumps the actor `z_index` by `round(fake_elevation × 0.08)`, and scales/fades the `BlobShadow` (to 0.65 scale and 0.55 alpha over 24 elevation units). Authoritative XY, collision and the ground root are untouched.

`IsometricVisualAnchor2D` carries the same idea in a reusable form: the node's position is the ground contact, elevation offsets only the child `VisualRoot` by `-px`, z-order comes from the profile band, and it owns no shadow, physics or collision.

Semantics agree (ground root fixed, only the visual lifts), but they differ in unit (elevation units × 0.5 vs pixels), in z ownership (the Operator mutates its own `z_index` by elevation, the anchor derives z from the band profile, so both cannot drive it), in shadow ownership (Operator-owned `BlobShadow` vs none) and in mechanism (per-sprite offsets vs one `VisualRoot`).

**Verdict: compatible but needs adapter/convergence in the Forum slice.** Not a semantic conflict, so no separate correction packet is needed. Neither system was modified.

## 9. No-mutation proof

- `2145` PNGs under `custodian/content/sprites/operator`: aggregate sha256 `5f4767b8b119388d2b2718fe276300e1b3dd1c411283ea76705c892609aaac5e` recorded at audit time (JSON `operator_art_tree_sha256`).
- At closeout `git status`/`git diff` shows no change under `custodian/content/sprites/`, `custodian/content/data/operator/`, or any Asset Pipeline V2 family; the catalog sha256 above is unchanged.
- Only files added: the five report artifacts under `reports/operator_presentation/`, this packet's bounded updates, and the closing summary. Temporary generation scripts stayed under the git-ignored `.ai/operator_2_5d_audit/`.

## 10. Recommended art-production roadmap (not authored)

Totals per recommended slice (drawn + mirror-derived new sheets; redraws), from the table above:

| Slice | Scope | Families | New drawn | New mirror-derived | Redraw (unique) |
| --- | --- | ---: | ---: | ---: | --- |
| A | unarmed locomotion + relaxed/ready identity | 7 | 34 | 18 | 8 (12 incl. mirror) |
| B | dodge / unarmed block+parry / movement transitions / unarmed fast-chain reconciliation | 15 | 67 | 50 | 0 (0 incl. mirror) |
| C | melee 1H locomotion + posture | 9 | 66 | 36 | 0 (0 incl. mirror) |
| D | melee 1H attack chain + guard (+ dagger and heavy-weapon overlays) | 16 | 111 | 56 | 0 (0 incl. mirror) |
| E | ranged 2H stance / aim / fire / locomotion | 6 | 42 | 26 | 3 (5 incl. mirror) |
| F | sidearm | 2 | 0 | 0 | 0 (0 incl. mirror) |
| G | heavy / reaction / special / death cleanup | 17 | 12 | 8 | 10 (12 incl. mirror) |

- **First slice: A (unarmed locomotion + relaxed/ready identity).** It sets the canonical look and registration every other slice inherits; it is also the highest-frequency body (idle/walk/run/ready) and holds the measured scale/headless defects.
- **Estimated total: 8 coherent slices**: A; B split into B1 (dodge, unarmed block/parry, transitions) and B2 (unarmed fast-chain reconciliation); C; D; E; F (no new sheets; confirm 45° sidearm mapping); G.
- **Parallelism:** after A fixes the reference/registration decision, B1, B2, C, D and E can run in parallel (separate families, separate locks). G last. F needs no art unless Q2 rejects the diagonal mapping.
- **Shared decisions that gate everything:** which look is canonical (Q1), the target sector set per family (P5 vs P8 vs P4), and whether mirror promotion is acceptable for handed gear.
- **Consolidation to check before drawing:** unarmed `fast_01-04` partly duplicate the 8-sector windup/strike/recovery trio; confirm which the chain actually needs (could remove most of B2).
- **Tooling:** the Workbench/Art Agent (publish, mirror promotion, registration profile) is sufficient for production. Gaps worth closing first: a per-family composed-layer preview that matches runtime z-order (this audit's composites are approximate), and a registration drift check against `ground_y` 85 in the status command, which the audit had to compute ad hoc.

## 11. Reviewer questions (human visual decision required)

1. Does current unarmed locomotion already meet the spatial/volumetric target? Evidence says not yet: idle S and walk SE/SW are headless/shortened, and E/S/W read as a different render from the diagonals.
2. Which current projections are acceptable versus obvious cheats? Proposed GRAY set is in the backlog; the sidearm 4-diagonal mapping (E→SE, N→NE) is the main judgement call.
3. Is 8-direction Operator art sufficient when LoP 16-angle continuity is the reference? Not answerable here until the LoP archive is available locally; the Knight shows 8-direction coverage can read well when pitch and volume stay consistent.
4. Which families should be regenerated rather than patched? Proposed RED: cyan-visor sets (`heavy_01`, `light_hitreact_01`, ranged `run_01`/`reload_01`, melee heavy windup). Proposed patch/extend: everything ORANGE.
5. Is the ranked backlog the right production order (A → B → C → D → E → F → G)?
6. Q1: which of the three looks is canonical? This decides whether L2 families (about 208 composed sheets in ORANGE families) are kept or redrawn.

## Handoff after human decision
- Next workstream: `isometric-2-5d-forum-vertical-slice` (refresh-required, owner chatgpt-user).
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
