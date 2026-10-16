# Operator NE walk V6 | Original single-frame rig audit

Workstream: `operator-2-5d-ne-walk-retargeting`  
Status: **root cause identified, repair not executed, neither candidate approved as master**  
Source: user-uploaded `SINGLE_FRAME.aseprite` compared to `operator_ne_rig_RECOVERED_FROM_V6_UNVERIFIED.aseprite` (the V6 preview-embedded rig).

## Verified original

- `SINGLE_FRAME.aseprite`: SHA-256 `0f5b3346044e60581db6e38e41fc292bd2b49ca05c291ada9591495765166149`; **128×128 RGBA, 1 frame, 53 layers**.
- Rig source 2191 opaque pixels, neutral reconstruction byte-exact, zero unclassified pixels, all 18 exact-color pivot markers present once.
- Far hip `[53, 75]`, knee `[52, 88]`, ankle `[49, 98]`, toe `[45, 101]`.
- Far thigh **13.038 px**, far shin **10.440 px**, near shin **11.045 px**.
- **Blocking:** `__RIG_PART_foot_far_visible` = 0 pixels; `__RIG_HIDDEN_foot_far_completion` = 0 pixels. Sole-aware far-support retargeting cannot pass the existing foot geometry requirement from this file alone.
- Contains older V5 single-frame working/reference layers; these are not canonical source layers for V6.

## Verified V6 candidate

- Recovered rig: SHA-256 `b883f9d068d29d1d012e873b8902394ce5716faabb2fa756e2936c6cc176a58a`; 128×128 RGBA, 1 frame, 48 layers; source 2199 opaque pixels, byte-exact neutral, zero unclassified, 18 markers.
- Far hip `[53, 75]`, knee `[52, 88]`, ankle `[50, 85]`; far shin **3.606 px**.
- `__RIG_PART_shin_far_visible` = 0, hidden shin completion = 0, `__RIG_PART_foot_far_visible` = 58. It has a recognized foot but an anatomically invalid far-shin chain for the target gait.

## Pixel-level regression evidence

All 58 pixels in the newer far-foot part correspond to these positions in SINGLE_FRAME's semantic ownership:

| Original owner | Pixels later assigned to `foot_far_visible` |
|---|---:|
| `shin_far_visible` | 29 |
| `thigh_far_visible` | 25 |
| `thigh_near_visible` | 1 |
| New opaque pixel locations | 3 |

Thus **all 29 original far-shin pixels were reassigned to the far-foot layer**. This explains the empty far shin in the V6 rig. The original far-ankle coordinate was `(49,98)`; the candidate moved it to `(50,85)`.

The two locked full-body reference images differ at **11 pixels** (8 added opaque pixels and 3 recolored pixels). They are **not byte-identical source masters**. Do not mix semantic layers across versions or call one a lossless reconstruction of the other without choosing an accepted source image and revalidating its partition.

## Precise next action for Codex

Continue `agent/operator-2-5d-ne-walk-retargeting` from checkpoint `230a0b2`.

1. Import/copy the supplied SINGLE_FRAME asset to a **disposable local review workspace**; record SHA-256 `0f5b3346044e60581db6e38e41fc292bd2b49ca05c291ada9591495765166149` and keep original immutable. Retain the V6 checkpoint and preview.
2. Treat SINGLE_FRAME as evidence for the pre-regression far shin segmentation and skeleton, not a ready-to-use production rig. Inspect the two locked full-body sources and 11-pixel difference, select source authority with human review if the identity is material.
3. Repair the far-leg classification and anatomical pivot/foot relationship in a separately named recovery candidate. **No direct pivot reset without rendered anatomy; no blind layer merges.** The original far shin pixels had been moved into the foot layer, while the older original has no foot-owned pixels. Reconcile semantic ownership across the accepted source, and explicitly plan hidden boot/shin completion pixels if required. Preserve the accepted palette, identity, and NE camera projection.
4. Validate exact neutral reconstruction, one-owner-per-visible-pixel, 18 unique pivots, both foot geometries, positive/anatomical near/far shin lengths, and actual transformed support sole. Add focused regression coverage so the same segmentation cannot silently recur.
5. **Only after the rig is validated**, rerun the existing 15-frame V6 solver unchanged into a new preview directory. Compare 3/15 previous full pass and 14/15 contact pass with new results, and report actual frame defects. Do not fake green checks by widening tolerances.
6. Do not change game runtime, publish source, update timing/FPS, or merge the V6 branch until there is a visually accepted 15-frame cycle and required validation ownership.

## Limits

Audit performed by parsing the Aseprite file frames, cels, and RGBA layers directly; neutral identity and visible ownership were checked from decoded pixels. This is not an Aseprite runtime or animation playback test.

Machine-readable coordinates, per-part pixel counts, source-pixel differences, and SHA hashes: `operator_ne_v6_rig_master_comparison.json`.
