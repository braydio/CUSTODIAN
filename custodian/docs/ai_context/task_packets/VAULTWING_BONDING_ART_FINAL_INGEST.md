# VAULTWING BONDING ART FINAL INGEST

- Workstream: `vaultwing-bonding-art-final-ingest`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `none`
- Locks: `none`
- Goal: Close Slice-B Vaultwing bonding body presentation by ingesting the remaining mapped source sheets through the existing Asset Pipeline V2 family, without changing bonding mechanics or generic ambient animation behavior.
- Current measured state: On main at `06b0143ce0a4f2bcadaed072f312f502a157401c`, prior Pass 2 source-hygiene and direction-safe fallback fixes are live. Production coverage is 7/18 authored E/S/N bonding masters, 9/24 bonding runtime strips, and 65/80 total Vaultwing runtime strips. The user's twelve root files `vw1.png` through `vw12.png` are local task inputs, not semantic ordinal names.
- Task-specific authority: `design/02_features/ambient/VAULTWING_SYSTEM.md`, `design/02_features/ambient/VAULTWING_SLICE_B_BONDING.md`, `custodian/content/metadata/assets/families/ambient_vaultwing_common.asset.json`, and the measured starting evidence in `VAULTWING_BONDING_ART_PASS_2_CLAUDE_SUMMARY.md`.
- Change: Add a minimal explicit source-map input to `custodian/tools/assets/stage_vaultwing_bonding_source_work.py`; stage the eleven approved local sheets into canonical source_work/inbox paths; quarantine the superseded wrong-facing sheet; ingest through `ambient_vaultwing_common`; visually validate the completed first-bond presentation; update only docs made stale by the completed art coverage.
- Preserve: Existing immutable accepted source masters; durable rejected-source quarantine; strict direction behavior for the six bonding actions; generic `AmbientCreatureAnimationSet` fallback behavior; all 56 wild Vaultwing runtime strips; existing bond progression/timing/allegiance/persistence/spawn behavior; unrelated shared-worktree changes.
- Non-goals: Do not generate or repaint art; do not add feed/bond SFX; do not implement bait inventory consumption, global save orchestration, Slice C companion behavior, `command_ack`, mounting, or generic ambient resolver changes.
- Acceptance: Explicit source mapping is regression-covered and does not change default numbered-source discovery; the eleven approved inputs produce eleven canonical accepted source masters and fifteen new runtime directional strips; the superseded input is retained only as rejected evidence; bonding coverage reaches 24/24 and total Vaultwing runtime reaches 80 strips; Asset V2 reports all six bonding actions complete; `vaultwing_asset_contract`, `vaultwing_runtime`, and `vaultwing_bond` pass; `combat/vaultwing_first_bond` passes evidence review and exactly one final full-capture review; active docs reflect 18 authored masters / 24 bonding strips / 80 total strips; no task-owned root `vw*.png` clutter remains after verified staging.
- Task overrides: none
- Deferred: production feed vocalization; bond-recognition call; bait pickup/InventoryManager consumption; global save ownership; Slice C commands/behavior.
- Progress: Implemented explicit `--source-map ORDINAL=PATH` handling and focused regression coverage. Validation passed (6 tests). Blocked before art staging because the required local inputs `vw1.png` through `vw12.png` are absent from both the coordination checkout and the claimed worktree. Resume by placing the original twelve inputs in the coordination checkout root and copying them into this worktree; do not synthesize substitutes.
- Agent/session: Codex 2026-09-28

## Work Surface

- Files/systems to change:
  - `custodian/tools/assets/stage_vaultwing_bonding_source_work.py`
  - its focused Python regression coverage
  - `custodian/asset_drop/source_work/fauna/ambient_vaultwing_common/`
  - `custodian/asset_drop/inbox/ambient_vaultwing_common/`
  - `custodian/asset_drop/unresolved/vaultwing_bonding_rejected/`
  - `custodian/content/sprites/ambient_creatures/vaultwing_common/runtime/body/`
  - only stale Vaultwing status/tracker docs after successful ingest
