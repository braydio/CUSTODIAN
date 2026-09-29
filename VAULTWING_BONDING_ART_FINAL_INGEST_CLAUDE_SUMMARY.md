# Vaultwing Bonding Art Final Ingest — Work Summary

## Result

Resumed the claimed `vaultwing-bonding-art-final-ingest` workstream using the
user's local `vw1.png`–`vw12.png` inputs. No input was downloaded from `main`.
The source map and all dispositions were SHA-256 checked. The workstream is
still blocked because the three `bond_greet` sheets visibly lose substantial
wing art when split into their required eight frames.

Eight approved raw masters were preserved in `source_work`; seven passed the
family-aware stager and the eighth (`watch_player_e`) passed the repository
pixel-art converter's six-cell conversion and an eight-pixel cell-bound check.
All eight were resized with the balanced preset and ingested through Asset V2.
The ingest jobs wrote 11 new runtime strips. Current totals are 15/18 authored
bonding masters, 20/24 bonding strips, and 76/80 Vaultwing runtime strips.

## Input disposition

| Input | Semantic target | Result |
|---|---|---|
| `vw1.png` | `notice_bait_e` | accepted, balanced conversion, ingested |
| `vw2.png` | superseded wrong-facing `inspect_bait_s` | rejected; delete after hash verification |
| `vw3.png` | `feed_accept_e` | accepted, balanced conversion, ingested |
| `vw4.png` | `feed_accept_n` | accepted, balanced conversion, ingested |
| `vw5.png` | `feed_accept_s` | accepted, balanced conversion, ingested |
| `vw6.png` | `watch_player_e` | fixed-cell balanced conversion, ingested |
| `vw7.png` | `watch_player_s` | accepted, balanced conversion, ingested |
| `vw8.png` | `watch_player_n` | accepted, balanced conversion, ingested |
| `vw9.png` | `bond_greet_e` | rejected: four X clusters for eight frames; fixed-cell preview clips wings; delete after hash verification |
| `vw10.png` | `bond_greet_n` | rejected: six X clusters for eight frames; fixed-cell preview clips wings; delete after hash verification |
| `vw11.png` | `inspect_bait_s` | accepted, balanced conversion, ingested |
| `vw12.png` | `bond_greet_s` | rejected: six X clusters for eight frames; fixed-cell preview clips wings; delete after hash verification |

The task-worktree copies of all twelve inputs were removed after either matching
an accepted source master or verifying the rejected input hash. Rejected bonding
art is not a durable artifact: repo-side rejected copies are removed. If the
project-root copies of `vw2.png`, `vw9.png`, `vw10.png`, or `vw12.png`
still match the recorded rejected hashes, delete them as well; a corrected
replacement using the same filename must not be deleted. Three of the eleven
packet-approved candidates could not be migrated losslessly because equal-cell
conversion visibly clips wing sections.

## Validation

- `test_stage_vaultwing_bonding_source_work.py`: passed, 6 tests.
- `asset_pipeline_cli_ux_smoke.py`: passed.
- `asset_pipeline_v21_production_smoke.py`: passed.
- `asset_pipeline_v2_smoke.py`: passed.
- `asset plan ambient_vaultwing_common --verbose --json`: passed for the seven
  normalized inputs and the additional `watch_player_e` sheet.
- Both Asset V2 ingests with `--yes --godot-import`: completed; 9 then 2 runtime
  strips written.
- `vaultwing_asset_contract`: passed after temporarily materializing the 65
  existing Vaultwing PNG payloads from the local project-root checkout.
- `vaultwing_runtime` and `vaultwing_bond`: smoke assertions printed pass, but
  `run_validation.py` marked each run failed due pointer-only LFS resources
  across the worktree and the invalid LimboAI editor library. No remote LFS
  content was fetched.
- `asset doctor`: failed on catalog hashes for pointer-only checkout assets and
  stale generated `REQUIRED_ASSETS.md`; these are broader worktree drift and
  prevent a clean doctor result here.
- Moment Forge and final full capture: not run; the required greeting art is
  incomplete.

## Workstream state

The packet remains `blocked` pending corrected `bond_greet_e/s/n` sheets or a
reviewed segmentation that preserves every frame. Rejected/wrong-facing bonding
images are deletion-only and must not be retained in `unresolved/`. Pass 3
measurements and the remaining work are recorded in the active packet and
Vaultwing authority docs.
