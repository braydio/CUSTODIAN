# CUSTODIAN Operator Body Audit

## Scope

- Runtime root: `/home//braydenchaffee/Projects/CUSTODIAN/custodian/content/sprites/operator/runtime`
- Audit cell: `96x96`
- Direction order in atlas: `s, se, e, ne / n, nw, w, sw`
- PNG files discovered: **549**
- Canonical body candidates: **261**
- Complete/full semantic groups analyzed: **129**
- Partial unmatched groups: **16**
- Composed frames measured: **723**
- Skipped/superseded diagnostics: **19**

## Overall Dimensions

- Median occupied bounding box: **48.0 x 69.0 px**.
- Median cell utilization: **50.0% horizontal**, **71.9% vertical**.
- Global opaque-centroid span: **34.9 px**.
- Global bottom-most-pixel span: **40.0 px**.

These global ranges include attacks, reactions, and locomotion. Use the animation table below for root/baseline judgments on a specific clip.

## Direction Summary

| Dir | Frames | Median box | Cell use H/V | Center span | Baseline span | Clip | Head/shoulder | Torso/shoulder | Stance/shoulder | Value range |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| s | 123 | 43.0x64.0 | 45% / 67% | 23.6 | 40.0 | 5 | 0.74 | 0.96 | 1.00 | 0.36 |
| se | 53 | 43.0x72.0 | 45% / 75% | 12.0 | 10.0 | 0 | 0.69 | 0.88 | 0.97 | 0.36 |
| e | 193 | 52.0x69.0 | 54% / 72% | 31.8 | 28.0 | 10 | 0.72 | 0.88 | 1.08 | 0.36 |
| ne | 24 | 48.0x69.5 | 50% / 72% | 9.9 | 9.0 | 0 | 0.68 | 0.94 | 1.18 | 0.30 |
| n | 88 | 48.0x70.5 | 50% / 73% | 12.6 | 13.0 | 1 | 0.62 | 0.92 | 0.95 | 0.28 |
| nw | 24 | 46.5x69.0 | 48% / 72% | 9.9 | 4.0 | 0 | 0.69 | 0.94 | 1.20 | 0.30 |
| w | 165 | 50.0x68.0 | 52% / 71% | 25.4 | 23.0 | 4 | 0.72 | 0.88 | 1.08 | 0.36 |
| sw | 53 | 43.0x72.0 | 45% / 75% | 12.0 | 10.0 | 0 | 0.68 | 0.88 | 0.95 | 0.37 |

## Directional Consistency

### Mirrored pairs

- `e ↔ w`: **93.6%** mirrored consensus overlap.
- `se ↔ sw`: **97.7%** mirrored consensus overlap.
- `ne ↔ nw`: **91.9%** mirrored consensus overlap.

### Adjacent directions

- `s → se`: **70.2%** direct consensus overlap.
- `se → e`: **74.9%** direct consensus overlap.
- `e → ne`: **78.7%** direct consensus overlap.
- `ne → n`: **82.6%** direct consensus overlap.
- `n → nw`: **82.9%** direct consensus overlap.
- `nw → w`: **81.3%** direct consensus overlap.
- `w → sw`: **78.0%** direct consensus overlap.
- `sw → s`: **67.4%** direct consensus overlap.

## Prioritized Improvements

1. **[CRITICAL] direction e — Silhouette touches the frame boundary**  
   Evidence: 10/193 frames touch at least one 96x96 cell edge.  
   Recommended change: Recenter the root or enlarge the source cell; no production body pixel should rely on the crop boundary.
2. **[CRITICAL] direction n — Silhouette touches the frame boundary**  
   Evidence: 1/88 frames touch at least one 96x96 cell edge.  
   Recommended change: Recenter the root or enlarge the source cell; no production body pixel should rely on the crop boundary.
3. **[CRITICAL] direction s — Silhouette touches the frame boundary**  
   Evidence: 5/123 frames touch at least one 96x96 cell edge.  
   Recommended change: Recenter the root or enlarge the source cell; no production body pixel should rely on the crop boundary.
