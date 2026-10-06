# Alpine Underlay Last-3-Generations Combination Review

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4
Authoring chat (packet): https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d

Workstream: `procgen-alpine-plateau-underlay-assets` (review-only side task; production underlay untouched).

## Implementation summary
- Fetched `implementation_inputs/procgen-alpine-plateau-underlay-assets/alpine_underlay_last3_generations_review_bundle.zip`; read `UNDERLAY_REVIEW_MANIFEST.json` and `CLAUDE_WIRING_INSTRUCTIONS.md` first. All 30 PNGs are RGBA 1536x1024; every combo path resolves.
- Staged all three generations review-only under `custodian/content/backgrounds/procgen/alpine_plateau/review_candidates/` (30 PNGs + manifest, ~77 MB). The directory carries a `.gdignore` (never imported) and is excluded from git via the worktree's info/exclude, so it is **not committed**; re-extract from the bundle to reproduce.
- No production asset, Asset V2 family or `alpine_plateau_underlay.tres` was modified. Instead of seven temporary `.tres` files, the Moment Forge fixture builds one temporary single-variant profile at runtime from env `ALPINE_REVIEW_COMBO`, duplicating the accepted Alpine tuning (opacities, parallax, coverage, base fill) unchanged.
- Ran the unchanged `procgen/alpine_plateau_edge_review` scenario (seed 424242, zoom 0.74, N/E/S/W logic) once per combo; each probe records the active `review_combo`.

## Combos run
combo_a_gen3_default, combo_b_gen3_alt, combo_c_gen3_gen2_mix, combo_d_gen2_balanced, combo_e_hero_stress, combo_f_cloud_sea, combo_g_gen1_reference.

## Dropbox review folders
`/CUSTODIAN/visual_review/procgen-alpine-plateau-underlay-combos/20261006T0614Z-<combo_id>/` (one per combo; contact sheet, six keyframes, metrics, run_result, REVIEW_MANIFEST.json, combo id in every filename) plus `20261006T0614Z-comparison/` with a side-by-side of all seven. The publisher keys folders by run id, so the layout is `<timestamp>-<combo>/` rather than `<timestamp>/<combo>/`.

## Recommendation (agent aid, not an aesthetic approval)
1. **combo_a_gen3_default** — broad territory, calm fog, best overall; busiest of the top three.
2. **combo_c_gen3_gen2_mix** — quieter far world than A; same fog/near. 
3. **combo_d_gen2_balanced** — calmest and most subordinate; flattest.
- combo_b: more breakup/movement, viable alternate. combo_e: citadel/arch/glyph read as hero architecture, correctly too rare for default. combo_f: cloud-sea dominates, little geography. combo_g: scenic-forward reference.
- Observation: the dark slate base fill is visible in upper-left corners for C and F where the plates have transparent gaps; judge whether that reads as intended depth.
