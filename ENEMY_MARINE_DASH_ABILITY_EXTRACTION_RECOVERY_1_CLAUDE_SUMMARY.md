# Enemy Marine Dash Ability Extraction (Recovery 1)

Implemented the Marine Dash recovery slice in isolated workstream `enemy-marine-dash-ability-extraction-recovery-1`, synchronized to current `origin/main` `2c32f596e`. The stranded donor was treated as evidence: only its original Marine implementation delta was replayed. Stale docs/manifest snapshots and its unrelated draft packets were excluded; current-main docs and validation manifest were retained and updated narrowly.

## Implementation

- Added actor-local `MarineDash` and typed `MarineDashConfig`, plus `marine_dash_default.tres` for the Marine scene tuning.
- Replaced Marine-specific phase/timer/target/reset/cadence state and phase methods in `enemy.gd` with a typed ability instance and narrow shared host-service calls. The actor shrank from 4,958 to 4,615 lines, a net reduction of 343 lines.
- Routed the Sundered Keep ambush through `request_marine_dash`; added the public diagnostic/typed-ability seam used by validation.
- Updated Marine, spatial telemetry, and production ambush validation plus manifest ownership; updated ability, feature, architecture, current-state, file-index, and validation documentation.
- No Savage/Falcon runtime logic, generic ability base, new art/audio, or unrelated layout changes were included.

## Verification

- Independent parity script: all 26 original `Enemy` defaults match `MarineDashConfig`; all 26 original Marine scene tuning values match `marine_dash_default.tres`.
- `authored_vault_grunt_loot_marine_smoke.gd`: PASS.
- `enemy_hit_spatial_telemetry_smoke.gd`: PASS.
- `sundered_keep_marine_ambush_smoke.gd`: PASS against the production map.
- Static search: old Marine phase/reset fields and external `_start_marine_dash_*` calls are absent from runtime callers.
- Import preflight: PASS; headless Godot editor import completed.
- Packet index and `git diff --check`: PASS.
- Required changed-file closeout on synchronized `2c32f596e`: **BLOCKED**. 23 checks selected; 19 passed, one failed, three integration checks were skipped after the actor-tier failure. The failing check is `grunt_falcon_reversal`, which reports `ordinary paired critical must remain 96x96` from its existing ordinary-critical profile assertion. I ran the same smoke on the clean project-root main checkout and reproduced the same failure. The extraction changes no Operator paired-execution code or Falcon logic; this is recorded as a baseline blocker, not a passing result. Machine-readable run: `/tmp/enemy_marine_dash_recovery_changed_validation.json`.

## Deferred and awkward details

- The worktree’s first full editor import reimported the fresh cache for thousands of assets. Tracked status after import contained only task-owned source/doc/test changes; no unrelated generated sidecars were committed.
- The donor contained unrelated draft follow-up packets and older snapshots of current-state/index/manifest files. Those were deliberately omitted while reconciling its implementation against newer main.
- The failing paired-critical assertion and the three tier-skipped integrations remain open. No out-of-scope test or runtime edits were made to hide the failure.
- The implementation is committed only as a recoverable workstream checkpoint; it is not landed, and its paired review remains dependency-gated.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: Required changed-file validation fails the existing `grunt_falcon_reversal` ordinary-critical frame-size assertion and skips three higher-tier integrations even though the Marine-owned gates pass.
- Root cause / contributing factors: The current main ordinary-critical paired-execution profile does not meet the smoke's hard-coded 96×96 expectation; the same failure reproduces on the clean project-root main checkout.
- Prevention / pipeline improvement: Repair the baseline profile/smoke contract in its owning follow-up before resuming this task; keep the failing owner selected and do not weaken or relabel the result.
- Tooling / docs drift discovered: none beyond the recorded baseline validation mismatch.
- Follow-up: manual-follow-up
- What worked: Selective replay of the donor implementation preserved current-main documentation and manifest changes; exact value parity and three task-specific Godot gates provide focused behavior-equivalence evidence.

## Next Handoff
- Next workstream: `enemy-savage-pounce-ability-extraction`
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: Resolve the recorded baseline validation blocker, resume and complete this workstream including paired review, then allow NPA-2 to dispatch.
- Blockers or open questions: `grunt_falcon_reversal` still fails its `ordinary_critical` frame-size assertion on clean main; three integration checks remain skipped by the runner's tier policy.