4. **[CRITICAL] direction w — Silhouette touches the frame boundary**  
   Evidence: 4/165 frames touch at least one 96x96 cell edge.  
   Recommended change: Recenter the root or enlarge the source cell; no production body pixel should rely on the crop boundary.
5. **[HIGH] ranged_2h__run_01 / e — Locomotion contact height changes unintentionally**  
   Evidence: Baseline range is 8.0 px over 5 frames.  
   Recommended change: Lock planted-foot frames to the common baseline and move only the lifting foot/body bob.
6. **[HIGH] ranged_2h__run_01 / w — Locomotion contact height changes unintentionally**  
   Evidence: Baseline range is 8.0 px over 5 frames.  
   Recommended change: Lock planted-foot frames to the common baseline and move only the lifting foot/body bob.
7. **[HIGH] unarmed__idle_01 / w — Locomotion contact height changes unintentionally**  
   Evidence: Baseline range is 3.0 px over 11 frames.  
   Recommended change: Lock planted-foot frames to the common baseline and move only the lifting foot/body bob.
8. **[HIGH] unarmed__run_01 / e — Locomotion contact height changes unintentionally**  
   Evidence: Baseline range is 8.0 px over 5 frames.  
   Recommended change: Lock planted-foot frames to the common baseline and move only the lifting foot/body bob.
9. **[HIGH] unarmed__run_01 / n — Locomotion contact height changes unintentionally**  
   Evidence: Baseline range is 3.0 px over 6 frames.  
   Recommended change: Lock planted-foot frames to the common baseline and move only the lifting foot/body bob.
10. **[HIGH] unarmed__run_01 / s — Locomotion contact height changes unintentionally**  
   Evidence: Baseline range is 7.0 px over 12 frames.  
   Recommended change: Lock planted-foot frames to the common baseline and move only the lifting foot/body bob.
11. **[HIGH] unarmed__run_01 / se — Locomotion contact height changes unintentionally**  
   Evidence: Baseline range is 9.0 px over 9 frames.  
   Recommended change: Lock planted-foot frames to the common baseline and move only the lifting foot/body bob.
12. **[HIGH] unarmed__run_01 / sw — Locomotion contact height changes unintentionally**  
   Evidence: Baseline range is 9.0 px over 9 frames.  
   Recommended change: Lock planted-foot frames to the common baseline and move only the lifting foot/body bob.
13. **[HIGH] unarmed__run_01 / w — Locomotion contact height changes unintentionally**  
   Evidence: Baseline range is 3.0 px over 5 frames.  
   Recommended change: Lock planted-foot frames to the common baseline and move only the lifting foot/body bob.
14. **[HIGH] unarmed__walk_01 / n — Locomotion contact height changes unintentionally**  
   Evidence: Baseline range is 11.0 px over 15 frames.  
   Recommended change: Lock planted-foot frames to the common baseline and move only the lifting foot/body bob.
15. **[HIGH] unarmed__walk_01 / s — Locomotion contact height changes unintentionally**  
   Evidence: Baseline range is 7.0 px over 11 frames.  
   Recommended change: Lock planted-foot frames to the common baseline and move only the lifting foot/body bob.
16. **[HIGH] unarmed__walk_01 / se — Locomotion contact height changes unintentionally**  
   Evidence: Baseline range is 3.0 px over 5 frames.  
   Recommended change: Lock planted-foot frames to the common baseline and move only the lifting foot/body bob.
17. **[HIGH] unarmed__walk_01 / sw — Locomotion contact height changes unintentionally**  
   Evidence: Baseline range is 3.0 px over 5 frames.  
   Recommended change: Lock planted-foot frames to the common baseline and move only the lifting foot/body bob.
18. **[HIGH] direction e — Foot baseline is inconsistent**  
   Evidence: Bottom-most opaque pixel moves 28.0 px across sampled poses.  
   Recommended change: Normalize contact frames to one authored operator root; reserve vertical movement for intentional hops, recoil, falls, or dodge arcs.
