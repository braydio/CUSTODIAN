# HUB FIRST-SET INTEGRATION CLOSEOUT — H7

- Packet schema: `custodian.task_packet.v2`
- Workstream: `hub-first-set-integration-closeout`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-hub-crown-transfer-twin-solaria, review-hub-campaign-return`
- Locks: `hub-runtime, world-lifecycle, contract-bootstrap, route-traversal`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, workflow`
- Paired review workstream: `review-hub-first-set-integration-closeout`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `c2d6452ac10d`

- Goal: Close the first real Campaign loop as one reviewed integration: boot → full Awakening → persistent Hub → Forum Contract → optional Twin roundtrip → Muster/Port → same prewarmed procgen Campaign → outcome → persistent Hub return.
- Completion boundary: Build the narrowest deterministic end-to-end harness and fix only integration defects between already-reviewed H1-H6 authorities. Create no new feature owner. Completion requires one coherent trace proving identity continuity, exactly-once generation/outcome, active-world exclusivity, correct named spawns, optional Twin preservation, final Hub restoration, and truthful docs/roadmap.
- Current measured state: This packet is pre-authored before H2-H6 exist. Existing startup/prewarm/Twin/outcome smokes cover isolated seams, but no production-path end-to-end story loop currently exists.
- Evidence: `HUB_FIRST_SET_IMPLEMENTATION_ROADMAP.md`; all archived H1-H6 packets/reviews when dependencies land; startup-world-entry; Awakening progression/handoff; H1; Twin; world-contract prewarm; ContractWorldLoader; WorldSimulation; Campaign outcome validations.
- Task-specific authority: all reviewed H1-H6 contracts; first-set blockout/design; Campaign Flow; World Transition System.
- Work surface: One integration smoke/harness under `custodian/tools/validation/`; validation ownership/recipes; only bounded adapters/fixes required to satisfy reviewed interfaces; CURRENT_STATE, CONTEXT, FILE_INDEX, task-packet README, and roadmap closeout.
- Change: Drive the production default start through the real sequence. Test hooks may accelerate generation or resolve the Campaign, but may not bypass the public interactions/transition authorities being proven. Exercise optional Twin entry/return while prewarm is active or ready. Verify deployment consumes the accepted scenario/seed/map identity and return consumes the produced outcome. If a defect requires changing a reviewed subsystem contract rather than a narrow adapter, create bounded correction work instead of silently broadening H7.
- Preserve: reviewed H1-H6 ownership boundaries; default story boot; direct development modes; deterministic fixed-step simulation; no production-art requirement for logic closeout.
- Non-goals: No new Hub district; no second Contract cycle; no final art/audio; no save/resume; no full recovery/armament program; no Twin Passage restoration; no unrelated performance work.
- Acceptance: one deterministic end-to-end run proves: default boot enters Awakening with generation_count=0; reviewed completion enters one Hub at Spawn_SouthReach; Dais acceptance stores one scenario/seed and starts exactly one generation; optional Twin enters Spawn_CrownCauseway and returns Spawn_TwinReturn with selection/prewarm preserved; Port refuses pre-READY deployment; READY enters Campaign using the same scenario/seed/live prewarmed map without duplicate generation; Campaign resolution yields one outcome and one Hub mutation; Campaign runtime is removed; Hub returns at Spawn_CampaignReturn; final active-world count is one; no stale camera/navigation/input binding remains; duplicate/reentrant signals cannot create extra generation/outcome/history.
- Validation: Add one end-to-end first-set integration smoke registered in validation ownership. Run it first; run predecessor smokes only as needed to localize failures, then one changed-file closeout + `git diff --check`. Full visual capture is not required for logic closure; use targeted evidence only if a real transition-presentation defect appears.
- Task overrides: `none`
- Deferred: production Hub art/population; next Contract cycle; save/resume; deeper Campaign objectives; final transition audiovisual polish.

## Temporary Refresh Gate — REMOVE WHEN REFRESHED

After both `review-hub-crown-transfer-twin-solaria` and `review-hub-campaign-return` pass, inspect every landed H2-H6 public seam and focused smoke path. Update the harness to public production APIs, absorb any bounded review-correction names, remove this section, and set ready/auto. Refresh this packet in place.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `<fill at closeout>`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `<fill at closeout>`
- Friction severity: `<fill at closeout>`
- What went wrong: `<fill at closeout>`
- Root cause / contributing factors: `<fill at closeout>`
- Prevention / pipeline improvement: `<fill at closeout>`
- Tooling / docs drift discovered: `<fill at closeout>`
- Follow-up: `<fill at closeout>`

## Handoff

- Next action: Refresh after HR4 + HR6 pass.
- Best starting files: roadmap; archived H1-H6 packets/reviews; production startup/Awakening/Hub/Twin/Port/game/return owners; validation manifest.
- Blockers or open questions: exact final APIs/tests are intentionally dependency-derived.
