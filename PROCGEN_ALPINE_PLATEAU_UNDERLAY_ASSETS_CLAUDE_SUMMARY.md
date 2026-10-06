# Procgen Alpine Plateau Underlay Assets (AP1) — Closing Summary

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4

Workstream: `procgen-alpine-plateau-underlay-assets` (packet archived `complete`). Companion review-only summary: `ALPINE_UNDERLAY_LAST3_COMBO_REVIEW_CLAUDE_SUMMARY.md`.

## What shipped
- The approved **final six** plates are the production `procgen_underlay_alpine_plateau` family (Asset V2 `ingest --replace`, doctor healthy, 6/6 ready). Gate A is the immutable handoff `implementation_inputs/procgen-alpine-plateau-underlay-assets/alpine-underlay-final-six-v3/`, verified with `implementation_handoff.py fetch` first; runtime PNGs are byte-identical to the donor plates from `alpine_underlay_last3_generations_review_bundle.zip` (far A=gen2 `alpine_ruins_among_fog_islands`, far B=gen3 `snowy_custodian_ruins_above_the_clouds`, fog A=gen3 `misty_alpine_ruins_overlay`, fog B=gen2 `translucent_alpine_ruins_cloudscape`, near A=gen3 `floating_alpine_cliffs_in_mist`, near B=gen2 `misty_ruined_alpine_plateau_cutout`).
- `ProcgenUnderlayProfile` / `ProcgenDepthBackdrop`: optional per-layer parallax (bounded `tanh`), `guarantee_viewport_coverage` (closed-form cover scale incl. parallax margin), opaque `base_fill_color`; all default off so Drowned Basilica / Endless Forest are unchanged. Alpine: parallax 0.04/0.08/0.12, 64 px cap, base fill (0.42,0.47,0.54). First camera lookup is now immediate (was a 0.5 s gray start-up).
- `alpine_plateau` Region Frame: `visual_fallback=false`, selects the Alpine underlay.
- Proof: `procgen_region_frame_smoke` extended (24-seed A/B determinism, 4 viewports x 6 zooms coverage, bounded deterministic parallax, non-Alpine defaults, RFR1 R0-01 production-scene assertion, RFR1 R0-02 ocean-pocket fixture). Moment Forge scenario `procgen/alpine_plateau_edge_review` (N/E/S/W, zoom 0.74) with review-only env wiring for candidate combos.

## Human decision
The user approved the six Gate A plates as the canonical baseline (chat, 2026-10-06) after seeing 7 curated combinations and all 8 A/B permutations. Dropbox: production profile `/CUSTODIAN/visual_review/procgen-alpine-plateau-underlay-assets/20261006T072124Z/REVIEW_MANIFEST.json`; permutations/comparison under `/CUSTODIAN/visual_review/procgen-alpine-plateau-underlay-combos/20261006T0628Z-*`.

## Preserved, not wired
The other 24 permissible donor plates (18 ordinary alternates, 6 scenic landmarks) stay in the donor ZIP (original bytes + generation identity) for `procgen-alpine-underlay-variety-v1`. The 30-image review candidates were staged locally under a `.gdignore`d, git-excluded directory and are not committed.

## Validation
Green: `procgen_region_frame`, `procgen_macro_presentation`, `procgen_meridian_hardstand_macro`, `elevated_world_asset_contract`, `procgen_nonwalkable_surface`, `asset_pipeline_v2`, `awakening_underlays_zones_01_05`, Drowned underlay smoke, `git diff --check`. Not green and not mine: `review_pairing_contract` fails identically on `origin/main` (`c720fe887`) for an Operator-workbench review packet's malformed bounded TASK OVERRIDE; it skips later tiers of `--changed`, so those tests were run individually.

## Awkward parts
- The claim was blocked by a stale branch claim; the user retired it (the auto-mode classifier refused the branch-hygiene command twice; the user ran it).
- The first-pass art was replaced twice; first Gate A recorded a different authoring chat than the packet.
- Sparse cutout art exposed engine-default gray in transparent gaps; fixed with the base-fill and then retoned from dark slate to a blue-gray so it no longer reads as a flat plane.
- The north review view shows an enclosed interior room's own gridded backdrop over the underlay (pre-existing, not changed here).
- Dropbox review runs are transient; cleanup commands from the manifests were not run.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: stale claim lock; art direction superseded twice; manifest authoring-chat mismatch; gray exposure through transparent gaps; unrelated red `review_pairing_contract` on main.
- Root cause / contributing factors: handoffs prepared before the packet's chat settled; backdrop assumed opaque-ish plates; wrapped branch-hygiene note.
- Prevention / pipeline improvement: verify manifest chat/id before claim; keep review-only candidate wiring; coverage/parallax/base-fill are profile data.
- Tooling / docs drift discovered: `review_pairing_contract` red on main skips later changed-file tiers.
- Follow-up: procgen-alpine-cliff-presentation-v1
- What worked: byte-identical promotion from a verified immutable handoff; 8-permutation review before committing art.

## Next Handoff
- Next workstream: procgen-alpine-cliff-presentation-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4
- Refresh reason: none
- Next action: AP1 is complete; verify cliff Gate B (26 PNGs) and release the cliff packet. `procgen-alpine-underlay-variety-v1` stays post-AP4.
- Blockers or open questions: none
