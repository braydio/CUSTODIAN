# Operator 2.5D Animation Viability Audit

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac60342-02a4-83e9-b402-577faeed63ff

Workstream: `operator-2-5d-animation-viability-audit` · **Paused at the human visual-review boundary; not complete.**

## Result
- 72 production-reachable action families: 4 GREEN, 1 YELLOW, 45 ORANGE, 5 RED, 17 GRAY. 178 legacy families, 13 superseded, 12 dormant and 4 head-only families were excluded from the estimate.
- Dominant gap is directional (E/W art reused for N/NE/SE/S/SW/NW in melee 1H, unarmed ready/relaxed posture and block). Second gap is identity: three character renders are in production (gray-armored hood, black-gold hood, cyan-visor).
- Proposed minimum target: 332 new directional sheets to draw, 194 more derivable by the existing mirror promotion, and 21 sheets to redraw, against 460 composed live sheets. High-frequency ORANGE/RED subset: 244 new drawn, 10 redraws.
- Elevation: Operator `set_fake_elevation()` vs `IsometricVisualAnchor2D` is compatible but needs adapter/convergence in the Forum slice.
- Likely runtime defects to verify in game: unarmed idle S and walk SE/SW compose headless; ranged fire_01 plays no fire layer at NE/S/NW; dodge_01 has only N/S (others fall back to south).

Artifacts (committed): `reports/operator_presentation/OPERATOR_2_5D_ANIMATION_VIABILITY.md`, `operator_2_5d_coverage.json`, locomotion, combat and reference matrices.

## Review handoff
- Dropbox manifest: `/CUSTODIAN/visual_review/operator-2-5d-animation-viability-audit/20261006T064109Z/REVIEW_MANIFEST.json`
- Reviewer questions: the five in the packet, plus which of the three looks is canonical.
- Reviewed evidence defaults to delete-after-review; after the decision resume this workstream and run:
  `python3 custodian/tools/iteration/publish_review_artifacts.py --reviewed-manifest /CUSTODIAN/visual_review/operator-2-5d-animation-viability-audit/20261006T064109Z/REVIEW_MANIFEST.json --reviewed-by chatgpt-user`

## Awkward parts and limits
- **Lords of Pain reference unavailable.** Neither named archive exists in ~/Downloads; nothing was fetched or substituted. The LoP row is a labelled placeholder. This is the only visual-review blocker.
- Knight row-to-direction mapping for rows 0-5 comes from the retired Knight-skin code; rows 6-7 are inferred; none pixel-proven.
- Matrix composites are reconstructed from the catalog (approximate z-order), not captured from the running game. The palette classifier is a heuristic confirmed by eye. Verdicts are a proposal, not an art-direction approval.
- My projection parser had two bugs mid-run (a regex that merged table entries, and an over-broad full-body rule); both were caught by comparing against the visuals and the runtime code, and the matrices were regenerated.
- Sheet counts depend on the proposed P5/P8/P4 targets and on mirror promotion being acceptable for handed gear; the reviewer may reduce them.
- Reachability drift found: `shared/locomotion/*_01` is LIVE at action level but only its dormant head layer exists; 54 retired full-body fallback sheets still ship.
- The Knight crops in the reference matrix come from the in-repo dev asset; no LoP pixels were used.

## No-mutation proof
2145 Operator PNGs and the generated catalog hashed identically before and after; `git status` shows only new files under `reports/operator_presentation/`; `git diff --check` clean. No broad Godot/runtime suite was run (no runtime code was touched).

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: LoP reference not present; projection parser bugs; no tool previews composed runtime layers, so composites were hand-built.
- Root cause / contributing factors: reference archive was expected in Downloads; runtime projection policy is spread across several GDScript tables.
- Prevention / pipeline improvement: add a composed-layer runtime preview and a ground_y registration check to the Operator status command; centralise projection tables in data.
- Tooling / docs drift discovered: reachability table marks head-only actions LIVE.
- Follow-up: manual-follow-up
- What worked: reachability table plus operator.gd tables gave a defensible production/legacy split; objective height/baseline measures confirmed visual impressions.

## Parallel worktree reminder
Other in-progress work exists: `agent/awakening-04-05-connector-transition-regression` (donor checkpoint, waiting on the connector polish review) and `agent/procgen-alpine-plateau-underlay-assets`. Your original checkout is `/home/braydenchaffee/Projects/CUSTODIAN` on `main`.

## Next Handoff
- Next workstream: isometric-2-5d-forum-vertical-slice
- Next packet state: refresh-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac60342-02a4-83e9-b402-577faeed63ff
- Refresh reason: Forum slice must incorporate the approved Operator viability verdict, the actual art backlog, and any required short-term projection/registration constraints rather than assuming the current Operator art is production-ready.
