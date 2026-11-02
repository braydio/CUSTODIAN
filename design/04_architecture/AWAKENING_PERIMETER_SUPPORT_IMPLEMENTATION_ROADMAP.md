# Awakening Perimeter Support V1 — Implementation Roadmap

**Status:** Authored planning DAG; not implemented. **Date:** 2026-10-09.
**Design:** [AWAKENING_PERIMETER_SUPPORT_V1.md](AWAKENING_PERIMETER_SUPPORT_V1.md) · **Prompts:** [AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md](AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md)
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a

## Calibration batch 01 (10 image requests)

**User disposition 2026-10-10:** All ten originally generated atlas-cropped assets were rejected for visible AI architecture artifacts and mirrored false seamless detail. No state is artistically approved or suitable for Asset V2 ingest; counts and human gates remain unfulfilled. See [Gate Side-Stair / Wind-Dust / Asset QA Ledger](AWAKENING_GATE_STAIRS_WIND_AND_ART_REVIEW_V1.md). Zone 07 production underlay visibly exposes east/west stairs and northward approach; AP3 must preserve these entrances for a separate, explicitly approved spatial-branch decision and must not treat speculative rubble sealing as part of a generic backdrop pass.

[AWAKENING_PERIMETER_BATCH_01_TEN_ASSETS.md](AWAKENING_PERIMETER_BATCH_01_TEN_ASSETS.md) is the first ten-asset source-generation brief: three complete 01/07/10 role sets (9 states), plus Zone 06's distant structures (1 state). Assets 1–3 are an explicit visual calibration stop/go before 4–10. This does not override AP0's camera-footprint proof or automatically promote AP1–AP4.

## Locked project decisions

Nine independently named **generic** nonplayable perimeter regions (Zones 01–04 and 06–10); three candidate Asset V2 states per generic region (27 new generic support files total); background-only support below canonical gameplay plates; all existing geometry/seams/collisions authoritative and unchanged. **Zone 05 Dust Lung is removed from this DAG** and owned by `AWAKENING_DUST_LUNG_V2.md` / `AWAKENING_DUST_LUNG_V2_ASSET_MANIFEST.md`, whose later runtime cutover may intentionally reauthor Zone 05 geometry. Camera-footprint extents and exact source normalization must be measured before committing layout/registered dimensions. No generated image exists solely by virtue of this roadmap.

## Execution DAG / workstream identity

| Stage | Implementation workstream | Paired review | Initial queue state | Completion criterion |
|---|---|---|---|---|
| AP0 | `awakening-perimeter-support-foundation-v1` | `review-awakening-perimeter-support-foundation-v1` | ready/auto, **dependency-gated** | Audit camera gaps, source support layer, schema-validated family/requirement plan, safe absent-art fallback, focused tests. |
| AP1 | `awakening-perimeter-interior-v1` | `review-awakening-perimeter-interior-v1` | draft/manual, art approval gate | Integrate 01–04 Crèche, Ambulatory, Attestation, Reliquary approved plates; validate adjacency and P-9. |
| AP2 | `awakening-perimeter-depth-v1` | `review-awakening-perimeter-depth-v1` | draft/manual, art approval gate | Integrate **Zone 06 Undergate only**; preserve 05→06 and current Dust Lung fallback while the separate Dust Lung V2 program proceeds. |
| AP3 | `awakening-perimeter-exterior-v1` | `review-awakening-perimeter-exterior-v1` | draft/manual, art approval gate | Integrate 07–09 Gate, Approach and optional Chapel; preserve Gate route and 08↔09. |
| AP4 | `awakening-perimeter-south-reach-v1` | `review-awakening-perimeter-south-reach-v1` | draft/manual, art approval gate | Integrate 10 around Road-owned South Reach without replacing its five modular plates or spilling into later Hub; final focused route/performance/coverage review. |

### AP0 implementation receipt (2026-10-15)

The AP0 implementation is complete on its scoped branch; paired post-land review
remains the next gate. The deterministic ledger covers ten live plate bounds
and 34 camera samples. It finds two repeated uncovered presentation windows:
704×32 px at wake/Zone01 entry and 704×96 px at the 05→06 seam. All three
authored camera reveals remain inside measured plate rectangles. Nine generic
families and 27 required states are registered, but no art exists or is claimed
fulfilled. Zone 05 remains excluded for Dust Lung V2. See the AP0 receipt in
`custodian/docs/ai_context/task_packets/archived/AWAKENING_PERIMETER_SUPPORT_FOUNDATION_V1.md`.

```text
review-awakening-handoff-readiness-art-convergence-v1
  ↓
AP0 → AR0
        ↓
AP1 → AR1
        ↓
AP2 → AR2
        ↓
AP3 → AR3
        ↓
AP4 → AR4
```

