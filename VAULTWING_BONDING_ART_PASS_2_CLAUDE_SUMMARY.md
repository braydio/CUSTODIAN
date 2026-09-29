# Vaultwing Bonding Art Pass 2 — Closeout

> **Superseding handling note (2026-09-29):** the rejected-art quarantine described below is historical. Rejected/wrong-facing Vaultwing bonding images are now deletion-only after rejection/hash verification; do not preserve them as future task inputs.

## 1. Starting HEAD

Started at `bd5bc493889fe86beabd2bacbfc47e5feaaf3288` on `main`, not the
packet's expected `1fa207d6c`; the Awakening connector and Operator/procgen work
were already present in the shared worktree. Those unrelated changes were
preserved and excluded from this task commit.

## 2–4. Source hygiene

The Pass-1 `inspect_bait_s_source.png` and quarantined `inspect_bait_s_vw8.png`
both hashed to
`2e75b561e1026ae24416f8305129cfcbb65b12a898ee7e1e1c7324438dfe10ad`.
Removed only the rejected canonical copy and moved the preserved evidence to
`custodian/asset_drop/unresolved/vaultwing_bonding_rejected/inspect_bait_s_vw8__2e75b561e102.png`.
The reusable stager now uses hash-named durable quarantine, validates source
alpha and frame normalization before canonical source assignment, never emits
inbox art for rejection, and verifies quarantine before optional root cleanup.
Accepted canonical masters remain immutable. The staging lifecycle has three
deterministic Python regression cases.

## 5–6. Direction-safe resolver

`VaultwingAnimationSet` now applies strict direction resolution only to
`notice_bait`, `guarded_approach`, `inspect_bait`, `feed_accept`, `watch_player`,
and `bond_greet`. An exact facing resolves; W can intentionally mirror E; all
other cross-facing results return empty to the existing semantic fallback
chain. Generic ambient direction fallback remains unchanged.

Synthetic runtime coverage proves S-only `notice_bait` cannot satisfy E,
N-only `inspect_bait` cannot satisfy S, E can mirror to W, exact facing wins,
non-bonding cross-facing fallback remains, and `notice_bait` can reach the
correct-facing `ground_idle` semantic fallback.

## 7–12. Numbered inputs and normalization

Pass-2 discovery was run for ordinals `1, 8, 10–18`. None of the matching
`vwN.png` / `vw_N.png` files were present. Missing: **1, 8, 10, 11, 12, 13,
14, 15, 16, 17, 18**. Accepted this pass: none. Newly rejected: none. The old
rejected ordinal 8 remains preserved as quarantine evidence.

Pass-1 accepted sources remain the seven canonical bonding masters: ordinals
2, 3, 4, 5, 6, 7, and 9. The source_work directory contains 49 total
`*_source.png` files, including seven accepted bonding masters; rejected vw8
is no longer among them. Prior raw dimensions were 2172×724 for ordinals 2–6
and 1983×793 for 7–9. No Pass-2 normalization occurred, so there are no new
normalization measurements or inbox outputs.

## 13–19. Asset state and validation

Asset V2 plan and dry-run both resolved **0 inbox files / 0 runtime outputs**;
the inbox is empty. No W mirror was created in this pass. Existing bonding
runtime remains nine strips: `guarded_approach` N/E/S/W; `notice_bait` N/S;
`inspect_bait` N/E/W. Total Vaultwing runtime is 65 PNG strips (56 wild + 9
bonding). Asset status reports required 11/11 ready and recommended 4/9 ready;
the bonding suite remains partial. Asset Doctor reports two unrelated warnings:
an Awakening `full_plate_underlay.png` classification warning and an
unregistered Operator inbox with 12 PNGs.

- Source lifecycle unittest: 3/3 passed.
- `vaultwing_asset_contract`: passed; partial recommended coverage is accepted,
  malformed present art and missing required directions remain rejected.
- `vaultwing_runtime`: passed with synthetic direction/fallback assertions.
- `vaultwing_bond`: passed.
- `combat/vaultwing_first_bond`: not run; the full six-action art suite is
  incomplete, so neither evidence nor full capture is eligible.
- `--changed --json`: exit 6, coverage incomplete. All 32 selected tests passed
  with zero test failures/timeouts; the runner returned its uncovered-changed-
  file status because the shared worktree also contains unrelated Operator,
  procgen, and Awakening changes. Its two selected Awakening moment checks also
  passed. No second broad sweep was started.

## 20–24. Documentation, controls, and failures

Updated the source-work lifecycle/Pass-2 inventory, current Vaultwing status,
wild-versus-bonding distinction in FILE_INDEX, partial tracker wording, and
design status. Updated the Pass-1 summary's historical quarantine link to the
durable path. Production SFX, bait InventoryManager integration, global save
ownership, and Slice C remain pending.

Negative controls cover differing accepted canonical content, identical versus
ambiguous numbered filename forms, malformed present art, required direction
loss, strict facing, and unaffected generic fallback. One initial lifecycle
test used two byte-identical transparent PNGs while expecting distinct hashes;
the fixture was corrected with a visible pixel difference and all three tests
then passed. No art was synthesized, and no gameplay timing or progression was
changed.

## 25–28. Remaining work and next slice

No new runtime strips were published; final coverage remains 9/24 bonding and
65/80 total Vaultwing strips. Remaining authored masters are ordinals 1, 8,
10–18. Next: supply clean replacements/sources, run the same normalizer and V2
ingest, then perform evidence-mode and one final full
`combat/vaultwing_first_bond` review. Production feed vocalization and
bond-recognition call follow art acceptance; bait pickup/consumption and global
save ownership follow SFX, then Slice C companion behavior and `command_ack`.