19. **[HIGH] direction n — Foot baseline is inconsistent**  
   Evidence: Bottom-most opaque pixel moves 13.0 px across sampled poses.  
   Recommended change: Normalize contact frames to one authored operator root; reserve vertical movement for intentional hops, recoil, falls, or dodge arcs.
20. **[HIGH] direction ne — Foot baseline is inconsistent**  
   Evidence: Bottom-most opaque pixel moves 9.0 px across sampled poses.  
   Recommended change: Normalize contact frames to one authored operator root; reserve vertical movement for intentional hops, recoil, falls, or dodge arcs.
21. **[HIGH] direction nw — Foot baseline is inconsistent**  
   Evidence: Bottom-most opaque pixel moves 4.0 px across sampled poses.  
   Recommended change: Normalize contact frames to one authored operator root; reserve vertical movement for intentional hops, recoil, falls, or dodge arcs.
22. **[HIGH] direction s — Foot baseline is inconsistent**  
   Evidence: Bottom-most opaque pixel moves 40.0 px across sampled poses.  
   Recommended change: Normalize contact frames to one authored operator root; reserve vertical movement for intentional hops, recoil, falls, or dodge arcs.
23. **[HIGH] direction se — Foot baseline is inconsistent**  
   Evidence: Bottom-most opaque pixel moves 10.0 px across sampled poses.  
   Recommended change: Normalize contact frames to one authored operator root; reserve vertical movement for intentional hops, recoil, falls, or dodge arcs.
24. **[HIGH] direction sw — Foot baseline is inconsistent**  
   Evidence: Bottom-most opaque pixel moves 10.0 px across sampled poses.  
   Recommended change: Normalize contact frames to one authored operator root; reserve vertical movement for intentional hops, recoil, falls, or dodge arcs.
25. **[HIGH] direction w — Foot baseline is inconsistent**  
   Evidence: Bottom-most opaque pixel moves 23.0 px across sampled poses.  
   Recommended change: Normalize contact frames to one authored operator root; reserve vertical movement for intentional hops, recoil, falls, or dodge arcs.
26. **[HIGH] direction e — Horizontal root registration drifts**  
   Evidence: Opaque centroid spans 31.8 px horizontally.  
   Recommended change: Realign frames around the pelvis/root instead of centering each redraw by its bounding box.
27. **[HIGH] direction n — Horizontal root registration drifts**  
   Evidence: Opaque centroid spans 12.6 px horizontally.  
   Recommended change: Realign frames around the pelvis/root instead of centering each redraw by its bounding box.
28. **[HIGH] direction ne — Horizontal root registration drifts**  
   Evidence: Opaque centroid spans 9.9 px horizontally.  
   Recommended change: Realign frames around the pelvis/root instead of centering each redraw by its bounding box.
29. **[HIGH] direction nw — Horizontal root registration drifts**  
   Evidence: Opaque centroid spans 9.9 px horizontally.  
   Recommended change: Realign frames around the pelvis/root instead of centering each redraw by its bounding box.
30. **[HIGH] direction s — Horizontal root registration drifts**  
   Evidence: Opaque centroid spans 23.6 px horizontally.  
   Recommended change: Realign frames around the pelvis/root instead of centering each redraw by its bounding box.

_Additional lower-priority findings remain available in the CSV metrics._

## Atlas Layers

- **SILHOUETTE ENVELOPE:** every occupied position across sampled poses.
- **STABLE BODY CORE:** pixels present in at least 75% of unique silhouettes.
- **MOTION FRINGE:** intermittent pixels; bright orange indicates the most unstable silhouette zones.
- **AVERAGE VALUE MAP:** average luminance where RGB/grayscale source data is available.
- **PROPORTION + ROOT GUIDES:** median body bounds, centerline, inferred vertical bands, and median baseline.
- **EDGE CLIPPING ISSUES:** red pixels touch the audit cell boundary.

## Measurement Notes

- Head, shoulder, torso, hip, and stance widths are inferred from vertical silhouette bands. They are comparative diagnostics, not skeletal landmarks.
- Mirrored overlap can be reduced by intentional cape, armor, or weapon asymmetry. Confirm the body underneath before changing deliberate design.
- Indexed PNGs contribute silhouette measurements but may not contribute luminance metrics.