Each review runs fresh-context/different-agent post-land, and only verifies the implementation already archived. Existing implementation/review pair(s) take priority over simultaneous writes in `awakening_first_return.gd`, `awakening_layout.gd` and scene registration. Claims must use current `origin/main` dispatcher.

## Parallel Dust Lung V2 program

Zone 05 no longer belongs to AP0–AP4 art fulfillment. Its replacement target is
the region-scale modular design in
[AWAKENING_DUST_LUNG_V2.md](AWAKENING_DUST_LUNG_V2.md), with exact underlay and
connector generation contracts in
[AWAKENING_DUST_LUNG_V2_ASSET_MANIFEST.md](AWAKENING_DUST_LUNG_V2_ASSET_MANIFEST.md).

AP0 may still **measure** Zone 05 camera gaps as part of the ten-zone coverage
ledger, but it must not register `awakening_dust_lung_perimeter_support`. AP2
must not consume or modify Dust Lung V2 art/geometry. A later dedicated DL0
implementation packet will own the actual Zone 05 spatial cutover after the V2
source set is generated and human-approved.

## Adjacent Crèche console VFX defect (separate owner)

A first-interaction FX has been reported rendering on the floor beneath the computer, and the live Awakening controller anchors `CrecheConsoleActivation` at the `(112,144)` logical interaction marker while the registered idle console prop is not visibly instanced. This is owned by `AWAKENING_INTERACTIBLE_CONSOLE_PORT_PRESENTATION_V1` and its paired review. The perimeter AP1 implementation **must not silently fix, replace, duplicate or move that console/FX**, and should include it only as an unchanged adjacent-presentation regression. The dedicated fix must inspect the baked console versus 128×128 Asset V2 prop and bind the existing 8-frame activation to the actual screen-local point, not the floor.

## Promotion / asset gates

- AP0 may be claimed when its named predecessor review archives complete, locks clear and the dispatcher reports eligibility. It does **not** require images or user aesthetic judgment.
- AP1–AP4 need human approval of all specified constituent images and a source/normalized handoff manifest with checksums and real dimensions, or a documented reduction in scope. Each stage must be refreshed against actual Asset V2 family/catalog status and predecessor reviewed runtime, then its implementation/review metadata promoted together to ready/auto and the README index regenerated. Do not fabricate source, fake ingestion, silently mark artwork complete, or change manual-to-auto while approval is outstanding.
- Style calibration for this generic perimeter DAG: generate/review representative interior, Gate and South Reach samples before producing all 27 generic files. Dust Lung calibration/generation happens only through its dedicated V2 manifest and authoring chat.
- If a verified asset already exists under another family, prefer a provenance-safe reuse decision; do not duplicate/replace production material without evidence.

## Required proof after each stage

Recompute world/camera/zone art bounds; verify all support has no collision and no Operator occlusion; inspect deterministic alpha/transparency/scale/z-order; assert unchanged passages and progression; run focused Awake scene/geometry/progression and Asset V2 checks; produce at most one compact external human review manifest for subjective styling. After AP4, compare 15 representative checkpoints and Road south approach, measure any visual seam gaps and confirm no material performance regression.

## Documentation drift ledger at authoring time

1. The 2026-09-20 `reports/awakening_visual_walkthrough/QA.md` still describes 04→05 rectangular uncovered connector gaps and claims five Road plates `REGEN_REQUIRED`. Subsequent direct registered composition and Road modular Asset V2 publication supersede both; treat that report as dated evidence, not current authority. AP0 should tag/cross-reference it rather than rewriting historical test results.
2. `AWAKENING_ASSET_MANIFEST.md` contains a dated 2026-10-03 claim about nine environment pairs, while the active 04→05 correction explicitly defers incompatible Locker foreground. Do not infer live foreground completeness from the older blanket statement; AP0 reconciles the current catalog ledger.
3. The 04→05 shared-parent fade defect is corrected and passed paired review; fade ownership remains on the registered Dust/Connector/Locker children. The sealed Gate body's visual-route question remains authored composition work. Perimeter art neither changes the accepted connector registration nor resolves/bypasses the Gate decision.

## Gate lateral-stair creative decision (2026-10-10)

The user rejected earlier proposed west/east names and small-pocket scope. West is now an unnamed forbidden high-difficulty lower region visible early and intended to matter again mid-game, potentially also teased as a visual-only view near the literal Zone01 Crèche spawn. East is simply an unnamed overlook of the dead historical city. See [AWAKENING_FORBIDDEN_LOWER_REGION_CONCEPTS_V1.md](AWAKENING_FORBIDDEN_LOWER_REGION_CONCEPTS_V1.md) for five nonbinding visual candidates. AP3 protects both stair mouths and cannot imply active branches, loot, mechanics, authoring of a real dungeon or later access requirements.
