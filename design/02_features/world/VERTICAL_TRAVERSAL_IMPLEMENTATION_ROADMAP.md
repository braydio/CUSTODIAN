# Vertical Traversal V1 Implementation Roadmap

**Status:** active execution roadmap  
**Date:** 2026-10-15  
**Audited main:** `350ee94e4b3b80010c0970903f3418966df3b851`  
**Refresh planning chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391

## Program result

Ship one production-readable generated Alpine lower-to-upper route plus one hardened reusable same-map lift foundation, with Awakening migrated to the lift. Ordinary cliff presentation, terrain truth, Asset V2 and route transitions remain separate authorities.

## Dependency graph

```text
A1 operator-elevation-traversal-enforcement-v1
  -> review A1
  -> A2 procgen-elevation-connector-topology-v1 [planning refresh]
  -> review A2
  -> A3 procgen-vertical-traversal-asset-v2 [refresh + source/human art gate]
  -> review A3
  -> A4 procgen-alpine-vertical-traversal-presentation-v1 [refresh + human visual]
  -> review A4

B1 transit-lift-runtime-foundation-v1
  -> review B1
  -> EXISTING awakening-interactible-locker-lift-presentation-v1 [material refresh]
  -> existing paired review

review A4 + reviewed Awakening lift presentation
  -> C1 vertical-traversal-integration-closeout-v1 [planning refresh]
  -> review C1
```

## Slice table

| Slice | Workstream | Authored state | Owns | Refresh gate |
| --- | --- | --- | --- | --- |
| A1 | `operator-elevation-traversal-enforcement-v1` | draft/manual + auto authoring handoff | Operator local displacement consumes existing elevation edge truth | none |
| B1 | `transit-lift-runtime-foundation-v1` | draft/manual + auto authoring handoff | reusable same-map lift lifecycle + Awakening compatibility migration | none |
| A2 | `procgen-elevation-connector-topology-v1` | blocked/manual | lower landing -> shelf turn -> standard ramp/stair -> upper overlook reservation | reviewed A1 |
| A3 | `procgen-vertical-traversal-asset-v2` | blocked/manual | new 14-state readable Alpine traversal family | reviewed A2 + human-approved sources |
| A4 | `procgen-alpine-vertical-traversal-presentation-v1` | blocked/manual | semantic binding, cliff suppression/occlusion, crest/look-back | reviewed A3 + current AP2/AP3 refresh |
| B2 | existing `awakening-interactible-locker-lift-presentation-v1` | blocked/manual | station/machine readability and game-feel polish | reviewed B1 + existing art gates |
| C1 | `vertical-traversal-integration-closeout-v1` | blocked/manual | final cross-system acceptance and documentation truth | reviewed A4 + reviewed B2 |

## Refresh rule for A2+

Later packets preserve stable workstream identity and intended completion boundaries, but they are deliberately non-claimable until predecessor truth exists.

At each refresh:
1. fetch latest `origin/main` and archived predecessor implementation/review summaries;
2. replace stale API/path/test/count assumptions with landed facts;
3. keep the same workstream ID unless the original boundary is genuinely superseded;
4. derive exact asset canvases/registration only from landed topology;
5. run targeted implementation+review authoring preflight before promotion;
6. keep human art/visual gates manual until required source/evidence is actually present.

## Existing assets

- Old 32 px industrial/mountain/ascent ramp/stair/cliff assets are compatibility/debug fallback only for this program and do not satisfy A3.
- AP2 Alpine fascia/contact and rocky-upland macro assets remain ordinary cliff geology/presentation.
- `awakening_dust_lung_lift` and `awakening_interact_lift` are Awakening-specific art families. B1 may preserve them as compatibility presentation but does not declare them reusable lift art.
- Dust Lung V2 `western_lift_spine` and seam overlays remain a later source-art/runtime-cutover gate. B1 mechanics do not wait for those images.

## Closeout condition

The program is not complete because elevation metadata or ramps exist. C1 requires a real Operator to be blocked by ordinary elevation barriers, traverse a generated lower-to-upper Alpine route, stand on the upper terrace with the lower route legible below, and use the migrated Awakening lift through hardened forward/reverse/reset lifecycle with no duplicate gameplay authority.