## Skipped and Superseded Files

- `/home//braydenchaffee/Projects/CUSTODIAN/custodian/content/sprites/operator/runtime/body/melee/operator__body__melee__light_01__s__6f__100.png | frame 1 is empty`
- `/home//braydenchaffee/Projects/CUSTODIAN/custodian/content/sprites/operator/runtime/body/melee/operator__body__melee__light_01__s__6f__101.png | frame 6 is empty`
- `/home//braydenchaffee/Projects/CUSTODIAN/custodian/content/sprites/operator/runtime/body/melee/operator__body__melee__light_01__s__6f__97.png | frame 6 is empty`
- `/home//braydenchaffee/Projects/CUSTODIAN/custodian/content/sprites/operator/runtime/body/melee/operator__body__melee__light_01__s__6f__98.png | frame 6 is empty`
- `/home//braydenchaffee/Projects/CUSTODIAN/custodian/content/sprites/operator/runtime/body/melee/operator__body__melee__light_01__s__6f__99.png | frame 6 is empty`
- `/home//braydenchaffee/Projects/CUSTODIAN/custodian/content/sprites/operator/runtime/body/full/operator__body__full__dodge_01__s__9f__96.png | lower-priority duplicate`
- `/home//braydenchaffee/Projects/CUSTODIAN/custodian/content/sprites/operator/runtime/body/melee/operator__body__melee__fast_01__e__6__96.png | missing canonical frame-count token`
- `/home//braydenchaffee/Projects/CUSTODIAN/custodian/content/sprites/operator/runtime/body/melee/operator__body__melee__fast_01__n__6__96.png | missing canonical frame-count token`
- `/home//braydenchaffee/Projects/CUSTODIAN/custodian/content/sprites/operator/runtime/body/melee/operator__body__melee__fast_01__s__6__96.png | missing canonical frame-count token`
- `/home//braydenchaffee/Projects/CUSTODIAN/custodian/content/sprites/operator/runtime/body/melee/operator__body__melee__fast_01__w__6__96.png | missing canonical frame-count token`
- `/home//braydenchaffee/Projects/CUSTODIAN/custodian/content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__death_01__omni__6f__96.png | missing canonical direction token`
- `/home//braydenchaffee/Projects/CUSTODIAN/custodian/content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__fast_recovery_01__e__3f__96.png | lower-priority duplicate`
- `/home//braydenchaffee/Projects/CUSTODIAN/custodian/content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__fast_recovery_01__w__3f__96.png | lower-priority duplicate`
- `/home//braydenchaffee/Projects/CUSTODIAN/custodian/content/sprites/operator/runtime/body/melee/operator__body__melee__light_01__s__6f__100.png | filename frame-size token disagrees with actual image dimensions`
- `/home//braydenchaffee/Projects/CUSTODIAN/custodian/content/sprites/operator/runtime/body/melee/operator__body__melee__light_01__s__6f__101.png | filename frame-size token disagrees with actual image dimensions`
- `/home//braydenchaffee/Projects/CUSTODIAN/custodian/content/sprites/operator/runtime/body/melee/operator__body__melee__light_01__s__6f__96.png | filename frame-size token disagrees with actual image dimensions`
- `/home//braydenchaffee/Projects/CUSTODIAN/custodian/content/sprites/operator/runtime/body/melee/operator__body__melee__light_01__s__6f__97.png | filename frame-size token disagrees with actual image dimensions`
- `/home//braydenchaffee/Projects/CUSTODIAN/custodian/content/sprites/operator/runtime/body/melee/operator__body__melee__light_01__s__6f__98.png | filename frame-size token disagrees with actual image dimensions`
- `/home//braydenchaffee/Projects/CUSTODIAN/custodian/content/sprites/operator/runtime/body/melee/operator__body__melee__light_01__s__6f__99.png | filename frame-size token disagrees with actual image dimensions`
