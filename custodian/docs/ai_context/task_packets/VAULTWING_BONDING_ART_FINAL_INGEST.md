# VAULTWING BONDING ART FINAL INGEST

- Workstream: `vaultwing-bonding-art-final-ingest`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `none`
- Locks: `none`
- Goal: Close Slice-B Vaultwing bonding body presentation by ingesting the remaining mapped source sheets through the existing Asset Pipeline V2 family, without changing bonding mechanics or generic ambient animation behavior.
- Current measured state: Pass 3 has ingested eight accepted masters into eleven new runtime strips. Production coverage is now 15/18 authored E/S/N bonding masters, 20/24 bonding runtime strips, and 76/80 total Vaultwing runtime strips. The only missing production body art is `bond_greet` E/S/N plus mirrored W. The previously rejected `vw2`, `vw9`, `vw10`, and `vw12` inputs are deletion-only and are not production evidence.
- Task-specific authority: `design/02_features/ambient/VAULTWING_SYSTEM.md`, `design/02_features/ambient/VAULTWING_SLICE_B_BONDING.md`, `custodian/content/metadata/assets/families/ambient_vaultwing_common.asset.json`, and the current measurements in `VAULTWING_BONDING_ART_FINAL_INGEST_CLAUDE_SUMMARY.md`.
- Change: Remove the rejected bonding-art quarantine lifecycle; delete known wrong-facing/clipped inputs after hash verification; keep the existing explicit source-map seam; ingest corrected `bond_greet` E/S/N sheets through `ambient_vaultwing_common`; visually validate the completed first-bond presentation; update only docs made stale by the completed art coverage.
- Preserve: Existing immutable accepted source masters; strict direction behavior for the six bonding actions; generic `AmbientCreatureAnimationSet` fallback behavior; all 56 wild Vaultwing runtime strips; the 20 currently accepted bonding runtime strips; existing bond progression/timing/allegiance/persistence/spawn behavior; unrelated shared-worktree changes.
- Non-goals: Do not generate or repaint art; do not add feed/bond SFX; do not implement bait inventory consumption, global save orchestration, Slice C companion behavior, `command_ack`, mounting, or generic ambient resolver changes.
- Acceptance: Explicit source mapping remains regression-covered; no rejected bonding image remains in `source_work`, inbox, runtime, or `asset_drop/unresolved/vaultwing_bonding_rejected`; corrected `bond_greet` E/S/N inputs produce the remaining four runtime directions; bonding coverage reaches 24/24 and total Vaultwing runtime reaches 80 strips; Asset V2 reports all six bonding actions complete; `vaultwing_asset_contract`, `vaultwing_runtime`, and `vaultwing_bond` pass; `combat/vaultwing_first_bond` passes evidence review and exactly one final full-capture review; the requirements registry is updated and root `REQUIRED_ASSETS.md` is regenerated, never hand-edited.
- Task overrides: none
- Deferred: production feed vocalization; bond-recognition call; bait pickup/InventoryManager consumption; global save ownership; Slice C commands/behavior.
- Progress: Explicit `--source-map ORDINAL=PATH` handling is regression-covered (6 tests). Eight accepted masters are staged and ingested, producing eleven runtime strips. Current state is 15/18 authored bonding masters, 20/24 bonding strips, and 76/80 total Vaultwing strips. The three prior `bond_greet` inputs (`vw9`, `vw10`, `vw12`) clip wing sections and `vw2` is the superseded wrong-facing inspect attempt; all four are rejected and deletion-only. The repo-side rejected copies are removed by this correction. Delete any matching project-root originals only after SHA-256 verification. The packet remains blocked pending corrected greeting sheets or reviewed segmentation. Focused Asset V2 smokes passed; behavior smoke assertions passed, while the validation wrapper reported unrelated pointer-only LFS resource errors and an invalid LimboAI library.
- Agent/session: Codex 2026-09-28

## Work Surface

