# Operator 3D master - candidate journal (art source-work only; nothing here is runtime art)

No candidate is human-approved. `best_candidate.json` / `selection_history.jsonl` are intentionally absent:
selection needs `experiments.py select-best --reviewed-by-human`. Rollback = re-select any earlier hash-verified
experiment; each experiment dir is immutable and frozen (`blender_proof_frozen.json`, full SHA256 per file).

| id | status | GLB sha256 (16) | .blend sha256 (16) | mean 8-dir silhouette IoU vs source idle f0 |
|---|---|---|---|---|
| exp-001 | REJECTED: lying down, grey, off-contract | `6cf4f14e0bf507cb` | `9af6d614244c3881` | n/a |
| exp-002 | baseline, pipeline fixed, shape unchanged | `63747ff8434d9d7a` | `f215b90d92f9bf01` | 0.519 |
| exp-003 | reference-driven reshape; walk too subtle (superseded by 005) | `54301e55d21048a8` | `b30a6e667289f699` | 0.676 |
| exp-004 | stocky contrast; overshoots width, leaning reject | `579d5c4b0c0af267` | `c2889c1b306ddced` | 0.576 |
| exp-005 | RECOMMENDED FOR REVIEW: 003 + stronger walk + hood ring | `1277b42f585d45ae` | `23cf2b5d8d145337` | 0.678 |
| exp-006 | capeless revision; visual approval pending | `33160633a98b2630` | `5a75edef511dbf8f` | 0.637 |
| exp-007 | hood-only rounded cowl on exp-006; visual approval pending | `7374dc804bdd5719` | `d70b79b947085196` | 0.648 |
| exp-008 | shoulder plates only (x0.55), span 1.336→1.068 m; rendered at 45°/50 px/m; visual approval pending | `2fdbd858001c8f4d` | `4653d99850e5787d` | 0.610 (45°, not comparable to 30° rows) |
| meshy-001 (imported, `meshy_candidates/meshy-001/`) | Meshy generation, untextured, unrigged, 1.04M verts; reference candidate, art approval pending | `950750e37742c93f` (decoded) | n/a | n/a |

IoU is triage only: it says nothing about gold-edge material language, hood shape or recognition.
`config/shape_v002.json` gained a `blender` block after exp-002 ran; `exp-002/shape.json` (the true snapshot) is
unchanged and was rendered at px_per_m=50. exp-001 used `scripts/create_blend_v1_exp001.py`.
Preview cadence (15 fps in the .blend, 67 ms GIF) is provisional and not canonical timing.
| meshy-002 (imported, `meshy_candidates/meshy-002_textured/`) | Meshy textured generation (model(3).meshy), 660k verts, UVs + 3 textures, unrigged; reference candidate, art approval pending | `b9c2f68dfaa555e2` (decoded) | n/a | n/a |
