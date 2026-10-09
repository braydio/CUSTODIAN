# CORRECTION: F14-C1 Real Enemy Handoff Review Cycle 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `living-world-entity-reification-handoff-review-corrections-1`
- Kind: `correction`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-living-world-entity-reification-handoff`
- Locks: `world-simulation-runtime, living-world-abstract-activity, world-actor-lifecycle`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-living-world-entity-reification-handoff-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Reviewed main: `0728ec281`
- Parent implementation: `living-world-entity-reification-handoff` — `custodian/docs/ai_context/task_packets/archived/LIVING_WORLD_ENTITY_REIFICATION_HANDOFF.md`
- Parent review: `review-living-world-entity-reification-handoff` — `custodian/docs/ai_context/task_packets/archived/REVIEW_LIVING_WORLD_ENTITY_REIFICATION_HANDOFF.md`
- Findings addressed: `R0-01, R0-02, R0-03`
- Affected acceptance: Parent (4)/(6) safe placement and non-destructive invalid-anchor rejection; (7) legacy migration/fingerprints; (8) real ownership-disabled falsification.
- Current defect/evidence: NaN Node2D safe anchor reentry returns ok and commits physical/nonfinite Grunt; old-v5 abstract-v1 snapshot restores with corrupted incoming fingerprint; scratch ownership-guard bypass still passes the authored smoke until its physical hold is extended to an eligible second macro boundary.
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Visual review: `none`
- Goal: Fail closed on invalid synthetic reentry geometry and corrupted legacy-v5 snapshots, and make the focused ownership regression discriminate physical abstract-advancement violations.
- Completion boundary: Small placement/fingerprint guards in their existing owners plus focused regression strengthening, preserving the one-real-Grunt synthetic C1 scope.
- Current measured state: Five parent focused smokes pass; independent review reproduces R0-01/R0-02 and an ownership-disabled PASS (R0-03). No production binding or new geographic contract is needed for these corrections.
- Evidence: `REVIEW_LIVING_WORLD_ENTITY_REIFICATION_HANDOFF_CLAUDE_SUMMARY.md` and archived parent Independent Review receipt; exact scratch reproductions recorded below.
- Task-specific authority: Parent F14-C1 exclusive ownership/placement/snapshot contract; existing canonical fingerprint restore guard; F15 synthetic-only boundary; NPA/Enemy ownership.
- Work surface: `custodian/game/systems/simulation/actor_reification_coordinator.gd`; `custodian/game/state/world/simulation_snapshot_migration.gd`; `custodian/tools/validation/world_simulation_actor_reification_handoff_smoke.gd`; narrowly relevant snapshot/abstract smoke only if required to prove legacy migration. Manifest only if owner selection actually changes.
- Required correction: R0-01 validate finite synthetic anchor geometry before staged scene activation/ownership commit; reject non-destructively with no leaked active Grunt. R0-02 compare original schema-v5 payload hash with its incoming fingerprint before converting abstract-v1 shape or legacy event IDs; retain valid migration. R0-03 ensure the committed physical hold crosses an eligible macro activity interval (including non-aligned transition ticks) and document a reproducible temporary ownership-disabled negative control that exits failure.
- Preserve: Stable Domain/ActorId/GroupId, condition/health/intent, fixed-step and 60-tick cadence, one active owner, exact-once callbacks/causal events, v4/v5/legacy dotted event reads, repeated crossings and abstract snapshot continuation, existing Enemy death/corpse/loot and spawner owners.
- Non-goals: No production safe-placement service, F15 topology, camp/procgen auto residency, multi-actor simulation, new Enemy family, disk-save/REMAP-3 integration, universal actor base or unrelated docs/runtime changes.
- Acceptance:
  1. R0-01: With a valid abstract D/G actor projection, reentry to an in-tree Node2D at NaN/Infinity is rejected before physical authority; group/projection/causal history remain unchanged and no active Grunt is leaked. Valid A/B anchors still reify once at finite deterministic positions.
  2. R0-02: A canonical valid schema-v5 snapshot with abstract schema-v1 actor fields absent restores (including pre-correction dotted event IDs); changing only its original fingerprint rejects it. Also reject payload tampering without updating its original fingerprint; successful migration yields the canonical new fingerprint and deterministic continuation. Existing v4 compatibility stays green.
  3. R0-03: Physical suspension assertions cross an actually eligible macro boundary after reentry at non-aligned ticks; a temporary bypass of the physical representation guard fails the focused smoke specifically on abstract movement/events while physical. Normal implementation passes.
  4. Parent full twice-crossing seeded replay, stable health/intent/IDs, duplicate requests, non-destructive attack/death/pending/failure negatives and abstract restore remain proven; five parent focused regressions pass.
- Validation: Import preflight then focused handoff smoke with the new negatives; reproduce the R0-01/R0-02 cases and ownership-disabled negative control. Run existing abstract activity, kernel, macro-state and snapshot-roundtrip smokes, changed-file validation once and `git diff --check`. No broad actor/boot sweep is justified by these scoped owners.
- Task overrides: `none`
- Deferred: F14-C2/F15 production binding and all parent non-goals remain gated after independent correction acceptance.

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `actor_reification_coordinator.gd` rejects nonfinite safe-anchor and staged actor positions before committing physical authority; `simulation_snapshot_migration.gd` checks the original schema-v5 state hash before abstract-v1 migration. The focused handoff smoke verifies NaN/Infinity rejection with unchanged group/projection and causal history, no leaked actor, valid finite reentry, valid dotted-ID legacy migration, corrupted-fingerprint rejection, and stale-hash payload-tamper rejection. Its 120-tick physical hold fails under a temporary representation-guard bypass with `abstract movement advanced while the actor was physical`. Import preflight passed; handoff, abstract-activity, kernel, macro-state, and snapshot-roundtrip smokes passed; changed-file validation passed 3/3; `git diff --check` passed.
- Outcome: Complete. R0-01, R0-02, and R0-03 are fixed within the synthetic one-Grunt boundary.
- R0-01 evidence: NaN and Infinity anchors reject before staged actor creation; canonical group/projection and causal history remain unchanged, no actor leaks, and finite B reification succeeds.
- R0-02 evidence: schema-v5/abstract-v1 input validates its original raw state fingerprint before migration. Valid dotted-ID legacy input restores; corrupted fingerprint and stale-hash payload tampering both return no restored state. Existing schema-v4 migration remains covered by snapshot-roundtrip smoke.
- R0-03 evidence: physical hold is 120 ticks after non-aligned reentry. A temporary physical-owner bypass failed the focused smoke with `abstract movement advanced while the actor was physical`; the source was restored and no bypass was committed.
- Validation: import preflight PASS; handoff, abstract-activity, kernel, macro-state, and snapshot-roundtrip smokes PASS; changed-file validation PASS (3/3 selected); `git diff --check` PASS.
- Deferred: production geography/residency, multi-actor transfer, ambient-spawner integration, and F14-C2/F15 remain outside this correction.

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: The first changed-file validation classified the expected corrupted-fingerprint `push_error` as a fatal test error even though the smoke assertions passed.
- Root cause / contributing factors: Invalid snapshot rejection logged through Godot's fatal error channel.
- Prevention / pipeline improvement: Reject the invalid legacy snapshot quietly by returning an empty migration result; rerun changed-file validation and require all selected checks green.
- Tooling / docs drift discovered: Fresh Godot editor import generated unrelated untracked `.import` sidecars; they were classified as generated setup output and removed before final changed-file validation.
- Follow-up: none
- What worked: The focused smoke now covers invalid geometry, both fingerprint failure modes, and the physical cadence mutation control.

## Minimal reproduction and falsification

- R0-01: Register synthetic D/A and D/B plus G/ACTOR. Set a valid abstract projection (health 39, max 78, condition 0.5, supported goal/profile, finite carried position), bind A to a live Node2D whose global position contains NaN or Infinity, request physical A and step once. Expected rejection with unchanged abstract record; reviewed main returns physical/nonfinite actor.
- R0-02: Capture a valid world snapshot v5, set abstract schema_version to 1 and remove actor_id/representation/actor_projection from its groups; use a legacy dotted event ID if present; compute original canonical hash. Valid restore must pass. Duplicate and change fingerprint only to `corrupted`, then separately tamper valid payload without changing that hash; both must reject before re-signing.
- R0-03: In disposable scratch outside the worktree, subclass the current AbstractActivitySimulationState and override advance_to_fixed_tick: temporarily mark physical group dictionaries abstract, call super, restore physical marks. Inject into focused fixture both before setup and after abstract snapshot restore. Reviewed smoke passes this mutation. Extending its physical loop from 60 to 120 ticks currently makes it exit 1 with `abstract movement advanced while the actor was physical`. Do not commit a production ownership bypass.

## Delta Rules

- Resolve only R0-01/R0-02/R0-03 and preserve the approved C1 boundary.
- Retain these IDs in re-review as fixed/unresolved/regressed; new cycle-1 findings use R1-NN.
- Correction is authorized by the parent review's bounded override; no human architecture choice is needed. Promote pair only after targeted authoring preflight, and claim only after review archive/queue publication is on origin/main.

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Refresh instruction: Reconcile live private owner names mechanically; do not introduce production geography or expand beyond these review findings.

## Next Handoff

- Next workstream: `review-living-world-entity-reification-handoff-review-corrections-1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Refresh reason: none
- Next action: Claim paired correction review in a fresh independent context after correction lands and archives complete.
- Blockers or open questions: none for bounded correction; production planning remains outside scope.

