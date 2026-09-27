# Awakening 04→05 Connector Visual Acceptance

## Workstream identity

- Workstream: `awakening-connector-04-05`
- Branch: `agent/awakening-connector-04-05`
- Donor preserved intact: `codex/twin-solaria-runtime-v1a@58fc0b3b`
- Chat: **Review Design Changes**
- Last relevant chat activity: **2026-09-27** (13:47 EDT)
- Status: extracted / visual acceptance open

## Goal

Finish and visually accept the Reliquary → Dust Lung 04→05 connector envelope without changing gameplay geometry.

The current candidate is the 1024x576 RGBA `full_plate_underlay`, centered at `(352,-2464)`, with the existing Layout A/B/C traversal rectangles unchanged. The previous 832x384 `full_plate` is rejected and must not regain runtime authority.

## Locked contract

- Approved source master remains immutable.
- Traversal, collision, triggers, room positions, P-9, and lighting geometry stay Layout-owned.
- Preserve exact A/B/C route rectangles and their union.
- Keep 96px presentation bleed outside the locked traversal union.
- Do not color-key the flattened RGB master.
- Do not fabricate a foreground/occlusion state from inseparable lighting, shadow, and tall architecture.
- Optional `full_plate_foreground` remains unbound unless genuinely authored.

## Current defect

Direct visual review still shows a noticeable straight room-canvas join in the C/A transitions. Focused runtime/asset tests passing is not visual acceptance.

## Acceptance

1. No hard/straight visible join at Reliquary or Dust Lung room-canvas boundaries during traversal.
2. No doubled threshold/stair details.
3. Architecture, lamps, route line, elbows, and landing surrounds remain present.
4. Exterior silhouette remains transparent.
5. Old 832x384 runtime binding remains retired.
6. Focused Awakening geometry/progression/first-return and Asset V2 ingest checks pass.
7. Fresh windowed captures are reviewed directly before landing.

## Non-goals

- No traversal/collision redesign.
- No Twin Solaria changes.
- No unrelated Awakening controller refactor.
- No invented foreground layer.

## Completion report

Report final visual evidence paths, Asset V2 state, focused validation, and whether the no-hard-seam criterion is accepted.