- Related consumers or tests:
  - `custodian/game/actors/ambient/vaultwing/vaultwing_animation_set.gd`
  - `custodian/tools/validation/vaultwing_asset_contract_smoke.py`
  - `custodian/tools/validation/vaultwing_runtime_smoke.gd`
  - `custodian/tools/validation/vaultwing_bond_smoke.gd`
  - `custodian/tools/iteration/scenarios/combat/vaultwing_first_bond.json`

## Input Mapping

The root filenames are batch order, not semantic ordinals. This mapping is authoritative:

| Local input | Semantic asset | Disposition |
|---|---|---|
| `vw1.png` | `notice_bait_e` | accept candidate |
| `vw2.png` | superseded wrong-facing `inspect_bait_s` attempt | reject/quarantine only |
| `vw3.png` | `feed_accept_e` | accept candidate |
| `vw4.png` | `feed_accept_n` | accept candidate |
| `vw5.png` | `feed_accept_s` | accept candidate |
| `vw6.png` | `watch_player_e` | accept candidate |
| `vw7.png` | `watch_player_s` | accept candidate |
| `vw8.png` | `watch_player_n` | accept candidate |
| `vw9.png` | `bond_greet_e` | accept candidate |
| `vw10.png` | `bond_greet_n` | accept candidate |
| `vw11.png` | corrected `inspect_bait_s` | accept candidate |
| `vw12.png` | corrected `bond_greet_s` | accept candidate |

The extra greeting image generated after `vw12.png` is outside this task.

The semantic source-map passed to the stager is therefore:

```text
1=vw1.png
8=vw11.png
10=vw3.png
11=vw5.png
12=vw4.png
13=vw6.png
14=vw7.png
15=vw8.png
16=vw9.png
17=vw12.png
18=vw10.png
```

Because these inputs are local/untracked and normal implementation uses an isolated worktree, verify the twelve files in the coordination checkout before claiming this packet, then copy them into the claimed worktree without committing the root copies. If they are unavailable, block rather than synthesize substitutes.

## Plan

1. Extend the existing stager with a repeatable explicit `--source-map ORDINAL=PATH` seam. Validate ordinals, duplicate mappings, missing paths, and preserve current automatic `vwN.png` / `vw_N.png` behavior when the option is absent. Add focused regression coverage.
2. Hash and quarantine `vw2.png` as wrong-facing evidence. It must never populate canonical source_work or inbox.
3. Dry-run the eleven approved mappings. Existing normalization contracts remain authoritative: 256x256 RGBA cells, exact family frame counts/FPS, shared strip scale, stable grounded anchor, no matte, no clipping, no synthesized repairs. Reject unsafe inputs rather than weakening the family contract.
4. Apply staging and Asset Pipeline V2 ingest. W remains pipeline-mirrored from E. Expected delta is 11 accepted masters and 15 runtime strips, closing 18/18 authored masters and 24/24 bonding runtime strips.
5. Run focused validation first:
   ```bash
   python3 custodian/tools/validation/run_validation.py --test vaultwing_asset_contract --json
   python3 custodian/tools/validation/run_validation.py --test vaultwing_runtime --json
   python3 custodian/tools/validation/run_validation.py --test vaultwing_bond --json
   ```
   Then run `combat/vaultwing_first_bond` with `--capture-mode evidence`; if visually green and 24/24 is complete, run exactly one `--capture-mode full`.
6. Run `run_validation.py --changed --json` once at closeout only. Do not expand scope for unrelated shared-worktree failures.
7. Update `REQUIRED_ASSETS.md`, `CURRENT_STATE.md`, `FILE_INDEX.md`, Vaultwing design status text, and the source-work README only where the successful ingest changes current truth. Create `VAULTWING_BONDING_ART_FINAL_INGEST_CLAUDE_SUMMARY.md` with accepted/rejected inputs, measured geometry, runtime counts, validation, visual review, and deferred work.
