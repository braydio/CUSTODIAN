# Operator 2.5D Canonical Visual Contract — Summary

Workstream `operator-2-5d-canonical-visual-contract`, branch `agent/operator-2-5d-canonical-visual-contract` (worktree `.custodian-worktrees/operator-2-5d-canonical-visual-contract`).

## Reminder
This work lives on a separate worktree/branch. Switch back to your original branch/worktree for any other in-progress work (main checkout: `/home/braydenchaffee/Projects/CUSTODIAN`, branch `main`). Other open Operator work: `agent/operator-2-5d-animation-viability-audit`.

## Deviations from the packet (user-approved)
- The approved source is the repo-root `OPERATOR_DESIGN_REFERENCE_480.png`: **3840x480 RGBA, eight 480x480 cells**, SHA-256 `37e080b8dda825dcfe048439e12f0ad4a66c70b33393d3296cd550761e1b0621`. The packet's 2048x256 / `2d5de16d...` identity was a mistaken reference; the user confirmed the root file. Recorded in the manifest.
- Claim gate: the viability-audit worktree still held the `operator-art-agent` lock when this started. Work is on an isolated branch and is **not landed**; resolve the lock before merging.

## What changed
- Preserved master + manifest + 8 exact source cells (reconstruct pixel-for-pixel) under `custodian/asset_drop/source_work/operator/operator_2_5d_design_reference/`. The root copy was left in place (byte-identical).
- `art_agent/canonical_contract.py`: deterministic build/verify, 128 normalization (one shared 1/5 crisp BOX reduction, binary alpha, integer translation; center x=64 from `hip_center`, support row 111 from toe contact, ground 112), landmarks, geometry/anatomy/color/outline measurements, rotational continuity, derived tolerances, and drift QA (`HARD_FAIL / STRUCTURAL_WARN / ART_DIRECTION_WARN / INFO`).
- `operator_art_profile.v3` registry (`legacy_96` unchanged + `operator_2_5d_128`, default). `registration_profile.load_profile` selects an explicit profile (id, frame size, or active); v1/v2 still load. Source Sessions pick profile by target size (default target size now 128); plans carry `profile_id` + effective hash; converter replay uses the same hash.
- Aseprite `operator_anchor_guides.lua`: 128 mode draws locked FLOOR/CENTER/BODY/CANONICAL_REFERENCE layers (`direction=` code or `grid`); 96 mode keeps the single ruler.
- Services/CLI/MCP: `canonical_reference`, `canonical_qa`.
- Docs: new `design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md`; style bible, roadmap, tools/aseprite READMEs, FILE_INDEX updated.
- Evidence: `reports/operator_presentation/canonical_visual_contract/` (turnaround, landmark overlay, measurement/palette JSON, report).

## Validation (all pass)
`operator_2_5d_canonical_visual_contract` (new), `operator_art_registration_profile` (updated to assert the new default + legacy), `operator_art_agent_aseprite_smoke`, `operator_art_agent_mcp_smoke`, `run_validation.py --changed --max-tier unit` (19/19), `git diff --check`. No Godot/runtime files touched; no runtime Operator art changed.

## Needs human attention
- Landmarks are **agent visual annotations** (confidence per point; occluded points <= 0.4); hood_top and toe/support rows are alpha-refined. Correct `operator_2_5d_landmark_annotations.json` and rebuild if any are off.
- The 5:1 crisp reduction of the approved render is the one appearance-changing step; review the turnaround/overlay.
- Old 96 Source Session plans carry the previous file hash and will report "profile changed; create a new plan" (intentional, no silent migration).
- Numeric camera pitch stays human-authority only.
