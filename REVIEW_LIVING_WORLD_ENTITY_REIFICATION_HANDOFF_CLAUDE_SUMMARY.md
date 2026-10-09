# F14-C1 Independent Review

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
Workstream: `review-living-world-entity-reification-handoff`
Reviewed main: `0728ec281`; target implementation commit `3eeae806f3f897c9b467cd929a324aa13cfb7216`.
Reviewer context: fresh. Reviewer provenance: different-agent (separately spawned reviewer context reconstructed from repository authority, archived packet, committed summary and live source).

## Findings

### R0-01 — Nonfinite anchor commits physical ownership

- Class: `blocking_defect`
- Domain: `implementation`
- Affected acceptance: (4) correct safe deterministic reentry anchor; (6) invalid anchor rejects non-destructively.
- Evidence: `custodian/game/systems/simulation/actor_reification_coordinator.gd:139` checks only node/type/tree membership; line 155 applies unchecked `anchor.global_position`; line 159 commits ownership. Independent probe registers synthetic D/A/B, supplies a valid abstract ActorId projection and an in-tree A anchor at `Vector2(NAN, 0)`, queues reentry and steps the kernel once: `ok=true`, `representation=physical`, `reified_position.is_finite=false`.
- Disposition: `correction`
- Rationale: Invalid geometry must preserve abstract authority and create no active actor. Finite geometry validation stays inside the approved synthetic boundary; no production placement/geography service is requested.

### R0-02 — Legacy v5 upgrade accepts corrupted fingerprint

- Class: `blocking_defect`
- Domain: `implementation`
- Affected acceptance: (7) legacy v5/event-ID migration and canonical fingerprint assertions; snapshot integrity/continuation.
- Evidence: `custodian/game/state/world/simulation_snapshot_migration.gd:8` calls `_capture_migrated_state` for abstract schema v1 before `SimulationSnapshot.restore` checks the migrated fingerprint (`simulation_snapshot.gd:15`). Capture a valid v5 D/G A/B snapshot, remove v2 actor fields, set abstract version 1 and compute its original payload hash: restore succeeds. Change only its fingerprint to `"corrupted"`: restore still succeeds. Migration replaces the supplied fingerprint with a new canonical hash.
- Disposition: `correction`
- Rationale: Re-signing the unchecked old payload bypasses the existing current-v5 corruption guard. Verify the original canonical payload fingerprint before normalization, while retaining valid legacy dotted event-ID reads and v4 compatibility.

### R0-03 — Ownership-disabled negative control still passes

- Class: `evidence_gap`
- Domain: `implementation`
- Affected acceptance: (8) focused test genuinely fails when exclusive ownership switching is disabled; (4) abstract movement suspended while physical.
- Evidence: `custodian/tools/validation/world_simulation_actor_reification_handoff_smoke.gd:156` holds physical ownership for 60 ticks after reentry. A scratch subclass of `AbstractActivitySimulationState` temporarily changes physical records to abstract during `advance_to_fixed_tick`, then restores their mode; inject it into the smoke both initially and after snapshot restore. The otherwise unchanged smoke exits 0/PASS. The sole macro boundary reached in the hold has elapsed less than `ACTIVITY_INTERVAL_TICKS` since the reentry transition, so the elapsed guard masks the removed ownership guard. Changing the scratch physical hold from 60 to 120 ticks makes the mutant exit 1 with `abstract movement advanced while the actor was physical`.
- Disposition: `correction`
- Rationale: The required falsification cannot be claimed from a test that passes when its invariant is deliberately disabled. Correct the committed hold/cadence assertions and retain reproducible mutation evidence without altering runtime ownership for normal validation.

## Verified evidence and limits

- Reconstructed from the archived nine-item implementation contract, F14 exclusive-ownership design table, F15 synthetic/production boundary, NPA ownership authority, committed target source and actual Grunt scene. No implementation-session transient reasoning was used and no implementation files were edited.
- `godot_import_preflight.py --project-dir custodian`: PASS. First direct invocation failed on missing global class metadata; `godot --headless --path custodian --editor --import` initialized it. This was not attributed to actor handoff behavior.
- Authored Grunt handoff, abstract activity, kernel, macro-state and snapshot-roundtrip smokes: PASS. Snapshot unsupported-schema diagnostic is an expected negative path. Synthetic Grunt reports missing production navigation path warnings; they do not change the smoke exit/PASS.
- Additional full two-crossing replay runs used the same committed smoke with a supported nondefault goal `harass_player` replacing the fixture's unrecognized `defend_relay`, plus a final canonical fingerprint/event print. Two separate processes produced identical fingerprint `1ac19fcaad4a4d637b393866d480fc46119f9c76780eb7b4034e552e3309bc64` and event `11:F14C_DOMAIN:11:F14C_PATROL:120`. This fills the initial concern that the committed replay comparison covers abstract continuation alone; it does not resolve the three findings.
- Identity/health capture and rollback, actual Grunt staging, root/descendant tree removal, fixed-step signal placement before abstract macro progression, accepted dotted IDs, legacy event migration and absence of production camp/procgen wiring were inspected. Initial claim is explicit fixture registration; residency requests wait for a fixed kernel boundary. No broad Enemy/spawner owner was modified, so no new spawn regression sweep was necessary for review.
- Review-artifact `run_validation.py --changed --json`: PASS, 2/2 selected contract checks (review pairing and visual handoff), no uncovered files. Targeted correction-pair authoring preflight passed before and after ready/auto promotion; managed queue index and `git diff --check` passed. These artifact checks are distinct from the five runtime smokes above.
- The authoring validator rejected an unpromoted draft/draft pair because it requires the gated review to be blocked/manual or ready/auto. A temporary local blocked/manual review allowed the first preflight; both packets were then promoted to ready/auto together, rechecked and indexed before publication. No manual hold was published.
- Temporary probes, logs and mutation scripts are outside the worktree under `/tmp/f14c1-review-*`; no generated media or implementation changes were committed. Nine generated unrelated reference-art `.import` sidecars were removed by exact path. The correction contract carries the minimal reproductions and expected assertions durably.

## Verdict

`findings`: two blocking implementation defects and one material acceptance-proof gap. Author one bounded cycle-1 correction/re-review pair; do not proceed into production F14-C2/F15 wiring. Review completion records the findings, not feature acceptance.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The first direct smoke could not resolve global classes in the fresh worktree; editor import generated nine unrelated reference-art import sidecars.
- Root cause / contributing factors: The new worktree had no Godot class/import cache; LFS preflight checks pointers rather than initializing that cache.
- Prevention / pipeline improvement: Initialize the Godot editor cache once before direct scripts in a fresh worktree; remove only the exact disposable generated sidecars after validation.
- Tooling / docs drift discovered: The authored physical hold missed an eligible macro interval, so its passing suspension assertion was not the claimed ownership falsification.
- Follow-up: living-world-entity-reification-handoff-review-corrections-1
- What worked: Independent fault probes and a temporary ownership mutation exposed defects the current passing smoke did not detect.

## Next Handoff

- Next workstream: `living-world-entity-reification-handoff-review-corrections-1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Refresh reason: none
- Next action: Claim the bounded correction after this review lands and archives; resolve R0-01/R0-02/R0-03, then obtain its fresh paired re-review.
- Blockers or open questions: Production F14-C2/F15 remains gated for the authoring chat after C1 correction acceptance.