- Files/systems to change:
  - `custodian/tools/assets/stage_vaultwing_bonding_source_work.py`
  - its focused Python regression coverage
  - `custodian/asset_drop/source_work/fauna/ambient_vaultwing_common/`
  - `custodian/asset_drop/inbox/ambient_vaultwing_common/`
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
| `vw2.png` | superseded wrong-facing `inspect_bait_s` attempt | reject and delete after hash verification; never stage |
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

## Remaining Closure Plan

1. **Delete the known rejected images; do not quarantine them.**
   - Remove all repo-side rejected copies under
     `custodian/asset_drop/unresolved/vaultwing_bonding_rejected/`, including
     the historical matte reject.
   - In the coordination checkout, delete these task inputs only when SHA-256
     still matches the rejected image:
     ```text
     vw2.png  bfa1cde36f35fa29e7f9a4d52be913b1bd68aa1d029ea1e27dbfdad5472e4876
     vw9.png  14a96068cf030d224ac0ee73a96730d6d192b20012ed72f20866553ea82c1174
     vw10.png e91f2314f4858b17faf77ca0292c2dad11b3646514578c3ff4cfa9c233faf9ed
     vw12.png 930c6195808d592230534fd0e6cf191483306f12d49a4a474b06b1c4e85c98b4
     ```
     If a filename now contains a corrected replacement with a different hash,
     keep it and evaluate it normally.
   - The old rejected matte evidence
     `inspect_bait_s_vw8__2e75b561e102.png`
     (`2e75b561e1026ae24416f8305129cfcbb65b12a898ee7e1e1c7324438dfe10ad`)
     is obsolete and should also be deleted.

2. **Keep rejection cleanup fail-safe.** The staging helper must never create a
   quarantine copy for rejected bonding art. With `--remove-root-copies`, a
   rejected untracked task input may be deleted only after its current SHA-256
   is measured and the rejection decision is complete. Accepted immutable
   source masters remain unchanged. Preserve both numbered-source discovery and
   explicit `--source-map ORDINAL=PATH` behavior.

3. **Replace only the missing greeting art.** Supply corrected
   `bond_greet_e`, `bond_greet_s`, and `bond_greet_n` sheets for semantic
   ordinals 16, 17, and 18. Each must be 8 frames at 256×256 RGBA per frame,
   10 FPS, non-looping, true alpha, complete silhouettes, stable grounded
   registration, and no clipped wings. W remains Asset V2 mirrored from E when
   symmetric. Do not resurrect a rejected image merely to satisfy counts if it
   loses visible wing content.

4. **Dry-run, stage, and ingest through Asset V2.** Do not hand-author runtime
   filenames. Target closure is 18/18 authored bonding masters, 24/24 bonding
   runtime strips, and 80/80 total Vaultwing runtime strips.

5. **Validate narrowly first.**
   ```bash
   python3 custodian/tools/assets/test_stage_vaultwing_bonding_source_work.py
   python3 custodian/tools/validation/run_validation.py --test vaultwing_asset_contract --json
   python3 custodian/tools/validation/run_validation.py --test vaultwing_runtime --json
   python3 custodian/tools/validation/run_validation.py --test vaultwing_bond --json
   ```
   Then run `combat/vaultwing_first_bond` with `--capture-mode evidence`.
   After 24/24 art is complete and evidence review is visually green, run exactly
   one final `--capture-mode full`. Run `run_validation.py --changed --json`
   once at closeout only.

6. **Reconcile requirements/docs from current authority.** Update
   `custodian/content/metadata/assets/required_assets.registry.json`, then run
   `python3 custodian/tools/assets/asset.py needs --write` to regenerate root
   `REQUIRED_ASSETS.md`; never hand-edit the generated view. Run the current
   needs check, family plan/status, and doctor equivalents discovered from
   `asset.py --help`. Update `CURRENT_STATE.md`, `FILE_INDEX.md`, active
   Vaultwing design docs, the source-work README, and this summary only where
   final runtime truth changes.

7. **Close only after the visual gate.** Keep production feed vocalization,
   bond-recognition call, bait inventory consumption, global save ownership,
   `command_ack`, and Slice C companion behavior deferred until this art slice
   is complete.
