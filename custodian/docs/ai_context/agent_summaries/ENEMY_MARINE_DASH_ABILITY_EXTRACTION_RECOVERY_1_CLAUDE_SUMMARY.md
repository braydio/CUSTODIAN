# Enemy Marine Dash Ability Extraction (Recovery 1)

Implemented and completed the Marine Dash recovery slice in isolated workstream `enemy-marine-dash-ability-extraction-recovery-1`. On resume, synchronized the branch with latest main and preserved its packet-index and architecture updates. The stranded donor remained evidence only; the workstream retained its selective Marine implementation delta.

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
- Main sync exposed a review-pairing validator mismatch for intentionally planning-gated packets. Updated the contract and tests so blocked/manual reviews may pair with gated implementations while ready/auto implementations still require ready/auto reviews.
- The baseline `grunt_falcon_reversal` smoke queried a nonexistent `frame_size` profile key. It now inspects the published ordinary-critical first-frame texture and verifies 96×96; the focused smoke passes.
- Required changed-file closeout against `origin/main`: **PASS**, all 23 selected checks passed with zero failures, skips, or infrastructure errors. Machine-readable run: `/tmp/npa1-closeout.json`.

## Deferred and awkward details

- The worktree’s first full editor import reimported the fresh cache for thousands of assets. Tracked status after import contained only task-owned source/doc/test changes; no unrelated generated sidecars were committed.
- The donor contained unrelated draft follow-up packets and older snapshots of current-state/index/manifest files. Those were deliberately omitted while reconciling its implementation against newer main.
- The first post-sync closeout attempt also found the packet-pairing mismatch in newly added planning-gated Savage packets; direct unit coverage and the repository pairing check now pass.
- The extraction remains implementation-only: the independent post-land paired review is the next workstream.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: Main sync exposed a stale packet-pairing validator assumption and a smoke assertion against a nonexistent profile field; shared packet-index and architecture docs also conflicted during merge.
- Root cause / contributing factors: Planning-gated implementation/review packets were rejected by the pairing validator, and the Falcon smoke used profile metadata as a proxy for published frame geometry.
- Prevention / pipeline improvement: Pairing validation supports blocked/manual review pairs while implementations are gated; pixel-size assertions now inspect published frame textures.
- Tooling / docs drift discovered: Both validation mismatches reproduced on the main-derived branch and are now covered by direct passing checks; `task_packet_index.py --write` still expects a Ready/Auto heading removed from the current README structure, so packet archival/index state was updated in its live section directly.
- Follow-up: fixed-in-scope
- What worked: Marine behavior/parity evidence remained valid after sync; the corrected gates enabled the full 23-check closeout.

## Next Handoff
- Next workstream: `review-enemy-marine-dash-ability-extraction-recovery-1`
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: Dispatch the paired review in a fresh reviewer context; after it passes, return the landed implementation/review evidence to the NPA planning chat before refreshing NPA-2.
- Blockers or open questions: none; NPA-2 remains planning-refresh gated on the passed NPA-1 review.
