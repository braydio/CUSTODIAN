# Awakening Perimeter Support V1 — Implementation Roadmap

**Status:** Authored planning DAG; not implemented. **Date:** 2026-10-09.
**Design:** [AWAKENING_PERIMETER_SUPPORT_V1.md](AWAKENING_PERIMETER_SUPPORT_V1.md) · **Prompts:** [AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md](AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md)
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a

## Locked project decisions

Ten independently named nonplayable perimeter regions; three candidate Asset V2 states per region (30 new art files total); background-only support below canonical gameplay plates; all existing geometry/seams/collisions authoritative and unchanged. Camera-footprint extents and exact source normalization must be measured before committing layout/registered dimensions. No generated image exists solely by virtue of this roadmap.

## Execution DAG / workstream identity

| Stage | Implementation workstream | Paired review | Initial queue state | Completion criterion |
|---|---|---|---|---|
| AP0 | `awakening-perimeter-support-foundation-v1` | `review-awakening-perimeter-support-foundation-v1` | ready/auto, **dependency-gated** | Audit camera gaps, source support layer, schema-validated family/requirement plan, safe absent-art fallback, focused tests. |
| AP1 | `awakening-perimeter-interior-v1` | `review-awakening-perimeter-interior-v1` | draft/manual, art approval gate | Integrate 01–04 Crèche, Ambulatory, Attestation, Reliquary approved plates; validate adjacency and P-9. |
| AP2 | `awakening-perimeter-depth-v1` | `review-awakening-perimeter-depth-v1` | draft/manual, art approval gate | Integrate 05–06 Dust Lung/Cistern and Undergate depth; validate 04→05/05→06 registration and camera reveal. |
| AP3 | `awakening-perimeter-exterior-v1` | `review-awakening-perimeter-exterior-v1` | draft/manual, art approval gate | Integrate 07–09 Gate, Approach and optional Chapel; preserve Gate route and 08↔09. |
| AP4 | `awakening-perimeter-south-reach-v1` | `review-awakening-perimeter-south-reach-v1` | draft/manual, art approval gate | Integrate 10 around Road-owned South Reach without replacing its five modular plates or spilling into later Hub; final focused route/performance/coverage review. |

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

## Promotion / asset gates

- AP0 may be claimed when its named predecessor review archives complete, locks clear and the dispatcher reports eligibility. It does **not** require images or user aesthetic judgment.
- AP1–AP4 need human approval of all specified constituent images and a source/normalized handoff manifest with checksums and real dimensions, or a documented reduction in scope. Each stage must be refreshed against actual Asset V2 family/catalog status and predecessor reviewed runtime, then its implementation/review metadata promoted together to ready/auto and the README index regenerated. Do not fabricate source, fake ingestion, silently mark artwork complete, or change manual-to-auto while approval is outstanding.
- Style calibration: generate/review single Dust Lung, Gate and South Reach sample images before producing all 30; this is a visual acceptance workflow, not an automated art-generation side effect of Codex.
- If a verified asset already exists under another family, prefer a provenance-safe reuse decision; do not duplicate/replace production material without evidence.

## Required proof after each stage

Recompute world/camera/zone art bounds; verify all support has no collision and no Operator occlusion; inspect deterministic alpha/transparency/scale/z-order; assert unchanged passages and progression; run focused Awake scene/geometry/progression and Asset V2 checks; produce at most one compact external human review manifest for subjective styling. After AP4, compare 15 representative checkpoints and Road south approach, measure any visual seam gaps and confirm no material performance regression.

## Documentation drift ledger at authoring time

1. The 2026-09-20 `reports/awakening_visual_walkthrough/QA.md` still describes 04→05 rectangular uncovered connector gaps and claims five Road plates `REGEN_REQUIRED`. Subsequent direct registered composition and Road modular Asset V2 publication supersede both; treat that report as dated evidence, not current authority. AP0 should tag/cross-reference it rather than rewriting historical test results.
2. `AWAKENING_ASSET_MANIFEST.md` contains a dated 2026-10-03 claim about nine environment pairs, while the active 04→05 correction explicitly defers incompatible Locker foreground. Do not infer live foreground completeness from the older blanket statement; AP0 reconciles the current catalog ledger.
3. The 04→05 shared-parent fade defect is corrected and passed paired review; fade ownership remains on the registered Dust/Connector/Locker children. The sealed Gate body's visual-route question remains authored composition work. Perimeter art neither changes the accepted connector registration nor resolves/bypasses the Gate decision.