## Independent Review

- Status: `passed`
- Review workstream: `review-living-world-entity-reification-handoff-review-corrections-1`
- Reviewed on main: `a2ba651aaad4fb89af0a50fbbf6654181c4376ab` (correction implementation `086a21f116b2c4a154a354704b2ddd6b322cf788`; completion receipt `05255f3b3`)
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime`
- Blocking defects: `0`
- Material evidence gaps: `0`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Correction finding IDs: `none`
- Retained finding dispositions: `R0-01 fixed; R0-02 fixed; R0-03 fixed`
- Next-slice finding IDs: `none`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_LIVING_WORLD_ENTITY_REIFICATION_HANDOFF_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md`
- Follow-up workstream: `none` — production F14-C2/F15 requires the recorded planning refresh.
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31

### Review Notes

- R0-01 fixed: `_to_physical` captures and validates both anchor coordinates before scene instantiation, then checks the staged global position before committing authority. Fresh dotted-identity probes reject NaN/Infinity on both axes, preserve complete group/projection and causal history, have zero coordinator children immediately and zero active matching Grunts after a frame. A finite `(64,32)` anchor reifies exactly one actor; the committed A/B handoff smoke also passes.
- R0-02 fixed: original schema-v5/abstract-v1 payload SHA-256 is compared with the incoming fingerprint before deserialization/migration/capture. Fresh valid dotted-ID legacy input restores and retains `D.1.G.1.60`; its new canonical snapshot fingerprint is valid. Corrupted fingerprint and stale-hash payload tampering reject; restored legacy and current snapshots produce equal fingerprints after 120 continuation ticks. Existing v4/current-v5 snapshot smoke passes.
- R0-03 fixed: the committed physical hold is 120 ticks. Independent scratch subclass changes physical records to abstract only during `advance_to_fixed_tick`, then restores the marks, injected before setup and after snapshot restore. The hold starts at tick 133 and ends at 253, reaching eligible macro tick 240; the mutant exits 1 with `abstract movement advanced while the actor was physical`. Normal source passes. No runtime mutation was made in the worktree.
- Parent C1 conserved: actual Grunt, stable IDs and 39/78 health, nondefault supported `harass_player` goal, complete removal before abstract advancement, exactly one event, repeated crossings, abstract restore, duplicate/pending/attack/death/corpse/loot/invalid/failure rejection, and absence of production binding remain proved by source inspection and focused execution. Two separate full supported-goal replay processes reach tick 256 with equal fingerprint `a8858bab4c14571b627c6c8b36b49cd4cfef6d4d8f3f77e67ba9accac2b16c51` and sole causal event `11:F14C_DOMAIN:11:F14C_PATROL:120`.
- Import preflight/editor import and all five required focused smokes PASS. Snapshot smoke's unsupported-schema error is its expected negative path. Review-artifact changed-file validation and finish checks are recorded in the closing summary. No ambient spawner/Enemy owner change or broad sweep was required.
