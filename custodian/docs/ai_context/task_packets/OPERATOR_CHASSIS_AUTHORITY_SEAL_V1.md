# OPERATOR CHASSIS AUTHORITY SEAL V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-chassis-authority-seal-v1`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `operator-runtime, validation-infrastructure`
- Kind: `implementation`
- Category: `agent-ops`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-operator-chassis-authority-seal-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Permanent structural Operator ownership and autonomous pre-landing validation are architecture-critical; a fresh reviewer must falsify bypasses.`
- Reviewed main: `65ee6fef70a6ad326a16ffbd46ebf18d7f3326db`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Seal the `operator.gd` actor/chassis ownership boundary **before F2/F3/F5/F6 extraction**, preventing new or reinstated gameplay-domain authorities while existing state is migrated out. Add real pre-landing checks; do not claim the zero architecture-debt ledger proves the chassis is already small.
- Completion boundary: A source-aware ownership/budget guard and independent negative fixtures are landed, registered in changed-file validation and compulsory before Operator-touching autonomous landing; it passes factual current source using explicit time-bounded legacy debt, catches attempts to reintroduce a stateful domain owner or foreign-body motor, rejects upward budget/rebaseline bypasses, and produces a monotonic ratchet consumable by F2/F3/F5/F6 and final G. No current gameplay behavior changes.
- Current measured state: At reviewed main, `custodian/game/actors/operator/operator.gd` is **14,676 lines / 738 top-level declared functions / 478 top-level variable declarations** (about 588 KB). The existing `operator_architecture_debt_baseline.json` is `{}` and its pattern audit has no measured violations, **but does not measure** actor-local melee/ranged/interaction/recovery authority. There remain actor-local attack chain/drive/hit bookkeeping, ammo/reload/heat, interaction targets/build/repair, damage/Field Patch/death, and extensive presentation control. An existing melee-hit fallback directly does `enemy.move_and_slide()` near line 7049: record as F2's bounded legacy exception and forbid additional occurrences immediately. Existing GitHub CI is push-triggered; it does not by itself fail a pre-push main landing. Main currently reports no repository rulesets.
- Evidence: `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`; `design/04_architecture/codebase_systems_audit/F01_OPERATOR_COMBAT.md` (2026-10-23 source audit/decision lock); `custodian/game/actors/operator/operator.gd`; `custodian/tools/validation/operator_architecture_debt_audit.py` and baseline; `custodian/tools/validation/validation_manifest.json`; `custodian/tools/agent/workstream.py`; `.github/workflows/validate-repository.yml`; existing F2/F3/F5/F6/G packets.
- Task-specific authority: Existing `operator/input/` owns input; `OperatorActionController` owns arbitration; `OperatorBodyPresenter`, `OperatorAnimationSelector`, `OperatorAnimationPlayer` and `OperatorPresentationController` own presentation. `OperatorLoadoutController`, `OperatorDodgeController`, `OperatorGuardController` already own their respective state. F2 owns melee including the foreign-body impact fallback; F3 owns ranged; F5 interactions; F6 damage/recovery; G chassis/scene collapse. `operator.gd` remains sole CharacterBody2D movement chassis, tick integration and necessary public facade. `run_validation.py` retains test execution authority; `workstream.py finish` retains landing safety authority.
- Work surface: Create `custodian/tools/validation/operator_chassis_authority_guard.py`, `custodian/tools/validation/operator_chassis_authority_budget.json`, `custodian/tools/validation/test_operator_chassis_authority_guard.py`; update `custodian/tools/validation/validation_manifest.json` and only the narrow existing finish/preflight integration needed for pre-landing enforcement; optionally extend the existing architecture debt audit for precise foreign-motor detection if appropriate. Refresh touched active Operator design/ownership/current-state/recipes, not historical receipts.
- Publication inputs: `none` (all prior authority docs/source and runner tools are tracked on main; the three new guard/budget/test files are **deliverables this packet creates**, never prerequisites assumed to exist at claim).
- Change:
  1. Measure live `main` at claim and emit auditable counts for actor line count, top-level fields, function declarations, non-delegating function/body size and stateful domains. Do not freeze the reviewed historic snapshot as current truth. Use deterministic GDScript-aware token/function boundaries; a brittle `^var` regex alone is not adequate, and comments/string literals must not generate false findings.
  2. Create a versioned machine-readable ownership map and baseline in the new budget file. Classify current actor-local gameplay state and methods by their **actual mutation/clock/decision behavior**: chassis integration vs pre-F2 melee, pre-F3 ranged, pre-F5 interaction, pre-F6 survivability, post-extraction compatibility and presentation bridges. List each historical exception and its owning extraction/expiry. Do not relabel unfinished domain authority as compliant just to reach zero.
  3. Fail closed on NEW unapproved mutable domain state, gameplay clocks, substantial actor-local state machines, ownership-changing method bodies, or domain mutation bypasses. Permit small explicit chassis orchestration and proven required forwarding facades; prevent the same mechanic regrowing inside an existing large method. A per-symbol/method-change classifier plus statement/side-effect thresholds should supplement global line/function budgets.
  4. Enforce a monotonic *decrease-only* budget after completed F2/F3/F5/F6 extractions; reject increases in owned state/function/delegation/line budget. Do not let a simple policy-file edit, blank baseline, or rebaseline flag waive violations. Allow an exceptional migration change only through an explicit, bounded, individually named evidence record identifying owner, consumer, reason, scope, and expiry, with independently testable approval handling; do not invent a secret approval channel.
  5. Check that direct Operator input sampling stays in input/, animation playback in presentation/, and actor gameplay never constructs private animation art; **reuse existing audit predicates** rather than fork duplicates. Extend foreign-motor detection: `enemy.move_and_slide()` is one **measured** F2 debt item; new `target.move_and_slide()` or aliased equivalent fails now, and F2 must retire the last legacy exception. Operator self `move_and_slide()` stays inside chassis movement application.
  6. Register the guard with `validation_manifest.json` ownership for `operator.gd`, controller/presenter files, policy, guard and tests; ensure domain files select their focused regressions rather than a perpetual broad `operator.gd` suite after migration.
  7. Prove the current autonomous `workstream.py finish` path cannot land an Operator-touching change if the authority guard fails, even when its author bypasses `run_validation.py --changed`; integrate at the existing preflight/validation authority, preserve worktree and receipt on failure, preserve unaffected non-Operator tasks. Also use ordinary push/PR CI for reproducibility. Document that no local preflight can replace enforced main-branch protection against arbitrary direct pushes; do not claim server-side enforcement unless verified.
  8. Run focused Python unit tests with positive delegation, nested field, accessor and multiline syntax cases and **negative controls**: new melee/weapon/recovery field; new or enlarged stateful actor method; policy increase/rebaseline; qualified or aliased foreign `move_and_slide()`; relocated controller state recreated in actor; non-registered facade; hash/comment/string bait; disabling guard or selective test execution. Verify fixture sensitivity by intentionally failing cases.
  9. Document the budget-reduction procedure and handoff to each domain packet and Slice G. G must demand the final reduced chassis ownership contract in addition to the three existing `--final` audits. Preserve final release zero-debt checks.
- Preserve: Fixed physics tick, existing actor public APIs and signals, gameplay/attack/field-patch/ranged/guard/dodge values and timing, one body owner, scene collision/root/registration, input and animation selectors, workstream claim/review/finish and all other checked-out work. No change to Render runtime.
- Non-goals: No F2/F3/F5/F6 extraction in this packet; do not remove the existing enemy impact fallback without F2's behavioral tests; no generic ECS, unrelated enemy.gd rewrite, large Godot actor sweep, balance changes, animation art, Asset Pipeline V2 work, or repo-wide CI redesign.
- Acceptance:
  1. A current-source baseline passes without hiding remaining domain state; initial debt and expiry owners are plainly reported.
  2. Negative fixtures genuinely fail, including disguised foreign movement, existing-method rebloat and policy-file manipulation, while legitimate thin delegation is accepted.
  3. Upward budget changes/rebaseline are mechanically gated; after extraction, retired exceptions cannot be re-added as ordinary code.
  4. Operator-touching finish/landing is blocked by a deliberately failing guard fixture and succeeds when restored; no other workstream's controls weakened.
  5. New guard selection is deterministic and scoped, and no newly named validation path is missing from the landed tree.
  6. Existing architecture, path, animation, action, dodge and loadout focused checks remain green; targeted agent/validation regression passes.
  7. Documentation identifies GitHub branch-protection limitation accurately. No false statement of server-side main protection.
- Validation: New chassis guard focused unit and negative tests; existing `custodian/tools/validation/operator_architecture_debt_audit.py --final`; existing `custodian/tools/validation/operator_runtime_path_audit.py` without `--final`; existing `custodian/tools/validation/operator_runtime_animation_authority_smoke.py` without `--final`; focused workstream preflight/finish tests; `custodian/tools/validation/run_validation.py --changed --json`; `git diff --check`. The ordinary path and animation audits must exit 0 and preserve all enforced invariants. Their existing legacy migration debt must be measured against the authenticated pre-change baseline, reported as outstanding, and must not increase or gain new prohibited identities. Their `--final` failures are expected incomplete-migration results, not passing validations. Do not alter audit semantics or require the not-yet-created guard test file at authoring time. Slice G remains responsible for the three final zero-debt audits and final chassis authority gate.
- Task overrides: `none`
- Deferred: F2 repairs foreign-body impact fallbacks and owns melee state extraction; F3 ranged, F5 interaction, F6 recovery each permanently ratchet their own debt; static socket closeout follows F3; G owns final shell contraction and hard-zero structural gate. GitHub repository ruleset/main protection is separately administered where available, never asserted present without verification.

## Handoff

- Next workstream: `review-operator-chassis-authority-seal-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `draft/manual only during targeted automatic authoring handoff; do not claim before both packets become ready/auto on origin/main`
- Next action: `Automatic authoring handoff promotes this pair, then dispatcher claims implementation under the existing lifecycle; independent review after landing.`
- Blockers or open questions: `none at authoring; F2/F3/F5/F6 must await the successful seal review`
