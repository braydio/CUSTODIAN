# Operator 2.5D Canonical Visual Contract — Summary (calibration correction pass)

Workstream `operator-2-5d-canonical-visual-contract`, branch `agent/operator-2-5d-canonical-visual-contract` (worktree `.custodian-worktrees/operator-2-5d-canonical-visual-contract`). **Not merged. Do not merge** until the viability audit releases `operator-art-agent` and the human calibration decisions below are made.

## Reminder
Separate worktree/branch. Switch back to your other in-progress work: main checkout `/home/braydenchaffee/Projects/CUSTODIAN` (`main`), and `agent/operator-2-5d-animation-viability-audit` (still holds the lock).

## Status
| Item | State |
|---|---|
| visual design | **locked** |
| camera / projection | **locked** |
| `operator_2_5d_128` profile | **provisional** (`legacy_96` accepted, unchanged) |
| root / floor | **pending human calibration** |
| shared body scale | **pending A/B approval** (0.200 vs 0.225) |
| universal 128 envelope | **pending proof** (projection evidence only) |
| final normalized hash | **pending** (zero-change cleanup receipts exist per candidate; final hash set after scale/root choice) |

## Corrections made
1. **Profile status.** `operator_2_5d_128` is `provisional`. `registration_profile.py` loads accepted or provisional geometry (legacy 96 must stay accepted), exposes `registration_status`/`accepted`, and `require_accepted()` / `ProfileNotAccepted` gate frozen-authority operations. Source Session production command, production verification and handoff now refuse a provisional profile (`PROFILE_NOT_ACCEPTED`); planning, QA, guides, overlays and calibration still work. Smoke proves (a) provisional 128 loads, (b) legacy accepted behaviour unchanged, (c) acceptance-only operations reject provisional.
2. **Root / floor.** Row 111 is now described and persisted as the *support-foot baseline* only. Per direction `root_model` persists `hip_center`, `left_foot_contact`, `right_foot_contact`, `projected_world_root` (candidate, `proven:false`), `shadow_origin` (candidate) plus `support_baseline_row`; global `root_model` records the median foot-contact midpoint (107.45) and comparison rows 106–108. Midpoints reproduce your table (N 108.4, NE 105.8, E 111.6, SE 106.6, S 108.3, SW 105.6, W 111.4, NW 106.0). No root_y is chosen.
3. **Registration overlay.** `operator_2_5d_registration_overlay.png`: 8 directions with cell bounds, x=64, both foot contacts, hip centre, candidate root/shadow origin, rails 106/107/108 vs 111/112, alpha bbox, shared scale.
4. **Scale A/B.** Deterministic, same canvas/root model, one scale per candidate: A 1/5 → 75–77 px (median 76); B 9/40 → 83–87 px (median 85, inside the previous 84–88 runtime range). Candidate PNGs under `reference/operator_2_5d/scale_candidates/`; `operator_2_5d_scale_ab_comparison.png` + summary JSON. Primary `directions/` remain candidate A, provisional. Human chooses.
5. **Action envelope.** Projection from the current runtime art for all 8 required classes (dodge/crouch, fast-chain, block-hit, overhead, longest 1H reach, ranged aim, large hit react, downed/death), per-sheet feet-band anchor, split lower/upper body modules (the `full_body` layer of melee_1h attack sheets has the sword baked in, so it would overstate body reach). **Body fits the 128 canvas projected for both A and B at root 111** in every class; weapon/FX/cape overflow is separate (longest 1H reach overflows 128 for A and B; dodge/fast-chain overflow for B) and needs its own presentation envelope. This is feasibility evidence, **not** proof of a universal 128 envelope: it needs authored canonical frames.
6. **Pixel cleanup certification.** Zero-change receipts for A and B (before/after hashes, empty changed-pixel list, alpha-mask and topology equality). The earlier contaminant flags were 6 yellow-gold speculars at hue 101–104° that my narrower 30–100° band missed; inspected, in-family, so the family band is now 25–110° (no pixel edited). Proposed cleanups are never auto-applied and pause for review.
7. **Source duplicate.** References now point at the preserved `source_work` copy (builder default included). The redundant repo-root `OPERATOR_DESIGN_REFERENCE_480.png` is removed on this branch; no code or current owner references it (only archived/active packet text). It disappears from `main` only when this branch merges, together with the preserved copy.
8. **Lock / main.** The audit worktree still owns `operator-art-agent` and is not archived on main. Branch is ahead of / behind `origin/main` (14 commits at last check); `git merge-tree` against current `origin/main` is clean. No rebase done yet (would rewrite the pushed branch): rebase/reconcile onto fresh main after the audit closes, then merge.

## Validation (all pass)
`operator_2_5d_canonical_visual_contract` (extended), `operator_art_registration_profile`, `operator_art_agent_aseprite_smoke`, `operator_art_agent_mcp_smoke`, `run_validation.py --changed --max-tier unit` (15/15), `git diff --check`. No runtime/Godot files touched.

## Human decisions needed
- Root/floor model: pick `projected_world_root`/`shadow_origin` rule and root row (106/107/108 vs 111) from the overlay.
- Canonical body scale: A 0.200 vs B 0.225.
- Review/approve the presentation-envelope approach for weapon/FX overflow.
- Then accept the profile (flip registration status) and re-run the cleanup certification on the chosen candidate to fix the final normalized hash.
- Landmarks remain agent visual annotations (confidence per point).

Visual review upload: see the Dropbox manifest in the chat reply.
