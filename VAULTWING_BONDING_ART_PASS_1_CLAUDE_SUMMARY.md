# Vaultwing Bonding Art Pass 1 Summary

Date: 2026-09-26
Starting HEAD: `668893aacaf0f251db8c9420cb1e0e0d1bca23b2`

## Inputs and fixed mapping

The requested ordinal range was 1–10. Eight root source files existed; seven
were accepted and one was rejected. No duplicate filename forms were present.
Ordinals 1 and 10 were absent. The source master mapping was not inferred from
image contents.

| Ordinal | Root input | Semantic source master | Raw dimensions | Result |
|---:|---|---|---:|---|
| 1 | absent | `notice_bait_e_source.png` | — | missing |
| 2 | `vw_2.png` | `notice_bait_s_source.png` | 2172×724 RGBA | accepted |
| 3 | `vw3.png` | `notice_bait_n_source.png` | 2172×724 RGBA | accepted |
| 4 | `vw4.png` | `guarded_approach_e_source.png` | 2172×724 RGBA | accepted |
| 5 | `vw5.png` | `guarded_approach_s_source.png` | 2172×724 RGBA | accepted |
| 6 | `vw6.png` | `guarded_approach_n_source.png` | 2172×724 RGBA | accepted |
| 7 | `vw7.png` | `inspect_bait_e_source.png` | 1983×793 RGBA | accepted |
| 8 | `vw8.png` | `inspect_bait_s_source.png` | 1983×793 RGBA | rejected; matte retained in quarantine |
| 9 | `vw9.png` | `inspect_bait_n_source.png` | 1983×793 RGBA | accepted |
| 10 | absent | `feed_accept_e_source.png` | — | missing |

Accepted and rejected source masters are under
`custodian/asset_drop/source_work/fauna/ambient_vaultwing_common/`. Ordinal 8
is also copied to
`custodian/asset_drop/unresolved/vaultwing_bonding_pass_1_matte/inspect_bait_s_vw8.png`.
Its generated gray/pink matte occupies about 49% of the low-alpha sheet area;
it was not safe to separate. The eight found root inputs were copied and
hash-verified before only those matching files were removed. Ordinals 1 and 10
were not synthesized.

## Normalization and ingest

`custodian/tools/assets/stage_vaultwing_bonding_source_work.py` implements the
fixed mapping and reusable frame extraction. It clusters source alpha by X,
checks frame groups and background cleanliness, uses one shared scale per
strip derived from the approved directional ground references, downsamples via
premultiplied-alpha Lanczos, and registers to the ground-support anchor in a
256×256 transparent cell. It does not repair anatomy or create frames.

Normalized inbox files were RGBA with these exact geometries:

- `notice_bait__n.png`, `notice_bait__s.png`: 1024×256 (4×256 cells, 8 FPS,
  one-shot).
- `guarded_approach__e.png`, `guarded_approach__n.png`,
  `guarded_approach__s.png`: 1536×256 (6×256 cells, 8 FPS, looping).
- `inspect_bait__e.png`, `inspect_bait__n.png`: 1280×256 (5×256 cells, 8 FPS,
  one-shot).
- No feed strip was available. No W inbox strips were authored.

Asset V2 dry-run planned exactly 7 source strips → 9 runtime strips, CREATE 9,
REPLACE 0. Ingest completed with `--godot-import`: 7 sources processed, 9
runtime files written, and 2 directions auto-mirrored. The W outputs are
`vaultwing_common__body__bonding__guarded_approach__w__6f__256.png` and
`vaultwing_common__body__bonding__inspect_bait__w__5f__256.png`; each was
verified as an exact per-cell horizontal mirror of its E strip. No gameplay
timing, mechanics, or animation-binding code changed. Asset V2 updated
`custodian/content/metadata/assets/generated/asset_catalog.generated.json` with
the nine authored/mirrored directional entries.

Runtime strips written under `custodian/content/sprites/ambient_creatures/vaultwing_common/runtime/body/bonding/`:

- `notice_bait`: N, S (`4f`).
- `guarded_approach`: E, W, N, S (`6f`).
- `inspect_bait`: E, W, N (`5f`).

## Asset and validation results

Asset V2 status after ingest:

- READY: `guarded_approach` N/E/S/W.
- PARTIAL: `notice_bait` N/S (E and mirrored W pending); `inspect_bait` N/E/W
  (S pending).
- MISSING: `feed_accept`, `watch_player`, and `bond_greet`.
- Required wild art remains 11/11 ready. Inbox is empty after ingest.
- `asset.py doctor`: no errors; one pre-existing unrelated warning for 12
  unregistered Operator inbox PNGs.

The Vaultwing asset smoke no longer assumes 56 strips. It validates every
present runtime strip against family metadata, canonical identity, dimensions,
alpha, frame occupancy, and cell-edge clipping; it enforces required-state
directions and treats recommended-state coverage as staged. Regression checks
prove partial recommended art passes, malformed present art fails, required
direction loss fails, and unknown action/direction are rejected. Result after
ingest: **65 strips, passed**.

Focused validation:

- `vaultwing_asset_contract`: passed.
- `vaultwing_bond`: passed.
- `vaultwing_runtime`: passed.
- `combat/vaultwing_first_bond --capture-mode evidence`: passed at tick 250;
  all 12 assertions passed, including observation, controlled approach,
  same-actor bond completion, allegiance, no hostile trial attack, and target
  release. Contact sheet was reviewed. Baseline was unavailable, so this is
  behavioral evidence, not final comparative art judgment. No full capture was
  run.
- `run_validation.py --changed --json`: 55 selected; 51 passed, 1 failed, and
  3 were skipped after the lower-tier failure. The unrelated
  `awakening_first_return` test failed on connector 04_05_A missing, connector
  04_05_B center mismatch, and the 04→05 production connector missing from the
  scene. A focused rerun reproduced those three failures. No Vaultwing-focused
  test failed.

## Documentation, controls, and remaining work

Updated the canonical missing-art tracker, source-work README, Slice B bonding
spec, Vaultwing system status, `CURRENT_STATE.md`, and `FILE_INDEX.md`. The
summary retains historical truth that B.2 itself added no art. The closeout
changed-file sweep was not fully green due to the unrelated Awakening connector
failures; those files were preserved and not altered here.

Negative controls held: no semantic remapping, no frame-count/FPS changes, no
manual W sheets, no matte cleanup guess, no source-master overwrite, no
`command_ack`, no gameplay changes, and no changes to unrelated dirty work.

The remaining planned eight masters are:

11 `feed_accept_s`; 12 `feed_accept_n`; 13 `watch_player_e`;
14 `watch_player_s`; 15 `watch_player_n`; 16 `bond_greet_e`;
17 `bond_greet_s`; 18 `bond_greet_n`.

Also recover/regenerate missing ordinal 1 and ordinal 10, and replace rejected
ordinal 8 with clean `inspect_bait_s` art before claiming the first ten
directions complete. Production feed/recognition SFX, inventory bait
consumption, and global save ownership remain follow-up work; companion
commands and `command_ack` remain Slice C.

## Awkward failures

The supplied set did not contain all ten numbered files: two were absent and
one was unusable due to its generated matte. The user's expected fully-ready
`notice_bait` and `inspect_bait` status therefore could not be met honestly.
The normalizer was corrected during dry-run after discovering that a sheet-wide
anchor made frame ground registration unstable; final staging uses each
frame's support anchor with one shared strip scale. The first mirror check
compared the whole strip as one image and reported a false mismatch because it
also reversed frame order; per-cell checks confirmed the Asset V2 mirrors are
exact. The Moment report has no baseline, and Asset Doctor retains the
unrelated Operator-inbox warning.
